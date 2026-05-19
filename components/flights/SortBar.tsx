import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';

interface SortBarProps {
    active: 'price' | 'duration' | 'departure';
    onChange: (sort: 'price' | 'duration' | 'departure') => void;
    isDark: boolean;
}

const TABS: { label: string; value: 'price' | 'duration' | 'departure' }[] = [
    { label: 'Cheapest', value: 'price' },
    { label: 'Fastest', value: 'duration' },
    { label: 'Earliest', value: 'departure' },
];

export default function SortBar({ active, onChange, isDark }: SortBarProps) {
    return (
        <View style={[
            styles.container,
            {
                backgroundColor: isDark ? '#020617' : '#f8fafc',
                borderBottomColor: isDark ? '#1e293b' : '#e2e8f0',
                shadowColor: isDark ? '#000' : '#94a3b8',
            },
        ]}>
            {TABS.map((tab) => {
                const isActive = active === tab.value;
                return (
                    <Pressable
                        key={tab.value}
                        onPress={() => onChange(tab.value)}
                        style={[
                            styles.tab,
                            isActive && { borderBottomColor: '#2563eb', borderBottomWidth: 2 },
                        ]}
                    >
                        <Text style={[
                            styles.tabText,
                            { color: isActive ? '#2563eb' : isDark ? '#64748b' : '#94a3b8' },
                            isActive && styles.tabTextActive,
                        ]}>
                            {tab.label}
                        </Text>
                    </Pressable>
                );
            })}
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flexDirection: 'row',
        paddingHorizontal: 16,
        borderBottomWidth: 1,
        marginBottom: 4,
        // Sticky shadow so it visually separates from scrolling cards
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.06,
        shadowRadius: 4,
        elevation: 3,
        zIndex: 10,
    },
    tab: {
        flex: 1,
        alignItems: 'center',
        paddingVertical: 10,
        borderBottomWidth: 2,
        borderBottomColor: 'transparent',
    },
    tabText: {
        fontSize: 13,
        fontWeight: '500',
    },
    tabTextActive: {
        fontWeight: '700',
    },
});
