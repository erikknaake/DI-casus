USE COURSE
GO

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
	-- Door deze index wordt bij query 2 in het execution plan gekozen voor een nonclustered index seek in plaats van een clustered index scan
	-- Bij query 3 gebeurd hetzelfde. Deze indexes zijn beide covering, waardoor de query snelheid er op vooruitgaat
	-- Het is sneller om een ingang te geven op trainer dan dat het is om een ingang te geven op starts
	CREATE NONCLUSTERED INDEX NCI_offr
		ON offr(trainer) include(starts)
	SET STATISTICS IO ON
	EXEC sp_recompile 'dbo.utr_UniqueStartTrainer'

	INSERT INTO offr VALUES ('J2EE', GETDATE(), 'CONF', 6, 1016, 'Zutphen')

ROLLBACK TRAN

-- Ook even daadwerkelijk aanmaken nadat gebleken is dat ze optimaliseren.
CREATE NONCLUSTERED INDEX NCI_emp
	ON emp(job) include (deptno)
CREATE NONCLUSTERED INDEX NCI_offr
	ON offr(trainer) include(starts)