--доступ к SQL Server и разрешения на создание триггеров и сборок CLR
EXEC sp_configure 'clr enabled', 1
RECONFIGURE

EXEC sp_configure 'show advanced', 1
RECONFIGURE

EXEC sp_configure 'clr strict security', 0
RECONFIGURE

CREATE DATABASE LOGON_DATABASE;
GO
USE LOGON_DATABASE;
GO
ALTER DATABASE LOGON_DATABASE SET TRUSTWORTHY ON;

CREATE ASSEMBLY DdlTriggerAssembly 
from 'D:\sql\Database1\bin\Debug\Database1.dll'
WITH PERMISSION_SET = external_access

CREATE TRIGGER LogDdlChanges
ON DATABASE
FOR CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE, CREATE_FUNCTION, ALTER_FUNCTION, DROP_FUNCTION
AS EXTERNAL NAME DdlTriggerAssembly.Triggers.SqlTrigger

Create FUNCTION TestFunction() 
RETURNS 
 INT AS BEGIN RETURN 4
END

ALTER FUNCTION TestFunction() 
RETURNS 
 INT AS BEGIN RETURN 0
END