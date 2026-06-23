/**
 * End-to-End: X01 match structure — multi-leg progression and multiplayer.
 *
 *   - Multi-leg (auto-scoring): bump LEGS TO WIN to 2 in the config sheet, then
 *     win two legs. The "Next Leg" modal after leg 1 (it only appears when
 *     legsToWin > 1) proves the leg reset; reaching the post-game summary after
 *     leg 2 proves GameCompleted fires on the final leg.
 *   - Multiplayer (manual entry): two players, turn rotation via NEXT PLAYER,
 *     player 1 checks out while player 2 misses → player 1 wins.
 *
 * The LEGS TO WIN stepper's +/- are unlabeled icon buttons (Icons.add/remove,
 * no semantics), so we click the rightmost small (≤40px) button — the "+".
 *
 * Serve sim-enabled web on :6780 (see docs/E2E_REGRESSION.md).
 */

import { test, expect, Browser, Page, Locator } from '@playwright/test';

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

/** Click the LEGS TO WIN "+" — the rightmost small (≤40px) unlabeled button. */
async function incrementLegs(page: Page): Promise<void> {
  const buttons = page.getByRole('button');
  const n = await buttons.count();
  let plus: Locator | null = null;
  let plusX = -1;
  for (let i = 0; i < n; i++) {
    const box = await buttons.nth(i).boundingBox();
    if (box && box.width <= 40 && box.height <= 40 && box.x > plusX) {
      plusX = box.x;
      plus = buttons.nth(i);
    }
  }
  if (!plus) throw new Error('LEGS TO WIN "+" button not found');
  await plus.click({ force: true });
}

/** Solo 301 checkout (180 then T20+T11+D14) through the sim bridge. */
async function autoCheckout301(page: Page): Promise<void> {
  await sim(page, "emit('T20')");
  await sim(page, "emit('T20')");
  await sim(page, "emit('T20')");
  await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
  await sim(page, 'advance()');
  await sim(page, "emit('T20')");
  await sim(page, "emit('T11')");
  await sim(page, "emit('D14')");
}

test.describe('X01 match structure', { tag: ['@x01'] }, () => {
  test('auto-scoring: best-of-3 — winning two legs reaches the summary, with a Next Leg in between', {
    tag: '@autoscorer',
  }, async ({ browser }) => {
    test.setTimeout(150000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await page.getByRole('button', { name: /X01/i }).click();
    await page.getByRole('button', { name: /Select 301/i }).click();

    // Config sheet → LEGS TO WIN 1 → 2 → APPLY.
    await page.getByText(/Double Out/i).first().click({ force: true });
    await expect(page.getByText('LEGS TO WIN')).toBeVisible({ timeout: 10000 });
    await incrementLegs(page);
    await expect(page.getByText('2', { exact: true }).first()).toBeVisible();
    await page.getByRole('button', { name: /APPLY/i }).click({ force: true });

    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Lena');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });

    // Leg 1 → won. Because legsToWin = 2, the leg-complete modal appears.
    await autoCheckout301(page);
    await expect(page.getByRole('button', { name: /Next Leg/i }))
      .toBeVisible({ timeout: 15000 });
    await page.getByRole('button', { name: /Next Leg/i }).click({ force: true });

    // Leg 2 starts at 301 again.
    await expect(page.getByText('301').first()).toBeVisible({ timeout: 15000 });

    // Leg 2 → won → match complete → post-game summary.
    await autoCheckout301(page);
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('STATISTICS BREAKDOWN')).toBeVisible();

    await page.context().close();
  });

  test('manual entry: two-player game — player 1 checks out while player 2 misses', async ({
    browser,
  }) => {
    test.setTimeout(150000);
    const page = await boot(browser);
    await page.getByRole('button', { name: /X01/i }).click();
    await page.getByRole('button', { name: /Select 301/i }).click();

    // Create two players (each CREATE PLAYER auto-selects into the lineup).
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Pia');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Quinn');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await expect(page.getByRole('button', { name: 'Triple 20 20', exact: true }))
      .toBeVisible({ timeout: 15000 });

    // P1 (Pia) visit 1: 180 → 121, then NEXT PLAYER.
    for (let i = 0; i < 3; i++) {
      await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    }
    await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
    await page.getByRole('button', { name: /NEXT PLAYER/i }).click({ force: true });

    // P2 (Quinn) visit 1: three misses, then NEXT PLAYER.
    for (let i = 0; i < 3; i++) {
      await page.getByRole('button', { name: 'Miss MISS', exact: true }).click();
    }
    await page.getByRole('button', { name: /NEXT PLAYER/i }).click({ force: true });

    // P1 visit 2: T20 (→61) T11 (→28) D14 (→0) → checkout → P1 wins the game.
    await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    await page.getByRole('button', { name: 'Triple 11 11', exact: true }).click();
    await page.getByRole('button', { name: 'Double 14 14', exact: true }).click();

    // Game complete → summary; Pia is the winner.
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('PIA').first()).toBeVisible();

    await page.context().close();
  });
});
