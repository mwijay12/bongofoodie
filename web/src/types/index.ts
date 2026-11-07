export type UserRole = 'customer' | 'waiter' | 'kitchen' | 'admin';

export interface MenuItem {
  $id: string;
  name: string;
  description: string;
  image_url: string;
  price: number;
  rating: number;
  rating_count?: number;
  calories?: number;
  protein?: number;
  prep_time_mins?: number;
  categories?: string;
}

export interface Category {
  $id: string;
  name: string;
  description?: string;
}

export interface Customization {
  id: string;
  name: string;
  price: number;
  type: string;
}

export interface Profile {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role?: UserRole;
  avatar_url?: string;
  updated_at?: string;
  isDemo?: boolean;
}

export interface CartItemType {
  id: string;
  name: string;
  price: number;
  image_url?: string;
  quantity: number;
  customizations?: Customization[];
  isAICreated?: boolean;
  calories?: number;
  protein?: number | string;
  recipe?: string;
}

export interface Order {
  id: string;
  profile_id?: string;
  table_number?: string;
  items: CartItemType[];
  status: 'pending' | 'preparing' | 'in_transit' | 'delivered' | 'cancelled';
  total_price: number;
  delivery_location: string;
  created_at: string;
  customer_name?: string;
  customer_email?: string;
  customer_phone?: string;
  payment_method?: 'cash' | 'lipanamba';
  notes?: string;
}

export interface Promotion {
  id: string;
  title: string;
  subtitle: string;
  discount_badge: string;
  promo_code: string;
  bg_hex: string;
  image_key: string;
  is_active: boolean;
}
