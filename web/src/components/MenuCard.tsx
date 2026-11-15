'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { MenuItem } from '@/types';
import { resolveFoodImage, hasValidImage } from '@/lib/imageMap';
import { getActiveUserProfile, toggleFavoriteWeb } from '@/lib/supabaseDb';
import { useCartStore } from '@/store/cart.store';
import { Plus, Star, Utensils, CupSoda, X, Heart, Share2, Minus, ShoppingCart, ChevronRight, Flame, Check } from 'lucide-react';

interface MenuCardProps {
  item: MenuItem;
}

export default function MenuCard({ item }: MenuCardProps) {
  const { $id, name, description, image_url, price, rating, categories } = item;
  const addItem = useCartStore((state) => state.addItem);
  const foodImg = resolveFoodImage(image_url);
  const hasPic = hasValidImage(image_url);
  const [showModal, setShowModal] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const [added, setAdded] = useState(false);
  const [isFavorite, setIsFavorite] = useState(false);

  const handleToggleFavorite = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const profile = await getActiveUserProfile();
    const uid = profile?.id || 'demo-customer';
    const nextState = await toggleFavoriteWeb(uid, $id);
    setIsFavorite(nextState);
  };

  const isDrink = categories?.toLowerCase() === 'vinywaji' ||
    name.toLowerCase().includes('drink') || name.toLowerCase().includes('soda') ||
    name.toLowerCase().includes('juice') || name.toLowerCase().includes('water') ||
    name.toLowerCase().includes('beer') || name.toLowerCase().includes('wine') ||
    name.toLowerCase().includes('tea') || name.toLowerCase().includes('chai') ||
    name.toLowerCase().includes('coffee') || name.toLowerCase().includes('kahawa') ||
    name.toLowerCase().includes('beverage');

  const handleAddToCart = () => {
    // Add item multiple times based on quantity (web store addItem adds 1)
    for (let i = 0; i < quantity; i++) {
      addItem({ id: $id, name, price, image_url });
    }
    if (showModal) {
      setAdded(true);
      setTimeout(() => { setAdded(false); setShowModal(false); setQuantity(1); }, 1500);
    }
  };

  return (
    <>
      {/* Card. The artwork sits INSIDE the card in its own tinted panel at the
          top — it used to be absolutely positioned above the card, which drew a
          rectangle straight through the dish name and left the row overlapping. */}
      <article
        onClick={() => setShowModal(true)}
        className="group bg-white border border-border rounded-2xl overflow-hidden flex flex-col shadow-sm hover:shadow-lg hover:-translate-y-1 transition-all duration-300 cursor-pointer h-full"
      >
        {/* Art panel */}
        <div className="relative bg-gradient-to-br from-[#F4EEE6] to-[#EFE6DA] aspect-[4/3] flex items-center justify-center overflow-hidden">
          {hasPic ? (
            <Image
              src={foodImg}
              alt={name}
              width={260}
              height={260}
              sizes="(max-width: 768px) 45vw, 22vw"
              className="size-full object-contain p-3 drop-shadow-sm transition-transform duration-500 group-hover:scale-105"
              priority
            />
          ) : (
            <div className="size-20 rounded-full bg-orange-100 border-4 border-white flex items-center justify-center shadow-md">
              {isDrink ? <CupSoda className="size-9 text-primary" /> : <Utensils className="size-9 text-primary" />}
            </div>
          )}

          {/* Rating — glass pill so it reads on any artwork */}
          <div className="absolute top-2.5 right-2.5 bg-white/92 backdrop-blur-sm border border-border px-2 py-1 rounded-full flex items-center gap-1 text-xs font-extrabold text-foreground-dark shadow-sm">
            <Star className="size-3 fill-amber-500 stroke-none" />
            <span>{rating.toFixed(1)}</span>
          </div>
        </div>

        {/* Body */}
        <div className="flex flex-col flex-1 p-4">
          <h3 className="font-heading font-bold text-foreground-dark text-[15px] leading-snug line-clamp-2">{name}</h3>
          <p className="text-[13px] text-muted-foreground line-clamp-2 mt-1.5 font-medium leading-relaxed">{description}</p>

          <div className="flex items-center justify-between mt-auto pt-3.5">
            <span className="font-heading font-extrabold text-primary text-base">TSh {price.toLocaleString()}</span>
            <button
              onClick={(e) => { e.stopPropagation(); handleAddToCart(); }}
              aria-label={`Add ${name} to cart`}
              className="size-10 rounded-xl bg-primary text-white flex items-center justify-center hover:bg-primary-soft active:scale-95 transition-all duration-200 shadow-sm shadow-primary/25"
            >
              <Plus className="size-5" />
            </button>
          </div>
        </div>
      </article>

      {/* Details Modal - like mobile app */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60" onClick={() => setShowModal(false)}>
          <div className="bg-white w-full sm:max-w-lg rounded-t-3xl sm:rounded-3xl max-h-[90vh] overflow-y-auto shadow-2xl" onClick={e => e.stopPropagation()}>
            
            {/* Modal Header */}
            <div className="sticky top-0 bg-white z-10 flex justify-between items-center px-6 pt-5 pb-3 border-b border-border">
              <button onClick={() => setShowModal(false)} className="size-10 rounded-full bg-muted flex items-center justify-center hover:bg-muted/70 transition-colors">
                <X className="size-5 text-foreground-dark" />
              </button>
              <div className="flex gap-2">
                <button onClick={() => { if (navigator.share) navigator.share({ title: name, text: `Check out ${name} on Bongo Foodie!` }); }}
                  className="size-10 rounded-full bg-muted flex items-center justify-center hover:bg-muted/70 transition-colors">
                  <Share2 className="size-4 text-foreground-dark" />
                </button>
                <button
                  onClick={handleToggleFavorite}
                  title="Save Favorite"
                  className={`size-10 rounded-full flex items-center justify-center transition-colors ${isFavorite ? 'bg-red-50 text-red-500' : 'bg-muted text-foreground-dark hover:bg-muted/70'}`}
                >
                  <Heart className={`size-4 ${isFavorite ? 'fill-red-500 stroke-red-500' : ''}`} />
                </button>
              </div>
            </div>

            <div className="px-6 pb-8">
              {/* Food Image */}
              <div className="flex justify-center my-6">
                {hasPic ? (
                  <Image src={foodImg} alt={name} width={200} height={200} className="rounded-2xl bg-muted object-contain" priority />
                ) : (
                  <div className="size-44 rounded-full bg-orange-100 flex items-center justify-center border-4 border-white shadow-md">
                    {isDrink ? <CupSoda className="size-20 text-primary" /> : <Utensils className="size-20 text-primary" />}
                  </div>
                )}
              </div>

              {/* Title & Category */}
              <div className="mb-6">
                <h2 className="font-heading text-2xl font-bold text-foreground-dark mb-1">{name}</h2>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">{isDrink ? "Beverage" : "Swahili Specialty"}</span>
                  {rating > 0 && (
                    <span className="flex items-center gap-1 bg-amber-50 text-amber-600 px-2 py-0.5 rounded-full text-xs font-bold">
                      <Star className="size-3 fill-amber-500 stroke-none" />{rating.toFixed(1)}
                    </span>
                  )}
                </div>
              </div>

              {/* Dark Info Panel */}
              <div className="bg-[#1E1E24] rounded-3xl p-6 mb-6">
                {/* Price / Calories */}
                <div className="flex justify-between items-center mb-6">
                  <span className="text-white text-2xl font-heading font-bold">TSh {price.toLocaleString()}</span>
                  <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1.5 rounded-full text-white text-xs font-semibold">
                    <Flame className="size-4 text-orange-400" /> {item.calories || 380} kcal
                  </span>
                </div>
                <div className="h-px bg-white/10 mb-6" />
                
                {/* Stats */}
                <div className="flex justify-between mb-6">
                  <div className="flex-1 text-center border-r border-white/10">
                    <p className="text-white text-lg font-bold">{item.calories ? Math.round(item.calories * 0.11) : 42}g</p>
                    <p className="text-white/60 text-xs mt-1">Carbs</p>
                  </div>
                  <div className="flex-1 text-center border-r border-white/10">
                    <p className="text-white text-lg font-bold">{item.calories ? Math.round(item.calories * 0.03) : 12}g</p>
                    <p className="text-white/60 text-xs mt-1">Fat</p>
                  </div>
                  <div className="flex-1 text-center">
                    <p className="text-white text-lg font-bold">{item.protein ? `${item.protein}g` : "24g"}</p>
                    <p className="text-white/60 text-xs mt-1">Protein</p>
                  </div>
                </div>
                <div className="h-px bg-white/10 mb-6" />
                
                {/* Description */}
                <div>
                  <p className="text-white/60 text-xs font-semibold uppercase tracking-wider mb-2">Description</p>
                  <p className="text-white/80 text-sm leading-relaxed">{description || "Fresh and authentic Swahili food, made to order using local spices."}</p>
                </div>
              </div>

              {/* Add to Cart */}
              <div className="flex items-center gap-4">
                {/* Quantity Selector */}
                <div className="flex items-center bg-muted border border-border rounded-full px-2 py-1">
                  <button onClick={() => setQuantity(q => Math.max(1, q - 1))} className="size-8 flex items-center justify-center rounded-full bg-white border border-border shadow-sm">
                    <Minus className="size-4" />
                  </button>
                  <span className="px-4 font-heading font-bold text-lg">{quantity}</span>
                  <button onClick={() => setQuantity(q => q + 1)} className="size-8 flex items-center justify-center rounded-full bg-white border border-border shadow-sm">
                    <Plus className="size-4" />
                  </button>
                </div>
                {/* Add Button */}
                <button onClick={handleAddToCart}
                  className={`flex-1 py-4 rounded-full font-heading font-bold text-base flex items-center justify-between px-6 transition-all ${added ? 'bg-emerald-600 text-white' : 'bg-primary text-white hover:bg-secondary'}`}>
                  {added ? (
                    <><Check className="size-5" /> Added</>
                  ) : (
                    <><ShoppingCart className="size-5" /> Add to Cart</>
                  )}
                  <ChevronRight className="size-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}