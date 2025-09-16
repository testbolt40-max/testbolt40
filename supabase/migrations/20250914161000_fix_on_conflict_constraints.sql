-- Ensure all ON CONFLICT targets have unique constraints

-- Add UNIQUE constraint to id in drivers (should already be PK, but make sure)
ALTER TABLE public.drivers ADD CONSTRAINT IF NOT EXISTS drivers_id_unique UNIQUE (id);

-- Add UNIQUE constraint to id in passengers (should already be PK, but make sure)
ALTER TABLE public.passengers ADD CONSTRAINT IF NOT EXISTS passengers_id_unique UNIQUE (id);

-- Add UNIQUE constraint to id in rides (should already be PK, but make sure)
ALTER TABLE public.rides ADD CONSTRAINT IF NOT EXISTS rides_id_unique UNIQUE (id);

-- Add UNIQUE constraint to id in app_settings (should already be PK, but make sure)
ALTER TABLE public.app_settings ADD CONSTRAINT IF NOT EXISTS app_settings_id_unique UNIQUE (id);

-- Add UNIQUE constraint to email in drivers (should already exist, but make sure)
ALTER TABLE public.drivers ADD CONSTRAINT IF NOT EXISTS drivers_email_unique UNIQUE (email);

-- Add UNIQUE constraint to email in passengers (should already exist, but make sure)
ALTER TABLE public.passengers ADD CONSTRAINT IF NOT EXISTS passengers_email_unique UNIQUE (email);

-- Add UNIQUE constraint to (user_id, card_last_four) in payment_methods for ON CONFLICT (user_id, card_last_four)
ALTER TABLE public.payment_methods ADD CONSTRAINT IF NOT EXISTS payment_methods_user_id_card_last_four_unique UNIQUE (user_id, card_last_four);

-- Add UNIQUE constraint to (user_id, label) in saved_addresses for ON CONFLICT (user_id, label)
ALTER TABLE public.saved_addresses ADD CONSTRAINT IF NOT EXISTS saved_addresses_user_id_label_unique UNIQUE (user_id, label);

-- Add UNIQUE constraint to (user_id, label) in driver_applications if needed
ALTER TABLE public.driver_applications ADD CONSTRAINT IF NOT EXISTS driver_applications_email_unique UNIQUE (email);

-- Add UNIQUE constraint to id in driver_applications (should already be PK, but make sure)
ALTER TABLE public.driver_applications ADD CONSTRAINT IF NOT EXISTS driver_applications_id_unique UNIQUE (id);

-- Add UNIQUE constraint to id in payment_methods (should already be PK, but make sure)
ALTER TABLE public.payment_methods ADD CONSTRAINT IF NOT EXISTS payment_methods_id_unique UNIQUE (id);

-- Add UNIQUE constraint to id in saved_addresses (should already be PK, but make sure)
ALTER TABLE public.saved_addresses ADD CONSTRAINT IF NOT EXISTS saved_addresses_id_unique UNIQUE (id);
