import { LANGUAGES, useSettings } from '@/context/SettingsContext';
import { useColorScheme } from '@/hooks/useColorScheme';
import { Stack, useRouter } from 'expo-router';
import { Check, ChevronLeft, Globe } from 'lucide-react-native';
import {
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const dark = {
    bg: '#0B1018',
    card: '#141C2A',
    border: '#1F2D3D',
    text: '#FFFFFF',
    muted: '#8896AA',
    blue: '#3B82F6',
    divider: '#1F2D3D',
    iconBg: 'rgba(59,130,246,0.15)',
    icon: '#3B82F6',
    selectedBg: 'rgba(59,130,246,0.12)',
};

const light = {
    bg: '#F8FAFC',
    card: '#FFFFFF',
    border: '#E2E8F0',
    text: '#0F172A',
    muted: '#64748B',
    blue: '#2563EB',
    divider: '#F1F5F9',
    iconBg: 'rgba(37,99,235,0.08)',
    icon: '#2563EB',
    selectedBg: 'rgba(37,99,235,0.08)',
};

function useTheme() {
    const colorScheme = useColorScheme();
    return colorScheme === 'dark' ? dark : light;
}

export default function LanguagePreferencesScreen() {
    const router = useRouter();
    const { language, setLanguage } = useSettings();
    const C = useTheme();

    const handleSelect = (code: string) => {
        setLanguage(code);
        router.back();
    };

    return (
        <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
            <Stack.Screen options={{ headerShown: false }} />
            <View style={[styles.header, { borderBottomColor: C.border }]}>
                <Pressable onPress={() => router.back()} style={styles.backRow} hitSlop={8}>
                    <ChevronLeft size={24} color={C.text} />
                    <Text style={[styles.backText, { color: C.text }]}>Back</Text>
                </Pressable>
            </View>

            {/* Header */}
            <View style={[styles.scroll, { flex: 1 }]}>
                {/* Hero */}
                <View style={styles.hero}>
                    <View style={[styles.heroIconBox, { backgroundColor: C.iconBg }]}>
                        <Globe size={22} color={C.icon} />
                    </View>
                    <Text style={[styles.heroTitle, { color: C.text }]}>Language Preferences</Text>
                </View>
                <Text style={[styles.subtitle, { color: C.muted }]}>
                    Choose the language you'd like to use across the app
                </Text>

                {/* Language list */}
                <ScrollView
                    showsVerticalScrollIndicator={false}
                    style={{ flex: 1 }}
                    contentContainerStyle={{
                        backgroundColor: C.card,
                        borderRadius: 16,
                        borderWidth: 1,
                        borderColor: C.border,
                        overflow: 'hidden',
                    }}
                >
                    {LANGUAGES.map((lang, index) => {
                        const isSelected = lang.code === language.code;
                        return (
                            <TouchableOpacity
                                key={lang.code}
                                style={{
                                    flexDirection: 'row',
                                    alignItems: 'center',
                                    paddingHorizontal: 16,
                                    paddingVertical: 14,
                                    borderBottomWidth: index < LANGUAGES.length - 1 ? 1 : 0,
                                    borderBottomColor: C.divider,
                                    backgroundColor: isSelected ? C.selectedBg : 'transparent',
                                }}
                                onPress={() => handleSelect(lang.code)}
                                activeOpacity={0.7}
                            >
                                <Text style={{ fontSize: 22, marginRight: 14 }}>{lang.flag}</Text>
                                <View style={{ flex: 1 }}>
                                    <Text style={{ fontSize: 15, fontWeight: '500', color: C.text }}>
                                        {lang.english}
                                    </Text>
                                    <Text style={{ fontSize: 12, color: C.muted, marginTop: 2 }}>
                                        {lang.label}
                                    </Text>
                                </View>
                                {isSelected && (
                                    <Check size={18} color={C.blue} strokeWidth={2.5} />
                                )}
                            </TouchableOpacity>
                        );
                    })}
                </ScrollView>
            </View>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingVertical: 14,
        borderBottomWidth: 1,
    },
    backRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
    },
    backText: {
        fontSize: 17,
        fontWeight: '600',
    },
    scroll: {
        padding: 20,
        paddingBottom: 40,
    },
    hero: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        marginBottom: 8,
    },
    heroIconBox: {
        width: 42,
        height: 42,
        borderRadius: 12,
        alignItems: 'center',
        justifyContent: 'center',
    },
    heroTitle: {
        fontSize: 24,
        fontWeight: '800',
    },
    subtitle: {
        fontSize: 14,
        marginBottom: 28,
        lineHeight: 20,
    },
});