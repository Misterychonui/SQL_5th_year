--Уровень А
--Разработать свой метод маскирования символьных данных. Инструменты: View, Триггеры, Функции
--Написать хранимую процедуру, которая позволяет включать (отключать) разработанный метод для указанного поля в представлении.

CREATE DATABASE TEST5DATABASE;
USE TEST5DATABASE;
GO

CREATE FUNCTION dbo.MaskData (@input NVARCHAR(MAX), @maskRatio FLOAT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @masked NVARCHAR(MAX);
    DECLARE @maskLength INT;

    -- Определяем длину маскированной части
    SET @maskLength = CEILING(LEN(@input) * @maskRatio);

    -- Маскируем часть строки
    SET @masked = REPLICATE('*', @maskLength) + SUBSTRING(@input, @maskLength + 1, LEN(@input));

    RETURN @masked;
END;

CREATE TABLE YourTable (
    Id INT PRIMARY KEY,
    [Name] NVARCHAR(100)
);
CREATE TRIGGER trg_MaskData
ON YourTable
AFTER INSERT, UPDATE
AS 
BEGIN
	UPDATE YourTable
	SET [Name] = dbo.MaskData([Name], 0.5)
	WHERE Id IN (SELECT Id FROM inserted);
END;

select * from YourTable

INSERT INTO YourTable (Id, [Name])
VALUES 
    (1, 'HelloWorld'),
    (2, 'TestData');

select * from YourTable


















--CREATE OR ALTER PROCEDURE ToggleMasking
--    @TableName NVARCHAR(128),        
--    @ColumnName NVARCHAR(128),       
--    @MaskEnabled BIT                 
--AS
--BEGIN
--    DECLARE @SQL NVARCHAR(MAX);

--    IF @MaskEnabled = 1
--    BEGIN
--        -- Включаем маскирование в представлении
--        SET @SQL = '
--        CREATE OR ALTER VIEW MaskedView AS
--        SELECT 
--            Id,
--            dbo.MaskData(' + QUOTENAME(@ColumnName) + ', 0.5) AS Masked' + @ColumnName + '
--        FROM 
--            ' + QUOTENAME(@TableName) + ';
--        ';
--    END
--    ELSE
--    BEGIN
--        -- Отключаем маскирование в представлении
--        SET @SQL = '
--        CREATE OR ALTER VIEW MaskedView AS
--        SELECT 
--            Id,
--            ' + QUOTENAME(@ColumnName) + '
--        FROM 
--            ' + QUOTENAME(@TableName) + ';
--        ';
--    END

--    EXEC sp_executesql @SQL;
--END;


--EXEC ToggleMasking @TableName = 'YourTable', @ColumnName = 'Name', @MaskEnabled = 1;
--SELECT * FROM MaskedView;


--EXEC ToggleMasking @TableName = 'YourTable', @ColumnName = 'Name', @MaskEnabled = 0;
--SELECT * FROM MaskedView;