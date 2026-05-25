import React from 'react';
import { ScrollView, View, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useColorScheme } from 'nativewind';
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

    return (
        <SafeAreaView className="flex-1 bg-slate-50 dark:bg-slate-950">
            <StatusBar barStyle={isDark ? 'light-content' : 'dark-content'} />
            <ScrollView
                className="flex-1"
                showsVerticalScrollIndicator={false}
            >
                <Hero />

                <View className="pb-20 gap-y-8">
                    <YourRecentSearches />
                    <TrendingNearYou />
                    <UniqueStays />
                    <DealsSection />
                    <ExploreVacationPackages />
                    <PriceAlertBanner />
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}
