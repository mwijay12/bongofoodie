'use client';

import React from 'react';
import Image from 'next/image';
import { MenuItem } from '@/types';
import { resolveFoodImage, hasValidImage } from '@/lib/imageMap';
import { useCartStore } from '@/store/cart.store';
import { Plus, Star, Utensils, CupSoda } from 'lucide-react';

interface MenuCardProps {
  item: MenuItem;
}

export default function MenuCard({ item }: MenuCardProps) {
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
    <div className="bg-white border border-border rounded-2xl pt-16 pb-4 px-4 flex flex-col items-center justify-between relative shadow-sm hover:shadow-md transition-shadow duration-200 h-64 mt-8">
      {/* Absolute Rating Badge (Top-Right) */}
      <div className="absolute top-3 right-3 bg-amber-500/10 border border-amber-500/20 text-amber-600 px-2 py-0.5 rounded-lg flex items-center gap-1 text-xs font-extrabold shadow-xs z-10">
        <Star className="size-3 fill-amber-500 stroke-none" />
        <span>{rating.toFixed(1)}</span>
      </div>

      {/* Absolute Image or Fallback Icon */}
      <div className="absolute -top-10 w-28 h-28 flex items-center justify-center">
        {hasPic ? (
          <Image
            src={foodImg}
            alt={name}
            width={112}
            height={112}
            className="object-contain drop-shadow-md rounded-lg"
            priority
          />
        ) : (
          <div className="size-24 rounded-full bg-orange-100 border-4 border-white flex items-center justify-center shadow-md">
            {isDrink ? (
              <CupSoda className="size-10 text-primary" />
            ) : (
              <Utensils className="size-10 text-primary" />
            )}
          </div>
        )}
      </div>

      <div className="w-full text-center space-y-1 mt-2">
        <h3 className="font-heading font-bold text-foreground-dark text-base line-clamp-1">
          {name}
        </h3>
        <p className="text-xs text-muted-foreground line-clamp-2 px-1 font-medium leading-relaxed">
          {description}
        </p>
      </div>

      <div className="w-full flex items-center justify-between mt-3 pt-3 border-t border-muted">
        <span className="font-heading font-extrabold text-primary text-sm">
          TSh {price.toLocaleString()}
        </span>
        <button
          onClick={() => addItem({ id: $id, name, price, image_url })}
          className="size-9 rounded-xl bg-primary text-white flex items-center justify-center hover:bg-secondary transition-colors duration-200 shadow-sm shadow-primary/20"
        >
          <Plus className="size-5" />
        </button>
      </div>
    </div>
  );
}
