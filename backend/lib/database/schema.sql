-- database/schema.sql
CREATE DATABASE procolis;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('super_admin', 'admin', 'driver', 'client')),
    garage_id UUID,
    vehicle_plate VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

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
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

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

CREATE TABLE parcels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    sender_id UUID REFERENCES users(id),
    receiver_name VARCHAR(255) NOT NULL,
    receiver_phone VARCHAR(50) NOT NULL,
    receiver_id UUID REFERENCES users(id),
    description TEXT,
    weight DECIMAL(10, 2),
    status VARCHAR(50) DEFAULT 'pending',
    departure_garage_id UUID REFERENCES garages(id),
    arrival_garage_id UUID REFERENCES garages(id),
    driver_id UUID REFERENCES users(id),
    assigned_vehicle_id UUID REFERENCES vehicles(id),
    created_at TIMESTAMP DEFAULT NOW(),
    picked_up_at TIMESTAMP,
    arrived_at TIMESTAMP,
    delivered_at TIMESTAMP
);

CREATE TABLE parcel_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID REFERENCES parcels(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE TABLE parcel_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_id UUID REFERENCES parcels(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_garage ON users(garage_id);
CREATE INDEX idx_parcels_tracking ON parcels(tracking_number);
CREATE INDEX idx_parcels_sender ON parcels(sender_id);
CREATE INDEX idx_parcels_driver ON parcels(driver_id);
CREATE INDEX idx_parcels_status ON parcels(status);
CREATE INDEX idx_parcels_departure ON parcels(departure_garage_id);
CREATE INDEX idx_parcels_arrival ON parcels(arrival_garage_id);
CREATE INDEX idx_parcel_events_parcel ON parcel_events(parcel_id);
CREATE INDEX idx_parcel_photos_parcel ON parcel_photos(parcel_id);