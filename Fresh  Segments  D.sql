-- Index Analysis
-- 1. What is the top 10 interests by the average composition for each month?
with avg_composition_rank as (
select 
distinct metrics.interest_id,
metrics.month_year,
map.interest_name,
round(metrics.composition / metrics.index_value,2) as avg_composition,
dense_rank() over (partition by metrics.month_year order by metrics.composition / metrics.index_value desc) as rnk
from interest_metrics metrics
join interest_map map on  metrics.interest_id = map.id
where metrics.month_year is not null
)
select *
from avg_composition_rank
where rnk <= 10;
 
 -- 2. For all of these top 10 interests - which interest appears the most often?
with avg_composition_rank as (
select 
distinct metrics.interest_id,
metrics.month_year,
map.interest_name,
round(metrics.composition / metrics.index_value,2) as avg_composition,
dense_rank() over (partition by metrics.month_year order by metrics.composition / metrics.index_value desc) as rnk
from interest_metrics metrics
join interest_map map on  metrics.interest_id = map.id
where metrics.month_year is not null
),
frequent_interests as (
select 
interest_id, interest_name,
count(*) as freq
from avg_composition_rank
where rnk <= 10
group by interest_id, interest_name
)
select *
from frequent_interests
where freq = (select max(freq) from frequent_interests);

-- 3. What is the average of the average composition for the top 10 interests for each month?
with avg_composition_rank as (
select 
distinct metrics.interest_id,
metrics.month_year,
map.interest_name,
round(metrics.composition / metrics.index_value,2) as avg_composition,
dense_rank() over (partition by metrics.month_year order by metrics.composition / metrics.index_value desc) as rnk
from interest_metrics metrics
join interest_map map on  metrics.interest_id = map.id
where metrics.month_year is not null
)
select month_year,
avg(avg_composition) as avg_of_avg_composition
from avg_composition_rank
where rnk <= 10
group by month_year
order by month_year;

-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
with avg_compositions as (
select 
month_year, interest_id,
round(composition/ index_value,2) as average_composition,
round(max(composition/index_value) over (partition by month_year),2) as max_avg_comp
from interest_metrics
where month_year is not null
),
max_avg_composition as (
select *
from avg_compositions
where average_composition = max_avg_comp
),
moving_avg_composition as (
select
mac.month_year,
im.interest_name,
mac.max_avg_comp,
round(avg(max_avg_comp) over (order by mac.month_year rows between 2 preceding and current row),2) as month_moving_avg,
concat(
lag(im.interest_name, 1) over (order by mac.month_year), ' : ',
lag(mac.max_avg_comp, 1) over  (order by mac.month_year)) as 1_month_ago,
concat(
lag(im.interest_name, 2) over (order by mac.month_year), ' : ',
lag(mac.max_avg_comp, 2) over  (order by mac.month_year)) as 2_month_ago
from max_avg_composition mac
join interest_map im on mac.interest_id = im.id
)
select *
from moving_avg_composition
where month_year between '2018-09-01' and '2019-08-01';

-- 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
-- Because travel-related services accounted for the majority of top interests and had strong seasonal demand during certain months of the year, the maximum average composition declined with time.  Consumers desired to travel in the early three months of the year and the end three months of the year.  As you can see, between September 2018 and March 2019, max_index_composition was high.

-- This indicates that travel-related services were a major component of Fresh Segments' business.  Customers showed little interest in other goods and services.