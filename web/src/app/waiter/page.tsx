'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { Order } from '@/types';
import { 
  Bell, 
  MapPin, 
  Check, 
  Loader2, 
  UtensilsCrossed, 
  TrendingUp, 
  CheckCircle2, 
  Clock,
  Volume2
} from 'lucide-react';

const MOCK_ACTIVE_ORDERS: Order[] = [
  {
    id: "bf-983104",
    table_number: "Table 4",
    items: [
      { id: "1", name: "Nyama Choma & Ugali", price: 12000, quantity: 2 },
      { id: "3", name: "Chipsi Mayai Street", price: 4500, quantity: 1 }
    ],
    status: "pending",
    total_price: 28500,
    delivery_location: "Kinondoni, Dar es Salaam",
    created_at: new Date().toISOString()
  },
  {
    id: "bf-748291",
    table_number: "Table 10",
    items: [
      { id: "2", name: "Samaki wa Kupaka", price: 15000, quantity: 1 }
    ],
    status: "in_transit",
    total_price: 15000,
    delivery_location: "Mikocheni, Dar es Salaam",
    created_at: new Date(Date.now() - 1800000).toISOString()
  }
];

export default function WaiterDashboard() {
  const [loading, setLoading] = useState(true);
  const [orders, setOrders] = useState<Order[]>([]);
  const [showcaseMode, setShowcaseMode] = useState(false);

  useEffect(() => {
    loadWaiterOrders();

    if (!showcaseMode) {
      // Subscribe to real-time changes in the 'orders' table!
      const channel = supabase
        .channel('waiter-order-changes')
        .on(
          'postgres_changes',
          { event: '*', schema: 'public', table: 'orders' },
          (payload) => {
            console.log('[Realtime Waiter Update received]', payload);
            loadWaiterOrders();
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(channel);
      };
    }
  }, [showcaseMode]);

  // Showcase order arrivals simulation
  useEffect(() => {
    if (showcaseMode) {
      const interval = setInterval(() => {
        const foodItems = [
          { name: "Chipsi Mayai Street", price: 4500 },
          { name: "Mishkaki ya Ng'ombe", price: 8000 },
          { name: "Pilau ya Kuku", price: 9500 },
          { name: "Burger ya Kuku", price: 11000 }
        ];
        const randomFood = foodItems[Math.floor(Math.random() * foodItems.length)];
        const randomTables = ["Table 3", "Table 7", "Table 12", "Takeaway"];
        const randomTable = randomTables[Math.floor(Math.random() * randomTables.length)];
        const id = `bf-${Math.floor(100000 + Math.random() * 900000)}`;

        // Decide whether to add a pending order or convert a pending order to ready
        setOrders(prev => {
          const hasPending = prev.some(o => o.status === 'pending');
          if (hasPending && Math.random() > 0.5) {
            // Transition one pending order to in_transit
            const updated = prev.map(o => {
              if (o.status === 'pending') {
                // Announce ready in Swahili
                announceSwahiliReady(o.table_number, o.id);
                return { ...o, status: 'in_transit' as const };
              }
              return o;
            });
            return updated;
          } else {
            // Insert new pending order
            const newOrder: Order = {
              id,
              table_number: randomTable,
              items: [{ id: "s", name: randomFood.name, price: randomFood.price, quantity: 1 }],
              status: "pending",
              total_price: randomFood.price,
              delivery_location: "Upanga, Dar es Salaam",
              created_at: new Date().toISOString()
            };
            return [newOrder, ...prev];
          }
        });
      }, 15000);

      return () => clearInterval(interval);
    }
  }, [showcaseMode]);

  const loadWaiterOrders = async () => {
    setLoading(true);
    try {
      if (showcaseMode) {
        setOrders(MOCK_ACTIVE_ORDERS);
        return;
      }

      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .in('status', ['pending', 'in_transit'])
        .order('created_at', { ascending: true });

      if (error) {
        console.warn('Database orders table error. Defaulting to showcase mockup list.');
        setOrders(MOCK_ACTIVE_ORDERS);
      } else if (!data || data.length === 0) {
        setOrders(MOCK_ACTIVE_ORDERS);
      } else {
        const parsed: Order[] = (data || []).map(order => ({
          id: order.id,
          table_number: order.table_number || 'Table 1',
          items: typeof order.items === 'string' ? JSON.parse(order.items) : (order.items || []),
          status: order.status,
          total_price: Number(order.total_price),
          delivery_location: order.delivery_location || 'Dar es Salaam',
          created_at: order.created_at,
        }));
        setOrders(parsed);
      }
    } catch (e) {
      console.warn('[Waiter load warning, using showcase]:', e);
      setOrders(MOCK_ACTIVE_ORDERS);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkDelivered = async (orderId: string) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({ status: 'delivered' })
        .eq('id', orderId);

      if (error) throw error;
      setOrders(prev => prev.filter(o => o.id !== orderId));
    } catch (e) {
      console.warn('Database error. Updating local list.');
      setOrders(prev => prev.filter(o => o.id !== orderId));
    }
  };

  const handleMarkInTransit = async (orderId: string) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({ status: 'in_transit' })
        .eq('id', orderId);

      if (error) throw error;
      loadWaiterOrders();
    } catch (e) {
      console.warn('Database error. Updating local list status.');
      setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: 'in_transit' } : o));
    }
  };

  const announceSwahiliReady = (tableNumber: string, orderId: string) => {
    if ('speechSynthesis' in window) {
      const displayId = orderId.slice(3, 7).split('').join(' ');
      const cleanTable = tableNumber.toLowerCase().includes('table') 
        ? tableNumber.replace(/table/gi, 'Meza ya') 
        : tableNumber;
      
      const msg = `Habari! Agizo namba ${displayId} la ${cleanTable} liko tayari sasa. Karibu uje kuchukua chakula chako cha Bongo Foodie. Asante!`;
      
      const utterance = new SpeechSynthesisUtterance(msg);
      utterance.lang = 'sw-TZ';
      utterance.rate = 0.85;
      utterance.pitch = 1.0;
      window.speechSynthesis.speak(utterance);
    } else {
      console.warn('Web SpeechSynthesis TTS is not supported in this client.');
    }
  };

  // Group orders by table number for waiter convenience
  const pendingOrders = orders.filter(o => o.status === 'pending');
  const readyOrders = orders.filter(o => o.status === 'in_transit');

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-40 gap-3">
        <Loader2 className="size-10 text-primary animate-spin" />
        <p className="text-xs font-bold uppercase tracking-widest text-primary animate-pulse">Synchronizing Dispatch feeds...</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 py-6 pb-20">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-border gap-3">
        <div className="flex items-center gap-3">
          <div className="size-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
            <Bell className="size-5 animate-bounce" />
          </div>
          <div>
            <h1 className="font-heading text-2xl font-bold text-foreground-dark">Waiter Dispatch Board</h1>
            <p className="text-xs text-muted-foreground font-medium">Real-time table food delivery updates. Powered by Supabase Realtime.</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowcaseMode(!showcaseMode)}
            className={`text-[9px] font-extrabold uppercase px-2 py-1.5 rounded-lg border transition-all cursor-pointer ${
              showcaseMode 
                ? 'bg-amber-500 text-white border-amber-600'
                : 'bg-white text-muted-foreground border-border hover:bg-muted'
            }`}
          >
            {showcaseMode ? '✨ Showcase Mode Active' : '✨ Toggle Showcase Mode'}
          </button>
          <span className="text-xs font-extrabold px-3 py-1.5 rounded-full bg-primary/10 text-primary uppercase tracking-wider shrink-0">
            Active Wards: {orders.length}
          </span>
        </div>
      </div>

      {/* Two Column Dispatch layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Column 1: Ready for Dispatch (Waiter needs to carry it!) */}
        <div className="space-y-4">
          <div className="flex items-center gap-2 p-3 bg-emerald-600/5 border border-emerald-600/10 rounded-2xl">
            <CheckCircle2 className="size-5 text-emerald-600" />
            <div>
              <h3 className="font-heading font-bold text-sm text-foreground-dark">Ready for Dispatch (Serve Now)</h3>
              <p className="text-[10px] text-muted-foreground font-semibold">Kitchen has finished cooking. Deliver to table immediately.</p>
            </div>
          </div>

          <div className="space-y-4">
            {readyOrders.length === 0 ? (
              <div className="text-center py-12 bg-white border border-border rounded-2xl text-muted-foreground text-xs font-semibold">
                No orders ready for dispatch yet.
              </div>
            ) : (
              readyOrders.map((order) => (
                <div key={order.id} className="bg-white border-2 border-emerald-600/30 rounded-2xl p-4 shadow-sm relative space-y-3">
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="font-heading font-extrabold text-foreground-dark text-base">
                        {order.table_number}
                      </h4>
                      <span className="text-[10px] text-muted-foreground font-medium block">
                        Order ID: #{order.id.slice(0, 6)}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => announceSwahiliReady(order.table_number, order.id)}
                        className="p-2 border border-border bg-white rounded-xl text-muted-foreground hover:text-primary transition-colors cursor-pointer"
                        title="Announce ready in Swahili (Voice)"
                      >
                        <Volume2 className="size-4" />
                      </button>
                      <button
                        onClick={() => handleMarkDelivered(order.id)}
                        className="inline-flex items-center gap-1 px-4 py-2 bg-emerald-600 text-white font-heading font-bold text-xs rounded-xl hover:bg-emerald-700 transition-colors shadow-md shadow-emerald-600/10 cursor-pointer"
                      >
                        <Check className="size-4" /> Delivered
                      </button>
                    </div>
                  </div>

                  {/* Items block */}
                  <div className="bg-emerald-600/5 p-3 rounded-xl border border-emerald-600/10">
                    <ul className="text-xs text-foreground-dark font-semibold space-y-1">
                      {order.items.map((item: any, i) => (
                        <li key={i} className="flex justify-between">
                          <span>{item.quantity}x {item.name}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Column 2: Kitchen Cooking (Preparing) */}
        <div className="space-y-4">
          <div className="flex items-center gap-2 p-3 bg-amber-600/5 border border-amber-600/10 rounded-2xl">
            <Clock className="size-5 text-amber-600 animate-spin" style={{ animationDuration: '3s' }} />
            <div>
              <h3 className="font-heading font-bold text-sm text-foreground-dark">Kitchen Cooking (Preparing)</h3>
              <p className="text-[10px] text-muted-foreground font-semibold">Chef is actively preparing. Watch for dispatch triggers.</p>
            </div>
          </div>

          <div className="space-y-4">
            {pendingOrders.length === 0 ? (
              <div className="text-center py-12 bg-white border border-border rounded-2xl text-muted-foreground text-xs font-semibold">
                Kitchen is currently idle. No pending tickets.
              </div>
            ) : (
              pendingOrders.map((order) => (
                <div key={order.id} className="bg-white border border-border rounded-2xl p-4 shadow-sm relative space-y-3">
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="font-heading font-extrabold text-foreground-dark text-base">
                        {order.table_number}
                      </h4>
                      <span className="text-[10px] text-muted-foreground font-medium block">
                        Order ID: #{order.id.slice(0, 6)}
                      </span>
                    </div>
                    <button
                      onClick={() => handleMarkInTransit(order.id)}
                      className="inline-flex items-center gap-1 px-3 py-1.5 bg-primary text-white font-heading font-bold text-xs rounded-xl hover:bg-secondary transition-colors cursor-pointer"
                    >
                      Ready for Serving
                    </button>
                  </div>

                  {/* Items list */}
                  <div className="bg-muted p-3 rounded-xl border border-border/40">
                    <ul className="text-xs text-foreground-dark font-medium space-y-1">
                      {order.items.map((item: any, i) => (
                        <li key={i} className="flex justify-between">
                          <span>{item.quantity}x {item.name}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

      </div>

    </div>
  );
}
