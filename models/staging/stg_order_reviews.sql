-- Note: review_id is NOT unique in the raw file (789 ids appear on 2+ rows:
-- the same review is attached to every item row of a multi-item order).
-- Kept as published; no uniqueness is claimed here.
select
    review_id,
    order_id,
    cast(review_score as integer) as review_score,
    review_comment_title,
    review_comment_message,
    cast(review_creation_date as timestamp) as review_creation_date,
    cast(review_answer_timestamp as timestamp) as review_answer_timestamp
from {{ source('raw_olist', 'order_reviews') }}
