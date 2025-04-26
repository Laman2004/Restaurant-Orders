use restaurant
select * from menu_items
select top 5 * from order_details
select item_name,price from menu_items where category='Main Course' order by price desc 
select AVG(price) as average_price from menu_items
select count(order_details_id) as total_place from order_details
select m.item_name,o.order_date,o.order_time from menu_items m left join order_details o on m.menu_item_id=o.item_id
select item_name from menu_items where price > (select avg(price) from menu_items)
select count(order_id) as count_order, month(order_date) as month_order from order_details group by month(order_date)
select category from menu_items group  by category having avg(price) > 15
select category, count(item_name) as count_item from menu_items group by category
select item_name, price, case when price > 20 then 'yes' else 'no' end as expensive from menu_items
update menu_items set menu_item_id = 101 where price = 25
insert into menu_items (menu_item_id, item_name, category, price) values (133, 'Dessert', 'American', 20)
delete from order_details where order_id < 100
select item_name, price, rank() over(order by price desc) as price_rank from menu_items
select item_name, price, price - lag(price) over(order by price desc) as previous_price, lead(price) over(order by price desc) - price as next_price from menu_items
with Expensive as (select item_name, price from menu_items where price > 15)
select * from Expensive
with Expensive as (select item_name, price from menu_items where price > 15)
select count(*) as count_items from Expensive
select order_id, item_name, price from menu_items m join order_details o on m.menu_item_id = o.item_id
select order_id, item_name, price from order_details o left join menu_items m on m.menu_item_id = o.item_id
select menu_item_id, property, property_value from (select menu_item_id, CAST(item_name AS VARCHAR(25)) AS item_name, CAST(category AS VARCHAR(25)) AS category, CAST(price AS VARCHAR(25)) AS price from menu_items) as menu unpivot (property_value for property in(item_name, category, price)) as unpvt
declare 
    @categoryfilter varchar(25) = 'American',
    @minprice decimal(10,2) = 15.00,
    @maxprice decimal(10,2) = 30.00,
    @sql nvarchar(max);
set @sql = N'select menu_item_id, item_name, category, price from menu_items
where category = @categoryfilter and price between @minprice and @maxprice'
exec sp_executesql @sql, N'@categoryfilter varchar(25), @minprice decimal(10,2), @maxprice decimal(10,2)', @categoryfilter, @minprice, @maxprice;
create procedure avg_price_by_category
 @categoryfilter varchar(25) = 'American'
 as 
 begin
 select avg(price) as avg_price from menu_items where category = @categoryfilter
 end
 exec avg_price_by_category
 create trigger after_insert_order_details
on order_details
after insert
as
begin
    declare @order_id int;
    select @order_id = order_id from inserted;
    insert into order_log (order_id, log_date, log_message)
    values (@order_id, getdate(), 'New order inserted into order_details');
end
select * from order_log
create table order_log (log_id int identity primary key, order_id int, log_date datetime, log_message varchar(100))

with menu_cte as ( select category as parent_name, null as child_name, 0 as level from  menu_items where  category is not null group by category
 union all
 select mi.category as parent_name, mi.item_name as child_name, 1 as level from menu_items mi where mi.category is not null)
select case when level = 0 then parent_name else replicate('  ', level) + child_name end as item_hierarchy from menu_cte order by parent_name, level, child_name;
ALTER TABLE menu_items ADD 
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL DEFAULT SYSUTCDATETIME(),
    valid_to DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999'),
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to);
ALTER TABLE menu_items SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.menu_items_history));
DECLARE @OrderId INT = (SELECT ISNULL(MAX(order_id), 0) + 1 FROM order_details);
DECLARE @OrderDetailId INT = (SELECT ISNULL(MAX(order_details_id), 0) + 1 FROM order_details);
DECLARE @OrderDate DATE = CAST(GETDATE() AS DATE);
DECLARE @OrderTime TIME = CAST(GETDATE() AS TIME);
DECLARE @MenuItemId INT = 25;
DECLARE @NewPrice DECIMAL(10,2) = 18.99;
BEGIN TRANSACTION
BEGIN TRY
    UPDATE menu_items
    SET price = @NewPrice
    WHERE menu_item_id = @MenuItemId;
    INSERT INTO order_details (order_details_id, order_id, order_date, order_time, item_id)
    VALUES (@OrderDetailId, @OrderId, @OrderDate, @OrderTime, @MenuItemId);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT ERROR_MESSAGE();
END CATCH;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SensitiveDataReader')
BEGIN CREATE ROLE SensitiveDataReader END
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Laman')
BEGIN CREATE USER Laman WITHOUT LOGIN END
ALTER ROLE SensitiveDataReader ADD MEMBER Laman;
GRANT SELECT ON dbo.menu_items TO SensitiveDataReader;
GRANT SELECT ON dbo.order_details TO SensitiveDataReader;

CREATE NONCLUSTERED INDEX idx_menu_items_category ON menu_items (category) INCLUDE (menu_item_id, item_name, price);









