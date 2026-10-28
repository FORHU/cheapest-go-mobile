import { LANGUAGES } from '@/context/SettingsContext';
import { useColorScheme } from '@/hooks/useColorScheme';
import { Check, X } from 'lucide-react-native';
import {
    Modal,
    ScrollView,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';

const dark = {
    card: '#141C2A',
    border: '#1F2D3D',
    text: '#FFFFFF',
    muted: '#8896AA',
    blue: '#3B82F6',
    divider: '#1F2D3D',
};

const light = {
    card: '#FFFFFF',
    border: '#E2E8F0',
    text: '#0F172A',
    muted: '#64748B',
    blue: '#2563EB',
    divider: '#F1F5F9',
};

function useTheme() {
    const colorScheme = useColorScheme();
    return colorScheme === 'dark' ? dark : light;
}

interface Props {
    visible: boolean;
    currentCode: string;
    onSelect: (code: string) => void;
    onClose: () => void;
}

export default function LanguagePickerModal({ visible, currentCode, onSelect, onClose }: Props) {
    const C = useTheme();

    return (
        <Modal
            visible={visible}
            animationType="slide"
            transparent
            onRequestClose={onClose}
        >
            <View style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.5)' }}>
                {/* Tap outside to dismiss */}
                <TouchableOpacity style={{ flex: 1 }} activeOpacity={1} onPress={onClose} />

                <View style={{
                    backgroundColor: C.card,
                    borderTopLeftRadius: 24,
                    borderTopRightRadius: 24,
                    maxHeight: '75%',
                }}>
                    {/* Header */}
                    <View style={{
                        flexDirection: 'row',
                        alignItems: 'center',
                        paddingHorizontal: 20,
                        paddingTop: 20,
                        paddingBottom: 16,
                        borderBottomWidth: 1,
                        borderBottomColor: C.divider,
                    }}>
                        <Text style={{ flex: 1, fontSize: 18, fontWeight: '700', color: C.text }}>
                            Select Language
                        </Text>
                        <TouchableOpacity onPress={onClose} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                            <X size={20} color={C.muted} />
                        </TouchableOpacity>
                    </View>

                    {/* Language list */}
                    <ScrollView
                        showsVerticalScrollIndicator={false}
                        contentContainerStyle={{ paddingVertical: 8, paddingBottom: 40 }}
                    >
                        {LANGUAGES.map((lang, index) => {
                            const isSelected = lang.code === currentCode;
                            return (
                                <TouchableOpacity
                                    key={lang.code}
                                    style={{
                                        flexDirection: 'row',
                                        alignItems: 'center',
                                        paddingHorizontal: 20,
                                        paddingVertical: 14,
                                        borderBottomWidth: index < LANGUAGES.length - 1 ? 1 : 0,
                                        borderBottomColor: C.divider,
                                        backgroundColor: isSelected ? `${C.blue}12` : 'transparent',
                                    }}
                                    onPress={() => {
                                        onSelect(lang.code);
                                        onClose();
                                    }}
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
            </View>
        </Modal>
    );
}