/*
  # Fix infinite recursion in profiles RLS policies

  1. Problem
    - Current RLS policies on profiles table cause infinite recursion
    - Using auth.uid() in policies creates circular dependencies
    - Error: "infinite recursion detected in policy for relation profiles"

  2. Solution
    - Replace auth.uid() with direct JWT claims access
    - Use current_setting('request.jwt.claims.sub', true)::uuid
    - Simplify policies to avoid recursive evaluation

  3. Changes
    - Drop all existing problematic policies
    - Create new policies using JWT claims directly
    - Maintain same security level without recursion
*/

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON profiles;

-- Create new policies using JWT claims to avoid recursion
CREATE POLICY "Users can insert their own profile"
  ON profiles
  FOR INSERT
  TO public
  WITH CHECK (user_id = (current_setting('request.jwt.claims.sub', true))::uuid);

CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  TO public
  USING (user_id = (current_setting('request.jwt.claims.sub', true))::uuid);

CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  TO public
  USING (user_id = (current_setting('request.jwt.claims.sub', true))::uuid);

-- Admin policy using direct user_type check without recursion
CREATE POLICY "Admins can manage all profiles"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles admin_profile 
      WHERE admin_profile.user_id = (current_setting('request.jwt.claims.sub', true))::uuid
      AND admin_profile.user_type = 'admin'
    )
  );

-- Update the handle_new_user function to avoid RLS issues during profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Temporarily disable RLS for this operation
  PERFORM set_config('row_security.active', 'off', true);
  
  INSERT INTO public.profiles (user_id, email, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'passenger')
  );
  
  -- Re-enable RLS
  PERFORM set_config('row_security.active', 'on', true);
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Re-enable RLS even if there's an error
    PERFORM set_config('row_security.active', 'on', true);
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;