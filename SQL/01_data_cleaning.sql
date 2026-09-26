-- ==============================================================================
-- PROJECT: E-Commerce Growth & Operations Analysis
-- FILE: 01_data_cleaning.sql
-- PURPOSE: Audit and clean website_sessions before analysis
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- AUDIT: Were empty values imported as real NULLs or as the text 'NULL'?
-- Finding: 0 real NULLs. 83,328 rows in utm_source and 39,917 rows in
-- http_referer contained the TEXT 'NULL', which breaks IS NULL checks.
-- ------------------------------------------------------------------------------
SELECT
    COUNT(*) FILTER (WHERE utm_source IS NULL)     AS real_null_source,
    COUNT(*) FILTER (WHERE utm_source = 'NULL')    AS text_null_source,
    COUNT(*) FILTER (WHERE http_referer IS NULL)   AS real_null_referer,
    COUNT(*) FILTER (WHERE http_referer = 'NULL')  AS text_null_referer
FROM website_sessions;


-- ------------------------------------------------------------------------------
-- CLEAN: Convert text 'NULL' into real NULL (inside a transaction for safety)
-- NULLIF(x, 'NULL') returns NULL when x = 'NULL', otherwise keeps x unchanged.
-- ------------------------------------------------------------------------------
BEGIN;

UPDATE website_sessions
SET utm_source   = NULLIF(utm_source, 'NULL'),
    utm_campaign = NULLIF(utm_campaign, 'NULL'),
    utm_content  = NULLIF(utm_content, 'NULL'),
    http_referer = NULLIF(http_referer, 'NULL');

-- Re-run the audit query above: text_null columns must be 0 before committing.
COMMIT;


-- ------------------------------------------------------------------------------
-- AUDIT 2: Is the is_primary_item flag in order_items usable?
-- Finding: all 40,025 rows were FALSE after import, which is impossible
-- (every order must have exactly one primary item).
-- ------------------------------------------------------------------------------
SELECT is_primary_item, COUNT(*)
FROM order_items
GROUP BY is_primary_item;


-- ------------------------------------------------------------------------------
-- CLEAN 2: Rebuild is_primary_item from orders.primary_product_id
-- An item is primary when its product is the order's primary product.
-- Verified after the update: TRUE = 32,313 (one per order), FALSE = 7,712
-- (= 40,025 items - 32,313 orders).
-- ------------------------------------------------------------------------------
BEGIN;

UPDATE order_items oi
SET is_primary_item = (oi.product_id = o.primary_product_id)
FROM orders o
WHERE oi.order_id = o.order_id;

-- Re-run AUDIT 2: expect TRUE = 32,313 and FALSE = 7,712 before committing.
COMMIT;


-- ------------------------------------------------------------------------------
-- AUDIT 3: Is the is_repeat_session flag in website_sessions usable?
-- Finding: all 472,871 sessions were FALSE after import, the same boolean
-- import bug as is_primary_item (all boolean columns were affected).
-- ------------------------------------------------------------------------------
SELECT is_repeat_session, COUNT(*)
FROM website_sessions
GROUP BY is_repeat_session;


-- ------------------------------------------------------------------------------
-- CLEAN 3: Rebuild is_repeat_session from each user's first session
-- A session is a repeat if it is not the user's first (smallest) session id.
-- Verified: FALSE = 394,318 (= distinct users, one first visit each),
-- TRUE = 78,553 (= sessions - users).
-- ------------------------------------------------------------------------------
BEGIN;

UPDATE website_sessions ws
SET is_repeat_session = (ws.website_session_id <> f.first_session_id)
FROM (SELECT user_id, MIN(website_session_id) AS first_session_id
      FROM website_sessions
      GROUP BY user_id) f
WHERE ws.user_id = f.user_id;

-- Re-run AUDIT 3 and compare FALSE with COUNT(DISTINCT user_id) before committing.
COMMIT;
