/**
 * Regression: Shanghai multi-player must complete at the end of the final round
 * (#595, finding F-012).
 *
 * The bug: the Shanghai engine's `apply('TurnEnded')` set `isComplete=true` in
 * state but returned a bare EngineResult (outcome=none). `_advanceTurn` gates
 * `GameCompleted` emission — and the post-game navigation — on
 * `outcome == gameCompleted`, so a 2-player game played to the natural end never
 * left the board: it rolled into a phantom "ROUND 8 / 7" with dead inputs
 * (irrecoverable soft-lock). The instant-win Shanghai path (completes via
 * DartThrown) was unaffected, which is why only the natural end broke.
 *
 * This drives a full 2-player, 7-round game through the sim bridge
 * (`window.dartlodgeSim`, lib/core/debug/auto_scorer_sim_bridge_web.dart) — the
 * same DartInputSink the native YOLO detector emits through — and asserts the
 * app reaches the post-game summary (`/post-game/:gameId`). Before the fix this
 * never happens; the game stays stuck on the board.
 *
 * Build/serve a RELEASE web build with the sim flag (DDC does not render in
 * headless chromium):
 *
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';

// Pixel 6a logical viewport (see x01_auto_score_correction.spec.ts for the
// rationale: viewport-only, no isMobile/DPR).
const PIXEL_6A = {
  viewport: { width: 412, height: 915 },
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

test.describe('Shanghai multi-player natural completion (#595)', () => {
  test('2-player, 7-round game reaches the post-game summary', async ({
    browser,
  }) => {
    test.setTimeout(180000);

    const context = await browser.newContext(PIXEL_6A);
    const page = await context.newPage();

    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    // CanvasKit only populates accessible roles/text after the semantics
    // placeholder receives a (synthetic) click — see feedback_playwright_flutter_web.
    await page.evaluate(() =>
      document
        .querySelector('flt-semantics-placeholder')
        ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
    await page.waitForFunction(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      () => !!(window as any).dartlodgeSim,
      { timeout: 60000 },
    );

    // Auto-scoring on → the practice board binds the DartInputSink the sim drives.
    await sim(page, 'enableAutoScoring()');

    // Home → Casual → Shanghai.
    await page.getByRole('button', { name: /Casual/i }).click();
    await page.getByRole('button', { name: /Select Shanghai/i }).click();

    // Player selection: create two players and start.
    for (const name of ['Alice595', 'Bob595']) {
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill(name);
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    }
    await page.getByRole('button', { name: /START GAME/i }).click();

    // Board is up once the sim is bound (auto-scoring path).
    await page.waitForTimeout(2000);

    // Play 7 rounds × 2 players. Each turn = 3 darts then advance(). Scores are
    // irrelevant to the completion path under test, so every dart is a MISS
    // (tie → first competitor wins). The active-player header ("NAME'S TURN")
    // toggles every turn — gating on it before emitting keeps the (async)
    // processDart pipeline from racing the turn transition (emits dropped on a
    // not-yet-active turn would leave dartsThrownInTurn=0, making advance no-op).
    const players = ['ALICE595', 'BOB595'];
    for (let round = 1; round <= 7; round++) {
      for (const name of players) {
        await expect(page.getByText(new RegExp(`${name}.S TURN`, 'i')))
          .toBeVisible({ timeout: 10000 });
        for (let d = 0; d < 3; d++) {
          await sim(page, "emit('MISS')");
          await page.waitForTimeout(200);
        }
        await sim(page, 'advance()');
        await page.waitForTimeout(300);
      }
    }

    // The deterministic proof: the natural end navigates to the post-game
    // summary. Before #595 the board stayed stuck on a phantom round 8.
    await page.waitForURL('**/post-game/**', { timeout: 15000 });

    await context.close();
  });
});
