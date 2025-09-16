/*
  # Fix infinite recursion in profiles RLS policies

  1. Problem
    - Current RLS policies are causing infinite recursion
    - Using current_setting('request.jwt.claims.sub', true)::uuid causes circular dependency
    
  2. Solution
    - Drop all existing problematic policies
    - Recreate policies using auth.uid() function
    - This prevents recursion by using Supabase's built-in auth helper
    
  3. Changes
    - Remove policies that cause recursion
    - Add new policies with auth.uid()
    - Ensure RLS remains enabled for security
*/

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- Create new policies using auth.uid() to prevent recursion
CREATE POLICY "Users can view their own profile" 
  ON public.profiles 
  FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own profile" 
  ON public.profiles 
  FOR UPDATE 
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles 
  FOR INSERT 
  WITH CHECK (user_id = auth.uid());

-- Admin policy for managing all profiles
CREATE POLICY "Admins can manage all profiles" 
  ON public.profiles 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.user_id = auth.uid() 
      AND admin_profile.user_type = 'admin'
    )
  );