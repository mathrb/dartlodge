/**
 * End-to-End: Around the Clock via manual entry (#NNN).
 *
 * With auto-scoring OFF the practice board shows the ATC input bar — a single
 * cell per multiplier for the CURRENT target, labelled `S-N` / `D-N` / `T-N`
 * (+ MISS), where N relabels as the target advances. We close a Standard game
 * by tapping the single cell for each target 1→20, advancing the turn every 3
 * darts, and assert the game completes — the input path the sim specs skip.
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

test.describe('Around the Clock — manual entry', { tag: ['@atc'] }, () => {
  test('closing 1→20 via the single cell wins the game', async ({ browser }) => {
    test.setTimeout(180000);
    const page = await boot(browser); // no auto-scoring → manual ATC input bar
    await page.getByRole('button', { name: /Practice/i }).click();
    await page.getByRole('button', { name: /Select Around the Clock/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Eli');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Manual board up: the single cell for target 1 is "S-1".
    await expect(page.getByText('S-1', { exact: true })).toBeVisible({ timeout: 15000 });

    for (let n = 1; n <= 20; n++) {
      await page.getByText(`S-${n}`, { exact: true }).click({ force: true });
      if (n < 20) {
        // The cell relabels to the next target — proof the hit advanced it.
        await expect(page.getByText(`S-${n + 1}`, { exact: true }))
          .toBeVisible({ timeout: 8000 });
        // Solo = 3 darts/turn; advance after every 3rd before tapping again.
        if (n % 3 === 0) {
          await page.getByRole('button', { name: /NEXT ROUND/i }).click({ force: true });
          await page.waitForTimeout(600); // let the new turn (async TurnStarted) settle
        }
      }
    }

    // Completing target 20 wins → post-game summary.
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('Around the Clock').first()).toBeVisible();
    await expect(page.getByText(/Eli/i).first()).toBeVisible();

    await page.context().close();
  });
});
