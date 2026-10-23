# Data source

**Dataset:** Brazilian E-Commerce Public Dataset by Olist (orders from 2016–2018).

**Downloaded from (public GitHub mirror, no auth required):**
`https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/<file>.csv`
(the official Olist "work-at-olist-data" repo). The original source is Kaggle
(`kaggle.com/datasets/olistbr/brazilian-ecommerce`), which requires an account;
the Hugging Face mirror (`olistbr/brazilian-ecommerce`) returned HTTP 401 on
2026-10-22, so the GitHub mirror was used. Downloaded 2026-10-22.

**Row counts verified after download** (parsed with DuckDB `read_csv_auto`,
not `wc -l`, because the reviews file contains embedded newlines inside
quoted comment fields — `wc -l` overcounts it by 5,495 lines):

| File | Rows | Known size |
|---|---|---|
| olist_customers_dataset.csv | 99,441 | ~99,441 |
| olist_orders_dataset.csv | 99,441 | ~99,441 |
| olist_order_items_dataset.csv | 112,650 | ~112,650 |
| olist_order_payments_dataset.csv | 103,886 | ~103,886 |
| olist_order_reviews_dataset.csv | 99,224 | ~99,224 |
| olist_products_dataset.csv | 32,951 | ~32,951 |
| olist_sellers_dataset.csv | 3,095 | ~3,095 |
| product_category_name_translation.csv | 71 | 71 |

All counts match the published dataset sizes exactly.

**Excluded:** `olist_geolocation_dataset.csv` (~1,000,870 rows of zip-prefix
lat/lng points). It is not loaded into the warehouse: nothing in the retention
analysis needs coordinates (the segment cut uses customer state, which is
already on the customers table), and 1M reference rows would slow every build
for zero analytical gain. It can be added as a staging model later if a
distance analysis is ever wanted.

**License/terms:** the dataset is published by Olist for public use
(CC BY-NC-SA 4.0 on Kaggle).
