// Premium Resilient Multi-Provider AI Client with Key Rotation & Fallback
import { GeneratedFoodInfo } from "@/type";

// Helper to retrieve and parse key lists from env
const getKeys = (envVar: string): string[] => {
  const value = process.env[envVar] || "";
  if (!value) return [];
  return value.split(",").map((k) => k.trim()).filter((k) => k.length > 0);
};

// Store current key indices for rotation
const keyIndices: Record<string, number> = {
  gemini: 0,
  groq: 0,
  cerebras: 0,
  openrouter: 0,
  siliconflow: 0, // from EXPO_PUBLIC_OLLAMA_KEYS
  elevenlabs: 0,
};

// Provider Fallback Chain for Text Generation
const TEXT_PROVIDERS = ["gemini", "groq", "cerebras", "openrouter", "siliconflow"];

// Fetch API keys from env (standard and Expo-prefixed options supported)
const providersConfig = {
  gemini: {
    keys: getKeys("EXPO_PUBLIC_GEMINI_KEYS").length ? getKeys("EXPO_PUBLIC_GEMINI_KEYS") : getKeys("GEMINI_KEYS"),
    models: ["gemini-2.5-flash", "gemini-1.5-flash"],
  },
  groq: {
    keys: getKeys("EXPO_PUBLIC_GROQ_KEYS").length ? getKeys("EXPO_PUBLIC_GROQ_KEYS") : getKeys("GROQ_KEYS"),
    models: ["llama-3.3-70b-versatile", "llama3-8b-8192"],
  },
  cerebras: {
    keys: getKeys("EXPO_PUBLIC_CEREBRAS_KEYS").length ? getKeys("EXPO_PUBLIC_CEREBRAS_KEYS") : getKeys("CEREBRAS_KEYS"),
    models: ["llama3.1-8b"],
  },
  openrouter: {
    keys: getKeys("EXPO_PUBLIC_OPENROUTER_KEYS").length ? getKeys("EXPO_PUBLIC_OPENROUTER_KEYS") : getKeys("OPENROUTER_KEYS"),
    models: ["meta-llama/llama-3.3-70b-instruct"],
  },
  siliconflow: {
    keys: getKeys("EXPO_PUBLIC_OLLAMA_KEYS").length ? getKeys("EXPO_PUBLIC_OLLAMA_KEYS") : getKeys("OLLAMA_KEYS"),
    models: ["Qwen/Qwen2.5-7B-Instruct"],
  },
  elevenlabs: {
    keys: getKeys("EXPO_PUBLIC_ELEVENLABS_KEYS").length ? getKeys("EXPO_PUBLIC_ELEVENLABS_KEYS") : getKeys("ELEVENLABS_KEYS"),
    voiceId: "21m00Tcm4TlvDq8ikWAM", // Default voice (Rachel)
  }
};

/**
 * Rotates the API key for a given provider and returns the next key.
 */
function rotateKey(provider: string): string {
  const config = providersConfig[provider as keyof typeof providersConfig];
  if (!config || !config.keys.length) {
    throw new Error(`No keys available for AI provider: ${provider}`);
  }
  const currentIndex = keyIndices[provider];
  const nextIndex = (currentIndex + 1) % config.keys.length;
  keyIndices[provider] = nextIndex;
  
  console.warn(`[AI Key Rotator] Rotating ${provider} key from index ${currentIndex} to ${nextIndex}`);
  return config.keys[nextIndex];
}

/**
 * Gets the current API key for a given provider.
 */
function getCurrentKey(provider: string): string {
  const config = providersConfig[provider as keyof typeof providersConfig];
  if (!config || !config.keys.length) {
    throw new Error(`No keys available for AI provider: ${provider}`);
  }
  return config.keys[keyIndices[provider]];
}

// ----------------------------------------------------
// 1. Text Generation Engine (Resilient Fallback Loop)
// ----------------------------------------------------

interface GenerateTextParams {
  prompt: string;
  json?: boolean;
}

export async function generateText(prompt: string, options: GenerateTextParams = { prompt: "" }): Promise<string> {
  const isJson = options.json ?? false;

  // Try each provider in the sequence
  for (const provider of TEXT_PROVIDERS) {
    const config = providersConfig[provider as keyof typeof providersConfig] as any;
    if (!config || !config.keys.length) {
      console.log(`[AI Fallback] Skipping ${provider} (no keys loaded)`);
      continue;
    }

    const maxRetries = config.keys.length;
    let retries = 0;

    while (retries < maxRetries) {
      const apiKey = getCurrentKey(provider);
      try {
        console.log(`[AI Request] Attempting text generation with ${provider} (model: ${config.models[0]})`);
        let responseText = "";

        if (provider === "gemini") {
          const model = config.models[0];
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
          const response = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: isJson ? { responseMimeType: "application/json" } : undefined,
            }),
          });

          if (!response.ok) {
            throw new Error(`Gemini API Error: Status ${response.status} ${response.statusText}`);
          }

          const data = await response.json();
          responseText = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (!responseText) throw new Error("Invalid response format from Gemini");

        } else {
          // OpenAI compatible API call
          let url = "";
          let model = config.models[0];

          if (provider === "groq") {
            url = "https://api.groq.com/openai/v1/chat/completions";
          } else if (provider === "cerebras") {
            url = "https://api.cerebras.ai/v1/chat/completions";
          } else if (provider === "openrouter") {
            url = "https://openrouter.ai/api/v1/chat/completions";
          } else if (provider === "siliconflow") {
            url = "https://api.siliconflow.cn/v1/chat/completions";
          }

          const response = await fetch(url, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${apiKey}`,
            },
            body: JSON.stringify({
              model: model,
              messages: [{ role: "user", content: prompt }],
              response_format: isJson ? { type: "json_object" } : undefined,
            }),
          });

          if (!response.ok) {
            throw new Error(`${provider} API Error: Status ${response.status} ${response.statusText}`);
          }

          const data = await response.json();
          responseText = data.choices?.[0]?.message?.content;
          if (!responseText) throw new Error(`Invalid response format from ${provider}`);
        }

        console.log(`[AI Request] Success with ${provider}`);
        return responseText;

      } catch (err: any) {
        console.error(`[AI Error] ${provider} failed (attempt ${retries + 1}/${maxRetries}): ${err.message}`);
        retries++;
        if (retries < maxRetries) {
          rotateKey(provider); // Try the next key for this provider
        }
      }
    }
  }

  throw new Error("Resilient AI Failure: All LLM providers and keys failed.");
}

// ----------------------------------------------------
// 2. Specific AI Chef Feature Helpers
// ----------------------------------------------------

function getGourmetFallbackImage(foodDescription: string): string {
  const desc = foodDescription.toLowerCase();
  if (desc.includes("pizza")) {
    return "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=80";
  }
  if (desc.includes("burger")) {
    return "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=80";
  }
  if (desc.includes("goat") || desc.includes("nyama") || desc.includes("mishkaki") || desc.includes("meat") || desc.includes("pork") || desc.includes("choma") || desc.includes("mbuzi")) {
    return "https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=80"; // Grilled meat
  }
  if (desc.includes("ugali") || desc.includes("sembe") || desc.includes("fufu")) {
    return "https://images.unsplash.com/photo-1627308595229-7830a5c91f9f?w=500&auto=format&fit=crop&q=80"; // Ugali / Fufu with stew
  }
  if (desc.includes("pilau") || desc.includes("rice") || desc.includes("wali") || desc.includes("biryani")) {
    return "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&auto=format&fit=crop&q=80"; // Rice dish
  }
  if (desc.includes("samaki") || desc.includes("fish") || desc.includes("seafood")) {
    return "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500&auto=format&fit=crop&q=80"; // Fish
  }
  if (desc.includes("chips") || desc.includes("fries") || desc.includes("mayai")) {
    return "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=80"; // Fries
  }
  if (desc.includes("chicken") || desc.includes("kuku")) {
    return "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=500&auto=format&fit=crop&q=80"; // Chicken
  }
  if (desc.includes("drink") || desc.includes("juice") || desc.includes("vinywaji") || desc.includes("soda") || desc.includes("cocktail")) {
    return "https://images.unsplash.com/photo-1497534446932-c925b458314e?w=500&auto=format&fit=crop&q=80"; // Drink
  }
  return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&auto=format&fit=crop&q=80";
}

/**
 * Uses LLM fallback to generate a structured GeneratedFoodInfo object from a description prompt.
 */
export async function generateFood(userDescription: string): Promise<GeneratedFoodInfo> {
  const prompt = `
    You are an elite Tanzanian executive chef specializing in Swahili and East African cuisine.
    CRITICAL: You MUST create a custom dish that matches the user's requested food concept EXACTLY:
    User Request: "${userDescription}".
    
    If the user asks for pizza, make a Swahili-fusion pizza. If they ask for pork or ugali, make a pork or ugali dish. If they ask for fish, make a Samaki dish. NEVER ignore their request or return goats when they ask for pizza.
    
    Respond STRICTLY with a valid, raw JSON object matching the following structure (do not wrap in markdown tags like \`\`\`json, return raw JSON string only):
    {
      "name": "A creative Swahili/English title matching user concept (max 4 words, e.g. 'Ugali Roast Pork')",
      "description": "A mouth-watering description in English detailing the specific user-requested food items and Swahili spices (max 15 words)",
      "price": a realistic price in Tanzanian Shillings (TSh) between 3000 and 20000 (must be a whole number, e.g., 8500),
      "calories": an integer representing calories (e.g. 450),
      "protein": an integer representing grams of protein (e.g. 24),
      "category": "The single most appropriate category name chosen EXACTLY from this list: Swahili Bites, Nyama Choma, Rice & Pilau, Traditional Stews, Vinywaji",
      "customizations": ["Up to 4 realistic toppings or additions that match user concept (e.g. Kachumbari, Pilipili, Coconut Sauce)"]
    }
  `;

  const jsonResponse = await generateText(prompt, { json: true, prompt });
  
  // Clean potential markdown wrapping if present
  let cleanJson = jsonResponse.trim();
  if (cleanJson.startsWith("```")) {
    cleanJson = cleanJson.replace(/^```json\s*/i, "").replace(/```$/, "").trim();
  }

  try {
    const data = JSON.parse(cleanJson);
    // Enforce fallback fields
    return {
      name: data.name || "Swahili Chef's Special",
      description: data.description || "A delicious custom crafted Swahili recipe.",
      price: typeof data.price === "number" ? parseFloat(data.price.toFixed(2)) : 6000,
      calories: typeof data.calories === "number" ? data.calories : 520,
      protein: typeof data.protein === "number" ? data.protein : 22,
      category: data.category || "Swahili Bites",
      customizations: Array.isArray(data.customizations) ? data.customizations : ["Kachumbari Extra"],
    };
  } catch (e) {
    console.error("[AI Parse Error] Failed to parse generated food JSON:", cleanJson);
    throw new Error("Could not parse AI chef response. Please try again.");
  }
}

// ----------------------------------------------------
// 3. SiliconFlow Image Generation (Resilient Key Loop)
// ----------------------------------------------------

export async function generateImage(foodDescription: string): Promise<string> {
  const provider = "siliconflow";
  const config = providersConfig[provider];
  if (!config || !config.keys.length) {
    console.warn("[AI Image Gen] SiliconFlow keys missing, using premium placeholder generator");
    return getGourmetFallbackImage(foodDescription);
  }

  const maxRetries = config.keys.length;
  let retries = 0;

  while (retries < maxRetries) {
    const apiKey = getCurrentKey(provider);
    try {
      console.log(`[AI Image Request] Attempting image gen on SiliconFlow (Flux)`);
      const response = await fetch("https://api.siliconflow.cn/v1/images/generations", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: "black-forest-labs/FLUX.1-schnell",
          prompt: `Gourmet studio food photograph of ${foodDescription}, professional plating on traditional African carved wooden platter or Swahili patterned ceramic plate, warm lighting, natural lighting, high contrast, fine dining, 8k resolution, square crop`,
          width: 512,
          height: 512,
          num_inference_steps: 4,
        }),
      });
      if (!response.ok) {
        throw new Error(`SiliconFlow Image Gen Error: Status ${response.status}`);
      }

      const data = await response.json();
      const imageUrl = data.images?.[0]?.url || data.data?.[0]?.url;
      if (!imageUrl) throw new Error("Image URL missing in SiliconFlow response");

      console.log(`[AI Image Success] Generated: ${imageUrl}`);
      return imageUrl;

    } catch (err: any) {
      console.error(`[AI Image Error] SiliconFlow failed (attempt ${retries + 1}/${maxRetries}): ${err.message}`);
      retries++;
      if (retries < maxRetries) {
        rotateKey(provider);
      }
    }
  }

  // Final fallback to high quality dummy food image
  return getGourmetFallbackImage(foodDescription);
}

// ----------------------------------------------------
// 4. ElevenLabs Voice Generation (Resilient Key Loop)
// ----------------------------------------------------

export async function generateSpeech(text: string): Promise<string> {
  const provider = "elevenlabs";
  const config = providersConfig[provider];
  if (!config || !config.keys.length) {
    console.warn("[AI Voice Engine] ElevenLabs keys missing, voice disabled");
    return "";
  }

  const maxRetries = config.keys.length;
  let retries = 0;

  while (retries < maxRetries) {
    const apiKey = getCurrentKey(provider);
    try {
      console.log(`[AI Voice Request] Attempting ElevenLabs text-to-speech`);
      const url = `https://api.elevenlabs.io/v1/text-to-speech/${config.voiceId}`;
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": apiKey,
        },
        body: JSON.stringify({
          text: text,
          model_id: "eleven_monolingual_v1",
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          },
        }),
      });

      if (!response.ok) {
        throw new Error(`ElevenLabs Error: Status ${response.status}`);
      }

      // Convert audio binary to base64 data URI to play in React Native WebView or client player
      const blob = await response.blob();
      const base64Data = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result as string);
        reader.onerror = reject;
        reader.readAsDataURL(blob);
      });

      console.log(`[AI Voice Success] Generated audio stream`);
      return base64Data; // Returns data:audio/mpeg;base64,...

    } catch (err: any) {
      console.error(`[AI Voice Error] ElevenLabs failed (attempt ${retries + 1}/${maxRetries}): ${err.message}`);
      retries++;
      if (retries < maxRetries) {
        rotateKey(provider);
      }
    }
  }

  return "";
}
