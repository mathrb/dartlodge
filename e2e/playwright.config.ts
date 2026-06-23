import { defineConfig, devices } from '@playwright/test';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// import dotenv from 'dotenv';
// dotenv.config({ path: path.resolve(__dirname, '.env') });

/**
 * See https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './',
  /* Run tests in files in parallel */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['list'],
    ['html', { outputFolder: '../.playwright-cli/test-results' }],
    ['json', { outputFolder: '../.playwright-cli/test-results' }],
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: 'http://localhost:6780',

    /* Pin the locale so the app resolves to English. Specs that target by
     * accessible name / visible text (e.g. x01_match's "Increase legs to win")
     * depend on this — the app follows the browser locale, so an unpinned
     * runner would render another language and the selectors would fail.
     * Specs that need a different locale override it per-context. */
    locale: 'en-US',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    
    /* Record video only on retry */
    video: 'on-first-retry',
    
    /* Record screenshot on failure */
    screenshot: 'only-on-failure',
    
    /* Timeout for each test */
    timeout: 60000,
    
    /* Wait for actions to complete */
    actionTimeout: 10000,
    
    /* Wait for elements to appear */
    expect: {
      timeout: 5000,
    },
    
    /* Viewport size — Pixel 6a logical resolution (portrait), phone-first app.
     * Flutter-web gotcha: set viewport ONLY. Do NOT use devices['Pixel ...']
     * (isMobile:true breaks semantics-placeholder activation; deviceScaleFactor/DPR
     * blows the timeout). Keep isMobile false + DPR 1. Pixel 6a = 1080x2400 @ DPR
     * 2.625 → 412x915 logical px. */
    viewport: { width: 412, height: 915 },
    
    /* User agent for Flutter web */
    userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // Override Desktop Chrome's 1280x720: phone-portrait viewport, but keep
        // isMobile:false + DPR 1 from Desktop Chrome (see viewport note above —
        // mobile device descriptors break Flutter-web semantics/timeout).
        viewport: { width: 412, height: 915 },
        headless: true,
        launchOptions: {
          headless: true,
        }
      },
    },

    // Uncomment to test on Firefox and WebKit
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
  ],

  /* Run your local dev server before starting the tests */
  webServer: {
    command: 'echo "Server should be running on port 6780"',
    url: 'http://localhost:6780',
    timeout: 120000, // 2 minutes to start
    reuseExistingServer: true,
  },
});
