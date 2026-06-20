/**
 * Regression: the Count-Up board binds the DartInputSink, so the sim bridge
 * (and the camera auto-scorer) can drive it (#601, finding F-013). Before the
 * fix, Count-Up never bound the sink, so `dartlodgeSim.emit` was inert.
 *
 * Drives a solo Count-Up game through the sim bridge and asserts the score
 * reflects the emitted darts (three T20s = 180).
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

test.describe('Count-Up sim bridge (#601)', () => {
  test('emitted darts score on the Count-Up board', async ({ browser }) => {
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
      { timeout: 60000 },
    );

    // Auto-scoring on → the board binds the sink + mounts camera-first.
    await sim(page, 'enableAutoScoring()');

    // Home → Casual → Count-Up → create a player → start.
    await page.getByRole('button', { name: /Casual/i }).click();
    await page.getByRole('button', { name: /Select Count-Up/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Alice601');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await page.waitForTimeout(2000);

    // Three T20s → 180. Before #601 these emits were inert (no sink bound).
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(300);

    // The score reflects the emitted darts — proof the sink is bound and live.
    await expect(page.getByText('180').first()).toBeVisible({ timeout: 10000 });

    // A fire-and-forget 4th dart arrives after the turn is done (turn no longer
    // active, NEXT not tapped). The sink must DROP it — Count-Up's processDart
    // throws on an out-of-turn dart, which without the guard would swap the
    // board for an error screen. Assert the board stays put (score still 180,
    // no error UI).
    await sim(page, "emit('T20')");
    await page.waitForTimeout(400);
    await expect(page.getByText('180').first()).toBeVisible();
    await expect(page.getByText(/Retry/i)).toHaveCount(0);

    await context.close();
  });
});
