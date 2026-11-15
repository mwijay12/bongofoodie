'use client';

import React from 'react';
import Image from 'next/image';
import { MenuItem } from '@/types';
import { resolveFoodImage, hasValidImage } from '@/lib/imageMap';
import { useCartStore } from '@/store/cart.store';
import { Plus, Star, Utensils, CupSoda } from 'lucide-react';

interface MenuRowCardProps {
  item: MenuItem;
}

export default function MenuRowCard({ item }: MenuRowCardProps) {
  const { $id, name, description, image_url, price, rating, categories } = item;
  const addItem = useCartStore((state) => state.addItem);
  const foodImg = resolveFoodImage(image_url);
  const hasPic = hasValidImage(image_url);

  const isDrink = categories?.toLowerCase() === 'vinywaji' ||
                  name.toLowerCase().includes('drink') ||
                  name.toLowerCase().includes('soda') ||
                  name.toLowerCase().includes('juice') ||
                  name.toLowerCase().includes('water') ||
                  name.toLowerCase().includes('beer') ||
                  name.toLowerCase().includes('wine') ||
                  name.toLowerCase().includes('tea') ||
                  name.toLowerCase().includes('chai') ||
                  name.toLowerCase().includes('coffee') ||
                  name.toLowerCase().includes('kahawa') ||
                  name.toLowerCase().includes('beverage');

  return (
    <div className="flex flex-row bg-white border border-border p-3 sm:p-3.5 rounded-2xl items-center gap-3.5 sm:gap-4 shadow-sm hover:shadow-md transition-shadow duration-200 w-full">
      {/* Left Image or Fallback Icon */}
      <div className="size-[76px] sm:size-20 rounded-xl bg-gradient-to-br from-[#F4EEE6] to-[#EFE6DA] flex items-center justify-center relative overflow-hidden shrink-0">
        {hasPic ? (
          <Image
            src={foodImg}
            alt={name}
            width={160}
            height={160}
            className="size-full object-contain p-1.5 drop-shadow-sm"
          />
        ) : (
          <div className="size-16 rounded-full bg-orange-100 flex items-center justify-center shadow-xs">
            {isDrink ? (
              <CupSoda className="size-7 text-primary" />
            ) : (
              <Utensils className="size-7 text-primary" />
            )}
          </div>
        )}
      </div>

      {/* Middle Details */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-0.5">
          <h3 className="font-heading font-bold text-foreground-dark text-[15px] sm:text-base truncate">
            {name}
          </h3>
          <span className="flex items-center gap-0.5 text-[13px] font-bold text-amber-600 shrink-0">
            <Star className="size-3 fill-secondary stroke-none" />
            {rating.toFixed(1)}
          </span>
        </div>
        <p className="text-[13px] text-muted-foreground line-clamp-2 mb-1.5 font-medium leading-relaxed">
          {description}
        </p>
        <span className="font-heading font-extrabold text-primary text-[15px]">
          TSh {price.toLocaleString()}
        </span>
      </div>

      {/* Right Action */}
      <button
        onClick={() => addItem({ id: $id, name, price, image_url })}
        aria-label={`Add ${name} to cart`}
        className="size-11 rounded-xl bg-primary text-white flex items-center justify-center hover:bg-primary-soft active:scale-95 transition-all duration-200 shrink-0 shadow-sm shadow-primary/25"
      >
        <Plus className="size-5" />
      </button>
    </div>
  );
}
