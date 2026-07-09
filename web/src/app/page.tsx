'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Sparkles, ArrowRight, Compass, ShoppingBag, HelpCircle } from 'lucide-react';

const TRIVIA_QUESTIONS = [
  {
    id: 1,
    question: "Which spice is known as 'Mdalasini' in East African cooking?",
    options: ["Clove", "Cinnamon", "Cardamom", "Ginger"],
    correctIndex: 1,
    explainer: "Mdalasini is Cinnamon! It is harvested from tree bark and used to add sweet aroma to Swahili Chai and Pilau."
  },
  {
    id: 2,
    question: "What does 'Tui la Nazi' translate to in English?",
    options: ["Coconut Milk", "Fresh Cow Milk", "Peanut Paste", "Mango Juice"],
    correctIndex: 0,
    explainer: "Correct! Tui la Nazi is Coconut Milk, a foundational ingredient in coastal cooking."
  },
  {
    id: 3,
    question: "What are 'Mishkaki' in Tanzanian cuisine?",
    options: ["Beef Skewers", "French Fries Omelette", "Spiced Rice", "Coconut Beans"],
    correctIndex: 0,
    explainer: "Mishkaki is Tanzanian marinated beef skewers, grilled over hot charcoal until tender and smoky."
  }
];

export default function Home() {
  const [quizIndex, setQuizIndex] = useState(0);
  const [selectedAns, setSelectedAns] = useState<number | null>(null);
  const [showExplanation, setShowExplanation] = useState(false);
  const [hideQuiz, setHideQuiz] = useState(false);

  useEffect(() => {
    // Select daily quiz based on today's day number
    setQuizIndex(new Date().getDay() % TRIVIA_QUESTIONS.length);
  }, []);

  const currentQuiz = TRIVIA_QUESTIONS[quizIndex];

  return (
    <div className="flex flex-col gap-12 py-10">
      
      {/* Hero Section */}
      <section className="bg-white border border-border rounded-3xl p-8 md:p-12 flex flex-col md:flex-row items-center justify-between gap-8 shadow-sm">
        <div className="flex-1 space-y-6 text-center md:text-left">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider">
            <Sparkles className="size-3.5 fill-primary" /> Spiced by Chef AI
          </span>
          <h1 className="font-heading text-4xl md:text-6xl font-extrabold tracking-tight text-foreground-dark leading-none">
            Authentic Swahili <br />
            <span className="text-primary">Gastronomy</span>
          </h1>
          <p className="text-muted-foreground text-base md:text-lg max-w-lg font-medium">
            Savor the rich heritage of coastal East African dishes like Chipsi Mayai, Nyama Choma, and Samaki wa Kupaka. Perfected by culinary wisdom, delivered hot.
          </p>
          <div className="flex flex-col sm:flex-row items-center gap-4 justify-center md:justify-start">
            <Link 
              href="/search" 
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3.5 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors duration-200"
            >
              Order Now <ArrowRight className="size-5" />
            </Link>
            <Link 
              href="/chef-ai" 
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3.5 border border-border bg-card text-foreground-dark font-heading font-bold rounded-xl hover:bg-muted transition-colors duration-200"
            >
              Consult Chef AI
            </Link>
          </div>
        </div>
        
        {/* Visual Graphic Representation - 3D Food Images */}
        <div className="w-full md:w-[40%] flex items-center justify-center">
          <div className="relative size-72 md:size-80">
            <div className="absolute inset-0 rounded-3xl bg-secondary/10 border border-secondary/20 overflow-hidden">
              <div className="absolute inset-0 bg-radial from-secondary/20 to-transparent pointer-events-none" />
            </div>
            <div className="relative z-10 grid grid-cols-2 gap-2 p-4 h-full">
              <div className="relative rounded-xl overflow-hidden bg-white/60 shadow-sm">
                <Image src="/assets/food-3d-icon.png" alt="Swahili Dish" fill className="object-contain p-2" />
              </div>
              <div className="relative rounded-xl overflow-hidden bg-white/60 shadow-sm">
                <Image src="/assets/food-3d-icon-2.png" alt="Tanzanian Cuisine" fill className="object-contain p-2" />
              </div>
              <div className="relative rounded-xl overflow-hidden bg-white/60 shadow-sm">
                <Image src="/assets/food-3d-icon-3.png" alt="East African Food" fill className="object-contain p-2" />
              </div>
              <div className="relative rounded-xl overflow-hidden bg-white/60 shadow-sm">
                <Image src="/assets/orange-juice-icon.png" alt="Fresh Juice" fill className="object-contain p-2" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Daily Culinary Trivia Box */}
      {!hideQuiz && currentQuiz && (
        <section className="bg-amber-50/20 border border-amber-200/60 p-6 md:p-8 rounded-3xl shadow-sm space-y-4">
          <div className="flex items-center gap-2 text-primary">
            <HelpCircle className="size-5" />
            <span className="font-heading font-black text-sm uppercase tracking-wider">Daily Swahili Trivia</span>
          </div>
          <div className="space-y-4 max-w-xl">
            <h3 className="font-heading text-lg md:text-xl font-extrabold text-foreground-dark">
              {currentQuiz.question}
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {currentQuiz.options.map((opt, idx) => {
                const isSelected = selectedAns === idx;
                const isCorrect = idx === currentQuiz.correctIndex;
                let btnStyle = "border-border bg-white hover:bg-muted/30 text-foreground-dark";

                if (selectedAns !== null) {
                  if (isCorrect) {
                    btnStyle = "border-green-300 bg-green-50 text-green-800 font-bold";
                  } else if (isSelected) {
                    btnStyle = "border-red-300 bg-red-50 text-red-800 font-bold";
                  } else {
                    btnStyle = "border-border bg-white opacity-60 pointer-events-none";
                  }
                }

                return (
                  <button
                    key={idx}
                    onClick={() => {
                      if (selectedAns !== null) return;
                      setSelectedAns(idx);
                      setShowExplanation(true);
                    }}
                    className={`p-3 text-left rounded-xl border text-sm font-semibold transition-all ${btnStyle}`}
                  >
                    {opt}
                  </button>
                );
              })}
            </div>

            {showExplanation && (
              <div className="mt-4 p-4 bg-white/80 border border-amber-200 rounded-xl space-y-2 animate-in fade-in slide-in-from-top duration-300">
                <span className="font-heading font-black text-sm text-foreground-dark block">
                  {selectedAns === currentQuiz.correctIndex 
                    ? "🎉 Correct! Unlocked Coupon: KARIBU2000 (TSh 2,000 off at Cart Checkout)" 
                    : "❌ Try Again!"}
                </span>
                <p className="text-xs text-muted-foreground font-medium leading-relaxed">
                  {currentQuiz.explainer}
                </p>
                {selectedAns === currentQuiz.correctIndex && (
                  <button 
                    onClick={() => setHideQuiz(true)}
                    className="inline-flex items-center text-xs font-bold text-primary hover:text-secondary mt-2 underline"
                  >
                    Got it, Dismiss Quiz
                  </button>
                )}
              </div>
            )}
          </div>
        </section>
      )}

      {/* Feature Navigation Bento Grid */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Card 1: Menu */}
        <Link 
          href="/search"
          className="group bg-white border border-border p-6 rounded-2xl hover:border-primary transition-all duration-200 shadow-sm"
        >
          <div className="size-12 rounded-xl bg-primary/10 flex items-center justify-center mb-5 group-hover:bg-primary group-hover:text-white transition-colors duration-200 text-primary">
            <Compass className="size-6" />
          </div>
          <h3 className="font-heading text-lg font-bold text-foreground-dark mb-2">Explore Menu</h3>
          <p className="text-sm text-muted-foreground font-medium">
            Browse through our local Swahili delicacies sorted by ingredients, pricing, and ratings.
          </p>
        </Link>

        {/* Card 2: Chef AI */}
        <Link 
          href="/chef-ai"
          className="group bg-white border border-border p-6 rounded-2xl hover:border-primary transition-all duration-200 shadow-sm"
        >
          <div className="size-12 rounded-xl bg-primary/10 flex items-center justify-center mb-5 group-hover:bg-primary group-hover:text-white transition-colors duration-200 text-primary">
            <Sparkles className="size-6" />
          </div>
          <h3 className="font-heading text-lg font-bold text-foreground-dark mb-2">Gourmet Chat Atelier</h3>
          <p className="text-sm text-muted-foreground font-medium">
            Chat with our AI assistant for Swahili recipe pairings and kitchen tips in Swahili and English.
          </p>
        </Link>

        {/* Card 3: Cart */}
        <Link 
          href="/cart"
          className="group bg-white border border-border p-6 rounded-2xl hover:border-primary transition-all duration-200 shadow-sm"
        >
          <div className="size-12 rounded-xl bg-primary/10 flex items-center justify-center mb-5 group-hover:bg-primary group-hover:text-white transition-colors duration-200 text-primary">
            <ShoppingBag className="size-6" />
          </div>
          <h3 className="font-heading text-lg font-bold text-foreground-dark mb-2">View Cart</h3>
          <p className="text-sm text-muted-foreground font-medium">
            Review your order selection, choose delivery location, and simulate checkout instantly.
          </p>
        </Link>
      </section>

    </div>
  );
}
