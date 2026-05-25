import { ChevronDown, Moon, Sun } from 'lucide-react-native';
import { useColorScheme } from 'nativewind';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { CURRENCIES, useSettings } from '../../context/SettingsContext';

const TopBar: React.FC = () => {
    const { colorScheme, setColorScheme } = useColorScheme();
    const isDark = colorScheme === 'dark';
    const { currency, setCurrency } = useSettings();

    const handleCurrencyPress = () => {
        const currentIndex = CURRENCIES.findIndex(c => c.code === currency.code);
        const nextIndex = (currentIndex + 1) % CURRENCIES.length;
        setCurrency(CURRENCIES[nextIndex].code);
    };

    const toggleTheme = () => setColorScheme(isDark ? 'light' : 'dark');

    return (
        <View style={styles.container}>
            <View style={styles.logoContainer}>
                <Text style={[styles.logoText, isDark && styles.logoTextDark]}>
                    Cheapest<Text style={styles.logoAccent}>Go</Text>
                </Text>
            </View>

            <View style={styles.actionsContainer}>
                <Pressable
                    style={[styles.currencyPill, isDark && styles.currencyPillDark]}
                    onPress={handleCurrencyPress}
                >
                    <Text style={[styles.currencySymbol, isDark && styles.currencyTextDark]}>{currency.symbol}</Text>
                    <Text style={[styles.currencyText, isDark && styles.currencyTextDark]}>{currency.code}</Text>
                    <ChevronDown size={14} color={isDark ? '#475569' : '#94a3b8'} />
                </Pressable>

                <Pressable style={styles.iconButton} onPress={toggleTheme}>
                    {isDark
                        ? <Sun size={22} color="#94a3b8" />
                        : <Moon size={22} color="#475569" />
                    }
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
        paddingVertical: 16,
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
        gap: 16,
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
    currencySymbol: {
        fontSize: 14,
        fontWeight: '700',
        color: '#0f172a',
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
    iconButton: {
        padding: 4,
    },
});

export default TopBar;
