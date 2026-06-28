import { useAuth } from '@/context/AuthContext';
import { Stack, useRouter } from 'expo-router';
import { CheckCircle, ChevronLeft, Eye, EyeOff, Lock } from 'lucide-react-native';
import { useState } from 'react';
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
  card: '#141C2A',
  border: '#1F2D3D',
  text: '#FFFFFF',
  muted: '#8896AA',
  label: '#CBD5E1',
  blue: '#3B82F6',
  divider: '#1F2D3D',
  inputBg: '#141C2A',
  inputText: '#FFFFFF',
  placeholder: '#4B5563',
  errorBg: 'rgba(239,68,68,0.10)',
  errorBorder: 'rgba(239,68,68,0.30)',
  errorText: '#F87171',
  confirmErrorBorder: 'rgba(239,68,68,0.50)',
  successBg: 'rgba(34,197,94,0.10)',
  successIcon: '#22c55e',
  infoBg: 'rgba(59,130,246,0.10)',
  infoIcon: '#3B82F6',
  iconBg: 'rgba(59,130,246,0.15)',
  icon: '#3B82F6',
  sectionLabel: '#8896AA',
};

const light = {
  bg: '#F8FAFC',
  card: '#FFFFFF',
  border: '#E2E8F0',
  text: '#0F172A',
  muted: '#64748B',
  label: '#374151',
  blue: '#2563eb',
  divider: '#F1F5F9',
  inputBg: '#F8FAFC',
  inputText: '#0F172A',
  placeholder: '#94A3B8',
  errorBg: '#fef2f2',
  errorBorder: '#fecaca',
  errorText: '#dc2626',
  confirmErrorBorder: '#fca5a5',
  successBg: '#f0fdf4',
  successIcon: '#22c55e',
  infoBg: '#eff6ff',
  infoIcon: '#2563eb',
  iconBg: 'rgba(37,99,235,0.08)',
  icon: '#2563EB',
  sectionLabel: '#64748B',
};

export default function UpdatePasswordScreen() {
  const router = useRouter();
  const { updatePassword, resetPassword, isLoading, user } = useAuth();
  const colorScheme = useColorScheme();
  const C = colorScheme === 'dark' ? dark : light;

  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [error, setError] = useState('');
  const [done, setDone] = useState(false);
  const [resetEmailSent, setResetEmailSent] = useState(false);
  const [sendingReset, setSendingReset] = useState(false);

  const passwordChecks = [
    { label: 'At least 8 characters', met: newPassword.length >= 8 },
    { label: 'Contains an uppercase letter', met: /[A-Z]/.test(newPassword) },
    { label: 'Contains a lowercase letter', met: /[a-z]/.test(newPassword) },
    { label: 'Contains a number', met: /[0-9]/.test(newPassword) },
  ];

  const getStrength = (pw: string) => {
    let score = 0;
    if (pw.length >= 8) score++;
    if (/[A-Z]/.test(pw)) score++;
    if (/[0-9]/.test(pw)) score++;
    if (/[^A-Za-z0-9]/.test(pw)) score++;
    return score;
  };
  const strength = getStrength(newPassword);
  const strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];
  const strengthColor = ['#e5e7eb', '#ef4444', '#f59e0b', '#3b82f6', '#22c55e'][strength];

  const handleUpdate = async () => {
    setError('');
    if (!currentPassword) { setError('Please enter your current password.'); return; }
    if (!newPassword) { setError('Please enter your new password.'); return; }
    if (!passwordChecks.every((c) => c.met)) { setError('New password must meet all requirements.'); return; }
    if (newPassword !== confirm) { setError('New passwords do not match.'); return; }
    if (newPassword === currentPassword) { setError('New password must be different from your current password.'); return; }
    try {
      await updatePassword(currentPassword, newPassword);
      setDone(true);
    } catch (e: any) {
      const msg: string = e?.message ?? '';
      const isWrongPassword =
        msg.toLowerCase().includes('incorrect password') ||
        msg.toLowerCase().includes('invalid password') ||
        msg.toLowerCase().includes('wrong password') ||
        msg.toLowerCase().includes('invalid login credentials');
      setError(isWrongPassword ? 'Current password is incorrect. Please try again.' : msg || 'Something went wrong. Please try again.');
    }
  };

  const handleForgotPassword = () => {
    const email = user?.email;
    if (!email) { Alert.alert('Error', 'No email address found on your account.'); return; }
    Alert.alert(
      'Forgot your password?',
      `We'll send a password reset link to:\n\n${email}`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Send reset link',
          onPress: async () => {
            setSendingReset(true);
            try {
              await resetPassword(email);
              setResetEmailSent(true);
            } catch (e: any) {
              Alert.alert('Error', e?.message ?? 'Could not send reset email. Please try again.');
            } finally {
              setSendingReset(false);
            }
          },
        },
      ],
    );
  };

  // ── Shared header (matches help-center pattern) ────────────────────────────
  const Header = () => (
    <View style={[styles.header, { borderBottomColor: C.border }]}>
      <Pressable onPress={() => router.back()} style={styles.backRow} hitSlop={8}>
        <ChevronLeft size={24} color={C.text} />
        <Text style={[styles.backText, { color: C.text }]}>Back</Text>
      </Pressable>
    </View>
  );

  // ── Success state ──────────────────────────────────────────────────────────
  if (done) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
        <Stack.Screen options={{ headerShown: false }} />
        <Header />
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 }}>
          <View style={{ width: 80, height: 80, borderRadius: 40, backgroundColor: C.successBg, alignItems: 'center', justifyContent: 'center', marginBottom: 24 }}>
            <CheckCircle size={40} color={C.successIcon} />
          </View>
          <Text style={{ fontSize: 24, fontWeight: '700', color: C.text, marginBottom: 10, textAlign: 'center' }}>Password updated</Text>
          <Text style={{ fontSize: 15, color: C.muted, textAlign: 'center', lineHeight: 22, marginBottom: 32 }}>
            Your password has been changed successfully.
          </Text>
          <TouchableOpacity
            style={{ backgroundColor: C.blue, borderRadius: 14, paddingVertical: 16, paddingHorizontal: 40 }}
            onPress={() => router.back()}
          >
            <Text style={{ color: '#fff', fontWeight: '700', fontSize: 16 }}>Done</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  // ── Reset email sent state ─────────────────────────────────────────────────
  if (resetEmailSent) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
        <Stack.Screen options={{ headerShown: false }} />
        <Header />
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 }}>
          <View style={{ width: 80, height: 80, borderRadius: 40, backgroundColor: C.infoBg, alignItems: 'center', justifyContent: 'center', marginBottom: 24 }}>
            <Lock size={36} color={C.infoIcon} />
          </View>
          <Text style={{ fontSize: 24, fontWeight: '700', color: C.text, marginBottom: 10, textAlign: 'center' }}>Check your email</Text>
          <Text style={{ fontSize: 15, color: C.muted, textAlign: 'center', lineHeight: 22, marginBottom: 8 }}>
            We sent a password reset link to
          </Text>
          <Text style={{ fontSize: 15, fontWeight: '600', color: C.text, marginBottom: 32 }}>{user?.email}</Text>
          <TouchableOpacity
            style={{ backgroundColor: C.blue, borderRadius: 14, paddingVertical: 16, paddingHorizontal: 40, alignItems: 'center', marginBottom: 12 }}
            onPress={() => router.back()}
          >
            <Text style={{ color: '#fff', fontWeight: '700', fontSize: 16 }}>Back to profile</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setResetEmailSent(false)}>
            <Text style={{ fontSize: 14, color: C.muted }}>Didn't get it? Try again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  // ── Main form ──────────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <Stack.Screen options={{ headerShown: false }} />
      <Header />
      <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <ScrollView
          contentContainerStyle={styles.scroll}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Hero — matches help-center */}
          <View style={styles.hero}>
            <View style={[styles.heroIconBox, { backgroundColor: C.iconBg }]}>
              <Lock size={22} color={C.icon} />
            </View>
            <Text style={[styles.heroTitle, { color: C.text }]}>Security Settings</Text>
          </View>
          <Text style={[styles.subtitle, { color: C.muted }]}>
            Manage your password and account security
          </Text>

          {/* Section label */}
          <Text style={[styles.sectionLabel, { color: C.text }]}>Change Password</Text>

          {/* Current password */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.fieldLabel, { color: C.sectionLabel }]}>Current Password</Text>
            <View style={[styles.inputRow, { borderColor: C.border, backgroundColor: C.inputBg }]}>
              <TextInput
                style={[styles.input, { color: C.inputText }]}
                placeholder="Enter current password"
                placeholderTextColor={C.placeholder}
                value={currentPassword}
                onChangeText={setCurrentPassword}
                secureTextEntry={!showCurrent}
                autoComplete="current-password"
                autoFocus
              />
              <TouchableOpacity onPress={() => setShowCurrent(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                {showCurrent ? <EyeOff size={18} color={C.placeholder} /> : <Eye size={18} color={C.placeholder} />}
              </TouchableOpacity>
            </View>
            <TouchableOpacity
              onPress={handleForgotPassword}
              disabled={sendingReset}
              style={{ alignSelf: 'flex-end', marginTop: 8 }}
              activeOpacity={0.7}
            >
              {sendingReset
                ? <ActivityIndicator size="small" color={C.blue} />
                : <Text style={{ fontSize: 13, color: C.blue, fontWeight: '600' }}>Forgot password?</Text>}
            </TouchableOpacity>
          </View>

          {/* Divider */}
          <View style={[styles.divider, { backgroundColor: C.divider }]} />

          {/* New password */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.fieldLabel, { color: C.sectionLabel }]}>New Password</Text>
            <View style={[styles.inputRow, { borderColor: C.border, backgroundColor: C.inputBg }]}>
              <TextInput
                style={[styles.input, { color: C.inputText }]}
                placeholder="Min. 8 characters"
                placeholderTextColor={C.placeholder}
                value={newPassword}
                onChangeText={setNewPassword}
                secureTextEntry={!showNew}
                autoComplete="new-password"
              />
              <TouchableOpacity onPress={() => setShowNew(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                {showNew ? <EyeOff size={18} color={C.placeholder} /> : <Eye size={18} color={C.placeholder} />}
              </TouchableOpacity>
            </View>

            {newPassword.length > 0 && (
              <View style={{ marginTop: 8 }}>
                <View style={{ flexDirection: 'row', gap: 4, marginBottom: 4 }}>
                  {[1, 2, 3, 4].map(i => (
                    <View key={i} style={{ flex: 1, height: 3, borderRadius: 2, backgroundColor: i <= strength ? strengthColor : C.border }} />
                  ))}
                </View>
                <Text style={{ fontSize: 12, color: strengthColor, fontWeight: '600' }}>{strengthLabel}</Text>
              </View>
            )}

            {newPassword.length > 0 && !passwordChecks.every(c => c.met) && (
              <View style={{ flexDirection: 'column', gap: 6, marginTop: 10 }}>
                {passwordChecks.map(({ label, met }) => (
                  <View
                    key={label}
                    style={{
                      flexDirection: 'row', alignItems: 'center', gap: 7,
                      paddingHorizontal: 10, paddingVertical: 6, borderRadius: 20, borderWidth: 1,
                      alignSelf: 'flex-start',
                      backgroundColor: met ? 'rgba(34,197,94,0.08)' : C.inputBg,
                      borderColor: met ? 'rgba(34,197,94,0.5)' : C.border,
                    }}
                  >
                    <View style={{ width: 7, height: 7, borderRadius: 4, borderWidth: 1.5, backgroundColor: met ? '#22c55e' : 'transparent', borderColor: met ? '#22c55e' : C.placeholder }} />
                    <Text style={{ fontSize: 12, fontWeight: '500', color: met ? '#22c55e' : C.muted }}>{label}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>

          {/* Confirm password */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.fieldLabel, { color: C.sectionLabel }]}>Confirm New Password</Text>
            <View style={[styles.inputRow, {
              borderColor: confirm && confirm !== newPassword ? C.confirmErrorBorder : C.border,
              backgroundColor: C.inputBg,
            }]}>
              <TextInput
                style={[styles.input, { color: C.inputText }]}
                placeholder="Re-enter new password"
                placeholderTextColor={C.placeholder}
                value={confirm}
                onChangeText={setConfirm}
                secureTextEntry={!showConfirm}
                autoComplete="new-password"
              />
              <TouchableOpacity onPress={() => setShowConfirm(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                {showConfirm ? <EyeOff size={18} color={C.placeholder} /> : <Eye size={18} color={C.placeholder} />}
              </TouchableOpacity>
            </View>
            {confirm.length > 0 && confirm !== newPassword && (
              <Text style={{ fontSize: 12, color: '#ef4444', marginTop: 4 }}>Passwords don't match</Text>
            )}
          </View>

          {/* Error banner */}
          {error ? (
            <View style={{ backgroundColor: C.errorBg, borderWidth: 1, borderColor: C.errorBorder, borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12, marginBottom: 16 }}>
              <Text style={{ fontSize: 14, color: C.errorText, lineHeight: 20 }}>{error}</Text>
            </View>
          ) : null}

          {/* Submit */}
          <TouchableOpacity
            style={[styles.submitBtn, { backgroundColor: C.blue, opacity: isLoading ? 0.7 : 1 }]}
            onPress={handleUpdate}
            disabled={isLoading}
            activeOpacity={0.85}
          >
            <Lock size={16} color="#fff" />
            {isLoading
              ? <ActivityIndicator color="#fff" />
              : <Text style={styles.submitText}>Update Password</Text>}
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
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 12,
    paddingHorizontal: 14,
  },
  input: {
    flex: 1,
    paddingVertical: 14,
    fontSize: 15,
  },
  divider: {
    height: 1,
    marginBottom: 16,
  },
  submitBtn: {
    flexDirection: 'row',
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 8,
  },
  submitText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 16,
  },
});