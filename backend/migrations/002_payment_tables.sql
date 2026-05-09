-- migrations/002_payment_tables.sql

-- Payments table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    parcel_id UUID REFERENCES parcels(id),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'XOF',
    method VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    transaction_id VARCHAR(255),
    phone_number VARCHAR(50),
    reference VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Payment methods configuration
CREATE TABLE payment_methods_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    method VARCHAR(50) NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    fees_percentage DECIMAL(5, 2) DEFAULT 0,
    fixed_fees DECIMAL(10, 2) DEFAULT 0,
    min_amount DECIMAL(10, 2) DEFAULT 0,
    max_amount DECIMAL(10, 2),
    config JSONB,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Driver location tracking
CREATE TABLE driver_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(10, 2),
    speed DECIMAL(10, 2),
    bearing DECIMAL(10, 2),
    recorded_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_parcel ON payments(parcel_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created ON payments(created_at);
CREATE INDEX idx_driver_locations_driver ON driver_locations(driver_id);
CREATE INDEX idx_driver_locations_recorded ON driver_locations(recorded_at);

-- Create a function to clean old driver locations
CREATE OR REPLACE FUNCTION clean_driver_locations()
RETURNS void AS $$
BEGIN
    DELETE FROM driver_locations 
    WHERE recorded_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to update parcel status
CREATE OR REPLACE FUNCTION update_parcel_status_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE parcels 
        SET payment_status = 'paid',
            status = 'confirmed'
        WHERE id = NEW.parcel_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_payment_completed
    AFTER UPDATE ON payments
    FOR EACH ROW
    WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
    EXECUTE FUNCTION update_parcel_status_on_payment();