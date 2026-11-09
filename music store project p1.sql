--**-**-- Section 1: Customer Behavior & Segmentation --**-**--

--Q1: Which 5 customers have spent the highest total amount in the store?

SELECT
	c.customer_id,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	ROUND(SUM(i.total)::numeric,2) AS total_spend
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5
select * from customer
--Q2: What is the average lifetime spending of customers grouped by their registered country?

WITH lifetime AS(
SELECT
	c.country,
	c.customer_id,
	ROUND(SUM(i.total)::numeric,2) AS total_spend
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1,2
)
SELECT 
	country,
	ROUND(AVG(total_spend)::numeric,2) AS avg_spend
FROM lifetime 
GROUP BY 1
ORDER BY 2 DESC

--Q3: Which customers have created an account but never made a single purchase?

SELECT
	c.customer_id,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name
FROM customer AS c
LEFT JOIN invoice AS i ON c.customer_id=i.customer_id
WHERE i.customer_id IS NULL

--Q4: Identify repeat customers: list all customers who have placed two or more separate orders.

SELECT
	c.customer_id,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	COUNT(invoice_id) AS total_order
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1,2
HAVING COUNT(invoice_id)>=2

--Q5: For customers who made more than one purchase, what is the gap in days between their first and second orders?

WITH purchase_date AS (
SELECT
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	i.invoice_date second_date,
	LAG(i.invoice_date) OVER(PARTITION BY c.customer_id ORDER BY i.invoice_date) AS first_date,
	ROW_NUMBER() OVER(PARTITION BY c.customer_id ORDER BY i.invoice_date) AS rank
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
)
SELECT 
	customer_name,
	second_date,
	first_date,
	(second_date-first_date) AS days_diff
FROM purchase_date
WHERE rank=2

--Q6: Which customers have an average order value (AOV) higher than the global average order value?

SELECT
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	ROUND(AVG(i.total)::numeric,2) AS customer_aov
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1
HAVING AVG(i.total)>(SELECT AVG(total) FROM invoice)
ORDER BY 2 DESC

--Q7: Identify the top 3 spending customers within each individual country.

WITH customer_spend AS (
SELECT
	i.billing_country,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(i.total) AS total_spend
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1,2
),
RANK AS (
SELECT 
	billing_country,
	customer_name,
	ROUND(total_spend::numeric,2) AS total_spend,
	DENSE_RANK() OVER (PARTITION BY billing_country ORDER BY total_spend DESC) AS rank
FROM customer_spend
)
SELECT *
FROM RANK
WHERE rank<=3

--Q8: Classify customers into spending tiers: 'High Spender' (total spend > $70), 'Medium Spender' ($40 - $70), and 'Low Spender' (< 40).

WITH spending AS (
SELECT
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(i.total) AS total_spend
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1
)
SELECT
	customer_name,
	ROUND(total_spend::numeric,2) AS total_spend,
	CASE
		WHEN total_spend>70 THEN 'High Spender' 
		WHEN total_spend BETWEEN 40 AND 70 THEN 'Medium Spender'
		ELSE 'Low Spender'
	END AS spending_tiers
FROM spending

--Q9: Find the date and total value of each customer's most recent purchase.

WITH recent AS (
SELECT
	c.customer_id,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	i.invoice_date,
	i.total,
	ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY i.invoice_date DESC) AS rank
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
)
SELECT *
FROM recent
WHERE rank=1

--Q10: Which customers have purchased tracks across 6 or more distinct genres?

SELECT
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(il.quantity) AS total_order,
	COUNT(DISTINCT t.genre_id) AS distinct_genre
FROM customer AS c
JOIN invoice AS i ON c.customer_id=i.customer_id
JOIN invoice_line AS il ON i.invoice_id=il.invoice_id
JOIN track AS t ON il.track_id=t.track_id
GROUP BY 1 
HAVING COUNT(DISTINCT t.genre_id)>6
ORDER BY 3 DESC

--**-**-- Section 2: Sales, Revenue & Growth --**-**--

--Q1: What is the total revenue and total volume of tracks sold by the store in each calendar year?

SELECT
	EXTRACT(YEAR FROM i.invoice_date) AS year,
	ROUND(SUM(il.quantity*il.unit_price)::numeric,2) AS total_revenue,
	SUM(il.quantity) AS total_volume_sold
FROM invoice AS i
JOIN invoice_line AS il ON i.invoice_id=il.invoice_id
GROUP BY 1
ORDER BY 1

--Q2: Calculate the year-over-year (YoY) revenue growth percentage for each year compared to the previous year.

WITH year AS (
SELECT
	EXTRACT(YEAR FROM invoice_date) AS year,
	ROUND(SUM(total)::numeric,2) AS total_rev
FROM invoice 
GROUP BY 1
),
prev_rev AS (
SELECT
	year,
	total_rev,
	LAG(total_rev) OVER (ORDER BY year) AS prev_rev
FROM year
)
SELECT
	year,
	total_rev,
	prev_rev,
	ROUND((total_rev-prev_rev)::numeric,2) AS rev_diff,
	ROUND(((total_rev-prev_rev)*100.0/NULLIF(prev_rev,0))::numeric,2) AS pct_rev
FROM prev_rev
ORDER BY 1

--Q3: Which month across the entire dataset recorded the highest total sales volume?

SELECT
	TO_CHAR(invoice_date,'mon-yy') AS month_year_name,
	SUM(il.quantity) AS total_volume
FROM invoice AS i
JOIN invoice_line AS il ON i.invoice_id=il.invoice_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

--Q4: What is the cumulative (running total) sales revenue generated day-by-day or order-by-order over time?

SELECT 
	invoice_date AS DAY,
	ROUND(total::numeric,2) AS total,
	ROUND(SUM(total) OVER (ORDER BY invoice_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::numeric,2) AS running_total
FROM invoice

--Q5: What proportion of total global revenue does each country contribute?

SELECT 
	billing_country,
	ROUND(SUM(total)::numeric,2) AS total_revenue,
	ROUND((SUM(total)*100.0/(SELECT SUM(total) FROM invoice))::numeric,2) AS pct_rev
FROM invoice 
GROUP BY 1
ORDER BY 2 DESC

--Q6: Find all invoices where the total quantity of purchased tracks is strictly higher than the overall average basket size across all invoices.

SELECT 
	invoice_id,
	SUM(quantity) AS toatal_quantity
FROM invoice_line 
GROUP BY 1
HAVING SUM(quantity)>(SELECT SUM(quantity)/COUNT(DISTINCT invoice_id) FROM invoice_line)
ORDER BY 2 DESC

--Q7: Identify any orders where the invoice billing country differs from the customer's registered profile country.

SELECT
	c.first_name,
	c.country
FROM customer AS c
LEFT JOIN invoice AS i ON c.customer_id=i.customer_id
WHERE i.billing_country != c.country

--Q8: What is the average number of days between successive purchases across all returning customers?

WITH purchase_gaps AS(
SELECT 
	customer_id,
	invoice_date,
	LAG(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date),
	(invoice_date::date-LAG(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date)::date) AS days_gap
FROM invoice 
)
SELECT
	ROUND(AVG(days_gap)::numeric,2) AS avg_days_btw_purchases
FROM purchase_gaps
WHERE days_gap IS NOT NULL

--**-**-- Section 3: Product, Catalog & Inventory Analytics --**-**--

--Q1: Which 10 tracks have generated the highest total revenue in store history?

SELECT
	il.track_id,
	t.name AS track_name,
	ROUND(SUM(il.quantity*il.unit_price)::numeric,2) AS total_revenue
FROM invoice_line AS il 
JOIN track AS t ON il.track_id=t.track_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10

--Q2: Which 5 music genres are the most popular based on total quantity of tracks sold?

SELECT
	g.genre_id,
	g.name AS genre_name,
	SUM(il.quantity) AS total_track_sold
FROM invoice_line AS il
JOIN track AS t ON il.track_id=t.track_id
JOIN genre AS g ON t.genre_id=g.genre_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5

--Q3: Find the top-selling music genre in each country by total tracks purchased.

WITH country_sold AS (
SELECT
	i.billing_country AS country,
	g.name AS genre_name,
	SUM(il.quantity) AS total_sold
FROM invoice AS i
JOIN invoice_line AS il ON i.invoice_id=il.invoice_id
JOIN track AS t ON il.track_id=t.track_id
JOIN genre AS g ON t.genre_id=g.genre_id
GROUP BY 1,2
),
ranking AS(
SELECT
	country,
	genre_name,
	total_sold,
	DENSE_RANK() OVER (PARTITION BY country ORDER BY total_sold DESC) AS rank
FROM country_sold
)
SELECT * 
FROM ranking
WHERE rank=1

--Q4: Which albums have never had a single track purchased by any customer?

SELECT
	alb.title AS album_title
FROM album AS alb
JOIN track AS t ON alb.album_id=t.album_id
LEFT JOIN invoice_line AS il ON t.track_id=il.track_id
GROUP BY 1
HAVING COUNT(il.invoice_line_id)=0

--Q5: What percentage of the store's complete track catalog has never been sold?

SELECT 
	ROUND((COUNT(t.name)*100.0/(SELECT COUNT(track_id) FROM track))::numeric,2) AS unsold_pct
FROM track AS t
LEFT JOIN invoice_line AS il ON t.track_id=il.track_id
WHERE il.track_id IS NULL

--Q6: List the top 10 artists whose songs have sold the highest combined total volume of tracks.

SELECT
	art.name AS artist_name,
	SUM(il.quantity) AS total_qty_sold
FROM artist AS art
JOIN album AS alb ON art.artist_id=alb.artist_id
JOIN track AS t ON alb.album_id=t.album_id
JOIN invoice_line AS il ON t.track_id=il.track_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

--Q7: Identify all artists who have produced tracks across 3 or more distinct genres.

SELECT
	art.name AS artist_name,
	COUNT(DISTINCT t.genre_id) AS total_genre
FROM artist AS art 
JOIN album AS alb ON art.artist_id=alb.artist_id
JOIN track AS t ON alb.album_id=t.album_id
GROUP BY 1
HAVING COUNT(DISTINCT t.genre_id)>=3
ORDER BY 2 DESC

--Q8: Which audio media types (e.g., MPEG, AAC) generate the highest sales volume and revenue?

SELECT 
	mt.name AS media_type_name,
	SUM(il.quantity) As total_volume,
	ROUND(SUM(il.quantity*il.unit_price)::numeric,2) AS total_revenue
FROM media_type AS mt
JOIN track AS t ON mt.media_type_id=t.media_type_id
JOIN invoice_line AS il ON t.track_id=il.track_id
GROUP BY 1
ORDER BY 3 DESC
LIMIT 1

--Q9: What is the average duration (in minutes) and average unit price of tracks within each genre?

SELECT
	g.name AS genre_name,
	ROUND(AVG(t.milliseconds/60000)::numeric,2) AS avg_duration_in_min,
	ROUND(AVG(t.unit_price)::numeric,2) AS avg_up
FROM track AS t
JOIN genre AS g ON t.genre_id=g.genre_id
GROUP BY 1
ORDER BY 3 DESC

--Q10: Which playlists contain the highest number of unique unpurchased tracks?

SELECT
	p.name AS playlist_name,
	COUNT(DISTINCT t.track_id)
FROM playlist AS p
JOIN playlist_track AS pt ON p.playlist_id=pt.playlist_id
JOIN track AS t ON pt.track_id=t.track_id
LEFT JOIN invoice_line AS il ON t.track_id=il.track_id
WHERE il.track_id IS NULL
GROUP BY 1
ORDER BY 2 DESC

--**-**-- Section 4: Employee Performance & Operations --**-**--

--Q1: What is the total sales revenue generated by each sales support representative?

SELECT 
	CONCAT(e.first_name,' ',e.last_name) AS employee_name,
	ROUND(SUM(i.total)::numeric,2) AS total_revenue
FROM employee AS e
JOIN customer AS c ON e.employee_id::int=c.support_rep_id::int
JOIN invoice AS i ON c.customer_id=i.customer_id
GROUP BY 1
ORDER BY 2 DESC

--Q2: Display a organizational hierarchy showing each employee along with the full name of their direct reporting manager.

SELECT
	CONCAT(e.first_name,' ',e.last_name) AS employee_name,
	e.title AS job_title,
	COALESCE(CONCAT(m.first_name,' ',m.last_name),'TOP LEVEL') AS manager_name
FROM employee AS e 
LEFT JOIN employee AS m ON e.reports_to=m.employee_id
ORDER BY e.employee_id