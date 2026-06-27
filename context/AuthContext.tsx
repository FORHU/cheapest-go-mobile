import {
    emailSchema,
    loginSchema,
    profileSchema,
    registerSchema,
    updatePasswordSchema,
    type ProfileInput,
    type RegisterInput,
} from '@/lib/schemas/auth';
import type { User } from '@/types/auth';
import { clearStoredUser, getStoredUser, storeUser } from '@/utils/auth/session';
import * as Linking from 'expo-linking';
import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';

// Session is cookie-based (Lucia). The native HTTP client sends the session
// cookie automatically on every request to the same domain — no bearer token needed.
const AUTH_URL = `${process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com'}/api/auth`;

async function authFetch<T = any>(
    path: string,
    method: string,
    body?: unknown,
): Promise<T> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    const res = await fetch(`${AUTH_URL}${path}`, {
        method,
        headers,
        credentials: 'include',
        body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const json = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(json.error ?? json.message ?? `HTTP ${res.status}`);
    return json as T;
}

// Maps the server's user shape to our internal User type.
function mapUser(u: any, fallback?: Partial<User>): User {
    return {
        id: u.id,
        email: u.email ?? fallback?.email ?? '',
        firstName: u.firstName ?? u.first_name ?? fallback?.firstName ?? '',
        lastName: u.lastName ?? u.last_name ?? fallback?.lastName ?? '',
        avatar: u.avatarUrl ?? u.avatar_url ?? fallback?.avatar,
        role: u.role ?? fallback?.role ?? 'user',
    };
}

interface AuthContextValue {
    user: User | null;
    isLoading: boolean;
    isPasswordRecovery: boolean;
    login: (email: string, password: string) => Promise<void>;
    register: (data: RegisterInput) => Promise<{ needsEmailVerification: boolean }>;
    logout: () => Promise<void>;
    resetPassword: (email: string) => Promise<void>;
    updateProfile: (data: ProfileInput) => Promise<void>;
    updatePassword: (currentPassword: string, newPassword: string) => Promise<void>;
    confirmPasswordReset: (newPassword: string) => Promise<void>;
    handleAuthDeepLink: (url: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isPasswordRecovery, setIsPasswordRecovery] = useState(false);
    const [resetToken, setResetToken] = useState<string | null>(null);

    // Restore session on mount: load cached user, then validate with the server.
    useEffect(() => {
        (async () => {
            try {
                const cached = await getStoredUser();
                if (cached) setUser(cached);

                // Validate the session cookie is still active.
                const { user: fresh } = await authFetch<{ user: any }>('/me', 'GET');
                if (fresh) {
                    const mapped = mapUser(fresh);
                    setUser(mapped);
                    await storeUser(mapped);
                } else {
                    await clearStoredUser();
                    setUser(null);
                }
            } catch {
                // Session expired or no session — clear local state.
                await clearStoredUser();
                setUser(null);
            } finally {
                setIsLoading(false);
            }
        })();
    }, []);

    const withLoading = async <T,>(fn: () => Promise<T>): Promise<T> => {
        setIsLoading(true);
        try { return await fn(); }
        finally { setIsLoading(false); }
    };

    const login = (email: string, password: string) => {
        loginSchema.parse({ email, password });
        return withLoading(async () => {
            try {
                const { user: u } = await authFetch<{ user: any }>('/login', 'POST', { email, password });
                const mapped = mapUser(u);

                // Fetch preferences to populate firstName/lastName immediately
                const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
                const prefRes = await fetch(`${BASE}/api/preferences`, {
                    method: 'GET',
                    credentials: 'include',
                });
                if (prefRes.ok) {
                    const { preferences } = await prefRes.json();
                    mapped.firstName = preferences?.firstName ?? mapped.firstName;
                    mapped.lastName = preferences?.lastName ?? mapped.lastName;
                }

                await storeUser(mapped);
                setUser(mapped);
            } catch (err: any) {
                console.error('[auth/login] ✗ failed', { message: err.message });
                throw err;
            }
        });
    };

    const register = (data: RegisterInput): Promise<{ needsEmailVerification: boolean }> => {
        registerSchema.parse(data);
        return withLoading(async () => {
            try {
                const { user: u } = await authFetch<{ user: any }>('/signup', 'POST', {
                    email: data.email,
                    password: data.password,
                    firstName: data.firstName,
                    lastName: data.lastName,
                });
                const mapped = mapUser(u, {
                    firstName: data.firstName,
                    lastName: data.lastName,
                    role: 'user',
                });
                await storeUser(mapped);
                setUser(mapped);
                return { needsEmailVerification: false };
            } catch (err: any) {
                console.error('[auth/signup] ✗ failed', { message: err.message });
                throw err;
            }
        });
    };

    const logout = () =>
        withLoading(async () => {
            await authFetch('/logout', 'POST').catch(() => { });
            await clearStoredUser();
            setUser(null);
            setIsPasswordRecovery(false);
        });

    const resetPassword = (email: string) => {
        emailSchema.parse({ email });
        return withLoading(async () => {
            await authFetch('/reset-password', 'POST', { email });
        });
    };

    const updateProfile = (data: ProfileInput) => {
        profileSchema.parse(data);
        return withLoading(async () => {
            const BASE = process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com';
            const res = await fetch(`${BASE}/api/preferences`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify({
                    firstName: data.firstName,
                    lastName: data.lastName,
                }),
            });
            if (!res.ok) {
                const json = await res.json().catch(() => ({}));
                throw new Error(json.error ?? `HTTP ${res.status}`);
            }
            // Update local state optimistically — same pattern as web authStore
            const updated = {
                ...user!,
                firstName: data.firstName ?? user!.firstName,
                lastName: data.lastName ?? user!.lastName,
            };
            setUser(updated);
            await storeUser(updated);
        });
    };

    const updatePassword = (currentPassword: string, newPassword: string) => {
        updatePasswordSchema.parse({ currentPassword, newPassword });
        return withLoading(async () => {
            if (!user?.email) throw new Error('No user logged in');

            // verify current password — same as web
            await authFetch('/login', 'POST', {
                email: user.email,
                password: currentPassword,
            });

            await authFetch('/reset-password', 'PUT', {
                token: '__current__',
                password: newPassword,
            });
        });
    };

    // Confirms a password reset using a token from the deep link.
    // The web backend handles this via PUT /api/auth/reset-password.
    const confirmPasswordReset = (newPassword: string) =>
        withLoading(async () => {
            if (!resetToken) throw new Error('No reset token. Request a new password reset link.');
            await authFetch('/reset-password', 'PUT', { token: resetToken, password: newPassword });
            setResetToken(null);
            setIsPasswordRecovery(false);
        });

    // Handles deep links from password reset emails.
    // Expected format: mobileapp://auth/reset-password?token=<token>
    const handleAuthDeepLink = useCallback(async (url: string): Promise<void> => {
        if (!url.includes('auth/')) return;
        const parsed = Linking.parse(url);
        const token = parsed.queryParams?.token as string | undefined;
        if (parsed.path?.includes('reset-password') && token) {
            setResetToken(token);
            setIsPasswordRecovery(true);
        }
    }, []);

    return (
        <AuthContext.Provider value={{
            user, isLoading, isPasswordRecovery,
            login, register, logout, resetPassword,
            updateProfile, updatePassword, confirmPasswordReset,
            handleAuthDeepLink,
        }}>
            {children}
        </AuthContext.Provider>
    );
}

export const useAuth = () => {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used within AuthProvider');
    return ctx;
};