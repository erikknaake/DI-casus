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

IF OBJECT_ID('dbo.CHK_PresidentSalary', 'C') IS NOT NULL 
    ALTER TABLE dbo.emp DROP CONSTRAINT CHK_PresidentSalary 
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
	- Als een president/manager wordt geinsert in emp OF
	- Als in emp de job van een medewerker naar president/manager wordt geupdate 
	en er geen administrator in de afdeling is of de geupdate medewerker de laatste administrator van de afdeling was OF
	- Als in emp de laatste administrator van een afdeling wordt geupdatet naar een andere job OF
	- Als in emp de departement van een president/manager wordt geupdatet naar een departement zonder administrator OF
	- Als in emp de departement van de laatste administrator van een afdeling wordt geupdatet 
	en er een president/manager is in de oude afdeling OF
	- Als in emp de laatste administrator van de afdeling gedeletet wordt en er een president/manager is in de afdeling

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
	SET NOCOUNT ON
	SET XACT_ABORT OFF
	DECLARE @TranCount INT = @@TRANCOUNT
	IF @TranCount > 0
		SAVE TRAN ProcedureSave
	ELSE
		BEGIN TRAN
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
		
				THROW 50020, 'Er is geen admin in deze afdeling', 1
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
				THROW 50021, 'Je kunt de job van de laatste admin van een afdeling waar een president of manager werkt niet veranderen', 1
			UPDATE emp
				SET job = @job
				WHERE empno = @empno
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
GO

/*******************************************************************************************
	3.	The company hires adult personnel only.
	age >= 18 OK
	age < 18 NOT OK
*******************************************************************************************/
IF OBJECT_ID('dbo.CHK_employee_age', 'C') IS NOT NULL 
    ALTER TABLE dbo.emp DROP CONSTRAINT CHK_employee_age 
ALTER TABLE emp
	ADD CONSTRAINT CHK_employee_age
	CHECK (DATEADD(YEAR, 18, born) < GETDATE())
go


/*******************************************************************************************
	4.	A salary grade overlaps with at most one lower salary grade. 
	The llimit of a salary grade must be higher than the llimit of the next lower salary grade. 
	The ulimit of the salary grade must be higher than the ulimit of the next lower salary grade. TODO: valideren of next lower salary grade inderdaad op grade slaat

	Kan misgaan bij:

	- Insert in grd waarbij de llimit lager is dan de llimit van een lagere grd
	- Insert in grd waarbij de ulimit lager is dan de ulimit van een lagere grd
	- Update van grd waarbij de llimit lager wordt dan de llimit van een lagere grd
	- Update van grd waarbij de ulimit lager wordt dan de ulimit van een lagere grd

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
				THROW 50040, 'Salary grades kunnen niet overlappen', 1
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
-- TODO:

/*******************************************************************************************
	6.	Trainers cannot teach different courses simultaneously.
	De starts + dur van de nieuwe offr mogen niet vallen binnen andere al gegeven offrs.

	Conditie A: StartA > EndB
	Conditie B: EndA < StartB
	Er is overlap als geen van beide waar is

	Kan misgaan als:

	- Nieuwe insert wordt gedaan in offr, en de starts tijd ligt binnen een bestaande offr die gegeven wordt (starts + dur)
	- Nieuwe insert wordt gedaan in offr, en de dur van de crs komt te vallen wanneer er al een andere offr wordt gegeven.
	- Bij een update van de starts in offr waardoor deze binnen een andere offr komt te liggen.
	- Bij een update van de duur van een course in de crs tabel waardoor deze komt te vallen binnen de duur van een andere offer

	-- Deze trigger handeld geen inserts of deletes af binnen de crs tabel, daarom hier niet aan voldaan worden

*******************************************************************************************/
GO
CREATE OR ALTER TRIGGER utr_OverlappingCourseOfferings
	ON offr
	AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		IF (UPDATE(starts))
		BEGIN
			IF exists (	
				SELECT *
				FROM inserted I
				WHERE exists (
					SELECT *
					FROM offr O
					WHERE (O.trainer = I.trainer) AND (
						-- StartA <= EndB
						(I.starts <= DATEADD(DAY, (SELECT dur-1 FROM crs WHERE code = O.course), O.starts))
						AND
						-- EndA >= StartB
						(DATEADD(DAY, (SELECT dur-1 FROM crs WHERE code = I.course), I.starts) >= O.starts)	
					) AND (O.course <> I.course AND O.starts <> I.starts)
				)								
			)
			THROW 50060, 'Een nieuwe offr mag niet binnen de tijdsduur van een al bestaande offr vallen', 1
		END
	END TRY

	BEGIN CATCH
		THROW
	END CATCH
END
GO


/*******************************************************************************************
	7.	An active employee cannot be managed by a terminated employee. 

	Kan misgaan bij:
	- Een update in memp waarbij de mgr naar een empno wordt gezet die in term staat
	- Een insert in memp waarbij de mgr een empno is van een term
	- Een insert in term waarbij de empno een mgr is in memp
	- Een update in term waarbij de empno naar een mgr in memp wordt gezet

	Gekozen voor een stored procedure voor het terminaten van een employee (insert in term), 
	omdat dit een voor de handliggende actie is en
	zodat er een default leftcomp date wordt ingevuld en een trigger geen voordelen heeft
*******************************************************************************************/
GO
CREATE OR ALTER PROC usp_TerminateEmp
	(
		@empno NUMERIC(4),
		@comments VARCHAR(60),
		@leftComp DATE = GETDATE
	)
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

		IF EXISTS (
				SELECT *
					FROM memp m
					WHERE m.mgr = @empno
					AND NOT EXISTS (
						SELECT *
							FROM term t
							WHERE m.empno = t.empno
					)
			)
			THROW 50070, 'Deze employee is nog een manager van een actieve employee', 1

		INSERT INTO term (empno, leftcomp, comments) VALUES (@empno, @leftComp, @comments)

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
GO


/*******************************************************************************************
	8.	A trainer cannot register for a course offering taught by him- or herself. 

	reg.stud mag niet gelijk zijn aan offr.trainer waar de course en starts gelijk aan elkaar zijn.

	Kan misgaan bij:
	- Een insert in reg waarbij de stud gelijk is aan de trainer van die course
	- Een update in reg zodat de stud gelijk wordt aan de trainer van die course
	- Een update in offr waardoor de trainer van gelijk wordt aan een geregistreerde employee

	Er is gekozen voor een stored procedure om een insert in de reg tabel te voorkomen,
	omdat dit een voor de hand liggende situatie is.
	
*******************************************************************************************/
GO
CREATE OR ALTER PROC usp_InsertNewReg
	(
		@stud numeric(4),
		@course varchar(6),
		@starts date,
		@eval numeric(1)
	)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT OFF

	DECLARE @TranCount INT = @@TRANCOUNT
	IF @TranCount > 0
		SAVE TRAN InsertNewReg
	ELSE
		BEGIN TRAN

	BEGIN TRY
		IF EXISTS (
			SELECT *
			FROM offr
			WHERE trainer = @stud AND (course = @course AND starts = @starts)
		)
		THROW 50080, 'Er mag niet geregistreerd worden op een course offering dat gegeven wordt door dezelfde employee', 1

		INSERT INTO reg VALUES (@stud, @course, @starts, @eval)

		IF @TranCount = 0 AND XACT_STATE() = 1 COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @TranCount = 0 AND XACT_STATE() = 1 ROLLBACK TRAN
		ELSE
			BEGIN
				IF XACT_STATE() <> -1 ROLLBACK TRAN InsertNewReg
			END;
		THROW
	END CATCH
END
GO


/*******************************************************************************************
	9.	At least half of the course offerings (measured by duration) taught by a trainer must be ‘home based’. 
	Note: ‘Home based’ means the course is offered at the same location where the employee is employed.

	Kan misgaan bij:
	- Update in crs waarbij de duration wordt veranderd
	- Update in offr waarbij de trainer wordt veranderd en dus de course inneens home based of niet meer home based is
	- Update in dept waarbij de locatie wordt aangepast en dus de course inneens home based of niet meer home based is
	- Update in emp waardoor de trainer in een andere locatie komt te werken en dus de course inneens home based of niet meer home based is
	- Insert in offr waardoor niet meer de helft van de offerings home based is
	- Delete in offr waardoor niet meer de helft van de offerings home based is

	Gekozen voor trigger op offr, omdat dezelfde code dan drie van de gevallen afdekt
*******************************************************************************************/
CREATE OR ALTER TRIGGER utr_HomeBasedOfferings
	ON offr
	AFTER UPDATE, INSERT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF UPDATE (course) OR UPDATE (trainer) OR UPDATE (loc)
		BEGIN
			-- Vanwege performance gekozen om te kijken welke home based zijn en dan de helft van de totale duration op te halen
			-- i.p.v te vergelijken met niet homebased
			IF (SELECT IIF(homeBasedDur.dur < halfDur.dur, 1, 0)
					FROM (
						SELECT SUM(dur) as dur
						FROM offr o INNER JOIN crs c ON o.course = c.code
							INNER JOIN emp e ON o.trainer = e.empno
							INNER JOIN dept d ON e.deptno = d.deptno
						WHERE d.loc = o.loc
					) as homeBasedDur, (
						SELECT SUM(dur) / 2 as dur
							FROM crs c INNER JOIN offr o ON c.code = o.course
					) as halfDur
				) = 1
				THROW 50090, 'Ten minste de helft van de offerings moet home based zijn', 1
		END
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END


/*******************************************************************************************
	10.	Offerings with 6 or more registrations must have status confirmed. 

	Wanneer er een insert of een update wordt gedaan in de registratie tabel
	Moet er gekeken worden of er courses zijn waar 6 of meer registraties op zijn.	

	Kan afgaan wanneer:
	- Er een nieuwe insert wordt gedaan in de reg tabel
	- Er een update wordt gedaan op de course in van een record in de reg tabel

	Er is gekozen voor een trigger, omdat deze verandering/check gedaan kan worden na
	dat er een insert/update is gedaan. Dit is niet belangrijk om te controleren
	voordat de insert/update gedaan wordt.
	
*******************************************************************************************/
GO
CREATE OR ALTER TRIGGER utr_OfferingsStatusChange
	ON reg
	AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		IF (UPDATE(course))
			UPDATE offr
			SET status = 'CONF'
			WHERE course IN (
				SELECT O.course
				FROM offr O JOIN reg R ON O.course = R.course AND O.starts = R.starts
				WHERE O.status <> 'CONF'
				GROUP BY O.course, O.starts
				HAVING COUNT(*) >= 6
			) AND starts IN (
				SELECT O.starts
				FROM offr O JOIN reg R ON O.course = R.course AND O.starts = R.starts
				WHERE O.status <> 'CONF'
				GROUP BY O.course, O.starts
				HAVING COUNT(*) >= 6
			)
	END TRY

	BEGIN CATCH
		THROW
	END CATCH
END
GO


/*******************************************************************************************
	11.	You are allowed to teach a course only if:
		- your job type is trainer and
		- you have been employed for at least one year 
		- or you have attended the course yourself (as participant) 

	Uitgegaan van job = 'TRAINER' AND (employed > 1 year OR attended course)

	Kan misgaan bij:
	- Update van emp waarbij de job wordt veranderd naar iets anders dan trainer
	- Update van emp waarbij de hiredDate naar voren wordt gezet
	- Delete van reg waarbij de gedelete record van een (nu) trainer is
	- Update van reg waarbij de course of deelnemer wordt aangepast
	- Insert in offr waarbij niet aan de condities wordt voldaan

	Gekozen voor een sproc insert van offr, omdat dat het meest waarschijnlijke scenario is
*******************************************************************************************/
GO
CREATE OR ALTER PROC usp_InsertOffering
	(
		@course VARCHAR(6),
		@starts DATE,
		@status VARCHAR(4),
		@maxcap NUMERIC(2),
		@trainer NUMERIC(4),
		@loc VARCHAR(14)
	)
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
		IF EXISTS (
				SELECT *
					FROM emp
					WHERE job <> 'TRAINER'
					AND empno = @trainer
			)
			THROW 50110, 'Iemand die een course geeft moet een trainer zijn', 1
		IF EXISTS (
				SELECT *
					FROM emp
					WHERE empno = @trainer
					AND (
						DATEADD(YEAR, 1, hired) < GETDATE()
						OR NOT EXISTS (
							SELECT *
								FROM reg
								WHERE stud = @trainer
								AND course = @course
						)
					)
			)
			THROW 50111, 'Een trainer moet of minimaal 1 jaar in dienst zijn, of moet de course hebben gevolgd', 1
		INSERT INTO offr VALUES (@course, @starts, @status, @maxcap, @trainer, @loc)
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
GO
