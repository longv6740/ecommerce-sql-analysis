-- ==============================================================================
-- PROJECT: E-Commerce Growth & Operations Analysis
-- FILE: 02_business_overview.sql
-- PURPOSE: Overall performance, growth, seasonality and traffic channels
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- Q1. What are total orders, total revenue and average order value (AOV)?
-- Result: 32,313 orders | $1,938,509.75 revenue | AOV $59.99
-- ------------------------------------------------------------------------------
SELECT
    COUNT(*)                   AS total_order,
    SUM(price_usd)             AS total_revenue,
    ROUND(AVG(price_usd), 2)   AS aov
FROM orders;


-- ------------------------------------------------------------------------------
-- Q2. How did orders, revenue and AOV change each year?
-- Note: 2012 and 2015 are partial years (see Q3).
-- ------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM created_at)  AS year,
    COUNT(*)                       AS total_order,
    SUM(price_usd)                 AS total_revenue,
    ROUND(AVG(price_usd), 2)       AS aov
FROM orders
GROUP BY year
ORDER BY year;


-- ------------------------------------------------------------------------------
-- Q3. What is the first and last order date in each year?
-- Result: data runs 2012-03-19 to 2015-03-19. Only 2013 and 2014 are full years.
-- ------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM created_at)  AS year,
    COUNT(*)                       AS total_order,
    SUM(price_usd)                 AS total_revenue,
    MIN(created_at)                AS first_date,
    MAX(created_at)                AS last_date
FROM orders
GROUP BY year
ORDER BY year;


-- ------------------------------------------------------------------------------
-- Q4. How many orders per day in each year? (fair comparison for partial years)
-- Result: 8.98 -> 20.40 -> 46.19 -> 69.49 orders/day
-- ------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM created_at)  AS year,
    COUNT(*)                       AS total_order,
    MIN(created_at)                AS first_date,
    MAX(created_at)                AS last_date,
    MAX(created_at::DATE) - MIN(created_at::DATE) + 1  AS days_in_dataset,
    ROUND(COUNT(*) * 1.0 / (MAX(created_at::DATE) - MIN(created_at::DATE) + 1), 2) AS orders_per_day
FROM orders
GROUP BY year
ORDER BY year;


-- ------------------------------------------------------------------------------
-- Q5. How many orders and how much revenue each month? (seasonality)
-- Result: Nov-Dec peaks every year; small Valentine's bump in February.
-- ------------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', o.created_at)::DATE  AS months,
    SUM(o.price_usd)                         AS monthly_revenue,
    COUNT(*)                                 AS monthly_orders
FROM orders o
GROUP BY months
ORDER BY months;


-- ------------------------------------------------------------------------------
-- Q6. Sessions, orders and conversion rate by year
-- Result: conversion rose from 4.14% (2012) to 8.44% (2015)
-- ------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM ws.created_at)  AS year,
    COUNT(*)                          AS total_website_session,
    COUNT(o.order_id)                 AS total_order,
    ROUND(COUNT(o.order_id) * 100.00 / COUNT(*), 2) AS conversion_rate
FROM website_sessions ws
LEFT JOIN orders o ON o.website_session_id = ws.website_session_id
GROUP BY year
ORDER BY year;


-- ------------------------------------------------------------------------------
-- Q7. Sessions, orders and conversion rate by traffic channel
-- Requires 01_data_cleaning.sql to be run first.
-- Result: 82% of traffic is paid (gsearch alone 67%); organic converts best
-- (7.51%); socialbook converts worst (3.21%).
-- ------------------------------------------------------------------------------
SELECT
    CASE
        WHEN utm_source IS NULL AND http_referer IS NULL     THEN 'direct'
        WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
        ELSE utm_source
    END AS channel,
    COUNT(*)                                         AS total_session,
    COUNT(o.order_id)                                AS total_orders,
    ROUND(COUNT(o.order_id) * 100.00 / COUNT(*), 2)  AS conversion_rate
FROM website_sessions ws
LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
GROUP BY channel
ORDER BY total_session DESC;


-- ------------------------------------------------------------------------------
-- Q8. Share of free traffic (organic + direct) by year
-- Result: 9.21% (2012) -> 23.23% (2015)
-- ------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM created_at)  AS year,
    COUNT(*) FILTER (WHERE utm_source IS NULL AND http_referer IS NULL)     AS direct,
    COUNT(*) FILTER (WHERE utm_source IS NULL AND http_referer IS NOT NULL) AS organic_search,
    ROUND(COUNT(*) FILTER (WHERE utm_source IS NULL) * 100.00 / COUNT(*), 2) AS free_rate
FROM website_sessions
GROUP BY year
ORDER BY year;
