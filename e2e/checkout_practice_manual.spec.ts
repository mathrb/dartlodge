/**
 * End-to-End: Checkout Practice via manual entry (#636 gap).
 *
 * With auto-scoring OFF the drill uses the full segment grid (same
 * DartInputGridWidget as X01 — you throw arbitrary darts to finish). We check
 * out 170 = Triple 20 + Triple 20 + Double Bull and assert the score lands on
 * 0 (a checkout on a double), exercising the manual input path.
 *
 * Serve a sim-enabled web build on :6780 (see docs/E2E_REGRESSION.md).
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

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

test.describe('Checkout Practice — manual entry', { tag: ['@checkout'] }, () => {
  test('checking out 170 via the segment grid lands the score on 0', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser); // no auto-scoring → manual segment grid
    await page.getByRole('button', { name: /Practice/i }).click();
    await page.getByRole('button', { name: /Select Checkout/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Jo');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Manual grid up; drill starts on 170.
    await expect(page.getByRole('button', { name: 'Triple 20 20', exact: true }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('170').first()).toBeVisible();

    // 170 = T20 (→110) + T20 (→50) + Double Bull (→0, a double → checkout).
    await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    await page.getByRole('button', { name: /Double Bull/ }).click();

    await expect(page.getByText('0', { exact: true }).first())
      .toBeVisible({ timeout: 10000 });

    await page.context().close();
  });
});
