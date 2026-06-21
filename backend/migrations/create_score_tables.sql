-- =====================================================
-- TABLE scores
-- =====================================================
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

CREATE INDEX IF NOT EXISTS idx_scores_user_id ON scores(user_id);
CREATE INDEX IF NOT EXISTS idx_scores_points ON scores(points DESC);
CREATE INDEX IF NOT EXISTS idx_scores_last_updated ON scores(last_updated DESC);

-- Trigger pour mettre à jour updated_at
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

-- =====================================================
-- TABLE score_transactions
-- =====================================================
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

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON score_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON score_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON score_transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON score_transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_parcel_id ON score_transactions(parcel_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON score_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON score_transactions(reference);
CREATE INDEX IF NOT EXISTS idx_transactions_user_type ON score_transactions(user_id, type);
CREATE INDEX IF NOT EXISTS idx_transactions_user_status ON score_transactions(user_id, status);

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_transactions_updated_at ON score_transactions;
CREATE TRIGGER trigger_transactions_updated_at
    BEFORE UPDATE ON score_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_transactions_updated_at();

-- =====================================================
-- TABLE score_config
-- =====================================================
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

-- =====================================================
-- TRIGGER: Création automatique du score à l'inscription
-- =====================================================
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

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- ✅ CORRECTION: Les paramètres par défaut doivent être à la fin
-- Fonction pour débiter des points
CREATE OR REPLACE FUNCTION debit_points(
    p_user_id UUID,
    p_amount INTEGER,
    p_type VARCHAR(50),
    p_description TEXT,
    p_parcel_id UUID DEFAULT NULL  -- Paramètre avec default à la fin
)
RETURNS TABLE(
    success BOOLEAN,
    new_balance INTEGER,
    transaction_id UUID
) AS $$
DECLARE
    current_balance INTEGER;
    v_transaction_id UUID;
BEGIN
    SELECT points INTO current_balance
    FROM scores
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Utilisateur non trouve';
    END IF;
    
    IF current_balance < p_amount THEN
        RAISE EXCEPTION 'Points insuffisants. Solde: %, requis: %', current_balance, p_amount;
    END IF;
    
    UPDATE scores
    SET 
        points = points - p_amount,
        total_spent = total_spent + p_amount,
        last_updated = NOW()
    WHERE user_id = p_user_id
    RETURNING points INTO current_balance;
    
    INSERT INTO score_transactions (
        user_id,
        amount,
        type,
        parcel_id,
        description,
        balance_after
    ) VALUES (
        p_user_id,
        -p_amount,
        p_type,
        p_parcel_id,
        p_description,
        current_balance
    ) RETURNING id INTO v_transaction_id;
    
    IF p_parcel_id IS NOT NULL AND p_type = 'parcel_creation' THEN
        UPDATE parcels SET score_debited = true WHERE id = p_parcel_id;
    END IF;
    
    RETURN QUERY SELECT true, current_balance, v_transaction_id;
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT false, NULL::INTEGER, NULL::UUID;
END;
$$ LANGUAGE plpgsql;

-- ✅ CORRECTION: Les paramètres par défaut doivent être à la fin
-- Fonction pour créditer des points
CREATE OR REPLACE FUNCTION credit_points(
    p_user_id UUID,
    p_amount INTEGER,
    p_type VARCHAR(50),
    p_description TEXT,
    p_parcel_id UUID DEFAULT NULL  -- Paramètre avec default à la fin
)
RETURNS TABLE(
    success BOOLEAN,
    new_balance INTEGER,
    transaction_id UUID
) AS $$
DECLARE
    current_balance INTEGER;
    v_transaction_id UUID;
BEGIN
    UPDATE scores
    SET 
        points = points + p_amount,
        total_earned = total_earned + p_amount,
        last_updated = NOW()
    WHERE user_id = p_user_id
    RETURNING points INTO current_balance;
    
    IF NOT FOUND THEN
        INSERT INTO scores (user_id, points, total_earned)
        VALUES (p_user_id, p_amount, p_amount)
        RETURNING points INTO current_balance;
    END IF;
    
    INSERT INTO score_transactions (
        user_id,
        amount,
        type,
        parcel_id,
        description,
        balance_after
    ) VALUES (
        p_user_id,
        p_amount,
        p_type,
        p_parcel_id,
        p_description,
        current_balance
    ) RETURNING id INTO v_transaction_id;
    
    RETURN QUERY SELECT true, current_balance, v_transaction_id;
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT false, NULL::INTEGER, NULL::UUID;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VUES POUR LES STATISTIQUES
-- =====================================================

-- Vue pour les statistiques globales des points
CREATE OR REPLACE VIEW score_stats AS
SELECT 
    COUNT(*) AS total_users_with_score,
    COALESCE(SUM(points), 0) AS total_points,
    COALESCE(AVG(points), 0) AS average_points,
    COALESCE(SUM(total_earned), 0) AS total_earned,
    COALESCE(SUM(total_spent), 0) AS total_spent
FROM scores;

-- Vue pour le classement des utilisateurs
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