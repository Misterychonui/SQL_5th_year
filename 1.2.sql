--�������� �������� ���������, ������� ��� ���������� �������, ��������� ������ � ������, ������ ��� ��� ��������. 
--� �������� ������� ����� ��������� �������, �������������, �����������, �������, ��������� ��� �������.
-- � ����������� �� ���� ������� �������� ����� ���� �������. ��������, ��� ������� ��� ���������� � ��������, ������������, ���������, ���������� ����� � �������� �� �� �����������. 
-- ��� �������� ��������� ���������� � ���������� � ������������, ������, ���������.
--��� ��������� �������� ������� ��� ���������� � ������� �� ������ ������, ���� �������� � ���� ��������� �����������.

CREATE OR ALTER PROCEDURE GetObjectProperties
    @SchemaName NVARCHAR(128),
    @ObjectName NVARCHAR(128)
AS
BEGIN
    DECLARE @ObjectType NVARCHAR(128);
    DECLARE @ObjectID INT;

    -- ���������� ��� ������� � ��� ID
    SELECT 
        @ObjectType = o.type,
        @ObjectID = o.object_id
    FROM 
        sys.objects o
    JOIN 
        sys.schemas s ON o.schema_id = s.schema_id
    WHERE 
        o.name = @ObjectName 
        AND s.name = @SchemaName;

    -- ���� ������ �� ������
    IF @ObjectID IS NULL
    BEGIN
        PRINT '������ �� ������.';
        RETURN;
    END;

    -- ������� ����� ���������� �� �������
    SELECT 
        o.name AS ObjectName,
        s.name AS SchemaName,
        o.type_desc AS ObjectType,
        o.create_date AS CreateDate,
        o.modify_date AS LastModifiedDate
    FROM 
        sys.objects o
    JOIN 
        sys.schemas s ON o.schema_id = s.schema_id
    WHERE 
        o.object_id = @ObjectID;

    -- ������� �������� � ����������� �� ���� �������
    IF @ObjectType IN ('U', 'V') -- ������� ��� �������������
    BEGIN
        -- ���������� � ��������
        SELECT 
            c.name AS ColumnName,
            t.name AS DataType,
            c.max_length AS MaxLength,
            c.is_nullable AS IsNullable,
            c.is_identity AS IsIdentity
        FROM 
            sys.columns c
        JOIN 
            sys.types t ON c.user_type_id = t.user_type_id
        WHERE 
            c.object_id = @ObjectID;

        -- ���������� � ��������� ������ � ���������� ������������
        SELECT 
            i.name AS IndexName,
            i.type_desc AS IndexType,
            c.name AS ColumnName
        FROM 
            sys.indexes i
        JOIN 
            sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN 
            sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE 
            i.object_id = @ObjectID 
            AND i.is_primary_key = 1;

        -- ���������� � ���������
        SELECT 
            tr.name AS TriggerName,
            tr.is_disabled AS IsDisabled
        FROM 
            sys.triggers tr
        WHERE 
            tr.parent_id = @ObjectID;

        -- ���������� � ������������
        SELECT 
            o.name AS ReferencedObject,
            o.type_desc AS ReferencedObjectType
        FROM 
            sys.sql_expression_dependencies d
        JOIN 
            sys.objects o ON d.referenced_id = o.object_id
        WHERE 
            d.referencing_id = @ObjectID;
    END;

    IF @ObjectType = 'P' -- �������� ���������
    BEGIN
        SELECT 
            p.name AS ParameterName,
            t.name AS DataType,
            p.max_length AS MaxLength,
            p.is_output AS IsOutput
        FROM 
            sys.parameters p
        JOIN 
            sys.types t ON p.user_type_id = t.user_type_id
        WHERE 
            p.object_id = @ObjectID;

        -- ���������� � ������������
        SELECT 
            o.name AS ReferencedObject,
            o.type_desc AS ReferencedObjectType
        FROM 
            sys.sql_expression_dependencies d
        JOIN 
            sys.objects o ON d.referenced_id = o.object_id
        WHERE 
            d.referencing_id = @ObjectID;

        -- ����� ���������
        SELECT 
            m.definition AS ProcedureDefinition
        FROM 
            sys.sql_modules m
        WHERE 
            m.object_id = @ObjectID;
    END;

    IF @ObjectType = 'FN' OR @ObjectType = 'TF' -- �������
    BEGIN
        SELECT 
            p.name AS ParameterName,
            t.name AS DataType,
            p.max_length AS MaxLength,
            p.is_output AS IsOutput
        FROM 
            sys.parameters p
        JOIN 
            sys.types t ON p.user_type_id = t.user_type_id
        WHERE 
            p.object_id = @ObjectID;

        -- ����� �������
        SELECT 
            m.definition AS FunctionDefinition
        FROM 
            sys.sql_modules m
        WHERE 
            m.object_id = @ObjectID;
    END;

    IF @ObjectType = 'TR' -- �������
    BEGIN
        -- ����� ��������
        SELECT 
            m.definition AS TriggerDefinition
        FROM 
            sys.sql_modules m
        WHERE 
            m.object_id = @ObjectID;
    END;

    -- ������� ���������� � �������
    SELECT 
        grantee_principal.name AS Grantee,
        permission_name AS Permission,
        state_desc AS PermissionState
    FROM 
        sys.database_permissions perm
    JOIN 
        sys.database_principals grantee_principal ON perm.grantee_principal_id = grantee_principal.principal_id
    WHERE 
        perm.major_id = @ObjectID;
END;

grant select, insert ON YourTable to public 
-- ������ ��� �������
EXEC GetObjectProperties @SchemaName = 'dbo', @ObjectName = 'YourTable';

-- ������ ��� �������� ���������
EXEC GetObjectProperties @SchemaName = 'dbo', @ObjectName = 'GetObjectProperties';

EXEC GetObjectProperties @SchemaName = 'dbo', @ObjectName = 'Category Sales for 1997';