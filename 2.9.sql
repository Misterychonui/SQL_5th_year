--Написать процедуру создания нового объекта в БД (представление или таблица) на основе существующей таблицы.
--Имя нового объекта должно строится динамически и проверятся на существование в словаре данных. 
--Входные параметры – тип нового объекта, исходная таблица, столбцы и количество строк, которые будут использоваться в запросе. 

CREATE PROCEDURE CreateNewObject
    @ObjectType NVARCHAR(50),   
    @SourceTable NVARCHAR(128), 
    @Columns NVARCHAR(MAX),     
    @RowCount INT               
AS
BEGIN
    DECLARE @NewObjectName NVARCHAR(128);
    DECLARE @SQLQuery NVARCHAR(MAX);
    DECLARE @ObjectExists BIT = 0;
    DECLARE @ColumnExists BIT = 1;
    DECLARE @ColumnList NVARCHAR(MAX);
    DECLARE @Column NVARCHAR(128);
    DECLARE @ColumnCheck NVARCHAR(MAX);

    -- Формируем имя нового объекта
    SET @NewObjectName = 'NEW_' + @SourceTable + '_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');

    -- Проверяем существование столбцов в исходной таблице
    SET @ColumnList = @Columns;
    WHILE CHARINDEX(',', @ColumnList) > 0
    BEGIN
        SET @Column = LTRIM(RTRIM(SUBSTRING(@ColumnList, 1, CHARINDEX(',', @ColumnList) - 1)));
        SET @ColumnList = SUBSTRING(@ColumnList, CHARINDEX(',', @ColumnList) + 1, LEN(@ColumnList));

        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @SourceTable AND COLUMN_NAME = @Column)
        BEGIN
            SET @ColumnExists = 0;
            BREAK;
        END
    END

    -- Проверяем последний столбец в списке
    IF @ColumnExists = 1 AND LEN(@ColumnList) > 0
    BEGIN
        SET @Column = LTRIM(RTRIM(@ColumnList));
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @SourceTable AND COLUMN_NAME = @Column)
        BEGIN
            SET @ColumnExists = 0;
        END
    END

    -- Если хотя бы один столбец не существует, выдаем ошибку
    IF @ColumnExists = 0
    BEGIN
        RAISERROR('Один или несколько указанных столбцов не существуют в таблице %s.', 16, 1, @SourceTable);
        RETURN;
    END

    -- Формируем SQL-запрос для создания нового объекта
    IF @ObjectType = 'TABLE'
    BEGIN
        SET @SQLQuery = 'SELECT TOP (' + CAST(@RowCount AS NVARCHAR) + ') ' + @Columns + ' INTO ' + @NewObjectName + ' FROM ' + @SourceTable;
    END
    ELSE IF @ObjectType = 'VIEW'
    BEGIN
        SET @SQLQuery = 'CREATE VIEW ' + @NewObjectName + ' AS SELECT TOP (' + CAST(@RowCount AS NVARCHAR) + ') ' + @Columns + ' FROM ' + @SourceTable;
    END

    EXEC sp_executesql @SQLQuery;

    PRINT 'Объект ' + @NewObjectName + ' успешно создан.';
END;

EXEC CreateNewObject 
    @ObjectType = 'TABLE', 
    @SourceTable = 'Orders', 
    @Columns = 'CustomerID, EmployeeID, OrderDate', 
    @RowCount = 100;

SELECT * FROM NEW_Orders_20250323_155236


EXEC CreateNewObject 
    @ObjectType = 'VIEW', 
    @SourceTable = 'Orders', 
    @Columns = 'CustomerID, EmployeeID, OrderDate', 
    @RowCount = 100;


SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME LIKE 'NEW_Orders%';

SELECT * FROM NEW_Orders_20250323_155538 