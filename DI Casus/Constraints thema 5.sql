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
 * @param @empNo the employeeNumer of the employer to check
 */
CREATE PROCEDURE dbo.PROC_max_number_of_departements_to_manage @empNo NUMERIC(4)
AS
	IF EXISTS (
		SELECT e.empno
			FROM emp e INNER JOIN dept d ON e.empno = d.mgr
			WHERE e.empno = @empNo
			GROUP BY e.empno
			HAVING COUNT(e.deptno) > 2
		)
		BEGIN
		PRINT 0
		RETURN 0
		END
	ELSE
		BEGIN
		PRINT 1
		RETURN 1
		END
GO
--DROP PROCEDURE dbo.PROC_max_number_of_departements_to_manage

BEGIN TRANSACTION
INSERT INTO dept (deptno, dname, loc, mgr) VALUES (21, 'TEMP', 'Zuthphen', 1001)
DECLARE @temp INT;
EXEC @temp = dbo.PROC_max_number_of_departements_to_manage 1001
-- Should be , dissallowed since he manages 3 departements
SELECT @temp as 'first'
EXEC @temp = dbo.PROC_max_number_of_departements_to_manage 1
--Should be 1, allowed
SELECT @temp as 'second'
ROLLBACK TRANSACTION

--Actual constraint:
/*ALTER TABLE dept
	ADD CONSTRAINT CHK_department_managers
	CHECK ()*/
/*******************************************************************************************
b) Er is maar maximaal één werknemer de president van het bedrijf in kwestie.
c) Een verkoop medewerker kan niet meer verdienen dan zijn baas (houdt rekening met de commissie die ook tot het salaris wordt gerekend en een jaarlijkse commissiebedrag betreft, terwijl het reguliere basissalaris een maandsalaris betreft).
d) Een trainer kan geen cursus geven voor zijn/haar datum in dienst treding.
e) Een manager moet tevens werknemer zijn van de afdeling die zij/hij bestuurt.

9.	De navolgende requirement dien je te implementeren met behulp van stored procedures in de database van de centrale casus van de course Database Implementation. 

Wijzigingen van salarissen (commissie en maandsalaris) moeten gelogd worden in een logtabel. In die tabel registreren we wie (de user), wanneer, welke wijziging heeft aangebracht. Ontwerp een tabel en schrijf een update stored procedure die deze functionaliteit implementeert. 		
*******************************************************************************************/
GO
CREATE PROCEDURE dbo.PROC_NumOfPresidents
AS
	SELECT COUNT(*)
		FROM emp
		WHERE job = 'PRESIDENT'
GO

SELECT CASE (dbo.PROC_NumOfPresidents)
BEGIN
	WHEN 1 THEN '1'
	WHEN 0 THEN '0'
END