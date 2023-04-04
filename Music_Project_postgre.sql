Select * from album ;

/* 
1. who is the senior most employee based on the job title ? 
*/
select * from employee;
Select first_name , last_name , title from employee order by levels desc limit 1;

/* 
2. which contries have the most invoices ? 
*/
select * from invoice ;
select count(*) as c ,  billing_country 
from invoice group by billing_country  order by c desc limit 5 ;
 
 /* 
3. What are the top three values of total invoices ? 
*/

select * from invoice order by total desc limit 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city ,  sum(total) invoice_total
from invoice group by billing_city  order by invoice_total desc limit 2;


/* Q5: Who is the best customer? The customer who has spent the most money
will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select customer.customer_id ,concat(customer.first_name,customer.last_name), sum(total) as TotalMoneySpent
from invoice , customer where customer.customer_id = invoice.customer_id group by 
customer.customer_id
order by TotalMoneySpent desc limit 2;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all
Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select distinct email, first_name , last_name  from customer 
join invoice on customer.customer_id = invoice.customer_id  
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in (
	select track_id from track 
	join genre on genre.genre_id = track.genre_id
	where genre.name like 'Rock' 
)
order by email ;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
select artist.artist_id ,artist.name
, count(artist.artist_id) as Total_Tracks 
from track   
join album  on track.album_id = album.album_id 
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by Total_Tracks desc
limit 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name , milliseconds from track where milliseconds > 
(select avg(milliseconds) as  avg_track_length from track)
order by milliseconds desc ;

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists?
Write a query to return customer name, 
artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the 
InvoiceLines. Now use this artist to find which customer spent the most on this 
artist. For this query, you will need to use the Invoice, InvoiceLine, Track, 
Customer, Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */
with best_selling_artist AS (
	select artist.artist_id , artist.name , 
	sum(invoice_line.unit_price * invoice_line.quantity) as sum from invoice_line 
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by artist.artist_id 
	order by sum desc limit 1 
)
select customer.customer_id ,customer.first_name , customer.last_name , bsa.name, 
sum(invoice_line.unit_price * invoice_line.quantity) as total_sales from invoice
join invoice_line on invoice_line.invoice_id = invoice.invoice_id
join customer on customer.customer_id = invoice.customer_id
join track on track.track_id = invoice_line.track_id
join album on album.album_id = track.album_id
join best_selling_artist bsa on bsa.artist_id = album.artist_id
group by 1,2,3,4 
order by 5 desc
;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */
With popular_genre as( 
	select count(invoice_line.quantity), customer.country , genre.name genre_name , genre.genre_id
	,Row_Number() over (partition by customer.country 
					   order by count(invoice_line.quantity )desc ) as RowNumber
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join invoice on invoice.invoice_id = invoice_line.invoice_id
	join customer on customer.customer_id = invoice.customer_id
	join genre on genre.genre_id = track.genre_id
	group by 2,3,4 
	order by 2
)
select * from popular_genre where RowNumber <= 1;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */
WITH Customter_with_country AS (
	select sum(invoice.total) total_spending , customer.customer_id, customer.first_name,customer.last_name,invoice.billing_country
	,ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
	from invoice 
	join customer on customer.customer_id = invoice.customer_id
	group by 2,3,4,5
	order by 5 asc ,1 desc
) 
select * from Customter_with_country where RowNo <= 1 ;



WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country
	)
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;