USE COURSE
GO


/*******************************************************************************************
	Code die gegenereerd moet worden per tabel:

	GO
	CREATE TABLE HIST_<tabel naam> (
		ts TIMESTAMP NOT NULL,
		<kolommen met datatypes>

		CONSTRAINT pk_HIST_<tabel_name> PRIMARY KEY (ts, <pk uit tabel>)
	)
	GO
	CREATE TRIGGER utr_HIST_<tabel naam> 
		ON <tabel naam>
		AFTER INSERT, UPDATE
	AS
	BEGIN
		INSERT INTO HIST_<tabel naam> (<kolommen>)
			SELECT * FROM inserted
	END
	GO
*******************************************************************************************/

CREATE OR ALTER PROC usp_generateHistTable
	(
		@tableName VARCHAR(MAX)
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
		-- Alle kolomen, nodig voor de trigger
		DECLARE @columns VARCHAR(MAX) = '';
		SELECT @columns = @columns + COLUMN_NAME + ', '
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = @tableName
		SELECT @columns = LEFT(@columns, LEN(@columns) - 1)

		-- De primary kolommen, nodig om de primary key constraint aan te leggen
		DECLARE @primaryKeys VARCHAR(MAX) = '';
		SELECT @primaryKeys = @primaryKeys + sc.COLUMN_NAME + ', '
			FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
			INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE sc ON tc.CONSTRAINT_NAME = sc.CONSTRAINT_NAME
			WHERE CONSTRAINT_TYPE = 'PRIMARY KEY'
			AND tc.TABLE_NAME = @tableName
		SELECT @primaryKeys = LEFT(@primaryKeys, LEN(@primaryKeys) - 1)
		-- De kolommen met datatypes
		DECLARE @columnsMetDataTypes VARCHAR(MAX) = '';
		SELECT @columnsMetDataTypes = @columnsMetDataTypes + c.COLUMN_NAME +
			' ' +
			DATA_TYPE +
			IIF(
				DATA_TYPE LIKE '%numeric%', -- Voor numeric moet er bij komen: (NUMERIC_PRECISION, NUMERIC_SCALE)
				'(' + CAST(NUMERIC_PRECISION AS VARCHAR(5)) + ', ' + CAST(NUMERIC_SCALE AS VARCHAR(5)) + ')',
				IIF(DATA_TYPE LIKE '%char%', -- Voor chars, nchar, varchar, nvarchar moet er bij komen: (CHARACTER_MAXIMUM_LENGTH)
				'(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(5)) + ')',
				''
				)	
			) + 
			' ' +
			IIF(IS_NULLABLE = 'NO', 'NOT NULL', 'NULL') + -- Is de kolom nullable?
			', '
			FROM INFORMATION_SCHEMA.COLUMNS c
			WHERE c.TABLE_NAME = @tableName

		-- Maak de tabel aan
		DECLARE @sql VARCHAR(MAX) = '';
		SELECT @sql = @sql + 'CREATE TABLE HIST_' + @tableName + ' (ts TIMESTAMP NOT NULL, ' +
		@columnsMetDataTypes + ' CONSTRAINT pk_HIST_' + @tableName + ' PRIMARY KEY (ts, ' + @primaryKeys + ')) '
		EXEC(@sql)

		-- Maak de trigger aan
		SET @sql = '';
		SELECT @sql = @sql + 'CREATE TRIGGER utr_HIST_' + @tableName +
			' ON ' + @tableName + 
			' AFTER INSERT, UPDATE AS BEGIN INSERT INTO HIST_' + @tableName +
				'(' + @columns + ') SELECT * FROM inserted END '
		EXEC(@sql)
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

GO
CREATE OR ALTER PROC usp_generateAllHistory
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
		DECLARE @sql VARCHAR(MAX) = '';
		SELECT @sql = @sql + 'EXEC usp_generateHistTable ''' + TABLE_NAME + ''' '
			FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_NAME NOT LIKE 'HIST%'
		EXEC (@sql)
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

BEGIN TRAN
	EXEC usp_generateAllHistory
	SELECT *
		FROM INFORMATION_SCHEMA.TABLES

	SELECT * FROM HIST_grd
	INSERT INTO grd VALUES (12, 11000, 17000, 6500)
	SELECT * FROM HIST_grd
	INSERT INTO grd VALUES (13, 12000, 18000, 7000)
	SELECT * FROM HIST_grd -- Checken of er geen duplicates ontstaan
ROLLBACK TRAN

-- Werkt, dus aanmaken
EXEC usp_generateAllHistory