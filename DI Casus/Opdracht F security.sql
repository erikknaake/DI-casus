USE master
GO

/*******************************************************************************************
	F.	Employees can register themselves for courses on offer using an app provided by the Human Resources department.
	The only data the employee have full access to are the data in the REG table.
	Of course read access to the EMP and OFFR  tables are also needed
	(foreign key checks require the user to have ac-cess to the referenced data). 
*******************************************************************************************/

DROP APPLICATION ROLE humanResourcesApp

CREATE APPLICATION ROLE humanResourcesApp
    WITH PASSWORD = 'password'
GO

USE COURSE
go

GRANT SELECT ON dbo.emp TO humanResourcesApp
GRANT SELECT ON dbo.offr TO humanResourcesApp
GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.reg TO humanResourcesApp
GO

-- Testjes of het werkt

-- Select op emp
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet output geven
SELECT TOP 20 * FROM emp

EXEC sp_unsetapprole @cookie
GO

-- Select op offr
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet output geven
SELECT TOP 20 * FROM offr

EXEC sp_unsetapprole @cookie
GO

-- Select op reg
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet output geven
SELECT TOP 20 * FROM reg

EXEC sp_unsetapprole @cookie
GO

-- Insert op reg
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet verandering geven
BEGIN TRAN
	INSERT INTO reg VALUES (1016, 'AM4DP', '1997-09-06', 1)
	SELECT * FROM reg WHERE stud = 1016 AND starts = '1997-09-06'
ROLLBACK TRAN

EXEC sp_unsetapprole @cookie
GO

-- Update op reg
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet verandering geven
BEGIN TRAN
	INSERT INTO reg VALUES (1016, 'AM4DP', '1997-09-06', 1)
	UPDATE reg
		SET course = 'J2EE', starts = '1997-08-14'
		WHERE stud = 1016 
		AND starts = '1997-09-06'
	SELECT * FROM reg WHERE stud = 1016 AND starts = '1997-08-14' -- moet 1016, J2EE, 1997-08-14, 1 geven
ROLLBACK TRAN

EXEC sp_unsetapprole @cookie
GO

-- Delete op reg
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet verandering geven
BEGIN TRAN
	DELETE FROM reg
	SELECT * FROM reg -- Moet geen resultaat geven
ROLLBACK TRAN

EXEC sp_unsetapprole @cookie
GO

-- Select op tabel waar dat niet mag
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet error geven
SELECT TOP 20 * FROM memp

EXEC sp_unsetapprole @cookie
GO

-- Insert op tabel waar dat niet mag
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
--Moet error geven
BEGIN TRAN
	INSERT INTO dept VALUES (15, 'Test', 'Zutphen', 2)
ROLLBACK TRAN

EXEC sp_unsetapprole @cookie
GO


-- Insert op offr
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
BEGIN TRAN
	INSERT INTO offr VALUES ('DI', GETDATE(), 'CONF', 6, 1016, 'Zutphen') -- moet error geven
ROLLBACK TRAN

EXEC sp_unsetapprole @cookie
GO

-- Insert op emp
DECLARE @cookie varbinary(8000);  
EXEC sp_setapprole 'humanResourcesApp', 'password', @fCreateCookie = true, @cookie = @cookie OUTPUT;  
BEGIN TRAN
	INSERT INTO emp VALUES (544, 'Erik', 'TRAINER', '2000-18-01', GETDATE(), 7, 7000, 'Erik', 1) -- moet error geven
ROLLBACK TRAN

EXEC sp_unsetapprole @cookie
GO

-- Security werkt



/*******************************************************************************************
	For reporting purposes a specific service account needs to be created allowing reporting tools full read access to all data. 
*******************************************************************************************/
CREATE USER reporter WITHOUT LOGIN
GO

GRANT SELECT ON SCHEMA::dbo TO reporter
GO

-- Testjes
EXECUTE AS USER = 'reporter'

SELECT TOP 20 * FROM memp -- mag
SELECT TOP 20 * FROM emp -- mag
SELECT TOP 20 * FROM offr -- mag
SELECT TOP 20 * FROM crs -- mag
SELECT TOP 20 * FROM reg -- mag
BEGIN TRAN
	-- mag allemaal niet
	INSERT INTO emp VALUES (544, 'Erik', 'TRAINER', '2000-18-01', GETDATE(), 7, 7000, 'Erik', 1)
	INSERT INTO offr VALUES ('DI', GETDATE(), 'CONF', 6, 1016, 'Zutphen')
	UPDATE reg
		SET stud = 1001
		WHERE course = 'AM4DPM' AND starts = '2005-04-03' AND stud = 1000
ROLLBACK TRAN
REVERT
--Werkt