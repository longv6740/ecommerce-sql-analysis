# E-Commerce Growth & Operations Analysis

SQL analysis of an online teddy bear store (March 2012 – March 2015): 472,871 website sessions, 1.19M pageviews and 32,313 orders.

**Tools:** PostgreSQL, DBeaver *(Tableau dashboard coming soon)*

## Data cleaning & audit

→ [`SQL/01_data_cleaning.sql`](SQL/01_data_cleaning.sql)

- **Text "NULL" values.** Empty values in `website_sessions` had been imported as the **text** `'NULL'` instead of real NULLs (83,328 rows in `utm_source`, 39,917 in `http_referer`). This made every `IS NULL` check fail and hid two traffic channels. I converted them into real NULLs inside a transaction before analysis.
- **No duplicate pageviews.** Every page appears at most once per session.
- **Consistency checks.** Every session has exactly one landing page (6 landing pages sum to 472,871 sessions), and every order passed through a billing page (sums to 32,313).

## Key findings

### Business overview
→ [`SQL/02_business_overview.sql`](SQL/02_business_overview.sql)

**1. Overall size.** 32,313 orders worth $1.94M, with an average order value of about $60.

**2. Strong growth, hidden by partial years.** The data covers only 9.5 months of 2012 and 2.5 months of 2015, so yearly totals make 2015 look like a drop. Measured per day, orders grew every year: 9.0 → 20.4 → 46.2 → 69.5 orders/day. Early 2015 runs 50% above the 2014 average, even though it covers only the slower Jan–Mar period.

**3. Revenue grew faster than orders.** Between the two full years (2013 → 2014), orders grew 2.3x while revenue grew 2.7x, because AOV rose from $52.81 to $63.80 as the store added products.

**4. Strong seasonality.** November–December bring about 25% of yearly revenue, with a smaller spike around Valentine's Day.

**5. Conversion doubled.** The share of sessions that became orders rose from 4.14% (2012) to 8.44% (2015). Growth came from more traffic *and* better conversion.

**6. Heavy dependence on paid search.** 82% of traffic comes from paid ads, and Google alone drives 67%. Free channels (organic and direct) convert best at 7.2–7.5%, while socialbook converts at only 3.2%.

**7. The brand is getting stronger.** Free traffic grew from 9% of sessions in 2012 to 23% in 2015, gradually reducing dependence on paid ads.

### Website funnel, A/B tests & landing pages
→ [`SQL/03_funnel_and_landing_pages.sql`](SQL/03_funnel_and_landing_pages.sql)

**8. Mobile is a missed opportunity.** Desktop converts 3x better than mobile (10.6% vs 3.5% in 2015). Mobile brings 30% of sessions but only 13% of orders, and its conversion has barely improved since 2013. Raising mobile conversion to just 5% would add ~5% more orders without extra ad spend.

**9. Where the funnel leaks.** Only 6.8% of sessions reach an order. The biggest leaks are the product page (only 45% add to cart) and the landing page (45% leave immediately, ~212K sessions). Even at the final billing step, 38% of sessions abandon.

**10. Billing A/B test.** Comparing the full lifetimes of the two billing pages is unfair, because the new page ran in later, stronger years. In the period when both pages ran (Sep 2012 – Jan 2013, ~1,660 sessions each), the new billing page converted 62.1% vs 45.1% for the old one, a 38% relative lift. Rolling it out to all traffic likely added ~8,000 orders (~$480K) over the following two years (estimate).

**11. Landing pages must be compared within the same device.** At first look, lander-3 seemed to be the worst landing page (3.39% conversion). Segmenting by device showed that lander-3 received 100% mobile traffic, while lander-4 and lander-5 received 100% desktop. Compared within the same device, lander-3 is actually the **best** mobile page (3.39% vs 2.96% for /home on mobile). It replaced lander-2 on mobile in July 2013.

**12. Each new landing page beat the previous one.** On desktop: lander-1 (5.3%) → lander-2 (8.0%) → lander-5 (10.2%). On mobile: lander-1 (1.6%) → lander-2 (2.8%) → lander-3 (3.4%). Part of this gain reflects the store improving over time.

## Recommendations (so far)

1. **Fix the mobile experience**, especially checkout, since mobile brings 30% of traffic but converts at a third of the desktop rate.
2. **Improve the product page**, the funnel's weakest step: test better photos, clearer shipping costs and reviews.
3. **Plan stock and ad spend around November–December and Valentine's Day.**
4. **Reduce dependence on Google Ads** by continuing to grow free traffic, and review socialbook spend given its low conversion.

## Limitations

- The data has no advertising costs, so channel profitability (ROI) can't be measured.
- 2012 and 2015 are partial years; they are compared with per-day rates or percentages only.
- Landing page comparisons across different time periods are partly affected by the store's overall improvement over time.

## Next steps

- Products, cross-selling and refunds
- Customer cohorts and repeat purchases
- Tableau dashboard
