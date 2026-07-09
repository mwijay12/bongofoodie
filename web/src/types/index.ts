export interface MenuItem {
  $id: string;
  name: string;
  description: string;
  image_url: string;
  price: number;
  rating: number;
  calories?: number;
  protein?: number;
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
  type: string; // 'topping', 'side', 'drink', etc.
}

export interface Profile {
  id: string;
  name: string;
  email: string;
  avatar_url?: string;
  updated_at?: string;
}

export interface CartItemType {
  id: string;
  name: string;
  price: number;
  image_url: string;
  quantity: number;
  customizations?: Customization[];
  isAICreated?: boolean;
  calories?: number;
  protein?: number;
  recipe?: string;
}

export interface Order {
  id: string;
  table_number?: string;
  items: CartItemType[];
  status: 'pending' | 'in_transit' | 'delivered' | 'cancelled';
  total_price: number;
  delivery_location: string;
  created_at: string;
  customer_name?: string;
  customer_email?: string;
}
