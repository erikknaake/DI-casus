USE COURSE
GO


SELECT * FROM emp

BEGIN TRAN
	-- Omdat er in de where zowel job als deptno worden gebruikt, zijn deze opgenomen in een nonclustered index, 
	-- zodat er een covering index ontstaat
	-- En MS SQL ervoor kiest om een nonclustered index seek te gaan doen in plaats van een clustered index scan.
	-- Op de huidige populatie is dit een vrijwel onmeetbaar verschil, echter kan het op grote populatie veel uitmaken
	-- omdat deze stored procedure 2 keer gebruik maakt van deze index
	CREATE NONCLUSTERED INDEX NCI_emp
		ON emp(job) include (deptno)

	SET STATISTICS IO ON
	EXEC usp_UpdateEmpJob @empno = 1011, @job = 'TRAINER' WITH RECOMPILE
	-- 2 clustered index scans naar non clustered index seek

	-- Subtree cost zonder NCI: 0.00991332
	-- 2, 6, 2 logical reads, geen physical reads, 2 scans zonder NCI.
	-- Subtree cost met NCI: 0.0098764
	-- 2, 8, 6 logical reads, geen physical reads, 3 scans met NCI
ROLLBACK TRAN


SELECT * FROM offr

BEGIN TRAN
	CREATE NONCLUSTERED INDEX NCI_offr
		ON offr(course, trainer, starts)
	SET STATISTICS IO ON
	EXEC sp_recompile 'dbo.utr_HomeBasedOfferings'
	EXEC sp_recompile 'dbo.utr_OverlappingCourseOfferings'

	EXEC usp_InsertOffering @course = 'J2EE', @starts = '2019-04-03', @status = 'CONF', @maxCap = 6, @trainer = 1016, @loc = 'Arnhem' WITH RECOMPILE
	-- Zoner NCI
	-- Subtree costs: 0.0537541
	-- 4 clustered index scans

ROLLBACK TRAN