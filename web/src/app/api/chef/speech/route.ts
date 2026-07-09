import { NextResponse } from 'next/server';

// Use OpenRouter for TTS with a feminine voice model
const keysString = process.env.EXPO_PUBLIC_OPENROUTER_KEYS || process.env.OPENROUTER_KEYS || '';
const openrouterKeys = keysString
  .split(',')
  .map(k => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

function getNextApiKey(): string | null {
  if (openrouterKeys.length === 0) return null;
  const key = openrouterKeys[currentKeyIndex];
  currentKeyIndex = (currentKeyIndex + 1) % openrouterKeys.length;
  return key;
}

// Use a feminine TTS model via OpenRouter
// Options: "gpt-4o-mini-tts" (OpenAI), "synthesia-tts", etc.
const TTS_MODEL = 'gpt-4o-mini-tts';

async function generateSpeechFromOpenRouter(text: string, retryCount = 0): Promise<Response> {
  const apiKey = getNextApiKey();
  if (!apiKey) {
    throw new Error('No OpenRouter API keys configured on server.');
  }

  try {
    const response = await fetch(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: TTS_MODEL,
          messages: [
            {
              role: 'user',
              content: text
            }
          ],
          // Request audio output (feminine voice by default in gpt-4o-mini-tts)
          modalities: ['text', 'audio'],
          audio: {
            voice: 'alloy', // feminine voice
            format: 'mp3'
          }
        }),
      }
    );

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`OpenRouter TTS failed with status ${response.status}: ${errText}`);
    }

    return response;
  } catch (error: any) {
    console.error(`[OpenRouter TTS Rotation Warning] Key index ${currentKeyIndex - 1} failed. Error: ${error.message}`);
    
    // Failover to next key
    if (retryCount < openrouterKeys.length) {
      console.log(`[OpenRouter TTS] Retrying with next API key in pool...`);
      return generateSpeechFromOpenRouter(text, retryCount + 1);
    }
    throw error;
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { text } = body;

    if (!text) {
      return NextResponse.json({ error: 'Text to speak is required.' }, { status: 400 });
    }

    const ttsResponse = await generateSpeechFromOpenRouter(text);
    
    // Read audio buffer from the response
    const data = await ttsResponse.json();
    const audioContent = data.choices?.[0]?.audio?.content;

    if (!audioContent) {
      throw new Error('No audio content in OpenRouter response');
    }

    // Convert base64 to buffer
    const audioBuffer = Buffer.from(audioContent, 'base64');

    return new Response(audioBuffer, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Content-Length': audioBuffer.byteLength.toString(),
      },
    });

  } catch (error: any) {
    console.error('[API Speech Server Error]', error);
    // Return a JSON error so the client can fall back to browser speech
    return NextResponse.json({ 
      error: error.message,
      fallback: true 
    }, { status: 500 });
  }
}