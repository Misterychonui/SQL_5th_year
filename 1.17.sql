--17.	Вывести все таблицы SQL Server, содержащие как минимум один столбец TEXT / NTEXT / IMAGE
CREATE OR ALTER PROCEDURE GetAllTablesWithTextNtextImageColumns
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = N'';
    DECLARE @DatabaseName NVARCHAR(128);

    CREATE TABLE #TablesWithTextNtextImageColumns (
        DatabaseName NVARCHAR(128),
        TableName NVARCHAR(128),
        ColumnName NVARCHAR(128),
        DataType NVARCHAR(128)
    );

    DECLARE db_cursor CURSOR FOR
    SELECT name FROM sys.databases WHERE state = 0; 

    OPEN db_cursor;
    FETCH NEXT FROM db_cursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Формируем динамический SQL для каждой базы данных
        SET @SQL = N'
        USE ' + QUOTENAME(@DatabaseName) + ';
        INSERT INTO #TablesWithTextNtextImageColumns (DatabaseName, TableName, ColumnName, DataType)
        SELECT 
            DB_NAME() AS DatabaseName,
            t.name AS TableName,
            c.name AS ColumnName,
            ty.name AS DataType
        FROM 
            sys.tables t
        INNER JOIN 
            sys.columns c ON t.object_id = c.object_id
        INNER JOIN 
            sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE 
            ty.name IN (''TEXT'', ''NTEXT'', ''IMAGE'');
        ';

        EXEC sp_executesql @SQL;

        FETCH NEXT FROM db_cursor INTO @DatabaseName;
    END;

    CLOSE db_cursor;
    DEALLOCATE db_cursor;

    SELECT * FROM #TablesWithTextNtextImageColumns;

    DROP TABLE #TablesWithTextNtextImageColumns;
END;

EXEC GetAllTablesWithTextNtextImageColumns;


