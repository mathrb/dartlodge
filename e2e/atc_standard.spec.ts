/**
 * End-to-End: Around the Clock — Standard variant (#NNN, fills the @atc gap).
 *
 * Standard ATC advances through targets 1→20; hitting the current target (any
 * multiplier) advances, and completing 20 wins. Driven via the sim bridge on
 * the camera-first practice board. We also assert the core hit-validation rule:
 * a wrong number does NOT advance the target, the right number does.
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

/** Home → Practice → Around the Clock → solo player → start (camera-first). */
async function startAtc(page: Page, player: string): Promise<void> {
  await sim(page, 'enableAutoScoring()');
  await page.getByRole('button', { name: /Practice/i }).click();
  await page.getByRole('button', { name: /Select Around the Clock/i }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  // Gate on the camera-first board mounting (sink bound) before emitting.
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
}

test.describe('Around the Clock — Standard', { tag: ['@atc', '@autoscorer'] }, () => {
  test('hitting 1→20 in order completes the game and reaches the summary', async ({
    browser,
  }) => {
    test.setTimeout(150000);
    const page = await boot(browser);
    await startAtc(page, 'Ada');

    // Hit each target in order. Each hit advances the current target, so we
    // must wait for the target display to show the next number before emitting
    // again — otherwise rapid fire-and-forget emits race ahead of the target
    // and land as wrong-number no-ops. Advance the turn after every 3rd dart
    // (solo = 3 darts/turn). Completing target 20 wins.
    for (let n = 1; n <= 20; n++) {
      await sim(page, `emit('${n}')`);
      if (n < 20) {
        await expect(page.getByText(`${n + 1}`, { exact: true }).first())
          .toBeVisible({ timeout: 8000 });
        if (n % 3 === 0) {
          await sim(page, 'advance()');
          await page.waitForTimeout(600); // let the async TurnStarted settle
        }
      }
    }

    // Game completes → auto-navigates to the post-game summary (practice has no
    // STATISTICS BREAKDOWN; the shared footer DONE + the "Around the Clock"
    // subline are the deterministic proof).
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('Around the Clock').first()).toBeVisible();
    await expect(page.getByText(/Ada/i).first()).toBeVisible();

    await page.context().close();
  });

  test('a wrong number does not advance the target; the correct number does', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startAtc(page, 'Bea');

    // Target starts at 1.
    await expect(page.getByText('1', { exact: true }).first())
      .toBeVisible({ timeout: 10000 });

    // Hit a WRONG number (5 while the target is 1). The dart registers (shows
    // in the band) but the target must NOT advance — so "2" never appears.
    await sim(page, "emit('5')");
    await expect(page.getByText('5', { exact: true }).first())
      .toBeVisible({ timeout: 8000 });
    await expect(page.getByText('2', { exact: true })).toHaveCount(0);

    // The correct number advances the target to 2.
    await sim(page, "emit('1')");
    await expect(page.getByText('2', { exact: true }).first())
      .toBeVisible({ timeout: 8000 });

    await page.context().close();
  });
});
