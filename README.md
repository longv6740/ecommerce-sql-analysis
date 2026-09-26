# E-Commerce Growth & Operations Analysis

SQL analysis of an online teddy bear store (March 2012 – March 2015): 472,871 website sessions, 1.19M pageviews and 32,313 orders.

**Tools:** PostgreSQL, DBeaver, Tableau

## 📊 Interactive dashboard

**[View the live dashboard on Tableau Public →](https://public.tableau.com/app/profile/vu.hoang.long/viz/EcommGrowthTableau/E-CommerceGrowthDashboardMar2012Feb2015)**

![E-Commerce Growth Dashboard](E-Commerce Growth Dashboard (Mar 2012 – Feb 2015).png)

The dashboard shows headline KPIs, monthly revenue, conversion by device, the website funnel, and product performance. All metrics are calculated in SQL, and Tableau only visualizes the results. The partial month of March 2015 is excluded from the monthly charts. The workbook file is included as [`Ecomm_Dashboard.twbx`](Ecomm_Dashboard.twbx).

## Data cleaning & audit

→ [`SQL/01_data_cleaning.sql`](SQL/01_data_cleaning.sql)

- **Text "NULL" values.** Empty values in `website_sessions` had been imported as the **text** `'NULL'` instead of real NULLs (83,328 rows in `utm_source`, 39,917 in `http_referer`). This made every `IS NULL` check fail and hid two traffic channels. I converted them into real NULLs inside a transaction before analysis.
- **Broken primary-item flag.** After import, `is_primary_item` in `order_items` was FALSE for all 40,025 items, which is impossible, since every order has exactly one main item. I rebuilt it from `orders.primary_product_id` and verified the result against known totals: 32,313 primary items (one per order) and 7,712 add-ons (items − orders).
- **Broken repeat-session flag.** `is_repeat_session` was also FALSE for all 472,871 sessions, the same boolean import bug (every boolean column was affected). I rebuilt it from each user's first session and verified it: 394,318 first visits (exactly one per user) and 78,553 return visits.
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

### Products, cross-selling & refunds
→ [`SQL/04_product_analysis.sql`](SQL/04_product_analysis.sql)

**13. One product drives the business.** Mr. Fuzzy brings 62% of revenue, a single-product dependency risk. The newer products have higher margins (Sugar Panda 68.5%, Mini Bear 68.4%), and Love Bear earns the most profit per item ($37.50) thanks to its higher price.

**14. Totals hide the fastest-selling products.** Adjusted for time on sale, the Mini Bear is the fastest-selling new product (12.3 items/day), ahead of Sugar Panda (10.8) and Love Bear (7.2), even though it looked weakest by total items.

**15. The Mini Bear is a cross-sell product.** 88% of its sales are add-ons to another bear. Mr. Fuzzy is a destination product, sold as an add-on only 1.5% of the time.

**16. Cross-selling works, with room to grow.** Since all four products have been on sale (Feb 2014 onward), 35% of orders include an add-on. The Mini Bear is the top add-on for every main bear and makes up 60% of all add-ons. Love Bear buyers add the least (25%). A 2-item order is worth about $38 more than a 1-item order.

**17. Refunds cost 4.4% of revenue.** Refunds total $85K. Sugar Panda has the highest refund rate (6.0%), erasing 8.8% of its profit and weakening its best-margin advantage, while Mr. Fuzzy accounts for 72% of refunded money due to its volume.

**18. Refund spikes point to quality incidents, not seasonality.** Mr. Fuzzy's refund rate spiked in September 2012 (9.1%) and August–September 2014 (peaking at 13.3%, more than double its normal 5.1%), then returned to normal, while September 2013 was normal. This suggests specific quality incidents that were resolved. (The data has no refund reasons, so the cause can't be confirmed.)

### Customers & retention
→ [`SQL/05_customer_analysis.sql`](SQL/05_customer_analysis.sql)

**19. Almost every customer buys once.** 98% of customers order only once (591 of 31,696 ever reorder). This is partly natural for gift products, but combined with 82% paid traffic, it means the store pays to acquire nearly every order.

**20. Visitors often need time to decide, and come back for free.** 17% of sessions are return visits, and two-thirds of them come back through free channels (vs 8% for first visits). Return visits convert better (7.8% vs 6.6%) and produce 19% of all orders, mostly first purchases by visitors who came back later. Each paid click keeps generating value after the first visit.

**21. Repeat buyers return within about a month.** The median gap between first and last order is 33 days (average 37, mildly skewed right by a few slower customers), and no customer returned after 118 days.

**22. Repeat customers are worth more, but they are not the main lever.** Repeat customers are worth 2.1x more ($125.81 vs $59.93), but they are only 1.9% of customers and 3.8% of revenue. Even doubling them would add only ~2% revenue, so improving conversion and cross-selling are bigger levers than retention for this gift-driven business.

## Recommendations

Roughly ranked by expected impact:

1. **Fix the mobile experience**, especially checkout. Mobile brings 30% of traffic but converts at a third of the desktop rate; raising mobile conversion to just 5% would add ~5% more orders without extra ad spend.
2. **Grow cross-selling.** Bundle the Mini Bear on the cart page with every main bear, and test a Love Bear couple bundle for Valentine's Day. Each add-on is worth ~$38, and 65% of orders still have none.
3. **Improve the product page**, the funnel's weakest step (only 45% add to cart): test better photos, clearer shipping costs and reviews.
4. **Plan stock and ad spend around November–December and Valentine's Day.**
5. **Monitor refund rates monthly per product**, with an alert when a product's rate exceeds twice its normal level. The 2014 Mr. Fuzzy incident lasted two months.
6. **Reduce dependence on Google Ads** by continuing to grow free traffic, and review socialbook spend given its low conversion.
7. **Send re-engagement emails within the first month after purchase**, when repeat buyers usually return, timed around gift occasions. A smaller but cheap win.

## Limitations

- The data has no advertising costs, so channel profitability (ROI) can't be measured.
- 2012 and 2015 are partial years; they are compared with per-day rates or percentages only.
- Landing page comparisons across different time periods are partly affected by the store's overall improvement over time.
- The data has no refund reasons, so the causes of refund spikes are inferred, not confirmed.

## Possible extensions

- Compare landing pages only during periods when they ran at the same time, to separate page effects from overall store improvement.
- Add advertising cost data, if available, to measure profitability (ROI) by channel.
- Connect Tableau directly to PostgreSQL instead of CSV exports, so the dashboard refreshes automatically.
