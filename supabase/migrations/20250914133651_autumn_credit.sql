/*
  # Fix users table permission errors

  1. Security
    - Update RLS policies to avoid referencing auth.users table directly
    - Use auth.uid() function instead of querying users table
    - Remove policies that cause permission denied errors

  2. Changes
    - Fix profiles table policies to use proper authentication checks
    - Update passenger policies to avoid users table references
    - Ensure proper access control without security risks
*/

-- Drop problematic policies that reference auth.users table
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can manage all passengers" ON passengers;

-- Create new admin policies that don't reference auth.users table
-- Instead, we'll check if the current user has admin user_type in their own profile
CREATE POLICY "Admins can read all profiles" ON profiles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR user_id = auth.uid()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Admins can manage all passengers" ON passengers
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR user_id = auth.uid()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR user_id = auth.uid()
  );

-- Ensure all tables have proper policies for authenticated users
-- Update driver applications policies
DROP POLICY IF EXISTS "Admins can manage all driver applications" ON driver_applications;
CREATE POLICY "Admins can manage all driver applications" ON driver_applications
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- Update drivers table policies  
DROP POLICY IF EXISTS "Admins can manage all drivers" ON drivers;
CREATE POLICY "Admins can manage all drivers" ON drivers
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- Update rides table policies
DROP POLICY IF EXISTS "Admins can view all rides" ON rides;
CREATE POLICY "Admins can view all rides" ON rides
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
    OR passenger_id IN (
      SELECT id FROM passengers WHERE user_id = auth.uid()
    )
    OR driver_id IN (
      SELECT id FROM drivers WHERE email = (
        SELECT email FROM profiles WHERE user_id = auth.uid()
      )
    )
  );