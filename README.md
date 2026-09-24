# E-Commerce Growth & Operations Analysis

SQL analysis of an online teddy bear store (March 2012 – March 2015): 472,871 website sessions and 32,313 orders.

**Tools:** PostgreSQL, DBeaver *(Tableau dashboard coming soon)*

## Data cleaning

During the audit, I found that empty values in `website_sessions` had been imported as the **text** `'NULL'` instead of real NULLs (83,328 rows in `utm_source`, 39,917 in `http_referer`). This made every `IS NULL` check fail and hid two traffic channels. I converted them into real NULLs inside a transaction before analysis. → [`sql/01_data_cleaning.sql`](sql/01_data_cleaning.sql)

## Key findings

→ Queries: [`sql/02_business_overview.sql`](sql/02_business_overview.sql)

**1. Overall size.** 32,313 orders worth $1.94M, with an average order value of about $60.

**2. Strong growth, hidden by partial years.** The data covers only 9.5 months of 2012 and 2.5 months of 2015, so yearly totals make 2015 look like a drop. Measured per day, orders grew every year: 9.0 → 20.4 → 46.2 → 69.5 orders/day. Early 2015 runs 50% above the 2014 average, even though it covers only the slower Jan–Mar period.

**3. Revenue grew faster than orders.** Between the two full years (2013 → 2014), orders grew 2.3x while revenue grew 2.7x, because AOV rose from $52.81 to $63.80 as the store added products.

**4. Strong seasonality.** November–December bring about 25% of yearly revenue, with a smaller spike around Valentine's Day.

**5. Conversion doubled.** The share of sessions that became orders rose from 4.14% (2012) to 8.44% (2015). Growth came from more traffic *and* better conversion.

**6. Heavy dependence on paid search.** 82% of traffic comes from paid ads, and Google alone drives 67%. Free channels (organic and direct) convert best at 7.2–7.5%, while socialbook converts at only 3.2%.

**7. The brand is getting stronger.** Free traffic grew from 9% of sessions in 2012 to 23% in 2015, gradually reducing dependence on paid ads.

## Limitations

- The data has no advertising costs, so channel profitability (ROI) can't be measured.
- 2012 and 2015 are partial years; they are compared with per-day rates or percentages only.

## Next steps

- Device analysis (desktop vs mobile)
- Website funnel: where visitors drop off
- Products, cross-selling and refunds
- Customer cohorts and repeat purchases
- Tableau dashboard
