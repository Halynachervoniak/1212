USE [Lv-289.db]
GO

INSERT INTO [PayTypes]
	(
		[Title]
	)
	VALUES ('Cash')
		,('Card')
GO

INSERT INTO [Currencies] ([Type], [Short]) VALUES
	('United States dollar', 'USD'),
	('Euro', 'EUR'),
	('British Pound', 'GBP'),
	('Mexican Peso', 'MXN'),
	('Canadian Dollar', 'CAD'),
	('Australian Dollar', 'AUD'),
	('Japanese Yen', 'JPY'),
	('Chinese Renminbi', 'CNY'),
	('Indonesian Rupiah', 'IDR'),
	('Brazilian Real', 'BRL')
GO

--				16/01/2018
INSERT INTO [CurrencyRates] ([CurrencyID], [Rate]) VALUES
	(1, 1.0),
	(2, 0.7415),
	(3, 0.6602),
	(4, 16.6831),
	(5, 1.1050),
	(6, 1.1080),
	(7, 98.4251),
	(8, 5.6752),
	(9, 11291.2312),
	(10, 2.8755)
GO

INSERT INTO [Discounts] ([Percent], [MinSum], [Description])
VALUES 
	(0, 0, 'Discount 0%. For unregistered customers'),
	(30, 0, 'Discount 30%. For employees only'),
	(1, 1, 'Discount 1%. For registered customers'),
	(5, 5000, NULL),
	(10, 15000, NULL),
	(15, 25000, NULL),
	(20, 50000, NULL)
GO

INSERT INTO  [Customers]
(
	[FirstName],
	[LastName], 
	[Gender],
	[DiscountID],
	[RegistrationDate],
	[Phone], 
	[Email], 
	[BirthDate], 
	[Country], 
	[State], 
	[City], 
	[PostalCode], 
	[Address]
)
VALUES
(
	'Guest', 
	'Guest', 
	'-',
	1, 
	'2013-01-01',
	'+10800304030', 
	'guest@covfefestore.com', 
	'1998-06-26', 
	'USA', 
	'New York', 
	'New York', 
	'12790',
	NULL
),
(
	'Employee', 
	'Employee', 
	'-',
	2, 
	'2013-01-01',
	'+10800304030', 
	'service@covfefestore.com', 
	'1998-06-26', 
	'USA', 
	'New York', 
	'New York', 
	'12790',
	NULL
)
GO

INSERT INTO [Guaranties]([Duration], [Description]) 
VALUES
	(0,'without guarantee')
	,(1,'1 month of guarantee')
	,(3,'3 monthes of guarantee')
	,(6,'6 monthes of guarantee')
	,(9,'9 monthes of guarantee')
	,(12,'12 monthes of guarantee')
	,(18,'18 monthes of guarantee')
	,(24,'24 monthes of guarantee')
	,(36,'36 monthes of guarantee')
	,(60,'60 monthes of guarantee')
GO	

INSERT INTO [ReturnProductTypes] ([Description]) VALUES
('Return and take money (not fitted)(14 days)'),
('Exchange on another, similar(not fitted)(14 days)'),
('Return with defect and take money(guarantee)'),
('Exchange with defect on another, similar(guarant)')
GO

INSERT INTO [BusinessUnitTypes] ([BusinessUnitType]) VALUES
('Stock'),
('Store')
GO



INSERT INTO [Roles] ([Name],[Salary])
     VALUES
           ('Sales Assistant', 1500)
		   ,('Salesman', 2000)
		   ,('Sales Manager', 2500)
		   ,('Document Control Assistant', 2000)
		   ,('Document Control', 3000)
		   ,('Marketing Assistant', 2500)
		   ,('Marketing Manager', 3500)
GO


INSERT INTO [dbo].[LossTypes]
           ([Description])
     VALUES
           ('broken during transport'),
		   ('broken in stock'),
		   ('broken in store')
GO


INSERT INTO [Regions] ([State],[Region]) VALUES
('Arizona','West'),
('Alaska','West'),
('Colorado','West'),
('California','West'),
('Idaho','West'),
('Hawaii','West'),
('Montana','West'),
('Oregon','West'),
('Nevada','West'),
('Washington','West'),
('New Mexico','West'),
('Utah','West'),
('Wyoming','West'),
('Delaware','South'),
('Alabama','South'),
('Arkansas','South'),
('Florida','South'),
('Kentucky','South'),
('Louisiana','South'),
('Georgia','South'),
('Mississippi','South'),
('Oklahoma','South'),
('Maryland','South'),
('Tennessee','South'),
('Texas','South'),
('North Carolina','South'),
('South Carolina','South'),
('Virginia','South'),
('District of Columbia','South'),
('West Virginia','South'),
('Illinois','Central'),
('Iowa','Central'),
('Indiana','Central'),
('Kansas','Central'),
('Michigan','Central'),
('Minnesota','Central'),
('Ohio','Central'),
('Missouri','Central'),
('Wisconsin','Central'),
('Nebraska','Central'),
('North Dakota','Central'),
('South Dakota','Central'),
('Connecticut','East'),
('New Jersey','East'),
('Maine','East'),
('New York','East'),
('Massachusetts','East'),
('Pennsylvania','East'),
('New Hampshire','East'),
('Rhode Island','East'),
('Vermont','East')
GO


/* 

-- Enable Microsoft.ACE.OLEDB.12.0 in SQL server

EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
GO
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
GO

------SetUP Linked Server for connection to Excel document


EXEC sp_addlinkedserver
    @server = 'ExcelServer',
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0',
	@datasrc = 'c:\users\adminaccount\documents\Products.xls',
--	@datasrc = 'E:\Products.xls',
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;'

-- have gotten a possibility to work with excel-sheets like with tables

INSERT INTO Categories(Name, Description)
SELECT Name
		,Description
FROM ExcelServer...[Categories$]



INSERT INTO Subcategories(CategoryID,Name,Description,IsAviable)
SELECT Cat.ID
		,Src.Name
		,Src.Description 
		,'1' AS IsAviable
FROM ExcelServer...[Subcategories$] AS Src
	JOIN Categories AS Cat
		ON Src.CategoryName=Cat.Name


INSERT INTO Vendors(Name, Country, City, Phone, Email, IsActive, CurrencyID)
SELECT 
	Name
	,Country
	,City
	,Phone
	,Email
	,'1' AS IsActive
	, CurrencyID
FROM ExcelServer...[Vendors$] AS Src


INSERT INTO Products(VendorID, SubcategoryID, Model, Color, Src.Description, GuarantyID, RetailPrice)
SELECT 
		v.ID AS VendorID
		,s.ID AS SubcategoryID
		,Model
		,Color
		,Src.Description
		,g.ID AS GuarantyID
		,RetailPrice
FROM ExcelServer...[All$] AS Src
	JOIN Vendors AS v
		ON Src.Vendor=v.Name
	JOIN Subcategories AS s
		ON Src.SubcategoryName=s.Name
	JOIN Guaranties AS g
		ON Src.Guaranty=g.Duration
ORDER BY s.ID
