/*
  # Complete RideShare Database Schema

  1. New Tables
    - `profiles` - User profiles with type (passenger/driver/admin)
    - `drivers` - Driver-specific information and vehicle details
    - `passengers` - Passenger-specific information
    - `rides` - All ride requests and trips
    - `driver_applications` - Driver application submissions
    - `saved_addresses` - User's saved locations
    - `payment_methods` - User payment information
    - `ride_ratings` - Trip ratings and feedback
    - `app_settings` - Global app configuration

  2. Security
    - Enable RLS on all tables
    - Add comprehensive policies for each user type
    - Secure data isolation between users

  3. Features
    - Automatic profile creation on user signup
    - Updated timestamp triggers
    - Performance indexes
    - Data validation constraints
*/

-- Create custom types
CREATE TYPE user_type AS ENUM ('passenger', 'driver', 'admin');
CREATE TYPE ride_status AS ENUM ('requested', 'driver_assigned', 'driver_arriving', 'driver_arrived', 'in_progress', 'completed', 'cancelled');
CREATE TYPE driver_status AS ENUM ('inactive', 'active', 'busy', 'offline');
CREATE TYPE application_status AS ENUM ('pending', 'under_review', 'approved', 'rejected');
CREATE TYPE payment_type AS ENUM ('card', 'paypal', 'apple_pay', 'google_pay');

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  user_type user_type NOT NULL DEFAULT 'passenger',
  rating DECIMAL(2,1) DEFAULT 5.0 CHECK (rating >= 0 AND rating <= 5),
  total_trips INTEGER DEFAULT 0 CHECK (total_trips >= 0),
  driver_status TEXT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. DRIVERS TABLE
CREATE TABLE IF NOT EXISTS public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  rating DECIMAL(2,1) DEFAULT 5.0 CHECK (rating >= 0 AND rating <= 5),
  vehicle_type TEXT DEFAULT 'economy',
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_year TEXT,
  vehicle_color TEXT,
  license_plate TEXT,
  status driver_status DEFAULT 'inactive',
  documents_verified BOOLEAN DEFAULT false,
  current_location JSONB,
  total_rides INTEGER DEFAULT 0 CHECK (total_rides >= 0),
  earnings DECIMAL(10,2) DEFAULT 0.00 CHECK (earnings >= 0),
  last_active TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. PASSENGERS TABLE
CREATE TABLE IF NOT EXISTS public.passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. RIDES TABLE
CREATE TABLE IF NOT EXISTS public.rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID NOT NULL REFERENCES public.passengers(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  pickup_coordinates JSONB,
  dropoff_coordinates JSONB,
  status ride_status DEFAULT 'requested',
  fare DECIMAL(8,2) DEFAULT 0.00 CHECK (fare >= 0),
  distance DECIMAL(8,2) DEFAULT 0.00 CHECK (distance >= 0),
  duration INTEGER DEFAULT 0 CHECK (duration >= 0),
  eta TEXT,
  ride_type TEXT DEFAULT 'economy',
  passengers_count INTEGER DEFAULT 1 CHECK (passengers_count > 0),
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- 5. DRIVER APPLICATIONS TABLE
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
  insurance_number TEXT,
  status application_status DEFAULT 'pending',
  documents JSONB DEFAULT '{"license_uploaded": false, "insurance_uploaded": false, "vehicle_registration_uploaded": false}',
  notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. SAVED ADDRESSES TABLE
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

-- 7. PAYMENT METHODS TABLE
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type payment_type NOT NULL,
  stripe_payment_method_id TEXT,
  stripe_customer_id TEXT,
  card_last_four TEXT,
  card_brand TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 8. RIDE RATINGS TABLE
CREATE TABLE IF NOT EXISTS public.ride_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
  user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
  driver_rating INTEGER CHECK (driver_rating >= 1 AND driver_rating <= 5),
  user_comment TEXT,
  driver_comment TEXT,
  tips JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. APP SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  base_fare DECIMAL(6,2) DEFAULT 3.50 CHECK (base_fare >= 0),
  per_km_rate DECIMAL(6,2) DEFAULT 1.20 CHECK (per_km_rate >= 0),
  per_minute_rate DECIMAL(6,2) DEFAULT 0.25 CHECK (per_minute_rate >= 0),
  surge_multiplier DECIMAL(3,2) DEFAULT 1.00 CHECK (surge_multiplier >= 1.00),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- CREATE INDEXES FOR PERFORMANCE
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

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Allow profile inserts" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- DRIVERS POLICIES
CREATE POLICY "Drivers can view their own data" ON public.drivers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Drivers can update their own data" ON public.drivers
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Allow driver inserts" ON public.drivers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Passengers can view active drivers" ON public.drivers
  FOR SELECT USING (status = 'active' AND documents_verified = true);

-- PASSENGERS POLICIES
CREATE POLICY "Passengers can view their own data" ON public.passengers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Passengers can update their own data" ON public.passengers
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Allow passenger inserts" ON public.passengers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RIDES POLICIES
CREATE POLICY "Users can view their own rides" ON public.rides
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM public.drivers WHERE drivers.id = rides.driver_id AND drivers.user_id = auth.uid())
  );

CREATE POLICY "Passengers can create rides" ON public.rides
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid())
  );

CREATE POLICY "Users can update their rides" ON public.rides
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.passengers WHERE passengers.id = rides.passenger_id AND passengers.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM public.drivers WHERE drivers.id = rides.driver_id AND drivers.user_id = auth.uid())
  );

-- DRIVER APPLICATIONS POLICIES
CREATE POLICY "Users can view their own applications" ON public.driver_applications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create applications" ON public.driver_applications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own applications" ON public.driver_applications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all applications" ON public.driver_applications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.user_id = auth.uid() AND profiles.user_type = 'admin')
  );

-- SAVED ADDRESSES POLICIES
CREATE POLICY "Users can manage their own addresses" ON public.saved_addresses
  FOR ALL USING (auth.uid() = user_id);

-- PAYMENT METHODS POLICIES
CREATE POLICY "Users can manage their own payment methods" ON public.payment_methods
  FOR ALL USING (auth.uid() = user_id);

-- RIDE RATINGS POLICIES
CREATE POLICY "Users can view ratings for their rides" ON public.ride_ratings
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() IN (
    SELECT drivers.user_id FROM public.drivers WHERE drivers.id = ride_ratings.driver_id
  ));

CREATE POLICY "Users can create ratings" ON public.ride_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- APP SETTINGS POLICIES
CREATE POLICY "Everyone can view app settings" ON public.app_settings
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only admins can modify app settings" ON public.app_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.user_id = auth.uid() AND profiles.user_type = 'admin')
  );

-- FUNCTIONS AND TRIGGERS

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE((NEW.raw_user_meta_data->>'user_type')::user_type, 'passenger')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for automatic profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON public.drivers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_driver_applications_updated_at BEFORE UPDATE ON public.driver_applications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_saved_addresses_updated_at BEFORE UPDATE ON public.saved_addresses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON public.payment_methods
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON public.app_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- INSERT DEFAULT APP SETTINGS
INSERT INTO public.app_settings (base_fare, per_km_rate, per_minute_rate, surge_multiplier)
VALUES (3.50, 1.20, 0.25, 1.00)
ON CONFLICT DO NOTHING;

-- Function to ensure passenger exists
CREATE OR REPLACE FUNCTION public.ensure_passenger_exists(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
  passenger_id UUID;
  user_email TEXT;
  user_name TEXT;
BEGIN
  -- Get user info
  SELECT email, COALESCE(raw_user_meta_data->>'full_name', email) 
  INTO user_email, user_name
  FROM auth.users 
  WHERE id = p_user_id;
  
  -- Insert or get passenger
  INSERT INTO public.passengers (user_id, name, email, phone)
  VALUES (p_user_id, user_name, user_email, '')
  ON CONFLICT (user_id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email
  RETURNING id INTO passenger_id;
  
  RETURN passenger_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to ensure driver exists
CREATE OR REPLACE FUNCTION public.ensure_driver_exists(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
  driver_id UUID;
  user_email TEXT;
  user_name TEXT;
BEGIN
  -- Get user info
  SELECT email, COALESCE(raw_user_meta_data->>'full_name', email) 
  INTO user_email, user_name
  FROM auth.users 
  WHERE id = p_user_id;
  
  -- Insert or get driver
  INSERT INTO public.drivers (user_id, name, email, phone)
  VALUES (p_user_id, user_name, user_email, '')
  ON CONFLICT (user_id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email
  RETURNING id INTO driver_id;
  
  RETURN driver_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;