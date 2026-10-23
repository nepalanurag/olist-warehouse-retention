-- One row per real person. The raw customers table has one row per ORDER
-- (customer_id changes every order); identity is customer_unique_id.
-- Attributes come from the customer's most recent order.
with ranked as (
    select
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,
        row_number() over (
            partition by c.customer_unique_id
            order by o.order_purchase_timestamp desc
        ) as rn
    from {{ ref('stg_customers') }} c
    join {{ ref('stg_orders') }} o using (customer_id)
)

select
    customer_unique_id,
    customer_city,
    customer_state,
    customer_zip_code_prefix
from ranked
where rn = 1
