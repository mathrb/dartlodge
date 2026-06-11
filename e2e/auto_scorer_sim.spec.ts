/**
 * End-to-End: auto-scorer camera-first flow, driven by the sim bridge.
 *
 * The camera + YOLO are Android-native only, so on web the camera-first layout
 * renders but produces no dart detections. Build/serve the web app with the sim
 * flag so `window.dartlodgeSim` is exposed
 * (lib/core/debug/auto_scorer_sim_bridge_web.dart). Serve a RELEASE build
 * statically on :6780 (a DDC `flutter run -d web-server` build does not render
 * in headless chromium):
 *
 *   flutter build web --dart-define=AUTOSCORER_SIM=true --base-href /
 *   python3 -m http.server 6780 -d build/web   # or any static server
 *
 * Hooks: enableAutoScoring() | emit('T20') | advance(). This is the smoke proof
 * + template for the per-game camera-first suites. It mocks POST-detection (the
 * DartInputSink); it does not exercise the native tracker.
 *
 * Navigation note: Flutter go_router does not change the URL path for the
 * setup screens (only the board uses a `/#/...` hash route), so this drives by
 * content (roles/text), not `waitForURL`.
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

    // 1. Load; wait for the Flutter view, expose the semantics tree (CanvasKit
    //    only populates accessible roles/text after this), and wait for the
    //    sim bridge to register.
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    await page.evaluate(() =>
      document.querySelector('flt-semantics-placeholder')
        ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
    await page.waitForFunction(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      () => !!(window as any).dartlodgeSim,
      { timeout: 60000 },
    );

    // 2. Turn auto-scoring on → the board renders camera-first when it mounts.
    await sim(page, 'enableAutoScoring()');

    // 3. Start a solo X01 (501) game. Drive by content (no URL change on these
    //    screens). A fresh context has an empty roster, so create the player.
    await page.getByRole('button', { name: /X01/i }).click();
    await page.getByRole('button', { name: /Select 501/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill(PLAYER);
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click(); // auto-selects
    await page.getByRole('button', { name: /START GAME/i }).click();

    // 4. Confirm the camera-first layout (not the manual segment grid): only it
    //    renders the camera overlay's "Start camera" affordance.
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });
    // Hero metric shows the starting score (also in the metadata bar → .first()).
    await expect(page.getByText('501').first()).toBeVisible({ timeout: 10000 });

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
