import { create } from 'zustand';
import { CartItemType } from '@/types';

interface CartState {
  items: CartItemType[];
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
  addItem: (item: Omit<CartItemType, 'quantity'>) => void;
  increaseQty: (id: string) => void;
  decreaseQty: (id: string) => void;
  removeItem: (id: string) => void;
  clearCart: () => void;
  getTotalItems: () => number;
  getTotalPrice: () => number;
}

export const useCartStore = create<CartState>((set, get) => ({
  items: [],
  isOpen: false,
  setIsOpen: (open) => set({ isOpen: open }),
  
  addItem: (item) => {
    const existing = get().items.find(i => i.id === item.id);
    if (existing) {
      set({
        items: get().items.map(i => 
          i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
        ),
        isOpen: true // Automatically open the cart drawer when adding an item!
      });
    } else {
      set({
        items: [...get().items, { ...item, quantity: 1 }],
        isOpen: true // Automatically open the cart drawer when adding an item!
      });
    }
  },

  increaseQty: (id) => {
    set({
      items: get().items.map(i => 
        i.id === id ? { ...i, quantity: i.quantity + 1 } : i
      )
    });
  },

  decreaseQty: (id) => {
    const item = get().items.find(i => i.id === id);
    if (item && item.quantity > 1) {
      set({
        items: get().items.map(i => 
          i.id === id ? { ...i, quantity: i.quantity - 1 } : i
        )
      });
    } else {
      get().removeItem(id);
    }
  },

  removeItem: (id) => {
    set({
      items: get().items.filter(i => i.id !== id)
    });
  },

  clearCart: () => set({ items: [] }),

  getTotalItems: () => {
    return get().items.reduce((total, item) => total + item.quantity, 0);
  },

  getTotalPrice: () => {
    return get().items.reduce((total, item) => total + (item.price * item.quantity), 0);
  }
}));
