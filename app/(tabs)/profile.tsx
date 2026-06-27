import CurrencyPickerModal from '@/components/ui/CurrencyPickerModal';
import EditProfileModal from '@/components/ui/EditProfileModal';
import LanguagePickerModal from '@/components/ui/LanguagePickerModal';
import { useAuth } from '@/context/AuthContext';
import { useSettings } from '@/context/SettingsContext';
import { useColorScheme } from '@/hooks/useColorScheme';
import AsyncStorage from '@react-native-async-storage/async-storage';
// import * as ImagePicker from 'expo-image-picker';
import { useRouter } from 'expo-router';
import {
  Bell,
  Camera,
  ChevronRight,
  FileText,
  Globe,
  HelpCircle,
  Lock,
  LogOut,
  Mail,
  Pencil,
  Star,
  User,
} from 'lucide-react-native';
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Image,
  Linking,
  ScrollView,
  Text,
  TouchableOpacity,
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
  chevron: '#3D4D5E',
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
  chevron: '#CBD5E1',
};

function useTheme() {
  const colorScheme = useColorScheme();
  return colorScheme === 'dark' ? dark : light;
}

function SectionLabel({ label }: { label: string }) {
  const C = useTheme();
  return (
    <Text style={{
      fontSize: 11,
      fontWeight: '600',
      color: C.label,
      letterSpacing: 1,
      marginHorizontal: 16,
      marginTop: 20,
      marginBottom: 8,
    }}>
      {label}
    </Text>
  );
}

function StatItem({ label, value }: { label: string; value: string }) {
  const C = useTheme();
  return (
    <View style={{ alignItems: 'center', flex: 1 }}>
      <Text style={{ fontSize: 22, fontWeight: '700', color: C.text }}>{value}</Text>
      <Text style={{ fontSize: 10, color: C.muted, letterSpacing: 0.5, marginTop: 2 }}>{label}</Text>
    </View>
  );
}

type Badge = { label: string; color: string; bg: string };

function SettingRow({
  icon,
  title,
  subtitle,
  badge,
  onPress,
  isLast,
}: {
  icon: React.ReactNode;
  title: string;
  subtitle?: string;
  badge?: Badge;
  onPress?: () => void;
  isLast: boolean;
}) {
  const C = useTheme();
  return (
    <TouchableOpacity
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingVertical: 14,
        borderBottomWidth: isLast ? 0 : 1,
        borderBottomColor: C.divider,
      }}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <View style={{
        width: 36,
        height: 36,
        borderRadius: 10,
        backgroundColor: C.iconBg,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 14,
      }}>
        {icon}
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 15, color: C.text, fontWeight: '500' }}>{title}</Text>
        {subtitle ? (
          <Text style={{ fontSize: 12, color: C.muted, marginTop: 2 }}>{subtitle}</Text>
        ) : null}
      </View>
      {badge ? (
        <View style={{
          backgroundColor: badge.bg,
          paddingHorizontal: 10,
          paddingVertical: 3,
          borderRadius: 6,
          marginRight: 10,
        }}>
          <Text style={{ fontSize: 12, fontWeight: '700', color: badge.color }}>{badge.label}</Text>
        </View>
      ) : null}
      <ChevronRight size={16} color={C.chevron} />
    </TouchableOpacity>
  );
}

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const C = useTheme();

  const [signingOut, setSigningOut] = useState(false);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [currencyPickerVisible, setCurrencyPickerVisible] = useState(false);
  const [languagePickerVisible, setLanguagePickerVisible] = useState(false);
  const [localAvatar, setLocalAvatar] = useState<string | null>(null);

  const { currency, setCurrency, language, setLanguage } = useSettings();

  const CURRENCY_NAMES: Record<string, string> = {
    KRW: 'Korean Won',
    USD: 'US Dollar',
    PHP: 'Philippine Peso',
  };

  // Load locally saved avatar on mount
  useEffect(() => {
    AsyncStorage.getItem('profile_avatar').then((uri) => {
      if (uri) setLocalAvatar(uri);
    });
  }, []);

  // ─── Handlers ──────────────────────────────────────────────────────────────

  /*const handleCameraPress = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert(
        'Permission required',
        'Please allow access to your photo library in Settings to change your profile photo.',
      );
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });
    if (!result.canceled && result.assets[0]) {
      const uri = result.assets[0].uri;
      setLocalAvatar(uri);
      await AsyncStorage.setItem('profile_avatar', uri);
    }
  };*/

  const handleCameraPress = () => {
    Alert.alert(
      'Coming soon',
      'Profile photo upload will be available in the next build.',
    );
  };

  const handleEmailPress = () => {
    Alert.alert(
      'Change Email',
      'To update your email address, please contact our support team.',
      [{ text: 'OK' }],
    );
  };

  const handleHelpCenter = () => {
    // TODO: replace with the real help URL once published
    Linking.openURL('https://cheapestgo.com/help').catch(() => {
      Alert.alert('Could not open help center', 'Please try again later.');
    });
  };

  const handleRateApp = () => {
    // TODO: replace with real App Store / Play Store URLs on launch
    Alert.alert(
      'Rate CheapestGo ⭐',
      'Thanks for your support! App store rating will be available once the app is published.',
      [{ text: 'OK' }],
    );
  };

  const handleTerms = () => {
    // TODO: replace with the real terms URL once published
    Linking.openURL('https://cheapestgo.com/terms').catch(() => {
      Alert.alert('Could not open page', 'Please try again later.');
    });
  };

  const handleLogout = () => {
    Alert.alert('Sign out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign out',
        style: 'destructive',
        onPress: async () => {
          setSigningOut(true);
          try { await logout(); } finally { setSigningOut(false); }
        },
      },
    ]);
  };

  // ─── Signed-out state ───────────────────────────────────────────────────────

  if (!user) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: C.bg, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 24 }}>
        <View style={{ width: 80, height: 80, backgroundColor: C.card, borderRadius: 40, alignItems: 'center', justifyContent: 'center', marginBottom: 24, borderWidth: 1, borderColor: C.border }}>
          <User size={36} color={C.muted} />
        </View>
        <Text style={{ fontSize: 20, fontWeight: '700', color: C.text, marginBottom: 8 }}>
          You're not signed in
        </Text>
        <Text style={{ fontSize: 14, color: C.muted, textAlign: 'center', marginBottom: 32, lineHeight: 22 }}>
          Sign in to manage your bookings and preferences.
        </Text>
        <TouchableOpacity
          style={{ backgroundColor: C.blue, borderRadius: 14, paddingVertical: 16, alignItems: 'center', width: '100%', marginBottom: 12 }}
          onPress={() => router.push('/(auth)/login')}
        >
          <Text style={{ color: '#fff', fontWeight: '700', fontSize: 16 }}>Sign in</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={{ backgroundColor: C.card, borderRadius: 14, paddingVertical: 16, alignItems: 'center', width: '100%', borderWidth: 1, borderColor: C.border }}
          onPress={() => router.push('/(auth)/register')}
        >
          <Text style={{ color: C.text, fontWeight: '700', fontSize: 16 }}>Create account</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }

  const initials = `${user.firstName?.[0] ?? ''}${user.lastName?.[0] ?? ''}`.toUpperCase();
  const fullName = `${user.firstName} ${user.lastName}`.trim();

  // ─── Main render ────────────────────────────────────────────────────────────

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }} edges={['top']}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 40 }}>

        {/* Header card */}
        <View style={{
          backgroundColor: C.card,
          marginHorizontal: 16,
          marginTop: 16,
          borderRadius: 20,
          borderWidth: 1,
          borderColor: C.border,
          padding: 20,
        }}>
          {/* Edit button */}
          <TouchableOpacity
            style={{
              position: 'absolute',
              top: 16,
              right: 16,
              flexDirection: 'row',
              alignItems: 'center',
              gap: 6,
              backgroundColor: C.bg,
              borderWidth: 1,
              borderColor: C.border,
              borderRadius: 10,
              paddingHorizontal: 12,
              paddingVertical: 7,
            }}
            onPress={() => setEditModalVisible(true)}
            activeOpacity={0.7}
          >
            <Pencil size={13} color={C.text} />
            <Text style={{ fontSize: 13, fontWeight: '600', color: C.text }}>Edit</Text>
          </TouchableOpacity>

          {/* Avatar */}
          <View style={{ alignItems: 'center', paddingTop: 8, marginBottom: 20 }}>
            <View style={{ position: 'relative', marginBottom: 12 }}>
              {localAvatar ? (
                <Image
                  source={{ uri: localAvatar }}
                  style={{ width: 72, height: 72, borderRadius: 36 }}
                />
              ) : (
                <View style={{
                  width: 72,
                  height: 72,
                  borderRadius: 36,
                  backgroundColor: '#3B82F6',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <Text style={{ fontSize: 26, fontWeight: '700', color: '#fff' }}>{initials}</Text>
                </View>
              )}
              <TouchableOpacity
                style={{
                  position: 'absolute',
                  bottom: 0,
                  right: 0,
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                  backgroundColor: '#3B82F6',
                  alignItems: 'center',
                  justifyContent: 'center',
                  borderWidth: 2,
                  borderColor: C.card,
                }}
                onPress={handleCameraPress}
                activeOpacity={0.8}
              >
                <Camera size={11} color="#fff" />
              </TouchableOpacity>
            </View>
            <Text style={{ fontSize: 18, fontWeight: '700', color: C.text, marginBottom: 4 }}>{fullName || user.email}</Text>
            <Text style={{ fontSize: 13, color: C.muted }}>{user.email}</Text>
          </View>

          {/* Divider */}
          <View style={{ height: 1, backgroundColor: C.divider, marginBottom: 16 }} />

          {/* Stats — hardcoded for now (Task 3 will replace these) */}
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <StatItem label="BOOKINGS" value="4" />
            <View style={{ width: 1, height: 32, backgroundColor: C.divider }} />
            <StatItem label="SAVED" value="12" />
            <View style={{ width: 1, height: 32, backgroundColor: C.divider }} />
            <StatItem label="REVIEWS" value="3" />
          </View>
        </View>

        {/* Account */}
        <SectionLabel label="ACCOUNT" />
        <View style={{ marginHorizontal: 16, backgroundColor: C.card, borderRadius: 16, borderWidth: 1, borderColor: C.border, overflow: 'hidden' }}>
          <SettingRow
            icon={<User size={18} color={C.icon} />}
            title="Full name"
            subtitle={fullName || 'Not set'}
            onPress={() => setEditModalVisible(true)}
            isLast={false}
          />
          <SettingRow
            icon={<Mail size={18} color={C.icon} />}
            title="Email"
            subtitle={user.email}
            onPress={handleEmailPress}
            isLast={false}
          />
          <SettingRow
            icon={<Lock size={18} color={C.icon} />}
            title="Change password"
            onPress={() => router.navigate('/(auth)/update-password')}
            isLast={true}
          />
        </View>

        {/* Preferences */}
        <SectionLabel label="PREFERENCES" />
        <View style={{ marginHorizontal: 16, backgroundColor: C.card, borderRadius: 16, borderWidth: 1, borderColor: C.border, overflow: 'hidden' }}>
          <SettingRow
            icon={<Text style={{ fontSize: 16, color: C.icon, fontWeight: '700' }}>{currency.symbol}</Text>}
            title="Currency"
            subtitle={`${CURRENCY_NAMES[currency.code] ?? currency.code} (${currency.symbol})`}
            onPress={() => setCurrencyPickerVisible(true)}
            isLast={false}
          />
          <SettingRow
            icon={<Bell size={18} color={C.icon} />}
            title="Price alerts"
            subtitle="3 active alerts"
            badge={{ label: 'ON', color: '#D97706', bg: 'rgba(217,119,6,0.15)' }}
            isLast={false}
          />
          <SettingRow
            icon={<Globe size={18} color={C.icon} />}
            title="Language"
            subtitle={language.english}
            onPress={() => setLanguagePickerVisible(true)}
            isLast={true}
          />
        </View>

        {/* Support */}
        <SectionLabel label="SUPPORT" />
        <View style={{ marginHorizontal: 16, backgroundColor: C.card, borderRadius: 16, borderWidth: 1, borderColor: C.border, overflow: 'hidden' }}>
          <SettingRow
            icon={<HelpCircle size={18} color={C.icon} />}
            title="Help center"
            onPress={handleHelpCenter}
            isLast={false}
          />
          <SettingRow
            icon={<Star size={18} color={C.icon} />}
            title="Rate the app"
            onPress={handleRateApp}
            isLast={false}
          />
          <SettingRow
            icon={<FileText size={18} color={C.icon} />}
            title="Terms & Privacy"
            onPress={handleTerms}
            isLast={true}
          />
        </View>

        {/* Sign out */}
        <View style={{ marginHorizontal: 16, marginTop: 20 }}>
          <TouchableOpacity
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 10,
              borderWidth: 1,
              borderColor: 'rgba(239,68,68,0.4)',
              borderRadius: 16,
              paddingVertical: 16,
              backgroundColor: 'rgba(239,68,68,0.06)',
            }}
            onPress={handleLogout}
            disabled={signingOut}
            activeOpacity={0.8}
          >
            {signingOut ? (
              <ActivityIndicator color="#ef4444" />
            ) : (
              <>
                <LogOut size={18} color="#ef4444" />
                <Text style={{ fontSize: 15, fontWeight: '600', color: '#ef4444' }}>Sign out</Text>
              </>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* Modals */}
      <EditProfileModal
        visible={editModalVisible}
        onClose={() => setEditModalVisible(false)}
      />
      <CurrencyPickerModal
        visible={currencyPickerVisible}
        currentCode={currency.code}
        onSelect={setCurrency}
        onClose={() => setCurrencyPickerVisible(false)}
      />
      <LanguagePickerModal
        visible={languagePickerVisible}
        currentCode={language.code}
        onSelect={setLanguage}
        onClose={() => setLanguagePickerVisible(false)}
      />
    </SafeAreaView>
  );
}