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
