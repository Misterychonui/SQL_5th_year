--8.	Вывести все таблицы SQL Server с хотя бы одним отключенным триггером
CREATE OR ALTER PROCEDURE GetAllDisabledTriggers
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = N'';
    DECLARE @DatabaseName NVARCHAR(128);

    CREATE TABLE #DisabledTriggers (
        DatabaseName NVARCHAR(128),
        TableSchema NVARCHAR(128),
        TableName NVARCHAR(128),
        TriggerName NVARCHAR(128)
    );

    -- Перебираем все базы данных
    DECLARE db_cursor CURSOR FOR
    SELECT name FROM sys.databases WHERE state = 0; -- Только активные базы данных

    OPEN db_cursor;
    FETCH NEXT FROM db_cursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Формируем динамический SQL для каждой базы данных
        SET @SQL = N'
        USE ' + QUOTENAME(@DatabaseName) + ';
        INSERT INTO #DisabledTriggers (DatabaseName, TableSchema, TableName, TriggerName)
        SELECT 
            DB_NAME() AS DatabaseName,
            SCHEMA_NAME(t.schema_id) AS TableSchema,
            t.name AS TableName,
            trg.name AS TriggerName
        FROM 
            sys.tables t
        JOIN 
            sys.triggers trg ON trg.parent_id = t.object_id
        WHERE 
            trg.is_disabled = 1;
        ';

        EXEC sp_executesql @SQL;

        FETCH NEXT FROM db_cursor INTO @DatabaseName;
    END;

    CLOSE db_cursor;
    DEALLOCATE db_cursor;

    SELECT * FROM #DisabledTriggers;

    DROP TABLE #DisabledTriggers;
END;

EXEC GetAllDisabledTriggers;

CREATE TRIGGER trg_MaskData
ON YourTable
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE YourTable
    SET [Name] = dbo.MaskData([Name], 0.5) 
    WHERE Id IN (SELECT Id FROM inserted);
END;

DISABLE TRIGGER trg_MaskData ON YourTable

ENABLE TRIGGER trg_MaskData ON YourTable


