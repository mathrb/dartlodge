/**
 * REPRO #656 — Undo collapses the round counter in Count Up.
 *
 * Count Up advances `currentRoundInLeg` only in the engine's `_applyTurnEnded`
 * (TurnEnded event). UndoLastDartUseCase's replay loop unconditionally skips
 * every TurnEnded, and _buildInitialState never seeds currentRoundInLeg, so a
 * single Undo rebuilds the game with the round stuck at 1.
 *
 * This drives a solo Count Up game to round 2 via the sim bridge, throws one
 * dart, then taps Undo. The round indicator should stay "ROUND 2 / 8" but the
 * bug makes it revert to "ROUND 1 / 8".
 *
 * Serve a RELEASE web build with the sim flag on :6780:
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
 */
import { test, expect, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };
const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

test.describe('Count Up undo preserves round (#656)', { tag: ['@countup', '@correction'] }, () => {
  test('round counter reverts to 1 after undoing a dart in round 2', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const context = await browser.newContext(PIXEL_6A);
    const page = await context.newPage();

    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    await page.evaluate(() =>
      document
        .querySelector('flt-semantics-placeholder')
        ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
    await page.waitForFunction(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      () => !!(window as any).dartlodgeSim,
      { timeout: 60000 });

    await sim(page, 'enableAutoScoring()');

    await page.getByRole('button', { name: /Casual/i }).click();
    await page.getByRole('button', { name: /Select Count-Up/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Undo656');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();
    await page.waitForTimeout(2000);

    // Round 1 starts.
    await expect(page.getByText(/ROUND 1 \//)).toBeVisible({ timeout: 10000 });

    // Round 1: three T20s (=180), then advance to round 2.
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(250);
    await sim(page, 'advance()');
    await page.waitForTimeout(400);

    // We are now in round 2.
    await expect(page.getByText(/ROUND 2 \//)).toBeVisible({ timeout: 10000 });

    // Throw one dart in round 2, then UNDO it.
    await sim(page, "emit('T20')");
    await page.waitForTimeout(300);
    await expect(page.getByText(/ROUND 2 \//)).toBeVisible();

    await page.getByRole('button', { name: /Undo last dart/i }).click();
    await page.waitForTimeout(500);

    // CORRECT behaviour: still ROUND 2 (we only removed one dart).
    // BUG #656: the round collapses back to ROUND 1.
    await expect(page.getByText(/ROUND 1 \//)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/ROUND 2 \//)).toHaveCount(0);

    await context.close();
  });
});
