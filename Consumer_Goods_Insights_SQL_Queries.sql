
-- Que. 1
select 
	distinct(market) 
from gdb023.dim_customer
where 
	customer = 'Atliq Exclusive' and region = 'APAC';

-- Que. 2
/* select count(distinct(product_code)) as unique_products_2020 from gdb023.fact_manufacturing_cost
where cost_year = 2020
union all 
select count(distinct(product_code)) as unique_products_2021 from gdb023.fact_manufacturing_cost
where cost_year = 2021; */

with cte as (
	select
		sum(case when cost_year = 2021 then 1 else 0 end) as unique_products_2021,
		sum(case when cost_year = 2020 then 1 else 0 end) as unique_products_2020
	from gdb023.fact_manufacturing_cost
)

select 
	unique_products_2020, 
    unique_products_2021, 
    concat(round(((unique_products_2021 - unique_products_2020)/unique_products_2020)*100,2),'%') as percentage_chg
from cte;

-- Que. 3
select 
	segment, 
    count(distinct(product_code)) as product_count 
from gdb023.dim_product
group by segment
order by product_count desc;

-- Que. 4
  
with cte as (
	select b.segment,
		sum(case when a.cost_year = 2021 then 1 else 0 end) as unique_products_2021,
		sum(case when a.cost_year = 2020 then 1 else 0 end) as unique_products_2020
	from gdb023.fact_manufacturing_cost a
	join gdb023.dim_product b
		on a.product_code = b.product_code
	group by b.segment
    )
    
select
	segment,
    unique_products_2020,
    unique_products_2021,
    (unique_products_2021 - unique_products_2020) as difference
from cte;

/*
select *
from (select b.segment, count(distinct(a.product_code)) as unique_products_2021
	from gdb023.fact_manufacturing_cost a
	join gdb023.dim_product b
		on a.product_code = b.product_code
	where a.cost_year = 2021
	group by b.segment) table_21
join (select b.segment, count(distinct(a.product_code)) as unique_products_2021
	from gdb023.fact_manufacturing_cost a
	join gdb023.dim_product b
		on a.product_code = b.product_code
	where a.cost_year = 2020
	group by b.segment) table_20
on table_21.segment = table_20.segment;   */


-- Que. 5
select * from gdb023.fact_manufacturing_cost;
select * from gdb023.dim_product;

(select 
	a.product_code, 
	a.product, 
    b.manufacturing_cost 
from gdb023.dim_product a
join gdb023.fact_manufacturing_cost b 
	on a.product_code = b.product_code
order by b.manufacturing_cost desc
limit 1)
union
(select 
	a.product_code, 
    a.product, 
    b.manufacturing_cost 
from gdb023.dim_product a
join gdb023.fact_manufacturing_cost b 
	on a.product_code = b.product_code
order by b.manufacturing_cost asc
limit 1);


-- Que. 6
	with cte as (
    select 
	a.customer_code,
    c.customer,
    a.sold_quantity,
    d.gross_price,
    b.pre_invoice_discount_pct,
    round(d.gross_price*a.sold_quantity,2) as selling_price,
    round(b.pre_invoice_discount_pct*d.gross_price*a.sold_quantity,2) as discount
    from gdb023.fact_sales_monthly a 
    join gdb023.fact_pre_invoice_deductions b
		on a.customer_code = b.customer_code
        and a.fiscal_year = b.fiscal_year
	join gdb023.dim_customer c
		on a.customer_code = c.customer_code
	join gdb023.fact_gross_price d
		on d.product_code = a.product_code
        and d.fiscal_year = a.fiscal_year
	where a.fiscal_year = 2021 and c.market = 'India'
    )
    
    select
    customer_code,
    customer,
    concat(round(sum(discount)/sum(selling_price)*100,2),'%') as discount_pct
    from cte
    group by customer_code, customer
    order by discount_pct desc
    limit 5;

-- Que. 7
select * from gdb023.fact_sales_monthly;
select month(a.date) from gdb023.fact_sales_monthly a;


/* select a.customer, b.gross_price, month(c.date), c.fiscal_year, c.product_code, c.sold_quantity from gdb023.fact_sales_monthly c
join gdb023.dim_customer a
	on a.customer_code = c.customer_code
join gdb023.fact_gross_price b
	on b.product_code = c.product_code
where a.customer = 'Atliq Exclusive'; */
    

select 
	month(c.date) as Month, 
    c.fiscal_year as FY, 
    sum(round((c.sold_quantity)*(b.gross_price)/100000,2)) as Gross_sales_Amount
from gdb023.fact_sales_monthly c
join gdb023.dim_customer a
	on a.customer_code = c.customer_code
join gdb023.fact_gross_price b
	on b.product_code = c.product_code
    and b.fiscal_year = c.fiscal_year
where 
	a.customer = 'Atliq Exclusive'
group by Month, FY
order by FY;

-- Que. 8
with cte as(
	select 
		month(date) as Month, 
        sold_quantity,
	case
		when month(date) > 8 and month(date) < 12 then 'Q_1'
		when month(date) > 11 or month(date) < 3 then 'Q_2'
		when month(date) > 2 and month(date) < 6 then 'Q_3'
		else 'Q_4'
	end as Quarter
	from gdb023.fact_sales_monthly
	where 
		fiscal_year = 2020)

select 
	Quarter, 
    sum(sold_quantity) as total_sold_quantity 
from cte
group by Quarter
order by total_sold_quantity desc;

/* select Quarter, sum(sold_quantity) as total_sold_quantity,
case
	when month(date) > 8 and month(date) < 12 then 'Q_1'
    when month(date) > 11 or month(date) < 3 then 'Q_2'
    when month(date) > 2 and month(date) < 6 then 'Q_3'
    else 'Q_4'
end as Quarter
from gdb023.fact_sales_monthly
where fiscal_year = 2020
group by Quarter */;


-- Que. 9 (Very nice problem)

with cte as (
	select 
		a.channel, 
        round(sum((b.gross_price)*(c.sold_quantity))/1000000,2) as gross_sales_mln 
	from gdb023.fact_sales_monthly c
	join gdb023.dim_customer a
		on a.customer_code = c.customer_code
	join gdb023.fact_gross_price b
		on b.product_code = c.product_code
        and b.fiscal_year = c.fiscal_year
	where 
		c.fiscal_year = 2021
	group by a.channel
)

select 
	channel, 
	gross_sales_mln, 
    concat(round(((gross_sales_mln)/(select sum(gross_sales_mln) from cte))*100,2),'%') as percentage
from cte
group by channel
order by gross_sales_mln desc;


-- Que. 10
select * from gdb023.fact_sales_monthly;

/* with cte as (
select a.division, b.product_code, a.product, sum(b.sold_quantity) as total_sold_quantity
from gdb023.fact_sales_monthly b
join gdb023.dim_product a
	on a.product_code = b.product_code
where b.fiscal_year = 2021
group by a.division, b.product_code, a.product
)

select division, product_code, product, total_sold_quantity,
rank() over (
				partition by division 
                order by total_sold_quantity desc) rank_order
from cte
where rank_order < 4;
 */


with cte as (
	select 
		a.division, 
        b.product_code, 
        a.product, 
        sum(b.sold_quantity) as total_sold_quantity,
	rank() over (
				partition by division 
                order by sum(b.sold_quantity) desc) rank_order
	from gdb023.fact_sales_monthly b
	join gdb023.dim_product a
		on a.product_code = b.product_code
	where 
		b.fiscal_year = 2021
	group by a.division, b.product_code, a.product
)

select 
	division, 
    product_code, 
    product, 
    total_sold_quantity, 
    rank_order
from cte
where rank_order < 4;

select count(distinct(customer_code))from gdb023.fact_sales_monthly