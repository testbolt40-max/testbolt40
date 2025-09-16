/*
  # Fix RLS INSERT Policy Recursion

  This migration fixes the infinite recursion error in the profiles table RLS policies.
  The issue occurs when the INSERT policy's WITH CHECK clause uses auth.uid() during
  trigger execution, creating a circular dependency.

  ## Changes
  1. Drop the problematic INSERT policy
  2. Create a new policy that allows service_role inserts (for triggers)
  3. Still maintains security for regular user inserts

  ## Security
  - Service role can insert (needed for handle_new_user trigger)
  - Authenticated users can only insert their own profiles
*/

-- Drop the existing problematic INSERT policy
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Create a new INSERT policy that prevents recursion
CREATE POLICY "Allow profile inserts by service role and authenticated users" 
  ON public.profiles FOR INSERT 
  WITH CHECK (
    (auth.role() = 'service_role') OR 
    (user_id = auth.uid())
  );