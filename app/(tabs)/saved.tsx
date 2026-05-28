import { useRouter } from 'expo-router';
import { Heart, MapPin, Star } from 'lucide-react-native';
import React, { useCallback, useState } from 'react';
import { FlatList, Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useColorScheme } from '@/hooks/useColorScheme';
import { getSavedHotels, toggleFavorite } from '@/lib/favorites';
import { useFocusEffect } from 'expo-router';
import { useSettings } from '@/context/SettingsContext';
import { convertCurrency } from '@/lib/currency';

const dark = {
  bg: '#0B1018',
  card: '#141C2A',
  border: '#1F2D3D',
  text: '#FFFFFF',
  muted: '#8896AA',
  blue: '#3B82F6',
  sub: '#64748b',
};

const light = {
  bg: '#F8FAFC',
  card: '#FFFFFF',
  border: '#E2E8F0',
  text: '#0F172A',
  muted: '#64748B',
  blue: '#2563EB',
  sub: '#94a3b8',
};

const FALLBACK_IMG = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=300&q=80';

export default function SavedScreen() {
  const colorScheme = useColorScheme();
  const C = colorScheme === 'dark' ? dark : light;
  const router = useRouter();
  const { currency } = useSettings();
  const [hotels, setHotels] = useState<any[]>([]);

  useFocusEffect(
    useCallback(() => {
      getSavedHotels().then(setHotels);
    }, [])
  );

  const handleUnsave = async (hotelId: string) => {
    await toggleFavorite(hotelId);
    setHotels(prev => prev.filter(h => h.hotelId !== hotelId));
  };

  const handleNavigate = (hotel: any) => {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    const fmt = (d: Date) => d.toISOString().split('T')[0];
    router.push({
      pathname: '/(tabs)/hotel/[id]',
      params: {
        id: hotel.hotelId,
        checkIn: fmt(today),
        checkOut: fmt(tomorrow),
        adults: '2',
        rooms: '1',
        currency: currency.code,
      },
    });
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: C.text }]}>Saved</Text>
        <Text style={[styles.subtitle, { color: C.muted }]}>
          {hotels.length} hotel{hotels.length !== 1 ? 's' : ''} saved
        </Text>
      </View>

      {hotels.length === 0 ? (
        <View style={styles.empty}>
          <View style={[styles.emptyIcon, { backgroundColor: colorScheme === 'dark' ? 'rgba(59,130,246,0.12)' : 'rgba(37,99,235,0.08)' }]}>
            <Heart size={32} color={C.blue} />
          </View>
          <Text style={[styles.emptyTitle, { color: C.text }]}>No saved hotels yet</Text>
          <Text style={[styles.emptyBody, { color: C.muted }]}>
            Search for hotels and tap the heart icon to save your favorites here.
          </Text>
        </View>
      ) : (
        <FlatList
          data={hotels}
          keyExtractor={(item) => item.hotelId}
          contentContainerStyle={styles.list}
          showsVerticalScrollIndicator={false}
          renderItem={({ item: hotel }) => {
            const score = hotel.reviewRating || hotel.rating || 0;
            const ratingLabel = score >= 9 ? 'Excellent' : score >= 8 ? 'Very Good' : score >= 7 ? 'Good' : score >= 6 ? 'Okay' : 'Fair';
            return (
              <Pressable
                style={[styles.card, { backgroundColor: C.card, borderColor: C.border }]}
                onPress={() => handleNavigate(hotel)}
              >
                <View style={styles.imageCol}>
                  <Image
                    source={{ uri: hotel.thumbnailUrl || FALLBACK_IMG }}
                    style={styles.image}
                    resizeMode="cover"
                  />
                  {hotel.refundable && (
                    <View style={styles.freeBadge}>
                      <Text style={styles.freeBadgeText}>Free cancel</Text>
                    </View>
                  )}
                </View>

                <View style={styles.details}>
                  <Text style={[styles.hotelName, { color: C.text }]} numberOfLines={2}>
                    {hotel.name}
                  </Text>

                  {hotel.address ? (
                    <View style={styles.locationRow}>
                      <MapPin size={11} color={C.sub} />
                      <Text style={[styles.locationText, { color: C.sub }]} numberOfLines={1}>
                        {hotel.address}
                      </Text>
                    </View>
                  ) : null}

                  {score > 0 && (
                    <View style={styles.ratingRow}>
                      <View style={styles.ratingBadge}>
                        <Star size={9} color="#fff" fill="#fff" />
                        <Text style={styles.ratingScore}>{score.toFixed(1)}</Text>
                        <Text style={styles.ratingLabel}>{ratingLabel}</Text>
                      </View>
                    </View>
                  )}

                  <View style={styles.footer}>
                    <View>
                      <Text style={[styles.price, { color: C.blue }]}>
                        {(() => {
                          const raw = hotel.displayPrice;
                          if (!raw || raw === '???') return '—';
                          const num = Number(raw);
                          if (isNaN(num)) return `${currency.symbol}${raw}`;
                          const from = hotel.priceCurrency || 'KRW';
                          return `${currency.symbol}${Math.round(convertCurrency(num, from, currency.code)).toLocaleString()}`;
                        })()}
                      </Text>
                      <Text style={[styles.perNight, { color: C.sub }]}>per night</Text>
                    </View>
                    <View style={[styles.viewBtn, { backgroundColor: C.blue }]}>
                      <Text style={styles.viewBtnText}>View</Text>
                    </View>
                  </View>
                </View>

                <Pressable style={styles.heartBtn} onPress={() => handleUnsave(hotel.hotelId)} hitSlop={8}>
                  <Heart size={14} color="#ef4444" fill="#ef4444" />
                </Pressable>
              </Pressable>
            );
          }}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 16,
  },
  title: {
    fontSize: 26,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 14,
    marginTop: 4,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
  },
  emptyIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyBody: {
    fontSize: 14,
    textAlign: 'center',
    lineHeight: 22,
  },
  list: {
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  card: {
    flexDirection: 'row',
    borderRadius: 16,
    borderWidth: 1,
    overflow: 'hidden',
    marginBottom: 12,
  },
  imageCol: {
    width: 130,
    position: 'relative',
  },
  image: {
    width: 130,
    height: 140,
  },
  freeBadge: {
    position: 'absolute',
    bottom: 8,
    left: 8,
    backgroundColor: 'rgba(34,197,94,0.9)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  freeBadgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '700',
  },
  details: {
    flex: 1,
    padding: 12,
    paddingRight: 36,
    justifyContent: 'space-between',
  },
  hotelName: {
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 4,
    lineHeight: 19,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginBottom: 6,
  },
  locationText: {
    fontSize: 11,
    flex: 1,
  },
  ratingRow: {
    marginBottom: 8,
  },
  ratingBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    alignSelf: 'flex-start',
    paddingHorizontal: 5,
    paddingVertical: 2,
    borderRadius: 5,
    backgroundColor: '#2563eb',
  },
  ratingScore: {
    fontSize: 11,
    fontWeight: '800',
    color: '#fff',
  },
  ratingLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.9)',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
  },
  price: {
    fontSize: 15,
    fontWeight: '700',
  },
  perNight: {
    fontSize: 10,
  },
  viewBtn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 10,
  },
  viewBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#fff',
  },
  heartBtn: {
    position: 'absolute',
    top: 10,
    right: 10,
    zIndex: 20,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255,255,255,0.9)',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
