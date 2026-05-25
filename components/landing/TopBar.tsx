import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { ChevronDown, DollarSign, Bell } from 'lucide-react-native';
import { useColorScheme } from 'nativewind';
import { useSettings, CURRENCIES } from '../../context/SettingsContext';

const TopBar: React.FC = () => {
    const { colorScheme } = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency, setCurrency } = useSettings();

    const handleCurrencyPress = () => {
        const currentIndex = CURRENCIES.findIndex(c => c.code === currency.code);
        const nextIndex = (currentIndex + 1) % CURRENCIES.length;
        setCurrency(CURRENCIES[nextIndex].code);
    };

    return (
        <View style={styles.container}>
            {/* Logo */}
            <View style={styles.logoContainer}>
                <Text style={[styles.logoText, isDark && styles.logoTextDark]}>
                    Cheapest<Text style={styles.logoAccent}>Go</Text>
                </Text>
            </View>

            {/* Right Side Actions */}
            <View style={styles.actionsContainer}>
                <Pressable
                    style={[styles.currencyPill, isDark && styles.currencyPillDark]}
                    onPress={handleCurrencyPress}
                >
                    <DollarSign size={13} color={isDark ? "#94a3b8" : "#64748b"} />
                    <Text style={[styles.currencyText, isDark && styles.currencyTextDark]}>{currency.code}</Text>
                    <ChevronDown size={14} color={isDark ? "#475569" : "#94a3b8"} />
                </Pressable>

                <Pressable style={styles.bellButton}>
                    <Bell size={22} color={isDark ? "#94a3b8" : "#475569"} />
                </Pressable>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        width: '100%',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 24,
        paddingVertical: 32,
    },
    logoContainer: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    logoText: {
        fontSize: 22,
        fontWeight: '700',
        color: '#0f172a',
    },
    logoTextDark: {
        color: '#ffffff',
    },
    logoAccent: {
        color: '#3b82f6',
    },
    actionsContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 24,
    },
    currencyPill: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 16,
        paddingVertical: 8,
        backgroundColor: '#f1f5f9',
        borderRadius: 9999,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    currencyPillDark: {
        backgroundColor: '#0f172a',
        borderColor: '#1e293b',
    },
    currencyText: {
        fontSize: 14,
        fontWeight: '700',
        color: '#0f172a',
        textTransform: 'uppercase',
    },
    currencyTextDark: {
        color: '#ffffff',
    },
    bellButton: {
        padding: 4,
    },
});

export default TopBar;
