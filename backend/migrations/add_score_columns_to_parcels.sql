-- backend/migrations/add_score_columns_to_parcels.sql

-- Ajouter les colonnes pour le suivi des points dans les colis
ALTER TABLE parcels 
ADD COLUMN IF NOT EXISTS score_debited BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS score_refunded BOOLEAN DEFAULT FALSE;

-- Index pour les requêtes
CREATE INDEX IF NOT EXISTS idx_parcels_score_debited ON parcels(score_debited);
CREATE INDEX IF NOT EXISTS idx_parcels_score_refunded ON parcels(score_refunded);

-- Commentaires pour documentation
COMMENT ON COLUMN parcels.score_debited IS 'Indique si les points ont été débités pour ce colis';
COMMENT ON COLUMN parcels.score_refunded IS 'Indique si les points ont été remboursés pour ce colis';