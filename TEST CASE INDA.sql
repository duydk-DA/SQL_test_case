
--Query revenue of category and the customer have revenue highest of each category
WITH A AS (
	SELECT
		pc.category_name,
		ct.first_name,
        ct.last_name,
		ROUND(SUM(oi.unit_price*oi.quantity),2) AS revenue,
        ct.phone,
		rank () Over (Partition by pc.category_name order by SUM(oi.unit_price*oi.quantity) DESC) AS rank_rev
	FROM order_items oi
	JOIN orders od ON od.order_id = oi.order_id
	JOIN products pd ON pd.product_id = oi.product_id
	JOIN product_categories pc ON pc.category_id = pd.category_id
    JOIN customers cus on cus.customer_id = od.customer_id
    JOIN contacts ct on ct.customer_id = cus.customer_id
	GROUP BY ct.first_name,ct.last_name, pc.category_name,ct.phone
    )
SELECT 
    A.category_name, 
    CONCAT(A.first_name, ' ', A.last_name) AS customer_name, 
    A.revenue, 
    A.phone
FROM A
WHERE A.rank_rev = 1


--Query revenue by customer's name and show website, 3 product's name have highest revenue
WITH T1 AS (
	SELECT
        CONCAT(ct.first_name, ' ', ct.last_name) as customer_name,
		cus.website,
		prd.product_name,
		ROUND(SUM(oi.unit_price*oi.quantity),2) AS revenue,
		rank () Over (Partition by CONCAT(ct.first_name, ' ', ct.last_name) order by SUM(oi.unit_price*oi.quantity) DESC) AS ranking
	FROM customers cus
	JOIN orders od ON od.customer_ID = cus.customer_ID
	JOIN order_items oi ON oi.order_ID = od.order_ID
    JOIN products prd ON prd.product_ID = oi.product_ID
    JOIN contacts ct on ct.customer_id = cus.customer_id
	GROUP BY 
        CONCAT(ct.first_name, ' ', ct.last_name),
		cus.website,
		prd.product_name
    )
SELECT
	T1.customer_name,
	T1.website,
	T1.product_name,
	T1.revenue
FROM T1
WHERE T1.ranking IN (1,2,3)
ORDER BY T1.customer_name

--Query category and product, show revenue of product and total revenue of category, show percentage of product relative to category
with TS as(
    SELECT
	pc.category_name,
    pc.category_ID,
	ROUND(SUM(oi.unit_price*oi.quantity),2) AS revenue_category
	FROM order_items oi
	JOIN products pd ON pd.Product_ID = oi.Product_ID
    JOIN Product_categories pc on pc.category_ID = pd.category_ID
	GROUP BY pc.category_name,pc.category_ID
    ) 
SELECT
	TS.category_name,
	pd.Product_name,
	ROUND(SUM(oi.unit_price*oi.quantity),2) AS revenue_product,
	TS.revenue_category,
	FORMAT((SUM(oi.unit_price*oi.quantity) / TS.revenue_category), '00.00%') AS percent_rev
FROM order_items oi
JOIN products pd ON pd.Product_ID = oi.Product_ID
JOIN TS ON TS.category_id = pd.category_id
GROUP BY 
    TS.category_name,
	pd.Product_name,
    TS.revenue_category
ORDER BY TS.category_name ASC, percent_rev DESC

--Find new customer in month, If the customer has purchased in the previous months, remove it from the list, show revenue of new customer
WITH A AS (
	SELECT
        YEAR(od.Order_Date) AS year,
        MONTH(od.ORDER_DATE) AS month,
		CONCAT(MONTH(od.Order_Date),'-',YEAR(od.Order_Date)) AS month_year,
		od.Customer_ID,
        ct.first_name,
        ct.last_name,
		ROUND(SUM(oi.unit_price*oi.quantity),2) AS revenue
	FROM orders od
	JOIN order_items oi  ON oi.order_ID = od.order_ID
    JOIN customers cus on cus.customer_id = od.customer_id
    JOIN contacts ct on ct.customer_id = cus.customer_id
	WHERE
		od.Customer_ID NOT IN (
			SELECT DISTINCT customer_ID
			FROM orders od2
			WHERE CONCAT(MONTH(od.Order_Date),'-',YEAR(od.Order_Date)) < CONCAT(MONTH(od2.Order_Date),'-',YEAR(od2.Order_Date))
            )
	GROUP BY
		YEAR(od.Order_Date),
        MONTH(od.ORDER_DATE),
		CONCAT(MONTH(od.Order_Date),'-',YEAR(od.Order_Date)),
		od.Customer_ID,
        ct.first_name,
        ct.last_name
        )
SELECT 
	A.year,
	A.month, 
	A.month_year,
	CONCAT(A.first_name, ' ' ,A.last_name) as customer_name, 
	A.revenue
FROM A
ORDER BY A.year,A.month,CONCAT(A.first_name, ' ' ,A.last_name)



