import React from 'react';
import { View, Text, useColorScheme } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import HeroHeadline from './HeroHeadline';
import AISearchBar from './AISearchBar';
import AISuggestionChips from './AISuggestionChips';
import TopBar from './TopBar';
import SearchPill from './SearchPill';

type SearchMode = 'Stays' | 'Flights' | 'AI Search';

interface HeroProps {
    /** Destination pre-filled into the search bar, e.g. from a Trending near you card. */
    destination?: string | null;
}

const Hero = ({ destination = null }: HeroProps) => {
    const [activeTab, setActiveTab] = React.useState<SearchMode>('Stays');
    const isDark = useColorScheme() === 'dark';

    // A pre-filled destination is always a stay, so snap back to that tab.
    // Derived during render — React's recommended alternative to a setState-in-effect.
    const [prevDestination, setPrevDestination] = React.useState(destination);
    if (destination !== prevDestination) {
        setPrevDestination(destination);
        if (destination) setActiveTab('Stays');
    }

    return (
        <View className="w-full items-center pt-2 pb-8 relative">
            {/* Gradient Background */}
            <LinearGradient
                colors={isDark ? ['rgba(30, 41, 59, 0.05)', 'transparent'] : ['rgba(59, 130, 246, 0.03)', 'transparent']}
                className="absolute top-0 left-0 right-0 h-[400px]"
            />

            {/* Background Glow Effect */}
            <View 
                className="absolute top-40 w-[300px] h-[300px] bg-blue-500/5 rounded-full" 
                pointerEvents="none" 
            />

            <TopBar />
            
            <View className="mt-8 w-full items-center">
                <HeroHeadline />
                
                <View className="mt-6 w-full items-center">
                    <Text className="text-slate-500 dark:text-slate-500 text-[10px] font-bold tracking-widest uppercase mb-2">
                        Ask anything. Book everything.
                    </Text>
                    <SearchPill activeTab={activeTab} onTabChange={setActiveTab} />
                </View>

                <AISearchBar activeTab={activeTab} destination={destination} />
                <AISuggestionChips onSuggestionClick={() => {}} />
            </View>
        </View>
    );
};

export default Hero;
