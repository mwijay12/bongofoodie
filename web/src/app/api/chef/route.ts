import { NextResponse } from 'next/server';

// Parse rotated API key pool
const keysString = process.env.GEMINI_KEYS || '';
const geminiKeys = keysString
  .split(',')
  .map(k => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

function getNextApiKey(): string | null {
  if (geminiKeys.length === 0) return null;
  const key = geminiKeys[currentKeyIndex];
  // Rotate index
  currentKeyIndex = (currentKeyIndex + 1) % geminiKeys.length;
  return key;
}

const SYSTEM_INSTRUCTION = `
You are Chef AI, the culinary soul of Bongo Foodie. 
Your tone must be warm, enthusiastic, and authentic to Tanzania.
Speak in a beautiful mix of English and Swahili (Sheng or standard Swahili) to make users feel at home.
Your main job is to help users select food from the Bongo Foodie menu, suggest custom recipes, and recommend pairings (like chipsi mayai with kachumbari or mishkaki with baridi soda).
Keep all responses extremely concise: maximum 3 sentences. Never output long blocks of text unless the user explicitly requests a full recipe.
Avoid default AI-like phrases such as "Here is your request", "Certainly!", "Sure thing", or "As an AI...". State things directly with a warm Swahili touch like "Karibu sana!", "Mambo vipi!", or "Mlo wako tayari!".
`;

async function queryGemini(messages: { role: string; content: string }[], language = 'en', retryCount = 0): Promise<string> {
  const apiKey = getNextApiKey();
  if (!apiKey) {
    throw new Error('No Gemini API keys found in server configuration.');
  }

  // Format messages to Gemini payload format
  const contents = messages.map(msg => ({
    role: msg.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: msg.content }]
  }));

  // Append language-specific directive to the system prompt instructions
  let langDirective = "Please respond strictly in English.";
  if (language === 'sw') {
    langDirective = "Tafadhali jibu kwa lugha ya Kiswahili pekee.";
  } else if (language === 'auto') {
    langDirective = "Zungumza kwa kuchanganya Kiswahili na Kiingereza (Sheng au Swahili/English mix) kulingana na mazungumzo.";
  }

  const CUSTOM_SYSTEM_INSTRUCTION = `${SYSTEM_INSTRUCTION}\n${langDirective}`;

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents,
          systemInstruction: {
            parts: [{ text: CUSTOM_SYSTEM_INSTRUCTION }]
          },
          generationConfig: {
            maxOutputTokens: 250,
            temperature: 0.7,
          }
        }),
      }
    );

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Gemini API Error (Status ${response.status}): ${errText}`);
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      throw new Error('Empty response payload returned from Gemini candidate parts.');
    }

    return text.trim();
  } catch (error: any) {
    console.error(`[Gemini Rotation Warning] Key index ${currentKeyIndex - 1} failed. Error: ${error.message}`);
    
    // Retry with next key up to pool length
    if (retryCount < geminiKeys.length) {
      console.log(`[Gemini Rotation] Attempting failover query with next key index in pool...`);
      return queryGemini(messages, language, retryCount + 1);
    }
    
    throw new Error(`All keys in Gemini key pool failed to return a response: ${error.message}`);
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
    console.error('[API Chef Server Error]', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
