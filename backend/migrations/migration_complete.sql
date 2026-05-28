-- migration_complete.sql
-- Migration complète pour PROCOLIS Database avec tous les modèles

-- ========================================
-- 1. SUPPRESSION DES TABLES EXISTANTES (optionnel - décommentez si besoin)
-- ========================================
-- DROP TABLE IF EXISTS parcel_events CASCADE;
-- DROP TABLE IF EXISTS payments CASCADE;
-- DROP TABLE IF EXISTS parcels CASCADE;
-- DROP TABLE IF EXISTS garages CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS otps CASCADE;
-- DROP TABLE IF EXISTS tokens CASCADE;

-- ========================================
-- 2. CRÉATION DES TABLES
-- ========================================

-- Table users (correspond au modèle User)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(50) DEFAULT 'client',
    pin VARCHAR(10),
    garage_id UUID,
    vehicle_plate VARCHAR(50),
    vehicle_model VARCHAR(100),
    vehicle_color VARCHAR(50),
    vehicle_year INTEGER,
    address TEXT,
    city VARCHAR(100),
    region VARCHAR(100),
    driver_status VARCHAR(50),
    profile_photo_url TEXT,
    status VARCHAR(50) DEFAULT 'active',
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table garages
CREATE TABLE IF NOT EXISTS garages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    drivers_count INT DEFAULT 0,
    parcels_count INT DEFAULT 0,
    revenue DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table parcels (correspond au modèle Parcel complet)
CREATE TABLE IF NOT EXISTS parcels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    sender_id UUID NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_phone VARCHAR(50) NOT NULL,
    receiver_name VARCHAR(255) NOT NULL,
    receiver_phone VARCHAR(50) NOT NULL,
    receiver_email VARCHAR(255),
    receiver_address TEXT,
    description TEXT NOT NULL,
    weight DECIMAL(10, 2) NOT NULL,
    length DECIMAL(10, 2),
    width DECIMAL(10, 2),
    height DECIMAL(10, 2),
    type VARCHAR(50) DEFAULT 'package',
    status VARCHAR(50) DEFAULT 'pending',
    departure_garage_id UUID NOT NULL,
    departure_garage_name VARCHAR(255) NOT NULL,
    arrival_garage_id UUID,
    arrival_garage_name VARCHAR(255),
    driver_id UUID,
    driver_name VARCHAR(255),
    driver_phone VARCHAR(50),
    price DECIMAL(10, 2),
    delivery_fees DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50) DEFAULT 'pending',
    photo_urls TEXT[] DEFAULT '{}',
    video_urls TEXT[] DEFAULT '{}',
    signature_url TEXT,
    is_insured BOOLEAN DEFAULT FALSE,
    insurance_amount DECIMAL(10, 2),
    is_urgent BOOLEAN DEFAULT FALSE,
    urgent_fee DECIMAL(10, 2),
    notes TEXT,
    pickup_date TIMESTAMP,
    delivery_date TIMESTAMP,
    estimated_delivery_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    cancelled_by UUID,
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (departure_garage_id) REFERENCES garages(id) ON DELETE RESTRICT,
    FOREIGN KEY (arrival_garage_id) REFERENCES garages(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Table parcel_events (correspond au modèle ParcelEvent)
CREATE TABLE IF NOT EXISTS parcel_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    location_lat VARCHAR(50),
    location_lng VARCHAR(50),
    user_id UUID,
    user_name VARCHAR(255),
    user_role VARCHAR(50),
    photo_url TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parcel_id) REFERENCES parcels(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Table payments (correspond au modèle Payment)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    parcel_id UUID,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'XOF',
    method VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    transaction_id VARCHAR(255) UNIQUE,
    phone_number VARCHAR(50),
    reference VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (parcel_id) REFERENCES parcels(id) ON DELETE SET NULL
);

-- Table otps
CREATE TABLE IF NOT EXISTS otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    code VARCHAR(10) NOT NULL,
    type VARCHAR(50) DEFAULT 'verification',
    expires_at TIMESTAMP NOT NULL,
    attempts INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table tokens
CREATE TABLE IF NOT EXISTS tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    token TEXT UNIQUE NOT NULL,
    refresh_token TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ========================================
-- 3. CRÉATION DES INDEX
-- ========================================

-- Index pour users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_garage ON users(garage_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_driver_status ON users(driver_status);

-- Index pour garages
CREATE INDEX IF NOT EXISTS idx_garages_city ON garages(city);
CREATE INDEX IF NOT EXISTS idx_garages_region ON garages(region);

-- Index pour parcels
CREATE INDEX IF NOT EXISTS idx_parcels_tracking ON parcels(tracking_number);
CREATE INDEX IF NOT EXISTS idx_parcels_status ON parcels(status);
CREATE INDEX IF NOT EXISTS idx_parcels_sender ON parcels(sender_id);
CREATE INDEX IF NOT EXISTS idx_parcels_driver ON parcels(driver_id);
CREATE INDEX IF NOT EXISTS idx_parcels_departure_garage ON parcels(departure_garage_id);
CREATE INDEX IF NOT EXISTS idx_parcels_arrival_garage ON parcels(arrival_garage_id);
CREATE INDEX IF NOT EXISTS idx_parcels_created ON parcels(created_at);
CREATE INDEX IF NOT EXISTS idx_parcels_pickup_date ON parcels(pickup_date);
CREATE INDEX IF NOT EXISTS idx_parcels_type ON parcels(type);
CREATE INDEX IF NOT EXISTS idx_parcels_payment_status ON parcels(payment_status);

-- Index pour parcel_events
CREATE INDEX IF NOT EXISTS idx_events_parcel ON parcel_events(parcel_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON parcel_events(status);
CREATE INDEX IF NOT EXISTS idx_events_created ON parcel_events(created_at);
CREATE INDEX IF NOT EXISTS idx_events_user ON parcel_events(user_id);

-- Index pour payments
CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_parcel ON payments(parcel_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_transaction ON payments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(method);
CREATE INDEX IF NOT EXISTS idx_payments_created ON payments(created_at);

-- Index pour otps
CREATE INDEX IF NOT EXISTS idx_otps_user ON otps(user_id);
CREATE INDEX IF NOT EXISTS idx_otps_code ON otps(code);
CREATE INDEX IF NOT EXISTS idx_otps_expires ON otps(expires_at);

-- Index pour tokens
CREATE INDEX IF NOT EXISTS idx_tokens_user ON tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_tokens_token ON tokens(token);
CREATE INDEX IF NOT EXISTS idx_tokens_expires ON tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_tokens_refresh ON tokens(refresh_token);

-- ========================================
-- 4. FONCTIONS ET TRIGGERS
-- ========================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers pour garages
DROP TRIGGER IF EXISTS update_garages_updated_at ON garages;
CREATE TRIGGER update_garages_updated_at
    BEFORE UPDATE ON garages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers pour parcels
DROP TRIGGER IF EXISTS update_parcels_updated_at ON parcels;
CREATE TRIGGER update_parcels_updated_at
    BEFORE UPDATE ON parcels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 5. DONNÉES INITIALES
-- ========================================

-- Insertion des garages
INSERT INTO garages (id, name, city, region, address, phone)
VALUES 
    (gen_random_uuid(), 'Garage Dakar Centre', 'Dakar', 'Dakar', '123 Avenue Cheikh Anta Diop', '+221 33 123 45 67'),
    (gen_random_uuid(), 'Garage Thiès', 'Thiès', 'Thiès', 'Route Nationale 1', '+221 33 987 65 43'),
    (gen_random_uuid(), 'Garage Saint-Louis', 'Saint-Louis', 'Saint-Louis', 'Boulevard de la Libération', '+221 33 456 78 90'),
    (gen_random_uuid(), 'Garage Ziguinchor', 'Ziguinchor', 'Ziguinchor', 'Avenue Léopold Sédar Senghor', '+221 33 654 32 10'),
    (gen_random_uuid(), 'Garage Kaolack', 'Kaolack', 'Kaolack', 'Boulevard du Général de Gaulle', '+221 33 789 01 23')
ON CONFLICT (id) DO NOTHING;

-- Insertion de l'admin
INSERT INTO users (id, email, phone, full_name, role, status, pin, is_email_verified, is_phone_verified)
VALUES (
    gen_random_uuid(), 
    'admin@procolis.com', 
    '+221 77 123 45 67', 
    'Administrateur', 
    'super_admin', 
    'active', 
    '123456',
    TRUE,
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- Insertion d'un chauffeur test
INSERT INTO users (id, email, phone, full_name, role, driver_status, status, garage_id)
SELECT 
    gen_random_uuid(), 
    'driver@procolis.com', 
    '+221 78 123 45 67', 
    'Chauffeur Test', 
    'driver', 
    'available', 
    'active',
    id
FROM garages 
WHERE name = 'Garage Dakar Centre'
LIMIT 1
ON CONFLICT (email) DO NOTHING;

-- ========================================
-- 6. VÉRIFICATIONS
-- ========================================

-- Afficher les tables créées
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Compter les enregistrements
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'garages', COUNT(*) FROM garages
UNION ALL
SELECT 'parcels', COUNT(*) FROM parcels
UNION ALL
SELECT 'parcel_events', COUNT(*) FROM parcel_events
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'otps', COUNT(*) FROM otps
UNION ALL
SELECT 'tokens', COUNT(*) FROM tokens;

-- Afficher les index
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;