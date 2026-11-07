// Supabase Edge Function: `chef-ai`
// Deploy with: `supabase functions deploy chef-ai --no-verify-jwt`
// Secrets required in Supabase Dashboard -> Edge Functions -> Secrets:
//   GEMINI_KEYS=key1,key2  (comma-separated pool)
//   SILICONFLOW_KEY=...    (optional, for Flux dish image generation)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function getKeys(envName: string): string[] {
  const raw = Deno.env.get(envName) ?? "";
  return raw.split(",").map((k) => k.trim()).filter(Boolean);
}

let keyCursor = 0;
function nextGeminiKey(): string | null {
  const keys = getKeys("GEMINI_KEYS");
  if (!keys.length) return null;
  const key = keys[keyCursor % keys.length];
  keyCursor = (keyCursor + 1) % keys.length;
  return key;
}

async function callGemini(prompt: string, jsonMode = false): Promise<string> {
  const keys = getKeys("GEMINI_KEYS");
  for (let i = 0; i < Math.max(keys.length, 1); i++) {
    const key = nextGeminiKey();
    if (!key) break;
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${key}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: jsonMode
            ? { responseMimeType: "application/json", temperature: 0.75 }
            : { maxOutputTokens: 260, temperature: 0.7 },
        }),
      },
    );
    if (res.ok) {
      const data = await res.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (text) return text.trim();
    }
  }
  throw new Error("No Gemini keys configured or all keys rate-limited.");
}

async function generateDishImage(dishPrompt: string): Promise<string> {
  const sfKey = Deno.env.get("SILICONFLOW_KEY") ?? "";
  if (sfKey) {
    try {
      const res = await fetch("https://api.siliconflow.cn/v1/images/generations", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${sfKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "black-forest-labs/FLUX.1-schnell",
          prompt: `Overhead gourmet studio photograph of ${dishPrompt}, East African Swahili fine dining presentation, warm natural lighting, 8k`,
          width: 512,
          height: 512,
          num_inference_steps: 4,
        }),
      });
      if (res.ok) {
        const payload = await res.json();
        const url = payload?.images?.[0]?.url ?? payload?.data?.[0]?.url;
        if (url) return url;
      }
    } catch (_) {
      // Fall through to curated photo
    }
  }
  return "https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80";
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const action = body.action ?? "chat";

    if (action === "custom_dish") {
      const description = String(body.description ?? "Nyama choma na ndizi mzuzu");
      const prompt = `
You are Executive Chef AI at Bongo Foodie in Dar es Salaam, Tanzania.
Design an orderable Swahili dish matching: "${description}".
Return ONLY raw JSON with keys:
{
  "name": "Creative Swahili/English dish title (max 4 words)",
  "description": "Appetizing description under 22 words",
  "price": 9500,
  "calories": 620,
  "protein": 34,
  "category": "Swahili Bites | Nyama Choma | Rice & Pilau | Traditional Stews | Vinywaji",
  "customizations": ["Kachumbari Extra", "Pili Pili Kali", "Stoney Tangawizi"]
}`;
      const raw = await callGemini(prompt, true);
      const parsed = JSON.parse(raw.replace(/^```json\s*/i, "").replace(/```$/, "").trim());
      const imageUrl = await generateDishImage(`${parsed.name}, ${parsed.description}`);
      return new Response(JSON.stringify({ ...parsed, imageUrl }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const message = String(body.message ?? "Pendekeza chakula cha jioni");
    const lang = String(body.language ?? "auto");
    const langRule = lang === "sw"
      ? "Jibu kwa Kiswahili fasaha na cha kuvutia cha Tanzania."
      : lang === "en"
      ? "Respond in warm, concise English with authentic Swahili culinary terms."
      : "Respond naturally in the language the customer used (Swahili, English, or Bongo Sheng).";

    const reply = await callGemini(
      `You are Chef AI at Bongo Foodie in Dar es Salaam. ${langRule} Keep your response to at most 3 short, appetizing sentences.\nCustomer: ${message}`,
      false,
    );

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Chef AI error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
