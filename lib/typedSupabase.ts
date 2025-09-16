import { supabase } from './supabase';
import { Database } from '@/types/database';
import { useAuth } from '@/hooks/useAuth';

// Type-safe wrapper for payment_methods table
export const paymentMethodsTable = () => {
  return supabase.from('payment_methods') as any;
};

// Type-safe wrapper for saved_addresses table
export const savedAddressesTable = () => {
  return supabase.from('saved_addresses') as any;
};

// Type-safe wrapper for profiles table
export const profilesTable = () => {
  return supabase.from('profiles') as any;
};

// Type-safe wrapper for rides table
export const ridesTable = () => {
  return supabase.from('rides') as any;
};

// Mock data for drivers
const mockDrivers = [
  {
    id: '550e8400-e29b-41d4-a716-446655440001',
    name: 'Mohammed Alami',
    email: 'mohammed.alami@example.com',
    phone: '+212600000001',
    rating: 4.8,
    vehicle_type: 'comfort',
    license_plate: '1234-A-1',
    status: 'available',
    documents_verified: true,
    current_location: { latitude: 33.5731, longitude: -7.5898 },
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440002',
    name: 'Sara Benjelloun',
    email: 'sara.benjelloun@example.com',
    phone: '+212600000002',
    rating: 4.9,
    vehicle_type: 'luxury',
    license_plate: '1234-B-2',
    status: 'available',
    documents_verified: true,
    current_location: { latitude: 33.5741, longitude: -7.5878 },
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440003',
    name: 'Karim Tazi',
    email: 'karim.tazi@example.com',
    phone: '+212600000003',
    rating: 4.7,
    vehicle_type: 'economy',
    license_plate: '1234-C-3',
    status: 'available',
    documents_verified: true,
    current_location: { latitude: 33.5721, longitude: -7.5918 },
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }
];

type Driver = (typeof mockDrivers)[0];

type SupabaseResponse<T> = { data: T };

interface DriverQueryBuilder {
  data: Driver[];
  eq: (field: keyof Driver, value: string | boolean) => DriverQueryBuilder;
  execute: () => Promise<SupabaseResponse<Driver[]> & { error: any }>;
}

interface DriverQuery {
  select: (columns?: '*' | string) => DriverQueryBuilder;
  update: (data: Partial<Driver>) => {
    eq: (field: keyof Driver, value: string) => Promise<SupabaseResponse<Driver | null>>;
  };
}

const createDriversTable = (): DriverQuery => ({
  select: (columns: '*' | string = '*'): DriverQueryBuilder => {
    let currentData = mockDrivers;
    const builder: DriverQueryBuilder = {
      data: currentData,
      eq: (field: keyof Driver, value: string | boolean) => {
        currentData = currentData.filter(driver => driver[field] === value);
        return builder;
      },
      execute: () => Promise.resolve({ data: currentData, error: null })
    };
    return builder;
  },
  update: (data: Partial<Driver>) => ({
    eq: (field: keyof Driver, value: string) => {
      const index = mockDrivers.findIndex(driver => driver[field] === value);
      if (index !== -1) {
        mockDrivers[index] = { ...mockDrivers[index], ...data };
        return Promise.resolve({ data: mockDrivers[index] });
      }
      return Promise.resolve({ data: null });
    }
  })
});

export const driversTable = createDriversTable;



// Type-safe wrapper for passengers table
export const passengersTable = () => {
  return supabase.from('passengers') as any;
};

// Type-safe wrapper for app_settings table
export const appSettingsTable = () => {
  return supabase.from('app_settings') as any;
};

export { supabase };
