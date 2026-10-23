# Stakeholder brief — Olist retention warehouse

## Requester

Marketplace growth lead (Olist-style marketplace: independent sellers,
one shared storefront, growth team owns acquisition and repeat purchase).

## The question

> We keep buying new customers. Do any of them ever come back — and if not,
> where is the second purchase being lost?

## The decision this informs

Where the retention budget goes next quarter. Specifically, which of these
gets funded:

1. **More acquisition** (the current default spend),
2. **Regional targeting** (spend concentrated in states believed to be loyal),
3. **Second-purchase conversion** (post-first-order experience: delivery
   reliability, review solicitation, category-led re-engagement).

The warehouse exists to answer this with numbers, and the analysis models
(`cohort_retention`, `segment_retention`, `repeat_drivers`) are the decision
inputs. The companion document `docs/recommendation.md` turns the findings
into sized interventions.

## Headline answer (from the current build)

- Only **3.12%** of 96,096 customers ever place a second order.
- Month-1 cohort retention is **0.48%** — acquisition cohorts behave as
  one-and-done regardless of size or season.
- No state retains meaningfully better than another (RJ 3.44%, SP 3.24%,
  MG 3.03% repeat), so option 2 has no evidence behind it. The money
  question is option 3: what distinguishes the 3.12% who return?

## Metric definitions (the contract for every number quoted)

| Metric | Definition |
|---|---|
| Customer | A distinct `customer_unique_id`. The raw `customer_id` is per-order and is **never** used as identity. |
| Repeat customer | A customer with ≥ 2 orders in `fact_orders` (all order statuses; see caveats). |
| Repeat rate | Repeat customers / all customers in the group. |
| Cohort | The calendar month of a customer's **first** order. |
| Month index | Whole months between the cohort month and the activity month (0 = first-purchase month). |
| Month-1 retention | Share of a cohort with ≥ 1 order in month index 1. Headline figure pools the 19 cohorts with ≥ 1,000 customers. |
| First order | A customer's earliest order by `order_purchase_timestamp`. All `repeat_drivers` cuts are attributes of this order. |
| Late delivery | `order_delivered_customer_date` is after `order_estimated_delivery_date` (delivered orders only). |
| Review band | The review score left on the customer's **first** order, banded 1–2 / 3 / 4–5 stars. |

## Caveats the reader must know

- **Identity is resolved, not given.** `customer_unique_id` is the dataset's
  own person key; if it under-merges (same person, two ids), repeat rates
  are understated. There is no better key in the published data.
- **All order statuses are counted**, including canceled and unavailable
  orders (1,234 of 99,441, 1.2%). Excluding them does not change any
  finding, but a "repeat buyer" here means "placed a second order", not
  "received a second delivery".
- **Right-censoring.** The data ends 2018-10-17. Late cohorts have fewer
  observable months; that is why the headline month-1 figure pools only the
  cohorts with ≥ 1,000 customers and why `repeat_drivers` should be read as
  associations over the full window, not as causal effects.
- **Driver cuts are associative, not causal.** A 5-star first order and a
  repeat purchase may both be caused by an unobserved good experience.
  `docs/recommendation.md` therefore sizes interventions as hypotheses with
  an A/B test attached, not as guaranteed lifts.
- **Reviews are sparse and skewed.** 58.7% of reviews have no comment text,
  and a minority of orders have no review row at all; the review-band cut
  covers only customers whose first order was reviewed.
- The geolocation table is excluded by design (see `data/SOURCE.md`); no
  distance or delivery-route claim can be made from this warehouse.
