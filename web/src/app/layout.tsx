import type { Metadata } from "next";
import { Outfit, Quicksand } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
});

const quicksand = Quicksand({
  variable: "--font-quicksand",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "Bongo Foodie | Premium Swahili Gastronomy",
  description: "Experience authentic East African culinary art with real-time AI assistance, custom dish creation, and prompt local delivery in Dar es Salaam.",
};

import Link from 'next/link';
import Navbar from "@/components/Navbar";
import CartDrawer from "@/components/CartDrawer";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${outfit.variable} ${quicksand.variable} h-full`}>
      <body className="min-h-full bg-background-warm text-foreground-dark antialiased font-sans flex flex-col">
        <Navbar />
        <main className="flex-1 w-full max-w-7xl mx-auto px-4 md:px-8 py-6 pb-12">
          {children}
        </main>
        
        {/* Premium Swahili Footer */}
        <footer className="w-full bg-card border-t border-border mt-auto">
          <div className="max-w-7xl mx-auto px-4 md:px-8 py-10 grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <span className="text-xl">🔥</span>
                <span className="font-heading font-extrabold text-lg text-foreground-dark">BONGO FOODIE</span>
              </div>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Authentic Swahili gastronomy paired with real-time culinary intelligence. Perfected by coastal recipes, cooked by gourmet chefs, delivered hot.
              </p>
            </div>
            
            <div className="space-y-3">
              <h4 className="font-heading font-bold text-xs uppercase tracking-wider text-primary">Sitemap</h4>
              <ul className="space-y-2 text-xs font-medium text-muted-foreground">
                <li><Link href="/search" className="hover:text-primary transition-colors">Explore Menu</Link></li>
                <li><Link href="/chef-ai" className="hover:text-primary transition-colors">Consult Chef AI</Link></li>
                <li><Link href="/cart" className="hover:text-primary transition-colors">View Cart</Link></li>
                <li><Link href="/admin" className="hover:text-primary transition-colors">Manager Portal</Link></li>
              </ul>
            </div>

            <div className="space-y-3">
              <h4 className="font-heading font-bold text-xs uppercase tracking-wider text-primary">Gourmet Quote</h4>
              <p className="text-xs italic text-muted-foreground leading-relaxed">
                "Kula vizuri, ishi vizuri. Chakula bora cha Waswahili kimeandaliwa kwa upendo na viungo asilia vya Kitanzania."
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
        </footer>

        <CartDrawer />
      </body>
    </html>
  );
}
