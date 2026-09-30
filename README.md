# DataCo Supply Chain Analytics

End-to-end SQL analysis and Power BI dashboard on the DataCo Smart Supply Chain dataset (~65K orders, ~20K customers, ~180K line items) — covering delivery performance, product profitability, and customer retention/RFM segmentation.

## Dashboard

[Watch the walkthrough on LinkedIn](https://www.linkedin.com/feed/update/urn:li:activity:7511072443474583552/)

4-page Power BI report: Executive Overview, Delivery Performance, Product Profitability, Customer Analytics.

## Tech Stack

- **Database:** PostgreSQL (hosted on Neon)
- **Analysis:** Advanced SQL — CTEs, window functions (NTILE, LAG, LEAD, ROW_NUMBER, PARTITION BY), statistical thresholding (mean + standard deviation outlier detection)
- **Visualization:** Power BI, DAX (CALCULATE, DIVIDE, time intelligence, CROSSFILTER)

## Business Questions Answered

- Which shipping mode and region combinations are driving late delivery?
- Is delivery performance improving, worsening, or flat over time?
- Which products and categories are profitable vs. loss-making, and is discounting a driver?
- How well does the business retain customers after a first purchase, and how long does it take them to come back?
- How do customers segment by recency, frequency, and monetary value (RFM)?

## Key Findings

- **First Class shipping is the dominant driver of late delivery**, running a 95% late rate — failing near-universally across regions (up to 100% in some), despite carrying the highest profit margin of any shipping mode. Full breakdown in [`RCA.md`](RCA.md).
- Late delivery has held flat at ~55% for the full multi-year period — a structural issue, not a seasonal spike or a worsening trend.
- 43% of customers never return after their first order; among repeat customers, the median time to a second purchase is 141 days.
- Category-level margin analysis surfaced specific loss-making categories and SKUs, with discounting behavior identified as a contributing factor for a subset of products.

See [`RCA.md`](RCA.md) for the full root cause analysis, including methodology notes and dataset limitations.

## Repo Structure

```
├── Code.sql          # All analysis queries, organized by domain (logistics, customer, product)
├── RCA.md            # Root cause analysis write-up
└── README.md
```

## Notes on Methodology

- All rate/aggregate metrics use `COUNT(DISTINCT ...)` consistently across numerator and denominator to avoid inflation from the line-item grain of the source tables.
- Outlier/hotspot detection uses a mean + 1 standard deviation threshold rather than a fixed cutoff, so it adapts if the underlying data changes.
- RFM frequency scoring uses manually-set buckets instead of NTILE, since a large share of customers share identical order counts (NTILE would arbitrarily split tied customers into different score buckets).
- This is a synthetic dataset (DataCo, via Kaggle). Some patterns — such as the flat ~55% late-delivery baseline and an empty RFM "Champions" segment — are treated as dataset characteristics rather than real business insights, and are reported as such in `RCA.md`.
