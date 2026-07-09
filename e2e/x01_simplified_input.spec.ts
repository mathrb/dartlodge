/**
 * End-to-End: the opt-in simplified scoring keypad (#720) on the X01 board.
 *
 * With the "Simplified scoring keypad" setting on, the X01 board swaps its dense
 * full grid for four rows (1–7, 8–14, 15–20 + an arm-aware Bull cell, then
 * MISS / Double / Triple). This spec enables the setting via the Settings page,
 * then drives the keypad: arm Triple → tap 20 → -60, and confirms the Bull cell
 * still scores.
 *
 * Serve sim-enabled web on :6780 (see docs/E2E_REGRESSION.md).
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

/** Home → Settings → toggle the simplified keypad on → back to Home. */
async function enableSimplifiedKeypad(page: Page): Promise<void> {
  await page.getByRole('button', { name: /Settings/i }).first().click();
  await page.getByText('Simplified scoring keypad').click();
  await page.getByRole('button', { name: 'Back' }).click();
  await expect(page.getByRole('button', { name: /X01/i })).toBeVisible({
    timeout: 15000,
  });
}

/** Home → X01 → 301 → solo player → board (simplified keypad up). */
async function startSimplifiedSolo301(page: Page, player: string): Promise<void> {
  await page.getByRole('button', { name: /X01/i }).click();
  await page.getByRole('button', { name: /Select 301/i }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  // The simplified keypad exposes a "Triple" arm button (the full grid does not).
  await expect(page.getByRole('button', { name: 'Triple TRIPLE', exact: true }))
    .toBeVisible({ timeout: 15000 });
}

test.describe('X01 simplified keypad (#720)', { tag: ['@x01'] }, () => {
  test('armed Triple then a number scores the triple; specials still work',
    async ({ browser }) => {
      test.setTimeout(120000);
      const page = await boot(browser);
      await enableSimplifiedKeypad(page);
      await startSimplifiedSolo301(page, 'Tara');

      // Arm Triple, tap 20 → T20 = 60. 301 → 241. Arm then disarms.
      await page.getByRole('button', { name: 'Triple TRIPLE', exact: true }).click();
      await page.getByRole('button', { name: '20 20', exact: true }).click();
      await expect(page.getByText('241').first()).toBeVisible({ timeout: 10000 });

      // With nothing armed, tapping 20 scores a single. 241 → 221.
      await page.getByRole('button', { name: '20 20', exact: true }).click();
      await expect(page.getByText('221').first()).toBeVisible({ timeout: 10000 });

      // Bull with nothing armed scores a single bull (25). 221 → 196.
      await page.getByRole('button', { name: /Bull/ }).click();
      await expect(page.getByText('196').first()).toBeVisible({ timeout: 10000 });

      await page.context().close();
    });
});
