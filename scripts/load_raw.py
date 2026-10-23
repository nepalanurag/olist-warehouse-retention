"""Create the raw layer: one DuckDB view per CSV in schema raw_olist.

The views read the CSVs in place (nothing is copied), so what dbt sees is
exactly what was downloaded. Run before `dbt build`.
"""
import duckdb

FILES = {
    "customers": "olist_customers_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "product_category_name_translation": "product_category_name_translation.csv",
}

con = duckdb.connect("warehouse.duckdb")
con.execute("create schema if not exists raw_olist")
for table, filename in FILES.items():
    con.execute(
        f"create or replace view raw_olist.{table} as "
        f"select * from read_csv_auto('data/{filename}', header=true)"
    )
    n = con.execute(f"select count(*) from raw_olist.{table}").fetchone()[0]
    print(f"raw_olist.{table}: {n} rows")
