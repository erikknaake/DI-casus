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

-- Er wordt wel gethrowd, maar omdat de transactie wordt terug gedraaid gaat tSQLt over zijn nek
--GO
--CREATE OR ALTER PROC testSalaryGradesCantOverlap.testInsertWithWrongLowerLimit
--AS
--BEGIN
--	INSERT INTO grd VALUES (1, 10, 20, NULL)
--	INSERT INTO expected VALUES (1, 10, 20, NULL)
--	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003

--	INSERT INTO grd VALUES (2, 9, 20, NULL)

--	EXEC tSQLt.AssertEqualsTable expected, grd
--END
--GO


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
--GO
--CREATE OR ALTER PROC testSalaryGradesCantOverlap.testInsertWithWrongUpperLimit
--AS
--BEGIN
--	INSERT INTO grd VALUES (1, 10, 20, NULL)
--	INSERT INTO expected VALUES (1, 10, 20, NULL)
--	EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003

--	INSERT INTO grd VALUES (2, 10, 19, NULL)

--	EXEC tSQLt.AssertEqualsTable expected, grd
--END
--GO

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
	Run all tests
*******************************************************************************************/
EXEC tSQLt.RunAll