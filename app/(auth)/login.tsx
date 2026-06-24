import LogoSvg from '@/assets/images/logo.svg';
import { useAuth } from '@/context/AuthContext';
import { useColorScheme } from '@/hooks/useColorScheme';
import { Link, useRouter } from 'expo-router';
import {
  AlertCircle,
  ArrowLeft,
  CheckCircle,
  Eye,
  EyeOff,
} from 'lucide-react-native';
import { useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Animated,
  Dimensions,
  Easing,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Svg, {
  Defs,
  Line,
  Path,
  Pattern,
  RadialGradient,
  Rect,
  Stop,
} from 'react-native-svg';

const { width: SW, height: SH } = Dimensions.get('window');

// ─── Palette ──────────────────────────────────────────────────────────────────
const DARK = {
  safe: '#060d1a',
  bg: '#0b1329',
  cardBg: '#0c1424',
  cardBorder: '#172036',
  inputBg: '#070e1c',
  inputBorder: '#1a2640',
  inputBorderFocus: '#3b82f6',
  inputBorderErr: '#dc2626',
  inputBgErr: '#0f0808',
  label: '#64748b',
  inputText: '#e2e8f0',
  placeholder: '#2d3a52',
  title: '#f1f5f9',
  subtitle: '#4a5568',
  forgot: '#3b82f6',
  fieldErr: '#ef4444',
  bannerErrBg: '#160808',
  bannerErrBorder: '#7f1d1d',
  bannerErrText: '#f87171',
  successBg: '#061410',
  successBorder: '#064e3b',
  successText: '#34d399',
  submitBg: '#2563eb',
  submitText: '#ffffff',
  backBg: 'rgba(6,13,26,0.85)',
  backBorder: '#172036',
  backIcon: '#64748b',
  signUpPrompt: '#475569',
  signUpLink: '#3b82f6',
  divider: '#111c30',
  gridLine: 'rgba(255,255,255,0.03)',
  sparkle: '#60a5fa',
  sparkleGlow: 'rgba(96,165,250,0.35)',
  topBarBg: '#0b1329',
};

const LIGHT = {
  safe: '#f0f6ff',
  bg: '#f8fafc',
  cardBg: '#ffffff',
  cardBorder: '#e2e8f0',
  inputBg: '#f8fafc',
  inputBorder: '#e2e8f0',
  inputBorderFocus: '#2563eb',
  inputBorderErr: '#ef4444',
  inputBgErr: '#fff5f5',
  label: '#64748b',
  inputText: '#0f172a',
  placeholder: '#94a3b8',
  title: '#0f172a',
  subtitle: '#64748b',
  forgot: '#2563eb',
  fieldErr: '#ef4444',
  bannerErrBg: '#fef2f2',
  bannerErrBorder: '#fecaca',
  bannerErrText: '#dc2626',
  successBg: '#f0fdf4',
  successBorder: '#bbf7d0',
  successText: '#15803d',
  submitBg: '#2563eb',
  submitText: '#ffffff',
  backBg: 'rgba(255,255,255,0.92)',
  backBorder: '#e2e8f0',
  backIcon: '#475569',
  signUpPrompt: '#94a3b8',
  signUpLink: '#2563eb',
  divider: '#f1f5f9',
  gridLine: 'rgba(37,99,235,0.045)',
  sparkle: '#3b82f6',
  sparkleGlow: 'rgba(59,130,246,0.18)',
  topBarBg: '#f8fafc',
};

// ─── Animated Drift Grid ──────────────────────────────────────────────────────
const GRID_SIZE = 40;
const EXTRA = GRID_SIZE * 3;

function DriftGrid({ color }: { color: string }) {
  const anim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.loop(
      Animated.timing(anim, {
        toValue: GRID_SIZE,
        duration: 4000,
        easing: Easing.linear,
        useNativeDriver: true,
      })
    ).start();
  }, []);

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        StyleSheet.absoluteFill,
        {
          left: -EXTRA,
          top: -EXTRA,
          width: SW + EXTRA * 2,
          height: SH + EXTRA * 2,
          transform: [{ translateX: anim }, { translateY: anim }],
        },
      ]}
    >
      <Svg width="100%" height="100%">
        <Defs>
          <Pattern
            id="cgrid"
            x="0"
            y="0"
            width={GRID_SIZE}
            height={GRID_SIZE}
            patternUnits="userSpaceOnUse"
          >
            <Line x1={GRID_SIZE} y1="0" x2={GRID_SIZE} y2={GRID_SIZE} stroke={color} strokeWidth="0.8" />
            <Line x1="0" y1={GRID_SIZE} x2={GRID_SIZE} y2={GRID_SIZE} stroke={color} strokeWidth="0.8" />
          </Pattern>
        </Defs>
        <Rect x="0" y="0" width="100%" height="100%" fill="url(#cgrid)" />
      </Svg>
    </Animated.View>
  );
}

// ─── Sparkle/Animation configs ──────────────────────────────
const SPARKLE_CONFIGS = [
  { top: SH * 0.08, left: SW * 0.10, size: 16, duration: 2800, delay: 0 },
  { top: SH * 0.14, left: SW * 0.48, size: 13, duration: 2100, delay: 400 },
  { top: SH * 0.24, left: SW * 0.82, size: 20, duration: 3200, delay: 800 },
  { top: SH * 0.42, left: SW * 0.92, size: 12, duration: 2500, delay: 200 },
  { top: SH * 0.54, left: SW * 0.06, size: 22, duration: 2000, delay: 600 },
  { top: SH * 0.62, left: SW * 0.60, size: 15, duration: 3000, delay: 1000 },
  { top: SH * 0.75, left: SW * 0.12, size: 16, duration: 2600, delay: 300 },
  { top: SH * 0.90, left: SW * 0.68, size: 14, duration: 2200, delay: 700 },
];

const STAR_PATH =
  'M12 2 C12 2 12.3 8.7 15.5 11.5 C15.5 11.5 18.7 12 22 12 ' +
  'C22 12 15.5 12.3 12.5 15.5 C12.5 15.5 12 18.7 12 22 ' +
  'C12 22 11.7 15.5 8.5 12.5 C8.5 12.5 5.3 12 2 12 ' +
  'C2 12 8.5 11.7 11.5 8.5 C11.5 8.5 12 5.3 12 2 Z';

function Sparkle({
  top, left, size, duration, delay, color, glowColor,
}: {
  top: number; left: number; size: number;
  duration: number; delay: number;
  color: string; glowColor: string;
}) {
  const opacity = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(0.5)).current;

  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.delay(delay),
        Animated.parallel([
          Animated.timing(opacity, { toValue: 1, duration: duration * 0.4, easing: Easing.out(Easing.quad), useNativeDriver: true }),
          Animated.timing(scale, { toValue: 1, duration: duration * 0.4, easing: Easing.out(Easing.back(1.4)), useNativeDriver: true }),
        ]),
        Animated.parallel([
          Animated.timing(opacity, { toValue: 0, duration: duration * 0.6, easing: Easing.in(Easing.quad), useNativeDriver: true }),
          Animated.timing(scale, { toValue: 0.4, duration: duration * 0.6, easing: Easing.in(Easing.quad), useNativeDriver: true }),
        ]),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, []);

  const glowId = `glow${size}${delay}`;

  return (
    <Animated.View
      pointerEvents="none"
      style={{ position: 'absolute', top, left, opacity, transform: [{ scale }] }}
    >
      <Svg
        width={size * 2.4}
        height={size * 2.4}
        style={{ position: 'absolute', top: -size * 0.7, left: -size * 0.7 }}
      >
        <Defs>
          <RadialGradient id={glowId} cx="50%" cy="50%" r="50%">
            <Stop offset="0%" stopColor={glowColor} stopOpacity="1" />
            <Stop offset="100%" stopColor={glowColor} stopOpacity="0" />
          </RadialGradient>
        </Defs>
        <Rect x="0" y="0" width={size * 2.4} height={size * 2.4} fill={`url(#${glowId})`} />
      </Svg>
      <Svg width={size} height={size} viewBox="0 0 24 24">
        <Path d={STAR_PATH} fill={color} />
      </Svg>
    </Animated.View>
  );
}

function SparkleLayer({ color, glowColor }: { color: string; glowColor: string }) {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {SPARKLE_CONFIGS.map((cfg, i) => (
        <Sparkle key={i} {...cfg} color={color} glowColor={glowColor} />
      ))}
    </View>
  );
}

// ─── CheapestGo Logo ──────────────────────────────────────────────────────────
function Logo({ dark }: { dark: '' | boolean }) {
  const textColor = dark ? '#f1f5f9' : '#0f172a';
  const accentColor = dark ? '#60a5fa' : '#2563eb';
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
      <View style={ls.box}>
        <LogoSvg width={26} height={26} />
      </View>
      <Text style={[ls.text, { color: textColor }]}>
        Cheapest<Text style={{ color: accentColor, fontWeight: '800' }}>Go</Text>
      </Text>
    </View>
  );
}
const ls = StyleSheet.create({
  box: { width: 44, height: 44, borderRadius: 12, overflow: 'hidden', alignItems: 'center', justifyContent: 'center', backgroundColor: '#2563eb' },
  text: { fontSize: 24, fontWeight: '700', letterSpacing: -0.3 },
});

// ─── Main Screen ──────────────────────────────────────────────────────────────
type Mode = 'signin' | 'forgot_password' | 'reset_password';

export default function LoginScreen() {
  const router = useRouter();
  const { login, resetPassword, confirmPasswordReset } = useAuth();

  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';
  const C = isDark ? DARK : LIGHT;

  const [mode, setMode] = useState<Mode>('signin');
  const [isLoading, setIsLoading] = useState(false);
  const [successMessage, setSuccess] = useState('');
  const [generalError, setGenError] = useState('');

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);

  const [emailErr, setEmailErr] = useState('');
  const [passwordErr, setPasswordErr] = useState('');

  const slideAnim = useRef(new Animated.Value(20)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(slideAnim, { toValue: 0, duration: 500, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
      Animated.timing(fadeAnim, { toValue: 1, duration: 500, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
    ]).start();
  }, []);

  const clearErrors = () => {
    setEmailErr(''); setPasswordErr('');
    setGenError(''); setSuccess('');
  };

  const switchMode = (next: Mode) => {
    clearErrors();
    setEmail(''); setPassword('');
    setMode(next);
  };

  const validateEmail = (v: string): boolean => {
    if (!v.trim()) { setEmailErr('Email is required'); return false; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim())) {
      setEmailErr('Please enter a valid email address'); return false;
    }
    return true;
  };

  const validatePassword = (v: string, min = 6): boolean => {
    if (!v) { setPasswordErr('Password is required'); return false; }
    if (v.length < min) { setPasswordErr(`Password must be at least ${min} characters`); return false; }
    return true;
  };

  const handleSignIn = async () => {
    clearErrors();
    if (!validateEmail(email) || !validatePassword(password)) return;
    setIsLoading(true);
    try { await login(email.trim(), password); }
    catch (err: any) {
      const msg: string = err?.message ?? 'Something went wrong.';
      if (msg.toLowerCase().includes('password') || msg.toLowerCase().includes('invalid'))
        setPasswordErr('Incorrect password. Please try again.');
      else if (msg.toLowerCase().includes('email') || msg.toLowerCase().includes('not found'))
        setEmailErr('No account found with this email.');
      else setGenError(msg);
    } finally { setIsLoading(false); }
  };

  const handleForgotPassword = async () => {
    clearErrors();
    if (!validateEmail(email)) return;
    setIsLoading(true);
    try {
      await resetPassword(email.trim());
      setSuccess('Instructions sent! Check your inbox.');
    } catch (err: any) { setGenError(err?.message ?? 'Failed to send reset email.'); }
    finally { setIsLoading(false); }
  };

  const handleResetPassword = async () => {
    clearErrors();
    if (!validatePassword(password, 8)) return;
    setIsLoading(true);
    try {
      await confirmPasswordReset(password);
      setSuccess('Password reset successfully!');
      setTimeout(() => switchMode('signin'), 1800);
    } catch (err: any) { setGenError(err?.message ?? 'Reset failed. Request a new link.'); }
    finally { setIsLoading(false); }
  };

  const handleSubmit = () => {
    if (mode === 'signin') handleSignIn();
    else if (mode === 'forgot_password') handleForgotPassword();
    else if (mode === 'reset_password') handleResetPassword();
  };

  const handleBack = () => {
    if (mode !== 'signin') { switchMode('signin'); return; }
    if (router.canGoBack()) router.back();
  };

  const titles = {
    signin: 'Welcome Back',
    forgot_password: 'Recover Password',
    reset_password: 'Set New Password',
  };
  const subtitles = {
    signin: 'Sign in to access your best travel deals',
    forgot_password: 'Enter your email to receive recovery instructions',
    reset_password: 'Create a secure new password for your account',
  };
  const submitLabels = {
    signin: 'Sign In',
    forgot_password: 'Send Reset Link',
    reset_password: 'Confirm New Password',
  };

  return (
    <SafeAreaView style={[s.safe, { backgroundColor: C.bg }]}>
      <View pointerEvents="none" style={StyleSheet.absoluteFill}>
        <DriftGrid color={C.gridLine} />
        <SparkleLayer color={C.sparkle} glowColor={C.sparkleGlow} />
      </View>

      <KeyboardAvoidingView
        style={s.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
      >
        <ScrollView
          style={s.flex}
          contentContainerStyle={s.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >

          {/* ── Header ── */}
          <View style={s.header}>
            <View style={s.topBar}>
              <TouchableOpacity
                style={[s.iconBtn, { backgroundColor: C.backBg, borderColor: C.backBorder }]}
                onPress={handleBack}
                disabled={isLoading}
                activeOpacity={0.75}
              >
                <ArrowLeft size={18} color={C.backIcon} strokeWidth={2.2} />
              </TouchableOpacity>
            </View>
            <Logo dark={isDark} />
          </View>

          <Animated.View
            style={[
              s.card,
              {
                backgroundColor: C.cardBg,
                borderColor: C.cardBorder,
                transform: [{ translateY: slideAnim }],
                opacity: fadeAnim,
              },
            ]}
          >
            <Text style={[s.title, { color: C.title }]}>{titles[mode]}</Text>
            <Text style={[s.subtitle, { color: C.subtitle }]}>{subtitles[mode]}</Text>

            {!!successMessage && (
              <View style={[s.banner, { backgroundColor: C.successBg, borderColor: C.successBorder }]}>
                <CheckCircle size={14} color={C.successText} strokeWidth={2.2} />
                <Text style={[s.bannerText, { color: C.successText }]}>{successMessage}</Text>
              </View>
            )}
            {!!generalError && (
              <View style={[s.banner, { backgroundColor: C.bannerErrBg, borderColor: C.bannerErrBorder }]}>
                <AlertCircle size={14} color={C.bannerErrText} strokeWidth={2.2} />
                <Text style={[s.bannerText, { color: C.bannerErrText }]}>{generalError}</Text>
              </View>
            )}

            <View style={[s.divider, { backgroundColor: C.divider }]} />

            {mode !== 'reset_password' && (
              <View style={s.fieldGroup}>
                <Text style={[s.label, { color: C.label }]}>EMAIL ADDRESS</Text>
                <View style={[
                  s.inputWrapper,
                  { backgroundColor: emailErr ? C.inputBgErr : C.inputBg, borderColor: emailErr ? C.inputBorderErr : C.inputBorder },
                ]}>
                  <TextInput
                    style={[s.input, s.flex, { color: C.inputText }]}
                    value={email}
                    onChangeText={v => { setEmail(v); setEmailErr(''); setGenError(''); }}
                    placeholder="Enter your email address"
                    placeholderTextColor={C.placeholder}
                    keyboardType="email-address"
                    autoCapitalize="none"
                    autoCorrect={false}
                    autoComplete="email"
                    returnKeyType="next"
                    editable={!isLoading}
                  />
                  {!!emailErr && <AlertCircle size={18} color={C.fieldErr} strokeWidth={2.2} />}
                </View>
                {!!emailErr && (
                  <Text style={[s.fieldErrText, { color: C.fieldErr }]}>{emailErr}</Text>
                )}
              </View>
            )}

            {/* ── Password ── */}
            {mode !== 'forgot_password' && (
              <View style={s.fieldGroup}>
                <Text style={[s.label, { color: C.label }]}>
                  {mode === 'reset_password' ? 'NEW PASSWORD' : 'PASSWORD'}
                </Text>
                <View style={[
                  s.inputWrapper,
                  { backgroundColor: passwordErr ? C.inputBgErr : C.inputBg, borderColor: passwordErr ? C.inputBorderErr : C.inputBorder },
                ]}>
                  <TextInput
                    style={[s.input, s.flex, { color: C.inputText }]}
                    value={password}
                    onChangeText={v => { setPassword(v); setPasswordErr(''); setGenError(''); }}
                    placeholder={mode === 'reset_password' ? 'Min. 8 characters' : 'Enter password (min 8 characters)'}
                    placeholderTextColor={C.placeholder}
                    secureTextEntry={!showPw}
                    autoCapitalize="none"
                    autoCorrect={false}
                    returnKeyType="done"
                    onSubmitEditing={handleSubmit}
                    editable={!isLoading}
                  />
                  <TouchableOpacity
                    onPress={() => setShowPw(v => !v)}
                    hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                    disabled={isLoading}
                  >
                    {showPw
                      ? <Eye size={18} color={C.placeholder} strokeWidth={2} />
                      : <EyeOff size={18} color={C.placeholder} strokeWidth={2} />
                    }
                  </TouchableOpacity>
                </View>

                <View style={s.pwFooter}>
                  {!!passwordErr
                    ? <Text style={[s.fieldErrText, s.flex, { color: C.fieldErr }]}>{passwordErr}</Text>
                    : <View style={s.flex} />
                  }
                  {mode === 'signin' && (
                    <TouchableOpacity
                      onPress={() => switchMode('forgot_password')}
                      hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                      disabled={isLoading}
                    >
                      <Text style={[s.forgotText, { color: C.forgot }]}>Forgot Password?</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            )}

            <TouchableOpacity
              style={[s.submitBtn, { backgroundColor: C.submitBg }, isLoading && s.submitDisabled]}
              onPress={handleSubmit}
              activeOpacity={0.85}
              disabled={isLoading}
            >
              {isLoading
                ? <ActivityIndicator color="#fff" size="small" />
                : <Text style={[s.submitText, { color: C.submitText }]}>{submitLabels[mode]}</Text>
              }
            </TouchableOpacity>

            <View style={s.switchRow}>
              {mode === 'signin' && (
                <>
                  <Text style={[s.switchPrompt, { color: C.signUpPrompt }]}>Don't have an account? </Text>
                  <Link href="/(auth)/register" asChild>
                    <TouchableOpacity disabled={isLoading}>
                      <Text style={[s.switchLink, { color: C.signUpLink }]}>Sign Up</Text>
                    </TouchableOpacity>
                  </Link>
                </>
              )}
              {(mode === 'forgot_password' || mode === 'reset_password') && (
                <>
                  <Text style={[s.switchPrompt, { color: C.signUpPrompt }]}>Already registered? </Text>
                  <TouchableOpacity onPress={() => switchMode('signin')} disabled={isLoading}>
                    <Text style={[s.switchLink, { color: C.signUpLink }]}>Sign In</Text>
                  </TouchableOpacity>
                </>
              )}
            </View>

          </Animated.View>

        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────
const s = StyleSheet.create({
  safe: { flex: 1 },
  flex: { flex: 1 },
  scrollContent: { flexGrow: 1 },

  header: {
    paddingTop: 8,
    paddingHorizontal: 20,
    paddingBottom: 36,
    alignItems: 'center',
    justifyContent: 'flex-end',
    minHeight: 190,
  },
  topBar: {
    position: 'absolute',
    top: 8,
    left: 20,
    right: 20,
    flexDirection: 'row',
    justifyContent: 'flex-start',
    alignItems: 'center',
    zIndex: 10,
  },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },

  card: {
    flex: 1,
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderRightWidth: 1,
    paddingHorizontal: 24,
    paddingTop: 32,
    paddingBottom: 44,
    // lift shadow
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.06,
    shadowRadius: 16,
    elevation: 8,
  },

  title: {
    fontSize: 24,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 6,
    letterSpacing: -0.3,
  },
  subtitle: {
    fontSize: 13,
    fontWeight: '400',
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 18,
  },

  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 16,
  },
  bannerText: {
    fontSize: 12,
    fontWeight: '500',
    flex: 1,
    lineHeight: 16,
  },

  divider: { height: 1, marginBottom: 20 },
  fieldGroup: { marginBottom: 16 },

  label: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 1.2,
    marginBottom: 8,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.5,
    borderRadius: 12,
    paddingHorizontal: 14,
    gap: 8,
    minHeight: 52,
  },
  input: {
    height: 52,
    fontSize: 14,
    fontWeight: '400',
    paddingVertical: 0,
  },
  fieldErrText: {
    fontSize: 11,
    fontWeight: '600',
    marginTop: 5,
  },
  pwFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 7,
    gap: 8,
  },
  forgotText: {
    fontSize: 12,
    fontWeight: '700',
  },

  submitBtn: {
    borderRadius: 14,
    height: 54,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 10,
    shadowColor: '#1d4ed8',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 12,
    elevation: 6,
  },
  submitDisabled: { opacity: 0.65 },
  submitText: {
    fontSize: 15,
    fontWeight: '700',
    letterSpacing: 0.3,
  },

  switchRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 22,
  },
  switchPrompt: { fontSize: 13, fontWeight: '400' },
  switchLink: { fontSize: 13, fontWeight: '700' },
});