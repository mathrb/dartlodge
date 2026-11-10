/**
 * End-to-End: Around the Clock with three players — undo across a turn
 * boundary, a status-chip correction, and the post-game breakdown.
 *
 * Manual entry (auto-scoring off): the ATC input bar shows one cell per
 * multiplier for the CURRENT player's target (`S-N` / `D-N` / `T-N` + MISS),
 * and the status bar above the board shows the current turn's darts as chips.
 *
 * Script (Standard 1→20):
 *   Round 1  Ana  1, MISS, MISS → NEXT ROUND → undo (back to Ana's 3rd dart)
 *                 → re-throw it as S-2 → target 3
 *            Ben  T-1 → tap the "T1" chip → correct to MISS (target falls back
 *                 to 1) → S-1, MISS → target 2
 *            Cal  MISS ×3
 *   Rounds 2–7    Ana hits her target three times a turn and wins on the 3rd
 *                 dart of round 7 (target 20); Ben and Cal miss.
 *
 * Expected breakdown (the undone dart is gone, the corrected one counts once):
 *   TURNS 7 / 6 / 6 · DARTS 21 / 18 / 18 · LAST TARGET HIT 20 / 1 / 0
 *
 * Serve a sim-enabled web build on :6780 (see docs/E2E_REGRESSION.md).
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

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

/** Board readout "<NAME>'S TURN" + the input bar labelled for [target]. */
async function expectTurn(page: Page, name: string, target: number): Promise<void> {
  await expect(page.getByText(`${name.toUpperCase()}'S TURN`, { exact: true }))
    .toBeVisible({ timeout: 8000 });
  await expect(page.getByText(`S-${target}`, { exact: true }).first())
    .toBeVisible({ timeout: 8000 });
}

/** Tap a cell of the input bar (`S-N` / `D-N` / `T-N` / `MISS`). */
async function tapCell(page: Page, label: string): Promise<void> {
  // A status chip can also be named "MISS"; the input bar's cell comes last.
  await page.getByRole('button', { name: label, exact: true }).last()
    .click({ force: true });
  await page.waitForTimeout(400); // let the async DartThrown settle
}

/** Hit the current target [n] with a single and wait for the bar to relabel. */
async function hit(page: Page, n: number): Promise<void> {
  await tapCell(page, `S-${n}`);
  if (n < 20) {
    // Matched as text: after a turn's 3rd dart the cells are no longer buttons.
    await expect(page.getByText(`S-${n + 1}`, { exact: true }).first())
      .toBeVisible({ timeout: 8000 });
  }
}

/** End the current turn and wait for [nextName]'s turn to start. */
async function nextRound(page: Page, nextName: string): Promise<void> {
  // Only tap once the turn's 3rd dart has landed (no empty chip slot left).
  await expect(page.getByText('dart not thrown')).toHaveCount(0, { timeout: 8000 });
  const next = page.getByRole('button', { name: /NEXT ROUND/i });
  const turn = page.getByText(`${nextName.toUpperCase()}'S TURN`, { exact: true });
  // A tap that races the button's entry animation is dropped, so retry until
  // the next turn shows. An extra tap is harmless: NEXT ROUND is disabled
  // until the new player's first dart.
  await expect(async () => {
    await next.click({ force: true });
    await expect(turn).toBeVisible({ timeout: 2000 });
  }).toPass({ timeout: 15000 });
}

async function missTurn(page: Page, nextName: string): Promise<void> {
  for (let i = 0; i < 3; i++) await tapCell(page, 'MISS');
  await nextRound(page, nextName);
}

test.describe('Around the Clock — multiplayer', { tag: ['@atc', '@correction'] }, () => {
  test('3 players: undo across a turn, chip correction, and the breakdown counts', async ({
    browser,
  }) => {
    test.setTimeout(240000);
    const page = await boot(browser); // no auto-scoring → manual ATC input bar
    await page.getByRole('button', { name: /Practice/i }).click();
    await page.getByRole('button', { name: /Select Around the Clock/i }).click();
    for (const name of ['Ana', 'Ben', 'Cal']) {
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill(name);
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
      await expect(page.getByRole('button', { name: `Remove ${name}` }))
        .toBeVisible({ timeout: 8000 });
    }
    await page.getByRole('button', { name: /START GAME/i }).click();

    // ── Round 1 ──────────────────────────────────────────────────────────────
    await expectTurn(page, 'Ana', 1);
    await hit(page, 1);
    await tapCell(page, 'MISS');
    await tapCell(page, 'MISS');
    await nextRound(page, 'Ben');
    await expectTurn(page, 'Ben', 1);

    // Undo across the turn boundary: back on Ana's turn, her 3rd dart removed.
    await page.getByRole('button', { name: 'Undo last dart' }).click({ force: true });
    await expectTurn(page, 'Ana', 2);
    await hit(page, 2); // replaces the undone MISS
    await nextRound(page, 'Ben');

    // Ben: T-1 advances him, then the chip correction T1 → MISS takes it back.
    await expectTurn(page, 'Ben', 1);
    await tapCell(page, 'T-1');
    await expectTurn(page, 'Ben', 2);
    await page.getByRole('button', { name: 'T1', exact: true }).click({ force: true });
    await expect(page.getByText('Correct dart 1')).toBeVisible({ timeout: 8000 });
    await page.getByRole('button', { name: 'MISS', exact: true }).click();
    await expect(page.getByText('Correct dart 1')).toHaveCount(0, { timeout: 8000 });
    await expectTurn(page, 'Ben', 1);
    await hit(page, 1);
    await tapCell(page, 'MISS');
    await nextRound(page, 'Cal');

    await expectTurn(page, 'Cal', 1);
    await missTurn(page, 'Ana');

    // ── Rounds 2–7: Ana runs 3 → 20, the others miss ─────────────────────────
    let target = 3;
    for (let round = 2; round <= 7; round++) {
      await expectTurn(page, 'Ana', target);
      for (let d = 0; d < 3; d++) await hit(page, target++);
      if (target > 20) break; // dart 3 of round 7 closed 20 → game over
      await nextRound(page, 'Ben');
      await expectTurn(page, 'Ben', 2);
      await missTurn(page, 'Cal');
      await expectTurn(page, 'Cal', 1);
      await missTurn(page, 'Ana');
    }

    // ── Post-game breakdown ──────────────────────────────────────────────────
    await expect(page.getByRole('button', { name: /DONE/i }))
      .toBeVisible({ timeout: 15000 });
    await expect(page.getByText('Around the Clock').first()).toBeVisible();
    await expect(page.getByRole('row', { name: 'CATEGORY Ana WINNER Ben Cal', exact: true }))
      .toBeVisible();
    // TURNS counts real turns (the winner's 7th is the deciding one), DARTS
    // drops the undone dart and counts the corrected one once.
    await expect(page.getByRole('row', { name: 'TURNS 7 6 6', exact: true })).toBeVisible();
    await expect(page.getByRole('row', { name: 'DARTS 21 18 18', exact: true })).toBeVisible();
    await expect(page.getByRole('row', { name: 'LAST TARGET HIT 20 1 0', exact: true })).toBeVisible();

    await page.context().close();
  });
});
