/*
  # Add Sample Trips Data

  1. Sample Data
    - Add sample drivers with proper UUIDs
    - Add sample passengers 
    - Add sample rides (active, completed, cancelled)
    - Add sample driver applications

  2. Data Relationships
    - Link rides to drivers and passengers
    - Ensure proper foreign key relationships
    - Add realistic timestamps and data

  3. Test Data Coverage
    - Multiple ride statuses
    - Different vehicle types
    - Various fare amounts and distances
    - Recent and historical data
*/

-- Insert sample drivers with proper UUIDs
INSERT INTO drivers (id, name, email, phone, rating, vehicle_type, license_plate, status, documents_verified, total_rides, earnings, last_active) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Mohammed Alami', 'mohammed.alami@example.com', '+212600000001', 4.8, 'comfort', '1234-A-1', 'active', true, 156, 8567.25, now()),
('550e8400-e29b-41d4-a716-446655440002', 'Sara Benjelloun', 'sara.benjelloun@example.com', '+212600000002', 4.9, 'luxury', '1234-B-2', 'active', true, 203, 12450.80, now()),
('550e8400-e29b-41d4-a716-446655440003', 'Karim Tazi', 'karim.tazi@example.com', '+212600000003', 4.7, 'economy', '1234-C-3', 'inactive', true, 89, 4230.50, now() - interval '2 hours'),
('550e8400-e29b-41d4-a716-446655440004', 'Fatima Zahra', 'fatima.zahra@example.com', '+212600000004', 4.6, 'economy', '1234-D-4', 'active', true, 67, 3120.75, now()),
('550e8400-e29b-41d4-a716-446655440005', 'Youssef Benali', 'youssef.benali@example.com', '+212600000005', 4.9, 'luxury', '1234-E-5', 'suspended', false, 234, 15670.90, now() - interval '1 day')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  rating = EXCLUDED.rating,
  vehicle_type = EXCLUDED.vehicle_type,
  license_plate = EXCLUDED.license_plate,
  status = EXCLUDED.status,
  documents_verified = EXCLUDED.documents_verified,
  total_rides = EXCLUDED.total_rides,
  earnings = EXCLUDED.earnings,
  last_active = EXCLUDED.last_active;

-- Insert sample passengers
INSERT INTO passengers (id, user_id, name, email, phone, status, total_rides, total_spent) VALUES
('650e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440001', 'Ahmed Hassan', 'ahmed.hassan@example.com', '+212600000101', 'active', 23, 567.80),
('650e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440002', 'Laila Mansouri', 'laila.mansouri@example.com', '+212600000102', 'active', 45, 1234.50),
('650e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440003', 'Omar Idrissi', 'omar.idrissi@example.com', '+212600000103', 'active', 12, 298.75),
('650e8400-e29b-41d4-a716-446655440004', '750e8400-e29b-41d4-a716-446655440004', 'Nadia Berrada', 'nadia.berrada@example.com', '+212600000104', 'active', 67, 1876.25),
('650e8400-e29b-41d4-a716-446655440005', '750e8400-e29b-41d4-a716-446655440005', 'Rachid Alaoui', 'rachid.alaoui@example.com', '+212600000105', 'active', 34, 892.40)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  status = EXCLUDED.status,
  total_rides = EXCLUDED.total_rides,
  total_spent = EXCLUDED.total_spent;

-- Insert sample rides with various statuses and recent timestamps
INSERT INTO rides (id, driver_id, passenger_id, pickup_location, dropoff_location, status, fare, distance, duration, eta, created_at, completed_at) VALUES
-- Active rides
('850e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 'Casablanca Marina', 'Mohammed V Airport', 'active', 45.50, 12.3, 25, '8 min', now() - interval '5 minutes', null),
('850e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440002', 'Hassan II Mosque', 'Twin Center', 'active', 28.75, 8.7, 18, '12 min', now() - interval '3 minutes', null),

-- Today's completed rides
('850e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440003', 'Ain Diab Beach', 'Maarif District', 'completed', 22.30, 6.5, 15, null, now() - interval '2 hours', now() - interval '1 hour 45 minutes'),
('850e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440004', 'Casa Port Train Station', 'Anfa Place Mall', 'completed', 18.90, 4.2, 12, null, now() - interval '4 hours', now() - interval '3 hours 48 minutes'),
('850e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440005', 'Morocco Mall', 'Corniche Casablanca', 'completed', 15.60, 3.8, 10, null, now() - interval '6 hours', now() - interval '5 hours 50 minutes'),
('850e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440001', 'Habous Quarter', 'Casa Finance City', 'completed', 32.40, 9.1, 20, null, now() - interval '8 hours', now() - interval '7 hours 40 minutes'),

-- Yesterday's completed rides
('850e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440002', 'Derb Ghallef', 'Sidi Maarouf', 'completed', 38.75, 11.2, 28, null, now() - interval '1 day 3 hours', now() - interval '1 day 2 hours 32 minutes'),
('850e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440003', 'Racine Mall', 'Casablanca Cathedral', 'completed', 19.85, 5.4, 14, null, now() - interval '1 day 5 hours', now() - interval '1 day 4 hours 46 minutes'),
('850e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440004', 'Bouskoura Golf City', 'Casablanca Port', 'completed', 42.10, 13.6, 32, null, now() - interval '1 day 7 hours', now() - interval '1 day 6 hours 28 minutes'),

-- This week's completed rides
('850e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440005', 'Technopark Casablanca', 'Ain Sebaa', 'completed', 26.50, 7.8, 19, null, now() - interval '2 days', now() - interval '2 days' + interval '19 minutes'),
('850e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440001', 'Gauthier District', 'Hay Hassani', 'completed', 21.75, 6.1, 16, null, now() - interval '3 days', now() - interval '3 days' + interval '16 minutes'),
('850e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440004', '650e8400-e29b-41d4-a716-446655440002', 'Bernoussi', 'Zenata Airport City', 'completed', 35.20, 10.4, 24, null, now() - interval '4 days', now() - interval '4 days' + interval '24 minutes'),

-- Cancelled rides
('850e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440003', 'Salmiya District', 'Bourgogne', 'cancelled', 0, 5.2, 0, null, now() - interval '1 day 2 hours', now() - interval '1 day 2 hours'),
('850e8400-e29b-41d4-a716-446655440014', null, '650e8400-e29b-41d4-a716-446655440004', 'Mers Sultan', 'Roches Noires', 'cancelled', 0, 0, 0, null, now() - interval '3 hours', now() - interval '3 hours')

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
  created_at = EXCLUDED.created_at,
  completed_at = EXCLUDED.completed_at;

-- Insert sample driver applications
INSERT INTO driver_applications (id, email, full_name, phone, license_number, vehicle_type, vehicle_year, vehicle_color, license_plate, insurance_number, status, documents, notes, created_at) VALUES
('950e8400-e29b-41d4-a716-446655440001', 'hassan.alami@example.com', 'Hassan Alami', '+212600000201', 'DL789456123', 'economy', '2021', 'White', '5678-F-6', 'INS123456789', 'pending', '{"license_uploaded": true, "insurance_uploaded": false, "vehicle_registration_uploaded": true}', 'Application submitted for review', now() - interval '2 days'),
('950e8400-e29b-41d4-a716-446655440002', 'amina.benali@example.com', 'Amina Benali', '+212600000202', 'DL456789012', 'comfort', '2022', 'Black', '5678-G-7', 'INS987654321', 'pending', '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": false}', 'Waiting for vehicle registration document', now() - interval '1 day'),
('950e8400-e29b-41d4-a716-446655440003', 'khalid.rami@example.com', 'Khalid Rami', '+212600000203', 'DL321654987', 'luxury', '2023', 'Silver', '5678-H-8', 'INS456789123', 'under_review', '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": true}', 'All documents received, under review by team', now() - interval '3 days'),
('950e8400-e29b-41d4-a716-446655440004', 'sofia.tahiri@example.com', 'Sofia Tahiri', '+212600000204', 'DL654321098', 'economy', '2020', 'Blue', '5678-I-9', 'INS789123456', 'approved', '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": true}', 'Application approved - driver can start working', now() - interval '5 days'),
('950e8400-e29b-41d4-a716-446655440005', 'mehdi.fassi@example.com', 'Mehdi Fassi', '+212600000205', 'DL987654321', 'comfort', '2019', 'Red', '5678-J-10', 'INS321098765', 'rejected', '{"license_uploaded": false, "insurance_uploaded": true, "vehicle_registration_uploaded": false}', 'Missing required documents - please resubmit', now() - interval '1 week')
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
  created_at = EXCLUDED.created_at;

-- Update app settings with realistic values
INSERT INTO app_settings (id, base_fare, per_km_rate, per_minute_rate, surge_enabled, max_surge_multiplier, commission_rate, notifications_enabled, support_email, support_phone) VALUES
('app-settings-1', 5.00, 1.50, 0.25, true, 3.0, 20, true, 'support@rideshare.com', '+1-800-RIDE-APP')
ON CONFLICT (id) DO UPDATE SET
  base_fare = EXCLUDED.base_fare,
  per_km_rate = EXCLUDED.per_km_rate,
  per_minute_rate = EXCLUDED.per_minute_rate,
  surge_enabled = EXCLUDED.surge_enabled,
  max_surge_multiplier = EXCLUDED.max_surge_multiplier,
  commission_rate = EXCLUDED.commission_rate,
  notifications_enabled = EXCLUDED.notifications_enabled,
  support_email = EXCLUDED.support_email,
  support_phone = EXCLUDED.support_phone;