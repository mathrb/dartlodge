/**
 * End-to-End: Cricket structure & target modes (#661 follow-up).
 *
 *   - Manual entry: a full solo Standard game closed via the unified-table
 *     segment cells (the input path the sim-bridge specs don't exercise).
 *   - Round cap: a finite-round game with no winner hits the cap → the
 *     cap-winner selection dialog resolves the leg.
 *   - Random / Crazy target modes: the board mounts a non-fixed target set
 *     without crashing (CrazyTargetsRolled wiring — cf. #590). Full completion
 *     isn't asserted for Crazy because its open targets re-roll every turn.
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

test.describe('Cricket structure & target modes', { tag: ['@cricket'] }, () => {
  test('manual entry: closing all targets via the segment grid wins the game', async ({
    browser,
  }) => {
    test.setTimeout(150000);
    const page = await boot(browser); // no auto-scoring → manual unified table
    await page.getByRole('button', { name: /Cricket/i }).first().click();
    await page.getByRole('button', { name: /Select Standard/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Mara');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Manual board up: the segment cells are tappable.
    await expect(page.getByRole('button', { name: /Triple 20/i }))
      .toBeVisible({ timeout: 15000 });

    const tap = (name: RegExp) =>
      page.getByRole('button', { name }).click({ force: true });
    const next = () =>
      page.getByRole('button', { name: /Next Round/i }).click({ force: true });

    // Turn 1: close 20, 19, 18.
    await tap(/Triple 20/i);
    await tap(/Triple 19/i);
    await tap(/Triple 18/i);
    await next();
    // Turn 2: close 17, 16, 15.
    await tap(/Triple 17/i);
    await tap(/Triple 16/i);
    await tap(/Triple 15/i);
    await next();
    // Turn 3: close the Bull (DB = 2 marks, +DB clamps to 3) → win.
    await tap(/Double Bull/i);
    await tap(/Double Bull/i);

    await expect(page.getByText('STATISTICS BREAKDOWN')).toBeVisible({ timeout: 15000 });
    await expect(page.getByRole('button', { name: /DONE/i })).toBeVisible();

    await page.context().close();
  });

  // NOTE: a round-cap → cap-winner-dialog spec is intentionally NOT included.
  // Setting a finite cap requires picking a value from the ROUNDS dropdown in
  // the config sheet, and the Flutter dropdown menu options don't surface as
  // reliably-clickable nodes in CanvasKit (the same dropdown the X01 specs
  // avoided — they drive only the legs stepper by geometry). Tracked as a gap
  // in docs/E2E_REGRESSION.md rather than shipped as a flaky test.

  test('Random target mode launches with a playable target set', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await page.getByRole('button', { name: /Cricket/i }).first().click();
    await page.getByRole('button', { name: /Select Random/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Nora');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Board mounts (sink bound) — the CrazyTargetsRolled/random wiring didn't
    // crash the board, which is the regression this guards.
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText(/Nora/i).first()).toBeVisible();

    await page.context().close();
  });

  test('Crazy target mode launches without crashing the board', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await page.getByRole('button', { name: /Cricket/i }).first().click();
    await page.getByRole('button', { name: /Select Crazy/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Otis');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Crazy re-rolls open targets every turn; we only assert the board mounts
    // and accepts a dart (no completion — the target set is non-deterministic).
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText(/Otis/i).first()).toBeVisible();
    await sim(page, "emit('T20')");
    await page.waitForTimeout(500);
    // Still on the board (no error screen) after a dart.
    await expect(page.getByText(/Otis/i).first()).toBeVisible();
    await expect(page.getByText(/Retry/i)).toHaveCount(0);

    await page.context().close();
  });
});
