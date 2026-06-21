/**
 * Regression: Bob's 27 has a 21st "Double-Bull finale" round (#588 / #621,
 * finding F-001).
 *
 * The bug: the engine ended the drill at round 20 (`roundNum >= 20`), so the
 * Double-Bull finale the in-app rules presuppose ("1437" reachable) was
 * unreachable — max 1287, and there was no round 21 / DB target. The fix
 * (#621) added round 21 targeting the Double Bull, and #629 fixed the round
 * total to /21.
 *
 * This drives a full solo Bob's 27 drill through the sim bridge, hitting the
 * round's double each round so the score never drops to <=0 (which would end
 * the drill early), and asserts:
 *   - round 21 is reached with total "/ 21" and a Double-Bull ("DB") target,
 *   - the drill then completes to the post-game summary.
 * Before the fix the drill ended after round 20 (no round 21 ever shown).
 *
 * Build/serve a RELEASE web build with the sim flag (DDC does not render in
 * headless chromium):
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
 */

import { test, expect, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

async function boot(page: Page) {
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
}

test.describe("Bob's 27 Double-Bull finale (#588)", () => {
  test('solo drill reaches round 21 (DB) and completes', async ({ browser }) => {
    test.setTimeout(180000);
    const context = await browser.newContext(PIXEL_6A);
    const page = await context.newPage();

    await boot(page);
    await sim(page, 'enableAutoScoring()');

    // Home → Practice → Bob's 27.
    await page.getByRole('button', { name: /Practice/i }).click();
    await page.getByRole('button', { name: /Select Bob's 27/i }).click();

    // One player + start.
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Bull588');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await page.waitForTimeout(2000);

    // Rounds 1–20: hit the round's double on all three darts so the score keeps
    // climbing (a whitewashed round subtracts round*2; an empty score ends the
    // drill early). Three hits give a comfortable buffer even if a dart is
    // dropped during a turn transition. The 700ms wait after advance() lets the
    // next round's turn become active before the first dart of that round — else
    // it races the (async) TurnStarted and is dropped (a silent whitewash).
    for (let round = 1; round <= 20; round++) {
      for (let d = 0; d < 3; d++) {
        await sim(page, `emit('D${round}')`);
        await page.waitForTimeout(150);
      }
      await sim(page, 'advance()');
      await page.waitForTimeout(700);
    }

    // The regression assertions: the 21st round exists (total "/ 21") and its
    // target is the Double Bull. Before #588/#621 the drill had already ended.
    await expect(page.getByText(/ROUND 21 \/ 21/i)).toBeVisible({
      timeout: 10000,
    });
    await expect(page.getByText('DB', { exact: true }).first()).toBeVisible({
      timeout: 10000,
    });

    // Round 21: hit the Double Bull, then finish the visit.
    for (let d = 0; d < 3; d++) {
      await sim(page, "emit('DB')");
      await page.waitForTimeout(150);
    }
    await sim(page, 'advance()');

    // The drill completes after the bull round → post-game summary.
    await page.waitForURL('**/post-game/**', { timeout: 15000 });

    await context.close();
  });
});
