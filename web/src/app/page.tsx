'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import dynamic from 'next/dynamic';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ArrowRight, ArrowUpRight, Clock, Flame, MessageCircle, Star } from 'lucide-react';
import Logo from '@/components/Logo';
import SwahiliTrivia from '@/components/SwahiliTrivia';
import { contact, contactLinks } from '@/lib/contact';
import { appRelease, appReleaseUrl, repoUrl } from '@/lib/appRelease';
import styles from './home.module.css';

/** Three.js is heavy and client-only, so it never enters the server bundle. */
const PlateScene = dynamic(() => import('@/components/PlateScene'), {
  ssr: false,
  loading: () => <div className={styles.sceneSkeleton} aria-hidden="true" />,
});

const dishes = [
  {
    name: 'Nyama Choma',
    swahili: 'Nyama choma na ugali',
    price: 'TSh 13,500',
    minutes: 25,
    rating: '4.9',
    reviews: 126,
    image: '/assets/dishes/nyama_choma_ugali.png',
    alt: 'Charcoal-grilled beef with ugali and fresh tomato-onion kachumbari',
    note: 'Charcoal-grilled beef ribs, warm ugali, mchicha wa nazi and kachumbari.',
  },
  {
    name: 'Chipsi Mayai',
    swahili: 'Chipsi mayai',
    price: 'TSh 5,500',
    minutes: 12,
    rating: '4.9',
    reviews: 84,
    image: '/assets/dishes/chipsi_mayai.png',
    alt: 'Golden potato and egg omelette with fresh kachumbari on a ceramic plate',
    note: 'Golden chips folded into a fresh egg omelette with tamarind pili pili.',
  },
  {
    name: 'Zanzibar Pilau',
    swahili: 'Pilau ya nyama',
    price: 'TSh 10,000',
    minutes: 20,
    rating: '4.8',
    reviews: 97,
    image: '/assets/dishes/zanzibar_pilau.png',
    alt: 'Beef pilau with long-grain spiced rice and a fresh salad',
    note: 'Basmati steamed with beef, cardamom and cloves from the spice coast.',
  },
];

const steps = [
  { number: '01', title: 'Chagua sahani', body: 'Browse the Swahili menu, or ask Chef AI what fits your evening.' },
  { number: '02', title: 'Lipa rahisi', body: 'Lipa Namba or cash on delivery. No card, no account gymnastics.' },
  { number: '03', title: 'Fuata oda live', body: 'Placed, preparing, ready, on the way — four steps you can watch.' },
];

/** The scrolling guarantee strip under the hero. */
const marqueeWords = [
  'Nyama choma',
  'Chipsi mayai',
  'Pilau ya viungo',
  'Samaki wa kupaka',
  'Mishkaki',
  'Wali wa nazi',
  'Chef Atelier AI',
  'Lipa Namba',
  'Dar es Salaam',
];

export default function Home() {
  const root = useRef<HTMLDivElement>(null);
  const heroRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    gsap.registerPlugin(ScrollTrigger);

    const ctx = gsap.context(() => {
      /* ── Hero entrance: masked lines rise, then the rest settles in ── */
      const tl = gsap.timeline({ defaults: { ease: 'power3.out' } });
      tl.from(`.${styles.heroLine} > span`, {
        yPercent: 118,
        duration: 0.95,
        stagger: 0.09,
      })
        .from(
          `.${styles.heroFade}`,
          { y: 22, opacity: 0, duration: 0.7, stagger: 0.09 },
          '-=0.55',
        )
        .from(`.${styles.sceneWrap}`, { scale: 0.9, opacity: 0, duration: 1.1 }, '-=0.9');

      /* ── Scene drifts and the headline counter-moves on scroll ── */
      gsap.to(`.${styles.sceneWrap}`, {
        yPercent: 14,
        scale: 1.06,
        ease: 'none',
        scrollTrigger: { trigger: heroRef.current, start: 'top top', end: 'bottom top', scrub: 0.6 },
      });
      gsap.to(`.${styles.heroCopy}`, {
        yPercent: -12,
        opacity: 0.25,
        ease: 'none',
        scrollTrigger: { trigger: heroRef.current, start: 'top top', end: 'bottom top', scrub: 0.6 },
      });

      /* ── Section headings rise as they enter ── */
      gsap.utils.toArray<HTMLElement>(`.${styles.reveal}`).forEach((element) => {
        gsap.from(element, {
          y: 46,
          opacity: 0,
          duration: 0.8,
          ease: 'power3.out',
          scrollTrigger: { trigger: element, start: 'top 88%', once: true },
        });
      });

      /* ── Dish cards: stagger up, then tilt with the scroll ── */
      gsap.from(`.${styles.dishCard}`, {
        y: 66,
        opacity: 0,
        rotate: 2.5,
        duration: 0.85,
        stagger: 0.13,
        ease: 'power3.out',
        scrollTrigger: { trigger: `.${styles.dishGrid}`, start: 'top 85%', once: true },
      });

      /* ── Each dish image parallaxes inside its frame ── */
      gsap.utils.toArray<HTMLElement>(`.${styles.cardImage}`).forEach((frame) => {
        gsap.fromTo(
          frame.querySelector('img'),
          { yPercent: -7 },
          {
            yPercent: 7,
            ease: 'none',
            scrollTrigger: { trigger: frame, start: 'top bottom', end: 'bottom top', scrub: 0.5 },
          },
        );
      });

      /* ── The steps draw a line as you scroll through them ── */
      gsap.from(`.${styles.stepLine}`, {
        scaleX: 0,
        transformOrigin: 'left center',
        duration: 1.1,
        ease: 'power2.inOut',
        scrollTrigger: { trigger: `.${styles.steps}`, start: 'top 78%', once: true },
      });
      gsap.from(`.${styles.steps} li`, {
        y: 34,
        opacity: 0,
        duration: 0.7,
        stagger: 0.12,
        ease: 'power3.out',
        scrollTrigger: { trigger: `.${styles.steps}`, start: 'top 80%', once: true },
      });

      /* ── Ember band sweeps its glow in ── */
      gsap.from(`.${styles.glow}`, {
        scale: 0.4,
        opacity: 0,
        duration: 1.4,
        ease: 'power2.out',
        scrollTrigger: { trigger: `.${styles.chefNote}`, start: 'top 85%', once: true },
      });

      /* ── Trivia + contact ── */
      gsap.from(`.${styles.trivia}`, {
        y: 40,
        opacity: 0,
        duration: 0.8,
        ease: 'power3.out',
        scrollTrigger: { trigger: `.${styles.trivia}`, start: 'top 88%', once: true },
      });

      /* ── Marquee speeds up as you scroll, an old Awwwards trick ── */
      const marquee = root.current?.querySelector(`.${styles.marqueeTrack}`);
      if (marquee) {
        gsap.to(marquee, {
          xPercent: -8,
          ease: 'none',
          scrollTrigger: { trigger: marquee, start: 'top bottom', end: 'bottom top', scrub: 1 },
        });
      }
    }, root);

    return () => ctx.revert();
  }, []);

  return (
    <div className={styles.home} ref={root}>
      {/* ─────────────────────────── HERO ─────────────────────────── */}
      <section className={styles.hero} ref={heroRef} aria-labelledby="home-title">
        <div className={styles.heroCopy}>
          <p className={`${styles.eyebrow} ${styles.heroFade}`}>
            <span className={styles.dot} aria-hidden="true" />
            {contact.kitchen} · Dar es Salaam
          </p>

          <h1 id="home-title">
            <span className={styles.heroLine}>
              <span>Karibu.</span>
            </span>
            <span className={styles.heroLine}>
              <span>Chakula</span>
            </span>
            <span className={`${styles.heroLine} ${styles.heroLineAccent}`}>
              <span>kizuri.</span>
            </span>
          </h1>

          <p className={`${styles.intro} ${styles.heroFade}`}>
            Swahili favourites from the charcoal grill and the spice coast — cooked in
            Kijitonyama and brought to your door in Dar es Salaam.
          </p>

          <div className={`${styles.actions} ${styles.heroFade}`}>
            <Link href="/search" className={styles.primary}>
              Explore the menu
              <ArrowRight size={18} aria-hidden="true" />
            </Link>
            <Link href="/chef-ai" className={styles.secondary}>
              Ask Chef AI
              <MessageCircle size={17} aria-hidden="true" />
            </Link>
          </div>

          <dl className={`${styles.proof} ${styles.heroFade}`}>
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

        <div className={styles.sceneWrap}>
          <div className={styles.glow} aria-hidden="true" />
          <PlateScene className={styles.scene} />
          <p className={styles.sceneHint}>
            <span className={styles.sceneHintDot} aria-hidden="true" />
            Live 3D · drag to look around
          </p>
        </div>
      </section>

      {/* ────────────────────────── MARQUEE ───────────────────────── */}
      <div className={styles.marquee} aria-hidden="true">
        <div className={styles.marqueeTrack}>
          {[...marqueeWords, ...marqueeWords].map((word, index) => (
            <span key={`${word}-${index}`}>
              {word}
              <span className={styles.marqueeDot} />
            </span>
          ))}
        </div>
      </div>

      {/* ─────────────────────── HOW IT WORKS ─────────────────────── */}
      <section className={styles.how} aria-labelledby="how-title">
        <div className={`${styles.sectionHead} ${styles.reveal}`}>
          <p className={styles.eyebrow}>From order to doorstep</p>
          <h2 id="how-title">Hatua tatu. Hakuna mshangao.</h2>
        </div>
        <div className={styles.stepLine} aria-hidden="true" />
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

      {/* ──────────────────────── DISH GRID ───────────────────────── */}
      <section id="coastal-table" className={styles.table} aria-labelledby="table-title">
        <div className={`${styles.sectionHeading} ${styles.reveal}`}>
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
                <span className={styles.cardRating}>
                  <Star size={12} aria-hidden="true" />
                  {item.rating}
                  <span className={styles.cardReviews}>({item.reviews})</span>
                </span>
              </div>
              <div className={styles.cardTitle}>
                <h3>{item.name}</h3>
                <span className={styles.cardPrice}>{item.price}</span>
              </div>
              <p className={styles.cardSwahili}>{item.swahili}</p>
              <p>{item.note}</p>
              <span className={styles.cardMeta}>
                <Clock size={12} aria-hidden="true" />
                {item.minutes} min
                <span className={styles.cardCta}>
                  Order
                  <ArrowRight size={13} aria-hidden="true" />
                </span>
              </span>
            </Link>
          ))}
        </div>
        <p className={styles.menuNote}>
          A few favourites. See the menu for current prices and availability.
        </p>
      </section>

      {/* ───────────────────────── CHEF BAND ──────────────────────── */}
      <section className={styles.chefNote} aria-labelledby="chef-title">
        <div className={styles.glow} aria-hidden="true" />
        <div className={styles.chefMark}>
          <Flame size={26} strokeWidth={1.6} aria-hidden="true" />
        </div>
        <div>
          <p className={styles.eyebrow}>Chef Atelier AI</p>
          <h2 id="chef-title">Hujui kula nini leo?</h2>
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

      {/* ─────────────────────────── APP ──────────────────────────── */}
      <section className={styles.appBand} aria-labelledby="app-title">
        <Logo size={56} />
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

      {/* ───────────────────────── CONTACT ────────────────────────── */}
      <section className={styles.contact} aria-labelledby="contact-title">
        <div>
          <p className={styles.eyebrow}>Talk to us</p>
          <h2 id="contact-title">Something not right with an order?</h2>
          <p>Mail us and a person replies. Open {contact.hours.toLowerCase()}.</p>
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
  );
}
