import { create } from 'zustand';
import { User } from "@/type";
import { supabase } from "@/lib/supabase";

type AuthState = {
    isAuthenticated: boolean;
    user: User | null;
    isLoading: boolean;
    phoneNumber: string | null;

    setIsAuthenticated: (value: boolean) => void;
    setUser: (user: User | null) => void;
    setLoading: (loading: boolean) => void;
    setPhoneNumber: (phone: string | null) => void;

    fetchAuthenticatedUser: () => Promise<void>;
}

const useAuthStore = create<AuthState>((set) => ({
    isAuthenticated: false,
    user: null,
    isLoading: true,
    phoneNumber: null,

    setIsAuthenticated: (value) => set({ isAuthenticated: value }),
    setUser: (user) => set({ user }),
    setLoading: (value) => set({ isLoading: value }),
    setPhoneNumber: (phone) => set({ phoneNumber: phone }),

    fetchAuthenticatedUser: async () => {
        set({ isLoading: true });

        try {
            const { data: { session } } = await supabase.auth.getSession();
            const user = session?.user;

            if (user) {
                set({
                    isAuthenticated: true,
                    user: {
                        $id: user.id,
                        name: user.user_metadata?.full_name || user.email || 'Bongo Foodie User',
                        email: user.email || '',
                        avatar_url: user.user_metadata?.avatar_url || ''
                    } as User
                });
            } else {
                set({ isAuthenticated: false, user: null });
            }
        } catch (e) {
            console.log('fetchAuthenticatedUser error', e);
            set({ isAuthenticated: false, user: null })
        } finally {
            set({ isLoading: false });
        }
    }
}))

export default useAuthStore;
