/**
 * End-to-End: a solo Standard Cricket game played to completion (#661).
 *
 * Fills the documented `@cricket` runtime gap — until now the only `@cricket`
 * spec was the `test.fixme` scaffold in cricket_correction_history.spec.ts.
 * Driven through the sim bridge (`window.dartlodgeSim`) exactly like the X01
 * auto-scoring specs: emit detected darts, advance the turn at the 3-dart
 * boundary. Closing all targets (20·19·18·17·16·15·Bull, 3 marks each) in a
 * solo game wins the single leg → the board auto-navigates to the post-game
 * summary, which is the deterministic completion proof.
 *
 * Unlike X01's camera-first board, the Cricket camera-first board has no
 * "Start camera" affordance, so we gate "board mounted / sink bound" on the
 * player name appearing in the marks strip before the first emit.
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

test.describe('Cricket solo standard playthrough (#661)', { tag: ['@cricket', '@autoscorer'] }, () => {
  test('closing all targets completes the leg and reaches the summary', async ({
    browser,
  }) => {
    test.setTimeout(150000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()'); // board mounts camera-first

    // Home → Cricket → Standard → solo player → start.
    await page.getByRole('button', { name: /Cricket/i }).first().click();
    await page.getByRole('button', { name: /Select Standard/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Crispin');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Wait for the camera-first board to mount (sink bound) before emitting —
    // the "Start camera" affordance is the signal, same as X01. The player name
    // alone renders a frame too early (before the postFrame sink-bind), so
    // emits sent then are silently dropped.
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText(/Crispin/i).first()).toBeVisible({ timeout: 10000 });

    // Turn 1: close 20, 19, 18 with triples (3 marks each).
    await sim(page, "emit('T20')");
    await sim(page, "emit('T19')");
    await sim(page, "emit('T18')");
    await sim(page, 'advance()');

    // Turn 2: close 17, 16, 15.
    await sim(page, "emit('T17')");
    await sim(page, "emit('T16')");
    await sim(page, "emit('T15')");
    await sim(page, 'advance()');

    // Turn 3: close the Bull — DB (2 marks) + DB (clamped to 3). Closing the
    // final target wins the leg → solo game completes immediately.
    await sim(page, "emit('DB')");
    await sim(page, "emit('DB')");

    // The game completes → board auto-navigates to the post-game summary.
    await expect(page.getByText('STATISTICS BREAKDOWN')).toBeVisible({ timeout: 15000 });
    await expect(page.getByRole('button', { name: /DONE/i })).toBeVisible();

    await page.context().close();
  });
});
