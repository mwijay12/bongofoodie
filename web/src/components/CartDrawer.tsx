'use client';

import React from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useCartStore } from '@/store/cart.store';
import { resolveFoodImage } from '@/lib/imageMap';
import { X, Plus, Minus, Trash2, ShoppingBag } from 'lucide-react';

export default function CartDrawer() {
  const { 
    items, 
    isOpen, 
    setIsOpen, 
    increaseQty, 
    decreaseQty, 
    removeItem, 
    getTotalPrice, 
    getTotalItems 
  } = useCartStore();

  const totalItems = getTotalItems();
  const totalPrice = getTotalPrice();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      {/* Background Overlay */}
      <div 
        onClick={() => setIsOpen(false)}
        className="absolute inset-0 bg-black/50 backdrop-blur-xs transition-opacity duration-300"
      />

      {/* Slide-over Content Drawer */}
      <div className="relative w-full max-w-md h-full bg-white shadow-2xl flex flex-col z-10 transition-transform duration-300 animate-slide-in">
        
        {/* Drawer Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShoppingBag className="size-5 text-primary" />
            <h2 className="font-heading font-bold text-lg text-foreground-dark">Your Cart</h2>
            <span className="bg-primary/10 text-primary text-xs font-bold px-2 py-0.5 rounded-full">
              {totalItems} items
            </span>
          </div>
          <button 
            onClick={() => setIsOpen(false)}
            className="p-1.5 hover:bg-muted rounded-xl transition-colors text-muted-foreground hover:text-foreground-dark"
          >
            <X className="size-5" />
          </button>
        </div>

        {/* Scrollable Items List */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {items.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center space-y-3">
              <ShoppingBag className="size-16 text-muted-foreground/35 stroke-[1.2px]" />
              <p className="text-muted-foreground font-semibold">Your cart is currently empty.</p>
              <button 
                onClick={() => setIsOpen(false)}
                className="text-primary hover:text-secondary font-bold text-sm"
              >
                Browse Swahili dishes ➔
              </button>
            </div>
          ) : (
            items.map((item) => {
              const imgUrl = resolveFoodImage(item.image_url);
              return (
                <div key={item.id} className="flex gap-4 p-3 bg-card border border-border rounded-2xl relative">
                  
                  {/* Item Image */}
                  <div className="size-16 rounded-xl bg-white border border-border flex items-center justify-center shrink-0 overflow-hidden">
                    <Image 
                      src={imgUrl} 
                      alt={item.name} 
                      width={56} 
                      height={56} 
                      className="object-contain"
                    />
                  </div>

                  {/* Item Details */}
                  <div className="flex-1 min-w-0 pr-6">
                    <h4 className="font-heading font-bold text-foreground-dark text-sm truncate">{item.name}</h4>
                    <span className="font-heading font-extrabold text-primary text-xs block mt-0.5">
                      TSh {item.price.toLocaleString()}
                    </span>

                    {/* Quantity selectors */}
                    <div className="flex items-center gap-3 mt-2.5">
                      <button 
                        onClick={() => decreaseQty(item.id)}
                        className="size-6 border border-border rounded-lg flex items-center justify-center bg-white hover:bg-muted text-foreground-dark"
                      >
                        <Minus className="size-3" />
                      </button>
                      <span className="text-xs font-extrabold text-foreground-dark">{item.quantity}</span>
                      <button 
                        onClick={() => increaseQty(item.id)}
                        className="size-6 border border-border rounded-lg flex items-center justify-center bg-white hover:bg-muted text-foreground-dark"
                      >
                        <Plus className="size-3" />
                      </button>
                    </div>
                  </div>

                  {/* Remove Button */}
                  <button 
                    onClick={() => removeItem(item.id)}
                    className="absolute top-3 right-3 text-muted-foreground hover:text-destructive transition-colors"
                  >
                    <Trash2 className="size-4" />
                  </button>

                </div>
              );
            })
          )}
        </div>

        {/* Drawer Footer calculations */}
        {items.length > 0 && (
          <div className="p-5 border-t border-border bg-card rounded-t-2xl space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between text-sm font-medium text-muted-foreground">
                <span>Items Subtotal</span>
                <span className="font-heading font-bold text-foreground-dark">TSh {totalPrice.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm font-medium text-muted-foreground">
                <span>Delivery Fee</span>
                <span className="font-heading font-bold text-foreground-dark">TSh 3,000</span>
              </div>
              <div className="flex justify-between text-sm font-medium text-muted-foreground">
                <span>Discount</span>
                <span className="font-heading font-bold text-accent-red">- TSh 1,000</span>
              </div>
              <div className="border-t border-border pt-3 flex justify-between">
                <span className="text-base font-bold text-foreground-dark">Total</span>
                <span className="font-heading font-extrabold text-primary text-lg">
                  TSh {(totalPrice + 3000 - 1000).toLocaleString()}
                </span>
              </div>
            </div>

            <Link 
              href="/cart"
              onClick={() => setIsOpen(false)}
              className="w-full inline-flex items-center justify-center py-3.5 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors shadow-md shadow-primary/10"
            >
              Checkout Now
            </Link>
          </div>
        )}

      </div>
    </div>
  );
}
