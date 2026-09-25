-- ==============================================================================
-- PROJECT: E-Commerce Growth & Operations Analysis
-- FILE: 03_funnel_and_landing_pages.sql
-- PURPOSE: Device performance, website funnel, billing A/B test, landing pages
-- Requires 01_data_cleaning.sql to be run first.
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- Q9. Sessions, orders and conversion rate by year and device
-- Result: desktop converts ~3x better than mobile (10.59% vs 3.50% in 2015).
-- Mobile = 30% of sessions but only 13% of orders.
-- ------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM ws.created_at)  AS year,
    ws.device_type                    AS device_type,
    COUNT(*)                          AS total_sessions,
    COUNT(o.order_id)                 AS total_orders,
    ROUND(COUNT(o.order_id) * 100.00 / COUNT(*), 2) AS conversion_rate
FROM website_sessions ws
LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
GROUP BY year, device_type
ORDER BY year, device_type;


-- ------------------------------------------------------------------------------
-- Q10. Which pages exist, and how many sessions reached each one?
-- Audit finding: total_views = sessions_reached for every page,
-- so there are no duplicate pageviews within a session.
-- ------------------------------------------------------------------------------
SELECT
    pageview_url                        AS page_url,
    COUNT(*)                            AS total_views,
    COUNT(DISTINCT website_session_id)  AS sessions_reached
FROM website_pageviews
GROUP BY pageview_url
ORDER BY sessions_reached DESC;


-- ------------------------------------------------------------------------------
-- Q11 + Q12. Funnel: sessions reaching each step, and step-to-step rates
-- Result: 472,871 -> 261,231 -> 210,214 -> 94,953 -> 64,484 -> 52,058 -> 32,313
-- Biggest leaks: product page -> cart (45.17%), landing -> products (55.24%).
-- ------------------------------------------------------------------------------
WITH funnel AS (
    SELECT
        COUNT(DISTINCT website_session_id) AS landing,
        COUNT(DISTINCT website_session_id) FILTER (WHERE pageview_url = '/products') AS products,
        COUNT(DISTINCT website_session_id) FILTER (WHERE pageview_url IN (
            '/the-original-mr-fuzzy', '/the-forever-love-bear',
            '/the-birthday-sugar-panda', '/the-hudson-river-mini-bear')) AS product_page,
        COUNT(DISTINCT website_session_id) FILTER (WHERE pageview_url = '/cart')          AS cart,
        COUNT(DISTINCT website_session_id) FILTER (WHERE pageview_url = '/shipping')      AS shipping,
        COUNT(DISTINCT website_session_id) FILTER (WHERE pageview_url LIKE '/billing%')   AS billing,
        COUNT(DISTINCT website_session_id) FILTER (WHERE pageview_url = '/thank-you-for-your-order') AS thank_you
    FROM website_pageviews
)
SELECT
    landing, products, product_page, cart, shipping, billing, thank_you,
    ROUND(products     * 100.0 / landing,      2) AS to_products_pct,
    ROUND(product_page * 100.0 / products,     2) AS to_product_page_pct,
    ROUND(cart         * 100.0 / product_page, 2) AS to_cart_pct,
    ROUND(shipping     * 100.0 / cart,         2) AS to_shipping_pct,
    ROUND(billing      * 100.0 / shipping,     2) AS to_billing_pct,
    ROUND(thank_you    * 100.0 / billing,      2) AS to_order_pct
FROM funnel;


-- ------------------------------------------------------------------------------
-- Q13a. Billing pages over their full lifetime (NOT a fair comparison)
-- /billing ran 2012-03-19 to 2013-01-05; /billing-2 ran 2012-09-10 to 2015-03-19,
-- during years when overall conversion was higher.
-- ------------------------------------------------------------------------------
SELECT
    wp.pageview_url,
    COUNT(DISTINCT wp.website_session_id)  AS sessions,
    COUNT(DISTINCT o.website_session_id)   AS orders,
    ROUND(COUNT(DISTINCT o.website_session_id) * 100.00 / COUNT(DISTINCT wp.website_session_id), 2) AS conversion_rate,
    MIN(wp.created_at)::DATE               AS first_seen,
    MAX(wp.created_at)::DATE               AS last_seen
FROM website_pageviews wp
LEFT JOIN orders o ON o.website_session_id = wp.website_session_id
WHERE wp.pageview_url LIKE '/billing%'
GROUP BY wp.pageview_url;


-- ------------------------------------------------------------------------------
-- Q13b. Billing A/B test: only the period when both pages ran (fair comparison)
-- Result: /billing 45.10% vs /billing-2 62.10% (~1,660 sessions each)
-- ------------------------------------------------------------------------------
SELECT
    wp.pageview_url,
    COUNT(DISTINCT wp.website_session_id)  AS sessions,
    COUNT(DISTINCT o.website_session_id)   AS orders,
    ROUND(COUNT(DISTINCT o.website_session_id) * 100.00 / COUNT(DISTINCT wp.website_session_id), 2) AS conversion_rate,
    MIN(wp.created_at)::DATE               AS first_seen,
    MAX(wp.created_at)::DATE               AS last_seen
FROM website_pageviews wp
LEFT JOIN orders o ON o.website_session_id = wp.website_session_id
WHERE wp.pageview_url LIKE '/billing%'
  AND wp.created_at >= '2012-09-10'
  AND wp.created_at <  '2013-01-06'
GROUP BY wp.pageview_url;


-- ------------------------------------------------------------------------------
-- Q14. Landing pages: sessions, orders, conversion and dates used
-- ------------------------------------------------------------------------------
SELECT
    wp.pageview_url                        AS landing_page,
    COUNT(DISTINCT wp.website_session_id)  AS sessions,
    COUNT(DISTINCT o.website_session_id)   AS orders,
    ROUND(COUNT(DISTINCT o.website_session_id) * 100.00 / COUNT(DISTINCT wp.website_session_id), 2) AS conversion_rate,
    MIN(wp.created_at)::DATE               AS first_seen,
    MAX(wp.created_at)::DATE               AS last_seen
FROM website_pageviews wp
LEFT JOIN orders o ON o.website_session_id = wp.website_session_id
WHERE (wp.pageview_url = '/home' OR wp.pageview_url LIKE '/lander%')
GROUP BY wp.pageview_url
ORDER BY first_seen;


-- ------------------------------------------------------------------------------
-- Q15. Which traffic channels did each landing page receive?
-- Result: channel mix does NOT explain lander-3's low conversion (86% gsearch,
-- similar to lander-2). Free traffic (organic + direct) lands on /home.
-- ------------------------------------------------------------------------------
SELECT
    wp.pageview_url AS landing_page,
    CASE
        WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL     THEN 'direct'
        WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN 'organic_search'
        ELSE ws.utm_source
    END AS channel,
    COUNT(*) AS sessions
FROM website_pageviews wp
JOIN website_sessions ws ON ws.website_session_id = wp.website_session_id
WHERE (wp.pageview_url = '/home' OR wp.pageview_url LIKE '/lander%')
GROUP BY landing_page, channel
ORDER BY landing_page, sessions DESC;


-- ------------------------------------------------------------------------------
-- Q16. Which devices did each landing page receive?
-- Result: lander-3 = 100% mobile; lander-4 and lander-5 = 100% desktop.
-- ------------------------------------------------------------------------------
SELECT
    wp.pageview_url  AS landing_page,
    ws.device_type   AS device_type,
    COUNT(*)         AS sessions
FROM website_pageviews wp
JOIN website_sessions ws ON ws.website_session_id = wp.website_session_id
WHERE (wp.pageview_url = '/home' OR wp.pageview_url LIKE '/lander%')
GROUP BY landing_page, device_type
ORDER BY landing_page, sessions DESC;


-- ------------------------------------------------------------------------------
-- Q17. Landing page conversion within the same device (fair comparison)
-- Result: lander-3 is the BEST mobile page (3.39% vs 2.96% for /home on mobile).
-- ------------------------------------------------------------------------------
SELECT
    wp.pageview_url                        AS landing_page,
    ws.device_type                         AS device_type,
    COUNT(DISTINCT ws.website_session_id)  AS sessions,
    COUNT(DISTINCT o.website_session_id)   AS orders,
    ROUND(COUNT(DISTINCT o.website_session_id) * 100.00 / COUNT(DISTINCT ws.website_session_id), 2) AS conversion_rate,
    MIN(wp.created_at)::DATE               AS first_seen,
    MAX(wp.created_at)::DATE               AS last_seen
FROM website_pageviews wp
JOIN website_sessions ws ON ws.website_session_id = wp.website_session_id
LEFT JOIN orders o       ON o.website_session_id  = wp.website_session_id
WHERE (wp.pageview_url = '/home' OR wp.pageview_url LIKE '/lander%')
GROUP BY landing_page, device_type
ORDER BY device_type, conversion_rate DESC;
