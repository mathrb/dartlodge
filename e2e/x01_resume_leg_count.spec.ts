/**
 * End-to-End regression for #663 — resuming an in-progress multi-leg X01 match
 * must NOT inflate the leg count.
 *
 * The X01 engine folds the leg win into the checkout dart AND the use-case layer
 * persists a separate LegCompleted. Cold-load replay (loadedGameState) used to
 * apply both, double-incrementing currentLegIndex (and legsWon). The board hash
 * route carries the gameId (#/game/active/x01/:gameId) and the game lives in
 * IndexedDB, so re-opening the app at that URL re-runs loadedGameState — the
 * resume path. (We navigate to the captured URL rather than page.reload(): a
 * bare reload doesn't restore the deep route on this Flutter-web build.)
 *
 * We win leg 1 of a best-of-2 (board then reads "LEG 2 / 2", i.e.
 * currentLegIndex == 1), re-open, and assert it still reads "LEG 2 / 2" — before
 * the fix the resumed board showed "LEG 3 / 2".
 *
 * Serve sim-enabled web on :6780 (see docs/E2E_REGRESSION.md).
 */

import { test, expect, Browser, Page, Locator } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

async function exposeSemantics(page: Page): Promise<void> {
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  await page.evaluate(() =>
    document.querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  await page.waitForFunction(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    () => !!(window as any).dartlodgeSim, { timeout: 60000 });
}

async function boot(browser: Browser): Promise<Page> {
  const context = await browser.newContext(PIXEL_6A);
  const page = await context.newPage();
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
  await exposeSemantics(page);
  return page;
}

/** Click the LEGS TO WIN "+" — the rightmost small (≤40px) unlabeled button. */
async function incrementLegs(page: Page): Promise<void> {
  const buttons = page.getByRole('button');
  const n = await buttons.count();
  let plus: Locator | null = null;
  let plusX = -1;
  for (let i = 0; i < n; i++) {
    const box = await buttons.nth(i).boundingBox();
    if (box && box.width <= 40 && box.height <= 40 && box.x > plusX) {
      plusX = box.x;
      plus = buttons.nth(i);
    }
  }
  if (!plus) throw new Error('LEGS TO WIN "+" button not found');
  await plus.click({ force: true });
}

/** Solo 301 checkout (180 then T20+T11+D14) through the sim bridge. */
async function autoCheckout301(page: Page): Promise<void> {
  await sim(page, "emit('T20')");
  await sim(page, "emit('T20')");
  await sim(page, "emit('T20')");
  await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
  await sim(page, 'advance()');
  await sim(page, "emit('T20')");
  await sim(page, "emit('T11')");
  await sim(page, "emit('D14')");
}

test.describe('X01 resume leg count', { tag: ['@x01'] }, () => {
  test('re-opening mid-match after winning a leg does not inflate the leg count (#663)', {
    tag: '@autoscorer',
  }, async ({ browser }) => {
    test.setTimeout(150000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await page.getByRole('button', { name: /X01/i }).click();
    await page.getByRole('button', { name: /Select 301/i }).click();

    // Config sheet → LEGS TO WIN 1 → 2 → APPLY.
    await page.getByText(/Double Out/i).first().click({ force: true });
    await expect(page.getByText('LEGS TO WIN')).toBeVisible({ timeout: 10000 });
    await incrementLegs(page);
    await page.getByRole('button', { name: /APPLY/i }).click({ force: true });

    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill('Lena');
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    await page.getByRole('button', { name: /START GAME/i }).click();

    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });

    // Win leg 1 → Next Leg modal → leg 2 starts (currentLegIndex == 1).
    await autoCheckout301(page);
    await expect(page.getByRole('button', { name: /Next Leg/i }))
      .toBeVisible({ timeout: 15000 });
    await page.getByRole('button', { name: /Next Leg/i }).click({ force: true });

    await expect(page.getByText(/LEG\s*2\s*\/\s*2/i)).toBeVisible({ timeout: 15000 });

    // Re-open the app directly at the in-progress board URL (hash route carries
    // the gameId) → a fresh load runs loadedGameState, replaying the persisted
    // log. This is the resume path (closing/reopening mid-match).
    const boardUrl = page.url();
    await page.goto(boardUrl, { waitUntil: 'domcontentloaded' });
    await exposeSemantics(page);

    // Still on leg 2 — NOT "LEG 3 / 2" (the pre-#663 doubled count).
    await expect(page.getByText(/LEG\s*2\s*\/\s*2/i)).toBeVisible({ timeout: 30000 });
    await expect(page.getByText(/LEG\s*3/i)).toHaveCount(0);

    await page.context().close();
  });
});
