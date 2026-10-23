select
    seller_id,
    lpad(cast(seller_zip_code_prefix as varchar), 5, '0') as seller_zip_code_prefix,
    lower(seller_city) as seller_city,
    upper(seller_state) as seller_state
from {{ source('raw_olist', 'sellers') }}
