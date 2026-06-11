/**
 * End-to-End: auto-scorer camera-first flow, driven by the sim bridge.
 *
 * The camera + YOLO are Android-native only, so on web the camera-first layout
 * renders but produces no dart detections. Build/serve the web app with the sim
 * flag so `window.dartlodgeSim` is exposed
 * (lib/core/debug/auto_scorer_sim_bridge_web.dart):
 *
 *   flutter run -d web-server --web-port 6780 --dart-define=AUTOSCORER_SIM=true
 *   # (or: flutter build web --dart-define=AUTOSCORER_SIM=true, served on :6780)
 *
 * Hooks: enableAutoScoring() | emit('T20') | advance(). This is the smoke proof
 * + template for the per-game camera-first suites. It mocks POST-detection (the
 * DartInputSink); it does not exercise the native tracker.
 *
 * NOTE: like the other specs here, this needs a browser that can render Flutter
 * CanvasKit (a real/GPU browser or the deployed build) — Flutter web does not
 * render in a GPU-less headless sandbox.
 */

import { test, expect, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PLAYER = 'Alice';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const sim = (page: Page, call: string) => page.evaluate(`window.dartlodgeSim.${call}`);

test.describe('Auto-scorer camera-first (sim bridge)', () => {
  test('emitting darts updates the camera-first X01 board', async ({ browser }) => {
    const page = await browser.newPage();
    test.setTimeout(120000);

    // 1. Load; wait for the Flutter view (DOM-level), then expose the semantics
    //    tree (Flutter web only populates accessible text after this) and wait
    //    for the sim bridge to register.
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    await page.evaluate(
      () => document.querySelector('flt-semantics-placeholder')?.dispatchEvent(
        new Event('click', { bubbles: true })),
    );
    await page.waitForFunction(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      () => !!(window as any).dartlodgeSim,
      { timeout: 60000 },
    );

    // 2. Turn auto-scoring on → boards render the camera-first layout.
    await sim(page, 'enableAutoScoring()');

    // 3. Start a solo X01 game (mirrors cricket_3players.spec.ts navigation).
    await page.getByRole('button', { name: /X01/i }).click();
    await page.waitForURL('**/variant-selection/x01', { timeout: 10000 });
    await page.getByRole('button', { name: /501/i }).first().click();
    await page.waitForURL('**/player-selection', { timeout: 10000 });

    if (!(await page.getByText(PLAYER).isVisible().catch(() => false))) {
      await page.getByRole('button', { name: /Add Player|Create/i }).first().click();
      await page.getByPlaceholder(/Name/i).fill(PLAYER);
      await page.getByRole('button', { name: /Save|Create|OK/i }).first().click();
      await expect(page.getByText(PLAYER)).toBeVisible({ timeout: 5000 });
    }
    await page.getByLabel(PLAYER).check();
    await page.getByRole('button', { name: /Next|Continue|Start/i }).first().click();

    await page.waitForURL('**/x01/**', { timeout: 10000 });
    await page.waitForTimeout(2000); // board mounts + binds the dart sink

    // 4. Camera-first board shows the starting score as the hero metric.
    await expect(page.getByText('501')).toBeVisible({ timeout: 10000 });

    // 5. Inject three T20s through the sink (= the auto-scorer detected them).
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");

    // 6. The game updated: 501 - 180 = 321 on the hero metric, and the
    //    prominent dart band shows the detected darts.
    await expect(page.getByText('321')).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('T20').first()).toBeVisible({ timeout: 10000 });

    await page.close();
  });
});
