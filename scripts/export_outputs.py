"""Export the dbt analysis tables to outputs/ as CSVs.

Run after `dbt build`. Every number quoted in README.md comes from these files.
"""
import duckdb

con = duckdb.connect("warehouse.duckdb", read_only=True)
for table, path in [
    ("cohort_retention", "outputs/cohort_retention.csv"),
    ("segment_retention", "outputs/segment_retention.csv"),
]:
    con.execute(f"copy (select * from main.{table}) to '{path}' (header, delimiter ',')")
    n = con.execute(f"select count(*) from main.{table}").fetchone()[0]
    print(f"{path}: {n} rows")
