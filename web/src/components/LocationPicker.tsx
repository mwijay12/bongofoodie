'use client';

import React, { useState, useEffect } from 'react';
import { getTzRegions, getTzDistricts, getTzWards } from '@/lib/supabaseDb';
import { MapPin, Navigation, Loader2 } from 'lucide-react';

interface LocationPickerProps {
  onLocationSelected: (locationStr: string) => void;
}

const FALLBACK_REGIONS = [
  { region_code: 7, region_name: 'Dar es Salaam' }
];

const FALLBACK_DISTRICTS: Record<number, { district_code: number; district_name: string }[]> = {
  7: [
    { district_code: 71, district_name: 'Kinondoni' },
    { district_code: 72, district_name: 'Ilala' },
    { district_code: 73, district_name: 'Temeke' },
    { district_code: 74, district_name: 'Ubungo' },
    { district_code: 75, district_name: 'Kigamboni' },
  ]
};

const FALLBACK_WARDS: Record<number, { ward_code: number; ward_name: string }[]> = {
  71: [
    { ward_code: 711, ward_name: 'Mikocheni' },
    { ward_code: 712, ward_name: 'Msasani' },
    { ward_code: 713, ward_name: 'Mwananyamala' },
    { ward_code: 714, ward_name: 'Oysterbay' },
    { ward_code: 715, ward_name: 'Kijitonyama' },
  ],
  72: [
    { ward_code: 721, ward_name: 'Kariakoo' },
    { ward_code: 722, ward_name: 'Kisutu' },
    { ward_code: 723, ward_name: 'Kivukoni' },
    { ward_code: 724, ward_name: 'Upanga' },
    { ward_code: 725, ward_name: 'Gerezani' },
  ],
  73: [
    { ward_code: 731, ward_name: 'Mbagala' },
    { ward_code: 732, ward_name: 'Chang\'ombe' },
    { ward_code: 733, ward_name: 'Kurasini' },
    { ward_code: 734, ward_name: 'Temeke' },
  ],
  74: [
    { ward_code: 741, ward_name: 'Mlimani' },
    { ward_code: 742, ward_name: 'Ubungo' },
    { ward_code: 743, ward_name: 'Kimara' },
    { ward_code: 744, ward_name: 'Mbezi' },
    { ward_code: 745, ward_name: 'Kibamba' },
  ],
  75: [
    { ward_code: 751, ward_name: 'Kigamboni' },
    { ward_code: 752, ward_name: 'Kimbiji' },
    { ward_code: 753, ward_name: 'Mjimwema' },
  ]
};

export default function LocationPicker({ onLocationSelected }: LocationPickerProps) {
  const [gpsLoading, setGpsLoading] = useState(false);
  const [gpsAddress, setGpsAddress] = useState<string | null>(null);

  // Geo Dropdowns
  const [regions, setRegions] = useState<any[]>([]);
  const [districts, setDistricts] = useState<any[]>([]);
  const [wards, setWards] = useState<any[]>([]);

  const [selectedRegion, setSelectedRegion] = useState<number | null>(null);
  const [selectedDistrict, setSelectedDistrict] = useState<number | null>(null);
  const [selectedWard, setSelectedWard] = useState<number | null>(null);

  const [regionName, setRegionName] = useState('');
  const [districtName, setDistrictName] = useState('');
  const [wardName, setWardName] = useState('');

  useEffect(() => {
    loadRegions();
  }, []);

  async function loadRegions() {
    try {
      const data = await getTzRegions();
      if (data && data.length > 0) {
        setRegions(data);
        const darEsSalaam = data.find(r => r.region_name.toLowerCase().includes('dar'));
        if (darEsSalaam) {
          handleRegionChange(darEsSalaam.region_code, darEsSalaam.region_name);
        }
      } else {
        setRegions(FALLBACK_REGIONS);
        handleRegionChange(7, 'Dar es Salaam');
      }
    } catch (e) {
      console.error(e);
      setRegions(FALLBACK_REGIONS);
      handleRegionChange(7, 'Dar es Salaam');
    }
  }

  async function handleRegionChange(regionCode: number, name: string) {
    setSelectedRegion(regionCode);
    setRegionName(name);
    
    // Reset child states
    setSelectedDistrict(null);
    setDistrictName('');
    setWards([]);
    setSelectedWard(null);
    setWardName('');
    
    try {
      const data = await getTzDistricts(regionCode);
      if (data && data.length > 0) {
        setDistricts(data);
      } else {
        setDistricts(FALLBACK_DISTRICTS[regionCode] || []);
      }
    } catch (e) {
      console.error(e);
      setDistricts(FALLBACK_DISTRICTS[regionCode] || []);
    }
  }

  const handleDistrictChange = async (districtCode: number, name: string) => {
    setSelectedDistrict(districtCode);
    setDistrictName(name);
    
    // Reset child states
    setSelectedWard(null);
    setWardName('');
    
    try {
      const data = await getTzWards(districtCode);
      if (data && data.length > 0) {
        setWards(data);
      } else {
        setWards(FALLBACK_WARDS[districtCode] || []);
      }
    } catch (e) {
      console.error(e);
      setWards(FALLBACK_WARDS[districtCode] || []);
    }
  };

  const handleWardChange = (wardCode: number, name: string) => {
    setSelectedWard(wardCode);
    setWardName(name);
    
    const fullAddr = `${name}, ${districtName}, ${regionName}, Tanzania`;
    onLocationSelected(fullAddr);
  };

  const requestGpsLocation = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser.');
      return;
    }

    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords;
        try {
          // Use OpenStreetMap free Nominatim reverse geocoding API
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json&accept-language=sw,en`
          );
          const data = await response.json();
          if (data && data.display_name) {
            const formatted = data.display_name;
            setGpsAddress(formatted);
            onLocationSelected(formatted);
          } else {
            const coordsStr = `GPS Coords: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
            setGpsAddress(coordsStr);
            onLocationSelected(coordsStr);
          }
        } catch (error) {
          const coordsStr = `GPS Coords: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
          setGpsAddress(coordsStr);
          onLocationSelected(coordsStr);
        } finally {
          setGpsLoading(false);
        }
      },
      (error) => {
        console.error(error);
        alert('Could not retrieve GPS coordinates. Please check your browser permission settings.');
        setGpsLoading(false);
      },
      { enableHighAccuracy: true, timeout: 8000 }
    );
  };

  return (
    <div className="space-y-4 border border-border bg-card p-4 rounded-2xl">
      <div className="flex items-center justify-between">
        <span className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Select Delivery Location</span>
        
        {/* GPS Button */}
        <button
          type="button"
          onClick={requestGpsLocation}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-border bg-white text-xs font-bold text-foreground-dark hover:bg-muted transition-colors cursor-pointer"
        >
          {gpsLoading ? (
            <Loader2 className="size-3.5 text-primary animate-spin" />
          ) : (
            <Navigation className="size-3.5 text-primary fill-primary/10" />
          )}
          <span>Detect GPS</span>
        </button>
      </div>

      {gpsAddress && (
        <div className="flex items-start gap-2 p-2 bg-primary/5 border border-primary/10 rounded-xl">
          <MapPin className="size-4 text-primary shrink-0 mt-0.5" />
          <span className="text-xs text-foreground-dark font-medium leading-tight">{gpsAddress}</span>
        </div>
      )}

      {/* Dropdown Layout */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        {/* Region */}
        <div className="space-y-1">
          <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Region</label>
          <select
            value={selectedRegion || ''}
            onChange={(e) => {
              const val = Number(e.target.value);
              const region = regions.find(r => r.region_code === val);
              if (region) handleRegionChange(val, region.region_name);
            }}
            className="w-full text-xs font-medium text-foreground-dark bg-white border border-border rounded-xl px-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary transition-all"
          >
            <option value="" disabled>Choose Region</option>
            {regions.map((reg) => (
              <option key={reg.region_code} value={reg.region_code}>
                {reg.region_name}
              </option>
            ))}
          </select>
        </div>

        {/* District */}
        <div className="space-y-1">
          <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">District</label>
          <select
            disabled={!selectedRegion}
            value={selectedDistrict || ''}
            onChange={(e) => {
              const val = Number(e.target.value);
              const dist = districts.find(d => d.district_code === val);
              if (dist) handleDistrictChange(val, dist.district_name);
            }}
            className="w-full text-xs font-medium text-foreground-dark bg-white border border-border rounded-xl px-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary transition-all disabled:opacity-50 disabled:bg-muted"
          >
            <option value="">{selectedRegion ? 'Choose District' : 'Select Region First'}</option>
            {districts.map((dist) => (
              <option key={dist.district_code} value={dist.district_code}>
                {dist.district_name}
              </option>
            ))}
          </select>
        </div>

        {/* Ward */}
        <div className="space-y-1">
          <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Ward</label>
          <select
            disabled={!selectedDistrict}
            value={selectedWard || ''}
            onChange={(e) => {
              const val = Number(e.target.value);
              const ward = wards.find(w => w.ward_code === val);
              if (ward) handleWardChange(val, ward.ward_name);
            }}
            className="w-full text-xs font-medium text-foreground-dark bg-white border border-border rounded-xl px-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary transition-all disabled:opacity-50 disabled:bg-muted"
          >
            <option value="">{selectedDistrict ? 'Choose Ward' : 'Select District First'}</option>
            {wards.map((ward) => (
              <option key={ward.ward_code} value={ward.ward_code}>
                {ward.ward_name}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
}
