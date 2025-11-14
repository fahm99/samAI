-- =====================================================
-- SMART AGRICULTURE SYSTEM DATABASE SCHEMA
-- =====================================================
-- This file contains the complete database schema for a smart agriculture system
-- including plant disease detection, irrigation management, and marketplace features.
-- Generated on: 2025-07-17
-- Database: Supabase PostgreSQL
-- =====================================================

-- =====================================================
-- CUSTOM TYPES (ENUMS)
-- =====================================================

-- Detection status for disease detection workflow
CREATE TYPE detection_status AS ENUM ('new', 'treating', 'treated', 'reviewed', 'resolved');

-- Irrigation system types
CREATE TYPE irrigation_type AS ENUM ('manual', 'automatic', 'smart');

-- Message types for chat system
CREATE TYPE message_type AS ENUM ('text', 'image', 'file', 'product_inquiry');

-- Notification categories
CREATE TYPE notification_type AS ENUM ('irrigation', 'sensor_alert', 'disease_detection', 'market', 'chat');

-- Disease prevention method types
CREATE TYPE prevention_type AS ENUM ('cultural', 'biological', 'chemical', 'physical');

-- Disease treatment types
CREATE TYPE treatment_type AS ENUM ('chemical', 'biological', 'cultural', 'preventive');

-- =====================================================
-- CORE TABLES
-- =====================================================

-- User profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone_number TEXT,
    location TEXT,
    avatar_url TEXT,
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    whatsapp_number TEXT,
    country_code TEXT DEFAULT '+967'
);

-- User application settings
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    theme_mode TEXT DEFAULT 'light',
    language TEXT DEFAULT 'ar',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    sound_enabled BOOLEAN DEFAULT TRUE,
    vibration_enabled BOOLEAN DEFAULT TRUE,
    auto_backup BOOLEAN DEFAULT TRUE,
    backup_frequency TEXT DEFAULT 'daily',
    location_enabled BOOLEAN DEFAULT TRUE,
    temperature_unit TEXT DEFAULT 'celsius',
    date_format TEXT DEFAULT 'dd/MM/yyyy',
    timezone TEXT DEFAULT 'Asia/Riyadh',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    plant_care_notifications BOOLEAN DEFAULT TRUE,
    market_notifications BOOLEAN DEFAULT TRUE,
    system_notifications BOOLEAN DEFAULT TRUE,
    show_personal_info BOOLEAN DEFAULT TRUE,
    share_location BOOLEAN DEFAULT FALSE,
    profile_visibility BOOLEAN DEFAULT TRUE
);

-- Admin users for system management
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    role TEXT NOT NULL DEFAULT 'admin',
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    is_active BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- IRRIGATION SYSTEM TABLES
-- =====================================================

-- IoT irrigation systems
CREATE TABLE irrigation_systems (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    device_serial TEXT NOT NULL UNIQUE,
    location TEXT,
    crop_type TEXT NOT NULL,
    area_size NUMERIC,
    is_active BOOLEAN DEFAULT TRUE,
    auto_irrigation_enabled BOOLEAN DEFAULT FALSE,
    water_low_threshold INTEGER DEFAULT 30,
    firmware_version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sensor data from irrigation systems
CREATE TABLE sensor_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES irrigation_systems(id) ON DELETE CASCADE,
    soil_moisture NUMERIC,
    temperature NUMERIC,
    humidity NUMERIC,
    water_level NUMERIC,
    pump_status BOOLEAN,
    rain_detected BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Irrigation activity logs
CREATE TABLE irrigation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES irrigation_systems(id) ON DELETE CASCADE,
    type irrigation_type NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER,
    water_amount_liters NUMERIC,
    soil_moisture_before NUMERIC,
    soil_moisture_after NUMERIC,
    triggered_by TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System configuration settings
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES irrigation_systems(id) ON DELETE CASCADE,
    plant_type_id TEXT,
    growth_stage INTEGER DEFAULT 0,
    auto_irrigation_enabled BOOLEAN DEFAULT FALSE,
    start_threshold NUMERIC DEFAULT 40.0,
    stop_threshold NUMERIC DEFAULT 80.0,
    temperature_threshold NUMERIC DEFAULT 30.0,
    rain_stop_enabled BOOLEAN DEFAULT TRUE,
    water_saving_mode BOOLEAN DEFAULT FALSE,
    irrigation_schedule JSONB,
    daily_irrigation_limit BIGINT,
    irrigation_duration DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Remote system commands
CREATE TABLE system_commands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES irrigation_systems(id) ON DELETE CASCADE,
    command_type TEXT NOT NULL,
    parameters JSONB,
    executed BOOLEAN DEFAULT FALSE,
    executed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- DISEASE DETECTION TABLES
-- =====================================================

-- Plant disease database
CREATE TABLE plant_diseases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    english_name TEXT NOT NULL,
    plant_type TEXT NOT NULL,
    description TEXT,
    symptoms TEXT[],
    conditions TEXT[],
    treatments JSONB,
    image_urls TEXT[],
    severity_level INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disease symptoms details
CREATE TABLE disease_symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_id UUID NOT NULL REFERENCES plant_diseases(id) ON DELETE CASCADE,
    symptom_name TEXT NOT NULL,
    description TEXT,
    severity_level INTEGER DEFAULT 1,
    visible_stage TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disease treatment methods
CREATE TABLE disease_treatments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_id UUID NOT NULL REFERENCES plant_diseases(id) ON DELETE CASCADE,
    treatment_name TEXT NOT NULL,
    treatment_type treatment_type NOT NULL,
    description TEXT,
    application_method TEXT,
    dosage TEXT,
    frequency TEXT,
    effectiveness_rating NUMERIC DEFAULT 0.0,
    cost_estimate NUMERIC,
    active_ingredients TEXT[],
    precautions TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disease prevention methods
CREATE TABLE disease_prevention (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_id UUID NOT NULL REFERENCES plant_diseases(id) ON DELETE CASCADE,
    prevention_method TEXT NOT NULL,
    method_type prevention_type NOT NULL,
    description TEXT,
    implementation_timing TEXT,
    effectiveness_rating NUMERIC DEFAULT 0.0,
    cost_estimate NUMERIC,
    required_materials TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User disease detection records
CREATE TABLE disease_detections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    image_path TEXT NOT NULL,
    plant_type TEXT NOT NULL,
    disease_name TEXT,
    disease_id UUID REFERENCES plant_diseases(id) ON DELETE SET NULL,
    confidence NUMERIC,
    status TEXT DEFAULT 'new',
    detection_date TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- MARKETPLACE TABLES
-- =====================================================

-- Agricultural products marketplace
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL,
    category TEXT NOT NULL,
    image_urls TEXT[],
    location TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product ratings and reviews
CREATE TABLE product_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, user_id)
);

-- Product likes/favorites
CREATE TABLE product_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, user_id)
);

-- =====================================================
-- NOTIFICATION SYSTEM
-- =====================================================

-- Notification templates
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type notification_type NOT NULL,
    variables JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type notification_type NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- SYSTEM MANAGEMENT TABLES
-- =====================================================

-- Device inventory management
CREATE TABLE device_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    serial_number TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL DEFAULT 'ESP32',
    model TEXT,
    manufacturer TEXT,
    purchase_date DATE,
    warranty_expiry DATE,
    status TEXT DEFAULT 'available',
    assigned_to UUID REFERENCES profiles(id),
    assigned_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ML models for disease detection
CREATE TABLE ml_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    model_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    accuracy NUMERIC,
    training_date TIMESTAMPTZ,
    deployment_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Content moderation system
CREATE TABLE content_moderation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_type TEXT NOT NULL,
    content_id UUID NOT NULL,
    status TEXT DEFAULT 'pending',
    moderator_id UUID REFERENCES admin_users(id),
    moderation_date TIMESTAMPTZ,
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STORAGE BUCKETS CONFIGURATION
-- =====================================================

-- Disease detection images bucket
-- Bucket: diseaseimages
-- Public: true
-- File size limit: 50MB
-- Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg

-- Product images bucket
-- Bucket: productimages
-- Public: true
-- File size limit: 50MB
-- Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg

-- User avatar images bucket
-- Bucket: avatars
-- Public: true
-- File size limit: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg

-- Profile images bucket
-- Bucket: profiles
-- Public: true
-- File size limit: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg

-- =====================================================
-- CUSTOM FUNCTIONS
-- =====================================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insert user data into profiles table
  INSERT INTO public.profiles (id, full_name, email, is_verified)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email,
    CASE WHEN NEW.email_confirmed_at IS NOT NULL THEN TRUE ELSE FALSE END
  );

  RETURN NEW;
END;
$$;

-- Function to update updated_at column automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_users
        WHERE user_id = auth.uid() AND is_active = true
    );
END;
$$;

-- Function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_users
        WHERE user_id = auth.uid() AND is_active = true AND role = 'super_admin'
    );
END;
$$;

-- Function to find disease by name
CREATE OR REPLACE FUNCTION find_disease_by_name(disease_name_param TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    disease_uuid UUID;
    cleaned_name TEXT;
BEGIN
    cleaned_name := TRIM(LOWER(disease_name_param));

    SELECT id INTO disease_uuid
    FROM plant_diseases
    WHERE LOWER(english_name) = cleaned_name
    AND is_active = true
    LIMIT 1;

    IF disease_uuid IS NULL THEN
        SELECT id INTO disease_uuid
        FROM plant_diseases
        WHERE LOWER(english_name) LIKE '%' || cleaned_name || '%'
        AND is_active = true
        ORDER BY LENGTH(english_name)
        LIMIT 1;
    END IF;

    RETURN disease_uuid;
END;
$$;

-- Function to save disease detection
CREATE OR REPLACE FUNCTION save_disease_detection(
    p_user_id UUID,
    p_image_path TEXT,
    p_plant_type TEXT,
    p_disease_name TEXT,
    p_confidence NUMERIC DEFAULT NULL,
    p_location TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    detection_id UUID;
    disease_uuid UUID;
BEGIN
    disease_uuid := find_disease_by_name(p_disease_name);

    INSERT INTO disease_detections (
        user_id, image_path, plant_type, disease_name,
        disease_id, confidence, location, notes
    ) VALUES (
        p_user_id, p_image_path, p_plant_type, p_disease_name,
        disease_uuid, p_confidence, p_location, p_notes
    ) RETURNING id INTO detection_id;

    RETURN detection_id;
END;
$$;

-- Function to get user detections with disease info
CREATE OR REPLACE FUNCTION get_user_detections(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    image_path TEXT,
    plant_type TEXT,
    disease_name TEXT,
    confidence NUMERIC,
    status TEXT,
    detection_date TIMESTAMPTZ,
    notes TEXT,
    location TEXT,
    disease_info JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        dd.id,
        dd.image_path,
        dd.plant_type,
        dd.disease_name,
        dd.confidence,
        dd.status,
        dd.detection_date,
        dd.notes,
        dd.location,
        CASE
            WHEN pd.id IS NOT NULL THEN
                jsonb_build_object(
                    'id', pd.id,
                    'name', pd.name,
                    'english_name', pd.english_name,
                    'description', pd.description,
                    'severity_level', pd.severity_level
                )
            ELSE NULL
        END as disease_info
    FROM disease_detections dd
    LEFT JOIN plant_diseases pd ON dd.disease_id = pd.id
    WHERE dd.user_id = p_user_id
    ORDER BY dd.detection_date DESC;
END;
$$;

-- Function to get product average rating
CREATE OR REPLACE FUNCTION get_product_average_rating(product_uuid UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    avg_rating DECIMAL(3,2);
BEGIN
    SELECT AVG(rating)::DECIMAL(3,2) INTO avg_rating
    FROM product_ratings
    WHERE product_id = product_uuid;

    RETURN COALESCE(avg_rating, 0.0);
END;
$$;

-- Function to get product likes count
CREATE OR REPLACE FUNCTION get_product_likes_count(product_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    likes_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO likes_count
    FROM product_likes
    WHERE product_id = product_uuid;

    RETURN COALESCE(likes_count, 0);
END;
$$;

-- Function to get product ratings with user info
CREATE OR REPLACE FUNCTION get_product_ratings_with_users(product_uuid UUID)
RETURNS TABLE(
    id UUID,
    rating INTEGER,
    comment TEXT,
    created_at TIMESTAMPTZ,
    user_name TEXT,
    user_avatar TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        pr.id,
        pr.rating,
        pr.comment,
        pr.created_at,
        COALESCE(p.full_name, 'مستخدم مجهول') as user_name,
        p.avatar_url as user_avatar
    FROM product_ratings pr
    LEFT JOIN profiles p ON pr.user_id = p.id
    WHERE pr.product_id = product_uuid
    ORDER BY pr.created_at DESC;
END;
$$;

-- Function to get products with ratings
CREATE OR REPLACE FUNCTION get_products_with_ratings(limit_count INTEGER DEFAULT 10)
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    price NUMERIC,
    image_url TEXT,
    category TEXT,
    location TEXT,
    user_id UUID,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    average_rating NUMERIC,
    ratings_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.description,
        p.price,
        p.image_url,
        p.category,
        p.location,
        p.user_id,
        p.is_active,
        p.created_at,
        p.updated_at,
        COALESCE(ROUND(AVG(pr.rating::DECIMAL), 2), 0) as average_rating,
        COUNT(pr.rating) as ratings_count
    FROM products p
    LEFT JOIN product_ratings pr ON p.id = pr.product_id
    WHERE p.is_active = true
    GROUP BY p.id, p.name, p.description, p.price, p.image_url, p.category, p.location, p.user_id, p.is_active, p.created_at, p.updated_at
    ORDER BY average_rating DESC, ratings_count DESC, p.created_at DESC
    LIMIT limit_count;
END;
$$;

-- Function to get top rated products
CREATE OR REPLACE FUNCTION get_top_rated_products(limit_count INTEGER DEFAULT 10)
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    price NUMERIC,
    image_urls TEXT[],
    category TEXT,
    location TEXT,
    user_id UUID,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    average_rating NUMERIC,
    ratings_count BIGINT,
    profiles JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.description,
        p.price,
        p.image_urls,
        p.category,
        p.location,
        p.user_id,
        p.is_active,
        p.created_at,
        p.updated_at,
        COALESCE(ROUND(AVG(pr.rating::DECIMAL), 2), 0) as average_rating,
        COUNT(pr.rating) as ratings_count,
        to_jsonb(prof.*) as profiles
    FROM products p
    LEFT JOIN product_ratings pr ON p.id = pr.product_id
    LEFT JOIN profiles prof ON p.user_id = prof.id
    WHERE p.is_active = true
    GROUP BY p.id, p.name, p.description, p.price, p.image_urls, p.category, p.location, p.user_id, p.is_active, p.created_at, p.updated_at, prof.*
    HAVING COUNT(pr.rating) > 0 AND AVG(pr.rating) >= 3.0
    ORDER BY average_rating DESC, ratings_count DESC, p.created_at DESC
    LIMIT limit_count;
END;
$$;

-- Function to get unread messages count (for chat system)
CREATE OR REPLACE FUNCTION get_unread_messages_count(conversation_uuid UUID, user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO unread_count
    FROM messages
    WHERE conversation_id = conversation_uuid
    AND is_read = false
    AND sender_id != user_uuid;

    RETURN COALESCE(unread_count, 0);
END;
$$;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Triggers for updating updated_at columns
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_irrigation_systems_updated_at
    BEFORE UPDATE ON irrigation_systems
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plant_diseases_updated_at
    BEFORE UPDATE ON plant_diseases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_disease_detections_updated_at
    BEFORE UPDATE ON disease_detections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_ratings_updated_at
    BEFORE UPDATE ON product_ratings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE irrigation_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE irrigation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE plant_diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE disease_symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE disease_treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE disease_prevention ENABLE ROW LEVEL SECURITY;
ALTER TABLE disease_detections ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can manage all profiles" ON profiles
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- User settings policies
CREATE POLICY "Users can view their own settings" ON user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_settings
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_settings
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own settings" ON user_settings
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all user settings" ON user_settings
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Admin users policies
CREATE POLICY "Only super admins can manage admin users" ON admin_users
    FOR ALL USING (is_super_admin()) WITH CHECK (is_super_admin());

-- Irrigation systems policies
CREATE POLICY "Users can view their own irrigation systems" ON irrigation_systems
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own irrigation systems" ON irrigation_systems
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update their own irrigation systems" ON irrigation_systems
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all irrigation systems" ON irrigation_systems
    FOR SELECT USING (is_admin_user());

CREATE POLICY "Admins can manage all irrigation systems" ON irrigation_systems
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Sensor data policies
CREATE POLICY "Users can view sensor data for their systems" ON sensor_data
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = sensor_data.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "System can insert sensor data" ON sensor_data
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage all sensor data" ON sensor_data
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Irrigation logs policies
CREATE POLICY "Users can view irrigation logs for their systems" ON irrigation_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = irrigation_logs.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert irrigation logs for their systems" ON irrigation_logs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = irrigation_logs.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all irrigation logs" ON irrigation_logs
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- System settings policies
CREATE POLICY "Users can view settings for their systems" ON system_settings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = system_settings.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update settings for their systems" ON system_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = system_settings.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = system_settings.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all system settings" ON system_settings
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- System commands policies
CREATE POLICY "Users can view commands for their systems" ON system_commands
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = system_commands.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert commands for their systems" ON system_commands
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM irrigation_systems
            WHERE irrigation_systems.id = system_commands.system_id
            AND irrigation_systems.user_id = auth.uid()
        )
    );

CREATE POLICY "System can update command execution status" ON system_commands
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Admins can manage all system commands" ON system_commands
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Plant diseases policies
CREATE POLICY "Anyone can view active plant diseases" ON plant_diseases
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage plant diseases" ON plant_diseases
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Disease symptoms policies
CREATE POLICY "Anyone can view disease symptoms" ON disease_symptoms
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage disease symptoms" ON disease_symptoms
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Disease treatments policies
CREATE POLICY "Anyone can view disease treatments" ON disease_treatments
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage disease treatments" ON disease_treatments
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Disease prevention policies
CREATE POLICY "Anyone can view disease prevention" ON disease_prevention
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage disease prevention" ON disease_prevention
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Disease detections policies
CREATE POLICY "Users can view their own disease detections" ON disease_detections
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own disease detections" ON disease_detections
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update their own disease detections" ON disease_detections
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own disease detections" ON disease_detections
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all disease detections" ON disease_detections
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Products policies
CREATE POLICY "Anyone can view active products" ON products
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can insert their own products" ON products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update their own products" ON products
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products" ON products
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all products" ON products
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Product ratings policies
CREATE POLICY "Anyone can view product ratings" ON product_ratings
    FOR SELECT USING (true);

CREATE POLICY "Users can rate products" ON product_ratings
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update their own ratings" ON product_ratings
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own ratings" ON product_ratings
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all ratings" ON product_ratings
    FOR ALL USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Product likes policies
CREATE POLICY "Anyone can view product likes" ON product_likes
    FOR SELECT USING (true);

CREATE POLICY "Users can like products" ON product_likes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can unlike their own likes" ON product_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for frequently queried columns
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_is_active ON profiles(is_active);
CREATE INDEX idx_irrigation_systems_user_id ON irrigation_systems(user_id);
CREATE INDEX idx_irrigation_systems_device_serial ON irrigation_systems(device_serial);
CREATE INDEX idx_sensor_data_system_id ON sensor_data(system_id);
CREATE INDEX idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX idx_irrigation_logs_system_id ON irrigation_logs(system_id);
CREATE INDEX idx_irrigation_logs_start_time ON irrigation_logs(start_time);
CREATE INDEX idx_plant_diseases_english_name ON plant_diseases(english_name);
CREATE INDEX idx_plant_diseases_plant_type ON plant_diseases(plant_type);
CREATE INDEX idx_disease_detections_user_id ON disease_detections(user_id);
CREATE INDEX idx_disease_detections_detection_date ON disease_detections(detection_date);
CREATE INDEX idx_products_user_id ON products(user_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_product_ratings_product_id ON product_ratings(product_id);
CREATE INDEX idx_product_likes_product_id ON product_likes(product_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE profiles IS 'User profiles extending Supabase auth.users with additional information';
COMMENT ON TABLE user_settings IS 'User application preferences and settings';
COMMENT ON TABLE admin_users IS 'System administrators with elevated permissions';
COMMENT ON TABLE irrigation_systems IS 'IoT irrigation systems registered by users';
COMMENT ON TABLE sensor_data IS 'Real-time sensor readings from irrigation systems';
COMMENT ON TABLE irrigation_logs IS 'Historical irrigation activity records';
COMMENT ON TABLE system_settings IS 'Configuration settings for each irrigation system';
COMMENT ON TABLE system_commands IS 'Remote commands sent to irrigation systems';
COMMENT ON TABLE plant_diseases IS 'Database of plant diseases for ML detection';
COMMENT ON TABLE disease_symptoms IS 'Detailed symptoms for each plant disease';
COMMENT ON TABLE disease_treatments IS 'Treatment methods for plant diseases';
COMMENT ON TABLE disease_prevention IS 'Prevention methods for plant diseases';
COMMENT ON TABLE disease_detections IS 'User disease detection records from ML analysis';
COMMENT ON TABLE products IS 'Agricultural marketplace products';
COMMENT ON TABLE product_ratings IS 'User ratings and reviews for products';
COMMENT ON TABLE product_likes IS 'User likes/favorites for products';
COMMENT ON TABLE notifications IS 'System notifications sent to users';
COMMENT ON TABLE notification_templates IS 'Templates for system notifications';
COMMENT ON TABLE device_inventory IS 'Inventory management for IoT devices';
COMMENT ON TABLE ml_models IS 'Machine learning models for disease detection';
COMMENT ON TABLE content_moderation IS 'Content moderation system for user-generated content';

-- =====================================================
-- END OF SCHEMA DOCUMENTATION
-- =====================================================
