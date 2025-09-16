import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  StatusBar,
  Animated,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Users, Car, DollarSign, TrendingUp, Settings, FileText, ChartBar as BarChart3, Shield, Bell, TriangleAlert as AlertTriangle, CircleCheck as CheckCircle, Clock, MapPin } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '@/hooks/useAuth';
import { router } from 'expo-router';
import { driversTable, ridesTable, passengersTable, supabase } from '@/lib/typedSupabase';
import { Database } from '@/types/database';

type Driver = Database['public']['Tables']['drivers']['Row'];
type Ride = Database['public']['Tables']['rides']['Row'];
type Passenger = Database['public']['Tables']['passengers']['Row'];

export default function AdminDashboard() {
  const [fadeAnim] = useState(new Animated.Value(0));
  const [dashboardStats, setDashboardStats] = useState({
    totalDrivers: 0,
    activeDrivers: 0,
    totalPassengers: 0,
    activeRides: 0,
    todayRevenue: 0,
    pendingApplications: 0,
    completedTrips: 0,
    averageRating: 0,
  });
  const [recentActivities, setRecentActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { user, signOut } = useAuth();

  useEffect(() => {
    if (user) {
      loadDashboardData();
    }
    
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start();
  }, [user]);

  const loadDashboardData = async () => {
    try {
      // Load drivers data
      const { data: allDrivers } = await driversTable().select('*');
      const activeDrivers = allDrivers?.filter(d => d.status === 'active') || [];
      
      // Load passengers data
      const { data: allPassengers } = await passengersTable().select('*');
      
      // Load rides data
      const { data: allRides } = await ridesTable().select('*');
      const activeRides = allRides?.filter(r => r.status === 'active') || [];
      const completedRides = allRides?.filter(r => r.status === 'completed') || [];
      
      // Calculate today's revenue
      const today = new Date();
      const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString();
      const { data: todayRides } = await ridesTable()
        .select('fare')
        .eq('status', 'completed')
        .gte('completed_at', startOfDay);
      
      const todayRevenue = todayRides?.reduce((sum, ride) => sum + (ride.fare || 0), 0) || 0;
      
      // Load pending applications
      const { data: applications } = await supabase
        .from('driver_applications')
        .select('*')
        .eq('status', 'pending');
      
      // Calculate average rating
      const driversWithRating = allDrivers?.filter(d => d.rating && d.rating > 0) || [];
      const averageRating = driversWithRating.length > 0 
        ? driversWithRating.reduce((sum, d) => sum + (d.rating || 0), 0) / driversWithRating.length
        : 0;
      
      setDashboardStats({
        totalDrivers: allDrivers?.length || 0,
        activeDrivers: activeDrivers.length,
        totalPassengers: allPassengers?.length || 0,
        activeRides: activeRides.length,
        todayRevenue,
        pendingApplications: applications?.length || 0,
        completedTrips: completedRides.length,
        averageRating,
      });
      
      // Load recent activities from database
      await loadRecentActivities();
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadRecentActivities = async () => {
    try {
      const activities = [];
      
      // Recent driver applications
      const { data: recentApps } = await supabase
        .from('driver_applications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(3);
      
      recentApps?.forEach(app => {
        activities.push({
          id: `app-${app.id}`,
          type: 'application',
          message: `New driver application from ${app.full_name}`,
          time: getTimeAgo(app.created_at),
          status: app.status,
        });
      });
      
      // Recent rides
      const { data: recentRides } = await ridesTable()
        .select('*')
        .order('created_at', { ascending: false })
        .limit(3);
      
      recentRides?.forEach(ride => {
        activities.push({
          id: `ride-${ride.id}`,
          type: 'ride',
          message: `Ride ${ride.status} - ${ride.pickup_location}`,
          time: getTimeAgo(ride.created_at!),
          status: ride.status,
        });
      });
      
      // Recent driver status changes
      const { data: recentDrivers } = await driversTable()
        .select('*')
        .order('last_active', { ascending: false })
        .limit(2);
      
      recentDrivers?.forEach(driver => {
        activities.push({
          id: `driver-${driver.id}`,
          type: 'driver',
          message: `Driver ${driver.name} went ${driver.status}`,
          time: getTimeAgo(driver.last_active!),
          status: driver.status,
        });
      });
      
      // Sort all activities by time and take the most recent
      setRecentActivities(activities.slice(0, 4));
    } catch (error) {
      console.error('Error loading recent activities:', error);
    }
  };

  const getTimeAgo = (dateString: string) => {
    const now = new Date();
    const date = new Date(dateString);
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} min ago`;
    
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
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
              await signOut();
              router.replace('/(auth)/login');
            } catch (error) {
              console.error('Admin logout error:', error);
              router.replace('/(auth)/login');
            }
          },
        },
      ]
    );
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'application':
        return <FileText size={16} color="#F59E0B" />;
      case 'ride':
        return <Car size={16} color="#3B82F6" />;
      case 'driver':
        return <Users size={16} color="#10B981" />;
      case 'system':
        return <Settings size={16} color="#6B7280" />;
      default:
        return <Bell size={16} color="#6B7280" />;
    }
  };

  const getActivityBgColor = (type: string) => {
    switch (type) {
      case 'application':
        return '#FEF3C7';
      case 'ride':
        return '#DBEAFE';
      case 'driver':
        return '#D1FAE5';
      case 'system':
        return '#F3F4F6';
      default:
        return '#F3F4F6';
    }
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
          colors={['#DC2626', '#B91C1C']}
          style={styles.headerGradient}
        >
          <View style={styles.headerContent}>
            <View style={styles.headerLeft}>
              <Text style={styles.greeting}>Admin Dashboard</Text>
              <Text style={styles.welcomeText}>Welcome back, Admin!</Text>
            </View>
            <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
              <Shield size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </LinearGradient>
      </Animated.View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Key Metrics */}
        <Animated.View style={[styles.metricsSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Key Metrics</Text>
          
          <View style={styles.metricsGrid}>
            <View style={styles.metricCard}>
              <View style={[styles.metricIcon, { backgroundColor: '#DBEAFE' }]}>
                <Users size={24} color="#3B82F6" />
              </View>
              <Text style={styles.metricValue}>{dashboardStats.totalDrivers}</Text>
              <Text style={styles.metricLabel}>Total Drivers</Text>
              <Text style={styles.metricSubtext}>{dashboardStats.activeDrivers} online</Text>
            </View>
            
            <View style={styles.metricCard}>
              <View style={[styles.metricIcon, { backgroundColor: '#D1FAE5' }]}>
                <Car size={24} color="#10B981" />
              </View>
              <Text style={styles.metricValue}>{dashboardStats.totalPassengers.toLocaleString()}</Text>
              <Text style={styles.metricLabel}>Passengers</Text>
              <Text style={styles.metricSubtext}>{dashboardStats.activeRides} active rides</Text>
            </View>
            
            <View style={styles.metricCard}>
              <View style={[styles.metricIcon, { backgroundColor: '#FEF3C7' }]}>
                <DollarSign size={24} color="#F59E0B" />
              </View>
              <Text style={styles.metricValue}>${dashboardStats.todayRevenue.toLocaleString()}</Text>
              <Text style={styles.metricLabel}>Today's Revenue</Text>
              <Text style={styles.metricSubtext}>+12% from yesterday</Text>
            </View>
            
            <View style={styles.metricCard}>
              <View style={[styles.metricIcon, { backgroundColor: '#FEE2E2' }]}>
                <FileText size={24} color="#DC2626" />
              </View>
              <Text style={styles.metricValue}>{dashboardStats.pendingApplications}</Text>
              <Text style={styles.metricLabel}>Pending Apps</Text>
              <Text style={styles.metricSubtext}>Needs review</Text>
            </View>
          </View>
        </Animated.View>

        {/* Quick Actions */}
        <Animated.View style={[styles.actionsSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          
          <View style={styles.actionsGrid}>
            <TouchableOpacity 
              style={styles.actionCard}
              onPress={() => router.push('/(admin)/applications')}
            >
              <FileText size={24} color="#DC2626" />
              <Text style={styles.actionText}>Review Applications</Text>
              <View style={styles.actionBadge}>
                <Text style={styles.actionBadgeText}>{dashboardStats.pendingApplications}</Text>
              </View>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionCard}
              onPress={() => router.push('/(admin)/drivers')}
            >
              <Users size={24} color="#3B82F6" />
              <Text style={styles.actionText}>Manage Drivers</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionCard}
              onPress={() => router.push('/(admin)/analytics')}
            >
              <BarChart3 size={24} color="#10B981" />
              <Text style={styles.actionText}>View Analytics</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionCard}
              onPress={() => router.push('/(admin)/settings')}
            >
              <Settings size={24} color="#6B7280" />
              <Text style={styles.actionText}>App Settings</Text>
            </TouchableOpacity>
          </View>
        </Animated.View>

        {/* Recent Activity */}
        <Animated.View style={[styles.activitySection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>Recent Activity</Text>
          
          <View style={styles.activityContainer}>
            {recentActivities.map((activity) => (
              <View key={activity.id} style={styles.activityItem}>
                <View style={[
                  styles.activityIcon,
                  { backgroundColor: getActivityBgColor(activity.type) }
                ]}>
                  {getActivityIcon(activity.type)}
                </View>
                <View style={styles.activityContent}>
                  <Text style={styles.activityMessage}>{activity.message}</Text>
                  <Text style={styles.activityTime}>{activity.time}</Text>
                </View>
                <View style={styles.activityStatus}>
                  {activity.status === 'pending' && <Clock size={16} color="#F59E0B" />}
                  {activity.status === 'active' && <AlertTriangle size={16} color="#3B82F6" />}
                  {activity.status === 'success' && <CheckCircle size={16} color="#10B981" />}
                </View>
              </View>
            ))}
          </View>
        </Animated.View>

        {/* System Status */}
        <Animated.View style={[styles.statusSection, { opacity: fadeAnim }]}>
          <Text style={styles.sectionTitle}>System Status</Text>
          
          <View style={styles.statusContainer}>
            <View style={styles.statusItem}>
              <View style={styles.statusIndicator}>
                <CheckCircle size={16} color="#10B981" />
              </View>
              <Text style={styles.statusText}>All systems operational</Text>
            </View>
            
            <View style={styles.statusItem}>
              <View style={styles.statusIndicator}>
                <CheckCircle size={16} color="#10B981" />
              </View>
              <Text style={styles.statusText}>Payment processing: Normal</Text>
            </View>
            
            <View style={styles.statusItem}>
              <View style={styles.statusIndicator}>
                <CheckCircle size={16} color="#10B981" />
              </View>
              <Text style={styles.statusText}>Driver matching: Optimal</Text>
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
  welcomeText: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  logoutButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    paddingTop: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  metricsSection: {
    marginBottom: 32,
  },
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 24,
    gap: 12,
  },
  metricCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  metricIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  metricValue: {
    fontSize: 24,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  metricLabel: {
    fontSize: 14,
    color: '#6B7280',
    fontWeight: '500',
    marginBottom: 4,
  },
  metricSubtext: {
    fontSize: 12,
    color: '#9CA3AF',
    textAlign: 'center',
  },
  actionsSection: {
    marginBottom: 32,
  },
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 24,
    gap: 12,
  },
  actionCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
    position: 'relative',
  },
  actionText: {
    fontSize: 14,
    color: '#374151',
    fontWeight: '600',
    marginTop: 8,
    textAlign: 'center',
  },
  actionBadge: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: '#DC2626',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    minWidth: 20,
    alignItems: 'center',
  },
  actionBadgeText: {
    color: '#FFFFFF',
    fontSize: 10,
    fontWeight: '600',
  },
  activitySection: {
    marginBottom: 32,
  },
  activityContainer: {
    paddingHorizontal: 24,
    gap: 12,
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  activityIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  activityContent: {
    flex: 1,
  },
  activityMessage: {
    fontSize: 14,
    color: '#111827',
    fontWeight: '500',
    marginBottom: 2,
  },
  activityTime: {
    fontSize: 12,
    color: '#6B7280',
  },
  activityStatus: {
    marginLeft: 8,
  },
  statusSection: {
    marginBottom: 40,
  },
  statusContainer: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 24,
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  statusItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
  },
  statusIndicator: {
    marginRight: 12,
  },
  statusText: {
    fontSize: 14,
    color: '#374151',
    fontWeight: '500',
  },
});