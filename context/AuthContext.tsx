import React, { createContext, useContext, useEffect, useState } from 'react';
import * as Linking from 'expo-linking';
import type { User } from '@/types/auth';
import { getStoredUser, storeUser, clearStoredUser } from '@/utils/auth/session';
import {
    loginSchema,
    registerSchema,
    emailSchema,
    profileSchema,
    updatePasswordSchema,
    type RegisterInput,
    type ProfileInput,
} from '@/lib/schemas/auth';

// Session is cookie-based (Lucia). The native HTTP client sends the session
// cookie automatically on every request to the same domain — no bearer token needed.
const AUTH_URL = `${process.env.EXPO_PUBLIC_WEB_API_URL ?? 'https://cheapestgo.com'}/api/auth`;

async function authFetch<T = any>(
    path: string,
    method: string,
    body?: unknown,
): Promise<T> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    console.log(`[authFetch] ${method} ${AUTH_URL}${path}`, body !== undefined ? { body } : '');
    const res = await fetch(`${AUTH_URL}${path}`, {
        method,
        headers,
        credentials: 'include',
        body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const json = await res.json().catch(() => ({}));
    console.log(`[authFetch] ${res.status} ${AUTH_URL}${path}`, json);
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
            console.log('[auth/login] →', { email, url: `${AUTH_URL}/login` });
            try {
                const { user: u } = await authFetch<{ user: any }>('/login', 'POST', { email, password });
                const mapped = mapUser(u);
                console.log('[auth/login] ✓ success', { id: mapped.id, email: mapped.email, role: mapped.role });
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
            console.log('[auth/signup] →', { email: data.email, firstName: data.firstName, lastName: data.lastName, url: `${AUTH_URL}/signup` });
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
                console.log('[auth/signup] ✓ success', { id: mapped.id, email: mapped.email });
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
            await authFetch('/logout', 'POST').catch(() => {});
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
            const { user: u } = await authFetch<{ user: any }>('/profile', 'PATCH', {
                firstName: data.firstName,
                lastName: data.lastName,
            });
            const mapped = mapUser(u);
            await storeUser(mapped);
            setUser(mapped);
        });
    };

    const updatePassword = (currentPassword: string, newPassword: string) => {
        updatePasswordSchema.parse({ currentPassword, newPassword });
        return withLoading(async () => {
            await authFetch('/update-password', 'PATCH', { currentPassword, newPassword });
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
    const handleAuthDeepLink = async (url: string): Promise<void> => {
        if (!url.includes('auth/')) return;
        const parsed = Linking.parse(url);
        const token = parsed.queryParams?.token as string | undefined;
        if (parsed.path?.includes('reset-password') && token) {
            setResetToken(token);
            setIsPasswordRecovery(true);
        }
    };

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
