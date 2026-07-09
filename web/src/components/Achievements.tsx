'use client';

import React from 'react';
import { Award, Lock, CheckCircle2, Shield, Flame, Sparkles, Star, Coffee, Crown, Compass } from 'lucide-react';

interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: any;
  unlocked: boolean;
  progressMax: number;
  progressCurrent: number;
}

interface AchievementsProps {
  ordersCount: number;
  nyamaChomaCount: number;
  chipsiCount: number;
  customDishCount: number;
  seafoodCount?: number;
  drinksCount?: number;
}

export default function Achievements({
  ordersCount = 0,
  nyamaChomaCount = 0,
  chipsiCount = 0,
  customDishCount = 0,
  seafoodCount = 1,
  drinksCount = 2,
}: AchievementsProps) {

  const list: Achievement[] = [
    {
      id: 'member',
      name: 'Mwana Jumuia',
      description: 'Registered account on Bongo Foodie workspace.',
      icon: Shield,
      unlocked: true,
      progressMax: 1,
      progressCurrent: 1,
    },
    {
      id: 'choma',
      name: 'Mzee wa Nyama Choma',
      description: 'Ordered authentic grilled beef mishkaki or nyama choma.',
      icon: Flame,
      unlocked: nyamaChomaCount >= 2,
      progressMax: 2,
      progressCurrent: Math.min(nyamaChomaCount, 2),
    },
    {
      id: 'chipsi',
      name: 'Chipsi Mayai King',
      description: 'Ordered 3 plates of local chipsi mayai street fries.',
      icon: Star,
      unlocked: chipsiCount >= 3,
      progressMax: 3,
      progressCurrent: Math.min(chipsiCount, 3),
    },
    {
      id: 'gourmet',
      name: 'Chef Customizer',
      description: 'Successfully customized an order dish with Chef AI.',
      icon: Sparkles,
      unlocked: customDishCount >= 1,
      progressMax: 1,
      progressCurrent: Math.min(customDishCount, 1),
    },
    {
      id: 'seafood',
      name: 'Mhifadhi wa Bahari',
      description: 'Ordered 2 sea food dishes (like Samaki wa Kupaka).',
      icon: Compass,
      unlocked: seafoodCount >= 2,
      progressMax: 2,
      progressCurrent: Math.min(seafoodCount, 2),
    },
    {
      id: 'beverage',
      name: 'Swahili Drink Lover',
      description: 'Ordered 3 local fresh juices or beverages.',
      icon: Coffee,
      unlocked: drinksCount >= 3,
      progressMax: 3,
      progressCurrent: Math.min(drinksCount, 3),
    },
    {
      id: 'balozi',
      name: 'Balozi wa Bongo',
      description: 'Placed 10 orders overall on our platform.',
      icon: Crown,
      unlocked: ordersCount >= 10,
      progressMax: 10,
      progressCurrent: Math.min(ordersCount, 10),
    },
    {
      id: 'gold',
      name: 'Mzee wa Meza',
      description: 'Placed 5 orders overall in Dar es Salaam.',
      icon: Award,
      unlocked: ordersCount >= 5,
      progressMax: 5,
      progressCurrent: Math.min(ordersCount, 5),
    },
  ];

  const unlockedCount = list.filter(a => a.unlocked).length;

  return (
    <div className="space-y-4">
      {/* Overview stats */}
      <div className="flex items-center justify-between pb-3 border-b border-border/60">
        <h3 className="font-heading font-bold text-base text-foreground-dark flex items-center gap-1.5">
          <Award className="size-5 text-primary" /> Mini Achievements
        </h3>
        <span className="text-xs font-bold text-primary bg-primary/10 px-2.5 py-1 rounded-full">
          {unlockedCount} / {list.length} Unlocked
        </span>
      </div>

      {/* Grid List */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
        {list.map((badge) => {
          const Icon = badge.icon;
          return (
            <div 
              key={badge.id} 
              className={`p-3.5 rounded-2xl border transition-all duration-200 flex items-start gap-3 relative ${
                badge.unlocked
                  ? 'bg-primary/5 border-primary/20 text-foreground-dark shadow-xs'
                  : 'bg-white border-border text-muted-foreground opacity-60'
              }`}
            >
              {/* Left Icon */}
              <div className={`p-2.5 rounded-xl shrink-0 ${
                badge.unlocked 
                  ? 'bg-primary/15 text-primary' 
                  : 'bg-muted text-muted-foreground'
              }`}>
                <Icon className="size-5" />
              </div>

              {/* Middle Details */}
              <div className="space-y-1 pr-6">
                <h4 className="font-heading font-bold text-sm text-foreground-dark">{badge.name}</h4>
                <p className="text-[10px] leading-normal font-semibold text-muted-foreground">{badge.description}</p>
                
                {/* Progress bar */}
                <div className="w-full bg-border/40 rounded-full h-1.5 mt-2 overflow-hidden">
                  <div 
                    className="bg-primary h-1.5 rounded-full transition-all duration-300"
                    style={{ width: `${(badge.progressCurrent / badge.progressMax) * 100}%` }}
                  />
                </div>
                <span className="text-[9px] font-bold text-muted-foreground mt-1 block">
                  Progress: {badge.progressCurrent}/{badge.progressMax}
                </span>
              </div>

              {/* Status Mark */}
              <div className="absolute top-3.5 right-3.5">
                {badge.unlocked ? (
                  <CheckCircle2 className="size-4.5 text-emerald-600 fill-emerald-100" />
                ) : (
                  <Lock className="size-4 text-muted-foreground/50" />
                )}
              </div>

            </div>
          );
        })}
      </div>
    </div>
  );
}
