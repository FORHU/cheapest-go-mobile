import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Star } from 'lucide-react-native';

interface StarRatingProps {
    rating: number;
    size?: number;
    color?: string;
    numeric?: boolean;
    // When true renders filled gold stars up to rating, no empty stars shown
    gold?: boolean;
}

const StarRating = React.memo(({
    rating,
    size = 16,
    color = '#2563eb',
    numeric = false,
    gold = false,
}: StarRatingProps) => {
    // Return nothing when there's no rating — avoids "0 ★" or 5 empty stars
    if (!rating || rating <= 0) return null;

    // Normalize: handles both 0-5 (star class) and 0-10 (review score) scales
    const normalizedRating = rating > 5 ? rating / 2 : rating;
    const starColor = gold ? '#f59e0b' : color;

    // ── Numeric mode: shows "8.5 ★" ─────────────────────────────
    if (numeric) {
        return (
            <View style={styles.numericContainer}>
                <Text style={[styles.numericText, { fontSize: size, color: starColor }]}>
                    {Math.round(normalizedRating * 10) / 10}
                </Text>
                <Star size={size - 2} color={starColor} fill={starColor} />
            </View>
        );
    }

    const fullStars  = Math.floor(normalizedRating);
    const totalStars = Math.min(fullStars, 5); // cap at 5

    // ── Gold mode: only filled stars, no empty stars ──────────────
    if (gold) {
        return (
            <View style={styles.starRow}>
                {[...Array(totalStars)].map((_, i) => (
                    <Star key={i} size={size} color="#f59e0b" fill="#f59e0b" />
                ))}
            </View>
        );
    }

    // ── Standard mode: filled + empty stars ──────────────────────
    return (
        <View style={styles.starRow}>
            {[...Array(5)].map((_, i) => (
                <Star
                    key={i}
                    size={size}
                    color={i < fullStars ? starColor : '#cbd5e1'}
                    fill={i < fullStars ? starColor : 'transparent'}
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
    },
    starRow: {
        flexDirection: 'row',
        gap: 2,
    },
});

export default StarRating;
