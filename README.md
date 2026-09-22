# E-Commerce Sales & Revenue Analytics

## 📌 Project Overview

This project analyzes an e-commerce business using SQL to understand revenue performance, customer behavior, product performance, profitability, and month-over-month (MoM) revenue growth.

The analysis is built on a relational database containing customers, orders, products, categories, order items, and payment information.

The main objective is to transform raw transactional data into meaningful business insights that can support revenue tracking, customer analysis, product decisions, and performance monitoring.

---

## 🎯 Business Objectives

The project focuses on answering questions such as:

* How is the business performing overall?
* How does revenue change month over month?
* Which months show strong growth or decline?
* Which categories and products generate the most revenue?
* Which products have high sales but comparatively low margins?
* Which customer segments contribute the most revenue?
* Which states generate the highest revenue?
* Who are the highest-value customers?
* Which customers are new and which are returning?
* How does revenue growth differ across customer segments?
* What percentage of orders are cancelled or returned?
* Which products contribute the largest share of total revenue?
* Which category performs best in each month?
* How are revenue and profitability changing over time?

---

## 🗂️ Database Structure

The database is named:

```text
ecommerce_analytics
```

### Tables

```text
customers
    │
    └── orders
          │
          ├── order_items ─── products ─── categories
          │
          └── payments
```

### Relationships

* `customers.customer_id` → `orders.customer_id`
* `orders.order_id` → `order_items.order_id`
* `products.product_id` → `order_items.product_id`
* `categories.category_id` → `products.category_id`
* `orders.order_id` → `payments.order_id`

---

## 📊 Dataset

| Table       | Records |
| ----------- | ------: |
| Customers   |   1,200 |
| Categories  |       8 |
| Products    |      80 |
| Orders      |  15,000 |
| Order Items |  26,945 |
| Payments    |  15,000 |

### Data Period

**January 2024 – June 2026**

The dataset contains transactional information across multiple years, allowing time-based revenue analysis and MoM growth calculations.

---

## 💰 Revenue Calculation

For delivered orders, revenue is calculated at order-item level:

```text
Revenue =
Quantity × Unit Price × (1 − Discount)
```

Example:

```text
Quantity = 2
Unit Price = ₹2,000
Discount = 10%

Revenue = 2 × 2,000 × (1 − 0.10)
        = ₹3,600
```

For profitability analysis:

```text
Profit =
Quantity × (Discounted Selling Price − Cost Price)
```

Profit margin:

```text
Profit Margin % =
Profit / Revenue × 100
```

---

## 📈 Month-over-Month Revenue Growth

The core analysis calculates monthly revenue and compares it with the previous month.

```text
MoM Growth % =
(Current Month Revenue − Previous Month Revenue)
÷ Previous Month Revenue × 100
```

SQL uses `LAG()` to retrieve the previous month's revenue.

Example:

```text
Month       Revenue       Previous Revenue    MoM Growth
---------------------------------------------------------
Jan 2025    ₹8,00,000     NULL                NULL
Feb 2025    ₹8,80,000     ₹8,00,000           10.00%
Mar 2025    ₹8,36,000     ₹8,80,000           -5.00%
```

---

## 🔎 Analysis Areas

### Revenue Analysis

* Monthly revenue
* MoM revenue growth
* Revenue contribution
* Revenue trends
* Revenue by state
* Revenue by customer segment

### Product Analysis

* Top products by revenue
* Units sold
* Category-level performance
* Top products within each category
* High-sales and low-margin products
* Product contribution to total revenue

### Customer Analysis

* Top customers by revenue
* Customer segments
* Average order value
* Active customers
* New vs returning customers
* Customer activity across multiple months

### Operational Analysis

* Delivered orders
* Cancelled orders
* Returned orders
* Cancellation rate
* Return rate
* Payment method usage

### Profitability Analysis

* Category profit
* Product profit
* Profit margin
* Revenue vs margin comparison
* Monthly profitability

---

## 🧠 SQL Concepts Used

The project uses SQL concepts naturally while solving business problems.

### Basic SQL

* `SELECT`
* `WHERE`
* `ORDER BY`
* `LIMIT`
* `GROUP BY`
* `HAVING`

### Data Combination

* `INNER JOIN`
* Multiple-table joins

### Aggregation

* `COUNT()`
* `SUM()`
* `AVG()`
* `ROUND()`
* Conditional aggregation

### Business Logic

* `CASE`
* `NULLIF()`
* Calculated columns
* Percentage calculations

### Advanced SQL

* Common Table Expressions (`WITH`)
* Subqueries
* `LAG()`
* `ROW_NUMBER()`
* `DENSE_RANK()`
* `PARTITION BY`
* Window `SUM()`
* Window `AVG()`
* Rolling averages
* Ranking within groups

---

## 📁 Project Files

```text
E-Commerce-Sales-Revenue-Analytics/
│
├── ecommerce_analytics_full_realistic.sql
│
├── MoM_Revenue_Growth_Business_Analysis.sql
│
└── README.md
```

### `ecommerce_analytics_full_realistic.sql`

Contains:

* Database creation
* Table creation
* Primary keys
* Foreign keys
* Product and category data
* Customer data
* Order data
* Order-item transactions
* Payment data

### `MoM_Revenue_Growth_Business_Analysis.sql`

Contains **20 business-focused SQL questions** covering revenue, customers, products, profitability, operations, and MoM growth.

---

## 🛠️ Tools Used

* **MySQL**
* SQL
* Relational Database Design
* CTEs
* Window Functions
* Aggregations
* Data Analysis

---

## 🚀 How to Run the Project

### 1. Create the database

Open:

```text
ecommerce_analytics_full_realistic.sql
```

Run the complete file in MySQL Workbench.

This creates the database, tables, relationships, and data.

### 2. Select the database

```sql
USE ecommerce_analytics;
```

### 3. Run the analysis

Open:

```text
MoM_Revenue_Growth_Business_Analysis.sql
```

Run the queries individually to explore the business data.

---

## 📌 Key Business Metrics

The project focuses on metrics such as:

| Metric                 | Purpose                               |
| ---------------------- | ------------------------------------- |
| Total Revenue          | Overall sales performance             |
| Monthly Revenue        | Time-based revenue tracking           |
| MoM Growth %           | Month-to-month revenue change         |
| Average Order Value    | Revenue generated per order           |
| Units Sold             | Product volume                        |
| Profit                 | Estimated earnings after product cost |
| Profit Margin %        | Profitability relative to revenue     |
| Revenue Contribution % | Share of total revenue                |
| Cancellation Rate      | Order cancellation behavior           |
| Return Rate            | Order return behavior                 |

---

## 📚 Project Outcome

This project demonstrates how SQL can be used to move from raw transactional data to structured business analysis.

The analysis connects multiple business dimensions such as:

```text
Revenue
   ↓
Products → Categories
   ↓
Customers → Segments → States
   ↓
Orders → Payments
   ↓
Monthly Performance
   ↓
MoM Growth
   ↓
Business Insights
```

The final monthly performance query combines revenue, previous-month revenue, MoM growth, orders, average order value, profit, profit margin, and the highest-revenue category into a single business view.

---


## ⚠️ Disclaimer

This project uses a fully synthetic dataset created specifically for this project.

The data has not been copied, scraped, downloaded, or taken from any external dataset, company, organization, website, or third-party source. The database, records, transactions, customer information, product information, and other values were generated specifically for practicing and demonstrating SQL-based business analysis.

Any names, email addresses, locations, transactions, financial figures, or other details appearing in the dataset are fictional and are not intended to represent real individuals, customers, businesses, or transactions.

The project is intended solely for educational, portfolio, and data-analysis demonstration purposes.


## 👤 Author

**Divyansh Chaturvedi**

SQL | Excel | Power BI | Python
