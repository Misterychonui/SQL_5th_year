CREATE ROLE DevUserRole;


ALTER ROLE db_datareader ADD MEMBER DevUserRole;  
ALTER ROLE db_datawriter ADD MEMBER DevUserRole;  

DECLARE @sql NVARCHAR(MAX);
-- Формирование SQL-запроса для предоставления прав на выполнение всех хранимых процедур в схеме dbo
SET @sql = (
    SELECT STRING_AGG('GRANT EXECUTE ON OBJECT::[' + SCHEMA_NAME(schema_id) + '].[' + name + '] TO DevUserRole;', CHAR(13))
    FROM sys.objects
    WHERE type = 'P' AND schema_id = SCHEMA_ID('dbo')  -- Выбираем только хранимые процедуры в схеме dbo
);

EXEC sp_executesql @sql;

CREATE OR ALTER TRIGGER DDL_GrantExecOnNewProc
ON DATABASE AFTER CREATE_PROCEDURE 
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @Procedure_Name NVARCHAR(MAX), @Schema_Name NVARCHAR(MAX), @sql NVARCHAR(MAX);

    -- Получение имени процедуры и схемы из события DDL
    SELECT @Procedure_Name = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(MAX)'),
           @Schema_Name = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(MAX)');

    IF @Schema_Name = 'dbo'
    BEGIN
        SET @sql = 'GRANT EXECUTE ON OBJECT::[' + @Schema_Name + '].[' + @Procedure_Name + '] TO DevUserRole;';
        EXEC sp_executesql @sql;  
    END;
END;

CREATE USER DDLUser WITHOUT LOGIN;


CREATE USER Test1 WITHOUT LOGIN;


ALTER ROLE DevUserRole ADD MEMBER Test1;


CREATE SCHEMA test;


CREATE PROCEDURE test.Test1
AS
BEGIN
    SELECT 'Работает!';
END;

CREATE SCHEMA test_2;


CREATE PROCEDURE test_2.Test1
AS
BEGIN
    SELECT 'Работает!';
END;

EXECUTE AS USER = 'Test1';
EXEC test.Test1;
REVERT;

EXECUTE AS USER = 'Test1';
EXEC test_2.Test1;
REVERT;


SELECT CURRENT_USER;

CREATE OR ALTER TRIGGER LostUsers
ON ALL SERVER 
FOR DROP_LOGIN  
AS
BEGIN
    DECLARE @LoginName SYSNAME;
    DECLARE @sid VARBINARY(86);

    SELECT @LoginName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'SYSNAME'),
           @sid = EVENTDATA().value('(/EVENT_INSTANCE/SID)[1]', 'VARBINARY(86)');

    CREATE TABLE #TEMPLogins (
        [sid] VARBINARY(86) NOT NULL,
        [name] SYSNAME NOT NULL
    );

    DECLARE @db_Name NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    DECLARE [cursor] CURSOR FOR
    SELECT Name FROM sys.databases;

    OPEN [cursor];
    FETCH NEXT FROM [cursor] INTO @db_Name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N' IF EXISTS (SELECT [sid] FROM [' + @db_Name + '].sys.sysusers WHERE [sid] = @sid)
                      BEGIN        
                        INSERT INTO #TEMPLogins VALUES (@sid, ''' + @db_Name + ''')
                      END';

        EXEC sp_executesql @sql, N'@sid VARBINARY(86)', @sid;

        FETCH NEXT FROM [cursor] INTO @db_Name;
    END;

    CLOSE [cursor];
    DEALLOCATE [cursor];

    IF (SELECT COUNT([sid]) FROM #TEMPLogins) <> 0
    BEGIN 
        PRINT 'Невозможно удалить логин, так как к нему есть еще привязанный user';
        ROLLBACK;  
    END;

    DROP TABLE IF EXISTS #TEMPLogins;
END;

drop trigger LostUsers on all server;

CREATE LOGIN Test2_Logon_1 WITH PASSWORD = '1234567890qwertyW!';


CREATE USER Test2_Sych_3  FOR LOGIN Test2_Logon_1 ;


DROP LOGIN Test2_Logon_1 ;  
DROP USER Test2_Sych_3 ;   