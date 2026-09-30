ALTER TABLE dim_customers ADD Primary key(customer_id);
ALTER TABLE dim_products ADD Primary key(product_card_id);
ALTER TABLE dim_logistics ADD Primary key(logistics_id);
ALTER TABLE dim_orders ADD Primary key(order_id);
ALTER TABLE dim_orders_items ADD CONSTRAINT pk_dim_orders_items Primary key(order_item_key)
  
CREATE VIEW dim_orders_items_analytics AS
  select order_id, product_card_id, order_item_key,
       order_item_quantity, order_item_product_price,
       order_item_discount, order_item_discount_rate,
       order_item_total, order_item_profit_ratio
  from dim_orders_items
  
CREATE VIEW dim_orders_items_unique AS
  SELECT order_id, customer_id,
       sales, sales_per_customer,
       benefit_per_order, order_profit_per_order
  FROM dim_orders_items 

  CREATE VIEW rfm_segments AS
  with RFM_base as (SELECT 
  c.customer_id, 
  MAX(o.order_date) as recency,
  COUNT(DISTINCT o.order_id) as frequency,
  SUM(oi.sales) as monetary 
FROM dim_customers c 
LEFT JOIN dim_orders_items oi ON c.customer_id = oi.customer_id
LEFT JOIN dim_orders o ON o.order_id = oi.order_id
GROUP BY c.customer_id
  HAVING MAX(o.order_date) is not NULL),
rfm_scores AS(SELECT 
  *,
  --recency determination
  NTILE(5) over(ORDER by recency ASC) AS r_score,
  --frequency determination
  CASE WHEN frequency=1 THEN 1
  WHEN frequency<=3 THEN 2
  WHEN frequency=4 THEN 3
  WHEN frequency<=6 THEN 4
  ELSE 5
  END AS f_score,
  --monetary determination
  NTILE(5) over(ORDER BY monetary ASC) AS m_score
  FROM RFM_base
  )
  SELECT *, CASE WHEN r_score>=4 AND f_score>=4 and m_score>=4 THEN 'Top customers'
  WHEN r_score>=3 AND f_score >=3 THEN 'Loyal Customer Base'
  WHEN r_score>=4 AND f_score <=2 THEN 'New Customers'
  WHEN r_score<=2 AND f_score>=3 THEN 'At risk customers'
  WHEN r_score<=2 AND f_score<=2 THEN 'Lost'
  ELSE 'Needs Attention' END AS segment
  FROM rfm_scores
  

/* Adding foreign keys to establish relationship among tables */
Alter table dim_orders_items
ADD Constraint fk_fact_cust Foreign Key(customer_id) references dim_customers(customer_id),
ADD Constraint fk_fact_prod Foreign Key(product_card_id) references dim_products(product_card_id),
ADD Constraint fk_fact_log Foreign Key(logistics_id) references dim_logistics(logistics_id),
ALTER TABLE dim_orders_items ADD CONSTRAINT fk_dim_order_items_orders FOREIGN KEY (order_id) REFERENCES dim_orders(order_id);

--SUPPLY CHAIN MANAGEMENT
--LATE DELIVERY RATE BY SHIPPING MODE
SELECT
  l.shipping_mode, count(distinct oi.order_id) as total_orders,
  count(distinct case when l.delivery_status='Late delivery' then oi.order_id end) as late_orders,
  round(100.0*count(DISTINCT CASE WHEN l.delivery_status='Late delivery' then oi.order_id END)/count(DISTINCT oi.order_id),2) as l_orders_rate
  FROM dim_logistics l left join dim_orders_items oi on 
  l.logistics_id=oi.logistics_id
  group by l.shipping_mode
  order by l_orders_rate desc 
--Conclusion: First class and Second Class have late delivery rate of 95 and 76 percent respectively followed by same day and standard class with 46 and 38 respectively

select l.delivery_status,COUNT(DISTINCT oi.order_id) as Total_orders,
  COUNT(DISTINCT CASE WHEN )
  
  from dim_logistics l left join dim_orders_items oi on l.logistics_id=oi.logistics_id
limit 10

--LATE DELIVERY VS ACTUAL DELIVERY ESTIMATE
SELECT count(DISTINCT order_id) as total_orders, 
count(DISTINCT CASE WHEN days_for_shipping>days_for_shipment THEN order_id END)as late_delivery,
count(DISTINCT CASE WHEN days_for_shipping<days_for_shipment THEN order_id END)as before_time,
  count(DISTINCT CASE WHEN days_for_shipping=days_for_shipment THEN order_id END)as on_time,
round(100.0*count(DISTINCT CASE WHEN days_for_shipping>days_for_shipment THEN order_id END)/count(distinct order_id),2) as late_time_rate,
round(100.0*count(DISTINCT CASE WHEN days_for_shipping<days_for_shipment THEN order_id END)/count(distinct order_id),2) as before_time_rate,
round(100.0*count(DISTINCT CASE WHEN days_for_shipping=days_for_shipment THEN order_id END)/count(distinct order_id),2) as on_time  
FROM dim_orders 
--COUNCLUSION TOTAL unique orders are 65K where 57% percent are late, only 24% are before time and 18 on actual promised days

--LATE DELIVERY BY REGION
SELECT order_region,market,
  COUNT(DISTINCT order_id) as Total_orders,
  count(DISTINCT CASE WHEN days_for_shipping>days_for_shipment THEN order_id END)as late_delivery,
count(DISTINCT CASE WHEN days_for_shipping<days_for_shipment THEN order_id END)as before_time,
  count(DISTINCT CASE WHEN days_for_shipping=days_for_shipment THEN order_id END)as on_time,
round(100.0*count(DISTINCT CASE WHEN days_for_shipping>days_for_shipment THEN order_id END)/count(distinct order_id),2) as late_time_rate,
round(100.0*count(DISTINCT CASE WHEN days_for_shipping<days_for_shipment THEN order_id END)/count(distinct order_id),2) as before_time_rate,
round(100.0*count(DISTINCT CASE WHEN days_for_shipping=days_for_shipment THEN order_id END)/count(distinct order_id),2) as on_time_rate
  FROM dim_orders 
GROUP BY order_region,market
  order by late_time_rate DESC,before_time_rate DESC,on_time_rate DESC
--CONCLUSION: central Africa, east africa and south usa experince the highest late delivery rate around 60,58 and 58% respectively

--AVERAGE ACTUAL VS SCHEDULED SHIPPING DAY
with ORDER_X AS (
SELECT l.shipping_mode as shipping_mode, o.order_id as order_id,
o.days_for_shipping as actual_d_days,o.days_for_shipment as estimated_d_days 
from dim_orders o left join dim_orders_items oi on o.order_id=oi.order_id LEFT JOIN
dim_logistics l on oi.logistics_id=l.logistics_id
)
SELECT shipping_mode,count(distinct order_id) as total_orders,
round(avg(actual_d_days),2) as actual_delivery_day,
round(avg(estimated_d_days),2) as estimated_deliver_day,
round(avg(actual_d_days-estimated_d_days),2) as delay_days
FROM order_x
GROUP BY shipping_mode
ORDER BY delay_days DESC
--CONCLUSION: Second class and First class take avg of 2 delay days for delivery, standard class being 0 for delay

--ORDER BY MONTH AND QUARTER
SELECT DAte_Trunc('month',o.order_date) as month,
  extract(quarter from o.order_date) as quarter_count,
  count(o.order_id) as order_count,
  SUM(oi.sales)::NUMERIC as Total_sales
  FROM dim_orders o left join dim_orders_items oi on o.order_id=oi.order_id
  group by DAte_Trunc('month',order_date), quarter_count
  order by Total_sales DESC
--CONCLUSION:by month october 2017 made the most sales 

--ORDER CANCELLATION RATE BY SHIPPING MODE
with cancellation as (SELECT l.shipping_mode as shipping_mode,
COUNT(DISTINCT o.order_id) as Total_orders,
COUNT(DISTINCT CASE WHEN o.order_status='CANCELED' THEN o.order_id END)as Cancelled_order
FROM dim_orders o LEFT JOIN dim_orders_items oi on o.order_id=oi.order_id
LEFT JOIN dim_logistics l on oi.logistics_id=l.logistics_id
GROUP BY l.shipping_mode)

SELECT shipping_mode,Total_orders,Cancelled_order,
round(100.0*Cancelled_order::NUMERIC/Total_orders,2) as Cancellation_rate
FROM cancellation 
ORDER BY Cancellation_rate DESC
--conclusion: Same day shipping mode has most cancelled order followed by first class and standard class
-- with rate of 2.27, 2.22 and 2.06. 

--PROFIT MARGIN BY SHIPPING MODE
SELECT l.shipping_mode as ship_mode,count(DISTINCT oi.order_id) as order_id,
sum(oi.sales)as totl_sales,
sum(oi.benefit_per_order) as total_profit,
round((100.0*sum(oi.benefit_per_order)/sum(oi.sales))::NUMERIC,2) as margin
FROM dim_orders_items oi LEFT JOIN dim_logistics l 
on oi.logistics_id=l.logistics_id
group by shipping_mode
order by margin DESC
--Conclusion First class has higher margin of 11.8%, Second class and standard class  has 10.78%, same day 9.8%

--Ranking shipping mode by region and their late delivery rate
with rank_mode as (SELECT shipping_mode,
  o.order_region,
  count(DISTINCT o.order_id) as total_orders,
  count(distinct case when l.delivery_status='Late delivery' then o.order_id end) as late_orders,
  round(100.0*count(DISTINCT case when l.delivery_status='Late delivery' then o.order_id end)/count(distinct o.order_id),2) as late_delivery
  from dim_logistics l left join dim_orders_items oi ON
l.logistics_id=oi.logistics_id left join dim_orders o on oi.order_id=o.order_id
group by l.shipping_mode,o.order_region)

  SELECT shipping_mode,order_region,late_delivery,ROW_NUMBER() over(
  PARTITION by shipping_mode order by late_delivery
  ) as rnk from rank_mode
  order by shipping_mode,rnk 

  --conclusion: FIRST CLASS mode in regions like canada central africa have high late delivery
  --mostly first class is failing to delivery on time with rate of 91%
  --in central asia, sourthern africa the rate is around 100% failing in regions like that for first class

--MONTH OVER MONTH late delivery trend
  with MOM as (SELECT
  DAte_trunc('month',o.order_date) as order_month,
  count(DISTINCT case when l.late_delivery_risk=1 then o.order_id end) as late_delivery,
  count(DISTINCT o.order_id) as total_orders,
  round(100.0*COUNT(DISTINCT CASE WHEN l.late_delivery_risk=1 then o.order_id end)/COUNT(DISTINCT o.order_id),2) as late_delivery_rate
  FROM dim_logistics l LEFT JOIN dim_orders_items oi on l.logistics_id=oi.logistics_id
  LEFT JOIN dim_orders o on oi.order_id=o.order_id
  GROUP by Date_trunc('month',o.order_date))

  SELECT order_month, total_orders, late_delivery, late_delivery_rate,
  LAG(late_delivery_rate) OVER(ORDER BY order_month) as prev_month,
  round(late_delivery_rate-lag(late_delivery_rate) over(ORDER BY order_month),2) as month_change_rate
  FROM MOM 
  ORDER BY order_month DESC
  --CONCLUSION: LATE DELIVERY is nearly 55% across all dataset with a increase over every month
  --meaning business is failing to delivery at time. Month over month increasing by small volume
  --LAte delivery is stably same across all

  --CUMMULATIVE ORDER OVER TIME
  with running_count as (SELECT DATE_TRUNC('month',order_date) as Month, 
  COUNT(DISTINCT order_id) as Order_Count
  FROM dim_orders
  GROUP BY DATE_TRUNC('month',order_date))

  SELECT Month, Order_Count,
  Sum(Order_Count) OVER(ORDER BY Month) as cum_run_sum
  FROM running_count
  group by Month, Order_Count
  ORDER BY MONTH ASC
  --CONCLUSION: Every month order count varies by small points, either declining or increasing by small margin
  --meaning business isnt performing very well

  --Outlier/Exception Analysis/Hotspot analysis identifying shipping mode–region combinations with 
  --late delivery rates exceeding the statistical threshold
  With modexregion as (SELECT
  l.shipping_mode,o.order_region,
  count(DISTINCT case when l.late_delivery_risk=1 then o.order_id end) as late_delivery,
  count(DISTINCT o.order_id) as total_orders,
  round(100.0*COUNT(DISTINCT CASE WHEN l.late_delivery_risk=1 then o.order_id end)/COUNT(DISTINCT o.order_id),2) as late_rate
  FROM dim_logistics l LEFT JOIN dim_orders_items oi on l.logistics_id=oi.logistics_id
  LEFT JOIN dim_orders o on oi.order_id=o.order_id
  GROUP by l.shipping_mode,o.order_region),
  deviation as(
  SELECT AVG(late_rate) as avg_late_rate,
  STDDEV(late_rate) as varied_rate
  FROM modexregion
  )
  SELECT m.shipping_mode, m.order_region,m.total_orders,m.late_rate,
  round(d.avg_late_rate::numeric,2) as avg_late_rate,
  round(d.avg_late_rate+d.varied_rate::numeric,2) as threshold
  FROM modexregion m CROSS JOIN deviation d
  WHERE m.late_rate>d.avg_late_rate+d.varied_rate
  ORDER BY m.late_rate DESC
  --CONCLUSION first class mode is failing almost in all regions even in central asia with total orders
  --19 with 100& late rate

  --Year-over-year comparison of average shipping delay
  with YOY as (SELECT EXTRACT(month from o.order_date) as o_month,
  EXTRACT(YEAR FROM o.order_date) as o_year,
  COUNT(DISTINCT o.order_id) as o_count,
  COUNT(DISTINCT CASE WHEN l.late_delivery_risk=1 THEN o.order_id END) as late_delivery,
  round(100.0*COUNT(DISTINCT CASE when l.late_delivery_risk=1 THEN o.order_id END)/COUNT(DISTINCT o.order_id),2) as late_d_rate
  FROM dim_orders o  LEFT JOIN dim_orders_items oi on o.order_id=oi.order_id LEFT JOIN
  dim_logistics l on oi.logistics_id=l.logistics_id
  GROUP BY EXTRACT(month from o.order_date),
  EXTRACT(YEAR FROM o.order_date))

  SELECT o_month, o_year,late_delivery, late_d_rate,
  LAG(late_d_rate) over(PARTITION BY o_month ORDER BY o_year) as prev_year,
  round(late_d_rate-lag(late_d_rate) over(PARTITION by o_month ORDER BY o_year),2) as YOY_rate_change
  FROM YOY 
  ORDER BY o_month, o_year
  --baseline late delivery is constant throught years, not improving/worsening over timee

  --Late delivery risk by order-size buckets//ORDER SIZE SEGMENTATION ANALYSIS
 with bucket as  (SELECT order_id,sum(order_item_quantity) as bucket_size
  from dim_orders_items
  group by order_id),
  order_dim as (
  SELECT b.order_id, b.bucket_size,
  l.late_delivery_risk,CASE WHEN bucket_size=1 THEN 'Small (1)items'
  WHEN bucket_size BETWEEN 2 and 3 THEN 'Medium (2-3) items'
  ELSE 'Large (4+) items'
  END AS size_bucket FROM bucket b LEFT JOIN dim_orders_items oi on b.order_id=oi.order_id
  LEFT JOIN dim_logistics l on oi.logistics_id=l.logistics_id)

  SELECT size_bucket, count(DISTINCT order_id) as total_orders,
  count(DISTINCT CASE WHEN late_delivery_risk = 1 THEN order_id END) as late_orders,
  round(100.0 * count(DISTINCT CASE WHEN late_delivery_risk = 1 THEN order_id END) 
        / count(DISTINCT order_id), 2) as late_rate
FROM order_dim
GROUP BY size_bucket
ORDER BY late_rate DESC;
--nearly 50% orders are late, with small items having a late rate of 55% and large orders with 50%
-- having a diffference of 5 points among each other


/*PRODUCT ANALYTICS*/
SELECT p.category_name, SUM(sales)::NUMERIC as Total_sales
  from dim_products p left join dim_orders_items oi 
  on p.product_card_id=oi.product_card_id
  GROUP BY p.category_name
  ORDER BY Total_sales DESC
  --MEN FOOTWEAR has highest sales,followed by fishing and water sports
  --AS seen on tV, toys, CD have the lowest sales among all
  --Mostly high sales lies on Sports category/capmping and stuff

  --Top 10 best selling products by quantity
  SELECT p.product_name,SUM(order_item_quantity) as Quantity,
  SUM(order_item_product_price*order_item_quantity)AS price_total
  FROM dim_products p LEFT JOIN dim_orders_items oi ON
  p.product_card_id=oi.product_card_id
  GROUP BY p.product_name
  ORDER BY Quantity DESC 
  limit 10

  --Top 10 products by total profit
  SELECT p.product_name,SUM(order_item_quantity) as Quantity,
  SUM(benefit_per_order)AS price_total
  FROM dim_products p LEFT JOIN dim_orders_items oi ON
  p.product_card_id=oi.product_card_id
  GROUP BY p.product_card_id
  ORDER BY price_total DESC 
  limit 10

  --Bottom 10 products by profit (loss-makers)
  SELECT p.product_name,SUM(order_item_quantity) as Quantity,
  SUM(benefit_per_order)AS price_total
  FROM dim_products p LEFT JOIN dim_orders_items oi ON
  p.product_card_id=oi.product_card_id
  GROUP BY p.product_name
  HAVING sum(oi.benefit_per_order)<0
  ORDER BY price_total DESC
  --There are 6 products with total 3 category that are loss makers for business

  --Products with the highest discount rates //Discount markdown analysis
  SELECT p.product_name,
  MAX(oi.order_item_discount_rate) as highest_discount FROM dim_products p 
  LEFT JOIN dim_orders_items oi on p.product_card_id=oi.product_card_id
  GROUP BY p.product_name
  ORDER BY highest_discount DESC

  --Profit margin by product category
  SELECT p.category_name,sum(oi.benefit_per_order) as profit,
  SUM(oi.sales) as Total_sales,
  round((100.0*SUM(oi.benefit_per_order)/SUM(oi.sales))::NUMERIC,2) as profit_margin
  FROM dim_products p LEFT JOIN dim_orders_items oi ON
  p.product_card_id=oi.product_card_id
  GROUP BY p.category_name
  ORDER BY profit_margin DESC
  --conclusion: golf bags and carts have highest profit margin, followed by fitness accessories,
  --basket ball, as seen on tv and strength training givw negative profit margin
  
     --products with high discount and low profit margin/sku identifaction
  with product_metric as (SELECT p.product_card_id,
  p.product_name, avg(oi.order_item_discount_rate) as avg_discount,sum(oi.benefit_per_order) as profit,
  sum(sales) as total_sales,
  round((100.0*sum(oi.benefit_per_order)/sum(sales))::numeric,2) as profit_margin
  FROM dim_products p LEFT JOIN dim_orders_items oi ON
  p.product_card_id=oi.product_card_id
  group by p.product_card_id, p.product_name),

  threshold as (
  SELECT avg(avg_discount)+stddev(avg_discount) as overall_avg_discount,
  avg(profit_margin)- stddev(profit_margin) as overall_avg_margin
  FROM product_metric
  )
  SELECT pm.* from product_metric pm cross JOIN threshold t 
  WHERE pm.avg_discount>t.overall_avg_discount and pm.profit_margin<t.overall_avg_margin
  ORDER BY pm.avg_discount DESC,pm.profit_margin ASC
  --conclusion: 



  /*CUSTOMER ANALYTICS*/
SELECT c.customer_id,c.customer_segment,
count(oi.order_id) as total_orders, sum(oi.sales) as Total_revenue
from dim_customers c LEFT JOIN dim_orders_items oi on c.customer_id=oi.customer_id 
GROUP BY c.customer_id, c.customer_segment
ORDER BY total_orders DESC, Total_revenue DESC

--average order value
SELECT c.customer_id, c.customer_segment,
count(oi.order_id) as total_orders,sum(oi.sales) as tot_revenue,
round((100.0*count(oi.order_id)/sum(oi.sales))::NUMERIC,2) as average_order_value
from dim_customers c LEFT JOIN dim_orders_items oi on c.customer_id=oi.customer_id
group by c.customer_id,c.customer_segment
ORDER BY average_order_value DESC

--Top 10 customers by profit genrated// customer profitablitly analysis
SELECT c.customer_id,sum(oi.benefit_per_order) as Total_profit
FROM dim_customers c LEFT JOIN dim_orders_items oi ON
c.customer_id=oi.customer_id 
GROUP BY c.customer_id
ORDER BY Total_profit DESC

--Number of orders per customer (distribution) Customer Order Frequency Distribution
SELECT c.customer_id,count(DISTINCT oi.order_id) as order_count
FROM dim_customers c LEFT JOIN dim_orders_items oi ON
c.customer_id=oi.customer_id
GROUP BY c.customer_id
ORDER BY order_count DESC

--Customer Retention Segmentation
with customer_stats as (
SELECT c.customer_id,count(DISTINCT oi.order_id) as order_count
FROM dim_customers c LEFT JOIN dim_orders_items oi ON
c.customer_id=oi.customer_id
GROUP BY c.customer_id
ORDER BY order_count DESC
)
SELECT CASE WHEN order_count=1 THEN 'One time buyer'
WHEN order_count>1 THEN 'Repeat buyer'
ELSE 'No orders' END as buyer_type,
COUNT(customer_id) as customer_count,
round((100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER())::NUMERIC, 2) as pct_customer
FROM customer_stats
GROUP BY CASE WHEN order_count=1 THEN 'One time buyer'
WHEN order_count>1 THEN 'Repeat buyer'
ELSE 'No orders' END
ORDER BY customer_count DESC
--Conclusion: 56% customer came and bought again
--43% turned one time buyer

--Discount Behavior by Segment
  SELECT c.customer_segment,
  round(AVG(oi.order_item_discount_rate)::numeric,4) as discount_rate,
  count(distinct oi.order_id) as total_orders FROM dim_customers c LEFT JOIN 
 dim_orders_items oi on c.customer_id=oi.customer_id 
GROUP BY customer_segment ORDER BY discount_rate DESC
--Cocnlusion: consumer>corporate>Homeoffice

--Geographic concentration by customer_count  
SELECT count(distinct c.customer_id) as customer_count, c.customer_city as city 
FROM dim_customers c
GROUP by c.customer_city 
ORDER BY customer_count DESC
LIMIT 10

--RFM SEgmentation
with RFM_base as (SELECT 
  c.customer_id, 
  MAX(o.order_date) as recency,
  COUNT(DISTINCT o.order_id) as frequency,
  SUM(oi.sales) as monetary 
FROM dim_customers c 
LEFT JOIN dim_orders_items oi ON c.customer_id = oi.customer_id
LEFT JOIN dim_orders o ON o.order_id = oi.order_id
GROUP BY c.customer_id
  HAVING MAX(o.order_date) is not NULL),
rfm_scores AS(SELECT 
  *,
  --recency determination
  NTILE(5) over(ORDER by recency ASC) AS r_score,
  --frequency determination
  CASE WHEN frequency=1 THEN 1
  WHEN frequency<=3 THEN 2
  WHEN frequency=4 THEN 3
  WHEN frequency<=6 THEN 4
  ELSE 5
  END AS f_score,
  --monetary determination
  NTILE(5) over(ORDER BY monetary ASC) AS m_score
  FROM RFM_base
  ),
  rfm_segments AS(
  SELECT *, CASE WHEN r_score>=4 AND f_score>=4 and m_score>=4 THEN 'Top customers'
  WHEN r_score>=3 AND f_score >=3 THEN 'Loyal Customer Base'
  WHEN r_score>=4 AND f_score <=2 THEN 'New Customers'
  WHEN r_score<=2 AND f_score>=3 THEN 'At risk customers'
  WHEN r_score<=2 AND f_score<=2 THEN 'Lost'
  ELSE 'Needs Attention' END AS segment
  FROM rfm_scores
  )
  -- add after your rfm_segments CTE
SELECT segment, 
       COUNT(*) AS customers,
       round((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct_of_customers,
       round(AVG(frequency)::numeric, 1) AS avg_orders,
       round(AVG(monetary)::numeric, 2) AS avg_spend
FROM rfm_segments
GROUP BY segment
ORDER BY customers DESC;
--conclusion:The empty "Top customers" segment is almost certainly a property of this synthetic dataset, not real behavior. 
--I'd report it as "recency and frequency don't co-occur in this data, so the standard Champions rule can't fire," not as a business insight. 
--The segment cutoffs are also my own judgment calls, 
--not an industry standard, and "At risk" is defined relatively (bottom 40% by recency), not by a fixed number of days

--CUSTOMER REPEAT RATE
WITH customer_stats as(select DISTINCT c.customer_id,c.customer_segment,
  o.order_date,o.order_id
  FROM dim_customers c LEFT JOIN dim_orders_items oi ON 
  c.customer_id=oi.customer_id LEFT JOIN dim_orders o ON
  oi.order_id=o.order_id),
  customer_rank as (SELECT customer_id,customer_segment,
  order_date,order_id, ROW_NUMBER() OVER(
  PARTITION BY customer_id ORDER BY order_date,order_id
  ) as order_sequence
  FROM customer_stats)
  SELECT customer_segment, count(DISTINCT customer_id) as customer,
  count(distinct CASE WHEN order_sequence>=2 THEN customer_id END) as repeat_customer,
  round((100.0*count(distinct CASE WHEN order_sequence>=2 THEN customer_id END)/count(DISTINCT customer_id))::NUMERIC,2) as pct_customer
  FROM customer_rank
  GROUP BY customer_segment
  ORDER BY pct_customer DESC

  --TIME TO SECOND PURCHASE
  with c_ranked as (SELECT ui.customer_id,o.order_date,
  LEAD(o.order_date) over(
  PARTITION BY ui.customer_id ORDER BY o.order_date
  ) as next_order,
  ROW_NUMBER() over( PARTITION BY ui.customer_id ORDER BY o.order_date) as purchase_rnk
  from dim_orders_items_unique ui LEFT JOIN dim_orders o 
  on ui.order_id=o.order_id)
  SELECT AVG(next_order-order_date) as avg_time_second_order,
  PERCENTILE_CONT(0.5) WITHIN GROUP (order BY(next_order-order_date)) as median_days_second_purchase
  FROM c_ranked 
  WHERE purchase_rnk=1 AND next_order is NOT NULL
  --Conlcusion: avg time is 194 days for second order
  --141 days is the median for second purchase
  
  --CUSTOMER LIFETIME VALUE
  WITH cte as (SELECT c.customer_id, c.customer_segment, MIN(o.order_date) as first_order,
  MAX(o.order_date) as recent_order,
  COUNT(DISTINCT o.order_id) as total_orders,
  sum(oi.benefit_per_order) as Total_profit, SUM(oi.sales) as total_revenue
  FROM dim_customers c LEFT JOIN dim_orders_items oi ON c.customer_id=oi.customer_id
  LEFT JOIN dim_orders o on oi.order_id=o.order_id
  GROUP BY c.customer_id,c.customer_segment),
  cte_rank as (
  SELECT *, NTILE(10) over(ORDER BY Total_profit) AS profit_decile
  FROM cte 
  )
  SELECT customer_id, customer_segment,
  Total_profit as Customer_lifetime_value,
  total_orders as customer_lifetime_orders,
  (recent_order-first_order) as customer_lifetime,
  round((total_revenue)/(total_orders)::numeric,2) as AOV,
  CASE WHEN profit_decile<=2 THEN 'Top 20 whales'
  WHEN profit_decile<=8 THEN 'Middle 60 core'
  ELSE 'Bottom 20 Low Value'
  END as clv_rank
  FROM cte_rank