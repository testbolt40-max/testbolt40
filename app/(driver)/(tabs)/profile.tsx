import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  StatusBar,
  Animated,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { User, Car, Star, Shield, Bell, Settings, CreditCard, FileText, CircleHelp as HelpCircle, LogOut, ChevronRight, CreditCard as Edit, Award, MapPin } from 'lucide-react-native';
import { useAuth } from '@/hooks/useAuth';
import { driversTable, profilesTable } from '@/lib/typedSupabase';
import { Database } from '@/types/database';
import { router } from 'expo-router';

type Driver = Database['public']['Tables']['drivers']['Row'];
type Profile = Database['public']['Tables']['profiles']['Row'];

export default function DriverProfile() {
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [autoAcceptEnabled, setAutoAcceptEnabled] = useState(false);
  const [fadeAnim] = useState(new Animated.Value(0));
  const [driverData, setDriverData] = useState<Driver | null>(null);
  const [profileData, setProfileData] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const { user, signOut } = useAuth();

  useEffect(() => {
    if (user) {
      loadDriverData();
    }
    
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start();
  }, [user]);

  const loadDriverData = async () => {
    if (!user) return;
    
    try {
      // Load driver data
      const { data: drivers, error: driverError } = await driversTable()
        .select('*')
        .eq('email', user.email!);
      
      if (driverError) {
        console.error('Error loading driver data:', driverError);
      } else if (drivers && drivers.length > 0) {
        setDriverData(drivers[0]);
      }
      
      // Load profile data
      const { data: profiles, error: profileError } = await profilesTable()
        .select('*')
        .eq('user_id', user.id);
      
      if (profileError) {
        console.error('Error loading profile data:', profileError);
      } else if (profiles && profiles.length > 0) {
        setProfileData(profiles[0]);
      }
    } catch (error) {
      console.error('Error loading driver data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calculate years active
  const getYearsActive = () => {
    if (!driverData?.created_at) return 0;
    const createdDate = new Date(driverData.created_at);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - createdDate.getTime());
    const diffYears = Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 365));
    return diffYears;
  };

  // Get driver stats from database or fallback to defaults
  const driverStats = {
    rating: driverData?.rating || 4.8,
    totalTrips: driverData?.total_rides || 0,
    totalEarnings: driverData?.earnings || 0,
    acceptanceRate: 92, // This would need to be calculated from ride history
    completionRate: 98, // This would need to be calculated from ride history
    yearsActive: getYearsActive(),
  };

  // Get vehicle info from database or fallback
  const vehicleInfo = {
    type: driverData?.vehicle_type || 'economy',
    licensePlate: driverData?.license_plate || 'N/A',
    verified: driverData?.documents_verified || false,
  };

  const handleLogout = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Sign Out',
          style: 'destructive',
          onPress: async () => {
            try {
              // Update driver status to offline before signing out
              if (driverData) {
                await driversTable()
                  .update({ status: 'inactive' })
                  .eq('id', driverData.id);
              }
              
              await signOut();
              router.replace('/(auth)/login');
            } catch (error) {
              console.error('Logout error:', error);
            }
          },
        },
      ]
    );
  };

  const handleSwitchToPassenger = () => {
    Alert.alert(
      'Switch to Passenger Mode',
      'You will be redirected to the passenger app. Continue?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Continue',
          onPress: () => {
            router.replace('/(tabs)');
          },
        },
      ]
    );
  };

  const handleUpdateProfile = async () => {
    if (!user) return;
    
    Alert.alert(
      'Update Profile',
      'What would you like to update?',
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Phone Number', 
          onPress: () => {
            Alert.prompt(
              'Update Phone',
              'Enter your new phone number:',
              async (phone) => {
                if (phone && driverData) {
                  try {
                    const { error } = await driversTable()
                      .update({ phone })
                      .eq('id', driverData.id);
                    
                    if (error) throw error;
                    
                    Alert.alert('Success', 'Phone number updated successfully');
                    loadDriverData();
                  } catch (error) {
                    console.error('Error updating phone:', error);
                    Alert.alert('Error', 'Failed to update phone number');
                  }
                }
              }
            );
          }
        },
        { 
          text: 'Full Name', 
          onPress: () => {
            Alert.prompt(
              'Update Name',
              'Enter your full name:',
              async (name) => {
                if (name && driverData) {
                  try {
                    const { error } = await driversTable()
                      .update({ name })
                      .eq('id', driverData.id);
                    
                    if (error) throw error;
                    
                    Alert.alert('Success', 'Name updated successfully');
                    loadDriverData();
                  } catch (error) {
                    console.error('Error updating name:', error);
                    Alert.alert('Error', 'Failed to update name');
                  }
                }
              }
            );
          }
        },
      ]
    );
  };

  const handleManageVehicle = async () => {
    if (!driverData) return;
    
    Alert.alert(
      'Vehicle Information',
      `Current: ${vehicleInfo.type} • ${vehicleInfo.licensePlate}`,
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Update License Plate', 
          onPress: () => {
            Alert.prompt(
              'Update License Plate',
              'Enter new license plate:',
              async (licensePlate) => {
                if (licensePlate && driverData) {
                  try {
                    const { error } = await driversTable()
                      .update({ license_plate: licensePlate.toUpperCase() })
                      .eq('id', driverData.id);
                    
                    if (error) throw error;
                    
                    Alert.alert('Success', 'License plate updated successfully');
                    loadDriverData();
                  } catch (error) {
                    console.error('Error updating license plate:', error);
                    Alert.alert('Error', 'Failed to update license plate');
                  }
                }
              }
            );
          }
        },
        { 
          text: 'Change Vehicle Type', 
          onPress: () => {
            Alert.alert(
              'Change Vehicle Type',
              'Select new vehicle type:',
              [
                { text: 'Cancel', style: 'cancel' },
                { 
                  text: 'Economy', 
                  onPress: async () => {
                    try {
                      const { error } = await driversTable()
                        .update({ vehicle_type: 'economy' })
                        .eq('id', driverData.id);
                      
                      if (error) throw error;
                      
                      Alert.alert('Success', 'Vehicle type updated to Economy');
                      loadDriverData();
                    } catch (error) {
                      console.error('Error updating vehicle type:', error);
                      Alert.alert('Error', 'Failed to update vehicle type');
                    }
                  }
                },
                { 
                  text: 'Comfort', 
                  onPress: async () => {
                    try {
                      const { error } = await driversTable()
                        .update({ vehicle_type: 'comfort' })
                        .eq('id', driverData.id);
                      
                      if (error) throw error;
                      
                      Alert.alert('Success', 'Vehicle type updated to Comfort');
                      loadDriverData();
                    } catch (error) {
                      console.error('Error updating vehicle type:', error);
                      Alert.alert('Error', 'Failed to update vehicle type');
                    }
                  }
                },
                { 
                  text: 'Luxury', 
                  onPress: async () => {
                    try {
                      const { error } = await driversTable()
                        .update({ vehicle_type: 'luxury' })
                        .eq('id', driverData.id);
                      
                      if (error) throw error;
                      
                      Alert.alert('Success', 'Vehicle type updated to Luxury');
                      loadDriverData();
                    } catch (error) {
                      console.error('Error updating vehicle type:', error);
                      Alert.alert('Error', 'Failed to update vehicle type');
                    }
                  }
                },
              ]
            );
          }
        },
      ]
    );
  };

  const handleManageDocuments = async () => {
    if (!driverData) return;
    
    Alert.alert(
      'Documents Status',
      `Verification: ${vehicleInfo.verified ? 'Verified ✓' : 'Pending Review'}`,
      [
        { text: 'OK', style: 'cancel' },
        { 
          text: 'Re-submit Documents', 
          onPress: () => {
            Alert.alert(
              'Re-submit Documents',
              'This will mark your documents as pending review again.',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Re-submit',
                  onPress: async () => {
                    try {
                      const { error } = await driversTable()
                        .update({ 
                          documents_verified: false,
                          status: 'inactive' // Set to inactive until re-verified
                        })
                        .eq('id', driverData.id);
                      
                      if (error) throw error;
                      
                      Alert.alert('Success', 'Documents marked for re-review. You will be notified once verified.');
                      loadDriverData();
                    } catch (error) {
                      console.error('Error updating documents status:', error);
                      Alert.alert('Error', 'Failed to update documents status');
                    }
                  }
                }
              ]
            );
          }
        },
      ]
    );
  };

  const handleEarningsSettings = async () => {
    if (!driverData) return;
    
    Alert.alert(
      'Earnings & Payments',
      `Total Earnings: $${driverStats.totalEarnings.toFixed(2)}\nTotal Trips: ${driverStats.totalTrips}\nCurrent Status: ${driverData.status}`,
      [
        { text: 'OK', style: 'cancel' },
        { 
          text: 'View Detailed Earnings', 
          onPress: () => {
            router.push('/(driver)/(tabs)/earnings');
          }
        },
      ]
    );
  };

  const profileSettings = [
    {
      id: 'vehicle',
      icon: Car,
      label: 'Vehicle Information',
      value: `${vehicleInfo.type} • ${vehicleInfo.licensePlate}`,
      onPress: handleManageVehicle,
      color: '#3B82F6',
    },
    {
      id: 'documents',
      icon: FileText,
      label: 'Documents',
      value: vehicleInfo.verified ? 'All verified' : 'Verification pending',
      onPress: handleManageDocuments,
      color: '#10B981',
    },
    {
      id: 'earnings',
      icon: CreditCard,
      label: 'Earnings & Payments',
      value: `$${driverStats.totalEarnings.toFixed(2)} earned`,
      onPress: handleEarningsSettings,
      color: '#F59E0B',
    },
    {
      id: 'notifications',
      icon: Bell,
      label: 'Notifications',
      hasSwitch: true,
      switchValue: notificationsEnabled,
      onToggle: async (value: boolean) => {
        setNotificationsEnabled(value);
        
        // Save notification preference
        try {
          // In a real app, you'd save this to a user preferences table
          Alert.alert(
            'Notifications Updated',
            `Push notifications are now ${value ? 'enabled' : 'disabled'}`
          );
        } catch (error) {
          console.error('Error updating notifications:', error);
          setNotificationsEnabled(!value); // Revert on error
        }
      },
      color: '#8B5CF6',
    },
  ];

  const menuItems = [
    {
      id: 'auto-accept',
      icon: Settings,
      label: 'Auto-Accept Rides',
      hasSwitch: true,
      switchValue: autoAcceptEnabled,
      onToggle: async (value: boolean) => {
        setAutoAcceptEnabled(value);
        
        // Save auto-accept preference to database
        if (driverData) {
          try {
            // Note: This would require adding an auto_accept field to drivers table
            // For now, we'll just update local state
            Alert.alert(
              'Auto-Accept Updated',
              `Auto-accept rides is now ${value ? 'enabled' : 'disabled'}`
            );
          } catch (error) {
            console.error('Error updating auto-accept:', error);
            setAutoAcceptEnabled(!value); // Revert on error
          }
        }
      },
      color: '#6B7280',
    },
    {
      id: 'passenger-mode',
      icon: User,
      label: 'Switch to Passenger Mode',
      onPress: handleSwitchToPassenger,
      color: '#3B82F6',
      color: '#3B82F6',
    },
    {
      id: 'safety',
      icon: Shield,
      label: 'Safety Center',
      onPress: () => {
        Alert.alert(
          'Safety Center',
          'Choose a safety option:',
          [
            { text: 'Cancel', style: 'cancel' },
            { 
              text: 'Emergency Contacts', 
              onPress: () => Alert.alert('Emergency Contacts', 'Manage your emergency contacts in settings.') 
            },
            { 
              text: 'Safety Toolkit', 
              onPress: () => Alert.alert('Safety Toolkit', 'Access safety features and report issues.') 
            },
          ]
        );
      },
      color: '#DC2626',
    },
    {
      id: 'help',
      icon: HelpCircle,
      label: 'Help & Support',
      onPress: () => {
        Alert.alert(
          'Help & Support',
          'How can we help you?',
          [
            { text: 'Cancel', style: 'cancel' },
            { 
              text: 'Contact Support', 
              onPress: () => Alert.alert('Contact Support', 'Email: support@rideshare.com\nPhone: 1-800-RIDESHARE') 
            },
            { 
              text: 'FAQ', 
              onPress: () => Alert.alert('FAQ', 'Frequently asked questions and troubleshooting guides.') 
            },
          ]
        );
      },
      color: '#059669',
    },
  ];

  const renderSettingItem = (item: any) => (
    <TouchableOpacity
      key={item.id}
      style={styles.settingItem}
      onPress={item.onPress}
      disabled={item.hasSwitch || !item.onPress}
      activeOpacity={item.hasSwitch ? 1 : 0.7}
    >
      <View style={[styles.settingIcon, { backgroundColor: `${item.color}15` }]}>
        <item.icon size={20} color={item.color} />
      </View>
      <View style={styles.settingContent}>
        <Text style={styles.settingLabel}>{item.label}</Text>
        {item.value && <Text style={styles.settingValue}>{item.value}</Text>}
      </View>
      <View style={styles.settingRight}>
        {item.hasSwitch ? (
          <Switch
            value={item.switchValue}
            onValueChange={item.onToggle}
            trackColor={{ false: '#E5E7EB', true: '#DBEAFE' }}
            thumbColor={item.switchValue ? item.color : '#FFFFFF'}
          />
        ) : (
          <ChevronRight size={20} color="#9CA3AF" />
        )}
      </View>
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Loading driver profile...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      {/* Header */}
      <Animated.View style={[styles.header, { opacity: fadeAnim }]}>
        <Text style={styles.title}>Driver Profile</Text>
        <TouchableOpacity style={styles.editButton} onPress={handleUpdateProfile}>
          <Edit size={20} color="#6B7280" />
        </TouchableOpacity>
      </Animated.View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Driver Card */}
        <Animated.View style={[styles.driverSection, { opacity: fadeAnim }]}>
          <View style={styles.driverCard}>
            <View style={styles.driverAvatar}>
              <User size={32} color="#FFFFFF" />
            </View>
            <View style={styles.driverInfo}>
              <Text style={styles.driverName}>
                {driverData?.name || user?.user_metadata?.full_name || 'Driver'}
              </Text>
              <Text style={styles.driverEmail}>{user?.email}</Text>
              <View style={styles.driverBadges}>
                <View style={[
                  styles.verifiedBadge,
                  !vehicleInfo.verified && styles.pendingBadge
                ]}>
                  <Shield size={12} color="#10B981" />
                  <Text style={[
                    styles.verifiedText,
                    !vehicleInfo.verified && styles.pendingText
                  ]}>
                    {vehicleInfo.verified ? 'Verified Driver' : 'Verification Pending'}
                  </Text>
                </View>
              </View>
            </View>
          </View>

          {/* Driver Stats */}
          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: '#FEF3C7' }]}>
                <Star size={16} color="#F59E0B" />
              </View>
              <Text style={styles.statValue}>{driverStats.rating}</Text>
              <Text style={styles.statLabel}>Rating</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: '#DBEAFE' }]}>
                <Car size={16} color="#3B82F6" />
              </View>
              <Text style={styles.statValue}>{driverStats.totalTrips.toLocaleString()}</Text>
              <Text style={styles.statLabel}>Trips</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: '#D1FAE5' }]}>
                <Award size={16} color="#10B981" />
              </View>
              <Text style={styles.statValue}>{driverStats.yearsActive}y</Text>
              <Text style={styles.statLabel}>Experience</Text>
            </View>
          </View>
        </Animated.View>

        {/* Performance Metrics */}
        <Animated.View style={[styles.section, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Performance</Text>
          <View style={styles.metricsContainer}>
            <View style={styles.metricCard}>
              <Text style={styles.metricValue}>{driverStats.acceptanceRate}%</Text>
              <Text style={styles.metricLabel}>Acceptance Rate</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={styles.metricValue}>{driverStats.completionRate}%</Text>
              <Text style={styles.metricLabel}>Completion Rate</Text>
            </View>
          </View>
        </Animated.View>

        {/* Vehicle Information */}
        <Animated.View style={[styles.section, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Vehicle</Text>
          <View style={styles.vehicleCard}>
            <View style={styles.vehicleHeader}>
              <View style={styles.vehicleIcon}>
                <Car size={24} color="#3B82F6" />
              </View>
              <View style={styles.vehicleInfo}>
                <Text style={styles.vehicleName}>
                  {vehicleInfo.type.charAt(0).toUpperCase() + vehicleInfo.type.slice(1)} Vehicle
                </Text>
                <Text style={styles.vehicleDetails}>
                  License: {vehicleInfo.licensePlate}
                </Text>
              </View>
              {vehicleInfo.verified && (
                <View style={styles.verifiedIcon}>
                  <Shield size={16} color="#10B981" />
                </View>
              )}
            </View>
          </View>
        </Animated.View>

        {/* Account Settings */}
        <Animated.View style={[styles.section, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Account</Text>
          <View style={styles.settingsContainer}>
            {profileSettings.map(renderSettingItem)}
          </View>
        </Animated.View>

        {/* Driver Settings */}
        <Animated.View style={[styles.section, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Driver Settings</Text>
          <View style={styles.settingsContainer}>
            {menuItems.map(renderSettingItem)}
          </View>
        </Animated.View>

        {/* Logout */}
        <Animated.View style={[styles.section, { opacity: fadeAnim }]}>
          <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
            <LogOut size={20} color="#DC2626" />
            <Text style={styles.logoutText}>Sign Out</Text>
          </TouchableOpacity>
        </Animated.View>

        {/* App Version */}
        <Animated.View style={[styles.versionSection, { opacity: fadeAnim }]}>
          <Text style={styles.versionText}>Driver App v2.1.0</Text>
        </Animated.View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#6B7280',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
  },
  editButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  driverSection: {
    paddingHorizontal: 24,
    paddingTop: 20,
    marginBottom: 32,
  },
  driverCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  driverAvatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#10B981',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  driverInfo: {
    flex: 1,
  },
  driverName: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  driverEmail: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 8,
  },
  driverBadges: {
    flexDirection: 'row',
  },
  verifiedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#D1FAE5',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    gap: 4,
  },
  pendingBadge: {
    backgroundColor: '#FEF3C7',
  },
  verifiedText: {
    color: '#10B981',
    fontSize: 12,
    fontWeight: '600',
  },
  pendingText: {
    color: '#F59E0B',
  },
  statsContainer: {
    flexDirection: 'row',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  statValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 2,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
  },
  statDivider: {
    width: 1,
    backgroundColor: '#E5E7EB',
    marginHorizontal: 16,
  },
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 16,
    paddingHorizontal: 24,
  },
  metricsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    gap: 12,
  },
  metricCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  metricValue: {
    fontSize: 24,
    fontWeight: '700',
    color: '#10B981',
    marginBottom: 4,
  },
  metricLabel: {
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  vehicleCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  vehicleHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  vehicleIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#DBEAFE',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  vehicleInfo: {
    flex: 1,
  },
  vehicleName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  vehicleDetails: {
    fontSize: 14,
    color: '#6B7280',
  },
  verifiedIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#D1FAE5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  settingsContainer: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 24,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  settingIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  settingContent: {
    flex: 1,
  },
  settingLabel: {
    fontSize: 16,
    color: '#111827',
    fontWeight: '600',
    marginBottom: 2,
  },
  settingValue: {
    fontSize: 14,
    color: '#6B7280',
  },
  settingRight: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 24,
    paddingVertical: 16,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#FEE2E2',
    gap: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  logoutText: {
    fontSize: 16,
    color: '#DC2626',
    fontWeight: '600',
  },
  versionSection: {
    alignItems: 'center',
    paddingVertical: 24,
    paddingBottom: 40,
  },
  versionText: {
    fontSize: 14,
    color: '#9CA3AF',
    fontWeight: '500',
  },
});