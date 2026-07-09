import React, { useState, useEffect } from 'react';
import { FlatList, Text, View, Image, TouchableOpacity, Modal, Alert, ScrollView, Share } from 'react-native';
import { SafeAreaView } from "react-native-safe-area-context";
import useAppwrite from "@/lib/useAppwrite";
import { getCategories, getMenu, toggleFavorite, updateMenuRating } from "@/lib/supabaseDb";
import { useLocalSearchParams } from "expo-router";
import CartButton from "@/components/CartButton";
import cn from "clsx";
import MenuCard from "@/components/MenuCard";
import { MenuItem, Category } from "@/type";
import { useCartStore } from "@/store/cart.store";
import Filter from "@/components/Filter";
import SearchBar from "@/components/SearchBar";
import { images } from "@/constants";
import { Ionicons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import useAuthStore from '@/store/auth.store';
import * as Haptics from 'expo-haptics';

// Specialized List Card Component for List View Mode with details Modal
const MenuRowCard = ({ item }: { item: MenuItem }) => {
    const { $id, image_url, name, price, description } = item;
    const { addItem } = useCartStore();
    const { user } = useAuthStore();

    // Modal, Ratings, and Quantity state
    const [showDetails, setShowDetails] = useState(false);
    const [isFav, setIsFav] = useState(false);
    const [userRating, setUserRating] = useState(0);
    const [submittingRating, setSubmittingRating] = useState(false);
    const [currentRatingScore, setCurrentRatingScore] = useState(item.rating || 0);
    const [quantity, setQuantity] = useState(1);

    useEffect(() => {
        const checkFav = async () => {
            if (!user?.$id) return;
            try {
                const { data } = await supabase
                    .from('favorites')
                    .select('id')
                    .eq('profile_id', user.$id)
                    .eq('menu_id', $id)
                    .maybeSingle();
                if (data) {
                    setIsFav(true);
                }
            } catch (e) {
                console.error('[checkFav error]', e);
            }
        };
        checkFav();
    }, [user?.$id, $id]);

    const handleToggleFav = async () => {
        if (!user?.$id) {
            Alert.alert("Authentication Required", "Please sign in to favorite dishes.");
            return;
        }
        
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
        setIsFav(prev => !prev);
        try {
            await toggleFavorite(user.$id, $id);
        } catch (e) {
            setIsFav(prev => !prev);
            Alert.alert("Error", "Could not update favorite status.");
        }
    };

    const handleRate = async (stars: number) => {
        setUserRating(stars);
        setSubmittingRating(true);
        try {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            const updated = await updateMenuRating($id, stars);
            if (updated && updated.rating !== undefined) {
                setCurrentRatingScore(updated.rating);
            }
            Alert.alert("Thank you!", `You rated this dish ${stars} stars. We appreciate your feedback!`);
        } catch (e) {
            Alert.alert("Error", "Failed to submit your rating.");
        } finally {
            setSubmittingRating(false);
        }
    };

    const handleShare = async () => {
        try {
            await Share.share({
                message: `Check out this delicious ${name} on Bongo Foodie! Price: TSh ${price.toLocaleString()}`,
            });
        } catch (e) {
            console.error('[Share error]', e);
        }
    };

    const localImgKey = image_url as keyof typeof images;
    const isLocalAsset = images[localImgKey] !== undefined;

    // Resolve keyword-matched images locally if possible
    let resolvedLocalSource = null;
    if (image_url) {
        const lowerVal = image_url.toLowerCase();
        if (lowerVal.includes('burger-one') || lowerVal.includes('burgerone') || (lowerVal.includes('burger') && !lowerVal.includes('two'))) {
            resolvedLocalSource = images.burgerOne;
        } else if (lowerVal.includes('burger-two') || lowerVal.includes('burgertwo')) {
            resolvedLocalSource = images.burgerTwo;
        } else if (lowerVal.includes('pizza-one') || lowerVal.includes('pizzaone') || lowerVal.includes('pizza')) {
            resolvedLocalSource = images.pizzaOne;
        } else if (lowerVal.includes('chipsi') || lowerVal.includes('mayai') || lowerVal.includes('fries')) {
            resolvedLocalSource = images.chipsiMayai;
        } else if (lowerVal.includes('nyama') || lowerVal.includes('choma') || lowerVal.includes('beef') || lowerVal.includes('steak')) {
            resolvedLocalSource = images.nyamaChoma;
        } else if (lowerVal.includes('pilau') || lowerVal.includes('kuku') || lowerVal.includes('chicken') || lowerVal.includes('rice')) {
            resolvedLocalSource = images.pilauYaKuku;
        } else if (lowerVal.includes('samaki') || lowerVal.includes('fish') || lowerVal.includes('kupaka')) {
            resolvedLocalSource = images.samakiWaKupaka;
        } else if (lowerVal.includes('mishkaki') || lowerVal.includes('kebab') || lowerVal.includes('skewers')) {
            resolvedLocalSource = images.mishkakiYaNgombe;
        }
    }

    const hasSpecificPic = isLocalAsset || 
                           resolvedLocalSource !== null || 
                           (image_url && image_url.startsWith('https://rkjanbxkgfyjpdcichvy.supabase.co'));

    const source = isLocalAsset 
        ? images[localImgKey] 
        : resolvedLocalSource 
            ? resolvedLocalSource 
            : (image_url && (image_url.startsWith('http://') || image_url.startsWith('https://') || image_url.startsWith('/')))
                ? { uri: image_url }
                : null;

    const isDrink = (item as any).categories?.toLowerCase() === 'vinywaji' ||
                    item.type?.toLowerCase() === 'vinywaji' ||
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
        <>
        <TouchableOpacity 
            onPress={() => setShowDetails(true)}
            activeOpacity={0.95}
            className="flex-row bg-white border border-gourmet-border rounded-xl p-3 items-center justify-between mb-1 w-full max-w-[480px] mx-auto"
        >
            {hasSpecificPic ? (
                <Image 
                    source={source!} 
                    style={{ width: 80, height: 80 }}
                    className="rounded-lg bg-gourmet-bone" 
                    resizeMode="cover" 
                />
            ) : (
                <View 
                    style={{ width: 80, height: 80 }}
                    className="rounded-lg bg-orange-100 flex items-center justify-center"
                >
                    {isDrink ? (
                        <Ionicons name="wine" size={32} color="#F6821F" />
                    ) : (
                        <Ionicons name="restaurant" size={32} color="#F6821F" />
                    )}
                </View>
            )}
            <View className="flex-1 ml-4 pr-2">
                <Text className="base-bold text-gourmet-charcoal mb-0.5" numberOfLines={1}>
                    {name}
                </Text>
                
                {currentRatingScore > 0 && (
                    <View className="flex-row items-center gap-x-1 mb-1">
                        <Ionicons name="star" size={11} color="#F6821F" />
                        <Text className="text-[10px] font-quicksand-bold text-gourmet-amber">
                            {currentRatingScore.toFixed(1)}★
                        </Text>
                    </View>
                )}

                <Text className="text-xs text-gray-200 mb-2" numberOfLines={1}>
                    {description}
                </Text>
                <Text className="paragraph-bold text-gourmet-amber">
                    TSh {price.toLocaleString()}
                </Text>
            </View>
            <TouchableOpacity 
                onPress={(e) => {
                    e.stopPropagation();
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    addItem({ id: $id, name, price, image_url, customizations: [] }, 1);
                    Alert.alert("Added to Cart", `${name} added to your cart successfully.`);
                }}
                className="bg-gourmet-forest p-2.5 rounded-lg border border-gourmet-forest/10 flex items-center justify-center size-10"
            >
                <Text className="paragraph-bold text-white">+</Text>
            </TouchableOpacity>
        </TouchableOpacity>

        {/* Details Modal */}
        <Modal
            visible={showDetails}
            animationType="slide"
            transparent={true}
            onRequestClose={() => setShowDetails(false)}
        >
            <View className="flex-1 justify-end bg-black/60">
                <View className="bg-white rounded-t-3xl min-h-[70%] max-h-[90%] flex-col">
                    {/* Top action row */}
                    <View className="flex-row justify-between items-center px-6 pt-5 pb-3">
                        <TouchableOpacity 
                            onPress={() => setShowDetails(false)}
                            className="size-10 rounded-full bg-gourmet-bone items-center justify-center border border-gourmet-border"
                        >
                            <Ionicons name="arrow-back" size={20} color="#1E1E24" />
                        </TouchableOpacity>
                        
                        <View className="flex-row gap-x-2">
                            <TouchableOpacity 
                                onPress={handleShare}
                                className="size-10 rounded-full bg-gourmet-bone items-center justify-center border border-gourmet-border"
                            >
                                <Ionicons name="share-outline" size={20} color="#1E1E24" />
                            </TouchableOpacity>

                            <TouchableOpacity 
                                onPress={handleToggleFav}
                                className="size-10 rounded-full bg-gourmet-bone items-center justify-center border border-gourmet-border"
                            >
                                <Ionicons name={isFav ? "heart" : "heart-outline"} size={20} color={isFav ? "#EF4444" : "#1E1E24"} />
                            </TouchableOpacity>
                        </View>
                    </View>

                    <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 40 }} className="px-6 flex-grow">
                        {/* Food Image */}
                        <View className="items-center mb-6">
                            {!hasSpecificPic ? (
                                <View className="size-44 rounded-full bg-orange-100 items-center justify-center border-4 border-white shadow-md">
                                    {isDrink ? (
                                        <Ionicons name="wine" size={80} color="#F6821F" />
                                    ) : (
                                        <Ionicons name="restaurant" size={80} color="#F6821F" />
                                    )}
                                </View>
                            ) : (
                                <Image 
                                    source={source!} 
                                    style={{ width: 220, height: 220 }}
                                    className="rounded-2xl bg-gourmet-bone"
                                    resizeMode="contain" 
                                />
                            )}
                        </View>

                        {/* Title, Category */}
                        <View className="items-start mb-6">
                            <Text className="text-3xl font-quicksand-bold text-gourmet-charcoal mb-1">{name}</Text>
                            <View className="flex-row items-center gap-x-2">
                                <Text className="small-bold text-gourmet-amber uppercase tracking-wider">
                                    {isDrink ? "Beverage" : "Swahili Specialty"}
                                </Text>
                                {currentRatingScore > 0 && (
                                    <View className="flex-row items-center gap-x-1 bg-gourmet-amber/10 px-2 py-0.5 rounded-full">
                                        <Ionicons name="star" size={10} color="#F6821F" />
                                        <Text className="text-[10px] font-quicksand-bold text-gourmet-amber">
                                            {currentRatingScore.toFixed(1)} ★
                                        </Text>
                                    </View>
                                )}
                            </View>
                        </View>

                        {/* Dark Info Panel (Image 5 style) */}
                        <View className="bg-[#1E1E24] rounded-3xl p-6 mb-6">
                            {/* Price / Calories header row */}
                            <View className="flex-row justify-between items-center mb-6">
                                <Text className="text-white text-2xl font-quicksand-bold">
                                    TSh {price.toLocaleString()}
                                </Text>
                                <View className="flex-row items-center gap-x-1.5 bg-white/10 px-3 py-1.5 rounded-full">
                                    <Ionicons name="flame" size={16} color="#FF7043" />
                                    <Text className="text-white text-xs font-semibold">
                                        {item.calories ? `${item.calories} kcal` : "380 kcal"}
                                    </Text>
                                </View>
                            </View>

                            {/* Divider line */}
                            <View className="h-[1px] bg-white/10 mb-6" />

                            {/* Stats row (Carbs, Fat, Protein) */}
                            <View className="flex-row justify-between items-center mb-6">
                                <View className="flex-1 items-center border-r border-white/10">
                                    <Text className="text-white text-lg font-quicksand-bold">
                                        {item.calories ? Math.round(item.calories * 0.11) : 42}g
                                    </Text>
                                    <Text className="text-white/60 text-xs mt-1">Carbs</Text>
                                </View>
                                <View className="flex-1 items-center border-r border-white/10">
                                    <Text className="text-white text-lg font-quicksand-bold">
                                        {item.calories ? Math.round(item.calories * 0.03) : 12}g
                                    </Text>
                                    <Text className="text-white/60 text-xs mt-1">Fat</Text>
                                </View>
                                <View className="flex-1 items-center">
                                    <Text className="text-white text-lg font-quicksand-bold">
                                        {item.protein ? `${item.protein}g` : "24g"}
                                    </Text>
                                    <Text className="text-white/60 text-xs mt-1">Protein</Text>
                                </View>
                            </View>

                            {/* Divider line */}
                            <View className="h-[1px] bg-white/10 mb-6" />

                            {/* Description inside dark panel */}
                            <View>
                                <Text className="text-white/60 text-xs font-semibold uppercase tracking-wider mb-2">Description</Text>
                                <Text className="text-white/80 text-sm leading-relaxed">
                                    {item.description || "Fresh and authentic Swahili food, made to order using organic, locally sourced coastal spices and ingredients."}
                                </Text>
                            </View>

                            {/* Rate Dish (Stars interaction inside dark panel) */}
                            <View className="border-t border-white/10 mt-6 pt-5 items-center">
                                <Text className="text-white/60 text-xs font-semibold uppercase tracking-wider mb-2">Rate this dish</Text>
                                <View className="flex-row gap-x-2">
                                    {[1, 2, 3, 4, 5].map((star) => (
                                        <TouchableOpacity 
                                            key={star} 
                                            onPress={() => handleRate(star)}
                                            disabled={submittingRating}
                                            className="p-1"
                                        >
                                            <Ionicons 
                                                name={star <= userRating ? "star" : "star-outline"} 
                                                size={24} 
                                                color="#F6821F" 
                                            />
                                        </TouchableOpacity>
                                    ))}
                                </View>
                            </View>
                        </View>

                        {/* Bottom action row: Counter and Add to Cart Button */}
                        <View className="flex-row gap-x-4 items-center">
                            {/* Counter Selector */}
                            <View className="flex-row items-center bg-gourmet-bone border border-gourmet-border rounded-full px-3 py-1">
                                <TouchableOpacity 
                                    onPress={() => {
                                        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                        if (quantity > 1) setQuantity(prev => prev - 1);
                                    }}
                                    className="size-8 items-center justify-center rounded-full bg-white border border-gourmet-border shadow-xs"
                                >
                                    <Ionicons name="remove" size={16} color="#1E1E24" />
                                </TouchableOpacity>
                                <Text className="px-4 font-quicksand-bold text-lg text-gourmet-charcoal">{quantity}</Text>
                                <TouchableOpacity 
                                    onPress={() => {
                                        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                        setQuantity(prev => prev + 1);
                                    }}
                                    className="size-8 items-center justify-center rounded-full bg-white border border-gourmet-border shadow-xs"
                                >
                                    <Ionicons name="add" size={16} color="#1E1E24" />
                                </TouchableOpacity>
                            </View>

                            {/* Add to Cart */}
                            <TouchableOpacity 
                                onPress={() => {
                                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                    addItem({ id: $id, name, price, image_url, customizations: [] }, quantity);
                                    setShowDetails(false);
                                    Alert.alert("Added to Cart", `${quantity}x ${name} added to your cart successfully.`);
                                    setQuantity(1);
                                }}
                                className="flex-1 bg-gourmet-forest py-4 rounded-full flex-row items-center justify-between px-6 border border-gourmet-forest/10 shadow-sm"
                            >
                                <Text className="text-white font-quicksand-bold text-base">Add to Cart</Text>
                                <View className="size-8 rounded-full bg-white/20 items-center justify-center">
                                    <Ionicons name="chevron-forward" size={16} color="#FFFFFF" />
                                </View>
                            </TouchableOpacity>
                        </View>
                    </ScrollView>
                </View>
            </View>
        </Modal>
        </>
    );
};

const Search = () => {
    const { category, query } = useLocalSearchParams<{ query: string; category: string }>();
    const [viewType, setViewType] = useState<"grid" | "list">("grid");
    const [sortBy, setSortBy] = useState<"default" | "price_asc" | "price_desc" | "rating">("default");
    const [showSortOptions, setShowSortOptions] = useState(false);

    const { data, refetch, loading } = useAppwrite({ 
        fn: getMenu, 
        params: { category: category || "", query: query || "", limit: 12 } 
    });
    const { data: categories } = useAppwrite({ fn: getCategories });

    useEffect(() => {
        refetch({ category: category || "", query: query || "", limit: 12 });
    }, [category, query]);

    // Live local sorting inside useMemo
    const sortedData = React.useMemo(() => {
        if (!data) return [];
        const items = [...(data as MenuItem[])];
        if (sortBy === 'price_asc') {
            return items.sort((a, b) => a.price - b.price);
        } else if (sortBy === 'price_desc') {
            return items.sort((a, b) => b.price - a.price);
        } else if (sortBy === 'rating') {
            return items.sort((a, b) => (b.rating || 0) - (a.rating || 0));
        }
        return items;
    }, [data, sortBy]);

    return (
        <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
            <View className="flex-1 px-5">
                {/* Fixed Sticky Header */}
                <View className="pt-5 pb-3 gap-3 bg-[#FBFBFA] z-20">
                    <View className="flex-between flex-row w-full">
                        <View className="flex-start items-start">
                            <Text className="small-bold uppercase text-gourmet-forest">Search</Text>
                            <View className="flex-start flex-row gap-x-1 mt-0.5">
                                <Text className="paragraph-semibold text-gourmet-charcoal">Find your favorite food</Text>
                            </View>
                        </View>

                        <View className="flex-row items-center gap-x-2">
                            <TouchableOpacity 
                                onPress={() => setShowSortOptions(prev => !prev)}
                                className={cn(
                                    "py-2 px-2.5 bg-gourmet-bone rounded-lg border border-gourmet-border flex-row items-center justify-center",
                                    showSortOptions ? "bg-gourmet-forest/10 border-gourmet-forest" : ""
                                )}
                            >
                                <Ionicons name="funnel-outline" size={14} color={showSortOptions ? "#15803D" : "#787774"} style={{ marginRight: 4 }} />
                                <Text className={cn("font-quicksand-bold text-xs", showSortOptions ? "text-gourmet-forest" : "text-gourmet-charcoal")}>
                                    Sort
                                </Text>
                            </TouchableOpacity>

                            <TouchableOpacity 
                                onPress={() => setViewType(viewType === "grid" ? "list" : "grid")}
                                className="py-2 px-3 bg-gourmet-bone rounded-lg border border-gourmet-border flex-row items-center justify-center"
                            >
                                <Text className="font-quicksand-bold text-gourmet-forest text-xs">
                                    {viewType === "grid" ? "List" : "Grid"}
                                </Text>
                            </TouchableOpacity>
                            <CartButton />
                        </View>
                    </View>

                    <SearchBar />

                    {categories && (
                        <View className="gap-y-2">
                            <Filter categories={categories as Category[]} />
                            
                            {/* Sort Selector Row (collapsible) */}
                            {showSortOptions && (
                                <View className="flex-row items-center bg-gourmet-bone/50 p-2 rounded-xl border border-gourmet-border/60">
                                    <Text className="text-[10px] font-quicksand-bold text-gray-200 uppercase tracking-wide mr-2">Sort By:</Text>
                                    <ScrollView horizontal showsHorizontalScrollIndicator={false} className="flex-row py-1">
                                        <TouchableOpacity 
                                            onPress={() => setSortBy('default')}
                                            className={cn(
                                                "px-3 py-1 rounded-full border mr-2 flex-row items-center",
                                                sortBy === 'default' ? "bg-gourmet-forest/10 border-gourmet-forest" : "bg-white border-gourmet-border"
                                            )}
                                        >
                                            <Text className={cn("text-[10px] font-quicksand-bold", sortBy === 'default' ? "text-gourmet-forest" : "text-gourmet-charcoal")}>Default</Text>
                                        </TouchableOpacity>
                                        <TouchableOpacity 
                                            onPress={() => setSortBy('price_asc')}
                                            className={cn(
                                                "px-3 py-1 rounded-full border mr-2 flex-row items-center",
                                                sortBy === 'price_asc' ? "bg-gourmet-forest/10 border-gourmet-forest" : "bg-white border-gourmet-border"
                                            )}
                                        >
                                            <Text className={cn("text-[10px] font-quicksand-bold", sortBy === 'price_asc' ? "text-gourmet-forest" : "text-gourmet-charcoal")}>Price: Low to High</Text>
                                        </TouchableOpacity>
                                        <TouchableOpacity 
                                            onPress={() => setSortBy('price_desc')}
                                            className={cn(
                                                "px-3 py-1 rounded-full border mr-2 flex-row items-center",
                                                sortBy === 'price_desc' ? "bg-gourmet-forest/10 border-gourmet-forest" : "bg-white border-gourmet-border"
                                            )}
                                        >
                                            <Text className={cn("text-[10px] font-quicksand-bold", sortBy === 'price_desc' ? "text-gourmet-forest" : "text-gourmet-charcoal")}>Price: High to Low</Text>
                                        </TouchableOpacity>
                                        <TouchableOpacity 
                                            onPress={() => setSortBy('rating')}
                                            className={cn(
                                                "px-3 py-1 rounded-full border mr-2 flex-row items-center",
                                                sortBy === 'rating' ? "bg-gourmet-forest/10 border-gourmet-forest" : "bg-white border-gourmet-border"
                                            )}
                                        >
                                            <Text className={cn("text-[10px] font-quicksand-bold", sortBy === 'rating' ? "text-gourmet-forest" : "text-gourmet-charcoal")}>Ratings</Text>
                                        </TouchableOpacity>
                                    </ScrollView>
                                </View>
                            )}
                        </View>
                    )}
                </View>

                {/* Scrollable list */}
                <FlatList
                    key={viewType}
                    data={sortedData as MenuItem[]}
                    renderItem={({ item }: { item: MenuItem }) => (
                        <View className={cn(viewType === "grid" ? "flex-1 max-w-[48%]" : "w-full")}>
                            {viewType === "grid" ? (
                                <View className="mt-8">
                                    <MenuCard item={item} />
                                </View>
                            ) : (
                                <MenuRowCard item={item} />
                            )}
                        </View>
                    )}
                    keyExtractor={(item: MenuItem) => item.$id}
                    numColumns={viewType === "grid" ? 2 : 1}
                    columnWrapperClassName={viewType === "grid" ? "gap-4 justify-between" : undefined}
                    contentContainerClassName="pb-36 max-w-2xl mx-auto w-full"
                    contentContainerStyle={{ paddingBottom: 150 }}
                    ListEmptyComponent={() => !loading && (
                        <View className="items-center py-10">
                            <Text className="base-regular text-gray-200">No results found</Text>
                        </View>
                    )}
                />
            </View>
        </SafeAreaView>
    );
};

export default Search;
