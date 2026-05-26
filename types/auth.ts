import type { User as SupabaseUser, Session } from '@supabase/supabase-js';

export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  avatar?: string;
  role?: 'user' | 'admin';
}

export type AuthStep = 'email' | 'password' | 'register' | 'forgot-password' | 'verify-email';

export type SocialProvider = 'google' | 'apple' | 'facebook';

export type { SupabaseUser, Session };
