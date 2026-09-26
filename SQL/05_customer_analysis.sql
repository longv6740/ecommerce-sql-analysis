-- ==============================================================================
-- PROJECT: E-Commerce Growth & Operations Analysis
-- FILE: 05_customer_analysis.sql
-- PURPOSE: Repeat purchases, return visits and customer value
-- Requires 01_data_cleaning.sql to be run first (is_repeat_session fix).
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- Q24. How many customers ordered once, twice, three times?
-- Result: 98.14% order once; only 591 of 31,696 customers (1.86%) reorder.
-- ------------------------------------------------------------------------------
WITH customer_orders AS (
    SELECT
        user_id    AS customer_id,
        COUNT(*)   AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    total_orders                  AS orders_per_customer,
    COUNT(customer_id)            AS customers,
    ROUND(COUNT(customer_id) * 100.00 / (SELECT COUNT(*) FROM customer_orders), 2) AS pct_of_customers
FROM customer_orders
GROUP BY orders_per_customer
ORDER BY orders_per_customer;


-- ------------------------------------------------------------------------------
-- Q25. First visits vs return visits: conversion and free-traffic share
-- Result: return visits are 17% of sessions, 66.62% come through free channels
-- (vs 7.86% for first visits), convert better (7.83% vs 6.64%) and bring
-- 6,149 orders (19% of all orders).
-- ------------------------------------------------------------------------------
SELECT
    ws.is_repeat_session,
    COUNT(DISTINCT ws.website_session_id)  AS total_sessions,
    COUNT(o.website_session_id)            AS total_orders,
    ROUND(COUNT(o.website_session_id) * 100.00 / COUNT(DISTINCT ws.website_session_id), 2) AS conversion_rate_pct,
    ROUND(COUNT(DISTINCT ws.website_session_id) FILTER (WHERE ws.utm_source IS NULL) * 100.00
          / COUNT(DISTINCT ws.website_session_id), 2) AS free_traffic_pct
FROM website_sessions ws
LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
GROUP BY ws.is_repeat_session;


-- ------------------------------------------------------------------------------
-- Q26. For repeat customers: days between first and last order
-- HAVING keeps only customers with 2+ orders (filters groups after GROUP BY).
-- Result: 591 customers, median 33 days, average 37, min 2, max 118.
-- ------------------------------------------------------------------------------
WITH repeat_customers AS (
    SELECT
        user_id,
        COUNT(*)                                        AS total_orders,
        MAX(created_at::DATE) - MIN(created_at::DATE)   AS days_between
    FROM orders
    GROUP BY user_id
    HAVING COUNT(*) >= 2
)
SELECT
    COUNT(*)                                               AS repeat_customers,
    ROUND(AVG(days_between), 1)                            AS avg_days,
    MIN(days_between)                                      AS min_days,
    MAX(days_between)                                      AS max_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_between) AS median_days
FROM repeat_customers;


-- ------------------------------------------------------------------------------
-- Q27. One-time vs repeat customers: revenue and value per customer
-- Result: repeat customers are worth $125.81 vs $59.93 (2.1x), but bring
-- only 3.84% of revenue.
-- ------------------------------------------------------------------------------
WITH revenue_calc AS (
    SELECT
        user_id           AS customer_id,
        COUNT(*)          AS total_orders,
        SUM(price_usd)    AS revenue
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_orders = 1  THEN 'one_time'
        WHEN total_orders >= 2 THEN 'repeat'
    END                                        AS customer_type,
    COUNT(*)                                   AS customers,
    SUM(revenue)                               AS total_revenue,
    ROUND(SUM(revenue) / COUNT(*), 2)          AS revenue_per_customer,
    ROUND(SUM(revenue) * 100.00 / (SELECT SUM(price_usd) FROM orders), 2) AS pct_of_revenue
FROM revenue_calc
GROUP BY customer_type;
