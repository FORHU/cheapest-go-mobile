import { ExternalLink, FileText, Shield } from 'lucide-react-native';
import {
    Alert,
    Linking,
    Modal,
    Pressable,
    StyleSheet,
    Text,
    useColorScheme,
    View,
} from 'react-native';

// TODO: replace with the real production domain once deployed
const LEGAL_LINKS = [
    {
        key: 'terms',
        title: 'Terms of Service',
        url: 'http://10.192.111.12:3000/terms-of-service',
        Icon: FileText,
    },
    {
        key: 'privacy',
        title: 'Privacy Policy',
        url: 'http://10.192.111.12:3000/privacy-policy',
        Icon: Shield,
    },
];

interface Props {
    visible: boolean;
    onClose: () => void;
}

export default function LegalLinksModal({ visible, onClose }: Props) {
    const isDark = useColorScheme() === 'dark';
    const C = isDark ? dark : light;

    const handleOpen = (url: string) => {
        Linking.openURL(url).catch(() => {
            Alert.alert('Could not open page', 'Please try again later.');
        });
    };

    return (
        <Modal
            visible={visible}
            transparent
            animationType="fade"
            statusBarTranslucent
            onRequestClose={onClose}
        >
            <Pressable style={styles.overlay} onPress={onClose}>
                <Pressable style={[styles.sheet, { backgroundColor: C.bg, borderColor: C.border }]} onPress={() => { }}>
                    <View style={[styles.handle, { backgroundColor: C.handle }]} />

                    <Text style={[styles.title, { color: C.text }]}>Terms & Privacy</Text>

                    {LEGAL_LINKS.map(({ key, title, url, Icon }, idx) => {
                        const isLast = idx === LEGAL_LINKS.length - 1;
                        return (
                            <Pressable
                                key={key}
                                style={[
                                    styles.row,
                                    { borderBottomColor: C.divider },
                                    isLast && styles.rowLast,
                                ]}
                                onPress={() => handleOpen(url)}
                            >
                                <View style={[styles.iconBox, { backgroundColor: C.iconBg }]}>
                                    <Icon size={18} color={C.icon} />
                                </View>
                                <Text style={[styles.rowTitle, { color: C.text }]}>{title}</Text>
                                <ExternalLink size={16} color={C.muted} />
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
    iconBg: 'rgba(59,130,246,0.15)',
    icon: '#3B82F6',
};

const light = {
    bg: '#FFFFFF',
    border: '#E2E8F0',
    text: '#0F172A',
    muted: '#64748B',
    divider: '#F1F5F9',
    handle: '#CBD5E1',
    iconBg: 'rgba(37,99,235,0.08)',
    icon: '#2563EB',
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
    iconBox: {
        width: 36,
        height: 36,
        borderRadius: 10,
        alignItems: 'center',
        justifyContent: 'center',
    },
    rowTitle: {
        flex: 1,
        fontSize: 15,
        fontWeight: '500',
    },
});