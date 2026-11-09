# 🎵 Chinook Music Store - SQL Data Analysis

A complete data analytics project using PostgreSQL on the Chinook digital media store database. This project analyzes real-world business metrics across sales trends, customer behavior, catalog efficiency, and employee performance through 30 structured SQL queries.

---

## 🛠️ Tech Stack & Skills
* **Database:** PostgreSQL (pgAdmin 4)
* **SQL Skills:** Multi-Table Joins, CTEs, Window Functions (LAG, DENSE_RANK), Anti-Joins (LEFT JOIN ... WHERE NULL), Aggregations (SUM, AVG, COUNT DISTINCT), Data Type Casting.

---

## 📁 Database Overview
The dataset models an online digital music store with 11 relational tables:
* **Catalog:** track, album, artist, genre, media_type, playlist
* **Sales:** invoice, invoice_line
* **People:** customer, employee

---

## 🔍 Key Insights & Business Findings

### 1. Sales & Revenue
* Analyzed historical sales volume and identified top revenue-generating countries.
* Tracked invoice accuracy and total billing metrics.

### 2. Customer Behavior
* Measured repeat purchase intervals using LAG() window functions to understand customer return frequency.
* Identified highest lifetime value (LTV) customers.

### 3. Catalog & Inventory Optimization
* *Dead Catalog Alert:* Found that *48.44%* of all tracks in the store have never recorded a single purchase, revealing significant dead inventory.
* Identified unsold albums and underperforming media types using SQL Anti-Joins.
* Highlighted top-selling artists and cross-genre artists.

### 4. Employee Operations
* Evaluated sales revenue handled by each sales support representative.
* Mapped out the organizational hierarchy (Manager vs Direct Reports) using Self-Joins and handled executive roles using COALESCE.

---

## 📂 Project Structure
* `music store project p1.sql` - Complete SQL scripts organized into 4 clear business sections.
* `README.md` - Business context, insights, and technical details.
