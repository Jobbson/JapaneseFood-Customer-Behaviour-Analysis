CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS AMOUNT_SPENT
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS DAYS_SPENT
FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH CUSTOMER_PREFERENCE AS ( 
	SELECT s.customer_id, MIN(s.order_date) AS First_Purchase
	FROM sales s
	GROUP BY customer_id
)
SELECT CUP.customer_id,CUP.First_Purchase,m.product_name
FROM CUSTOMER_PREFERENCE CUP
JOIN sales s ON CUP.customer_id = s.customer_id 
AND CUP.First_Purchase = s.order_date
JOIN Menu m ON s.product_id = m.product_id
;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(m.product_name) AS TOTAL_BOUGHT
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY TOTAL_BOUGHT DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?

WITH POPULAR AS (
	SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS NO_PURCHASE,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS RANK_NO
	FROM sales s
    JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id,m.product_name
)
SELECT POP.customer_id, POP.product_name
FROM POPULAR POP
WHERE RANK_NO = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH FirstPurchase_AfterMember AS (
	SELECT s.customer_id,MIN(s.order_date) AS DATE
	FROM sales s
	JOIN members mm ON s.customer_id = mm.customer_id
	WHERE s.order_date >= mm.join_date
	GROUP BY s.customer_id
)
SELECT FPA.customer_id, m.product_name 
FROM FirstPurchase_AfterMember FPA
JOIN sales s ON FPA.customer_id = s.customer_id
AND FPA.DATE = s.order_date
JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id;



-- 7. Which item was purchased just before the customer became a member?
WITH FirstPurchase_AfterMember AS (
	SELECT s.customer_id,MAX(s.order_date) AS DATE
	FROM sales s
	JOIN members mm ON s.customer_id = mm.customer_id
	WHERE s.order_date < mm.join_date
	GROUP BY s.customer_id
)
SELECT FPA.customer_id, m.product_name 
FROM FirstPurchase_AfterMember FPA
JOIN sales s ON FPA.customer_id = s.customer_id
AND FPA.DATE = s.order_date
JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id;



-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(*) AS Total_Items, SUM(m.price) AS Total_Spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mm ON s.customer_id = mm.customer_id
WHERE s.order_date < mm.join_date
GROUP BY s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, SUM(
    CASE 
        WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;


/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/
SELECT s.customer_id, SUM(
    CASE 
        WHEN s.order_date BETWEEN mm.join_date AND DATE_ADD( mm.join_date, INTERVAL 7 DAY ) THEN m.price*20
        WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mm ON s.customer_id = mm.customer_id
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;


-- 11. Recreate the table output using the available data
SELECT s.customer_id, s.order_date,m.product_name,m.price,(
    CASE 
        WHEN s.order_date >= mm.join_date THEN 'Y'
        ELSE 'N' 
    END) AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mm ON s.customer_id = mm.customer_id;




-- 12. Rank all the things:

WITH RANKING AS (SELECT s.customer_id, s.order_date,m.product_name,m.price,(
    CASE 
        WHEN s.order_date >= mm.join_date THEN 'Y'
        ELSE 'N' 
        END) AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mm ON s.customer_id = mm.customer_id)
SELECT R.customer_id, R.order_date,
R.product_name,
R.price, R.member, CASE
    WHEN member = 'N' THEN NULL
    ELSE RANK () OVER(
      PARTITION BY customer_id, member
      ORDER BY order_date) END AS ranking  
FROM RANKING R




