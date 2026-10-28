import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { MapPin, Search, Sparkles, TrendingUp } from 'lucide-react-native';
import { useEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, useColorScheme, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import HotelSearchModal from '../../components/search/HotelSearchModal';
import { useSettings } from '../../context/SettingsContext';
import { fetchPopularDestinations } from '../../lib/landing';

const dark = {
  bg: '#020617',
  card: '#0f172a',
  border: '#1e293b',
  text: '#ffffff',
  muted: '#64748b',
  sub: '#94a3b8',
  blue: '#3b82f6',
  chip: '#1e293b',
  chipBorder: '#334155',
};

const light = {
  bg: '#f8fafc',
  card: '#ffffff',
  border: '#e2e8f0',
  text: '#0f172a',
  muted: '#94a3b8',
  sub: '#64748b',
  blue: '#2563eb',
  chip: '#ffffff',
  chipBorder: '#e2e8f0',
};

type Category = 'All' | 'Beach' | 'City' | 'Nature' | 'Cultural';

type Destination = {
  id: string;
  city: string;
  country: string;
  category: Exclude<Category, 'All'>;
  imageUrl: string;
  tag?: string;
};

const CATEGORIES: Category[] = ['All', 'Beach', 'City', 'Nature', 'Cultural'];

// Curated discovery set. Tapping a card runs a hotel search for the city with
// sensible default dates — the same contract HotelSearchModal pushes to /search.
const DESTINATIONS: Destination[] = [
  { id: 'tokyo', city: 'Tokyo', country: 'Japan', category: 'City', tag: 'Trending', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=600&q=80' },
  { id: 'bali', city: 'Bali', country: 'Indonesia', category: 'Beach', tag: 'Top rated', imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=600&q=80' },
  { id: 'seoul', city: 'Seoul', country: 'South Korea', category: 'City', imageUrl: 'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=600&q=80' },
  { id: 'paris', city: 'Paris', country: 'France', category: 'Cultural', tag: 'Classic', imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=600&q=80' },
  { id: 'phuket', city: 'Phuket', country: 'Thailand', category: 'Beach', imageUrl: 'https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?auto=format&fit=crop&w=600&q=80' },
  { id: 'queenstown', city: 'Queenstown', country: 'New Zealand', category: 'Nature', tag: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1589802829985-817e51171b92?auto=format&fit=crop&w=600&q=80' },
  { id: 'rome', city: 'Rome', country: 'Italy', category: 'Cultural', imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=600&q=80' },
  { id: 'singapore', city: 'Singapore', country: 'Singapore', category: 'City', tag: 'Trending', imageUrl: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=600&q=80' },
  { id: 'interlaken', city: 'Interlaken', country: 'Switzerland', category: 'Nature', imageUrl: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?auto=format&fit=crop&w=600&q=80' },
  { id: 'maldives', city: 'Malé', country: 'Maldives', category: 'Beach', tag: 'Luxury', imageUrl: 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?auto=format&fit=crop&w=600&q=80' },
];

const BLURHASH = 'L15#hiof00of~qfQIUay00fQ-;fQ';

function formatDateLocal(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export default function ExploreScreen() {
  const colorScheme = useColorScheme();
  const C = colorScheme === 'dark' ? dark : light;
  const isDark = colorScheme === 'dark';
  const router = useRouter();
  const { currency } = useSettings();

  const [activeCategory, setActiveCategory] = useState<Category>('All');
  const [searchModalVisible, setSearchModalVisible] = useState(false);
  const [apiDestinations, setApiDestinations] = useState<Destination[] | null>(null);

  // Pull live popular destinations from the web landing feed. The API has no
  // category metadata, so live results render as one "Popular destinations" grid;
  // when the feed is empty/unreachable we fall back to the curated set below
  // (which keeps the category browsing experience).
  useEffect(() => {
    let cancelled = false;
    fetchPopularDestinations().then(items => {
      if (cancelled || items.length === 0) return;
      setApiDestinations(
        items
          .filter(d => d.city && d.imageUrl)
          .map(d => ({
            id: d.id,
            city: d.city,
            country: d.country,
            category: 'City' as const,
            imageUrl: d.imageUrl,
          }))
      );
    });
    return () => { cancelled = true; };
  }, []);

  const usingLiveData = !!apiDestinations && apiDestinations.length > 0;

  const destinations = useMemo(() => {
    if (usingLiveData) return apiDestinations!;
    return activeCategory === 'All'
      ? DESTINATIONS
      : DESTINATIONS.filter(d => d.category === activeCategory);
  }, [usingLiveData, apiDestinations, activeCategory]);

  const handleExplore = (dest: Destination) => {
    const checkIn = new Date();
    const checkOut = new Date();
    checkOut.setDate(checkOut.getDate() + 2);
    router.push({
      pathname: '/search',
      params: {
        destination: `${dest.city}, ${dest.country}`,
        countryCode: '',
        placeId: '',
        destinationCode: '',
        checkIn: formatDateLocal(checkIn),
        checkOut: formatDateLocal(checkOut),
        adults: '2',
        children: '0',
        childrenAges: '',
        rooms: '1',
        currency: currency.code,
      },
    });
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scroll}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.title, { color: C.text }]}>Explore</Text>
          <Text style={[styles.subtitle, { color: C.sub }]}>
            Find your next stay across the world
          </Text>
        </View>

        {/* Search pill */}
        <Pressable
          style={[styles.searchPill, { backgroundColor: C.card, borderColor: C.border }]}
          onPress={() => setSearchModalVisible(true)}
        >
          <Search size={18} color={C.blue} />
          <Text style={[styles.searchPillText, { color: C.muted }]}>
            Search city, hotel, or landmark
          </Text>
        </Pressable>

        {/* Category chips — only meaningful for the curated fallback set */}
        {!usingLiveData ? (
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.chipsRow}
          >
            {CATEGORIES.map(cat => {
              const active = cat === activeCategory;
              return (
                <Pressable
                  key={cat}
                  onPress={() => setActiveCategory(cat)}
                  style={[
                    styles.chip,
                    { backgroundColor: active ? C.blue : C.chip, borderColor: active ? C.blue : C.chipBorder },
                  ]}
                >
                  <Text style={[styles.chipText, { color: active ? '#fff' : C.sub }]}>{cat}</Text>
                </Pressable>
              );
            })}
          </ScrollView>
        ) : (
          <View style={{ height: 16 }} />
        )}

        {/* Section heading */}
        <View style={styles.sectionHeader}>
          <Sparkles size={16} color={C.blue} />
          <Text style={[styles.sectionTitle, { color: C.text }]}>
            {usingLiveData || activeCategory === 'All' ? 'Popular destinations' : `${activeCategory} escapes`}
          </Text>
        </View>

        {/* Destination grid */}
        <View style={styles.grid}>
          {destinations.map(dest => (
            <Pressable
              key={dest.id}
              style={[styles.cardWrap, { backgroundColor: C.card, borderColor: C.border }]}
              onPress={() => handleExplore(dest)}
            >
              <View style={styles.imageWrap}>
                <Image
                  source={{ uri: dest.imageUrl }}
                  style={styles.image}
                  contentFit="cover"
                  cachePolicy="memory-disk"
                  placeholder={{ blurhash: BLURHASH }}
                />
                {dest.tag ? (
                  <View style={styles.tagBadge}>
                    <TrendingUp size={10} color="#fff" />
                    <Text style={styles.tagText}>{dest.tag}</Text>
                  </View>
                ) : null}
              </View>
              <View style={styles.cardBody}>
                <Text style={[styles.cityName, { color: C.text }]} numberOfLines={1}>
                  {dest.city}
                </Text>
                <View style={styles.countryRow}>
                  <MapPin size={11} color={C.muted} />
                  <Text style={[styles.countryText, { color: C.muted }]} numberOfLines={1}>
                    {dest.country}
                  </Text>
                </View>
              </View>
            </Pressable>
          ))}
        </View>

        {destinations.length === 0 ? (
          <Text style={[styles.emptyText, { color: C.muted }]}>
            No destinations in this category yet.
          </Text>
        ) : null}
      </ScrollView>

      <HotelSearchModal
        visible={searchModalVisible}
        onClose={() => setSearchModalVisible(false)}
      />
    </SafeAreaView>
  );
}

const GAP = 12;

const styles = StyleSheet.create({
  scroll: {
    paddingBottom: 32,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 12,
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
  searchPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginHorizontal: 20,
    paddingHorizontal: 16,
    height: 48,
    borderRadius: 14,
    borderWidth: 1,
  },
  searchPillText: {
    fontSize: 14,
    fontWeight: '500',
  },
  chipsRow: {
    paddingHorizontal: 20,
    gap: 8,
    paddingVertical: 16,
  },
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '600',
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 20,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 20,
    gap: GAP,
  },
  cardWrap: {
    flexGrow: 1,
    flexBasis: '46%',
    borderRadius: 16,
    borderWidth: 1,
    overflow: 'hidden',
  },
  imageWrap: {
    position: 'relative',
    height: 120,
  },
  image: {
    width: '100%',
    height: '100%',
  },
  tagBadge: {
    position: 'absolute',
    top: 8,
    left: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: 'rgba(37, 99, 235, 0.9)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 20,
  },
  tagText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '700',
  },
  cardBody: {
    padding: 10,
    gap: 3,
  },
  cityName: {
    fontSize: 14,
    fontWeight: '700',
  },
  countryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  countryText: {
    fontSize: 12,
  },
  emptyText: {
    textAlign: 'center',
    fontSize: 14,
    marginTop: 40,
  },
});
