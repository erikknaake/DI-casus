USE COURSE
GO
CREATE APPLICATION ROLE humanResourcesApp
    WITH PASSWORD = 'password'
GO

GRANT SELECT ON dbo.emp TO humanResourcesApp
GRANT SELECT ON dbo.offr TO humanResourcesApp
GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.reg TO humanResourcesApp
GO

CREATE USER HumanResourcesTestUser
	WITHOUT LOGIN
GO

ALTER ROLE humanResourcesApp
	ADD MEMBER HumanResourcesTestUser
GO