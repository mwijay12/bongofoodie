import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, Image, TouchableOpacity, Alert, ScrollView, Modal, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { signOutUser } from "@/lib/supabaseAuth";
import useAuthStore from "@/store/auth.store";
import useLocationStore from "@/store/location.store";
import LocationPicker from '@/components/LocationPicker';
import { Ionicons } from '@expo/vector-icons';
import { getUserOrders, getUserFavorites, toggleFavorite } from '@/lib/supabaseDb';
import * as Haptics from 'expo-haptics';
import { supabase } from '@/lib/supabase';
import * as Notifications from 'expo-notifications';
import cn from 'clsx';

// Setup global notification handler outside the component
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

// Visual stepper mapping the four milestones (Placed, Kitchen, Delivery, Arrived)
const OrderStatusStepper = ({ currentStatus }: { currentStatus: string }) => {
  const steps = [
    { label: "Placed" },
    { label: "Kitchen" },
    { label: "Delivery" },
    { label: "Arrived" }
  ];

  let activeIndex = 0;
  if (currentStatus === 'preparing') activeIndex = 1;
  else if (currentStatus === 'in_transit' || currentStatus === 'out_for_delivery') activeIndex = 2;
  else if (currentStatus === 'delivered') activeIndex = 3;
  else if (currentStatus === 'cancelled') activeIndex = -1;

  if (currentStatus === 'cancelled') {
    return (
      <View className="bg-red-50 p-2.5 rounded-lg border border-red-100 items-center mt-3">
        <Text className="text-red-600 text-[10px] font-bold uppercase tracking-wider">Order Cancelled</Text>
      </View>
    );
  }

  return (
    <View className="flex-row items-center justify-between mt-3 px-1 py-1">
      {steps.map((step, idx) => {
        const isCompleted = idx <= activeIndex;
        const isCurrent = idx === activeIndex;
        
        return (
          <React.Fragment key={idx}>
            {/* Step circle */}
            <View className="items-center flex-1">
              <View className={cn(
                "size-6 rounded-full items-center justify-center border",
                isCompleted 
                  ? "bg-gourmet-forest border-gourmet-forest" 
                  : "bg-white border-gourmet-border"
              )}>
                {isCompleted ? (
                  <Ionicons name="checkmark" size={12} color="#FFF" />
                ) : (
                  <Text className="text-[10px] font-bold text-gray-200">{idx + 1}</Text>
                )}
              </View>
              <Text className={cn(
                "text-[9px] font-quicksand-bold mt-1 uppercase tracking-wide",
                isCurrent ? "text-gourmet-forest" : (isCompleted ? "text-gourmet-charcoal" : "text-gray-200")
              )}>
                {step.label}
              </Text>
            </View>
            
            {/* Connective line */}
            {idx < steps.length - 1 && (
              <View className={cn(
                "h-0.5 flex-1 -mt-4",
                idx < activeIndex ? "bg-gourmet-forest" : "bg-gourmet-border"
              )} />
            )}
          </React.Fragment>
        );
      })}
    </View>
  );
};

const Profile = () => {
    const { user, setUser, setIsAuthenticated } = useAuthStore();
    const { deliveryLocation, setDeliveryLocation } = useLocationStore();
    const [activeModal, setActiveModal] = useState<'orders' | 'favorites' | 'addresses' | 'help' | 'terms' | null>(null);

    const [orders, setOrders] = useState<any[]>([]);
    const [favorites, setFavorites] = useState<any[]>([]);
    const [loadingOrders, setLoadingOrders] = useState(false);
    const [loadingFavorites, setLoadingFavorites] = useState(false);

    const loadOrders = useCallback(async () => {
        if (!user?.$id) return;
        setLoadingOrders(true);
        try {
            const data = await getUserOrders(user.$id);
            setOrders(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoadingOrders(false);
        }
    }, [user?.$id]);

    const loadFavorites = useCallback(async () => {
        if (!user?.$id) return;
        setLoadingFavorites(true);
        try {
            const data = await getUserFavorites(user.$id);
            setFavorites(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoadingFavorites(false);
        }
    }, [user?.$id]);

    useEffect(() => {
        if (user?.$id) {
            loadOrders();
            loadFavorites();
        }
    }, [user?.$id, loadOrders, loadFavorites]);

    useEffect(() => {
        // Reload when modals open to ensure fresh data
        if (activeModal === 'orders') {
            loadOrders();
        } else if (activeModal === 'favorites') {
            loadFavorites();
        }
    }, [activeModal, loadOrders, loadFavorites]);

    // Request notification permissions
    useEffect(() => {
        const reqPermissions = async () => {
            const { status } = await Notifications.getPermissionsAsync();
            if (status !== 'granted') {
                await Notifications.requestPermissionsAsync();
            }
        };
        reqPermissions();
    }, []);

    // Subscribe to realtime order status modifications
    useEffect(() => {
        if (!user?.$id) return;

        const channel = supabase
            .channel(`user-orders-${user.$id}`)
            .on(
                'postgres_changes',
                {
                    event: 'UPDATE',
                    schema: 'public',
                    table: 'orders',
                    filter: `profile_id=eq.${user.$id}`
                },
                async (payload: any) => {
                    console.log('[Supabase Realtime Order Update]', payload.new);
                    
                    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                    
                    // Update state locally
                    setOrders(prev => prev.map(o => o.id === payload.new.id ? { ...o, ...payload.new } : o));
                    
                    // Schedule notification banner
                    await Notifications.scheduleNotificationAsync({
                        content: {
                            title: "Bongo Foodie Status Update! 🍽️",
                            body: `Your order #${payload.new.id.slice(0, 6).toUpperCase()} is now [${payload.new.status.toUpperCase()}].`,
                        },
                        trigger: null,
                    });
                }
            )
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, [user?.$id]);

    const handleRemoveFavorite = async (menuId: string) => {
        if (!user?.$id) return;
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
        try {
            await toggleFavorite(user.$id, menuId);
            setFavorites(prev => prev.filter(item => item.$id !== menuId));
        } catch (e) {
            Alert.alert("Error", "Could not remove favorite.");
        }
    };

    const handleLogout = async () => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        Alert.alert(
            "Confirm Sign Out",
            "Are you sure you want to sign out of Bongo Foodie?",
            [
                { text: "Cancel", style: "cancel" },
                {
                    text: "Sign Out",
                    style: "destructive",
                    onPress: async () => {
                        try {
                            await signOutUser();
                            setUser(null);
                            setIsAuthenticated(false);
                        } catch (error: any) {
                            Alert.alert("Error", error.message || "Failed to sign out.");
                        }
                    }
                }
            ]
        );
    };

    const profileMenuItems = [
        { icon: "receipt-outline" as const, title: "My Orders", subtitle: "Track and view past orders", type: 'orders' as const },
        { icon: "heart-outline" as const, title: "Favorite Dishes", subtitle: "Your top rated Swahili meals", type: 'favorites' as const },
        { icon: "location-outline" as const, title: "Delivery Addresses", subtitle: "Manage your dropoff locations", type: 'addresses' as const },
        { icon: "card-outline" as const, title: "Payment Methods", subtitle: "Add or remove payment options", type: null },
        { icon: "help-circle-outline" as const, title: "Help & Support", subtitle: "FAQs, chat support, and contact info", type: 'help' as const },
        { icon: "document-text-outline" as const, title: "Terms & Conditions", subtitle: "User agreement and privacy policy", type: 'terms' as const },
    ];

    const avatarUrl = user?.avatar_url || null;
    const nameLetter = user?.name ? user.name.charAt(0).toUpperCase() : "B";

    return (
        <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
            {/* Sticky Header */}
            <View className="flex-row justify-between items-center px-5 pt-3 pb-3 bg-[#FBFBFA] border-b border-gourmet-border/30 z-20">
                <Text className="h1-bold">My Profile</Text>
                <TouchableOpacity onPress={handleLogout} className="p-2 rounded-full bg-red-50">
                    <Ionicons name="log-out-outline" size={24} color="#EF4444" />
                </TouchableOpacity>
            </View>

            <ScrollView 
                contentContainerClassName="pb-36 px-5 pt-4 max-w-2xl mx-auto w-full" 
                contentContainerStyle={{ paddingBottom: 150 }}
                showsVerticalScrollIndicator={false}
            >

                {/* Profile Card */}
                <View className="bg-white border border-gourmet-border rounded-2xl p-6 items-center mb-8 shadow-sm">
                    {avatarUrl ? (
                        <Image 
                            source={{ uri: avatarUrl }} 
                            className="size-24 rounded-full mb-4 border-2 border-gourmet-forest"
                            resizeMode="cover"
                        />
                    ) : (
                        <View className="size-24 rounded-full bg-gourmet-forest flex items-center justify-center mb-4">
                            <Text className="text-white text-3xl font-quicksand-bold">{nameLetter}</Text>
                        </View>
                    )}
                    
                    <Text className="h2-bold text-center mb-1 text-gourmet-charcoal">
                        {user?.name || 'Bongo Foodie User'}
                    </Text>
                    <Text className="body-regular text-center text-gray-200">
                        {user?.email || 'user@bongofoodie.com'}
                    </Text>
                </View>

                {/* Quick Stats Grid */}
                <View className="flex-row gap-3 mb-8">
                    <View className="flex-1 bg-gourmet-bone border border-gourmet-border p-4 rounded-xl items-center">
                        <Text className="text-xl font-quicksand-bold text-gourmet-forest">{orders.length}</Text>
                        <Text className="text-xs text-gray-200 mt-1">Total Orders</Text>
                    </View>
                    <View className="flex-1 bg-gourmet-bone border border-gourmet-border p-4 rounded-xl items-center">
                        <Text className="text-xl font-quicksand-bold text-gourmet-amber">{favorites.length}</Text>
                        <Text className="text-xs text-gray-200 mt-1">Favorite Dishes</Text>
                    </View>
                </View>

                {/* Menu List */}
                <View className="bg-white border border-gourmet-border rounded-2xl overflow-hidden mb-6">
                    {profileMenuItems.map((item, index) => (
                        <TouchableOpacity 
                            key={index} 
                            onPress={() => {
                                if (item.type) {
                                    setActiveModal(item.type);
                                } else {
                                    Alert.alert("Coming Soon", `${item.title} integration is under active development.`);
                                }
                            }}
                            className={`flex-row items-center p-4 border-b border-gourmet-border ${index === profileMenuItems.length - 1 ? 'border-b-0' : ''}`}
                        >
                            <View className="size-10 rounded-lg bg-gourmet-bone items-center justify-center mr-4">
                                <Ionicons name={item.icon} size={20} color="#F6821F" />
                            </View>
                            <View className="flex-1">
                                <Text className="paragraph-bold text-gourmet-charcoal">{item.title}</Text>
                                <Text className="text-xs text-gray-200 mt-0.5">{item.subtitle}</Text>
                            </View>
                            <Ionicons name="chevron-forward" size={16} color="#C4C4C4" />
                        </TouchableOpacity>
                    ))}
                </View>

                {/* Developer Credits */}
                <View className="mt-6 pt-4 border-t border-gourmet-border/30 items-center">
                    <Text className="text-[10px] text-gray-200/60 text-center leading-relaxed">
                        Built by <Text className="text-gourmet-forest font-bold">Mwijay Davie</Text>
                    </Text>
                    <View className="flex-row items-center gap-3 mt-1">
                        <Text className="text-[10px] text-gray-200/60">📞 0790942616</Text>
                        <Text className="text-[10px] text-gray-200/60">✉️ mwijaydavie@gmail.com</Text>
                    </View>
                </View>

                {/* Version Info */}
                <Text className="text-center text-xs text-gray-200/60 mt-2">
                    Bongo Foodie v1.0.0
                </Text>
            </ScrollView>

            {/* Modal for Profile Sections */}
            <Modal
                visible={activeModal !== null}
                animationType="slide"
                transparent={true}
                onRequestClose={() => setActiveModal(null)}
            >
                <View className="flex-1 justify-end bg-gourmet-charcoal/50">
                    <View className="bg-white rounded-t-3xl min-h-[60%] max-h-[85%] p-6">
                        
                        {/* Modal Header */}
                        <View className="flex-row justify-between items-center mb-6">
                            <Text className="h2-bold text-gourmet-charcoal">
                                {activeModal === 'orders' && "My Orders"}
                                {activeModal === 'favorites' && "Favorite Dishes"}
                                {activeModal === 'addresses' && "Delivery Settings"}
                                {activeModal === 'help' && "Help & Support"}
                                {activeModal === 'terms' && "Terms & Conditions"}
                            </Text>
                            <TouchableOpacity 
                                onPress={() => setActiveModal(null)}
                                className="size-8 rounded-full bg-gourmet-bone items-center justify-center"
                            >
                                <Ionicons name="close" size={20} color="#F6821F" />
                            </TouchableOpacity>
                        </View>

                        {/* Modal Content */}
                        <ScrollView showsVerticalScrollIndicator={false}>
                            {activeModal === 'orders' && (
                                <View className="gap-4">
                                    {loadingOrders ? (
                                        <ActivityIndicator size="small" color="#F6821F" />
                                    ) : orders.length === 0 ? (
                                        <Text className="text-center text-xs text-gray-200 py-6">You have no orders yet.</Text>
                                    ) : (
                                        orders.map((ord) => {
                                            const parsedItems = typeof ord.items === 'string' ? JSON.parse(ord.items) : (ord.items || []);
                                            const itemsString = parsedItems.map((item: any) => `${item.name} x${item.quantity}`).join(', ');
                                            const statusMap: Record<string, string> = {
                                                pending: "Pending",
                                                preparing: "Kitchen",
                                                in_transit: "In Transit",
                                                delivered: "Delivered",
                                                cancelled: "Cancelled",
                                            };
                                            const displayStatus = statusMap[ord.status] || ord.status;
                                            return (
                                                <View key={ord.id} className="bg-gourmet-bone border border-gourmet-border p-4 rounded-xl">
                                                    <View className="flex-row justify-between items-center mb-2">
                                                        <Text className="paragraph-bold text-gourmet-charcoal">Order #{ord.id.slice(0, 6).toUpperCase()}</Text>
                                                        <Text className="text-xs text-gourmet-forest font-bold">{displayStatus}</Text>
                                                    </View>
                                                    <Text className="text-xs text-gray-200 mb-1">
                                                        {new Date(ord.created_at).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}
                                                    </Text>
                                                    <Text className="paragraph-medium text-gourmet-charcoal mb-2">{itemsString}</Text>
                                                    <Text className="paragraph-bold text-gourmet-amber">TSh {Number(ord.total_price).toLocaleString()}</Text>
                                                    
                                                    {/* Visual Stepper tracker bar */}
                                                    <OrderStatusStepper currentStatus={ord.status} />
                                                </View>
                                            );
                                        })
                                    )}
                                </View>
                            )}

                            {activeModal === 'favorites' && (
                                <View className="gap-4">
                                    {loadingFavorites ? (
                                        <ActivityIndicator size="small" color="#F6821F" />
                                    ) : favorites.length === 0 ? (
                                        <Text className="text-center text-xs text-gray-200 py-6">No favorites added yet.</Text>
                                    ) : (
                                        favorites.map((fav) => (
                                            <View key={fav.$id} className="flex-row bg-gourmet-bone border border-gourmet-border p-4 rounded-xl items-center justify-between">
                                                <View className="flex-1 pr-4">
                                                    <View className="flex-row items-center gap-2 mb-1">
                                                        <Text className="paragraph-bold text-gourmet-charcoal">{fav.name}</Text>
                                                        {fav.rating ? (
                                                            <Text className="text-xs text-gourmet-amber font-bold">{fav.rating}★</Text>
                                                        ) : null}
                                                    </View>
                                                    <Text className="text-xs text-gray-200 mb-2" numberOfLines={1}>{fav.description}</Text>
                                                    <Text className="paragraph-bold text-gourmet-forest">TSh {fav.price.toLocaleString()}</Text>
                                                </View>
                                                <TouchableOpacity 
                                                    onPress={() => handleRemoveFavorite(fav.$id)}
                                                    className="bg-red-50 p-2.5 rounded-lg border border-red-100"
                                                >
                                                    <Ionicons name="heart" size={18} color="#EF4444" />
                                                </TouchableOpacity>
                                            </View>
                                        ))
                                    )}
                                </View>
                            )}

                            {activeModal === 'addresses' && (
                                <View className="pb-10">
                                    <Text className="text-xs text-gray-200 mb-3">
                                        Choose your delivery region, district, and ward or use GPS. Your selection will update across Bongo Foodie.
                                    </Text>
                                    <LocationPicker onLocationSelected={(loc) => setDeliveryLocation(loc)} />
                                    
                                    <View className="bg-gourmet-forest/5 border border-gourmet-forest/20 p-5 rounded-xl mt-5">
                                        <Text className="small-bold text-gourmet-forest">CURRENT SET ADDRESS:</Text>
                                        <Text className="paragraph-bold text-gourmet-charcoal mt-1">{deliveryLocation}</Text>
                                    </View>
                                </View>
                            )}

                            {activeModal === 'help' && (
                                <View className="p-4 bg-gourmet-bone border border-gourmet-border rounded-xl">
                                    <Text className="paragraph-bold text-gourmet-charcoal mb-2">Bongo Foodie Support</Text>
                                    <Text className="text-xs text-gray-200 mb-4 leading-relaxed">
                                        Need help with an order or have culinary questions? Contact our Dar es Salaam headquarters directly.
                                    </Text>
                                    <View className="gap-2.5">
                                        <View className="flex-row items-center">
                                            <Ionicons name="call" size={16} color="#F6821F" style={{ marginRight: 8 }} />
                                            <Text className="paragraph-medium text-gourmet-charcoal">+255 712 345 678</Text>
                                        </View>
                                        <View className="flex-row items-center">
                                            <Ionicons name="mail" size={16} color="#F6821F" style={{ marginRight: 8 }} />
                                            <Text className="paragraph-medium text-gourmet-charcoal">support@bongofoodie.com</Text>
                                        </View>
                                        <View className="flex-row items-center">
                                            <Ionicons name="time" size={16} color="#F6821F" style={{ marginRight: 8 }} />
                                            <Text className="paragraph-medium text-gourmet-charcoal">Daily: 08:00 AM - 10:00 PM</Text>
                                        </View>
                                    </View>
                                </View>
                            )}

                            {activeModal === 'terms' && (
                                <View className="p-4 bg-gourmet-bone border border-gourmet-border rounded-xl">
                                    <Text className="paragraph-bold text-gourmet-charcoal mb-2">User Service Terms</Text>
                                    <Text className="text-xs text-gray-200 leading-relaxed space-y-2">
                                        1. Deliveries are estimated and subject to Dar traffic.{"\n"}
                                        2. Digital payments must settle to admin Till channels.{"\n"}
                                        3. Chef AI suggests custom recipes; check allergies independently.
                                    </Text>
                                </View>
                            )}
                        </ScrollView>
                    </View>
                </View>
            </Modal>
        </SafeAreaView>
    );
};

export default Profile;
