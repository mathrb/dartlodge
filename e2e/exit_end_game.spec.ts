/**
 * Regression (#706): Back → End Game must abandon the in-progress game and
 * return Home in a SINGLE confirmation, for the practice board (Around the
 * Clock + the other drills) and the Count-Up board — matching X01/Cricket.
 *
 * Before the fix the board's local End Game dialog navigated home WITHOUT
 * marking the game complete, so the route's `onExit` guard re-raised the dialog
 * (a double-prompt) and the exit took several attempts. These tests assert that
 * one tap of "End Game" both dismisses the dialog AND lands on Home, and that
 * the abandoned game is persisted (shows up in History). Cancel keeps the
 * player on the board.
 *
 * Serve a sim-enabled web build on :6780 (see docs/E2E_REGRESSION.md):
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
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

/** Home → category → select game → new solo player → start. */
async function startGame(
  page: Page,
  { category, select, player }: { category: RegExp; select: RegExp; player: string },
): Promise<void> {
  await page.getByRole('button', { name: category }).click();
  await page.getByRole('button', { name: select }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  await page.waitForTimeout(1500);
}

/** Exits via the AppBar back button and confirms End Game once. */
async function backAndConfirmEndGame(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Back' }).first().click();
  await expect(page.getByText('End Game?')).toBeVisible({ timeout: 10000 });
  // A SINGLE tap: dismisses the dialog AND lands Home (no second prompt).
  await page.getByRole('button', { name: /^End Game$/i }).click();
}

test.describe('Back → End Game exits in one pass (#706)', { tag: ['@atc', '@countup'] }, () => {
  test('Around the Clock: one confirm abandons and lands Home', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startGame(page, {
      category: /Practice/i,
      select: /Select Around the Clock/i,
      player: 'Atc706',
    });

    await backAndConfirmEndGame(page);

    // Single pass: dialog gone, Home (Casual entry point) visible.
    await expect(page.getByText('End Game?')).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Casual/i }).first())
      .toBeVisible({ timeout: 10000 });

    // The abandoned game was persisted → it shows in History.
    await page.getByRole('button', { name: /History/i }).first().click();
    await expect(page.getByText('Around the Clock').first())
      .toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('Count-Up: one confirm abandons and lands Home', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startGame(page, {
      category: /Casual/i,
      select: /Select Count-Up/i,
      player: 'Cu706',
    });

    await backAndConfirmEndGame(page);

    await expect(page.getByText('End Game?')).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Casual/i }).first())
      .toBeVisible({ timeout: 10000 });

    await page.getByRole('button', { name: /History/i }).first().click();
    await expect(page.getByText('Count-Up').first())
      .toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('Cancel keeps the player on the board', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startGame(page, {
      category: /Casual/i,
      select: /Select Count-Up/i,
      player: 'Cu706cancel',
    });

    await page.getByRole('button', { name: 'Back' }).first().click();
    await expect(page.getByText('End Game?')).toBeVisible({ timeout: 10000 });
    await page.getByRole('button', { name: /Cancel/i }).click();

    // Dialog gone, still on the board (not Home).
    await expect(page.getByText('End Game?')).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Casual/i })).toHaveCount(0);

    await page.context().close();
  });
});
