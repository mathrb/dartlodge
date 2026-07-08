/**
 * End-to-End: the opt-in simplified scoring keypad (#720) on the Count-Up board.
 *
 * Count-Up uses the manual grid when auto-scoring is off (default). This spec
 * enables the "Simplified scoring keypad" setting, starts a solo Count-Up game,
 * and drives the keypad: arm Triple → tap 20 → +60.
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
  await expect(page.getByRole('button', { name: /Casual/i })).toBeVisible({
    timeout: 15000,
  });
}

test.describe('Count-Up simplified keypad (#720)', { tag: ['@countup'] }, () => {
  test('armed Triple then a number scores the triple (auto-scoring off)',
    async ({ browser }) => {
      test.setTimeout(120000);
      const page = await boot(browser);
      await enableSimplifiedKeypad(page);

      // Home → Casual → Count-Up → create a player → start. Auto-scoring stays
      // off (default), so the manual simplified keypad is up.
      await page.getByRole('button', { name: /Casual/i }).click();
      await page.getByRole('button', { name: /Select Count-Up/i }).click();
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill('Cody720');
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
      await page.getByRole('button', { name: /START GAME/i }).click();

      await expect(page.getByRole('button', { name: 'Triple', exact: true }))
        .toBeVisible({ timeout: 15000 });

      // Arm Triple, tap 20 → T20 = 60 (Count-Up accumulates). 0 → 60.
      await page.getByRole('button', { name: 'Triple', exact: true }).click();
      await page.getByRole('button', { name: '20', exact: true }).click();
      await expect(page.getByText('60').first()).toBeVisible({ timeout: 10000 });

      await page.context().close();
    });
});
