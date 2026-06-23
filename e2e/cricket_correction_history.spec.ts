/**
 * Regression: the Cricket history turn breakdown reflects corrected darts —
 * superseded (undone/corrected) darts are stripped (#597 / #619, finding F-010).
 *
 * The bug: the history turn-breakdown builder did not honour `DartCorrected`, so
 * a turn that had a dart undone/corrected still rendered the stale dart (and its
 * marks). The fix routes the breakdown through `stripSupersededEvents`.
 *
 * STATUS: test.fixme — scaffold, not yet runnable end-to-end.
 *
 * The flow below is verified up to the game's history *detail* page: the board
 * undo (DartCorrected), re-throw, End-Game-to-history, Sessions nav and the
 * game-card tap all work. The blocker is the assertion target: the per-turn
 * breakdown is keyed on COMPLETED legs, and an abandoned game shows
 * "No legs completed" — so the dart-chip rows never render. Asserting the
 * corrected dart needs a fully *completed* cricket leg (close 15–20 + Bull
 * across alternating Cric597/OPPONENT turns, with turn-active gating + the
 * leg-complete modal), which is long and click-fragile on CanvasKit/web.
 *
 * The underlying fix is unit-covered (turn_breakdown_test.dart, cricket
 * DartCorrected cases). Finish this spec by replacing the End-Game step with a
 * full leg completion, then switch to the "BREAKDOWN" tab on the detail page
 * before the chip assertions. Best validated/stabilised on the device rail.
 *
 * Build/serve a RELEASE web build with the sim flag:
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
 */

import { test, expect, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

async function emit(page: Page, seg: string) {
  await sim(page, `emit('${seg}')`);
  await page.waitForTimeout(200);
}

test.describe('Cricket history reflects corrected darts (#597)', { tag: ['@cricket', '@correction', '@history'] }, () => {
  // Scaffold: navigates correctly to the game detail, but the turn breakdown
  // only renders for COMPLETED legs (see header). Unblock by completing a full
  // cricket leg, then switch to the BREAKDOWN tab before asserting.
  test.fixme('an undone dart does not appear in the turn breakdown', async ({
    browser,
  }) => {
    test.setTimeout(150000);
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
      { timeout: 60000 },
    );

    await sim(page, 'enableAutoScoring()');

    // Home → Cricket → Standard → one player → start.
    await page.getByRole('button', { name: /Cricket/i }).first().click();
    await page.getByRole('button', { name: /Select Standard/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Cric597');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await page.waitForTimeout(2000);

    // Throw T18 (a stray), then UNDO it via the board's undo button — this
    // appends a DartCorrected that supersedes the T18.
    await emit(page, 'T18');
    await page.getByRole('button', { name: /Undo last dart/i }).click();
    await page.waitForTimeout(400);

    // Re-throw three T20s (closes 20), then end the turn so it lands as a
    // completed turn in history.
    await emit(page, 'T20');
    await emit(page, 'T20');
    await emit(page, 'T20');
    await sim(page, 'advance()');
    await page.waitForTimeout(600);

    // Abandon the game (End Game) so it appears in history.
    await page.getByRole('button', { name: /Game options/i }).click();
    await page.getByRole('menuitem', { name: /End Game/i }).click();
    // The confirm dialog's primary action is also labelled "End Game".
    await page.getByRole('button', { name: /End Game/i }).last().click();

    // Lands on Home → open Sessions (history) → the game's detail.
    await page.getByRole('button', { name: /Sessions/i }).click();
    await page.waitForTimeout(1000);
    await page.getByText('Cric597').first().click();
    await page.waitForTimeout(1000);

    // The turn breakdown shows the live darts (T20), never the superseded T18.
    await expect(page.getByText('T20').first()).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('T18')).toHaveCount(0);

    await context.close();
  });
});
