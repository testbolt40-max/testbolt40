/*
  # Fix infinite recursion in RLS policies

  1. Database Changes
    - Add user_id column to passengers table
    - Link existing passengers to profiles via email
    - Create proper RLS policies for passengers table
    - Remove problematic policies that cause recursion

  2. Security
    - Enable RLS on passengers table
    - Create policies for direct user_id access
    - Remove circular policy dependencies
*/

-- Add user_id to passengers table if it doesn't exist
ALTER TABLE public.passengers
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Update existing passenger records to link to profiles.user_id if possible
-- This is a best-effort migration. It assumes email is unique and linked to a profile.
UPDATE public.passengers p
SET user_id = pr.user_id
FROM public.profiles pr
WHERE p.email = pr.email AND p.user_id IS NULL;

-- Drop existing problematic policies on passengers table
DROP POLICY IF EXISTS "Admins can manage all passengers" ON public.passengers;
DROP POLICY IF EXISTS "Allow all operations for authenticated users on passengers" ON public.passengers;
DROP POLICY IF EXISTS "Allow all operations on passengers" ON public.passengers;

-- Enable RLS for passengers table
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;

-- Create simple, non-recursive RLS policies for passengers table
CREATE POLICY "Users can view their own passenger record"
  ON public.passengers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own passenger record"
  ON public.passengers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own passenger record"
  ON public.passengers FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own passenger record"
  ON public.passengers FOR DELETE
  USING (auth.uid() = user_id);

-- Admin policy for passengers (non-recursive)
CREATE POLICY "Admins can manage all passengers"
  ON public.passengers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'user_type' = 'admin'
    )
  );

-- Also fix any problematic policies on profiles table that might cause recursion
DROP POLICY IF EXISTS "Enable admin read access to all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Enable admin update access to all profiles" ON public.profiles;

-- Create simpler admin policies for profiles
CREATE POLICY "Admins can read all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'user_type' = 'admin'
    )
  );

CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'user_type' = 'admin'
    )
  );