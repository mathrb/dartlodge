/**
 * #657 — Count Up per-dart correction on auto-assist.
 *
 * On the camera-first boards, tapping a thrown dart in the prominent dart band
 * opens a "Correct dart N" bottom sheet (see x01_auto_score_correction.spec.ts).
 * Count Up was the one board that no-op'd that tap (#657); this spec is the
 * positive control proving the fix: tapping a mis-scored dart opens the sheet
 * and picking a new segment recomputes the additive total.
 *
 * Two darts are emitted on a solo Count Up board, the first is corrected, and
 * the total + band are asserted.
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

test.describe('Count Up auto-scorer dart correction (#657)', { tag: ['@countup', '@correction'] }, () => {
  test('tapping a thrown dart opens the correction sheet and recomputes the total', async ({ browser }) => {
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
    await page.getByRole('textbox', { name: /Player name/i }).fill('Fix657');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();
    await page.waitForTimeout(2000);

    // Two darts → the camera "mis-scored" the first as T20 (=60 each → 120).
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(300);
    await expect(page.getByText('120').first()).toBeVisible({ timeout: 10000 });

    // Tap the first thrown dart's slot → the correction sheet opens.
    await page.getByText('T20', { exact: true }).nth(0).click({ force: true });
    await expect(page.getByText('Correct dart 1')).toBeVisible({ timeout: 10000 });

    // It was actually a single 5. Fix dart #1 → 5 + 60 = 65 (tail preserved).
    await page.getByRole('button', { name: 'Single 5 5', exact: true }).click();
    await expect(page.getByText('65').first()).toBeVisible({ timeout: 10000 });
    // The first slot now reads 5; the second is still T20.
    await expect(page.getByText('5', { exact: true }).first()).toBeVisible();
    await expect(page.getByText('T20', { exact: true }).first()).toBeVisible();

    await context.close();
  });
});
