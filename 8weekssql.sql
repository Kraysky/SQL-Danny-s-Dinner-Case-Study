/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- 1. What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id,
    SUM(m.price) AS total_amount_spent
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
-- FIRST OPTION
WITH ordered_sales AS (
  SELECT
    s.customer_id,
    RANK() OVER (
      PATITION BY s.customer_id
      ORDER BY s.order_date
    ) AS order_rank,
    m.product_name
  FROM sales s
  JOIN menu m
    ON s.product_id = m.product_id
)
SELECT DISTINCT
  customer_id,
  product_name
FROM ordered_sales
WHERE order_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    m.product_name,
    COUNT(s.product_id) AS total_purchases
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.product_id
ORDER BY total_purchases DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH customer_rank AS(
  SELECT
  	s.customer_id,
  	m.product_name,
  	COUNT(s.product_id) AS total_purchases,
  	RANK OVER(
      		PARTITION BY s.customer_id,
      		ORDER BY COUNT(s.product_id)
      ) AS ranking
  FROM sales s
  JOIN menu m
  	ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
  )
  
SELECT 
    customer_id,
    product_name,
    total_purchases
FROM customer_rank
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH members_purchase_after_joining AS(
  SELECT
  	s.customer_id,
  	m.product_name,
  	s.order_date,
  	members.join_date,
  	RANK OVER(
      		PARTITION BY s.customer_id,
      		ORDER BY s.order_date
      ) AS ranking
  FROM sales s
  JOIN menu m
  	ON s.product_id = m.product_id
  JOIN members
  	ON s.customer_id = memebers.customer_id
  WHERE s.order_date >= members.join_date
 )
 
 SELECT
    customer_id,
    product_name,
    order_date
 FROM members_purchase_after_joining
 WHERE ranking = 1;
 
 -- 7. Which item was purchased just before the customer became a member?
 WITH members_purchase_before_joining AS(
  SELECT
  	s.customer_id,
  	m.product_name,
  	s.order_date,
  	members.join_date,
  	RANK OVER(
      		PARTITION BY s.customer_id,
      		ORDER BY s.order_date DESC
      ) AS ranking
  FROM sales s
  JOIN menu m
  	ON s.product_id = m.product_id
  JOIN members
  	ON s.customer_id = memebers.customer_id
  WHERE s.order_date < members.join_date
 )
 
 SELECT
    customer_id,
    product_name,
    order_date
 FROM members_purchase_before_joining
 WHERE ranking = 1;
  
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    s.customer_id,
    COUNT(s.product_id) AS amount_purchased,
    SUM(m.price) AS total_amount_spent,
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members
    ON s.customer_id = memebers.customer_id
WHERE s.order_date < members.join_date
GROUP BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
    s.customer_id,
    SUM(CASE 
    	WHEN m.product_name = 'SUSHI' THEN 2*10* m.price
        ELSE 10* m.price)
     AS points
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH additional_points AS(
  SELECT
	s.customer_id,
    SUM(CASE 
        WHEN s.order_date BETWEEN members.join_date AND DATEADD(month, 1, members.join_date) THEN 2*10* m.price
    	WHEN m.product_name = 'SUSHI' THEN 2*10* m.price
        ELSE 10* m.price)
  	AS points,
  	FROM sales s
  	JOIN menu m
		ON s.product_id = m.product_id
  	JOIN members
  		ON s.customer_id = memebers.customer_id)
        
 	SELECT 
    	customer_id,
        points
    FROM additional_points
    WHERE s.order_date <= '2021-31-01'
    GROUP BY customer_id;
    