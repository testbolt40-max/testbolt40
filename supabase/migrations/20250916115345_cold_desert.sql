/*
  # Clean Database and Rebuild Schema

  1. Cleanup
    - Drop all existing tables, types, functions, and policies
    - Remove all triggers and constraints
    - Clean slate for fresh start

  2. New Tables
    - `profiles` - User profiles with type system (passenger/driver/admin)
    - `drivers` - Driver-specific data with vehicle info and earnings
    - `passengers` - Passenger records linked to auth users
    - `rides` - Trip data with pickup/dropoff and status tracking
    - `driver_applications` - Driver application workflow
    - `saved_addresses` - User saved locations
    - `payment_methods` - Payment card management
    - `ride_ratings` - Trip feedback system
    - `app_settings` - Configurable fare rates

  3. Security
    - Enable RLS on all tables
    - Comprehensive policies for data access
    - Secure user registration trigger

  4. Sample Data
    - Test drivers and applications
    - Default app settings
*/

-- =============================================
-- CLEANUP: Remove all existing tables and objects
-- =============================================

-- Drop all tables (CASCADE removes dependent objects)
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.passengers CASCADE;
DROP TABLE IF EXISTS public.rides CASCADE;
DROP TABLE IF EXISTS public.driver_applications CASCADE;
DROP TABLE IF EXISTS public.saved_addresses CASCADE;
DROP TABLE IF EXISTS public.payment_methods CASCADE;
DROP TABLE IF EXISTS public.ride_ratings CASCADE;
DROP TABLE IF EXISTS public.app_settings CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS public.user_type CASCADE;
DROP TYPE IF EXISTS public.payment_method_type CASCADE;
DROP TYPE IF EXISTS public.ride_status CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- =============================================
-- CREATE CUSTOM TYPES
-- =============================================

CREATE TYPE public.user_type AS ENUM ('passenger', 'driver', 'admin');
CREATE TYPE public.payment_method_type AS ENUM ('card', 'paypal', 'apple_pay', 'google_pay');
CREATE TYPE public.ride_status AS ENUM ('active', 'completed', 'cancelled');

-- =============================================
-- CREATE TABLES
-- =============================================

-- Profiles table (core user data)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  user_type user_type NOT NULL DEFAULT 'passenger',
  rating NUMERIC(3,2) DEFAULT 0,
  total_trips INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Drivers table (driver-specific data)
CREATE TABLE public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  rating NUMERIC(3,2) DEFAULT 0,
  vehicle_type TEXT,
  license_plate TEXT,
  status TEXT DEFAULT 'inactive',
  documents_verified BOOLEAN DEFAULT false,
  current_location JSONB,
  total_rides INTEGER DEFAULT 0,
  earnings NUMERIC(10,2) DEFAULT 0,
  last_active TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Passengers table
CREATE TABLE public.passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Rides table
CREATE TABLE public.rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  status ride_status DEFAULT 'active',
  fare NUMERIC(10,2) DEFAULT 0,
  distance NUMERIC(8,2) DEFAULT 0,
  duration NUMERIC(8,2) DEFAULT 0,
  eta TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  rating NUMERIC(3,2)
);

-- Driver applications table
CREATE TABLE public.driver_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  license_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL,
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_year TEXT NOT NULL,
  vehicle_color TEXT NOT NULL,
  license_plate TEXT NOT NULL,
  insurance_number TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  documents JSONB DEFAULT '{}',
  notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Saved addresses table
CREATE TABLE public.saved_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude NUMERIC(10,8) NOT NULL,
  longitude NUMERIC(11,8) NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, label)
);

-- Payment methods table
CREATE TABLE public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type payment_method_type NOT NULL,
  card_last_four TEXT,
  card_brand TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, card_last_four)
);

-- Ride ratings table
CREATE TABLE public.ride_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  driver_id UUID NOT NULL REFERENCES drivers(id),
  user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
  driver_rating INTEGER CHECK (driver_rating >= 1 AND driver_rating <= 5),
  user_comment TEXT,
  driver_comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- App settings table
CREATE TABLE public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  base_fare NUMERIC(6,2) DEFAULT 0,
  per_km_rate NUMERIC(6,2) DEFAULT 0,
  per_minute_rate NUMERIC(6,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- CREATE INDEXES
-- =============================================

-- Profiles indexes
CREATE INDEX profiles_user_id_idx ON public.profiles(user_id);
CREATE INDEX profiles_email_idx ON public.profiles(email);

-- Drivers indexes
CREATE INDEX drivers_email_idx ON public.drivers(email);
CREATE INDEX drivers_status_idx ON public.drivers(status);
CREATE INDEX drivers_vehicle_type_idx ON public.drivers(vehicle_type);

-- Passengers indexes
CREATE INDEX passengers_user_id_idx ON public.passengers(user_id);
CREATE INDEX passengers_email_idx ON public.passengers(email);
CREATE INDEX passengers_status_idx ON public.passengers(status);

-- Rides indexes
CREATE INDEX rides_passenger_id_idx ON public.rides(passenger_id);
CREATE INDEX rides_driver_id_idx ON public.rides(driver_id);
CREATE INDEX rides_status_idx ON public.rides(status);

-- Ride ratings indexes
CREATE INDEX ride_ratings_ride_id_idx ON public.ride_ratings(ride_id);
CREATE INDEX ride_ratings_user_id_idx ON public.ride_ratings(user_id);
CREATE INDEX ride_ratings_driver_id_idx ON public.ride_ratings(driver_id);

-- Payment methods indexes
CREATE INDEX payment_methods_user_id_idx ON public.payment_methods(user_id);
CREATE INDEX payment_methods_is_default_idx ON public.payment_methods(is_default);
CREATE INDEX payment_methods_is_active_idx ON public.payment_methods(is_active);

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- =============================================
-- CREATE RLS POLICIES
-- =============================================

-- Profiles policies
CREATE POLICY "Users can view their own profile" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Drivers policies
CREATE POLICY "Authenticated users can view drivers" 
  ON public.drivers FOR SELECT 
  USING (auth.role() = 'authenticated');

CREATE POLICY "Drivers can view their own profile" 
  ON public.drivers FOR SELECT 
  USING (auth.email() = email);

CREATE POLICY "Drivers can update their own profile" 
  ON public.drivers FOR UPDATE 
  USING (auth.email() = email);

-- Passengers policies
CREATE POLICY "Authenticated users can view their own passenger record" 
  ON public.passengers FOR SELECT 
  USING (auth.email() = email);

CREATE POLICY "Authenticated users can update their own passenger record" 
  ON public.passengers FOR UPDATE 
  USING (auth.email() = email);

CREATE POLICY "Authenticated users can insert their own passenger record" 
  ON public.passengers FOR INSERT 
  WITH CHECK (auth.email() = email);

-- Rides policies
CREATE POLICY "Passengers can view their own rides" 
  ON public.rides FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM passengers 
    WHERE passengers.id = rides.passenger_id 
    AND passengers.email = auth.email()
  ));

CREATE POLICY "Passengers can insert rides" 
  ON public.rides FOR INSERT 
  WITH CHECK (EXISTS (
    SELECT 1 FROM passengers 
    WHERE passengers.id = rides.passenger_id 
    AND passengers.email = auth.email()
  ));

CREATE POLICY "Passengers can update their own rides" 
  ON public.rides FOR UPDATE 
  USING (EXISTS (
    SELECT 1 FROM passengers 
    WHERE passengers.id = rides.passenger_id 
    AND passengers.email = auth.email()
  ));

CREATE POLICY "Drivers can view and update assigned rides" 
  ON public.rides FOR ALL 
  USING (driver_id = (
    SELECT drivers.id FROM drivers 
    WHERE drivers.email = auth.email()
  ));

-- Driver applications policies
CREATE POLICY "Users can view their own applications" 
  ON public.driver_applications FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own applications" 
  ON public.driver_applications FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own applications" 
  ON public.driver_applications FOR UPDATE 
  USING (auth.uid() = user_id);

-- Saved addresses policies
CREATE POLICY "Users can manage their own addresses" 
  ON public.saved_addresses FOR ALL 
  USING (auth.uid() = user_id);

-- Payment methods policies
CREATE POLICY "Users can view their own payment methods" 
  ON public.payment_methods FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment methods" 
  ON public.payment_methods FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment methods" 
  ON public.payment_methods FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own payment methods" 
  ON public.payment_methods FOR DELETE 
  USING (auth.uid() = user_id);

-- Ride ratings policies
CREATE POLICY "Users can view their own ride ratings" 
  ON public.ride_ratings FOR SELECT 
  USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM rides 
    WHERE rides.id = ride_ratings.ride_id 
    AND rides.passenger_id = (
      SELECT passengers.id FROM passengers 
      WHERE passengers.email = auth.email()
    )
  ));

CREATE POLICY "Users can insert ride ratings" 
  ON public.ride_ratings FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ride ratings" 
  ON public.ride_ratings FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Drivers can view their own ride ratings" 
  ON public.ride_ratings FOR SELECT 
  USING (driver_id = (
    SELECT drivers.id FROM drivers 
    WHERE drivers.email = auth.email()
  ));

CREATE POLICY "Drivers can update their own ride ratings" 
  ON public.ride_ratings FOR UPDATE 
  USING (driver_id = (
    SELECT drivers.id FROM drivers 
    WHERE drivers.email = auth.email()
  ));

-- App settings policies
CREATE POLICY "Authenticated users can read app settings" 
  ON public.app_settings FOR SELECT 
  USING (auth.role() = 'authenticated');

-- =============================================
-- CREATE FUNCTIONS
-- =============================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'passenger')::user_type
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- CREATE TRIGGERS
-- =============================================

-- Trigger for automatic profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Triggers for updated_at timestamps
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at
  BEFORE UPDATE ON public.drivers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_saved_addresses_updated_at
  BEFORE UPDATE ON public.saved_addresses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at
  BEFORE UPDATE ON public.payment_methods
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_driver_applications_updated_at
  BEFORE UPDATE ON public.driver_applications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

-- Insert default app settings
INSERT INTO public.app_settings (base_fare, per_km_rate, per_minute_rate) 
VALUES (3.50, 1.20, 0.25);

-- Insert sample drivers
INSERT INTO public.drivers (
  name, email, phone, rating, vehicle_type, license_plate, 
  status, documents_verified, current_location, total_rides, earnings
) VALUES 
(
  'John Smith', 
  'john.driver@example.com', 
  '+1-555-0101', 
  4.8, 
  'economy', 
  'ABC123', 
  'active', 
  true, 
  '{"latitude": 37.7749, "longitude": -122.4194}',
  342,
  8567.25
),
(
  'Sarah Johnson', 
  'sarah.driver@example.com', 
  '+1-555-0102', 
  4.9, 
  'comfort', 
  'XYZ789', 
  'active', 
  true, 
  '{"latitude": 37.7849, "longitude": -122.4094}',
  156,
  4234.50
),
(
  'Mike Davis', 
  'mike.driver@example.com', 
  '+1-555-0103', 
  4.7, 
  'luxury', 
  'LUX456', 
  'active', 
  true, 
  '{"latitude": 37.7649, "longitude": -122.4294}',
  89,
  3456.75
);

-- Insert sample driver applications (for admin testing)
INSERT INTO public.driver_applications (
  user_id, email, full_name, phone, license_number, vehicle_type, 
  vehicle_year, vehicle_color, license_plate, insurance_number, status
) VALUES 
(
  gen_random_uuid(),
  'pending1@example.com',
  'Alex Rodriguez',
  '+1-555-0201',
  'DL123456789',
  'economy',
  '2021',
  'Blue',
  'PND001',
  'INS987654321',
  'pending'
),
(
  gen_random_uuid(),
  'pending2@example.com',
  'Maria Garcia',
  '+1-555-0202',
  'DL987654321',
  'comfort',
  '2022',
  'White',
  'PND002',
  'INS123456789',
  'pending'
),
(
  gen_random_uuid(),
  'pending3@example.com',
  'David Kim',
  '+1-555-0203',
  'DL456789123',
  'luxury',
  '2023',
  'Black',
  'PND003',
  'INS456789123',
  'under_review'
);