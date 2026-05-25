import React from 'react';
import { View, Text, Pressable, ScrollView, StyleSheet, useColorScheme } from 'react-native';
import { Waves, Gem, Heart, Plane, Mountain } from 'lucide-react-native';

const suggestions = [
    { label: 'Beach Escape', prompt: 'Beachfront resort in Boracay for 2, this weekend' },
    { label: 'Luxury Stay', prompt: '5-star hotel in Manila under ₱15,000/night' },
    { label: 'Romantic Trip', prompt: "Couple's retreat in Tagaytay with spa" },
    { label: 'Quick Getaway', prompt: 'Last-minute deal in Cebu, 3 nights' },
    { label: 'Adventure', prompt: 'Mountain lodge in Baguio for a group of 4' },
];

interface AISuggestionChipsProps {
    onSuggestionClick: (prompt: string) => void;
}

const AISuggestionChips: React.FC<AISuggestionChipsProps> = ({ onSuggestionClick }) => {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const iconColor = isDark ? '#64748b' : '#94a3b8';

    const iconMap: Record<string, React.ReactNode> = {
        'Beach Escape': <Waves size={13} color={iconColor} />,
        'Luxury Stay': <Gem size={13} color={iconColor} />,
        'Romantic Trip': <Heart size={13} color={iconColor} />,
        'Quick Getaway': <Plane size={13} color={iconColor} />,
        'Adventure': <Mountain size={13} color={iconColor} />,
    };

    const styles = getStyles(isDark);

    return (
        <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.scrollView}
            contentContainerStyle={styles.contentContainer}
        >
            <View style={styles.chipsContainer}>
                {suggestions.map((suggestion) => (
                    <Pressable
                        key={suggestion.label}
                        onPress={() => onSuggestionClick(suggestion.prompt)}
                        style={styles.chip}
                    >
                        {iconMap[suggestion.label]}
                        <Text style={styles.chipText}>
                            {suggestion.label}
                        </Text>
                    </Pressable>
                ))}
            </View>
        </ScrollView>
    );
};

const getStyles = (isDark: boolean) => StyleSheet.create({
    scrollView: {
        marginTop: 14,
        paddingHorizontal: 16,
    },
    contentContainer: {
        paddingRight: 32,
    },
    chipsContainer: {
        flexDirection: 'row',
        gap: 8,
    },
    chip: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 7,
        paddingHorizontal: 14,
        paddingVertical: 8,
        borderRadius: 9999,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
    },
    chipText: {
        fontSize: 12,
        fontWeight: '500',
        color: isDark ? '#94a3b8' : '#475569',
    },
});

export default AISuggestionChips;
