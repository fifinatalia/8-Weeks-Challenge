SELECT * FROM interest_map;
SELECT * FROM interest_metrics;
SELECT * FROM json_data;

## Data Exploration and Cleansing

-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT month_year, COUNT(*)
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
SELECT 
  ROUND(100 * (SUM(CASE WHEN interest_id IS NULL THEN 1 END) * 1.0 / COUNT(*)),2) AS null_perc
FROM interest_metrics;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT 
  COUNT(DISTINCT ma.id) AS map_id_count,
  COUNT(DISTINCT me.interest_id) AS metrics_id_count,
  SUM(CASE WHEN ma.id is NULL THEN 1 END) AS not_in_metric,
  SUM(CASE WHEN .interest_id is NULL THEN 1 END) AS not_in_map
FROM interest_map ma
FULL OUTER JOIN interest_metrics me
ON ma.interest_id = me.id;

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT 
  id, 
  interest_name, 
  COUNT(*)
FROM interest_map ma
JOIN interest_metrics me
ON ma.id = me.interest_id
GROUP BY id, interest_name
ORDER BY count DESC, id;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
SELECT *
FROM interest_map ma
INNER JOIN interest_metrics me
  ON ma.id = me.interest_id
WHERE me.interest_id = 21246   
  AND me._month IS NOT NULL;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT 
  COUNT(*)
FROM interest_map ma
JOIN interest_metrics me
  ON ma.id = me.interest_id
WHERE me.month_year < ma.created_at;
