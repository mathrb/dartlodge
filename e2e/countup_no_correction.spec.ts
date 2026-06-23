/**
 * REPRO #657 — Count Up has no per-dart correction on auto-assist.
 *
 * On the X01/Cricket/Practice camera-first boards, tapping a thrown dart in the
 * prominent dart band opens a "Correct dart N" bottom sheet (see
 * x01_auto_score_correction.spec.ts — the positive control). The Count Up board
 * deliberately no-ops that tap (`_onSlotTapped` returns early for already-thrown
 * slots: "Count-Up has no per-dart correction"). With auto-assist, a mis-scored
 * dart therefore can't be fixed.
 *
 * This emits two darts on a solo Count Up board, taps the first dart's slot the
 * same way the X01 correction spec does, and asserts NO correction sheet opens.
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

test.describe('Count Up has no per-dart correction sheet (#657)', { tag: ['@countup', '@correction'] }, () => {
  test('tapping a thrown dart opens no correction sheet', async ({ browser }) => {
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
    await page.getByRole('textbox', { name: /Player name/i }).fill('NoFix657');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();
    await page.waitForTimeout(2000);

    // Two darts → the camera "mis-scored" the first as T20 (=60 each → 120).
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(300);
    await expect(page.getByText('120').first()).toBeVisible({ timeout: 10000 });

    // Tap the first thrown dart's slot, exactly like the X01 correction spec.
    await page.getByText('T20', { exact: true }).nth(0).click({ force: true });
    await page.waitForTimeout(1500);

    // On X01 this would show "Correct dart 1". On Count Up the tap is inert:
    // no correction sheet, no manual-entry grid (no segment buttons), score
    // unchanged, board still up.
    await expect(page.getByText(/Correct dart/i)).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Triple 20/i })).toHaveCount(0);
    await expect(page.getByText('120').first()).toBeVisible();

    await context.close();
  });
});
