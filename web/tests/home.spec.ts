import { expect, test } from '@playwright/test';

for (const viewport of [{ width: 360, height: 640 }, { width: 430, height: 932 }, { width: 1440, height: 1000 }]) {
  test(`Home fits ${viewport.width}px and previews all dishes`, async ({ page }) => {
    await page.setViewportSize(viewport);
    const errors: string[] = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto('/');
    await expect(page.getByRole('heading', { level: 1 })).toContainText('Karibu.');
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    // The hero is real food photography on a CSS plate. A canvas here would
    // mean the heavy WebGL scene came back: this is the performance contract.
    await expect(page.getByRole('img', { name: /Nyama choma na ugali/i })).toBeVisible();
    expect(await page.locator('canvas').count()).toBe(0);
    for (const name of ['Nyama Choma', 'Chipsi Mayai', 'Zanzibar Pilau']) {
      await expect(page.getByRole('heading', { name, exact: true })).toBeVisible();
    }
    await expect(page.getByRole('link', { name: 'Explore the menu', exact: true })).toHaveAttribute('href', '/search');
    await expect(page.getByRole('link', { name: 'Ask Chef AI' })).toHaveAttribute('href', '/chef-ai');
    await expect.poll(() => page.locator('main img').evaluateAll(images => images.every(image => (image as HTMLImageElement).complete && (image as HTMLImageElement).naturalWidth > 0))).toBe(true);
    expect(errors).toEqual([]);
  });
}

test('top navigation drops Home and the empty Flutter preview tab', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto('/');
  const nav = page.getByRole('banner');
  await expect(nav.getByRole('link', { name: 'Search', exact: true })).toHaveAttribute('href', '/search');
  await expect(nav.getByRole('link', { name: 'Chef AI', exact: true })).toHaveAttribute('href', '/chef-ai');
  await expect(nav.getByRole('link', { name: 'Home', exact: true })).toHaveCount(0);
  await expect(nav.getByRole('link', { name: 'Flutter App', exact: true })).toHaveCount(0);
});

test('the real Flutter APK is downloadable from the footer', async ({ page, request }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto('/');
  const download = page.getByRole('contentinfo').getByRole('link', { name: 'Download APK' });
  await expect(download).toBeVisible();
  const href = await download.getAttribute('href');
  expect(href).toMatch(
    /^https:\/\/github\.com\/[^/]+\/[^/]+\/releases\/download\/[^/]+\/app-release\.apk$/,
  );

  // A hand-maintained tag can drift from what is actually published, which would
  // hand every visitor a 404. Ask the releases API whether that exact asset
  // exists, reading the repo and tag straight out of the page's own URL so a
  // repo rename or release bump cannot make this pass against a stale copy.
  const [, owner, name, tag] = href!.match(
    /^https:\/\/github\.com\/([^/]+)\/([^/]+)\/releases\/download\/([^/]+)\//,
  )!;
  const release = await request.get(
    `https://api.github.com/repos/${owner}/${name}/releases/tags/${tag}`,
    { headers: { Accept: 'application/vnd.github+json' } },
  );
  expect(release.status()).toBe(200);
  const asset = (await release.json()).assets.find(
    (candidate: { name: string }) => candidate.name === 'app-release.apk',
  );
  expect(asset).toBeTruthy();
  expect(asset.state).toBe('uploaded');
  expect(asset.browser_download_url).toBe(href);
});


test('headlines use the editorial face while UI copy stays legible sans', async ({ page }) => {
  await page.goto('/');
  const [heading, body] = await page.evaluate(() => [
    getComputedStyle(document.querySelector('h1')!).fontFamily,
    getComputedStyle(document.body).fontFamily,
  ]);
  expect(heading).not.toBe(body);
  expect(heading.toLowerCase()).toContain('serif');
  expect(body.toLowerCase()).toContain('sans-serif');
});

test('reduced motion still renders the hero and the trivia works', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toContainText('Karibu.');
  // The CSS steam/marquee must not run, but the content must still be there.
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

test('every support contact is real and clickable', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto('/');

  const footer = page.getByRole('contentinfo');
  await expect(footer.getByRole('link', { name: 'info@tanzaniareach.com' })).toHaveAttribute(
    'href',
    'mailto:info@tanzaniareach.com',
  );
  await expect(footer.getByRole('link', { name: '+255 790 942 616' })).toHaveAttribute(
    'href',
    'tel:+255790942616',
  );
  await expect(footer.getByRole('link', { name: 'WhatsApp' })).toHaveAttribute(
    'href',
    'https://wa.me/255790942616',
  );

  // Placeholders that used to sit in the Help & Support sheet. They bounced or
  // rang nowhere, so their absence is the contract.
  const body = await page.locator('body').innerText();
  expect(body).not.toContain('+255 712 345 678');
  expect(body).not.toContain('support@bongofoodie.com');
});

test('menu cards show real artwork and never overlap the dish name', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto('/search');

  // Wait for the client-side menu to arrive.
  const cards = page.locator('article');
  await expect.poll(() => cards.count(), { timeout: 20_000 }).toBeGreaterThan(5);

  // Every dish image must actually load. The drink cards used to fall back to
  // /assets/favicon.png (48x48), which rendered as a black rectangle.
  const broken = await page
    .locator('article img')
    .evaluateAll((images) =>
      images
        .filter((image) => !(image as HTMLImageElement).complete || (image as HTMLImageElement).naturalWidth === 0)
        .map((image) => (image as HTMLImageElement).src),
    );
  expect(broken).toEqual([]);

  // No card may be small enough to be the favicon thumbnail.
  const sizes = await page
    .locator('article img')
    .evaluateAll((images) => images.map((image) => (image as HTMLImageElement).naturalWidth));
  for (const width of sizes) expect(width).toBeGreaterThan(200);

  // The artwork must not sit on top of the heading: the two rects may not
  // intersect. This is the bug from the screenshot.
  const overlap = await cards.first().evaluate((card) => {
    const image = card.querySelector('img')?.getBoundingClientRect();
    const heading = card.querySelector('h3')?.getBoundingClientRect();
    if (!image || !heading) return false;
    return !(
      image.bottom <= heading.top ||
      image.top >= heading.bottom ||
      image.right <= heading.left ||
      image.left >= heading.right
    );
  });
  expect(overlap).toBe(false);
});

test('menu grid never leaves a dead gutter on the right', async ({ page }) => {
  for (const width of [390, 768, 1024, 1440]) {
    await page.setViewportSize({ width, height: 900 });
    await page.goto('/search');
    await expect.poll(() => page.locator('article').count(), { timeout: 20_000 }).toBeGreaterThan(5);
    const gutter = await page.evaluate(() => {
      const cards = Array.from(document.querySelectorAll('article'));
      if (!cards.length) return 9999;
      const widest = Math.max(...cards.map((card) => card.getBoundingClientRect().right));
      return window.innerWidth - widest;
    });
    // A dead gutter wider than a third of the screen means the grid collapsed.
    expect(gutter).toBeLessThan(width / 3);
  }
});

test('brand favicon set and web manifest are wired to the real mark', async ({ page, request }) => {
  await page.goto('/');

  await expect(page.locator('link[rel="icon"][type="image/svg+xml"]')).toHaveAttribute('href', /favicon\.svg/);
  await expect(page.locator('link[rel="manifest"]')).toHaveAttribute('href', '/site.webmanifest');
  await expect(page.locator('link[rel="apple-touch-icon"]')).toHaveAttribute('href', /apple-touch-icon\.png/);
  await expect(page.locator('meta[name="theme-color"]')).toHaveAttribute('content', '#1A100B');

  const viewport = await page.locator('meta[name="viewport"]').getAttribute('content');
  expect(viewport ?? '').not.toContain('user-scalable=no');
  expect(viewport ?? '').not.toContain('maximum-scale=1.0');

  for (const path of [
    '/favicon.svg',
    '/favicon.ico',
    '/favicon-16x16.png',
    '/favicon-32x32.png',
    '/apple-touch-icon.png',
    '/android-chrome-192x192.png',
    '/android-chrome-512x512.png',
    '/site.webmanifest',
  ]) {
    expect((await request.get(path)).status(), path).toBe(200);
  }

  const manifest = await (await request.get('/site.webmanifest')).json();
  expect(manifest.icons.length).toBeGreaterThan(4);
  expect(manifest.icons.some((icon: { src: string }) => icon.src === '/favicon.svg')).toBe(true);
});

test('saved reading size raises small copy without breaking a 360px screen', async ({ page }) => {
  await page.setViewportSize({ width: 360, height: 640 });
  await page.goto('/');

  const tiny = page
    .locator('[class*="text-[9px]"], [class*="text-[10px]"], [class*="text-[11px]"], .text-xs')
    .first();
  expect(await tiny.count()).toBeGreaterThan(0);
  const tinySize = await tiny.evaluate((element) =>
    parseFloat(getComputedStyle(element).fontSize),
  );
  expect(tinySize).toBeGreaterThanOrEqual(14);

  const beforeBodySize = await page.evaluate(() =>
    parseFloat(getComputedStyle(document.body).fontSize),
  );
  const select = page.getByRole('combobox', {
    name: 'Ukubwa wa maandishi / Text size',
  });
  await select.selectOption('larger');

  expect(await page.evaluate(() => document.documentElement.dataset.textSize)).toBe('larger');
  const afterBodySize = await page.evaluate(() =>
    parseFloat(getComputedStyle(document.body).fontSize),
  );
  expect(afterBodySize).toBeGreaterThan(beforeBodySize * 1.2);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);

  await page.reload();
  await expect(
    page.getByRole('combobox', { name: 'Ukubwa wa maandishi / Text size' }),
  ).toHaveValue('larger');
});
