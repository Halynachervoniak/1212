/*
truncate table EmployeeRoles
go

TRUNCATE TABLE dbo.LogActivities
go

EXECUTE dbo.STP_GenerateEmployeeRoles;
GO

--*/

/*
ALTER TABLE dbo.ConsigmentDetails DROP FK_ConsigmentDetails_ConsigmentID
GO
TRUNCATE TABLE dbo.Consigments
GO

ALTER TABLE dbo.ConsigmentDetails ADD CONSTRAINT FK_ConsigmentDetails_ConsigmentID FOREIGN KEY(ConsigmentID) REFERENCES dbo.Consigments(ID)
GO

EXECUTE dbo.STP_GenerateConsigments;
GO
--*/


/*
TRUNCATE TABLE dbo.ConsigmentDetails
GO
*/
EXECUTE dbo.STP_GenerateEmployeeRoles;
GO
EXECUTE dbo.STP_GenerateConsigments;
GO
EXECUTE dbo.STP_GenerateConsigmentDetails;
GO
EXEC dbo.STP_GenerateStocks;
GO
EXEC dbo.STP_GenerateShipments;
GO
EXEC dbo.STP_GenerateShipmentDetails;
GO