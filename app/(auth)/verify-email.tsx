import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '@/context/AuthContext';

export default function VerifyEmailScreen() {
  const router = useRouter();
  const { email } = useLocalSearchParams<{ email: string }>();
  const { resendConfirmation, isLoading } = useAuth();

  const [resent, setResent] = useState(false);
  const [error, setError] = useState('');

  const handleResend = async () => {
    if (!email) return;
    setError('');
    try {
      await resendConfirmation(email);
      setResent(true);
    } catch (e: any) {
      setError(e?.message || 'Failed to resend. Please try again.');
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-white">
      <View className="flex-1 justify-center items-center px-6">
        <View className="w-20 h-20 bg-blue-100 rounded-full items-center justify-center mb-6">
          <Text className="text-4xl">✉️</Text>
        </View>

        <Text className="text-2xl font-bold text-gray-900 mb-3 text-center">Verify your email</Text>
        <Text className="text-base text-gray-500 text-center mb-2">
          We sent a confirmation link to
        </Text>
        {email ? (
          <Text className="text-base font-semibold text-gray-700 text-center mb-8">{email}</Text>
        ) : null}
        <Text className="text-sm text-gray-400 text-center mb-10">
          Click the link in the email to activate your account. Check your spam folder if you don't see it.
        </Text>

        {error ? (
          <View className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 mb-4 w-full">
            <Text className="text-sm text-red-600 text-center">{error}</Text>
          </View>
        ) : null}

        {resent ? (
          <View className="bg-green-50 border border-green-200 rounded-xl px-4 py-3 mb-6 w-full">
            <Text className="text-sm text-green-600 text-center">Confirmation email resent!</Text>
          </View>
        ) : (
          <TouchableOpacity
            className="mb-4"
            onPress={handleResend}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#2563eb" />
            ) : (
              <Text className="text-blue-600 font-semibold text-base">Resend email</Text>
            )}
          </TouchableOpacity>
        )}

        <TouchableOpacity onPress={() => router.replace('/(auth)/login')}>
          <Text className="text-gray-500 text-sm">Back to sign in</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}
