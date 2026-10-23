# Olist Warehouse + Cohort Retention (dbt + DuckDB)

## The question

A marketplace growth team keeps buying new customers and asked: **do any of
them ever come back — and if not, where is the second purchase being lost?**
This repo is the warehouse and analysis built to answer that, on the
**Brazilian E-Commerce Public Dataset by Olist** (9 relational source
tables, ~100k orders from 2016–2018). The stakeholder framing, metric
definitions and caveats live in `docs/stakeholder_brief.md`.

**Live dashboard (Tableau Public):** [Olist Customers Almost Never Come Back — cohort retention + repeat rate by state](https://public.tableau.com/app/profile/anurag.nepal/viz/OlistCustomersAlmostNeverComeBackCohortRetentiondbtDuckDBwarehouse/Dashboard1)

## The answer

- **Repeat buying barely exists.** Of 96,096 distinct customers, **2,997
  (3.12%) ever placed a second order**. The other 93,099 bought exactly once.
- **Month-1 retention is under half a percent.** Across the 19 cohorts with
  ≥1,000 customers, 457 of 95,000 customers (0.48%) ordered again in the month
  after their first purchase; the per-cohort range is 0.11%–0.72%. The
  largest cohort, Nov 2017 (7,304 customers, Black Friday), retained 0.55%
  at month 1 — the biggest acquisition month behaved like every other month.
- **Geography is not the lever.** Repeat rate by customer state sits in a
  narrow band: RJ 3.44%, SP 3.24% (40,296 customers, 42% of the base), MG
  3.03%. The only states above 4.5% are AC (5.19%) and RO (4.58%) on bases of
  77 and 240 customers — noise, not signal.

## The lever

Repeat rate is a property of the **first order**, not of the region
(`outputs/repeat_drivers.csv`):

- **Late delivery is the one service failure that costs repeat buyers:**
  first orders delivered after their estimated date repeat at **2.54%** vs
  **3.13%** on time — a 0.59pp penalty on 6,344 customers.
- **Category is the strongest split:** first orders in furniture_decor
  (4.56%) and bed_bath_table (4.50%) repeat at ~2× the rate of auto (2.14%),
  watches_gifts (2.19%) and telephony (2.49%).
- **Review score is nearly flat** (1–2 stars 2.96% vs 4–5 stars 3.16%) —
  the unhappy first-time buyer still comes back almost as often, so a
  review-score program is the smallest lever measured.

`docs/recommendation.md` turns these into a sized playbook (late-delivery
recovery, a second-purchase voucher run as an experiment, category-led
re-engagement), each with the A/B test that would prove it and the
sample-size logic behind it. Every number in this README is computed by
the pipeline and traceable to a file in `outputs/` or to `RUN_LOG.txt`.

## Run it

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt          # dbt-duckdb 1.11.0, duckdb 2.0.0
# download the 8 CSVs listed in data/SOURCE.md into data/ (URLs + row counts there)
python scripts/load_raw.py               # creates raw_olist views over the CSVs
dbt build --profiles-dir .               # 18 models, 36 tests — all must pass
python scripts/export_outputs.py         # writes outputs/*.csv
```

CI (`.github/workflows/ci.yml`) runs exactly this sequence — download,
load, build, sqlfluff lint, export — on every push and pull request, so a
failing data test fails the build. `RUN_LOG.txt` captures a from-scratch
run and the upgrade run of the same sequence.

## Warehouse shape

```
raw_olist (views over the published CSVs, untouched)
  customers · orders · order_items · order_payments
  reviews · products · sellers · category_translation
        │
staging (views, 1 per table: renamed, typed, zip codes re-padded to 5 chars)
  stg_customers · stg_orders · stg_order_items · stg_order_payments
  stg_order_reviews · stg_products · stg_sellers · stg_product_category_translation
        │
marts (tables, star schema, model contracts enforced in _marts.yml)
  dim_customers   96,096 people (identity resolved via customer_unique_id)
  dim_products    32,951 products, category translated to English
  dim_sellers      3,095 sellers
  dim_date           774 days, 2016-09-04 → 2018-10-17
  fact_orders     99,441 orders (items/freight/payment totals folded in)
  fact_order_items 112,650 line items
        │
analysis (tables → outputs/, declared as dbt exposures in _exposures.yml)
  cohort_retention    monthly first-purchase cohorts, window functions
  segment_retention   repeat rate by customer state
  repeat_drivers      repeat rate by first-order review band, delivery
                      lateness, category, payment type
  data_quality_report monitored source-defect counts (see below)
```

Tests (36, all passing): `unique` + `not_null` on every key,
`relationships` from both facts to all dims and staging to staging,
`accepted_values` on `order_status` (8 values) and `review_score` (1–5),
plus a singular test for the fact_order_items grain
(one row per order_id + order_item_id). The six marts models also carry
**enforced dbt contracts** (column names and DuckDB types), so a silent
schema drift in a mart fails the build instead of reaching a dashboard.
SQL is linted with sqlfluff (dbt templater, DuckDB dialect); the rule
scoping adopted for this existing codebase is documented in `.sqlfluff`.

Sanity numbers from the facts: 97.0% of orders reached `delivered`, median
delivery time 10 days, average payment R$161.00 per order, R$13.59M in item
value plus R$2.26M freight across the period.

Cohorts count orders of every status (canceled + unavailable are 1,234 of
99,441 orders, 1.2%); excluding them does not change any finding above.

## Messiness found in the raw data (why staging exists)

- `customer_id` is **per-order**, not per-person — the same human gets a new
  id every order. Identity only resolves through `customer_unique_id`
  (99,441 customer rows → 96,096 people). Any naive retention query on
  `customer_id` returns exactly zero repeat buyers.
- **789 `review_id`s appear on multiple rows** (one review attached to every
  item of a multi-item order), so review_id is not a key.
- **58,247 of 99,224 reviews (58.7%) have no comment text**; 610 products
  have no category; 775 orders have no item rows; 1 order has no payment row;
  2,965 orders have no delivery date.
- The reviews CSV has newlines embedded in quoted comment fields — a line
  count overstates it by 5,495 rows. Row counts in `data/SOURCE.md` were
  verified with a real CSV parser.
- Zip-code prefixes lose leading zeros when parsed as integers (`01001` →
  `1001`); staging re-pads them to 5 characters.
- The geolocation table (~1.0M rows) is deliberately not loaded; see
  `data/SOURCE.md`.

These defects are monitored, not just documented: the
`data_quality_report` model recounts them on every build and exports
`outputs/data_quality_report.csv` with review thresholds, so a sudden
change means the source extract changed, not that the warehouse broke.

## Resume bullet

> Built a dbt + DuckDB star-schema warehouse over 99,441 Olist orders
> (8 source tables, 18 models, 36 passing data tests, enforced model
> contracts, GitHub Actions CI) and analysed cohort retention and
> repeat-purchase drivers with window functions; found only 3.12% of
> 96,096 customers ever reordered, month-1 retention of 0.48%, and a
> 0.59pp repeat penalty on late-delivered first orders, so the growth
> lever is second-purchase conversion, not acquisition or regional
> targeting.

## Layout

```
dbt_project.yml · profiles.yml · requirements.txt · .sqlfluff
data/       CSVs (git-ignored) + SOURCE.md (URLs, verified row counts)
docs/       stakeholder_brief.md (question, definitions, caveats) ·
            recommendation.md (sized playbook, A/B tests)
scripts/    load_raw.py (raw views), export_outputs.py (analysis → CSV)
models/     staging/ · marts/ (contracts in _marts.yml) · analysis/
            _exposures.yml (outputs declared as downstream products)
tests/      singular grain test for fact_order_items
outputs/    cohort_retention.csv (225 rows) · segment_retention.csv
            (27 states) · repeat_drivers.csv (23 rows) ·
            data_quality_report.csv (6 checks)
.github/    workflows/ci.yml — download → build → lint → export
RUN_LOG.txt from-scratch build log (PASS=52) + upgrade run (PASS=54)
```
