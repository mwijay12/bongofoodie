'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Send, Sparkles, Loader2, Utensils, Plus, ShoppingBag, Check, Image as ImageIcon, Volume2, VolumeX, Globe } from 'lucide-react';
import { useCartStore } from '@/store/cart.store';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

interface CustomDish {
  name: string;
  description: string;
  price: number;
  ingredients: string[];
  calories: number;
  protein: string;
  recipe: string;
}

type LangOption = 'en' | 'sw' | 'auto';

export default function ChefAiPage() {
  const [messages, setMessages] = useState<Message[]>([
    { role: 'assistant', content: 'Welcome to Bongo Foodie Chef Atelier! How can I assist you with your Swahili food queries and order customizations today?' }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  
  // Language selector state (defaults to English 'en')
  const [language, setLanguage] = useState<LangOption>('en');

  // Custom Dish states
  const [customDish, setCustomDish] = useState<CustomDish | null>(null);
  const [customDishLoading, setCustomDishLoading] = useState(false);
  const [dishImageUrl, setDishImageUrl] = useState<string | null>(null);
  const [imageLoading, setImageLoading] = useState(false);
  const [addedToCart, setAddedToCart] = useState(false);

  // Voice synthesis states
  const [playingIndex, setPlayingIndex] = useState<number | null>(null);
  const [voiceLoading, setVoiceLoading] = useState<number | null>(null);
  const activeAudioRef = useRef<HTMLAudioElement | null>(null);
  
  const addCartItem = useCartStore((state) => state.addItem);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollToBottom();
    return () => {
      if (activeAudioRef.current) {
        activeAudioRef.current.pause();
      }
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        window.speechSynthesis.cancel();
      }
    };
  }, [messages, loading]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSend = async (textToSend?: string) => {
    const text = (textToSend || input).trim();
    if (!text || loading) return;

    if (!textToSend) setInput('');

    const newMessages = [...messages, { role: 'user', content: text } as Message];
    setMessages(newMessages);
    setLoading(true);

    try {
      const response = await fetch('/api/chef', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
          messages: newMessages,
          language: language // Pass language choice to Gemini system instructions!
        }),
      });

      const data = await response.json();
      if (data.reply) {
        setMessages([...newMessages, { role: 'assistant', content: data.reply }]);
      } else {
        setMessages([...newMessages, { role: 'assistant', content: 'Chef AI is currently busy. Please try again in a moment!' }]);
      }
    } catch (error) {
      console.error(error);
      setMessages([...newMessages, { role: 'assistant', content: 'Chef AI is currently busy. Please try again in a moment!' }]);
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateCustomDish = async () => {
    if (messages.length <= 1 || customDishLoading) return;
    
    setCustomDishLoading(true);
    setDishImageUrl(null);
    setAddedToCart(false);
    
    try {
      const response = await fetch('/api/chef/custom-dish', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ messages }),
      });
      
      const data = await response.json();
      if (data && data.name) {
        setCustomDish(data);
        triggerImageGeneration(data.name);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setCustomDishLoading(false);
    }
  };

  const triggerImageGeneration = async (name: string) => {
    setImageLoading(true);
    try {
      const imgRes = await fetch('/api/chef/generate-image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ dishName: name }),
      });
      const imgData = await imgRes.json();
      if (imgData.imageUrl) {
        setDishImageUrl(imgData.imageUrl);
      }
    } catch (err) {
      console.error('[Image generation failed]', err);
    } finally {
      setImageLoading(false);
    }
  };

  // Browser Fallback Speech Engine (Free & Unlimited!)
  const speakWithBrowserFallback = (text: string, index: number) => {
    if (typeof window === 'undefined' || !('speechSynthesis' in window)) {
      alert('Your browser does not support voice synthesis.');
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);

    // Set speech language based on selection or text
    if (language === 'sw') {
      utterance.lang = 'sw-TZ';
    } else {
      utterance.lang = 'en-US';
    }

    // Attempt to load proper voice
    const voices = window.speechSynthesis.getVoices();
    const targetVoice = voices.find(v => v.lang.startsWith(utterance.lang));
    if (targetVoice) {
      utterance.voice = targetVoice;
    }

    utterance.onend = () => {
      setPlayingIndex(null);
    };

    setPlayingIndex(index);
    window.speechSynthesis.speak(utterance);
  };

  const handleToggleVoice = async (text: string, index: number) => {
    // If playing, stop it
    if (playingIndex === index) {
      if (activeAudioRef.current) {
        activeAudioRef.current.pause();
        activeAudioRef.current = null;
      }
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        window.speechSynthesis.cancel();
      }
      setPlayingIndex(null);
      return;
    }

    // Stop active audio
    if (activeAudioRef.current) {
      activeAudioRef.current.pause();
      activeAudioRef.current = null;
    }
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
    setPlayingIndex(null);

    setVoiceLoading(index);
    try {
      const response = await fetch('/api/chef/speech', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text }),
      });

      if (!response.ok) throw new Error('ElevenLabs quota limit or credentials error');

      const blob = await response.blob();
      const audioUrl = URL.createObjectURL(blob);
      
      const audio = new Audio(audioUrl);
      activeAudioRef.current = audio;
      setPlayingIndex(index);
      
      audio.onended = () => {
        setPlayingIndex(null);
        activeAudioRef.current = null;
      };

      await audio.play();
    } catch (err) {
      console.warn('[ElevenLabs Speech failed, falling back to Browser synthesis]', err);
      // Seamlessly fall back to browser speechSynthesis!
      speakWithBrowserFallback(text, index);
    } finally {
      setVoiceLoading(null);
    }
  };

  const handleAddToCart = () => {
    if (!customDish) return;
    
    addCartItem({
      id: `ai-${Date.now()}`,
      name: customDish.name,
      price: customDish.price,
      image_url: dishImageUrl || 'chipsiMayai',
      isAICreated: true,
      calories: customDish.calories,
      protein: customDish.protein,
      recipe: customDish.recipe
    });
    
    setAddedToCart(true);
    setTimeout(() => setAddedToCart(false), 3000);
  };

  const starterPrompts = [
    'Recommend a drink for Nyama Choma',
    'What is a delicious meal option for lunch?',
    'Tell me how Chipsi Mayai is prepared',
    'Suggest a spicy topping combo'
  ];

  return (
    <div className="flex flex-col lg:flex-row gap-6 h-[calc(100vh-140px)] md:h-[calc(100vh-100px)] py-4 max-w-6xl mx-auto">
      
      {/* Left Chat Column */}
      <div className="flex-1 flex flex-col h-full bg-white border border-border rounded-3xl p-5 shadow-sm">
        
        {/* Chat Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-border">
          <div className="flex items-center gap-3">
            <div className="size-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
              <Sparkles className="size-5 fill-primary/10" />
            </div>
            <div>
              <h1 className="font-heading text-lg font-bold text-foreground-dark">Chef AI Atelier</h1>
              <p className="text-xs text-muted-foreground font-medium">Bespoke Recipes & Meal Builder</p>
            </div>
          </div>

          {/* Lang Selector & Custom Dish Trigger */}
          <div className="flex items-center gap-2">
            
            {/* Language Toggle Options */}
            <div className="inline-flex bg-muted p-1 rounded-xl border border-border text-xs font-bold text-muted-foreground">
              <button
                onClick={() => setLanguage('en')}
                className={`px-2 py-1 rounded-lg transition-colors cursor-pointer ${language === 'en' ? 'bg-white text-primary shadow-xs' : ''}`}
                title="Respond in English"
              >
                EN
              </button>
              <button
                onClick={() => setLanguage('sw')}
                className={`px-2 py-1 rounded-lg transition-colors cursor-pointer ${language === 'sw' ? 'bg-white text-primary shadow-xs' : ''}`}
                title="Jibu kwa Kiswahili pekee"
              >
                SW
              </button>
              <button
                onClick={() => setLanguage('auto')}
                className={`px-2 py-1 rounded-lg transition-colors cursor-pointer ${language === 'auto' ? 'bg-white text-primary shadow-xs' : ''}`}
                title="Kuchanganya Swahili/English mix"
              >
                AUTO
              </button>
            </div>

            {messages.length > 1 && (
              <button
                onClick={handleGenerateCustomDish}
                disabled={customDishLoading}
                className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-primary/10 hover:bg-primary/20 text-primary text-xs font-bold transition-all cursor-pointer"
              >
                {customDishLoading ? (
                  <Loader2 className="size-3.5 animate-spin" />
                ) : (
                  <Utensils className="size-3.5" />
                )}
                <span>Build Custom Dish</span>
              </button>
            )}

          </div>
        </div>

        {/* Messages List */}
        <div className="flex-1 overflow-y-auto no-scrollbar py-4 space-y-4 pr-1">
          {messages.map((msg, index) => {
            const isChef = msg.role === 'assistant';
            const isVoicePlaying = playingIndex === index;
            const isVoiceLoading = voiceLoading === index;

            return (
              <div 
                key={index} 
                className={`flex w-full ${isChef ? 'justify-start' : 'justify-end'}`}
              >
                <div 
                  className={`max-w-[85%] sm:max-w-[75%] p-4 rounded-2xl text-sm leading-relaxed font-sans relative ${
                    isChef 
                      ? 'bg-white border border-border text-foreground-dark rounded-tl-none shadow-xs pr-10' 
                      : 'bg-primary text-white rounded-tr-none shadow-sm shadow-primary/15'
                  }`}
                >
                  {isChef && (
                    <>
                      <span className="font-heading text-[10px] font-extrabold uppercase tracking-wider text-primary block mb-1">
                        Chef AI
                      </span>
                      <button
                        onClick={() => handleToggleVoice(msg.content, index)}
                        className="absolute top-3 right-3 text-muted-foreground hover:text-primary transition-colors cursor-pointer"
                      >
                        {isVoiceLoading ? (
                          <Loader2 className="size-4 animate-spin text-primary" />
                        ) : isVoicePlaying ? (
                          <VolumeX className="size-4 text-primary" />
                        ) : (
                          <Volume2 className="size-4" />
                        )}
                      </button>
                    </>
                  )}
                  <p className="font-medium">{msg.content}</p>
                </div>
              </div>
            );
          })}
          {loading && (
            <div className="flex justify-start">
              <div className="bg-white border border-border p-4 rounded-2xl rounded-tl-none flex items-center gap-2 shadow-xs">
                <span className="font-heading text-[10px] font-extrabold uppercase tracking-wider text-primary block">Chef AI</span>
                <Loader2 className="size-4 text-primary animate-spin" />
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Starter prompts */}
        {messages.length === 1 && (
          <div className="grid grid-cols-2 gap-2 pb-4">
            {starterPrompts.map((prompt, idx) => (
              <button
                key={idx}
                onClick={() => handleSend(prompt)}
                className="text-left p-3 border border-border bg-card text-xs font-semibold text-foreground-dark rounded-xl hover:border-primary hover:bg-primary/5 transition-all cursor-pointer"
              >
                {prompt}
              </button>
            ))}
          </div>
        )}

        {/* Input dock */}
        <div className="pt-2 border-t border-border bg-white">
          <div className="relative flex items-center">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleSend();
              }}
              placeholder="Tell Chef AI your customized toppings/sides..."
              className="w-full bg-white border border-border rounded-xl pl-4 pr-12 py-3.5 text-sm font-sans font-medium text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all shadow-sm"
            />
            <button
              onClick={() => handleSend()}
              disabled={!input.trim() || loading}
              className="absolute right-2 p-2 rounded-lg bg-primary text-white hover:bg-secondary transition-colors disabled:opacity-40 cursor-pointer"
            >
              <Send className="size-4" />
            </button>
          </div>
        </div>

      </div>

      {/* Right Custom Dish Atelier Sidebar */}
      <div className="w-full lg:w-[350px] bg-white border border-border rounded-3xl p-5 flex flex-col justify-between shadow-sm h-auto lg:h-full shrink-0">
        
        <div className="space-y-4">
          <div className="pb-3 border-b border-border">
            <h3 className="font-heading font-bold text-base text-foreground-dark flex items-center gap-1.5">
              <Utensils className="size-4.5 text-primary" /> Gourmet Dream Kitchen
            </h3>
            <p className="text-xs text-muted-foreground mt-0.5 font-medium">Chef AI converts chats into custom orderable plates.</p>
          </div>

          {customDishLoading ? (
            <div className="py-24 text-center space-y-3">
              <Loader2 className="size-8 text-primary animate-spin mx-auto" />
              <p className="text-xs text-muted-foreground font-semibold">Cooking up custom meal composition...</p>
            </div>
          ) : customDish ? (
            <div className="space-y-3 overflow-y-auto max-h-[calc(100vh-320px)] pr-1 no-scrollbar">
              
              {/* Image box representation */}
              <div className="w-full aspect-video bg-card border border-border rounded-2xl overflow-hidden relative flex items-center justify-center">
                {imageLoading ? (
                  <div className="absolute inset-0 bg-neutral-100 flex flex-col items-center justify-center gap-2">
                    <Loader2 className="size-6 text-primary animate-spin" />
                    <span className="text-[10px] text-muted-foreground font-bold">Generating Food Art...</span>
                  </div>
                ) : dishImageUrl ? (
                  <img 
                    src={dishImageUrl} 
                    alt={customDish.name} 
                    className="size-full object-cover animate-fade-in"
                  />
                ) : (
                  <div className="text-center space-y-1 text-muted-foreground/50">
                    <ImageIcon className="size-8 mx-auto" />
                    <span className="text-[10px] font-bold block">No Food Photo yet</span>
                  </div>
                )}
              </div>

              {/* Card display details */}
              <div className="p-4 bg-secondary/5 border border-secondary/20 rounded-2xl space-y-3">
                <div className="flex justify-between items-start gap-2">
                  <h4 className="font-heading font-bold text-foreground-dark text-sm leading-tight">{customDish.name}</h4>
                  <span className="bg-primary/10 text-primary text-[9px] font-extrabold uppercase px-2 py-0.5 rounded-full shrink-0">
                    Custom
                  </span>
                </div>
                <p className="text-[11px] text-muted-foreground leading-relaxed font-medium">{customDish.description}</p>
                
                {/* Stats */}
                <div className="grid grid-cols-2 gap-2 pt-2 border-t border-border/40 text-center">
                  <div className="bg-white/80 p-2 rounded-xl border border-border/30">
                    <span className="text-[9px] font-bold text-muted-foreground uppercase block">Calories</span>
                    <span className="font-heading font-extrabold text-xs text-foreground-dark">{customDish.calories} kcal</span>
                  </div>
                  <div className="bg-white/80 p-2 rounded-xl border border-border/30">
                    <span className="text-[9px] font-bold text-muted-foreground uppercase block">Protein</span>
                    <span className="font-heading font-extrabold text-xs text-foreground-dark">{customDish.protein}</span>
                  </div>
                </div>

                {/* Toppings list */}
                <div className="space-y-1">
                  <span className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground block">Ingredients:</span>
                  <div className="flex flex-wrap gap-1">
                    {customDish.ingredients.map((ing, i) => (
                      <span key={i} className="text-[9px] bg-white border border-border px-2 py-0.5 rounded-full text-foreground-dark font-semibold">
                        {ing}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Swahili recipe note */}
                <div className="text-[10px] text-primary italic font-semibold leading-snug">
                  📌 {customDish.recipe}
                </div>
              </div>
            </div>
          ) : (
            <div className="py-20 text-center space-y-3">
              <ShoppingBag className="size-12 text-muted-foreground/30 mx-auto stroke-[1.2px]" />
              <p className="text-xs text-muted-foreground font-semibold max-w-[200px] mx-auto leading-relaxed">
                Chat with Chef AI about custom adjustments, then click "Build Custom Dish" above to generate.
              </p>
            </div>
          )}
        </div>

        {/* Footer Add button */}
        {customDish && !customDishLoading && (
          <div className="pt-3 border-t border-border mt-3 shrink-0">
            <div className="flex justify-between items-center mb-3">
              <span className="text-xs font-bold text-muted-foreground">Kitchen Cost</span>
              <span className="font-heading font-extrabold text-primary text-base">
                TSh {customDish.price.toLocaleString()}
              </span>
            </div>
            
            <button
              onClick={handleAddToCart}
              className={`w-full py-3 rounded-xl font-heading font-bold text-sm inline-flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                addedToCart 
                  ? 'bg-emerald-600 text-white shadow-emerald-600/10' 
                  : 'bg-primary text-white hover:bg-secondary shadow-primary/10'
              }`}
            >
              {addedToCart ? (
                <>
                  <Check className="size-4.5" /> Added to Order
                </>
              ) : (
                <>
                  <Plus className="size-4.5" /> Order Chef's Custom
                </>
              )}
            </button>
          </div>
        )}

      </div>

    </div>
  );
}
