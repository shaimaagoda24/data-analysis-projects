create database museum ;
select * from  work ;



--  1: Fetch all the paintings which are not displayed on any museums?
select * from work where museum_id is null ;


--  2: Are there museuems without any paintings?
select  distinct m.museum_id, m.name ,w.museum_id, w.name  from museum m left join work w on m.museum_id = w.museum_id 
having w.museum_id is null ;




--  3: How many paintings have an asking price of more than their regular price? 
select count(*) from product_size where regular_price-sale_price >0 ;

    

-- 4: Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size where (regular_price*0.5) > sale_price ;



-- 5: Which canva size costs the most?
select  cs.label,pz.sale_price from product_size pz join canvas_size cs
on pz.size_id=cs.size_id
 where sale_price=(select max(sale_price) from product_size)
;


-- 6: Identify the museums with invalid city information in the given dataset
SELECT * FROM museum WHERE city REGEXP '^[0-9]';           -- REGEXPis a matching operator  and ^ is the begining



-- 7: Fetch the top 10 most famous painting subject
	select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x where ranking <= 10;
        
        

--  8: Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select m.name ,m.city from museum_hours mh join  museum m  on m.museum_id=mh.museum_id where day ='sunday'
and exists(select 1 from museum_hours mh2 where mh2.museum_id=mh.museum_id and mh2.day='monday') ;




-- 9:  How many museums are open every single day?
with cte as
(select museum_id , rank() over(partition by museum_id order by day desc) as count from museum_hours)
select count(*) from cte join museum on cte.museum_id = museum.museum_id and  cte.count = 7 ;



--  10 :Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
with cte as (
select museum_id , count(museum_id) as count  from work group by museum_id order by count desc limit 5)
select * from museum m join cte c on c.museum_id=m.museum_id ;

         -- another solution 
select m.name as museum, m.city,m.country,x.no_of_painintgs
from (	select m.museum_id, count(1) as no_of_painintgs
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.museum_id) x
join museum m on m.museum_id=x.museum_id
where x.rnk<=5;


-- 11:  Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
with cte as (
select artist_id , count(artist_id) as count  from work group by artist_id order by count desc limit 5)
select * from artist ar join cte c on c.artist_id= ar.artist_id ;


-- 12: Display the 3 least popular canva sizes

	select size_id,label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;



-- 13: Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

with cte as(
select  museum_id, duration ,day from  museum_hours order by duration  desc limit 1
)
select *  from cte c join  museum m on c.museum_id = m.museum_id;



--  14: Which museum has the most no of most popular painting style?
with pop_style as 
		(select style
		,rank() over(order by count(1) desc) as rnk
		from work
		group by style),
	cte as
		(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		join pop_style ps on ps.style = w.style
		where w.museum_id is not null
		and ps.rnk=1
		group by w.museum_id, m.name,ps.style)
select museum_name,style,no_of_paintings
from cte 
where rnk=1;




-- 15 :Identify the artists whose paintings are displayed in multiple countries

SELECT w.artist_id, m.country
FROM museum m
INNER JOIN work w ON m.museum_id = w.museum_id
GROUP BY w.artist_id, m.country
HAVING COUNT(*) > 1 ;
                -- another solution --
with cte as
	(select distinct a.full_name as artist
	, w.name as painting, m.name as museum
	, m.country
	from work w
	join artist a on a.artist_id=w.artist_id
	join museum m on m.museum_id=w.museum_id)
select artist,count(artist) as no_of_countries
from cte
group by artist
having count(artist)>1
order by count(artist) desc;


--  16 : Display the country and the city with most no of museums.
-- Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
with ct1 as(
select country , count(country) as c , rank() over(order by count(country) desc) as rnk
 from museum group by country order by count(country) desc 
)
,ct2 as(
select city , count(city) , rank() over(order by count(city) desc) as rnk
 from museum group by city order by count(city) desc 
)
select country , city from ct1 cross join ct2 where ct1.rnk =1 and ct2.rnk=1 ; 



--  17: Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label
with cte as (
SELECT distinct * FROM product_size
WHERE regular_price = (SELECT MAX(regular_price) FROM product_size)) 
	select w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = cte.size_id;




--  18: Which country has the 5th highest no of paintings?

with cte as 
(select m.country, count(country) as no_of_Paintings , rank() over(order by count(country) desc) as rnk
from work w join museum m on m.museum_id=w.museum_id group by m.country)
select country, no_of_Paintings
from cte 
where rnk=5; 





-- 19: Which are the 3 most popular and 3 least popular painting styles? 
with cte as (
select style , count(style) , rank() over( order by count(style) desc  ) as rnk
 from work   group by style  having style is not null)
select * from cte where rnk <= 3 or rnk >((select count(*) from cte)-3) ;  





-- 20 : Which artist has the most no of Portraits paintings outside USA?. Display artist name,
-- no of paintings and the artist nationality.
-- select full_name as artist_name, nationality, no_of_paintings

	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;
