export interface User {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    avatar?: string;
    role?: 'user' | 'admin';
}

export type AuthStep = 'email' | 'password' | 'register' | 'forgot-password';
export type SocialProvider = 'google' | 'apple' | 'facebook';
