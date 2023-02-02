SELECT * FROM campaign_identifier;
SELECT * FROM event_identifier;
SELECT * FROM page_hierarchy;
SELECT * FROM users;
SELECT * FROM events;

-- A. Digital Analysis
-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) FROM users;

-- 2. How many cookies does each user have on average?
WITH cookies AS ( 
SELECT *, COUNT(DISTINCT cookie_id) AS cookie_count FROM users
GROUP BY user_id)

SELECT ROUND(AVG(cookie_count),0) AS cookies_avg FROM cookies;

-- 3. What is the unique number of visits by all users per month?
SELECT 
MONTH(event_time) AS month, 
COUNT(DISTINCT visit_id) FROM events
GROUP BY MONTH(event_time);

-- 4. What is the number of events for each event type?
SELECT event_type, COUNT(1) FROM events
GROUP BY event_type
ORDER BY event_type;

-- 5. What is the percentage of visits which have a purchase event?
SELECT 
ROUND(100 * COUNT(DISTINCT e.visit_id) / ( SELECT COUNT( DISTINCT visit_id) FROM events),1) AS percentage_of_visits
FROM events e
JOIN event_identifier ei
ON e.event_type = ei.event_type
WHERE event_type = 'Purchase';

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH checkout_purchase AS (
SELECT visit_id,
MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
FROM events
GROUP BY visit_id)

SELECT 
  ROUND(100*(1-(SUM(purchase)/SUM(checkout))),2) AS percentage_checkout_view_with_no_purchase
FROM checkout_purchase;

-- 7. What are the top 3 pages by number of views?
SELECT 
  page_name, 
  COUNT(*) AS page_views
FROM events AS e
JOIN page_hierarchy AS ph
ON e.page_id = ph.page_id
WHERE e.event_type = 1 
GROUP BY ph.page_name
ORDER BY page_views DESC 
LIMIT 3; 

-- 8. What is the number of views and cart adds for each product category?
SELECT 
  product_category, 
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM events AS e
JOIN page_hierarchy AS ph
  ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY page_views DESC;

-- 9. What are the top 3 products by purchases?
WITH cte AS( 
SELECT visit_id,
    SUM( CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_count,
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_count
  FROM events
  GROUP BY sequence_number)

SELECT
  e.visit_id,
  e.sequence_number,
  ei.event_name,
  ph.page_name
FROM
  events e
  JOIN event_identifier ei ON e.event_type = ei.event_type
  JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.visit_id IN (
    SELECT visit_id FROM cte
    WHERE cart_count > 0 AND purchase_count = 0)
ORDER BY sequence_number;
  
-- B. Product Funnel Analysis
WITH product_page_events AS (
  SELECT 
    e.visit_id,
    ph.product_id,
    ph.page_name AS product_name,
    ph.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view, -- 1 for Page View
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add -- 2 for Add Cart
  FROM events e
  JOIN page_hierarchy ph
    ON e.page_id = ph.page_id
  WHERE product_id IS NOT NULL
  GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),

purchase_events AS ( 
  SELECT DISTINCT visit_id
  FROM events
  WHERE event_type = 3 
),

combined_table AS ( 
  SELECT 
    ppe.visit_id, 
    ppe.product_id, 
    ppe.product_name, 
    ppe.product_category, 
    ppe.page_view, 
    ppe.cart_add,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
	FROM product_page_events ppe
	JOIN purchase_events pe
	ON ppe.visit_id = pe.visit_id
),

product_info AS (
  SELECT 
    product_name, 
    product_category, 
    SUM(page_view) AS views,
    SUM(cart_add) AS cart_adds, 
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_id, product_name, product_category)

SELECT * FROM product_info
ORDER BY product_id;

WITH product_page_events AS (
  SELECT 
    e.visit_id,
    ph.product_id,
    ph.page_name AS product_name,
    ph.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view, -- 1 for Page View
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add -- 2 for Add Cart
  FROM events e
  JOIN page_hierarchy ph
    ON e.page_id = ph.page_id
  WHERE product_id IS NOT NULL
  GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),
purchase_events AS (
  SELECT 
    DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3 
),
combined_table AS ( 
  SELECT 
    ppe.visit_id, 
    ppe.product_id, 
    ppe.product_name, 
    ppe.product_category, 
    ppe.page_view, 
    ppe.cart_add,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
  FROM product_page_events AS ppe
  LEFT JOIN purchase_events AS pe
    ON ppe.visit_id = pe.visit_id
),
product_category AS (
  SELECT 
    product_category, 
    SUM(page_view) AS views,
    SUM(cart_add) AS cart_adds, 
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_category)

SELECT * FROM product_category;

-- 1. Which product had the most views, cart adds and purchases?
(SELECT product_name, 'Most views' AS Type
  FROM product_info
  ORDER BY page_views DESC
  LIMIT 1)

UNION
  (SELECT product_name, 'Most cart adds' AS Type
    FROM product_info
    ORDER BY cart_adds DESC 
      LIMIT 1)

UNION
  (SELECT product_name, 'Most purhchases' AS Type
    FROM product_info
    ORDER BY purchases DESC
    LIMIT 1);
    
-- 2. Which product was most likely to be abandoned?
SELECT product_name,
  100 - ROUND(100 * purchases / cart_adds, 2) AS abandoned_rate
FROM product_info
ORDER BY 2 DESC
LIMIT 1;

-- 3. Which product had the highest view to purchase percentage?
SELECT 
  product_name, 
  product_category, 
  ROUND(100 * purchases/views,2) AS purchase_per_view_percentage
FROM product_info
ORDER BY purchase_per_view_percentage DESC;

-- 4. What is the average conversion rate from view to cart add?
SELECT ROUND(AVG(100 * cart_adds/page_views),2) AS average_view_to_cart_rate
FROM product_info;

-- 5. What is the average conversion rate from cart add to purchase?
SELECT 
  ROUND(100*AVG(cart_adds/views),2) AS avg_view_to_cart_add_conversion,
  ROUND(100*AVG(purchases/cart_adds),2) AS avg_cart_add_to_purchases_conversion_rate
FROM product_info;
