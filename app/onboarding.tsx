import React, { useState } from 'react';
import { View, Text, ImageBackground, TouchableOpacity, StyleSheet, TextInput, Modal, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Redirect, router } from "expo-router";
import useAuthStore from "@/store/auth.store";
import { images } from "@/constants";
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';

const ONBOARDING_STEPS = [
  {
    title: "Build your Flavor,",
    highlight: "Step by Step",
    description: "Stack fresh organic ingredients for Swahili gourmet meals prepared exactly your way.",
    image: images.burgerOne,
  },
  {
    title: "Exceptional Food,",
    highlight: "Delivered Fresh",
    description: "Thoughtfully prepared coastal delicacies and Tanzanian favorites delivered fresh to your doorstep.",
    image: images.chefOnboarding,
  },
  {
    title: "Discover & Play",
    highlight: "Culinary Trivia",
    description: "Explore Zanzibar spice histories, solve Swahili food trivia, and enjoy dining benefits.",
    image: images.samakiWaKupaka,
  }
];

export default function Onboarding() {
    const { isAuthenticated, setPhoneNumber } = useAuthStore();
    const [step, setStep] = useState(0);

    // Onboarding validations state
    const [phone, setPhone] = useState("");
    const [agreedToTerms, setAgreedToTerms] = useState(false);
    const [showTermsModal, setShowTermsModal] = useState(false);

    if (isAuthenticated) {
        return <Redirect href="/" />;
    }

    const currentData = ONBOARDING_STEPS[step];

    const isNextDisabled = step === 2 && (phone.trim().length < 9 || !agreedToTerms);

    const handleNext = () => {
        if (step < ONBOARDING_STEPS.length - 1) {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            setStep(prev => prev + 1);
        } else {
            if (isNextDisabled) return;
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            // Cache the onboarding phone number globally so it is available during sign-up
            setPhoneNumber(phone.trim());
            router.push("/sign-in");
        }
    };

    const handleBack = () => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        if (step > 0) {
            setStep(prev => prev - 1);
        }
    };

    const handleSkip = () => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        router.push("/sign-in");
    };

    return (
        <ImageBackground 
            source={currentData.image} 
            className="flex-1"
            resizeMode="cover"
        >
            {/* Vignette Overlay */}
            <View className="absolute inset-0 bg-black/60" />

            <SafeAreaView className="flex-1 justify-between px-6 py-8">
                {/* Top Section: Progress Bar & Skip */}
                <View className="w-full">
                    {/* Progress Bar Segments */}
                    <View className="flex-row gap-x-2 w-full px-2 mb-6">
                        {ONBOARDING_STEPS.map((_, idx) => (
                            <View 
                                key={idx} 
                                className={`h-1.5 flex-1 rounded-full ${
                                    idx === step ? 'bg-gourmet-amber' : 'bg-white/30'
                                }`} 
                            />
                        ))}
                    </View>

                    {/* Header Row */}
                    <View className="flex-row justify-between items-center w-full px-2">
                        <Text className="font-quicksand-bold text-white text-lg tracking-widest uppercase">
                            Bongo<Text className="text-gourmet-amber">Foodie</Text>
                        </Text>
                        
                        <TouchableOpacity onPress={handleSkip} className="px-4 py-1.5 rounded-full bg-white/10 border border-white/20">
                            <Text className="text-white text-xs font-quicksand-bold">Skip</Text>
                        </TouchableOpacity>
                    </View>
                </View>

                {/* Bottom Welcome Content */}
                <View className="w-full gap-y-6 mb-4">
                    <View className="gap-y-2">
                        <Text className="text-white text-4xl font-quicksand-bold leading-tight">
                            {currentData.title}{"\n"}
                            <Text className="text-gourmet-amber font-quicksand-bold">{currentData.highlight}</Text>
                        </Text>
                        <Text className="text-white/80 text-base font-quicksand-medium leading-relaxed">
                            {currentData.description}
                        </Text>
                    </View>

                    {/* Step 3 input and terms checkbox */}
                    {step === 2 && (
                        <View className="w-full gap-y-3 mt-1 bg-black/40 p-4 rounded-2xl border border-white/10">
                            <Text className="text-white/80 font-quicksand-bold text-xs uppercase tracking-wider">Verification details</Text>
                            
                            <View className="w-full bg-white/15 border border-white/20 rounded-xl px-4 flex-row items-center h-12">
                                <Ionicons name="call" size={16} color="#FFF" style={{ marginRight: 8 }} />
                                <TextInput
                                    value={phone}
                                    onChangeText={setPhone}
                                    placeholder="Enter phone number (e.g. 0712345678)"
                                    placeholderTextColor="#A0A0A0"
                                    keyboardType="phone-pad"
                                    className="flex-1 h-full text-white font-quicksand-semibold text-sm"
                                />
                            </View>

                            <TouchableOpacity 
                                onPress={() => {
                                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                    setAgreedToTerms(prev => !prev);
                                }}
                                className="flex-row items-center w-full mt-1 pr-4"
                            >
                                <Ionicons 
                                    name={agreedToTerms ? "checkbox" : "checkbox-outline"} 
                                    size={22} 
                                    color={agreedToTerms ? "#F6821F" : "#FFFFFF"} 
                                />
                                <Text className="text-white text-xs font-quicksand-semibold ml-2 leading-relaxed">
                                    I agree to the{" "}
                                    <Text 
                                        onPress={(e) => {
                                            e.stopPropagation();
                                            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                                            setShowTermsModal(true);
                                        }}
                                        className="text-gourmet-amber font-quicksand-bold underline"
                                    >
                                        Terms & Conditions
                                    </Text>
                                </Text>
                            </TouchableOpacity>
                        </View>
                    )}

                    {/* Navigation Buttons Row */}
                    <View className="flex-row gap-x-3 items-center w-full">
                        {/* Back Button (shown from Step 1 onwards) */}
                        {step > 0 && (
                            <TouchableOpacity 
                                onPress={handleBack}
                                activeOpacity={0.8}
                                className="size-14 rounded-full bg-white/10 border border-white/20 items-center justify-center"
                            >
                                <Ionicons name="arrow-back" size={22} color="#FFFFFF" />
                            </TouchableOpacity>
                        )}

                        {/* Next / Proceed Button */}
                        <TouchableOpacity 
                            onPress={handleNext}
                            activeOpacity={isNextDisabled ? 1 : 0.85}
                            disabled={isNextDisabled}
                            className={`flex-1 border p-2.5 rounded-full flex-row items-center justify-between ${
                                isNextDisabled ? 'bg-white/5 border-white/10 opacity-50' : 'bg-white/10 border-white/20'
                            }`}
                            style={styles.blurContainer}
                        >
                            <Text className="text-white font-quicksand-bold text-lg pl-6">
                                {step === ONBOARDING_STEPS.length - 1 ? "Get Started" : "Next"}
                            </Text>
                            <View className={`size-12 rounded-full items-center justify-center shadow-md ${
                                isNextDisabled ? 'bg-gray-400' : 'bg-gourmet-amber'
                            }`}>
                                <Ionicons name="arrow-forward" size={22} color="#FFFFFF" />
                            </View>
                        </TouchableOpacity>
                    </View>
                </View>
            </SafeAreaView>

            {/* Terms & Conditions Modal */}
            <Modal
                visible={showTermsModal}
                animationType="slide"
                transparent={true}
                onRequestClose={() => setShowTermsModal(false)}
            >
                <View className="flex-1 justify-end bg-black/60">
                    <View className="bg-white rounded-t-3xl h-[80%] flex-col">
                        {/* Header */}
                        <View className="flex-row justify-between items-center px-6 pt-5 pb-3 border-b border-gourmet-border/60">
                            <Text className="text-xl font-quicksand-bold text-gourmet-charcoal">Terms & Conditions</Text>
                            <TouchableOpacity 
                                onPress={() => setShowTermsModal(false)}
                                className="size-10 rounded-full bg-gourmet-bone items-center justify-center border border-gourmet-border"
                            >
                                <Ionicons name="close" size={20} color="#1E1E24" />
                            </TouchableOpacity>
                        </View>

                        {/* Body Text */}
                        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 40 }} className="p-6">
                            <Text className="text-gourmet-charcoal text-sm leading-relaxed mb-4">
                                Welcome to Bongo Foodie. By using our application, you agree to comply with and be bound by the following terms and conditions. Please read them carefully.
                            </Text>

                            <Text className="text-gourmet-charcoal font-quicksand-bold text-base mb-2">1. Ordering & Delivery</Text>
                            <Text className="text-gray-200 text-sm leading-relaxed mb-4">
                                Bongo Foodie coordinates with premium culinary teams to prepare your meals. Delivery times are estimated and may vary based on weather, kitchen queue load, and Dar es Salaam traffic conditions.
                            </Text>

                            <Text className="text-gourmet-charcoal font-quicksand-bold text-base mb-2">2. Lipa Namba & Cash Payments</Text>
                            <Text className="text-gray-200 text-sm leading-relaxed mb-4">
                                All digital payments via M-Pesa / Tigo Pesa Lipa Namba must settle exactly to the Till configurations synced inside the app. Checkouts are final once confirmed.
                            </Text>

                            <Text className="text-gourmet-charcoal font-quicksand-bold text-base mb-2">3. Chef AI Content Policy</Text>
                            <Text className="text-gray-200 text-sm leading-relaxed mb-4">
                                The Chef AI assistant generates digital meal compositions, nutritional estimates, and custom recipes for entertainment and discovery purposes. Always verify spice sensitivities and allergens independently.
                            </Text>

                            <Text className="text-gourmet-charcoal font-quicksand-bold text-base mb-2">4. User Accounts & Privacy</Text>
                            <Text className="text-gray-200 text-sm leading-relaxed mb-4">
                                You agree to provide a valid phone number and accept and secure your login session. We encrypt and safeguard account metadata according to security policies.
                            </Text>

                            <Text className="text-gourmet-charcoal text-xs text-gray-100 italic mt-6">
                                Last Updated: July 2026. Bongo Foodie Culinary Services.
                            </Text>
                        </ScrollView>
                    </View>
                </View>
            </Modal>
        </ImageBackground>
    );
}

const styles = StyleSheet.create({
    blurContainer: {
        backgroundColor: 'rgba(255, 255, 255, 0.12)',
        overflow: 'hidden',
    }
});
