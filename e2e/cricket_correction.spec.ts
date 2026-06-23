/**
 * End-to-End: Cricket undo (#661 follow-up).
 *
 * The board UNDO button removes the last dart and re-applies the engine, so a
 * scoring dart's points are rolled back. We close 20 then overflow a triple for
 * 60 points (standard), then undo and assert the score returns to 0 — read from
 * the camera-first marks strip by row geometry.
 *
 * (Band→sheet dart CORRECTION on cricket — incl. the #590 crazy closed-target
 * case — stays with the open cricket_correction_history fixme gap; see
 * docs/E2E_REGRESSION.md.)
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

async function scoreForPlayer(page: Page, name: string): Promise<string | null> {
  const nameBox = await page.getByText(new RegExp(name, 'i')).first().boundingBox();
  if (!nameBox) return null;
  const nameMid = nameBox.y + nameBox.height / 2;
  const nums = page.getByText(/^\d+$/);
  const n = await nums.count();
  let best: string | null = null;
  let bestDist = 24;
  for (let i = 0; i < n; i++) {
    const b = await nums.nth(i).boundingBox();
    if (!b) continue;
    const dist = Math.abs(b.y + b.height / 2 - nameMid);
    if (dist < bestDist) {
      bestDist = dist;
      best = (await nums.nth(i).textContent())?.trim() ?? null;
    }
  }
  return best;
}

test.describe('Cricket undo', { tag: ['@cricket', '@autoscorer', '@correction'] }, () => {
  test('undo rolls back a scoring dart', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await page.getByRole('button', { name: /Cricket/i }).first().click();
    await page.getByRole('button', { name: /Select Standard/i }).click();
    for (const p of ['Yan', 'Zoe']) {
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill(p);
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
    }
    await page.getByRole('button', { name: /START GAME/i }).click();
    await expect(page.getByRole('button', { name: /Start camera/i }))
      .toBeVisible({ timeout: 15000 });

    // Yan: close 20 (T20), then overflow a triple → 60 points.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");
    await expect.poll(() => scoreForPlayer(page, 'Yan'), { timeout: 10000 })
      .toBe('60');

    // Undo the scoring dart → points rolled back to 0.
    await page.getByRole('button', { name: /Undo/i }).click({ force: true });
    await expect.poll(() => scoreForPlayer(page, 'Yan'), { timeout: 10000 })
      .toBe('0');

    await page.context().close();
  });
});
