/*
  # Create confirmed test users

  1. Test Users
    - Creates test@passenger.com with password123
    - Creates test@driver.com with password123  
    - Creates admin@rideshare.com with admin123
    - All users have confirmed emails to bypass confirmation requirement

  2. User Profiles
    - Creates corresponding profiles for each test user
    - Sets appropriate user types (passenger, driver, admin)

  3. Security
    - Uses secure password hashing
    - Sets email_confirmed_at to bypass email confirmation
*/

-- Create test passenger user
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
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'test@passenger.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  false,
  'authenticated',
  'authenticated'
) ON CONFLICT (email) DO NOTHING;

-- Create test driver user
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
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'test@driver.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  false,
  'authenticated',
  'authenticated'
) ON CONFLICT (email) DO NOTHING;

-- Create test admin user
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
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'admin@rideshare.com',
  crypt('admin123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  false,
  'authenticated',
  'authenticated'
) ON CONFLICT (email) DO NOTHING;

-- Create profiles for test users
INSERT INTO public.profiles (
  user_id,
  email,
  full_name,
  user_type
) 
SELECT 
  u.id,
  u.email,
  CASE 
    WHEN u.email = 'test@passenger.com' THEN 'Test Passenger'
    WHEN u.email = 'test@driver.com' THEN 'Test Driver'
    WHEN u.email = 'admin@rideshare.com' THEN 'Admin User'
  END,
  CASE 
    WHEN u.email = 'test@passenger.com' THEN 'passenger'::user_type
    WHEN u.email = 'test@driver.com' THEN 'driver'::user_type
    WHEN u.email = 'admin@rideshare.com' THEN 'admin'::user_type
  END
FROM auth.users u
WHERE u.email IN ('test@passenger.com', 'test@driver.com', 'admin@rideshare.com')
ON CONFLICT (user_id) DO NOTHING;