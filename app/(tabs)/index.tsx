import React, { useCallback, useRef, useState } from 'react';
import { ScrollView, View, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useColorScheme } from 'nativewind';
import { WeekendDeal } from '../../lib/landing';
import Hero from '../../components/landing/Hero';
import YourRecentSearches from '../../components/landing/sections/YourRecentSearches';
import TrendingNearYou from '../../components/landing/sections/TrendingNearYou';
import UniqueStays from '../../components/landing/sections/UniqueStays';
import DealsSection from '../../components/landing/sections/DealsSection';
import ExploreVacationPackages from '../../components/landing/sections/ExploreVacationPackages';
import PriceAlertBanner from '../../components/landing/sections/PriceAlertBanner';

export default function LandingScreen() {
    const { colorScheme } = useColorScheme();
    const isDark = colorScheme === 'dark';

    const scrollRef = useRef<ScrollView>(null);
    const [searchDestination, setSearchDestination] = useState<string | null>(null);

    // Tapping a trending card fills the hero search bar with that city and scrolls
    // back up to it, so the user only has to add dates before searching.
    const handleTrendingSelect = useCallback((deal: WeekendDeal) => {
        setSearchDestination(deal.location || deal.name);
        scrollRef.current?.scrollTo({ y: 0, animated: true });
    }, []);

    return (
        <SafeAreaView className="flex-1 bg-slate-50 dark:bg-slate-950">
            <StatusBar barStyle={isDark ? 'light-content' : 'dark-content'} />
            <ScrollView
                ref={scrollRef}
                className="flex-1"
                showsVerticalScrollIndicator={false}
            >
                <Hero destination={searchDestination} />

                <View className="pb-20 gap-y-8">
                    <YourRecentSearches />
                    <TrendingNearYou onSelect={handleTrendingSelect} />
                    <UniqueStays />
                    <DealsSection />
                    <ExploreVacationPackages />
                    <PriceAlertBanner />
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}
