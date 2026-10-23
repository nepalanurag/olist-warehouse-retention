-- Data quality report: one row per monitored source defect, with the count
-- for THIS build. Exported to outputs/data_quality_report.csv so every run
-- leaves a comparable snapshot. These are defects in the published source
-- extracts, monitored on purpose (staging deliberately keeps the data as
-- published); a sudden change in a count means the source changed, not that
-- the warehouse broke. Thresholds are judgement calls for a human reviewer,
-- not pass/fail gates -- the dbt tests remain the gates.
with checks as (
    select
        'orders_without_items' as check_name,
        'fact_orders.item_count = 0: orders with no item rows in the source extract' as check_description,
        count(*) as affected_count,
        (select count(*) from {{ ref('fact_orders') }}) as total_count,
        'review if share moves by more than 1pp between source drops' as threshold_note
    from {{ ref('fact_orders') }}
    where item_count = 0

    union all

    select
        'orders_without_payments',
        'orders with no payment rows at all in stg_order_payments (orders whose payment rows sum to zero are a separate, smaller oddity)',
        count(*),
        (select count(*) from {{ ref('fact_orders') }}),
        'any increase above the current 1 order is a source anomaly'
    from {{ ref('fact_orders') }} f
    where
        not exists (
            select 1 from {{ ref('stg_order_payments') }} p
            where p.order_id = f.order_id
        )

    union all

    select
        'orders_without_delivery_date',
        'delivered orders with no order_delivered_customer_date (excludes canceled/unavailable, which never deliver)',
        count(*),
        (
            select count(*) from {{ ref('fact_orders') }}
            where fact_orders.order_status = 'delivered'
        ),
        'review if share of delivered orders moves by more than 1pp between source drops'
    from {{ ref('fact_orders') }}
    where fact_orders.order_status = 'delivered' and fact_orders.delivered_date is null

    union all

    select
        'duplicate_review_ids',
        'review_id values appearing on 2+ rows in stg_order_reviews (one review attached to every item of a multi-item order)',
        count(*),
        (select count(distinct stg_order_reviews.review_id) from {{ ref('stg_order_reviews') }}),
        'expected to grow with multi-item orders; a step change suggests a source re-extract'
    from (
        select stg_order_reviews.review_id
        from {{ ref('stg_order_reviews') }}
        group by stg_order_reviews.review_id
        having count(*) > 1
    ) dupes

    union all

    select
        'reviews_without_text',
        'reviews with no comment message (58.7% at first build; the silent majority of reviewers)',
        count(*),
        (select count(*) from {{ ref('stg_order_reviews') }}),
        'informational: tracks review-engagement mix, not a defect to fix'
    from {{ ref('stg_order_reviews') }}
    where review_comment_message is null

    union all

    select
        'products_without_category',
        'dim_products rows with no product_category_name in the source extract',
        count(*),
        (select count(*) from {{ ref('dim_products') }}),
        'review if count grows materially; these products are invisible to category cuts'
    from {{ ref('dim_products') }}
    where product_category_name is null
)

select
    check_name,
    check_description,
    affected_count,
    total_count,
    round(affected_count::double / total_count, 4) as affected_share,
    threshold_note
from checks
order by check_name
