@@ .. @@
 
 -- Insert sample app settings
 INSERT INTO public.app_settings (base_fare, per_km_rate, per_minute_rate) VALUES (3.50, 1.20, 0.25);
-
--- Insert sample drivers (these will be created when real users sign up)
-INSERT INTO public.drivers (id, name, email, phone, rating, vehicle_type, license_plate, status, documents_verified, current_location, total_rides, earnings, last_active) VALUES
-  ('550e8400-e29b-41d4-a716-446655440001', 'John Smith', 'driver1@example.com', '+1-555-0101', 4.8, 'economy', 'ABC123', 'active', true, '{"latitude": 37.7749, "longitude": -122.4194}', 342, 8567.25, now()),
-  ('550e8400-e29b-41d4-a716-446655440002', 'Sarah Johnson', 'driver2@example.com', '+1-555-0102', 4.9, 'comfort', 'XYZ789', 'active', true, '{"latitude": 37.7849, "longitude": -122.4094}', 156, 4231.80, now()),
-  ('550e8400-e29b-41d4-a716-446655440003', 'Mike Davis', 'driver3@example.com', '+1-555-0103', 4.7, 'luxury', 'LUX456', 'active', true, '{"latitude": 37.7649, "longitude": -122.4294}', 89, 3456.90, now());
-
--- Insert sample driver applications (pending review)
-INSERT INTO public.driver_applications (user_id, email, full_name, phone, license_number, vehicle_type, vehicle_make, vehicle_model, vehicle_year, vehicle_color, license_plate, insurance_number, status, documents) VALUES
-  ('a2dd66a4-918c-41dc-8a39-fb0f1a8e3040', 'applicant1@example.com', 'Robert Wilson', '+1-555-0201', 'DL123456789', 'economy', 'Honda', 'Civic', '2021', 'Blue', 'HON123', 'INS987654321', 'pending', '{"license_uploaded": true, "insurance_uploaded": false, "vehicle_registration_uploaded": true}'),
-  ('b3ee77b5-a29d-52ed-9b4a-gc1g2b9f4f51', 'applicant2@example.com', 'Lisa Chen', '+1-555-0202', 'DL987654321', 'comfort', 'Toyota', 'Prius', '2022', 'White', 'TOY456', 'INS123456789', 'pending', '{"license_uploaded": true, "insurance_uploaded": true, "vehicle_registration_uploaded": false}'),
-  ('c4ff88c6-b3ae-63fe-ac5b-hd2h3cag5g62', 'applicant3@example.com', 'David Brown', '+1-555-0203', 'DL456789123', 'luxury', 'BMW', '3 Series', '2023', 'Black', 'BMW789', 'INS456789123', 'pending', '{"license_uploaded": false, "insurance_uploaded": true, "vehicle_registration_uploaded": true}');