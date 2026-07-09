'use client';

import React, { useState, useEffect } from 'react';
import { getMenu, getCategories } from '@/lib/supabaseDb';
import { MenuItem, Category } from '@/types';
import MenuCard from '@/components/MenuCard';
import MenuRowCard from '@/components/MenuRowCard';
import { Grid, List, Loader2, Search as SearchIcon, X } from 'lucide-react';

export default function SearchPage() {
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Search & Filter States
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState('All');
  const [viewType, setViewType] = useState<'grid' | 'list'>('grid');

  useEffect(() => {
    loadCategories();
  }, []);

  // Fetch menu dynamically when search query or category filters change (with debounced search query)
  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      loadMenu(activeCategory, searchQuery);
    }, 300); // 300ms debounce delay

    return () => clearTimeout(delayDebounceFn);
  }, [activeCategory, searchQuery]);

  const loadCategories = async () => {
    try {
      const data = await getCategories();
      // Prepend an 'All' category option
      setCategories([{ $id: 'all', name: 'All' }, ...data]);
    } catch (e) {
      console.error('[Load Categories Error]', e);
    }
  };

  const loadMenu = async (categoryFilter: string, queryFilter: string) => {
    setLoading(true);
    try {
      const data = await getMenu({
        category: categoryFilter,
        query: queryFilter
      });
      setMenuItems(data);
    } catch (e) {
      console.error('[Load Menu Error]', e);
    } finally {
      setLoading(false);
    }
  };

  const handleClearSearch = () => {
    setSearchQuery('');
  };

  return (
    <div className="flex flex-col gap-6 py-6 pb-20">
      
      {/* Search Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="font-heading text-3xl font-bold text-foreground-dark">Search Menu</h1>
          <p className="text-muted-foreground mt-1 font-medium">Browse and discover Swahili food delicacies.</p>
        </div>

        {/* View Toggle Buttons */}
        <div className="flex items-center gap-2 self-end sm:self-auto">
          <button
            onClick={() => setViewType('grid')}
            className={`p-2.5 rounded-xl border transition-colors ${
              viewType === 'grid' 
                ? 'bg-primary text-white border-primary' 
                : 'bg-white text-muted-foreground border-border hover:bg-muted'
            }`}
            title="Grid View"
          >
            <Grid className="size-5" />
          </button>
          <button
            onClick={() => setViewType('list')}
            className={`p-2.5 rounded-xl border transition-colors ${
              viewType === 'list' 
                ? 'bg-primary text-white border-primary' 
                : 'bg-white text-muted-foreground border-border hover:bg-muted'
            }`}
            title="List View"
          >
            <List className="size-5" />
          </button>
        </div>
      </div>

      {/* Input Search Bar */}
      <div className="relative w-full max-w-2xl">
        <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
          <SearchIcon className="size-5 text-muted-foreground" />
        </div>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search food items (e.g., Nyama Choma, Chipsi Mayai)..."
          className="w-full bg-white border border-border rounded-xl pl-11 pr-10 py-3.5 text-sm font-sans font-medium text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all shadow-sm"
        />
        {searchQuery && (
          <button
            onClick={handleClearSearch}
            className="absolute inset-y-0 right-0 pr-3 flex items-center text-muted-foreground hover:text-foreground-dark transition-colors"
          >
            <X className="size-5" />
          </button>
        )}
      </div>

      {/* Dynamic Category Filter Slider */}
      <div className="w-full overflow-x-auto no-scrollbar py-1">
        <div className="flex flex-row gap-2.5">
          {categories.map((cat) => {
            const isActive = activeCategory.toLowerCase() === cat.name.toLowerCase();
            return (
              <button
                key={cat.$id}
                onClick={() => setActiveCategory(cat.name)}
                className={`px-5 py-2.5 rounded-full text-xs font-bold font-sans transition-all shrink-0 border uppercase tracking-wider ${
                  isActive
                    ? 'bg-primary text-white border-primary shadow-sm shadow-primary/20'
                    : 'bg-white text-muted-foreground border-border hover:text-foreground-dark hover:border-muted-foreground/30'
                }`}
              >
                {cat.name}
              </button>
            );
          })}
        </div>
      </div>

      {/* Loading & Grid Rendering */}
      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="size-8 text-primary animate-spin" />
        </div>
      ) : menuItems.length === 0 ? (
        <div className="text-center py-20 bg-white border border-border rounded-3xl">
          <p className="text-muted-foreground font-semibold">No food items found matching your selection.</p>
        </div>
      ) : (
        <div className={viewType === 'grid' 
          ? "grid grid-cols-2 md:grid-cols-4 gap-6 pt-4" 
          : "flex flex-col gap-1 w-full max-w-3xl mx-auto"
        }>
          {menuItems.map((item) => (
            viewType === 'grid' ? (
              <MenuCard key={item.$id} item={item} />
            ) : (
              <MenuRowCard key={item.$id} item={item} />
            )
          ))}
        </div>
      )}
    </div>
  );
}
