import React, { useState, useRef } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, Image, ActivityIndicator, Alert, KeyboardAvoidingView, Platform, Clipboard } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import FireLoader from "@/components/FireLoader";
import { WebView } from "react-native-webview";
import { generateText, generateFood, generateImage, generateSpeech } from "@/lib/aiService";
import { useCartStore } from "@/store/cart.store";
import { ChatMessage, GeneratedFoodInfo } from "@/type";
import * as Speech from "expo-speech";
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';

export default function AIChef() {
  const [activeTab, setActiveTab] = useState<"chat" | "creator">("chat");
  const [loading, setLoading] = useState(false);
  const { addItem } = useCartStore();

  // Chat States
  const [chatInput, setChatInput] = useState("");
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: "welcome",
      role: "assistant",
      content: "Welcome to Bongo Foodie. Ask me to pair dishes, detail nutrition, or suggest culinary combinations.",
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
  ]);

  // Audio state for WebView playback hack
  const [playAudioBase64, setPlayAudioBase64] = useState<string | null>(null);
  const [voiceLoadingId, setVoiceLoadingId] = useState<string | null>(null);

  // Creator States
  const [creatorInput, setCreatorInput] = useState("");
  const [generatedFood, setGeneratedFood] = useState<GeneratedFoodInfo | null>(null);
  const [generatedImageUrl, setGeneratedImageUrl] = useState<string | null>(null);

  const scrollViewRef = useRef<ScrollView>(null);

  // Image attachment picker
  const pickImage = async () => {
    const permissionResult = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permissionResult.granted) {
      Alert.alert("Permission Required", "Please allow access to your media library to attach photos.");
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });
    if (!result.canceled && result.assets && result.assets.length > 0) {
      setSelectedImage(result.assets[0].uri);
    }
  };

  // 1. Text Chat Handler
  const handleSendMessage = async () => {
    if (!chatInput.trim() && !selectedImage) return;

    const userMsg: ChatMessage = {
      id: `user-${Date.now()}`,
      role: "user",
      content: chatInput.trim() || "Attached image description",
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      imageUrl: selectedImage || undefined,
    };

    setMessages((prev) => [...prev, userMsg]);
    const promptMessageText = chatInput.trim();
    const promptImageUri = selectedImage;
    
    setChatInput("");
    setSelectedImage(null);
    setLoading(true);

    try {
      // Assemble full conversation history context for LLM
      const contextPrompt = messages
        .map((m) => `${m.role === "user" ? "User" : "Chef"}: ${m.content}`)
        .join("\n") + `\nUser: ${promptMessageText}${promptImageUri ? " [Attached image reference]" : ""}\nChef:`;

      const aiResponse = await generateText(
        `You are the Executive Chef at Bongo Foodie, an elite restaurant.
        Answer user questions directly, with high culinary wisdom.
        Keep answers under 3 sentences. No adverbs. No filler.
        
        Current conversation:
        ${contextPrompt}`
      );

      const chefMsg: ChatMessage = {
        id: `chef-${Date.now()}`,
        role: "assistant",
        content: aiResponse.trim(),
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };

      setMessages((prev) => [...prev, chefMsg]);
      setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 100);

    } catch (e: any) {
      Alert.alert("AI Error", e.message || "Chef assistant is currently resting.");
    } finally {
      setLoading(false);
    }
  };

  // 2. Play ElevenLabs Audio Speech with local Speech fallback
  const playSpeech = async (msgId: string, text: string) => {
    setVoiceLoadingId(msgId);
    try {
      const base64Audio = await generateSpeech(text);
      if (base64Audio) {
        setPlayAudioBase64(base64Audio);
      } else {
        console.warn("[Voice Fallback] ElevenLabs returned empty stream, falling back to local Expo Speech");
        Speech.speak(text);
      }
    } catch (e) {
      console.error("[Voice API Error] Falling back to local Expo Speech:", e);
      Speech.speak(text);
    } finally {
      setVoiceLoadingId(null);
    }
  };

  // 3. Custom Dish Creator Handler
  const handleDesignDish = async () => {
    if (!creatorInput.trim()) return;

    setLoading(true);
    setGeneratedFood(null);
    setGeneratedImageUrl(null);

    try {
      // Step A: Generate metadata using text LLM fallbacks
      console.log("[AI Chef] Generating food metadata...");
      const foodData = await generateFood(creatorInput.trim());
      setGeneratedFood(foodData);

      // Step B: Generate gourmet photo using SiliconFlow (Flux) key rotation
      console.log("[AI Chef] Generating food image...");
      const imageUrl = await generateImage(foodData.name + ", " + foodData.description);
      setGeneratedImageUrl(imageUrl);

      // Scroll down to show results card
      setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 300);

    } catch (e: any) {
      Alert.alert("Gourmet Designer Error", e.message || "Dish design failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  // 4. Create Dish from the Chat History
  const handleDesignDishFromChat = async () => {
    // Check if there's user messaging history to design from
    const userMessages = messages.filter(m => m.role === 'user');
    if (userMessages.length === 0) {
      Alert.alert("No Chat History", "Please ask the Chef about food first!");
      return;
    }

    const combinedChatHistory = messages
      .map(m => `${m.role === 'user' ? 'User Request' : 'Chef Response'}: ${m.content}`)
      .join("\n");
      
    // Set a user-friendly prompt description in the input box
    const latestUserPrompt = userMessages[userMessages.length - 1].content;
    setCreatorInput(latestUserPrompt);
    setActiveTab("creator");

    setLoading(true);
    setGeneratedFood(null);
    setGeneratedImageUrl(null);

    try {
      const foodData = await generateFood(`Summarize the desired custom food from this conversation history. Pay attention to ingredients the user wanted (e.g. Pork, Ugali) and ingredients they explicitly excluded or said they don't use (e.g. no lemons/malimao/citrus):\n\n${combinedChatHistory}`);
      setGeneratedFood(foodData);

      const imageUrl = await generateImage(foodData.name + ", " + foodData.description);
      setGeneratedImageUrl(imageUrl);
    } catch (e: any) {
      Alert.alert("Gourmet Designer Error", e.message || "Dish design failed.");
    } finally {
      setLoading(false);
    }
  };

  // 5. Add Generated Item to Zustand Cart Store
  const handleAddCustomToCart = () => {
    if (!generatedFood) return;

    const uniqueId = `ai-dish-${Date.now()}`;
    const mappedCustomizations = generatedFood.customizations.map((name, i) => ({
      id: `ai-cust-${i}-${Date.now()}`,
      name,
      price: 1000, // standard topping price TSh
      type: "topping"
    }));

    addItem({
      id: uniqueId,
      name: generatedFood.name,
      price: generatedFood.price,
      image_url: generatedImageUrl || "https://picsum.photos/500/500",
      customizations: mappedCustomizations,
      isAICreated: true,
      calories: generatedFood.calories,
      protein: generatedFood.protein,
      description: generatedFood.description
    });

    Alert.alert("Bon Appétit!", `${generatedFood.name} added to your cart.`);
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
      <View className="flex-1 bg-gourmet-bone">
      {/* Invisible WebView for base64 audio play hack */}
      {playAudioBase64 && (
        <View style={{ width: 0, height: 0, opacity: 0, position: 'absolute' }}>
          <WebView
            originWhitelist={['*']}
            source={{
              html: `<html><body><audio autoplay src="${playAudioBase64}"></audio></body></html>`
            }}
            onNavigationStateChange={() => {
              // clear audio reference after it mounts/plays to allow playing again
              setTimeout(() => setPlayAudioBase64(null), 5000);
            }}
          />
        </View>
      )}

      {/* Tabs Header */}
      <View className="border-b border-gourmet-border bg-white w-full z-20">
        <View className="flex-row px-5 py-3 justify-between items-center max-w-2xl mx-auto w-full">
          <Text className="h3-bold">Chef Atelier</Text>
          <View className="flex-row bg-gourmet-bone p-1 rounded-lg border border-gourmet-border">
            <TouchableOpacity
              onPress={() => setActiveTab("chat")}
              className={`px-4 py-1.5 rounded-md ${activeTab === "chat" ? "bg-white border border-gourmet-border" : ""}`}
            >
              <Text className={`paragraph-bold ${activeTab === "chat" ? "text-gourmet-forest" : "text-gray-200"}`}>Chat Notes</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setActiveTab("creator")}
              className={`px-4 py-1.5 rounded-md ${activeTab === "creator" ? "bg-white border border-gourmet-border" : ""}`}
            >
              <Text className={`paragraph-bold ${activeTab === "creator" ? "text-gourmet-forest" : "text-gray-200"}`}>Dish Creator</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>

      {activeTab === "chat" ? (
        // ----------------------------------------------------
        // CHAT TAB LAYOUT
        // ----------------------------------------------------
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
          className="flex-1"
        >
          <ScrollView
            ref={scrollViewRef}
            contentContainerClassName="p-5 pb-10 max-w-2xl mx-auto w-full"
            showsVerticalScrollIndicator={false}
          >
            {messages.map((msg) => (
              <View
                key={msg.id}
                className={`mb-4 flex-row ${msg.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <View
                  className={`max-w-[80%] p-4 rounded-xl border ${
                    msg.role === "user"
                      ? "bg-gourmet-forest border-gourmet-forest/10 rounded-br-none"
                      : "bg-white border-gourmet-border rounded-bl-none"
                  }`}
                >
                  {msg.imageUrl && (
                    <Image 
                      source={{ uri: msg.imageUrl }} 
                      style={{ width: 180, height: 180, borderRadius: 8, marginBottom: 8 }} 
                      resizeMode="cover" 
                    />
                  )}
                  <Text className={`paragraph-semibold ${msg.role === "user" ? "text-white" : "text-gourmet-charcoal"}`}>
                    {msg.content}
                  </Text>
                  
                  <View className="flex-row items-center justify-between mt-2.5 pt-2 border-t border-gourmet-border/10">
                    <Text className={`body-regular text-[9px] ${msg.role === "user" ? "text-white/60" : "text-gray-100"}`}>
                      {msg.timestamp}
                    </Text>
                    {msg.role === "assistant" && (
                      <View className="flex-row items-center gap-x-2">
                        <TouchableOpacity 
                          onPress={() => playSpeech(msg.id, msg.content)}
                          disabled={voiceLoadingId !== null}
                          className="bg-gourmet-forest/5 px-2 py-1 rounded border border-gourmet-forest/10 flex-row items-center"
                        >
                          {voiceLoadingId === msg.id ? (
                             <ActivityIndicator size="small" color="#F6821F" />
                          ) : (
                            <Text className="text-[10px] font-quicksand-bold text-gourmet-forest">Listen</Text>
                          )}
                        </TouchableOpacity>

                        <TouchableOpacity 
                          onPress={() => {
                            Clipboard.setString(msg.content);
                            Alert.alert("Copied", "Response copied to clipboard!");
                          }}
                          className="bg-gourmet-forest/5 px-2 py-1 rounded border border-gourmet-forest/10 flex-row items-center"
                        >
                          <Text className="text-[10px] font-quicksand-bold text-gourmet-forest">Copy</Text>
                        </TouchableOpacity>
                      </View>
                    )}
                  </View>
                </View>
              </View>
            ))}
            {loading && (
              <View className="flex-row justify-start mb-4">
                <View className="bg-white border border-gourmet-border p-4 rounded-xl rounded-bl-none flex-row items-center">
                  <FireLoader />
                  <Text className="paragraph-semibold text-gourmet-charcoal ml-2.5">Chef is composing...</Text>
                </View>
              </View>
            )}
          </ScrollView>

          {/* Create Dish from Chat banner option */}
          {messages.length > 1 && (
            <View className="px-5 pb-2 pt-1 flex-row justify-center bg-transparent max-w-2xl mx-auto w-full">
              <TouchableOpacity 
                onPress={handleDesignDishFromChat}
                className="bg-gourmet-forest/10 border border-gourmet-forest/20 py-2 px-4 rounded-full flex-row items-center justify-center gap-1.5 shadow-sm"
              >
                <Ionicons name="restaurant-outline" size={14} color="#15803D" />
                <Text className="text-xs font-quicksand-bold text-gourmet-forest">
                  Create Custom Dish from Chat History
                </Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Chat Input Dock */}
          <View className="bg-white border-t border-gourmet-border w-full">
            {/* Image Selected Thumbnail indicator */}
            {selectedImage && (
              <View className="px-4 pt-3 flex-row items-center max-w-2xl mx-auto w-full">
                <View className="relative">
                  <Image source={{ uri: selectedImage }} style={{ width: 50, height: 50, borderRadius: 8 }} />
                  <TouchableOpacity 
                    onPress={() => setSelectedImage(null)}
                    className="absolute -top-1.5 -right-1.5 size-5 bg-red-500 rounded-full items-center justify-center border border-white"
                  >
                    <Ionicons name="close" size={12} color="#FFF" />
                  </TouchableOpacity>
                </View>
                <Text className="text-xs text-gray-200 font-quicksand-bold ml-2">Image attached to message</Text>
              </View>
            )}

            <View className="p-4 mb-[110px] flex-row items-center gap-2.5 max-w-2xl mx-auto w-full">
              <TouchableOpacity 
                onPress={pickImage}
                className="bg-gourmet-bone p-3 rounded-lg border border-gourmet-border flex items-center justify-center"
              >
                <Ionicons name="image-outline" size={20} color="#787774" />
              </TouchableOpacity>

              <TextInput
                value={chatInput}
                onChangeText={setChatInput}
                placeholder="Ask Chef about Swahili recipes or pairings..."
                className="flex-1 bg-gourmet-bone border border-gourmet-border rounded-lg p-3 font-quicksand-semibold text-gourmet-charcoal"
                placeholderTextColor="#787774"
              />
              <TouchableOpacity
                onPress={handleSendMessage}
                disabled={loading}
                className="bg-gourmet-forest p-3 rounded-lg flex items-center justify-center border border-gourmet-forest/10"
              >
                <Text className="paragraph-bold text-white px-2">Ask</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      ) : (
        // ----------------------------------------------------
        // DISH CREATOR TAB LAYOUT
        // ----------------------------------------------------
        <ScrollView 
          ref={scrollViewRef}
          contentContainerClassName="p-5 pb-36 max-w-2xl mx-auto w-full" 
          contentContainerStyle={{ paddingBottom: 150 }}
          showsVerticalScrollIndicator={false}
        >
          <View className="mb-6">
            <Text className="h3-bold mb-1">Gourmet Dream Kitchen</Text>
            <Text className="base-regular text-gray-200">Describe your culinary fantasy. The AI rotates keys to write specifications, calculate nutrition, and render an original food composition.</Text>
          </View>

          {/* Prompt Box */}
          <View className="bg-white p-4 border border-gourmet-border rounded-xl mb-6">
            <TextInput
              value={creatorInput}
              onChangeText={setCreatorInput}
              placeholder="e.g. Nyama choma ya mbuzi yenye pilipili na ndizi kaanga"
              multiline={true}
              numberOfLines={3}
              className="w-full text-base font-quicksand-semibold text-gourmet-charcoal mb-4 p-2 bg-gourmet-bone/30 rounded-lg border border-gourmet-border"
              placeholderTextColor="#787774"
              textAlignVertical="top"
            />
            
            <TouchableOpacity
              onPress={handleDesignDish}
              disabled={loading}
              className="custom-btn flex-row items-center gap-2"
            >
              {loading ? (
                <ActivityIndicator size="small" color="#FFFFFF" />
              ) : (
                <>
                  <Text className="base-bold text-white">Create Dish with AI</Text>
                </>
              )}
            </TouchableOpacity>
          </View>

          {/* Generation Results Card */}
          {loading && !generatedFood && (
            <View className="bg-white border border-gourmet-border p-6 rounded-xl items-center gap-3">
              <FireLoader />
              <Text className="paragraph-semibold text-gourmet-charcoal mt-2">Activating resilient key pool...</Text>
              <Text className="body-regular text-gray-100 text-center">Failing over if rate-limited. Synthesizing gourmet details and rendering photo...</Text>
            </View>
          )}

          {generatedFood && (
            <View className="bg-white border border-gourmet-border rounded-xl overflow-hidden mb-8 animate-in fade-in slide-in-from-bottom duration-300">
              {/* Generated Image Loader */}
              <View className="w-full h-64 bg-gourmet-forest/5 flex items-center justify-center border-b border-gourmet-border relative">
                {generatedImageUrl ? (
                  <Image source={{ uri: generatedImageUrl }} className="size-full" resizeMode="cover" />
                ) : (
                  <View className="items-center gap-2">
                    <FireLoader />
                    <Text className="body-medium text-gourmet-forest mt-2">Plating dish composition...</Text>
                  </View>
                )}
                
                {/* Category Tag */}
                <View className="absolute top-4 left-4 bg-gourmet-amber/95 px-3 py-1 rounded-full border border-white/20">
                  <Text className="small-bold text-white text-[9px] uppercase tracking-wider">{generatedFood.category}</Text>
                </View>
              </View>

              {/* Specs & Info */}
              <View className="p-5 gap-4">
                <View className="flex-between flex-row">
                  <Text className="h1-bold flex-1 mr-4">{generatedFood.name}</Text>
                  <Text className="h3-bold text-gourmet-forest">TSh {generatedFood.price.toLocaleString()}</Text>
                </View>

                <Text className="base-regular text-gray-200 italic">
                  {`"${generatedFood.description}"`}
                </Text>

                {/* Nutrition Badge row */}
                <View className="flex-row gap-3 py-2 border-y border-gourmet-border/50">
                  <View className="flex-1 bg-gourmet-bone p-2.5 rounded-lg border border-gourmet-border items-center">
                    <Text className="small-bold text-gray-200">Energy</Text>
                    <Text className="paragraph-bold text-gourmet-charcoal mt-0.5">{generatedFood.calories} kcal</Text>
                  </View>
                  <View className="flex-1 bg-gourmet-bone p-2.5 rounded-lg border border-gourmet-border items-center">
                    <Text className="small-bold text-gray-200">Protein</Text>
                    <Text className="paragraph-bold text-gourmet-charcoal mt-0.5">{generatedFood.protein}g</Text>
                  </View>
                </View>

                {/* Customizations tags */}
                <View>
                  <Text className="small-bold text-gray-200 mb-2">SUGGESTED ADDITIONS</Text>
                  <View className="flex-row flex-wrap gap-2">
                    {generatedFood.customizations.map((name, i) => (
                      <View key={i} className="bg-gourmet-bone border border-gourmet-border px-3 py-1 rounded-md">
                        <Text className="paragraph-semibold text-gourmet-charcoal">{name}</Text>
                      </View>
                    ))}
                  </View>
                </View>

                {/* Add to Cart button */}
                <TouchableOpacity
                  onPress={handleAddCustomToCart}
                  disabled={!generatedImageUrl}
                  className={`w-full py-4 rounded-lg flex items-center justify-center border ${
                    generatedImageUrl
                      ? "bg-gourmet-forest border-gourmet-forest/10"
                      : "bg-gourmet-forest/50 border-transparent"
                  }`}
                >
                  <Text className="base-bold text-white">Order Chef Custom Creation</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </ScrollView>
      )}
      </View>
    </SafeAreaView>
  );
}
