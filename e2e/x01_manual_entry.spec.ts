/**
 * End-to-End: X01 manual-entry specifics not exercised elsewhere.
 *
 * The manual segment grid is already driven by x01_checkout / x01_strategy /
 * x01_match. This spec fills the two manual-only gaps those leave:
 *   - Bull and Double-Bull entry (25 / 50) through the grid.
 *   - The board UNDO button removing the last dart and restoring the score
 *     (the plain UndoLastDartUseCase path — distinct from the band→sheet
 *     DartCorrected correction covered in x01_auto_score_correction).
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

/** Home → X01 → 301 → solo player → board (manual grid up). */
async function startManualSolo301(page: Page, player: string): Promise<void> {
  await page.getByRole('button', { name: /X01/i }).click();
  await page.getByRole('button', { name: /Select 301/i }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  await expect(page.getByRole('button', { name: 'Triple 20 20', exact: true }))
    .toBeVisible({ timeout: 15000 });
}

test.describe('X01 manual entry', { tag: ['@x01'] }, () => {
  test('Bull and Double-Bull score 25 and 50', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startManualSolo301(page, 'Vera');

    // Double Bull (50): 301 → 251.
    await page.getByRole('button', { name: /Double Bull/ }).click();
    await expect(page.getByText('251').first()).toBeVisible({ timeout: 10000 });

    // Single Bull (25): 251 → 226.
    await page.getByRole('button', { name: /Single Bull/ }).click();
    await expect(page.getByText('226').first()).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('the board UNDO button removes the last dart and restores the score', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startManualSolo301(page, 'Wade');

    // Two T20s → 301 - 60 - 60 = 181.
    await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    await expect(page.getByText('241').first()).toBeVisible({ timeout: 10000 });
    await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    await expect(page.getByText('181').first()).toBeVisible({ timeout: 10000 });

    // Undo the last dart → back to 241 (the 181 state is gone).
    await page.getByRole('button', { name: /Undo/i }).click({ force: true });
    await expect(page.getByText('241').first()).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('181')).toHaveCount(0);

    // Undo again → back to the starting 301.
    await page.getByRole('button', { name: /Undo/i }).click({ force: true });
    await expect(page.getByText('301').first()).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });
});
