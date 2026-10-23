-- Grain: one row per order line (order_id, order_item_id).
select
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    c.customer_unique_id,
    o.order_purchase_timestamp::date as order_date,
    i.price,
    i.freight_value
from {{ ref('stg_order_items') }} i
join {{ ref('stg_orders') }} o using (order_id)
join {{ ref('stg_customers') }} c on c.customer_id = o.customer_id
