-- ==============================================================================
-- PROJECT: E-Commerce Growth & Operations Analysis
-- FILE: 04_product_analysis.sql
-- PURPOSE: Product performance, sales speed, cross-selling and refunds
-- Requires 01_data_cleaning.sql to be run first (is_primary_item fix).
-- Product IDs: 1 = Mr. Fuzzy, 2 = Love Bear, 3 = Sugar Panda, 4 = Mini Bear
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- Q18 + Q19. Sales, revenue, profit and margin per product, plus sales speed
-- adjusted for time on sale.
-- Result: Mr. Fuzzy = 62% of revenue. Sugar Panda has the best margin (68.49%).
-- Per day on sale: Mr. Fuzzy 22.10, Mini Bear 12.30, Sugar Panda 10.77,
-- Love Bear 7.22.
-- ------------------------------------------------------------------------------
SELECT
    p.product_name                                    AS product_name,
    p.created_at::DATE                                AS launch_date,
    MAX(oi.created_at::DATE) - p.created_at::DATE + 1 AS days_on_sale,
    COUNT(*)                                          AS items_sold,
    ROUND(COUNT(*) * 1.0 / (MAX(oi.created_at::DATE) - p.created_at::DATE + 1), 2) AS items_per_day,
    SUM(oi.price_usd)                                 AS revenue,
    SUM(oi.cogs_usd)                                  AS cogs,
    SUM(oi.price_usd - oi.cogs_usd)                   AS profit,
    ROUND(SUM(oi.price_usd - oi.cogs_usd) * 100.00 / SUM(oi.price_usd), 2) AS profit_margin
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY product_name, p.created_at
ORDER BY launch_date;


-- ------------------------------------------------------------------------------
-- Q20. How often is each product sold as the main item vs as an add-on?
-- Result: Mini Bear is sold as an add-on 88.42% of the time; Mr. Fuzzy 1.51%.
-- ------------------------------------------------------------------------------
SELECT
    p.product_name                                            AS product_name,
    COUNT(*)                                                  AS total_items,
    COUNT(*) FILTER (WHERE oi.is_primary_item = TRUE)         AS as_primary,
    COUNT(*) FILTER (WHERE oi.is_primary_item = FALSE)        AS as_add_on,
    ROUND(COUNT(*) FILTER (WHERE oi.is_primary_item = FALSE) * 100.00 / COUNT(*), 2) AS add_on_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY product_name
ORDER BY add_on_pct DESC;


-- ------------------------------------------------------------------------------
-- Q21. For each main bear: add-on rate and which bear is added
-- Only orders from 2014-02-05, when all 4 products were on sale (fair comparison).
-- The add-on condition sits in ON (not WHERE) so orders without add-ons are kept.
-- Result: Mr. Fuzzy orders get add-ons most (38.26%); Mini Bear is the top
-- add-on for every main bear (60% of all add-ons).
-- ------------------------------------------------------------------------------
SELECT
    o.primary_product_id,
    COUNT(o.order_id)                                  AS total_orders_as_main,
    COUNT(oi.order_id)                                 AS orders_with_add_on,
    COUNT(*) FILTER (WHERE oi.product_id = 1)          AS add_fuzzy,
    COUNT(*) FILTER (WHERE oi.product_id = 2)          AS add_love_bear,
    COUNT(*) FILTER (WHERE oi.product_id = 3)          AS add_sugar_panda,
    COUNT(*) FILTER (WHERE oi.product_id = 4)          AS add_mini_bear,
    ROUND(COUNT(oi.order_id) * 100.00 / COUNT(o.order_id), 2) AS attach_rate_pct
FROM orders o
LEFT JOIN order_items oi
       ON o.order_id = oi.order_id
      AND oi.is_primary_item = FALSE
WHERE o.created_at >= '2014-02-05'
GROUP BY o.primary_product_id
ORDER BY attach_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- Q22. Refund rate and refunded money per product
-- Result: Sugar Panda has the highest refund rate (6.04%); Mr. Fuzzy accounts
-- for 72% of refunded money. Refunds total $85,339 (4.4% of revenue).
-- ------------------------------------------------------------------------------
SELECT
    p.product_name                         AS product_name,
    COUNT(*)                               AS items_sold,
    COUNT(oir.order_item_id)               AS items_refunded,
    ROUND(COUNT(oir.order_item_id) * 100.00 / COUNT(*), 2) AS refund_rate_pct,
    SUM(oir.refund_amount_usd)             AS refund_amount
FROM order_items oi
JOIN products p                 ON oi.product_id = p.product_id
LEFT JOIN order_item_refunds oir ON oir.order_item_id = oi.order_item_id
GROUP BY product_name
ORDER BY refund_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- Q23. Monthly refund rate per product
-- NULLIF(..., 0) avoids division by zero in months before a product launched.
-- ------------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', oi.created_at)::DATE AS month,
    ROUND(COUNT(oir.order_item_id) FILTER (WHERE oi.product_id = 1) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE oi.product_id = 1), 0), 2) AS fuzzy_refund_pct,
    ROUND(COUNT(oir.order_item_id) FILTER (WHERE oi.product_id = 2) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE oi.product_id = 2), 0), 2) AS love_bear_refund_pct,
    ROUND(COUNT(oir.order_item_id) FILTER (WHERE oi.product_id = 3) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE oi.product_id = 3), 0), 2) AS sugar_panda_refund_pct,
    ROUND(COUNT(oir.order_item_id) FILTER (WHERE oi.product_id = 4) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE oi.product_id = 4), 0), 2) AS mini_bear_refund_pct
FROM order_items oi
LEFT JOIN order_item_refunds oir ON oir.order_item_id = oi.order_item_id
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------------------------
-- Q23b. Is Mr. Fuzzy's September refund spike seasonal? Zoom into Aug-Oct.
-- Result: NOT seasonal. September 2013 was normal. Spikes in Sep 2012 (9.06%)
-- and Aug-Sep 2014 (peak 13.26%), back to normal by Oct 2014: likely
-- specific quality incidents that were resolved.
-- ------------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', oi.created_at)::DATE AS month,
    COUNT(*) FILTER (WHERE oi.product_id = 1) AS fuzzy_items_sold,
    ROUND(COUNT(oir.order_item_id) FILTER (WHERE oi.product_id = 1) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE oi.product_id = 1), 0), 2) AS fuzzy_refund_pct
FROM order_items oi
LEFT JOIN order_item_refunds oir ON oir.order_item_id = oi.order_item_id
WHERE EXTRACT(MONTH FROM oi.created_at) IN (8, 9, 10)
GROUP BY month
ORDER BY month;
