-- Data Exploration and Cleansing
-- Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

ALTER TABLE fresh_segments.interest_metrics 
MODIFY COLUMN month_year VARCHAR(10);


UPDATE fresh_segments.interest_metrics
SET month_year = STR_TO_DATE(CONCAT('01-', month_year), '%d-%m-%Y');

ALTER TABLE fresh_segments.interest_metrics 
MODIFY COLUMN month_year DATE;


SELECT *
 FROM fresh_segments.interest_metrics;

-- What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT 
  month_year,
  COUNT(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year;

-- What do you think we should do with these null values in the fresh_segments.interest_metrics
SELECT *
FROM fresh_segments.interest_metrics
WHERE month_year IS NULL
ORDER BY interest_id DESC;

DELETE FROM interest_metrics
WHERE interest_id IS NULL;

--  How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT 
    COUNT(DISTINCT id) AS map_id_count,
    COUNT(DISTINCT interest_id) AS metrics_id_count,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS not_in_metric,
    SUM(CASE WHEN interest_id IS NULL THEN 1 ELSE 0 END) AS not_in_map
FROM (
    SELECT interest_id, id
    FROM interest_metrics metrics
    LEFT JOIN interest_map map ON interest_id = id
    
    UNION
    
    SELECT interest_id, id
    FROM interest_metrics metrics
    RIGHT JOIN interest_map map ON interest_id = id
    WHERE interest_id IS NULL  
) AS combined;

-- Summarise the id values in the fresh_segments.interest_map by its total record count in this table
select
count(*) as map_id
from interest_map;

-- What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
-- We can JOIN table interest_metrics and table interest_map in our analysis because only available interest_id in table interest_metrics are meaningful.
select interest_metrics.*,
interest_name,
interest_summary, created_at, 
last_modified
from interest_metrics
join interest_map
on interest_id = id
where interest_id = 21246
;

-- Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
-- We first check if metrics.month_year values were before the map.created_at values.
select count(*) as ctn
from interest_metrics
join interest_map
on interest_id = id
where month_year < cast(created_at as date)
;

-- There are 376 month_year values that are before created_at values. However, it may be the case that those 376th created_at values were created at the same month as month_year values. The reason is because month_year values were set on the first date of the month by default in Question 1
-- To check that, we turn the create_at to the first date of the month:
select count(*) as ctn
from interest_metrics
join interest_map
on interest_id = id
where month_year < str_to_date(concat( date_format(created_at, 
'%Y-%M'), '-1'),'%Y-%m-%d');

