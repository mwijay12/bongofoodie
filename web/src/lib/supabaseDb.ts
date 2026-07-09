import { supabase } from './supabase';
import { MenuItem, Category } from '@/types';

export interface GetMenuParams {
  category?: string;
  query?: string;
  limit?: number;
}

export async function getMenu({ category, query, limit }: GetMenuParams = {}): Promise<MenuItem[]> {
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

    if (query) {
      q = q.ilike('name', `%${query}%`);
    }

    if (limit) {
      q = q.limit(limit);
    }

    const { data, error } = await q;
    if (error) throw error;

    let filteredData = data || [];

    if (category && category.toLowerCase() !== 'all') {
      filteredData = filteredData.filter(item => 
        item.categories && (item.categories as any).name.toLowerCase() === category.toLowerCase()
      );
    }

    return filteredData.map(item => ({
      $id: item.id,
      name: item.name,
      description: item.description,
      image_url: item.image_url,
      price: Number(item.price),
      rating: Number(item.rating),
      calories: item.calories,
      protein: item.protein,
      categories: item.categories ? (item.categories as any).name : '',
    }));
  } catch (error: any) {
    console.error('[Supabase getMenu Error]', error);
    throw error;
  }
}

export async function getCategories(): Promise<Category[]> {
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
