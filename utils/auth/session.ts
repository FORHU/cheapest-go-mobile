import AsyncStorage from '@react-native-async-storage/async-storage';
import type { User } from '@/types/auth';

// Session is cookie-based (Lucia) — the native HTTP client sends the session
// cookie automatically. We only persist the user object in AsyncStorage so the
// app can restore the UI without a round-trip on every cold start.

const USER_KEY = 'auth_user';

export async function getStoredUser(): Promise<User | null> {
    const raw = await AsyncStorage.getItem(USER_KEY);
    if (!raw) return null;
    try { return JSON.parse(raw) as User; } catch { return null; }
}

export async function storeUser(user: User): Promise<void> {
    await AsyncStorage.setItem(USER_KEY, JSON.stringify(user));
}

export async function clearStoredUser(): Promise<void> {
    await AsyncStorage.removeItem(USER_KEY);
}
