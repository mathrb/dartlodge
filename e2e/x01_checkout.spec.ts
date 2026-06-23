/**
 * End-to-End: X01 checkout → win → post-game summary, both input paths.
 *
 * The canonical X01 happy path — finishing a leg on a double (the default
 * double-out strategy) and landing on the post-game summary — was not asserted
 * anywhere before this spec. We cover it twice:
 *   - auto-scoring: darts arrive through the sim bridge (`window.dartlodgeSim`,
 *     lib/core/debug/auto_scorer_sim_bridge_web.dart), turns advanced with the
 *     bridge's `advance()` (= sink.advanceTurn()), exactly the camera path.
 *   - manual entry: darts entered through the real segment grid, turns advanced
 *     with the NEXT control — the input path nothing else exercises.
 *
 * The auto-scoring leg also doubles as the X01 STATS check (#634 etc.): a clean
 * 301 finished in two full 3-dart visits → Avg PPR = 301 / 6 * 3 = 150.5, and
 * the opening 180 lands in the "180s" bucket. We assert on the summary that
 * the board auto-navigates to once the game completes.
 *
 * Serve a sim-enabled web build on :6780 (see docs/E2E_REGRESSION.md):
 *   flutter build web --dart-define=AUTOSCORER_SIM=true --base-href /
 *   python3 -m http.server 6780 -d build/web
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';

// Pixel 6a logical viewport drives the camera-first layout. No isMobile/DPR
// (see x01_auto_score_correction.spec.ts for the rationale).
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

const sim = (page: Page, call: string) =>
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  page.evaluate(`window.dartlodgeSim.${call}`);

/** Boot a fresh context and expose the Flutter semantics tree + sim bridge. */
async function boot(browser: Browser): Promise<Page> {
  const context = await browser.newContext(PIXEL_6A);
  const page = await context.newPage();
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  // CanvasKit populates accessible roles/text only after the semantics
  // placeholder is clicked (see feedback_playwright_flutter_web).
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

/**
 * Start a solo X01 game with the given starting score, in the camera-first
 * (auto-scoring) layout. [scoreLabel] is the "Select NNN" button, [hero] the
 * starting-score text shown on the hero metric.
 */
async function startAutoSolo(
  browser: Browser,
  player: string,
  scoreLabel: RegExp,
  hero: string,
): Promise<Page> {
  const page = await boot(browser);
  await sim(page, 'enableAutoScoring()'); // boards mount camera-first
  await page.getByRole('button', { name: /X01/i }).click();
  await page.getByRole('button', { name: scoreLabel }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click(); // auto-selects
  await page.getByRole('button', { name: /START GAME/i }).click();
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
  await expect(page.getByText(hero).first()).toBeVisible({ timeout: 10000 });
  return page;
}

test.describe('X01 checkout → win → summary', { tag: ['@x01', '@stats'] }, () => {
  test('auto-scoring: double-out checkout completes the game and lands on the summary', {
    tag: '@autoscorer',
  }, async ({ browser }) => {
    test.setTimeout(120000);
    const page = await startAutoSolo(browser, 'Aiden', /Select 301/i, '301');

    // Visit 1: three T20s → 301 - 180 = 121.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });

    // Advance to visit 2 (the camera path's turn boundary).
    await sim(page, 'advance()');

    // Visit 2: T20 (→61) T11 (→28) D14 (→0) — checkout on a double → WIN.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T11')");
    await sim(page, "emit('D14')");

    // The game completes → the board auto-navigates to the post-game summary.
    // The summary footer's DONE button is the deterministic "we got there" proof.
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('STATISTICS BREAKDOWN')).toBeVisible();

    // X01 stats, computed from this exact leg (#634 padded-visit convention does
    // NOT apply — no bust — so all six darts count):
    //   Avg PPR = 301 / 6 * 3 = 150.5
    //   Checkout = 1 / 1 attempt = 100%
    //   Best Out = the 121 finish
    //   180s = 1 (the opening three T20s)
    await expect(page.getByText('AVG PPR').first()).toBeVisible();
    await expect(page.getByText('150.5').first()).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('CHECKOUT').first()).toBeVisible();
    await expect(page.getByText('100%')).toBeVisible();
    await expect(page.getByText('BEST OUT')).toBeVisible();
    await expect(page.getByText('121').first()).toBeVisible();
    await expect(page.getByText('180S')).toBeVisible();

    await page.context().close();
  });

  test('manual entry: double-out checkout via the segment grid wins the game', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    // No auto-scoring → the board renders the manual segment grid (same
    // dart_input_grid_widget the correction sheet uses, so button names carry
    // both the semantic label and the visible label: "Triple 20 20").
    const page = await boot(browser);
    await page.getByRole('button', { name: /X01/i }).click();
    await page.getByRole('button', { name: /Select 301/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Mira');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Manual board is up: the segment grid is on-screen (no camera affordance).
    await expect(page.getByRole('button', { name: 'Triple 20 20', exact: true }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('301').first()).toBeVisible();

    // Visit 1: three T20s → 121, then advance (solo → NEXT ROUND).
    for (let i = 0; i < 3; i++) {
      await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    }
    await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
    // NEXT ROUND pulses to draw attention → not "stable"; force past the gate.
    await page.getByRole('button', { name: /NEXT ROUND/i }).click({ force: true });

    // Visit 2: T20 (→61) T11 (→28) D14 (→0) — checkout on a double.
    await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
    await page.getByRole('button', { name: 'Triple 11 11', exact: true }).click();
    await page.getByRole('button', { name: 'Double 14 14', exact: true }).click();

    // Game completes → post-game summary.
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('STATISTICS BREAKDOWN')).toBeVisible();
    await expect(page.getByText('150.5').first()).toBeVisible();

    await page.context().close();
  });
});
