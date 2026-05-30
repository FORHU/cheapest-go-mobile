/**
 * ForceUpdateModal — blocks the entire app when the admin requires an update.
 *
 * Shows over everything (modal presentation).
 * The "Update Now" button opens the App Store / Play Store.
 * There is intentionally no "dismiss" — the user must update.
 */

import React from 'react';
import {
    Modal,
    View,
    Text,
    Pressable,
    Linking,
    StyleSheet,
    useColorScheme,
    Platform,
} from 'react-native';
import { APP_VERSION } from '@/lib/config';

// Store URLs — Play Store uses the definitive package name from app.json.
// iOS URL will resolve once the app is live in App Store Connect;
// until then it falls back to a search for "CheapestGo".
const APP_STORE_URL  = 'https://apps.apple.com/app/cheapestgo/id?bundleId=com.cheapestgo.mobile';
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.cheapestgo.mobile';

interface ForceUpdateModalProps {
    visible: boolean;
    message: string;
    minVersion: string;
}

export function ForceUpdateModal({ visible, message, minVersion }: ForceUpdateModalProps) {
    const isDark = useColorScheme() === 'dark';
    const s = styles(isDark);

    const openStore = () => {
        const url = Platform.OS === 'ios' ? APP_STORE_URL : PLAY_STORE_URL;
        Linking.openURL(url).catch(() => {});
    };

    return (
        <Modal
            visible={visible}
            animationType="fade"
            transparent
            statusBarTranslucent
        >
            <View style={s.overlay}>
                <View style={s.card}>
                    {/* Icon */}
                    <View style={s.iconWrap}>
                        <Text style={s.icon}>🚀</Text>
                    </View>

                    <Text style={s.title}>Update Required</Text>

                    <Text style={s.body}>
                        {message || `CheapestGo ${minVersion} is required to continue. Please update to the latest version.`}
                    </Text>

                    <Text style={s.versionHint}>
                        Your version: {APP_VERSION} · Required: {minVersion}+
                    </Text>

                    <Pressable
                        style={({ pressed }) => [s.btn, pressed && s.btnPressed]}
                        onPress={openStore}
                    >
                        <Text style={s.btnText}>Update Now</Text>
                    </Pressable>
                </View>
            </View>
        </Modal>
    );
}

const styles = (isDark: boolean) => StyleSheet.create({
    overlay: {
        flex: 1,
        backgroundColor: isDark ? 'rgba(0,0,0,0.85)' : 'rgba(0,0,0,0.6)',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
    },
    card: {
        width: '100%',
        maxWidth: 360,
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderRadius: 24,
        padding: 28,
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 12 },
        shadowOpacity: isDark ? 0.6 : 0.15,
        shadowRadius: 24,
        elevation: 20,
    },
    iconWrap: {
        width: 72,
        height: 72,
        borderRadius: 20,
        backgroundColor: isDark ? 'rgba(37,99,235,0.15)' : '#dbeafe',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 20,
    },
    icon: {
        fontSize: 36,
    },
    title: {
        fontSize: 22,
        fontWeight: '800',
        color: isDark ? '#f8fafc' : '#0f172a',
        marginBottom: 12,
        textAlign: 'center',
        letterSpacing: -0.5,
    },
    body: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#475569',
        textAlign: 'center',
        lineHeight: 22,
        marginBottom: 8,
    },
    versionHint: {
        fontSize: 11,
        color: isDark ? '#475569' : '#94a3b8',
        textAlign: 'center',
        marginBottom: 24,
        fontVariant: ['tabular-nums'],
    },
    btn: {
        width: '100%',
        height: 52,
        backgroundColor: '#2563eb',
        borderRadius: 14,
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 6 },
        shadowOpacity: 0.35,
        shadowRadius: 12,
        elevation: 8,
    },
    btnPressed: {
        backgroundColor: '#1d4ed8',
        shadowOpacity: 0.2,
    },
    btnText: {
        color: '#ffffff',
        fontSize: 16,
        fontWeight: '700',
        letterSpacing: 0.2,
    },
});
