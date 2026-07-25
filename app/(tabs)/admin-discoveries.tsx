import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, Alert, ScrollView, Modal, TextInput, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import { getDailyDiscoveries, createDailyDiscovery, updateDailyDiscovery, deleteDailyDiscovery } from '@/lib/supabaseDb';
import useAuthStore from '@/store/auth.store';
import cn from 'clsx';

const AdminDiscoveries = () => {
  const { user } = useAuthStore();
  const [discoveries, setDiscoveries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);

  // Check if user is admin
  const isAdmin = user?.email === 'defoodordering@gmail.com';

  useEffect(() => {
    if (!isAdmin) {
      router.back();
      return;
    }
    loadDiscoveries();
  }, []);

  const loadDiscoveries = async () => {
    setLoading(true);
    const data = await getDailyDiscoveries();
    setDiscoveries(data);
    setLoading(false);
  };

  const openCreate = () => {
    setEditingId(null);
    setTitle('');
    setDescription('');
    setShowModal(true);
  };

  const openEdit = (d: any) => {
    setEditingId(d.id);
    setTitle(d.title);
    setDescription(d.description);
    setShowModal(true);
  };

  const handleSave = async () => {
    if (!title.trim() || !description.trim()) {
      Alert.alert('Validation Error', 'Both title and description are required.');
      return;
    }
    setSaving(true);
    try {
      if (editingId) {
        await updateDailyDiscovery(editingId, title.trim(), description.trim());
      } else {
        await createDailyDiscovery(title.trim(), description.trim());
      }
      setShowModal(false);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      await loadDiscoveries();
    } catch (e: any) {
      Alert.alert('Error', e.message || 'Failed to save discovery.');
    }
    setSaving(false);
  };

  const handleDelete = (id: string) => {
    Alert.alert(
      'Confirm Delete',
      'Are you sure you want to delete this discovery? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteDailyDiscovery(id);
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
              await loadDiscoveries();
            } catch (e: any) {
              Alert.alert('Error', e.message || 'Failed to delete.');
            }
          }
        }
      ]
    );
  };

  if (!isAdmin) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
        <View className="flex-1 items-center justify-center p-5">
          <Ionicons name="shield-checkmark-outline" size={48} color="#EF4444" />
          <Text className="h3-bold text-gourmet-charcoal mt-4 text-center">Admin access required</Text>
          <Text className="paragraph-medium text-gray-200 mt-2 text-center">You must be logged in as an admin to manage daily discoveries.</Text>
          <TouchableOpacity 
            onPress={() => router.back()}
            className="mt-6 bg-gourmet-forest px-6 py-3 rounded-xl"
          >
            <Text className="text-white font-bold">Go Back</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#FBFBFA' }}>
      {/* Header */}
      <View className="flex-row justify-between items-center px-5 pt-3 pb-3 bg-[#FBFBFA] border-b border-gourmet-border/30">
        <View className="flex-row items-center gap-3">
          <TouchableOpacity onPress={() => router.back()} className="p-1">
            <Ionicons name="arrow-back" size={24} color="#181C2E" />
          </TouchableOpacity>
          <Text className="h2-bold">Manage Discoveries</Text>
        </View>
        <TouchableOpacity 
          onPress={openCreate}
          className="bg-gourmet-forest px-3 py-2 rounded-lg flex-row items-center gap-1"
        >
          <Ionicons name="add" size={18} color="#FFF" />
          <Text className="text-white text-xs font-bold">Add New</Text>
        </TouchableOpacity>
      </View>

      <ScrollView 
        contentContainerClassName="pb-36 px-5 pt-4 max-w-2xl mx-auto w-full"
        contentContainerStyle={{ paddingBottom: 150 }}
        showsVerticalScrollIndicator={false}
      >
        <View className="mb-4">
          <Text className="text-xs text-gray-200">
            Total: {discoveries.length} discoveries | These appear on the home page "Daily Discovery" section
          </Text>
        </View>

        {loading ? (
          <View className="py-20 items-center">
            <ActivityIndicator size="large" color="#F6821F" />
          </View>
        ) : discoveries.length === 0 ? (
          <View className="py-20 items-center">
            <Ionicons name="bulb-outline" size={48} color="#C4C4C4" />
            <Text className="paragraph-bold text-gray-200 mt-4">No discoveries yet</Text>
            <Text className="text-xs text-gray-200 mt-2 text-center">Tap "Add New" to create your first daily discovery!</Text>
          </View>
        ) : (
          <View className="gap-3">
            {discoveries.map((d) => (
              <View key={d.id} className="bg-white border border-gourmet-border rounded-xl p-4">
                <View className="flex-row justify-between items-start mb-2">
                  <View className="flex-1 mr-3">
                    <Text className="paragraph-bold text-gourmet-charcoal">{d.title}</Text>
                    <Text className="text-xs text-gray-200 mt-1 leading-relaxed" numberOfLines={2}>
                      {d.description}
                    </Text>
                  </View>
                  <View className="flex-row gap-1">
                    <TouchableOpacity 
                      onPress={() => openEdit(d)}
                      className="bg-gourmet-forest/10 p-2 rounded-lg"
                    >
                      <Ionicons name="create-outline" size={16} color="#1B5E20" />
                    </TouchableOpacity>
                    <TouchableOpacity 
                      onPress={() => handleDelete(d.id)}
                      className="bg-red-50 p-2 rounded-lg"
                    >
                      <Ionicons name="trash-outline" size={16} color="#EF4444" />
                    </TouchableOpacity>
                  </View>
                </View>
                <Text className="text-[9px] text-gray-200">
                  Created: {new Date(d.created_at).toLocaleDateString()}
                </Text>
              </View>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Create/Edit Modal */}
      <Modal
        visible={showModal}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowModal(false)}
      >
        <View className="flex-1 justify-end bg-gourmet-charcoal/50">
          <View className="bg-white rounded-t-3xl max-h-[80%] p-6">
            <View className="flex-row justify-between items-center mb-6">
              <Text className="h2-bold text-gourmet-charcoal">
                {editingId ? 'Edit Discovery' : 'New Discovery'}
              </Text>
              <TouchableOpacity 
                onPress={() => setShowModal(false)}
                className="size-8 rounded-full bg-gourmet-bone items-center justify-center"
              >
                <Ionicons name="close" size={20} color="#F6821F" />
              </TouchableOpacity>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              <View className="mb-6">
                <Text className="paragraph-bold text-gourmet-charcoal mb-2">Title</Text>
                <TextInput
                  value={title}
                  onChangeText={setTitle}
                  placeholder="e.g. Zanzibar Spice Capital 🌴"
                  placeholderTextColor="#C4C4C4"
                  className="border border-gourmet-border rounded-xl p-4 paragraph-medium text-gourmet-charcoal"
                />
              </View>

              <View className="mb-6">
                <Text className="paragraph-bold text-gourmet-charcoal mb-2">Description</Text>
                <TextInput
                  value={description}
                  onChangeText={setDescription}
                  placeholder="Write a short, engaging culinary fact..."
                  placeholderTextColor="#C4C4C4"
                  multiline
                  numberOfLines={5}
                  textAlignVertical="top"
                  className="border border-gourmet-border rounded-xl p-4 paragraph-medium text-gourmet-charcoal min-h-[120px]"
                />
              </View>

              <TouchableOpacity
                onPress={handleSave}
                disabled={saving}
                className={cn(
                  "py-4 rounded-xl items-center",
                  saving ? "bg-gourmet-forest/60" : "bg-gourmet-forest"
                )}
              >
                {saving ? (
                  <ActivityIndicator size="small" color="#FFF" />
                ) : (
                  <Text className="text-white font-quicksand-bold text-base">
                    {editingId ? 'Update Discovery' : 'Create Discovery'}
                  </Text>
                )}
              </TouchableOpacity>
            </ScrollView>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
};

export default AdminDiscoveries;