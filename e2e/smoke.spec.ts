/**
 * Smoke: the app boots, CanvasKit renders, and the home screen is interactive.
 * The cheapest "did we break the build / app shell / router" guard — run it
 * (`@smoke`) after any change to main.dart, the router, or the app shell.
 *
 * No sim bridge required; works on any web build served on :6780.
 *   flutter run -d web-server --web-port 6780
 */

import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
const PIXEL_6A = { viewport: { width: 412, height: 915 } };

test.describe('App boots and home renders', { tag: ['@smoke'] }, () => {
  test('home screen exposes the Casual entry point', async ({ browser }) => {
    test.setTimeout(120000);
    const context = await browser.newContext(PIXEL_6A);
    const page = await context.newPage();

    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    // Flutter-web gotcha: click the semantics placeholder to expose the widget
    // tree before any getByRole query (see PLAYWRIGHT_FLUTTER_WEB.md).
    await page.evaluate(() =>
      document
        .querySelector('flt-semantics-placeholder')
        ?.dispatchEvent(new MouseEvent('click', { bubbles: true })));

    // Home is rendered and interactive once its primary entry point is visible.
    await expect(page.getByRole('button', { name: /Casual/i }).first())
      .toBeVisible({ timeout: 30000 });

    await context.close();
  });
});
