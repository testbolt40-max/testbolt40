import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  StatusBar,
  Animated,
  Switch,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Car, DollarSign, Clock, MapPin, Star, Navigation, Phone, MessageCircle, Settings, ChartBar as BarChart3, User, Zap, Shield } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '@/hooks/useAuth';
import { driversTable, ridesTable, supabase } from '@/lib/typedSupabase';
import { Database } from '@/types/database';
import MapView from '@/components/MapView';

type Driver = Database['public']['Tables']['drivers']['Row'];
type Ride = Database['public']['Tables']['rides']['Row'];

export default function DriverDashboard() {
  const [isOnline, setIsOnline] = useState(false);
  const [currentRide, setCurrentRide] = useState<Ride | null>(null);
  const [pendingRideRequest, setPendingRideRequest] = useState<Ride | null>(null);
  const [driverData, setDriverData] = useState<Driver | null>(null);
  const [fadeAnim] = useState(new Animated.Value(0));
  const [todayEarnings, setTodayEarnings] = useState(0);
  const [todayTrips, setTodayTrips] = useState(0);
  const [rating, setRating] = useState(0);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (user) {
      loadDriverData();
      loadRideRequests();
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
      const { data: drivers, error } = await driversTable()
        .select('*')
        .eq('email', user.email!);
      
      if (error) throw error;
      
      if (drivers && drivers.length > 0) {
        const driver = drivers[0];
        setDriverData(driver);
        setIsOnline(driver.status === 'active');
        setRating(driver.rating || 4.8);
        
        // Load today's earnings and trips from rides table
        await loadTodayStats(driver.id);
      }
    } catch (error) {
      console.error('Error loading driver data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadTodayStats = async (driverId: string) => {
    try {
      const today = new Date();
      const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString();
      
      // Get today's completed rides
      const { data: todayRides, error } = await ridesTable()
        .select('fare')
        .eq('driver_id', driverId)
        .eq('status', 'completed')
        .gte('completed_at', startOfDay);
      
      if (error) throw error;
      
      if (todayRides) {
        const earnings = todayRides.reduce((sum, ride) => sum + (ride.fare || 0), 0);
        setTodayEarnings(earnings);
        setTodayTrips(todayRides.length);
      }
    } catch (error) {
      console.error('Error loading today stats:', error);
    }
  };

  const loadRideRequests = async () => {
    if (!driverData) return;
    
    try {
      // Check for pending ride requests assigned to this driver
      const { data: rides, error } = await ridesTable()
        .select('*')
        .eq('driver_id', driverData.id)
        .eq('status', 'active')
        .order('created_at', { ascending: false })
        .limit(1);
      
      if (error) throw error;
      
      if (rides && rides.length > 0) {
        const ride = rides[0];
        setCurrentRide(ride);
      }
      
      // Also check for unassigned rides if driver is online
      if (isOnline) {
        const { data: unassignedRides, error: unassignedError } = await ridesTable()
          .select('*')
          .is('driver_id', null)
          .eq('status', 'active')
          .order('created_at', { ascending: true })
          .limit(1);
        
        if (!unassignedError && unassignedRides && unassignedRides.length > 0) {
          setPendingRideRequest(unassignedRides[0]);
        }
      }
    } catch (error) {
      console.error('Error loading ride requests:', error);
    }
  };

  const handleGoOnline = async () => {
    if (!driverData) return;
    
    const newOnlineStatus = !isOnline;
    const newStatus = newOnlineStatus ? 'active' : 'inactive';
    
    try {
      // Update driver status in database
      const { error } = await driversTable()
        .update({ 
          status: newStatus,
          last_active: new Date().toISOString()
        })
        .eq('id', driverData.id);
      
      if (error) throw error;
      
      // Update local state
      setIsOnline(newOnlineStatus);
      setDriverData({ ...driverData, status: newStatus });
      
      Alert.alert(
        'Status Updated', 
        newOnlineStatus ? 'You are now online and ready to receive rides!' : 'You are now offline'
      );
      
      // If going online, start checking for ride requests
      if (newOnlineStatus) {
        loadRideRequests();
      } else {
        // If going offline, clear any pending requests
        setPendingRideRequest(null);
      }
    } catch (error) {
      console.error('Error updating driver status:', error);
      Alert.alert('Error', 'Failed to update status. Please try again.');
    }
  };

  // Refresh ride requests every 30 seconds when online
  useEffect(() => {
    if (isOnline && driverData) {
      const interval = setInterval(() => {
        loadRideRequests();
      }, 30000); // Check every 30 seconds
      
      return () => clearInterval(interval);
    }
  }, [isOnline, driverData]);

  const handleAcceptRide = async () => {
    if (!pendingRideRequest || !driverData) return;
    
    try {
      // Assign driver to the ride
      const { error } = await ridesTable()
        .update({ 
          driver_id: driverData.id,
          eta: '5 min'
        })
        .eq('id', pendingRideRequest.id);
      
      if (error) throw error;
      
      setCurrentRide(pendingRideRequest);
      setPendingRideRequest(null);
      
      Alert.alert('Ride Accepted', 'Navigate to pickup location');
      
      // Reload ride requests to get updated data
      loadRideRequests();
    } catch (error) {
      console.error('Error accepting ride:', error);
      Alert.alert('Error', 'Failed to accept ride. Please try again.');
    }
  };

  const handleDeclineRide = async () => {
    if (!pendingRideRequest) return;
    
    try {
      // For now, just remove from local state
      // In a real app, you might want to track declined rides
      setPendingRideRequest(null);
      
      Alert.alert('Ride Declined', 'Looking for another ride...');
      
      // Look for next available ride
      setTimeout(() => {
        loadRideRequests();
      }, 2000);
    } catch (error) {
      console.error('Error declining ride:', error);
    }
  };

  const handleCompleteRide = async () => {
    if (!currentRide || !driverData) return;
    
    Alert.alert(
      'Complete Ride',
      'Mark this ride as completed?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Complete',
          onPress: async () => {
            try {
              // Update ride status to completed
              const { error } = await ridesTable()
                .update({ 
                  status: 'completed',
                  completed_at: new Date().toISOString()
                })
                .eq('id', currentRide.id);
              
              if (error) throw error;
              
              // Update driver stats
              await driversTable()
                .update({ 
                  total_rides: (driverData.total_rides || 0) + 1,
                  earnings: (driverData.earnings || 0) + (currentRide.fare || 0),
                  last_active: new Date().toISOString()
                })
                .eq('id', driverData.id);
              
              setCurrentRide(null);
              Alert.alert('Success', 'Ride completed successfully!');
              
              // Reload data to update stats
              loadDriverData();
              loadRideRequests();
            } catch (error) {
              console.error('Error completing ride:', error);
              Alert.alert('Error', 'Failed to complete ride. Please try again.');
            }
          }
        }
      ]
    );
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="light-content" backgroundColor="transparent" translucent={true} />
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Loading dashboard...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent={true} />
      
      {/* Header */}
      <Animated.View style={[styles.header, { opacity: fadeAnim }]}>
        <LinearGradient
          colors={isOnline ? ['#10B981', '#059669'] : ['#6B7280', '#4B5563']}
          style={styles.headerGradient}
        >
          <View style={styles.headerContent}>
            <View style={styles.headerLeft}>
              <Text style={styles.greeting}>Good morning, Driver!</Text>
              <Text style={styles.statusText}>
                {isOnline ? 'You are online' : 'You are offline'}
              </Text>
            </View>
            <TouchableOpacity style={styles.settingsButton}>
              <Settings size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </LinearGradient>
      </Animated.View>

      {/* Online/Offline Toggle */}
      <Animated.View style={[styles.toggleSection, { opacity: fadeAnim }]}>
        <View style={styles.toggleCard}>
          <View style={styles.toggleContent}>
            <View style={styles.toggleInfo}>
              <Text style={styles.toggleTitle}>
                {isOnline ? 'You\'re Online' : 'You\'re Offline'}
              </Text>
              <Text style={styles.toggleSubtitle}>
                {isOnline 
                  ? 'Ready to receive ride requests' 
                  : 'Tap to start receiving rides'}
              </Text>
            </View>
            <Switch
              value={isOnline}
              onValueChange={handleGoOnline}
              trackColor={{ false: '#E5E7EB', true: '#D1FAE5' }}
              thumbColor={isOnline ? '#10B981' : '#9CA3AF'}
              style={styles.toggle}
            />
          </View>
        </View>
      </Animated.View>

      {/* Map View */}
      <View style={styles.mapContainer}>
        <MapView
          currentLocation={{
            latitude: 37.7749,
            longitude: -122.4194
          }}
          showNearbyDrivers={false}
        />
        
        {/* Map Overlay Stats */}
        <View style={styles.mapOverlay}>
          <View style={styles.statsRow}>
            <View style={styles.statCard}>
              <DollarSign size={16} color="#10B981" />
              <Text style={styles.statValue}>${todayEarnings}</Text>
              <Text style={styles.statLabel}>Today</Text>
            </View>
            <View style={styles.statCard}>
              <Car size={16} color="#3B82F6" />
              <Text style={styles.statValue}>{todayTrips}</Text>
              <Text style={styles.statLabel}>Trips</Text>
            </View>
            <View style={styles.statCard}>
              <Star size={16} color="#F59E0B" />
              <Text style={styles.statValue}>{rating}</Text>
              <Text style={styles.statLabel}>Rating</Text>
            </View>
          </View>
        </View>
      </View>

      {/* Ride Request Modal */}
      {isOnline && !currentRide && pendingRideRequest && (
        <View style={styles.rideRequestModal}>
          <View style={styles.rideRequestHeader}>
            <Text style={styles.rideRequestTitle}>New Ride Request</Text>
            <View style={styles.rideRequestTimer}>
              <Clock size={16} color="#DC2626" />
              <Text style={styles.timerText}>15s</Text>
            </View>
          </View>
          
          <View style={styles.rideRequestContent}>
            <View style={styles.passengerInfo}>
              <View style={styles.passengerAvatar}>
                <User size={20} color="#FFFFFF" />
              </View>
              <View style={styles.passengerDetails}>
                <Text style={styles.passengerName}>Passenger</Text>
                <View style={styles.passengerRating}>
                  <Star size={12} color="#F59E0B" fill="#F59E0B" />
                  <Text style={styles.ratingText}>4.7</Text>
                </View>
              </View>
            </View>
            
            <View style={styles.rideDetails}>
              <View style={styles.rideDetailRow}>
                <MapPin size={16} color="#10B981" />
                <Text style={styles.rideDetailText}>{pendingRideRequest.pickup_location}</Text>
              </View>
              <View style={styles.rideDetailRow}>
                <Navigation size={16} color="#DC2626" />
                <Text style={styles.rideDetailText}>{pendingRideRequest.dropoff_location}</Text>
              </View>
              <View style={styles.rideMetrics}>
                <Text style={styles.metricText}>{pendingRideRequest.distance?.toFixed(1)} km</Text>
                <Text style={styles.metricText}>{pendingRideRequest.duration} min</Text>
                <Text style={styles.fareText}>${(pendingRideRequest.fare || 0).toFixed(2)}</Text>
              </View>
            </View>
          </View>
          
          <View style={styles.rideRequestActions}>
            <TouchableOpacity 
              style={styles.declineButton}
              onPress={handleDeclineRide}
            >
              <Text style={styles.declineButtonText}>Decline</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={styles.acceptButton}
              onPress={handleAcceptRide}
            >
              <LinearGradient
                colors={['#10B981', '#059669']}
                style={styles.acceptButtonGradient}
              >
                <Text style={styles.acceptButtonText}>Accept</Text>
              </LinearGradient>
            </TouchableOpacity>
          </View>
        </View>
      )}

      {/* Current Ride */}
      {currentRide && (
        <View style={styles.currentRidePanel}>
          <View style={styles.currentRideHeader}>
            <Text style={styles.currentRideTitle}>Current Trip</Text>
            <View style={styles.currentRideStatus}>
              <Zap size={16} color="#10B981" />
              <Text style={styles.statusText}>En Route</Text>
            </View>
          </View>
          
          <View style={styles.currentRideContent}>
            <Text style={styles.currentRidePassenger}>Current Passenger</Text>
            <Text style={styles.currentRideDestination}>{currentRide.dropoff_location}</Text>
            
            <View style={styles.currentRideActions}>
              <TouchableOpacity style={styles.contactButton}>
                <Phone size={18} color="#FFFFFF" />
              </TouchableOpacity>
              <TouchableOpacity style={styles.contactButton}>
                <MessageCircle size={18} color="#FFFFFF" />
              </TouchableOpacity>
              <TouchableOpacity style={styles.navigationButton} onPress={handleCompleteRide}>
                <Navigation size={18} color="#FFFFFF" />
                <Text style={styles.navigationText}>Complete</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
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
    paddingTop: 50,
  },
  headerGradient: {
    paddingHorizontal: 24,
    paddingVertical: 20,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerLeft: {
    flex: 1,
  },
  greeting: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
    marginBottom: 4,
  },
  statusText: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  settingsButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  toggleSection: {
    paddingHorizontal: 24,
    marginTop: -10,
    marginBottom: 20,
  },
  toggleCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  toggleContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  toggleInfo: {
    flex: 1,
  },
  toggleTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  toggleSubtitle: {
    fontSize: 14,
    color: '#6B7280',
  },
  toggle: {
    transform: [{ scaleX: 1.2 }, { scaleY: 1.2 }],
  },
  mapContainer: {
    flex: 1,
    position: 'relative',
  },
  mapOverlay: {
    position: 'absolute',
    top: 20,
    left: 20,
    right: 20,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 12,
  },
  statCard: {
    flex: 1,
    backgroundColor: 'rgba(255,255,255,0.95)',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
    marginTop: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  rideRequestModal: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
  },
  rideRequestHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  rideRequestTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
  },
  rideRequestTimer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEE2E2',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    gap: 4,
  },
  timerText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#DC2626',
  },
  rideRequestContent: {
    marginBottom: 20,
  },
  passengerInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  passengerAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#6B7280',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  passengerDetails: {
    flex: 1,
  },
  passengerName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  passengerRating: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  ratingText: {
    fontSize: 12,
    color: '#F59E0B',
    fontWeight: '500',
  },
  rideDetails: {
    gap: 8,
  },
  rideDetailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  rideDetailText: {
    fontSize: 14,
    color: '#374151',
    flex: 1,
  },
  rideMetrics: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  metricText: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
  },
  fareText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#10B981',
  },
  rideRequestActions: {
    flexDirection: 'row',
    gap: 12,
  },
  declineButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: '#F3F4F6',
    alignItems: 'center',
  },
  declineButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
  },
  acceptButton: {
    flex: 2,
    borderRadius: 12,
    overflow: 'hidden',
  },
  acceptButtonGradient: {
    paddingVertical: 12,
    alignItems: 'center',
  },
  acceptButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  currentRidePanel: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
  },
  currentRideHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  currentRideTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
  },
  currentRideStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  currentRideContent: {
    marginBottom: 16,
  },
  currentRidePassenger: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  currentRideDestination: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 16,
  },
  currentRideActions: {
    flexDirection: 'row',
    gap: 12,
  },
  contactButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#6B7280',
    justifyContent: 'center',
    alignItems: 'center',
  },
  navigationButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#10B981',
    paddingVertical: 12,
    borderRadius: 12,
    gap: 8,
  },
  navigationText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
});