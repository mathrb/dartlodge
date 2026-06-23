/**
 * End-to-End: X01 auto-scorer dart CORRECTION flow, at Pixel 6a resolution.
 *
 * Builds on auto_scorer_sim.spec.ts. The sim bridge (`window.dartlodgeSim`,
 * lib/core/debug/auto_scorer_sim_bridge_web.dart) injects detected darts through
 * the live DartInputSink — exactly where the native YOLO detector emits — so we
 * can drive the camera-first board on web with no camera. The CORRECTION itself
 * is driven through the REAL UI (the prominent dart band → bottom-sheet grid),
 * which is the genuine user flow: the camera over/under-reads a dart and the
 * player taps the slot to fix it. We assert the recomputed remaining score,
 * which is the deterministic proof the correction (rewind tail → re-apply) ran.
 *
 * Build/serve a RELEASE web build with the sim flag (DDC does not render in
 * headless chromium):
 *
 *   flutter build web --dart-define=AUTOSCORER_SIM=true --base-href /
 *   python3 -m http.server 6780 -d build/web
 *
 * "Plusieurs approches" — three correction scenarios, each a distinct code path:
 *   A. over-read → a lower single   (single-dart replace, no tail shift)
 *   B. over-read → MISS             (camera saw a dart that actually missed)
 *   C. first dart of the turn       (rewind + RE-APPLY the two tail darts)
 *
 * Navigation note: Flutter go_router does not change the URL on the setup
 * screens, so we drive by content (roles/text), not waitForURL.
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';

// Pixel 6a: 1080×2400 physical, DPR 2.625 → 412×915 logical (CSS) px, portrait.
// The 412×915 logical viewport is what drives the responsive (camera-first)
// layout. We deliberately do NOT set isMobile/hasTouch (Flutter web's "Enable
// accessibility" placeholder only reacts to the synthetic click in a non-touch
// context) nor deviceScaleFactor (a 2.6× CanvasKit render slows every frame and
// blows the action timeout, without changing layout).
const PIXEL_6A = {
  viewport: { width: 412, height: 915 },
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

/**
 * Boot a fresh Pixel-6a context, enable auto-scoring, and start a solo X01 (501)
 * game in the camera-first layout. Returns the page sitting on the board.
 */
async function startSolo501(browser: Browser, player: string): Promise<Page> {
  const context = await browser.newContext(PIXEL_6A);
  const page = await context.newPage();

  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  // CanvasKit only populates the accessible roles/text after the semantics
  // placeholder is clicked (see feedback_playwright_flutter_web). A real
  // Playwright click is intercepted by <flutter-view>, so dispatch the event.
  await page.evaluate(() =>
    document
      .querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  await page.waitForFunction(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    () => !!(window as any).dartlodgeSim,
    { timeout: 60000 },
  );

  // Auto-scoring on → boards mount camera-first.
  await sim(page, 'enableAutoScoring()');

  await page.getByRole('button', { name: /X01/i }).click();
  await page.getByRole('button', { name: /Select 501/i }).click();
  await page.getByRole('button', { name: /NEW PLAYER/i }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click(); // auto-selects
  await page.getByRole('button', { name: /START GAME/i }).click();

  // Confirm the camera-first layout: only it renders the "Start camera"
  // affordance + the hero metric (starting score 501).
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
  await expect(page.getByText('501').first()).toBeVisible({ timeout: 10000 });

  return page;
}

/**
 * Tap a dart slot in the prominent dart band, then pick a segment from the
 * correction bottom sheet. [segmentName] is the grid button's FULL accessible
 * name — the semantic label plus the visible label, e.g. 'Single 7 7',
 * 'Triple 20 20', 'Miss MISS' (see the input grid's Semantics wrapping).
 */
async function correctDart(
  page: Page,
  slotText: string,
  slotNth: number,
  expectedDartNumber: number,
  segmentName: string,
): Promise<void> {
  // The band slot is an InkWell whose only text is the segment — tap it.
  await page.getByText(slotText, { exact: true }).nth(slotNth).click({ force: true });
  // The bottom sheet header confirms which dart we are editing.
  await expect(page.getByText(`Correct dart ${expectedDartNumber}`))
    .toBeVisible({ timeout: 10000 });
  await page.getByRole('button', { name: segmentName, exact: true }).click();
}

test.describe('X01 auto-scorer dart correction (Pixel 6a, sim bridge)', { tag: ['@x01', '@autoscorer', '@correction'] }, () => {
  test('A. correct an over-read to a lower single recomputes the score', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await startSolo501(browser, 'AliceA');

    // Camera detects T20(60) T19(57) T18(54) → 501 - 171 = 330.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T19')");
    await sim(page, "emit('T18')");
    await expect(page.getByText('330')).toBeVisible({ timeout: 10000 });

    // It was actually a single 7, not T19. Fix dart #2.
    await correctDart(page, 'T19', 0, 2, 'Single 7 7');

    // 501 - 60 - 7 - 54 = 380.
    await expect(page.getByText('380')).toBeVisible({ timeout: 10000 });
    // The band now shows the corrected dart.
    await expect(page.getByText('7', { exact: true }).first()).toBeVisible();

    await page.context().close();
  });

  test('B. correct an over-read to MISS removes its score', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await startSolo501(browser, 'BobB');

    // Camera detects three T20s → 501 - 180 = 321.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await expect(page.getByText('321')).toBeVisible({ timeout: 10000 });

    // The 3rd "dart" actually missed the board. Fix dart #3 → MISS.
    await correctDart(page, 'T20', 2, 3, 'Miss MISS');

    // 501 - 60 - 60 - 0 = 381.
    await expect(page.getByText('381')).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('MISS', { exact: true }).first()).toBeVisible();

    await page.context().close();
  });

  test('C. correcting the first dart re-applies the tail darts', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await startSolo501(browser, 'CarolC');

    // Camera under-read the first dart as a single 20 (should have been T20),
    // then two single 20s → 501 - 60 = 441.
    await sim(page, "emit('20')");
    await sim(page, "emit('20')");
    await sim(page, "emit('20')");
    await expect(page.getByText('441')).toBeVisible({ timeout: 10000 });

    // Fix dart #1 → Triple 20. The use case rewinds darts #2 and #3 and
    // re-applies them after the corrected dart, so the tail must survive.
    await correctDart(page, '20', 0, 1, 'Triple 20 20');

    // 501 - 60 - 20 - 20 = 401 (tail darts preserved).
    await expect(page.getByText('401')).toBeVisible({ timeout: 10000 });
    // The first slot now reads T20; the other two are still 20.
    await expect(page.getByText('T20', { exact: true }).first()).toBeVisible();

    await page.context().close();
  });

  test('D. correct the 2nd dart mid-turn, then throw the 3rd', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await startSolo501(browser, 'DaveD');

    // Only TWO darts detected so far: T20(60) T19(57) → 501 - 117 = 384. The
    // turn is still live (3rd slot empty) — this is the mid-turn case, unlike
    // test A which corrects after all three are in.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T19')");
    await expect(page.getByText('384')).toBeVisible({ timeout: 10000 });

    // Fix dart #2 (T19 → Single 7) while the turn is still open. No tail to
    // re-apply (dart 2 is the last thrown), and the turn must stay live.
    await correctDart(page, 'T19', 0, 2, 'Single 7 7');
    // 501 - 60 - 7 = 434 after the correction.
    await expect(page.getByText('434')).toBeVisible({ timeout: 10000 });

    // Now the camera detects the 3rd dart: T18(54). It must land on the still-
    // open turn after the corrected 2nd dart.
    await sim(page, "emit('T18')");

    // 501 - 60 - 7 - 54 = 380, with the band reading T20 / 7 / T18.
    await expect(page.getByText('380')).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('T18', { exact: true }).first()).toBeVisible();

    await page.context().close();
  });
});
