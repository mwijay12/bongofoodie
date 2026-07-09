import { create } from 'zustand';

type LocationState = {
    deliveryLocation: string;
    setDeliveryLocation: (location: string) => void;
}

const useLocationStore = create<LocationState>((set) => ({
    deliveryLocation: "Dar es Salaam, TZ",
    setDeliveryLocation: (location) => set({ deliveryLocation: location }),
}));

export default useLocationStore;
