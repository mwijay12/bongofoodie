import { SafeAreaView } from "react-native-safe-area-context";
import { FlatList, Image, Pressable, Text, TouchableOpacity, View, ScrollView, ActivityIndicator } from "react-native";
import React, { useState, useEffect } from "react";
import cn from 'clsx';
import { router } from "expo-router";
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';

import CartButton from "@/components/CartButton";
import { images } from "@/constants";
import useAuthStore from "@/store/auth.store";
import useLocationStore from "@/store/location.store";
import useAppwrite from "@/lib/useAppwrite";
import { getMenu } from "@/lib/supabaseDb";
import MenuCard from "@/components/MenuCard";
import { MenuItem } from "@/type";

// Daily Culinary & Business Curations
const CULINARY_FACTS = [
  {
    title: "Zanzibar Spice Capital 🌴",
    description: "Zanzibar (Unguja) is nicknamed the 'Spice Island' because it remains one of the world's top exporters of Cloves (Karafuu) and Nutmeg."
  },
  {
    title: "Bongo Foodie Sourcing 🧑‍🌾",
    description: "We source 100% of our organic vegetables, fresh meat, and rice from local Tanzanian family farms, supporting sustainable community growth!"
  },
  {
    title: "Eco-Friendly Delivery 📦",
    description: "To minimize plastic waste, all Bongo Foodie deliveries use biodegradable boxes inspired by traditional East African banana leaves."
  },
  {
    title: "National Comfort Comfort 🍟",
    description: "Chipsi Mayai (French Fries Omelette) started as a cheap roadside breakfast in Dar es Salaam and has evolved into Tanzania's most famous street food!"
  },
  {
    title: "Our Kijitonyama Branch 📍",
    description: "Bongo Foodie opened its first physical branch in Kijitonyama, Dar es Salaam, aiming to bring high-tech premium dining experiences to local foodies."
  },
  {
    title: "The Pilau Path 🍛",
    description: "Swahili Pilau is distinct because it roasts dry spices (cumin, cardamom, cloves, cinnamon) in caramelized onions before adding meat and rice."
  },
  {
    title: "Coastal Coconut Magic 🥥",
    description: "Tui la Nazi (Fresh Coconut Milk) is the soul of coastal cooking, used to simmer Samaki wa Kupaka (Coastal Fish Curry) or Maharage ya Nazi."
  }
];

const TRIVIA_QUESTIONS = [
  {
    id: 1,
    question: "Which local spice is called 'Mdalasini' in Swahili?",
    options: ["Clove (Karafuu)", "Cinnamon", "Cardamom (Hiliki)", "Ginger (Tangawizi)"],
    correctIndex: 1,
    explainer: "Mdalasini is Cinnamon! It is harvested from tree bark and used to add sweet aroma to Swahili Chai and Pilau."
  },
  {
    id: 2,
    question: "What does 'Tui la Nazi' mean in Swahili cuisine?",
    options: ["Coconut Milk", "Cow Milk", "Peanut Paste", "Mango Juice"],
    correctIndex: 0,
    explainer: "Correct! Tui la Nazi is Coconut Milk, a foundational ingredient in coastal cooking."
  },
  {
    id: 3,
    question: "Which of these is a popular Tanzanian roadside skewered meat?",
    options: ["Nyama ya Ng'ombe", "Mishkaki", "Kachumbari", "Uji"],
    correctIndex: 1,
    explainer: "Mishkaki is Tanzanian marinated beef skewers, grilled over hot charcoal until tender and smoky."
  }
];

// Typewriter component for typewriter motions
const TypewriterText = ({ text }: { text: string }) => {
    const [displayedText, setDisplayedText] = useState("");
    
    useEffect(() => {
        setDisplayedText("");
        if (!text) return;
        let i = 0;
        const timer = setInterval(() => {
            setDisplayedText((prev) => prev + text.charAt(i));
            i++;
            if (i >= text.length) {
                clearInterval(timer);
            }
        }, 15); // Fast, snappy typewriter effect
        return () => clearInterval(timer);
    }, [text]);

    return (
        <Text className="paragraph-medium text-gray-200 leading-relaxed min-h-[50px]">
            {displayedText}
        </Text>
    );
};

export default function Index() {
  const { user } = useAuthStore();
  const { deliveryLocation } = useLocationStore();
  const userName = user?.name || "Gourmand";

  // Setup rotation index based on weekday
  const initialFactIndex = new Date().getDay() % CULINARY_FACTS.length;
  const quizIndex = new Date().getDay() % TRIVIA_QUESTIONS.length;
  const currentQuiz = TRIVIA_QUESTIONS[quizIndex];

  // Retention States
  const [factIndex, setFactIndex] = useState(initialFactIndex);
  const currentFact = CULINARY_FACTS[factIndex];

  const [selectedAns, setSelectedAns] = useState<number | null>(null);
  const [showExplanation, setShowExplanation] = useState(false);
  const [hideQuiz, setHideQuiz] = useState(false);

  // Fetch featured menu items (limit to 4)
  const { data: menuItems, loading } = useAppwrite({
    fn: getMenu,
    params: { category: "", query: "" }
  });

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
      <View className="flex-1">
        {/* Sticky Header */}
        <View className="flex-between flex-row w-full px-5 pt-3 pb-3 bg-[#FBFBFA] border-b border-gourmet-border/30 z-20" style={{ overflow: 'visible' }}>
          <View className="flex-start items-start max-w-[70%]">
            <Text className="small-bold text-gourmet-amber">DELIVER TO</Text>
            <TouchableOpacity 
              onPress={() => router.push("/profile")}
              className="flex-row items-center gap-x-1.5 mt-1 max-w-full"
            >
              <Text className="paragraph-bold text-gourmet-charcoal flex-shrink" numberOfLines={1} ellipsizeMode="tail">
                {deliveryLocation ? (
                  deliveryLocation.split(',')[0].trim()
                ) : "Dar es Salaam"}
              </Text>
              <Image source={images.arrowDown} className="size-3 flex-shrink-0" resizeMode="contain" tintColor="#181C2E" />
            </TouchableOpacity>
          </View>
          <CartButton />
        </View>

        <ScrollView 
          contentContainerClassName="pb-36 px-5 pt-4 max-w-2xl mx-auto w-full" 
          contentContainerStyle={{ paddingBottom: 150 }}
          showsVerticalScrollIndicator={false}
        >
          
        {/* Greeting */}
        <View className="mb-6">
          <Text className="h1-bold leading-tight">Welcome, {userName}</Text>
          <Text className="base-regular text-gray-200 mt-1">Discover authentic Swahili cuisine</Text>
        </View>

        {/* Resilient AI Assistant Banner */}
        <Pressable 
          onPress={() => router.push("/ai-chef")}
          className="w-full bg-gourmet-forest p-5 rounded-xl mb-8 flex-row items-center justify-between border border-gourmet-forest/10"
        >
          <View className="flex-1 pr-4">
            <Text className="base-bold text-white mb-1">Chef AI Assistant</Text>
            <Text className="paragraph-semibold text-white/80 leading-snug">
              Describe your dream custom meal. Chef AI will generate the ingredients, nutritional stats, and render an original food photo in seconds!
            </Text>
          </View>
          <View className="size-14 rounded-lg bg-gourmet-amber flex items-center justify-center">
            <Image source={images.star} className="size-7" tintColor="#FFFFFF" />
          </View>
        </Pressable>

        {/* Asymmetric Bento Campaigns Grid */}
        <View className="mb-8">
          <Text className="h3-bold mb-4">Seasonal campaigns</Text>
          
          {/* Main Campaign Card (Full Width) */}
          <Pressable 
            onPress={() => router.push("/search")}
            className="w-full h-40 bg-gourmet-forest rounded-xl overflow-hidden mb-3 border border-gourmet-border flex-row items-center justify-between"
          >
            <View className="flex-1 p-6 justify-center items-start">
              <Text className="small-bold text-gourmet-amber mb-1">LIMITED TIME</Text>
              <Text className="h1-bold text-white text-2xl mb-3">SWAHILI FEAST</Text>
              <Text className="paragraph-bold text-white/90">20% off Chipsi Mayai & Mishkaki</Text>
            </View>
            <View className="w-1/2 h-full justify-center items-center">
              <Image source={images.chipsiMayai} style={{ width: 128, height: 128 }} resizeMode="contain" />
            </View>
          </Pressable>

          {/* Secondary Campaign Split Cards (2 Columns) */}
          <View className="flex-row gap-3">
            {/* Left Card */}
            <Pressable 
              onPress={() => router.push("/search")}
              className="flex-1 h-44 bg-gourmet-amber rounded-xl p-4 justify-between border border-gourmet-border"
            >
              <View className="items-start">
                <Text className="small-bold text-white/90 mb-1">FEATURED</Text>
                <Text className="h3-bold text-white">NYAMA CHOMA</Text>
              </View>
              <Image source={images.nyamaChoma} style={{ width: 96, height: 96 }} className="self-center" resizeMode="contain" />
            </Pressable>

            {/* Right Card */}
            <Pressable 
              onPress={() => router.push("/search")}
              className="flex-1 h-44 bg-gourmet-charcoal rounded-xl p-4 justify-between border border-gourmet-border"
            >
              <View className="items-start">
                <Text className="small-bold text-gourmet-amber mb-1">WEEKEND SPEC</Text>
                <Text className="h3-bold text-white">KACHUMBARI FRESH</Text>
              </View>
              <Image source={images.salad} style={{ width: 96, height: 96 }} className="self-center" resizeMode="contain" />
            </Pressable>
          </View>
        </View>

        {/* Culinary Discovery & Trivia Hub */}
        <View className="bg-gourmet-bone border border-gourmet-border rounded-xl p-5 mb-8">
          <View className="flex-row items-center gap-x-2 mb-4">
            <Ionicons name="bulb-outline" size={20} color="#F6821F" />
            <Text className="h3-bold">Bongo Culinary Hub</Text>
          </View>

          {/* Daily Fact card with Reshuffle next fact action */}
          <View className="bg-white border border-gourmet-border/60 p-4 rounded-lg mb-4">
            <View className="flex-row justify-between items-center mb-1">
              <Text className="small-bold text-gourmet-amber uppercase">Daily Discovery</Text>
              <TouchableOpacity 
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setFactIndex((prev) => (prev + 1) % CULINARY_FACTS.length);
                }}
                className="flex-row items-center gap-x-1"
              >
                <Text className="text-[10px] font-bold text-gourmet-forest uppercase">Next ➡️</Text>
              </TouchableOpacity>
            </View>
            <Text className="paragraph-bold text-gourmet-charcoal mb-1">{currentFact.title}</Text>
            {/* Snap Typewriter text effect */}
            <TypewriterText text={currentFact.description} />
          </View>

          {/* Daily Quiz, fades/hides on correct answer completion */}
          {!hideQuiz && (
            <View className="bg-white border border-gourmet-border/60 p-4 rounded-lg">
              <Text className="small-bold text-gourmet-forest uppercase mb-2">Daily Trivia Quiz</Text>
              <Text className="paragraph-bold text-gourmet-charcoal mb-3">{currentQuiz.question}</Text>
              
              <View className="gap-y-2">
                {currentQuiz.options.map((opt, idx) => {
                  const isSelected = selectedAns === idx;
                  const isCorrect = idx === currentQuiz.correctIndex;
                  let btnStyle = "border-gourmet-border bg-white";
                  let textStyle = "text-gourmet-charcoal";

                  if (selectedAns !== null) {
                    if (isCorrect) {
                      btnStyle = "border-green-300 bg-green-50";
                      textStyle = "text-green-800 font-bold";
                    } else if (isSelected) {
                      btnStyle = "border-red-300 bg-red-50";
                      textStyle = "text-red-800 font-bold";
                    } else {
                      btnStyle = "border-gourmet-border bg-white opacity-60";
                    }
                  }

                  return (
                    <TouchableOpacity
                      key={idx}
                      onPress={() => {
                        if (selectedAns !== null) return;
                        setSelectedAns(idx);
                        setShowExplanation(true);
                        if (idx === currentQuiz.correctIndex) {
                          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                        } else {
                          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                        }
                      }}
                      className={cn("border p-3 rounded-lg", btnStyle)}
                    >
                      <Text className={cn("paragraph-medium", textStyle)}>{opt}</Text>
                    </TouchableOpacity>
                  );
                })}
              </View>

              {showExplanation && (
                <View className="mt-3 pt-3 border-t border-gourmet-border/40">
                  <Text className="paragraph-bold text-gourmet-charcoal mb-1">
                    {selectedAns === currentQuiz.correctIndex ? "🎉 Correct! Use coupon KARIBU2000 in your Cart to save TSh 2,000!" : "❌ Oops! Try again."}
                  </Text>
                  <Text className="paragraph-medium text-gray-200 leading-relaxed mb-2">
                    {currentQuiz.explainer}
                  </Text>
                  {selectedAns === currentQuiz.correctIndex && (
                    <TouchableOpacity 
                      onPress={() => setHideQuiz(true)}
                      className="mt-3 py-2 bg-gourmet-forest/10 border border-gourmet-forest/20 rounded-lg items-center"
                    >
                      <Text className="text-xs font-quicksand-bold text-gourmet-forest">Dismiss Trivia</Text>
                    </TouchableOpacity>
                  )}
                </View>
              )}
            </View>
          )}
        </View>

        {/* Featured Items */}
        <View className="mb-6">
          <View className="flex-between flex-row mb-4">
            <Text className="h3-bold">Featured selection</Text>
            <TouchableOpacity onPress={() => router.push("/search")}>
              <Text className="paragraph-bold text-gourmet-forest">View All</Text>
            </TouchableOpacity>
          </View>

          {loading ? (
            <ActivityIndicator size="small" color="#F6821F" />
          ) : (
            <View className="flex-row flex-wrap gap-4 justify-between">
              {menuItems?.slice(0, 4).map((item) => (
                <View key={item.$id} className="w-[47%] mb-4 mt-8">
                  <MenuCard item={item as MenuItem} />
                </View>
              ))}
            </View>
          )}
        </View>

      </ScrollView>
      </View>
    </SafeAreaView>
  );
}
