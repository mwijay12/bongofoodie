'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { AnimatePresence, MotionConfig, motion, useReducedMotion } from 'motion/react';
import { ArrowDown, ArrowRight, Flame, MapPin, MessageCircle, ShoppingBag } from 'lucide-react';
import SwahiliTrivia from '@/components/SwahiliTrivia';
import styles from './home.module.css';

const dishes = [
  { name: 'Nyama Choma', detail: '& ugali', image: '/assets/dishes/nyama_choma_ugali.png', note: 'Charcoal, kachumbari, good company.', label: 'From the grill', alt: 'Charcoal-grilled beef with ugali and fresh tomato-onion kachumbari' },
  { name: 'Chipsi Mayai', detail: 'Dar’s street-food classic', image: '/assets/dishes/chipsi_mayai.png', note: 'Golden chips. Fresh eggs. A little pili pili.', label: 'A Dar favourite', alt: 'Golden potato and egg omelette with fresh kachumbari on a ceramic plate' },
  { name: 'Zanzibar Pilau', detail: 'with beef & whole spices', image: '/assets/dishes/zanzibar_pilau.png', note: 'Cardamom, cloves and a taste of the coast.', label: 'From the spice coast', alt: 'Beef pilau with long-grain spiced rice and a fresh salad' },
];

export default function Home() {
  const [selected, setSelected] = useState(0);
  const reduceMotion = useReducedMotion();
  const dish = dishes[selected];

  return (
    <MotionConfig reducedMotion="user">
      <div className={styles.home}>
        <section className={styles.hero} aria-labelledby="home-title">
          <div className={styles.heroCopy}>
            <p className={styles.eyebrow}><MapPin size={15} aria-hidden="true" /> Dar es Salaam, Tanzania</p>
            <h1 id="home-title">Karibu.<br />Good food.<br /><span>Our coast.</span></h1>
            <p className={styles.intro}>From the charcoal grill to the spice markets of Zanzibar. Find your Swahili favourites, all in one place.</p>
            <div className={styles.actions}>
              <Link href="/search" className={styles.primary}>Explore the menu <ArrowRight size={19} aria-hidden="true" /></Link>
              <Link href="/chef-ai" className={styles.secondary}>Help me choose <MessageCircle size={18} aria-hidden="true" /></Link>
            </div>
            <a href="#coastal-table" className={styles.downLink}><ArrowDown size={16} aria-hidden="true" /> A taste of home</a>
          </div>
          <div className={styles.heroVisual}>
            <div className={styles.plateHalo} aria-hidden="true" />
            <div className={styles.plateStage}>
              <AnimatePresence mode="wait" initial={false}>
                <motion.div key={dish.name} className={styles.plate}
                  initial={reduceMotion ? false : { opacity: 0, rotate: -6, scale: 0.96 }}
                  animate={{ opacity: 1, rotate: 0, scale: 1 }}
                  exit={reduceMotion ? { opacity: 1 } : { opacity: 0, rotate: 5, scale: 0.97 }}
                  transition={reduceMotion ? { duration: 0 } : { type: 'spring', stiffness: 300, damping: 24 }}>
                  <Image src={dish.image} alt={dish.alt} fill sizes="(max-width: 760px) 92vw, 580px" className={styles.foodImage} priority={selected === 0} />
                </motion.div>
              </AnimatePresence>
            </div>
            <div className={styles.dishCaption} aria-live="polite" aria-atomic="true">
              <span>{dish.label}</span><h2>{dish.name}</h2><p>{dish.detail}</p>
            </div>
            <div className={styles.dishPicker} role="group" aria-label="Preview a Swahili dish">
              {dishes.map((item, index) => (
                <button key={item.name} aria-pressed={selected === index} onClick={() => setSelected(index)}>
                  {selected === index && <motion.span className={styles.pickerActive} layoutId="dish-selection" transition={reduceMotion ? { duration: 0 } : { type: 'spring', stiffness: 300, damping: 24 }} />}
                  <span className={styles.pickerLabel}>{item.name}</span>
                </button>
              ))}
            </div>
          </div>
        </section>

        <section id="coastal-table" className={styles.table} aria-labelledby="table-title">
          <div className={styles.sectionHeading}>
            <div><p className={styles.eyebrow}>Made familiar. Made Swahili.</p><h2 id="table-title">The coastal table.</h2></div>
            <Link href="/search">Browse the menu <ArrowRight size={18} aria-hidden="true" /></Link>
          </div>
          <div className={styles.dishGrid}>
            {dishes.map((item, index) => (
              <Link key={item.name} href="/search" className={styles.dishCard}>
                <div className={styles.cardImage}><span className={styles.cardNumber}>0{index + 1}</span><Image src={item.image} alt={item.alt} width={480} height={480} sizes="(max-width: 760px) 90vw, 33vw" /></div>
                <div className={styles.cardTitle}><h3>{item.name}</h3><ArrowRight size={20} aria-hidden="true" /></div>
                <p>{item.note}</p>
              </Link>
            ))}
          </div>
          <p className={styles.menuNote}>A few favourites from Swahili cooking. See the menu for current dishes, prices and availability.</p>
        </section>

        <section className={styles.chefNote} aria-labelledby="chef-title">
          <div className={styles.chefMark}><Flame size={30} strokeWidth={1.5} aria-hidden="true" /></div>
          <div><p className={styles.eyebrow}>Your seat at the table</p><h2 id="chef-title">A little help finding your next favourite?</h2><p>Ask Chef AI about ingredients, Swahili recipes or what goes well together.</p></div>
          <Link href="/chef-ai" className={styles.secondary}>Ask Chef AI <ArrowRight size={18} aria-hidden="true" /></Link>
        </section>
        <SwahiliTrivia />
        <Link href="/cart" className={styles.cartLink}><ShoppingBag size={20} aria-hidden="true" /><span>Already picked something? <strong>Review your bag</strong></span><ArrowRight size={18} aria-hidden="true" /></Link>
      </div>
    </MotionConfig>
  );
}
