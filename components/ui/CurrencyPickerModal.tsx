import { Check } from 'lucide-react-native';
import React from 'react';
import {
    Modal,
    Pressable,
    StyleSheet,
    Text,
    useColorScheme,
    View,
} from 'react-native';
import { CURRENCIES } from '../../context/SettingsContext';

interface CurrencyPickerModalProps {
    visible: boolean;
    currentCode: string;
    onSelect: (code: string) => void;
    onClose: () => void;
}

const CURRENCY_META: Record<string, { flag: string; name: string }> = {
    KRW: { flag: '🇰🇷', name: 'Korean Won' },
    USD: { flag: '🇺🇸', name: 'US Dollar' },
    PHP: { flag: '🇵🇭', name: 'Philippine Peso' },
};

export default function CurrencyPickerModal({
    visible,
    currentCode,
    onSelect,
    onClose,
}: CurrencyPickerModalProps) {
    const isDark = useColorScheme() === 'dark';
    const C = isDark ? dark : light;

    return (
        <Modal
            visible={visible}
            transparent
            animationType="fade"
            statusBarTranslucent
            onRequestClose={onClose}
        >
            <Pressable style={styles.overlay} onPress={onClose}>
                <Pressable style={[styles.sheet, { backgroundColor: C.bg, borderColor: C.border }]} onPress={() => {}}>
                    <View style={[styles.handle, { backgroundColor: C.handle }]} />

                    <Text style={[styles.title, { color: C.text }]}>Select Currency</Text>

                    {CURRENCIES.map((currency, idx) => {
                        const meta = CURRENCY_META[currency.code];
                        const isActive = currency.code === currentCode;
                        const isLast = idx === CURRENCIES.length - 1;
                        return (
                            <Pressable
                                key={currency.code}
                                style={[
                                    styles.row,
                                    { borderBottomColor: C.divider },
                                    isLast && styles.rowLast,
                                    isActive && { backgroundColor: isDark ? 'rgba(59,130,246,0.08)' : 'rgba(37,99,235,0.05)' },
                                ]}
                                onPress={() => { onSelect(currency.code); onClose(); }}
                            >
                                <Text style={styles.flag}>{meta?.flag ?? '🌐'}</Text>
                                <View style={styles.rowText}>
                                    <Text style={[styles.rowCode, { color: C.text }]}>{currency.code}</Text>
                                    <Text style={[styles.rowName, { color: C.muted }]}>{meta?.name ?? currency.code}</Text>
                                </View>
                                <Text style={[styles.rowSymbol, { color: isActive ? '#3b82f6' : C.muted }]}>
                                    {currency.symbol}
                                </Text>
                                {isActive && (
                                    <Check size={18} color="#3b82f6" style={styles.check} />
                                )}
                            </Pressable>
                        );
                    })}
                </Pressable>
            </Pressable>
        </Modal>
    );
}

const dark = {
    bg: '#141C2A',
    border: '#1F2D3D',
    text: '#FFFFFF',
    muted: '#8896AA',
    divider: '#1F2D3D',
    handle: '#2D3E50',
};

const light = {
    bg: '#FFFFFF',
    border: '#E2E8F0',
    text: '#0F172A',
    muted: '#64748B',
    divider: '#F1F5F9',
    handle: '#CBD5E1',
};

const styles = StyleSheet.create({
    overlay: {
        flex: 1,
        backgroundColor: 'rgba(0,0,0,0.5)',
        justifyContent: 'flex-end',
    },
    sheet: {
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        borderWidth: 1,
        borderBottomWidth: 0,
        paddingBottom: 32,
        paddingHorizontal: 0,
        overflow: 'hidden',
    },
    handle: {
        width: 40,
        height: 4,
        borderRadius: 2,
        alignSelf: 'center',
        marginTop: 12,
        marginBottom: 4,
    },
    title: {
        fontSize: 16,
        fontWeight: '700',
        textAlign: 'center',
        paddingVertical: 14,
        paddingHorizontal: 20,
    },
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 24,
        paddingVertical: 16,
        borderBottomWidth: 1,
        gap: 14,
    },
    rowLast: {
        borderBottomWidth: 0,
    },
    flag: {
        fontSize: 26,
        lineHeight: 32,
    },
    rowText: {
        flex: 1,
    },
    rowCode: {
        fontSize: 15,
        fontWeight: '700',
    },
    rowName: {
        fontSize: 12,
        marginTop: 2,
    },
    rowSymbol: {
        fontSize: 18,
        fontWeight: '700',
        minWidth: 24,
        textAlign: 'right',
    },
    check: {
        marginLeft: 4,
    },
});
