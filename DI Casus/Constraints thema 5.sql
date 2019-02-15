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
c) Een verkoop medewerker kan niet meer verdienen dan zijn baas (houdt rekening met de commissie die ook tot het salaris wordt gerekend en een jaarlijkse commissiebedrag betreft, terwijl het reguliere basissalaris een maandsalaris betreft).
d) Een trainer kan geen cursus geven voor zijn/haar datum in dienst treding.
e) Een manager moet tevens werknemer zijn van de afdeling die zij/hij bestuurt.

9.	De navolgende requirement dien je te implementeren met behulp van stored procedures in de database van de centrale casus van de course Database Implementation. 

Wijzigingen van salarissen (commissie en maandsalaris) moeten gelogd worden in een logtabel. In die tabel registreren we wie (de user), wanneer, welke wijziging heeft aangebracht. Ontwerp een tabel en schrijf een update stored procedure die deze functionaliteit implementeert. 		
*******************************************************************************************/
GO
CREATE PROCEDURE dbo.PROC_NumOfPresidents
AS
	IF (SELECT COUNT(*)
		FROM emp
		WHERE job = 'PRESIDENT') > 1
		RAISERROR ('Er zijn meerdere presidenten', 11, 1)
	ELSE
		RAISERROR ('There are <= 1 presidents', 1, 1)
GO

EXEC dbo.PROC_NumOfPresidents


-- Reset DB voor casus
DROP PROCEDURE dbo.PROC_max_number_of_departements_to_manage
DROP PROCEDURE dbo.PROC_NumOfPresidents