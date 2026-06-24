/**
 * End-to-End: Checkout Practice target modes (#636) — launch-only.
 *
 * The target mode (Fixed / Random / Progressive) is a segmented control in the
 * config sheet (so it IS drivable, unlike the dropdowns). We set the mode and
 * assert the drill launches with a target consistent with it:
 *   - Progressive starts at the minimum (default 40).
 *   - Random launches with a checkoutable target in [40, 170] (value is a stable
 *     hash of gameId+runIndex, so it can't be predicted — launch-only).
 * Fixed → 170 is already covered by checkout_practice_fixed.spec.ts.
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

/** Practice → Checkout, set [mode] via the segmented TARGET MODE control, start. */
async function startCheckoutMode(
  page: Page,
  player: string,
  mode: RegExp,
): Promise<void> {
  await sim(page, 'enableAutoScoring()');
  await page.getByRole('button', { name: /Practice/i }).click();
  await page.getByRole('button', { name: /Select Checkout/i }).click();
  await page.getByText(/Checkout/).first().click({ force: true }); // config chip
  await expect(page.getByText('TARGET MODE')).toBeVisible({ timeout: 10000 });
  await page.getByRole('button', { name: mode }).click({ force: true });
  await page.getByRole('button', { name: /APPLY/i }).click({ force: true });
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
}

test.describe('Checkout Practice — target modes', { tag: ['@checkout', '@autoscorer'] }, () => {
  test('Progressive starts at the minimum target (40)', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCheckoutMode(page, 'Hal', /PROGRESSIVE/i);

    // Progressive run 0 = minTarget (default 40), not the fixed 170.
    await expect(page.getByText('40', { exact: true }).first())
      .toBeVisible({ timeout: 10000 });
    await expect(page.getByText('170', { exact: true })).toHaveCount(0);

    await page.context().close();
  });

  test('Random launches the drill without crashing', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCheckoutMode(page, 'Ivy', /RANDOM/i);

    // The target is a stable hash of gameId+runIndex — unpredictable, so we
    // only assert the drill mounted (board up, first round live).
    await expect(page.getByText(/Checkout Practice/i).first()).toBeVisible();
    await expect(page.getByText(/ROUND 1/i)).toBeVisible();

    await page.context().close();
  });
});
