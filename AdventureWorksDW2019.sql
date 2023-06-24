use AdventureWorksDW2019
go
/* Truy vấn ra các thông tin sau của các đơn hàng được đặt trong năm 2013 và 2014:
SalesOrderNumber, SalesOrderLineNumber, ProductKey, EnglishProductName; SalesTerritoryCountry, SalesAmount, OrderQuantity */

select 
SalesOrderNumber,
SalesOrderLineNumber,
FIS.ProductKey,
EnglishProductName,
SalesTerritoryCountry,
SalesAmount,
OrderQuantity
from FactInternetSales as FIS
left join DimProduct as DP 
on FIS.ProductKey = DP.Productkey
left join DimSalesTerritory as DST 
on FIS.SalesTerritoryKey = DST.SalesTerritoryKey
left join DimDate as DD 
on FIS.OrderDateKey = DD.DateKey
where LEFT(DD.DateKey, 4) in ('2013','2014')



/* Tính tổng doanh thu (InternetTotalSales) và số đơn hàng (NumberofOrders) 
của từng sản phẩm theo mỗi quốc gia từ bảng DimSalesTerritory. 
Kết quả trả về gồm:
SalesTerritoryCountry, ProductKey, EnglishProductName, InternetTotalSales, NumberofOrders */

select 
FIS.ProductKey,
EnglishProductName, 
SalesTerritoryCountry,
SUM (SalesAmount) as InternetTotalSales,
COUNT(Distinct SalesOrderNumber) as NumberofOrders

from FactInternetSales as FIS
left join DimProduct as DP 
on FIS.ProductKey = DP.ProductKey
left join DimSalesTerritory as DST 
on FIS.SalesTerritoryKey = DST.SalesTerritoryKey
group by FIS.Productkey, SalesTerritoryCountry, EnglishProductName
order by FIS.Productkey, SalesTerritoryCountry ASC



/* Tính toán % tỷ trọng doanh thu của từng sản phẩm (PercentofTotaInCountry) trong Tổng doanh thu của mỗi quốc gia.
Kết quả trả về gồm:
SalesTerritoryCountry, ProductKey, EnglishProductName, InternetTotalSales, PercentofTotaInCountry (định dạng %) */

with a as
(
    select 
    sum(SalesAmount) as CountryTotalSales,
    SalesTerritoryCountry
    from FactInternetSales as FIS
    left join DimProduct as DP 
    on FIS.ProductKey = DP.ProductKey
    left join DimSalesTerritory as DST 
    on FIS.SalesTerritoryKey = DST.SalesTerritoryKey
    group by SalesTerritoryCountry
    ),
b as
(
    select 
    FIS.ProductKey,
    EnglishProductName,
    SalesTerritoryCountry,
    sum(SalesAmount) as InternetTotalSales
    from FactInternetSales as FIS
    left join DimProduct as DP 
    on FIS.ProductKey = DP.ProductKey
    left join DimSalesTerritory as DST 
    on FIS.SalesTerritoryKey = DST.SalesTerritoryKey
    group by DST.SalesTerritoryCountry, EnglishProductName, FIS.ProductKey
    )
select
ProductKey,
EnglishProductName,
b.SalesTerritoryCountry,
InternetTotalSales,
InternetTotalSales/CountryTotalSales*100 as "PercentofTotaInCountry"
from b
full outer join a
on b.SalesTerritoryCountry = a.SalesTerritoryCountry
order by SalesTerritoryCountry, ProductKey ASC



/* Truy vấn ra danh sách top 3 khách hàng có tổng doanh thu tháng (CustomerMonthAmount) cao nhất trong hệ thống theo mỗi tháng.
Kết quả trả về gồm:
OrderYear, OrderMonth, CustomerKey, CustomerFullName (kết hợp từ FirstName, MiddleName,LastName), CustomerMonthAmount */

with a as 
(
    select year(a.orderdate) Orderyear,
    month(a.orderdate) Ordermonth,
    left(a.orderdatekey,6) yearmonth,
    a.CustomerKey, concat_ws(' ',FirstName,MiddleName,LastName) CustomerFullname,
    SalesAmount
    from FactInternetSales a
    left join DimCustomer b on a.CustomerKey=b.CustomerKey
    ), 

b as (
    select 
    yearmonth,
    Orderyear,
    Ordermonth,
    CustomerKey,
    CustomerFullname,
    sum(SalesAmount) CustomerMonthAmount,
    ROW_NUMBER() OVER (PARTITION BY yearmonth Order by sum(SalesAmount) desc) RN
    from a
    group by yearmonth, Orderyear, Ordermonth,CustomerKey,CustomerFullname
    )

select 
Orderyear,
Ordermonth,
CustomerKey,
CustomerFullname,
CustomerMonthAmount
from b
where rn in ('1','2','3')



/* Tính toán tổng doanh thu theo từng tháng (đặt tên là InternetMonthAmount).
Kết quả trả về gồm:
OrderYear, OrderMonth, InternetMonthAmount */

with a as
(
    select
    year(orderdate) as orderyear,
    month(orderdate) as ordermonth,
    left(orderdatekey,6) as yearmonth,
    SalesAmount
    from FactInternetSales
    )
select 
orderyear,
ordermonth,
sum(salesamount) as internetmonthamount
from a
group by orderyear, ordermonth, yearmonth
order by yearmonth desc


/* Tính toán % tăng trưởng doanh thu (đặt tên là PercentSalesGrowth) so với cùng kỳ năm trước 
(ví dụ:Tháng 11 năm 2012 thì so sánh với tháng 11 năm 2011). 
Kết quả trả về gồm:
OrderYear, OrderMonth, InternetMonthAmount,InternetMonthAmount_LastYear, PercentSalesGrowth */

with a as 
(
    select 
    year(orderdate) Orderyear,
    month(OrderDate) Ordermonth,
    left(OrderDateKey,6) as yearmonth,
    SalesAmount
    from FactInternetSales
    ),

b as 
(
    select 
    Orderyear,
    Ordermonth,
    yearmonth, 
    sum(SalesAmount) InternetMonthAmount
    from a
    group by Orderyear, Ordermonth, yearmonth
    )

select
b.Orderyear,
b.Ordermonth,
b.InternetMonthAmount,
b1.InternetMonthAmount as InternetMonthAmount_Lastyear,
(b.InternetMonthAmount - b1.InternetMonthAmount)*100/b1.InternetMonthAmount as PercentSalesGrowth
from b
left join (select * from b) b1
on b.Ordermonth=b1.Ordermonth and b.Orderyear=b1.Orderyear+1
order by Orderyear, Ordermonth asc 