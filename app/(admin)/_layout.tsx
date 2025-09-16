import { Stack } from 'expo-router';

export default function AdminLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="dashboard" />
      <Stack.Screen name="drivers" />
      <Stack.Screen name="applications" />
      <Stack.Screen name="settings" />
      <Stack.Screen name="analytics" />
    </Stack>
  );
}