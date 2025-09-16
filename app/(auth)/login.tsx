import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StatusBar,
  Animated,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Link, router } from 'expo-router';
import { Mail, Lock, Eye, EyeOff, Users, Car, Shield, ArrowRight } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '@/hooks/useAuth';
import { isSupabaseConfigured } from '@/lib/supabase';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [fadeAnim] = useState(new Animated.Value(0));
  const { signIn } = useAuth();

  React.useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 800,
      useNativeDriver: true,
    }).start();
  }, []);

  // Check if Supabase is configured
  if (!isSupabaseConfigured()) {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="light-content" backgroundColor="transparent" translucent />
        <LinearGradient colors={['#000000', '#1F2937']} style={styles.gradient}>
          <View style={styles.configurationMessage}>
            <View style={styles.logoContainer}>
              <Car size={32} color="#FFFFFF" />
            </View>
            <Text style={styles.configTitle}>Setup Required</Text>
            <Text style={styles.configMessage}>
              Please configure your Supabase credentials to use authentication features.
            </Text>
            <Text style={styles.configInstructions}>
              Click "Connect to Supabase" in the top right corner or update credentials in app.json
            </Text>
          </View>
        </LinearGradient>
      </SafeAreaView>
    );
  }

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert('Missing Information', 'Please enter both email and password');
      return;
    }

    setLoading(true);
    const { error } = await signIn(email, password);
    setLoading(false);

    if (error) {
      if (error.message.includes('Email not confirmed') || error.message.includes('email_not_confirmed') || error.message.includes('Email link is invalid or has expired')) {
        Alert.alert(
          'Email Not Confirmed',
          'For testing purposes, you can use these pre-configured accounts:\n\nPassenger: test@passenger.com / password123\nDriver: test@driver.com / password123\nAdmin: admin@rideshare.com / admin123\n\nOr check your email for the confirmation link.',
          [{ text: 'OK' }]
        );
      } else if (error.message.includes('Invalid login credentials')) {
        Alert.alert(
          'Login Failed', 
          'Invalid email or password. Try these test accounts:\n\nPassenger: test@passenger.com / password123\nDriver: test@driver.com / password123\nAdmin: admin@rideshare.com / admin123'
        );
      } else {
        Alert.alert('Login Failed', error.message);
      }
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent />
      
      <LinearGradient colors={['#000000', '#1F2937']} style={styles.gradient}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
            {/* Header */}
            <Animated.View style={[styles.header, { opacity: fadeAnim }]}>
              <View style={styles.logoContainer}>
                <Car size={32} color="#FFFFFF" />
              </View>
              <Text style={styles.appTitle}>RideShare</Text>
              <Text style={styles.welcomeText}>Welcome back</Text>
            </Animated.View>


            {/* Login Form */}
            <Animated.View style={[styles.formContainer, { opacity: fadeAnim }]}>
              <View style={styles.formCard}>
                {/* Email Input */}
                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Email</Text>
                  <View style={styles.inputContainer}>
                    <Mail size={20} color="#9CA3AF" />
                    <TextInput
                      style={styles.input}
                      placeholder="Enter your email"
                      placeholderTextColor="#9CA3AF"
                      value={email}
                      onChangeText={setEmail}
                      keyboardType="email-address"
                      autoCapitalize="none"
                      autoComplete="email"
                    />
                  </View>
                </View>

                {/* Password Input */}
                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Password</Text>
                  <View style={styles.inputContainer}>
                    <Lock size={20} color="#9CA3AF" />
                    <TextInput
                      style={styles.input}
                      placeholder="Enter your password"
                      placeholderTextColor="#9CA3AF"
                      value={password}
                      onChangeText={setPassword}
                      secureTextEntry={!showPassword}
                      autoComplete="password"
                    />
                    <TouchableOpacity
                      style={styles.eyeButton}
                      onPress={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOff size={20} color="#9CA3AF" />
                      ) : (
                        <Eye size={20} color="#9CA3AF" />
                      )}
                    </TouchableOpacity>
                  </View>
                </View>

                {/* Forgot Password */}
                <TouchableOpacity style={styles.forgotPassword}>
                  <Text style={styles.forgotPasswordText}>Forgot your password?</Text>
                </TouchableOpacity>

                {/* Login Button */}
                <TouchableOpacity
                  style={[styles.loginButton, loading && styles.loginButtonDisabled]}
                  onPress={handleLogin}
                  disabled={loading}
                >
                  <LinearGradient
                    colors={loading ? ['#9CA3AF', '#6B7280'] : ['#000000', '#374151']}
                    style={styles.buttonGradient}
                  >
                    <Text style={styles.loginButtonText}>
                      {loading ? 'Signing In...' : 'Sign In'}
                    </Text>
                    {!loading && <ArrowRight size={20} color="#FFFFFF" />}
                  </LinearGradient>
                </TouchableOpacity>
              </View>
            </Animated.View>

            {/* Sign Up Link */}
            <Animated.View style={[styles.signupSection, { opacity: fadeAnim }]}>
              <Text style={styles.signupText}>Don't have an account?</Text>
              <Link href="/(auth)/signup" asChild>
                <TouchableOpacity style={styles.signupButton}>
                  <Text style={styles.signupButtonText}>Create Account</Text>
                </TouchableOpacity>
              </Link>
            </Animated.View>
          </ScrollView>
        </KeyboardAvoidingView>
      </LinearGradient>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 40,
  },
  
  // Header
  header: {
    alignItems: 'center',
    marginBottom: 40,
  },
  logoContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: 'rgba(255,255,255,0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  appTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 8,
    letterSpacing: -0.5,
  },
  welcomeText: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
  },

  // Configuration Message
  configurationMessage: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  configTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFFFFF',
    marginTop: 20,
    marginBottom: 16,
    textAlign: 'center',
  },
  configMessage: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 20,
  },
  configInstructions: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
    textAlign: 'center',
    lineHeight: 20,
  },


  // Form Container
  formContainer: {
    flex: 1,
  },
  formCard: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 24,
    padding: 24,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },

  // Input Groups
  inputGroup: {
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  input: {
    flex: 1,
    fontSize: 16,
    color: '#FFFFFF',
    paddingVertical: 16,
    marginLeft: 12,
  },
  eyeButton: {
    padding: 8,
  },

  // Forgot Password
  forgotPassword: {
    alignSelf: 'center',
    marginBottom: 24,
  },
  forgotPasswordText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
    fontWeight: '500',
  },

  // Login Button
  loginButton: {
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  loginButtonDisabled: {
    opacity: 0.6,
  },
  buttonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 18,
    gap: 8,
  },
  loginButtonText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },

  // Signup Section
  signupSection: {
    alignItems: 'center',
    marginTop: 32,
  },
  signupText: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.7)',
    marginBottom: 12,
  },
  signupButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  signupButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});