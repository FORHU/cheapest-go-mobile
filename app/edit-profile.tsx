import { useAuth } from '@/context/AuthContext';
import { Stack, useRouter } from 'expo-router';
import { ChevronLeft, User } from 'lucide-react-native';
import { useEffect, useState } from 'react';
import {
    ActivityIndicator,
    Alert,
    KeyboardAvoidingView,
    Platform,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
    useColorScheme,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const dark = {
    bg: '#0B1018',
    border: '#1F2D3D',
    text: '#FFFFFF',
    muted: '#8896AA',
    sectionLabel: '#8896AA',
    blue: '#3B82F6',
    inputBg: '#141C2A',
    inputText: '#FFFFFF',
    placeholder: '#4B5563',
    iconBg: 'rgba(59,130,246,0.15)',
    icon: '#3B82F6',
};

const light = {
    bg: '#F8FAFC',
    border: '#E2E8F0',
    text: '#0F172A',
    muted: '#64748B',
    sectionLabel: '#64748B',
    blue: '#2563EB',
    inputBg: '#F8FAFC',
    inputText: '#0F172A',
    placeholder: '#94A3B8',
    iconBg: 'rgba(37,99,235,0.08)',
    icon: '#2563EB',
};

export default function EditProfileModal() {
    const router = useRouter();
    const { user, updateProfile } = useAuth();
    const colorScheme = useColorScheme();
    const C = colorScheme === 'dark' ? dark : light;

    const [firstName, setFirstName] = useState('');
    const [lastName, setLastName] = useState('');
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        if (user) {
            setFirstName(user.firstName ?? '');
            setLastName(user.lastName ?? '');
        }
    }, [user]);

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
            router.back();
        } catch (err: any) {
            Alert.alert('Update failed', err.message ?? 'Something went wrong. Please try again.');
        } finally {
            setSaving(false);
        }
    };

    return (
        <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
            <Stack.Screen options={{ headerShown: false }} />

            {/* Header */}
            <View style={[styles.header, { borderBottomColor: C.border }]}>
                <Pressable onPress={() => router.back()} style={styles.backRow} hitSlop={8}>
                    <ChevronLeft size={24} color={C.text} />
                    <Text style={[styles.backText, { color: C.text }]}>Back</Text>
                </Pressable>
            </View>

            <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
                <ScrollView
                    contentContainerStyle={styles.scroll}
                    keyboardShouldPersistTaps="handled"
                    showsVerticalScrollIndicator={false}
                >
                    {/* Hero */}
                    <View style={styles.hero}>
                        <View style={[styles.heroIconBox, { backgroundColor: C.iconBg }]}>
                            <User size={22} color={C.icon} />
                        </View>
                        <Text style={[styles.heroTitle, { color: C.text }]}>Profile Information</Text>
                    </View>
                    <Text style={[styles.subtitle, { color: C.muted }]}>
                        Manage your personal information
                    </Text>

                    {/* Section label */}
                    <Text style={[styles.sectionLabel, { color: C.text }]}>Full Name</Text>

                    {/* First name */}
                    <View style={styles.fieldGroup}>
                        <Text style={[styles.fieldLabel, { color: C.sectionLabel }]}>First Name</Text>
                        <TextInput
                            value={firstName}
                            onChangeText={setFirstName}
                            placeholder="First name"
                            placeholderTextColor={C.placeholder}
                            autoCapitalize="words"
                            returnKeyType="next"
                            style={[styles.input, { backgroundColor: C.inputBg, borderColor: C.border, color: C.inputText }]}
                        />
                    </View>

                    {/* Last name */}
                    <View style={styles.fieldGroup}>
                        <Text style={[styles.fieldLabel, { color: C.sectionLabel }]}>Last Name</Text>
                        <TextInput
                            value={lastName}
                            onChangeText={setLastName}
                            placeholder="Last name"
                            placeholderTextColor={C.placeholder}
                            autoCapitalize="words"
                            returnKeyType="done"
                            onSubmitEditing={handleSave}
                            style={[styles.input, { backgroundColor: C.inputBg, borderColor: C.border, color: C.inputText }]}
                        />
                    </View>

                    {/* Save */}
                    <TouchableOpacity
                        style={[styles.saveBtn, { backgroundColor: hasChanges ? C.blue : C.border }]}
                        onPress={handleSave}
                        disabled={saving || !hasChanges}
                        activeOpacity={0.85}
                    >
                        {saving
                            ? <ActivityIndicator color="#fff" />
                            : <Text style={[styles.saveBtnText, { color: hasChanges ? '#fff' : C.muted }]}>
                                Save changes
                            </Text>}
                    </TouchableOpacity>
                </ScrollView>
            </KeyboardAvoidingView>
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
    sectionLabel: {
        fontSize: 16,
        fontWeight: '700',
        marginBottom: 16,
    },
    fieldGroup: {
        marginBottom: 16,
    },
    fieldLabel: {
        fontSize: 13,
        fontWeight: '600',
        marginBottom: 6,
    },
    input: {
        borderWidth: 1,
        borderRadius: 12,
        paddingHorizontal: 16,
        paddingVertical: 14,
        fontSize: 15,
    },
    saveBtn: {
        borderRadius: 14,
        paddingVertical: 16,
        alignItems: 'center',
        marginTop: 8,
    },
    saveBtnText: {
        fontWeight: '700',
        fontSize: 16,
    },
});