/*
  # Temporarily disable RLS on profiles table to fix recursion

  This migration temporarily disables RLS on the profiles table to resolve
  the infinite recursion error. After running this, you should:
  
  1. Test that the app works
  2. Go to Supabase Dashboard > Authentication > Policies
  3. Remove ALL existing policies on the profiles table
  4. Re-enable RLS
  5. Add only the correct policies from DATABASE_SETUP.md
*/

-- Temporarily disable RLS on profiles table
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- Note: RLS is now disabled. You need to manually re-enable it in Supabase Dashboard
-- and add the correct policies after confirming the app works.