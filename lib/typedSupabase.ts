import { supabase } from './supabase';
import { Database } from '@/types/database';

// Type-safe wrapper for payment_methods table
export const paymentMethodsTable = () => {
  return supabase.from('payment_methods');
};

// Type-safe wrapper for saved_addresses table
export const savedAddressesTable = () => {
  return supabase.from('saved_addresses');
};

// Type-safe wrapper for profiles table
export const profilesTable = () => {
  return supabase.from('profiles');
};

// Type-safe wrapper for rides table
export const ridesTable = () => {
  return supabase.from('rides');
};

// Type-safe wrapper for drivers table
export const driversTable = () => {
  return supabase.from('drivers');
};

// Type-safe wrapper for passengers table
export const passengersTable = () => {
  return supabase.from('passengers');
};

// Type-safe wrapper for driver_applications table
export const driverApplicationsTable = () => {
  return supabase.from('driver_applications');
};

// Type-safe wrapper for ride_ratings table
export const rideRatingsTable = () => {
  return supabase.from('ride_ratings');
};

// Type-safe wrapper for app_settings table
export const appSettingsTable = () => {
  return supabase.from('app_settings');
};

export { supabase };