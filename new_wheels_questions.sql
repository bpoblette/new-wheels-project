use new_wheels;
-- Question 1:
-- Find the total number of customers who have placed orders. What is the distribution of the customers across states? [4 marks]
-- Hint: For each state, count the number of customers

SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) AS TOTAL_NUMBER_OF_CUSTOMERS_PER_STATE,
    t.TOTAL_NUMBER_OF_CUSTOMERS
FROM 
    customer_t c
JOIN 
    order_t o 
    ON c.customer_id = o.customer_id
CROSS JOIN (
    SELECT COUNT(DISTINCT customer_id) AS TOTAL_NUMBER_OF_CUSTOMERS
    FROM order_t
) t
GROUP BY 
    c.state, t.TOTAL_NUMBER_OF_CUSTOMERS
ORDER BY 
    TOTAL_NUMBER_OF_CUSTOMERS_PER_STATE DESC;

SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) AS TOTAL_NUMBER_OF_CUSTOMERS_PER_STATE,
    t.TOTAL_NUMBER_OF_CUSTOMERS
FROM 
    customer_t c
JOIN 
    order_t o 
    ON c.customer_id = o.customer_id
CROSS JOIN (
    SELECT COUNT(DISTINCT customer_id) AS TOTAL_NUMBER_OF_CUSTOMERS
    FROM order_t
) t
GROUP BY 
    c.state, t.TOTAL_NUMBER_OF_CUSTOMERS
ORDER BY 
    TOTAL_NUMBER_OF_CUSTOMERS_PER_STATE ASC;
    
SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) AS TOTAL_NUMBER_OF_CUSTOMERS_PER_STATE,
    t.TOTAL_NUMBER_OF_CUSTOMERS
FROM 
    customer_t c
JOIN 
    order_t o 
    ON c.customer_id = o.customer_id
CROSS JOIN (
    SELECT COUNT(DISTINCT customer_id) AS TOTAL_NUMBER_OF_CUSTOMERS
    FROM order_t
) t
GROUP BY 
    c.state, t.TOTAL_NUMBER_OF_CUSTOMERS
ORDER BY 
    state ASC;
    
    
-- Question 2:
-- Which are the top 5 vehicle makers preferred by the customers? [4 marks]
-- Hint: For each vehicle make what is the count of the customers.
SELECT vehicle_maker, COUNT(DISTINCT customer_id) AS CUSTOMER_COUNT
FROM product_t JOIN order_t USING(product_id)
GROUP BY vehicle_maker
ORDER BY CUSTOMER_COUNT DESC
LIMIT 5;

SELECT vehicle_maker, COUNT(DISTINCT customer_id) AS CUSTOMER_COUNT
FROM product_t JOIN order_t USING(product_id)
GROUP BY vehicle_maker
ORDER BY CUSTOMER_COUNT ASC
LIMIT 5;

-- Question 3:
-- Which is the most preferred vehicle maker in each state? [4 marks]
-- Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
-- After ranking, take the vehicle maker whose rank is 1.
SELECT state, vehicle_maker, RNK
FROM (SELECT state, vehicle_maker, COUNT(DISTINCT customer_id) AS CUSTOMER_COUNT, RANK() OVER(PARTITION BY state ORDER BY COUNT(DISTINCT customer_id) DESC) AS RNK
	FROM product_t JOIN order_t USING(product_id) JOIN customer_t USING(customer_id)
    GROUP BY state, vehicle_maker) AS  RANKED
WHERE RNK = 1
ORDER BY state ASC;

SELECT quarter_number, vehicle_maker, RNK
FROM (SELECT quarter_number, vehicle_maker, COUNT(DISTINCT customer_id) AS CUSTOMER_COUNT, RANK() OVER(PARTITION BY quarter_number ORDER BY COUNT(DISTINCT customer_id) DESC) AS RNK
	FROM product_t JOIN order_t USING(product_id) JOIN customer_t USING(customer_id)
    GROUP BY quarter_number, vehicle_maker) AS  RANKED
WHERE RNK = 1
ORDER BY quarter_number ASC;

SELECT vehicle_maker,
       COUNT(*) AS number_of_states_favoring_maker
FROM (
    SELECT state, vehicle_maker
    FROM (
        SELECT state, vehicle_maker,
               COUNT(DISTINCT customer_id) AS CUSTOMER_COUNT,
               RANK() OVER(
                   PARTITION BY state
                   ORDER BY COUNT(DISTINCT customer_id) DESC
               ) AS RNK
        FROM customer_t
        JOIN order_t USING(customer_id)
        JOIN product_t USING(product_id)
        GROUP BY state, vehicle_maker
    ) AS ranked
    WHERE RNK = 1
) AS favorites
GROUP BY vehicle_maker
ORDER BY number_of_states_favoring_maker DESC;

-- Question 4:
-- Find the overall average rating given by the customers. What is the average rating in each quarter? [5 marks]
-- Consider the following mapping for ratings:
-- “Very Bad”: 1, “Bad”: 2, “Okay”: 3, “Good”: 4, “Very Good”: 5
-- Hint: Use subquery and assign numerical values to feedback categories using a CASE statement. 
-- Then, calculate the average feedback count per quarter. Use a subquery to convert feedback 
-- into numerical values and group by quarter_number to compute the average.

SELECT 
	ROUND(AVG(feedback_score), 4) as OVERALL_AVG_RATING
FROM
	(SELECT customer_feedback,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END as  feedback_score
	FROM order_t) AS customer_feeback_t;

SELECT 
	quarter_number,
    ROUND(AVG(feedback_score), 4) as AVG_SCORE_PER_QUARTER, 
    OVERALL_AVG_RATING
FROM 
	(SELECT customer_feedback, quarter_number,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END as  feedback_score
	FROM order_t
    ) AS customer_feeback_t
CROSS JOIN(
	SELECT 
		ROUND(AVG(feedback_score), 4) as OVERALL_AVG_RATING
	FROM
		(SELECT customer_feedback,
			CASE
				WHEN customer_feedback = 'Very Bad' THEN 1
				WHEN customer_feedback = 'Bad' THEN 2
				WHEN customer_feedback = 'Okay' THEN 3
				WHEN customer_feedback = 'Good' THEN 4
				WHEN customer_feedback = 'Very Good' THEN 5
			END as  feedback_score
		FROM order_t) AS average_rating_t
        ) temp_t
GROUP BY 
	quarter_number, 
    OVERALL_AVG_RATING
ORDER BY 
	AVG_SCORE_PER_QUARTER desc;


-- Question 5:
-- Find the percentage distribution of feedback from the customers. Are customers getting more dissatisfied over time? [5 marks]
-- Hint: Calculate the percentage of each feedback type by using conditional aggregation. 
-- For each feedback category, use a CASE statement to count the occurrences and then divide by the total count of feedback for the quarter, multiplied by 100 to get the percentage. 
-- Finally, group by quarter_number and order the results to reflect the correct sequence.

SELECT quarter_number,
	CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS VERY_GOOD_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS GOOD_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS OKAY_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS BAD_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS VERY_BAD_PCT
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number ASC;

SELECT
	CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS VERY_GOOD_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS GOOD_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS OKAY_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS BAD_PCT,
    CONCAT(ROUND(100 * SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) / COUNT(*), 2) , '%') AS VERY_BAD_PCT
FROM order_t;


-- Question 6:
-- What is the trend of the number of orders by quarter? [3 marks]
-- Hint: Count the number of orders for each quarter.
SELECT quarter_number, COUNT(order_id) AS  ORDERS_PER_QUARTER
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number asc;

SELECT COUNT(order_id) AS TOTAL_ORDERS
FROM order_t
ORDER BY quarter_number asc;


-- Question 7:
-- Calculate the net revenue generated by the company. What is the quarter-over-quarter % change in net revenue? [5 marks]
-- Hint: Net Revenue is the amount obtained by multiplying the number of units sold by the price after deducting the discounts applied.
-- Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
-- Calculate the revenue for each quarter by summing the quantity of product and the discounted vehicle price. Use the LAG function to get the revenue from the previous quarter, and then compute the quarter-over-quarter percentage change based on the current and previous revenue values.
-- Ensure the results are ordered by quarter_number to maintain the correct sequence.

-- using two different queries
DROP TABLE IF EXISTS revenue_by_customer_t;
CREATE TEMPORARY TABLE revenue_by_customer_t
SELECT customer_name, vehicle_model, quantity, discount, o.vehicle_price, (o.vehicle_price * (1 - discount)) * quantity AS total_order_price, quarter_number
FROM product_t p JOIN order_t o USING(product_id) JOIN customer_t c USING(customer_id)
ORDER BY quarter_number, customer_name;

SELECT SUM(total_order_price) AS net_revenue_company
FROM revenue_by_customer_t;

 -- using sub queries
SELECT SUM(total_order_price) AS net_revenue_company
FROM (SELECT vehicle_model, quantity, discount, o.vehicle_price, (o.vehicle_price * (1 - discount)) * quantity AS total_order_price, quarter_number
FROM product_t p JOIN order_t o USING(product_id) JOIN customer_t c USING(customer_id)
ORDER BY quarter_number) AS revenue_table_t;

-- Question 7 part 2: Revenue by quarter

SELECT quarter_number, SUM(total_order_price) AS net_revenue_per_quarter
FROM revenue_by_customer_t
GROUP BY quarter_number;

SELECT LAG(net_revenue_per_quarter,1) OVER(ORDER BY quarter_number)
FROM (SELECT quarter_number, SUM(total_order_price) AS net_revenue_per_quarter
FROM revenue_by_customer_t
GROUP BY quarter_number) AS quarterly_net_revenue_t;

-- using sub queries
SELECT 
	quarter_number, 
    net_revenue_per_quarter, 
    CONCAT(ROUND((((net_revenue_per_quarter - LAG(net_revenue_per_quarter,1) OVER(ORDER BY quarter_number)) / LAG(net_revenue_per_quarter,1) OVER(ORDER BY quarter_number)) * 100),2), '%') AS change_of_net_revenue_per_quarter
FROM(
	SELECT 
		quarter_number, 
        SUM(total_order_price) AS net_revenue_per_quarter
	FROM(
		SELECT 
			vehicle_model, 
            quantity, discount,
            o.vehicle_price, 
            (o.vehicle_price * (1 - discount)) * quantity AS total_order_price, 
            quarter_number
		FROM 
			product_t p 
		JOIN 
			order_t o USING(product_id) 
        JOIN 
			customer_t c USING(customer_id)
		ORDER BY 
			quarter_number
        ) AS revenue_table_t
	GROUP BY quarter_number) AS quarterly_net_revenue_t;

SELECT SUM(total_order_price) AS net_revenue_company
FROM (SELECT vehicle_model, quantity, discount, o.vehicle_price, (o.vehicle_price * (1 - discount)) * quantity AS total_order_price, quarter_number
FROM product_t p JOIN order_t o USING(product_id) JOIN customer_t c USING(customer_id)
ORDER BY quarter_number) AS revenue_table_t;

-- single query which displays the net_revenue with the quarterly changes
SELECT 
	quarter_number, 
	net_revenue_per_quarter, 
    CONCAT(ROUND((((net_revenue_per_quarter - LAG(net_revenue_per_quarter,1) OVER(ORDER BY quarter_number)) / LAG(net_revenue_per_quarter,1) OVER(ORDER BY quarter_number)) * 100),2), '%') AS change_of_net_revenue_per_quarter, 
    net_revenue_company
FROM (SELECT quarter_number, SUM((vehicle_price * (1 - discount)) * quantity) AS net_revenue_per_quarter
	FROM order_t
	GROUP BY quarter_number) AS quarterly_net_revenue_t
CROSS JOIN(
	SELECT SUM(vehicle_price * (1 - discount) * quantity) AS net_revenue_company
	FROM order_t
) AS net_revenue_t;

-- Question 8:
-- What is the trend of net revenue and orders by quarters? [4 marks]
-- Hint: Find out the sum of net revenue and count the number of orders for each quarter.

SELECT vehicle_model, quantity, discount, o.vehicle_price, (o.vehicle_price * (1 - discount)) * quantity AS total_order_price, quarter_number
FROM product_t p JOIN order_t o USING(product_id) JOIN customer_t c USING(customer_id)
ORDER BY quarter_number;

SELECT quarter_number, SUM(total_order_price) AS net_revenue_per_quarter
FROM(SELECT vehicle_model, quantity, discount, o.vehicle_price, (o.vehicle_price * (1 - discount)) * quantity AS total_order_price, quarter_number
FROM product_t p JOIN order_t o USING(product_id) JOIN customer_t c USING(customer_id)
ORDER BY quarter_number) AS revenue_table_t
GROUP BY quarter_number
ORDER BY quarter_number ASC;

SELECT 
	quarter_number, 
    SUM((o.vehicle_price * (1 - discount)) * quantity) AS net_revenue_per_quarter, 
    COUNT(ORDER_ID) AS orders_per_quarter
FROM 
	order_t o 
GROUP BY 
	quarter_number
ORDER BY 
	quarter_number ASC; 

-- Question 9:
-- What is the average discount offered for different types of credit cards? [3 marks]
-- Hint: Find out the average of discount for each credit card type.
SELECT credit_card_type, discount
FROM order_t JOIN customer_t USING(customer_id);

SELECT 
	credit_card_type, 
    CONCAT(ROUND(AVG(discount), 2), '%') as average_discount_per_credit_card_type
FROM 
	order_t 
JOIN 
	customer_t USING(customer_id)
GROUP BY 
	credit_card_type
ORDER BY 
	average_discount_per_credit_card_type DESC;

-- Question 10:
-- What is the average time taken to ship the placed orders for each quarter? [3 marks]
-- Hint: Please use the julianday function instead of the DATEDIFF function to find the difference between the ship date and the order date.
-- The SQL Playground Editor is built on the SQLite platform, which doesn’t support the DATEDIFF function available in MySQL
SELECT order_id, quarter_number, order_date, ship_date
FROM order_t
ORDER BY quarter_number ASC;

SELECT JULIANDAY(ship_date) - JULIANDAY(order_date) AS order_to_shipping_diff
FROM order_t;

SELECT quarter_number, ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)), 2) AS order_to_shipping_avg
FROM order_t
GROUP BY quarter_number;
