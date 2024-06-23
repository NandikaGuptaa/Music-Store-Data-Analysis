SELECT * FROM album
SELECT * FROM artist
SELECT * FROM customer
SELECT * FROM employee
SELECT * FROM genre
SELECT * FROM invoice
SELECT * FROM invoice_line
SELECT * FROM media_type
SELECT * FROM playlist
SELECT * FROM playlist_track
SELECT * FROM track

-- Ques1- Find the senior most employee based on job title.

SELECT * FROM employee 
ORDER BY levels DESC
LIMIT 1

-- Ans- Mohan Madan

	
-- Ques2- Find the country which have the most invoices

SELECT COUNT(invoice_id) AS invoices , billing_country FROM invoice
GROUP BY billing_country
ORDER BY invoices DESC

--Ans- USA

	
--Ques3- What are top 3 values of total invoices?

SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3

--Ans- 23.76 , 19.8 , 19.8


--Ques4- Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name and sum of all invoice totals.
	
SELECT SUM(total) AS total_invoice , billing_city FROM invoice
GROUP BY billing_city
ORDER BY total_invoice DESC

--Ans- City: Prague , Total invoice: 273.240


--Ques5- Who is the best customer? The person who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.

-- here we will join two tables: 'invoice and customer table' because sales/invoice data is in invoice table and customer names & all details are in customer table.
	
SELECT SUM(a.total) AS total_invoice , b.customer_id , b.first_name , b.last_name
FROM invoice as a
LEFT JOIN customer as b
ON a.customer_id = b.customer_id
GROUP BY b.customer_id
ORDER BY total_invoice DESC
LIMIT 1

--Ans- R Madhav

-- Ques6- Write query to return the email, first name, last name and Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A.

-- we have to find genre id where genre name = Rock (using genre table)
-- join 'track table' to get track id (common column = genre id)
-- join 'invoice_line table' to get invoice id (common column = track id)
-- join 'invoice table' to get customer id (common column = invoice id)
-- join 'customer table' to get the remaining customer info (common column = customer id)

SELECT DISTINCT a.email , a.first_name , a.last_name , genre.name
FROM customer AS a
LEFT JOIN invoice ON a.customer_id = invoice.customer_id
LEFT JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
LEFT JOIN track ON invoice_line.track_id = track.track_id
LEFT JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name = 'Rock'
ORDER BY email


-- optimised solution because less number of JOINS are use, so better efficiency and performance

SELECT DISTINCT a.email , a.first_name , a.last_name 
FROM customer as a
LEFT JOIN invoice ON a.customer_id = invoice.customer_id
LEFT JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
	SELECT track_id 
	FROM track
	LEFT JOIN genre 
	ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email


-- Ques7- Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands.

-- we need genre name = Rock (from 'genre table')
-- take 'artist table' to get artist name and id
-- join with 'album table' to get album id (common column = artist id)
-- join with 'track table' to get genre id (common column = album id)
-- join with 'genre table' to get genre name which should be 'ROCK'
-- take count of 'album id' from 'track table' to get total number of songs by each artist

SELECT artist.artist_id , artist.name , COUNT(track.album_id) AS total_track_count
FROM artist 
LEFT JOIN album ON artist.artist_id = album.artist_id
LEFT JOIN track ON album.album_id = track.album_id
LEFT JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name = 'Rock'
GROUP BY artist.artist_id
ORDER BY total_track_count DESC
LIMIT 10


-- 2nd method
-- we need genre name = Rock (from 'genre table')
-- take 'track table' as the main table because we can get genre name and artist name both 
-- join with 'album table' using album id
-- join with 'artist table' using artist id
-- join with 'genre table' using genre id to use genre name = ROCK
-- number of songs = COUNT(artist.artist_id)

SELECT artist.artist_id , artist.name , COUNT(artist.artist_id) AS number_of_songs
FROM track
LEFT JOIN album ON track.album_id = album.album_id
LEFT JOIN artist ON album.artist_id = artist.artist_id
LEFT JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name = 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10


-- Ques8- Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

SELECT name , milliseconds FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC


-- Ques9- Find how much amount is spent by each customer on artists? Write a query to return customer name, artist name and total spent.

-- total amount spent = unit price * quantity 
-- CTE create (common table expression: query stored in a temporary table)
-- with CTE. we find the best selling artist. and then we use it to find the total amount spent by customers along with their details

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id , artist.name AS artist_name , SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
	FROM invoice_line
	LEFT JOIN track ON invoice_line.track_id = track.track_id
	LEFT JOIN album ON track.album_id = album.album_id
	LEFT JOIN artist ON album.artist_id = artist.artist_id
	GROUP BY 1
	ORDER BY total_sales DESC
	LIMIT 1
)

SELECT c.customer_id , c.first_name , c.last_name , bsa.artist_name , SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice AS i
RIGHT JOIN customer AS c ON i.customer_id = c.customer_id
RIGHT JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
RIGHT JOIN track AS t ON il.track_id = t.track_id
RIGHT JOIN album AS alb ON t.album_id = alb.album_id
RIGHT JOIN best_selling_artist AS bsa ON alb.artist_id = bsa.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


-- Ques10- We want to find out the most popular Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top genre. For countries where the maximum number of purchases is shared return all Genres.

-- creating CTE

WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) AS purchases , customer.country , genre.name , genre.genre_id,
	ROW_NUMBER() OVER (PARTITION BY customer.country
	ORDER BY COUNT(invoice_line.quantity) DESC) AS Row_no
	FROM invoice_line
	LEFT JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	LEFT JOIN customer ON invoice.customer_id = customer.customer_id
	LEFT JOIN track ON track.track_id = invoice_line.track_id
	LEFT JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC , 1 DESC
)
SELECT * FROM popular_genre WHERE Row_no = 1


-- Ques11- Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount.

-- creating CTE
	
WITH 
  customer_with_country AS (
	SELECT customer.customer_id , customer.first_name , customer.last_name , invoice.billing_country , SUM(invoice.total) AS total_spending,
	ROW_NUMBER() OVER (PARTITION BY invoice.billing_country ORDER BY SUM(invoice.total) DESC) AS Row_no
	FROM invoice 
	RIGHT JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY invoice.billing_country ASC , total_spending DESC
   )
SELECT * FROM customer_with_country WHERE Row_no = 1