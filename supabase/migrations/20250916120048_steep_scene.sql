/*
  # Clean and Rebuild RideShare Database Schema

  This migration completely rebuilds the database schema for the RideShare application.

  ## What this migration does:
  1. **Cleanup**: Removes all existing tables, functions, triggers, and policies
  2. **Core Tables**: Creates profiles, drivers, passengers, rides tables
  3. **Application System**: Sets up driver application workflow
  4. **User Features**: Adds saved addresses, payment methods, ratings
  5. **Configuration**: App settings for fare calculation
  6. **Security**: Comprehensive RLS policies for all tables
  7. **Sample Data**: Test drivers and applications for development

  ## New Tables:
  - `profiles` - User profiles with type system (passenger/driver/admin)
  - `drivers` - Driver information, vehicle details, and earnings
  - `passengers` - Passenger records linked to auth users
  - `rides` - Trip data with pickup/dropoff and status tracking
  - `driver_applications` - Driver application workflow
  - `saved_addresses` - User's favorite locations
  - `payment_methods` - Payment card management
  - `ride_ratings` - Trip feedback and rating system
  - `app_settings` - Configurable fare rates and settings

  ## Security:
  - Row Level Security enabled on all tables
  - Users can only access their own data
  - Proper foreign key relationships
  - Secure user registration trigger
*/

-- =============================================
-- CLEANUP: Remove all existing tables and objects
-- =============================================

-- Drop all existing tables (order matters due to foreign keys)
DROP TABLE IF EXISTS public.ride_ratings CASCADE;
DROP TABLE IF EXISTS public.payment_methods CASCADE;
DROP TABLE IF EXISTS public.saved_addresses CASCADE;
DROP TABLE IF EXISTS public.driver_applications CASCADE;
DROP TABLE IF EXISTS public.rides CASCADE;
DROP TABLE IF EXISTS public.passengers CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.app_settings CASCADE;

-- Drop any existing functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.increment_driver_stats(text, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.increment_passenger_stats(text, numeric) CASCADE;

-- Drop any existing types
DROP TYPE IF EXISTS public.user_type CASCADE;
DROP TYPE IF EXISTS public.ride_status CASCADE;
DROP TYPE IF EXISTS public.driver_status CASCADE;
DROP TYPE IF EXISTS public.application_status CASCADE;
DROP TYPE IF EXISTS public.payment_type CASCADE;

-- =============================================
-- CREATE TYPES
-- =============================================

CREATE TYPE public.user_type AS ENUM ('passenger', 'driver', 'admin');
CREATE TYPE public.ride_status AS ENUM ('active', 'completed', 'cancelled');
CREATE TYPE public.driver_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE public.application_status AS ENUM ('pending', 'under_review', 'approved', 'rejected');
CREATE TYPE public.payment_type AS ENUM ('card', 'paypal', 'apple_pay', 'google_pay');

-- =============================================
-- CORE TABLES
-- =============================================

-- Profiles table (core user data)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  user_type public.user_type NOT NULL DEFAULT 'passenger',
  rating DECIMAL(2,1) DEFAULT 5.0,
  total_trips INTEGER DEFAULT 0,
  driver_status TEXT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Drivers table (driver-specific data)
CREATE TABLE IF NOT EXISTS public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  rating DECIMAL(2,1) DEFAULT 5.0,
  vehicle_type TEXT DEFAULT 'economy',
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_year TEXT,
  vehicle_color TEXT,
  license_plate TEXT,
  status public.driver_status DEFAULT 'inactive',
  documents_verified BOOLEAN DEFAULT false,
  current_location JSONB,
  total_rides INTEGER DEFAULT 0,
  earnings DECIMAL(10,2) DEFAULT 0.00,
  last_active TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id),
  UNIQUE(email)
);

-- Passengers table (passenger-specific data)
CREATE TABLE IF NOT EXISTS public.passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT DEFAULT '',
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id),
  UNIQUE(email)
);

-- Rides table (trip data)
CREATE TABLE IF NOT EXISTS public.rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID NOT NULL REFERENCES public.passengers(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  status public.ride_status DEFAULT 'active',
  fare DECIMAL(8,2) DEFAULT 0.00,
  distance DECIMAL(8,2) DEFAULT 0.00,
  duration INTEGER DEFAULT 0,
  eta TEXT DEFAULT '',
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Driver Applications table
CREATE TABLE IF NOT EXISTS public.driver_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  license_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL DEFAULT 'economy',
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_year TEXT,
  vehicle_color TEXT,
  license_plate TEXT,
  insurance_number TEXT NOT NULL,
  status public.application_status DEFAULT 'pending',
  documents JSONB DEFAULT '{"license_uploaded": false, "insurance_uploaded": false, "vehicle_registration_uploaded": false}',
  notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Saved Addresses table
CREATE TABLE IF NOT EXISTS public.saved_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Payment Methods table
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type public.payment_type NOT NULL DEFAULT 'card',
  card_last_four TEXT,
  card_brand TEXT,
  stripe_payment_method_id TEXT,
  stripe_customer_id TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ride Ratings table
CREATE TABLE IF NOT EXISTS public.ride_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
  user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
  driver_rating INTEGER CHECK (driver_rating >= 1 AND driver_rating <= 5),
  user_comment TEXT,
  driver_comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ride_id)
);

-- App Settings table
CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  base_fare DECIMAL(6,2) DEFAULT 3.50,
  per_km_rate DECIMAL(6,2) DEFAULT 1.20,
  per_minute_rate DECIMAL(6,2) DEFAULT 0.25,
  surge_multiplier DECIMAL(3,2) DEFAULT 1.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX IF NOT EXISTS profiles_user_id_idx ON public.profiles (user_id);
CREATE INDEX IF NOT EXISTS profiles_user_type_idx ON public.profiles (user_type);
CREATE INDEX IF NOT EXISTS drivers_user_id_idx ON public.drivers (user_id);
CREATE INDEX IF NOT EXISTS drivers_status_idx ON public.drivers (status);
CREATE INDEX IF NOT EXISTS drivers_email_idx ON public.drivers (email);
CREATE INDEX IF NOT EXISTS passengers_user_id_idx ON public.passengers (user_id);
CREATE INDEX IF NOT EXISTS passengers_email_idx ON public.passengers (email);
CREATE INDEX IF NOT EXISTS rides_passenger_id_idx ON public.rides (passenger_id);
CREATE INDEX IF NOT EXISTS rides_driver_id_idx ON public.rides (driver_id);
CREATE INDEX IF NOT EXISTS rides_status_idx ON public.rides (status);
CREATE INDEX IF NOT EXISTS rides_created_at_idx ON public.rides (created_at);
CREATE INDEX IF NOT EXISTS driver_applications_user_id_idx ON public.driver_applications (user_id);
CREATE INDEX IF NOT EXISTS driver_applications_status_idx ON public.driver_applications (status);
CREATE INDEX IF NOT EXISTS saved_addresses_user_id_idx ON public.saved_addresses (user_id);
CREATE INDEX IF NOT EXISTS payment_methods_user_id_idx ON public.payment_methods (user_id);
CREATE INDEX IF NOT EXISTS ride_ratings_ride_id_idx ON public.ride_ratings (ride_id);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Allow profile inserts by service role and authenticated users" ON public.profiles FOR INSERT WITH CHECK ((auth.role() = 'service_role') OR (user_id = auth.uid()));

-- Drivers policies
CREATE POLICY "Drivers can view their own data" ON public.drivers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Drivers can update their own data" ON public.drivers FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Allow driver inserts" ON public.drivers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Public can view active drivers" ON public.drivers FOR SELECT USING (status = 'active' AND documents_verified = true);

-- Passengers policies
CREATE POLICY "Passengers can view their own data" ON public.passengers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Passengers can update their own data" ON public.passengers FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Allow passenger inserts" ON public.passengers FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Rides policies
CREATE POLICY "Users can view their own rides" ON public.rides FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.drivers WHERE drivers.id = rides.driver_id AND drivers.user_id = auth.uid())
);
CREATE POLICY "Passengers can create rides" ON public.rides FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid())
);
CREATE POLICY "Drivers can update assigned rides" ON public.rides FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.drivers WHERE drivers.id = rides.driver_id AND drivers.user_id = auth.uid())
);

-- Driver Applications policies
CREATE POLICY "Users can view their own applications" ON public.driver_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create their own applications" ON public.driver_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own applications" ON public.driver_applications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all applications" ON public.driver_applications FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.user_id = auth.uid() AND profiles.user_type = 'admin')
);
CREATE POLICY "Admins can update all applications" ON public.driver_applications FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.user_id = auth.uid() AND profiles.user_type = 'admin')
);

-- Saved Addresses policies
CREATE POLICY "Users can manage their own addresses" ON public.saved_addresses FOR ALL USING (auth.uid() = user_id);

-- Payment Methods policies
CREATE POLICY "Users can manage their own payment methods" ON public.payment_methods FOR ALL USING (auth.uid() = user_id);

-- Ride Ratings policies
CREATE POLICY "Users can view ratings for their rides" ON public.ride_ratings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create ratings for their rides" ON public.ride_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);

-- App Settings policies (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view app settings" ON public.app_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can update app settings" ON public.app_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.user_id = auth.uid() AND profiles.user_type = 'admin')
);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'passenger')::public.user_type
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_rides_updated_at BEFORE UPDATE ON public.rides FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_driver_applications_updated_at BEFORE UPDATE ON public.driver_applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_saved_addresses_updated_at BEFORE UPDATE ON public.saved_addresses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON public.payment_methods FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON public.app_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create trigger for automatic profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Insert default app settings
INSERT INTO public.app_settings (base_fare, per_km_rate, per_minute_rate, surge_multiplier) 
VALUES (3.50, 1.20, 0.25, 1.00)
ON CONFLICT DO NOTHING;

-- Insert sample drivers (for testing)
INSERT INTO public.drivers (
  id, user_id, name, email, phone, rating, vehicle_type, vehicle_make, vehicle_model, 
  vehicle_year, vehicle_color, license_plate, status, documents_verified, 
  current_location, total_rides, earnings
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001',
  '550e8400-e29b-41d4-a716-446655440001',
  'John Smith',
  'test@driver.com',
  '+1 (555) 123-4567',
  4.8,
  'economy',
  'Toyota',
  'Camry',
  '2022',
  'Silver',
  'ABC 123',
  'active',
  true,
  '{"latitude": 37.7749, "longitude": -122.4194}',
  342,
  8567.25
),
(
  '550e8400-e29b-41d4-a716-446655440002',
  '550e8400-e29b-41d4-a716-446655440002',
  'Sarah Johnson',
  'sarah@driver.com',
  '+1 (555) 234-5678',
  4.9,
  'comfort',
  'Honda',
  'Accord',
  '2021',
  'Black',
  'XYZ 789',
  'active',
  true,
  '{"latitude": 37.7849, "longitude": -122.4094}',
  156,
  4230.75
),
(
  '550e8400-e29b-41d4-a716-446655440003',
  '550e8400-e29b-41d4-a716-446655440003',
  'Mike Davis',
  'mike@driver.com',
  '+1 (555) 345-6789',
  4.7,
  'luxury',
  'BMW',
  '3 Series',
  '2023',
  'White',
  'LUX 456',
  'active',
  true,
  '{"latitude": 37.7649, "longitude": -122.4294}',
  89,
  3890.50
)
ON CONFLICT (id) DO NOTHING;

-- Insert sample driver applications (for admin testing)
INSERT INTO public.driver_applications (
  user_id, email, full_name, phone, license_number, vehicle_type, 
  vehicle_make, vehicle_model, vehicle_year, vehicle_color, license_plate, 
  insurance_number, status, documents
) VALUES 
(
  gen_random_uuid(),
  'applicant1@example.com',
  'Alex Rodriguez',
  '+1 (555) 111-2222',
  'DL123456789',
  'economy',
  'Nissan',
  'Altima',
  '2020',
  'Blue',
  'APP 001',
  'INS123456789',
  'pending',
  '{"license_uploaded": true, "insurance_uploaded": false, "vehicle_registration_uploaded": true}'
),
(
  gen_random_uuid(),
  'applicant2@example.com',
  'Maria Garcia',
  '+1 (555) 222-3333',
  'DL987654321',
  'comfort',
  'Hyundai',
  'Sonata',
  '2021',
  'Red',
  'APP 002',
  'INS987654321',
  'pending',
  '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": false}'
),
(
  gen_random_uuid(),
  'applicant3@example.com',
  'David Kim',
  '+1 (555) 333-4444',
  'DL456789123',
  'luxury',
  'Audi',
  'A4',
  '2022',
  'Gray',
  'APP 003',
  'INS456789123',
  'under_review',
  '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": true}'
)
ON CONFLICT DO NOTHING;