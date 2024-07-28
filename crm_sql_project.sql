
/*B2B sales pipeline data from a fictitious company that sells computer hardware, 
including information on accounts, products, sales teams, and sales opportunities.*/
----------------------------------------------------------------------------------------------------------------------------
-- General Analysis 
-- [一般分析]
----------------------------------------------------------------------------------------------------------------------------
--===================================================================
-- 1. What is the total number of sales opportunities in the dataset?
-- [データセット内の販売機会の総数はいくらですか?]
--===================================================================

/*
select count(*) as total_number_of_sales_opportunities
from sales_pipeline
where opportunity_id is not null
*/

--===================================================================
-- 2. What is the average deal size for closed-won opportunities?
-- [成立した商談の平均取引規模はどれくらいですか?]
--===================================================================

/*
with grouped_table as ( select product, 
							   round(avg(cast(close_value as float)),2) as avg_value
						from sales_pipeline
						where deal_stage = 'won'
						group by product )
select p.product, 
       p.series,
	   p.sales_price,  
	   gt.avg_value as Average_deal_size, 
	   round(( p.sales_price - gt.avg_value ),2) as Price_difference 
from products p 
join grouped_table gt
on p.product = gt.product
*/

--===================================================================
-- 3. What is the win rate (percentage of closed-won opportunities) for the sales team?
-- [営業チームの勝率 (成立した商談の割合) はどれくらいですか?]
--===================================================================

/*

with grouped_table1 as ( 
						select st.regional_office as sales_team, 
						       count(*) as total_sales_amount
						from sales_pipeline sp
						right join sales_teams st
						on sp.sales_agent = st.sales_agent 
						group by regional_office),
						
     grouped_table2 as (
						select st.regional_office as sales_team, 
						       count(*) as total_sales_amount
						from sales_pipeline sp
						right join sales_teams st
						on sp.sales_agent = st.sales_agent
						where deal_stage = 'won'
						group by regional_office )
select t1.sales_team, 
       t1.total_sales_amount as total_deals, 
	   t2.total_sales_amount as deal_won, 
	   round((cast(t2.total_sales_amount as float) / t1.total_sales_amount)*100,2) as win_rate
from grouped_table1 t1
join grouped_table2 t2
on t1.sales_team = t2.sales_team
order by 4 desc
*/

--===================================================================
-- 4. How long does it typically take to move an opportunity from the initial stage to closure?
-- [営業案件を初期段階から完了まで移行するのに通常どれくらい時間がかかりますか?]
--===================================================================

/*
with days_table as (
					select datediff(day,cast(engage_date as date), cast(close_date as date)) as days_taken
					from sales_pipeline
					where deal_stage = 'won')
select min(days_taken) as min_days, 
       max(days_taken) as max_days, 
	   avg(days_taken) as avg_days
from days_table
*/
--===================================================================
-- 5. What is the average sales cycle length for different product categories?
-- [さまざまな製品カテゴリの平均販売サイクルの長さはどれくらいですか?]
--===================================================================

/*
select product, 
       avg(datediff(day,cast(engage_date as date),cast(close_date as date))) as days_taken
from sales_pipeline
where deal_stage = 'won'
group by product
order by 2 desc
*/

--===================================================================
-- 6. Which stage has the highest drop-off rate (percentage of opportunities lost at that stage)?
-- [どの段階の離脱率 (その段階で失われた機会の割合) が最も高いですか?]
--===================================================================

/*
select deal_stage, 
       count(*) as total_opportunities
from sales_pipeline
group by deal_stage
order by 2 desc
*/

----------------------------------------------------------------------------------------------------------------------------
-- Account Analysis
-- [アカウント分析]
----------------------------------------------------------------------------------------------------------------------------
--===================================================================
-- 7. Which accounts have the highest number of win opportunities?
-- [どのアカウントが最も多くの勝利機会を持っていますか?]
--===================================================================

/*
select top 10 a.account, 
       count(*) as total_win
from accounts a
left join sales_pipeline sp
on a.account = sp.account
where deal_stage = 'won'
group by a.account
order by 2 desc, 1 asc
*/
--===================================================================
-- 8. How does the distribution of opportunities vary by account size (e.g., small, medium, large)?
-- [機会の分布はアカウントのサイズ (小規模、中規模、大規模など) によってどのように異なりますか?]
--===================================================================

/*
-- @s_m_threshold variable is the threshold between small and medium sized by revenue accounts

declare @s_m_threshold as float
set @s_m_threshold = ( select max(revenue) as revenue
						from (
							  select revenue,
							  ntile(3) over (order by cast(revenue as float)) as division
							  from accounts) data
						where division = 1 )
-- print @s_m_threshold

-- @m_b_threshold variable is the threshold between medium and big sized by revenue accounts

declare @m_b_threshold as float
set @m_b_threshold = ( select max(revenue) as revenue
						from (
							  select revenue,
							  ntile(3) over (order by cast(revenue as float)) as division
							  from accounts) data
						where division = 2 )
--print @m_b_threshold

select 'Small' as account_size, 
       count(*) as total_opportunity
from accounts a 
left join sales_pipeline sp 
on a.account = sp.account 
where cast(revenue as float) < @s_m_threshold
union 
select 'Medium' as account_size, 
       count(*) as total_opportunity
from accounts a 
left join sales_pipeline sp 
on a.account = sp.account 
where cast(revenue as float) between @s_m_threshold and @m_b_threshold
union
select 'Big' as account_size, 
       count(*) as total_opportunity
from accounts a 
left join sales_pipeline sp 
on a.account = sp.account 
where cast(revenue as float) > @m_b_threshold

*/

----------------------------------------------------------------------------------------------------------------------------
-- Product Analysis
-- [製品分析]
----------------------------------------------------------------------------------------------------------------------------
--===================================================================
-- 9. Which products have the highest number of opportunities?
-- [どの製品が最も多くの機会を持っていますか?]
--===================================================================

/*
select sp.product, 
       count(*) as total_sales
from sales_pipeline sp
right join sales_teams st
on sp.sales_agent = st.sales_agent 
where sp.product is not null
group by sp.product
order by 2 desc
*/
--===================================================================
-- 10. What is the average deal size for each product?
-- [各商品の平均取引規模はどれくらいですか?]
--===================================================================

/*
with grouped_table as ( select p.product, 
                               round(avg(cast(sp.close_value as float)),2) as average_deal_size
						from products p
						left join sales_pipeline sp 
						on p.product = sp.product
						where sp.deal_stage = 'won'
						group by p.product
						)
select p.product, 
       p.series, 
	   gp.average_deal_size, 
	   p.sales_price, 
	   concat(round((gp.average_deal_size - p.sales_price),2),'  ','$') as difference_between
from grouped_table gp
join products p 
on gp.product = p.product
order by cast(p.sales_price as float) desc
*/

--===================================================================
-- 11. Are there products that have a significantly higher win rate than others?
-- [他の商品よりも勝率が著しく高い商品はありますか?]
--===================================================================

/*
with won_table as (
					select p.product, 
					       p.series, 
						   count(*) as won_opportunity
					from products p
					join sales_pipeline sp
					on p.product = sp.product
					where sp.deal_stage = 'won'
					group by p.product, p.series
					),
	 all_table as (
	 				select p.product, 
					       p.series, 
						   count(*) as opportunity
					from products p
					join sales_pipeline sp
					on p.product = sp.product
					group by p.product, p.series
					) 
select t1.product, 
       t2.series, 
	   t2.won_opportunity, 
	   t1.opportunity, 
	   round(t2.won_opportunity / cast(t1.opportunity as float) * 100,2) as win_rate
from all_table  t1
join won_table t2
on t1.product = t2.product
order by 4 desc
*/

--===================================================================
-- 12. Which products contribute the most to the company's overall revenue?
-- [会社全体の収益に最も貢献しているのはどの製品ですか?]
--===================================================================

/*
with aggregated_table as ( select product, 
                                  sum(cast(close_value as float)) as value_sold
							from sales_pipeline
							group by product ) 

--select *, sum(value_sold) over (order by value_sold) as cumulative_value
--from aggregated_table

select *, round(value_sold / (select sum(value_sold) from aggregated_table) *100,2) as revenue_contribution
from aggregated_table
order by 2 desc
*/


----------------------------------------------------------------------------------------------------------------------------
-- Team Performance Analysis
-- [チームパフォーマンス分析]
----------------------------------------------------------------------------------------------------------------------------
--===================================================================
-- 13. How does the win rate vary across different sales teams?
-- [営業チームが異なると、勝率はどのように異なりますか?]
--===================================================================

-- Central
/*
declare @central_value as int
set @central_value = (select count(*)
						from sales_pipeline sp
						right join sales_teams st
						on sp.sales_agent = st.sales_agent
						where st.regional_office = 'Central' )

select sp.sales_agent as Agents_name, 
       count(*) as Amount_sold, 
	   sum(cast(sp.close_value as float)) as Total_sold_value, 
	   round((cast(count(*) as float) / @central_value ) * 100,2) as win_proportion
from sales_pipeline sp
right join sales_teams st
on sp.sales_agent = st.sales_agent 
where (deal_stage = 'won') and (st.regional_office = 'Central')
group by sp.sales_agent
order by 3 desc
*/

-- West
/*
declare @west_value as int
set @west_value = (select count(*)
						from sales_pipeline sp
						right join sales_teams st
						on sp.sales_agent = st.sales_agent
						where st.regional_office = 'west' ) 

select sp.sales_agent as Agents_name, 
       count(*) as Amount_sold, 
	   sum(cast(sp.close_value as float)) as Total_sold_value, 
	   round((cast(count(*) as float) / @west_value ) * 100,2) as win_proportion
from sales_pipeline sp
right join sales_teams st
on sp.sales_agent = st.sales_agent 
where (deal_stage = 'won') and (st.regional_office = 'West')
group by sp.sales_agent
order by 4 desc
*/


--East
/*
declare @east_value as int
set @east_value = (select count(*)
						from sales_pipeline sp
						right join sales_teams st
						on sp.sales_agent = st.sales_agent
						where st.regional_office = 'east' ) 

select sp.sales_agent as Agents_name, 
       count(*) as Amount_sold, 
	   sum(cast(sp.close_value as float)) as Total_sold_value, 
	   round((cast(count(*) as float) / @east_value ) * 100,2) as win_proportion
from sales_pipeline sp
right join sales_teams st
on sp.sales_agent = st.sales_agent 
where (deal_stage = 'won') and (st.regional_office = 'East')
group by sp.sales_agent
order by 4 desc
*/
--===================================================================
-- 14 . What is the average deal size for each sales team?
-- [各営業チームの平均取引規模はどれくらいですか?]
--===================================================================

-- avg deal size = total revenue / number of deals

/*
with total_revenue as ( select st.regional_office, 
                               sum(cast(sp.close_value as float)) as total_revenue
						from sales_teams st
						left join sales_pipeline sp
						on st.sales_agent = sp.sales_agent
						group by st.regional_office ),

         num_deals as ( select st.regional_office, 
		                       count(*) as num_deals
						from sales_teams st
						left join sales_pipeline sp
						on st.sales_agent = sp.sales_agent
						group by st.regional_office)
select tr.regional_office, 
       tr.total_revenue, 
	   nd.num_deals, 
	   round(tr.total_revenue / nd.num_deals,2) as avg_deal_size
from total_revenue tr
join num_deals nd
on tr.regional_office = nd.regional_office
order by 4

*/

--===================================================================
-- 15 . Which sales teams have the shortest average sales cycle length? What practices contribute to this efficiency?
-- [平均販売サイクル期間が最も短いのはどの営業チームですか?この効率化にはどのような実践が貢献しているのでしょうか?]
--===================================================================

/*
select st.regional_office, 
       avg(DATEDIFF(day,CAST(sp.engage_date as date), 
	   cast(sp.close_date as date))) as avg_sales_cycle
from sales_teams st
join sales_pipeline sp
on st.sales_agent = sp.sales_agent
where sp.deal_stage = 'won'
group by st.regional_office
*/

--===================================================================
-- 16. Can you identify any quarter-over-quarter trends?
-- [四半期ごとの傾向を特定できますか?]
--===================================================================
/*
with date_table as ( select *, 
			         year(cast(engage_date as date)) as year_n,
		        	 month(cast(engage_date as date)) as month_n
					 from sales_pipeline
					 ),

     quarter_table as (	select *,
						      case when month_n in (1,2,3) then 1
							       when month_n in (4,5,6) then 2
							       when month_n in (7,8,9) then 3
							       else 4 end as quarter_n
					      from date_table )
*/
/*
select t1.Y, 
       t1.Q, 
	   t1.won_opportunity, 
	   concat(round ((cast (t1.won_opportunity as float) / t3.total_opportunity)*100,2),' ','%') as win_proportion  , 
	   t2.lost_opportunity,
	   concat(round ((cast (t2.lost_opportunity as float) / t3.total_opportunity)*100,2) ,' ','%') as lost_proportion,
	   t3.total_opportunity
from (
		select year_n as Y, quarter_n as Q, count(*) as won_opportunity
		from quarter_table
		where deal_stage = 'won'
		group by year_n, quarter_n ) t1
join (
		select year_n as Y, quarter_n as Q, count(*) as lost_opportunity
		from quarter_table
		where deal_stage = 'Lost'
		group by year_n, quarter_n ) t2
on (t1.Y = t2.Y) and (t1.Q = t2.Q)
join (  select year_n as Y, quarter_n as Q, count(*) as total_opportunity
		from quarter_table
		where year_n != 1900
		group by year_n, quarter_n) t3
on (t1.Y = t3.Y) and (t1.Q = t3.Q)
order by 1 asc, 2 asc
*/

--===================================================================
-- Products quarter-over-quarter trends
-- [製品の四半期ごとの傾向]
--===================================================================
/*
select *,
       RANK() over (partition by year_n, quarter_n order by proportion desc) as ranking
from (
		select w_1.product, 
		       w_1.year_n, 
			   w_1.quarter_n, 
			   w_1.won_opportunity, 
			   round((cast (w_1.won_opportunity as float) / w_2.total_won_opportunity) *100,2) as proportion
		from (
				select product, year_n, quarter_n, count(*) as won_opportunity
				from quarter_table
				where deal_stage = 'won'
				group by product, year_n, quarter_n ) w_1
		join ( select year_n as Y, quarter_n as Q, count(*) as total_won_opportunity
				from quarter_table
				where deal_stage = 'won'
				group by year_n, quarter_n) w_2
		on (w_1.year_n = w_2.Y) and (w_1.quarter_n = w_2.Q)) t
*/