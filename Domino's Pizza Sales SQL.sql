-- =====================================================
-- DATABASE: PostgreSQL
-- PROJECT: DOMINO'S PIZZA SALES ANALYSIS
-- =====================================================

DROP TABLE IF EXISTS pizza_sales;
CREATE TABLE pizza_sales (
    pizza_id           INTEGER,
    order_id           INTEGER,
    pizza_name_id      TEXT,
    quantity           NUMERIC(10,2),
    order_date         DATE,
    order_time         TIME,
    unit_price         NUMERIC(10,2),
    total_price        NUMERIC(10,2),
    pizza_size         TEXT,
    pizza_category     TEXT,
    pizza_ingredients  TEXT,
    pizza_name         TEXT
);







-- =====================================================
-- A. KPI’s
-- =====================================================

-- 1. Total Revenue
SELECT SUM(total_price) AS total_revenue
FROM pizza_sales;

-- 2. Average Order Value
SELECT 
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM pizza_sales;

-- 3. Total Pizzas Sold
SELECT SUM(quantity) AS total_pizzas_sold
FROM pizza_sales;

-- 4. Total Orders
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales;

-- 5. Average Pizzas Per Order
SELECT 
    ROUND(SUM(quantity)::numeric / COUNT(DISTINCT order_id), 2) AS avg_pizzas_per_order
FROM pizza_sales;


-- =====================================================
-- B. Daily Trend for Total Orders
-- =====================================================
SELECT 
    TO_CHAR(order_date, 'FMDay') AS order_day,
    COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY order_day
ORDER BY total_orders DESC;


-- =====================================================
-- C. Monthly Trend for Orders
-- =====================================================
SELECT 
    TO_CHAR(order_date, 'FMMonth') AS month_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY month_name
ORDER BY total_orders DESC;


-- =====================================================
-- D. % of Sales by Pizza Category
-- =====================================================
SELECT 
    pizza_category,
    ROUND(SUM(total_price), 2) AS total_revenue,
    ROUND(
        SUM(total_price) * 100.0 / (SELECT SUM(total_price) FROM pizza_sales),
        2
    ) AS pct
FROM pizza_sales
GROUP BY pizza_category
ORDER BY pct DESC;


-- =====================================================
-- E. % of Sales by Pizza Size
-- =====================================================
SELECT 
    pizza_size,
    ROUND(SUM(total_price), 2) AS total_revenue,
    ROUND(
        SUM(total_price) * 100.0 / (SELECT SUM(total_price) FROM pizza_sales),
        2
    ) AS pct
FROM pizza_sales
GROUP BY pizza_size
ORDER BY pizza_size;


-- =====================================================
-- F. Total Pizzas Sold by Pizza Category
-- =====================================================
SELECT 
    pizza_category,
    SUM(quantity) AS total_quantity_sold
FROM pizza_sales
GROUP BY pizza_category
ORDER BY total_quantity_sold DESC;


-- =====================================================
-- G. Top 5 Pizzas by Revenue
-- =====================================================
SELECT 
    pizza_name,
    SUM(total_price) AS total_revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_revenue DESC
LIMIT 5;


-- =====================================================
-- H. Bottom 5 Pizzas by Revenue
-- =====================================================
SELECT 
    pizza_name,
    SUM(total_price) AS total_revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_revenue ASC
LIMIT 5;


-- =====================================================
-- I. Top 5 Pizzas by Quantity
-- =====================================================
SELECT 
    pizza_name,
    SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_pizza_sold DESC
LIMIT 5;


-- =====================================================
-- J. Bottom 5 Pizzas by Quantity
-- =====================================================
SELECT 
    pizza_name,
    SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_pizza_sold ASC
LIMIT 5;


-- =====================================================
-- K. Top 5 Pizzas by Total Orders
-- =====================================================
SELECT 
    pizza_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_orders DESC
LIMIT 5;


-- =====================================================
-- L. Bottom 5 Pizzas by Total Orders
-- =====================================================
SELECT 
    pizza_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_orders ASC
LIMIT 5;


-- =====================================================
-- M. Hourly Trend for Orders (Peak Hours)
-- =====================================================
SELECT 
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_price) AS revenue
FROM pizza_sales
GROUP BY order_hour
ORDER BY total_orders DESC;


-- =====================================================
-- N. Day-Part Analysis (Morning / Afternoon / Evening / Night)
-- =====================================================
SELECT
    CASE 
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS day_part,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_price) AS revenue
FROM pizza_sales
GROUP BY day_part
ORDER BY revenue DESC;


-- =====================================================
-- O. Revenue per Month
-- =====================================================
SELECT 
    TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS month,
    SUM(total_price) AS total_revenue
FROM pizza_sales
GROUP BY month
ORDER BY month;


-- =====================================================
-- P. Revenue Contribution % by Pizza Name
-- =====================================================
SELECT 
    pizza_name,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(
        SUM(total_price) * 100.0 /
        (SELECT SUM(total_price) FROM pizza_sales),
        2
    ) AS percent_contribution
FROM pizza_sales
GROUP BY pizza_name
ORDER BY percent_contribution DESC;


-- =====================================================
-- Q. Month-over-Month Revenue Growth (%)
-- =====================================================
WITH monthly AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month_start,
        SUM(total_price) AS revenue
    FROM pizza_sales
    GROUP BY month_start
)
SELECT 
    TO_CHAR(month_start, 'YYYY-MM') AS month,
    revenue,
    LAG(revenue) OVER (ORDER BY month_start) AS previous_month,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month_start)) /
        NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0) * 100,
        2
    ) AS growth_percentage
FROM monthly
ORDER BY month_start;


-- =====================================================
-- R. Category-wise Revenue by Month
-- =====================================================
SELECT
    TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS month,
    pizza_category,
    SUM(total_price) AS revenue
FROM pizza_sales
GROUP BY month, pizza_category
ORDER BY month, revenue DESC;


-- =====================================================
-- S. Most Used Ingredients
-- =====================================================
SELECT 
    TRIM(ingredient) AS ingredient,
    COUNT(*) AS usage_count
FROM (
    SELECT UNNEST(string_to_array(pizza_ingredients, ', ')) AS ingredient
    FROM pizza_sales
) t
GROUP BY ingredient
ORDER BY usage_count DESC;


-- =====================================================
-- T. Revenue Distribution by Order (High / Medium / Low)
-- =====================================================
WITH order_vals AS (
    SELECT 
        order_id,
        SUM(total_price) AS order_value
    FROM pizza_sales
    GROUP BY order_id
)
SELECT 
    order_id,
    order_value,
    CASE 
        WHEN order_value >= 50 THEN 'High Value'
        WHEN order_value BETWEEN 20 AND 49.99 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS segment
FROM order_vals
ORDER BY order_value DESC;


-- =====================================================
-- U. Pizza Performance Index (PPI)
-- =====================================================
WITH metrics AS (
    SELECT
        pizza_name,
        SUM(total_price) AS revenue,
        SUM(quantity) AS qty,
        COUNT(DISTINCT order_id) AS orders
    FROM pizza_sales
    GROUP BY pizza_name
),
rnk AS (
    SELECT
        pizza_name,
        revenue,
        qty,
        orders,
        RANK() OVER (ORDER BY revenue DESC) AS rev_rank,
        RANK() OVER (ORDER BY qty DESC) AS qty_rank,
        RANK() OVER (ORDER BY orders DESC) AS ord_rank
    FROM metrics
)
SELECT
    pizza_name,
    revenue,
    qty,
    orders,
    ROUND((rev_rank + qty_rank + ord_rank) / 3.0, 2) AS performance_index
FROM rnk
ORDER BY performance_index;


-- =====================================================
-- V. Size-wise Share of Orders
-- =====================================================
SELECT 
    pizza_size,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM pizza_sales),
        2
    ) AS size_percentage
FROM pizza_sales
GROUP BY pizza_size
ORDER BY size_percentage DESC;


-- =====================================================
-- W. Highest Revenue Weekday
-- =====================================================
SELECT 
    TO_CHAR(order_date, 'FMDay') AS weekday,
    SUM(total_price) AS revenue
FROM pizza_sales
GROUP BY weekday
ORDER BY revenue DESC
LIMIT 1;