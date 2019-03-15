USE Course
go


/*******************************************************************************************
	1.	The president of the company earns more than $10.000 monthly.

	is president		earns >= 10k	OK
	is president		earns < 10k		NOT OK
	is not president	earns >= 10k	OK
	is not president	earns < 10k		OK

	is not president || earns >= 10k
*******************************************************************************************/
/*SELECT *
	FROM emp
	WHERE job = 'PRESIDENT'*/

--Constraint
ALTER TABLE emp
	ADD CONSTRAINT CHK_PresidentSalary
	CHECK (job <> 'PRESIDENT' OR msal >= 10000)
go


/*******************************************************************************************
	2.	A department that employs the president or a manager should also employ at least one administrator.

	employs president		employs manager			employs admin		OK
	not employs president	employs manager			employs admin		OK
	not employs president	not employs manager		employs admin		OK
	employs president		not employs manager		employs admin		OK
	employs president		not employs manager		not employs admin	NOT OK
	employs president		employs manager			not employs admin	NOT OK
	not employs president	employs manager			not employs admin	NOT OK
	not employs president	not employs manager		not employs admin	OK

	(not employs president && not employs manager) || employs admin
	-----------------------------------------------------------------------------------------
	Kan misgaan als:
	Als een president/manager wordt geinsert in emp OF

	Als in emp de job van een medewerker naar president/manager wordt geupdate 
	en er geen administrator in de afdeling is of de geupdate medewerker de laatste administrator van de afdeling was OF

	Als in emp de laatste administrator van een afdeling wordt geupdatet naar een andere job OF

	Als in emp de departement van een president/manager wordt geupdatet naar een departement zonder administrator OF

	Als in emp de departement van de laatste administrator van een afdeling wordt geupdatet 
	en er een president/manager is in de oude afdeling OF

	Als in emp de laatste administrator van de afdeling gedeletet wordt en er een president/manager is in de afdeling

	Er is gekozen om de update van de job te implementeren, 
	omdat dit evenveel gevallen zijn als updates voor het updaten van het departmentnummer (de meeste gevallen)
	en er rekening gehouden moet worden dat de medewerker ook zelf de laatste administrator van een afdeling kan zijn
*******************************************************************************************/
GO
CREATE OR ALTER PROC usp_UpdateEmpJob
	(
		@empno NUMERIC(4,0),
		@job VARCHAR(9)
	)
AS
BEGIN
	BEGIN TRY
		DECLARE @deptno NUMERIC(2,0) = (
						SELECT deptno
							FROM emp
							WHERE empno = @empno --PK, dus veilig om aan te nemen dat het een scalar is
					) 
		IF (@job = 'PRESIDENT' OR @job = 'MANAGER') AND NOT EXISTS (
			-- Wordt een president of manager, check of er nog een (andere, mag niet zich zelf zijn met zijn oude job) admin is
			SELECT *
				FROM emp
				WHERE job = 'ADMIN' AND deptno = @deptno AND empno <> @empno
			)
		
			THROW 50001, 'Er is geen admin in deze afdeling', 1
		IF EXISTS (
			-- Emp die geupdate wordt is een admin, dus als er een President of Manager werkt EN het de laatste admin is in de afdeling, tegenhouden
			SELECT *
				FROM Emp
				WHERE empno = @empno AND job = 'ADMIN'
			) AND NOT EXISTS (
				SELECT *
					FROM Emp
					WHERE job = 'ADMIN' and deptno = @deptno AND empno <> @empno -- Het is de laatste admin als hier true uitkomt
			) AND EXISTS (
				SELECT *
					FROM Emp
					WHERE deptno = @deptno AND (job = 'PRESIDENT' OR job = 'MANAGER') -- En er werkt een president of manager in de afdeling
			)
			THROW 50002, 'Je kunt de job van de laatste admin van een afdeling waar een president of manager werkt niet veranderen', 1
		UPDATE emp
			SET job = @job
			WHERE empno = @empno
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

/*******************************************************************************************
	3.	The company hires adult personnel only.
	age >= 18 OK
	age < 18 NOT OK
*******************************************************************************************/
ALTER TABLE emp
	ADD CONSTRAINT CHK_employee_age
	CHECK (DATEADD(YEAR, 18, born) < GETDATE())
go


/*******************************************************************************************
	4.	A salary grade overlaps with at most one lower salary grade. 
	The llimit of a salary grade must be higher than the llimit of the next lower salary grade. 
	The ulimit of the salary grade must be higher than the ulimit of the next lower salary grade. TODO: valideren of next lower salary grade inderdaad op grade slaat

	Kan misgaan bij:

	Insert in grd waarbij de llimit lager is dan de llimit van een lagere grd
	Insert in grd waarbij de ulimit lager is dan de ulimit van een lagere grd

	Update van grd waarbij de llimit lager wordt dan de llimit van een lagere grd
	Update van grd waarbij de ulimit lager wordt dan de ulimit van een lagere grd

	Gekozen voor een trigger omdat die met dezelfde code zowel voor inserts als updates kan werken
*******************************************************************************************/
GO
CREATE OR ALTER TRIGGER utr_OverlappingSalaryGrades
	ON grd
	AFTER UPDATE, INSERT
AS
BEGIN 
	BEGIN TRY
		SET NOCOUNT ON
		IF UPDATE(llimit) OR UPDATE(ulimit)
		BEGIN
			IF EXISTS (
				SELECT *
					FROM inserted i
					WHERE EXISTS (
						SELECT *
							FROM grd g
							WHERE g.grade < i.grade AND (
								i.llimit < g.llimit OR
								i.ulimit < g.ulimit
							)
					)
				)
				THROW 50003, 'Salary grades kunnen niet overlappen', 1
		END
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

/*******************************************************************************************
	5.	The start date and known trainer uniquely identify course offerings. 
	Note: the use of a filtered index is not allowed.
*******************************************************************************************/
-- Dit is in het COURSE_constraint.sql bestand al gedaan onder de constraint: ofr_unq.

/*******************************************************************************************
	6.	Trainers cannot teach different courses simultaneously.
	De starts van de nieuwe offr mag niet liggen binenn de starts + dur (crs) van een andere course. 

	Kan misgaan als:

	Nieuwe insert wordt gedaan in offr en de starts tijd ligt binnen een bestaande offr die gegeven wordt (starts + dur)
	Nieuwe insert wordt gedaan en de dur van de crs komt te vallen wanneer er al een andere offr wordt gegeven.

	Bij een update van de starts in offr waardoor deze in een andere offr komt te liggen.
	Bij een update van de duration van een crs waardoor deze komt te vallen binnen de duur van een andere crs

*******************************************************************************************/
GO
CREATE OR ALTER TRIGGER utr_OverlappingCourseOfferings
	ON offr
	AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT OFF

	DECLARE @TranCount INT = @@TRANCOUNT
	IF @TranCount > 0
		SAVE TRAN ProcedureSave
	ELSE
		BEGIN TRAN

	BEGIN TRY

		-- Check met throw als het verkeerd gaat


		-- Commit als het goed gaat
		IF @TranCount = 0 AND XACT_STATE() = 1 COMMIT TRAN
	END TRY

	BEGIN CATCH
		IF @TranCount = 0 AND XACT_STATE() = 1 ROLLBACK TRAN
		ELSE
			BEGIN
				IF XACT_STATE() <> -1 ROLLBACK TRAN ProcedureSave
			END;
		THROW
	END CATCH
END