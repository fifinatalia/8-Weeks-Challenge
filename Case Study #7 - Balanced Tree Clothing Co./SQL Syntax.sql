SELECT * FROM product_details;
SELECT * FROM product_hierarchy;
SELECT * FROM product_prices;
SELECT * FROM sales;

## High Level Sales Analysis
  
-- 1. What was the total quantity sold for all products?
SELECT 
  pd.product_name,
  SUM(s.qty) AS total_qty
FROM sales s
JOIN product_details pd ON s.prod_id = pd.product_id
GROUP BY product_id
ORDER BY qty DESC;

-- 2. What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS total_rev
FROM sales;

-- 3. What was the total discount amount for all products?
SELECT ROUND(SUM(qty * price * discount/ 100), 2) AS total_discount_amount
FROM sales;

## Transaction Analysis
  
-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id)
FROM sales;
  
-- 2. What is the average unique products purchased in each transaction?
WITH cte AS(
  SELECT COUNT(DISTINCT prod_id) AS frequency
  FROM sales
  GROUP BY txn_id)
  
SELECT CEILING(AVG(frequency)) avg_unique_product_per_transaction
FROM cte;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

-- 4. What is the average discount value per transaction?\
WITH cte AS( 
SELECT SUM((discount/ 100) * price * qty) AS total_revenue
  FROM sales
  GROUP BY txn_id)
  
SELECT ROUND(AVG(total_revenue), 2) avg_discount_per_transaction
FROM cte;
  
-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT
  member,
  COUNT(DISTINCT txn_id) AS frequency,
  ROUND(100 *(COUNT(DISTINCT txn_id) / SUM(COUNT(DISTINCT txn_id)) OVER()),2) AS percentage
FROM sales
GROUP BY member;

-- 6. What is the average revenue for member transactions and non-member transactions?
WITH cte AS(
  SELECT
    txn_id,
    member,
    SUM((1 - discount/ 100) * price * qty) AS total_revenue
  FROM sales
  GROUP BY prod_id)

SELECT member,
  ROUND(AVG(total_revenue), 2) AS avg_rev_by_member
FROM cte
GROUP BY prod_id;
