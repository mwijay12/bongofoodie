import { images } from "@/constants";
import { router, useLocalSearchParams } from "expo-router";
import React, { useState, useRef, useEffect } from "react";
import { Image, TextInput, TouchableOpacity, View, LayoutAnimation, Platform, UIManager } from "react-native";
import { Ionicons } from '@expo/vector-icons';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const Searchbar = () => {
    const params = useLocalSearchParams<{ query: string }>();
    const [query, setQuery] = useState(params.query || "");
    const [isExpanded, setIsExpanded] = useState(!!params.query);
    const inputRef = useRef<TextInput | null>(null);

    // Sync query local state with URL param changes
    useEffect(() => {
        setQuery(params.query || "");
        if (params.query) {
            setIsExpanded(true);
        }
    }, [params.query]);

    const handleSearch = (text: string) => {
        setQuery(text);
        router.setParams({ query: text.trim() || undefined });
    };

    const handleSubmit = () => {
        if(query.trim()) {
            router.setParams({ query });
        }
    };

    const handleToggle = () => {
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        if (isExpanded) {
            // Collapse
            if (query) {
                setQuery("");
                router.setParams({ query: undefined });
            }
            setIsExpanded(false);
        } else {
            // Expand
            setIsExpanded(true);
            setTimeout(() => {
                inputRef.current?.focus();
            }, 100);
        }
    };

    return (
        <View className="flex-row items-center justify-end w-full h-12">
            <View 
                className={`h-12 border border-gourmet-border bg-white flex-row items-center overflow-hidden ${
                    isExpanded ? "flex-1 rounded-xl px-3" : "w-12 rounded-full justify-center"
                }`}
            >
                {isExpanded ? (
                    <>
                        <TouchableOpacity onPress={handleToggle} className="mr-2">
                            <Image
                                source={images.search}
                                className="size-5"
                                resizeMode="contain"
                                tintColor="#F6821F"
                            />
                        </TouchableOpacity>
                        <TextInput
                            ref={inputRef}
                            className="flex-grow h-full font-quicksand-semibold text-gourmet-charcoal text-sm"
                            placeholder="Search pizzas, burgers, meals..."
                            value={query}
                            onChangeText={handleSearch}
                            onSubmitEditing={handleSubmit}
                            placeholderTextColor="#A0A0A0"
                            returnKeyType="search"
                        />
                        {query.length > 0 && (
                            <TouchableOpacity 
                                onPress={() => { 
                                    setQuery(""); 
                                    router.setParams({ query: undefined }); 
                                }}
                            >
                                <Ionicons name="close-circle" size={18} color="#787774" />
                            </TouchableOpacity>
                        )}
                    </>
                ) : (
                    <TouchableOpacity 
                        onPress={handleToggle} 
                        className="size-full items-center justify-center"
                    >
                        <Image
                            source={images.search}
                            className="size-5"
                            resizeMode="contain"
                            tintColor="#5D5F6D"
                        />
                    </TouchableOpacity>
                )}
            </View>
        </View>
    );
};

export default Searchbar;
