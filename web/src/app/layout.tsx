import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import Script from "next/script";
import { TEXT_SIZE_STORAGE_KEY } from "@/lib/textSize";
import "./globals.css";

/*
 * Two self-hosted variable woff2 faces (SIL OFL 1.1, licences in src/fonts).
 *   Fraunces  — warm, soft-serif display built for editorial/menu typography.
 *               It gives Swahili headlines an appetising, authoritative voice.
 *   DM Sans   — tall x-height, open apertures, stays readable at 13px on a
 *               cheap phone. Used for body copy, buttons and dense UI.
 * Variable files replace five 77KB TTFs, and nothing is fetched from Google.
 */
const fraunces = localFont({
  src: "../fonts/Fraunces-Variable.woff2",
  variable: "--font-fraunces",
  weight: "100 900",
  style: "normal",
  display: "swap",
  fallback: ["Georgia", "Times New Roman", "serif"],
});

const dmSans = localFont({
  src: "../fonts/DMSans-Variable.woff2",
  variable: "--font-dmsans",
  weight: "100 900",
  style: "normal",
  display: "swap",
  fallback: ["ui-sans-serif", "system-ui", "sans-serif"],
});

export const metadata: Metadata = {
  applicationName: "Bongo Foodie",
  title: "Bongo Foodie | Swahili Food in Dar es Salaam",
  description: "Explore Swahili dishes, find recipe advice with Chef AI, and order food in Dar es Salaam.",
  manifest: "/site.webmanifest",
  icons: {
    icon: [
      { url: "/favicon.svg", type: "image/svg+xml", sizes: "any" },
      { url: "/favicon-16x16.png", type: "image/png", sizes: "16x16" },
      { url: "/favicon-32x32.png", type: "image/png", sizes: "32x32" },
      { url: "/favicon.ico", type: "image/x-icon", sizes: "any" },
    ],
    apple: [
      { url: "/apple-touch-icon.png", type: "image/png", sizes: "180x180" },
    ],
    shortcut: ["/favicon.ico"],
  },
  appleWebApp: {
    capable: true,
    title: "Bongo Foodie",
    statusBarStyle: "black-translucent",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: "#1A100B",
  colorScheme: "light",
};

import Link from 'next/link';
import Image from 'next/image';
import { Download } from 'lucide-react';
import Navbar from "@/components/Navbar";
import CartDrawer from "@/components/CartDrawer";
import SmoothScroll from "@/components/SmoothScroll";
import ScrollProgress from "@/components/ScrollProgress";
import PageTransition from "@/components/PageTransition";
import TextSizeControl from "@/components/TextSizeControl";
import { appRelease, appReleaseUrl, appReleasePageUrl } from "@/lib/appRelease";
import { contact, contactLinks } from "@/lib/contact";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${fraunces.variable} ${dmSans.variable} h-full`}
      suppressHydrationWarning
    >
      <head>
        <Script id="bongo-text-size" strategy="beforeInteractive">{`
          try {
            var size = window.localStorage.getItem('${TEXT_SIZE_STORAGE_KEY}');
            if (size === 'normal' || size === 'large' || size === 'larger') {
              document.documentElement.dataset.textSize = size;
            }
          } catch (_) {}
        `}</Script>
      </head>
      <body className="min-h-full bg-background-warm text-foreground-dark antialiased font-sans flex flex-col">
        <SmoothScroll />
        <ScrollProgress />
        <PageTransition />
        <Navbar />
        <main className="flex-1 w-full max-w-7xl mx-auto px-4 md:px-8 py-4 md:py-6 pb-20 md:pb-12">
          {children}
        </main>

        {/* Footer: dark app band, three columns, real contact details. */}
        <footer className="w-full bg-card border-t border-border mt-auto">
          <div className="w-full bg-foreground-dark text-white">
            <div className="max-w-7xl mx-auto px-4 md:px-8 py-8 md:py-9 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
              <div className="flex items-center gap-4">
                <Image
                  src="/assets/brand/app-icon.png"
                  alt=""
                  width={56}
                  height={56}
                  className="rounded-2xl shrink-0"
                />
                <div className="space-y-1">
                  <h4 className="font-display font-extrabold text-base">
                    Pata app halisi ya Flutter
                  </h4>
                  <p className="text-xs text-white/65 leading-relaxed max-w-md">
                    BongoFoodie {appRelease.appVersion} · Android APK ({appRelease.size}) · Chef
                    Atelier AI, Kiswahili/English, Lipa Namba. Bila Play Store.
                  </p>
                </div>
              </div>
              <div className="flex flex-col sm:flex-row sm:items-center gap-3">
                <a
                  href={appReleaseUrl}
                  download
                  className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-full bg-primary text-primary-foreground font-extrabold text-sm hover:bg-white hover:text-foreground-dark transition-colors"
                >
                  <Download className="size-4" aria-hidden="true" />
                  Download APK
                </a>
                <a
                  href={appReleasePageUrl}
                  className="inline-flex items-center justify-center gap-2 px-4 py-3.5 rounded-full border border-white/20 text-white/70 font-semibold text-xs hover:border-white/50 hover:text-white transition-colors"
                >
                  {appRelease.minAndroid} · Build {appRelease.commit}
                </a>
              </div>
            </div>
          </div>

          <div className="max-w-7xl mx-auto px-4 md:px-8 py-10 grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-10">
            <div className="space-y-3">
              <span className="font-display font-extrabold text-base text-foreground-dark tracking-tight">
                Bongo Foodie
              </span>
              <p className="text-xs text-muted-foreground leading-relaxed max-w-xs">
                Swahili favourites, coastal recipes and a little help from Chef AI. Cooked in{' '}
                {contact.kitchen}, delivered across Dar es Salaam.
              </p>
            </div>

            <nav className="space-y-3" aria-labelledby="footer-shop">
              <h4
                id="footer-shop"
                className="font-heading font-bold text-[11px] uppercase tracking-widest text-primary"
              >
                Duka
              </h4>
              <ul className="space-y-1 text-xs font-medium text-muted-foreground">
                <li>
                  <Link href="/search" className="inline-flex min-h-9 items-center hover:text-primary transition-colors">
                    Menyu yote
                  </Link>
                </li>
                <li>
                  <Link href="/chef-ai" className="inline-flex min-h-9 items-center hover:text-primary transition-colors">
                    Chef Atelier AI
                  </Link>
                </li>
                <li>
                  <Link href="/cart" className="inline-flex min-h-9 items-center hover:text-primary transition-colors">
                    Kikapu &amp; malipo
                  </Link>
                </li>
                <li>
                  <Link href="/profile" className="inline-flex min-h-9 items-center hover:text-primary transition-colors">
                    Oda zangu
                  </Link>
                </li>
              </ul>
            </nav>

            <div className="space-y-3">
              <h4 className="font-heading font-bold text-[11px] uppercase tracking-widest text-primary">
                Mawasiliano
              </h4>
              <ul className="space-y-1 text-xs font-medium text-muted-foreground">
                <li>
                  <a
                    href={contactLinks.email}
                    className="inline-flex min-h-9 items-center hover:text-primary transition-colors"
                  >
                    {contact.email}
                  </a>
                </li>
                <li>
                  <a
                    href={contactLinks.phone}
                    className="inline-flex min-h-9 items-center hover:text-primary transition-colors"
                  >
                    {contact.phoneDisplay}
                  </a>
                </li>
                <li>
                  <a
                    href={contactLinks.whatsapp}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex min-h-9 items-center hover:text-primary transition-colors"
                  >
                    WhatsApp
                  </a>
                </li>
              </ul>
              <p className="text-[11px] text-muted-foreground/80">{contact.hours}</p>
            </div>
          </div>

          {/* Reading size lives here, not in the sticky header: on the home
              page it sat between the nav and the hero and broke the
              editorial entrance. It is still one tap from every page. */}
          <div className="max-w-7xl mx-auto px-4 md:px-8 pt-5 pb-1">
            <div
              role="group"
              aria-label="Reading preferences"
              className="flex flex-wrap items-center justify-between gap-2 rounded-2xl border border-border bg-cream/70 px-4 py-2.5"
            >
              <TextSizeControl />
            </div>
          </div>

          <div className="max-w-7xl mx-auto px-4 md:px-8 pt-4 pb-6 border-t border-border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-[11px] text-muted-foreground">
            <span>© {new Date().getFullYear()} Bongo Foodie · Dar es Salaam, Tanzania</span>
            <span className="flex flex-wrap items-center gap-x-3 gap-y-1">
              <span>Lipa Namba</span>
              <span aria-hidden="true">·</span>
              <span>Cash on delivery</span>
              <span aria-hidden="true">·</span>
              <span>
                Built by{' '}
                <a href={contactLinks.email} className="font-semibold text-primary hover:underline">
                  Mwijay Davie
                </a>
              </span>
            </span>
          </div>
        </footer>

        <CartDrawer />
      </body>
    </html>
  );
}
