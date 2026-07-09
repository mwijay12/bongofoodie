'use client';

import React, { useState, useEffect } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useCartStore } from '@/store/cart.store';
import { resolveFoodImage } from '@/lib/imageMap';
import { Plus, Minus, Trash2, ShoppingBag, ArrowRight, Download } from 'lucide-react';
import LocationPicker from '@/components/LocationPicker';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import { supabase } from '@/lib/supabase';

export default function CartPage() {
  const { 
    items, 
    increaseQty, 
    decreaseQty, 
    removeItem, 
    getTotalPrice, 
    getTotalItems,
    clearCart
  } = useCartStore();

  const totalItems = getTotalItems();
  const totalPrice = getTotalPrice();

  const [tableNumber, setTableNumber] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [notes, setNotes] = useState('');
  const [selectedAddress, setSelectedAddress] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'lipanamba'>('cash');
  const [checkedOut, setCheckedOut] = useState(false);  // States to preserve items for receipt generation after cart flush
  const [lastOrderedItems, setLastOrderedItems] = useState<any[]>([]);
  const [lastOrderedTotal, setLastOrderedTotal] = useState(0);
  const [lastOrderId, setLastOrderId] = useState('');
  const [promoCode, setPromoCode] = useState('');
  const [promoDiscount, setPromoDiscount] = useState(1000);
  const [promoApplied, setPromoApplied] = useState(false);
  const [promoError, setPromoError] = useState('');

  const [branchConfig, setBranchConfig] = useState({
    restaurantName: 'Bongo Foodie',
    branchAddress: 'Kijitonyama Branch, Dar es Salaam',
    phone: '+255 712 345 678',
    mpesaTill: '556677',
    tigoTill: '223344',
    airtelTill: '889900',
    haloTill: '112233',
    nmbAccount: '9900112233',
    crdbAccount: '8877665544',
    logo: '🔥',
    promoCode: 'KARIBU2000',
    promoDiscount: 2000,
    promoActive: true
  });

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('bongo_branch_settings');
      if (stored) {
        try {
          const parsed = JSON.parse(stored);
          setBranchConfig(prev => ({ ...prev, ...parsed }));
        } catch(e) {}
      }
    }

    const fetchSettings = async () => {
      try {
        const { data, error } = await supabase
          .from('settings')
          .select('*')
          .eq('id', 'branch_settings')
          .single();
        if (data && !error) {
          setBranchConfig({
            restaurantName: data.restaurant_name || 'Bongo Foodie',
            branchAddress: data.branch_address || 'Kijitonyama Branch, Dar es Salaam',
            phone: data.phone || '+255 712 345 678',
            mpesaTill: data.mpesa_till || '556677',
            tigoTill: data.tigo_till || '223344',
            airtelTill: data.airtel_till || '889900',
            haloTill: data.halo_till || '112233',
            nmbAccount: data.nmb_account || '9900112233',
            crdbAccount: data.crdb_account || '8877665544',
            logo: data.logo || '🔥',
            promoCode: data.promo_code || 'KARIBU2000',
            promoDiscount: Number(data.promo_discount || 2000),
            promoActive: data.promo_active !== undefined ? data.promo_active : true
          });
        }
      } catch (err) {
        console.error('[Web Cart Settings Fetch Error]', err);
      }
    };
    fetchSettings();
  }, []);

  const handleCheckout = (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) return;
    
    const generatedId = `bf-${Math.floor(100000 + Math.random() * 900000)}`;
    setLastOrderId(generatedId);
    setLastOrderedItems([...items]);
    setLastOrderedTotal(totalPrice + 3000 - promoDiscount);
    
    const checkoutNotes = notes + (paymentMethod === 'lipanamba' ? ' (Paid via Lipa Namba)' : ' (Cash on Delivery)');

    // Write order row to database for admin live monitor sync
    supabase.from('orders').insert({
      id: generatedId,
      table_number: tableNumber || 'Takeaway / Delivery',
      items: JSON.stringify(items),
      status: 'pending',
      total_price: totalPrice + 3000 - promoDiscount,
      delivery_location: selectedAddress || 'Dar es Salaam',
      customer_name: 'Guest Customer',
      customer_email: phoneNumber || 'no-phone@email.com'
    }).then(({ error }) => {
      if (error) console.error('[Database order insertion error]', error);
    });

    setCheckedOut(true);
    clearCart();
  };

  const handleDownloadPDFReceipt = (orderId: string, itemsList: any[], totalCost: number, tableNum: string) => {
    const doc = new jsPDF();
    
    const rName = (branchConfig.restaurantName || 'BONGO FOODIE').toUpperCase();
    const bAddr = branchConfig.branchAddress || 'Kijitonyama, Dar es Salaam, Tanzania';
    const bPhone = branchConfig.phone || '+255 712 345 678';
    const bLogo = branchConfig.logo || '🔥';

    // Draw stylized header badge for logo
    doc.setFillColor(246, 130, 31);
    doc.rect(14, 15, 14, 14, 'F');
    doc.setFontSize(11);
    doc.setTextColor(255, 255, 255);
    doc.text(bLogo, 18, 24);

    doc.setFontSize(16);
    doc.setFont('Helvetica', 'bold');
    doc.setTextColor(246, 130, 31);
    doc.text(rName, 33, 21);

    doc.setFontSize(9);
    doc.setFont('Helvetica', 'normal');
    doc.setTextColor(100, 100, 100);
    doc.text(`Branch: ${bAddr}`, 33, 26);
    doc.text(`Contact: ${bPhone}`, 33, 31);

    // Separator line
    doc.setDrawColor(220, 220, 220);
    doc.setLineWidth(0.5);
    doc.line(14, 37, 196, 37);

    // Invoice details
    doc.setFontSize(10);
    doc.setFont('Helvetica', 'bold');
    doc.setTextColor(80, 80, 80);
    doc.text(`INVOICE / CUSTOMER RECEIPT`, 14, 44);
    
    doc.setFont('Helvetica', 'normal');
    doc.text(`Order ID: #${orderId}`, 14, 50);
    doc.text(`Seat / Table: #${tableNum || 'Takeaway'}`, 14, 56);
    doc.text(`Date: ${new Date().toLocaleDateString()}`, 14, 62);

    // Table Data
    const tableData = itemsList.map(item => [
      item.name,
      `${item.quantity}x`,
      `TSh ${item.price.toLocaleString()}`,
      `TSh ${(item.price * item.quantity).toLocaleString()}`
    ]);

    autoTable(doc, {
      startY: 68,
      head: [['Dish Name', 'Qty', 'Unit Price', 'Total']],
      body: tableData,
      theme: 'grid',
      headStyles: { fillColor: [246, 130, 31] }
    });

    const finalY = (doc as any).lastAutoTable.finalY + 12;

    // Draw total summary block
    doc.setFillColor(248, 249, 250);
    doc.rect(14, finalY - 4, 182, 16, 'F');
    doc.setFontSize(11);
    doc.setFont('Helvetica', 'bold');
    doc.setTextColor(0, 0, 0);
    doc.text(`GRAND TOTAL PAID: TSh ${totalCost.toLocaleString()}`, 18, finalY + 6);

    // Footer Investor details
    doc.setFontSize(8);
    doc.setFont('Helvetica', 'italic');
    doc.setTextColor(130, 130, 130);
    doc.text('Asanteni sana kwa kuteua huduma yetu! / Thank you for dining with us.', 14, finalY + 20);
    
    doc.setFont('Helvetica', 'normal');
    doc.text(`Investor Verification ID: BF-${orderId.slice(0, 6).toUpperCase()}`, 14, finalY + 25);

    doc.save(`Receipt-${orderId}.pdf`);
  };

  if (checkedOut) {
    return (
      <div className="max-w-xl mx-auto py-16 text-center space-y-6 bg-white border border-border rounded-3xl p-8 shadow-sm">
        <div className="size-20 bg-primary/10 rounded-full flex items-center justify-center mx-auto text-primary animate-pulse">
          <ShoppingBag className="size-10" />
        </div>
        <h2 className="font-heading text-3xl font-bold text-foreground-dark">Order Confirmed!</h2>
        <p className="text-muted-foreground font-medium max-w-sm mx-auto">
          Your Swahili meal request has been received by our kitchen. Your food will be served shortly.
        </p>
        {tableNumber && (
          <div className="inline-block px-4 py-2 bg-muted rounded-xl text-sm font-bold text-foreground-dark">
            Seat / Table: #{tableNumber}
          </div>
        )}
        <div className="pt-4 flex flex-col sm:flex-row items-center gap-3 justify-center">
          <button
            onClick={() => handleDownloadPDFReceipt(lastOrderId, lastOrderedItems, lastOrderedTotal, tableNumber)}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3 border border-border bg-card text-foreground-dark font-heading font-bold rounded-xl hover:bg-muted transition-colors cursor-pointer"
          >
            <Download className="size-4 text-primary" /> Download Receipt
          </button>
          <Link 
            href="/search" 
            onClick={() => setCheckedOut(false)}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors"
          >
            Order Something Else <ArrowRight className="size-4" />
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 py-6 pb-20">
      <div>
        <h1 className="font-heading text-3xl font-bold text-foreground-dark">Your Cart</h1>
        <p className="text-muted-foreground mt-1 font-medium">Review selection and specify delivery table coordinates.</p>
      </div>

      {items.length === 0 ? (
        <div className="text-center py-20 bg-white border border-border rounded-3xl space-y-4">
          <ShoppingBag className="size-16 text-muted-foreground/30 mx-auto stroke-[1.2px]" />
          <p className="text-muted-foreground font-semibold">Your cart is currently empty.</p>
          <Link 
            href="/search" 
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors"
          >
            Browse Food Menu
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          
          {/* Left Columns: Items List */}
          <div className="lg:col-span-2 space-y-4">
            {items.map((item) => {
              const imgUrl = resolveFoodImage(item.image_url);
              return (
                <div key={item.id} className="flex flex-row bg-white border border-border p-4 rounded-2xl items-center gap-4 shadow-sm">
                  {/* Item image */}
                  <div className="size-20 rounded-xl bg-card border border-border flex items-center justify-center shrink-0 overflow-hidden">
                    <Image 
                      src={imgUrl} 
                      alt={item.name} 
                      width={64} 
                      height={64} 
                      className="object-contain"
                    />
                  </div>

                  {/* Item details */}
                  <div className="flex-1 min-w-0 pr-6">
                    <h3 className="font-heading font-bold text-foreground-dark text-base truncate">{item.name}</h3>
                    <span className="font-heading font-extrabold text-primary text-sm mt-0.5 block">
                      TSh {item.price.toLocaleString()}
                    </span>

                    {/* Quantity selectors */}
                    <div className="flex items-center gap-3 mt-3">
                      <button 
                        onClick={() => decreaseQty(item.id)}
                        className="size-7 border border-border rounded-lg flex items-center justify-center bg-white hover:bg-muted text-foreground-dark"
                      >
                        <Minus className="size-3.5" />
                      </button>
                      <span className="text-sm font-extrabold text-foreground-dark">{item.quantity}</span>
                      <button 
                        onClick={() => increaseQty(item.id)}
                        className="size-7 border border-border rounded-lg flex items-center justify-center bg-white hover:bg-muted text-foreground-dark"
                      >
                        <Plus className="size-3.5" />
                      </button>
                    </div>
                  </div>

                  {/* Remove Action */}
                  <button 
                    onClick={() => removeItem(item.id)}
                    className="p-2 text-muted-foreground hover:text-destructive hover:bg-destructive/5 rounded-xl transition-all"
                  >
                    <Trash2 className="size-5" />
                  </button>
                </div>
              );
            })}
          </div>
          <div className="bg-amber-50/20 border-2 border-dashed border-amber-200/80 rounded-3xl p-6 shadow-sm space-y-6 relative overflow-hidden">
            <div className="absolute top-0 right-0 size-24 bg-primary/5 rounded-full -mr-10 -mt-10 blur-xl pointer-events-none" />
            
            {/* Receipt Header Style */}
            <div className="text-center space-y-1.5 pb-4 border-b border-border">
              <span className="text-3xl inline-block animate-bounce">{branchConfig.logo || '🔥'}</span>
              <h3 className="font-heading font-black text-lg text-foreground-dark tracking-wide uppercase">
                {branchConfig.restaurantName || 'Bongo Foodie'}
              </h3>
              <p className="text-[10px] text-muted-foreground font-semibold px-4">
                {branchConfig.branchAddress || 'Kijitonyama, Dar es Salaam'}
              </p>
              <p className="text-[10px] text-muted-foreground font-semibold">
                Tel: {branchConfig.phone || '+255 712 345 678'}
              </p>
            </div>

            {/* Receipt Items breakdown */}
            <div className="space-y-2 py-2 border-b-2 border-dashed border-border/80 text-xs font-semibold">
              <span className="text-[10px] uppercase text-muted-foreground tracking-wider font-extrabold block">Order Items:</span>
              <div className="space-y-1.5 max-h-[120px] overflow-y-auto pr-1 no-scrollbar">
                {items.map((item) => (
                  <div key={item.id} className="flex justify-between text-foreground-dark">
                    <span>{item.quantity}x {item.name}</span>
                    <span className="text-muted-foreground font-medium">TSh {(item.price * item.quantity).toLocaleString()}</span>
                  </div>
                ))}
              </div>
            </div>
            
            <div className="space-y-2.5 pb-4 border-b border-border">
              <div className="flex justify-between text-xs text-muted-foreground font-semibold">
                <span>Items Subtotal</span>
                <span className="text-foreground-dark font-bold">TSh {totalPrice.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-xs text-muted-foreground font-semibold">
                <span>Delivery Fee</span>
                <span className="text-foreground-dark font-bold">TSh 3,000</span>
              </div>
              <div className="flex justify-between text-xs text-muted-foreground font-semibold">
                <span>Discount Applied</span>
                <span className="text-accent-red font-bold">- TSh {promoDiscount.toLocaleString()}</span>
              </div>
              <div className="border-t border-border pt-2.5 flex justify-between items-center">
                <span className="text-sm font-bold text-foreground-dark">ESTIMATED TOTAL</span>
                <span className="font-heading font-black text-primary text-xl">
                  TSh {(totalPrice + 3000 - promoDiscount).toLocaleString()}
                </span>
              </div>
            </div>

            {/* Promo Code Coupon verification */}
            <div className="space-y-1.5 pb-2">
              <label className="text-[9px] font-extrabold uppercase tracking-wider text-muted-foreground block">Promo Code</label>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  value={promoCode}
                  onChange={(e) => {
                    setPromoCode(e.target.value);
                    setPromoError('');
                  }}
                  placeholder="e.g. KARIBU2000"
                  className="flex-1 bg-white border border-border rounded-xl px-3 py-2 text-xs font-semibold text-foreground-dark focus:outline-none uppercase"
                />
                <button 
                  type="button"
                  onClick={() => {
                    const code = promoCode.trim().toUpperCase();
                    const dbCode = (branchConfig.promoCode || 'KARIBU2000').toUpperCase();
                    const dbDiscount = Number(branchConfig.promoDiscount || 2000);
                    const dbActive = branchConfig.promoActive !== undefined ? branchConfig.promoActive : true;

                    if (code === dbCode && dbActive) {
                      setPromoDiscount(dbDiscount);
                      setPromoApplied(true);
                      setPromoError('');
                    } else if (!dbActive) {
                      setPromoDiscount(1000);
                      setPromoApplied(false);
                      setPromoError('This coupon has expired');
                    } else {
                      setPromoDiscount(1000);
                      setPromoApplied(false);
                      setPromoError('Invalid coupon code');
                    }
                  }}
                  className="bg-primary hover:bg-secondary text-white text-xs font-bold px-4 py-2 rounded-xl transition-all"
                >
                  Apply
                </button>
              </div>
              {promoApplied && (
                <span className="text-[10px] text-green-600 font-bold block">✓ Coupon {branchConfig.promoCode} applied successfully!</span>
              )}
              {promoError && (
                <span className="text-[10px] text-red-500 font-bold block">{promoError}</span>
              )}
            </div>

            {/* Checkout Form fields inside receipt */}
            <form onSubmit={handleCheckout} className="space-y-4">
              <div className="space-y-1.5">
                <LocationPicker onLocationSelected={(addr) => setSelectedAddress(addr)} />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-[9px] font-extrabold uppercase tracking-wider text-muted-foreground">Seat / Table No.</label>
                  <input 
                    type="text" 
                    value={tableNumber}
                    onChange={(e) => setTableNumber(e.target.value)}
                    placeholder="e.g. Table 5"
                    className="w-full bg-white border border-border rounded-xl px-3 py-2.5 text-xs font-semibold text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-[9px] font-extrabold uppercase tracking-wider text-muted-foreground">Mobile Contact</label>
                  <input 
                    type="tel" 
                    required
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    placeholder="e.g. +255..."
                    className="w-full bg-white border border-border rounded-xl px-3 py-2.5 text-xs font-semibold text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-[9px] font-extrabold uppercase tracking-wider text-muted-foreground">Payment Method</label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('cash')}
                    className={`py-2.5 rounded-xl border text-xs font-bold text-center transition-all cursor-pointer ${
                      paymentMethod === 'cash'
                        ? 'border-primary bg-primary/5 text-primary'
                        : 'border-border bg-white text-muted-foreground hover:bg-muted'
                    }`}
                  >
                    Cash on Delivery
                  </button>
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('lipanamba')}
                    className={`py-2.5 rounded-xl border text-xs font-bold text-center transition-all cursor-pointer ${
                      paymentMethod === 'lipanamba'
                        ? 'border-primary bg-primary/5 text-primary'
                        : 'border-border bg-white text-muted-foreground hover:bg-muted'
                    }`}
                  >
                    Lipa Namba (Mobile)
                  </button>
                </div>
              </div>

              {paymentMethod === 'lipanamba' && (
                <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl space-y-2.5 text-xs text-foreground-dark">
                  <p className="font-heading font-black text-primary text-center tracking-wider text-[11px]">ACTIVE LIPA NAMBA CHANNELS</p>
                  <div className="space-y-1.5 mt-2 font-semibold text-[11px]">
                    {branchConfig.mpesaTill && (
                      <div className="flex justify-between">
                        <span>Vodacom M-Pesa:</span>
                        <span className="font-extrabold text-foreground-dark">{branchConfig.mpesaTill} (Till)</span>
                      </div>
                    )}
                    {branchConfig.tigoTill && (
                      <div className="flex justify-between">
                        <span>Tigo Pesa:</span>
                        <span className="font-extrabold text-foreground-dark">{branchConfig.tigoTill} (Till)</span>
                      </div>
                    )}
                    {branchConfig.airtelTill && (
                      <div className="flex justify-between">
                        <span>Airtel Money:</span>
                        <span className="font-extrabold text-foreground-dark">{branchConfig.airtelTill} (Till)</span>
                      </div>
                    )}
                    {branchConfig.haloTill && (
                      <div className="flex justify-between">
                        <span>Halopesa:</span>
                        <span className="font-extrabold text-foreground-dark">{branchConfig.haloTill} (Till)</span>
                      </div>
                    )}
                    {branchConfig.nmbAccount && (
                      <div className="flex justify-between">
                        <span>NMB Transfer:</span>
                        <span className="font-extrabold text-foreground-dark">{branchConfig.nmbAccount}</span>
                      </div>
                    )}
                    {branchConfig.crdbAccount && (
                      <div className="flex justify-between">
                        <span>CRDB Transfer:</span>
                        <span className="font-extrabold text-foreground-dark">{branchConfig.crdbAccount}</span>
                      </div>
                    )}
                  </div>
                  <p className="text-[9px] text-muted-foreground text-center italic mt-2">Make your transfer, then note down the reference/transaction ID below.</p>
                </div>
              )}

              <div className="space-y-1.5">
                <label className="text-[9px] font-extrabold uppercase tracking-wider text-muted-foreground">Special Instructions / Transaction Ref</label>
                <textarea 
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="e.g. Spicy, extra hot sauce... Or Transaction Ref ID..."
                  rows={2}
                  className="w-full bg-white border border-border rounded-xl px-4 py-3 text-xs font-semibold text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all resize-none font-sans"
                />
              </div>

              <button 
                type="submit"
                className="w-full py-4 bg-primary text-white font-heading font-black rounded-xl hover:bg-secondary transition-all hover:scale-[1.01] active:scale-[0.99] shadow-lg shadow-primary/20 text-xs uppercase tracking-widest mt-2 cursor-pointer"
              >
                PAY & CONFIRM ORDER
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
