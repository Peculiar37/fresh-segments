-- Segment Analysis
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
with max_composition as (
select 
month_year, interest_id,
max(composition) over (partition by interest_id) as largest_composition
from interest_metrics_edited
where month_year is not null
),
composition_rank as (
select *,
dense_rank () over (order by largest_composition desc) as rnk
from max_composition
)
select
 distinct (cr.interest_id),
im.interest_name,
cr.rnk
from composition_rank cr
join interest_map im on cr.interest_id = im.id
where cr.rnk <= 10
order by cr.rnk;

-- bottom 10 interests with largest composition
with max_composition as (
select 
month_year, interest_id,
max(composition) over (partition by interest_id) as largest_composition
from interest_metrics_edited
where month_year is not null
),
composition_rank as (
select *,
dense_rank () over (order by largest_composition desc) as rnk
from max_composition
)
select
 distinct (cr.interest_id),
im.interest_name,
cr.rnk
from composition_rank cr
join interest_map im on cr.interest_id = im.id
group by cr.interest_id, im.interest_name,
cr.rnk
order by cr.rnk desc
limit 10;

-- 2. Which 5 interests had the lowest average ranking value?
select metrics.interest_id,
map.interest_name,
cast(avg(metrics.ranking) as decimal(10,2)) as avg_ranking 
from interest_metrics_edited metrics 
join interest_map map on metrics.interest_id = map.id
group by metrics.interest_id, map.interest_name
order by avg_ranking
limit 5;

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
with ranked_interest as (
select metrics.interest_id,
map.interest_name,
stddev_pop(metrics.percentile_ranking) as std_percentile_ranking
from interest_metrics_edited metrics 
join interest_map map on metrics.interest_id = map.id
group by metrics.interest_id, map.interest_name
)
select interest_id,
interest_name,
round(std_percentile_ranking,2) as std_percentile_ranking
from ranked_interest
order by std_percentile_ranking desc
limit 5;

-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
create temporary table interest_metrics_edit as 
select *
from interest_metrics
where interest_id not in (
select interest_id
from interest_metrics
where interest_id is not null
group by interest_id
having count(distinct month_year) < 6
);

with largest_std_interest as (
select metric.interest_id,
map.interest_name, map.interest_summary,
stddev_pop(metric.percentile_ranking) as std_percentile_ranking
from interest_metrics_edit metric 
join interest_map map on metric.interest_id = map.id
group by metric.interest_id, map.interest_name, map.interest_summary
order by std_percentile_ranking desc
limit 5
),
min_max_percentiles as (
select 
lsi.interest_id,
lsi.interest_name,
lsi.interest_summary,
ime.month_year,
ime.percentile_ranking,
max(ime.percentile_ranking) over (partition by lsi.interest_id) as max_pct_rank, 
min(ime.percentile_ranking) over (partition by lsi.interest_id) as min_pct_rank
from largest_std_interest lsi
join interest_metrics_edit ime on lsi.interest_id = ime.interest_id
)
select 
interest_id, interest_name, interest_summary,
max(case when percentile_ranking = max_pct_rank then month_year end) as max_pct_month_year,
max(case when percentile_ranking = max_pct_rank then percentile_ranking end) as max_pct_rnk,
min(case when percentile_ranking = max_pct_rank then month_year end) as min_pct_month_year,
min(case when percentile_ranking = max_pct_rank then percentile_ranking end) as min_pct_rnk
from min_max_percentiles
group by  interest_id, interest_name, interest_summary;

