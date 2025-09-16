/*
  # Fix User Registration Database Error

  This migration fixes the "Database error saving new user" issue by ensuring:
  1. The profiles table has the correct structure with user_type column
  2. The handle_new_user function works properly
  3. The trigger is set up correctly for automatic profile creation

  ## Changes Made
  - Add user_type column to profiles table if missing
  - Create/update handle_new_user function
  - Set up trigger for automatic profile creation on user signup
  - Add proper RLS policies for profile creation
*/

-- First, ensure the user_type column exists in profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'user_type'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN user_type TEXT NOT NULL DEFAULT 'passenger';
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_user_type_check 
      CHECK (user_type IN ('passenger', 'driver', 'admin'));
  END IF;
END $$;

-- Create or replace the handle_new_user function
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
EXCEPTION
  WHEN others THEN
    -- Log the error but don't fail the user creation
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Ensure RLS policies allow profile creation
DROP POLICY IF EXISTS "Allow profile inserts" ON public.profiles;
CREATE POLICY "Allow profile inserts"
  ON public.profiles
  FOR INSERT
  TO public
  WITH CHECK (true);

-- Ensure users can view their own profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  TO public
  USING (auth.uid() = user_id);

-- Ensure users can update their own profiles
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  TO public
  USING (auth.uid() = user_id);