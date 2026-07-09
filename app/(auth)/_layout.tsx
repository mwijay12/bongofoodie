import { View, KeyboardAvoidingView, Platform, ScrollView, ImageBackground, Image } from 'react-native'
import { Redirect, Slot } from "expo-router";
import { images } from "@/constants";
import useAuthStore from "@/store/auth.store";

export default function AuthLayout() {
    const { isAuthenticated } = useAuthStore();

    if (isAuthenticated) return <Redirect href="/" />

    return (
        <KeyboardAvoidingView 
            behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
            style={{ flex: 1, backgroundColor: '#FFFFFF' }}
        >
            <ScrollView 
                className="bg-white flex-1" 
                keyboardShouldPersistTaps="handled"
                contentContainerStyle={{ flexGrow: 1, justifyContent: 'center' }}
                showsVerticalScrollIndicator={false}
            >
                <View className="w-full max-w-md mx-auto px-5 pb-12 pt-6">
                    {/* Fixed Height Header Banner */}
                    <View className="w-full h-48 rounded-xl overflow-hidden relative border border-gourmet-border bg-gourmet-bone">
                        <ImageBackground 
                            source={images.loginGraphic} 
                            className="size-full" 
                            resizeMode="cover" 
                        />
                        {/* Overlay to dim graphic slightly for contrast */}
                        <View className="absolute inset-0 bg-gourmet-charcoal/10" />
                    </View>

                    {/* Logo placed in-flow to prevent overlapping input elements */}
                    <Image 
                        source={images.logo} 
                        className="self-center size-28 -mt-14 z-10 mb-6" 
                        resizeMode="contain" 
                    />

                    {/* Authentication Inputs Screen */}
                    <Slot />
                </View>
            </ScrollView>
        </KeyboardAvoidingView>
    )
}
