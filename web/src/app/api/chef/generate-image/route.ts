import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const siliconflowKey = process.env.SILICONFLOW_KEY || '';
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// Initialize server-side admin client for storage uploads (bypassing RLS)
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { dishName } = body;

    if (!dishName) {
      return NextResponse.json({ error: 'Dish name is required.' }, { status: 400 });
    }

    if (!siliconflowKey) {
      return NextResponse.json({ error: 'SiliconFlow API key is not configured.' }, { status: 500 });
    }

    // Call SiliconFlow FLUX-1.0-Schnell API
    const response = await fetch('https://api.siliconflow.cn/v1/images/generations', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${siliconflowKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'black-forest-labs/FLUX.1-schnell',
        prompt: `Gourmet plating of Swahili food: ${dishName}, professional food photography, overhead shot, studio lighting, hyperrealistic, highly detailed, appetizing, restaurant style`,
        width: 512,
        height: 512,
        num_inference_steps: 4,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`SiliconFlow Image Gen failed: ${errText}`);
    }

    const resData = await response.json();
    const tempUrl = resData.data?.[0]?.url;

    if (!tempUrl) {
      throw new Error('No image URL returned from SiliconFlow API response.');
    }

    // Attempt to download the image and store it permanently in Supabase Storage
    try {
      const imgResponse = await fetch(tempUrl);
      const imgBuffer = await imgResponse.arrayBuffer();

      const fileName = `custom-dish-${Date.now()}-${Math.random().toString(36).substr(2, 5)}.png`;

      // Upload to 'dishes' public bucket
      const { data, error } = await supabaseAdmin.storage
        .from('dishes')
        .upload(fileName, imgBuffer, {
          contentType: 'image/png',
          cacheControl: '3600',
          upsert: true,
        });

      if (error) {
        console.warn('[Supabase Storage Upload Warning]', error.message);
        // Fallback to temporary SiliconFlow URL if bucket or credentials are not fully set
        return NextResponse.json({ imageUrl: tempUrl });
      }

      // Get Public URL
      const { data: { publicUrl } } = supabaseAdmin.storage
        .from('dishes')
        .getPublicUrl(fileName);

      return NextResponse.json({ imageUrl: publicUrl });
    } catch (uploadError: any) {
      console.warn('[Storage upload fallback to temp URL]', uploadError.message);
      return NextResponse.json({ imageUrl: tempUrl });
    }

  } catch (error: any) {
    console.error('[API Image Gen Error] SiliconFlow failed, using gourmet fallback image:', error);
    // Retrieve dishName from request scope if parsed successfully, or default to empty
    let lookupName = '';
    try {
      lookupName = dishName || '';
    } catch(e){}
    const fallbackUrl = getGourmetFallbackImage(lookupName);
    return NextResponse.json({ imageUrl: fallbackUrl });
  }
}

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
