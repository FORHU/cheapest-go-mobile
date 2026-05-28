import FontAwesome from '@expo/vector-icons/FontAwesome';
import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { useFonts } from 'expo-font';
import * as Linking from 'expo-linking';
import { Stack, useRouter, useSegments } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import * as WebBrowser from 'expo-web-browser';
import { useEffect } from 'react';
import 'react-native-reanimated';
import { SafeAreaProvider } from 'react-native-safe-area-context';

// Required for OAuth browser sessions to complete properly on Android
WebBrowser.maybeCompleteAuthSession();

import { useColorScheme } from '@/hooks/useColorScheme';
import { SettingsProvider } from '../context/SettingsContext';
import { AuthProvider, useAuth } from '../context/AuthContext';
import "../global.css";

export {
  ErrorBoundary,
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
  const colorScheme = useColorScheme();
  const { user, isLoading, isPasswordRecovery, handleAuthDeepLink } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  // Handle deep links from auth emails (confirmation, password reset)
  useEffect(() => {
    const handle = async (url: string) => {
      try {
        await handleAuthDeepLink(url);
      } catch (_) {}
    };

    Linking.getInitialURL().then(url => { if (url) handle(url); });
    const sub = Linking.addEventListener('url', ({ url }) => handle(url));
    return () => sub.remove();
  }, []);

  useEffect(() => {
    if (isLoading) return;

    const inAuthGroup = segments[0] === '(auth)';

    if (isPasswordRecovery) {
      router.replace('/(auth)/update-password');
      return;
    }

    if (!user && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup) {
      router.replace('/(tabs)');
    }
  }, [user, isLoading, segments, isPasswordRecovery]);

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
        <Stack.Screen name="flights" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="checkout" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="flight-checkout" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
      </Stack>
    </ThemeProvider>
  );
}
