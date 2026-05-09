-- migrations/001_initial_schema.sql

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    password_hash TEXT,
    role VARCHAR(50) NOT NULL CHECK (role IN ('super_admin', 'admin', 'driver', 'client')),
    garage_id UUID,
    vehicle_plate VARCHAR(50),
    profile_photo_url TEXT,
    status VARCHAR(50) DEFAULT 'active',
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    updated_at TIMESTAMP
);

-- OTP Codes table
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    type VARCHAR(50) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(255),
    is_used BOOLEAN DEFAULT FALSE,
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User tokens table
CREATE TABLE user_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Garages table
CREATE TABLE garages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    country VARCHAR(100) DEFAULT 'Sénégal',
    address TEXT NOT NULL,
    phone VARCHAR(50) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    admin_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Vehicles table
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate_number VARCHAR(50) UNIQUE NOT NULL,
    model VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    capacity INT NOT NULL,
    garage_id UUID REFERENCES garages(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Parcels table
CREATE TABLE parcels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    sender_id UUID REFERENCES users(id),
    receiver_name VARCHAR(255) NOT NULL,
    receiver_phone VARCHAR(50) NOT NULL,
    receiver_email VARCHAR(255),
    receiver_id UUID REFERENCES users(id),
    description TEXT,
    weight DECIMAL(10, 2),
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    departure_garage_id UUID REFERENCES garages(id),
    arrival_garage_id UUID REFERENCES garages(id),
    current_location_id UUID REFERENCES garages(id),
    driver_id UUID REFERENCES users(id),
    assigned_vehicle_id UUID REFERENCES vehicles(id),
    price DECIMAL(10, 2),
    payment_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    picked_up_at TIMESTAMP,
    departed_at TIMESTAMP,
    arrived_at TIMESTAMP,
    delivered_at TIMESTAMP
);

-- Parcel events table
CREATE TABLE parcel_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID REFERENCES parcels(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    user_id UUID REFERENCES users(id),
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Parcel photos table
CREATE TABLE parcel_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID REFERENCES parcels(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_otp_codes_user ON otp_codes(user_id);
CREATE INDEX idx_otp_codes_code ON otp_codes(code);
CREATE INDEX idx_parcels_tracking ON parcels(tracking_number);
CREATE INDEX idx_parcels_sender ON parcels(sender_id);
CREATE INDEX idx_parcels_driver ON parcels(driver_id);
CREATE INDEX idx_parcels_status ON parcels(status);
CREATE INDEX idx_parcels_created ON parcels(created_at);
CREATE INDEX idx_parcel_events_parcel ON parcel_events(parcel_id);
CREATE INDEX idx_parcel_events_timestamp ON parcel_events(timestamp);