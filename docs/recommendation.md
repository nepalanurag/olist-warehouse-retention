# Recommendation — the second-purchase playbook

Companion to `docs/stakeholder_brief.md`. Every number below comes from
`outputs/repeat_drivers.csv` (and `outputs/segment_retention.csv` for the
state cut), computed by the `repeat_drivers` dbt model from the customer's
**first** order. Baseline for all sizing: **2,997 of 96,096 customers
(3.12%) ever repeat.**

## What the drivers say

| First-order attribute | Repeat rate | Read |
|---|---|---|
| Review 4–5 stars (73,513 customers) | 3.16% | Barely above baseline |
| Review 1–2 stars (13,998) | 2.96% | Unhappy reviewers still come back |
| Delivered on/before estimate (86,904) | 3.13% | — |
| **Delivered late (6,344)** | **2.54%** | −0.59pp, a 19% relative penalty |
| Category: furniture_decor (6,053) | 4.56% | Replenishable home goods lead |
| Category: bed_bath_table (8,858) | 4.50% | Same pattern |
| Category: auto (3,786) | 2.14% | Low trio: ~1pp below average |
| Category: watches_gifts (5,438) | 2.19% | " |
| Category: telephony (4,093) | 2.49% | " |
| Paid by voucher (1,482) | 4.52% | Self-selected — a hypothesis, not a lever |
| Paid by credit card (73,909) / boleto (19,189) | 3.12% / 3.07% | Payment method is otherwise flat |

These are associations, not causal effects (see the brief's caveats). Each
intervention below is therefore written as a test, with the sizing shown as
"if the association were causal and fully closed" — the ceiling, not a
forecast.

## Fund these

### 1. Late-delivery recovery
**Observation.** A late first delivery is the only service failure with a
visible repeat penalty: 2.54% vs 3.13% on-time.
**Intervention.** When a first order is delivered after its estimated date,
send an apology plus a time-boxed second-purchase voucher within 48 hours
of delivery. Cost is a message and voucher margin.
**Size.** 6,344 late first orders in this extract. Closing the full 0.59pp
gap would mean ≈ +37 repeat customers per comparable period; closing half,
≈ +19. Small in absolute terms — worth it because it is cheap and because
late delivery is also a review/complaint risk this dataset cannot price.
**Test.** Randomize late-delivered first-time buyers 50/50: recovery vs
silent control. Primary metric: second order within 180 days.
Sample-size logic: baseline 2.54%, and detecting a +0.6pp recovery at 80%
power needs on the order of 11k late buyers per arm — more than the entire
late population of this 2-year extract (6.3k). Plan on live traffic over
multiple months, or widen eligibility to "delivered late or in the slowest
delivery decile" and pre-register the wider definition. An underpowered
6-week test that "shows nothing" would be a planning failure, not evidence.

### 2. Second-purchase voucher — as an experiment, not a rollout
**Observation.** First orders paid by voucher repeat at 4.52% vs 3.12% for
credit card. But voucher use is self-selected (deal-seekers, gifted
balances), so this gap is exactly the kind of signal that evaporates under
randomization.
**Intervention.** At first-order delivery, offer a 30-day second-purchase
voucher — to a randomized half of new buyers only.
**Size.** If the voucher truly caused +0.5pp repeat on the ~96k first
orders in a comparable period, that is ≈ +480 repeat customers; the test
exists to find out whether any of that is real before paying voucher costs
on every order.
**Test.** The intervention *is* the test. Primary metric: second order
within 90 days. Sample-size logic: baseline 3.12%, detecting +0.5pp at 80%
power needs roughly 20k buyers per arm — reachable in months at this
marketplace's volume (96k first orders per 25 months). Guardrail metric:
contribution margin per order, so a "win" bought with discount spend is
visible as one.

### 3. Category-led re-engagement for the low-repeat trio
**Observation.** Repeat rate is a category property more than a service
property: furniture_decor and bed_bath_table hold 4.5%+, while auto
(2.14%), watches_gifts (2.19%) and telephony (2.49%) sit ~1pp below the
marketplace average on a combined 13,317 first-order customers.
**Intervention.** Replace the generic post-purchase newsletter for these
three categories with category-specific journeys: refill/consumable
reminders for auto care, straps/batteries/accessories for watches, cases
and plans for telephony. Mirror what the home categories get right
(replenishable, occasion-driven) instead of broadcasting harder.
**Size.** Lifting the trio from ~2.3% blended to the 3.12% average would be
≈ +110 repeat customers per comparable period; half the gap ≈ +55.
**Test.** Randomize first-order buyers in the trio: tailored journey vs
current generic program. Primary metric: second order within 180 days.
Sample-size logic: pooled across the trio (base rate ~2.3%, MDE +0.8pp)
the test needs roughly 6k buyers per arm — feasible; run
per-category cuts as secondaries only, because no single category is
powered on its own.

## Explicitly not funded

- **A review-score improvement program.** The gap between 1–2 star and
  4–5 star first orders is 0.20pp on 13,998 unhappy reviewers — fully
  closing it is worth ≈ +28 repeat customers, the smallest lever measured.
  Reviews matter for conversion of *new* buyers; the data says they are
  not where the second purchase is lost.
- **Regional targeting.** Repeat rate by state is a narrow band (MG 3.03%,
  SP 3.24%, RJ 3.44%); the only states above 4.5% have 77 and 240
  customers. There is no loyal region to concentrate spend on.
