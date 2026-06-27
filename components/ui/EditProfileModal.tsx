import { useAuth } from '@/context/AuthContext';
import { useColorScheme } from '@/hooks/useColorScheme';
import { X } from 'lucide-react-native';
import { useEffect, useState } from 'react';
import {
    ActivityIndicator,
    Alert,
    KeyboardAvoidingView,
    Modal,
    Platform,
    Text,
    TextInput,
    TouchableOpacity,
    View,
} from 'react-native';

const dark = {
    bg: '#0B1018',
    card: '#141C2A',
    border: '#1F2D3D',
    text: '#FFFFFF',
    muted: '#8896AA',
    label: '#8896AA',
    blue: '#3B82F6',
    divider: '#1F2D3D',
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
};

function useTheme() {
    const colorScheme = useColorScheme();
    return colorScheme === 'dark' ? dark : light;
}

interface Props {
    visible: boolean;
    onClose: () => void;
}

export default function EditProfileModal({ visible, onClose }: Props) {
    const { user, updateProfile } = useAuth();
    const C = useTheme();

    const [firstName, setFirstName] = useState('');
    const [lastName, setLastName] = useState('');
    const [saving, setSaving] = useState(false);

    // Sync fields whenever the modal opens
    useEffect(() => {
        if (visible && user) {
            setFirstName(user.firstName ?? '');
            setLastName(user.lastName ?? '');
        }
    }, [visible, user]);

    const hasChanges =
        firstName.trim() !== (user?.firstName ?? '') ||
        lastName.trim() !== (user?.lastName ?? '');

    const handleSave = async () => {
        const f = firstName.trim();
        const l = lastName.trim();

        if (!f || !l) {
            Alert.alert('Missing fields', 'Please enter both first and last name.');
            return;
        }

        setSaving(true);
        try {
            await updateProfile({ firstName: f, lastName: l });
            onClose();
        } catch (err: any) {
            Alert.alert('Update failed', err.message ?? 'Something went wrong. Please try again.');
        } finally {
            setSaving(false);
        }
    };

    return (
        <Modal
            visible={visible}
            animationType="slide"
            transparent
            onRequestClose={onClose}
        >
            <KeyboardAvoidingView
                style={{ flex: 1 }}
                behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
            >
                {/* Backdrop — tap to dismiss */}
                <TouchableOpacity
                    style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.5)' }}
                    activeOpacity={1}
                    onPress={onClose}
                />

                <View style={{
                    backgroundColor: C.card,
                    borderTopLeftRadius: 24,
                    borderTopRightRadius: 24,
                    padding: 24,
                    paddingBottom: Platform.OS === 'ios' ? 40 : 24,
                }}>
                    {/* Header */}
                    <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 24 }}>
                        <Text style={{ flex: 1, fontSize: 18, fontWeight: '700', color: C.text }}>
                            Edit Profile
                        </Text>
                        <TouchableOpacity
                            onPress={onClose}
                            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                        >
                            <X size={20} color={C.muted} />
                        </TouchableOpacity>
                    </View>

                    {/* First name */}
                    <Text style={{
                        fontSize: 11,
                        fontWeight: '600',
                        color: C.label,
                        letterSpacing: 1,
                        marginBottom: 6,
                    }}>
                        FIRST NAME
                    </Text>
                    <TextInput
                        value={firstName}
                        onChangeText={setFirstName}
                        placeholder="First name"
                        placeholderTextColor={C.muted}
                        autoCapitalize="words"
                        returnKeyType="next"
                        style={{
                            backgroundColor: C.bg,
                            borderRadius: 12,
                            paddingHorizontal: 16,
                            paddingVertical: 14,
                            fontSize: 15,
                            color: C.text,
                            borderWidth: 1,
                            borderColor: C.border,
                            marginBottom: 16,
                        }}
                    />

                    {/* Last name */}
                    <Text style={{
                        fontSize: 11,
                        fontWeight: '600',
                        color: C.label,
                        letterSpacing: 1,
                        marginBottom: 6,
                    }}>
                        LAST NAME
                    </Text>
                    <TextInput
                        value={lastName}
                        onChangeText={setLastName}
                        placeholder="Last name"
                        placeholderTextColor={C.muted}
                        autoCapitalize="words"
                        returnKeyType="done"
                        onSubmitEditing={handleSave}
                        style={{
                            backgroundColor: C.bg,
                            borderRadius: 12,
                            paddingHorizontal: 16,
                            paddingVertical: 14,
                            fontSize: 15,
                            color: C.text,
                            borderWidth: 1,
                            borderColor: C.border,
                            marginBottom: 28,
                        }}
                    />

                    {/* Save */}
                    <TouchableOpacity
                        style={{
                            backgroundColor: hasChanges ? C.blue : C.border,
                            borderRadius: 14,
                            paddingVertical: 16,
                            alignItems: 'center',
                        }}
                        onPress={handleSave}
                        disabled={saving || !hasChanges}
                        activeOpacity={0.8}
                    >
                        {saving ? (
                            <ActivityIndicator color="#fff" />
                        ) : (
                            <Text style={{
                                color: hasChanges ? '#fff' : C.muted,
                                fontWeight: '700',
                                fontSize: 16,
                            }}>
                                Save changes
                            </Text>
                        )}
                    </TouchableOpacity>
                </View>
            </KeyboardAvoidingView>
        </Modal>
    );
}