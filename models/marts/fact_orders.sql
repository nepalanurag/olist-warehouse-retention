-- Grain: one row per order.
with items as (
    select
        order_id,
        count(*) as item_count,
        sum(price) as items_value,
        sum(freight_value) as freight_value
    from {{ ref('stg_order_items') }}
    group by 1
),
payments as (
    select order_id, sum(payment_value) as payment_value
    from {{ ref('stg_order_payments') }}
    group by 1
)
select
    o.order_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_purchase_timestamp::date as order_date,
    o.order_delivered_customer_date::date as delivered_date,
    date_diff('day', o.order_purchase_timestamp::date,
              o.order_delivered_customer_date::date) as days_to_deliver,
    coalesce(i.item_count, 0) as item_count,
    coalesce(i.items_value, 0) as items_value,
    coalesce(i.freight_value, 0) as freight_value,
    coalesce(p.payment_value, 0) as payment_value
from {{ ref('stg_orders') }} o
join {{ ref('stg_customers') }} c using (customer_id)
left join items i using (order_id)
left join payments p using (order_id)
