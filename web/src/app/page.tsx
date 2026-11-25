'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ArrowRight, ArrowUpRight, Clock, Flame, MessageCircle, Star } from 'lucide-react';
import Logo from '@/components/Logo';
import Magnetic from '@/components/Magnetic';
import SwahiliTrivia from '@/components/SwahiliTrivia';
import { countUp, isFinePointer, splitWords } from '@/lib/motion';
import { contact, contactLinks } from '@/lib/contact';
import { appRelease, appReleaseUrl, repoUrl } from '@/lib/appRelease';
import styles from './home.module.css';

/*
 * The hero used to mount a Three.js plate (fiber + drei + an HDR environment
 * fetched at runtime). It is now a pure CSS/Image composition: real food
 * photography, a ceramic rim, steam and a ticket. No WebGL context, no rAF
 * render loop, no 700KB of 3D JavaScript on the first paint.
 */
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
        .from(`.${styles.plateWrap}`, { scale: 0.9, opacity: 0, duration: 1.1 }, '-=0.9');

      /* ── Plate drifts and the headline counter-moves on scroll ── */
      gsap.to(`.${styles.plateWrap}`, {
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

      /* ── Split-text: section headings rise word by word ── */
      gsap.utils.toArray<HTMLElement>('[data-split]').forEach((heading) => {
        const words = splitWords(heading);
        if (!words.length) return;
        gsap.from(words, {
          yPercent: 115,
          duration: 0.85,
          stagger: 0.06,
          ease: 'power3.out',
          scrollTrigger: { trigger: heading, start: 'top 88%', once: true },
        });
      });

      /* ── Proof stats count up when the hero settles ── */
      gsap.utils.toArray<HTMLElement>('[data-count]').forEach((el) => {
        const end = Number(el.dataset.count);
        if (!Number.isFinite(end)) return;
        countUp(el, end, {
          decimals: Number(el.dataset.decimals ?? 0),
          prefix: el.dataset.prefix ?? '',
          delay: 0.55,
        });
      });

      /* ── Hero plate floats gently (inner stage, so it never fights the
         scroll parallax on the wrapper) ── */
      gsap.to(`.${styles.plateStage}`, {
        y: -10,
        duration: 3.2,
        ease: 'sine.inOut',
        yoyo: true,
        repeat: -1,
      });

      /* ── Pointer parallax: plate leans toward the cursor, copy counter-moves ── */
      if (isFinePointer() && heroRef.current) {
        const plateX = gsap.quickTo(`.${styles.plateWrap}`, 'x', { duration: 0.6, ease: 'power3.out' });
        const plateY = gsap.quickTo(`.${styles.plateWrap}`, 'y', { duration: 0.6, ease: 'power3.out' });
        const copyX = gsap.quickTo(`.${styles.heroCopy}`, 'x', { duration: 0.8, ease: 'power3.out' });
        const copyY = gsap.quickTo(`.${styles.heroCopy}`, 'y', { duration: 0.8, ease: 'power3.out' });

        const onHeroMove = (event: MouseEvent) => {
          const rect = heroRef.current?.getBoundingClientRect();
          if (!rect) return;
          const nx = (event.clientX - rect.left) / rect.width - 0.5;
          const ny = (event.clientY - rect.top) / rect.height - 0.5;
          plateX(nx * 18);
          plateY(ny * 14);
          copyX(nx * -8);
          copyY(ny * -6);
        };
        const onHeroLeave = () => {
          plateX(0);
          plateY(0);
          copyX(0);
          copyY(0);
        };

        heroRef.current.addEventListener('mousemove', onHeroMove);
        heroRef.current.addEventListener('mouseleave', onHeroLeave);
        return () => {
          heroRef.current?.removeEventListener('mousemove', onHeroMove);
          heroRef.current?.removeEventListener('mouseleave', onHeroLeave);
        };
      }

      /* ── Dish cards tilt toward the pointer (21st.dev tilt-effect pattern) ── */
      if (isFinePointer()) {
        gsap.utils.toArray<HTMLElement>(`.${styles.dishCard}`).forEach((card) => {
          const onMove = (event: MouseEvent) => {
            const rect = card.getBoundingClientRect();
            const nx = (event.clientX - rect.left) / rect.width - 0.5;
            const ny = (event.clientY - rect.top) / rect.height - 0.5;
            gsap.to(card, {
              rotationY: nx * 10,
              rotationX: ny * -8,
              transformPerspective: 900,
              y: -4,
              duration: 0.4,
              ease: 'power2.out',
              overwrite: 'auto',
            });
          };
          const onLeave = () => {
            gsap.to(card, {
              rotationX: 0,
              rotationY: 0,
              y: 0,
              duration: 0.7,
              ease: 'elastic.out(1, 0.5)',
              overwrite: 'auto',
            });
          };
          card.addEventListener('mousemove', onMove);
          card.addEventListener('mouseleave', onLeave);
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
            <Magnetic>
              <Link href="/search" className={styles.primary}>
                Explore the menu
                <ArrowRight size={18} aria-hidden="true" />
              </Link>
            </Magnetic>
            <Magnetic>
              <Link href="/chef-ai" className={styles.secondary}>
                Ask Chef AI
                <MessageCircle size={17} aria-hidden="true" />
              </Link>
            </Magnetic>
          </div>

          <dl className={`${styles.proof} ${styles.heroFade}`}>
            <div>
              <dt>Signature dishes</dt>
              <dd>
                <span data-count="11">11</span>
              </dd>
            </div>
            <div>
              <dt>Average rating</dt>
              <dd>
                <Star size={15} className={styles.star} aria-hidden="true" />
                <span data-count="4.8" data-decimals="1">
                  4.8
                </span>
              </dd>
            </div>
            <div>
              <dt>Delivery in Dar</dt>
              <dd>
                <span data-count="2000" data-prefix="TSh ">
                  TSh 2,000
                </span>
              </dd>
            </div>
          </dl>
        </div>

        <div className={styles.plateWrap}>
          <div className={styles.glow} aria-hidden="true" />
          <div className={styles.plateStage}>
            <div className={styles.plateRing} aria-hidden="true">
              <span className={styles.ringMark} />
            </div>
            <div className={styles.steam} aria-hidden="true">
              <span />
              <span />
              <span />
            </div>
            <Image
              className={styles.heroDish}
              src="/assets/hero/nyama-choma.webp"
              alt="Nyama choma na ugali: charcoal-grilled beef, ugali and kachumbari on a ceramic plate"
              width={760}
              height={760}
              sizes="(max-width: 1000px) 90vw, 40vw"
              priority
            />
            <div className={styles.sideDish} aria-hidden="true">
              <Image
                src="/assets/hero/chipsi-mayai.webp"
                alt=""
                width={360}
                height={312}
                sizes="160px"
                loading="eager"
              />
            </div>
            <div className={styles.ticket}>
              <span className={styles.ticketLabel}>Sahani ya leo</span>
              <span className={styles.ticketName}>Nyama Choma</span>
              <span className={styles.ticketMeta}>
                <span>
                  <Star size={13} aria-hidden="true" /> 4.9
                </span>
                <span>
                  <Clock size={13} aria-hidden="true" /> 25 min
                </span>
              </span>
              <span className={styles.ticketPrice}>TSh 13,500</span>
            </div>
          </div>
          <p className={styles.plateCaption}>
            <span className={styles.plateCaptionDot} aria-hidden="true" />
            Fresh off the charcoal · Kijitonyama
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
        <div className={styles.sectionHead}>
          <p className={`${styles.eyebrow} ${styles.reveal}`}>From order to doorstep</p>
          <h2 id="how-title" data-split>
            Hatua tatu. Hakuna mshangao.
          </h2>
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
        <div className={styles.sectionHeading}>
          <div>
            <p className={`${styles.eyebrow} ${styles.reveal}`}>The coastal table</p>
            <h2 id="table-title" data-split>
              Made familiar. Made Swahili.
            </h2>
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
          <h2 id="chef-title" data-split>
            Hujui kula nini leo?
          </h2>
          <p>
            Ask about spice pairings, what is good today, or design a Swahili plate that
            does not exist yet — then order it.
          </p>
        </div>
        <Magnetic>
          <Link href="/chef-ai" className={styles.secondary}>
            Open Chef AI
            <ArrowUpRight size={17} aria-hidden="true" />
          </Link>
        </Magnetic>
      </section>

      <SwahiliTrivia />

      {/* ─────────────────────────── APP ──────────────────────────── */}
      <section className={styles.appBand} aria-labelledby="app-title">
        <Logo size={56} />
        <div>
          <p className={styles.eyebrow}>The Flutter app</p>
          <h2 id="app-title" data-split>
            Take BongoFoodie with you.
          </h2>
          <p>
            The full app — Chef AI, live order tracking, Kiswahili and English — as a{' '}
            {appRelease.size} Android download.
          </p>
        </div>
        <Magnetic>
          <a href={appReleaseUrl} className={styles.primary} download>
            Download APK
          </a>
        </Magnetic>
      </section>

      {/* ───────────────────────── CONTACT ────────────────────────── */}
      <section className={styles.contact} aria-labelledby="contact-title">
        <div>
          <p className={styles.eyebrow}>Talk to us</p>
          <h2 id="contact-title" data-split>
            Something not right with an order?
          </h2>
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
