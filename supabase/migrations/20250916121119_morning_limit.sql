/*
  # RideShare App - Complete Database Schema

  1. New Tables
    - `profiles` - User profiles with type system (passenger/driver/admin)
    - `drivers` - Driver information with vehicle details and earnings
    - `passengers` - Passenger records linked to auth users
    - `rides` - Trip management with status tracking
    - `driver_applications` - Driver application workflow
    - `saved_addresses` - User saved locations
    - `payment_methods` - Payment card management
    - `ride_ratings` - Trip feedback and rating system
    - `app_settings` - Configurable app settings (fares, rates)

  2. Security
    - Enable RLS on all tables
    - Comprehensive access policies for each user type
    - Secure data isolation between users

  3. Features
    - Automatic profile creation on user signup
    - Updated timestamp triggers
    - Sample data for testing
    - Proper foreign key relationships
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user type enum
CREATE TYPE user_type AS ENUM ('passenger', 'driver', 'admin');

-- Create ride status enum
CREATE TYPE ride_status AS ENUM ('active', 'completed', 'cancelled');

-- Create application status enum
CREATE TYPE application_status AS ENUM ('pending', 'under_review', 'approved', 'rejected');

-- Create payment method type enum
CREATE TYPE payment_method_type AS ENUM ('card', 'paypal', 'apple_pay', 'google_pay');

-- =============================================
-- PROFILES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  phone text,
  avatar_url text,
  user_type user_type NOT NULL DEFAULT 'passenger',
  rating decimal(2,1) DEFAULT 5.0,
  total_trips integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- DRIVERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS drivers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  rating decimal(2,1) DEFAULT 5.0,
  vehicle_type text DEFAULT 'economy',
  license_plate text,
  status text DEFAULT 'inactive',
  documents_verified boolean DEFAULT false,
  current_location jsonb,
  total_rides integer DEFAULT 0,
  earnings decimal(10,2) DEFAULT 0.00,
  last_active timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- PASSENGERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS passengers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

-- =============================================
-- RIDES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS rides (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  passenger_id uuid NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  pickup_location text NOT NULL,
  dropoff_location text NOT NULL,
  status ride_status DEFAULT 'active',
  fare decimal(8,2) DEFAULT 0.00,
  distance decimal(8,2) DEFAULT 0.00,
  duration integer DEFAULT 0,
  eta text,
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

-- =============================================
-- DRIVER APPLICATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS driver_applications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  phone text NOT NULL,
  license_number text NOT NULL,
  vehicle_type text NOT NULL,
  vehicle_make text,
  vehicle_model text,
  vehicle_year text NOT NULL,
  vehicle_color text NOT NULL,
  license_plate text NOT NULL,
  insurance_number text NOT NULL,
  status application_status DEFAULT 'pending',
  documents jsonb DEFAULT '{"license_uploaded": false, "insurance_uploaded": false, "vehicle_registration_uploaded": false}',
  notes text,
  reviewed_by uuid REFERENCES auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- SAVED ADDRESSES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS saved_addresses (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label text NOT NULL,
  address text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  is_default boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- PAYMENT METHODS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS payment_methods (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type payment_method_type NOT NULL,
  card_last_four text,
  card_brand text,
  is_default boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- RIDE RATINGS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS ride_ratings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id uuid UNIQUE NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  driver_id uuid NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  user_rating integer CHECK (user_rating >= 1 AND user_rating <= 5),
  driver_rating integer CHECK (driver_rating >= 1 AND driver_rating <= 5),
  user_comment text,
  driver_comment text,
  created_at timestamptz DEFAULT now()
);

-- =============================================
-- APP SETTINGS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS app_settings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  base_fare decimal(6,2) DEFAULT 3.50,
  per_km_rate decimal(6,2) DEFAULT 1.20,
  per_minute_rate decimal(6,2) DEFAULT 0.25,
  created_at timestamptz DEFAULT now()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS profiles_user_id_idx ON profiles(user_id);
CREATE INDEX IF NOT EXISTS profiles_user_type_idx ON profiles(user_type);
CREATE INDEX IF NOT EXISTS drivers_status_idx ON drivers(status);
CREATE INDEX IF NOT EXISTS drivers_email_idx ON drivers(email);
CREATE INDEX IF NOT EXISTS passengers_user_id_idx ON passengers(user_id);
CREATE INDEX IF NOT EXISTS rides_passenger_id_idx ON rides(passenger_id);
CREATE INDEX IF NOT EXISTS rides_driver_id_idx ON rides(driver_id);
CREATE INDEX IF NOT EXISTS rides_status_idx ON rides(status);
CREATE INDEX IF NOT EXISTS saved_addresses_user_id_idx ON saved_addresses(user_id);
CREATE INDEX IF NOT EXISTS payment_methods_user_id_idx ON payment_methods(user_id);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- =============================================
-- PROFILES POLICIES
-- =============================================
CREATE POLICY "Users can view their own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Allow profile inserts" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- =============================================
-- DRIVERS POLICIES
-- =============================================
CREATE POLICY "Drivers can view their own data" 
  ON drivers FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Drivers can update their own data" 
  ON drivers FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Allow driver inserts" 
  ON drivers FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Passengers can view active drivers" 
  ON drivers FOR SELECT 
  USING (status = 'active' AND documents_verified = true);

-- =============================================
-- PASSENGERS POLICIES
-- =============================================
CREATE POLICY "Passengers can view their own data" 
  ON passengers FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Passengers can update their own data" 
  ON passengers FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Allow passenger inserts" 
  ON passengers FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- =============================================
-- RIDES POLICIES
-- =============================================
CREATE POLICY "Users can view their own rides" 
  ON rides FOR SELECT 
  USING (
    EXISTS (SELECT 1 FROM passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM drivers WHERE drivers.id = rides.driver_id AND drivers.user_id = auth.uid())
  );

CREATE POLICY "Passengers can create rides" 
  ON rides FOR INSERT 
  WITH CHECK (
    EXISTS (SELECT 1 FROM passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid())
  );

CREATE POLICY "Drivers can update assigned rides" 
  ON rides FOR UPDATE 
  USING (
    EXISTS (SELECT 1 FROM drivers WHERE drivers.id = rides.driver_id AND drivers.user_id = auth.uid())
  );

-- =============================================
-- DRIVER APPLICATIONS POLICIES
-- =============================================
CREATE POLICY "Users can view their own applications" 
  ON driver_applications FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create applications" 
  ON driver_applications FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own applications" 
  ON driver_applications FOR UPDATE 
  USING (auth.uid() = user_id);

-- =============================================
-- SAVED ADDRESSES POLICIES
-- =============================================
CREATE POLICY "Users can manage their own addresses" 
  ON saved_addresses FOR ALL 
  USING (auth.uid() = user_id);

-- =============================================
-- PAYMENT METHODS POLICIES
-- =============================================
CREATE POLICY "Users can manage their own payment methods" 
  ON payment_methods FOR ALL 
  USING (auth.uid() = user_id);

-- =============================================
-- RIDE RATINGS POLICIES
-- =============================================
CREATE POLICY "Users can view ratings for their rides" 
  ON ride_ratings FOR SELECT 
  USING (auth.uid() = user_id OR auth.uid() = driver_id);

CREATE POLICY "Users can create ratings for their rides" 
  ON ride_ratings FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- =============================================
-- APP SETTINGS POLICIES
-- =============================================
CREATE POLICY "Everyone can view app settings" 
  ON app_settings FOR SELECT 
  TO authenticated 
  USING (true);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (user_id, email, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE((NEW.raw_user_meta_data->>'user_type')::user_type, 'passenger')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Triggers for updated_at columns
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_applications_updated_at
  BEFORE UPDATE ON driver_applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saved_addresses_updated_at
  BEFORE UPDATE ON saved_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at
  BEFORE UPDATE ON payment_methods
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Insert default app settings
INSERT INTO app_settings (base_fare, per_km_rate, per_minute_rate) 
VALUES (3.50, 1.20, 0.25)
ON CONFLICT DO NOTHING;

-- Insert sample drivers (for testing)
INSERT INTO drivers (
  id, name, email, phone, rating, vehicle_type, license_plate, 
  status, documents_verified, current_location, total_rides, earnings
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001',
  'John Smith',
  'john.driver@example.com',
  '+1-555-0101',
  4.9,
  'economy',
  'ABC 123',
  'active',
  true,
  '{"latitude": 37.7749, "longitude": -122.4194}',
  342,
  8567.25
),
(
  '550e8400-e29b-41d4-a716-446655440002',
  'Sarah Johnson',
  'sarah.driver@example.com',
  '+1-555-0102',
  4.8,
  'comfort',
  'XYZ 789',
  'active',
  true,
  '{"latitude": 37.7849, "longitude": -122.4094}',
  256,
  6234.80
),
(
  '550e8400-e29b-41d4-a716-446655440003',
  'Mike Davis',
  'mike.driver@example.com',
  '+1-555-0103',
  4.7,
  'luxury',
  'LUX 456',
  'active',
  true,
  '{"latitude": 37.7649, "longitude": -122.4294}',
  189,
  4892.15
)
ON CONFLICT (email) DO NOTHING;

-- Insert sample driver applications (for admin testing)
INSERT INTO driver_applications (
  user_id, email, full_name, phone, license_number, vehicle_type,
  vehicle_make, vehicle_model, vehicle_year, vehicle_color, license_plate,
  insurance_number, status
) VALUES 
(
  uuid_generate_v4(),
  'pending1@example.com',
  'Alex Wilson',
  '+1-555-0201',
  'DL123456789',
  'economy',
  'Honda',
  'Civic',
  '2021',
  'Blue',
  'PND 001',
  'INS123456789',
  'pending'
),
(
  uuid_generate_v4(),
  'pending2@example.com',
  'Maria Garcia',
  '+1-555-0202',
  'DL987654321',
  'comfort',
  'Toyota',
  'Prius',
  '2022',
  'White',
  'PND 002',
  'INS987654321',
  'pending'
),
(
  uuid_generate_v4(),
  'pending3@example.com',
  'David Chen',
  '+1-555-0203',
  'DL456789123',
  'luxury',
  'BMW',
  '3 Series',
  '2023',
  'Black',
  'PND 003',
  'INS456789123',
  'under_review'
)
ON CONFLICT DO NOTHING;