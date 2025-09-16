/*
  # Update User Types System

  1. Schema Changes
    - Update profiles table user_type constraint to include 'admin'
    - Update existing check constraint to allow admin, driver, passenger
    - Add role column if not exists for additional permissions

  2. Security
    - Update RLS policies to handle admin access
    - Ensure admins can access all data for management purposes

  3. Data Migration
    - Preserve existing user types
    - No data loss during migration
*/

-- Update the user_type check constraint to include admin
DO $$
BEGIN
  -- Drop the existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'profiles_user_type_check' 
    AND table_name = 'profiles'
  ) THEN
    ALTER TABLE public.profiles DROP CONSTRAINT profiles_user_type_check;
  END IF;
  
  -- Add the new constraint with admin included
  ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_user_type_check 
  CHECK (user_type IN ('passenger', 'driver', 'admin'));
END $$;

-- Ensure role column exists and has proper constraint
DO $$
BEGIN
  -- Add role column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'role'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN role text DEFAULT 'user';
  END IF;
  
  -- Update role constraint to include admin
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'profiles_role_check' 
    AND table_name = 'profiles'
  ) THEN
    ALTER TABLE public.profiles DROP CONSTRAINT profiles_role_check;
  END IF;
  
  ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('user', 'admin', 'driver'));
END $$;

-- Create admin-specific RLS policies
CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() 
      AND user_type = 'admin'
    )
    OR auth.uid() = user_id
  );

CREATE POLICY "Admins can update all profiles"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() 
      AND user_type = 'admin'
    )
    OR auth.uid() = user_id
  );

-- Update driver applications policies for admin access
CREATE POLICY "Admins can manage all driver applications"
  ON public.driver_applications
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() 
      AND user_type = 'admin'
    )
  );

-- Update drivers table policies for admin access
CREATE POLICY "Admins can manage all drivers"
  ON public.drivers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() 
      AND user_type = 'admin'
    )
  );

-- Update passengers table policies for admin access
CREATE POLICY "Admins can manage all passengers"
  ON public.passengers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() 
      AND user_type = 'admin'
    )
  );

-- Update rides table policies for admin access
CREATE POLICY "Admins can view all rides"
  ON public.rides
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() 
      AND user_type = 'admin'
    )
  );

-- Create a test admin user function (for development only)
CREATE OR REPLACE FUNCTION create_test_admin(
  admin_email text,
  admin_password text,
  admin_name text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id uuid;
  result json;
BEGIN
  -- This function should only be used in development
  -- In production, admins should be created through proper channels
  
  -- Note: This is a placeholder function
  -- Actual user creation must be done through Supabase Auth
  
  result := json_build_object(
    'message', 'Admin creation must be done through Supabase Auth Dashboard',
    'instructions', 'Create user in Auth > Users, then update their profile user_type to admin'
  );
  
  RETURN result;
END;
$$;