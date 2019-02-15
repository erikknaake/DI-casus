/******************************************************************************************
	Erik Knaake
	13 februari 2019
*******************************************************************************************/
USE COURSE
GO

/*******************************************************************************************
	Een salarisschaal specificeert een salarisinterval van minimaal 500 euro.
*******************************************************************************************/
ALTER TABLE grd
	ADD CONSTRAINT CHK_grade_size
	CHECK (ulimit - llimit >= 500)
GO

BEGIN TRANSACTION
-- Should fail, interval < 500
INSERT INTO grd (grade, llimit, ulimit, bonus) VALUES (12, 500, 999, 250)
-- Should succeed, interval >= 500
INSERT INTO grd (grade, llimit, ulimit, bonus) VALUES (13, 500, 1000, 250)
ROLLBACK TRANSACTION
/*******************************************************************************************
	De ondergrenswaarde van een salarisschaal (llimit) identificeert de schaal in kwestie. 
*******************************************************************************************/
ALTER TABLE grd
	ADD CONSTRAINT U_llimit
	UNIQUE (llimit)
GO

BEGIN TRANSACTION
-- Should succeed, first lower limit of 750
INSERT INTO grd (grade, llimit, ulimit, bonus) VALUES (14, 750, 5000, 250)
-- Should fail, second lower limit of 500
INSERT INTO grd (grade, llimit, ulimit, bonus) VALUES (15, 500, 5001, 250)
ROLLBACK TRANSACTION

/*******************************************************************************************
	Een cursus uitvoering (tabel OFFR) heeft altijd een trainer tenzij de status waarde aangeeft dat de cursus afgeblazen (status ‘CANC’) is of dat de cursus gepland is (status ‘SCHD’).  
*******************************************************************************************/
ALTER TABLE offr
	ADD CONSTRAINT CHK_trainer_status
	CHECK (trainer IS NOT NULL OR status = 'CANC' OR status = 'SCHD')
GO

BEGIN TRANSACTION
-- Should succeed, trainer and status = CANC
INSERT INTO offr (course, starts, status, maxcap, trainer, loc) VALUES ('AM4DP', GETDATE(), 'CANC', 20, 1018, 'SAN FRANCISCO')
-- Should succeed, trainer and status = SCHD
INSERT INTO offr (course, starts, status, maxcap, trainer, loc) VALUES ('AM4DPM', GETDATE(), 'SCHD', 20, 1017, 'SAN FRANCISCO')
-- Should succeed, no trainer and status = SCHD
INSERT INTO offr (course, starts, status, maxcap, trainer, loc) VALUES ('APEX', GETDATE(), 'SCHD', 20, NULL, 'SAN FRANCISCO')
-- Should succeed, no trainer and status = CANC
INSERT INTO offr (course, starts, status, maxcap, trainer, loc) VALUES ('DBCENT', DATEADD(DAY, 1, GETDATE()), 'CANC', 20, NULL, 'SAN FRANCISCO') --Date adds because unique on trainer and start
-- Should fail, no trainer and status = CONF
INSERT INTO offr (course, starts, status, maxcap, trainer, loc) VALUES ('J2EE', DATEADD(DAY, 2, GETDATE()), 'CONF', 20, NULL, 'SAN FRANCISCO')
ROLLBACK TRANSACTION