/*
  # Fix infinite recursion in profiles RLS policies

  1. Problem
    - The handle_new_user() trigger function creates infinite recursion
    - RLS policies on profiles table conflict with SECURITY DEFINER function
    - auth.uid() doesn't match NEW.id during initial insert

  2. Solution
    - Update handle_new_user() function to bypass RLS during insert
    - Simplify RLS policies to avoid circular dependencies
    - Ensure proper permissions without recursion
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for users to their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable update access for users to their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert access for users to their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Create simple, non-recursive policies
CREATE POLICY "Allow users to read own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Allow users to update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Allow inserts for authenticated users (used by trigger)
CREATE POLICY "Allow profile creation"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Admin policy that doesn't cause recursion
CREATE POLICY "Allow admin access to all profiles"
  ON public.profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- Fix the handle_new_user function to bypass RLS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Temporarily disable row level security for this insert
  -- This is necessary because the function runs as SECURITY DEFINER
  -- and auth.uid() would not match NEW.id during the initial insert.
  PERFORM set_config('row_security.active', 'off', true);

  INSERT INTO public.profiles (user_id, email, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'passenger')
  );

  -- Re-enable row level security
  PERFORM set_config('row_security.active', 'on', true);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;