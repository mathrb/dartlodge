/**
 * Regression: a busted X01 visit scores 0 points AND counts as a full 3-dart
 * visit in the three-dart-average denominator (#610 → #622, then #634 / #644,
 * PDC / Wikipedia convention).
 *
 * The bug history: per-game / best / trend PPR once credited a bust's points at
 * full value (#610/#622 → bust = 0 points); then #634 changed the denominator
 * so a sub-3-dart bust is padded to a full 3-dart visit (it is a complete
 * visit). This drives a deterministic solo X01 301 (double-out) game with a
 * 2-dart bust and asserts the post-game "Avg PPR" hero reflects the padded
 * convention.
 *
 * Deterministic scenario (301, double-out, solo):
 *   Turn 1: T20 T20 T20 = 180          → remaining 121   (3 darts)
 *   Turn 2: T20 T20     → 121→61→1 BUST → remaining 121   (2 darts, 0 points)
 *   Turn 3: T20 T11 D14 = 121 checkout → remaining 0      (3 darts) → WIN
 * Numerator (turn scores, bust = 0): 180 + 0 + 121 = 301.
 * Denominator (#634 padded): 3 + 3 + 3 = 9 darts (turn 2's 2 darts padded to 3).
 * Avg = 301 / 9 * 3 = 100.33 → displayed "100.3".
 * (Pre-#634, the actual-darts denominator 8 gives 301/8*3 = 112.9 — so "100.3"
 * is the deterministic proof the bust visit was padded.)
 *
 * Build/serve a RELEASE web build with the sim flag:
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

async function emit(page: Page, seg: string) {
  await sim(page, `emit('${seg}')`);
  await page.waitForTimeout(180);
}

test.describe('X01 PPR busts as a 3-dart visit (#634)', { tag: ['@x01', '@stats'] }, () => {
  test('post-game Avg PPR pads a 2-dart bust to a full visit', async ({
    browser,
  }) => {
    test.setTimeout(150000);
    const context = await browser.newContext(PIXEL_6A);
    const page = await context.newPage();

    await boot(page);
    await sim(page, 'enableAutoScoring()');

    // Home → X01 → 301 → one player → start. (The home category card's
    // accessible name includes its subtitle, so match "X01" as a substring.)
    await page.getByRole('button', { name: /X01/i }).first().click();
    await page.getByRole('button', { name: /Select 301/i }).click();
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Bust634');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await page.waitForTimeout(2000);

    // Turn 1: 180 → remaining 121. Gate on the remaining score so the next
    // turn's darts don't race the (async) TurnStarted.
    await emit(page, 'T20');
    await emit(page, 'T20');
    await emit(page, 'T20');
    await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
    await sim(page, 'advance()');
    await page.waitForTimeout(800);

    // Turn 2: T20 (→61) T20 (→1, BUST). 2 darts, 0 points, reverts to 121.
    await emit(page, 'T20');
    await emit(page, 'T20');
    // The bust raises a `showBust` flag that the board auto-clears after 2s
    // (Future.delayed → dismissBust). The sink's advanceTurn no-ops while
    // showBust is set, so wait out the auto-dismiss before advancing.
    await page.waitForTimeout(2600);
    await sim(page, 'advance()');
    await page.waitForTimeout(800);

    // Turn 3: T20 (→61) T11 (→28) D14 (→0) checkout → WIN.
    await emit(page, 'T20');
    await emit(page, 'T11');
    await emit(page, 'D14');
    await sim(page, 'advance()');

    // Game completes → post-game summary.
    await page.waitForURL('**/post-game/**', { timeout: 15000 });

    // The deterministic proof of the padded-denominator convention (#634):
    // 301 / 9 * 3 = 100.3, NOT 112.9 (actual-darts denominator).
    await expect(page.getByText('100.3').first()).toBeVisible({
      timeout: 10000,
    });
    await expect(page.getByText('112.9')).toHaveCount(0);

    await context.close();
  });
});
