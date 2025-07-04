-- Interest Analysis
-- 1. Which interests have been present in all month_year dates in our dataset?
SET @unique_month_year_cnt = (
  SELECT COUNT(DISTINCT month_year)
  FROM interest_metrics
);

-- Filter interest_ids that appear in all month_year periods
SELECT 
  interest_id,
  COUNT(month_year) AS period_count
FROM interest_metrics
GROUP BY interest_id
HAVING COUNT(month_year) = @unique_month_year_cnt;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH interest_months AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
),
interest_count AS (
  SELECT
    total_months,
    COUNT(interest_id) AS interests
  FROM interest_months
  GROUP BY total_months
)

SELECT 
  ic.*,
  ROUND(100.0 * (
    SELECT SUM(interests) 
    FROM interest_count ic2 
    WHERE ic2.total_months >= ic.total_months
  ) / (SELECT SUM(interests) FROM interest_count), 2) AS cumulative_pct
FROM interest_count ic
ORDER BY total_months DESC;


-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

 WITH interest_months AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
  HAVING total_months < 6  
)
SELECT 
  COUNT(*) AS total_occurrences,
  COUNT(DISTINCT im.interest_id) AS unique_short_term_interests
FROM interest_metrics im
WHERE EXISTS (
  SELECT 1 
  FROM interest_months imo
  WHERE imo.interest_id = im.interest_id
);

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
-- Even though those clients didn't have a significant impact on the company outcome, we shouldn't eliminate these data points from a business standpoint.  I discovered that this company had only been in operation for a year and a half when I looked at the timeline in our data collection.  There was not enough time to determine whether or not those customers would return.
SELECT 
  MIN(month_year) AS first_date,
  MAX(month_year) AS last_date
FROM interest_metrics;

-- When total_months = 14
SELECT 
  month_year,
  COUNT(DISTINCT interest_id) AS interest_count,
  MIN(ranking) AS highest_rank,
  MAX(composition) AS composition_max,
  MAX(index_value) AS index_max
FROM interest_metrics metrics
WHERE interest_id IN (
  SELECT interest_id
  FROM interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) = 14
)
GROUP BY month_year
ORDER BY month_year, highest_rank;

-- Interests that appeared in only one month (total_months = 1)
SELECT 
  month_year,
  COUNT(DISTINCT interest_id) AS interest_count,
  MIN(ranking) AS highest_rank,
  MAX(composition) AS composition_max,
  MAX(index_value) AS index_max
FROM interest_metrics metrics
WHERE interest_id IN (
  SELECT interest_id
  FROM interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) = 1
)
GROUP BY month_year
ORDER BY month_year, highest_rank;
-- In the event that we wish to calculate the average, maximum, or minimum ranking, composition, or index_values for each interest each month, interests with fewer than 14 months would result in an uneven distribution of observations since we would not have data for some months.  Therefore, in order to get a precise picture of the general interest of clients, we need archive these data points in the segment analysis.

-- 5. After removing these interests - how many unique interests are there for each month?
-- Create a temporary table [interest_metrics_edited]
CREATE TEMPORARY TABLE interest_metrics_edited AS
SELECT *
FROM interest_metrics
WHERE interest_id NOT IN (
  SELECT interest_id
  FROM interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) < 6
);

-- Check the count of interests_id
SELECT 
  COUNT(interest_id) AS all_interests,
  COUNT(DISTINCT interest_id) AS unique_interests
FROM interest_metrics_edited;

SELECT 
  month_year,
  COUNT(DISTINCT interest_id) AS unique_interests
FROM interest_metrics_edited
WHERE month_year IS NOT NULL
GROUP BY month_year
ORDER BY month_year;

