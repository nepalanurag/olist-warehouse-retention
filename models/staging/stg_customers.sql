select
    customer_id,
    customer_unique_id,
    lpad(cast(customer_zip_code_prefix as varchar), 5, '0') as customer_zip_code_prefix,
    lower(customer_city) as customer_city,
    upper(customer_state) as customer_state
from {{ source('raw_olist', 'customers') }}
