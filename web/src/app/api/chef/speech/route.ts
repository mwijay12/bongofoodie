import { NextResponse } from 'next/server';

const keysString = process.env.ELEVENLABS_KEYS || '';
const elevenlabsKeys = keysString
  .split(',')
  .map(k => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

function getNextApiKey(): string | null {
  if (elevenlabsKeys.length === 0) return null;
  const key = elevenlabsKeys[currentKeyIndex];
  currentKeyIndex = (currentKeyIndex + 1) % elevenlabsKeys.length;
  return key;
}

// Default standard voice: Rachel (21m00Tcm4TlvDq8ikWAM)
const VOICE_ID = '21m00Tcm4TlvDq8ikWAM';

async function generateSpeechFromElevenLabs(text: string, retryCount = 0): Promise<Response> {
  const apiKey = getNextApiKey();
  if (!apiKey) {
    throw new Error('No ElevenLabs API keys configured on server.');
  }

  try {
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          model_id: 'eleven_multilingual_v2', // Multilingual supports Swahili pronunciation perfectly!
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          }
        }),
      }
    );

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`ElevenLabs API failed with status ${response.status}: ${errText}`);
    }

    return response;
  } catch (error: any) {
    console.error(`[ElevenLabs Rotation Warning] Key index ${currentKeyIndex - 1} failed. Error: ${error.message}`);
    
    // Failover to next key
    if (retryCount < elevenlabsKeys.length) {
      console.log(`[ElevenLabs Rotation] Retrying with next API key in pool...`);
      return generateSpeechFromElevenLabs(text, retryCount + 1);
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

    const ttsResponse = await generateSpeechFromElevenLabs(text);
    
    // Read audio buffer
    const audioBuffer = await ttsResponse.arrayBuffer();

    return new Response(audioBuffer, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Content-Length': audioBuffer.byteLength.toString(),
      },
    });

  } catch (error: any) {
    console.error('[API Speech Server Error]', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
