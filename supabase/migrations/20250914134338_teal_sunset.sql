/*
  # Fix infinite recursion in profiles RLS policies

  1. Problem
    - RLS policies on profiles table are causing infinite recursion
    - This happens when auth.uid() function triggers re-evaluation of the same policy

  2. Solution
    - Disable RLS temporarily
    - Drop all existing policies that might cause recursion
    - Create new policies using JWT claims directly instead of auth.uid()
    - Re-enable RLS

  3. Security
    - Maintains same security level but avoids recursion
    - Uses current_setting('request.jwt.claims.sub') instead of auth.uid()
*/

-- Disable RLS temporarily to avoid issues during policy updates
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin access to all profiles" ON public.profiles;

-- Create new policies using JWT claims directly to avoid recursion
CREATE POLICY "Users can view their own profile" 
  ON public.profiles FOR SELECT 
  USING (user_id = current_setting('request.jwt.claims.sub', true)::uuid);

CREATE POLICY "Users can update their own profile" 
  ON public.profiles FOR UPDATE 
  USING (user_id = current_setting('request.jwt.claims.sub', true)::uuid);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (user_id = current_setting('request.jwt.claims.sub', true)::uuid);

-- Re-enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;