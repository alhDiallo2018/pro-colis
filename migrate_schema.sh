#!/bin/bash

# Script pour ajouter uniquement les éléments manquants en production

PROD_URL="postgresql://procolis_user:gBHMPFBYrB1AER4cbGKh5c3jiR1LGdyL@dpg-d89i57mk1jcs73f2u8m0-a.oregon-postgres.render.com/procolis_db"

echo "🔍 Analyse des différences de structure..."

# Récupérer la liste des tables locales
psql -U testad -d procolis -t -c "SELECT tablename FROM pg_tables WHERE schemaname='public';" > /tmp/local_tables.txt

echo "📋 Tables locales trouvées:"
cat /tmp/local_tables.txt

# Pour chaque table, ajouter les colonnes manquantes
psql "$PROD_URL" << 'EOF'
DO $$
DECLARE
    _table text;
    _col text;
    _type text;
    _nullable text;
    _sql text;
BEGIN
    -- Pour chaque table locale
    FOR _table IN (SELECT tablename FROM pg_tables WHERE schemaname='public') 
    LOOP
        -- Ajouter les colonnes manquantes
        FOR _col, _type, _nullable IN 
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = _table AND table_schema = 'public'
            AND column_name NOT IN (
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = _table AND table_schema = 'public'
            )
        LOOP
            _sql := format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS %I %s %s', 
                _table, _col, _type,
                CASE WHEN _nullable = 'NO' THEN ' NOT NULL' ELSE '' END);
            EXECUTE _sql;
            RAISE NOTICE '✅ Ajout colonne: %.%', _table, _col;
        END LOOP;
    END LOOP;
END $$;
EOF

echo "✅ Migration terminée !"