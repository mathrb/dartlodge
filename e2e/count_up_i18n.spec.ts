/**
 * Regression: the Count-Up board chrome is localized (#596 / #620, finding
 * F-006). It was the only board whose chrome was hardcoded English — the
 * NEXT/undo/menu strings stayed in English even when the app ran in another
 * language.
 *
 * This launches the app with a French browser locale (the app follows the
 * device/browser locale when no language is stored — resolveAppLocale +
 * locale_provider returning null), plays a solo Count-Up turn through the sim
 * bridge, and asserts the board's NEXT button reads the French "TOUR SUIVANT"
 * (gameNextRound) and the English "NEXT ROUND" is absent. Before #620 the board
 * showed "NEXT ROUND" regardless of locale.
 *
 * Build/serve a RELEASE web build with the sim flag:
 *   flutter build web --dart-define=AUTOSCORER_SIM=true
 *   python3 -m http.server 6780 -d build/web
 */

import { test, expect, Page } from '@playwright/test';

const BASE_URL = 'http://localhost:6780';
// French locale → the whole app (incl. nav) renders in French.
const PIXEL_6A_FR = { viewport: { width: 412, height: 915 }, locale: 'fr-FR' };

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const sim = (page: Page, call: string) =>
  page.evaluate(`window.dartlodgeSim.${call}`);

test.describe('Count-Up board is localized (#596)', { tag: ['@countup', '@i18n'] }, () => {
  test('French locale → board NEXT button reads "TOUR SUIVANT"', async ({
    browser,
  }) => {
    test.setTimeout(120000);
    const context = await browser.newContext(PIXEL_6A_FR);
    const page = await context.newPage();

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

    await sim(page, 'enableAutoScoring()');

    // Home → Casual ("Casual" is a hardcoded category label, locale-independent)
    // → Count-Up (variant select semantic is localized: "Sélectionner Count-Up").
    await page.getByRole('button', { name: /Casual/i }).click();
    await page.getByRole('button', { name: /Sélectionner Count-Up/i }).click();

    // Player selection (French): "NOUVEAU JOUEUR" / "Nom du joueur" /
    // "Créer le joueur" / "DÉMARRER".
    await page.getByRole('button', { name: /NOUVEAU JOUEUR/i }).click();
    await page.getByRole('textbox', { name: /Nom du joueur/i }).fill('Alice596');
    await page.getByRole('button', { name: /Créer le joueur/i }).click();
    await page.getByRole('button', { name: /DÉMARRER/i }).click();

    await page.waitForTimeout(2000);

    // Three darts complete the solo turn → the NEXT control activates.
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(150);
    await sim(page, "emit('T20')");
    await page.waitForTimeout(400);

    // The board chrome is French: NEXT reads "TOUR SUIVANT", never "NEXT ROUND".
    await expect(page.getByText(/TOUR SUIVANT/i).first()).toBeVisible({
      timeout: 10000,
    });
    await expect(page.getByText(/NEXT ROUND/i)).toHaveCount(0);

    await context.close();
  });
});
