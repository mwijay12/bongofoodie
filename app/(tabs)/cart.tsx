import { View, Text, FlatList, TextInput, Alert, TouchableOpacity, Modal, Share, Image } from 'react-native'
import { SafeAreaView } from "react-native-safe-area-context";
import React, { useState, useEffect } from 'react';
import { useCartStore } from "@/store/cart.store";
import CustomHeader from "@/components/CustomHeader";
import cn from "clsx";
import CustomButton from "@/components/CustomButton";
import CartItem from "@/components/CartItem";
import { CartItemType, PaymentInfoStripeProps } from "@/type";
import LocationPicker from '@/components/LocationPicker';
import useLocationStore from "@/store/location.store";
import { createOrder, getBranchSettings } from "@/lib/supabaseDb";
import useAuthStore from "@/store/auth.store";
import { router } from "expo-router";
import * as Haptics from 'expo-haptics';
import { Ionicons } from '@expo/vector-icons';
import { images } from "@/constants";

const PaymentInfoStripe = ({ label, value, labelStyle, valueStyle }: PaymentInfoStripeProps) => (
    <View className="flex-between flex-row my-1.5">
        <Text className={cn("paragraph-medium text-gray-200", labelStyle)}>
            {label}
        </Text>
        <Text className={cn("paragraph-bold text-gourmet-charcoal", valueStyle)}>
            {value}
        </Text>
    </View>
);

const Cart = () => {
    const { items, getTotalItems, getTotalPrice, clearCart } = useCartStore();
    const { deliveryLocation, setDeliveryLocation } = useLocationStore();
    const { user } = useAuthStore();

    const totalItems = getTotalItems();
    const totalPrice = getTotalPrice();

    const [confirmedOrder, setConfirmedOrder] = useState<{ id: string; price: number; notes: string; location: string } | null>(null);
    const [settings, setSettings] = useState<any>(null);
    const [paymentMethod, setPaymentMethod] = useState<'cash' | 'lipanamba'>('cash');
    const [notes, setNotes] = useState('');
    const [isCheckingOut, setIsCheckingOut] = useState(false);
    const [promoInput, setPromoInput] = useState('');
    const [promoDiscount, setPromoDiscount] = useState(1000);
    const [promoApplied, setPromoApplied] = useState(false);

    useEffect(() => {
        const fetchSettings = async () => {
            const data = await getBranchSettings();
            if (data) {
                setSettings(data);
            }
        };
        fetchSettings();
    }, []);

    const handleCheckout = async () => {
        if (items.length === 0) return;
        if (!deliveryLocation) {
            Alert.alert("Delivery Location Required", "Please select a dropoff location first.");
            return;
        }

        setIsCheckingOut(true);
        try {
            const userId = user?.$id || null;
            const userName = user?.name || "Guest Customer";
            const userEmail = user?.email || "no-phone@email.com";
            
            const generatedId = `bf-${Math.floor(100000 + Math.random() * 900000)}`;
            const checkoutNotes = notes + (paymentMethod === 'lipanamba' ? ' (Paid via Lipa Namba)' : ' (Cash on Delivery)');
            
            await createOrder({
                id: generatedId,
                profile_id: userId || undefined,
                table_number: checkoutNotes ? `Delivery (${checkoutNotes})` : 'Delivery',
                items: JSON.stringify(items),
                status: 'pending',
                total_price: totalPrice + 3000 - promoDiscount,
                delivery_location: deliveryLocation,
                customer_name: userName,
                customer_email: userEmail
            });

            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

            // Save order confirmation details locally to trigger modal popup
            setConfirmedOrder({
                id: generatedId,
                price: totalPrice + 3000 - promoDiscount,
                notes: checkoutNotes,
                location: deliveryLocation
            });

            clearCart();
            setNotes('');
            
        } catch (error: any) {
            console.error(error);
            Alert.alert("Checkout Error", error.message || "Failed to place your order. Please try again.");
        } finally {
            setIsCheckingOut(false);
        }
    };

    return (
        <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
            <View className="flex-1">
                <FlatList
                    data={items}
                    renderItem={({ item }: { item: CartItemType }) => <CartItem item={item} />}
                    keyExtractor={(item: CartItemType) => item.id}
                    contentContainerClassName="pb-36 px-5 pt-5 max-w-2xl mx-auto w-full"
                    contentContainerStyle={{ paddingBottom: 150 }}
                    ListHeaderComponent={() => <CustomHeader title="Your Cart" />}
                    ListEmptyComponent={() => (
                        <View className="items-center py-10">
                            <Text className="base-regular text-gray-200">Your cart is currently empty.</Text>
                        </View>
                    )}
                    ListFooterComponent={() => totalItems > 0 ? (
                        <View className="gap-5 mt-4">
                            <LocationPicker onLocationSelected={(loc) => setDeliveryLocation(loc)} />

                            {deliveryLocation && (
                                <View className="bg-gourmet-forest/5 border border-gourmet-forest/20 p-5 rounded-xl">
                                    <Text className="small-bold text-gourmet-forest">DELIVERING TO:</Text>
                                    <Text className="paragraph-bold text-gourmet-charcoal mt-1">{deliveryLocation}</Text>
                                </View>
                            )}

                            {/* Promo Code Input Card */}
                            <View className="bg-white border border-gourmet-border p-5 rounded-xl gap-2">
                                <Text className="paragraph-bold text-gourmet-charcoal">Promo Code / Coupon</Text>
                                <View className="flex-row gap-2">
                                    <TextInput
                                        value={promoInput}
                                        onChangeText={setPromoInput}
                                        placeholder="e.g. KARIBU2000"
                                        autoCapitalize="characters"
                                        className="flex-1 bg-gourmet-bone border border-gourmet-border rounded-lg p-2.5 font-quicksand-semibold text-gourmet-charcoal text-xs"
                                        placeholderTextColor="#787774"
                                    />
                                    <TouchableOpacity 
                                        onPress={() => {
                                            if (promoInput.trim().toUpperCase() === 'KARIBU2000') {
                                                setPromoDiscount(2000);
                                                setPromoApplied(true);
                                                Alert.alert("Coupon Applied!", "You saved TSh 2,000 on this order.");
                                            } else {
                                                setPromoDiscount(1000);
                                                setPromoApplied(false);
                                                Alert.alert("Invalid Coupon", "Please check your promo code.");
                                            }
                                        }}
                                        className="bg-gourmet-forest px-4 py-2.5 rounded-lg items-center justify-center"
                                    >
                                        <Text className="text-white text-xs font-quicksand-bold">Apply</Text>
                                    </TouchableOpacity>
                                </View>
                                {promoApplied && (
                                    <Text className="text-[10px] font-quicksand-bold text-success">✓ Coupon KARIBU2000 applied successfully!</Text>
                                )}
                            </View>

                            <View className="bg-white border border-gourmet-border p-5 rounded-xl">
                                <Text className="h3-bold mb-4">
                                    Payment Summary
                                </Text>

                                <PaymentInfoStripe
                                    label={`Total Items (${totalItems})`}
                                    value={`TSh ${totalPrice.toLocaleString()}`}
                                />
                                <PaymentInfoStripe
                                    label={`Delivery Fee`}
                                    value={`TSh 3,000`}
                                />
                                <PaymentInfoStripe
                                    label={`Discount`}
                                    value={`- TSh ${promoDiscount.toLocaleString()}`}
                                    valueStyle="!text-success"
                                />
                                <View className="border-t border-gourmet-border my-3" />
                                <PaymentInfoStripe
                                    label={`Total`}
                                    value={`TSh ${(totalPrice + 3000 - promoDiscount).toLocaleString()}`}
                                    labelStyle="base-bold !text-gourmet-charcoal"
                                    valueStyle="base-bold !text-gourmet-forest !text-right"
                                />
                            </View>

                            {/* Payment Method Selector */}
                            <View className="bg-white border border-gourmet-border p-5 rounded-xl gap-3">
                                <Text className="paragraph-bold text-gourmet-charcoal">Payment Method</Text>
                                <View className="flex-row gap-3">
                                    <TouchableOpacity 
                                        onPress={() => setPaymentMethod('cash')}
                                        className={cn("flex-1 py-3 rounded-lg border flex items-center justify-center", 
                                            paymentMethod === 'cash' ? "border-gourmet-forest bg-gourmet-forest/5" : "border-gourmet-border bg-white"
                                        )}
                                    >
                                        <Text className={cn("paragraph-bold", paymentMethod === 'cash' ? "text-gourmet-forest" : "text-gray-200")}>
                                            Cash on Delivery
                                        </Text>
                                    </TouchableOpacity>
                                    <TouchableOpacity 
                                        onPress={() => setPaymentMethod('lipanamba')}
                                        className={cn("flex-1 py-3 rounded-lg border flex items-center justify-center", 
                                            paymentMethod === 'lipanamba' ? "border-gourmet-forest bg-gourmet-forest/5" : "border-gourmet-border bg-white"
                                        )}
                                    >
                                        <Text className={cn("paragraph-bold", paymentMethod === 'lipanamba' ? "text-gourmet-forest" : "text-gray-200")}>
                                            Lipa Namba
                                        </Text>
                                    </TouchableOpacity>
                                </View>
                            </View>

                            {/* Lipa Namba synced details */}
                            {paymentMethod === 'lipanamba' && settings && (
                                <View className="bg-amber-50/50 border border-amber-200 p-5 rounded-xl gap-2">
                                    <Text className="small-bold text-gourmet-forest text-center mb-2">Active Till Channels</Text>
                                    {settings.mpesa_till && (
                                        <View className="flex-row justify-between my-0.5">
                                            <Text className="body-medium text-gourmet-charcoal">M-Pesa Till:</Text>
                                            <Text className="paragraph-bold text-gourmet-charcoal">{settings.mpesa_till}</Text>
                                        </View>
                                    )}
                                    {settings.tigo_till && (
                                        <View className="flex-row justify-between my-0.5">
                                            <Text className="body-medium text-gourmet-charcoal">Tigo Pesa Till:</Text>
                                            <Text className="paragraph-bold text-gourmet-charcoal">{settings.tigo_till}</Text>
                                        </View>
                                    )}
                                    {settings.airtel_till && (
                                        <View className="flex-row justify-between my-0.5">
                                            <Text className="body-medium text-gourmet-charcoal">Airtel Till:</Text>
                                            <Text className="paragraph-bold text-gourmet-charcoal">{settings.airtel_till}</Text>
                                        </View>
                                    )}
                                    {settings.halo_till && (
                                        <View className="flex-row justify-between my-0.5">
                                            <Text className="body-medium text-gourmet-charcoal">Halopesa Till:</Text>
                                            <Text className="paragraph-bold text-gourmet-charcoal">{settings.halo_till}</Text>
                                        </View>
                                    )}
                                    {settings.nmb_account && (
                                        <View className="flex-row justify-between my-0.5">
                                            <Text className="body-medium text-gourmet-charcoal">NMB Account:</Text>
                                            <Text className="paragraph-bold text-gourmet-charcoal">{settings.nmb_account}</Text>
                                        </View>
                                    )}
                                    {settings.crdb_account && (
                                        <View className="flex-row justify-between my-0.5">
                                            <Text className="body-medium text-gourmet-charcoal">CRDB Account:</Text>
                                            <Text className="paragraph-bold text-gourmet-charcoal">{settings.crdb_account}</Text>
                                        </View>
                                    )}
                                </View>
                            )}

                            {/* Special Instructions */}
                            <View className="bg-white border border-gourmet-border p-5 rounded-xl gap-2">
                                <Text className="paragraph-bold text-gourmet-charcoal">Special Instructions / Transaction Ref</Text>
                                <TextInput
                                    value={notes}
                                    onChangeText={setNotes}
                                    placeholder={paymentMethod === 'lipanamba' ? "Enter Lipa Namba reference code..." : "e.g. Extra hot sauce, delivery directions..."}
                                    className="bg-gourmet-bone border border-gourmet-border rounded-lg p-3 font-quicksand-semibold text-gourmet-charcoal"
                                    placeholderTextColor="#787774"
                                    multiline
                                    numberOfLines={2}
                                />
                            </View>

                            <CustomButton 
                                title="Order Now" 
                                onPress={handleCheckout} 
                                isLoading={isCheckingOut}
                            />
                        </View>
                    ) : null}
                />
            </View>

            {/* Order Confirmation Receipt Modal */}
            <Modal
                visible={confirmedOrder !== null}
                transparent={true}
                animationType="fade"
                onRequestClose={() => setConfirmedOrder(null)}
            >
                <View className="flex-1 bg-black/60 justify-center items-center p-6">
                    <View className="bg-white rounded-3xl w-full max-w-md overflow-hidden p-6 shadow-2xl border border-gourmet-border relative">
                        
                        {/* Header Branding */}
                        <Image 
                            source={images.logo} 
                            style={{ width: 140, height: 45, alignSelf: 'center', marginBottom: 12 }} 
                            resizeMode="contain" 
                        />
                        
                        <View className="items-center mb-4">
                            <View className="size-12 rounded-full bg-success/15 items-center justify-center mb-2">
                                <Ionicons name="checkmark-circle" size={32} color="#15803D" />
                            </View>
                            <Text className="h2-bold text-success">Order Confirmed!</Text>
                            <Text className="body-medium text-gray-200 mt-1">Thank you for ordering Swahili food</Text>
                        </View>
                        
                        {/* Receipt Box */}
                        <View className="bg-gourmet-bone border border-gourmet-border rounded-xl p-4 mb-5">
                            <View className="flex-row justify-between mb-2">
                                <Text className="small-bold text-gray-200">ORDER NUMBER</Text>
                                <Text className="paragraph-bold text-gourmet-charcoal">#{confirmedOrder?.id.toUpperCase()}</Text>
                            </View>
                            <View className="border-t border-dashed border-gourmet-border/60 my-2" />
                            
                            <View className="flex-row justify-between mb-2">
                                <Text className="small-bold text-gray-200">DELIVERY TO</Text>
                                <Text className="paragraph-bold text-gourmet-charcoal flex-1 text-right ml-4" numberOfLines={1}>
                                    {confirmedOrder?.location}
                                </Text>
                            </View>
                            <View className="flex-row justify-between mb-2">
                                <Text className="small-bold text-gray-200">PAYMENT</Text>
                                <Text className="paragraph-bold text-gourmet-charcoal">
                                    {paymentMethod === 'lipanamba' ? 'Lipa Namba' : 'Cash on Delivery'}
                                </Text>
                            </View>
                            <View className="flex-row justify-between">
                                <Text className="small-bold text-gray-200">TOTAL PAID</Text>
                                <Text className="paragraph-bold text-gourmet-forest">TSh {confirmedOrder?.price.toLocaleString()}</Text>
                            </View>
                        </View>

                        {/* Actions */}
                        <View className="gap-3">
                            <TouchableOpacity 
                                onPress={async () => {
                                    if (!confirmedOrder) return;
                                    try {
                                        await Share.share({
                                            message: `🧾 BONGO FOODIE RECEIPT\nOrder ID: #${confirmedOrder.id.toUpperCase()}\nLocation: ${confirmedOrder.location}\nPayment: ${paymentMethod === 'lipanamba' ? 'Lipa Namba' : 'Cash on Delivery'}\nTotal: TSh ${confirmedOrder.price.toLocaleString()}\n\nThank you for choosing Bongo Foodie Swahili restaurant!`,
                                        });
                                    } catch (e) {
                                        console.error(e);
                                    }
                                }}
                                className="w-full py-3.5 bg-gourmet-forest rounded-xl flex-row items-center justify-center gap-2 border border-gourmet-forest/10"
                            >
                                <Ionicons name="share-outline" size={16} color="#FFF" />
                                <Text className="paragraph-bold text-white">Share Receipt</Text>
                            </TouchableOpacity>

                            <TouchableOpacity 
                                onPress={() => {
                                    setConfirmedOrder(null);
                                    router.push("/profile");
                                }}
                                className="w-full py-3 bg-white border border-gourmet-border rounded-xl items-center justify-center"
                            >
                                <Text className="paragraph-bold text-gourmet-charcoal">View Order Status</Text>
                            </TouchableOpacity>

                            <TouchableOpacity 
                                onPress={() => setConfirmedOrder(null)}
                                className="w-full py-2 items-center justify-center"
                            >
                                <Text className="body-medium text-gray-200">Close</Text>
                            </TouchableOpacity>
                        </View>
                    </View>
                </View>
            </Modal>
        </SafeAreaView>
    )
}

export default Cart
