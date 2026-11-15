'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { AnimatePresence, MotionConfig, motion, useReducedMotion } from 'motion/react';
import { ArrowRight, ArrowUpRight, Clock, Flame, MessageCircle, Star } from 'lucide-react';
import HeatShader from '@/components/HeatShader';
import SwahiliTrivia from '@/components/SwahiliTrivia';
import { contact, contactLinks } from '@/lib/contact';
import { appRelease, appReleaseUrl, repoUrl } from '@/lib/appRelease';
import styles from './home.module.css';

const dishes = [
  {
    name: 'Nyama Choma',
    swahili: 'Nyama choma na ugali',
    price: 'TSh 13,500',
    minutes: 25,
    image: '/assets/dishes/nyama_choma_ugali.png',
    alt: 'Charcoal-grilled beef with ugali and fresh tomato-onion kachumbari',
    note: 'Charcoal-grilled beef ribs, warm ugali, mchicha wa nazi and kachumbari.',
  },
  {
    name: 'Chipsi Mayai',
    swahili: 'Chipsi mayai',
    price: 'TSh 5,500',
    minutes: 12,
    image: '/assets/dishes/chipsi_mayai.png',
    alt: 'Golden potato and egg omelette with fresh kachumbari on a ceramic plate',
    note: 'Golden chips folded into a fresh egg omelette with tamarind pili pili.',
  },
  {
    name: 'Zanzibar Pilau',
    swahili: 'Pilau ya nyama',
    price: 'TSh 10,000',
    minutes: 20,
    image: '/assets/dishes/zanzibar_pilau.png',
    alt: 'Beef pilau with long-grain spiced rice and a fresh salad',
    note: 'Basmati steamed with beef, cardamom and cloves from the spice coast.',
  },
];

const steps = [
  { number: '01', title: 'Choose your plate', body: 'Browse the Swahili menu, or ask Chef AI what fits your evening.' },
  { number: '02', title: 'Pay how you like', body: 'Lipa Namba or cash on delivery. No card, no account gymnastics.' },
  { number: '03', title: 'Follow it live', body: 'Placed, preparing, ready, on the way — four steps you can watch.' },
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
            <p className={styles.eyebrow}>
              <span className={styles.dot} aria-hidden="true" />
              {contact.kitchen} · {contact.city.split(',')[0]}
            </p>
            <h1 id="home-title">
              Karibu.
              <br />
              Good food,
              <br />
              <span>cooked hot.</span>
            </h1>
            <p className={styles.intro}>
              Swahili favourites from the charcoal grill and the spice coast — cooked in
              Kijitonyama and brought to your door in Dar es Salaam.
            </p>
            <div className={styles.actions}>
              <Link href="/search" className={styles.primary}>
                Explore the menu
                <ArrowRight size={18} aria-hidden="true" />
              </Link>
              <Link href="/chef-ai" className={styles.secondary}>
                Ask Chef AI
                <MessageCircle size={17} aria-hidden="true" />
              </Link>
            </div>
            <dl className={styles.proof}>
              <div>
                <dt>Signature dishes</dt>
                <dd>11</dd>
              </div>
              <div>
                <dt>Average rating</dt>
                <dd>
                  <Star size={15} className={styles.star} aria-hidden="true" />
                  4.8
                </dd>
              </div>
              <div>
                <dt>Delivery in Dar</dt>
                <dd>TSh 2,000</dd>
              </div>
            </dl>
          </div>

          <div className={styles.heroVisual}>
            <HeatShader className={styles.shader} />
            <div className={styles.plateHalo} aria-hidden="true" />
            <div className={styles.plateStage}>
              <AnimatePresence mode="wait" initial={false}>
                <motion.div
                  key={dish.name}
                  className={styles.plate}
                  initial={reduceMotion ? false : { opacity: 0, rotate: -5, scale: 0.97 }}
                  animate={{ opacity: 1, rotate: 0, scale: 1 }}
                  exit={reduceMotion ? { opacity: 1 } : { opacity: 0, rotate: 4, scale: 0.97 }}
                  transition={
                    reduceMotion ? { duration: 0 } : { type: 'spring', stiffness: 260, damping: 26 }
                  }
                >
                  <Image
                    src={dish.image}
                    alt={dish.alt}
                    fill
                    sizes="(max-width: 760px) 88vw, 520px"
                    className={styles.foodImage}
                    priority={selected === 0}
                  />
                </motion.div>
              </AnimatePresence>
            </div>

            <div className={styles.dishCaption} aria-live="polite" aria-atomic="true">
              <span className={styles.dishSwahili}>{dish.swahili}</span>
              <h2>{dish.name}</h2>
              <div className={styles.dishMeta}>
                <span className={styles.price}>{dish.price}</span>
                <span className={styles.minutes}>
                  <Clock size={13} aria-hidden="true" />
                  {dish.minutes} min
                </span>
              </div>
            </div>

            <div className={styles.dishPicker} role="group" aria-label="Preview a Swahili dish">
              {dishes.map((item, index) => (
                <button
                  key={item.name}
                  type="button"
                  aria-pressed={selected === index}
                  onClick={() => setSelected(index)}
                >
                  {selected === index && (
                    <motion.span
                      className={styles.pickerActive}
                      layoutId="dish-selection"
                      transition={
                        reduceMotion ? { duration: 0 } : { type: 'spring', stiffness: 320, damping: 28 }
                      }
                    />
                  )}
                  <span className={styles.pickerLabel}>{item.name}</span>
                </button>
              ))}
            </div>
          </div>
        </section>

        <section className={styles.how} aria-labelledby="how-title">
          <div className={styles.sectionHead}>
            <p className={styles.eyebrow}>From order to doorstep</p>
            <h2 id="how-title">Three steps, no surprises.</h2>
          </div>
          <ol className={styles.steps}>
            {steps.map((step) => (
              <li key={step.number}>
                <span className={styles.stepNumber}>{step.number}</span>
                <h3>{step.title}</h3>
                <p>{step.body}</p>
              </li>
            ))}
          </ol>
        </section>

        <section id="coastal-table" className={styles.table} aria-labelledby="table-title">
          <div className={styles.sectionHeading}>
            <div>
              <p className={styles.eyebrow}>The coastal table</p>
              <h2 id="table-title">Made familiar. Made Swahili.</h2>
            </div>
            <Link href="/search" className={styles.textLink}>
              Browse the full menu
              <ArrowRight size={17} aria-hidden="true" />
            </Link>
          </div>
          <div className={styles.dishGrid}>
            {dishes.map((item, index) => (
              <Link key={item.name} href="/search" className={styles.dishCard}>
                <div className={styles.cardImage}>
                  <span className={styles.cardNumber}>0{index + 1}</span>
                  <Image
                    src={item.image}
                    alt={item.alt}
                    width={520}
                    height={520}
                    sizes="(max-width: 760px) 90vw, 33vw"
                  />
                </div>
                <div className={styles.cardTitle}>
                  <h3>{item.name}</h3>
                  <span className={styles.cardPrice}>{item.price}</span>
                </div>
                <p>{item.note}</p>
              </Link>
            ))}
          </div>
          <p className={styles.menuNote}>
            A few favourites. See the menu for current prices and availability.
          </p>
        </section>

        <section className={styles.chefNote} aria-labelledby="chef-title">
          <div className={styles.chefMark}>
            <Flame size={26} strokeWidth={1.6} aria-hidden="true" />
          </div>
          <div>
            <p className={styles.eyebrow}>Chef Atelier AI</p>
            <h2 id="chef-title">Not sure what to eat tonight?</h2>
            <p>
              Ask about spice pairings, what is good today, or design a Swahili plate that
              does not exist yet — then order it.
            </p>
          </div>
          <Link href="/chef-ai" className={styles.secondary}>
            Open Chef AI
            <ArrowUpRight size={17} aria-hidden="true" />
          </Link>
        </section>

        <SwahiliTrivia />

        <section className={styles.appBand} aria-labelledby="app-title">
          <Image
            src="/assets/brand/app-icon.png"
            alt=""
            width={64}
            height={64}
            className={styles.appIcon}
          />
          <div>
            <p className={styles.eyebrow}>The Flutter app</p>
            <h2 id="app-title">Take BongoFoodie with you.</h2>
            <p>
              The full app — Chef AI, live order tracking, Kiswahili and English — as a{' '}
              {appRelease.size} Android download.
            </p>
          </div>
          <a href={appReleaseUrl} className={styles.primary} download>
            Download APK
          </a>
        </section>

        <section className={styles.contact} aria-labelledby="contact-title">
          <div>
            <p className={styles.eyebrow}>Talk to us</p>
            <h2 id="contact-title">Something not right with an order?</h2>
            <p>
              Mail us and a person replies. Open {contact.hours.toLowerCase()}.
            </p>
          </div>
          <div className={styles.contactLinks}>
            <a href={contactLinks.email}>{contact.email}</a>
            <a href={contactLinks.phone}>{contact.phoneDisplay}</a>
            <a href={contactLinks.whatsapp} rel="noopener noreferrer" target="_blank">
              WhatsApp
            </a>
            <a href={repoUrl} rel="noopener noreferrer" target="_blank">
              GitHub
            </a>
          </div>
        </section>
      </div>
    </MotionConfig>
  );
}
