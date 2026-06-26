-- =====================================================
-- SCHEMA COMPLET PROCOLIS - VERSION SUPABASE
-- AVEC DONNÉES D'EXEMPLE CORRIGÉES
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    password_hash TEXT,
    role TEXT NOT NULL DEFAULT 'client',
    pin TEXT,
    garage_id UUID,
    garage_name TEXT,
    vehicle_plate TEXT,
    vehicle_model TEXT,
    vehicle_color TEXT,
    vehicle_year INTEGER,
    address TEXT,
    city TEXT,
    region TEXT,
    driver_status TEXT DEFAULT 'offline',
    profile_photo_url TEXT,
    status TEXT DEFAULT 'active',
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2),
    total_deliveries INTEGER DEFAULT 0,
    completed_deliveries INTEGER DEFAULT 0,
    cancelled_deliveries INTEGER DEFAULT 0,
    gender TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    region TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    drivers_count INTEGER DEFAULT 0,
    parcels_count INTEGER DEFAULT 0,
    revenue DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour garages
CREATE INDEX idx_garages_city ON garages(city);
CREATE INDEX idx_garages_region ON garages(region);

-- =====================================================
-- TABLE OTP_CODES
-- =====================================================
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    type TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number TEXT UNIQUE NOT NULL,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    sender_phone TEXT NOT NULL,
    sender_email TEXT,
    receiver_name TEXT NOT NULL,
    receiver_phone TEXT NOT NULL,
    receiver_email TEXT,
    receiver_address TEXT,
    description TEXT NOT NULL,
    weight DECIMAL(10,2) NOT NULL,
    length DECIMAL(10,2),
    width DECIMAL(10,2),
    height DECIMAL(10,2),
    type TEXT NOT NULL DEFAULT 'package',
    status TEXT NOT NULL DEFAULT 'pending',
    departure_garage_id UUID NOT NULL REFERENCES garages(id),
    departure_garage_name TEXT NOT NULL,
    arrival_garage_id UUID REFERENCES garages(id),
    arrival_garage_name TEXT,
    driver_id UUID REFERENCES users(id),
    driver_name TEXT,
    driver_phone TEXT,
    price DECIMAL(15,2),
    delivery_fees DECIMAL(15,2),
    total_amount DECIMAL(15,2),
    payment_method TEXT,
    payment_phone_number TEXT,
    payment_status TEXT,
    photo_urls JSONB DEFAULT '[]',
    video_urls JSONB DEFAULT '[]',
    audio_urls JSONB DEFAULT '[]',
    signature_url TEXT,
    is_insured BOOLEAN DEFAULT FALSE,
    insurance_amount DECIMAL(15,2),
    is_urgent BOOLEAN DEFAULT FALSE,
    urgent_fee DECIMAL(15,2),
    notes TEXT,
    pickup_date TIMESTAMPTZ,
    delivery_date TIMESTAMPTZ,
    estimated_delivery_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    created_by_name TEXT,
    cancelled_by UUID REFERENCES users(id),
    cancellation_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    score_debited BOOLEAN DEFAULT FALSE,
    score_refunded BOOLEAN DEFAULT FALSE,
    is_free_for_bidding BOOLEAN DEFAULT FALSE,
    proposed_price DECIMAL(15,2),
    negotiated_price DECIMAL(15,2),
    selected_bid_id UUID
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id),
    driver_name TEXT NOT NULL,
    driver_phone TEXT NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    message TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    response_message TEXT,
    audio_url TEXT
);

-- Index pour bids
CREATE INDEX idx_bids_parcel_id ON bids(parcel_id);
CREATE INDEX idx_bids_driver_id ON bids(driver_id);
CREATE INDEX idx_bids_status ON bids(status);

-- =====================================================
-- TABLE PARCEL_EVENTS
-- =====================================================
CREATE TABLE parcel_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT,
    location_lat TEXT,
    location_lng TEXT,
    user_id UUID REFERENCES users(id),
    user_name TEXT,
    user_role TEXT,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour parcel_events
CREATE INDEX idx_events_parcel_id ON parcel_events(parcel_id);
CREATE INDEX idx_events_status ON parcel_events(status);
CREATE INDEX idx_events_created_at ON parcel_events(created_at);

-- =====================================================
-- TABLE PAYMENTS
-- =====================================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parcel_id UUID REFERENCES parcels(id),
    amount DECIMAL(15,2) NOT NULL,
    currency TEXT DEFAULT 'XOF',
    method TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    transaction_id TEXT,
    phone_number TEXT,
    reference TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    type TEXT NOT NULL,
    parcel_id UUID REFERENCES parcels(id),
    description TEXT NOT NULL,
    status TEXT DEFAULT 'completed',
    metadata JSONB,
    balance_after INTEGER DEFAULT 0,
    reference TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parcel_id UUID REFERENCES parcels(id),
    bid_id UUID REFERENCES bids(id),
    sender_id UUID REFERENCES users(id),
    sender_name TEXT,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    priority TEXT DEFAULT 'normal',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- Index pour notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_parcel_id ON notifications(parcel_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- =====================================================
-- FONCTIONS ET TRIGGERS
-- =====================================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour users
DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;
CREATE TRIGGER trigger_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour garages
DROP TRIGGER IF EXISTS trigger_garages_updated_at ON garages;
CREATE TRIGGER trigger_garages_updated_at
BEFORE UPDATE ON garages
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour parcels
DROP TRIGGER IF EXISTS trigger_parcels_updated_at ON parcels;
CREATE TRIGGER trigger_parcels_updated_at
BEFORE UPDATE ON parcels
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VUES POUR LES STATISTIQUES
-- =====================================================

-- Vue pour les statistiques administratives
CREATE OR REPLACE VIEW admin_stats AS
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
    (SELECT COALESCE(SUM(total_amount), 0) FROM parcels WHERE status = 'delivered' AND DATE_TRUNC('month', delivery_date) = DATE_TRUNC('month', NOW())) AS revenue_this_month,
    (SELECT COALESCE(SUM(total_amount), 0) FROM parcels WHERE status = 'delivered' AND DATE_TRUNC('month', delivery_date) = DATE_TRUNC('month', NOW() - INTERVAL '1 month')) AS revenue_last_month;

-- Vue pour les performances des garages
CREATE OR REPLACE VIEW garage_performance AS
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
-- DONNÉES D'EXEMPLE (CORRIGÉES)
-- =====================================================

-- Insertion d'un garage par défaut (UUID généré automatiquement)
INSERT INTO garages (name, city, region) 
VALUES (
    'Garage Principal Dakar',
    'Dakar',
    'Dakar'
) ON CONFLICT DO NOTHING;

-- Insertion d'un super admin par défaut (UUID généré automatiquement)
-- Mot de passe: admin123 (à hasher en production)
INSERT INTO users (
    email, phone, full_name, role, status, is_email_verified, is_phone_verified
) VALUES (
    'admin@procolis.com',
    '+221771234567',
    'Super Admin ProColis',
    'superAdmin',
    'active',
    TRUE,
    TRUE
) ON CONFLICT (email) DO NOTHING;

-- =====================================================
-- FIN DU SCHEMA
-- =====================================================