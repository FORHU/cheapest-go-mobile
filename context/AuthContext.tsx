import React, { createContext, useContext, useEffect, useState } from 'react';
import type { Session, User as SupabaseUser } from '@supabase/supabase-js';
import * as WebBrowser from 'expo-web-browser';
import * as Linking from 'expo-linking';
import { supabase } from '@/utils/supabase/client';
import type { User } from '@/types/auth';
import {
  loginSchema,
  registerSchema,
  emailSchema,
  profileSchema,
  updatePasswordSchema,
  type RegisterInput,
  type ProfileInput,
} from '@/lib/schemas/auth';

interface AuthContextValue {
  user: User | null;
  session: Session | null;
  isLoading: boolean;
  isPasswordRecovery: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: RegisterInput) => Promise<{ needsEmailVerification: boolean }>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  resendConfirmation: (email: string) => Promise<void>;
  updateProfile: (data: ProfileInput) => Promise<void>;
  updatePassword: (currentPassword: string, newPassword: string) => Promise<void>;
  confirmPasswordReset: (newPassword: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  handleAuthDeepLink: (url: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const extractUserProfile = (supabaseUser: SupabaseUser): User => {
  const meta = supabaseUser.user_metadata || {};
  return {
    id: supabaseUser.id,
    email: supabaseUser.email || '',
    firstName: meta.first_name || meta.firstName || meta.name?.split(' ')[0] || 'User',
    lastName: meta.last_name || meta.lastName || meta.name?.split(' ').slice(1).join(' ') || '',
    avatar: meta.avatar_url || meta.picture,
    role: meta.role || 'user',
  };
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isPasswordRecovery, setIsPasswordRecovery] = useState(false);

  const syncSession = (s: Session | null) => {
    if (s?.user) {
      setSession(s);
      setUser(extractUserProfile(s.user));
    } else {
      setSession(null);
      setUser(null);
    }
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session: s } }) => {
      syncSession(s);
      setIsLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, s) => {
      syncSession(s);
      setIsLoading(false);
      if (event === 'PASSWORD_RECOVERY') {
        setIsPasswordRecovery(true);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const withLoading = async <T>(fn: () => Promise<T>): Promise<T> => {
    setIsLoading(true);
    try {
      return await fn();
    } finally {
      setIsLoading(false);
    }
  };

  const login = (email: string, password: string) => {
    loginSchema.parse({ email, password });
    return withLoading(async () => {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      if (data.session) syncSession(data.session);
    });
  };

  const register = (data: RegisterInput): Promise<{ needsEmailVerification: boolean }> => {
    registerSchema.parse(data);
    return withLoading(async () => {
      const emailRedirectTo = Linking.createURL('auth/callback');
      const { data: authData, error } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          emailRedirectTo,
          data: {
            first_name: data.firstName,
            last_name: data.lastName,
            full_name: `${data.firstName} ${data.lastName}`,
          },
        },
      });
      if (error) throw error;
      if (authData.session) {
        syncSession(authData.session);
        return { needsEmailVerification: false };
      }
      return { needsEmailVerification: true };
    });
  };

  const logout = () =>
    withLoading(async () => {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      syncSession(null);
      setIsPasswordRecovery(false);
    });

  const resetPassword = (email: string) => {
    emailSchema.parse({ email });
    return withLoading(async () => {
      const redirectTo = Linking.createURL('auth/reset-password');
      const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo });
      if (error) throw error;
    });
  };

  const resendConfirmation = (email: string) => {
    emailSchema.parse({ email });
    return withLoading(async () => {
      const emailRedirectTo = Linking.createURL('auth/callback');
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email,
        options: { emailRedirectTo },
      });
      if (error) throw error;
    });
  };

  const updateProfile = (data: ProfileInput) => {
    profileSchema.parse(data);
    return withLoading(async () => {
      const { data: userData, error } = await supabase.auth.updateUser({
        data: {
          first_name: data.firstName,
          last_name: data.lastName,
          full_name: `${data.firstName} ${data.lastName}`,
        },
      });
      if (error) throw error;
      if (userData.user) setUser(extractUserProfile(userData.user));
    });
  };

  const updatePassword = (currentPassword: string, newPassword: string) => {
    updatePasswordSchema.parse({ currentPassword, newPassword });
    return withLoading(async () => {
      if (!user?.email) throw new Error('No user logged in');
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: user.email,
        password: currentPassword,
      });
      if (signInError) throw new Error('Current password is incorrect');
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) throw error;
    });
  };

  const confirmPasswordReset = (newPassword: string) =>
    withLoading(async () => {
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) throw error;
      setIsPasswordRecovery(false);
    });

  const signInWithGoogle = async () => {
    const redirectUrl = Linking.createURL('auth/callback');

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: redirectUrl, skipBrowserRedirect: true },
    });
    if (error) throw error;
    if (!data.url) throw new Error('No OAuth URL returned');

    const result = await WebBrowser.openAuthSessionAsync(data.url, redirectUrl);

    if (result.type === 'success') {
      const hashPart = result.url.split('#')[1];
      const params = new URLSearchParams(hashPart || '');
      const accessToken = params.get('access_token');
      const refreshToken = params.get('refresh_token');

      if (accessToken && refreshToken) {
        const { data: sessionData, error: sessionError } = await supabase.auth.setSession({
          access_token: accessToken,
          refresh_token: refreshToken,
        });
        if (sessionError) throw sessionError;
        if (sessionData.session) syncSession(sessionData.session);
      }
    }
    // result.type === 'cancel' means user dismissed — not an error
  };

  // Handles deep links from email confirmation and password reset emails.
  // Parses the access/refresh tokens from the URL hash and sets the Supabase session.
  // onAuthStateChange fires PASSWORD_RECOVERY when type=recovery, routing to update-password.
  const handleAuthDeepLink = async (url: string): Promise<void> => {
    if (!url.includes('auth/')) return;

    const fragment = url.split('#')[1] ?? '';
    const params = new URLSearchParams(fragment);
    const accessToken = params.get('access_token');
    const refreshToken = params.get('refresh_token');

    if (!accessToken || !refreshToken) return;

    const { error } = await supabase.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });
    if (error) throw error;
  };

  return (
    <AuthContext.Provider value={{
      user, session, isLoading, isPasswordRecovery,
      login, register, logout, resetPassword,
      resendConfirmation, updateProfile, updatePassword,
      confirmPasswordReset, signInWithGoogle, handleAuthDeepLink,
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
