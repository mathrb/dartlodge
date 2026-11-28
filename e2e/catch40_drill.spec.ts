/**
 * Catch 40 drill: scoring table, bust reset, undo across a target boundary,
 * a full 40-target drill, a camera board-clear on a short visit and End Drill.
 *
 * Catch 40 is a solo finishing drill: targets 61..100, up to six darts
 * (two visits of three) per target, double-out. A checkout in 1-2 darts
 * scores 3, in 3 darts 2 (99 in 3 darts is the exception: 3), in 4-6 darts 1,
 * and a failure 0. Rules oracle: docs/games/catch-40.md.
 *
 * The board renders a progress line "Target {t} | Visit {v}/2 | Score {s}",
 * which every assertion here reads. Score only moves when a target is closed
 * (NEXT TARGET, or `advance()` on the sim path), so each closed target asserts
 * its own points.
 *
 * NEXT TARGET and the board menu are animated / overlay nodes, so they are
 * clicked with an element click (see docs/rules/e2e.md and the Flutter-web
 * notes in docs/E2E_REGRESSION.md); the keypad keys take a normal click.
 *
 * Serve a sim-enabled web build on :6780 (see docs/E2E_REGRESSION.md):
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

const sim = (page: Page, call: string) =>
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

/** Home → Practice → Catch 40 → new solo player → start. */
async function startDrill(page: Page, player: string): Promise<void> {
  await page.getByRole('button', { name: /Practice/i }).click();
  await page.getByRole('button', { name: /Select Catch 40/i }).click();
  await page.getByRole('button', { name: /NEW PLAYER/ }).click();
  await page.getByRole('textbox', { name: /Player name/i }).fill(player);
  await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
  await page.getByRole('button', { name: /START GAME/i }).click();
  await expect(progress(page, 61, 1, 0)).toBeVisible({ timeout: 15000 });
}

/** The board's progress line for target [t], visit [v], drill score [s]. */
function progress(page: Page, t: number, v: number, s: number) {
  return page.getByText(`Target ${t} | Visit ${v}/2 | Score ${s}`, { exact: true });
}

/** Manual keypad tap by accessible name ("Double 18 18", "Miss MISS"). */
async function tap(page: Page, name: string): Promise<void> {
  await page.getByRole('button', { name, exact: true }).click();
  await page.waitForTimeout(250);
}

/**
 * NEXT TARGET enables a beat after the closing dart lands; an element click on
 * the still-disabled node is silently dropped, so wait for it first.
 */
async function nextTarget(page: Page): Promise<void> {
  const button = page.getByRole('button', { name: 'NEXT TARGET' });
  await expect(button).toBeEnabled({ timeout: 10000 });
  await button.evaluate((el) => (el as HTMLElement).click());
}

// ── Sim-path checkout solver ─────────────────────────────────────────────

/** Every board segment with its value, in the app's segment format. */
const SEGMENTS: Array<[string, number]> = [
  ...Array.from({ length: 20 }, (_, i): [string, number] => [`${i + 1}`, i + 1]),
  ...Array.from({ length: 20 }, (_, i): [string, number] => [`D${i + 1}`, 2 * (i + 1)]),
  ...Array.from({ length: 20 }, (_, i): [string, number] => [`T${i + 1}`, 3 * (i + 1)]),
  ['SB', 25],
  ['DB', 50],
];
const DOUBLES = SEGMENTS.filter(([s]) => s.startsWith('D') || s === 'DB');

/**
 * Darts that check [t] out in exactly [n] darts (n = 2 or 3), never leaving
 * 1 or less before the final double (so no dart busts or finishes early).
 */
function checkout(t: number, n: 2 | 3): string[] {
  for (const [d, dv] of DOUBLES) {
    if (n === 2) {
      const a = SEGMENTS.find(([, v]) => v === t - dv && t - v >= 2);
      if (a) return [a[0], d];
    } else {
      for (const [a, av] of SEGMENTS) {
        const b = SEGMENTS.find(([, v]) => v === t - dv - av);
        if (b && t - av >= 2 && t - av - b[1] >= 2) return [a, b[0], d];
      }
    }
  }
  throw new Error(`no ${n}-dart checkout for ${t}`);
}

type Plan = { darts: string[]; points: number; success: boolean };

/**
 * A fixed outcome mix over the 40 targets, cycling 2-dart (3 pts), 3-dart
 * (2 pts), 5-dart (1 pt: a missed visit, then a 2-dart finish) and a failed
 * target (6 misses, 0 pts). 99 is forced to a 3-dart finish: the 3-point
 * exception, since 99 has no 2-dart checkout.
 */
function planFor(t: number): Plan {
  const miss3 = ['MISS', 'MISS', 'MISS'];
  if (t === 99) return { darts: checkout(t, 3), points: 3, success: true };
  switch ((t - 61) % 4) {
    case 0: return { darts: checkout(t, 2), points: 3, success: true };
    case 1: return { darts: checkout(t, 3), points: 2, success: true };
    case 2: return { darts: [...miss3, ...checkout(t, 2)], points: 1, success: true };
    default: return { darts: [...miss3, ...miss3], points: 0, success: false };
  }
}

test.describe('Catch 40 drill', { tag: ['@catch40'] }, () => {
  test('manual entry: scoring table, bust reset and a failed target', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startDrill(page, 'C40manual');

    // 61 in 2 darts (SB + D18) → 3 pts.
    await tap(page, 'Single Bull 25 BULL');
    await tap(page, 'Double 18 18');
    await nextTarget(page);
    await expect(progress(page, 62, 1, 3)).toBeVisible({ timeout: 10000 });

    // 62 in 3 darts (20, 10, D16) → 2 pts.
    await tap(page, 'Single 20 20');
    await tap(page, 'Single 10 10');
    await tap(page, 'Double 16 16');
    await nextTarget(page);
    await expect(progress(page, 63, 1, 5)).toBeVisible({ timeout: 10000 });

    // 63: 20 (43 left), T20 busts → back to 63, then 3 (60 left). Visit 2
    // opens on its own; 20, D20 checks out on the 5th dart → 1 pt. Without the
    // bust reset the D20 would not check out and the target would not close.
    await tap(page, 'Single 20 20');
    await tap(page, 'Triple 20 20');
    await tap(page, 'Single 3 3');
    await expect(progress(page, 63, 2, 5)).toBeVisible({ timeout: 10000 });
    await tap(page, 'Single 20 20');
    await tap(page, 'Double 20 20');
    await nextTarget(page);
    await expect(progress(page, 64, 1, 6)).toBeVisible({ timeout: 10000 });

    // 64: six misses → 0 pts, still moves on.
    for (let i = 0; i < 6; i++) await tap(page, 'Miss MISS');
    await nextTarget(page);
    await expect(progress(page, 65, 1, 6)).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('undo after NEXT TARGET reopens the target and removes its points', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startDrill(page, 'C40undo');

    // 61 in 2 darts → 3 pts.
    await tap(page, 'Single Bull 25 BULL');
    await tap(page, 'Double 18 18');
    await nextTarget(page);
    await expect(progress(page, 62, 1, 3)).toBeVisible({ timeout: 10000 });

    // 62 in 2 darts (T14, D10) → 3 more pts.
    await tap(page, 'Triple 14 14');
    await tap(page, 'Double 10 10');
    await nextTarget(page);
    await expect(progress(page, 63, 1, 6)).toBeVisible({ timeout: 10000 });

    // Undo removes the checkout dart: back on 62 with T14 thrown (20 left),
    // and the 3 points of 62 are gone. The re-thrown D10 below checking out
    // proves the 20 left.
    await page.getByRole('button', { name: 'Undo last dart' }).click();
    await expect(progress(page, 62, 1, 3)).toBeVisible({ timeout: 10000 });

    // Re-throwing the double scores the target again.
    await tap(page, 'Double 10 10');
    await nextTarget(page);
    await expect(progress(page, 63, 1, 6)).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('full drill through the sim bridge: total, targets and the 99 exception', async ({ browser }) => {
    test.setTimeout(300000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await startDrill(page, 'C40sim');

    let score = 0;
    let successes = 0;
    for (let t = 61; t <= 100; t++) {
      const plan = planFor(t);
      for (const dart of plan.darts) {
        await sim(page, `emit('${dart}')`);
        await page.waitForTimeout(150);
      }
      // advance() = board clear: closes a finished or a failed (6-dart) target.
      await sim(page, 'advance()');
      score += plan.points;
      if (plan.success) successes++;
      if (t < 100) {
        await expect(progress(page, t + 1, 1, score)).toBeVisible({ timeout: 10000 });
      }
    }

    // The mix: 10 × 3 + 10 × 2 + 9 × 1 + 99 in 3 darts (3) + 10 × 0.
    expect(score).toBe(62);
    expect(successes).toBe(30);

    await page.waitForURL('**/post-game/**', { timeout: 15000 });
    await expect(page.getByText(`${score} / 120`, { exact: true })).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(`${successes} / 40`, { exact: true })).toBeVisible();
    await expect(page.getByText('ENDED EARLY')).toHaveCount(0);

    await page.context().close();
  });

  test('a camera board-clear after 1 dart counts the visit as 3 darts', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await sim(page, 'enableAutoScoring()');
    await startDrill(page, 'C40clear');

    // 61: T19 leaves 4, then the board is cleared with 2 darts undetected.
    await sim(page, "emit('T19')");
    await page.waitForTimeout(150);
    await sim(page, 'advance()');
    await expect(progress(page, 61, 2, 0)).toBeVisible({ timeout: 10000 });

    // D2 checks out on the 4th dart: 1 point, not the 2-dart 3.
    await sim(page, "emit('D2')");
    await page.waitForTimeout(150);
    await sim(page, 'advance()');
    await expect(progress(page, 62, 1, 1)).toBeVisible({ timeout: 10000 });

    // 62: one dart per visit, cleared each time -> the target fails after
    // two visits (6 darts), not five.
    for (let v = 1; v <= 2; v++) {
      await expect(progress(page, 62, v, 1)).toBeVisible({ timeout: 10000 });
      await sim(page, "emit('1')");
      await page.waitForTimeout(150);
      await sim(page, 'advance()');
    }
    await expect(progress(page, 63, 1, 1)).toBeVisible({ timeout: 10000 });

    await page.context().close();
  });

  test('End Drill from the board menu shows an ENDED EARLY summary', async ({ browser }) => {
    test.setTimeout(120000);
    const page = await boot(browser);
    await startDrill(page, 'C40end');

    // 61 in 2 darts → 3 pts, then end on 62.
    await tap(page, 'Single Bull 25 BULL');
    await tap(page, 'Double 18 18');
    await nextTarget(page);
    await expect(progress(page, 62, 1, 3)).toBeVisible({ timeout: 10000 });

    await page.getByRole('button', { name: 'Show menu' })
      .evaluate((el) => (el as HTMLElement).click());
    await page.getByRole('menuitem', { name: 'End Drill' })
      .evaluate((el) => (el as HTMLElement).click());

    await page.waitForURL('**/post-game/**', { timeout: 15000 });
    await expect(page.getByText('ENDED EARLY')).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('3 / 120', { exact: true })).toBeVisible();
    await expect(page.getByText('1 / 40', { exact: true })).toBeVisible();

    await page.context().close();
  });
});
