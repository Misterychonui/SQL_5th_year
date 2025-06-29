--�������� ��������� �������� ������ ������� � �� (������������� ��� �������) �� ������ ������������ �������.
--��� ������ ������� ������ �������� ����������� � ���������� �� ������������� � ������� ������. 
--������� ��������� � ��� ������ �������, �������� �������, ������� � ���������� �����, ������� ����� �������������� � �������. 

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

    -- ��������� ��� ������ �������
    SET @NewObjectName = 'NEW_' + @SourceTable + '_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');

    -- ��������� ������������� �������� � �������� �������
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

    -- ��������� ��������� ������� � ������
    IF @ColumnExists = 1 AND LEN(@ColumnList) > 0
    BEGIN
        SET @Column = LTRIM(RTRIM(@ColumnList));
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @SourceTable AND COLUMN_NAME = @Column)
        BEGIN
            SET @ColumnExists = 0;
        END
    END

    -- ���� ���� �� ���� ������� �� ����������, ������ ������
    IF @ColumnExists = 0
    BEGIN
        RAISERROR('���� ��� ��������� ��������� �������� �� ���������� � ������� %s.', 16, 1, @SourceTable);
        RETURN;
    END

    -- ��������� SQL-������ ��� �������� ������ �������
    IF @ObjectType = 'TABLE'
    BEGIN
        SET @SQLQuery = 'SELECT TOP (' + CAST(@RowCount AS NVARCHAR) + ') ' + @Columns + ' INTO ' + @NewObjectName + ' FROM ' + @SourceTable;
    END
    ELSE IF @ObjectType = 'VIEW'
    BEGIN
        SET @SQLQuery = 'CREATE VIEW ' + @NewObjectName + ' AS SELECT TOP (' + CAST(@RowCount AS NVARCHAR) + ') ' + @Columns + ' FROM ' + @SourceTable;
    END

    EXEC sp_executesql @SQLQuery;

    PRINT '������ ' + @NewObjectName + ' ������� ������.';
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