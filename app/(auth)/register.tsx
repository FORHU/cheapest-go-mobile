import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
} from 'react-native';
import { Link, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import AntDesign from '@expo/vector-icons/AntDesign';
import { User, Mail, Lock, Eye, EyeOff } from 'lucide-react-native';
import { useAuth } from '@/context/AuthContext';
import { useColorScheme } from '@/hooks/useColorScheme';

const dark = {
  bg: '#0B1018',
  inputBg: '#141C2A',
  border: '#1F2D3D',
  text: '#FFFFFF',
  muted: '#8896AA',
  label: '#B8C4D0',
  blue: '#3B82F6',
  btnBg: '#EEF0F3',
  btnText: '#0F172A',
  placeholder: '#3D4D5E',
  divider: '#1A2535',
  green: '#22c55e',
};

const light = {
  bg: '#F8FAFC',
  inputBg: '#FFFFFF',
  border: '#E2E8F0',
  text: '#0F172A',
  muted: '#64748B',
  label: '#475569',
  blue: '#2563EB',
  btnBg: '#0F172A',
  btnText: '#FFFFFF',
  placeholder: '#94A3B8',
  divider: '#E2E8F0',
  green: '#16a34a',
};

export default function RegisterScreen() {
  const router = useRouter();
  const { register, signInWithGoogle, isLoading } = useAuth();
  const colorScheme = useColorScheme();
  const C = colorScheme === 'dark' ? dark : light;

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [error, setError] = useState('');
  const [googleLoading, setGoogleLoading] = useState(false);

  const passwordChecks = [
    { label: '8+ chars', met: password.length >= 8 },
    { label: 'Uppercase', met: /[A-Z]/.test(password) },
    { label: 'Number', met: /[0-9]/.test(password) },
  ];

  const handleRegister = async () => {
    setError('');
    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }
    try {
      const { needsEmailVerification } = await register({
        firstName, lastName, email: email.trim(), password,
      });
      if (needsEmailVerification) {
        router.replace({ pathname: '/(auth)/verify-email', params: { email: email.trim() } });
      } else {
        router.replace('/(tabs)');
      }
    } catch (e: any) {
      const msg = e?.message || 'Something went wrong. Please try again.';
      if (msg.toLowerCase().includes('already registered')) {
        setError('An account with this email already exists.');
      } else if (e?.errors) {
        setError(e.errors[0]?.message || msg);
      } else {
        setError(msg);
      }
    }
  };

  const handleGoogleSignUp = async () => {
    setError('');
    setGoogleLoading(true);
    try {
      await signInWithGoogle();
      router.replace('/(tabs)');
    } catch (e: any) {
      setError(e?.message || 'Google sign-up failed. Please try again.');
    } finally {
      setGoogleLoading(false);
    }
  };

  const s = makeStyles(C);

  return (
    <SafeAreaView style={[s.safe, { backgroundColor: C.bg }]}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1 }}
          keyboardShouldPersistTaps="handled"
        >
          <View style={s.container}>
            {/* Logo */}
            <Text style={[s.logo, { color: C.text }]}>
              Cheapest<Text style={{ color: C.blue }}>Go</Text>
            </Text>

            {/* Header */}
            <View style={{ marginBottom: 32 }}>
              <Text style={[s.title, { color: C.text }]}>{'Create your\naccount.'}</Text>
              <Text style={s.subtitle}>Start finding the best deals today</Text>
            </View>

            {/* Google */}
            <TouchableOpacity
              style={[s.googleBtn, (googleLoading || isLoading) && s.dimmed]}
              onPress={handleGoogleSignUp}
              disabled={googleLoading || isLoading}
              activeOpacity={0.8}
            >
              {googleLoading ? (
                <ActivityIndicator color={C.white} size="small" />
              ) : (
                <>
                  <AntDesign name="google" size={20} color="#4285F4" />
                  <Text style={s.googleText}>Sign up with Google</Text>
                </>
              )}
            </TouchableOpacity>

            {/* Divider */}
            <View style={s.dividerRow}>
              <View style={s.dividerLine} />
              <Text style={s.dividerText}>or sign up with email</Text>
              <View style={s.dividerLine} />
            </View>

            {/* Name row */}
            <View style={{ flexDirection: 'row', gap: 12, marginBottom: 16 }}>
              <View style={{ flex: 1 }}>
                <Text style={s.label}>First Name</Text>
                <View style={s.inputWrap}>
                  <User size={15} color={C.muted} />
                  <TextInput
                    style={s.input}
                    placeholder="John"
                    placeholderTextColor={C.placeholder}
                    value={firstName}
                    onChangeText={setFirstName}
                    autoCapitalize="words"
                    autoComplete="given-name"
                  />
                </View>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={s.label}>Last Name</Text>
                <View style={s.inputWrap}>
                  <User size={15} color={C.muted} />
                  <TextInput
                    style={s.input}
                    placeholder="Doe"
                    placeholderTextColor={C.placeholder}
                    value={lastName}
                    onChangeText={setLastName}
                    autoCapitalize="words"
                    autoComplete="family-name"
                  />
                </View>
              </View>
            </View>

            {/* Email */}
            <View style={{ marginBottom: 16 }}>
              <Text style={s.label}>Email</Text>
              <View style={s.inputWrap}>
                <Mail size={16} color={C.muted} />
                <TextInput
                  style={s.input}
                  placeholder="you@example.com"
                  placeholderTextColor={C.placeholder}
                  value={email}
                  onChangeText={setEmail}
                  autoCapitalize="none"
                  keyboardType="email-address"
                  autoComplete="email"
                />
              </View>
            </View>

            {/* Password */}
            <View style={{ marginBottom: 16 }}>
              <Text style={s.label}>Password</Text>
              <View style={[s.inputWrap, { marginBottom: 10 }]}>
                <Lock size={16} color={C.muted} />
                <TextInput
                  style={s.input}
                  placeholder="Min. 8 characters"
                  placeholderTextColor={C.placeholder}
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry={!showPassword}
                  autoComplete="new-password"
                />
                <TouchableOpacity onPress={() => setShowPassword(v => !v)} hitSlop={8}>
                  {showPassword
                    ? <EyeOff size={16} color={C.muted} />
                    : <Eye size={16} color={C.muted} />
                  }
                </TouchableOpacity>
              </View>

              {/* Validation chips */}
              <View style={{ flexDirection: 'row', gap: 8 }}>
                {passwordChecks.map(({ label, met }) => (
                  <View key={label} style={[s.chip, met && s.chipMet]}>
                    <View style={[s.chipDot, met && s.chipDotMet]} />
                    <Text style={[s.chipText, met && s.chipTextMet]}>{label}</Text>
                  </View>
                ))}
              </View>
            </View>

            {/* Confirm Password */}
            <View style={{ marginBottom: 8 }}>
              <Text style={s.label}>Confirm Password</Text>
              <View style={s.inputWrap}>
                <Lock size={16} color={C.muted} />
                <TextInput
                  style={s.input}
                  placeholder="Repeat password"
                  placeholderTextColor={C.placeholder}
                  value={confirmPassword}
                  onChangeText={setConfirmPassword}
                  secureTextEntry={!showConfirm}
                  autoComplete="new-password"
                />
                <TouchableOpacity onPress={() => setShowConfirm(v => !v)} hitSlop={8}>
                  {showConfirm
                    ? <EyeOff size={16} color={C.muted} />
                    : <Eye size={16} color={C.muted} />
                  }
                </TouchableOpacity>
              </View>
            </View>

            {/* Error */}
            {error ? (
              <View style={s.errorBox}>
                <Text style={s.errorText}>{error}</Text>
              </View>
            ) : null}

            {/* Create account */}
            <TouchableOpacity
              style={[s.primaryBtn, isLoading && s.dimmed]}
              onPress={handleRegister}
              disabled={isLoading}
              activeOpacity={0.9}
            >
              {isLoading
                ? <ActivityIndicator color={C.btnText} />
                : <Text style={s.primaryBtnText}>Create account</Text>
              }
            </TouchableOpacity>

            {/* Footer */}
            <View style={s.footerRow}>
              <Text style={s.footerText}>Already have an account? </Text>
              <Link href="/(auth)/login" asChild>
                <TouchableOpacity>
                  <Text style={s.link}>Sign in</Text>
                </TouchableOpacity>
              </Link>
            </View>

            {/* Legal */}
            <Text style={s.legal}>
              By creating an account you agree to our{' '}
              <Text style={s.link}>Terms of Service</Text>
              {' '}and{' '}
              <Text style={s.link}>Privacy Policy</Text>
            </Text>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function makeStyles(C: typeof dark) {
  return StyleSheet.create({
    safe: { flex: 1 },
    container: { flex: 1, paddingHorizontal: 24, paddingTop: 20, paddingBottom: 32 },
    logo: { fontSize: 20, fontWeight: '700', marginBottom: 32 },
    title: { fontSize: 34, fontWeight: '800', marginBottom: 8, letterSpacing: -0.5 },
    subtitle: { fontSize: 15, color: C.muted, lineHeight: 22 },

    googleBtn: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 12,
      backgroundColor: C.inputBg,
      borderWidth: 1,
      borderColor: C.border,
      borderRadius: 14,
      paddingVertical: 15,
      marginBottom: 20,
    },
    googleText: { fontSize: 15, fontWeight: '600', color: C.text },
    dimmed: { opacity: 0.55 },

    dividerRow: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 24 },
    dividerLine: { flex: 1, height: 1, backgroundColor: C.divider },
    dividerText: { fontSize: 13, color: C.muted },

    label: {
      fontSize: 11,
      fontWeight: '600',
      color: C.label,
      letterSpacing: 0.8,
      textTransform: 'uppercase',
      marginBottom: 8,
    },
    inputWrap: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: C.inputBg,
      borderWidth: 1,
      borderColor: C.border,
      borderRadius: 12,
      paddingHorizontal: 14,
      gap: 10,
    },
    input: {
      flex: 1,
      fontSize: 15,
      color: C.text,
      paddingVertical: 13,
      paddingHorizontal: 0,
    },

    chip: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 5,
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
      backgroundColor: C.inputBg,
      borderWidth: 1,
      borderColor: C.border,
    },
    chipMet: {
      borderColor: 'rgba(34,197,94,0.5)',
      backgroundColor: 'rgba(34,197,94,0.08)',
    },
    chipDot: {
      width: 7,
      height: 7,
      borderRadius: 4,
      borderWidth: 1.5,
      borderColor: C.muted,
    },
    chipDotMet: { backgroundColor: C.green, borderColor: C.green },
    chipText: { fontSize: 12, color: C.muted, fontWeight: '500' },
    chipTextMet: { color: C.green },

    link: { fontSize: 14, color: C.blue, fontWeight: '600' },

    errorBox: {
      backgroundColor: 'rgba(239,68,68,0.1)',
      borderWidth: 1,
      borderColor: 'rgba(239,68,68,0.3)',
      borderRadius: 10,
      padding: 12,
      marginVertical: 8,
    },
    errorText: { fontSize: 13, color: '#f87171', textAlign: 'center' },

    primaryBtn: {
      backgroundColor: C.btnBg,
      borderRadius: 14,
      paddingVertical: 16,
      alignItems: 'center',
      marginTop: 16,
      marginBottom: 24,
    },
    primaryBtnText: { fontSize: 16, fontWeight: '700', color: C.btnText },

    footerRow: { flexDirection: 'row', justifyContent: 'center', marginBottom: 20 },
    footerText: { fontSize: 14, color: C.muted },

    legal: { fontSize: 12, color: C.muted, textAlign: 'center', lineHeight: 18 },
  });
}
