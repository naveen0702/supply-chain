use supply_db;

## Step 1: Filter out ‘Sangli’ and ‘Srinagar’ from the city column of the data.
## Step 2: Filter out ‘SUSPECTED_FRAUD ’ from the order_status column of the data.
## Step 3: Aggregation – COUNT(order_id), GROUP BY Transaction_type
## Step 4: Sort the result in the descending order of Orders

SELECT 

Type AS Type_of_Transaction,

COUNT(order_id) as orders

FROM orders

WHERE Order_City <>'Sangli' AND Order_City <>'Srinagar'

AND Order_Status<>'SUSPECTED_FRAUD'

GROUP BY Type_of_Transaction

ORDER BY Orders DESC;
-- -----------------------------------------------------------------

## Get the list of the Top 3 customers based on the completed orders along with the following details:

-- Customer Id
-- Customer First Name
-- Customer City
-- Customer State
-- Number of completed orders
-- Total Sales


with order_summary as
(
select ord.order_id,
ord.customer_id, 
sum(sales) as ord_sales
from orders as ord
join
ordered_items as itm
on
ord.order_id = itm.order_id
where ord.order_status = "complete"
group by ord.order_id, 
ord.customer_id
)
select Id as customer_id, 
first_name as customer_first_name,
city as customer_city,
state as customer_state,
count(distinct order_id) as completed_orders,
sum(ord_sales) as total_sales
 from
order_summary as ord
inner join
customer_info as cust
on
ord.customer_id = cust.id
group by id,
customer_first_name,
customer_city,
customer_state
order by completed_orders desc
limit 3
;

### “Get the order count by the Shipping Mode and the Department Name. Consider departments with at least 40 closed/completed orders.”


-- Step 1: Join orders, ordered_items, product_info and department to get all the departments and orders associated with them
-- Step 2: Filter out ‘COMPLETE’ and ‘CLOSED’ from the order_status column of the orders table.
-- Step 3: Apply Aggregation – COUNT(order_id), GROUP BY department name
-- Step 4: In the table mentioned in Step 3, filter out COUNT(order_id)>=40
-- Step 4: In the table mentioned in Step 3, filter out COUNT(order_id)>=40
-- Step 5: From Step 1, perform aggregation – COUNT(order_id), GROUP BY Shipping mode and department name.
	-- Retain only those department names that were left over after the filter was applied in Step 4.
    

with  order_dept_summary as
	(
SELECT ord.order_id, ord.shipping_mode, d.name AS department_name, order_status
FROM
orders as ord
JOIN
ordered_items as ord_itm
ON ord.order_id=ord_itm.order_id
JOIN
product_info as p
ON ord_itm.item_id=p.product_id
JOIN
department as d
ON p.department_id=d.id
),
department_summary as
(
select department_name, count(order_id) as order_count
 from order_dept_summary
where order_status = 'complete' or order_status='closed'
group by department_name
)
select * from department_summary
where order_count>=40;


## 	“Create a new field as shipment compliance based on Real_Shipping_Days and Scheduled_Shipping_Days.
# 		It should have the following values:

--  Cancelled shipment: If the Order Status is SUSPECTED_FRAUD or CANCELED
--  Within schedule: If shipped within the scheduled number of days 
--  On time: If shipped exactly as per schedule
--  Up to 2 days of delay: If shipped beyond schedule but delayed by 2 days
--  Beyond 2 days of delay: If shipped beyond schedule with a delay of more than 2 days


-- select distinct order_status,shipment_compliance
-- from
-- (
with compliance_summary as
(
select 
-- distinct (test for null values too)
Order_Id,Real_Shipping_Days,Scheduled_Shipping_Days,Shipping_Mode,order_status,
case when order_status = 'SUSPECTED_FRAUD' OR order_status = 'CANCELED' THEN 'Cancelled shipment'
	 when Real_Shipping_Days < Scheduled_Shipping_Days THEN 'WITHIN SCHEDULE'
     when Real_Shipping_Days = Scheduled_Shipping_Days THEN ' ON TIME'
	 when Real_Shipping_Days <= Scheduled_Shipping_Days+2 THEN 'UPTO 2 DAYS OF DELAY'
	 when Real_Shipping_Days > Scheduled_Shipping_Days+2 THEN 'BEYOND 2 DAYS OF DELAY'
else 'others' end AS shipment_compliance
from orders 
)
-- )as sta
select shipping_mode, count(order_id) as orders
 from
compliance_summary
where shipment_compliance in('UPTO 2 DAYS OF DELAY' , 'BEYOND 2 DAYS OF DELAY')
group by shipping_mode
order by orders desc
limit 1;
  
## An order is canceled when the status of the order is either CANCELED or SUSPECTED_FRAUD.
# Obtain the list of states by the order cancellation% and sort them in the descending order of the cancellation%.

##. Definition: Cancellation% = Cancelled order / Total orders”

-- Step 1: Filter out ‘CANCELED’ and ‘SUSPECTED_FRAUD’ from the order_status column of the orders table.
-- Step 2: From the result of Step 1, perform aggregation – COUNT(order_id), GROUP BY Order_State.
-- Step 3: Create separate aggregation of the orders table to get the total orders - COUNT(order_id), GROUP BY Order_State
-- Step 4: Join the results of Step 2 and Step 3 on Order_State.
-- Step 5: Create a new column with the calculation of Cancellation percentage = Cancelled Orders / Total Orders.
-- Step 6: Sort the final table in the descending order of Cancellation percentage.

with cancelled_orders_summary as 
(
select count(order_id) as cancelled_orders, order_state
from orders
where order_status = 'CANCELED' or order_status = 'SUSPECTED_FRAUD'
group by order_state
),
total_orders_summary AS
(
select count(order_id) as total_orders, order_state
from orders
group by order_state
)
SELECT t.order_state,
cancelled_orders, total_orders,
round(coalesce(cancelled_orders,0)/total_orders*100,2) as cancellation_percentage
FROM 
cancelled_orders_summary as c
RIGHT JOIN
total_orders_summary as t
ON c.Order_State=t.Order_state
























