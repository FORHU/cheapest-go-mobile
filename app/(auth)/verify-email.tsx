import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function VerifyEmailScreen() {
  const router = useRouter();
  const { email } = useLocalSearchParams<{ email: string }>();

  return (
    <SafeAreaView className="flex-1 bg-white">
      <View className="flex-1 justify-center items-center px-6">
        <View className="w-20 h-20 bg-blue-100 rounded-full items-center justify-center mb-6">
          <Text className="text-4xl">✉️</Text>
        </View>

        <Text className="text-2xl font-bold text-gray-900 mb-3 text-center">Check your email</Text>
        <Text className="text-base text-gray-500 text-center mb-2">
          We sent a confirmation link to
        </Text>
        {email ? (
          <Text className="text-base font-semibold text-gray-700 text-center mb-8">{email}</Text>
        ) : null}
        <Text className="text-sm text-gray-400 text-center mb-10">
          Click the link in the email to activate your account. Check your spam folder if you don't see it.
        </Text>

        <TouchableOpacity onPress={() => router.replace('/(auth)/login')}>
          <Text className="text-blue-600 font-semibold text-base">Back to sign in</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}
