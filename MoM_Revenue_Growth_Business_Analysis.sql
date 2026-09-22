/*
============================================================
E-COMMERCE SALES & REVENUE ANALYTICS
Business Analysis SQL Project
============================================================

Database: ecommerce_analytics

Tables:
    customers
    categories
    products
    orders
    order_items
    payments

Business rule:
    Revenue = quantity * unit_price * (1 - discount)

Revenue-focused analysis uses Delivered orders unless the question
specifically asks about order status, payments, or cancellations.

Comments contain only:
    1. Business question
    2. Approach

The SQL solution is kept outside the comments.

MySQL 8+ recommended.
============================================================
*/

USE ecommerce_analytics;


/* ============================================================
Q01
QUESTION:
What is the overall sales performance of the business, including
total customers, total products, total orders, delivered orders,
units sold, and delivered revenue?

APPROACH:
Calculate each business metric from the appropriate tables.
Use delivered orders for revenue and units, while customer, product,
and order counts represent the overall dataset.
============================================================ */

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Delivered') AS delivered_orders,
    (
        SELECT SUM(oi.quantity)
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_status = 'Delivered'
    ) AS total_units_sold,
    (
        SELECT ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_status = 'Delivered'
    ) AS total_revenue;


/* ============================================================
Q02
QUESTION:
How much revenue, profit, and profit margin does each product
category generate?

APPROACH:
Join products with order_items and orders. Calculate revenue and
estimated profit from selling price minus cost price. Aggregate the
metrics at category level and calculate profit margin from profit
divided by revenue.
============================================================ */

SELECT
    p.category_name,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue,
    ROUND(
        SUM(
            oi.quantity * (
                oi.unit_price * (1 - oi.discount) - p.cost_price
            )
        ), 2
    ) AS profit,
    ROUND(
        SUM(
            oi.quantity * (
                oi.unit_price * (1 - oi.discount) - p.cost_price
            )
        )
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 0)
        * 100,
        2
    ) AS profit_margin_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category_name
ORDER BY revenue DESC;


/* ============================================================
Q03
QUESTION:
Which products generate the highest revenue, and how many units
have been sold for each product?

APPROACH:
Aggregate delivered sales at product level. Calculate total units and
revenue, then sort the products by revenue to identify the strongest
products.
============================================================ */

SELECT
    p.product_id,
    p.product_name,
    p.category_name,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),
        2
    ) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    p.product_id,
    p.product_name,
    p.category_name
ORDER BY revenue DESC
LIMIT 10;


/* ============================================================
Q04
QUESTION:
How does monthly revenue change over time, and how many delivered
orders are generated each month?

APPROACH:
Aggregate delivered revenue and distinct delivered orders by month.
Use order_date to create a chronological monthly business view.
============================================================ */

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;


/* ============================================================
Q05
QUESTION:
What is the Month-over-Month revenue growth for every month?

APPROACH:
First create a monthly revenue dataset. Use LAG() to bring the
previous month's revenue into the current row, then calculate the
percentage change between the two months.
============================================================ */

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_growth
ORDER BY month;


/* ============================================================
Q06
QUESTION:
Which months experienced the strongest revenue growth and which
months experienced the largest decline?

APPROACH:
Calculate monthly revenue and MoM growth using LAG(). Rank the
months by growth percentage so periods of strong expansion and
decline can be identified from the same result.
============================================================ */

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_growth
WHERE previous_revenue IS NOT NULL
ORDER BY mom_growth_pct DESC;


/* ============================================================
Q07
QUESTION:
Which customer segments contribute the most revenue, orders,
and average order value?

APPROACH:
Join customers to orders and order_items. Aggregate delivered
revenue and distinct orders by customer segment, then calculate
average order value from revenue divided by delivered orders.
============================================================ */

SELECT
    c.customer_segment,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),
        2
    ) AS revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_segment
ORDER BY revenue DESC;


/* ============================================================
Q08
QUESTION:
Which states contribute the most revenue and what percentage of
total revenue does each state represent?

APPROACH:
Aggregate delivered revenue by customer state. Use a window SUM()
over the aggregated result to calculate each state's share of total
business revenue.
============================================================ */

WITH state_revenue AS (
    SELECT
        c.state,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.state
)
SELECT
    state,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        revenue / SUM(revenue) OVER () * 100,
        2
    ) AS revenue_share_pct
FROM state_revenue
ORDER BY revenue DESC;


/* ============================================================
Q09
QUESTION:
Which customers generate the highest revenue, and what is their
average order value?

APPROACH:
Aggregate delivered sales by customer. Count distinct delivered
orders and calculate customer-level revenue and average order value.
============================================================ */

SELECT
    c.customer_id,
    c.customer_name,
    c.state,
    c.customer_segment,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),
        2
    ) AS revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.customer_name,
    c.state,
    c.customer_segment
ORDER BY revenue DESC
LIMIT 10;


/* ============================================================
Q10
QUESTION:
Which products have strong sales but comparatively low profit
margin?

APPROACH:
Calculate product-level revenue and profit. Derive profit margin
from profit divided by revenue, then identify products with high
revenue but relatively weak margins using an average-margin benchmark.
============================================================ */

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue,
        SUM(
            oi.quantity * (
                oi.unit_price * (1 - oi.discount) - p.cost_price
            )
        ) AS profit
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category_name
),
metrics_with_margin AS (
    SELECT
        *,
        profit / NULLIF(revenue, 0) * 100 AS profit_margin_pct
    FROM product_metrics
)
SELECT
    product_id,
    product_name,
    category_name,
    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,
    ROUND(profit_margin_pct, 2) AS profit_margin_pct
FROM metrics_with_margin
WHERE revenue >= (
    SELECT AVG(revenue)
    FROM product_metrics
)
AND profit_margin_pct < (
    SELECT AVG(profit / NULLIF(revenue, 0) * 100)
    FROM product_metrics
)
ORDER BY revenue DESC;


/* ============================================================
Q11
QUESTION:
What are the top 3 products by revenue within each category?

APPROACH:
Calculate product revenue within each category. Use DENSE_RANK()
with PARTITION BY category so products are ranked independently
inside their own category.
============================================================ */

WITH product_revenue AS (
    SELECT
        p.category_name,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.category_name,
        p.product_id,
        p.product_name
),
ranked_products AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY revenue DESC
        ) AS category_rank
    FROM product_revenue
)
SELECT
    category_name,
    product_id,
    product_name,
    ROUND(revenue, 2) AS revenue,
    category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY category_name, category_rank, revenue DESC;


/* ============================================================
Q12
QUESTION:
Which category was the highest-revenue category in each month?

APPROACH:
Calculate revenue by month and category. Rank categories within
each month using ROW_NUMBER(), then keep the first category for
each month.
============================================================ */

WITH monthly_category AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        p.category_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m'),
        p.category_name
),
ranked_categories AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category
)
SELECT
    month,
    category_name,
    ROUND(revenue, 2) AS revenue
FROM ranked_categories
WHERE category_rank = 1
ORDER BY month;


/* ============================================================
Q13
QUESTION:
How does each month's revenue compare with the average revenue
of the previous three months?

APPROACH:
Create monthly revenue and use a window frame covering the three
preceding rows. Calculate the previous-three-month average separately
from the current month, then compare current revenue with that baseline.
============================================================ */

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
rolling_metrics AS (
    SELECT
        month,
        revenue,
        AVG(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ) AS previous_3_month_avg
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_3_month_avg, 2) AS previous_3_month_avg,
    ROUND(
        (revenue - previous_3_month_avg)
        / NULLIF(previous_3_month_avg, 0) * 100,
        2
    ) AS variance_from_previous_3_month_avg_pct
FROM rolling_metrics
ORDER BY month;


/* ============================================================
Q14
QUESTION:
Which customers have been active across at least three different
months, and how much revenue have they generated?

APPROACH:
Create a customer-month revenue layer so multiple orders within the
same month count as one active month. Aggregate that layer by customer
and use HAVING to keep customers active in at least three months.
============================================================ */

WITH customer_monthly AS (
    SELECT
        c.customer_id,
        c.customer_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS monthly_revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        c.customer_id,
        c.customer_name,
        DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    customer_id,
    customer_name,
    COUNT(*) AS active_months,
    ROUND(SUM(monthly_revenue), 2) AS total_revenue,
    ROUND(AVG(monthly_revenue), 2) AS average_monthly_revenue
FROM customer_monthly
GROUP BY customer_id, customer_name
HAVING COUNT(*) >= 3
ORDER BY total_revenue DESC;


/* ============================================================
Q15
QUESTION:
For each customer, identify the first month of purchase and
distinguish new purchase months from returning purchase months.

APPROACH:
Create a distinct customer-month purchase dataset. Use MIN() as
a window function to find each customer's first purchase month,
then classify every later purchase month as Returning.
============================================================ */

WITH customer_months AS (
    SELECT DISTINCT
        c.customer_id,
        c.customer_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS purchase_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
),
customer_lifecycle AS (
    SELECT
        customer_id,
        customer_name,
        purchase_month,
        MIN(purchase_month) OVER (
            PARTITION BY customer_id
        ) AS first_purchase_month
    FROM customer_months
)
SELECT
    customer_id,
    customer_name,
    purchase_month,
    first_purchase_month,
    CASE
        WHEN purchase_month = first_purchase_month THEN 'New'
        ELSE 'Returning'
    END AS purchase_type
FROM customer_lifecycle
ORDER BY customer_id, purchase_month;


/* ============================================================
Q16
QUESTION:
How does monthly revenue growth differ across customer segments?

APPROACH:
Aggregate revenue by customer segment and month. Use LAG() with
PARTITION BY customer_segment so every segment is compared against
its own previous month.
============================================================ */

WITH segment_monthly AS (
    SELECT
        c.customer_segment,
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        c.customer_segment,
        DATE_FORMAT(o.order_date, '%Y-%m')
),
segment_growth AS (
    SELECT
        customer_segment,
        month,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY customer_segment
            ORDER BY month
        ) AS previous_revenue
    FROM segment_monthly
)
SELECT
    customer_segment,
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(
        (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0) * 100,
        2
    ) AS mom_growth_pct
FROM segment_growth
ORDER BY customer_segment, month;


/* ============================================================
Q17
QUESTION:
Which payment methods are used most frequently, and how much
revenue is associated with each payment method?

APPROACH:
Join payments with orders and order_items. Restrict revenue to
Delivered orders, count orders by payment method, and calculate
the corresponding delivered revenue.
============================================================ */

SELECT
    o.payment_method,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY o.payment_method
ORDER BY delivered_orders DESC;


/* ============================================================
Q18
QUESTION:
What percentage of orders are cancelled or returned, and how does
the order status vary by month?

APPROACH:
Aggregate orders by month and status. Use conditional aggregation
to calculate delivered, cancelled, and returned order counts, then
derive the cancellation and return rates from total orders.
============================================================ */

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(*) AS total_orders,
    SUM(order_status = 'Delivered') AS delivered_orders,
    SUM(order_status = 'Cancelled') AS cancelled_orders,
    SUM(order_status = 'Returned') AS returned_orders,
    ROUND(
        SUM(order_status = 'Cancelled')
        / COUNT(*) * 100,
        2
    ) AS cancellation_rate_pct,
    ROUND(
        SUM(order_status = 'Returned')
        / COUNT(*) * 100,
        2
    ) AS return_rate_pct
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


/* ============================================================
Q19
QUESTION:
Which products contribute the largest share of total business
revenue, and what percentage does each product contribute?

APPROACH:
Calculate delivered revenue at product level. Use a window SUM()
over all product revenues to calculate each product's contribution
to total revenue, then rank products by their contribution.
============================================================ */

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category_name
)
SELECT
    product_id,
    product_name,
    category_name,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        revenue / SUM(revenue) OVER () * 100,
        2
    ) AS revenue_contribution_pct
FROM product_revenue
ORDER BY revenue_contribution_pct DESC
LIMIT 15;


/* ============================================================
Q20
QUESTION:
Create a monthly business performance view containing revenue,
previous-month revenue, MoM growth, delivered orders, average order
value, total profit, profit margin, and the highest-revenue category
for each month.

APPROACH:
Build separate monthly revenue/profit metrics and monthly category
metrics. Use LAG() for previous-month revenue, calculate MoM growth
and profit margin, rank categories within each month, and combine
the results into one chronological business report.
============================================================ */

WITH monthly_business AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue,
        SUM(
            oi.quantity * (
                oi.unit_price * (1 - oi.discount) - p.cost_price
            )
        ) AS profit
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_with_lag AS (
    SELECT
        *,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_business
),
monthly_category AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        p.category_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m'),
        p.category_name
),
ranked_categories AS (
    SELECT
        month,
        category_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category
)
SELECT
    m.month,
    m.delivered_orders,
    ROUND(m.revenue, 2) AS revenue,
    ROUND(m.previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (m.revenue - m.previous_month_revenue)
        / NULLIF(m.previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_pct,
    ROUND(
        m.revenue / NULLIF(m.delivered_orders, 0),
        2
    ) AS average_order_value,
    ROUND(m.profit, 2) AS profit,
    ROUND(
        m.profit / NULLIF(m.revenue, 0) * 100,
        2
    ) AS profit_margin_pct,
    rc.category_name AS top_category,
    ROUND(rc.revenue, 2) AS top_category_revenue
FROM monthly_with_lag m
LEFT JOIN ranked_categories rc
    ON m.month = rc.month
   AND rc.category_rank = 1
ORDER BY m.month;
