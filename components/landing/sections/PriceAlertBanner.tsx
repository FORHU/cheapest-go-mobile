import React from 'react';
import { View, Text, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { Bell } from 'lucide-react-native';

export default function PriceAlertBanner() {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);

    return (
        <View style={styles.container}>
            <Text style={styles.label}>PRICE ALERT</Text>
            <Text style={styles.headline}>Never overpay{'\n'}again.</Text>
            <Text style={styles.body}>
                Turn on smart tracking and we'll notify you the moment your dream destination drops in price.
            </Text>
            <View style={styles.buttons}>
                <Pressable style={styles.btnPrimary}>
                    <Bell size={14} color="#0f172a" />
                    <Text style={styles.btnPrimaryText}>Enable alerts</Text>
                </Pressable>
                <Pressable style={styles.btnOutline}>
                    <Text style={styles.btnOutlineText}>Learn more</Text>
                </Pressable>
            </View>
        </View>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        marginHorizontal: 20,
        backgroundColor: isDark ? '#0c1628' : '#0f172a',
        borderRadius: 24,
        padding: 24,
        borderWidth: 1,
        borderColor: isDark ? '#1e3a5f' : '#1e293b',
        borderLeftWidth: 4,
        borderLeftColor: '#3b82f6',
    },
    label: {
        fontSize: 11,
        fontWeight: '700',
        color: '#3b82f6',
        letterSpacing: 1.2,
        marginBottom: 10,
    },
    headline: {
        fontSize: 28,
        fontWeight: '800',
        color: '#ffffff',
        lineHeight: 34,
        marginBottom: 12,
    },
    body: {
        fontSize: 13,
        color: '#64748b',
        lineHeight: 20,
        marginBottom: 20,
    },
    buttons: {
        flexDirection: 'row',
        gap: 12,
    },
    btnPrimary: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        backgroundColor: '#ffffff',
        paddingHorizontal: 18,
        paddingVertical: 11,
        borderRadius: 12,
    },
    btnPrimaryText: {
        fontSize: 13,
        fontWeight: '700',
        color: '#0f172a',
    },
    btnOutline: {
        paddingHorizontal: 18,
        paddingVertical: 11,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: '#334155',
    },
    btnOutlineText: {
        fontSize: 13,
        fontWeight: '600',
        color: '#94a3b8',
    },
});
