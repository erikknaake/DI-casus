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

	employs president		employss manager		employs admin		OK
	not employs president	employss manager		employs admin		OK
	not employs president	not employss manager	employs admin		OK
	employs president		not employss manager	employs admin		OK
	employs president		not employss manager	not employs admin	NOT OK
	employs president		employss manager		not employs admin	NOT OK
	not employs president	employss manager		not employs admin	NOT OK
	not employs president	not employss manager	not employs admin	OK

	(not employs president && not employs manager) || employs admin
*******************************************************************************************/

--TODO: procedure 1


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