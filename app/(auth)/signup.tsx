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
import { Mail, Lock, User, Eye, EyeOff, ArrowRight, Car, Users, Shield } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '@/hooks/useAuth';
import { UserType } from '@/types/database';

export default function SignupScreen() {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [selectedUserType, setSelectedUserType] = useState<UserType>('passenger');
  const [loading, setLoading] = useState(false);
  const [fadeAnim] = useState(new Animated.Value(0));
  const { signUp } = useAuth();

  React.useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 800,
      useNativeDriver: true,
    }).start();
  }, []);

  const handleSignup = async () => {
    if (!fullName || !email || !password || !confirmPassword) {
      Alert.alert('Missing Information', 'Please fill in all fields');
      return;
    }

    if (password !== confirmPassword) {
      Alert.alert('Password Mismatch', 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      Alert.alert('Weak Password', 'Password must be at least 6 characters');
      return;
    }

    setLoading(true);
    const { error } = await signUp(email, password, fullName, selectedUserType);
    setLoading(false);

    if (error) {
      Alert.alert('Signup Failed', error.message);
    } else {
      Alert.alert(
        'Account Created!',
        'Your account has been created successfully. You can now sign in.',
        [{ text: 'OK', onPress: () => router.push('/(auth)/login') }]
      );
    }
  };

  const getUserTypeIcon = (type: UserType) => {
    switch (type) {
      case 'passenger':
        return <Users size={18} color={selectedUserType === type ? '#FFFFFF' : '#3B82F6'} />;
      case 'driver':
        return <Car size={18} color={selectedUserType === type ? '#FFFFFF' : '#10B981'} />;
      case 'admin':
        return <Shield size={18} color={selectedUserType === type ? '#FFFFFF' : '#DC2626'} />;
    }
  };

  const getUserTypeColor = (type: UserType) => {
    switch (type) {
      case 'passenger':
        return 'rgba(59, 130, 246, 0.2)';
      case 'driver':
        return 'rgba(16, 185, 129, 0.2)';
      case 'admin':
        return 'rgba(220, 38, 38, 0.2)';
    }
  };

  const getUserTypeBorderColor = (type: UserType) => {
    switch (type) {
      case 'passenger':
        return 'rgba(59, 130, 246, 0.3)';
      case 'driver':
        return 'rgba(16, 185, 129, 0.3)';
      case 'admin':
        return 'rgba(220, 38, 38, 0.3)';
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
              <Text style={styles.welcomeText}>Create your account</Text>
            </Animated.View>

            {/* Signup Form */}
            <Animated.View style={[styles.formContainer, { opacity: fadeAnim }]}>
              <View style={styles.formCard}>
                {/* User Type Selection */}
                <View style={styles.userTypeSection}>
                  <Text style={styles.userTypeTitle}>I want to be a:</Text>
                  <View style={styles.userTypeGrid}>
                    {(['passenger', 'driver', 'admin'] as UserType[]).map((type) => (
                      <TouchableOpacity
                        key={type}
                        style={[
                          styles.userTypeCard,
                          { 
                            backgroundColor: selectedUserType === type ? 'rgba(255,255,255,0.15)' : getUserTypeColor(type),
                            borderColor: selectedUserType === type ? 'rgba(255,255,255,0.3)' : getUserTypeBorderColor(type),
                          }
                        ]}
                        onPress={() => setSelectedUserType(type)}
                      >
                        {getUserTypeIcon(type)}
                        <Text style={[
                          styles.userTypeText,
                          selectedUserType === type && styles.selectedUserTypeText
                        ]}>
                          {type.charAt(0).toUpperCase() + type.slice(1)}
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                </View>

                {/* Full Name Input */}
                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Full Name</Text>
                  <View style={styles.inputContainer}>
                    <User size={20} color="#9CA3AF" />
                    <TextInput
                      style={styles.input}
                      placeholder="Enter your full name"
                      placeholderTextColor="#9CA3AF"
                      value={fullName}
                      onChangeText={setFullName}
                      autoCapitalize="words"
                      autoComplete="name"
                    />
                  </View>
                </View>

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
                      placeholder="Create a password"
                      placeholderTextColor="#9CA3AF"
                      value={password}
                      onChangeText={setPassword}
                      secureTextEntry={!showPassword}
                      autoComplete="new-password"
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

                {/* Confirm Password Input */}
                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Confirm Password</Text>
                  <View style={styles.inputContainer}>
                    <Lock size={20} color="#9CA3AF" />
                    <TextInput
                      style={styles.input}
                      placeholder="Confirm your password"
                      placeholderTextColor="#9CA3AF"
                      value={confirmPassword}
                      onChangeText={setConfirmPassword}
                      secureTextEntry={!showConfirmPassword}
                      autoComplete="new-password"
                    />
                    <TouchableOpacity
                      style={styles.eyeButton}
                      onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                    >
                      {showConfirmPassword ? (
                        <EyeOff size={20} color="#9CA3AF" />
                      ) : (
                        <Eye size={20} color="#9CA3AF" />
                      )}
                    </TouchableOpacity>
                  </View>
                </View>

                {/* Terms */}
                <View style={styles.termsSection}>
                  <Text style={styles.termsText}>
                    By creating an account, you agree to our{' '}
                    <Text style={styles.termsLink}>Terms of Service</Text> and{' '}
                    <Text style={styles.termsLink}>Privacy Policy</Text>
                  </Text>
                </View>

                {/* Signup Button */}
                <TouchableOpacity
                  style={[styles.signupButton, loading && styles.signupButtonDisabled]}
                  onPress={handleSignup}
                  disabled={loading}
                >
                  <LinearGradient
                    colors={loading ? ['#9CA3AF', '#6B7280'] : ['#000000', '#374151']}
                    style={styles.buttonGradient}
                  >
                    <Text style={styles.signupButtonText}>
                      {loading ? 'Creating Account...' : 'Create Account'}
                    </Text>
                    {!loading && <ArrowRight size={20} color="#FFFFFF" />}
                  </LinearGradient>
                </TouchableOpacity>
              </View>
            </Animated.View>

            {/* Login Link */}
            <Animated.View style={[styles.loginSection, { opacity: fadeAnim }]}>
              <Text style={styles.loginText}>Already have an account?</Text>
              <Link href="/(auth)/login" asChild>
                <TouchableOpacity style={styles.loginButton}>
                  <Text style={styles.loginButtonText}>Sign In</Text>
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

  // User Type Selection
  userTypeSection: {
    marginBottom: 24,
  },
  userTypeTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 12,
    textAlign: 'center',
  },
  userTypeGrid: {
    flexDirection: 'row',
    gap: 8,
  },
  userTypeCard: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderRadius: 12,
    borderWidth: 1,
    gap: 6,
  },
  userTypeText: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.7)',
  },
  selectedUserTypeText: {
    color: '#FFFFFF',
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

  // Terms
  termsSection: {
    marginBottom: 24,
  },
  termsText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'center',
    lineHeight: 18,
  },
  termsLink: {
    color: '#FFFFFF',
    fontWeight: '600',
  },

  // Signup Button
  signupButton: {
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  signupButtonDisabled: {
    opacity: 0.6,
  },
  buttonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 18,
    gap: 8,
  },
  signupButtonText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },

  // Login Section
  loginSection: {
    alignItems: 'center',
    marginTop: 32,
  },
  loginText: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.7)',
    marginBottom: 12,
  },
  loginButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  loginButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});