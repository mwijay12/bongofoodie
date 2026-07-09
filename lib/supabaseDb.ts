import { supabase } from './supabase';
import { GetMenuParams } from '@/type';

export async function getMenu({ category, query, limit }: GetMenuParams & { limit?: number }) {
  try {
    let q = supabase
      .from('menu')
      .select(`
        id,
        name,
        description,
        image_url,
        price,
        rating,
        calories,
        protein,
        categories (
          id,
          name
        )
      `);

    // If query is provided, search by name
    if (query) {
      q = q.ilike('name', `%${query}%`);
    }

    // If limit is provided, apply limit
    if (limit) {
      q = q.limit(limit);
    }

    const { data, error } = await q;
    if (error) throw error;

    let filteredData = data || [];

    // Filter by category client-side or in the select if possible.
    // Since Supabase doesn't easily filter parents by child relation in simple queries without joins,
    // we can filter the result array if category is specified.
    if (category) {
      filteredData = filteredData.filter(item => 
        item.categories && item.categories.name.toLowerCase() === category.toLowerCase()
      );
    }

    // Map to the shape expected by the UI (translating id -> $id, categories -> categories name)
    return filteredData.map(item => ({
      $id: item.id,
      name: item.name,
      description: item.description,
      image_url: item.image_url,
      price: Number(item.price),
      rating: Number(item.rating),
      calories: item.calories,
      protein: item.protein,
      categories: item.categories ? item.categories.name : '',
    }));
  } catch (error: any) {
    console.error('[Supabase getMenu Error]', error);
    throw error;
  }
}

export async function getCategories() {
  try {
    const { data, error } = await supabase
      .from('categories')
      .select('id, name, description');
    
    if (error) throw error;
    
    return (data || []).map(cat => ({
      $id: cat.id,
      name: cat.name,
      description: cat.description,
    }));
  } catch (error: any) {
    console.error('[Supabase getCategories Error]', error);
    throw error;
  }
}

export async function getTzRegions() {
  try {
    const { data, error } = await supabase
      .from('regions')
      .select('region_name, region_code')
      .order('region_name', { ascending: true });
    
    if (error) throw error;
    return data || [];
  } catch (error: any) {
    console.error('[Supabase getTzRegions Error]', error);
    throw error;
  }
}

export async function getTzDistricts(regionCode: number) {
  try {
    const { data, error } = await supabase
      .from('districts')
      .select('district_name, district_code')
      .eq('region_id', regionCode)
      .order('district_name', { ascending: true });
    
    if (error) throw error;
    return data || [];
  } catch (error: any) {
    console.error('[Supabase getTzDistricts Error]', error);
    throw error;
  }
}

export async function getTzWards(districtCode: number) {
  try {
    const { data, error } = await supabase
      .from('wards')
      .select('ward_name, ward_code')
      .eq('district_id', districtCode)
      .order('ward_name', { ascending: true });
    
    if (error) throw error;
    return data || [];
  } catch (error: any) {
    console.error('[Supabase getTzWards Error]', error);
    throw error;
  }
}

export async function createOrder(orderData: {
  id: string;
  profile_id?: string;
  table_number?: string;
  items: string;
  status?: string;
  total_price: number;
  delivery_location?: string;
  customer_name?: string;
  customer_email?: string;
}) {
  try {
    // Graceful Profile Sync Guard: If profile_id is provided, ensure it exists in the profiles table!
    if (orderData.profile_id) {
      const { data: profile } = await supabase
        .from('profiles')
        .select('id')
        .eq('id', orderData.profile_id)
        .maybeSingle();

      if (!profile) {
        console.warn(`[Profiles Sync Guard] Profile ${orderData.profile_id} was missing in profiles table. Auto-creating profile row.`);
        await supabase.from('profiles').insert({
          id: orderData.profile_id,
          name: orderData.customer_name || 'Bongo Foodie User',
          email: orderData.customer_email || ''
        });
      }
    }

    const { error } = await supabase
      .from('orders')
      .insert(orderData);
    
    if (error) throw error;
    return true;
  } catch (error: any) {
    console.error('[Supabase createOrder Error]', error);
    throw error;
  }
}

export async function getUserOrders(userId: string) {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('profile_id', userId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data || [];
  } catch (error: any) {
    console.error('[Supabase getUserOrders Error]', error);
    throw error;
  }
}

export async function getBranchSettings() {
  try {
    const { data, error } = await supabase
      .from('settings')
      .select('*')
      .eq('id', 'branch_settings')
      .single();
    
    if (error) throw error;
    return data;
  } catch (error: any) {
    console.error('[Supabase getBranchSettings Error]', error);
    return null;
  }
}

export async function toggleFavorite(userId: string, menuId: string) {
  try {
    // Ensure profile exists in profiles table before executing operations
    const { data: profile } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .maybeSingle();

    if (!profile) {
      console.warn(`[Profiles Sync Guard] Profile ${userId} was missing. Auto-creating profile row.`);
      const { data: authUser } = await supabase.auth.getUser();
      await supabase.from('profiles').insert({
        id: userId,
        name: authUser.user?.user_metadata?.full_name || 'Bongo Foodie User',
        email: authUser.user?.email || ''
      });
    }

    const { data, error: checkError } = await supabase
      .from('favorites')
      .select('id')
      .eq('profile_id', userId)
      .eq('menu_id', menuId)
      .maybeSingle();
    
    if (checkError) throw checkError;
    
    if (data) {
      const { error: deleteError } = await supabase
        .from('favorites')
        .delete()
        .eq('profile_id', userId)
        .eq('menu_id', menuId);
      
      if (deleteError) throw deleteError;
      return { favorited: false };
    } else {
      const { error: insertError } = await supabase
        .from('favorites')
        .insert({ profile_id: userId, menu_id: menuId });
      
      if (insertError) throw insertError;
      return { favorited: true };
    }
  } catch (error: any) {
    console.error('[Supabase toggleFavorite Error]', error);
    throw error;
  }
}

export async function getUserFavorites(userId: string) {
  try {
    const { data, error } = await supabase
      .from('favorites')
      .select(`
        menu_id,
        menu (
          id,
          name,
          description,
          image_url,
          price,
          rating,
          calories,
          protein,
          category_id
        )
      `)
      .eq('profile_id', userId);
    
    if (error) throw error;
    
    return (data || []).map((fav: any) => {
      const item = fav.menu;
      return {
        $id: item.id,
        name: item.name,
        description: item.description,
        image_url: item.image_url,
        price: Number(item.price),
        rating: Number(item.rating),
        calories: item.calories,
        protein: item.protein,
        category_id: item.category_id,
      };
    });
  } catch (error: any) {
    console.error('[Supabase getUserFavorites Error]', error);
    throw error;
  }
}

export async function updateMenuRating(menuId: string, rating: number) {
  try {
    const { data, error: fetchError } = await supabase
      .from('menu')
      .select('rating')
      .eq('id', menuId)
      .single();
    
    if (fetchError) throw fetchError;
    
    const currentRating = Number(data.rating || 0);
    const updatedRating = currentRating > 0 ? (currentRating + rating) / 2 : rating;
    
    const { data: updatedData, error: updateError } = await supabase
      .from('menu')
      .update({ rating: parseFloat(updatedRating.toFixed(1)) })
      .eq('id', menuId)
      .select();
      
    if (updateError) throw updateError;
    const finalRatingValue = parseFloat(updatedRating.toFixed(1));
    return updatedData && updatedData.length > 0 ? updatedData[0] : { rating: finalRatingValue };
  } catch (error: any) {
    console.error('[Supabase updateMenuRating Error]', error);
    throw error;
  }
}

