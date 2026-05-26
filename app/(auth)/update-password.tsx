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
import { useAuth } from '@/context/AuthContext';

export default function UpdatePasswordScreen() {
  const router = useRouter();
  const { confirmPasswordReset, isLoading } = useAuth();

  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [done, setDone] = useState(false);

  const handleUpdate = async () => {
    setError('');
    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }
    if (password !== confirm) {
      setError('Passwords do not match.');
      return;
    }
    try {
      await confirmPasswordReset(password);
      setDone(true);
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
        <View className="flex-1 px-6 pt-12 pb-8">
          {done ? (
            <View className="flex-1 justify-center items-center">
              <View className="w-20 h-20 bg-green-100 rounded-full items-center justify-center mb-6">
                <Text className="text-4xl">✓</Text>
              </View>
              <Text className="text-2xl font-bold text-gray-900 mb-3 text-center">
                Password updated
              </Text>
              <Text className="text-base text-gray-500 text-center mb-10">
                Your password has been changed successfully. You're now signed in.
              </Text>
              <TouchableOpacity
                className="bg-blue-600 rounded-xl py-4 px-10 items-center"
                onPress={() => router.replace('/(tabs)')}
              >
                <Text className="text-white font-semibold text-base">Continue</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <>
              <View className="mb-10">
                <Text className="text-3xl font-bold text-gray-900 mb-2">Set new password</Text>
                <Text className="text-base text-gray-500">
                  Choose a strong password for your account.
                </Text>
              </View>

              <View className="gap-4">
                <View>
                  <Text className="text-sm font-medium text-gray-700 mb-1.5">New password</Text>
                  <TextInput
                    className="border border-gray-300 rounded-xl px-4 py-3.5 text-base text-gray-900 bg-gray-50"
                    placeholder="Min. 8 characters"
                    placeholderTextColor="#9ca3af"
                    value={password}
                    onChangeText={setPassword}
                    secureTextEntry
                    autoComplete="new-password"
                    autoFocus
                  />
                </View>

                <View>
                  <Text className="text-sm font-medium text-gray-700 mb-1.5">Confirm password</Text>
                  <TextInput
                    className="border border-gray-300 rounded-xl px-4 py-3.5 text-base text-gray-900 bg-gray-50"
                    placeholder="Re-enter password"
                    placeholderTextColor="#9ca3af"
                    value={confirm}
                    onChangeText={setConfirm}
                    secureTextEntry
                    autoComplete="new-password"
                  />
                </View>

                {error ? (
                  <View className="bg-red-50 border border-red-200 rounded-xl px-4 py-3">
                    <Text className="text-sm text-red-600">{error}</Text>
                  </View>
                ) : null}

                <TouchableOpacity
                  className="bg-blue-600 rounded-xl py-4 items-center mt-2"
                  onPress={handleUpdate}
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <ActivityIndicator color="#fff" />
                  ) : (
                    <Text className="text-white font-semibold text-base">Update password</Text>
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
