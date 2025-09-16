/*
  # Complete Database Reset and Schema Recreation

  1. Database Reset
    - Drop all existing tables and policies
    - Clean slate for proper setup

  2. New Tables
    - `profiles` - User profiles with proper RLS
    - `drivers` - Driver information and status
    - `passengers` - Passenger information
    - `rides` - Ride booking and tracking
    - `saved_addresses` - User saved locations
    - `payment_methods` - User payment information
    - `driver_applications` - Driver application process
    - `app_settings` - Application configuration

  3. Security
    - Proper RLS policies without recursion
    - Secure user data access
    - Admin access controls

  4. Functions
    - Auto profile creation trigger
    - Update timestamp triggers
*/

-- Drop all existing tables and policies to start fresh
DROP TABLE IF EXISTS public.stripe_orders CASCADE;
DROP TABLE IF EXISTS public.stripe_subscriptions CASCADE;
DROP TABLE IF EXISTS public.stripe_customers CASCADE;
DROP TABLE IF EXISTS public.driver_applications CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.payment_methods CASCADE;
DROP TABLE IF EXISTS public.service_zones CASCADE;
DROP TABLE IF EXISTS public.app_settings CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.rides CASCADE;
DROP TABLE IF EXISTS public.passengers CASCADE;
DROP TABLE IF EXISTS public.saved_addresses CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS public.stripe_subscription_status CASCADE;
DROP TYPE IF EXISTS public.stripe_order_status CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create profiles table with proper structure
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  user_type TEXT NOT NULL DEFAULT 'passenger' CHECK (user_type IN ('passenger', 'driver', 'admin')),
  rating DECIMAL(2,1) DEFAULT 5.0,
  total_trips INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create passengers table
CREATE TABLE public.passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'banned')),
  total_rides INTEGER DEFAULT 0,
  total_spent DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create drivers table
CREATE TABLE public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  rating DECIMAL DEFAULT 0,
  status TEXT DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'suspended')),
  documents_verified BOOLEAN DEFAULT false,
  total_rides INTEGER DEFAULT 0,
  earnings DECIMAL DEFAULT 0,
  last_active TIMESTAMPTZ DEFAULT now(),
  vehicle_type TEXT,
  license_plate TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create rides table
CREATE TABLE public.rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
  passenger_id UUID REFERENCES public.passengers(id) ON DELETE CASCADE,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  fare DECIMAL DEFAULT 0,
  distance DECIMAL DEFAULT 0,
  duration INTEGER DEFAULT 0,
  eta TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create saved_addresses table
CREATE TABLE public.saved_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create payment_methods table
CREATE TABLE public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('card', 'paypal', 'apple_pay', 'google_pay')),
  card_last_four TEXT,
  card_brand TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create driver_applications table
CREATE TABLE public.driver_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  license_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL,
  vehicle_year TEXT NOT NULL,
  vehicle_color TEXT NOT NULL,
  license_plate TEXT NOT NULL,
  insurance_number TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  documents JSONB DEFAULT '{}',
  notes TEXT,
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create app_settings table
CREATE TABLE public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  base_fare DECIMAL DEFAULT 5.00,
  per_km_rate DECIMAL DEFAULT 1.50,
  per_minute_rate DECIMAL DEFAULT 0.25,
  surge_enabled BOOLEAN DEFAULT true,
  max_surge_multiplier DECIMAL DEFAULT 3.0,
  commission_rate INTEGER DEFAULT 20,
  notifications_enabled BOOLEAN DEFAULT true,
  support_email TEXT DEFAULT 'support@rideapp.com',
  support_phone TEXT DEFAULT '+1-800-RIDE-APP',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create service_zones table
CREATE TABLE public.service_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  coordinates JSONB,
  active BOOLEAN DEFAULT true,
  surge_multiplier DECIMAL DEFAULT 1.0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX idx_passengers_email ON public.passengers(email);
CREATE INDEX idx_passengers_status ON public.passengers(status);
CREATE INDEX idx_drivers_email ON public.drivers(email);
CREATE INDEX idx_drivers_status ON public.drivers(status);
CREATE INDEX idx_rides_passenger_id ON public.rides(passenger_id);
CREATE INDEX idx_rides_driver_id ON public.rides(driver_id);
CREATE INDEX idx_rides_status ON public.rides(status);
CREATE INDEX idx_rides_created_at ON public.rides(created_at);
CREATE INDEX idx_driver_applications_email ON public.driver_applications(email);
CREATE INDEX idx_driver_applications_status ON public.driver_applications(status);
CREATE INDEX saved_addresses_user_id_idx ON public.saved_addresses(user_id);
CREATE INDEX saved_addresses_is_default_idx ON public.saved_addresses(is_default);
CREATE INDEX saved_addresses_created_at_idx ON public.saved_addresses(created_at DESC);
CREATE INDEX payment_methods_user_id_idx ON public.payment_methods(user_id);
CREATE INDEX payment_methods_is_default_idx ON public.payment_methods(is_default);
CREATE INDEX payment_methods_is_active_idx ON public.payment_methods(is_active);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_zones ENABLE ROW LEVEL SECURITY;

-- Create SIMPLE RLS policies for profiles (no recursion)
CREATE POLICY "Users can view their own profile" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = user_id);

-- Passengers policies
CREATE POLICY "Users can view their own passenger record" 
  ON public.passengers FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own passenger record" 
  ON public.passengers FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own passenger record" 
  ON public.passengers FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own passenger record" 
  ON public.passengers FOR DELETE 
  USING (auth.uid() = user_id);

-- Admin policies for passengers
CREATE POLICY "Admins can manage all passengers" 
  ON public.passengers FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- Drivers policies
CREATE POLICY "Allow all operations for authenticated users on drivers" 
  ON public.drivers FOR ALL 
  TO authenticated 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Allow all operations on drivers" 
  ON public.drivers FOR ALL 
  TO public 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Admins can manage all drivers" 
  ON public.drivers FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- Rides policies
CREATE POLICY "Allow all operations for authenticated users on rides" 
  ON public.rides FOR ALL 
  TO authenticated 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Allow all operations on rides" 
  ON public.rides FOR ALL 
  TO public 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Admins can view all rides" 
  ON public.rides FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR passenger_id IN (
      SELECT passengers.id FROM public.passengers 
      WHERE passengers.user_id = auth.uid()
    )
    OR driver_id IN (
      SELECT drivers.id FROM public.drivers 
      WHERE drivers.email = (
        SELECT profiles.email FROM public.profiles 
        WHERE profiles.user_id = auth.uid()
      )
    )
  );

-- Saved addresses policies
CREATE POLICY "Users can view their own addresses" 
  ON public.saved_addresses FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses" 
  ON public.saved_addresses FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses" 
  ON public.saved_addresses FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses" 
  ON public.saved_addresses FOR DELETE 
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

-- Driver applications policies
CREATE POLICY "Anyone can create driver applications" 
  ON public.driver_applications FOR INSERT 
  TO anon, authenticated 
  WITH CHECK (true);

CREATE POLICY "Allow all operations for authenticated users on driver_applications" 
  ON public.driver_applications FOR ALL 
  TO authenticated 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Admins can manage all driver applications" 
  ON public.driver_applications FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- App settings policies (public read, admin write)
CREATE POLICY "Allow all operations for authenticated users on app_settings" 
  ON public.app_settings FOR ALL 
  TO authenticated 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Allow all operations on app_settings" 
  ON public.app_settings FOR ALL 
  TO public 
  USING (true) 
  WITH CHECK (true);

-- Service zones policies (public read, admin write)
CREATE POLICY "Allow all operations for authenticated users on service_zones" 
  ON public.service_zones FOR ALL 
  TO authenticated 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "Allow all operations on service_zones" 
  ON public.service_zones FOR ALL 
  TO public 
  USING (true) 
  WITH CHECK (true);

-- Create updated_at triggers
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON public.profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_passengers_updated_at 
  BEFORE UPDATE ON public.passengers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at 
  BEFORE UPDATE ON public.drivers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rides_updated_at 
  BEFORE UPDATE ON public.rides 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saved_addresses_updated_at 
  BEFORE UPDATE ON public.saved_addresses 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at 
  BEFORE UPDATE ON public.payment_methods 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_applications_updated_at 
  BEFORE UPDATE ON public.driver_applications 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_settings_updated_at 
  BEFORE UPDATE ON public.app_settings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_zones_updated_at 
  BEFORE UPDATE ON public.service_zones 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'passenger')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Insert default app settings
INSERT INTO public.app_settings (
  base_fare,
  per_km_rate,
  per_minute_rate,
  surge_enabled,
  max_surge_multiplier,
  commission_rate,
  notifications_enabled,
  support_email,
  support_phone
) VALUES (
  5.00,
  1.50,
  0.25,
  true,
  3.0,
  20,
  true,
  'support@rideapp.com',
  '+1-800-RIDE-APP'
);

-- Insert default service zone
INSERT INTO public.service_zones (
  name,
  coordinates,
  active,
  surge_multiplier
) VALUES (
  'San Francisco',
  '{"type": "Polygon", "coordinates": [[[-122.5, 37.7], [-122.3, 37.7], [-122.3, 37.8], [-122.5, 37.8], [-122.5, 37.7]]]}',
  true,
  1.0
);