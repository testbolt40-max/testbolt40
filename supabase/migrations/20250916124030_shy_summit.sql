/*
  # Update existing users to confirmed status

  This migration updates any existing users in the auth.users table to have confirmed email addresses,
  which resolves login issues for users who were created before email confirmation was disabled.

  1. Updates email_confirmed_at timestamp for all users
  2. Ensures all existing users can log in immediately
  3. Safe to run multiple times (uses WHERE clause to only update unconfirmed users)
*/

-- Update all existing users to have confirmed emails
UPDATE auth.users 
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, now()),
  updated_at = now()
WHERE email_confirmed_at IS NULL;

-- Ensure the email confirmation is properly set
UPDATE auth.users 
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, created_at),
  updated_at = now()
WHERE email_confirmed_at IS NULL;