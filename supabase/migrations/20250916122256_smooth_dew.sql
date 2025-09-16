/*
  # Disable Email Confirmation for Development

  This migration disables email confirmation requirements to allow immediate login after signup.
  This is useful for development and testing environments.

  ## Changes
  1. Update auth configuration to disable email confirmation
  2. Allow users to sign in immediately after registration
*/

-- Disable email confirmation requirement
UPDATE auth.config 
SET email_confirm_required = false 
WHERE id = 1;

-- If the config table doesn't exist or is empty, insert default config
INSERT INTO auth.config (id, email_confirm_required)
VALUES (1, false)
ON CONFLICT (id) DO UPDATE SET email_confirm_required = false;