import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'expo-router';
import { ArrowLeft, CheckCircle, Eye, EyeOff, Lock } from 'lucide-react-native';
import { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function UpdatePasswordScreen() {
  console.log('UpdatePasswordScreen mounted');
  const router = useRouter();
  const { updatePassword, resetPassword, isLoading, user } = useAuth();

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

  // Derive strength: 0–4
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
    if (!currentPassword) {
      setError('Please enter your current password.');
      return;
    }
    if (!newPassword) {
      setError('Please enter your new password.');
      return;
    }
    if (!passwordChecks.every((c: { label: string; met: boolean }) => c.met)) {
      setError('New password must meet all requirements');
      return;
    }
    if (newPassword !== confirm) {
      setError('New passwords do not match.');
      return;
    }
    if (newPassword === currentPassword) {
      setError('New password must be different from your current password.');
      return;
    }
    try {
      await updatePassword(currentPassword, newPassword);
      setDone(true);
    } catch (e: any) {
      // Surface wrong current-password errors clearly
      const msg: string = e?.message ?? '';
      console.log('UpdatePassword raw error:', msg);

      const isWrongPassword =
        msg.toLowerCase().includes('incorrect password') ||
        msg.toLowerCase().includes('invalid password') ||
        msg.toLowerCase().includes('wrong password') ||
        msg.toLowerCase().includes('invalid login credentials');

      if (isWrongPassword) {
        setError('Current password is incorrect. Please try again.');
      } else {
        setError(msg || 'Something went wrong. Please try again.');
      }
    }
  };

  const handleForgotPassword = () => {
    const email = user?.email;
    if (!email) {
      Alert.alert('Error', 'No email address found on your account.');
      return;
    }
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

  // ── Success state ──────────────────────────────────────────────────────────
  if (done) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: '#fff' }}>
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 }}>
          <View style={{
            width: 80, height: 80,
            borderRadius: 40,
            backgroundColor: '#f0fdf4',
            alignItems: 'center', justifyContent: 'center',
            marginBottom: 24,
          }}>
            <CheckCircle size={40} color="#22c55e" />
          </View>
          <Text style={{ fontSize: 24, fontWeight: '700', color: '#111827', marginBottom: 10, textAlign: 'center' }}>
            Password updated
          </Text>
          <Text style={{ fontSize: 15, color: '#6b7280', textAlign: 'center', lineHeight: 22, marginBottom: 32 }}>
            Your password has been changed successfully.
          </Text>
          <TouchableOpacity
            style={{ backgroundColor: '#2563eb', borderRadius: 14, paddingVertical: 16, paddingHorizontal: 40, alignItems: 'center' }}
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
      <SafeAreaView style={{ flex: 1, backgroundColor: '#fff' }}>
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 }}>
          <View style={{
            width: 80, height: 80,
            borderRadius: 40,
            backgroundColor: '#eff6ff',
            alignItems: 'center', justifyContent: 'center',
            marginBottom: 24,
          }}>
            <Lock size={36} color="#2563eb" />
          </View>
          <Text style={{ fontSize: 24, fontWeight: '700', color: '#111827', marginBottom: 10, textAlign: 'center' }}>
            Check your email
          </Text>
          <Text style={{ fontSize: 15, color: '#6b7280', textAlign: 'center', lineHeight: 22, marginBottom: 8 }}>
            We sent a password reset link to
          </Text>
          <Text style={{ fontSize: 15, fontWeight: '600', color: '#111827', marginBottom: 32 }}>
            {user?.email}
          </Text>
          <TouchableOpacity
            style={{ backgroundColor: '#2563eb', borderRadius: 14, paddingVertical: 16, paddingHorizontal: 40, alignItems: 'center', marginBottom: 12 }}
            onPress={() => router.back()}
          >
            <Text style={{ color: '#fff', fontWeight: '700', fontSize: 16 }}>Back to profile</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setResetEmailSent(false)}>
            <Text style={{ fontSize: 14, color: '#6b7280' }}>Didn't get it? Try again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  // ── Main form ──────────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#fff' }}>
      <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, paddingHorizontal: 24, paddingBottom: 40 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Back button */}
          <TouchableOpacity
            onPress={() => router.back()}
            style={{ marginTop: 12, marginBottom: 28, flexDirection: 'row', alignItems: 'center', gap: 6, alignSelf: 'flex-start' }}
            activeOpacity={0.7}
          >
            <ArrowLeft size={20} color="#374151" />
            <Text style={{ fontSize: 15, color: '#374151', fontWeight: '500' }}>Back</Text>
          </TouchableOpacity>

          {/* Heading */}
          <View style={{ marginBottom: 28 }}>
            <Text style={{ fontSize: 28, fontWeight: '800', color: '#111827', marginBottom: 6 }}>
              Change password
            </Text>
            <Text style={{ fontSize: 15, color: '#6b7280', lineHeight: 22 }}>
              Enter your current password to make a change.
            </Text>
          </View>

          {/* Current password */}
          <View style={{ marginBottom: 16 }}>
            <Text style={{ fontSize: 13, fontWeight: '600', color: '#374151', marginBottom: 6 }}>
              Current password
            </Text>
            <View style={{ flexDirection: 'row', alignItems: 'center', borderWidth: 1, borderColor: '#d1d5db', borderRadius: 12, backgroundColor: '#f9fafb', paddingHorizontal: 14 }}>
              <TextInput
                style={{ flex: 1, paddingVertical: 14, fontSize: 15, color: '#111827' }}
                placeholder="Enter current password"
                placeholderTextColor="#9ca3af"
                value={currentPassword}
                onChangeText={setCurrentPassword}
                secureTextEntry={!showCurrent}
                autoComplete="current-password"
                autoFocus
              />
              <TouchableOpacity onPress={() => setShowCurrent(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                {showCurrent
                  ? <EyeOff size={18} color="#9ca3af" />
                  : <Eye size={18} color="#9ca3af" />}
              </TouchableOpacity>
            </View>

            {/* Forgot password link */}
            <TouchableOpacity
              onPress={handleForgotPassword}
              disabled={sendingReset}
              style={{ alignSelf: 'flex-end', marginTop: 8 }}
              activeOpacity={0.7}
            >
              {sendingReset
                ? <ActivityIndicator size="small" color="#2563eb" />
                : <Text style={{ fontSize: 13, color: '#2563eb', fontWeight: '600' }}>Forgot password?</Text>}
            </TouchableOpacity>
          </View>

          {/* Divider */}
          <View style={{ height: 1, backgroundColor: '#f3f4f6', marginBottom: 16 }} />

          {/* New password */}
          <View style={{ marginBottom: 16 }}>
            <Text style={{ fontSize: 13, fontWeight: '600', color: '#374151', marginBottom: 6 }}>
              New password
            </Text>
            <View style={{ flexDirection: 'row', alignItems: 'center', borderWidth: 1, borderColor: '#d1d5db', borderRadius: 12, backgroundColor: '#f9fafb', paddingHorizontal: 14 }}>
              <TextInput
                style={{ flex: 1, paddingVertical: 14, fontSize: 15, color: '#111827' }}
                placeholder="Min. 8 characters"
                placeholderTextColor="#9ca3af"
                value={newPassword}
                onChangeText={setNewPassword}
                secureTextEntry={!showNew}
                autoComplete="new-password"
              />
              <TouchableOpacity onPress={() => setShowNew(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                {showNew
                  ? <EyeOff size={18} color="#9ca3af" />
                  : <Eye size={18} color="#9ca3af" />}
              </TouchableOpacity>
            </View>

            {/* Strength bar */}
            {newPassword.length > 0 && (
              <View style={{ marginTop: 8 }}>
                <View style={{ flexDirection: 'row', gap: 4, marginBottom: 4 }}>
                  {[1, 2, 3, 4].map(i => (
                    <View
                      key={i}
                      style={{
                        flex: 1, height: 3, borderRadius: 2,
                        backgroundColor: i <= strength ? strengthColor : '#e5e7eb',
                      }}
                    />
                  ))}
                </View>
                <Text style={{ fontSize: 12, color: strengthColor, fontWeight: '600' }}>
                  {strengthLabel}
                </Text>
              </View>
            )}
            {/* Password requirement chips */}
            {newPassword.length > 0 && !passwordChecks.every(c => c.met) && (
              <View style={{ flexDirection: 'column', gap: 6, marginTop: 10 }}>
                {passwordChecks.map(({ label, met }) => (
                  <View
                    key={label}
                    style={{
                      flexDirection: 'row',
                      alignItems: 'center',
                      gap: 7,
                      paddingHorizontal: 10,
                      paddingVertical: 6,
                      borderRadius: 20,
                      borderWidth: 1,
                      alignSelf: 'flex-start',
                      backgroundColor: met ? 'rgba(34,197,94,0.08)' : '#f9fafb',
                      borderColor: met ? 'rgba(34,197,94,0.5)' : '#d1d5db',
                    }}
                  >
                    <View
                      style={{
                        width: 7,
                        height: 7,
                        borderRadius: 4,
                        borderWidth: 1.5,
                        backgroundColor: met ? '#22c55e' : 'transparent',
                        borderColor: met ? '#22c55e' : '#9ca3af',
                      }}
                    />
                    <Text style={{ fontSize: 12, fontWeight: '500', color: met ? '#22c55e' : '#6b7280' }}>
                      {label}
                    </Text>
                  </View>
                ))}
              </View>
            )}
          </View>

          {/* Confirm password */}
          <View style={{ marginBottom: 20 }}>
            <Text style={{ fontSize: 13, fontWeight: '600', color: '#374151', marginBottom: 6 }}>
              Confirm new password
            </Text>
            <View style={{
              flexDirection: 'row', alignItems: 'center',
              borderWidth: 1,
              borderColor: confirm && confirm !== newPassword ? '#fca5a5' : '#d1d5db',
              borderRadius: 12, backgroundColor: '#f9fafb', paddingHorizontal: 14,
            }}>
              <TextInput
                style={{ flex: 1, paddingVertical: 14, fontSize: 15, color: '#111827' }}
                placeholder="Re-enter new password"
                placeholderTextColor="#9ca3af"
                value={confirm}
                onChangeText={setConfirm}
                secureTextEntry={!showConfirm}
                autoComplete="new-password"
              />
              <TouchableOpacity onPress={() => setShowConfirm(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                {showConfirm
                  ? <EyeOff size={18} color="#9ca3af" />
                  : <Eye size={18} color="#9ca3af" />}
              </TouchableOpacity>
            </View>
            {confirm.length > 0 && confirm !== newPassword && (
              <Text style={{ fontSize: 12, color: '#ef4444', marginTop: 4 }}>Passwords don't match</Text>
            )}
          </View>

          {/* Error banner */}
          {error ? (
            <View style={{
              backgroundColor: '#fef2f2', borderWidth: 1, borderColor: '#fecaca',
              borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12, marginBottom: 16,
            }}>
              <Text style={{ fontSize: 14, color: '#dc2626', lineHeight: 20 }}>{error}</Text>
            </View>
          ) : null}

          {/* Submit */}
          <TouchableOpacity
            style={{
              backgroundColor: '#2563eb',
              borderRadius: 14,
              paddingVertical: 16,
              alignItems: 'center',
              opacity: isLoading ? 0.7 : 1,
            }}
            onPress={handleUpdate}
            disabled={isLoading}
            activeOpacity={0.85}
          >
            {isLoading
              ? <ActivityIndicator color="#fff" />
              : <Text style={{ color: '#fff', fontWeight: '700', fontSize: 16 }}>Update password</Text>}
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}