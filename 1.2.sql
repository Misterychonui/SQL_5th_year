--Написать хранимую процедуру, которая для указанного объекта, заданного именем и схемой, вернет все его свойства. 
--В качестве объекта может выступать таблица, представление, ограничение, функция, процедура или триггер.
-- В зависимости от типа объекта свойства могут быть разными. Например, для таблицы это информация о столбцах, ограничениях, триггерах, количестве строк и объектах на неё ссылающихся. 
-- Для хранимой процедуры информация о параметрах и зависимостях, тексте, владельце.
--Как отдельные элементы вывести все привилегии и запреты на данный объект, дату создания и дату последней модификации.

CREATE OR ALTER PROCEDURE GetObjectProperties
    @SchemaName NVARCHAR(128),
    @ObjectName NVARCHAR(128)
AS
BEGIN
    DECLARE @ObjectType NVARCHAR(128);
    DECLARE @ObjectID INT;

    -- Определяем тип объекта и его ID
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

    -- Если объект не найден
    IF @ObjectID IS NULL
    BEGIN
        PRINT 'Объект не найден.';
        RETURN;
    END;

    -- Выводим общую информацию об объекте
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

    -- Выводим свойства в зависимости от типа объекта
    IF @ObjectType IN ('U', 'V') -- Таблица или представление
    BEGIN
        -- Информация о столбцах
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

        -- Информация о первичных ключах и уникальных ограничениях
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

        -- Информация о триггерах
        SELECT 
            tr.name AS TriggerName,
            tr.is_disabled AS IsDisabled
        FROM 
            sys.triggers tr
        WHERE 
            tr.parent_id = @ObjectID;

        -- Информация о зависимостях
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

    IF @ObjectType = 'P' -- Хранимая процедура
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

        -- Информация о зависимостях
        SELECT 
            o.name AS ReferencedObject,
            o.type_desc AS ReferencedObjectType
        FROM 
            sys.sql_expression_dependencies d
        JOIN 
            sys.objects o ON d.referenced_id = o.object_id
        WHERE 
            d.referencing_id = @ObjectID;

        -- Текст процедуры
        SELECT 
            m.definition AS ProcedureDefinition
        FROM 
            sys.sql_modules m
        WHERE 
            m.object_id = @ObjectID;
    END;

    IF @ObjectType = 'FN' OR @ObjectType = 'TF' -- Функция
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

        -- Текст функции
        SELECT 
            m.definition AS FunctionDefinition
        FROM 
            sys.sql_modules m
        WHERE 
            m.object_id = @ObjectID;
    END;

    IF @ObjectType = 'TR' -- Триггер
    BEGIN
        -- Текст триггера
        SELECT 
            m.definition AS TriggerDefinition
        FROM 
            sys.sql_modules m
        WHERE 
            m.object_id = @ObjectID;
    END;

    -- Выводим привилегии и запреты
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
-- Пример для таблицы
EXEC GetObjectProperties @SchemaName = 'dbo', @ObjectName = 'YourTable';

-- Пример для хранимой процедуры
EXEC GetObjectProperties @SchemaName = 'dbo', @ObjectName = 'GetObjectProperties';

EXEC GetObjectProperties @SchemaName = 'dbo', @ObjectName = 'Category Sales for 1997';