import { Redirect, Tabs } from "expo-router";
import useAuthStore from "@/store/auth.store";
import { Image, View, TouchableOpacity, StyleSheet } from "react-native";
import React from 'react';
import { images } from "@/constants";
import { BottomTabBarProps } from "@react-navigation/bottom-tabs";

// Custom tab bar component following the styled components glassmorphism template
function CustomTabBar({ state, descriptors, navigation }: BottomTabBarProps) {
    return (
        <View style={styles.tabContainer}>
            <View style={styles.tabBar}>
                {state.routes.map((route, index) => {
                    const isFocused = state.index === index;

                    const onPress = () => {
                        const event = navigation.emit({
                            type: 'tabPress',
                            target: route.key,
                            canPreventDefault: true,
                        });

                        if (!isFocused && !event.defaultPrevented) {
                            navigation.navigate(route.name, route.params);
                        }
                    };

                    let icon = images.home;
                    if (route.name === 'index') icon = images.home;
                    else if (route.name === 'search') icon = images.search;
                    else if (route.name === 'ai-chef') icon = images.star;
                    else if (route.name === 'cart') icon = images.bag;
                    else if (route.name === 'profile') icon = images.person;

                    return (
                        <TouchableOpacity
                            key={route.key}
                            onPress={onPress}
                            style={isFocused ? styles.activeTabButton : styles.tabButton}
                            activeOpacity={0.8}
                        >
                            <Image 
                                source={icon} 
                                style={styles.tabIcon} 
                                resizeMode="contain"
                                tintColor={isFocused ? "#FFFFFF" : "rgba(255, 255, 255, 0.6)"} 
                            />
                        </TouchableOpacity>
                    );
                })}
            </View>
        </View>
    );
}

export default function TabLayout() {
    const { isAuthenticated } = useAuthStore();

    if(!isAuthenticated) return <Redirect href="/onboarding" />;

    return (
        <Tabs 
            tabBar={(props) => <CustomTabBar {...props} />}
            screenOptions={{
                headerShown: false,
            }}
        >
            <Tabs.Screen name='index' options={{ title: 'Home' }} />
            <Tabs.Screen name='search' options={{ title: 'Search' }} />
            <Tabs.Screen name='ai-chef' options={{ title: 'Chef AI' }} />
            <Tabs.Screen name='cart' options={{ title: 'Cart' }} />
            <Tabs.Screen name='profile' options={{ title: 'Profile' }} />
        </Tabs>
    );
}

const styles = StyleSheet.create({
    tabContainer: {
        position: 'absolute',
        bottom: 24,
        left: 0,
        right: 0,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: 20,
        backgroundColor: 'transparent',
    },
    tabBar: {
        flexDirection: 'row',
        width: '100%',
        maxWidth: 500,
        height: 64,
        backgroundColor: 'rgba(30, 30, 36, 0.94)', // Translucent dark matching template
        borderRadius: 999,
        borderWidth: 1,
        borderColor: 'rgba(255, 255, 255, 0.08)',
        shadowColor: '#000000',
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.22,
        shadowRadius: 20,
        elevation: 8,
        padding: 6,
        alignItems: 'center',
        justifyContent: 'space-around',
    },
    tabButton: {
        width: 48,
        height: 48,
        borderRadius: 999,
        alignItems: 'center',
        justifyContent: 'center',
    },
    activeTabButton: {
        width: 48,
        height: 48,
        borderRadius: 999,
        backgroundColor: '#F6821F', // Brand orange active highlight matching app styles
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#F6821F',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 6,
        elevation: 4,
    },
    tabIcon: {
        width: 20,
        height: 20,
    }
});
