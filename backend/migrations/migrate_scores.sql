-- =====================================================
-- MIGRATION DES TABLES DE SCORE VERS LA PRODUCTION
-- =====================================================

-- 1. TABLE scores
CREATE TABLE IF NOT EXISTS scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
    total_earned INTEGER NOT NULL DEFAULT 0 CHECK (total_earned >= 0),
    total_spent INTEGER NOT NULL DEFAULT 0 CHECK (total_spent >= 0),
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scores_user_id ON scores(user_id);
CREATE INDEX idx_scores_points ON scores(points DESC);
CREATE INDEX idx_scores_last_updated ON scores(last_updated DESC);

-- 2. TABLE score_transactions
CREATE TABLE IF NOT EXISTS score_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'parcel_creation',
        'parcel_acceptance', 
        'parcel_delivery',
        'purchase',
        'bonus',
        'refund'
    )),
    parcel_id UUID REFERENCES parcels(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (status IN (
        'pending',
        'completed',
        'failed',
        'refunded'
    )),
    reference VARCHAR(50) UNIQUE,
    metadata JSONB DEFAULT '{}'::jsonb,
    balance_after INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_user_id ON score_transactions(user_id);
CREATE INDEX idx_transactions_user_created ON score_transactions(user_id, created_at DESC);
CREATE INDEX idx_transactions_type ON score_transactions(type);
CREATE INDEX idx_transactions_parcel_id ON score_transactions(parcel_id);

-- 3. TABLE score_config
CREATE TABLE IF NOT EXISTS score_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

INSERT INTO score_config (key, value, description) VALUES
    ('welcome_bonus', '5', 'Points offerts a l''inscription'),
    ('parcel_creation_cost', '1', 'Points requis pour creer un colis'),
    ('parcel_acceptance_cost', '1', 'Points requis pour accepter un colis (chauffeur)'),
    ('parcel_delivery_cost', '1', 'Points requis pour livrer un colis (chauffeur)'),
    ('referral_bonus', '2', 'Points offerts pour parrainage'),
    ('price_per_point', '100', 'Prix en FCFA d''un point')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = NOW();

-- 4. Fonctions et Triggers
CREATE OR REPLACE FUNCTION update_scores_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_scores_updated_at ON scores;
CREATE TRIGGER trigger_scores_updated_at
    BEFORE UPDATE ON scores
    FOR EACH ROW
    EXECUTE FUNCTION update_scores_updated_at();

-- 5. Trigger de création de score à l'inscription
CREATE OR REPLACE FUNCTION create_score_for_new_user()
RETURNS TRIGGER AS $$
DECLARE
    welcome_bonus_value INTEGER;
BEGIN
    SELECT value::INTEGER INTO welcome_bonus_value
    FROM score_config 
    WHERE key = 'welcome_bonus';
    
    IF welcome_bonus_value IS NULL THEN
        welcome_bonus_value := 5;
    END IF;

    INSERT INTO scores (user_id, points, total_earned)
    VALUES (NEW.id, welcome_bonus_value, welcome_bonus_value);
    
    INSERT INTO score_transactions (
        user_id,
        amount,
        type,
        description,
        balance_after
    ) VALUES (
        NEW.id,
        welcome_bonus_value,
        'bonus',
        '🎉 Bonus de bienvenue',
        welcome_bonus_value
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_score_on_user_creation ON users;
CREATE TRIGGER trigger_create_score_on_user_creation
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_score_for_new_user();

-- 6. Vues
CREATE OR REPLACE VIEW score_stats AS
SELECT 
    COUNT(*) AS total_users_with_score,
    COALESCE(SUM(points), 0) AS total_points,
    COALESCE(AVG(points), 0) AS average_points,
    COALESCE(SUM(total_earned), 0) AS total_earned,
    COALESCE(SUM(total_spent), 0) AS total_spent
FROM scores;

CREATE OR REPLACE VIEW score_ranking AS
SELECT 
    s.user_id,
    u.full_name,
    u.email,
    s.points,
    s.total_earned,
    s.total_spent,
    RANK() OVER (ORDER BY s.points DESC) AS rank
FROM scores s
JOIN users u ON u.id = s.user_id
WHERE u.status = 'active';

-- 7. Ajout des colonnes à parcels
ALTER TABLE parcels 
ADD COLUMN IF NOT EXISTS score_debited BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS score_refunded BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_parcels_score_debited ON parcels(score_debited);
CREATE INDEX IF NOT EXISTS idx_parcels_score_refunded ON parcels(score_refunded);