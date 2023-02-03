-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT(node_id)) FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT r.region_id, region_name, COUNT(*) AS node_count
FROM customer_nodes cn
JOIN regions r ON r.region_id = cn.node_id
GROUP BY r.region_id
ORDER BY r.region_id;

-- 3. How many customers are allocated to each region?
SELECT node_id, region_name, COUNT(customer_id) AS customer_count
FROM customer_nodes cn
JOIN regions r ON r.region_id = cn.node_id
GROUP BY cn.node_id
ORDER BY cn.node_id;

-- 4. How many days on average are customers reallocated to a different node?
WITH node_diff AS (
SELECT customer_id,node_id, start_date, end_date, (end_date-start_date) AS diff
FROM customer_nodes
WHERE end_date != '9999-12-31'
GROUP BY customer_id
ORDER BY customer_id
)

SELECT ROUND(AVG(SUM(diff)),2) FROM node_diff;


-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(*) AS unique_count, SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH deposit AS (
SELECT customer_id, txn_type, COUNT(*) AS txn_count, AVG(txn_amount) AS avg_amount
FROM customer_transactions 
GROUP BY customer_id, txn_type)

SELECT ROUND(AVG(txn_count),0) AS avg_deposit, ROUND(AVG(avg_amount),2) AS avg_amount 
FROM deposit
WHERE txn_type = 'deposit';

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_transactions AS (
  SELECT 
    customer_id, 
    MONTH(txn_date) AS month,
    SUM(CASE WHEN txn_type = 'deposit' THEN 0 ELSE 1 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 0 ELSE 1 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
  FROM data_bank.customer_transactions
  GROUP BY customer_id, month
 )

SELECT
  month,
  COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_transactions
WHERE deposit_count >= 2 
  AND (purchase_count > 1 OR withdrawal_count > 1)
GROUP BY month
ORDER BY month;
