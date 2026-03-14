-- Check Dataabses Recovery Model

SELECT name, recovery_model_desc
FROM sys.databases
WHERE database_id > 4;


-- Change single Databse Recovery Model to FULL

ALTER DATABASE AdventureWorks2014
SET RECOVERY FULL;

-- Change Database Recovery Model to FULL except system DBs

DECLARE @DBName NVARCHAR(256)
DECLARE @SQL NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE recovery_model_desc = 'SIMPLE'
AND database_id > 4   -- Exclude system databases

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

SET @SQL = 'ALTER DATABASE [' + @DBName + '] SET RECOVERY FULL'

PRINT @SQL
EXEC(@SQL)

FETCH NEXT FROM db_cursor INTO @DBName
END

CLOSE db_cursor
DEALLOCATE db_cursor


-- Create Credential for Azure Blob container (SAS Token)

CREATE CREDENTIAL [https://mssqldmsmigrationdemo.blob.core.windows.net/sqlbackup]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'sp=racwdli&st=2026-03-14T06:10:02Z&se=2026-03-28T14:25:02Z&spr=https&sv=2024-11-04&sr=c&sig=nCxOnT2XBh1Hca75loz5T%2BnGCwiWJNaPVrwRoKXBxxo%3D';


-- One time Full backup for all DBs except System DBs

DECLARE @DBName NVARCHAR(256)
DECLARE @SQL NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE database_id > 4

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

SET @SQL =
'BACKUP DATABASE ['+@DBName+']
TO URL = ''https://mssqldmsmigrationdemo.blob.core.windows.net/sqlbackup/'+@DBName+'/'+@DBName+'_FULL.bak''
WITH INIT'

PRINT @SQL
EXEC(@SQL)

FETCH NEXT FROM db_cursor INTO @DBName
END

CLOSE db_cursor
DEALLOCATE db_cursor


-- Log backup SQL Agent Job (continuos)

DECLARE @DBName NVARCHAR(256)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TimeStamp NVARCHAR(50)

SET @TimeStamp =
REPLACE(CONVERT(VARCHAR,GETDATE(),120),':','-')

DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE database_id > 4
AND recovery_model_desc='FULL'

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

SET @SQL =
'BACKUP LOG ['+@DBName+']
TO URL = ''https://mssqldmsmigrationdemo.blob.core.windows.net/sqlbackup/'+@DBName+'/'+@DBName+'_LOG_'+@TimeStamp+'.trn''
WITH INIT'

EXEC(@SQL)

FETCH NEXT FROM db_cursor INTO @DBName
END

CLOSE db_cursor
DEALLOCATE db_cursor
