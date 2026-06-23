/**
 * End-to-End: X01 in/out strategy rules.
 *
 *   - Double-In: until the leg is "opened" with a double, darts do not score.
 *     The opening double itself scores. Covered both auto-scoring (sim bridge)
 *     and manual (segment grid) since the in-strategy gate lives in the engine
 *     and must hold on either input path.
 *   - Double-Out bust: overshooting the remaining score reverts the whole visit
 *     to its starting score (the default out-strategy is double-out).
 *
 * The in-strategy is set through the config bottom sheet opened from the config
 * summary chip on the player-selection screen (the "Custom" variant tile is
 * disabled; the chip is the only path). The sheet lists IN STRATEGY then OUT
 * STRATEGY, each STRAIGHT/DOUBLE/MASTER — so the IN-strategy DOUBLE is the first
 * of the two "DOUBLE" buttons (nth(0)).
 *
 * Serve sim-enabled web on :6780 (see docs/E2E_REGRESSION.md).
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
    document
      .querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  await page.waitForFunction(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    () => !!(window as any).dartlodgeSim,
    { timeout: 60000 },
  );
  return page;
}

/** Navigate Home → X01 → Select 301, landing on the player-selection screen. */
async function pickX01_301(page: Page): Promise<void> {
  await page.getByRole('button', { name: /X01/i }).click();
  await page.getByRole('button', { name: /Select 301/i }).click();
}

/** Open the config chip, switch IN STRATEGY to DOUBLE, APPLY (back to setup). */
async function setDoubleIn(page: Page): Promise<void> {
  await page.getByText(/Double Out/i).first().click({ force: true }); // chip
  await expect(page.getByText('IN STRATEGY')).toBeVisible({ timeout: 10000 });
  // First of the two DOUBLE buttons = IN STRATEGY's (OUT's is already DOUBLE).
  await page.getByRole('button', { name: 'DOUBLE', exact: true }).nth(0)
    .click({ force: true });
  await page.getByRole('button', { name: /APPLY/i }).click({ force: true });
  // The chip now advertises Double-In.
  await expect(page.getByText(/Double In/i).first()).toBeVisible({ timeout: 10000 });
}

/** Create a solo player and start the game. */
async function createPlayerAndStart(page: Page, player: string): Promise<void> {
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
}

test.describe('X01 in/out strategy', { tag: ['@x01'] }, () => {
  test('auto-scoring: Double-In — a single does not score until a double opens the leg', {
    tag: '@autoscorer',
  }, async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await pickX01_301(page);
    await setDoubleIn(page);
    await createPlayerAndStart(page, 'Ingrid');

    // Wait for the camera-first board to mount (sink bound) before emitting,
    // else the fire-and-forget emits land before the sink exists and are lost.
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('301').first()).toBeVisible({ timeout: 10000 });

    // Single 20 while not yet "in" → does NOT score: stays 301, never 281.
    await sim(page, "emit('20')");
    await expect(page.getByText('20').first()).toBeVisible({ timeout: 10000 }); // band shows the dart
    await expect(page.getByText('301').first()).toBeVisible();
    await expect(page.getByText('281')).toHaveCount(0);

    // Double 20 opens the leg and scores: 301 - 40 = 261.
    await sim(page, "emit('D20')");
    await expect(page.getByText('261').first()).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('manual entry: Double-In — single does not score, double opens and scores', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await pickX01_301(page);
    await setDoubleIn(page);
    await createPlayerAndStart(page, 'Otto');

    await expect(page.getByRole('button', { name: 'Single 20 20', exact: true }))
      .toBeVisible({ timeout: 15000 });

    // Single 20 → not in → 301 stays (never 281).
    await page.getByRole('button', { name: 'Single 20 20', exact: true }).click();
    await expect(page.getByText('301').first()).toBeVisible();
    await expect(page.getByText('281')).toHaveCount(0);

    // Double 20 → opens + scores → 261.
    await page.getByRole('button', { name: 'Double 20 20', exact: true }).click();
    await expect(page.getByText('261').first()).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('auto-scoring: Double-Out — overshooting the remaining busts back to the visit start', {
    tag: '@autoscorer',
  }, async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await pickX01_301(page); // default out-strategy = double, no config change
    await createPlayerAndStart(page, 'Bruno');

    // Wait for the camera-first board to mount before emitting (see above).
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('301').first()).toBeVisible({ timeout: 10000 });

    // Visit 1: three T20s → 121, advance.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
    await sim(page, 'advance()');

    // Visit 2: T20 (→61) T19 (→4) then T20 would go to -56 → BUST. The whole
    // visit reverts to its start score (121), proving bust resolution.
    await sim(page, "emit('T20')");
    await expect(page.getByText('61').first()).toBeVisible({ timeout: 10000 });
    await sim(page, "emit('T19')");
    await expect(page.getByText('4').first()).toBeVisible({ timeout: 10000 });
    await sim(page, "emit('T20')"); // overshoot → bust

    // Score is restored to the visit start (121), not left at 4 or negative.
    await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });
});
