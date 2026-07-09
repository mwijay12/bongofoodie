import { View, Text, Alert, TouchableOpacity, Modal, TextInput } from 'react-native';
import { Link, router } from "expo-router";
import CustomInput from "@/components/CustomInput";
import CustomButton from "@/components/CustomButton";
import React, { useState } from "react";
import { signInWithEmail, signInWithGoogle, resetPasswordForEmail } from "@/lib/supabaseAuth";
import useAuthStore from "@/store/auth.store";
import * as Sentry from '@sentry/react-native';
import { Ionicons } from '@expo/vector-icons';

const SignIn = () => {
    const { setUser, setIsAuthenticated } = useAuthStore();
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [isGoogleSubmitting, setIsGoogleSubmitting] = useState(false);
    const [form, setForm] = useState({ email: '', password: '' });

    // Forgot password states
    const [showForgotModal, setShowForgotModal] = useState(false);
    const [forgotEmail, setForgotEmail] = useState("");
    const [sendingReset, setSendingReset] = useState(false);

    const submit = async () => {
        const { email, password } = form;

        if (!email || !password) {
            return Alert.alert('Error', 'Please enter a valid email address and password.');
        }

        setIsSubmitting(true);

        try {
            const user = await signInWithEmail({ email, password });
            if (user) {
                setUser({
                    $id: user.id,
                    name: user.user_metadata?.full_name || user.email || 'Bongo Foodie User',
                    email: user.email || '',
                    avatar_url: user.user_metadata?.avatar_url || ''
                });
                setIsAuthenticated(true);
                router.replace('/');
            }
        } catch (error: any) {
            // Better confirmation warnings for email confirmation issues
            let msg = error.message || 'Failed to sign in.';
            if (msg.toLowerCase().includes("confirm") || msg.toLowerCase().includes("invalid login credentials")) {
                msg = "Invalid credentials. If you recently signed up, please confirm your email via the link sent or verify your credentials. If you are developing locally, you can disable 'Confirm email' under Authentication -> Providers -> Email in your Supabase Dashboard to allow instant sign-ins.";
            }
            Alert.alert('Sign-In Failed', msg);
            Sentry.captureException(error);
        } finally {
            setIsSubmitting(false);
        }
    }

    const handleGoogleSignIn = async () => {
        setIsGoogleSubmitting(true);
        try {
            const user = await signInWithGoogle();
            if (user) {
                // Populate the global auth store on success
                setUser({
                    $id: user.id,
                    name: user.user_metadata?.full_name || user.email || 'Bongo Foodie User',
                    email: user.email || '',
                    avatar_url: user.user_metadata?.avatar_url || ''
                });
                setIsAuthenticated(true);
                router.replace('/');
            }
        } catch (error: any) {
            Alert.alert('Google Sign-In Error', error.message || 'Authentication could not be completed.');
        } finally {
            setIsGoogleSubmitting(false);
        }
    }

    const handleResetSubmit = async () => {
        if (!forgotEmail.trim()) {
            return Alert.alert("Error", "Please enter a valid email address.");
        }
        setSendingReset(true);
        try {
            await resetPasswordForEmail(forgotEmail.trim());
            Alert.alert("Link Sent", "Password reset instructions have been sent to your email!");
            setShowForgotModal(false);
            setForgotEmail("");
        } catch (e: any) {
            Alert.alert("Error", e.message || "Failed to trigger password reset.");
        } finally {
            setSendingReset(false);
        }
    };

    return (
        <View className="gap-6 bg-white p-4 flex-1 justify-center">
            <View>
                <Text className="h1-bold text-center mb-1 text-gourmet-charcoal">Bongo Foodie</Text>
                <Text className="body-regular text-center text-gray-200">Sign in to order Tanzanian gourmet meals</Text>
            </View>

            <CustomInput
                placeholder="Enter your email"
                value={form.email}
                onChangeText={(text) => setForm((prev) => ({ ...prev, email: text }))}
                label="Email"
                keyboardType="email-address"
            />
            
            <View className="w-full gap-y-2">
                <CustomInput
                    placeholder="Enter your password"
                    value={form.password}
                    onChangeText={(text) => setForm((prev) => ({ ...prev, password: text }))}
                    label="Password"
                    secureTextEntry={true}
                />
                
                <TouchableOpacity 
                    onPress={() => setShowForgotModal(true)}
                    className="self-end mr-1 mt-1"
                >
                    <Text className="body-medium text-gourmet-forest font-quicksand-bold text-xs underline">Forgot Password?</Text>
                </TouchableOpacity>
            </View>

            <View className="gap-3 mt-2">
                <CustomButton
                    title="Sign In"
                    isLoading={isSubmitting}
                    onPress={submit}
                />

                {/* Google Sign In Button */}
                <TouchableOpacity
                    onPress={handleGoogleSignIn}
                    disabled={isGoogleSubmitting}
                    className="w-full bg-white border border-gourmet-border py-4 rounded-lg flex flex-row items-center justify-center gap-2"
                >
                    <Text className="body-bold text-gourmet-charcoal">
                        {isGoogleSubmitting ? 'Connecting to Google...' : 'Continue with Google 🔑'}
                    </Text>
                </TouchableOpacity>
            </View>

            <View className="flex justify-center flex-row gap-2 mt-2">
                <Text className="body-regular text-gray-200">
                    {"Don't have an account?"}
                </Text>
                <Link href="/sign-up" className="body-medium font-quicksand-bold text-gourmet-forest">
                    Sign Up
                </Link>
            </View>

            {/* Forgot Password Modal */}
            <Modal
                visible={showForgotModal}
                animationType="fade"
                transparent={true}
                onRequestClose={() => setShowForgotModal(false)}
            >
                <View className="flex-1 justify-center items-center bg-black/60 px-6">
                    <View className="bg-white rounded-2xl w-full max-w-sm p-6 gap-y-4 shadow-xl">
                        <View className="flex-row justify-between items-center pb-2 border-b border-gourmet-border/60">
                            <Text className="text-lg font-quicksand-bold text-gourmet-charcoal">Reset Password</Text>
                            <TouchableOpacity onPress={() => setShowForgotModal(false)}>
                                <Ionicons name="close" size={22} color="#1E1E24" />
                            </TouchableOpacity>
                        </View>
                        
                        <Text className="text-gray-200 text-xs font-quicksand-medium leading-relaxed">
                            Enter your registered email address below. We will send a secure link to reset your password.
                        </Text>

                        <View className="w-full bg-gourmet-bone border border-gourmet-border rounded-xl px-4 flex-row items-center h-12">
                            <Ionicons name="mail" size={16} color="#5D5F6D" style={{ marginRight: 8 }} />
                            <TextInput
                                value={forgotEmail}
                                onChangeText={setForgotEmail}
                                placeholder="Enter email address"
                                placeholderTextColor="#A0A0A0"
                                keyboardType="email-address"
                                autoCapitalize="none"
                                className="flex-1 h-full text-gourmet-charcoal font-quicksand-semibold text-sm"
                            />
                        </View>

                        <TouchableOpacity 
                            onPress={handleResetSubmit}
                            disabled={sendingReset}
                            className="bg-gourmet-forest py-3.5 rounded-lg flex items-center justify-center border border-gourmet-forest/10"
                        >
                            <Text className="text-white font-quicksand-bold text-sm">
                                {sendingReset ? "Sending recovery link..." : "Send Reset Link 📧"}
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </Modal>
        </View>
    );
};

export default SignIn;
