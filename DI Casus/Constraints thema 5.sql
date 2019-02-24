/******************************************************************************************
	Erik Knaake
	13 februari 2019
*******************************************************************************************/
USE COURSE
GO


/*******************************************************************************************
	a) Een manager kan niet meer dan 2 afdelingen managen. 
*******************************************************************************************/
/**
 * @return 1 when the employee is allowed, 0 when he manages to many departements
 */
CREATE PROCEDURE dbo.PROC_max_number_of_departements_to_manage
AS
	IF EXISTS (
		SELECT e.empno
			FROM emp e INNER JOIN dept d ON e.empno = d.mgr
			GROUP BY e.empno
			HAVING COUNT(e.deptno) > 2
		)
		BEGIN
			RAISERROR ('Er is een epmloyee die te veel afdelingen managed', 11, 1)
		END
	ELSE
		BEGIN
			RAISERROR ('Er zijn geen epmloyees die te veel afdelingen managen', 1, 1)
		END
GO
--DROP PROCEDURE dbo.PROC_max_number_of_departements_to_manage

BEGIN TRANSACTION
DECLARE @temp INT;
EXEC @temp = dbo.PROC_max_number_of_departements_to_manage
--Should be 1, allowed
SELECT @temp as 'first'
INSERT INTO dept (deptno, dname, loc, mgr) VALUES (21, 'TEMP', 'Zuthphen', 1001)
EXEC @temp = dbo.PROC_max_number_of_departements_to_manage
-- Should be , dissallowed since he manages 3 departements
SELECT @temp as 'second'
ROLLBACK TRANSACTION

/*******************************************************************************************
b) Er is maar maximaal één werknemer de president van het bedrijf in kwestie.

d) Een trainer kan geen cursus geven voor zijn/haar datum in dienst treding.
e) Een manager moet tevens werknemer zijn van de afdeling die zij/hij bestuurt.

9.	De navolgende requirement dien je te implementeren met behulp van stored procedures in de database van de centrale casus van de course Database Implementation. 

Wijzigingen van salarissen (commissie en maandsalaris) moeten gelogd worden in een logtabel. In die tabel registreren we wie (de user), wanneer, welke wijziging heeft aangebracht. Ontwerp een tabel en schrijf een update stored procedure die deze functionaliteit implementeert. 		
*******************************************************************************************/
GO
CREATE PROCEDURE dbo.usp_CheckPresidentCount
AS
	IF (
		SELECT COUNT(*)
		FROM emp
		WHERE job = 'PRESIDENT') >= 1
		RAISERROR ('Er is al een president', 11, 1)
GO
CREATE PROC dbo.usp_InsEmp @empno NUMERIC(4,0),
	@ename VARCHAR(8),
	@job VARCHAR(9),
	@born DATE,
	@hired DATE,
	@sgrade NUMERIC(2,0),
	@msal NUMERIC(7,2),
	@username VARCHAR(15),
	@deptno NUMERIC(2,0)
AS
BEGIN
	BEGIN TRY
		IF (@job = 'PRESIDENT')
			EXEC dbo.usp_CheckPresidentCount
		INSERT INTO emp VALUES (@empno, @ename, @job, @born, @hired, @sgrade, @msal, @username, @deptno)
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

BEGIN TRANSACTION
EXEC dbo.usp_InsEmp 1999, 'TEST', 'PRESIDENT', '01-01-2000', '19-jan-2019', 10, 10000, 'TEST_PRES', 11 --Er is al een president
EXEC dbo.usp_InsEmp 1999, 'TEST2', 'ADMIN', '01-01-2000', '19-jan-2019', 10, 10000, 'TEST_PRES2', 10 -- Moet slagen
ROLLBACK TRANSACTION

GO
CREATE PROC dbo.usp_UpdEmpJob @newJob VARCHAR(9), @empno NUMERIC(4,0)
AS
BEGIN
	BEGIN TRY
		IF(@newJob = 'PRESIDENT')
			EXEC dbo.usp_CheckPresidentCount
		UPDATE emp
			SET job = @newJob
			WHERE empno = @empno
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

BEGIN TRAN
	EXEC dbo.usp_UpdEmpJob 'PRESIDENT', 1000 --Huidige president
	EXEC dbo.usp_UpdEmpJob 'ADMIN', 1000 --Huidige president, moet slagen
	EXEC dbo.usp_UpdEmpJob 'PRESIDENT', 1001 -- Moet falen, tweede president
	EXEC dbo.usp_UpdEmpJob 'ADMIN', 1001 -- moet slagen
ROLLBACK TRAN



/*******************************************************************************************
	c) Een verkoop medewerker kan niet meer verdienen dan zijn baas
	(houdt rekening met de commissie die ook tot het salaris wordt gerekend en een jaarlijkse commissiebedrag betreft, 
	terwijl het reguliere basissalaris een maandsalaris betreft).

	Moet updates en deletes in memp en emp table checken
*******************************************************************************************/
GO
CREATE PROC dbo_usp_check_salaries @mgr NUMERIC(4,0), @emp NUMERIC(4,0)
AS
BEGIN
	IF 
		(
			SELECT msal * 12 + s.comm
				FROM emp e INNER JOIN srep s ON e.empno = s.empno
				WHERE e.empno = @emp
		) > 
		(
			SELECT msal * 12
				FROM emp e
				WHERE e.empno = @empno
		)
		THROW
END
GO
-- Reset DB voor casus
DROP PROCEDURE dbo.PROC_max_number_of_departements_to_manage
DROP PROCEDURE dbo.usp_CheckPresidentCount
DROP PROC dbo.usp_InsEmp
DROP PROC dbo.usp_UpdEmpJob
DROP PROC dbo.PROC_NumOfPresidents
DROP PROC dbo.usp_check_salaries