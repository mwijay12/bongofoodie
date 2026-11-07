import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const messages: Array<{ role: string; content: string }> = body?.messages ?? [];
    const lastUserText =
      [...messages].reverse().find((m) => m.role === 'user')?.content ||
      'Swahili grilled specialty';

    const geminiKey = process.env.GEMINI_API_KEY;
    if (geminiKey) {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [
                {
                  role: 'user',
                  parts: [
                    {
                      text: `Compose a custom Tanzanian Swahili dish inspired by "${lastUserText}". Return ONLY JSON with keys: name (string), description (string), price (number in TZS between 6500 and 18500), ingredients (string array), calories (number), protein (string like "36g"), recipe (short string).`,
                    },
                  ],
                },
              ],
              generationConfig: { responseMimeType: 'application/json' },
            }),
          }
        );
        if (res.ok) {
          const json = await res.json();
          const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (rawText) {
            return NextResponse.json(JSON.parse(rawText));
          }
        }
      } catch {
        // Fall through to Showcase Swahili Chef composer
      }
    }

    const lower = lastUserText.toLowerCase();
    if (lower.includes('samaki') || lower.includes('fish') || lower.includes('nazi')) {
      return NextResponse.json({
        name: 'Samaki wa Nazi & Ndizi Mzuzu Royale',
        description:
          'Charcoal-seared Indian Ocean snapper simmered in velvety Tui la Nazi coconut-tamarind glaze with sweet fried plantains.',
        price: 15000,
        ingredients: ['Red Snapper', 'Tui la Nazi', 'Tamarind', 'Ndizi Mzuzu', 'Fresh Lime'],
        calories: 640,
        protein: '39g',
        recipe:
          'Grill marinated snapper over mkaa embers, finish in spiced coconut-tamarind reduction, and plate alongside caramelized plantains.',
      });
    }

    if (lower.includes('pilau') || lower.includes('rice') || lower.includes('biryani')) {
      return NextResponse.json({
        name: 'Zanzibar Spice Pilau & Mishkaki Platter',
        description:
          'Aromatic basmati rice infused with Pemba cloves, whole cardamom, and caramelized shallots topped with beef mishkaki.',
        price: 12500,
        ingredients: ['Basmati Rice', 'Pemba Cloves', 'Cardamom', 'Beef Mishkaki', 'Kachumbari'],
        calories: 690,
        protein: '35g',
        recipe:
          'Caramelize red onions deep golden, bloom whole Zanzibar pilau masala spices, steam with stock, and crown with charcoal mishkaki.',
      });
    }

    return NextResponse.json({
      name: 'Kijitonyama Mkaa Choma Chef Special',
      description: `Flame-grilled Tanzanian prime cuts basted in ginger-garlic lime butter inspired by "${lastUserText.slice(0, 60)}".`,
      price: 13500,
      ingredients: ['Prime Beef / Mbuzi', 'Crushed Ginger & Garlic', 'Fresh Lime', 'Pili-Pili ya Ukwaju', 'Kachumbari'],
      calories: 710,
      protein: '44g',
      recipe:
        'Marinate tender cuts in ginger, garlic, and lime juice, slow-roast over hardwood charcoal, and serve sizzling with fresh kachumbari.',
    });
  } catch {
    return NextResponse.json(
      { error: 'Unable to compose custom dish right now.' },
      { status: 500 }
    );
  }
}
