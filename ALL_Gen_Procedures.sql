
CREATE PROC [dbo].[STP_AddLogActivity]
	@PROCID INT
	, @InsertedRows INT = 0
	, @UpdatedRows INT = 0
	, @DeletedRows INT = 0
	, @DateStart DATETIME = NULL
	, @DateEnd DATETIME = NULL
	, @Status VARCHAR(10)
	, @ErrorMessage VARCHAR(255) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	--	returns id of inserted record from table LogActivities
	DECLARE @LogID INT;
	BEGIN TRAN
		IF (@DateEnd < @DateStart)
		BEGIN
			DECLARE @Swap DATETIME = @DateEnd;
			SET @DateEnd = @DateStart;
			SET @DateStart = @Swap;
		END

		IF (@DateStart IS NULL)
		BEGIN
			SET @DateStart = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		END
	
		DECLARE @ProcName VARCHAR(255) = TRY_CONVERT(VARCHAR(255), OBJECT_NAME(@PROCID));

		INSERT INTO LogActivities
			(
				[User]
				,[Process]
				,[InsertedRows]
				,[UpdatedRows]
				,[DeletedRows]
				,[DateStart]
				,[DateEnd]
				,[Status]
				,[ErrorMessage]
			)
			VALUES
			(
				TRY_CONVERT(VARCHAR(255), SYSTEM_USER)
				, @ProcName
				, @InsertedRows
				, @UpdatedRows
				, @DeletedRows
				, COALESCE(@DateStart, CURRENT_TIMESTAMP)
				, @DateEnd
				, @Status
				, @ErrorMessage
			);
		SET @LogID = SCOPE_IDENTITY();

		IF (@@ERROR = 0)
		BEGIN
			COMMIT;
		END
		ELSE
		BEGIN
			ROLLBACK;
		END
	RETURN @LogID;
END
GO

CREATE PROC [dbo].[STP_EditLogActivity]
	@LogID INT
	, @InsertedRows INT
	, @UpdatedRows INT
	, @DeletedRows INT
	, @DateEnd DATETIME
	, @Status VARCHAR(10)
	, @ErrorMessage VARCHAR(255)
AS
BEGIN
	BEGIN  TRAN
		
	UPDATE [dbo].[LogActivities]
		SET 
			[InsertedRows] = COALESCE(@InsertedRows, [InsertedRows])
			,[UpdatedRows] =  COALESCE(@UpdatedRows, [UpdatedRows])
			,[DeletedRows] =  COALESCE(@DeletedRows, [DeletedRows])
			,[DateEnd] = COALESCE(@DateEnd, CURRENT_TIMESTAMP)
			,[Status] =  COALESCE(@Status, [Status])
			,[ErrorMessage] = @ErrorMessage
		WHERE [ID] = @LogID;

	IF (@@ERROR = 0)
	BEGIN
		COMMIT;
	END
	ELSE
	BEGIN
		ROLLBACK;
	END
END
GO

CREATE PROC [dbo].[STP_LogError] @LogID INT, @ProcID INT
AS
BEGIN
	DECLARE
		@ErrorNumber INT = ERROR_NUMBER(),
		@ErrorSeverity INT = ERROR_SEVERITY(),
		@ErrorState INT = ERROR_STATE(),
		@ErrorLine INT = ERROR_LINE(),
		@errorMessageInfo VARCHAR(4000);

	SET @errorMessageInfo = 'Error Number ' + TRY_CAST(@ErrorNumber AS VARCHAR(50))+ ', ' +
							'Error Line ' + TRY_CAST(@ErrorLine AS VARCHAR(50)) + ', ' +
							'Error Message : ''' + TRY_CAST(ERROR_MESSAGE() AS VARCHAR(255)) + '''';

	IF EXISTS (SELECT * FROM [dbo].[LogActivities] WHERE [ID] = @LogID)
	BEGIN
		EXEC [STP_EditLogActivity] @LogID, 0, 0, 0, NULL, 'FAILURE', @errorMessageInfo;
	END
	ELSE
	BEGIN
		SET @errorMessageInfo = 'Does not exists record with ID: ' + TRY_CAST(@LogID AS VARCHAR(10));
		EXEC [STP_AddLogActivity] @ProcID, 0, 0, 0, NULL, 'FAILURE', @errorMessageInfo;
	END
END
GO

CREATE PROCEDURE [dbo].[STP_GenerateEmployeeRoles]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
		--	for table LogActivities
		DECLARE @LogID INT;	--	ID of inserted record into table LogActivities
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;

		DECLARE @StartProc DATETIME = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		DECLARE @RowsCount INT = (SELECT COUNT(*) FROM [EmployeeRoles]);

		--	fields which are into table EmployeeRoles
		DECLARE @EmployeeID INT;
		DECLARE @RoleID SMALLINT;
		DECLARE @BusinessUnitID SMALLINT;
		DECLARE @StartDate DATE;
		DECLARE @EndDate DATE;
		DECLARE @Description VARCHAR(255);

		--	Worker can has description, so it is list of worker`s description
		DECLARE @Descriptions TABLE([descr] VARCHAR(255));
		INSERT INTO @Descriptions
			(descr)
			VALUES
				(NULL)
				,('Good worker')
				,('Excellent worker')
				,('The best worker')
				,('Bad worker')
				,('The worst worker');

		--	list of stocks
		DECLARE @Stocks TABLE ([ID] INT IDENTITY, [BusinessUnitID] SMALLINT);
		INSERT INTO @Stocks ([BusinessUnitID])
			(
				SELECT [bu].[ID]
				FROM [BusinessUnits] [bu]
				JOIN [BusinessUnitTypes] [but]
					ON [bu].[BusinessUnitTypeID] = [but].[ID]
				WHERE
					LOWER([but].[BusinessUnitType]) LIKE 'stock'
			);

		--	list of stores
		DECLARE @Stores TABLE ([ID] INT IDENTITY, [BusinessUnitID] SMALLINT);
		INSERT INTO @Stores ([BusinessUnitID])
			(
				SELECT [bu].[ID]
				FROM [BusinessUnits] [bu]
				JOIN [BusinessUnitTypes] [but]
					ON [bu].[BusinessUnitTypeID] = [but].[ID]
				WHERE
					LOWER([but].[BusinessUnitType]) LIKE 'store'
			);
			
		--	iterators for Stores and Stocks
		DECLARE @iStock INT = (SELECT MAX([ID]) FROM @Stocks),
				@iStore INT = (SELECT MAX([ID]) FROM @Stores);

		DECLARE @IsActive BIT;

		--	in the stocks we do not have salers
		DECLARE @StockEmployeeRoles TABLE ([ID] TINYINT IDENTITY, [RoleID] SMALLINT);
		INSERT INTO @StockEmployeeRoles ([RoleID]) VALUES (4), (5);
		DECLARE @iStockEmplyeeRole TINYINT = (SELECT MAX([ID]) FROM @StockEmployeeRoles);

		DECLARE @i TINYINT;
		--/*
		--	loop foreach for Stocks
		--	each stock has as minimum 2 employees: document control and his assistant
		WHILE (@iStock > 0)
		BEGIN
			SET @BusinessUnitID = (SELECT [BusinessUnitID] FROM @Stocks WHERE [ID] = @iStock);
			SET @IsActive = (SELECT [IsActive] FROM [BusinessUnits] WHERE [ID] = @BusinessUnitID);
			--	loop for each stock role
			SET @i = @iStockEmplyeeRole;
			WHILE(@i > 0)
			BEGIN

				SET @RoleID = (SELECT [RoleID] FROM @StockEmployeeRoles WHERE [ID] = @i);

				SET @StartDate =
					(
						SELECT [OpeningDate]
							FROM [BusinessUnits]
							WHERE [ID] = @BusinessUnitID
					);

				--	if current stock is active Employee MUST be from list of Employees which don`t work now (EndDate IS NOT NULL) or new Employee without their job story
				IF (@IsActive = 1)
				BEGIN
					SET @EmployeeID =  
						(
							SELECT TOP(1) [ID] 
							FROM
							(
								SELECT [ID] FROM [Employees]
								EXCEPT
								SELECT DISTINCT [EmployeeID] AS [ID] FROM [EmployeeRoles] WHERE [EndDate] IS NULL
							)[a]
							ORDER BY NEWID()
						);
					-- Employee work now and he is without description
					SET @EndDate = NULL;
					SET @Description = NULL;
				END
				ELSE
	            BEGIN
					SET @EmployeeID =  
						(
							SELECT TOP(1) [ID] 
							FROM
							(
								SELECT [ID] FROM [Employees]
								EXCEPT
								SELECT DISTINCT [EmployeeID] AS [ID] FROM [EmployeeRoles]
							)[a]
							ORDER BY NEWID()
						);

					SET @EndDate = [dbo].[GetDateInRange](@StartDate, NULL);

					SET @Description = (SELECT TOP(1) [descr] FROM @Descriptions ORDER BY NEWID());
				END

				INSERT INTO EmployeeRoles
						   (
							   [EmployeeID]
							   ,[RoleID]
							   ,[BusinessUnitID]
							   ,[StartDate]
							   ,[EndDate]
							   ,[Description]
						   )
					 VALUES
						   (
							   @EmployeeID
							   , @RoleID
							   , @BusinessUnitID
							   , @StartDate
							   , @EndDate
							   , @Description
						   );
				SET @i -= 1;
			END
			SET @iStock -= 1;
		END
		--*/
		--	in the store we have each role
		--	in the stocks we do not have salers
		DECLARE @StoreEmployeeRoles TABLE ([ID] TINYINT IDENTITY, [RoleID] SMALLINT);
		INSERT INTO @StoreEmployeeRoles ([RoleID]) VALUES (2), (5), (7);
		DECLARE @iStoreEmplyeeRole TINYINT = (SELECT MAX([ID]) FROM @StoreEmployeeRoles);
		--/*
		--	loop foreach for Stores
		--	each stock has as minimum 3 employees
		WHILE (@iStore > 0)
		BEGIN
			SET @BusinessUnitID = (SELECT [BusinessUnitID] FROM @Stores WHERE [ID] = @iStore);
			SET @IsActive = (SELECT [IsActive] FROM [BusinessUnits] WHERE [ID] = @BusinessUnitID);
			--	loop for each store role
			SET @i = @iStoreEmplyeeRole;
			WHILE(@i > 0)
			BEGIN
				SET @RoleID = @i;
				SET @StartDate =
					(
						SELECT [OpeningDate]
							FROM [BusinessUnits]
							WHERE [ID] = @BusinessUnitID
					);
				--	if current store is active Employee MUST be from list of Employees which don`t work now (EndDate IS NOT NULL) or new Employee without their job story
				IF (@IsActive = 1)
				BEGIN
					SET @EmployeeID =  
						(
							SELECT TOP(1) [ID] 
							FROM
							(
								SELECT [ID] FROM [Employees]
								EXCEPT
								SELECT DISTINCT [EmployeeID] AS [ID] FROM [EmployeeRoles] WHERE [EndDate] IS NULL
							)a
							ORDER BY NEWID()
						);

					SET @EndDate = NULL;
					SET @Description = NULL;
				END
				ELSE
	            BEGIN
					SET @EmployeeID =  
						(
							SELECT TOP(1) [ID] 
							FROM
							(
								SELECT [ID] FROM [Employees]
								EXCEPT
								SELECT DISTINCT [EmployeeID] AS [ID] FROM [EmployeeRoles]
							)a
							ORDER BY NEWID()
						);

					SET @EndDate = [dbo].[GetDateInRange](@StartDate, NULL);

					SET @Description = (SELECT TOP(1) [descr] FROM @Descriptions ORDER BY NEWID());
				END

				INSERT INTO EmployeeRoles
						   (
							   [EmployeeID]
							   ,[RoleID]
							   ,[BusinessUnitID]
							   ,[StartDate]
							   ,[EndDate]
							   ,[Description]
						   )
					 VALUES
						   (
							   @EmployeeID
							   , @RoleID
							   , @BusinessUnitID
							   , @StartDate
							   , @EndDate
							   , @Description
						   );
				SET @i -= 1;
			END
			SET @iStore -= 1;
		END
		--*/
		DELETE FROM @Stocks;
		DELETE FROM @Stores;
		-- loop for each employees which are in table Employees and aren`t in table EmployeeRoles
		WHILE (1 = 1)
		BEGIN
			SET @EmployeeID = (SELECT TOP(1) [ID] FROM 
			(
				SELECT [ID] FROM [Employees]
				EXCEPT
	            SELECT DISTINCT [EmployeeID] FROM [EmployeeRoles]
			)[a] 
			ORDER BY NEWID());

			--	exit from the loop if in EmployeeRoles are all employees from Employees
			IF (@EmployeeID IS NULL)
			BEGIN
				BREAK;
			END
	        
			SET @BusinessUnitID = (SELECT TOP(1) [ID] FROM [BusinessUnits] ORDER BY NEWID());
			
			--	set any role from roles if store and document control if stock
			IF EXISTS (SELECT * FROM [BusinessUnits] WHERE [BusinessUnitTypeID] = 2 AND [ID] = @BusinessUnitID)
			BEGIN
				SET @RoleID = (SELECT TOP(1) [ID] FROM [Roles] ORDER BY NEWID());
			END
			ELSE
			BEGIN
				SET @RoleID = 5;
			END
					
			SET @StartDate =
					(
						SELECT MAX([MinDate])
						FROM
						(
							SELECT [OpeningDate] AS [MinDate]
								FROM [BusinessUnits]
								WHERE [ID] = @BusinessUnitID
							UNION
							SELECT MAX([EndDate]) AS [MinDate]
								FROM [EmployeeRoles]
								WHERE [EmployeeID] = @EmployeeID AND [EndDate] IS NOT NULL
						)[a]
					);

			SET @EndDate =
					(
						SELECT ISNULL([StartDate], CURRENT_TIMESTAMP)
							FROM [EmployeeRoles]
							WHERE [EmployeeID] = @EmployeeID AND [EndDate] IS NULL
					);
					
			SET @EndDate = [dbo].[GetDateInRange](@StartDate, @EndDate);
			
			--	any Employee can`t work less than 1 week
			IF (DATEDIFF(DAY, @StartDate, @EndDate) < 7)
			BEGIN
				CONTINUE;
			END

			SET @Description = (SELECT TOP(1) [descr] FROM @Descriptions ORDER BY NEWID());

			INSERT INTO [EmployeeRoles]
						   (
							   [EmployeeID]
							   ,[RoleID]
							   ,[BusinessUnitID]
							   ,[StartDate]
							   ,[EndDate]
							   ,[Description]
						   )
					 VALUES
						   (
							   @EmployeeID
							   , @RoleID
							   , @BusinessUnitID
							   , @StartDate
							   , @EndDate
							   , @Description
						   );
		END
	
		SET @RowsCount = (SELECT COUNT(*) FROM [EmployeeRoles]) - @RowsCount;
		EXEC [STP_EditLogActivity] @LogID, @RowsCount, 0, 0, NULL, 'ENDED', NULL;
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE [dbo].[STP_GenerateConsigments]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
		--	for table LogActivities
		DECLARE @LogID INT;	--	ID of inserted record into table LogActivities
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;
	
		DECLARE @StartProc DATETIME = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		DECLARE @RowsCount INT = (SELECT COUNT(*) FROM [Consigments]);

		CREATE TABLE [Temp_Vendors] ([ID] INT IDENTITY, [VendorID] SMALLINT);

		--	fields which are in table Consigments
		DECLARE @EmployeeID INT;
		DECLARE @BusinessUnitID SMALLINT;
		DECLARE @VendorID SMALLINT;
		DECLARE @OrderDate DATE;
		DECLARE @RecievedDate DATE;

		--	List of BusinessUnits
		--	we have to have consigments for each business unit which are in the Stocks
		DECLARE @BusinessUnits TABLE ([ID] INT IDENTITY, [BusinessUnitID] SMALLINT);
		INSERT INTO @BusinessUnits ([BusinessUnitID]) (SELECT [ID] FROM [BusinessUnits] where [BusinessUnitTypeID] = 1);
		DECLARE @iBusinessUnits INT = (SELECT MAX([ID]) FROM @BusinessUnits);

		--	make consigments can only role document control
		DECLARE @RoleID SMALLINT = 5;
		
		DECLARE @MinDate DATE;
		DECLARE @MaxDate DATE;

		WHILE (@iBusinessUnits > 0)
		BEGIN
			SET @BusinessUnitID = (SELECT [BusinessUnitID] FROM @BusinessUnits WHERE [ID] = @iBusinessUnits);
			
			--	date of consigment MUST be >= than first day of document control in current stock
			--	document control manager which ever worked in current business unit
			SET @MinDate =
			(
				SELECT MAX([StartDate]) FROM
				(
					SELECT [OpeningDate] AS [StartDate] FROM [BusinessUnits] WHERE [ID] = @BusinessUnitID
					UNION
					SELECT MIN([StartDate]) AS [StartDate]
						FROM
						(
							SELECT [StartDate]
								FROM [EmployeeRoles]
								WHERE
									[BusinessUnitID] = @BusinessUnitID AND
									[RoleID] = @RoleID
						)a
				)b
			);
			
			SET @EmployeeID = 
			(
				SELECT TOP(1) [EmployeeID]
					FROM [EmployeeRoles]
					WHERE
						[BusinessUnitID] = @BusinessUnitID AND
						[RoleID] = @RoleID AND
						(@MinDate BETWEEN [StartDate] AND ISNULL([EndDate], TRY_CAST(CURRENT_TIMESTAMP AS DATE)))
					ORDER BY NEWID()
			);

			IF @EmployeeID IS NULL
			BEGIN
				SET @iBusinessUnits -= 1;
				CONTINUE;
			END
			--	date of consigment MUST be <= than last day of document control in current stock or current date
			SET @MaxDate = 
			(
				SELECT ISNULL(MAX([EndDate]), TRY_CAST(CURRENT_TIMESTAMP AS DATE))
					FROM [EmployeeRoles]
					WHERE
						[EmployeeID] = @EmployeeID
			);

			--	list of vendors wich provide products for current business unit
			DECLARE @iVendors INT = CAST(RAND()*400 AS INT)%400+1;

			TRUNCATE TABLE [Temp_Vendors];
			
			WITH [A]
			AS
			(
				SELECT TOP(@iVendors) [ID]
				FROM [Vendors]
				ORDER BY NEWID()
			)
			INSERT INTO [Temp_Vendors] (VendorID) (SELECT [ID] FROM [A]);

			SET @iVendors = (SELECT MAX([ID]) FROM [Temp_Vendors]);

			--	loop for each vendor who provide products for current stock
			WHILE (@iVendors > 0)
			BEGIN
				SET @VendorID = (SELECT [VendorID] FROM [Temp_Vendors] WHERE [ID] = @iVendors);

				IF @VendorID IS NULL
				BEGIN
					BREAK;
				END
	            
	            --	first consigment may be for first week after opening of stock or start working any document control manager
				SET @OrderDate = [dbo].[GetDateInRange](@MinDate, DATEADD(DAY, 7, @MinDate));

				IF (@OrderDate > @MaxDate)
				BEGIN
					SET @OrderDate = [dbo].[GetDateInRange](@MinDate, @MaxDate);
				END	
				
				--recieved date should be not later than 1 week after order date
				SET @RecievedDate = [dbo].[GetDateInRange](@OrderDate, DATEADD(DAY, 7, @OrderDate));
				
				IF (@RecievedDate > @MaxDate)
				BEGIN
					SET @RecievedDate = [dbo].[GetDateInRange](@MinDate, @MaxDate);
				END
	            
				INSERT INTO [Consigments]
					([EmployeeID]
					,[BusinessUnitID]
					,[VendorID]
					,[OrderDate]
					,[RecievedDate])
				VALUES
					(@EmployeeID
					,@BusinessUnitID
					,@VendorID
					,@OrderDate
					,@RecievedDate);

				SET @iVendors -= 1;
			END

			TRUNCATE TABLE [Temp_Vendors];

			SET @iBusinessUnits -= 1;
		END

		--	 for table LogActivities
		SET @RowsCount = (SELECT COUNT(*) FROM Consigments) - @RowsCount;
		EXEC [STP_EditLogActivity] @LogID, @RowsCount, 0, 0, NULL, 'ENDED', NULL;
		DROP TABLE [dbo].[Temp_Vendors];
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE [dbo].[STP_GenerateConsigmentDetails]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
		--	for table LogActivities
		DECLARE @LogID INT;	--	ID of inserted record into table LogActivities
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;
		DECLARE @StartProc DATETIME = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		DECLARE @RowsCount INT = (SELECT COUNT(*) FROM [ConsigmentDetails]);

		DECLARE @ConsigmentID INT;

		-- list of products which are in current business unit from current vendor
		CREATE TABLE [Temp_Products] (
				[ID] INT IDENTITY
				, [ProductID] INT
				, [Quantity] SMALLINT
				, [Price] NUMERIC(10, 2)
			);

		DECLARE @Consigments TABLE ([ID] INT IDENTITY, [ConsigmentID] INT);
		INSERT INTO @Consigments ([ConsigmentID]) (SELECT [ID] FROM [Consigments]);
		DECLARE @iConsigment INT = (SELECT MAX([ID]) FROM @Consigments);

		DECLARE @VendorID SMALLINT;
		-- how many different products each vendor can provide for current stock
		DECLARE @DifferentProducts INT;

		-- loop for each consigment
		WHILE(@iConsigment > 0)
		BEGIN
			SET @ConsigmentID = (SELECT [ConsigmentID] FROM @Consigments WHERE [ID] = @iConsigment);
			SET @VendorID = (SELECT [VendorID] FROM [Consigments] WHERE [ID] = @ConsigmentID);
			
			TRUNCATE TABLE Temp_Products;

			-- [5; 10]
			SET @DifferentProducts = CAST(RAND()*6 AS INT)%(6) + 5;

			WITH [pids]
			AS
			(
				SELECT TOP(@DifferentProducts) [ID], [RetailPrice]*(dbo.FN_RANDOM()*30 + 60)/100
				FROM [Products]
				WHERE [VendorID] = @VendorID
				ORDER BY NEWID()
			)
			INSERT INTO [Temp_Products] ([ProductID], [Quantity], [Price])
			(
				SELECT [ID], (CAST(dbo.FN_RANDOM()*50 AS SMALLINT)%(50) + 5)*20, [RetailPrice]
				FROM [pids] [ps]
			);

			SET @DifferentProducts = (SELECT MAX([ID]) FROM [Temp_Products]);

			--	loop for each product for current vedor for current consigment
			WHILE(@DifferentProducts > 0)
			BEGIN
				INSERT INTO [ConsigmentDetails]
				(
					[ConsigmentID]
					, [ProductID]
					, [Quantity]
					, [PurchasePrice]
				) 
				(
					SELECT
						@ConsigmentID
						, [ProductID]
						, [Quantity]
						, [Price] 
					FROM [Temp_Products]
					WHERE 
						[ID] = @DifferentProducts
				);
				SET @DifferentProducts -= 1;
			END
			TRUNCATE TABLE [Temp_Products];
			SET @iConsigment -= 1;
		END

		SET @RowsCount = (SELECT COUNT(*) FROM [ConsigmentDetails]) - @RowsCount;
		EXEC [STP_EditLogActivity] @LogID, @RowsCount, 0, 0, NULL, 'ENDED', NULL;
		DROP TABLE [Temp_Products];
	COMMIT TRANSACTION;
END
GO

CREATE PROC [dbo].[STP_GenerateStocks]
AS
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
		--	for table LogActivities
		DECLARE @LogID INT;	--	ID of inserted record into table LogActivities
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;

		DECLARE @StartProc DATETIME = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		DECLARE @RowsCount INT = 0;
		TRUNCATE TABLE Stocks;

		INSERT INTO [Stocks]
		(
			[BusinessUnitID]
			, [ProductID]
			, [Quantity]
		)
		(
			SELECT
				[c].[BusinessUnitID]
				, [cd].[ProductID]
				, SUM([cd].[Quantity])
			FROM [Consigments] [c]
			JOIN [ConsigmentDetails] [cd]
				ON [c].[ID] = [cd].[ConsigmentID]
			GROUP BY [c].[BusinessUnitID], [cd].[ProductID]
		);

		SET @RowsCount = @@ROWCOUNT;
		
		DECLARE @EndProc DATETIME = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		EXEC [STP_EditLogActivity] @LogID, @EndProc, 0, 0, NULL, 'ENDED', NULL;
	COMMIT TRANSACTION;
END
GO


------------------------------------------------------------------------------------------------------------------------------------


CREATE PROCEDURE [dbo].[STP_GenerateShipments]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION
		--	for table LogActivities
		DECLARE @LogID INT; 	--	ID of inserted record into table LogActivities
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;
	
		DECLARE @RowsCount INT = (SELECT COUNT(*) FROM [Shipments]);

		--	fields which are in table Shipments
		DECLARE @SourceID SMALLINT;
		DECLARE @DestinationID SMALLINT;
		DECLARE @EmployeeID SMALLINT;
		DECLARE @OrderDate DATETIME;
		DECLARE @RecieveDate DATETIME;

		-- In table BusinessUnitTypes: 1 - Stock, 2 - Store
		-- List of Stocks (Source)
		DECLARE @Stocks TABLE ([ID] INT IDENTITY, [StockID] SMALLINT);
		INSERT INTO @Stocks ([StockID]) (SELECT DISTINCT [BusinessUnitID] FROM [Consigments]);
		DECLARE @iStocks INT = (SELECT MAX([ID]) FROM @Stocks); -- iterator for Stocks

		--	List of Stores (Destination)
		DECLARE @Stores TABLE ([ID] INT IDENTITY, [StoreID] SMALLINT);
		INSERT INTO @Stores ([StoreID]) (SELECT [ID] FROM [BusinessUnits] WHERE [BusinessUnitTypeID] = 2);
		DECLARE @iStores INT;  -- iterator for Stores

		-- variables that define range for OrderDate and RecievedDate
		DECLARE  @MinDate DATETIME
				,@MaxDate DATETIME;

		-------------- we deliver some products from each Stocks to each Stores --------------
		-- loop for Stocks
		WHILE (@iStocks > 0)
		BEGIN
			-- 
			SET @SourceID = (SELECT [StockID] FROM @Stocks WHERE [ID] = @iStocks);
		
			SET @iStores = (SELECT MAX([ID]) FROM @Stores);
			-- loop for Stores
			WHILE (@iStores > 0)
			BEGIN		
				SET @DestinationID = (SELECT [StoreID] FROM @Stores WHERE [ID] = @iStores);
				-- Only managers which works in store can make shipments
				SET @EmployeeID = 
					(
						SELECT TOP(1) [EmployeeID]
							FROM [EmployeeRoles] 
							WHERE
								[BusinessUnitID] = @DestinationID
								AND [RoleID] IN (3, 5, 7)  -- 3 - Sales Manager, 5 - Document Control, 7 - Marketing Manager
							ORDER BY NEWID()
					);

				--	min date from consigment to this stock
				SET @MinDate =
					(
						SELECT TRY_CAST(MAX([MinDate]) AS DATETIME)
						FROM
						(
							SELECT MAX([RecievedDate]) AS [MinDate] FROM [Consigments] WHERE [BusinessUnitID] = @SourceID
							UNION
							SELECT MAX([StartDate]) AS [MinDate] FROM [EmployeeRoles]	WHERE [EmployeeID] = @EmployeeID
						)md			
					);
				-- MaxDate as realise date employee from this Store	
				SET @MaxDate = 
					(
						SELECT MIN([EndDate])
							FROM [EmployeeRoles]
							WHERE
								[EmployeeID] = @DestinationID
								AND [RoleID] = 5
								AND @MinDate BETWEEN [StartDate] AND ISNULL([EndDate], CURRENT_TIMESTAMP)
					);

				-- random date using stored function
				SET @OrderDate = dbo.GetDateTimeInRange(@MinDate, @MaxDate);
				SET @RecieveDate = [dbo].[GetDateTimeInRange](@OrderDate, @MaxDate);

				-- duration shipment less than 3 days
				IF (DATEDIFF(DAY, @OrderDate, @RecieveDate) > 3)
					SET @RecieveDate = DATEADD(DAY, 3, @OrderDate)
			
				INSERT INTO [dbo].[Shipments]
				   ([SourceID]
				   ,[DestinationID]
				   ,[EmployeeID]
				   ,[OrderDate]
				   ,[RecievedDate])
				VALUES
				   (@SourceID
				   ,@DestinationID
				   ,@EmployeeID
				   ,@OrderDate
				   ,@RecieveDate);
				SET @iStores -= 1;
			END
			SET @iStocks -= 1;
		END
		--	 for table LogActivities
		SET @RowsCount = (SELECT COUNT(*) FROM Shipments) - @RowsCount;
		EXEC [STP_EditLogActivity] @LogID, @RowsCount, 0, 0, NULL, 'ENDED', NULL;
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE [dbo].[STP_GenerateShipmentDetails]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
		--	for table LogActivities
		DECLARE @LogID INT;
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;
	
		DECLARE @StartProc DATETIME = TRY_CONVERT(DATETIME, CURRENT_TIMESTAMP);
		DECLARE @InsertedRows INT = 0,
				@UpdatedRows INT = 0;

		-- list of products which are in current business unit from current vendor
		CREATE TABLE [Temp_Products]
		(
			 [ID] INT IDENTITY
			,[ProductID] INT
			,[Quantity] SMALLINT
		);
		-- we have add details to each shipment
		DECLARE @Shipments TABLE ([ID] INT IDENTITY, [ShipmentID] INT);
		INSERT INTO @Shipments ([ShipmentID]) (SELECT [ID] FROM [Shipments]);
		DECLARE @iShipment INT = (SELECT MAX([ID]) FROM @Shipments); -- iterator fro Shipments
		DECLARE @ShipmentID INT;

		-- variables in table ShipmentDetails
		DECLARE  @ProductID INT
				,@Quantity SMALLINT;
		-- additional variables which determine some details of shipments
		DECLARE  @SourceID SMALLINT
				,@DestinationID SMALLINT
				,@OrderDate DATE;
		-- loop for each shipment
		WHILE(@iShipment > 0)																																																																									WHILE(@iShipment > 0)
		BEGIN
			SET @ShipmentID = (SELECT [ShipmentID] FROM @Shipments WHERE [ID] = @iShipment);
			-- initialisation variables
			SELECT
				 @SourceID = [SourceID]
				,@DestinationID = [DestinationID]
				,@OrderDate = [OrderDate]
			FROM [Shipments]
			WHERE [ID] = @ShipmentID;
		
			TRUNCATE TABLE [Temp_Products];
			-- Quantity of different products in one shipment can be from 1 to 10
			DECLARE @DifferentProducts SMALLINT = CAST(RAND()*10 AS SMALLINT)%(11) + 1;

			WITH [pids]
			AS
			(
				SELECT TOP(@DifferentProducts) [cd].[ProductID], [s].[Quantity]
				FROM [ConsigmentDetails] [cd]
				JOIN [Consigments] [c] ON [c].[ID] = [cd].[ConsigmentID]
				JOIN [Stocks] [s] ON [s].[BusinessUnitID] = [c].[BusinessUnitID]
				WHERE
					[c].[BusinessUnitID] = @SourceID
					AND [cd].[ProductID] = [s].[ProductID]
					AND [s].[Quantity] > 0
				ORDER BY NEWID()
			)
			INSERT INTO [Temp_Products] ([ProductID], [Quantity])
			(
				SELECT [ProductID], CAST(dbo.FN_RANDOM()*[Quantity]/10 AS SMALLINT) + 1 -- we can take less than 10% of Stock
				FROM [pids]
			);

			-- loop for all chosen products
			SET @DifferentProducts = (SELECT MAX([ID]) FROM [Temp_Products]);
			WHILE(@DifferentProducts > 0)
			BEGIN
				-- choose current product and add one record to table ShipmentDetails
				SELECT
					 @ProductID = [ProductID]
					,@Quantity = [Quantity]
				FROM [Temp_Products]
				WHERE 
					[ID] = @DifferentProducts;
			
				INSERT INTO [ShipmentDetails]
				(
					[ShipmentID]
					, [ProductID]
					, [Quantity]
				)
				VALUES
				(
					 @ShipmentID
					, @ProductID
					, @Quantity
				);
				SET @InsertedRows += 1; -- for LogActivities
			
				-- updating quantity in table Stocks(take away from current Stock)
				UPDATE [Stocks] SET [Quantity] -= @Quantity WHERE [BusinessUnitID] = @SourceID AND [ProductID] = @ProductID;
				SET @UpdatedRows += 1;  -- for LogActivities
			
				-- updating quantity in table Stocks(add to current Store)
				IF NOT EXISTS(SELECT * FROM [Stocks] WHERE [BusinessUnitID] = @DestinationID AND [ProductID] = @ProductID)
				BEGIN
					INSERT INTO [Stocks] ([BusinessUnitID], [ProductID], [Quantity]) VALUES (@DestinationID, @ProductID, @Quantity);
					SET @InsertedRows += 1;
				END
				ELSE
				BEGIN
					UPDATE [Stocks] SET [Quantity] += @Quantity WHERE [BusinessUnitID] = @DestinationID AND [ProductID] = @ProductID;
					SET @UpdatedRows += 1;  -- for LogActivities
				END

				SET @DifferentProducts -= 1;
			END
			SET @iShipment -= 1;
		END
		DROP TABLE [Temp_Products];
		-- for LogActivities
		EXEC [STP_EditLogActivity] @LogID, @InsertedRows, @UpdatedRows, 0, NULL, 'ENDED', NULL;
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE [dbo].[STP_GenerateOrders]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION
		--	for table LogActivities
		DECLARE @LogID INT;
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;

		DECLARE @RowsCount INT = (SELECT TRY_CAST(COUNT(*) AS BIGINT) FROM [Orders]);

		--	variables which are in the table Orders
		DECLARE  @CustomerID INT
				,@EmployeeID INT
				,@BusinessUnitID SMALLINT
				,@OperationTime DATETIME
				,@PayTypeID TINYINT
				,@DiscountID TINYINT;

		--	Additional variables that determine range of OrderTime
		DECLARE @MinDate DATETIME,
				@MaxDate DATETIME;
		-- only Salesmen and their assistants can make orders
		DECLARE @Roles TABLE([ID] INT IDENTITY, [RoleID] SMALLINT);
		INSERT INTO @Roles ([RoleID]) (SELECT [ID] FROM [Roles] WHERE LOWER([Name]) LIKE 'sale%');

		DECLARE @EmployeeRoleID INT;

		--	list of stores
		DECLARE @BusinessUnits TABLE ([ID] INT IDENTITY, [BusinessUnitID] SMALLINT, [OpeningDate] DATE);
		INSERT INTO @BusinessUnits ([BusinessUnitID], [OpeningDate])
		(
			SELECT [bu].[ID], [bu].[OpeningDate]
				FROM [BusinessUnits] [bu]
				JOIN [BusinessUnitTypes] [but]
					ON [bu].[BusinessUnitTypeID] = [but].[ID]
				WHERE LOWER([but].[BusinessUnitType]) LIKE 'store'
		);
		-- iterator for stores
		DECLARE @iStore INT = (SELECT MAX([ID]) FROM @BusinessUnits);
		-- variable that show how long store opened
		DECLARE @amountDays INT;
		-- variable that show count of orders in store
		DECLARE @amountOrders INT;

		--	orders for each store
		WHILE (@iStore > 0)
		BEGIN
			SELECT @BusinessUnitID = [BusinessUnitID], @MinDate = [OpeningDate] FROM @BusinessUnits WHERE [ID] = @iStore;
			
			-- Amount of orders in each store can be from 0 to 5 per day
			SET @amountDays = DATEDIFF(DAY, @MinDate, CURRENT_TIMESTAMP);
			SET @amountOrders = CAST(RAND()*@amountDays*5 AS INT);

			WHILE (@amountOrders > 0)
			BEGIN				
				SELECT TOP(1) @EmployeeID = [EmployeeID], @MinDate = [StartDate], @MaxDate = [EndDate]
					FROM [EmployeeRoles]
					WHERE
						[BusinessUnitID] = @BusinessUnitID
						AND [RoleID] IN (SELECT [RoleID] FROM @Roles)
					ORDER BY NEWID();

					
				SET @OperationTime = [dbo].[GetDateTimeInRange](@MinDate, @MaxDate);

				-- Customer must be registered before order
				SET @CustomerID =
					(
						SELECT TOP(1) [ID]
						FROM [Customers]
						WHERE [RegistrationDate] < @OperationTime
						ORDER BY NEWID()
					 );
				-- 31.5% orders by Guests(unregistered customers), 3.5% by Employees, 65% by registered customers
				IF ([dbo].[FN_RANDOM]() <= 0.35)
				BEGIN
					IF([dbo].[FN_RANDOM]() <= 0.9)
					BEGIN
						SET @CustomerID = 1; -- Guest
					END
					ELSE
					BEGIN
						SET @CustomerID = 2; -- Employee
					END
				END
				
				SET @PayTypeID = (SELECT TOP(1) [ID] FROM [PayType] ORDER BY NEWID());
				SET @DiscountID = (SELECT [DiscountID] FROM [Customers] WHERE [ID] = @CustomerID);

				INSERT INTO [Orders]
					(
						[CustomerID]
						, [EmployeeID]
						, [OperationTime]
						, [PayTypeID]
						, [DiscountID]
					)
					VALUES
					(
						@CustomerID
						, @EmployeeID
						, @OperationTime
						, @PayTypeID
						, @DiscountID
					);
				SET @amountOrders -=1
			END

			SET @iStore -= 1;
		END		
		--	 for table LogActivities
		SET @RowsCount = (SELECT COUNT(*) FROM [Orders]) - @RowsCount;
		EXEC [STP_EditLogActivity] @LogID, @RowsCount, 0, 0, NULL, 'ENDED', NULL;
	COMMIT TRANSACTION
END
GO

CREATE PROCEDURE [dbo].[STP_GenerateOrderDetails]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION
		--	 for table LogActivities
		DECLARE @LogID INT;
		EXEC @LogID = [STP_AddLogActivity] @@PROCID, 0, 0, 0, NULL, NULL, 'STARTED', NULL;
		DECLARE @InsertedRows INT, @UpdatedRows INT;

		-- variables in table OrderDetails
		DECLARE @OrderID INT;
		DECLARE @ProductID INT;
		DECLARE @Quantity SMALLINT;
		DECLARE @UnitPrice NUMERIC(10,2);

		-- additional variables
		DECLARE @BUID SMALLINT;
		DECLARE @AvailableQuantity SMALLINT;
		DECLARE @iProducts TINYINT;
		DECLARE @start INT = (SELECT MIN([ID]) - 1 FROM [Orders]); -- from order
		DECLARE @finish INT = (SELECT MAX([ID]) + 1 FROM [Orders]) -- to order

		-- temp table with Orders
		DECLARE @Orders TABLE ([ID] INT IDENTITY, [OrderID] INT, [BusinessUnitID] SMALLINT, [EmployeeID] INT, [OperationTime] DATETIME)
		INSERT INTO @Orders
		(
			[OrderID],
			[BusinessUnitID],
			[EmployeeID],
			[OperationTime]
		)
		SELECT   [ID]
				,[BusinessUnitID]
				,[EmployeeID]
				,[OperationTime]
		FROM [Orders]
		WHERE [ID] < @finish 
			AND [ID] > @start
		
		-- iterator
		DECLARE @iOrders INT = (SELECT MAX([ID]) FROM @Orders);

		-- table which contain some products which are available in store
		CREATE TABLE [AvailableProductsInCurrentStock]
			([ID] INT IDENTITY
			,[ProductID] INT
			,[Quantity] SMALLINT)
		
		-- loop for each Order
		WHILE(@iOrders > 0)
		BEGIN
			SELECT  @OrderID = [OrderID]
					,@BUID = [BusinessUnitID]
			FROM @Orders
			WHERE [ID] = @iOrders;

			-- In one order can be from 1 to 3 different products
			TRUNCATE TABLE [AvailableProductsInCurrentStock];
			INSERT INTO [AvailableProductsInCurrentStock]
				([ProductID]
				,[Quantity])
			SELECT TOP(CAST(RAND()*3 AS SMALLINT) + 1)
				[ProductID], [Quantity]
			FROM [Stocks]
			WHERE [BusinessUnitID] = @BUID
				AND [Quantity] > 0
			ORDER BY NEWID();

			SET @iProducts = (SELECT MAX([ID]) FROM [AvailableProductsInCurrentStock]);
			-- loop for each Product
			WHILE (@iProducts > 0)
			BEGIN
				SELECT @ProductID = [ProductID] 
				FROM [AvailableProductsInCurrentStock] 
				WHERE [ID] = @iProducts;
				-- if we don't have any products in the Store
				IF (@ProductID IS NULL)
				BEGIN
					SET @iProducts -= 1;
					CONTINUE;
				END

				SET @UnitPrice = 
					(SELECT [RetailPrice]
					FROM [Products]
					WHERE [ID] = @ProductID)

				-- Quantity of one product in order from 1 to 3
				SET @Quantity = CAST(RAND()*3 AS SMALLINT) + 1;
				-- if we don't have so much, we offer availavle quantity
				IF (@Quantity > 
						(SELECT [Quantity]
						FROM [AvailableProductsInCurrentStock]
						WHERE [ID] = @iProducts))
				BEGIN
					SET @Quantity =
						(SELECT [Quantity]
						FROM [AvailableProductsInCurrentStock]
						WHERE [ID] = @iProducts);
				END

				--Updating table Stocks
				UPDATE [Stocks]
					SET [Quantity] -= @Quantity
					WHERE [BusinessUnitID] = @BUID
						AND [ProductID] = @ProductID;

				SET @UpdatedRows += 1;  -- for LogActivities
			
				INSERT INTO [OrderDetails]
				(
					[OrderID],
					[ProductID],
					[Quantity],
					[UnitPrice]
				)
				VALUES
				(
					@OrderID,    
					@ProductID,
					@Quantity,
					@UnitPrice
				);
				SET @iProducts -= 1;
			END
			SET @iOrders -= 1;
		END
		DROP TABLE [AvailableProductsInCurrentStock];

		--	 for table LogActivities
		SET @InsertedRows = (SELECT COUNT(*) FROM [OrderDetails]) - @InsertedRows;
		EXEC [STP_EditLogActivity] @LogID, @InsertedRows, @UpdatedRows, 0,  NULL, 'ENDED', NULL;
	COMMIT TRANSACTION;
END
GO


CREATE PROCEDURE [dbo].[STP_GenerateLosses]
AS
BEGIN
	SET NOCOUNT ON;
	-- Variables in Losses
	DECLARE
		 @ProductID INT
		,@Quantity SMALLINT
		,@Price NUMERIC(10, 2)
		,@LossTypeID TINYINT
		,@LossDate DATETIME
		,@BusinessUnitID SMALLINT
		,@StockID SMALLINT;

	-- iterator which determine amount of losses
	DECLARE @i INT = 105;
	WHILE(@i > 0)
	BEGIN
		SET @LossTypeID = 
			(SELECT TOP(1) [ID]
			 FROM [LossTypes]
			 ORDER BY NEWID()
			);
		-- when goods broken in Stock, we take away those products from table Stock
		IF (@LossTypeID = 2)
		BEGIN
			-- One product from Consigments, Quantity between 1 and 3, Price as PurchasePrice
			SELECT TOP(1) 
					@ProductID = s.[ProductID]
					,@Quantity = TRY_CAST(RAND()*3 AS SMALLINT)%s.[Quantity] + 1
					,@Price = cd.[PurchasePrice]
					,@LossDate = c.[RecievedDate]
					,@BusinessUnitID = c.[BusinessUnitID]
				FROM [Consigments] c
					JOIN [Stocks] s
						ON s.[BusinessUnitID] = c.[BusinessUnitID]
					JOIN [ConsigmentDetails] cd
						ON cd.[ConsigmentID] = c.[ID]
				WHERE cd.[ProductID] = s.[ProductID]
					AND s.[Quantity] > 0
					AND  c.[RecievedDate] IS NOT NULL
				ORDER BY NEWID();		
		END
		ELSE
		BEGIN
			-- One product from Shipments
			SELECT TOP(1)
				 @ProductID = s.[ProductID]
				,@Quantity =  TRY_CAST(RAND()*3 AS SMALLINT)%s.[Quantity] + 1
				,@LossDate = sh.[RecievedDate]
				,@BusinessUnitID = sh.[DestinationID]
				,@StockID = sh.[SourceID]
			FROM [Shipments] sh
				JOIN [Stocks] s
				ON s.[BusinessUnitID] = sh.[DestinationID]
				JOIN [ShipmentDetails] shd
				ON shd.[ShipmentID] = sh.[ID]
			WHERE shd.[ProductID] = s.[ProductID]
				AND s.[Quantity] > 0
				AND  sh.[RecievedDate] IS NOT NULL
			ORDER BY NEWID();
			
			-- take Price as PurchasePrice from table ConsigmentDetails
			SELECT TOP(1)
				@Price = cd.[PurchasePrice]
			FROM [Consigments] c
				JOIN [ConsigmentDetails] cd
				ON cd.[ConsigmentID] = c.[ID]
			WHERE cd.[ProductID] = @ProductID
				AND c.[BusinessUnitID] = @StockID
			ORDER BY NEWID();
		END
		INSERT INTO [Losses]
			([ProductID]
			,[Quantity]
			,[Price]
			,[LossTypeID]
			,[LossDate]
			,[BusinessUnitID])	
		VALUES
			(
				@ProductID
			,@Quantity
			,@Price 
			,@LossTypeID 
			,@LossDate 
			,@BusinessUnitID
			);

		UPDATE [Stocks]
		   SET [Quantity] -= @Quantity
		 WHERE [BusinessUnitID] = @BusinessUnitID
			AND [ProductID] = @ProductID;

		SET @i -= 1;
	END
END


CREATE PROCEDURE [STP_UpdateDiscountID]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION
		--Orders by OperationTime
		DECLARE @Orders TABLE ([ID] INT IDENTITY, [OrderID] INT)
		INSERT INTO @Orders([OrderID])
		SELECT [ID]
		  FROM [Orders]
		  WHERE [CustomerID] NOT IN (1, 2)
		  ORDER BY [OperationTime] DESC

		-- Variables in table Orders and Customers
		DECLARE @OrderID INT;
		DECLARE @CustomerID INT;
		DECLARE @DiscountID INT;
		DECLARE @TotalSum NUMERIC(10 ,2);
		-- iterator
		DECLARE @iOrders INT = (SELECT MAX([ID]) FROM @Orders);

		-- loop for each Order
		WHILE(@iOrders > 0)
		BEGIN
			SELECT @OrderID = [OrderID] FROM @Orders WHERE [ID] = @iOrders;
			SELECT @CustomerID = [CustomerID] FROM [Orders] WHERE [ID] = @OrderID);
			SELECT @DiscountID = [DiscountID] FROM [Customers] WHERE [ID] = @CustomerID);

			-- set DiscountID for Customer as DiscountID during last Customer's order
			UPDATE [Orders]
				SET [DiscountID] = @DiscountID
				WHERE [ID] = @OrderID;

			-- Summary price of that order
			SET @TotalSum = (SELECT SUM([Quantity]*[UnitPrice]) FROM [OrderDetails] WHERE [OrderID] = @OrderID);
			-- In table OrderDetails we have prices without discount
			SET @TotalSum *= (SELECT TRY_CAST(100-[Percent] AS NUMERIC(10, 2)) FROM [Discounts] WHERE [ID] = @DiscountID)/100;

			-- add summary price of that order with discount to Customers
			UPDATE [Customers]
				SET [TotalSum] += @TotalSum
				WHERE [ID] = @CustomerID;
			
			-- Updating DiscountID in table Customers
			SELECT @TotalSum = [TotalSum] FROM [Customers] WHERE [ID] = @CustomerID;
			SET @DiscountID = 
				CASE  
					WHEN @TotalSum >= 50000 THEN 7
					WHEN @TotalSum >= 25000 THEN 6
					WHEN @TotalSum >= 15000 THEN 5
					WHEN @TotalSum >= 5000 THEN 4
					ELSE 3
				END;

			UPDATE [Customers]
				SET [DiscountID] = @DiscountID
				WHERE [ID] = @CustomerID;

			SET @iOrders -= 1;
		END
	COMMIT TRANSACTION;
END
GO
