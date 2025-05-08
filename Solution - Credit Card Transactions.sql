-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends


select city,sum(amount) as total_spend,
sum(amount) *100.0/(select sum(amount)from credit_card_transcations) as percentage 
from credit_card_transcations
group by city
order by total_spend desc
limit 5;


-- 2- write a query to print highest spend month for each year and amount spent in that month for each card type
with cte1 as(
select card_type, year(transaction_date) as yr,
month(transaction_date) as mt, sum(amount) as total_spend
from credit_card_transcations
group by card_type, year(transaction_date), month(transaction_date)
), cte2 as (
select *, dense_rank()over(partition by card_type order by total_spend desc) as rn
from cte1
)
select *
from cte2
where rn =1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
    with cte as (
    select *, sum(amount) over(partition by card_type order by transaction_id, transaction_date) as total_spend
    from credit_card_transcations
    ), 
    cte2 as (
    select*, 
    dense_rank() over(partition by card_type order by total_spend) as rn
    from cte 
    where total_spend >= 1000000
    ) 
    select *
    from cte2
    where rn=1;
    

-- 4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select city, card_type, sum(amount) as amount,
sum(case
when card_type= "Gold" then amount
end) as gold_amount
from credit_card_transcations
group by city, card_type)

select city,sum(gold_amount) *100/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount) >0
order by gold_ratio;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
select city, 
max(exp_type) as highest_expense_type,
min(exp_type) as lowest_expense_type
from (select city, exp_type, sum(amount) as total_spend
from credit_card_transcations
group by city, exp_type ) as city_exp_total
group by city; 

with cte as (
select city , exp_type, sum(amount) as total_amount
from credit_card_transcations
group by city, exp_type
),cte2 as (
select *,
dense_rank() over(partition by city order by total_amount desc) as rn_desc,
dense_rank() over(partition by city order by total_amount asc) as rn_asc
from cte
) 
select city,
max(case when rn_asc=1 then exp_type end) as lowest_exp_type,
max(case when rn_desc =1 then exp_type end) as highest_exp_type
from cte2
group by  city ;







-- 6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,
sum(case when gender= "F" then amount else 0 end ) *100/sum(amount)as per_fem_contributions
from credit_card_transcations
group by exp_type;


-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
  WITH cte1 AS (
    SELECT card_type, exp_type, YEAR(transaction_date) AS year, 
   MONTH(transaction_date) AS month, SUM(amount) AS Total_spend
    FROM credit_card_transcations
    GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
),
cte2 AS (
SELECT card_type, exp_type, year,month, Total_spend,
LAG(Total_spend) OVER (PARTITION BY card_type, exp_type ORDER BY year, month) AS prev_spend
FROM cte1
)
SELECT card_type, exp_type, Total_spend, prev_spend,
Total_spend - prev_spend AS growth
FROM cte2
WHERE year = 2014 AND month = 1 AND prev_spend IS NOT NULL
ORDER BY growth DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
select city, sum(amount) *100/count(1) transaction_ratio
from credit_card_transcations
where dayname(transaction_date)in ("saturday","sunday")
group by city
order by transaction_ratio desc
limit 1;
-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (
select *,
row_number() over(partition by city order by transaction_date, transaction_id) as rn
from credit_card_transcations
)
select city,timestampdiff(day, min(transaction_date), max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1) = 2
order by datediff1
limit 1;
-- once you are done with this create a github repo to put that link in your resume. Some example github links:
-- https://github.com/ptyadana/SQL-Data-Analysis-and-Visualization-Projects/tree/master/Advanced%20SQL%20for%20Application%20Development
-- https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/COVID%20Portfolio%20Project%20-%20Data%20Exploration.sql
