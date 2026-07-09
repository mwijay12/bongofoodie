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
    <div className="flex flex-row bg-white border border-border p-3 rounded-2xl items-center gap-4 shadow-sm hover:shadow-md transition-shadow duration-200 w-full mb-3">
      {/* Left Image or Fallback Icon */}
      <div className="size-20 rounded-xl bg-card border border-border flex items-center justify-center relative overflow-hidden shrink-0">
        {hasPic ? (
          <Image
            src={foodImg}
            alt={name}
            width={72}
            height={72}
            className="object-contain drop-shadow-sm"
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
          <h3 className="font-heading font-bold text-foreground-dark text-base truncate">
            {name}
          </h3>
          <span className="flex items-center gap-0.5 text-xs font-bold text-secondary shrink-0">
            <Star className="size-3 fill-secondary stroke-none" />
            {rating.toFixed(1)}
          </span>
        </div>
        <p className="text-xs text-muted-foreground line-clamp-2 mb-1.5 font-medium leading-relaxed">
          {description}
        </p>
        <span className="font-heading font-extrabold text-primary text-sm">
          TSh {price.toLocaleString()}
        </span>
      </div>

      {/* Right Action */}
      <button
        onClick={() => addItem({ id: $id, name, price, image_url })}
        className="size-10 rounded-xl bg-primary text-white flex items-center justify-center hover:bg-secondary transition-colors duration-200 shrink-0 shadow-sm shadow-primary/20"
      >
        <Plus className="size-5" />
      </button>
    </div>
  );
}
