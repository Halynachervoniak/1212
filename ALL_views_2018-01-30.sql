USE [DBE]
GO


----------------------EmployeeTimeInPosition-----------------------------------------------
IF OBJECT_ID ('dbo.VW_EmployeeTimeInPosition', 'V') IS NOT NULL
    DROP VIEW dbo.VW_EmployeeTimeInPosition;
GO


CREATE VIEW dbo.VW_EmployeeTimeInPosition
AS
SELECT 
		Categ AS TimeInPosition
		,FirstName +' '+ LastName AS Name
		,but.BusinessUnitType AS BU_Type
		,bu.Name AS BU_Name	
		,StartDate
		,IIF(EndDate is NULL,'Till now',CAST(EndDate AS VARCHAR(20))) AS EndDate
		,Duration
FROM (
		SELECT
			EmployeeID
			,BusinessUnitID
			,'Longest' AS Categ
			,StartDate
			,EndDate
			,DATEDIFF(DAY,StartDate,IIF(EndDate IS NULL,GETDATE(),EndDate)) Duration
		FROM EmployeeRoles
		WHERE DATEDIFF(DAY,StartDate,IIF(EndDate IS NULL,GETDATE(),EndDate))=(
							SELECT MAX(DATEDIFF(DAY,StartDate,IIF(EndDate IS NULL,GETDATE(),EndDate)))
							FROM EmployeeRoles				
						)
		UNION ALL
		SELECT
			EmployeeID
			,BusinessUnitID
			,'Shortest' AS Categ
			,StartDate
			,EndDate
			,DATEDIFF(DAY,StartDate,IIF(EndDate IS NULL,GETDATE(),EndDate)) Duration
		FROM EmployeeRoles
		WHERE DATEDIFF(DAY,StartDate,IIF(EndDate IS NULL,GETDATE(),EndDate))=(
							SELECT MIN(DATEDIFF(DAY,StartDate,IIF(EndDate IS NULL,GETDATE(),EndDate)))
							FROM EmployeeRoles				
						)	
	) AS emr
	JOIN Employees AS em
			ON emr.EmployeeID = em.ID
	JOIN BusinessUnits AS bu
			ON bu.id=emr.BusinessUnitID
		JOIN BusinessUnitTypes	BUT
			ON bu.BusinessUnitTypeID=but.ID
ORDER BY TimeInPosition
OFFSET 0 ROWS
GO


-----------------------GendeRelationCustomers------------------------------------------
IF OBJECT_ID ('dbo.VW_GendeRelationCustomers', 'V') IS NOT NULL
    DROP VIEW dbo.VW_GendeRelationCustomers;
GO


CREATE VIEW dbo.VW_GendeRelationCustomers
AS
SELECT a.Male
		,b.Female
FROM (
		SELECT
			COUNT(*) AS Male
			,Country
		FROM Customers 
		WHERE Gender= 'M'
		GROUP BY Country
	) AS a
	JOIN (
			SELECT 
				COUNT(*) AS Female
				,Country
			FROM Customers 
			WHERE Gender= 'f'
			GROUP BY Country
		) AS b 
	ON a.Country=b.Country

GO


-------------------------GendeRelationEmployees--------------------------------------------
IF OBJECT_ID ('dbo.VW_GendeRelationEmployees', 'V') IS NOT NULL
    DROP VIEW dbo.VW_GendeRelationEmployees;
GO


CREATE VIEW dbo.VW_GendeRelationEmployees 
AS
SELECT a.Male
		,b.Female
FROM (
		SELECT 
			COUNT(*) AS Male
			,Country
		FROM Employees 
		WHERE Gender= 'M'
		GROUP BY Country
	 ) AS a
  JOIN (
			SELECT 
				COUNT(*) AS Female
				,Country
			FROM Employees 
			WHERE Gender= 'f'
			GROUP BY Country
		) AS b 
	ON a.Country=b.Country
 GO

 
--------------------AvailableProductsBySubcategVendors-------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_AvailableProductsBySubcategVendors', 'V') IS NOT NULL
    DROP VIEW dbo.VW_AvailableProductsBySubcategVendors;
GO


CREATE VIEW dbo.VW_AvailableProductsBySubcategVendors
AS
SELECT 
		but.BusinessUnitType AS BU_Type
		,bu.NAME AS BU_Name
		,c.NAME AS Subcategory
		,v.NAME AS Vendor
		,Model
		,SUM(Quantity) AS Quantity
 FROM BusinessUnits AS bu
	JOIN BusinessUnitTypes AS but 
		on bu.BusinessUnitTypeID = but.ID 
	JOIN Stocks AS s
		on bu.ID = s.BusinessUnitID
	JOIN Products AS p
		on s.ProductID = p.ID
	JOIN Vendors AS v
		ON p.VendorID = v.ID
	JOIN Subcategories AS c
		ON p.SubcategoryID = c.ID
 GROUP BY but.BusinessUnitType,bu.NAME, c.NAME, v.NAME, Model
 ORDER BY Subcategory, BU_Name, Quantity DESC
 OFFSET 0 ROWS
GO


------------------------------------------------------------------------------------------------------------------------------
-------------------------AvaibleQtyProductsInBU-------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_AvaibleQtyProductsInBU', 'V') IS NOT NULL
    DROP VIEW dbo.VW_AvaibleQtyProductsInBU;
GO

CREATE VIEW dbo.VW_AvaibleQtyProductsInBU
AS
SELECT
	b.BusinessUnitType
	,a.Name AS BusinessUnit
	,a.City
	,a.State
	,a.Country
	,SUM(c.Quantity) AS Quantity
	,SUM(d.RetailPrice*c.Quantity) AS Price
FROM dbo.BusinessUnits AS a 
	 INNER JOIN dbo.BusinessUnitTypes AS b
		ON a.BusinessUnitTypeID=b.ID
	 INNER JOIN dbo.Stocks AS c
		ON a.ID=c.BusinessUnitID
	 INNER JOIN dbo.Products AS d
		ON d.ID=c.ProductID
GROUP BY b.BusinessUnitType, a.Name, a.City, a.State, a.Country
ORDER BY BusinessUnitType, Quantity, a.State DESC
OFFSET 0 ROW;
GO


------------------------------------------------------------------------------------------------------------------------------
-------------------------AgeRelationCustomers-------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_AgeRelationCustomers', 'V') IS NOT NULL
    DROP VIEW dbo.VW_AgeRelationCustomers;
GO

CREATE VIEW dbo.VW_AgeRelationCustomers
AS
SELECT AgeCategory, COUNT(*) AS Quantity
FROM (SELECT CASE 
			WHEN AgeCategory <21 THEN '1. <20 years'
			WHEN AgeCategory <26 THEN '2. 20 - 25 years'
			WHEN AgeCategory <36 THEN '3. 26 - 35 years'
			WHEN AgeCategory <51 THEN '4. 36 - 50 years'
			WHEN AgeCategory <61 THEN '5. 51 - 60 years'
			ELSE '6. >60 years'
		END AS AgeCategory
		FROM (
				SELECT FLOOR(DATEDIFF(DAY,BirthDate,CURRENT_TIMESTAMP)/365) AS AgeCategory
				FROM Customers
			) AS a
	) AS b
GROUP BY AgeCategory
ORDER BY AgeCategory
OFFSET 0 ROW
GO

------------------------------------------------------------------------------------------------------------------------------
-------------------------AgeRelationEmployee-------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_AgeRelationEmployees', 'V') IS NOT NULL
    DROP VIEW dbo.VW_AgeRelationEmployees;
GO

CREATE VIEW dbo.VW_AgeRelationEmployees
AS
SELECT AgeCategory, COUNT(*) AS Quantity
FROM (SELECT  CASE 
			WHEN AgeCategory <21 THEN '1. <20 years'
			WHEN AgeCategory <26 THEN '2. 20 - 25 years'
			WHEN AgeCategory <36 THEN '3. 26 - 35 years'
			WHEN AgeCategory <51 THEN '4. 36 - 50 years'
			WHEN AgeCategory <61 THEN '5. 51 - 60 years'
			ELSE '6. >60 years'
		END AS AgeCategory
		FROM (
				SELECT FLOOR(DATEDIFF(DAY,BirthDate,CURRENT_TIMESTAMP)/365) AS AgeCategory
				FROM Employees
			) AS a
	) AS b
GROUP BY AgeCategory
ORDER BY AgeCategory
OFFSET 0 ROW
GO


------------------------------------------------------------------------------------------------------------------------------
-------------------------Customer Registration Rating-------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_CustomerRegistrationRating', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_CustomerRegistrationRating];
GO

CREATE VIEW [dbo].[VW_CustomerRegistrationRating]
 AS
SELECT *
FROM (SELECT YEAR(a.RegistrationDate) AS RegistrYear, 
		DATENAME(MONTH,a.RegistrationDate) AS RegistrMonth,  
		COUNT(a.ID) as COUNT_CUST
	  FROM dbo.Customers AS a 
	  GROUP BY YEAR(a.RegistrationDate),DATENAME(MONTH,a.RegistrationDate)
	  UNION
	  SELECT YEAR(a.RegistrationDate) AS RegistrYear, 'Total',  COUNT(a.ID) AS COUNT_CUST
	   FROM dbo.Customers AS a 
	  GROUP BY YEAR(a.RegistrationDate)) AS MontlyRegistr
PIVOT( SUM(COUNT_CUST)   
	FOR RegistrMonth IN ([January],[February],[March],[April],[May],
	[June],[July],[August],[September],[October],[November],[December],[Total])) AS MNamePivot; 
GO

--------------------------------------------------------------------------------------------------------------------------------
-----------------------------Store Open Rating------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_StoreOpenRating', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_StoreOpenRating] ;
GO

CREATE VIEW [dbo].[VW_StoreOpenRating]
 AS
SELECT *
FROM   (SELECT YEAR(a.OpeningDate) AS OpenYear, DATENAME(MONTH,a.OpeningDate) AS OpenMonth, COUNT(a.ID) AS COUNT_UNIT
		FROM dbo.BusinessUnits AS a 
			 INNER JOIN dbo.BusinessUnitTypes AS b ON a.BusinessUnitTypeID=b.ID
		WHERE a.BusinessUnitTypeID=2
		GROUP BY YEAR(a.OpeningDate),DATENAME(MONTH,a.OpeningDate)
		UNION
		SELECT YEAR(a.OpeningDate) AS OpenYear, 'Total', COUNT(a.ID) AS COUNT_UNIT
		FROM dbo.BusinessUnits AS a 
			INNER JOIN dbo.BusinessUnitTypes AS b ON a.BusinessUnitTypeID=b.ID
		WHERE a.BusinessUnitTypeID=2
		GROUP BY YEAR(a.OpeningDate)) as MontlyUnitOpen
PIVOT( SUM(COUNT_UNIT)   
		FOR OpenMonth IN ([January],[February],[March],[April],[May],
		[June],[July],[August],[September],[October],[November],[December],[Total])) AS MNamePivot;
GO
---------------------------------------------------------------------------------------------------------------------------------
-----------------------------Stock Open Rating------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.VW_StockOpenRating', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_StockOpenRating] ;
GO

CREATE VIEW [dbo].[VW_StockOpenRating]
 AS
SELECT *
FROM   (SELECT YEAR(a.OpeningDate) AS OpenYear, DATENAME(MONTH,a.OpeningDate) AS OpenMonth, COUNT(a.ID) AS COUNT_UNIT
		FROM dbo.BusinessUnits AS a 
			INNER JOIN dbo.BusinessUnitTypes AS b ON a.BusinessUnitTypeID=b.ID
		WHERE a.BusinessUnitTypeID=1
		GROUP BY YEAR(a.OpeningDate),DATENAME(MONTH,a.OpeningDate)
		UNION
		SELECT YEAR(a.OpeningDate) AS OpenYear, 'Total', COUNT(a.ID) AS COUNT_UNIT
		FROM [dbo].[BusinessUnits] AS a 
			INNER JOIN [dbo].[BusinessUnitTypes] AS b ON a.BusinessUnitTypeID=b.ID
		WHERE a.BusinessUnitTypeID=1
		GROUP BY YEAR(a.OpeningDate)) AS MontlyUnitOpen
PIVOT( SUM(COUNT_UNIT)   
		FOR OpenMonth IN ([January],[February],[March],[April],[May],
			[June],[July],[August],[September],[October],[November],[December],[Total])) AS MNamePivot; 
GO
------------------------------------------------------------------------------------------------------------------------------
---------------------------ActiveBisinessUnit---------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_ActiveBisinessUnit', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_ActiveBisinessUnit];
GO

CREATE VIEW [dbo].[VW_ActiveBisinessUnit]
 AS
SELECT b.BusinessUnitType, 
	COUNT(a.ID) AS AllBisinessUnit, 
	SUM(CASE WHEN a.IsActive=1 then 1 else 0 end) AS ActiveBisinessUnit,
	TRY_CAST((SUM(CASE WHEN a.IsActive=1 THEN 1 ELSE 0 END)*100)/COUNT(a.ID) AS NUMERIC(5,2)) AS '% Active'
FROM BusinessUnits AS a 
	 INNER JOIN BusinessUnitTypes AS b ON a.BusinessUnitTypeID=b.ID
GROUP BY b.BusinessUnitType;
GO
------------------------------------------------------------------------------------------------------------------------------
----------------------------ActiveBisinessUnitInState-------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_ActiveBisinessUnitInState', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_ActiveBisinessUnitInState] ;
GO

CREATE VIEW [dbo].[VW_ActiveBisinessUnitInState]
 AS
SELECT a.[State], 
	SUM(CASE WHEN a.BusinessUnitTypeID=1 then 1 else 0 end) AS AllStock,
	SUM(CASE WHEN a.IsActive=1 AND a.BusinessUnitTypeID=1 then 1 else 0 end) AS ActiveStock,
	SUM(CASE WHEN a.BusinessUnitTypeID=2 then 1 else 0 end) AS AllStore,
	SUM(CASE WHEN a.IsActive=1 AND a.BusinessUnitTypeID=2 then 1 else 0 end) AS ActiveStore
FROM BusinessUnits AS a 
GROUP BY a.[State];
GO
------------------------------------------------------------------------------------------------------------------------------
-----------------------------------Avaible Quantity Products In BusinessUnit--------------------------------------------------
IF OBJECT_ID ('dbo.VW_AvaibleQtyProductsInBU', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_AvaibleQtyProductsInBU];
GO

CREATE VIEW [dbo].[VW_AvaibleQtyProductsInBU]
 AS
	SELECT b.BusinessUnitType, a.Name AS BusinessUnit,a.City, a.[State], a.Country, 
		  SUM(c.Quantity) AS Quantity, 
		  SUM(d.RetailPrice*c.Quantity) AS Price
	FROM BusinessUnits AS a 
		 INNER JOIN BusinessUnitTypes AS b ON a.BusinessUnitTypeID=b.ID
		 INNER JOIN Stocks AS c ON a.ID=c.BusinessUnitID
		 INNER JOIN Products AS d ON d.ID=c.ProductID
	GROUP BY b.BusinessUnitType, a.Name, a.City, a.State, a.Country
	ORDER BY BusinessUnitType, SUM(c.Quantity), a.[State] DESC
	OFFSET 0 row;
GO
------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular products in consigments---------------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularProductInConsigments', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_MostPopularProductInConsigments];
GO

CREATE VIEW [dbo].[VW_MostPopularProductInConsigments]
 AS
  SELECT TOP(20)  WITH TIES ProductID, d.Name AS Subcategory, c.Name AS Category, a.Model,
		 SUM(Quantity) AS Quantity, 
		 SUM(b.PurchasePrice*Quantity) AS PurchasePrice, 
		 ROUND(AVG(b.PurchasePrice),2) AS AvgPrice
  FROM ConsigmentDetails AS b
		INNER JOIN Products AS a ON a.ID=b.ProductID
		INNER JOIN Vendors AS v ON a.VendorID = v.ID
		INNER JOIN Subcategories AS d ON d.ID=a.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=d.CategoryID
  GROUP BY ProductID, d.Name, c.Name, a.Model
  ORDER BY SUM(Quantity) DESC;
  GO
------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular subcategory in consigments------------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularSubcategoryInConsigments', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_MostPopularSubcategoryInConsigments];
GO

CREATE VIEW [dbo].[VW_MostPopularSubcategoryInConsigments]
 AS
  SELECT TOP(20)  WITH TIES d.Name AS Subcategory, c.Name AS Category,
		 SUM(Quantity) AS Quantity, 
		 SUM(b.PurchasePrice*Quantity) AS PurchasePrice, 
		 ROUND(AVG(b.PurchasePrice),2) AS AvgPrice
  FROM ConsigmentDetails AS b
		INNER JOIN Products AS a ON a.ID=b.ProductID
		INNER JOIN Vendors AS v ON a.VendorID = v.ID
		INNER JOIN Subcategories AS d ON d.ID=a.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=d.CategoryID
  GROUP BY d.Name, c.Name
  ORDER BY SUM(Quantity) DESC;
  GO

  ------------------------------------------------------------------------------------------------------------------------------
  -----------------------------The most popular category in consigments-----------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularCategoryInConsigments', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_MostPopularCategoryInConsigments];
GO

CREATE VIEW dbo.VW_MostPopularCategoryInConsigments
 AS
  SELECT TOP(20)  WITH TIES c.Name AS Category, 
		 SUM(Quantity) AS Quantity, 
		 SUM(b.PurchasePrice*Quantity) AS TotalPurchasePrice,
		 ROUND(AVG(b.PurchasePrice),2) AS AvgPrice
  FROM ConsigmentDetails AS b
		INNER JOIN Products AS a ON a.ID=b.ProductID
		INNER JOIN Vendors AS v ON a.VendorID = v.ID
		INNER JOIN Subcategories AS d ON d.ID=a.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=d.CategoryID
  GROUP BY c.Name
  ORDER BY SUM(Quantity) DESC;
  GO
-----------------------------------------------------------------------------------------------------------------------------------
--------------------consignment by BussinessUnits-----------------------------------------------------------------------------

IF OBJECT_ID ('dbo.VW_Consignment', 'V') IS NOT NULL
DROP VIEW dbo.VW_Consignment;
GO

CREATE VIEW dbo.VW_Consignment
 AS
SELECT * 
FROM
	(SELECT a.Name AS BusinessUnit,a.City, a.State, a.Country,a.OpeningDate, YEAR(c.RecievedDate) AS [Year], 
			SUM (cd.PurchasePrice * cd.Quantity) AS [Sum per year]
	FROM ConsigmentDetails AS cd
		INNER JOIN Consigments AS c ON cd.ConsigmentID = c.ID
		INNER JOIN BusinessUnits AS a ON a.ID=c.BusinessUnitID
		INNER JOIN BusinessUnitTypes AS b ON a.BusinessUnitTypeID=b.ID
	GROUP BY c.BusinessUnitID,a.Name, a.City, a.State, a.Country,a.OpeningDate, YEAR(c.RecievedDate)) AS YearRevenueConsigmentPrice
PIVOT( SUM([Sum per year])   
		FOR [Year] IN ([2013],[2014],[2015],[2016],[2017],[2018])) AS MNamePivot
	ORDER BY OpeningDate
	OFFSET 0 row;
GO


-------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular products in Orders---------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularProductInOrders', 'V') IS NOT NULL
DROP VIEW dbo.VW_MostPopularProductInOrders;
GO

CREATE VIEW dbo.VW_MostPopularProductInOrders 
 AS
  SELECT TOP(20) WITH TIES b.ProductID, d.Name AS Subcategory, c.Name AS Category, a.Model,
		 SUM(b.Quantity) AS [Count of purchases],
		 SUM(b.UnitPrice*b.Quantity) AS [Sum of purchases],
		 ROUND(AVG(b.UnitPrice),2) AS AvgPrice
  FROM OrderDetails b
		INNER JOIN Products AS a ON a.ID=b.ProductID
		INNER JOIN Subcategories AS d ON d.ID=a.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=d.CategoryID
  GROUP BY b.ProductID, d.Name, c.Name, a.Model
  ORDER BY SUM(b.Quantity) DESC;
  GO

--------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular category in Orders----------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularCategoryInOrders', 'V') IS NOT NULL
DROP VIEW dbo.VW_MostPopularCategoryInOrders;
GO

CREATE VIEW dbo.VW_MostPopularCategoryInOrders
 AS
  SELECT TOP(20) WITH TIES c.Name AS Category,
		 SUM(b.Quantity) AS [Count of purchases],
		 SUM(b.UnitPrice*b.Quantity) AS [Sum of purchases],
		 ROUND(AVG(b.UnitPrice),2) AS AvgPrice
  FROM OrderDetails b
		INNER JOIN Products AS a ON a.ID=b.ProductID
		INNER JOIN Subcategories AS d ON d.ID=a.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=d.CategoryID
  GROUP BY c.Name
  ORDER BY SUM(b.Quantity) DESC;
  GO

---------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular Subcategory in Orders------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularSubcategoryInOrders', 'V') IS NOT NULL
DROP VIEW dbo.VW_MostPopularSubcategoryInOrders;
GO

CREATE VIEW dbo.VW_MostPopularSubcategoryInOrders
 AS
  SELECT TOP(20) WITH TIES d.Name AS Subcategory, c.Name AS Category,
		 SUM(b.Quantity) AS [Count of purchases],
		 SUM(b.UnitPrice*b.Quantity) AS [Sum of purchases],
		 ROUND(AVG(b.UnitPrice),2) AS AvgPrice
  FROM dbo.OrderDetails b
		INNER JOIN Products AS a ON a.ID=b.ProductID
		INNER JOIN dbo.Subcategories AS d ON d.ID=a.SubcategoryID
		INNER JOIN dbo.Categories AS c ON c.ID=d.CategoryID
  GROUP BY d.Name, c.Name
  ORDER BY SUM(b.Quantity) DESC;
  GO

------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular products in ReturnProducts-----------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularProductInReturns', 'V') IS NOT NULL
DROP VIEW dbo.VW_MostPopularProductInReturns;
GO

CREATE VIEW dbo.VW_MostPopularProductInReturns 
AS
  SELECT TOP(10) WITH TIES r.ProductID, sc.Name AS Subcategory, c.Name AS Category, p.Model,
		 SUM(r.Quantity) AS [Count of purchases],
		 SUM(r.UnitPrice*r.Quantity) AS [Sum of purchases],
		 ROUND(AVG(r.UnitPrice),2) AS AvgPrice
  FROM ReturnProducts r
		INNER JOIN Products AS p ON p.ID=r.ProductID
		INNER JOIN Subcategories AS sc ON sc.ID=p.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=sc.CategoryID
  GROUP BY r.ProductID, sc.Name, c.Name, p.Model
  ORDER BY SUM(r.Quantity) DESC;
  GO

------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular category in ReturnProducts------------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularCategoryInReturns', 'V') IS NOT NULL
DROP VIEW dbo.VW_MostPopularCategoryInReturns;
GO

CREATE VIEW dbo.VW_MostPopularCategoryInReturns 
 AS
  SELECT TOP(10) WITH TIES c.Name AS Category,
		 SUM(r.Quantity) AS [Count of purchases],
		 SUM(r.UnitPrice*r.Quantity) AS [Sum of purchases],
		 ROUND(AVG(r.UnitPrice),2) AS AvgPrice
  FROM ReturnProducts r
		INNER JOIN Products AS p ON p.ID=r.ProductID
		INNER JOIN Subcategories AS sc ON sc.ID=p.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=sc.CategoryID
  GROUP BY c.Name
  ORDER BY SUM(r.Quantity) DESC;
  GO

--------------------------------------------------------------------------------------------------------------------------------
-----------------------------The most popular Subcategory in ReturnProducts-----------------------------------------------------
IF OBJECT_ID ('dbo.VW_MostPopularSubcategoryInReturns', 'V') IS NOT NULL
DROP VIEW [dbo].[VW_MostPopularSubcategoryInReturns];
GO

CREATE VIEW [dbo].[VW_MostPopularSubcategoryInReturns]
 AS
  SELECT TOP(10) WITH TIES sc.Name AS Subcategory, c.Name AS Category,
		 SUM(r.Quantity) AS [Count of purchases],
		 SUM(r.UnitPrice*r.Quantity) AS [Sum of purchases],
		 ROUND(AVG(r.UnitPrice),2) AS AvgPrice
  FROM ReturnProducts r
		INNER JOIN Products AS p ON p.ID=r.ProductID
		INNER JOIN Subcategories AS sc ON sc.ID=p.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=sc.CategoryID
  GROUP BY sc.Name, c.Name
  ORDER BY SUM(r.Quantity) DESC;
  GO

------------------------------------------------------------------------------------------------------------------------------
--------------------------------total revenue by UN (Order+ReturnProdukts)---------------------------------------------
IF OBJECT_ID ('dbo.VW_TotalRevenueByBU', 'V') IS NOT NULL
DROP VIEW dbo.VW_TotalRevenueByBU;
GO

CREATE VIEW dbo.VW_TotalRevenueByBU
 AS
SELECT o.BusinessUnitID, bu.Name AS BusinessUnit, bu.[State],
	 SUM(od.Quantity) AS Count_of_purchases,
	 SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)) AS Sum_of_purchases,
	 TRY_CAST(((SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)))/
				SUM(SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0))) OVER())*100 AS NUMERIC(5,2)) AS [% of total]
FROM Orders AS o 
		INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
		INNER JOIN BusinessUnits AS bu ON o.BusinessUnitID=bu.ID
		INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
GROUP BY o.BusinessUnitID, bu.Name, bu.[State];
GO


------------------------------------------------------------------------------------------------------------------------------
--------------------------------total revenue by State (Order+ReturnProdukts)---------------------------------------------
IF OBJECT_ID ('dbo.VW_TotalRevenueByState', 'V') IS NOT NULL
DROP VIEW dbo.VW_TotalRevenueByState;
GO

CREATE VIEW dbo.VW_TotalRevenueByState
 AS
SELECT bu.[State], reg.Region,
	 COUNT(DISTINCT o.BusinessUnitID) AS Sum_of_BusinessUnit,
	 SUM(od.Quantity) AS Count_of_purchases,
	 SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)) AS Sum_of_purchases,
	 TRY_CAST(((SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)))/
				SUM(SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0))) OVER())*100 AS NUMERIC(5,2)) AS [% of total]
FROM Orders AS o 
		INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
		INNER JOIN BusinessUnits AS bu ON o.BusinessUnitID=bu.ID
		INNER JOIN Regions AS reg ON UPPER(bu.State)=UPPER(reg.State)
		INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
GROUP BY bu.[State], reg.Region;
GO


------------------------------------------------------------------------------------------------------------------------------
--------------------------------total revenue by Region (Order+ReturnProdukts)---------------------------------------------
IF OBJECT_ID ('dbo.VW_TotalRevenueByRegion', 'V') IS NOT NULL
DROP VIEW dbo.VW_TotalRevenueByRegion;
GO

CREATE VIEW dbo.VW_TotalRevenueByRegion
 AS
SELECT reg.Region,
	 COUNT(DISTINCT o.BusinessUnitID) AS Sum_of_BusinessUnit,
	 SUM(od.Quantity) AS Count_of_purchases,
	 SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)) AS Sum_of_purchases,
	 TRY_CAST(((SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)))/
				SUM(SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0))) OVER())*100 AS NUMERIC(5,2)) AS [% of total]
FROM Orders AS o 
		INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
		INNER JOIN BusinessUnits AS bu ON o.BusinessUnitID=bu.ID
		INNER JOIN Regions AS reg ON UPPER(bu.State)=UPPER(reg.State)
		INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
GROUP BY reg.Region;
GO

------------------------------------------------------------------------------------------------------------------------------
--------------------------------total revenue by Customer (Order+ReturnProdukts)----------------------------------------------
IF OBJECT_ID ('dbo.VW_TotalRevenueByCustomer', 'V') IS NOT NULL
DROP VIEW dbo.VW_TotalRevenueByCustomer;
GO

CREATE VIEW dbo.VW_TotalRevenueByCustomer
 AS
SELECT CustomerID, c.FirstName +' '+ c.LastName AS Customer,
	 SUM(od.Quantity) AS Count_of_purchases,
	 SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)) AS Sum_of_purchases,
	 TRY_CAST(((SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)))/
				SUM(SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0))) OVER())*100 AS NUMERIC(5,2)) AS [% of total]
FROM Orders AS o 
		INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
		INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
		INNER JOIN Customers AS c ON c.ID=o.CustomerID
GROUP BY CustomerID, c.FirstName +' '+ c.LastName
ORDER BY SUM(od.Quantity) DESC
OFFSET 0 row;
GO
------------------------------------------------------------------------------------------------------------------------------
--------------------------------total revenue by Employees (Order+ReturnProdukts)---------------------------------------------
IF OBJECT_ID ('dbo.VW_TotalRevenueByEmployee', 'V') IS NOT NULL
DROP VIEW dbo.VW_TotalRevenueByEmployee;
GO

CREATE VIEW dbo.VW_TotalRevenueByEmployee
 AS
SELECT o.EmployeeID, em.FirstName +' '+ em.LastName AS Employee,
	 SUM(od.Quantity) AS Count_of_purchases,
	 SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)) AS Sum_of_purchases,
	 TRY_CAST(((SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)))/
				SUM(SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0))) OVER())*100 AS NUMERIC(5,2)) AS [% of total]
FROM  Orders AS o 
		INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
		INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
		INNER JOIN Employees AS em ON em.ID=o.EmployeeID
GROUP BY EmployeeID, em.FirstName +' '+ em.LastName
ORDER BY SUM(od.Quantity) DESC
OFFSET 0 row;
GO

-------------------------------------info about orders--------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.VW_Orders', 'V') IS NOT NULL
    DROP VIEW dbo.VW_Orders;
GO

CREATE VIEW dbo.VW_Orders
AS
SELECT  o.BusinessUnitID, bu.Name AS BusinessUnit, bu.OpeningDate AS OpeningDateBU,
		bu.[State], reg.Region, bu.IsActive AS  IsActiveBU,
		od.OrderID, o.OperationTime, od.ProductID, p.Model, c.Name AS Category, sc.Name AS Subcategory,
		v.Name AS Vendor, v.Country AS VendorCountry,
		dis.[Percent] AS Discount, od.Quantity, od.UnitPrice,
		od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0) AS Sum_of_purchases,	
		o.EmployeeID, em.FirstName +' '+ em.LastName AS Employee,
		o.CustomerID, cu.FirstName +' '+ cu.LastName AS Customer
FROM Orders AS o 
		INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
		INNER JOIN BusinessUnits AS bu ON o.BusinessUnitID=bu.ID
		INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
		INNER JOIN Products AS p ON p.ID=od.ProductID
		INNER JOIN Subcategories AS sc ON sc.ID=p.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=sc.CategoryID
		INNER JOIN Customers AS cu ON cu.ID=o.CustomerID
		INNER JOIN Employees AS em ON em.ID=o.EmployeeID
		INNER JOIN Regions AS reg ON UPPER(bu.State)=UPPER(reg.State)
		INNER JOIN Vendors AS v ON p.VendorID = v.ID;
GO

-------------------------------------info about product-------------------------------------
IF OBJECT_ID ('dbo.VW_Products', 'V') IS NOT NULL
    DROP VIEW dbo.VW_Products;
GO

CREATE VIEW dbo.VW_Products
AS
SELECT p.ID AS ProductID, p.Model, c.Name AS Category, sc.Name AS Subcategory,
	   v.Name as Vendor, v.Country AS VendorCountry,
	   QuantityInConsigments, SumInConsigments,
	   QuantityInStocks, QuantityInStores,
	   QuantityInOrders, PurchaseInOrders,
	   QuantityInLosses, SumInLosses,
	   QuantityInReturns, SumInReturns
FROM Products AS p 
		INNER JOIN Subcategories AS sc ON sc.ID=p.SubcategoryID
		INNER JOIN Categories AS c ON c.ID=sc.CategoryID
		INNER JOIN Vendors AS v ON p.VendorID = v.ID
		LEFT JOIN ( SELECT  od.ProductID, 
							SUM(od.Quantity) AS QuantityInOrders,
							SUM(od.Quantity*od.UnitPrice*(1 - dis.[Percent]/100.0)) AS PurchaseInOrders
					FROM Orders AS o 
						 INNER JOIN OrderDetails AS od ON o.ID=od.OrderID
						 INNER JOIN Discounts AS dis ON dis.id=o.DiscountID
					GROUP BY od.ProductID) AS o  ON o.ProductID=p.ID
		LEFT JOIN (SELECT ProductID,
						  SUM(Quantity) AS QuantityInStocks
					FROM Stocks 
					INNER JOIN BusinessUnits bu ON BusinessUnitID=bu.ID
					WHERE BusinessUnitTypeID=1
					GROUP BY ProductID) AS InStock ON InStock.ProductID = p.ID
		LEFT JOIN (SELECT ProductID,
						  sum(Quantity) AS QuantityInStores
					FROM Stocks 
					INNER JOIN BusinessUnits bu ON BusinessUnitID=bu.ID
					WHERE BusinessUnitTypeID=2
					GROUP BY ProductID) AS InStore ON InStore.ProductID = p.ID
		LEFT JOIN (SELECT ProductID, 
						  sum(Quantity) AS QuantityInConsigments, 
						  sum(Quantity*PurchasePrice) as SumInConsigments
					FROM ConsigmentDetails
					GROUP BY ProductID) AS InConsigment ON InConsigment.ProductID = p.ID
		LEFT JOIN (SELECT ProductID, 
						  sum(Quantity) AS QuantityInLosses, 
						  sum(Quantity*Price) as SumInLosses
					FROM Losses
					GROUP BY ProductID) AS InLosses ON InLosses.ProductID = p.ID
		LEFT JOIN (SELECT ProductID, 
						  sum(Quantity) AS QuantityInReturns, 
						  sum(Quantity*UnitPrice) as SumInReturns
					FROM ReturnProducts
					GROUP BY ProductID) AS InReturns ON InReturns.ProductID = p.ID;
GO












-------------------------------------------
IF OBJECT_ID ('dbo.VW_RevenueConsignmentPrice', 'V') IS NOT NULL
DROP VIEW dbo.VW_RevenueConsignmentPrice;
GO

/*CREATE VIEW VW_Total AS
 SELECT SUM(SumInConsigments) AS Consigments,
		SUM(PurchaseInOrders) AS Orders, 
		SUM(SumInLosses)  AS Losses, 
		SUM(SumInReturns) AS [Returns]
FROM [VW_Products];*/