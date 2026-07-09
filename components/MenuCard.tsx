import { Text, TouchableOpacity, Image, View, Alert, Modal, ScrollView, Share } from 'react-native';
import React, { useState, useEffect } from 'react';
import { MenuItem } from "@/type";
import { useCartStore } from "@/store/cart.store";
import { images } from "@/constants";
import { Ionicons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import { toggleFavorite, updateMenuRating } from '@/lib/supabaseDb';
import useAuthStore from '@/store/auth.store';
import * as Haptics from 'expo-haptics';
import cn from 'clsx';

const MenuCard = ({ item }: { item: MenuItem }) => {
    const { $id, name, price, image_url } = item;
    const { user } = useAuthStore();
    const [isFav, setIsFav] = useState(false);
    
    // Modal, Ratings, and Quantity state
    const [showDetails, setShowDetails] = useState(false);
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
    
    // Resolve whether this is a local asset registered in constants/index.ts or a remote image URL
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

    const { addItem } = useCartStore();

    return (
        <>
        <TouchableOpacity 
            onPress={() => setShowDetails(true)}
            activeOpacity={0.95}
            className="menu-card bg-white border border-gourmet-border rounded-xl pt-20 pb-4 px-3 flex items-center justify-between w-full max-w-[260px] mx-auto md:max-w-[220px]"
        >
            {/* Heart Button */}
            <TouchableOpacity 
                onPress={(e) => {
                    e.stopPropagation();
                    handleToggleFav();
                }}
                style={{ position: 'absolute', top: 12, right: 12, zIndex: 10 }}
                className="bg-white/80 p-1.5 rounded-full shadow-xs border border-gourmet-border/40"
            >
                <Ionicons 
                    name={isFav ? "heart" : "heart-outline"} 
                    size={18} 
                    color={isFav ? "#EF4444" : "#787774"} 
                />
            </TouchableOpacity>

            {!hasSpecificPic ? (
                <View 
                    style={{ width: 96, height: 96 }}
                    className="rounded-full bg-orange-100 border-4 border-white flex items-center justify-center shadow-md absolute -top-8"
                >
                    {isDrink ? (
                        <Ionicons name="wine" size={40} color="#F6821F" />
                    ) : (
                        <Ionicons name="restaurant" size={40} color="#F6821F" />
                    )}
                </View>
            ) : (
                <Image 
                    source={source!} 
                    style={{ width: 112, height: 112 }}
                    className="absolute -top-8 rounded-lg" 
                    resizeMode="contain" 
                />
            )}
            
            <View className="w-full items-center mt-2">
                <Text className="text-center base-bold text-gourmet-charcoal mb-1" numberOfLines={1}>
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

                <Text className="body-medium text-gourmet-amber mb-3">
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
                className="w-full bg-gourmet-forest/5 py-2.5 rounded-lg border border-gourmet-forest/10 flex items-center"
            >
                <Text className="paragraph-bold text-gourmet-forest">Add to Cart</Text>
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

export default MenuCard;
