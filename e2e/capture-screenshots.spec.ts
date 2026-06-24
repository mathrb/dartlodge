/**
 * Screenshot generator for the Play Store listing (NOT a regression test).
 *
 * Drives the sim-enabled web build to capture representative phone screenshots
 * in BOTH light and dark themes (the app follows the system colorScheme).
 * Serve the sim build on :6780 first (see docs/E2E_REGRESSION.md), then:
 *   npx playwright test capture-screenshots --project=chromium --workers=1
 *
 * Output: e2e/screenshots/<theme>-*.png. Each screen is an isolated test so one
 * failure doesn't block the rest. deviceScaleFactor:2 → crisp 824x1830 captures
 * while keeping the phone (412 logical) layout.
 */

import { test, expect, Browser, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const OUT = 'screenshots';
const DPR = 2;

const phone = (theme: 'light' | 'dark') => ({
  viewport: { width: 412, height: 915 },
  deviceScaleFactor: DPR,
  locale: 'en-US',
  colorScheme: theme,
});

const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

async function boot(browser: Browser, theme: 'light' | 'dark'): Promise<Page> {
  const context = await browser.newContext(phone(theme));
  const page = await context.newPage();
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  await page.evaluate(() =>
    document.querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  await page.waitForFunction(
    () => !!(window as any).dartlodgeSim, { timeout: 60000 });
  await page.waitForTimeout(1500);
  return page;
}

for (const theme of ['light', 'dark'] as const) {
  test.describe(`Store screenshots — ${theme}`, () => {
    test.describe.configure({ timeout: 180000 });

    const shot = async (page: Page, name: string) => {
      await page.waitForTimeout(800);
      await page.screenshot({ path: `${OUT}/${theme}-${name}.png` });
    };

    test('home', async ({ browser }) => {
      const page = await boot(browser, theme);
      await shot(page, '01-home');
      await page.context().close();
    });

    test('x01-board', async ({ browser }) => {
      const page = await boot(browser, theme);
      await page.getByRole('button', { name: /X01/i }).click();
      await page.getByRole('button', { name: /Select 501/i }).click();
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill('Luke');
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
      await page.getByRole('button', { name: /START GAME/i }).click();
      await expect(page.getByRole('button', { name: 'Triple 20 20', exact: true }))
        .toBeVisible({ timeout: 15000 });
      for (let i = 0; i < 3; i++) {
        await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
      }
      await shot(page, '02-x01-board');
      await page.context().close();
    });

    test('cricket-board (2 players)', async ({ browser }) => {
      const page = await boot(browser, theme);
      await page.getByRole('button', { name: /Cricket/i }).click();
      await page.getByRole('button', { name: /Standard/i }).first().click({ force: true });
      // Two players → both columns populate.
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill('Luke');
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill('Fallon');
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
      await page.getByRole('button', { name: /START GAME/i }).click();
      await expect(page.getByRole('button', { name: 'Triple 20 20', exact: true }))
        .toBeVisible({ timeout: 15000 });
      // P1: open 20, 19, 18.
      await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
      await page.getByRole('button', { name: 'Triple 19 19', exact: true }).click();
      await page.getByRole('button', { name: 'Triple 18 18', exact: true }).click();
      await page.getByRole('button', { name: /NEXT PLAYER/i }).click({ force: true });
      // P2: open 20, hit 17, 16.
      await page.getByRole('button', { name: 'Triple 20 20', exact: true }).click();
      await page.getByRole('button', { name: 'Triple 17 17', exact: true }).click();
      await page.getByRole('button', { name: 'Double 16 16', exact: true }).click();
      await shot(page, '03-cricket-board');
      await page.context().close();
    });

    test('post-game summary + impact heatmap', async ({ browser }) => {
      const page = await boot(browser, theme);
      await sim(page, 'enableAutoScoring()');
      await page.getByRole('button', { name: /X01/i }).click();
      await page.getByRole('button', { name: /Select 301/i }).click();

      // Config sheet → LEGS TO WIN 1 → 2 → APPLY (2 legs = 12 positioned darts).
      await page.getByText(/Double Out/i).first().click({ force: true });
      await expect(page.getByText('LEGS TO WIN', { exact: true })).toBeVisible({ timeout: 10000 });
      await page.getByRole('button', { name: 'Increase legs to win' }).click({ force: true });
      await page.getByRole('button', { name: /APPLY/i }).click({ force: true });

      await page.getByRole('button', { name: /NEW PLAYER/i }).click();
      await page.getByRole('textbox', { name: /Player name/i }).fill('Luke');
      await page.getByRole('button', { name: /CREATE PLAYER/i }).click();
      await page.getByRole('button', { name: /START GAME/i }).click();
      await expect(page.getByRole('button', { name: /Start camera/i }))
        .toBeVisible({ timeout: 15000 });

      // Heatmap frame: origin = centre, radius 1.0 = double ring, 20 at top
      // (T20 ≈ y -0.6). Cluster around T20; checkout darts add spread.
      const t20 = (): [number, number] => [
        (Math.random() - 0.5) * 0.2,
        -0.6 + (Math.random() - 0.5) * 0.2,
      ];
      const emitPos = (seg: string, xy: [number, number]) =>
        sim(page, `emit('${seg}', ${xy[0].toFixed(3)}, ${xy[1].toFixed(3)})`);
      async function positionedCheckout301() {
        await emitPos('T20', t20());
        await emitPos('T20', t20());
        await emitPos('T20', t20());
        await expect(page.getByText('121').first()).toBeVisible({ timeout: 10000 });
        await sim(page, 'advance()');
        await emitPos('T20', t20());
        await emitPos('T11', [0.32 + Math.random() * 0.1, -0.12]);
        await emitPos('D14', [-0.5 + Math.random() * 0.1, 0.22]);
      }

      await positionedCheckout301();
      await expect(page.getByRole('button', { name: /Next Leg/i }))
        .toBeVisible({ timeout: 15000 });
      await page.getByRole('button', { name: /Next Leg/i }).click({ force: true });
      await expect(page.getByText('301').first()).toBeVisible({ timeout: 15000 });
      await positionedCheckout301();

      await expect(page.getByRole('button', { name: /DONE/i }))
        .toBeVisible({ timeout: 15000 });
      await shot(page, '04-post-game');
      await page.mouse.wheel(0, 1400);
      await page.waitForTimeout(900);
      await shot(page, '05-heatmap');
      await page.context().close();
    });
  });
}
