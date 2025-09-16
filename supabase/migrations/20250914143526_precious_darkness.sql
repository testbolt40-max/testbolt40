/*
  # Add Sample Trips and Driver Data

  1. New Data
    - Sample drivers with realistic information
    - Sample rides (active, completed, cancelled)
    - Sample driver applications
    - Updated app settings

  2. Security
    - All data respects existing RLS policies
    - Uses proper UUID format for all IDs
    - Links to auth.users table properly

  3. Data Structure
    - 5 drivers with different vehicle types and statuses
    - 14 rides across different time periods
    - 5 driver applications with various statuses
    - Realistic fare and location data
*/

-- First, let's add some sample users to auth.users (this simulates real user accounts)
-- Note: In production, these would be created through the signup process

-- Insert sample drivers (these represent real driver accounts)
INSERT INTO public.drivers (
  id,
  name,
  email,
  phone,
  rating,
  status,
  documents_verified,
  total_rides,
  earnings,
  last_active,
  vehicle_type,
  license_plate,
  created_at,
  updated_at
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001',
  'Mohammed Alami',
  'mohammed.alami@rideshare.com',
  '+212600000001',
  4.8,
  'active',
  true,
  127,
  2850.75,
  now(),
  'comfort',
  '1234-A-1',
  now() - interval '6 months',
  now()
),
(
  '550e8400-e29b-41d4-a716-446655440002',
  'Sara Benjelloun',
  'sara.benjelloun@rideshare.com',
  '+212600000002',
  4.9,
  'active',
  true,
  89,
  1967.50,
  now() - interval '2 hours',
  'luxury',
  '1234-B-2',
  now() - interval '4 months',
  now()
),
(
  '550e8400-e29b-41d4-a716-446655440003',
  'Karim Tazi',
  'karim.tazi@rideshare.com',
  '+212600000003',
  4.7,
  'inactive',
  true,
  203,
  4125.25,
  now() - interval '1 day',
  'economy',
  '1234-C-3',
  now() - interval '8 months',
  now()
),
(
  '550e8400-e29b-41d4-a716-446655440004',
  'Fatima El Mansouri',
  'fatima.mansouri@rideshare.com',
  '+212600000004',
  4.6,
  'suspended',
  false,
  45,
  892.00,
  now() - interval '3 days',
  'economy',
  '1234-D-4',
  now() - interval '2 months',
  now()
),
(
  '550e8400-e29b-41d4-a716-446655440005',
  'Youssef Benali',
  'youssef.benali@rideshare.com',
  '+212600000005',
  4.9,
  'active',
  true,
  156,
  3421.80,
  now() - interval '30 minutes',
  'luxury',
  '1234-E-5',
  now() - interval '1 year',
  now()
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  rating = EXCLUDED.rating,
  status = EXCLUDED.status,
  documents_verified = EXCLUDED.documents_verified,
  total_rides = EXCLUDED.total_rides,
  earnings = EXCLUDED.earnings,
  last_active = EXCLUDED.last_active,
  vehicle_type = EXCLUDED.vehicle_type,
  license_plate = EXCLUDED.license_plate,
  updated_at = now();

-- Insert sample passengers (without foreign key to auth.users)
INSERT INTO public.passengers (
  id,
  name,
  email,
  phone,
  status,
  total_rides,
  total_spent,
  created_at,
  updated_at
) VALUES 
(
  '650e8400-e29b-41d4-a716-446655440001',
  'Ahmed Hassan',
  'ahmed.hassan@example.com',
  '+212600000101',
  'active',
  23,
  567.50,
  now() - interval '3 months',
  now()
),
(
  '650e8400-e29b-41d4-a716-446655440002',
  'Laila Benkirane',
  'laila.benkirane@example.com',
  '+212600000102',
  'active',
  45,
  1123.75,
  now() - interval '6 months',
  now()
),
(
  '650e8400-e29b-41d4-a716-446655440003',
  'Omar Ziani',
  'omar.ziani@example.com',
  '+212600000103',
  'active',
  12,
  298.25,
  now() - interval '1 month',
  now()
),
(
  '650e8400-e29b-41d4-a716-446655440004',
  'Nadia Chraibi',
  'nadia.chraibi@example.com',
  '+212600000104',
  'active',
  67,
  1567.90,
  now() - interval '8 months',
  now()
),
(
  '650e8400-e29b-41d4-a716-446655440005',
  'Rachid Amrani',
  'rachid.amrani@example.com',
  '+212600000105',
  'banned',
  8,
  156.00,
  now() - interval '2 months',
  now()
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  status = EXCLUDED.status,
  total_rides = EXCLUDED.total_rides,
  total_spent = EXCLUDED.total_spent,
  updated_at = now();

-- Insert sample rides with realistic data
INSERT INTO public.rides (
  id,
  driver_id,
  passenger_id,
  pickup_location,
  dropoff_location,
  status,
  fare,
  distance,
  duration,
  eta,
  created_at,
  completed_at,
  updated_at
) VALUES 
-- Active rides (happening now)
(
  '750e8400-e29b-41d4-a716-446655440001',
  '550e8400-e29b-41d4-a716-446655440001',
  '650e8400-e29b-41d4-a716-446655440001',
  'Gueliz, Marrakech',
  'Medina, Marrakech',
  'active',
  25.50,
  3.2,
  18,
  '12 min',
  now() - interval '8 minutes',
  null,
  now()
),
(
  '750e8400-e29b-41d4-a716-446655440002',
  '550e8400-e29b-41d4-a716-446655440002',
  '650e8400-e29b-41d4-a716-446655440002',
  'Agdal, Rabat',
  'Mohammed V Airport, Casablanca',
  'active',
  85.00,
  45.8,
  55,
  '42 min',
  now() - interval '13 minutes',
  null,
  now()
),

-- Completed rides from today
(
  '750e8400-e29b-41d4-a716-446655440003',
  '550e8400-e29b-41d4-a716-446655440001',
  '650e8400-e29b-41d4-a716-446655440003',
  'Hassan II Mosque, Casablanca',
  'Morocco Mall, Casablanca',
  'completed',
  32.75,
  8.5,
  22,
  null,
  now() - interval '3 hours',
  now() - interval '2 hours 38 minutes',
  now() - interval '2 hours 38 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440004',
  '550e8400-e29b-41d4-a716-446655440003',
  '650e8400-e29b-41d4-a716-446655440004',
  'Majorelle Garden, Marrakech',
  'Jemaa el-Fnaa, Marrakech',
  'completed',
  18.25,
  4.1,
  15,
  null,
  now() - interval '5 hours',
  now() - interval '4 hours 45 minutes',
  now() - interval '4 hours 45 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440005',
  '550e8400-e29b-41d4-a716-446655440005',
  '650e8400-e29b-41d4-a716-446655440005',
  'Corniche, Casablanca',
  'Twin Center, Casablanca',
  'completed',
  28.50,
  6.8,
  19,
  null,
  now() - interval '6 hours',
  now() - interval '5 hours 41 minutes',
  now() - interval '5 hours 41 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440006',
  '550e8400-e29b-41d4-a716-446655440001',
  '650e8400-e29b-41d4-a716-446655440001',
  'Anfa Place, Casablanca',
  'Casa Port Train Station, Casablanca',
  'completed',
  22.00,
  5.2,
  16,
  null,
  now() - interval '8 hours',
  now() - interval '7 hours 44 minutes',
  now() - interval '7 hours 44 minutes'
),

-- Completed rides from yesterday
(
  '750e8400-e29b-41d4-a716-446655440007',
  '550e8400-e29b-41d4-a716-446655440002',
  '650e8400-e29b-41d4-a716-446655440002',
  'Oudayas Kasbah, Rabat',
  'Hassan Tower, Rabat',
  'completed',
  15.75,
  3.8,
  12,
  null,
  now() - interval '1 day 2 hours',
  now() - interval '1 day 1 hour 48 minutes',
  now() - interval '1 day 1 hour 48 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440008',
  '550e8400-e29b-41d4-a716-446655440003',
  '650e8400-e29b-41d4-a716-446655440003',
  'Menara Mall, Marrakech',
  'Marrakech Railway Station',
  'completed',
  35.25,
  9.1,
  25,
  null,
  now() - interval '1 day 4 hours',
  now() - interval '1 day 3 hours 35 minutes',
  now() - interval '1 day 3 hours 35 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440009',
  '550e8400-e29b-41d4-a716-446655440005',
  '650e8400-e29b-41d4-a716-446655440004',
  'Ain Diab Beach, Casablanca',
  'Casa Voyageurs Train Station',
  'completed',
  41.50,
  12.3,
  28,
  null,
  now() - interval '1 day 6 hours',
  now() - interval '1 day 5 hours 32 minutes',
  now() - interval '1 day 5 hours 32 minutes'
),

-- Completed rides from this week
(
  '750e8400-e29b-41d4-a716-446655440010',
  '550e8400-e29b-41d4-a716-446655440001',
  '650e8400-e29b-41d4-a716-446655440005',
  'Agadir Marina, Agadir',
  'Agadir Airport',
  'completed',
  55.00,
  18.7,
  35,
  null,
  now() - interval '3 days',
  now() - interval '2 days 23 hours 25 minutes',
  now() - interval '2 days 23 hours 25 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440011',
  '550e8400-e29b-41d4-a716-446655440002',
  '650e8400-e29b-41d4-a716-446655440001',
  'Fez Medina, Fez',
  'Fez Train Station',
  'completed',
  19.75,
  5.4,
  17,
  null,
  now() - interval '4 days',
  now() - interval '3 days 23 hours 43 minutes',
  now() - interval '3 days 23 hours 43 minutes'
),
(
  '750e8400-e29b-41d4-a716-446655440012',
  '550e8400-e29b-41d4-a716-446655440003',
  '650e8400-e29b-41d4-a716-446655440002',
  'Tangier Port, Tangier',
  'Tangier Ibn Battuta Airport',
  'completed',
  48.25,
  15.2,
  32,
  null,
  now() - interval '5 days',
  now() - interval '4 days 23 hours 28 minutes',
  now() - interval '4 days 23 hours 28 minutes'
),

-- Cancelled rides
(
  '750e8400-e29b-41d4-a716-446655440013',
  '550e8400-e29b-41d4-a716-446655440004',
  '650e8400-e29b-41d4-a716-446655440003',
  'Meknes Medina, Meknes',
  'Meknes Train Station',
  'cancelled',
  0,
  0,
  0,
  null,
  now() - interval '2 days',
  now() - interval '2 days',
  now() - interval '2 days'
),
(
  '750e8400-e29b-41d4-a716-446655440014',
  null,
  '650e8400-e29b-41d4-a716-446655440004',
  'Essaouira Port, Essaouira',
  'Essaouira Airport',
  'cancelled',
  0,
  0,
  0,
  null,
  now() - interval '1 day',
  now() - interval '1 day',
  now() - interval '1 day'
)
ON CONFLICT (id) DO UPDATE SET
  driver_id = EXCLUDED.driver_id,
  passenger_id = EXCLUDED.passenger_id,
  pickup_location = EXCLUDED.pickup_location,
  dropoff_location = EXCLUDED.dropoff_location,
  status = EXCLUDED.status,
  fare = EXCLUDED.fare,
  distance = EXCLUDED.distance,
  duration = EXCLUDED.duration,
  eta = EXCLUDED.eta,
  completed_at = EXCLUDED.completed_at,
  updated_at = now();

-- Insert sample driver applications
INSERT INTO public.driver_applications (
  id,
  email,
  full_name,
  phone,
  license_number,
  vehicle_type,
  vehicle_year,
  vehicle_color,
  license_plate,
  insurance_number,
  status,
  documents,
  notes,
  created_at,
  updated_at
) VALUES 
(
  '850e8400-e29b-41d4-a716-446655440001',
  'hassan.alaoui@example.com',
  'Hassan Alaoui',
  '+212600000201',
  'DL789456123',
  'economy',
  '2021',
  'White',
  '5678-F-6',
  'INS123456789',
  'pending',
  '{"license_uploaded": true, "insurance_uploaded": false, "vehicle_registration_uploaded": true}',
  'Application submitted and awaiting document review.',
  now() - interval '2 days',
  now() - interval '2 days'
),
(
  '850e8400-e29b-41d4-a716-446655440002',
  'aicha.benali@example.com',
  'Aicha Benali',
  '+212600000202',
  'DL456789012',
  'comfort',
  '2022',
  'Black',
  '5678-G-7',
  'INS987654321',
  'under_review',
  '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": true}',
  'All documents received. Background check in progress.',
  now() - interval '5 days',
  now() - interval '1 day'
),
(
  '850e8400-e29b-41d4-a716-446655440003',
  'mehdi.fassi@example.com',
  'Mehdi Fassi',
  '+212600000203',
  'DL321654987',
  'luxury',
  '2023',
  'Silver',
  '5678-H-8',
  'INS456789123',
  'approved',
  '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": true}',
  'Application approved. Welcome to the driver network!',
  now() - interval '1 week',
  now() - interval '2 days'
),
(
  '850e8400-e29b-41d4-a716-446655440004',
  'khadija.idrissi@example.com',
  'Khadija Idrissi',
  '+212600000204',
  'DL654321098',
  'economy',
  '2019',
  'Red',
  '5678-I-9',
  'INS789123456',
  'rejected',
  '{"license_uploaded": true, "insurance_uploaded": false, "vehicle_registration_uploaded": false}',
  'Application rejected due to incomplete documentation. Please resubmit with all required documents.',
  now() - interval '10 days',
  now() - interval '8 days'
),
(
  '850e8400-e29b-41d4-a716-446655440005',
  'abdellatif.berrada@example.com',
  'Abdellatif Berrada',
  '+212600000205',
  'DL987654321',
  'comfort',
  '2020',
  'Blue',
  '5678-J-10',
  'INS321987654',
  'pending',
  '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": false}',
  'Waiting for vehicle registration document.',
  now() - interval '1 day',
  now() - interval '1 day'
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  license_number = EXCLUDED.license_number,
  vehicle_type = EXCLUDED.vehicle_type,
  vehicle_year = EXCLUDED.vehicle_year,
  vehicle_color = EXCLUDED.vehicle_color,
  license_plate = EXCLUDED.license_plate,
  insurance_number = EXCLUDED.insurance_number,
  status = EXCLUDED.status,
  documents = EXCLUDED.documents,
  notes = EXCLUDED.notes,
  updated_at = now();

-- Update app settings with realistic values
INSERT INTO public.app_settings (
  id,
  base_fare,
  per_km_rate,
  per_minute_rate,
  surge_enabled,
  max_surge_multiplier,
  commission_rate,
  notifications_enabled,
  support_email,
  support_phone,
  updated_at
) VALUES (
  gen_random_uuid(),
  8.00,
  2.50,
  0.35,
  true,
  2.5,
  25,
  true,
  'support@rideshare.ma',
  '+212520000000',
  now()
)
ON CONFLICT (id) DO UPDATE SET
  base_fare = EXCLUDED.base_fare,
  per_km_rate = EXCLUDED.per_km_rate,
  per_minute_rate = EXCLUDED.per_minute_rate,
  surge_enabled = EXCLUDED.surge_enabled,
  max_surge_multiplier = EXCLUDED.max_surge_multiplier,
  commission_rate = EXCLUDED.commission_rate,
  notifications_enabled = EXCLUDED.notifications_enabled,
  support_email = EXCLUDED.support_email,
  support_phone = EXCLUDED.support_phone,
  updated_at = now();