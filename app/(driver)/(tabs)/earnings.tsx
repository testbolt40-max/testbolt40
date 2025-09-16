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
import { DollarSign, TrendingUp, Calendar, Clock, Car, ChartBar as BarChart3, Target, Award } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '@/hooks/useAuth';
import { driversTable, ridesTable } from '@/lib/typedSupabase';
import { Database } from '@/types/database';

type Driver = Database['public']['Tables']['drivers']['Row'];
type Ride = Database['public']['Tables']['rides']['Row'];

export default function DriverEarnings() {
  const [selectedPeriod, setSelectedPeriod] = useState('today');
  const [fadeAnim] = useState(new Animated.Value(0));
  const [driverData, setDriverData] = useState<Driver | null>(null);
  const [earningsData, setEarningsData] = useState({
    today: { total: 0, trips: 0, hours: 0, bonus: 0 },
    week: { total: 0, trips: 0, hours: 0, bonus: 0 },
    month: { total: 0, trips: 0, hours: 0, bonus: 0 }
  });
  const [recentTrips, setRecentTrips] = useState<Ride[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (user) {
      loadDriverEarnings();
    }
    
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start();
  }, [user]);

  const loadDriverEarnings = async () => {
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
        
        // Load earnings for different periods
        await loadEarningsForPeriods(driver.id);
        await loadRecentTrips(driver.id);
      }
    } catch (error) {
      console.error('Error loading driver earnings:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadEarningsForPeriods = async (driverId: string) => {
    try {
      const now = new Date();
      
      // Today
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const { data: todayRides } = await ridesTable()
        .select('fare, duration')
        .eq('driver_id', driverId)
        .eq('status', 'completed')
        .gte('completed_at', startOfDay);
      
      // This week
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay());
      startOfWeek.setHours(0, 0, 0, 0);
      const { data: weekRides } = await ridesTable()
        .select('fare, duration')
        .eq('driver_id', driverId)
        .eq('status', 'completed')
        .gte('completed_at', startOfWeek.toISOString());
      
      // This month
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      const { data: monthRides } = await ridesTable()
        .select('fare, duration')
        .eq('driver_id', driverId)
        .eq('status', 'completed')
        .gte('completed_at', startOfMonth);
      
      // Calculate earnings
      const calculateStats = (rides: any[]) => {
        const total = rides.reduce((sum, ride) => sum + (ride.fare || 0), 0);
        const trips = rides.length;
        const totalMinutes = rides.reduce((sum, ride) => sum + (ride.duration || 0), 0);
        const hours = totalMinutes / 60;
        const bonus = total * 0.1; // 10% bonus calculation
        
        return { total, trips, hours, bonus };
      };
      
      setEarningsData({
        today: calculateStats(todayRides || []),
        week: calculateStats(weekRides || []),
        month: calculateStats(monthRides || [])
      });
    } catch (error) {
      console.error('Error loading earnings data:', error);
    }
  };

  const loadRecentTrips = async (driverId: string) => {
    try {
      const { data: trips, error } = await ridesTable()
        .select('*')
        .eq('driver_id', driverId)
        .eq('status', 'completed')
        .order('completed_at', { ascending: false })
        .limit(10);
      
      if (error) throw error;
      setRecentTrips(trips || []);
    } catch (error) {
      console.error('Error loading recent trips:', error);
    }
  };

  const currentData = earningsData[selectedPeriod as keyof typeof earningsData];

  const formatTripTime = (completedAt: string) => {
    return new Date(completedAt).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Loading earnings...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      {/* Header */}
      <Animated.View style={[styles.header, { opacity: fadeAnim }]}>
        <Text style={styles.title}>Earnings</Text>
        <TouchableOpacity style={styles.chartButton}>
          <BarChart3 size={24} color="#6B7280" />
        </TouchableOpacity>
      </Animated.View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Period Selector */}
        <Animated.View style={[styles.periodSelector, { opacity: fadeAnim }]}>
          {['today', 'week', 'month'].map((period) => (
            <TouchableOpacity
              key={period}
              style={[
                styles.periodButton,
                selectedPeriod === period && styles.activePeriodButton,
              ]}
              onPress={() => setSelectedPeriod(period)}
            >
              <Text style={[
                styles.periodButtonText,
                selectedPeriod === period && styles.activePeriodButtonText,
              ]}>
                {period.charAt(0).toUpperCase() + period.slice(1)}
              </Text>
            </TouchableOpacity>
          ))}
        </Animated.View>

        {/* Earnings Summary */}
        <Animated.View style={[styles.summaryCard, { opacity: fadeAnim }]}>
          <LinearGradient
            colors={['#10B981', '#059669']}
            style={styles.summaryGradient}
          >
            <View style={styles.summaryContent}>
              <View style={styles.summaryHeader}>
                <Text style={styles.summaryTitle}>Total Earnings</Text>
                <DollarSign size={24} color="#FFFFFF" />
              </View>
              <Text style={styles.summaryAmount}>${currentData.total.toFixed(2)}</Text>
              <View style={styles.summaryStats}>
                <View style={styles.summaryStatItem}>
                  <Car size={16} color="rgba(255,255,255,0.8)" />
                  <Text style={styles.summaryStatText}>{currentData.trips} trips</Text>
                </View>
                <View style={styles.summaryStatItem}>
                  <Clock size={16} color="rgba(255,255,255,0.8)" />
                  <Text style={styles.summaryStatText}>{currentData.hours}h online</Text>
                </View>
              </View>
            </View>
          </LinearGradient>
        </Animated.View>

        {/* Earnings Breakdown */}
        <Animated.View style={[styles.breakdownSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Earnings Breakdown</Text>
          
          <View style={styles.breakdownGrid}>
            <View style={styles.breakdownCard}>
              <View style={styles.breakdownIcon}>
                <Car size={20} color="#3B82F6" />
              </View>
              <Text style={styles.breakdownValue}>
                ${(currentData.total - currentData.bonus).toFixed(2)}
              </Text>
              <Text style={styles.breakdownLabel}>Trip Fares</Text>
            </View>
            
            <View style={styles.breakdownCard}>
              <View style={styles.breakdownIcon}>
                <Award size={20} color="#F59E0B" />
              </View>
              <Text style={styles.breakdownValue}>${currentData.bonus.toFixed(2)}</Text>
              <Text style={styles.breakdownLabel}>Bonuses</Text>
            </View>
            
            <View style={styles.breakdownCard}>
              <View style={styles.breakdownIcon}>
                <Target size={20} color="#10B981" />
              </View>
              <Text style={styles.breakdownValue}>
                ${(currentData.total / currentData.hours).toFixed(2)}
              </Text>
              <Text style={styles.breakdownLabel}>Per Hour</Text>
            </View>
            
            <View style={styles.breakdownCard}>
              <View style={styles.breakdownIcon}>
                <TrendingUp size={20} color="#8B5CF6" />
              </View>
              <Text style={styles.breakdownValue}>
                ${(currentData.total / currentData.trips).toFixed(2)}
              </Text>
              <Text style={styles.breakdownLabel}>Per Trip</Text>
            </View>
          </View>
        </Animated.View>

        {/* Recent Trips */}
        <Animated.View style={[styles.tripsSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Recent Trips</Text>
          
          <View style={styles.tripsContainer}>
            {recentTrips.map((trip) => (
              <View key={trip.id} style={styles.tripCard}>
                <View style={styles.tripHeader}>
                  <Text style={styles.tripTime}>
                    {trip.completed_at ? formatTripTime(trip.completed_at) : 'N/A'}
                  </Text>
                  <Text style={styles.tripEarnings}>
                    ${(trip.fare || 0).toFixed(2)}
                  </Text>
                </View>
                <View style={styles.tripRoute}>
                  <Text style={styles.tripLocation}>{trip.pickup_location}</Text>
                  <View style={styles.tripArrow} />
                  <Text style={styles.tripLocation}>{trip.dropoff_location}</Text>
                </View>
                <View style={styles.tripBreakdown}>
                  <Text style={styles.tripFare}>Fare: ${(trip.fare || 0).toFixed(2)}</Text>
                  <Text style={styles.tripTip}>Distance: {(trip.distance || 0).toFixed(1)} km</Text>
                </View>
              </View>
            ))}
          </View>
        </Animated.View>

        {/* Goals Section */}
        <Animated.View style={[styles.goalsSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Daily Goal</Text>
          
          <View style={styles.goalCard}>
            <View style={styles.goalHeader}>
              <Text style={styles.goalTitle}>Earnings Goal</Text>
              <Text style={styles.goalAmount}>$150.00</Text>
            </View>
            
            <View style={styles.goalProgress}>
              <View style={styles.goalProgressBar}>
                <View 
                  style={[
                    styles.goalProgressFill, 
                    { width: `${(currentData.total / 150) * 100}%` }
                  ]} 
                />
              </View>
              <Text style={styles.goalProgressText}>
                ${(150 - currentData.total).toFixed(2)} to go
              </Text>
            </View>
          </View>
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
  chartButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    paddingTop: 20,
  },
  periodSelector: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    marginBottom: 20,
    gap: 8,
  },
  periodButton: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  activePeriodButton: {
    backgroundColor: '#10B981',
    borderColor: '#10B981',
  },
  periodButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6B7280',
  },
  activePeriodButtonText: {
    color: '#FFFFFF',
  },
  summaryCard: {
    marginHorizontal: 24,
    marginBottom: 24,
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  summaryGradient: {
    padding: 24,
  },
  summaryContent: {
    alignItems: 'center',
  },
  summaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    gap: 8,
  },
  summaryTitle: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.9)',
    fontWeight: '500',
  },
  summaryAmount: {
    fontSize: 36,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  summaryStats: {
    flexDirection: 'row',
    gap: 24,
  },
  summaryStatItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  summaryStatText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.9)',
    fontWeight: '500',
  },
  breakdownSection: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  breakdownGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 24,
    gap: 12,
  },
  breakdownCard: {
    flex: 1,
    minWidth: '45%',
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
  breakdownIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  breakdownValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  breakdownLabel: {
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  tripsSection: {
    marginBottom: 24,
  },
  tripsContainer: {
    paddingHorizontal: 24,
    gap: 12,
  },
  tripCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  tripHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  tripTime: {
    fontSize: 14,
    color: '#6B7280',
    fontWeight: '500',
  },
  tripEarnings: {
    fontSize: 16,
    fontWeight: '700',
    color: '#10B981',
  },
  tripRoute: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    gap: 8,
  },
  tripLocation: {
    fontSize: 14,
    color: '#111827',
    fontWeight: '500',
  },
  tripArrow: {
    width: 16,
    height: 1,
    backgroundColor: '#D1D5DB',
  },
  tripBreakdown: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  tripFare: {
    fontSize: 12,
    color: '#6B7280',
  },
  tripTip: {
    fontSize: 12,
    color: '#10B981',
    fontWeight: '500',
  },
  goalsSection: {
    marginBottom: 40,
  },
  goalCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    marginHorizontal: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  goalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  goalTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
  },
  goalAmount: {
    fontSize: 16,
    fontWeight: '700',
    color: '#6B7280',
  },
  goalProgress: {
    gap: 8,
  },
  goalProgressBar: {
    height: 8,
    backgroundColor: '#E5E7EB',
    borderRadius: 4,
    overflow: 'hidden',
  },
  goalProgressFill: {
    height: '100%',
    backgroundColor: '#10B981',
    borderRadius: 4,
  },
  goalProgressText: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
});