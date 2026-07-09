import { View, Text, TextInput, TouchableOpacity } from 'react-native';
import { CustomInputProps } from "@/type";
import React, { useState } from "react";
import cn from "clsx";
import { Ionicons } from '@expo/vector-icons';

const CustomInput = ({
    placeholder = 'Enter text',
    value,
    onChangeText,
    label,
    secureTextEntry = false,
    keyboardType = "default"
}: CustomInputProps) => {
    const [isFocused, setIsFocused] = useState(false);
    const [isPasswordVisible, setIsPasswordVisible] = useState(false);

    const isPasswordType = secureTextEntry;

    return (
        <View className="w-full">
            <Text className="label">{label}</Text>

            <View className={cn(
                'flex-row items-center rounded-lg border bg-white/50 w-full h-[52px]',
                isFocused ? 'border-gourmet-amber' : 'border-gourmet-border'
            )}>
                <TextInput
                    autoCapitalize="none"
                    autoCorrect={false}
                    value={value}
                    onChangeText={onChangeText}
                    secureTextEntry={isPasswordType && !isPasswordVisible}
                    keyboardType={keyboardType}
                    onFocus={() => setIsFocused(true)}
                    onBlur={() => setIsFocused(false)}
                    placeholder={placeholder}
                    placeholderTextColor="#A0A0A0"
                    className="flex-1 h-full px-4 text-base font-quicksand-semibold text-gourmet-charcoal"
                />
                
                {isPasswordType && (
                    <TouchableOpacity 
                        onPress={() => setIsPasswordVisible(!isPasswordVisible)}
                        className="pr-4 justify-center h-full"
                    >
                        <Ionicons 
                            name={isPasswordVisible ? "eye-off" : "eye"} 
                            size={20} 
                            color="#5D5F6D" 
                        />
                    </TouchableOpacity>
                )}
            </View>
        </View>
    );
};

export default CustomInput;
