/**
 * Push notification registration.
 *
 * Uses a lazy require() so that missing native modules (Expo Go, simulators,
 * web) are caught at runtime rather than crashing on the static import.
 */

import { Platform } from 'react-native';
import { WEB_API_URL, MOBILE_API_KEY, APP_VERSION } from './config';

type NotificationsModule = typeof import('expo-notifications');

let Notifications: NotificationsModule | null = null;
try {
    // Optional native module — require()'d in a try/catch so the app degrades
    // gracefully where expo-notifications isn't available.
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    Notifications = require('expo-notifications') as NotificationsModule;
    Notifications.setNotificationHandler({
        handleNotification: async () => ({
            shouldShowAlert: true,
            shouldPlaySound: true,
            shouldSetBadge: false,
            shouldShowBanner: true,
            shouldShowList: true,
        }),
    });
} catch {
    // Native module unavailable — Expo Go, simulator, or web. Push is disabled.
}

export async function registerForPushNotifications(userId?: string): Promise<string | null> {
    if (!Notifications) return null;

    try {
        if (Platform.OS === 'android') {
            await Notifications.setNotificationChannelAsync('default', {
                name: 'CheapestGo',
                importance: Notifications.AndroidImportance.MAX,
                vibrationPattern: [0, 250, 250, 250],
                lightColor: '#2563EB',
            });
        }

        const { status: existingStatus } = await Notifications.getPermissionsAsync();
        let finalStatus = existingStatus;

        if (existingStatus !== 'granted') {
            const { status } = await Notifications.requestPermissionsAsync();
            finalStatus = status;
        }

        if (finalStatus !== 'granted') {
            return null;
        }

        const EAS_PROJECT_ID = 'a438c5b2-ecf9-4bde-a329-7d40658ac43e';
        const { data: token } = await Notifications.getExpoPushTokenAsync({
            projectId: process.env.EXPO_PUBLIC_PROJECT_ID ?? EAS_PROJECT_ID,
        });

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
            console.warn('[notifications] Registration request failed:', err);
        }

        return token;
    } catch {
        return null;
    }
}

export function addForegroundNotificationListener(
    onNotification: (notification: import('expo-notifications').Notification) => void,
) {
    if (!Notifications) return () => {};
    try {
        const sub = Notifications.addNotificationReceivedListener(onNotification);
        return () => sub.remove();
    } catch {
        return () => {};
    }
}

export function addNotificationResponseListener(
    onResponse: (response: import('expo-notifications').NotificationResponse) => void,
) {
    if (!Notifications) return () => {};
    try {
        const sub = Notifications.addNotificationResponseReceivedListener(onResponse);
        return () => sub.remove();
    } catch {
        return () => {};
    }
}
