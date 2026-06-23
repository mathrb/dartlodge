/**
 * End-to-End: Cricket scoring modes — the points mechanic differs per mode and
 * nothing else covers it (#661 follow-up).
 *
 * Re-hitting an already-closed number (overflow marks) scores differently:
 *   - standard:   the THROWER scores the overflow points.
 *   - cut-throat: the points go to OPPONENTS who haven't closed that number.
 *   - no-score:   no points at all (pure race to close).
 *
 * We assert the points-attribution directly mid-turn (a triple on a freshly
 * closed 20 overflows 3 marks → 3 × 20 = 60), reading the per-player score from
 * the camera-first marks strip by row geometry (CanvasKit exposes a flat
 * semantics tree, so there's no DOM nesting to scope by).
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

/** Home → Cricket → [variant tile] → create [players] → START → board mounted. */
async function startCricket(
  page: Page,
  variant: RegExp,
  players: string[],
): Promise<void> {
  await sim(page, 'enableAutoScoring()');
  await page.getByRole('button', { name: /Cricket/i }).first().click();
  await page.getByRole('button', { name: variant }).click();
  for (const p of players) {
    await page.getByRole('button', { name: /NEW PLAYER/i }).click();
    await page.getByRole('textbox', { name: /Player name/i }).fill(p);
    await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  }
  await page.getByRole('button', { name: /START GAME/i }).click();
  // Camera-first board mounted (sink bound) once "Start camera" shows.
  await expect(page.getByRole('button', { name: /Start camera/i }))
    .toBeVisible({ timeout: 15000 });
}

/**
 * Read the numeric score sitting on the same row as [name] in the marks strip,
 * matched by vertical centre (no DOM nesting in CanvasKit). Returns the text.
 */
async function scoreForPlayer(page: Page, name: string): Promise<string | null> {
  const nameBox = await page.getByText(new RegExp(name, 'i')).first().boundingBox();
  if (!nameBox) return null;
  const nameMid = nameBox.y + nameBox.height / 2;
  const nums = page.getByText(/^\d+$/);
  const n = await nums.count();
  let best: string | null = null;
  let bestDist = 24; // must be within ~one row
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

test.describe('Cricket scoring modes', { tag: ['@cricket', '@autoscorer'] }, () => {
  test('standard: the thrower scores overflow on a closed number', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCricket(page, /Select Standard/i, ['Sam', 'Theo']);

    // Sam: T20 closes 20 (3 marks, 0 overflow), then T20 overflows 3 → 3×20 = 60
    // points to Sam (standard).
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");

    await expect.poll(() => scoreForPlayer(page, 'Sam'), { timeout: 10000 })
      .toBe('60');
    expect(await scoreForPlayer(page, 'Theo')).toBe('0');

    await page.context().close();
  });

  test('cut-throat: overflow points go to the opponent, not the thrower', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCricket(page, /Select Cut Throat/i, ['Uma', 'Vince']);

    // Uma closes 20 then overflows 3 → in cut-throat the 60 points are dealt to
    // Vince (who hasn't closed 20); Uma stays at 0.
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");

    await expect.poll(() => scoreForPlayer(page, 'Vince'), { timeout: 10000 })
      .toBe('60');
    expect(await scoreForPlayer(page, 'Uma')).toBe('0');

    await page.context().close();
  });

  test('no-score: re-hitting a closed number scores nothing', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startCricket(page, /Select No Score/i, ['Wade', 'Xena']);

    // The exact darts that bank 60 points in Standard: close 20, then overflow
    // a triple. In no-score that overflow scores nothing, so the 60 that the
    // Standard test asserts must NOT appear here. (The same emits are proven to
    // register by the Standard/Cut-throat tests above.)
    await sim(page, "emit('T20')");
    await sim(page, "emit('T20')");

    // Positive anchor first: the darts registered (the prominent band shows
    // them), THEN assert no points were banked — instead of a bare timeout
    // before a negative count, which can pass before the score even renders.
    // (The Standard/Cut-throat tests prove these same emits bank 60.)
    await expect(page.getByText('T20').first()).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('60', { exact: true })).toHaveCount(0);
    await expect(page.getByText(/Wade/i).first()).toBeVisible();

    await page.context().close();
  });
});
