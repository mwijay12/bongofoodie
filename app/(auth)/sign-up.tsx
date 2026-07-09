import { View, Text, Alert } from 'react-native';
import { Link, router } from "expo-router";
import CustomInput from "@/components/CustomInput";
import CustomButton from "@/components/CustomButton";
import React, { useState } from "react";
import { signUpWithEmail } from "@/lib/supabaseAuth";
import useAuthStore from "@/store/auth.store";

const SignUp = () => {
    const { phoneNumber, setUser, setIsAuthenticated } = useAuthStore();
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [form, setForm] = useState({ name: '', email: '', password: '' });

    const submit = async () => {
        const { name, email, password } = form;

        if (!name || !email || !password) {
            return Alert.alert('Error', 'Please fill in all details.');
        }

        setIsSubmitting(true);

        try {
            const user = await signUpWithEmail({ email, password, name }, phoneNumber || undefined);
            if (user) {
                setUser({
                    $id: user.id,
                    name: user.user_metadata?.full_name || name || 'Bongo Foodie User',
                    email: user.email || '',
                    avatar_url: user.user_metadata?.avatar_url || ''
                });
                setIsAuthenticated(true);
                Alert.alert(
                    'Verification Required', 
                    'Account created successfully! If email confirmation is enabled in your Supabase Auth settings, please check your inbox to confirm your email before signing in.'
                );
                router.replace('/');
            }
        } catch (error: any) {
            Alert.alert('Registration Failed', error.message || 'Failed to sign up.');
        } finally {
            setIsSubmitting(false);
        }
    }

    return (
        <View className="gap-6 bg-white p-4 flex-1 justify-center">
            <View>
                <Text className="h1-bold text-center mb-1 text-gourmet-charcoal">Bongo Foodie</Text>
                <Text className="body-regular text-center text-gray-200">Join Bongo Foodie to start ordering Swahili food</Text>
            </View>

            <CustomInput
                placeholder="Enter your full name"
                value={form.name}
                onChangeText={(text) => setForm((prev) => ({ ...prev, name: text }))}
                label="Full name"
            />
            
            <CustomInput
                placeholder="Enter your email"
                value={form.email}
                onChangeText={(text) => setForm((prev) => ({ ...prev, email: text }))}
                label="Email"
                keyboardType="email-address"
            />
            
            <CustomInput
                placeholder="Enter your password"
                value={form.password}
                onChangeText={(text) => setForm((prev) => ({ ...prev, password: text }))}
                label="Password"
                secureTextEntry={true}
            />

            <CustomButton
                title="Sign Up"
                isLoading={isSubmitting}
                onPress={submit}
            />

            <View className="flex justify-center mt-2 flex-row gap-2">
                <Text className="body-regular text-gray-200">
                    Already have an account?
                </Text>
                <Link href="/sign-in" className="body-medium font-quicksand-bold text-gourmet-forest">
                    Sign In
                </Link>
            </View>
        </View>
    );
};

export default SignUp;
