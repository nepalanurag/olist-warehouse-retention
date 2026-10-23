-- Monthly first-purchase cohort retention.
-- Cohort = month of a customer's first order (all statuses; cancellations are
-- 1.2% of orders and are not filtered, stated in the README).
-- A customer is "active" in a month if they placed >= 1 order that month.
-- retention_rate = active_customers / cohort_size.
with customer_orders as (
    select
        customer_unique_id,
        date_trunc('month', order_purchase_timestamp)::date as order_month,
        min(date_trunc('month', order_purchase_timestamp)::date)
            over (partition by customer_unique_id) as cohort_month
    from {{ ref('fact_orders') }}
),

activity as (
    select distinct
        cohort_month,
        customer_unique_id,
        order_month
    from customer_orders
),

cohort_sizes as (
    select
        cohort_month,
        count(distinct customer_unique_id) as cohort_size
    from activity
    where order_month = cohort_month
    group by 1
)

select
    a.cohort_month,
    date_diff('month', a.cohort_month, a.order_month) as month_index,
    s.cohort_size,
    count(distinct a.customer_unique_id) as active_customers,
    round(count(distinct a.customer_unique_id)::double / s.cohort_size, 4) as retention_rate
from activity a
join cohort_sizes s using (cohort_month)
group by 1, 2, 3
order by 1, 2
