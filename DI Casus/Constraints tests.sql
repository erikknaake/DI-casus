/*******************************************************************************************
	Tests van constraints	
*******************************************************************************************/
USE COURSE
GO

EXEC tSQLt.NewTestClass 'testEmps'

-- Before each test in the testEmps test class
GO
CREATE PROC testEmps.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable @TableName = 'dbo.emp' -- Use of @SchemaName has been deprecated, use of tablename with schemaName prefixed is now prefered
END


/*******************************************************************************************
	Constraint 1
	President salary
*******************************************************************************************/

GO
CREATE OR ALTER PROC testEmps.testPresidentMontlySalaryShouldBeGreaterThan10000InvalidCase
AS
BEGIN
	EXEC tSQLt.ApplyConstraint 'dbo.emp', 'CHK_PresidentSalary'
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 547 -- A check constraint should be violated
	INSERT INTO emp VALUES (NULL, NULL, 'PRESIDENT', NULL, NULL, NULL, 9999, NULL, NULL)
END
GO

GO
CREATE OR ALTER PROC testEmps.testPresidentMontlySalaryShouldBeGreaterThan10000ValidCase
AS
BEGIN
	EXEC tSQLt.ApplyConstraint 'dbo.emp', 'CHK_PresidentSalary'
	EXEC tSQLt.ExpectNoException
	INSERT INTO emp VALUES (NULL, NULL, 'PRESIDENT', NULL, NULL, NULL, 10000, NULL, NULL)
END
GO

/*******************************************************************************************
	Constraint 2
	A department that employs the president or a manager should also employ at least one administrator.
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testAdminInEveryDeptAPresidentOrManagerWorks'

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.emp'
	SELECT *
		INTO expected
		FROM dbo.emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testEmpToPresidentWithoutAdmin
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001

	EXEC dbo.usp_UpdateEmpJob @empno = 1, @job = 'PRESIDENT'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testEmpToPresidentWithAdmin
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'PRESIDENT', NULL, NULL, NULL, NULL, NULL, 10), (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_UpdateEmpJob @empno = 1, @job = 'PRESIDENT'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testEmpToManagerWithoutAdmin
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001

	EXEC dbo.usp_UpdateEmpJob @empno = 1, @job = 'MANAGER'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testEmpToManagerWithAdmin
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'MANAGER', NULL, NULL, NULL, NULL, NULL, 10), (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_UpdateEmpJob @empno = 1, @job = 'MANAGER'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testLastAdminToOtherWithManager
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'MANAGER', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'MANAGER', NULL, NULL, NULL, NULL, NULL, 10), (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50002

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'SALESREP'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testLastAdminToOtherWithPresident
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'PRESIDENT', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'PRESIDENT', NULL, NULL, NULL, NULL, NULL, 10), (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50002

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'SALESREP'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testLastAdminToOther
AS
BEGIN
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (2, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'SALESREP'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testNonLastAdminToOtherWithPresident
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'PRESIDENT', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (3, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'PRESIDENT', NULL, NULL, NULL, NULL, NULL, 10), (2, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10), (3, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'SALESREP'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testNonLastAdminToOther
AS
BEGIN
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (3, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (2, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10), (3, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'SALESREP'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testNonLastAdminToOtherWithManager
AS
BEGIN
	INSERT INTO dbo.emp VALUES (1, NULL, 'MANAGER', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO dbo.emp VALUES (3, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (1, NULL, 'MANAGER', NULL, NULL, NULL, NULL, NULL, 10), (2, NULL, 'SALESREP', NULL, NULL, NULL, NULL, NULL, 10), (3, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'SALESREP'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testLastAdminToPresident
AS
BEGIN
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (2, NULL, 'PRESIDENT', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'PRESIDENT'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

GO
CREATE OR ALTER PROC testAdminInEveryDeptAPresidentOrManagerWorks.testLastAdminToManager
AS
BEGIN
	INSERT INTO dbo.emp VALUES (2, NULL, 'ADMIN', NULL, NULL, NULL, NULL, NULL, 10)
	INSERT INTO expected VALUES (2, NULL, 'MANAGER', NULL, NULL, NULL, NULL, NULL, 10)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001

	EXEC dbo.usp_UpdateEmpJob @empno = 2, @job = 'MANAGER'

	EXEC tSQLt.AssertEqualsTable expected, emp
END
GO

/*******************************************************************************************
	Constraint 3
	All employees should be age 18 or older
*******************************************************************************************/
CREATE OR ALTER PROC testEmps.testEmpAge18OrHigherInvalidCase
AS
BEGIN
	EXEC tSQLt.ApplyConstraint 'dbo.emp', 'CHK_employee_age'
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 547 -- A check constraint should be violated
	INSERT INTO emp VALUES (NULL, NULL, NULL, DATEADD(YEAR, -17, GETDATE()), NULL, NULL, NULL, NULL, NULL)
END
GO

CREATE OR ALTER PROC testEmps.testEmpAge18OrHigherValidCase
AS
BEGIN
	EXEC tSQLt.ApplyConstraint 'dbo.emp', 'CHK_employee_age'
	EXEC tSQLt.ExpectNoException
	INSERT INTO emp VALUES (NULL, NULL, NULL, DATEADD(YEAR, -18, GETDATE()), NULL, NULL, NULL, NULL, NULL)
END
GO

/*******************************************************************************************
	Constraint 4
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testSalaryGradesCantOverlap'

GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.grd'
	EXEC tSQLt.ApplyTrigger 'dbo.grd', 'dbo.utr_OverlappingSalaryGrades'
	SELECT *
		INTO expected
		FROM dbo.grd
END
GO

 --Er wordt wel gethrowd, maar omdat de transactie wordt terug gedraaid gaat tSQLt over zijn nek
GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testInsertWithWrongLowerLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003

	INSERT INTO grd VALUES (2, 9, 20, NULL)

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO


GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testInsertWithCorrectLowerLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL), (2, 11, 20, NULL)
	EXEC tSQLt.ExpectNoException

	INSERT INTO grd VALUES (2, 11, 20, NULL)

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO

-- Er wordt wel gethrowd, maar omdat de transactie wordt terug gedraaid gaat tSQLt over zijn nek
GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testInsertWithWrongUpperLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003

	INSERT INTO grd VALUES (2, 10, 19, NULL)

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO

GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testInsertWithCorrectUpperLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL), (2, 10, 21, NULL)
	EXEC tSQLt.ExpectNoException

	INSERT INTO grd VALUES (2, 10, 21, NULL)

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO

GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testUpdateWithWrongLowerLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL), (2, 11, 20, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL), (2, 11, 20, NULL)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003

	UPDATE grd
		SET llimit = 9
		WHERE grade = 2

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO


GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testUpdateWithCorrectLowerLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL), (2, 11, 20, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL), (2, 12, 20, NULL)
	EXEC tSQLt.ExpectNoException

	UPDATE grd
		SET llimit = 12
		WHERE grade = 2

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO

GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testUpdateWithWrongUpperLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL), (2, 10, 21, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL), (2, 10, 21, NULL)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003

	UPDATE grd
		SET ulimit = 19
		WHERE grade = 2

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO

GO
CREATE OR ALTER PROC testSalaryGradesCantOverlap.testUpdateWithCorrectUpperLimit
AS
BEGIN
	INSERT INTO grd VALUES (1, 10, 20, NULL), (2, 10, 21, NULL)
	INSERT INTO expected VALUES (1, 10, 20, NULL), (2, 10, 22, NULL)
	EXEC tSQLt.ExpectNoException

	UPDATE grd
		SET ulimit = 22
		WHERE grade = 2

	EXEC tSQLt.AssertEqualsTable expected, grd
END
GO


/*******************************************************************************************
	Constraint 5
	The start date and known trainer uniquely identify course offerings. 
	Note: the use of a filtered index is not allowed.
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testOffrIsUniqueByTrainerAndStarts'

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.offr'
	EXEC tSQLt.ApplyConstraint 'dbo.offr', 'ofr_unq'
	SELECT *
		INTO expected
		FROM dbo.offr
END
GO

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.testNormalInsert
AS
BEGIN
	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL)
	INSERT INTO expected VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL), (NULL, '24-DEC-2019', NULL, NULL, 2, NULL)
	EXEC tSQLt.ExpectNoException

	INSERT INTO offr VALUES (NULL, '24-DEC-2019', NULL, NULL, 2, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.testSameDate
AS
BEGIN
	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL)
	INSERT INTO expected VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL), (NULL, '23-DEC-2019', NULL, NULL, 2, NULL)
	EXEC tSQLt.ExpectNoException

	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, 2, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.testSameTrainer
AS
BEGIN
	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL)
	INSERT INTO expected VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL), (NULL, '24-DEC-2019', NULL, NULL, 1, NULL)
	EXEC tSQLt.ExpectNoException

	INSERT INTO offr VALUES (NULL, '24-DEC-2019', NULL, NULL, 1, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.testSameTrainerSameDate
AS
BEGIN
	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL)
	INSERT INTO expected VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 2627

	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, 1, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.testSameTrainerNull
AS
BEGIN
	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, NULL, NULL)
	INSERT INTO expected VALUES (NULL, '23-DEC-2019', NULL, NULL, NULL, NULL), (NULL, '24-DEC-2019', NULL, NULL, NULL, NULL)
	EXEC tSQLt.ExpectNoException

	INSERT INTO offr VALUES (NULL, '24-DEC-2019', NULL, NULL, NULL, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testOffrIsUniqueByTrainerAndStarts.testSameTrainerSameDateWithNullTrainer
AS
BEGIN
	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, NULL, NULL)
	INSERT INTO expected VALUES (NULL, '23-DEC-2019', NULL, NULL, NULL, NULL)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 2627

	INSERT INTO offr VALUES (NULL, '23-DEC-2019', NULL, NULL, NULL, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO


/*******************************************************************************************
	Constraint 6
	Trainers cannot teach different courses simultaneously. 
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testCourseOfferingsCantOverlap'

GO
CREATE OR ALTER PROC testCourseOfferingsCantOverlap.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.offr'
	EXEC tSQLt.ApplyTrigger 'dbo.offr', 'dbo.utr_OverlappingCourseOfferings'
	SELECT *
		INTO expected
		FROM dbo.offr
END
GO

GO
CREATE OR ALTER PROC testCourseOfferingsCantOverlap.testInsertWithoutErrors
AS
BEGIN
	INSERT INTO offr VALUES ('PLSQL', '2006-10-08', NULL, NULL, 1016, NULL)
	INSERT INTO expected VALUES ('PLSQL', '2006-10-08', NULL, NULL, 1016, NULL), ('AM4PD', '2006-10-12', NULL, NULL, 1016, NULL)

	EXEC tSQLt.ExpectNoException

	INSERT INTO offr VALUES ('AM4PD', '2006-10-12', NULL, NULL, 1016, NULL)

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testCourseOfferingsCantOverlap.testInsertWhileEndWillSurpassStartOfAnotherOffer
AS
BEGIN
	INSERT INTO offr VALUES ('PLSQL', '2006-10-08', NULL, NULL, 1016, NULL)

	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50061

	INSERT INTO offr VALUES ('AM4DP', '2006-10-06', NULL, NULL, 1016, NULL)
END
GO

GO
CREATE OR ALTER PROC testCourseOfferingsCantOverlap.testInsertWhileStartsIsLessThenEndOfAnotherOffer
AS
BEGIN
	INSERT INTO offr VALUES ('PLSQL', '2006-10-08', NULL, NULL, 1016, NULL)

	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50061

	INSERT INTO offr VALUES ('APEX', '2006-10-10', NULL, NULL, 1016, NULL)
END
GO

GO
CREATE OR ALTER PROC testCourseOfferingsCantOverlap.testUpdateSoEndWillSurpassStartOfAnotherOffer
AS
BEGIN
	INSERT INTO offr VALUES ('AM4DP', '2006-10-08', NULL, NULL, 1016, NULL)
	INSERT INTO offr VALUES ('PLSQL', '2006-10-18', NULL, NULL, 1016, NULL)

	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50061

	UPDATE offr
		SET starts = '2006-10-09'
		WHERE course = 'AM4DP' AND starts ='2006-10-08'
END
GO

GO
CREATE OR ALTER PROC testCourseOfferingsCantOverlap.testUpdateSoStartsIsLessThenEndOfAnotherOffer
AS
BEGIN
	INSERT INTO offr VALUES ('AM4DP', '2006-10-08', NULL, NULL, 1016, NULL)
	INSERT INTO offr VALUES ('PLSQL', '2006-10-18', NULL, NULL, 1016, NULL)

	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50061

	UPDATE offr
		SET starts = '2006-10-17'
		WHERE course = 'PLSQL' AND starts ='2006-10-18'
END
GO

/*******************************************************************************************
	Constraint 7
	An active employee cannot be managed by a terminated employee.
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testTermEmpNotManagingActiveEmp'

GO
CREATE OR ALTER PROC testTermEmpNotManagingActiveEmp.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.term'
	EXEC tSQLt.FakeTable 'dbo.memp'
	EXEC tSQLt.FakeTable 'dbo.emp'
	SELECT *
		INTO expected
		FROM dbo.term
END
GO

GO
CREATE OR ALTER PROC testTermEmpNotManagingActiveEmp.testNormalTerm
AS
BEGIN
	INSERT INTO emp VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
	INSERT INTO memp VALUES (1, 2)
	INSERT INTO expected VALUES (1, NULL, NULL)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_TerminateEmp 1, NULL, NULL

	EXEC tSQLt.AssertEqualsTable expected, term
END
GO

GO
CREATE OR ALTER PROC testTermEmpNotManagingActiveEmp.testTermOfManagerWithActiveEmp
AS
BEGIN
	INSERT INTO emp VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
	INSERT INTO memp VALUES (2, 1)
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50006

	EXEC dbo.usp_TerminateEmp 1, NULL, NULL

	EXEC tSQLt.AssertEqualsTable expected, term
END
GO

GO
CREATE OR ALTER PROC testTermEmpNotManagingActiveEmp.testTermOfManagerWithInactiveEmp
AS
BEGIN
	INSERT INTO emp VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
	INSERT INTO memp VALUES (1, 2)
	INSERT INTO term VALUES (1, NULL, NULL)
	INSERT INTO expected VALUES (1, NULL, NULL), (2, NULL, NULL)
	EXEC tSQLt.ExpectNoException

	EXEC dbo.usp_TerminateEmp 2, NULL, NULL

	EXEC tSQLt.AssertEqualsTable expected, term
END
GO


/*******************************************************************************************
	Constraint 8
	A trainer cannot register for a course offering taught by him- or herself.
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testNotRegOnCourseTaughtBySameEmp'

GO
CREATE OR ALTER PROC testNotRegOnCourseTaughtBySameEmp.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.emp'
	EXEC tSQLt.FakeTable 'dbo.reg'
	EXEC tSQLt.FakeTable 'dbo.offr'
	SELECT *
		INTO expected
		FROM dbo.reg
END
GO

GO
CREATE OR ALTER PROC testNotRegOnCourseTaughtBySameEmp.testNormalInsert
AS
BEGIN
	INSERT INTO emp VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
	INSERT INTO offr VALUES (1016, '2006-10-07', NULL, NULL, 1, NULL)
	INSERT INTO expected VALUES (2, 1016, '2006-10-07', NULL)
	
	EXEC tSQLt.ExpectNoException

	EXEC usp_InsertNewReg 2, 1016, '2006-10-07', NULL

	EXEC tSQLt.AssertEqualsTable expected, reg
END
GO

GO
CREATE OR ALTER PROC testNotRegOnCourseTaughtBySameEmp.testTermOfSameEmp
AS
BEGIN
	INSERT INTO emp VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
	INSERT INTO offr VALUES (1016, '2006-10-07', null, null, 1, null)
	
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50081

	EXEC usp_InsertNewReg 1, 1016, '2006-10-07', null

	EXEC tSQLt.AssertEqualsTable expected, reg
END
GO


/*******************************************************************************************
	Constraint 11
	11.	You are allowed to teach a course only if:
		your job type is trainer and
		-      you have been employed for at least one year 
		-	or you have attended the course yourself (as participant) 
*******************************************************************************************/
EXEC tSQLt.NewTestClass 'testTeacherRequirements'

GO
CREATE OR ALTER PROC testTeacherRequirements.SetUp
AS
BEGIN
	EXEC tSQLt.FakeTable 'dbo.emp'
	EXEC tSQLt.FakeTable 'dbo.reg'
	EXEC tSQLt.FakeTable 'dbo.offr'
	EXEC tSQLt.FakeTable 'dbo.crs'
	SELECT *
		INTO expected
		FROM dbo.offr
	INSERT INTO emp VALUES (1, NULL, 'TRAINER', NULL, DATEADD(YEAR, -1, GETDATE()), NULL, NULL, NULL, NULL), 
		(2, NULL, 'SALESREP', NULL, DATEADD(YEAR, -1, GETDATE()), NULL, NULL, NULL, NULL),
		(3, NULL, 'TRAINER', NULL, GETDATE(), NULL, NULL, NULL, NULL),
		(4, NULL, 'TRAINER', NULL, GETDATE(), NULL, NULL, NULL, NULL),
		(5, NULL, 'TRAINER', NULL, DATEADD(YEAR, -1, GETDATE()), NULL, NULL, NULL, NULL)
	INSERT INTO reg VALUES (4, 'DMDD', NULL, NULL), (3, 'DI', NULL, NULL), (5, 'DI', NULL, NULL)
END
GO

GO
CREATE OR ALTER PROC testTeacherRequirements.testTrainerEmployedFor1YearAndHadCourse
AS
BEGIN
	DECLARE @date DATE = GETDATE();

	INSERT INTO expected VALUES ('DI', @date, 'CONF', 2, 5, 'Zutphen')
	EXEC tSQLt.ExpectNoException

	EXEC usp_InsertOffering 'DI', @date, 'CONF', 2, 5, 'Zutphen'

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testTeacherRequirements.testTrainerEmployedFor1YearAndNotHadCourse
AS
BEGIN
	DECLARE @date DATE = GETDATE();

	INSERT INTO expected VALUES ('DMDD', @date, 'CONF', 2, 5, 'Zutphen')
	EXEC tSQLt.ExpectNoException

	EXEC usp_InsertOffering 'DMDD', @date, 'CONF', 2, 5, 'Zutphen'

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testTeacherRequirements.testTrainerNotEmployedFor1YearHadCourse
AS
BEGIN
	DECLARE @date DATE = GETDATE();

	INSERT INTO expected VALUES ('DMDD', @date, 'CONF', 2, 4, 'Zutphen')
	EXEC tSQLt.ExpectNoException

	EXEC usp_InsertOffering 'DMDD', @date, 'CONF', 2, 4, 'Zutphen'

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testTeacherRequirements.testTrainerNotHadCourseAndNotEmployedFor1Year
AS
BEGIN
	DECLARE @date DATE = GETDATE();
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50111

	EXEC usp_InsertOffering 'DI', @date, 'CONF', 2, 4, 'Zutphen'

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO

GO
CREATE OR ALTER PROC testTeacherRequirements.testNotATrainer
AS
BEGIN
	DECLARE @date DATE = GETDATE();
	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50110

	EXEC usp_InsertOffering 'DMDD', @date, 'CONF', 2, 2, 'Zutphen'

	EXEC tSQLt.AssertEqualsTable expected, offr
END
GO
/*******************************************************************************************
	Run all tests
*******************************************************************************************/
EXEC tSQLt.RunAll