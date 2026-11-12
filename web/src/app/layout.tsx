import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";

const outfit = localFont({
  variable: "--font-outfit",
  src: [
    { path: "../fonts/Quicksand-Medium.ttf", weight: "500", style: "normal" },
    { path: "../fonts/Quicksand-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "../fonts/Quicksand-Bold.ttf", weight: "700", style: "normal" },
    { path: "../fonts/Quicksand-Bold.ttf", weight: "800", style: "normal" },
  ],
});

const quicksand = localFont({
  variable: "--font-quicksand",
  src: [
    { path: "../fonts/Quicksand-Light.ttf", weight: "300", style: "normal" },
    { path: "../fonts/Quicksand-Regular.ttf", weight: "400", style: "normal" },
    { path: "../fonts/Quicksand-Medium.ttf", weight: "500", style: "normal" },
    { path: "../fonts/Quicksand-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "../fonts/Quicksand-Bold.ttf", weight: "700", style: "normal" },
  ],
});

export const metadata: Metadata = {
  title: "Bongo Foodie | Swahili Food in Dar es Salaam",
  description: "Explore Swahili dishes, find recipe advice with Chef AI, and order food in Dar es Salaam.",
};

import Link from 'next/link';
import Image from 'next/image';
import { Download } from 'lucide-react';
import Navbar from "@/components/Navbar";
import CartDrawer from "@/components/CartDrawer";
import { appRelease, appReleaseUrl, appReleasePageUrl } from "@/lib/appRelease";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${outfit.variable} ${quicksand.variable} h-full`}>
      <body className="min-h-full bg-background-warm text-foreground-dark antialiased font-sans flex flex-col">
        <Navbar />
        <main className="flex-1 w-full max-w-7xl mx-auto px-4 md:px-8 py-4 md:py-6 pb-20 md:pb-12">
          {children}
        </main>

        {/* Premium Swahili Footer */}
        <footer className="w-full bg-card border-t border-border mt-auto">
          {/* Real Flutter app download — the showcase build is a GitHub release asset. */}
          <div className="w-full bg-foreground-dark">
            <div className="max-w-7xl mx-auto px-4 md:px-8 py-8 md:py-10 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
              <div className="flex items-center gap-4">
                <Image
                  src="/assets/brand/app-icon.png"
                  alt=""
                  width={64}
                  height={64}
                  className="rounded-2xl shadow-lg shrink-0"
                />
                <div className="space-y-1">
                  <h4 className="font-heading font-extrabold text-base md:text-lg text-white">
                    Pata app halisi ya Flutter
                  </h4>
                  <p className="text-xs text-white/70 leading-relaxed max-w-md">
                    BongoFoodie {appRelease.appVersion} · Android APK ({appRelease.size}) · Chef Atelier AI,
                    Kiswahili/English, Lipa Namba. Bila Play Store.
                  </p>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row sm:items-center gap-3">
                <a
                  href={appReleaseUrl}
                  className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-full bg-primary text-white font-extrabold text-sm hover:bg-secondary hover:text-secondary-foreground transition-colors shadow-lg"
                  download
                >
                  <Download className="size-4" aria-hidden="true" />
                  Download APK
                </a>
                <a
                  href={appReleasePageUrl}
                  className="inline-flex items-center justify-center gap-2 px-4 py-3.5 rounded-full border border-white/25 text-white/80 font-semibold text-xs hover:border-white/60 hover:text-white transition-colors"
                >
                  {appRelease.minAndroid} · Build {appRelease.commit}
                </a>
              </div>
            </div>
          </div>

          <div className="max-w-7xl mx-auto px-4 md:px-8 py-10 grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="space-y-4">
              <div className="flex items-center gap-2">

                <span className="font-heading font-extrabold text-lg text-foreground-dark">BONGO FOODIE</span>
              </div>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Swahili favourites, coastal recipes and a little help from Chef AI. Made for your table in Dar es Salaam.
              </p>
            </div>

            <div className="space-y-3">
              <h4 className="font-heading font-bold text-xs uppercase tracking-wider text-primary">Sitemap</h4>
              <ul className="space-y-2 text-xs font-medium text-muted-foreground">
                <li><Link href="/search" className="hover:text-primary transition-colors">Explore Menu</Link></li>
                <li><Link href="/chef-ai" className="hover:text-primary transition-colors">Consult Chef AI</Link></li>
                <li><Link href="/cart" className="hover:text-primary transition-colors">View Cart</Link></li>
                <li><Link href="/profile" className="hover:text-primary transition-colors">My Profile</Link></li>
                <li><Link href="/admin" className="hover:text-primary transition-colors">Manager Portal</Link></li>
              </ul>
            </div>

            <div className="space-y-3">
              <h4 className="font-heading font-bold text-xs uppercase tracking-wider text-primary">From the coast</h4>
              <p className="text-xs italic text-muted-foreground leading-relaxed">
                Kula vizuri, ishi vizuri. Chakula bora cha Waswahili kimeandaliwa kwa upendo na viungo asilia vya Kitanzania.
              </p>
            </div>

            <div className="space-y-3">
              <h4 className="font-heading font-bold text-xs uppercase tracking-wider text-primary">Payment Channels</h4>
              <div className="grid grid-cols-3 gap-2 text-[10px] font-bold text-muted-foreground">
                <span className="bg-muted px-2 py-1 rounded-md text-center">M-PESA</span>
                <span className="bg-muted px-2 py-1 rounded-md text-center">TIGO PESA</span>
                <span className="bg-muted px-2 py-1 rounded-md text-center">AIRTEL</span>
                <span className="bg-muted px-2 py-1 rounded-md text-center">HALOPESA</span>
                <span className="bg-muted px-2 py-1 rounded-md text-center">CRDB</span>
                <span className="bg-muted px-2 py-1 rounded-md text-center">NMB</span>
              </div>
            </div>
          </div>

          <div className="max-w-7xl mx-auto px-4 md:px-8 py-4 border-t border-border flex flex-col sm:flex-row items-center justify-between text-[11px] text-muted-foreground font-semibold gap-2">
            <span>© {new Date().getFullYear()} Bongo Foodie. All Rights Reserved.</span>
            <span>Dar es Salaam, Tanzania</span>
          </div>

          {/* Developer Credits */}
          <div className="bg-primary/5 border-t border-primary/10">
            <div className="max-w-7xl mx-auto px-4 md:px-8 py-3 flex flex-col sm:flex-row items-center justify-between text-[11px] text-muted-foreground gap-1">
              <span className="font-medium">
                Built by <strong className="text-primary">Mwijay Davie</strong>
              </span>
              <span className="flex items-center gap-3">
                <a href="tel:+255790942616" className="hover:text-primary transition-colors">0790942616</a>
                <a href="mailto:mwijaydavie@gmail.com" className="hover:text-primary transition-colors">mwijaydavie@gmail.com</a>
              </span>
            </div>
          </div>
        </footer>

        <CartDrawer />
      </body>
    </html>
  );
}
