import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  StatusBar,
  Animated,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { 
  Car,
  Clock,
  MapPin,
  Star,
  DollarSign,
  Navigation,
  Filter
} from 'lucide-react-native';
import { useAuth } from '@/hooks/useAuth';
import { driversTable, ridesTable } from '@/lib/typedSupabase';
import { Database } from '@/types/database';

type Driver = Database['public']['Tables']['drivers']['Row'];
type Ride = Database['public']['Tables']['rides']['Row'];

export default function DriverTrips() {
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [fadeAnim] = useState(new Animated.Value(0));
  const [driverData, setDriverData] = useState<Driver | null>(null);
  const [trips, setTrips] = useState<Ride[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (user) {
      loadDriverTrips();
    }
    
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start();
  }, [user]);

  const loadDriverTrips = async () => {
    if (!user) return;
    
    try {
      // Load driver data
      const { data: drivers, error: driverError } = await driversTable()
        .select('*')
        .eq('email', user.email!);
      
      if (driverError) throw driverError;
      
      if (drivers && drivers.length > 0) {
        const driver = drivers[0];
        setDriverData(driver);
        
        // Load driver's trips
        const { data: driverTrips, error: tripsError } = await ridesTable()
          .select('*')
          .eq('driver_id', driver.id)
          .order('created_at', { ascending: false });
        
        if (tripsError) throw tripsError;
        setTrips(driverTrips || []);
      }
    } catch (error) {
      console.error('Error loading driver trips:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return 'Yesterday';
    } else {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
  };

  const formatTime = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  const filteredTrips = trips.filter(trip => {
    if (selectedFilter === 'all') return true;
    return trip.status === selectedFilter;
  });

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Loading trips...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      {/* Header */}
      <Animated.View style={[styles.header, { opacity: fadeAnim }]}>
        <Text style={styles.title}>My Trips</Text>
        <TouchableOpacity style={styles.filterButton}>
          <Filter size={24} color="#6B7280" />
        </TouchableOpacity>
      </Animated.View>

      {/* Filter Tabs */}
      <Animated.View style={[styles.filterTabs, { opacity: fadeAnim }]}>
        {[
          { key: 'all', label: 'All Trips', count: trips.length },
          { key: 'completed', label: 'Completed', count: trips.filter(t => t.status === 'completed').length },
          { key: 'cancelled', label: 'Cancelled', count: 0 },
        ].map((tab) => (
          <TouchableOpacity
            key={tab.key}
            style={[
              styles.filterTab,
              selectedFilter === tab.key && styles.activeFilterTab,
            ]}
            onPress={() => setSelectedFilter(tab.key)}
          >
            <Text style={[
              styles.filterTabText,
              selectedFilter === tab.key && styles.activeFilterTabText,
            ]}>
              {tab.label}
            </Text>
            {tab.count > 0 && (
              <View style={[
                styles.filterTabBadge,
                selectedFilter === tab.key && styles.activeFilterTabBadge,
              ]}>
                <Text style={[
                  styles.filterTabBadgeText,
                  selectedFilter === tab.key && styles.activeFilterTabBadgeText,
                ]}>
                  {tab.count}
                </Text>
              </View>
            )}
          </TouchableOpacity>
        ))}
      </Animated.View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Trip Stats */}
        <Animated.View style={[styles.statsSection, { opacity: fadeAnim }]}>
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Car size={20} color="#3B82F6" />
              <Text style={styles.statValue}>{trips.length}</Text>
              <Text style={styles.statLabel}>Total Trips</Text>
            </View>
            <View style={styles.statCard}>
              <DollarSign size={20} color="#10B981" />
              <Text style={styles.statValue}>
                ${trips.reduce((sum, trip) => sum + (trip.fare || 0), 0).toFixed(0)}
              </Text>
              <Text style={styles.statLabel}>Total Earned</Text>
            </View>
            <View style={styles.statCard}>
              <Star size={20} color="#F59E0B" />
              <Text style={styles.statValue}>
                {driverData?.rating?.toFixed(1) || '0.0'}
              </Text>
              <Text style={styles.statLabel}>Avg Rating</Text>
            </View>
          </View>
        </Animated.View>

        {/* Trips List */}
        <Animated.View style={[styles.tripsSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Recent Trips</Text>
          
          {filteredTrips.length === 0 ? (
            <View style={styles.emptyState}>
              <Car size={48} color="#E5E7EB" />
              <Text style={styles.emptyStateText}>No trips found</Text>
              <Text style={styles.emptyStateSubtext}>Your trips will appear here</Text>
            </View>
          ) : (
            <View style={styles.tripsContainer}>
              {filteredTrips.map((trip) => (
                <TouchableOpacity key={trip.id} style={styles.tripCard}>
                  <View style={styles.tripHeader}>
                    <View style={styles.tripInfo}>
                      <Text style={styles.passengerName}>Passenger</Text>
                      <Text style={styles.tripStatus}>{trip.status}</Text>
                    </View>
                    <View style={styles.tripEarnings}>
                      <Text style={styles.fareAmount}>${(trip.fare || 0).toFixed(2)}</Text>
                      <Text style={styles.tripTime}>{formatTime(trip.completed_at)}</Text>
                    </View>
                  </View>

                  <View style={styles.tripRoute}>
                    <View style={styles.routeItem}>
                      <View style={[styles.routeDot, { backgroundColor: '#10B981' }]} />
                      <Text style={styles.routeText}>{trip.pickup_location}</Text>
                    </View>
                    <View style={styles.routeLine} />
                    <View style={styles.routeItem}>
                      <View style={[styles.routeDot, { backgroundColor: '#DC2626' }]} />
                      <Text style={styles.routeText}>{trip.dropoff_location}</Text>
                    </View>
                  </View>

                  <View style={styles.tripFooter}>
                    <View style={styles.tripMetrics}>
                      <View style={styles.metricItem}>
                        <Navigation size={12} color="#6B7280" />
                        <Text style={styles.metricText}>{(trip.distance || 0).toFixed(1)} km</Text>
                      </View>
                      <View style={styles.metricItem}>
                        <Clock size={12} color="#6B7280" />
                        <Text style={styles.metricText}>{trip.duration || 0} min</Text>
                      </View>
                    </View>
                    <Text style={styles.tripDate}>{formatDate(trip.created_at)}</Text>
                  </View>

                  <View style={styles.tripBreakdown}>
                    <View style={styles.breakdownItem}>
                      <Text style={styles.breakdownLabel}>Fare</Text>
                      <Text style={styles.breakdownValue}>${(trip.fare || 0).toFixed(2)}</Text>
                    </View>
                    <View style={styles.breakdownItem}>
                      <Text style={styles.breakdownLabel}>Distance</Text>
                      <Text style={[styles.breakdownValue, styles.tipValue]}>
                        {(trip.distance || 0).toFixed(1)} km
                      </Text>
                    </View>
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          )}
        </Animated.View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#6B7280',
  },
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
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
  filterButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  filterTabs: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    gap: 12,
  },
  filterTab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    gap: 6,
  },
  activeFilterTab: {
    backgroundColor: '#10B981',
  },
  filterTabText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#6B7280',
  },
  activeFilterTabText: {
    color: '#FFFFFF',
  },
  filterTabBadge: {
    backgroundColor: '#E5E7EB',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 1,
    minWidth: 18,
    alignItems: 'center',
  },
  activeFilterTabBadge: {
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  filterTabBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#374151',
  },
  activeFilterTabBadgeText: {
    color: '#FFFFFF',
  },
  content: {
    flex: 1,
    paddingTop: 20,
  },
  statsSection: {
    marginBottom: 24,
  },
  statsGrid: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    gap: 12,
  },
  statCard: {
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
  statValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginTop: 8,
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  tripsSection: {
    marginBottom: 40,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 48,
    paddingHorizontal: 24,
  },
  emptyStateText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#374151',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateSubtext: {
    fontSize: 14,
    color: '#9CA3AF',
    textAlign: 'center',
  },
  tripsContainer: {
    paddingHorizontal: 24,
    gap: 12,
  },
  tripCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  tripHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  tripInfo: {
    flex: 1,
  },
  passengerName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  tripStatus: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
    textTransform: 'capitalize',
  },
  tripEarnings: {
    alignItems: 'flex-end',
  },
  fareAmount: {
    fontSize: 18,
    fontWeight: '700',
    color: '#10B981',
    marginBottom: 2,
  },
  tripTime: {
    fontSize: 12,
    color: '#6B7280',
  },
  tripRoute: {
    marginBottom: 16,
  },
  routeItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  routeDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 12,
  },
  routeLine: {
    width: 2,
    height: 16,
    backgroundColor: '#D1D5DB',
    marginLeft: 3,
    marginRight: 12,
    marginVertical: 2,
  },
  routeText: {
    fontSize: 14,
    color: '#374151',
    flex: 1,
  },
  tripFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  tripMetrics: {
    flexDirection: 'row',
    gap: 16,
  },
  metricItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  metricText: {
    fontSize: 12,
    color: '#6B7280',
  },
  tripDate: {
    fontSize: 12,
    color: '#6B7280',
  },
  tripBreakdown: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  breakdownItem: {
    alignItems: 'center',
  },
  breakdownLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 2,
  },
  breakdownValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
  },
  tipValue: {
    color: '#10B981',
  },
});