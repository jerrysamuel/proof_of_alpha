import { expect, test } from '@playwright/test';

const pages = ['/', '/leaderboard', '/post', '/about', '/call/1', '/caller/0x0000000000000000000000000000000000000001'];

test.describe('Proof of Alpha smoke checks', () => {
  for (const path of pages) {
    test(`${path} has disclaimer and no horizontal scroll`, async ({ page }) => {
      await page.goto(path);
      await expect(page.locator('footer')).toContainText('Not financial advice. Past results do not predict future results. Calls are published by users and are not endorsed.');
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    });
  }
  test('mobile bottom navigation is visible and desktop navigation is used', async ({ page, isMobile }) => {
    await page.goto('/');
    if (isMobile) await expect(page.locator('.bottom-nav')).toBeVisible();
    else await expect(page.locator('.bottom-nav')).toBeHidden();
  });
  test('address search accepts addresses and rejects names', async ({ page }) => {
    await page.goto('/');
    await page.locator('input[name="address"]').fill('0x0000000000000000000000000000000000000001');
    await page.locator('header form button').click();
    await expect(page).toHaveURL(/\/caller\/0x0000000000000000000000000000000000000001/);
    await page.goto('/caller?address=alice.ai');
    await expect(page.getByText('Address only.')).toBeVisible();
  });
});
