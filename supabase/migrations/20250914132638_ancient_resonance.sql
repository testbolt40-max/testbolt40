/*
  # Fix profiles table user_type column

  1. Database Schema Updates
    - Ensure user_type column exists with correct constraints
    - Update check constraint to include 'admin' type
    - Add proper indexes for performance
    
  2. Security Updates
    - Update RLS policies to handle admin users
    - Ensure proper permissions for all user types
    
  3. Trigger Updates
    - Update the handle_new_user function to properly handle user_type
*/

-- First, check if user_type column exists and add it if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'user_type'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN user_type text DEFAULT 'passenger' NOT NULL;
  END IF;
END $$;

-- Update the check constraint to include admin
DO $$
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'profiles' AND constraint_name = 'profiles_user_type_check'
  ) THEN
    ALTER TABLE public.profiles DROP CONSTRAINT profiles_user_type_check;
  END IF;
  
  -- Add new constraint with admin included
  ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_user_type_check 
  CHECK (user_type IN ('passenger', 'driver', 'admin'));
END $$;

-- Ensure the column has the correct default
ALTER TABLE public.profiles ALTER COLUMN user_type SET DEFAULT 'passenger';
ALTER TABLE public.profiles ALTER COLUMN user_type SET NOT NULL;

-- Create index for user_type if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);

-- Update the handle_new_user function to properly handle user_type
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

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update RLS policies to handle admin users properly
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    (EXISTS ( SELECT 1
     FROM profiles profiles_1
    WHERE ((profiles_1.user_id = auth.uid()) AND (profiles_1.user_type = 'admin'::text)))) 
    OR (auth.uid() = user_id)
  );

DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    (EXISTS ( SELECT 1
     FROM profiles profiles_1
    WHERE ((profiles_1.user_id = auth.uid()) AND (profiles_1.user_type = 'admin'::text)))) 
    OR (auth.uid() = user_id)
  );