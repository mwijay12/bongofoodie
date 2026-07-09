export const imageMap: Record<string, string> = {
  chipsiMayai: '/assets/chipsi-mayai.png',
  nyamaChoma: '/assets/nyama-choma.png',
  pilauYaKuku: '/assets/pilau-ya-kuku.png',
  samakiWaKupaka: '/assets/samaki-wa-kupaka.png',
  mishkakiYaNgombe: '/assets/mishkaki-ya-ngombe.png',
  burgerOne: '/assets/burger-one.png',
  burgerTwo: '/assets/burger-two.png',
  pizzaOne: '/assets/pizza-one.png',
  avocado: '/assets/avocado.png',
  bacon: '/assets/bacon.png',
  buritto: '/assets/buritto.png',
  cheese: '/assets/cheese.png',
  coleslaw: '/assets/coleslaw.png',
  cucumber: '/assets/cucumber.png',
  fries: '/assets/fries.png',
  mozarellaSticks: '/assets/mozarella-sticks.png',
  mushrooms: '/assets/mushrooms.png',
  onionRings: '/assets/onion-rings.png',
  onions: '/assets/onions.png',
  tomatoes: '/assets/tomatoes.png',
  salad: '/assets/salad.png',
  emptyState: '/assets/empty-state.png',
  success: '/assets/success.png',
  logo: '/assets/logo.png',
  icon: '/assets/icon.png',
  avatar: '/assets/avatar.png',
  loginGraphic: '/assets/login-graphic.png',
  chefOnboarding: '/assets/chef-onboarding.png',
  food3dIcon: '/assets/food-3d-icon.png',
  food3dIcon2: '/assets/food-3d-icon-2.png',
  food3dIcon3: '/assets/food-3d-icon-3.png',
  aiChefIcon: '/assets/ai-chef-icon.png',
  orangeJuiceIcon: '/assets/orange-juice-icon.png',
  robotChef: '/assets/robot-chef.png',
};

export function hasValidImage(url: string | null | undefined): boolean {
  if (!url) return false;
  if (imageMap[url] || url.startsWith('/assets/')) return true;
  const foundKey = Object.keys(imageMap).find(k => k.toLowerCase() === url.toLowerCase());
  if (foundKey) return true;

  const lowerVal = url.toLowerCase();
  if (
    lowerVal.includes('burger') ||
    lowerVal.includes('pizza') ||
    lowerVal.includes('chipsi') ||
    lowerVal.includes('mayai') ||
    lowerVal.includes('fries') ||
    lowerVal.includes('nyama') ||
    lowerVal.includes('choma') ||
    lowerVal.includes('beef') ||
    lowerVal.includes('steak') ||
    lowerVal.includes('pilau') ||
    lowerVal.includes('kuku') ||
    lowerVal.includes('chicken') ||
    lowerVal.includes('rice') ||
    lowerVal.includes('samaki') ||
    lowerVal.includes('fish') ||
    lowerVal.includes('kupaka') ||
    lowerVal.includes('mishkaki') ||
    lowerVal.includes('kebab') ||
    lowerVal.includes('skewers')
  ) {
    return true;
  }

  if (url.startsWith('https://rkjanbxkgfyjpdcichvy.supabase.co')) {
    return true;
  }

  return false;
}

export function resolveFoodImage(url: string): string {
  if (!url) {
    return '/assets/salad.png';
  }

  if (imageMap[url]) {
    return imageMap[url];
  }

  // Case-insensitive mapping check
  const foundKey = Object.keys(imageMap).find(k => k.toLowerCase() === url.toLowerCase());
  if (foundKey) {
    return imageMap[foundKey];
  }

  // If it's a valid relative/absolute path or URL, return it
  if (url.startsWith('/') || url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // Check if it matches keywords of locally stored food items
  const lowerVal = url.toLowerCase();
  if (lowerVal.includes('burger-one') || lowerVal.includes('burgerone')) {
    return imageMap.burgerOne;
  }
  if (lowerVal.includes('burger-two') || lowerVal.includes('burgertwo')) {
    return imageMap.burgerTwo;
  }
  if (lowerVal.includes('pizza-one') || lowerVal.includes('pizzaone')) {
    return imageMap.pizzaOne;
  }
  if (lowerVal.includes('burger')) {
    return imageMap.burgerOne;
  }
  if (lowerVal.includes('pizza')) {
    return imageMap.pizzaOne;
  }
  if (lowerVal.includes('chipsi') || lowerVal.includes('mayai') || lowerVal.includes('fries')) {
    return imageMap.chipsiMayai;
  }
  if (lowerVal.includes('nyama') || lowerVal.includes('choma') || lowerVal.includes('beef') || lowerVal.includes('steak')) {
    return imageMap.nyamaChoma;
  }
  if (lowerVal.includes('pilau') || lowerVal.includes('kuku') || lowerVal.includes('chicken') || lowerVal.includes('rice')) {
    return imageMap.pilauYaKuku;
  }
  if (lowerVal.includes('samaki') || lowerVal.includes('fish') || lowerVal.includes('kupaka')) {
    return imageMap.samakiWaKupaka;
  }
  if (lowerVal.includes('mishkaki') || lowerVal.includes('kebab') || lowerVal.includes('skewers')) {
    return imageMap.mishkakiYaNgombe;
  }

  // Check if it's a drink/beverage
  const isDrink = lowerVal.includes('drink') || 
                  lowerVal.includes('soda') || 
                  lowerVal.includes('juice') || 
                  lowerVal.includes('water') || 
                  lowerVal.includes('beer') || 
                  lowerVal.includes('wine') || 
                  lowerVal.includes('tea') || 
                  lowerVal.includes('chai') || 
                  lowerVal.includes('coffee') || 
                  lowerVal.includes('kahawa') || 
                  lowerVal.includes('beverage');

  if (isDrink) {
    return '/assets/favicon.png';
  }

  return '/assets/salad.png';
}

