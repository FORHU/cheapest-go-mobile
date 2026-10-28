import { Stack, useRouter } from 'expo-router';
import { ChevronLeft, HelpCircle, Mail, MessageCircle } from 'lucide-react-native';
import {
    Alert,
    Linking,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    useColorScheme,
    View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const dark = {
    bg: '#0B1018',
    card: '#141C2A',
    border: '#1F2D3D',
    text: '#FFFFFF',
    muted: '#8896AA',
    label: '#8896AA',
    blue: '#3B82F6',
    divider: '#1F2D3D',
    iconBg: 'rgba(59,130,246,0.15)',
    icon: '#3B82F6',
    faqBg: '#141C2A',
    bulletColor: '#3B82F6',
};

const light = {
    bg: '#F8FAFC',
    card: '#FFFFFF',
    border: '#E2E8F0',
    text: '#0F172A',
    muted: '#64748B',
    label: '#94A3B8',
    blue: '#2563EB',
    divider: '#F1F5F9',
    iconBg: 'rgba(37,99,235,0.08)',
    icon: '#2563EB',
    faqBg: '#F1F5F9',
    bulletColor: '#2563EB',
};

const FAQ_ITEMS = [
    'How do I cancel or modify my booking?',
    'When will I receive my booking confirmation?',
    'How do I request a refund?',
    'What payment methods are accepted?',
    'Can I change my check-in or check-out dates?',
    'How do I contact the hotel directly?',
];

export default function HelpCenterScreen() {
    const colorScheme = useColorScheme();
    const C = colorScheme === 'dark' ? dark : light;
    const router = useRouter();

    const handleEmailSupport = () => {
        Linking.openURL('mailto:support@cheapestgo.com').catch(() => {
            Alert.alert('Could not open email', 'Please email us at support@cheapestgo.com');
        });
    };

    const handleLiveChat = () => {
        Alert.alert(
            'Coming Soon',
            'Live chat support will be available in the next build.',
            [{ text: 'OK' }],
        );
    };

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: C.bg }]} edges={['top']}>
            <Stack.Screen options={{ headerShown: false }} />
            {/* Header */}
            <View style={[styles.header, { borderBottomColor: C.border }]}>
                <Pressable onPress={() => router.back()} style={styles.backRow} hitSlop={8}>
                    <ChevronLeft size={26} color={C.text} />
                    <Text style={[styles.backText, { color: C.text }]}>Back</Text>
                </Pressable>
            </View>

            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
            >
                {/* Page hero */}
                <View style={styles.hero}>
                    <View style={[styles.heroIconBox, { backgroundColor: C.iconBg }]}>
                        <HelpCircle size={22} color={C.icon} />
                    </View>
                    <Text style={[styles.heroTitle, { color: C.text }]}>Help & Support</Text>
                </View>
                <Text style={[styles.subtitle, { color: C.muted }]}>
                    Get help with your account and bookings
                </Text>

                {/* Contact Options */}
                <View style={styles.section}>
                    {/* Email Support */}
                    <TouchableOpacity
                        style={[styles.contactCard, { backgroundColor: C.card, borderColor: C.border }]}
                        onPress={handleEmailSupport}
                        activeOpacity={0.7}
                    >
                        <View style={[styles.contactIconBox, { backgroundColor: 'rgba(37,99,235,0.10)' }]}>
                            <Mail size={22} color={C.icon} />
                        </View>
                        <View style={styles.contactText}>
                            <Text style={[styles.contactTitle, { color: C.text }]}>Email Support</Text>
                            <Text style={[styles.contactSub, { color: C.muted }]}>support@cheapestgo.com</Text>
                        </View>
                    </TouchableOpacity>

                    {/* Live Chat */}
                    <TouchableOpacity
                        style={[styles.contactCard, { backgroundColor: C.card, borderColor: C.border }]}
                        onPress={handleLiveChat}
                        activeOpacity={0.7}
                    >
                        <View style={[styles.contactIconBox, { backgroundColor: 'rgba(34,197,94,0.10)' }]}>
                            <MessageCircle size={22} color="#16a34a" />
                        </View>
                        <View style={styles.contactText}>
                            <Text style={[styles.contactTitle, { color: C.text }]}>Live Chat</Text>
                            <Text style={[styles.contactSub, { color: C.muted }]}>Chat with our support team</Text>
                        </View>
                    </TouchableOpacity>
                </View>

                {/* FAQ */}
                <View style={[styles.faqCard, { backgroundColor: C.faqBg, borderColor: C.border }]}>
                    <Text style={[styles.faqTitle, { color: C.text }]}>Frequently Asked Questions</Text>
                    {FAQ_ITEMS.map((item, i) => (
                        <View key={i} style={styles.faqItem}>
                            <View style={[styles.bullet, { backgroundColor: C.bulletColor }]} />
                            <Text style={[styles.faqText, { color: C.muted }]}>{item}</Text>
                        </View>
                    ))}
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
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
    section: {
        gap: 12,
        marginBottom: 24,
    },
    contactCard: {
        flexDirection: 'row',
        alignItems: 'center',
        padding: 16,
        borderRadius: 16,
        borderWidth: 1,
        gap: 14,
    },
    contactIconBox: {
        width: 46,
        height: 46,
        borderRadius: 13,
        alignItems: 'center',
        justifyContent: 'center',
    },
    contactText: {
        flex: 1,
    },
    contactTitle: {
        fontSize: 15,
        fontWeight: '600',
        marginBottom: 2,
    },
    contactSub: {
        fontSize: 13,
    },
    faqCard: {
        borderRadius: 16,
        borderWidth: 1,
        padding: 20,
    },
    faqTitle: {
        fontSize: 15,
        fontWeight: '700',
        marginBottom: 16,
    },
    faqItem: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        gap: 10,
        marginBottom: 12,
    },
    bullet: {
        width: 6,
        height: 6,
        borderRadius: 3,
        marginTop: 6,
        flexShrink: 0,
    },
    faqText: {
        fontSize: 14,
        flex: 1,
        lineHeight: 20,
    },
});