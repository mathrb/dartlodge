/**
 * End-to-End: Around the Clock variants — Reverse and Doubles Only (#NNN).
 *
 *   - Reverse: the first target is 20 and the sequence descends (20→19→18…).
 *   - Doubles Only: only a DOUBLE of the current target advances; singles and
 *     triples on the right number do NOT (Table D2 — the distinctive rule).
 *
 * The variant is set through the config-summary chip → bottom sheet on the
 * player-selection screen. Driven via the sim bridge on the camera-first board.
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

/** Practice → ATC, set [variant] via the config chip, create player, start. */
async function startAtcVariant(
  page: Page,
  player: string,
  variantLabel: RegExp,
): Promise<void> {
  await sim(page, 'enableAutoScoring()');
  await page.getByRole('button', { name: /Practice/i }).click();
  await page.getByRole('button', { name: /Select Around the Clock/i }).click();
  // Config summary chip → bottom sheet → pick the variant → APPLY.
  await page.getByText(/Around the Clock/).first().click({ force: true });
  await expect(page.getByText('VARIANT')).toBeVisible({ timeout: 10000 });
  await page.getByRole('button', { name: variantLabel }).click({ force: true });
  await page.getByRole('button', { name: /APPLY/i }).click({ force: true });
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
}

test.describe('Around the Clock variants', { tag: ['@atc', '@autoscorer'] }, () => {
  test('Reverse starts at 20 and descends', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startAtcVariant(page, 'Cyd', /REVERSE/i);

    // First target is 20; hits descend 20 → 19 → 18.
    await expect(page.getByText('20', { exact: true }).first())
      .toBeVisible({ timeout: 10000 });
    await sim(page, "emit('20')");
    await expect(page.getByText('19', { exact: true }).first())
      .toBeVisible({ timeout: 8000 });
    await sim(page, "emit('19')");
    await expect(page.getByText('18', { exact: true }).first())
      .toBeVisible({ timeout: 8000 });

    await page.context().close();
  });

  test('Doubles Only: a single does not advance, a double does', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startAtcVariant(page, 'Dot', /DOUBLES ONLY/i);

    // Target starts at 1.
    await expect(page.getByText('1', { exact: true }).first())
      .toBeVisible({ timeout: 10000 });

    // Three SINGLE 1s — none advance (only doubles count). The turn ends after
    // 3 darts (NEXT ROUND appears = darts processed), and the target is still 1
    // (2 never appears).
    await sim(page, "emit('1')");
    await sim(page, "emit('1')");
    await sim(page, "emit('1')");
    await expect(page.getByRole('button', { name: /NEXT ROUND/i }))
      .toBeVisible({ timeout: 8000 });
    await expect(page.getByText('2', { exact: true })).toHaveCount(0);

    // Next turn: a DOUBLE of 1 advances the target to 2. Wait out the async
    // TurnStarted after advancing before emitting (the bobs27 / cricket pattern)
    // — otherwise the emit can race the new turn and be dropped.
    await sim(page, 'advance()');
    await page.waitForTimeout(600);
    await sim(page, "emit('D1')");
    await expect(page.getByText('2', { exact: true }).first())
      .toBeVisible({ timeout: 8000 });

    await page.context().close();
  });
});
