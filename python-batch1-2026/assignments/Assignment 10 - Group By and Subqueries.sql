-- ============================================================
--  ASSIGNMENT 10 — Group By & Subqueries
--  Database : BikeStores
--  Topics   : Aggregate functions, GROUP BY, HAVING,
--             subqueries in WHERE (IN / NOT IN / scalar),
--             subqueries in FROM (derived tables),
--             subqueries in SELECT
-- ============================================================


-- ============================================================
--  Question 1 — Aggregate Functions
--  From sales.order_items, write ONE query that returns:
--    • total number of order lines
--    • total units sold (SUM of quantity)
--    • average, minimum and maximum list_price
--  Give every column a meaningful alias.
-- ============================================================


SELECT
    COUNT(*) AS total_order_lines,
    SUM(quantity) AS total_units_sold,
    AVG(list_price) AS average_list_price,
    MIN(list_price) AS minimum_list_price,
    MAX(list_price) AS maximum_list_price
FROM sales.order_items;


-- ============================================================
--  Question 2 — COUNT(*) vs COUNT(column)
--  a) How many rows are there in sales.customers?
--  b) How many customers have an email on record, and how many
--     have a phone number on record?
--  c) Using the results above, how many customers have NO phone
--     number? Confirm it with a separate query using IS NULL.
--  Add the numbers you get as comments.
-- ============================================================

-- Part a:
SELECT COUNT(*) AS total_customer_rows
FROM sales.customers;

-- Part b:
SELECT
    COUNT(email) AS customers_with_email,
    COUNT(phone) AS customers_with_phone
FROM sales.customers;

-- Part c:
SELECT
    COUNT(*) AS customers_without_phone
FROM sales.customers
WHERE phone IS NULL;



-- ============================================================
--  Question 3 — GROUP BY
--  a) Find the total units sold (SUM of quantity) for each
--     product_id in sales.order_items, highest first.
--  b) Count the number of customers in each state, highest
--     first.
--  c) Count the number of orders handled by each staff_id and
--     each order_status combination.
-- ============================================================

-- Part a:
SELECT
    product_id,
    SUM(quantity) AS total_units_sold
FROM sales.order_items
GROUP BY product_id
ORDER BY total_units_sold DESC;

-- Part b:
SELECT
    state,
    COUNT(*) AS customer_count
FROM sales.customers
GROUP BY state
ORDER BY customer_count DESC;

-- Part c:
SELECT
    staff_id,
    order_status,
    COUNT(*) AS order_count
FROM sales.orders
GROUP BY
    staff_id,
    order_status
ORDER BY
    staff_id ASC,
    order_status ASC;



-- ============================================================
--  Question 4 — GROUP BY with Joins
--  a) Show category_name and the average list_price of its
--     products (rounded to 2 decimals). Join products and
--     categories.
--  b) Show brand_name and the number of products in each brand,
--     sorted by the product count descending.
--  c) For every customer, show customer_id, first_name,
--     last_name, order_count and total_spent.
--     total_spent = SUM(quantity * list_price * (1 - discount))
--     Hint: use COUNT(DISTINCT order_id) so orders are not
--     counted once per item.
-- ============================================================

-- Part a:
SELECT
    c.category_name,
    ROUND(AVG(p.list_price), 2) AS average_list_price
FROM production.categories AS c
INNER JOIN production.products AS p
    ON p.category_id = c.category_id
GROUP BY
    c.category_name
ORDER BY
    c.category_name ASC;

-- Part b:
SELECT
    b.brand_name,
    COUNT(p.product_id) AS product_count
FROM production.brands AS b
INNER JOIN production.products AS p
    ON p.brand_id = b.brand_id
GROUP BY
    b.brand_name
ORDER BY
    product_count DESC;

-- Part c:

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    ISNULL(
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)),
        0.00
    ) AS total_spent
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
    ON o.customer_id = c.customer_id
LEFT JOIN sales.order_items AS oi
    ON oi.order_id = o.order_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    c.customer_id ASC;


-- ============================================================
--  Question 5 — HAVING
--  a) List the model_year values that have more than 50
--     products, with the product count.
--  b) List the customers who have placed 2 or more orders
--     (customer_id and order_count).
--  c) List the product_ids that have sold more than 100 units
--     in total.
--  d) In a comment, explain why part (a) cannot be written
--     with WHERE alone.
-- ============================================================

-- Part a:
SELECT
    model_year,
    COUNT(*) AS product_count
FROM production.products
GROUP BY model_year
HAVING COUNT(*) > 50
ORDER BY product_count DESC;

-- Part b:
SELECT
    customer_id,
    COUNT(*) AS order_count
FROM sales.orders
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC;

-- Part c:
SELECT
    product_id,
    SUM(quantity) AS total_units_sold
FROM sales.order_items
GROUP BY product_id
HAVING SUM(quantity) > 100
ORDER BY total_units_sold DESC;

-- Part d (answer as a comment):
-- WHERE filters individual rows before grouping.
-- HAVING filters grouped results after aggregate functions are calculated.
-- Therefore, part (a) requires HAVING because it filters COUNT(*).



-- ============================================================
--  Question 6 — WHERE + GROUP BY + HAVING Together
--  Using only orders placed in the year 2017, find the stores
--  (store_id) whose total revenue is above 100000.
--  Show store_id and total_revenue, highest first.
--  Hint: WHERE filters rows before grouping, HAVING filters
--  groups after grouping.
-- ============================================================

SELECT
    o.store_id,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM sales.orders AS o
INNER JOIN sales.order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.order_date >= '20170101'
  AND o.order_date < '20180101'
GROUP BY
    o.store_id
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 100000
ORDER BY
    total_revenue DESC;




-- ============================================================
--  Question 7 — Subquery in WHERE (IN)
--  a) Return all orders placed by customers who live in
--     'New York'. Use a subquery on sales.customers.
--  b) Return the product_id and product_name of all products
--     that belong to the categories 'Electric Bikes' or
--     'Cruisers Bicycles'. Use a subquery on categories.
--  c) Return the customers (first_name, last_name, city) who
--     have placed at least one order. Use IN with a subquery.
-- ============================================================

-- Part a:
SELECT
    o.*
FROM sales.orders AS o
WHERE o.customer_id IN
(
    SELECT c.customer_id
    FROM sales.customers AS c
    WHERE c.city = 'New York'
);

-- Part b:
SELECT
    p.product_id,
    p.product_name
FROM production.products AS p
WHERE p.category_id IN
(
    SELECT c.category_id
    FROM production.categories AS c
    WHERE c.category_name IN ('Electric Bikes', 'Cruisers Bicycles')
);

-- Part c:
SELECT
    c.first_name,
    c.last_name,
    c.city
FROM sales.customers AS c
WHERE c.customer_id IN
(
    SELECT o.customer_id
    FROM sales.orders AS o
);



-- ============================================================
--  Question 8 — Subquery in WHERE (Scalar & NOT IN)
--  a) Return all products priced ABOVE the overall average
--     list_price. Do not hardcode the average.
--  b) Return all products priced BELOW the overall average
--     list_price, and write a second query that counts how
--     many such products there are.
--  c) Return the customers who have NEVER placed an order,
--     using NOT IN.
--  d) Return the products that have never been ordered
--     (not present in sales.order_items).
--  Hint for c and d: filter out NULLs inside the subquery so
--  NOT IN works correctly.
-- ============================================================

-- Part a:
SELECT
    p.product_id,
    p.product_name,
    p.list_price
FROM production.products AS p
WHERE p.list_price >
(
    SELECT AVG(p2.list_price)
    FROM production.products AS p2
);

-- Part b:
SELECT
    p.product_id,
    p.product_name,
    p.list_price
FROM production.products AS p
WHERE p.list_price <
(
    SELECT AVG(p2.list_price)
    FROM production.products AS p2
);

-- Count products priced below the overall average
SELECT
    COUNT(*) AS products_below_average
FROM production.products AS p
WHERE p.list_price <
(
    SELECT AVG(p2.list_price)
    FROM production.products AS p2
);

-- Part c:
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city
FROM sales.customers AS c
WHERE c.customer_id NOT IN
(
    SELECT o.customer_id
    FROM sales.orders AS o
    WHERE o.customer_id IS NOT NULL
);

-- Part d:
SELECT
    p.product_id,
    p.product_name,
    p.list_price
FROM production.products AS p
WHERE p.product_id NOT IN
(
    SELECT oi.product_id
    FROM sales.order_items AS oi
    WHERE oi.product_id IS NOT NULL
);



-- ============================================================
--  Question 9 — Subquery in FROM (Derived Table)
--  a) First find the number of orders handled by each staff
--     member. Then, using that result as a derived table,
--     calculate the average, minimum and maximum order count
--     per staff member.
--  b) Using a derived table of total_spent per customer,
--     return the average total_spent across all customers.
--  Remember: a derived table needs an alias.
-- ============================================================

-- Part a:
SELECT
    AVG(CAST(staff_order_counts.order_count AS decimal(10, 2)))
        AS average_order_count,
    MIN(staff_order_counts.order_count) AS minimum_order_count,
    MAX(staff_order_counts.order_count) AS maximum_order_count
FROM
(
    SELECT
        staff_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY staff_id
) AS staff_order_counts;

-- Part b:
SELECT
    AVG(customer_totals.total_spent) AS average_total_spent
FROM
(
    SELECT
        c.customer_id,
        ISNULL(
            SUM(oi.quantity * oi.list_price * (1 - oi.discount)),
            0.00
        ) AS total_spent
    FROM sales.customers AS c
    LEFT JOIN sales.orders AS o
        ON o.customer_id = c.customer_id
    LEFT JOIN sales.order_items AS oi
        ON oi.order_id = o.order_id
    GROUP BY c.customer_id
) AS customer_totals;



-- ============================================================
--  Question 10 — Subquery in SELECT
--  a) For each product (product_id, product_name, list_price),
--     show the total quantity sold as a column named
--     units_sold, using a correlated subquery on
--     sales.order_items.
--  b) For each order (order_id, order_date), show the number of
--     items in that order as item_count and the highest
--     list_price in that order as max_item_price.
--  c) Show the difference between each product's list_price and
--     the overall average list_price as price_difference.
-- ============================================================

-- Part a:
SELECT
    p.product_id,
    p.product_name,
    p.list_price,
    ISNULL(
        (
            SELECT SUM(oi.quantity)
            FROM sales.order_items AS oi
            WHERE oi.product_id = p.product_id
        ),
        0
    ) AS units_sold
FROM production.products AS p;

-- Part b:
SELECT
    o.order_id,
    o.order_date,
    (
        SELECT COUNT(*)
        FROM sales.order_items AS oi
        WHERE oi.order_id = o.order_id
    ) AS item_count,
    (
        SELECT MAX(oi.list_price)
        FROM sales.order_items AS oi
        WHERE oi.order_id = o.order_id
    ) AS max_item_price
FROM sales.orders AS o;

-- Part c:
SELECT
    p.product_id,
    p.product_name,
    p.list_price,
    p.list_price -
    (
        SELECT AVG(p2.list_price)
        FROM production.products AS p2
    ) AS price_difference
FROM production.products AS p;



-- ============================================================
--  Question 11 — Challenge
--  Find the customers whose total_spent is higher than the
--  average total_spent of all customers.
--  Show customer_id, first_name, last_name and total_spent,
--  highest first.
--  Hint: combine GROUP BY + HAVING with a scalar subquery
--  (or a derived table) that calculates the average.
-- ============================================================

WITH customer_totals AS
(
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        ISNULL(
            SUM(oi.quantity * oi.list_price * (1 - oi.discount)),
            0.00
        ) AS total_spent
    FROM sales.customers AS c
    LEFT JOIN sales.orders AS o
        ON o.customer_id = c.customer_id
    LEFT JOIN sales.order_items AS oi
        ON oi.order_id = o.order_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
)
SELECT
    customer_id,
    first_name,
    last_name,
    total_spent
FROM customer_totals
WHERE total_spent >
(
    SELECT AVG(total_spent)
    FROM customer_totals
)
ORDER BY
    total_spent DESC;

