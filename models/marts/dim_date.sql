-- Calendar spine covering the full purchase window in the data.
with bounds as (
    select
        min(order_purchase_timestamp)::date as start_date,
        max(order_purchase_timestamp)::date as end_date
    from {{ ref('stg_orders') }}
)
select
    d::date as date_day,
    extract(year from d) as year,
    extract(month from d) as month,
    extract(day from d) as day,
    strftime(d, '%Y-%m') as year_month,
    date_trunc('month', d)::date as month_start
from bounds, generate_series(start_date, end_date, interval 1 day) as t(d)
