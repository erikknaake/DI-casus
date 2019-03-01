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

--Tests
BEGIN TRANSACTION
-- Should succeed, "is president		earns >= 10k	OK"
INSERT INTO emp (empno, ename, job, born, hired, sgrade, msal, username, deptno) VALUES (9990, 'Test', 'PRESIDENT', '11-feb-2000', '30-jun-2008', 11, 10000, 'Test_Subject', 10)

-- Should fail, "is president		earns < 10k		NOT OK"
INSERT INTO emp (empno, ename, job, born, hired, sgrade, msal, username, deptno) VALUES (9991, 'Test', 'PRESIDENT', '11-feb-2000', '30-jun-2008', 11, 9999, 'TestSubject1', 10)

-- Should succeed, "is not president	earns >= 10k	OK"
INSERT INTO emp (empno, ename, job, born, hired, sgrade, msal, username, deptno) VALUES (9992, 'Test', 'ADMIN', '11-feb-2000', '30-jun-2008', 11, 10000, 'TestSubject2', 10)

-- Should succeed, "is not president	earns < 10k		OK"
INSERT INTO emp (empno, ename, job, born, hired, sgrade, msal, username, deptno) VALUES (9993, 'Test', 'ADMIN', '11-feb-2000', '30-jun-2008', 11, 9999, 'TestSubject3', 10)
ROLLBACK TRANSACTION




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

	Als in emp de job van een medewerker naar president/mamanger wordt geupdate 
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
CREATE PROC usp_UpdateEmpJob
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
		IF (@job = 'PRESIDENT' OR @job = 'MANAGER') AND EXISTS (
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

-- Tests
BEGIN TRANSACTION
-- Should fail, age < 18
INSERT INTO emp (empno, ename, job, born, hired, sgrade, msal, username, deptno) VALUES (9993, 'Test', 'ADMIN', '11-feb-2004', '30-jun-2008', 11, 9999, 'TestSubject4', 10)

-- Should succeed, age >= 18
INSERT INTO emp (empno, ename, job, born, hired, sgrade, msal, username, deptno) VALUES (9994, 'Test', 'ADMIN', '11-feb-2000', '30-jun-2008', 11, 9999, 'TestSubject5', 10)
ROLLBACK TRANSACTION


/*******************************************************************************************
	4.	A salary grade overlaps with at most one lower salary grade. 
	The llimit of a salary grade must be higher than the llimit of the next lower salary grade. 
	The ulimit of the salary grade must be higher than the ulimit of the next lower salary grade.
*******************************************************************************************/
-- TODO: procedure 2


/*******************************************************************************************
	5.	The start date and known trainer uniquely identify course offerings. 
	Note: the use of a filtered index is not allowed.
*******************************************************************************************/
--TODO: is unique over 2 kollomen toegestaan?


/*******************************************************************************************
	6.	Trainers cannot teach different courses simultaneously.
*******************************************************************************************/
-- Procedure 3