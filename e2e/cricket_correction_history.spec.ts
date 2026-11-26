/**
 * Regression: the Cricket history turn breakdown reflects corrected darts —
 * superseded (undone/corrected) darts are stripped (#597 / #619, finding F-010).
 *
 * The bug: the history turn-breakdown builder did not honour `DartCorrected`, so
 * a turn that had a dart undone/corrected still rendered the stale dart (and its
 * marks). The fix routes the breakdown through `stripSupersededEvents`.
 *
 * Flow: undo a stray T18 on the board (DartCorrected), then close every
 * target through the sim bridge (emit + advance, as in cricket_solo_standard)
 * so the solo leg completes. The history turn breakdown only renders COMPLETED
 * legs (an abandoned game shows "No legs completed"), so ending the game early
 * would leave nothing to assert. From the post-game summary, DONE returns Home;
 * Sessions opens the game's detail page, whose leg breakdown lists the darts.
 * 18 is closed with D18 + 18, so no live dart reads "T18".
 *
 * The underlying fix is also unit-covered (turn_breakdown_test.dart, cricket
 * DartCorrected cases).
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
  test('an undone dart does not appear in the turn breakdown', async ({
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

    // Gate on the camera-first board being mounted (sink bound) before the
    // first emit, exactly like cricket_solo_standard: the player name renders a
    // frame before the postFrame sink-bind, and emits sent then are dropped.
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });

    // Throw T18 (a stray), then UNDO it via the board's undo button — this
    // appends a DartCorrected that supersedes the T18.
    await emit(page, 'T18');
    await page.getByRole('button', { name: /Undo last dart/i }).click();
    await page.waitForTimeout(400);

    // Then close every target, as in cricket_solo_standard, so the leg
    // completes (the history breakdown only renders completed legs). 18 is
    // closed with D18 + 18 so no live dart is a T18.
    // Turn 1: T20 · T19 · D18.
    await emit(page, 'T20');
    await emit(page, 'T19');
    await emit(page, 'D18');
    await sim(page, 'advance()');
    // Turn 2: 18 · T17 · T16.
    await emit(page, '18');
    await emit(page, 'T17');
    await emit(page, 'T16');
    await sim(page, 'advance()');
    // Turn 3: T15 · DB · DB — closing the Bull wins the solo leg.
    await emit(page, 'T15');
    await emit(page, 'DB');
    await emit(page, 'DB');

    // The game completes → post-game summary → DONE back to Home.
    await expect(page.getByText('STATISTICS BREAKDOWN')).toBeVisible({ timeout: 15000 });
    await page.getByRole('button', { name: /DONE/i }).click();
    await page.waitForTimeout(1000);

    // Home → open Sessions (history) → the game's detail.
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
