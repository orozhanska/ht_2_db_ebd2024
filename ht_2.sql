CREATE DATABASE IF NOT EXISTS opt_db;
USE opt_db;

CREATE TABLE IF NOT EXISTS opt_clients (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    status ENUM('active', 'inactive') NOT NULL
);

CREATE TABLE IF NOT EXISTS opt_products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_category ENUM('Category1', 'Category2', 'Category3', 'Category4', 'Category5') NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS opt_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE NOT NULL,
    client_id CHAR(36),
    product_id INT,
    FOREIGN KEY (client_id) REFERENCES opt_clients(id),
    FOREIGN KEY (product_id) REFERENCES opt_products(product_id)
);

select distinct count(*) from opt_orders limit 100; -- 100 clients 

-- знайти місяць, в який активні покупці купляли найбільше кожну категорію
select distinct date_format(order_date, '%Y-%m') from opt_orders limit 10000;


explain analyze select

(select concat(' max when ', y_m,' of category ', product_category, ' ordered ', orders, ' times ' ) as res
from (select date_format(order_date, '%Y-%m') y_m, product_category, count(*) orders
	from (  select t2.*, p.product_name, p.product_category
			from (  select o.*, c.status
					from opt_orders o
					left join opt_clients c
					on o.client_id = c.id
					where order_date >= '2022-02-24'
					and c.status = 'active'
				) t2
			left join opt_products p
			on t2.product_id = p.product_id
	) t3
	group by date_format(order_date, '%Y-%m'), product_category
	order by orders DESC
) t4
limit 1) as max_month_cat,


(select concat(' min when ', y_m,' of category ', product_category, ' ordered ', orders, ' times ' ) as res
from (select date_format(order_date, '%Y-%m') y_m, product_category, count(*) orders
	from (  select t2.*, p.product_name, p.product_category
			from (  select o.*, c.status
					from opt_orders o
					left join opt_clients c
					on o.client_id = c.id
					where order_date >= '2022-02-24'
					and c.status = 'active'
				) t2
			left join opt_products p
			on t2.product_id = p.product_id
	) t3
	group by date_format(order_date, '%Y-%m'), product_category
	order by orders asc
) t4
limit 1)  as min_month_cat;

-- structured query

create index orders_date_indx
on opt_orders(order_date);

with monthly_orders as (
    select date_format(order_date, '%Y-%m') y_m, p.product_category, count(*) orders
    from opt_orders o
    left join opt_clients c on o.client_id = c.id
    left join opt_products p on o.product_id = p.product_id
    where o.order_date >= '2022-02-24'
      and c.status = 'active'
    group by y_m, p.product_category
)

select
    (select concat('max when ', y_m, ' of category ', product_category, ' ordered ', orders, ' times') AS res
     from monthly_orders
     order by orders DESC
     limit 1) max_month_cat,

    (select CONCAT('min when ', y_m, ' of category ', product_category, ' ordered ', orders, ' times') AS res
     from monthly_orders
     order by orders ASC
     limit 1) min_month_cat;


