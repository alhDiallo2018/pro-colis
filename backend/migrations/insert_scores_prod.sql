-- =====================================================
-- INSERTION DES SCORES POUR LES UTILISATEURS DE PRODUCTION
-- =====================================================

-- 1. Insérer les scores pour chaque utilisateur
INSERT INTO scores (user_id, points, total_earned, total_spent) VALUES
    ('72f59e15-a5fc-4a0e-99eb-50f3d740a0a3', 5, 5, 0),  -- Alhassane Diallo (driver)
    ('92be5303-f6d3-4a82-81ef-3d714fe8e493', 5, 5, 0),  -- Chauffeur Test (driver)
    ('ce3941a7-f9e2-44b5-b245-d688cacc3ad9', 5, 5, 0),  -- assane (driver)
    ('67caa9af-8d22-4adf-bdca-6b7e95994e91', 5, 5, 0),  -- assane (driver)
    ('e9af595c-ee72-4fd0-89a5-7a2fa8ca05e3', 5, 5, 0),  -- Administrateur (super_admin)
    ('00000000-0000-0000-0000-000000000004', 5, 5, 0),  -- Client Test (client)
    ('5eceb151-5b98-4723-9386-7f9f568b5927', 5, 5, 0),  -- assane (driver)
    ('ecfc5a02-602c-48a0-ac2e-6b5ea86fba62', 5, 5, 0),  -- assane (driver)
    ('554d2ca1-4149-43fc-aeb0-07104ef48e62', 5, 5, 0),  -- assane (driver)
    ('74b6a05d-78ee-4d4a-af52-09b27d2fc7d1', 5, 5, 0),  -- assane (driver)
    ('a197013e-b292-4348-a0f8-b3059a0122d4', 5, 5, 0),  -- assane (driver)
    ('cbd40544-ac88-4a78-9dd5-e647c7fe934c', 5, 5, 0),  -- Ndao (driver)
    ('f86f43aa-e074-4268-9117-343632b82c8f', 5, 5, 0),  -- Jule (driver)
    ('1c4050e5-ff4f-4d7b-b30e-b85169a71820', 5, 5, 0),  -- alpha (driver)
    ('5c389d1b-015c-48ee-a0c8-0f3d9567187e', 5, 5, 0);  -- Fallou Ndao (driver)

-- 2. Insérer les transactions de bienvenue pour chaque utilisateur
INSERT INTO score_transactions (user_id, amount, type, description, balance_after) VALUES
    ('72f59e15-a5fc-4a0e-99eb-50f3d740a0a3', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('92be5303-f6d3-4a82-81ef-3d714fe8e493', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('ce3941a7-f9e2-44b5-b245-d688cacc3ad9', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('67caa9af-8d22-4adf-bdca-6b7e95994e91', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('e9af595c-ee72-4fd0-89a5-7a2fa8ca05e3', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('00000000-0000-0000-0000-000000000004', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('5eceb151-5b98-4723-9386-7f9f568b5927', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('ecfc5a02-602c-48a0-ac2e-6b5ea86fba62', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('554d2ca1-4149-43fc-aeb0-07104ef48e62', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('74b6a05d-78ee-4d4a-af52-09b27d2fc7d1', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('a197013e-b292-4348-a0f8-b3059a0122d4', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('cbd40544-ac88-4a78-9dd5-e647c7fe934c', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('f86f43aa-e074-4268-9117-343632b82c8f', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('1c4050e5-ff4f-4d7b-b30e-b85169a71820', 5, 'bonus', '🎉 Bonus de bienvenue', 5),
    ('5c389d1b-015c-48ee-a0c8-0f3d9567187e', 5, 'bonus', '🎉 Bonus de bienvenue', 5);

-- 3. Vérifier les insertions
SELECT 
    u.full_name,
    u.email,
    u.role,
    s.points,
    s.total_earned,
    s.total_spent,
    COUNT(st.id) as transaction_count
FROM users u
LEFT JOIN scores s ON u.id = s.user_id
LEFT JOIN score_transactions st ON u.id = st.user_id
WHERE u.id IN (
    '72f59e15-a5fc-4a0e-99eb-50f3d740a0a3',
    '92be5303-f6d3-4a82-81ef-3d714fe8e493',
    'ce3941a7-f9e2-44b5-b245-d688cacc3ad9',
    '67caa9af-8d22-4adf-bdca-6b7e95994e91',
    'e9af595c-ee72-4fd0-89a5-7a2fa8ca05e3',
    '00000000-0000-0000-0000-000000000004',
    '5eceb151-5b98-4723-9386-7f9f568b5927',
    'ecfc5a02-602c-48a0-ac2e-6b5ea86fba62',
    '554d2ca1-4149-43fc-aeb0-07104ef48e62',
    '74b6a05d-78ee-4d4a-af52-09b27d2fc7d1',
    'a197013e-b292-4348-a0f8-b3059a0122d4',
    'cbd40544-ac88-4a78-9dd5-e647c7fe934c',
    'f86f43aa-e074-4268-9117-343632b82c8f',
    '1c4050e5-ff4f-4d7b-b30e-b85169a71820',
    '5c389d1b-015c-48ee-a0c8-0f3d9567187e'
)
GROUP BY u.full_name, u.email, u.role, s.points, s.total_earned, s.total_spent
ORDER BY u.full_name;