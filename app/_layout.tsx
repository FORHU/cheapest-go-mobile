import FontAwesome from '@expo/vector-icons/FontAwesome';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFonts } from 'expo-font';
import * as Linking from 'expo-linking';
import { DarkTheme, DefaultTheme, Stack, ThemeProvider, useRouter, useSegments } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect, useState } from 'react';
import 'react-native-reanimated';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { useColorScheme } from '@/hooks/useColorScheme';
import { ForceUpdateModal } from '../components/ui/ForceUpdateModal';
import { AuthProvider, useAuth } from '../context/AuthContext';
import { SettingsProvider } from '../context/SettingsContext';
import "../global.css";
import { registerForPushNotifications } from '../lib/notifications';
import {
  fetchVersionConfig,
  isUpdateRequired,
  type VersionConfig,
} from '../lib/version-check';

export {
  ErrorBoundary
} from 'expo-router';

export const unstable_settings = {
  initialRouteName: '(tabs)',
};

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    SpaceMono: require('../assets/fonts/SpaceMono-Regular.ttf'),
    ...FontAwesome.font,
  });

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return (
    <SafeAreaProvider>
      <AuthProvider>
        <SettingsProvider>
          <RootLayoutNav />
        </SettingsProvider>
      </AuthProvider>
    </SafeAreaProvider>
  );
}

function RootLayoutNav() {
  const ONBOARDING_KEY = 'hasSeenOnboarding';
  const [hasSeenOnboarding, setHasSeenOnboarding] = useState<boolean | null>(null);

  const colorScheme = useColorScheme();
  const { user, isLoading, isPasswordRecovery, handleAuthDeepLink } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  // ── Version gate ─────────────────────────────────────────────────────────
  const [versionConfig, setVersionConfig] = useState<VersionConfig | null>(null);
  const [forceUpdateVisible, setForceUpdateVisible] = useState(false);

  useEffect(() => {
    fetchVersionConfig().then(cfg => {
      setVersionConfig(cfg);
      if (isUpdateRequired(cfg)) {
        setForceUpdateVisible(true);
      }
    });
  }, []);

  // ── Push notifications ───────────────────────────────────────────────────
  useEffect(() => {
    if (isLoading) return;
    // Register once we know whether the user is logged in or not
    registerForPushNotifications(user?.id ?? undefined);
  }, [isLoading, user?.id]);

  // ── Onboarding check ────────────────────────────────────────────────────────
  useEffect(() => {
    AsyncStorage.getItem(ONBOARDING_KEY)
      .then(value => setHasSeenOnboarding(value === 'true'))
      .catch(() => setHasSeenOnboarding(true));
  }, []);

  // ── Deep link handling ───────────────────────────────────────────────────
  useEffect(() => {
    const handle = async (url: string) => {
      try {
        await handleAuthDeepLink(url);
      } catch { }
    };

    Linking.getInitialURL().then(url => { if (url) handle(url); });
    const sub = Linking.addEventListener('url', ({ url }) => handle(url));
    return () => sub.remove();
  }, [handleAuthDeepLink]);

  // ── Auth redirect ────────────────────────────────────────────────────────
  useEffect(() => {
    if (isLoading || hasSeenOnboarding === null) return;

    const inAuthGroup = segments[0] === '(auth)';
    const inOnboarding = segments[0] === 'onboarding';
    const inUpdatePassword = segments[1] === 'update-password';

    if (isPasswordRecovery) {
      router.replace('/(auth)/update-password');
      return;
    }

    if (!hasSeenOnboarding && !user && !inOnboarding && !inAuthGroup) {
      router.replace('/onboarding');
      return;
    }

    if (!user && !inAuthGroup && !inOnboarding) {
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup && !inUpdatePassword) {
      router.replace('/(tabs)');
    }
  }, [user, isLoading, segments, isPasswordRecovery, hasSeenOnboarding, router]);

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="onboarding" options={{ headerShown: false }} />
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
        <Stack.Screen name="edit-profile" options={{ headerShown: false }} />
        <Stack.Screen name="language" options={{ headerShown: false }} />
        <Stack.Screen name="flights" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="checkout" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="flight-checkout" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
      </Stack>

      {/* Force-update gate — renders over everything, no dismiss button */}
      {versionConfig && (
        <ForceUpdateModal
          visible={forceUpdateVisible}
          message={versionConfig.updateMessage}
          minVersion={versionConfig.minVersion}
        />
      )}
    </ThemeProvider>
  );
}
