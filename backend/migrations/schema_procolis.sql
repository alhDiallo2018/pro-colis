'EOF'

-- =====================================================
-- SCHEMA COMPLET PROCOLIS
-- Généré à partir des modèles Dart
-- =====================================================

-- Supprimer les tables existantes (si besoin)
DROP TABLE IF EXISTS score_transactions CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS parcel_events CASCADE;
DROP TABLE IF EXISTS bids CASCADE;
DROP TABLE IF EXISTS parcels CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS otp_codes CASCADE;
DROP TABLE IF EXISTS garages CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- =====================================================
-- TABLE USERS
-- =====================================================
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'client',
    pin VARCHAR(10),
    garage_id VARCHAR(36),
    garage_name VARCHAR(255),
    vehicle_plate VARCHAR(20),
    vehicle_model VARCHAR(100),
    vehicle_color VARCHAR(50),
    vehicle_year INTEGER,
    address TEXT,
    city VARCHAR(100),
    region VARCHAR(100),
    driver_status VARCHAR(50) DEFAULT 'offline',
    profile_photo_url TEXT,
    status VARCHAR(50) DEFAULT 'active',
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2),
    total_deliveries INTEGER DEFAULT 0,
    completed_deliveries INTEGER DEFAULT 0,
    cancelled_deliveries INTEGER DEFAULT 0,
    gender VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    last_active_at TIMESTAMP
);

-- Index pour users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_garage_id ON users(garage_id);

-- =====================================================
-- TABLE GARAGES
-- =====================================================
CREATE TABLE garages (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    drivers_count INTEGER DEFAULT 0,
    parcels_count INTEGER DEFAULT 0,
    revenue DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour garages
CREATE INDEX idx_garages_city ON garages(city);
CREATE INDEX idx_garages_region ON garages(region);

-- =====================================================
-- TABLE OTP_CODES
-- =====================================================
CREATE TABLE otp_codes (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(10) NOT NULL,
    type VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    attempts INTEGER DEFAULT 0
);

-- Index pour otp_codes
CREATE INDEX idx_otp_user_id ON otp_codes(user_id);
CREATE INDEX idx_otp_code ON otp_codes(code);
CREATE INDEX idx_otp_expires_at ON otp_codes(expires_at);

-- =====================================================
-- TABLE PARCELS
-- =====================================================
CREATE TABLE parcels (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    sender_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_name VARCHAR(255) NOT NULL,
    sender_phone VARCHAR(20) NOT NULL,
    sender_email VARCHAR(255),
    receiver_name VARCHAR(255) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    receiver_email VARCHAR(255),
    receiver_address TEXT,
    description TEXT NOT NULL,
    weight DECIMAL(10,2) NOT NULL,
    length DECIMAL(10,2),
    width DECIMAL(10,2),
    height DECIMAL(10,2),
    type VARCHAR(50) NOT NULL DEFAULT 'package',
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    departure_garage_id VARCHAR(36) NOT NULL REFERENCES garages(id),
    departure_garage_name VARCHAR(255) NOT NULL,
    arrival_garage_id VARCHAR(36) REFERENCES garages(id),
    arrival_garage_name VARCHAR(255),
    driver_id VARCHAR(36) REFERENCES users(id),
    driver_name VARCHAR(255),
    driver_phone VARCHAR(20),
    price DECIMAL(15,2),
    delivery_fees DECIMAL(15,2),
    total_amount DECIMAL(15,2),
    payment_method VARCHAR(50),
    payment_phone_number VARCHAR(20),
    payment_status VARCHAR(50),
    photo_urls JSONB DEFAULT '[]',
    video_urls JSONB DEFAULT '[]',
    audio_urls JSONB DEFAULT '[]',
    signature_url TEXT,
    is_insured BOOLEAN DEFAULT FALSE,
    insurance_amount DECIMAL(15,2),
    is_urgent BOOLEAN DEFAULT FALSE,
    urgent_fee DECIMAL(15,2),
    notes TEXT,
    pickup_date TIMESTAMP,
    delivery_date TIMESTAMP,
    estimated_delivery_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) REFERENCES users(id),
    created_by_name VARCHAR(255),
    cancelled_by VARCHAR(36) REFERENCES users(id),
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP,
    score_debited BOOLEAN DEFAULT FALSE,
    score_refunded BOOLEAN DEFAULT FALSE,
    is_free_for_bidding BOOLEAN DEFAULT FALSE,
    proposed_price DECIMAL(15,2),
    negotiated_price DECIMAL(15,2),
    selected_bid_id VARCHAR(36)
);

-- Index pour parcels
CREATE INDEX idx_parcels_tracking_number ON parcels(tracking_number);
CREATE INDEX idx_parcels_sender_id ON parcels(sender_id);
CREATE INDEX idx_parcels_status ON parcels(status);
CREATE INDEX idx_parcels_departure_garage ON parcels(departure_garage_id);
CREATE INDEX idx_parcels_arrival_garage ON parcels(arrival_garage_id);
CREATE INDEX idx_parcels_driver_id ON parcels(driver_id);
CREATE INDEX idx_parcels_created_at ON parcels(created_at);

-- =====================================================
-- TABLE BIDS (Offres)
-- =====================================================
CREATE TABLE bids (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id VARCHAR(36) NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
    driver_id VARCHAR(36) NOT NULL REFERENCES users(id),
    driver_name VARCHAR(255) NOT NULL,
    driver_phone VARCHAR(20) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    message TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP,
    response_message TEXT,
    audio_url TEXT
);

-- Index pour bids
CREATE INDEX idx_bids_parcel_id ON bids(parcel_id);
CREATE INDEX idx_bids_driver_id ON bids(driver_id);
CREATE INDEX idx_bids_status ON bids(status);

-- Mise à jour de la clé étrangère selected_bid_id
ALTER TABLE parcels ADD CONSTRAINT fk_parcels_selected_bid FOREIGN KEY (selected_bid_id) REFERENCES bids(id);

-- =====================================================
-- TABLE PARCEL_EVENTS
-- =====================================================
CREATE TABLE parcel_events (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id VARCHAR(36) NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    location_lat VARCHAR(50),
    location_lng VARCHAR(50),
    user_id VARCHAR(36) REFERENCES users(id),
    user_name VARCHAR(255),
    user_role VARCHAR(50),
    photo_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour parcel_events
CREATE INDEX idx_events_parcel_id ON parcel_events(parcel_id);
CREATE INDEX idx_events_status ON parcel_events(status);
CREATE INDEX idx_events_created_at ON parcel_events(created_at);

-- =====================================================
-- TABLE PAYMENTS
-- =====================================================
CREATE TABLE payments (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parcel_id VARCHAR(36) REFERENCES parcels(id),
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'XOF',
    method VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    transaction_id VARCHAR(255),
    phone_number VARCHAR(20),
    reference VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Index pour payments
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_parcel_id ON payments(parcel_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);

-- =====================================================
-- TABLE SCORE_TRANSACTIONS
-- =====================================================
CREATE TABLE score_transactions (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL,
    parcel_id VARCHAR(36) REFERENCES parcels(id),
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'completed',
    metadata JSONB,
    balance_after INTEGER DEFAULT 0,
    reference VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour score_transactions
CREATE INDEX idx_score_user_id ON score_transactions(user_id);
CREATE INDEX idx_score_parcel_id ON score_transactions(parcel_id);
CREATE INDEX idx_score_type ON score_transactions(type);
CREATE INDEX idx_score_created_at ON score_transactions(created_at);

-- =====================================================
-- TABLE NOTIFICATIONS
-- =====================================================
CREATE TABLE notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parcel_id VARCHAR(36) REFERENCES parcels(id),
    bid_id VARCHAR(36) REFERENCES bids(id),
    sender_id VARCHAR(36) REFERENCES users(id),
    sender_name VARCHAR(255),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'normal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Index pour notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_parcel_id ON notifications(parcel_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- =====================================================
-- VUES POUR LES STATISTIQUES
-- =====================================================

-- Vue pour les statistiques administratives
CREATE VIEW admin_stats AS
SELECT 
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM users WHERE role = 'driver') AS total_drivers,
    (SELECT COUNT(*) FROM users WHERE role = 'client') AS total_clients,
    (SELECT COUNT(*) FROM garages) AS total_garages,
    (SELECT COUNT(*) FROM users WHERE vehicle_plate IS NOT NULL) AS total_vehicles,
    (SELECT COUNT(*) FROM parcels) AS total_parcels,
    (SELECT COUNT(*) FROM parcels WHERE status IN ('confirmed', 'picked_up', 'in_transit', 'arrived', 'out_for_delivery')) AS parcels_in_transit,
    (SELECT COUNT(*) FROM parcels WHERE status = 'delivered' AND DATE(delivery_date) = CURRENT_DATE) AS parcels_delivered_today,
    (SELECT COUNT(*) FROM parcels WHERE status = 'pending') AS parcels_pending,
    (SELECT COALESCE(SUM(total_amount), 0) FROM parcels WHERE status = 'delivered') AS total_revenue,
    (SELECT COALESCE(SUM(total_amount), 0) FROM parcels WHERE status = 'delivered' AND DATE_TRUNC('month', delivery_date) = DATE_TRUNC('month', CURRENT_DATE)) AS revenue_this_month,
    (SELECT COALESCE(SUM(total_amount), 0) FROM parcels WHERE status = 'delivered' AND DATE_TRUNC('month', delivery_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')) AS revenue_last_month;

-- Vue pour les performances des garages
CREATE VIEW garage_performance AS
SELECT 
    g.id AS garage_id,
    g.name AS garage_name,
    g.city,
    COUNT(p.id) AS parcels_handled,
    COUNT(CASE WHEN p.status = 'delivered' AND p.delivery_date <= p.estimated_delivery_date THEN 1 END) AS on_time_deliveries,
    COALESCE(AVG(u.rating), 0) AS rating,
    COALESCE(SUM(p.total_amount), 0) AS revenue
FROM garages g
LEFT JOIN parcels p ON p.departure_garage_id = g.id OR p.arrival_garage_id = g.id
LEFT JOIN users u ON u.garage_id = g.id
GROUP BY g.id, g.name, g.city;

-- =====================================================
-- FONCTIONS ET TRIGGERS
-- =====================================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour users
CREATE TRIGGER trigger_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour garages
CREATE TRIGGER trigger_garages_updated_at
BEFORE UPDATE ON garages
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour parcels
CREATE TRIGGER trigger_parcels_updated_at
BEFORE UPDATE ON parcels
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour générer un numéro de suivi unique
CREATE OR REPLACE FUNCTION generate_tracking_number()
RETURNS TRIGGER AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..10 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    NEW.tracking_number := CONCAT('PC-', result);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour générer le tracking number
CREATE TRIGGER trigger_generate_tracking_number
BEFORE INSERT ON parcels
FOR EACH ROW
WHEN (NEW.tracking_number IS NULL)
EXECUTE FUNCTION generate_tracking_number();

-- =====================================================
-- DONNÉES D'EXEMPLE (optionnel)
-- =====================================================

-- Insertion d'un garage par défaut
INSERT INTO garages (id, name, city, region) 
VALUES (
    'garage-default-001',
    'Garage Principal Dakar',
    'Dakar',
    'Dakar'
);

-- Insertion d'un super admin par défaut
-- Mot de passe: admin123 (à hasher en production)
INSERT INTO users (
    id, email, phone, full_name, role, status, is_email_verified, is_phone_verified
) VALUES (
    'superadmin-001',
    'admin@procolis.com',
    '+221771234567',
    'Super Admin ProColis',
    'superAdmin',
    'active',
    TRUE,
    TRUE
);

-- =====================================================
-- FIN DU SCHEMA
-- =====================================================

EOF