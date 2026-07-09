import { NextResponse } from 'next/server';

const keysString = process.env.GEMINI_KEYS || '';
const geminiKeys = keysString
  .split(',')
  .map(k => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

function getNextApiKey(): string | null {
  if (geminiKeys.length === 0) return null;
  const key = geminiKeys[currentKeyIndex];
  currentKeyIndex = (currentKeyIndex + 1) % geminiKeys.length;
  return key;
}

const CUSTOM_DISH_PROMPT = `
Analyze the chat history between the customer and Chef AI. Based on the food options discussed, customize a special meal composition that the restaurant kitchen can build.
Return ONLY a valid JSON object matching the following structure, with no markdown wrappers or additional text:
{
  "name": "A creative Swahili name for the custom dish (e.g. Pilau ya Kuku ya Mzee Special)",
  "description": "A mouth-watering description in mixed Swahili and English detailing why this was created for them.",
  "price": A realistic price in Tanzanian Shillings (number, e.g. 9500),
  "ingredients": ["list", "of", "custom", "ingredients", "and", "toppings"],
  "calories": Estimated calories (number),
  "protein": "Estimated protein weight (string, e.g. 28g)",
  "recipe": "A short sentence in Swahili explaining how the chef will customize it."
}
`;

async function getCustomDishFromGemini(messages: any[], retryCount = 0): Promise<string> {
  const apiKey = getNextApiKey();
  if (!apiKey) throw new Error('No API keys configured.');

  const contents = [
    {
      role: 'user',
      parts: [{ text: `Here is the conversation history:\n${JSON.stringify(messages)}\n\n${CUSTOM_DISH_PROMPT}` }]
    }
  ];

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
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.8,
          }
        }),
      }
    );

    if (!response.ok) {
      throw new Error(`Gemini status: ${response.status}`);
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error('Empty candidate parts');
    return text.trim();
  } catch (error: any) {
    console.error(`[Custom Dish Failover] key failed. Retrying...`, error.message);
    if (retryCount < geminiKeys.length) {
      return getCustomDishFromGemini(messages, retryCount + 1);
    }
    throw error;
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { messages } = body;
    
    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json({ error: 'Messages history is required.' }, { status: 400 });
    }

    const jsonText = await getCustomDishFromGemini(messages);
    const parsedDish = JSON.parse(jsonText);
    
    return NextResponse.json(parsedDish);
  } catch (error: any) {
    console.error('[API Custom Dish Error]', error);
    // Fallback dish if parsing or API fails completely
    const fallback = {
      name: 'Sahani Maalum ya Chef',
      description: 'Customized mix of Swahili chicken stew, kachumbari, and hot chipsi created especially for you.',
      price: 8500,
      ingredients: ['Chipsi', 'Kuku wa Kupaka', 'Kachumbari', 'Pilipili za kukaanga'],
      calories: 580,
      protein: '32g',
      recipe: 'Jikoni watachanganya chipsi na kuku wa kupaka pamoja na kachumbari pembeni.'
    };
    return NextResponse.json(fallback);
  }
}
