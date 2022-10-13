create database Report

select * from Customer
select * from prod_cat_info
select * from transactions

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Data Preperation and Understanding

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--1. What is the total number of rows in each of the 3 tables in the database?
select 'Customer' as Table_Name, count(*) as Row_Count
from Customer
Union
select 'Transaction' as Table_Name, count(*) as Row_Count
from Transactions
Union
select 'Prod_cat_info' as Table_Name, count(*) as Row_Count
from Prod_cat_info

--2. What is the total number of transactions that have a return?
select count(*) as Tot_Trans_Return 
from Transactions 
where Qty<0

--3. Convert date variables into valid date formats
alter table Customer
alter column DOB date
alter table Transactions
alter column tran_date date

/*4. What is the time range of transaction data available for analysis? show the 
output in number of days, months and years simultaneously in different columns*/
select 
      datediff(Day, min(tran_date), max(tran_date)) as Days_Difference,
      datediff(Month, min(tran_date), max(tran_date)) as Months_Difference,
      datediff(Year, min(tran_date), max(tran_date)) as Years_Difference
from Transactions

--5. Which product category does the sub_category 'DIY' belong to?
select prod_cat from prod_cat_info
where prod_subcat = 'DIY'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Data Analysis

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--1. Which channel is most frequently used for transactions?
select top 1 Store_type 
from Transactions

--2. What is the count of Male and Female customers in the database?
select gender, 
count(gender) as Gender_Count 
from Customer
group by gender 
having gender is not null

--3. From which city do we have the maximum number of customers and how many?
select top 1 city_code ,
count(city_code) as Number_of_Customers
from Customer
group by city_code
order by count(city_code) desc

--4. How many sub_categories are there under the books category?
select prod_cat,
count(prod_subcat) as Count_of_SubCategories
from prod_cat_info
where prod_cat = 'books'
group by prod_cat

--5. What is the maximum quantity of products ever ordered?
select top 1 Y.prod_cat,
count(Qty) as Total_Quantity_Ordered 
from Transactions as X
inner join 
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code And
   X.prod_subcat_code = Y.prod_sub_cat_code
group by Y.prod_cat
order by count(Qty) desc

--What is the net total revenue generated in categpries Electronics and Books?
select Y.prod_cat,
sum(total_amt) as Total_Revenue
from Transactions as X
inner join
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code 
group by Y.prod_cat
having prod_cat in ('Electronics', 'Books')

--7. How many customers have >10 transactions with us, excluding returns?
select count(*) as Number_of_customers_more_than_10_Transactions 
from (
       select cust_id,
       count(cust_id) as Cust_with_more_than_10_trans
       from Transactions
       where Qty>0
       group by cust_id
       having count(Transaction_id)>10
     ) 
as a

--8. What is the combined revenue earned from the 'Electronics' and 'Clothing' categories, from 'Flagship stores'?
select sum(total_amt) as Combined_revenue
from transactions as X
inner join
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code
where prod_cat in ('Electronics', 'Clothing') And   
      Store_type = 'flagship store'

--9.What is the total Revenue generated from 'Male' customers in 'Electronics' category? output should display total revenue by prod sub_cat?
select Z.prod_cat, Y.gender, prod_subcat,
sum(total_amt) as Total_Revenue
from transactions as X
inner join
Customer as Y
on X.cust_id = Y.customer_Id
inner join
prod_cat_info as Z
on X.prod_cat_code = Z.prod_cat_code And
   X.prod_subcat_code = Z.prod_sub_cat_code
group by prod_subcat, Y.gender, Z.prod_cat
having gender = 'M' and prod_cat = 'Electronics'

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
select top 5 prod_subcat,
         (select round(
                      (sum(case when total_amt>0 then total_amt else 0 end)/(select sum(total_amt) from transactions where total_amt>0)*100),2)) as percent_sales,
		 (select round(
                      (sum(case when total_amt<0 then total_amt else 0 end)/(select sum(total_amt) from transactions where total_amt<0)*100),2)) as percent_return
from Transactions as X
inner join 
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code And
   X.prod_subcat_code = Y.prod_sub_cat_code
group by prod_subcat
order by percent_sales desc

/*11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days 
of transactions from max transaction date available in the data?*/
select Y.customer_id, 
datediff(year, DOB, tran_date) as age,
sum(total_amt) as Tot_Revenue 
from transactions  as X
inner join 
Customer as Y
on X.cust_id = Y.customer_Id
group by customer_Id, DOB, tran_date
having datediff(year, DOB, tran_date) between 25 and 35 And
       datediff(Day, X.tran_date,(select max(tran_date) from Transactions)) <=30 
order by age

--12. Which product category has seen the max value of returns in the last 3 months of transactions?
select top 1 prod_cat,
sum(case when total_amt<0 then total_amt else 0 end) as Max_Return_Value
from Transactions as X
inner join
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code
group by prod_cat, tran_date
having tran_date > dateadd(month,-3,(select max(tran_date) from transactions))
order by Max_Return_Value asc

--13 Which store-type sells the maximum products; by value of sales amount and quantity sold?
select top 1 store_type,
sum(total_amt) as Total_Amount_Of_Sales,
sum(Qty) as No_Of_Quantity_Sold
from transactions
group by Store_type
order by Total_Amount_Of_Sales desc ,
         No_Of_Quantity_Sold desc

--14. What are the categories for which average revenue is above the overall average?
select prod_cat,
avg(total_amt) as Average_Amount
from transactions as X
inner join
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code
group by prod_cat
having avg(total_amt) > (select avg(total_amt) from transactions)

--15.Find the average and total revenue by each sub category for the categories which are among top 5 categories in terms of quantity sold?
select prod_cat, prod_subcat,
avg(total_amt) as Average_Amount,
sum(total_amt) as Total_Revenue
from transactions as X
inner join
prod_cat_info as Y
on X.prod_cat_code = Y.prod_cat_code And
   X.prod_subcat_code = Y.prod_sub_cat_code
where Y.prod_cat_code in
(
  select top 5 prod_cat_code
  from transactions
  group by prod_cat_code
  order by (select sum(case when Qty>0 then Qty else 0 end)) desc
)
group by prod_cat, prod_subcat
order by prod_cat

-----------------------------------------------------END OF CASE STUDY 1 RETAIL DATA ANAYSIS------------------------------------------------------------------------------------
