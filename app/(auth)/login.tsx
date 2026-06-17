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
import { Mail, Lock, Eye, EyeOff, ShieldCheck } from 'lucide-react-native';
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
};

export default function LoginScreen() {
  const router = useRouter();
  const { login, isLoading } = useAuth();
  const colorScheme = useColorScheme();
  const C = colorScheme === 'dark' ? dark : light;

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    setError('');
    try {
      await login(email.trim(), password);
      router.replace('/(tabs)');
    } catch (e: any) {
      const msg = e?.message || 'Something went wrong. Please try again.';
      if (msg.toLowerCase().includes('email not confirmed')) {
        router.push({ pathname: '/(auth)/verify-email', params: { email: email.trim() } });
      } else if (msg.toLowerCase().includes('invalid login')) {
        setError('Incorrect email or password.');
      } else {
        setError(msg);
      }
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
              <Text style={[s.title, { color: C.text }]}>Welcome back.</Text>
              <Text style={s.subtitle}>Sign in to continue finding great deals</Text>
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
            <View style={{ marginBottom: 8 }}>
              <Text style={s.label}>Password</Text>
              <View style={s.inputWrap}>
                <Lock size={16} color={C.muted} />
                <TextInput
                  style={s.input}
                  placeholder="••••••••"
                  placeholderTextColor={C.placeholder}
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry={!showPassword}
                  autoComplete="password"
                />
                <TouchableOpacity onPress={() => setShowPassword(v => !v)} hitSlop={8}>
                  {showPassword
                    ? <EyeOff size={16} color={C.muted} />
                    : <Eye size={16} color={C.muted} />
                  }
                </TouchableOpacity>
              </View>
            </View>

            {/* Forgot password */}
            <Link href="/(auth)/forgot-password" asChild>
              <TouchableOpacity style={{ alignSelf: 'flex-end', marginBottom: 20 }}>
                <Text style={s.link}>Forgot password?</Text>
              </TouchableOpacity>
            </Link>

            {/* Error */}
            {error ? (
              <View style={s.errorBox}>
                <Text style={s.errorText}>{error}</Text>
              </View>
            ) : null}

            {/* Sign In */}
            <TouchableOpacity
              style={[s.primaryBtn, isLoading && s.dimmed]}
              onPress={handleLogin}
              disabled={isLoading}
              activeOpacity={0.9}
            >
              {isLoading
                ? <ActivityIndicator color={C.btnText} />
                : <Text style={s.primaryBtnText}>Sign in</Text>
              }
            </TouchableOpacity>

            {/* Footer */}
            <View style={s.footerRow}>
              <Text style={s.footerText}>Don't have an account? </Text>
              <Link href="/(auth)/register" asChild>
                <TouchableOpacity>
                  <Text style={s.link}>Sign up</Text>
                </TouchableOpacity>
              </Link>
            </View>

            {/* Trust badges */}
            <View style={s.trustRow}>
              <TrustBadge icon={<Lock size={15} color={C.muted} />} label="Secure login" mutedColor={C.muted} />
              <TrustBadge icon={<ShieldCheck size={15} color={C.muted} />} label="Data protected" mutedColor={C.muted} />
              <TrustBadge icon={<EyeOff size={15} color={C.muted} />} label="No tracking" mutedColor={C.muted} />
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function TrustBadge({ icon, label, mutedColor }: { icon: React.ReactNode; label: string; mutedColor: string }) {
  return (
    <View style={{ alignItems: 'center', gap: 5 }}>
      {icon}
      <Text style={{ fontSize: 11, color: mutedColor }}>{label}</Text>
    </View>
  );
}

function makeStyles(C: typeof dark) {
  return StyleSheet.create({
    safe: { flex: 1 },
    container: { flex: 1, paddingHorizontal: 24, paddingTop: 20, paddingBottom: 32 },
    logo: { fontSize: 20, fontWeight: '700', marginBottom: 36 },
    title: { fontSize: 34, fontWeight: '800', marginBottom: 8, letterSpacing: -0.5 },
    subtitle: { fontSize: 15, color: C.muted, lineHeight: 22 },

    dimmed: { opacity: 0.55 },

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
      paddingHorizontal: 16,
      gap: 12,
    },
    input: {
      flex: 1,
      fontSize: 15,
      color: C.text,
      paddingVertical: 14,
      paddingHorizontal: 0,
    },

    link: { fontSize: 14, color: C.blue, fontWeight: '600' },

    errorBox: {
      backgroundColor: 'rgba(239,68,68,0.1)',
      borderWidth: 1,
      borderColor: 'rgba(239,68,68,0.3)',
      borderRadius: 10,
      padding: 12,
      marginBottom: 16,
    },
    errorText: { fontSize: 13, color: '#f87171', textAlign: 'center' },

    primaryBtn: {
      backgroundColor: C.btnBg,
      borderRadius: 14,
      paddingVertical: 16,
      alignItems: 'center',
      marginBottom: 24,
    },
    primaryBtnText: { fontSize: 16, fontWeight: '700', color: C.btnText },

    footerRow: { flexDirection: 'row', justifyContent: 'center', marginBottom: 40 },
    footerText: { fontSize: 14, color: C.muted },

    trustRow: { flexDirection: 'row', justifyContent: 'center', gap: 36 },
  });
}
