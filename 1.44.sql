--44.	Вывести все представления SQL Server, ссылающиеся на другие представления
CREATE OR ALTER PROCEDURE GetAllViewsWithReferencedViews
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = N'';
    DECLARE @DatabaseName NVARCHAR(128);

    CREATE TABLE #ViewsWithReferencedViews (
        DatabaseName NVARCHAR(128),
        ViewName NVARCHAR(128),
        ReferencedViewName NVARCHAR(128)
    );

    DECLARE db_cursor CURSOR FOR
    SELECT name FROM sys.databases WHERE state = 0; 

    OPEN db_cursor;
    FETCH NEXT FROM db_cursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = N'
        USE ' + QUOTENAME(@DatabaseName) + ';
        INSERT INTO #ViewsWithReferencedViews (DatabaseName, ViewName, ReferencedViewName)
        SELECT 
            DB_NAME() AS DatabaseName,
            v.name AS ViewName,
            r.name AS ReferencedViewName
        FROM 
            sys.views v
        INNER JOIN 
            sys.sql_expression_dependencies sed ON v.object_id = sed.referencing_id
        INNER JOIN 
            sys.views r ON sed.referenced_id = r.object_id
        WHERE 
            sed.referenced_id IN (SELECT object_id FROM sys.views);
        ';

        EXEC sp_executesql @SQL;

        FETCH NEXT FROM db_cursor INTO @DatabaseName;
    END;

    CLOSE db_cursor;
    DEALLOCATE db_cursor;

    SELECT * FROM #ViewsWithReferencedViews;

    DROP TABLE #ViewsWithReferencedViews;
END;

EXEC GetAllViewsWithReferencedViews;
