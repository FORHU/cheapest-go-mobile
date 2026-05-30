/**
 * Push notification registration.
 *
 * Flow:
 *  1. Request permission (iOS asks the user; Android ≥ 13 also needs permission)
 *  2. Get the Expo push token
 *  3. POST it to /api/mobile/register-device so the admin can send pushes
 *
 * Call registerForPushNotifications() once after the user is authenticated
 * (or on first launch for guest users). It is safe to call multiple times —
 * the backend upserts on the token.
 */

import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { WEB_API_URL, MOBILE_API_KEY, APP_VERSION } from './config';

// How notifications behave while the app is foregrounded
Notifications.setNotificationHandler({
    handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
        shouldShowBanner: true,
        shouldShowList: true,
    }),
});

/**
 * Request permission and register the device's push token with the backend.
 * Returns the token string on success, null on failure or denial.
 */
export async function registerForPushNotifications(userId?: string): Promise<string | null> {
    // Physical device only — emulators can't receive push
    // (expo-constants Device.isDevice check removed to avoid import; handle in caller if needed)

    // Android: set up a notification channel
    if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync('default', {
            name: 'CheapestGo',
            importance: Notifications.AndroidImportance.MAX,
            vibrationPattern: [0, 250, 250, 250],
            lightColor: '#2563EB',
        });
    }

    // Request permission
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
    }

    if (finalStatus !== 'granted') {
        console.log('[notifications] Permission denied');
        return null;
    }

    // Get token — EAS project ID from app.json extra.eas.projectId
    const EAS_PROJECT_ID = 'a438c5b2-ecf9-4bde-a329-7d40658ac43e';
    let token: string;
    try {
        const result = await Notifications.getExpoPushTokenAsync({
            projectId: process.env.EXPO_PUBLIC_PROJECT_ID ?? EAS_PROJECT_ID,
        });
        token = result.data;
    } catch (err) {
        console.error('[notifications] Failed to get push token:', err);
        return null;
    }

    // Register with backend
    try {
        await fetch(`${WEB_API_URL}/api/mobile/register-device`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Mobile-Api-Key': MOBILE_API_KEY,
            },
            body: JSON.stringify({
                expoPushToken: token,
                platform: Platform.OS,
                appVersion: APP_VERSION,
                userId: userId ?? null,
            }),
        });
    } catch (err) {
        // Non-fatal — the app works fine without push
        console.warn('[notifications] Registration request failed:', err);
    }

    return token;
}

/**
 * Add a listener for notifications received while the app is in the foreground.
 * Returns a cleanup function — call it in a useEffect return.
 */
export function addForegroundNotificationListener(
    onNotification: (notification: Notifications.Notification) => void,
) {
    const sub = Notifications.addNotificationReceivedListener(onNotification);
    return () => sub.remove();
}

/**
 * Add a listener for when the user taps a notification to open the app.
 */
export function addNotificationResponseListener(
    onResponse: (response: Notifications.NotificationResponse) => void,
) {
    const sub = Notifications.addNotificationResponseReceivedListener(onResponse);
    return () => sub.remove();
}
