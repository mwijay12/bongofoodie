import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const dishName = String(body?.dishName || '').toLowerCase();

    let imageUrl = '/assets/nyama-choma.png';
    if (dishName.includes('samaki') || dishName.includes('fish') || dishName.includes('nazi')) {
      imageUrl = '/assets/samaki-wa-kupaka.png';
    } else if (dishName.includes('pilau') || dishName.includes('rice') || dishName.includes('biryani')) {
      imageUrl = '/assets/pilau-ya-kuku.png';
    } else if (dishName.includes('mishkaki') || dishName.includes('skewer')) {
      imageUrl = '/assets/mishkaki-ya-ngombe.png';
    } else if (dishName.includes('chips') || dishName.includes('mayai') || dishName.includes('zege')) {
      imageUrl = '/assets/chipsi-mayai.png';
    } else if (dishName.includes('pizza')) {
      imageUrl = '/assets/pizza-one.png';
    } else if (dishName.includes('burger')) {
      imageUrl = '/assets/burger-one.png';
    }

    return NextResponse.json({ imageUrl });
  } catch {
    return NextResponse.json({ imageUrl: '/assets/nyama-choma.png' });
  }
}
