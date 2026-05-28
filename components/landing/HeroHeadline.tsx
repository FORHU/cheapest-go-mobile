import React from 'react';
import { View, Text, StyleSheet, useColorScheme } from 'react-native';
import { GradientText } from '../GradientText';

const HeroHeadline: React.FC = () => {
    const isDark = useColorScheme() === 'dark';

    return (
        <View style={styles.container}>
            {/* Headline */}
            <View style={styles.headlineBlock}>
                <Text style={[styles.headlineLine, isDark && styles.headlineLineDark]}>
                    Precision Travel.
                </Text>
                <GradientText
                    colors={['#3b82f6', '#06b6d4']}
                    style={styles.headlineLine}
                >
                    For You.
                </GradientText>
            </View>

            {/* Subtitle */}
            <Text style={[styles.subtitle, isDark && styles.subtitleDark]}>
                The operating system for the modern voyager.
            </Text>

            {/* Stats Row */}
            <View style={styles.statsRow}>
                <View style={styles.statItem}>
                    <Text style={[styles.statValue, isDark && styles.statValueDark]}>2.4M+</Text>
                    <Text style={[styles.statLabel, isDark && styles.statLabelDark]}>Properties</Text>
                </View>
                <View style={[styles.statDivider, isDark && styles.statDividerDark]} />
                <View style={styles.statItem}>
                    <Text style={[styles.statValue, isDark && styles.statValueDark]}>500+</Text>
                    <Text style={[styles.statLabel, isDark && styles.statLabelDark]}>Airlines</Text>
                </View>
                <View style={[styles.statDivider, isDark && styles.statDividerDark]} />
                <View style={styles.statItem}>
                    <Text style={[styles.statValue, { color: '#3b82f6' }]}>₱0</Text>
                    <Text style={[styles.statLabel, isDark && styles.statLabelDark]}>Booking fees</Text>
                </View>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        alignItems: 'center',
        paddingHorizontal: 24,
    },
    headlineBlock: {
        alignItems: 'center',
        marginBottom: 12,
    },
    headlineLine: {
        fontSize: 40,
        fontWeight: '800',
        color: '#0f172a',
        letterSpacing: -1,
        lineHeight: 48,
        textAlign: 'center',
    },
    headlineLineDark: {
        color: '#ffffff',
    },
    subtitle: {
        fontSize: 14,
        color: '#64748b',
        textAlign: 'center',
        lineHeight: 20,
        marginBottom: 20,
    },
    subtitleDark: {
        color: '#64748b',
    },
    statsRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 20,
    },
    statItem: {
        alignItems: 'center',
    },
    statValue: {
        fontSize: 18,
        fontWeight: '800',
        color: '#0f172a',
    },
    statValueDark: {
        color: '#ffffff',
    },
    statLabel: {
        fontSize: 11,
        color: '#94a3b8',
        fontWeight: '500',
        marginTop: 1,
    },
    statLabelDark: {
        color: '#64748b',
    },
    statDivider: {
        width: 1,
        height: 28,
        backgroundColor: '#e2e8f0',
    },
    statDividerDark: {
        backgroundColor: '#1e293b',
    },
});

export default HeroHeadline;
