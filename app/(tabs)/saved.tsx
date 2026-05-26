import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Heart } from 'lucide-react-native';
import { useColorScheme } from '@/hooks/useColorScheme';
import { getFavorites } from '@/lib/favorites';

const dark = {
  bg: '#0B1018',
  card: '#141C2A',
  border: '#1F2D3D',
  text: '#FFFFFF',
  muted: '#8896AA',
  blue: '#3B82F6',
};

const light = {
  bg: '#F8FAFC',
  card: '#FFFFFF',
  border: '#E2E8F0',
  text: '#0F172A',
  muted: '#64748B',
  blue: '#2563EB',
};

export default function SavedScreen() {
  const colorScheme = useColorScheme();
  const C = colorScheme === 'dark' ? dark : light;
  const [count, setCount] = useState(0);

  useEffect(() => {
    getFavorites().then(ids => setCount(ids.length));
  }, []);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <View style={{ paddingHorizontal: 20, paddingTop: 12, paddingBottom: 16 }}>
        <Text style={{ fontSize: 26, fontWeight: '800', color: C.text, letterSpacing: -0.5 }}>
          Saved
        </Text>
        <Text style={{ fontSize: 14, color: C.muted, marginTop: 4 }}>
          {count} hotel{count !== 1 ? 's' : ''} saved
        </Text>
      </View>

      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 40 }}>
        <View style={{
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: colorScheme === 'dark' ? 'rgba(59,130,246,0.12)' : 'rgba(37,99,235,0.08)',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: 20,
        }}>
          <Heart size={32} color={C.blue} />
        </View>
        <Text style={{ fontSize: 18, fontWeight: '700', color: C.text, marginBottom: 8, textAlign: 'center' }}>
          {count > 0 ? 'Hotels you\'ve saved' : 'No saved hotels yet'}
        </Text>
        <Text style={{ fontSize: 14, color: C.muted, textAlign: 'center', lineHeight: 22 }}>
          {count > 0
            ? `You have ${count} hotel${count !== 1 ? 's' : ''} saved. Search for hotels and tap the heart icon to save your favorites here.`
            : 'Search for hotels and tap the heart icon to save your favorites here.'}
        </Text>
      </View>
    </SafeAreaView>
  );
}
