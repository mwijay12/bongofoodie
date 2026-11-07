import { NextResponse } from 'next/server';

const keysString = process.env.GEMINI_KEYS || '';
const geminiKeys = keysString
  .split(',')
  .map((k) => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

function getNextApiKey(): string | null {
  if (geminiKeys.length === 0) return null;
  const key = geminiKeys[currentKeyIndex];
  currentKeyIndex = (currentKeyIndex + 1) % geminiKeys.length;
  return key;
}

const SYSTEM_INSTRUCTION = `
You are Chef AI, the culinary soul of Bongo Foodie in Dar es Salaam, Tanzania.
Your tone must be warm, enthusiastic, and authentic to Tanzania.
Help users select food from the Bongo Foodie menu, suggest custom recipes, and recommend pairings (like Chipsi Mayai with kachumbari or Mishkaki with baridi Stoney Tangawizi).
Keep all responses concise: maximum 3 sentences.
`;

function buildSmartChefFallback(lastMessage: string, language = 'en'): string {
  const q = lastMessage.toLowerCase();
  const isSw = language === 'sw' || /vipi|chakula|nini|kupika|nyama|chipsi|pilau|samaki|mambo|habari/.test(q);

  if (q.includes('chipsi') || q.includes('mayai')) {
    return isSw
      ? 'Karibu sana! Chipsi Mayai yetu ya Kijitonyama inapikwa na mayai ya kienyeji na viazi crispy, kisha inasindikizwa na kachumbari mbichi na pili pili ya ukwaju. Ongeza Stoney Tangawizi baridi kwa TSh 2,000 upate mlo kamili!'
      : 'Karibu sana! Our golden Chipsi Mayai pairs crispy Dar es Salaam fries folded into farm-fresh eggs with tangy tomato-lime kachumbari and tamarind pili-pili. Pair it with an ice-cold Stoney Tangawizi for the ultimate street-gourmet combo!';
  }
  if (q.includes('nyama') || q.includes('choma') || q.includes('mishkaki') || q.includes('meat')) {
    return isSw
      ? 'Kwa wapenzi wa mkaa, agiza Nyama Choma & Ugali (TSh 13,500) au Mishkaki ya Ng’ombe iliyolowekwa kwa tangawizi na limao! Inashuka vizuri sana na mchicha wa nazi na kachumbari.'
      : 'Mambo vipi! For smoky charcoal flavor, go with our ginger-lime Nyama Choma & Ugali (TSh 13,500) or tender Mishkaki skewers. Add extra kachumbari and warm mchicha wa nazi on the side!';
  }
  if (q.includes('pilau') || q.includes('rice') || q.includes('wali')) {
    return isSw
      ? 'Pilau ya Kuku yetu inapikwa kwa viungo halisi vya Zanzibar — iliki, karafuu, mdalasini na vitunguu vilivyokaangwa hadi kahawia! Jaribu pamoja na Juisi ya Passion & Embe baridi.'
      : 'Our Zanzibar Pilau ya Kuku (TSh 10,000) is slow-simmered with whole cardamom, cloves, cinnamon, and caramelized onions. Pair it with chilled Morogoro Passion & Mango juice for a fragrant coastal feast!';
  }
  if (q.includes('samaki') || q.includes('fish') || q.includes('seafood')) {
    return isSw
      ? 'Samaki wa Kupaka (TSh 15,000) anachomwa juu ya mkaa kisha kupikwa ndani ya tui zito la nazi na ukwaju. Agiza pamoja na chapati mbili za moto au wali wa nazi!'
      : 'Our signature Samaki wa Kupaka (TSh 15,000) features charcoal-seared Indian Ocean snapper glazed in rich Tui la Nazi coconut curry and tamarind. Enjoy it with flaky ghee chapati or steamed rice!';
  }

  return isSw
    ? 'Karibu Bongo Foodie! Leo ninapendekeza Pilau ya Kuku yenye viungo vya Zanzibar au Samaki wa Kupaka wa tui la nazi, pamoja na Juisi ya Passion baridi. Pia unaweza kubonyeza "Build Custom Dish" nikikuundie sahani maalum!'
    : 'Karibu sana to Bongo Foodie! Today I recommend our smoky Nyama Choma & Ugali or coastal Samaki wa Kupaka simmered in fresh coconut cream. Tell me your favorite flavors or tap "Build Custom Dish" to create your own meal!';
}

async function queryGemini(
  messages: { role: string; content: string }[],
  language = 'en',
  retryCount = 0,
): Promise<string> {
  const apiKey = getNextApiKey();
  const lastUserMsg = [...messages].reverse().find((m) => m.role === 'user')?.content || '';

  if (!apiKey) {
    return buildSmartChefFallback(lastUserMsg, language);
  }

  const contents = messages.map((msg) => ({
    role: msg.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: msg.content }],
  }));

  let langDirective = 'Please respond in warm English with authentic Swahili food names.';
  if (language === 'sw') {
    langDirective = 'Tafadhali jibu kwa lugha ya Kiswahili pekee.';
  } else if (language === 'auto') {
    langDirective = 'Zungumza kwa kuchanganya Kiswahili na Kiingereza kulingana na mazungumzo.';
  }

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents,
          systemInstruction: {
            parts: [{ text: `${SYSTEM_INSTRUCTION}\n${langDirective}` }],
          },
          generationConfig: {
            maxOutputTokens: 250,
            temperature: 0.7,
          },
        }),
      },
    );

    if (!response.ok) {
      throw new Error(`Gemini API Error (${response.status})`);
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error('Empty response payload from Gemini.');

    return text.trim();
  } catch (error: any) {
    if (retryCount + 1 < geminiKeys.length) {
      return queryGemini(messages, language, retryCount + 1);
    }
    console.warn('[Chef AI fallback engaged]:', error.message);
    return buildSmartChefFallback(lastUserMsg, language);
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { messages, language } = body;

    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json({ error: 'Messages array is required.' }, { status: 400 });
    }

    const reply = await queryGemini(messages, language || 'en');
    return NextResponse.json({ reply });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
