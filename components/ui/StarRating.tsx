import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Star } from 'lucide-react-native';

interface StarRatingProps {
    rating: number;
    size?: number;
    color?: string;
    numeric?: boolean;
}

const StarRating = React.memo(({ rating, size = 16, color = '#2563eb', numeric = false }: StarRatingProps) => {
    // Convert 0-10 or 0-5 to 5-star scale
    const normalizedRating = rating > 5 ? rating / 2 : rating;
    
    if (numeric) {
        return (
            <View style={styles.numericContainer}>
                <Text style={[styles.numericText, { fontSize: size, color }]}>
                    {Math.round(normalizedRating * 10) / 10}
                </Text>
                <Star size={size - 2} color={color} fill={color} />
            </View>
        );
    }

    const fullStars = Math.floor(normalizedRating);

    return (
        <View style={{ flexDirection: 'row', gap: 2 }}>
            {[...Array(5)].map((_, i) => (
                <Star
                    key={i}
                    size={size}
                    color={i < fullStars ? color : '#cbd5e1'}
                    fill={i < fullStars ? color : 'transparent'}
                />
            ))}
        </View>
    );
});

const styles = StyleSheet.create({
    numericContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
    },
    numericText: {
        fontWeight: '800',
    }
});

export default StarRating;
