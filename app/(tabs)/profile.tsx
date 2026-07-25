import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, Image, TouchableOpacity, Alert, ScrollView, Modal, ActivityIndicator, Switch } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { signOutUser } from "@/lib/supabaseAuth";
import useAuthStore from "@/store/auth.store";
import useLocationStore from "@/store/location.store";
import LocationPicker from '@/components/LocationPicker';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { getUserOrders, getUserFavorites, toggleFavorite, getUserAnalytics, getUserSettings, upsertUserSettings } from '@/lib/supabaseDb';
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

// Achievements Component
const AchievementsSection = ({ ordersCount, favoritesCount }: { ordersCount: number; favoritesCount: number }) => {
  const achievements = [
    {
      id: 'member',
      name: 'Mwana Jumuia',
      description: 'Registered account on Bongo Foodie',
      icon: 'shield-checkmark-outline' as const,
      unlocked: true,
      progressMax: 1,
      progressCurrent: 1,
    },
    {
      id: 'first_order',
      name: 'First Bite',
      description: 'Placed your first order',
      icon: 'restaurant-outline' as const,
      unlocked: ordersCount >= 1,
      progressMax: 1,
      progressCurrent: Math.min(ordersCount, 1),
    },
    {
      id: 'five_orders',
      name: 'Mzee wa Meza',
      description: 'Placed 5 orders',
      icon: 'trophy-outline' as const,
      unlocked: ordersCount >= 5,
      progressMax: 5,
      progressCurrent: Math.min(ordersCount, 5),
    },
    {
      id: 'ten_orders',
      name: 'Balozi wa Bongo',
      description: 'Placed 10 orders',
      icon: 'trophy-outline' as const,
      unlocked: ordersCount >= 10,
      progressMax: 10,
      progressCurrent: Math.min(ordersCount, 10),
    },
    {
      id: 'fav_foodie',
      name: 'Foodie Collector',
      description: 'Added 3 favorite dishes',
      icon: 'heart-outline' as const,
      unlocked: favoritesCount >= 3,
      progressMax: 3,
      progressCurrent: Math.min(favoritesCount, 3),
    },
    {
      id: 'explorer',
      name: 'Menu Explorer',
      description: 'Browse the full menu',
      icon: 'compass-outline' as const,
      unlocked: true,
      progressMax: 1,
      progressCurrent: 1,
    },
  ];

  const unlockedCount = achievements.filter(a => a.unlocked).length;

  return (
    <View className="bg-white border border-gourmet-border rounded-2xl p-5 mb-6">
      <View className="flex-row items-center justify-between mb-4">
        <View className="flex-row items-center gap-2">
          <Ionicons name="trophy" size={20} color="#F6821F" />
          <Text className="h3-bold">Achievements</Text>
        </View>
        <View className="bg-gourmet-amber/10 px-2.5 py-1 rounded-full">
          <Text className="text-[10px] font-quicksand-bold text-gourmet-amber">
            {unlockedCount} / {achievements.length}
          </Text>
        </View>
      </View>

      <View className="gap-3">
        {achievements.map((badge) => {
          const IconName = badge.icon;
          return (
            <View
              key={badge.id}
              className={cn(
                "flex-row items-center p-3.5 rounded-xl border",
                badge.unlocked
                  ? "bg-gourmet-forest/5 border-gourmet-forest/20"
                  : "bg-white border-gourmet-border/40 opacity-60"
              )}
            >
              <View className={cn(
                "size-10 rounded-xl items-center justify-center mr-3",
                badge.unlocked ? "bg-gourmet-forest/10" : "bg-gourmet-bone"
              )}>
                <Ionicons
                  name={IconName}
                  size={20}
                  color={badge.unlocked ? "#1B5E20" : "#C4C4C4"}
                />
              </View>
              <View className="flex-1">
                <Text className={cn(
                  "paragraph-bold",
                  badge.unlocked ? "text-gourmet-charcoal" : "text-gray-200"
                )}>
                  {badge.name}
                </Text>
                <Text className="text-[10px] text-gray-200 mt-0.5">{badge.description}</Text>
                {/* Progress bar */}
                <View className="w-full bg-gourmet-border/40 rounded-full h-1.5 mt-2 overflow-hidden">
                  <View
                    className="bg-gourmet-forest h-1.5 rounded-full"
                    style={{ width: `${(badge.progressCurrent / badge.progressMax) * 100}%` }}
                  />
                </View>
                <Text className="text-[8px] text-gray-200 mt-0.5">
                  {badge.progressCurrent}/{badge.progressMax}
                </Text>
              </View>
              <View className="ml-2">
                {badge.unlocked ? (
                  <Ionicons name="checkmark-circle" size={20} color="#1B5E20" />
                ) : (
                  <Ionicons name="lock-closed" size={16} color="#C4C4C4" />
                )}
              </View>
            </View>
          );
        })}
      </View>
    </View>
  );
};

// Analytics Component
const AnalyticsSection = ({ analytics }: { analytics: any }) => {
  const stats = [
    { label: 'Total Orders', value: analytics.totalOrders, icon: 'receipt-outline' as const, color: '#F6821F' },
    { label: 'Completed', value: analytics.completedOrders, icon: 'checkmark-circle-outline' as const, color: '#1B5E20' },
    { label: 'Total Spent', value: `TSh ${(analytics.totalSpent || 0).toLocaleString()}`, icon: 'cash-outline' as const, color: '#F6821F' },
    { label: 'Favorites', value: analytics.totalFavorites, icon: 'heart-outline' as const, color: '#EF4444' },
    { label: 'Quiz Score', value: `${analytics.quizCorrect}/${analytics.quizTotal}`, icon: 'bulb-outline' as const, color: '#F6821F' },
  ];

  return (
    <View className="bg-white border border-gourmet-border rounded-2xl p-5 mb-6">
      <View className="flex-row items-center gap-2 mb-4">
        <Ionicons name="stats-chart" size={20} color="#F6821F" />
        <Text className="h3-bold">Analytics</Text>
      </View>
      <View className="flex-row flex-wrap gap-3">
        {stats.map((stat, idx) => (
          <View key={idx} className="w-[30%] flex-1 bg-gourmet-bone border border-gourmet-border/60 p-3 rounded-xl items-center min-w-[80px]">
            <Ionicons name={stat.icon} size={18} color={stat.color} />
            <Text className="text-lg font-quicksand-bold text-gourmet-charcoal mt-1">{stat.value}</Text>
            <Text className="text-[9px] text-gray-200 mt-0.5 text-center">{stat.label}</Text>
          </View>
        ))}
      </View>
    </View>
  );
};

// Settings Component (Notification Controls)
const SettingsSection = ({ userId }: { userId: string }) => {
  const [settings, setSettings] = useState({
    push_notifications: true,
    email_notifications: true,
    sms_notifications: false,
    order_updates: true,
    promotional_offers: true,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      if (!userId) return;
      const data = await getUserSettings(userId);
      if (data) {
        setSettings({
          push_notifications: data.push_notifications ?? true,
          email_notifications: data.email_notifications ?? true,
          sms_notifications: data.sms_notifications ?? false,
          order_updates: data.order_updates ?? true,
          promotional_offers: data.promotional_offers ?? true,
        });
      }
      setLoading(false);
    };
    load();
  }, [userId]);

  const toggleSetting = async (key: string, value: boolean) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const newSettings = { ...settings, [key]: value };
    setSettings(newSettings);
    try {
      await upsertUserSettings(userId, newSettings);
    } catch (e) {
      console.error('[Settings] Error saving:', e);
    }
  };

  const toggles = [
    { key: 'push_notifications', label: 'Push Notifications', icon: 'notifications-outline' as const },
    { key: 'email_notifications', label: 'Email Notifications', icon: 'mail-outline' as const },
    { key: 'sms_notifications', label: 'SMS Notifications', icon: 'chatbubble-outline' as const },
    { key: 'order_updates', label: 'Order Updates', icon: 'receipt-outline' as const },
    { key: 'promotional_offers', label: 'Promotional Offers', icon: 'pricetag-outline' as const },
  ];

  if (loading) {
    return (
      <View className="bg-white border border-gourmet-border rounded-2xl p-5 mb-6">
        <View className="flex-row items-center gap-2 mb-4">
          <Ionicons name="settings-outline" size={20} color="#F6821F" />
          <Text className="h3-bold">Notification Settings</Text>
        </View>
        <ActivityIndicator size="small" color="#F6821F" />
      </View>
    );
  }

  return (
    <View className="bg-white border border-gourmet-border rounded-2xl p-5 mb-6">
      <View className="flex-row items-center gap-2 mb-4">
        <Ionicons name="settings-outline" size={20} color="#F6821F" />
        <Text className="h3-bold">Notification Settings</Text>
      </View>
      <View className="gap-1">
        {toggles.map((item) => (
          <View key={item.key} className="flex-row items-center justify-between py-3 border-b border-gourmet-border/30 last:border-b-0">
            <View className="flex-row items-center gap-3">
              <Ionicons name={item.icon} size={18} color="#F6821F" />
              <Text className="paragraph-medium text-gourmet-charcoal">{item.label}</Text>
            </View>
            <Switch
              value={(settings as any)[item.key]}
              onValueChange={(val) => toggleSetting(item.key, val)}
              trackColor={{ false: '#E5E7EB', true: '#1B5E20' }}
              thumbColor={(settings as any)[item.key] ? '#FFFFFF' : '#F4F3F4'}
              ios_backgroundColor="#E5E7EB"
            />
          </View>
        ))}
      </View>
    </View>
  );
};

const Profile = () => {
    const { user, setUser, setIsAuthenticated } = useAuthStore();
    const { deliveryLocation, setDeliveryLocation } = useLocationStore();
    const [activeModal, setActiveModal] = useState<'orders' | 'favorites' | 'addresses' | 'help' | 'terms' | 'discoveries' | 'settings' | null>(null);

    const [orders, setOrders] = useState<any[]>([]);
    const [favorites, setFavorites] = useState<any[]>([]);
    const [loadingOrders, setLoadingOrders] = useState(false);
    const [loadingFavorites, setLoadingFavorites] = useState(false);
    const [analytics, setAnalytics] = useState<any>(null);
    const [analyticsLoading, setAnalyticsLoading] = useState(true);

    const userId = user?.$id || user?.id;

    const loadOrders = useCallback(async () => {
        if (!userId) return;
        setLoadingOrders(true);
        try {
            const data = await getUserOrders(userId);
            setOrders(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoadingOrders(false);
        }
    }, [userId]);

    const loadFavorites = useCallback(async () => {
        if (!userId) return;
        setLoadingFavorites(true);
        try {
            const data = await getUserFavorites(userId);
            setFavorites(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoadingFavorites(false);
        }
    }, [userId]);

    const loadAnalytics = useCallback(async () => {
        if (!userId) return;
        setAnalyticsLoading(true);
        try {
            const data = await getUserAnalytics(userId);
            setAnalytics(data);
        } catch (e) {
            console.error(e);
        } finally {
            setAnalyticsLoading(false);
        }
    }, [userId]);

    useEffect(() => {
        if (userId) {
            loadOrders();
            loadFavorites();
            loadAnalytics();
        }
    }, [userId, loadOrders, loadFavorites, loadAnalytics]);

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
        if (!userId) return;

        const channel = supabase
            .channel(`user-orders-${userId}`)
            .on(
                'postgres_changes',
                {
                    event: 'UPDATE',
                    schema: 'public',
                    table: 'orders',
                    filter: `profile_id=eq.${userId}`
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
    }, [userId]);

    const handleRemoveFavorite = async (menuId: string) => {
        if (!userId) return;
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
        try {
            await toggleFavorite(userId, menuId);
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

    const isAdmin = user?.email === 'defoodordering@gmail.com';

    const baseMenuItems: Array<{
      icon: "receipt-outline" | "heart-outline" | "location-outline" | "card-outline" | "bulb-outline" | "settings-outline" | "help-circle-outline" | "document-text-outline";
      title: string;
      subtitle: string;
      type: 'orders' | 'favorites' | 'addresses' | 'settings' | 'help' | 'terms' | 'discoveries' | null;
    }> = [
        { icon: "receipt-outline", title: "My Orders", subtitle: "Track and view past orders", type: 'orders' },
        { icon: "heart-outline", title: "Favorite Dishes", subtitle: "Your top rated Swahili meals", type: 'favorites' },
        { icon: "location-outline", title: "Delivery Addresses", subtitle: "Manage your dropoff locations", type: 'addresses' },
        { icon: "card-outline", title: "Payment Methods", subtitle: "Add or remove payment options", type: null },
        { icon: "settings-outline", title: "Settings", subtitle: "Notifications, preferences & more", type: 'settings' },
        { icon: "help-circle-outline", title: "Help & Support", subtitle: "FAQs, chat support, and contact info", type: 'help' },
        { icon: "document-text-outline", title: "Terms & Conditions", subtitle: "User agreement and privacy policy", type: 'terms' },
    ];

    const adminItem = isAdmin ? [{ icon: "bulb-outline" as const, title: "Manage Daily Discoveries", subtitle: "Add, edit, or remove culinary facts", type: 'discoveries' as const }] : [];
    const profileMenuItems = [...baseMenuItems.slice(0, 5), ...adminItem, ...baseMenuItems.slice(5)];

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

                {/* Analytics Section */}
                {analyticsLoading ? (
                    <View className="bg-white border border-gourmet-border rounded-2xl p-5 mb-6 items-center">
                        <ActivityIndicator size="small" color="#F6821F" />
                    </View>
                ) : analytics && (
                    <AnalyticsSection analytics={analytics} />
                )}

                {/* Achievements Section */}
                <AchievementsSection 
                  ordersCount={orders.length} 
                  favoritesCount={favorites.length} 
                />

                {/* Menu List */}
                <View className="bg-white border border-gourmet-border rounded-2xl overflow-hidden mb-6">
                    {profileMenuItems.map((item, index) => (
                        <TouchableOpacity 
                            key={index} 
                            onPress={() => {
                                if (item.type === 'discoveries') {
                                    router.push('/admin-discoveries');
                                } else if (item.type) {
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
                                {activeModal === 'settings' && "Settings"}
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

                            {activeModal === 'settings' && userId && (
                                <SettingsSection userId={userId} />
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