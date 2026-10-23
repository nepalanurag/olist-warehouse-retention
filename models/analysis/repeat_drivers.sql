-- Decision cut: what distinguishes the customers who come back?
-- Every row attributes a customer by an attribute of their FIRST order
-- (earliest order_purchase_timestamp) and reports the repeat rate for that
-- group. repeat = the customer placed >= 2 orders in fact_orders.
-- Cuts are associative, not causal -- see docs/stakeholder_brief.md caveats.
-- Populations differ by cut and are stated in the README:
--   first_order_review_band  only customers whose first order has a review
--   first_order_delivery     only customers whose first order was delivered
--   first_order_category     all customers ('uncategorized' = no items or
--                            no category; 'all_other_categories' = rank 11+)
--   first_order_payment_type all customers ('no_payment_recorded' if none)
with customer_orders as (
    select
        customer_unique_id,
        order_id,
        order_status,
        order_purchase_timestamp,
        delivered_date,
        row_number() over (
            partition by customer_unique_id
            order by order_purchase_timestamp, order_id
        ) as order_rn,
        count(*) over (partition by customer_unique_id) as total_orders
    from {{ ref('fact_orders') }}
),

first_orders as (
    select
        customer_unique_id,
        order_id,
        order_status,
        delivered_date,
        total_orders >= 2 as is_repeat
    from customer_orders
    where order_rn = 1
),

order_reviews as (
    select
        order_id,
        max(review_score) as review_score
    from {{ ref('stg_order_reviews') }}
    group by order_id
),

first_order_reviews as (
    select
        f.customer_unique_id,
        f.is_repeat,
        case
            when r.review_score <= 2 then '1-2 stars'
            when r.review_score = 3 then '3 stars'
            else '4-5 stars'
        end as band
    from first_orders f
    join order_reviews r using (order_id)
),

first_order_delivery as (
    select
        f.customer_unique_id,
        f.is_repeat,
        case
            when f.delivered_date > o.order_estimated_delivery_date::date
                then 'delivered_late'
            else 'delivered_on_or_before_estimate'
        end as delivery_flag
    from first_orders f
    join {{ ref('stg_orders') }} o using (order_id)
    where f.order_status = 'delivered' and f.delivered_date is not null
),

first_order_items as (
    select
        order_id,
        product_id
    from {{ ref('stg_order_items') }}
    qualify row_number() over (partition by order_id order by order_item_id) = 1
),

first_order_categories as (
    select
        f.customer_unique_id,
        f.is_repeat,
        coalesce(p.product_category_name_english, 'uncategorized') as category
    from first_orders f
    left join first_order_items i on f.order_id = i.order_id
    left join {{ ref('dim_products') }} p on i.product_id = p.product_id
),

category_counts as (
    select
        category,
        count(*) as customers_in_category
    from first_order_categories
    where category <> 'uncategorized'
    group by category
),

category_ranks as (
    select
        category,
        dense_rank() over (order by customers_in_category desc) as category_rank
    from category_counts
),

category_ranked as (
    select
        f.customer_unique_id,
        f.is_repeat,
        case
            when f.category = 'uncategorized' then 'uncategorized'
            when r.category_rank > 10 then 'all_other_categories'
            else f.category
        end as category_group
    from first_order_categories f
    left join category_ranks r using (category)
),

first_order_payments as (
    select
        f.customer_unique_id,
        f.is_repeat,
        coalesce(p.payment_type, 'no_payment_recorded') as payment_type
    from first_orders f
    left join {{ ref('stg_order_payments') }} p
        on f.order_id = p.order_id and p.payment_sequential = 1
)

select
    'first_order_review_band' as driver,
    band as dimension_value,
    count(*) as customers,
    sum(case when is_repeat then 1 else 0 end) as repeat_customers,
    round(sum(case when is_repeat then 1 else 0 end)::double / count(*), 4) as repeat_rate
from first_order_reviews
group by band

union all

select
    'first_order_delivery',
    delivery_flag,
    count(*),
    sum(case when is_repeat then 1 else 0 end),
    round(sum(case when is_repeat then 1 else 0 end)::double / count(*), 4)
from first_order_delivery
group by delivery_flag

union all

select
    'first_order_category',
    category_group,
    count(*),
    sum(case when is_repeat then 1 else 0 end),
    round(sum(case when is_repeat then 1 else 0 end)::double / count(*), 4)
from category_ranked
group by category_group

union all

select
    'first_order_payment_type',
    payment_type,
    count(*),
    sum(case when is_repeat then 1 else 0 end),
    round(sum(case when is_repeat then 1 else 0 end)::double / count(*), 4)
from first_order_payments
group by payment_type

order by driver asc, customers desc
