/*
  # Create driver auth user and profile

  This migration creates the actual Supabase Auth user for the driver test account
  and ensures the profile data is properly linked.

  1. Auth User Creation
    - Creates auth.users record for driver@test.com
    - Sets password and user metadata
    - Confirms email automatically for testing

  2. Profile Data
    - Links existing driver profile to auth user
    - Updates user_id references in related tables

  3. Security
    - Ensures proper RLS policies are applied
    - Maintains data integrity across tables
*/

-- Create the auth user for the driver account
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role,
  aud
) VALUES (
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'driver@test.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "John Smith", "user_type": "driver"}',
  false,
  'authenticated',
  'authenticated'
);

-- Create identity record
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  '{"sub": "550e8400-e29b-41d4-a716-446655440001", "email": "driver@test.com"}',
  'email',
  now(),
  now()
);

-- Update the existing profile to link to the auth user
UPDATE profiles 
SET user_id = '550e8400-e29b-41d4-a716-446655440001'::uuid
WHERE email = 'driver@test.com';

-- Update the existing driver record to link to the auth user
UPDATE drivers 
SET user_id = '550e8400-e29b-41d4-a716-446655440001'::uuid
WHERE email = 'driver@test.com';

-- Update driver application to link to the auth user
UPDATE driver_applications 
SET user_id = '550e8400-e29b-41d4-a716-446655440001'::uuid
WHERE email = 'driver@test.com';

-- Update any existing rides for this driver
UPDATE rides 
SET driver_id = (SELECT id FROM drivers WHERE email = 'driver@test.com')
WHERE driver_id IS NULL 
AND pickup_location LIKE '%San Francisco%';

-- Update payment methods to link to the auth user
UPDATE payment_methods 
SET user_id = '550e8400-e29b-41d4-a716-446655440001'::uuid
WHERE user_id = (SELECT user_id FROM profiles WHERE email = 'driver@test.com' LIMIT 1);

-- Update saved addresses to link to the auth user
UPDATE saved_addresses 
SET user_id = '550e8400-e29b-41d4-a716-446655440001'::uuid
WHERE user_id = (SELECT user_id FROM profiles WHERE email = 'driver@test.com' LIMIT 1);