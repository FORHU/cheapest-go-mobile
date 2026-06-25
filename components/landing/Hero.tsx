import React from 'react';
import { View, Text, useColorScheme } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import HeroHeadline from './HeroHeadline';
import AISearchBar from './AISearchBar';
import AISuggestionChips from './AISuggestionChips';
import TopBar from './TopBar';
import SearchPill from './SearchPill';

type SearchMode = 'Stays' | 'Flights' | 'AI Search';

const Hero = () => {
    const [activeTab, setActiveTab] = React.useState<SearchMode>('Stays');
    const isDark = useColorScheme() === 'dark';

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

                <AISearchBar activeTab={activeTab} />
                <AISuggestionChips onSuggestionClick={() => {}} />
            </View>
        </View>
    );
};

export default Hero;
