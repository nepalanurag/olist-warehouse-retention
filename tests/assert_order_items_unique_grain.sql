-- fact_order_items grain must be exactly one row per (order_id, order_item_id).
select order_id, order_item_id, count(*) as n
from {{ ref('fact_order_items') }}
group by 1, 2
having count(*) > 1
