import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ChevronLeft } from 'lucide-react-native';
import { useAuth } from '@/context/AuthContext';

export default function ForgotPasswordScreen() {
  const router = useRouter();
  const { resetPassword, isLoading } = useAuth();

  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  const handleReset = async () => {
    setError('');
    try {
      await resetPassword(email.trim());
      setSent(true);
    } catch (e: any) {
      setError(e?.message || 'Something went wrong. Please try again.');
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-white">
      <KeyboardAvoidingView
        className="flex-1"
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <View className="flex-1 px-6 pt-4 pb-8">
          <TouchableOpacity className="mb-8 self-start" onPress={() => router.back()}>
            <ChevronLeft size={28} color="#374151" />
          </TouchableOpacity>

          {sent ? (
            <View className="flex-1 justify-center items-center">
              <View className="w-16 h-16 bg-blue-100 rounded-full items-center justify-center mb-6">
                <Text className="text-3xl">📧</Text>
              </View>
              <Text className="text-2xl font-bold text-gray-900 mb-3 text-center">Check your email</Text>
              <Text className="text-base text-gray-500 text-center mb-8">
                We sent a password reset link to{'\n'}
                <Text className="font-semibold text-gray-700">{email}</Text>
              </Text>
              <TouchableOpacity onPress={() => router.replace('/(auth)/login')}>
                <Text className="text-blue-600 font-semibold text-base">Back to sign in</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <>
              <View className="mb-10">
                <Text className="text-3xl font-bold text-gray-900 mb-2">Reset password</Text>
                <Text className="text-base text-gray-500">
                  Enter your email and we'll send you a link to reset your password.
                </Text>
              </View>

              <View className="gap-4">
                <View>
                  <Text className="text-sm font-medium text-gray-700 mb-1.5">Email</Text>
                  <TextInput
                    className="border border-gray-300 rounded-xl px-4 py-3.5 text-base text-gray-900 bg-gray-50"
                    placeholder="you@example.com"
                    placeholderTextColor="#9ca3af"
                    value={email}
                    onChangeText={setEmail}
                    autoCapitalize="none"
                    keyboardType="email-address"
                    autoComplete="email"
                  />
                </View>

                {error ? (
                  <View className="bg-red-50 border border-red-200 rounded-xl px-4 py-3">
                    <Text className="text-sm text-red-600">{error}</Text>
                  </View>
                ) : null}

                <TouchableOpacity
                  className="bg-blue-600 rounded-xl py-4 items-center mt-2"
                  onPress={handleReset}
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <ActivityIndicator color="#fff" />
                  ) : (
                    <Text className="text-white font-semibold text-base">Send reset link</Text>
                  )}
                </TouchableOpacity>
              </View>
            </>
          )}
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
