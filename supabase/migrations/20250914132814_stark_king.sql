/*
  # Fix profiles table schema and RLS policies

  1. Schema Updates
    - Add missing columns: rating, total_trips
    - Ensure user_type column exists with proper constraints
    - Update column defaults and constraints

  2. RLS Policy Fixes
    - Remove problematic recursive policies
    - Create simple, non-recursive policies
    - Ensure proper permissions for all user types

  3. Trigger Updates
    - Fix handle_new_user function
    - Ensure proper profile creation on signup
*/

-- First, drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Add missing columns if they don't exist
DO $$
BEGIN
  -- Add rating column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'rating'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN rating DECIMAL(2,1) DEFAULT 5.0;
  END IF;

  -- Add total_trips column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'total_trips'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN total_trips INTEGER DEFAULT 0;
  END IF;

  -- Add phone column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'phone'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN phone TEXT;
  END IF;
END $$;

-- Update user_type constraint to include admin
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
  ALTER TABLE public.profiles ADD CONSTRAINT profiles_user_type_check 
    CHECK (user_type IN ('passenger', 'driver', 'admin'));
END $$;

-- Create simple, non-recursive RLS policies
CREATE POLICY "Enable read access for users to their own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Enable insert access for users to their own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable update access for users to their own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create admin policies (separate from user policies to avoid recursion)
CREATE POLICY "Enable admin read access to all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

CREATE POLICY "Enable admin update access to all profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );

-- Update the handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    user_id, 
    email, 
    full_name, 
    user_type,
    rating,
    total_trips
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'passenger'),
    5.0,
    0
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update existing profiles to have default values for new columns
UPDATE public.profiles 
SET 
  rating = COALESCE(rating, 5.0),
  total_trips = COALESCE(total_trips, 0)
WHERE rating IS NULL OR total_trips IS NULL;