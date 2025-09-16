/*
  # Add Test Driver Account

  1. New Data
    - Create test driver user in auth.users
    - Create corresponding profile in profiles table
    - Create driver record in drivers table
    - Add some sample ride history

  2. Test Account Details
    - Email: driver@test.com
    - Password: password123
    - User Type: driver
    - Vehicle: 2022 Silver Toyota Camry
    - License Plate: DRV 123
    - Status: Active and verified

  3. Sample Data
    - Driver profile with good rating
    - Vehicle information
    - Some completed trips for demo
*/

-- Insert test driver user into auth.users (this would normally be done through Supabase Auth)
-- Note: In production, users are created through the auth API, not directly in the database
-- This is for testing purposes only

-- First, let's create a profile for the test driver
INSERT INTO public.profiles (
  id,
  user_id,
  email,
  full_name,
  phone,
  user_type,
  rating,
  total_trips,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid, -- Mock user ID for test driver
  'driver@test.com',
  'John Smith',
  '+1 (555) 123-4567',
  'driver',
  4.8,
  342,
  now(),
  now()
) ON CONFLICT (user_id) DO NOTHING;

-- Create driver record
INSERT INTO public.drivers (
  id,
  user_id,
  name,
  email,
  phone,
  rating,
  vehicle_type,
  vehicle_make,
  vehicle_model,
  vehicle_year,
  vehicle_color,
  license_plate,
  status,
  documents_verified,
  current_location,
  total_rides,
  earnings,
  last_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'John Smith',
  'driver@test.com',
  '+1 (555) 123-4567',
  4.8,
  'economy',
  'Toyota',
  'Camry',
  '2022',
  'Silver',
  'DRV 123',
  'active',
  true,
  '{"latitude": 37.7749, "longitude": -122.4194}'::jsonb,
  342,
  8567.25,
  now(),
  now() - interval '1 year',
  now()
) ON CONFLICT (user_id) DO NOTHING;

-- Create passenger record for the same user (drivers can also be passengers)
INSERT INTO public.passengers (
  id,
  user_id,
  name,
  email,
  phone,
  status,
  created_at
) VALUES (
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'John Smith',
  'driver@test.com',
  '+1 (555) 123-4567',
  'active',
  now() - interval '1 year'
) ON CONFLICT (user_id) DO NOTHING;

-- Add some sample completed rides for this driver
DO $$
DECLARE
  driver_id uuid;
  passenger_id uuid;
  ride_id uuid;
BEGIN
  -- Get the driver ID
  SELECT id INTO driver_id FROM public.drivers WHERE email = 'driver@test.com';
  
  -- Get a passenger ID (we'll use the test passenger if it exists)
  SELECT id INTO passenger_id FROM public.passengers WHERE email = 'test@passenger.com';
  
  -- If no test passenger exists, use the driver as passenger for some rides
  IF passenger_id IS NULL THEN
    SELECT id INTO passenger_id FROM public.passengers WHERE email = 'driver@test.com';
  END IF;
  
  -- Create sample rides if we have both driver and passenger
  IF driver_id IS NOT NULL AND passenger_id IS NOT NULL THEN
    -- Ride 1: Completed ride from yesterday
    INSERT INTO public.rides (
      id,
      passenger_id,
      driver_id,
      pickup_location,
      dropoff_location,
      pickup_coordinates,
      dropoff_coordinates,
      status,
      fare,
      distance,
      duration,
      ride_type,
      passengers_count,
      created_at,
      completed_at
    ) VALUES (
      gen_random_uuid(),
      passenger_id,
      driver_id,
      'Downtown San Francisco',
      'San Francisco Airport',
      '{"latitude": 37.7749, "longitude": -122.4194}'::jsonb,
      '{"latitude": 37.6213, "longitude": -122.3790}'::jsonb,
      'completed',
      45.50,
      24.8,
      35,
      'economy',
      1,
      now() - interval '1 day',
      now() - interval '1 day' + interval '35 minutes'
    );
    
    -- Ride 2: Completed ride from this morning
    INSERT INTO public.rides (
      id,
      passenger_id,
      driver_id,
      pickup_location,
      dropoff_location,
      pickup_coordinates,
      dropoff_coordinates,
      status,
      fare,
      distance,
      duration,
      ride_type,
      passengers_count,
      created_at,
      completed_at
    ) VALUES (
      gen_random_uuid(),
      passenger_id,
      driver_id,
      'Union Square',
      'Golden Gate Bridge',
      '{"latitude": 37.7880, "longitude": -122.4075}'::jsonb,
      '{"latitude": 37.8199, "longitude": -122.4783}'::jsonb,
      'completed',
      28.75,
      12.3,
      22,
      'comfort',
      2,
      now() - interval '4 hours',
      now() - interval '4 hours' + interval '22 minutes'
    );
    
    -- Ride 3: Recent completed ride
    INSERT INTO public.rides (
      id,
      passenger_id,
      driver_id,
      pickup_location,
      dropoff_location,
      pickup_coordinates,
      dropoff_coordinates,
      status,
      fare,
      distance,
      duration,
      ride_type,
      passengers_count,
      created_at,
      completed_at
    ) VALUES (
      gen_random_uuid(),
      passenger_id,
      driver_id,
      'Financial District',
      'Mission District',
      '{"latitude": 37.7946, "longitude": -122.3999}'::jsonb,
      '{"latitude": 37.7599, "longitude": -122.4148}'::jsonb,
      'completed',
      18.25,
      8.7,
      16,
      'economy',
      1,
      now() - interval '2 hours',
      now() - interval '2 hours' + interval '16 minutes'
    );
  END IF;
END $$;

-- Create approved driver application for this test driver
INSERT INTO public.driver_applications (
  id,
  user_id,
  email,
  full_name,
  phone,
  license_number,
  vehicle_type,
  vehicle_make,
  vehicle_model,
  vehicle_year,
  vehicle_color,
  license_plate,
  insurance_number,
  status,
  documents,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'driver@test.com',
  'John Smith',
  '+1 (555) 123-4567',
  'DL123456789',
  'economy',
  'Toyota',
  'Camry',
  '2022',
  'Silver',
  'DRV 123',
  'INS987654321',
  'approved',
  '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": true}'::jsonb,
  'Application approved. All documents verified. Welcome to the RideShare driver network!',
  '550e8400-e29b-41d4-a716-446655440000'::uuid, -- Mock admin user ID
  now() - interval '6 months',
  now() - interval '1 year',
  now() - interval '6 months'
) ON CONFLICT (user_id) DO NOTHING;

-- Add some payment methods for the driver
INSERT INTO public.payment_methods (
  id,
  user_id,
  type,
  card_last_four,
  card_brand,
  is_default,
  is_active,
  created_at,
  updated_at
) VALUES 
(
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'card',
  '1234',
  'Visa',
  true,
  true,
  now() - interval '6 months',
  now()
),
(
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'card',
  '5678',
  'Mastercard',
  false,
  true,
  now() - interval '3 months',
  now()
) ON CONFLICT DO NOTHING;

-- Add saved addresses for the driver
INSERT INTO public.saved_addresses (
  id,
  user_id,
  label,
  address,
  latitude,
  longitude,
  is_default,
  created_at,
  updated_at
) VALUES 
(
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'Home',
  '789 Driver Lane, San Francisco, CA',
  37.7849,
  -122.4094,
  true,
  now() - interval '1 year',
  now()
),
(
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'Garage',
  '321 Parking St, San Francisco, CA',
  37.7649,
  -122.4294,
  false,
  now() - interval '8 months',
  now()
) ON CONFLICT DO NOTHING;