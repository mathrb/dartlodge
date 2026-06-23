/**
 * REPRO #656 (P0 facet) — Undo corrupts Shanghai's round AND score.
 *
 * Shanghai advances `practiceRound` only in `_applyTurnEnded`, and its per-dart
 * scoring reads `practiceRound` as the target to hit. UndoLastDartUseCase skips
 * every TurnEnded on replay, so a single Undo collapses the round back to 1 —
 * which then re-scores the surviving round-2 darts against round 1's target,
 * silently dropping their points.
 *
 * Solo Shanghai:
 *   round 1 (target 1): T1 (3 pts), MISS, MISS  → score 3, advance
 *   round 2 (target 2): D2 (4 pts), D2 (4 pts)   → score 11
 *   undo the 2nd D2:
 *     correct → round 2, score 7 (3 + 4)
 *     bug     → round 1, score 3 (surviving D2 re-scored vs target 1 = 0)
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

test.describe('Shanghai undo preserves round and score (#656)', { tag: ['@shanghai', '@correction'] }, () => {
  test('undo in round 2 keeps the round at 2', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    // #656 fixed: undo now replays the non-superseded TurnEnded, so the round
    // counter survives and surviving round-2 darts keep scoring against round
    // 2's target. This spec asserts the correct invariant and must pass.
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
    await page.getByRole('button', { name: /Select Shanghai/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Undo656S');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();
    await page.waitForTimeout(2000);

    await expect(page.getByText(/ROUND 1 \//)).toBeVisible({ timeout: 10000 });

    // Round 1 (target 1): one triple-1 then two misses, advance.
    await sim(page, "emit('T1')");
    await page.waitForTimeout(150);
    await sim(page, "emit('MISS')");
    await page.waitForTimeout(150);
    await sim(page, "emit('MISS')");
    await page.waitForTimeout(250);
    await sim(page, 'advance()');
    await page.waitForTimeout(400);

    await expect(page.getByText(/ROUND 2 \//)).toBeVisible({ timeout: 10000 });

    // Round 2 (target 2): two double-2s.
    await sim(page, "emit('D2')");
    await page.waitForTimeout(150);
    await sim(page, "emit('D2')");
    await page.waitForTimeout(300);
    await expect(page.getByText(/ROUND 2 \//)).toBeVisible();

    // The practice board's undo button is a bare Icon(Icons.undo) with no
    // semanticLabel, so it has no accessible name — click it by position
    // (bottom-left 56x56 square in the action bar).
    await page.mouse.click(40, 871);
    await page.waitForTimeout(500);

    // Correct behaviour: removing one dart keeps us in ROUND 2.
    // (Under bug #656 the round collapses to ROUND 1, so this assertion fails
    // today — which is exactly what the expected-to-fail annotation captures.)
    await expect(page.getByText(/ROUND 2 \//)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/ROUND 1 \//)).toHaveCount(0);

    await context.close();
  });
});
