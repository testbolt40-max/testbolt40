import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View, Text, StyleSheet } from 'react-native';
import { useAuth } from '@/hooks/useAuth';
import { router, useNavigationContainerRef, useSegments } from 'expo-router';
import { useFrameworkReady } from '@/hooks/useFrameworkReady';
import { useState } from 'react';

// Error Boundary Component
function ErrorFallback({ error }: { error: Error }) {
  return (
    <View style={styles.errorContainer}>
      <Text style={styles.errorTitle}>Something went wrong</Text>
      <Text style={styles.errorMessage}>{error.message}</Text>
    </View>
  );
}

export default function RootLayout() {
  useFrameworkReady();
  const { user, userType, loading } = useAuth();
  const [isNavigationReady, setIsNavigationReady] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const navigationRef = useNavigationContainerRef();
  const segments = useSegments();

  // Catch any errors during initialization
  useEffect(() => {
    const handleError = (error: Error) => {
      console.error('App initialization error:', error);
      setError(error);
    };

    // Global error handler
    const originalConsoleError = console.error;
    console.error = (...args) => {
      originalConsoleError(...args);
      if (args[0] instanceof Error) {
        handleError(args[0]);
      }
    };

    return () => {
      console.error = originalConsoleError;
    };
  }, []);

  useEffect(() => {
    const unsubscribe = navigationRef.addListener('state', () => {
      setIsNavigationReady(true);
    });

    return unsubscribe;
  }, [navigationRef]);

  useEffect(() => {
    try {
    if (loading) {
      return;
    }

    if (!isNavigationReady) {
      return;
    }

    console.log('Auth routing check:', { 
      hasUser: !!user, 
      userType, 
      currentSegments: segments,
      userEmail: user?.email 
    });
    
    const inAuthGroup = segments[0] === '(auth)';
    const inTabsGroup = segments[0] === '(tabs)';
    const inDriverGroup = segments[0] === '(driver)';
    const inAdminGroup = segments[0] === '(admin)';

    // If no user, redirect to login
    if (!user && !inAuthGroup) {
      console.log('No user found, redirecting to login');
      router.replace('/(auth)/login');
      return;
    }
    
    // If user is authenticated but in auth group, redirect to appropriate dashboard
    if (user && inAuthGroup) {
      console.log('User authenticated, routing to correct interface for:', userType);
      
      if (userType === 'driver') {
        console.log('Redirecting driver to driver dashboard');
        router.replace('/(driver)/(tabs)/dashboard');
      } else if (userType === 'admin') {
        console.log('Redirecting admin to admin dashboard');
        router.replace('/(admin)/dashboard');
      } else {
        console.log('Redirecting passenger to passenger interface');
        router.replace('/(tabs)');
      }
      return;
    }

    // If user is in wrong section based on their type, redirect them
    if (user && userType) {
      let shouldRedirect = false;
      let redirectPath = '';

      if (userType === 'driver' && !inDriverGroup) {
        console.log('Driver in wrong section, redirecting to driver interface');
        shouldRedirect = true;
        redirectPath = '/(driver)/(tabs)/dashboard';
      } else if (userType === 'admin' && !inAdminGroup) {
        console.log('Admin in wrong section, redirecting to admin interface');
        shouldRedirect = true;
        redirectPath = '/(admin)/dashboard';
      } else if (userType === 'passenger' && !inTabsGroup) {
        console.log('Passenger in wrong section, redirecting to passenger interface');
        shouldRedirect = true;
        redirectPath = '/(tabs)';
      }

      if (shouldRedirect) {
        router.replace(redirectPath);
      }
    }
    } catch (error) {
      console.error('Navigation error:', error);
      setError(error as Error);
    }
  }, [user, userType, loading, segments, isNavigationReady]);

  // Show error screen if there's an error
  if (error) {
    return <ErrorFallback error={error} />;
  }

  // Show loading screen while initializing
  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  return (
    <>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="(driver)" />
        <Stack.Screen name="(admin)" />
        <Stack.Screen name="+not-found" />
      </Stack>
      <StatusBar style="auto" />
    </>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  loadingText: {
    fontSize: 16,
    color: '#6B7280',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 20,
  },
  errorTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#DC2626',
    marginBottom: 8,
  },
  errorMessage: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
});
