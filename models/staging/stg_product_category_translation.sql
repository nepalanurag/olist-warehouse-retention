select
    product_category_name,
    product_category_name_english
from {{ source('raw_olist', 'product_category_name_translation') }}
