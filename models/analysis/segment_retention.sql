-- Decision cut: which customer segment comes back?
-- Segment = customer state (from their most recent order's address).
-- repeat_rate = share of the state's customers with >= 2 orders.
with per_customer as (
    select
        c.customer_state,
        f.customer_unique_id,
        count(*) as orders
    from {{ ref('fact_orders') }} f
    join {{ ref('dim_customers') }} c using (customer_unique_id)
    group by 1, 2
)
select
    customer_state,
    count(*) as customers,
    sum(case when orders >= 2 then 1 else 0 end) as repeat_customers,
    round(sum(case when orders >= 2 then 1 else 0 end)::double / count(*), 4) as repeat_rate,
    round(avg(orders), 3) as avg_orders_per_customer
from per_customer
group by 1
order by customers desc
