import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Animated,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { 
  MapPin, 
  Car, 
  Shield, 
  Clock, 
  Star, 
  Users, 
  CreditCard, 
  Smartphone,
  ArrowRight,
  CheckCircle,
  Zap
} from 'lucide-react-native';
import { router } from 'expo-router';

const { width, height } = Dimensions.get('window');

export default function LandingPage() {
  const [fadeAnim] = useState(new Animated.Value(0));
  const [slideAnim] = useState(new Animated.Value(50));

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 800,
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 800,
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  const features = [
    {
      icon: MapPin,
      title: 'Real-time Tracking',
      description: 'Track your ride in real-time with live GPS updates',
      color: '#3B82F6',
    },
    {
      icon: Shield,
      title: 'Safe & Secure',
      description: 'All drivers are verified with background checks',
      color: '#10B981',
    },
    {
      icon: Clock,
      title: 'Quick Booking',
      description: 'Book a ride in seconds with our easy-to-use app',
      color: '#F59E0B',
    },
    {
      icon: CreditCard,
      title: 'Cashless Payments',
      description: 'Secure payments with multiple payment options',
      color: '#8B5CF6',
    },
  ];

  const stats = [
    { number: '1M+', label: 'Happy Riders' },
    { number: '50K+', label: 'Verified Drivers' },
    { number: '100+', label: 'Cities' },
    { number: '4.9★', label: 'App Rating' },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent={true} />
      
      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {/* Hero Section */}
        <Animated.View 
          style={[
            styles.heroSection, 
            { 
              opacity: fadeAnim,
              transform: [{ translateY: slideAnim }]
            }
          ]}
        >
          <LinearGradient
            colors={['#1F2937', '#111827']}
            style={styles.heroGradient}
          >
            <View style={styles.heroContent}>
              <View style={styles.heroHeader}>
                <View style={styles.logoContainer}>
                  <Car size={32} color="#FFFFFF" />
                  <Text style={styles.logoText}>RideShare</Text>
                </View>
              </View>
              
              <View style={styles.heroMain}>
                <Text style={styles.heroTitle}>
                  Your ride is just a{'\n'}
                  <Text style={styles.heroTitleAccent}>tap away</Text>
                </Text>
                <Text style={styles.heroSubtitle}>
                  Safe, reliable, and affordable rides in your city. 
                  Join millions of riders worldwide.
                </Text>
                
                <View style={styles.heroButtons}>
                  <TouchableOpacity 
                    style={styles.primaryButton}
                    onPress={() => router.push('/(auth)/signup')}
                  >
                    <Text style={styles.primaryButtonText}>Get Started</Text>
                    <ArrowRight size={20} color="#FFFFFF" />
                  </TouchableOpacity>
                  
                  <TouchableOpacity 
                    style={styles.secondaryButton}
                    onPress={() => router.push('/(auth)/login')}
                  >
                    <Text style={styles.secondaryButtonText}>Sign In</Text>
                  </TouchableOpacity>
                </View>
              </View>
              
              {/* Floating Car Animation */}
              <View style={styles.heroIllustration}>
                <Animated.View 
                  style={[
                    styles.floatingCar,
                    {
                      transform: [{
                        translateY: fadeAnim.interpolate({
                          inputRange: [0, 1],
                          outputRange: [20, 0]
                        })
                      }]
                    }
                  ]}
                >
                  <LinearGradient
                    colors={['#3B82F6', '#1D4ED8']}
                    style={styles.carIcon}
                  >
                    <Car size={40} color="#FFFFFF" />
                  </LinearGradient>
                </Animated.View>
              </View>
            </View>
          </LinearGradient>
        </Animated.View>

        {/* Stats Section */}
        <Animated.View 
          style={[
            styles.statsSection,
            { opacity: fadeAnim }
          ]}
        >
          <View style={styles.statsContainer}>
            {stats.map((stat, index) => (
              <View key={index} style={styles.statItem}>
                <Text style={styles.statNumber}>{stat.number}</Text>
                <Text style={styles.statLabel}>{stat.label}</Text>
              </View>
            ))}
          </View>
        </Animated.View>

        {/* Features Section */}
        <Animated.View 
          style={[
            styles.featuresSection,
            { opacity: fadeAnim }
          ]}
        >
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Why Choose RideShare?</Text>
            <Text style={styles.sectionSubtitle}>
              Experience the future of transportation with our premium features
            </Text>
          </View>
          
          <View style={styles.featuresGrid}>
            {features.map((feature, index) => (
              <Animated.View
                key={index}
                style={[
                  styles.featureCard,
                  {
                    transform: [{
                      translateY: fadeAnim.interpolate({
                        inputRange: [0, 1],
                        outputRange: [30, 0]
                      })
                    }]
                  }
                ]}
              >
                <View style={[styles.featureIcon, { backgroundColor: `${feature.color}15` }]}>
                  <feature.icon size={24} color={feature.color} />
                </View>
                <Text style={styles.featureTitle}>{feature.title}</Text>
                <Text style={styles.featureDescription}>{feature.description}</Text>
              </Animated.View>
            ))}
          </View>
        </Animated.View>

        {/* How It Works Section */}
        <Animated.View 
          style={[
            styles.howItWorksSection,
            { opacity: fadeAnim }
          ]}
        >
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>How It Works</Text>
            <Text style={styles.sectionSubtitle}>
              Getting a ride is simple and fast
            </Text>
          </View>
          
          <View style={styles.stepsContainer}>
            {[
              {
                step: '1',
                icon: Smartphone,
                title: 'Request a Ride',
                description: 'Open the app and enter your destination',
              },
              {
                step: '2',
                icon: Users,
                title: 'Get Matched',
                description: 'We find the nearest verified driver for you',
              },
              {
                step: '3',
                icon: Car,
                title: 'Track & Ride',
                description: 'Track your driver and enjoy your safe ride',
              },
            ].map((item, index) => (
              <View key={index} style={styles.stepItem}>
                <View style={styles.stepNumber}>
                  <Text style={styles.stepNumberText}>{item.step}</Text>
                </View>
                <View style={styles.stepIcon}>
                  <item.icon size={24} color="#3B82F6" />
                </View>
                <View style={styles.stepContent}>
                  <Text style={styles.stepTitle}>{item.title}</Text>
                  <Text style={styles.stepDescription}>{item.description}</Text>
                </View>
              </View>
            ))}
          </View>
        </Animated.View>

        {/* Driver Section */}
        <Animated.View 
          style={[
            styles.driverSection,
            { opacity: fadeAnim }
          ]}
        >
          <LinearGradient
            colors={['#10B981', '#059669']}
            style={styles.driverGradient}
          >
            <View style={styles.driverContent}>
              <View style={styles.driverIcon}>
                <Car size={32} color="#FFFFFF" />
              </View>
              <Text style={styles.driverTitle}>Drive with RideShare</Text>
              <Text style={styles.driverSubtitle}>
                Earn money on your schedule. Join thousands of drivers earning great income.
              </Text>
              
              <View style={styles.driverFeatures}>
                {[
                  'Flexible schedule',
                  'Weekly payouts',
                  'Driver support 24/7',
                ].map((feature, index) => (
                  <View key={index} style={styles.driverFeature}>
                    <CheckCircle size={16} color="#FFFFFF" />
                    <Text style={styles.driverFeatureText}>{feature}</Text>
                  </View>
                ))}
              </View>
              
              <TouchableOpacity 
                style={styles.driverButton}
                onPress={() => router.push('/(auth)/signup')}
              >
                <Text style={styles.driverButtonText}>Start Driving</Text>
                <Zap size={18} color="#10B981" />
              </TouchableOpacity>
            </View>
          </LinearGradient>
        </Animated.View>

        {/* CTA Section */}
        <Animated.View 
          style={[
            styles.ctaSection,
            { opacity: fadeAnim }
          ]}
        >
          <View style={styles.ctaContent}>
            <Text style={styles.ctaTitle}>Ready to ride?</Text>
            <Text style={styles.ctaSubtitle}>
              Join millions of users who trust RideShare for their daily commute
            </Text>
            
            <View style={styles.ctaButtons}>
              <TouchableOpacity 
                style={styles.ctaPrimaryButton}
                onPress={() => router.push('/(auth)/signup')}
              >
                <Text style={styles.ctaPrimaryButtonText}>Sign Up Now</Text>
              </TouchableOpacity>
              
              <TouchableOpacity 
                style={styles.ctaSecondaryButton}
                onPress={() => router.push('/(auth)/login')}
              >
                <Text style={styles.ctaSecondaryButtonText}>Already have an account?</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Animated.View>

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>© 2025 RideShare. All rights reserved.</Text>
          <View style={styles.footerLinks}>
            <TouchableOpacity>
              <Text style={styles.footerLink}>Privacy Policy</Text>
            </TouchableOpacity>
            <Text style={styles.footerDivider}>•</Text>
            <TouchableOpacity>
              <Text style={styles.footerLink}>Terms of Service</Text>
            </TouchableOpacity>
            <Text style={styles.footerDivider}>•</Text>
            <TouchableOpacity>
              <Text style={styles.footerLink}>Support</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  scrollContainer: {
    flex: 1,
  },
  
  // Hero Section
  heroSection: {
    height: height * 0.85,
    position: 'relative',
  },
  heroGradient: {
    flex: 1,
    paddingTop: 60,
  },
  heroContent: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: 'space-between',
  },
  heroHeader: {
    alignItems: 'center',
    marginBottom: 40,
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  logoText: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFFFFF',
    letterSpacing: -0.5,
  },
  heroMain: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 40,
  },
  heroTitle: {
    fontSize: 42,
    fontWeight: '700',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 16,
    letterSpacing: -1,
    lineHeight: 48,
  },
  heroTitleAccent: {
    color: '#60A5FA',
  },
  heroSubtitle: {
    fontSize: 18,
    color: 'rgba(255,255,255,0.8)',
    textAlign: 'center',
    lineHeight: 26,
    marginBottom: 40,
    paddingHorizontal: 20,
  },
  heroButtons: {
    width: '100%',
    gap: 16,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 16,
    gap: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  primaryButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
  },
  secondaryButton: {
    alignItems: 'center',
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 16,
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.3)',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  heroIllustration: {
    position: 'absolute',
    top: '20%',
    right: -20,
    zIndex: 1,
  },
  floatingCar: {
    shadowColor: '#3B82F6',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 8,
  },
  carIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  
  // Stats Section
  statsSection: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 40,
    marginTop: -20,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    zIndex: 2,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 24,
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 28,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 14,
    color: '#6B7280',
    fontWeight: '500',
  },
  
  // Features Section
  featuresSection: {
    backgroundColor: '#F9FAFB',
    paddingVertical: 60,
  },
  sectionHeader: {
    alignItems: 'center',
    marginBottom: 40,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 32,
    fontWeight: '700',
    color: '#111827',
    textAlign: 'center',
    marginBottom: 12,
    letterSpacing: -0.5,
  },
  sectionSubtitle: {
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 24,
  },
  featuresGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 24,
    gap: 16,
  },
  featureCard: {
    flex: 1,
    minWidth: width * 0.4,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  featureIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  featureTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 8,
    textAlign: 'center',
  },
  featureDescription: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
  },
  
  // How It Works Section
  howItWorksSection: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 60,
  },
  stepsContainer: {
    paddingHorizontal: 24,
    gap: 32,
  },
  stepItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 20,
  },
  stepNumber: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#3B82F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepNumberText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  stepIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#EFF6FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepContent: {
    flex: 1,
  },
  stepTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  stepDescription: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
  },
  
  // Driver Section
  driverSection: {
    marginVertical: 40,
    marginHorizontal: 24,
    borderRadius: 20,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 6,
  },
  driverGradient: {
    padding: 32,
    alignItems: 'center',
  },
  driverContent: {
    alignItems: 'center',
    maxWidth: 300,
  },
  driverIcon: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
  },
  driverTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 12,
    textAlign: 'center',
  },
  driverSubtitle: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.9)',
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 24,
  },
  driverFeatures: {
    alignItems: 'flex-start',
    marginBottom: 24,
    gap: 8,
  },
  driverFeature: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  driverFeatureText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.9)',
    fontWeight: '500',
  },
  driverButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 12,
    gap: 8,
  },
  driverButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#10B981',
  },
  
  // CTA Section
  ctaSection: {
    backgroundColor: '#F9FAFB',
    paddingVertical: 60,
  },
  ctaContent: {
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  ctaTitle: {
    fontSize: 32,
    fontWeight: '700',
    color: '#111827',
    textAlign: 'center',
    marginBottom: 12,
    letterSpacing: -0.5,
  },
  ctaSubtitle: {
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 32,
  },
  ctaButtons: {
    width: '100%',
    gap: 12,
  },
  ctaPrimaryButton: {
    backgroundColor: '#111827',
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 16,
    alignItems: 'center',
  },
  ctaPrimaryButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  ctaSecondaryButton: {
    alignItems: 'center',
    paddingVertical: 12,
  },
  ctaSecondaryButtonText: {
    fontSize: 16,
    color: '#6B7280',
    fontWeight: '500',
  },
  
  // Footer
  footer: {
    backgroundColor: '#111827',
    paddingVertical: 32,
    paddingHorizontal: 24,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
    marginBottom: 16,
  },
  footerLinks: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  footerLink: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
    fontWeight: '500',
  },
  footerDivider: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.4)',
  },
});