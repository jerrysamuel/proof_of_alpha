import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './apps/web/e2e',
  timeout: 30_000,
  use: { baseURL: 'http://127.0.0.1:3000', trace: 'retain-on-failure' },
  webServer: { command: 'NEXT_PUBLIC_DEMO=1 pnpm dev', url: 'http://127.0.0.1:3000', reuseExistingServer: true, timeout: 120_000 },
  projects: [
    { name: '360', use: { browserName: 'chromium', viewport: { width: 360, height: 800 }, isMobile: true } },
    { name: '390', use: { browserName: 'chromium', viewport: { width: 390, height: 844 }, isMobile: true } },
    { name: '768', use: { browserName: 'chromium', viewport: { width: 768, height: 1024 }, isMobile: false } },
    { name: '1280', use: { browserName: 'chromium', viewport: { width: 1280, height: 900 }, isMobile: false } },
  ],
});
