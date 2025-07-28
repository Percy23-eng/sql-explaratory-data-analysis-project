--CHANGE OVER TIME ANALYSIS--
--Analyzing Sales Perfomance Over Time
SELECT 
DATETRUNC (month,order_date) as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC (month,order_date)
ORDER BY DATETRUNC (month,order_date)

  
/* Cumilitive Analysis
Trying yo understand how the business is perfoming*/
--Calculating Total Sales per month
--Running total of sales over time
SELECT
order_date,
total_sales,
SUM(total_sales) OVER ( ORDER BY order_date) AS running_total_sales
FROM
(
SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
)t
