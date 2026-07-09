import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, Alert, ScrollView } from 'react-native';
import * as Location from 'expo-location';
import { getTzRegions, getTzDistricts, getTzWards } from '@/lib/supabaseDb';

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
    { ward_code: 711, ward_name: 'Mikochem' },
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
  const [gpsLocation, setGpsLocation] = useState<string | null>(null);

  // DB Dropdowns
  const [regions, setRegions] = useState<any[]>([]);
  const [districts, setDistricts] = useState<any[]>([]);
  const [wards, setWards] = useState<any[]>([]);

  const [selectedRegion, setSelectedRegion] = useState<number | null>(null);
  const [selectedDistrict, setSelectedDistrict] = useState<number | null>(null);
  const [selectedWard, setSelectedWard] = useState<number | null>(null);

  const [regionName, setRegionName] = useState('');
  const [districtName, setDistrictName] = useState('');
  const [wardName, setWardName] = useState('');

  // Dropdown UI visibility states
  const [showRegions, setShowRegions] = useState(false);
  const [showDistricts, setShowDistricts] = useState(false);
  const [showWards, setShowWards] = useState(false);

  useEffect(() => {
    loadRegions();
  }, []);

  const loadRegions = async () => {
    try {
      const data = await getTzRegions();
      if (data && data.length > 0) {
        setRegions(data);
      } else {
        setRegions(FALLBACK_REGIONS);
      }
    } catch (e) {
      console.error(e);
      setRegions(FALLBACK_REGIONS);
    }
  };

  const handleRegionSelect = async (regionCode: number, name: string) => {
    setSelectedRegion(regionCode);
    setRegionName(name);
    setShowRegions(false);
    
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
  };

  const handleDistrictSelect = async (districtCode: number, name: string) => {
    setSelectedDistrict(districtCode);
    setDistrictName(name);
    setShowDistricts(false);
    
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

  const handleWardSelect = (wardCode: number, name: string) => {
    setSelectedWard(wardCode);
    setWardName(name);
    setShowWards(false);

    const fullAddr = `${name}, ${districtName}, ${regionName}, Tanzania`;
    onLocationSelected(fullAddr);
  };

  const requestGpsLocation = async () => {
    setGpsLoading(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Denied', 'GPS location permission is required for finding your current address.');
        setGpsLoading(false);
        return;
      }

      const location = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.Balanced,
      });

      const { latitude, longitude } = location.coords;
      
      // Reverse geocode to get name
      const geocode = await Location.reverseGeocodeAsync({ latitude, longitude });
      if (geocode.length > 0) {
        const address = geocode[0];
        const formatted = `${address.street || ''} ${address.name || ''}, ${address.district || address.city || ''}, ${address.region || ''}`.trim().replace(/^,\s*/, '');
        const finalAddr = formatted || `Lat: ${latitude.toFixed(4)}, Lon: ${longitude.toFixed(4)}`;
        setGpsLocation(finalAddr);
        onLocationSelected(finalAddr);
      } else {
        const coordsStr = `GPS Coords: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
        setGpsLocation(coordsStr);
        onLocationSelected(coordsStr);
      }
    } catch (e: any) {
      Alert.alert('GPS Error', e.message || 'Could not fetch GPS coordinates.');
    } finally {
      setGpsLoading(false);
    }
  };

  return (
    <View className="bg-white border border-gourmet-border p-5 rounded-xl mt-4">
      <Text className="base-bold text-gourmet-charcoal mb-3">Delivery Address</Text>

      {/* GPS Button */}
      <TouchableOpacity
        onPress={requestGpsLocation}
        disabled={gpsLoading}
        className="w-full bg-gourmet-forest py-3 rounded-lg flex flex-row items-center justify-center gap-2 mb-4"
      >
        {gpsLoading ? (
          <ActivityIndicator color="#FFFFFF" size="small" />
        ) : (
          <Text className="paragraph-bold text-white">📍 Use Current GPS Location</Text>
        )}
      </TouchableOpacity>

      {gpsLocation && (
        <View className="bg-gourmet-forest/5 p-3 rounded-lg border border-gourmet-forest/10 mb-4">
          <Text className="small-semibold text-gourmet-forest">Detected Current Location:</Text>
          <Text className="paragraph-medium text-gourmet-charcoal mt-1">{gpsLocation}</Text>
        </View>
      )}

      <Text className="small-bold text-gray-200 text-center mb-3">—— OR SELECT MANUALLY ——</Text>

      {/* Region Selector */}
      <View className="mb-3 relative z-30">
        <Text className="small-bold text-gourmet-charcoal mb-1">Region</Text>
        <TouchableOpacity
          onPress={() => setShowRegions(!showRegions)}
          className="border border-gourmet-border p-3 rounded-lg flex-row justify-between items-center bg-white"
        >
          <Text className="paragraph-medium text-gourmet-charcoal">
            {regionName || 'Choose Region...'}
          </Text>
          <Text className="small-bold text-gourmet-forest">▼</Text>
        </TouchableOpacity>
        
        {showRegions && (
          <ScrollView style={{ maxHeight: 160 }} nestedScrollEnabled={true} className="absolute top-[65px] left-0 right-0 bg-white border border-gourmet-border rounded-lg z-50 elevation-5 shadow-sm">
            {regions.map((r) => (
              <TouchableOpacity
                key={r.region_code}
                onPress={() => handleRegionSelect(r.region_code, r.region_name)}
                className="p-3 border-b border-gourmet-border"
              >
                <Text className="paragraph-medium text-gourmet-charcoal">{r.region_name}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        )}
      </View>

      {/* District Selector */}
      {selectedRegion !== null && (
        <View className="mb-3 relative z-20">
          <Text className="small-bold text-gourmet-charcoal mb-1">District</Text>
          <TouchableOpacity
            onPress={() => setShowDistricts(!showDistricts)}
            className="border border-gourmet-border p-3 rounded-lg flex-row justify-between items-center bg-white"
          >
            <Text className="paragraph-medium text-gourmet-charcoal">
              {districtName || 'Choose District...'}
            </Text>
            <Text className="small-bold text-gourmet-forest">▼</Text>
          </TouchableOpacity>
          
          {showDistricts && (
            <ScrollView style={{ maxHeight: 160 }} nestedScrollEnabled={true} className="absolute top-[65px] left-0 right-0 bg-white border border-gourmet-border rounded-lg z-50 elevation-5 shadow-sm">
              {districts.map((d) => (
                <TouchableOpacity
                  key={d.district_code}
                  onPress={() => handleDistrictSelect(d.district_code, d.district_name)}
                  className="p-3 border-b border-gourmet-border"
                >
                  <Text className="paragraph-medium text-gourmet-charcoal">{d.district_name}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          )}
        </View>
      )}

      {/* Ward Selector */}
      {selectedDistrict !== null && (
        <View className="mb-1 relative z-10">
          <Text className="small-bold text-gourmet-charcoal mb-1">Ward (Kata)</Text>
          <TouchableOpacity
            onPress={() => setShowWards(!showWards)}
            className="border border-gourmet-border p-3 rounded-lg flex-row justify-between items-center bg-white"
          >
            <Text className="paragraph-medium text-gourmet-charcoal">
              {wardName || 'Choose Ward...'}
            </Text>
            <Text className="small-bold text-gourmet-forest">▼</Text>
          </TouchableOpacity>
          
          {showWards && (
            <ScrollView style={{ maxHeight: 160 }} nestedScrollEnabled={true} className="absolute top-[65px] left-0 right-0 bg-white border border-gourmet-border rounded-lg z-50 elevation-5 shadow-sm">
              {wards.map((w) => (
                <TouchableOpacity
                  key={w.ward_code}
                  onPress={() => handleWardSelect(w.ward_code, w.ward_name)}
                  className="p-3 border-b border-gourmet-border"
                >
                  <Text className="paragraph-medium text-gourmet-charcoal">{w.ward_name}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          )}
        </View>
      )}
    </View>
  );
}
