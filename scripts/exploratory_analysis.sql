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


  
--Perfomance Analysis--
/*Analyzing the yearly perfomance of products
by comparing each products sales to both
its average sales perfomance and the previous years sales
*/

WITH yearly_product_sales AS(
SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
)

SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	ELSE 'AVG'
	END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) py_sales, --Year Over Year Analysis
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	ELSE 'NO Change'
END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year


--Which categories contribute to the most overall sales?
WITH category_sales AS (
SELECT
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key 
GROUP BY category)

SELECT
category,
total_sales,
SUM(total_sales) OVER() overall_sales,
ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100,2) percantage_of_total
FROM category_sales
