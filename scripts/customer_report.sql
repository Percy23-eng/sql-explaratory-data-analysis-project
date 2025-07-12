/*
================================================================================
Customer Report
================================================================================
Purpose:
 -This Report consolidates key customer metrics and behaviours

 Highlights:
   1. Gather essantial fields such as names , ages , and transaction deatils .
   2. Segments customers into Categories (VIP, Regular, New) and age groups.
   3. Aggregates customer-level metrics:
     -total orders
	 -total sales
	 -total quantity purchased
	 -total products
	 -lifespan (in months)
   4.Calculates valuable KPIs:
     -recency(months since last order)
	 -average order value
	 -average monthly spend
================================================================================
*/
/*------------------------------------------------------------------------------
1) Base Query : Retrieves core colunms from tables
-------------------------------------------------------------------------------*/
CREATE VIEW gold.report_customers AS
WITH base_query AS(
--1) Base Query : Retrieves core colunms from tables
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name , ' ' , c.last_name) AS customer_name,
DATEDIFF(year,c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)


, customer_aggregation AS (
/*
Customer Aggregation: Summarizes key metrics at the customer level
*/
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifesapn
FROM base_query
GROUP BY
	customer_key,
    customer_number,
    customer_name,
    age
)
SELECT
	customer_key,
    customer_number,
    customer_name,
    age,
	CASE 
		WHEN age < 20 THEN 'Under 20'
		WHEN age between 20 and 29 THEN '20-29'
		WHEN age between 30 and 39 THEN '30-39'
		WHEN age between 40 and 49 THEN '40-49'
		ELSE '50 and Above'
	END AS age_group,
	CASE 
		WHEN lifesapn >=12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifesapn >=12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
	total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifesapn,
	--Compute Average Order Value
	CASE WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	    END AS avg_order_value,
	--Compute Average Monthly spend
	CASE WHEN lifesapn = 0 THEN total_sales
		ELSE total_sales / lifesapn
	END AS avg_monthly_spend
FROM customer_aggregation
