/**
 * End-to-End: Checkout Practice — the double-out checkout + bust mechanics
 * (fills the @checkout gap).
 *
 * The drill starts on 170 (fixed default). Finishing exactly on 0 with a DOUBLE
 * is a checkout (score shows 0, the attempt's darts in the band); the next
 * attempt resets the score to 170. A bust (overshoot / leaves 1 / 0 on a
 * non-double) reverts the score to the attempt's start and does NOT check out.
 *
 * Driven via the sim bridge in the default ∞-quota mode. NOTE: quota-based
 * auto-completion → post-game summary is NOT covered here — setting a finite
 * `target_successes` needs the config TARGET SUCCESSES dropdown, and the Flutter
 * dropdown menu (like the board "Show menu" overlay) resets the CanvasKit
 * semantics tree and isn't drivable by Playwright (same wall as cricket's
 * round-cap dropdown). The on-board score (0 vs reverted-170) is what cleanly
 * distinguishes a checkout from a bust, so we assert on that.
 *
 * Serve a sim-enabled web build on :6780 (see docs/E2E_REGRESSION.md).
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

const sim = (page: Page, call: string) =>
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  page.evaluate(`window.dartlodgeSim.${call}`);

async function boot(browser: Browser): Promise<Page> {
  const context = await browser.newContext(PIXEL_6A);
  const page = await context.newPage();
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  await page.evaluate(() =>
    document.querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  await page.waitForFunction(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    () => !!(window as any).dartlodgeSim, { timeout: 60000 });
  return page;
}

/** Home → Practice → Checkout → solo player → start (camera-first, ∞ quota). */
async function startCheckout(page: Page, player: string): Promise<void> {
  await sim(page, 'enableAutoScoring()');
  await page.getByRole('button', { name: /Practice/i }).click();
  await page.getByRole('button', { name: /Select Checkout/i }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
  await expect(page.getByText('170').first()).toBeVisible({ timeout: 10000 });
}

test.describe('Checkout Practice — fixed 170', { tag: ['@checkout', '@autoscorer'] }, () => {
  test('a double-out checkout drops the score to 0, then the next attempt resets to 170', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCheckout(page, 'Fin');

    // 170 = T20 (→110) + T20 (→50) + DB (→0, double bull is a double → checkout).
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await sim(page, "emit('DB')");

    // Checked out: the score sits at exactly 0 (a bust would show 170).
    await expect(page.getByText('0', { exact: true }).first())
      .toBeVisible({ timeout: 10000 });

    // The next attempt resets the score back to 170 (multi-attempt drill).
    await page.getByRole('button', { name: /NEXT ROUND/i }).click({ force: true });
    await expect(page.getByText('170').first()).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('a busting attempt reverts the score to 170 and does not check out', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCheckout(page, 'Gus');

    // T20 (→110) T20 (→50) T20 (→ -10, overshoot) → BUST: the whole attempt
    // reverts to its 170 start; no checkout (the score never reaches 0).
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");

    // Turn ended (3 darts processed) — NEXT ROUND is the positive anchor.
    await expect(page.getByRole('button', { name: /NEXT ROUND/i }))
      .toBeVisible({ timeout: 10000 });
    await expect(page.getByText('170').first()).toBeVisible();
    await expect(page.getByText('0', { exact: true })).toHaveCount(0);

    await page.context().close();
  });
});
