# Root Cause Analysis — DataCo Supply Chain Performance

## Scope
This analysis investigates three recurring operational issues in the DataCo Supply Chain dataset: chronic late delivery, product-level profitability gaps, and customer retention drop-off. Each section states the question investigated, the finding, and — where the data supports it — the likely driver.

---

## 1. Late Delivery — Root Cause: First Class Shipping Mode

**Question:** Why is the overall late delivery rate so high, and what's driving it?

**Finding:** Of ~65K total orders, 57% are delivered late, 24% early, and only 18% arrive on the exact promised day. This is not evenly distributed across shipping modes — **First Class carries a 95% late rate**, followed by Second Class at 76%. Same Day (46%) and Standard (38%) are comparatively far better.

**Root cause isolated:** Breaking late rate down by shipping mode × region confirms First Class is not a regional problem — it fails almost everywhere. In Central Asia and Southern Africa specifically, First Class hits ~100% late on the (small) order volumes shipped through that lane. A hotspot/outlier analysis (mean + 1 standard deviation threshold) flagged First Class in nearly every region as a statistical outlier, confirming this is a mode-level failure, not noise from a handful of regions.

**Supporting evidence:**
- Average delay for First Class and Second Class is ~2 days beyond the scheduled delivery window; Standard averages ~0 days delay.
- First Class also carries the highest cancellation-adjacent rate among the shipping modes analyzed.
- Despite the reliability problem, First Class actually generates the **highest profit margin (11.8%)** of any shipping mode — the business has a financial incentive to route orders through the least reliable option, which is likely reinforcing the problem rather than correcting it.

**Trend check:** Late delivery rate has stayed flat at ~55% month-over-month and year-over-year, with no clear seasonal pattern and no sign of improvement over the dataset's full time range. This is a structural, persistent issue — not a one-time spike or a specific bad quarter.

**Regional concentration:** Central Africa, East Africa, and South USA show the highest overall late rates (~58-60%), independent of shipping mode.

**Order size:** A secondary check on whether order size (item quantity) drives lateness found only a weak effect — small orders (1 item) run ~55% late vs. ~50% for large orders (4+ items), a 5-point spread. Order size is a minor factor at most; shipping mode is the dominant driver.

---

## 2. Product Profitability — Root Cause: Category and SKU-Level Margin Erosion

**Question:** Which products/categories are underperforming on profit, and why?

**Finding:** At the category level, **Golf Bags & Carts and Fitness Accessories carry the highest profit margins**, while **As Seen on TV and Strength Training categories run negative margins** — these categories are losing money on every unit sold, not just underperforming relative to others.

**SKU-level confirmation:** Six individual products across three categories were identified as outright loss-makers (negative total profit), separate from the category-level trend — meaning the category-level loss isn't just an average pulled down by one outlier, it's present at the individual product level too.

**Discount correlation:** A combined discount-rate + margin threshold analysis (products with above-average discount rate AND below-average margin, using mean ± 1 standard deviation as the cutoff) isolated a small, high-confidence list of "problem SKUs" — products being discounted aggressively while running thin or negative margins. *(Note: the specific products flagged by this query were not recorded in a comment in the source file — rerun and document before citing specific SKU names externally.)*

**Sales volume vs. profitability are not the same signal:** Men's Footwear leads by total sales volume, followed by Fishing and Water Sports — but high sales volume does not imply high margin (see Golf/Fitness margin leaders above, which are not the top sellers by volume). This is a useful distinction for any stakeholder assuming "best-selling" means "most profitable."

---

## 3. Customer Retention — Root Cause: High First-Purchase Drop-off, Slow Repeat Cycle

**Question:** How well is the business retaining customers after a first purchase?

**Finding:** 56% of customers who placed an order came back and bought again; 43% remained one-time buyers. Roughly four in ten customers acquired are never converted into repeat business.

**Time-to-repeat:** Among customers who do return, the **average time to second purchase is 194 days, with a median of 141 days** — the gap between mean and median indicates a right-skewed distribution: most repeat customers return in under 5 months, but a smaller group of slow-returning customers pulls the average upward. This ~4.5-6 month gap is a long re-engagement window for an e-commerce operation and represents a clear opportunity for lifecycle marketing (e.g., a win-back campaign targeted before the 141-day median, rather than waiting passively).

**RFM segmentation caveat:** RFM scoring (Recency, Frequency, Monetary — quintile-based, with hand-set frequency buckets to avoid tie distortion) produced zero customers in the "Top Customers / Champions" segment. This is flagged as a **data characteristic, not a business insight**: recency and frequency scores do not co-occur in this dataset (customers with high order frequency do not also have recent last-order dates), so the standard Champions rule structurally cannot fire. This should be reported honestly as a limitation of the synthetic dataset, not misrepresented as "we have no loyal high-value customers."

**Discount behavior by segment:** Average discount rate ranks Consumer > Corporate > Home Office — Consumer-segment orders receive the deepest average discounting of the three customer segments.

---

## Summary of Root Causes

| Issue | Root Cause | Confidence |
|---|---|---|
| Chronic late delivery (~55-57% overall) | First Class shipping mode, failing near-universally across regions, with no improving trend over time | High — confirmed via mode, region, mode×region, and time-series cuts independently |
| Category/product margin loss | Specific categories (As Seen on TV, Strength Training) and SKUs within them run structurally negative margins, sometimes linked to aggressive discounting | Moderate — category and discount link established; exact loss-making SKU list needs to be re-extracted and documented |
| Customer drop-off after first purchase | 43% never return; among those who do, median 141-day gap before second purchase | High — confirmed via repeat-rate and time-to-second-purchase analysis independently |

## Known Limitations
- Dataset is synthetic (DataCo Kaggle dataset) — flat/structural patterns (e.g., the empty RFM Champions segment, the ~55% late rate baseline) likely reflect how the data was generated rather than real customer or logistics behavior, and are reported as methodology findings rather than business recommendations.
- RFM segment cutoffs (r/f/m score thresholds) are analyst-defined judgment calls, not an industry standard.
- "At risk" customer definition is relative (bottom 40% by recency rank within this dataset), not anchored to a fixed day-count threshold.
