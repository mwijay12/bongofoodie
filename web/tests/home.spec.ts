import { expect, test } from '@playwright/test';

for (const viewport of [{ width: 360, height: 640 }, { width: 430, height: 932 }, { width: 1440, height: 1000 }]) {
  test(`Home fits ${viewport.width}px and previews all dishes`, async ({ page }) => {
    await page.setViewportSize(viewport);
    const errors: string[] = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto('/');
    await expect(page.getByRole('heading', { level: 1 })).toContainText('Karibu.');
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    const picker = page.getByRole('group', { name: 'Preview a Swahili dish' });
    for (const name of ['Chipsi Mayai', 'Zanzibar Pilau', 'Nyama Choma']) {
      await picker.getByRole('button', { name, exact: true }).click();
      await expect(picker.getByRole('button', { name, exact: true })).toHaveAttribute('aria-pressed', 'true');
      await expect(page.locator('[aria-live="polite"]')).toContainText(name);
    }
    await expect(page.getByRole('link', { name: 'Explore the menu', exact: true })).toHaveAttribute('href', '/search');
    await expect(page.getByRole('link', { name: 'Help me choose' })).toHaveAttribute('href', '/chef-ai');
    await expect.poll(() => page.locator('main img').evaluateAll(images => images.every(image => (image as HTMLImageElement).complete && (image as HTMLImageElement).naturalWidth > 0))).toBe(true);
    expect(errors).toEqual([]);
  });
}

test('keyboard selection, reduced motion and trivia feedback', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  const button = page.getByRole('button', { name: 'Chipsi Mayai', exact: true });
  await button.focus();
  await page.keyboard.press('Enter');
  await expect(button).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('[aria-live="polite"]')).toContainText('Chipsi Mayai');
  expect(await page.locator('h1').evaluate(element => getComputedStyle(element.parentElement!).animationName)).toBe('none');
  const quiz = page.getByRole('region', { name: 'Know your spices?' });
  await quiz.getByRole('button').first().click();
  await expect(quiz.getByRole('status')).toBeVisible();
  await expect(quiz.getByRole('button').first()).toBeDisabled();
  await quiz.getByRole('button', { name: 'Got it' }).click();
  await expect(quiz).toHaveCount(0);
});

test('130 percent text remains within a small screen', async ({ page }) => {
  await page.setViewportSize({ width: 360, height: 640 });
  await page.goto('/');
  await page.addStyleTag({ content: 'html { font-size: 130%; }' });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
});
