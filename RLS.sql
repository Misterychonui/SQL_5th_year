CREATE DATABASE TestRLS2;
GO

USE TestRLS2;
GO

/* ������� � */

-- ������� ������� ��� �������� ������� ������� (����� ������������)
CREATE TABLE Access_Marks_Table (
    access_Level INT PRIMARY KEY,          
    data_mark NVARCHAR(50) NOT NULL       
);

-- ������� ������� ��� �������� ������������� � �� ������� �������
CREATE TABLE users (
    name NVARCHAR(100) PRIMARY KEY,        
    access_Level INT NOT NULL,             
    FOREIGN KEY (access_Level) REFERENCES Access_Marks_Table(access_Level) 
);

-- ������� ������� ��� �������� ������ � ������� ������������
CREATE TABLE SensitiveData (
    id INT PRIMARY KEY,                    
    information NVARCHAR(300) NOT NULL,    
    access_Level INT NOT NULL,             
    FOREIGN KEY (access_Level) REFERENCES Access_Marks_Table(access_Level) 
);

CREATE TABLE Sensitive(
    Id INT PRIMARY KEY,                    
    information NVARCHAR(300) NOT NULL,    
    Level1 INT NOT NULL,             
    FOREIGN KEY (Level1) REFERENCES Access_Marks_Table(access_Level) 
);

/* ��������� ������� */

INSERT INTO Access_Marks_Table (access_Level, data_mark)
VALUES
    (1, 'TOP SECRET'),                     
    (2, 'SECRET'),                         
    (3, 'UNCLASSIFIED'); 

INSERT INTO users (name, access_Level)
VALUES
    ('USER_1', 1),                         
    ('USER_2', 2),                         
    ('USER_3', 3);                         

INSERT INTO SensitiveData (id, information, access_Level)
VALUES
    (1, '������������� ����������', 3),   
    (2, '��������� ����������', 2),       
    (3, '�������������� ����������', 1);   
	
INSERT INTO Sensitive (Id, information, Level1)
VALUES
    (1, '������������� ����������', 3),   
    (2, '��������� ����������', 2),       
    (3, '�������������� ����������', 1); 
SELECT * FROM SensitiveData

-- ������� ������� ��� ���������� ������ �� ������ ������ ������� ������������
CREATE FUNCTION dbo.Access_Level_Filter (@access_Level INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS Access_Allowed
    FROM dbo.users
    WHERE name = CURRENT_USER AND access_Level >= @access_Level -- ������� "No read up"
);

-- ������� �������� ������������ ��� ������� SensitiveData � �������������� ������� ����������
CREATE SECURITY POLICY Access_Level_Security_Policy
ADD FILTER PREDICATE dbo.Access_Level_Filter(access_Level) 
ON dbo.SensitiveData
WITH (STATE = ON, SCHEMABINDING = ON); 

-- ������� �������� ������������ ��� ������� Sensitive � �������������� ������� ����������
CREATE SECURITY POLICY Test_Access_Level_Security_Policy
ADD FILTER PREDICATE dbo.Access_Level_Filter(Level1) 
ON dbo.Sensitive
WITH (STATE = ON, SCHEMABINDING = ON); 

-- ������� ������������� ��� ������ ��� ������������
CREATE USER USER_1 WITHOUT LOGIN;
CREATE USER USER_2 WITHOUT LOGIN;
CREATE USER USER_3 WITHOUT LOGIN;

-- ��������� ������������� ��������������� ������ �������
EXEC sp_addrolemember 'db_datareader', 'USER_1';
EXEC sp_addrolemember 'db_datareader', 'USER_2';
EXEC sp_addrolemember 'db_datareader', 'USER_3';

-- ���� ����� �� ������ ������� SensitiveData �������������
GRANT SELECT ON SensitiveData TO USER_1;
GRANT SELECT ON SensitiveData TO USER_2;
GRANT SELECT ON SensitiveData TO USER_3;

GRANT SELECT ON Sensitive TO USER_1;
GRANT SELECT ON Sensitive TO USER_2;
GRANT SELECT ON Sensitive TO USER_3;


EXECUTE AS USER = 'USER_1';
SELECT * FROM SensitiveData; -- USER_1 ������ ������ ��� ������, ��� ��� ��� ������� ������� 1 (������)
REVERT;

EXECUTE AS USER = 'USER_2';
SELECT * FROM SensitiveData; -- USER_2 ������ ������ ������ � ������� ������� 2 � 3
REVERT;

EXECUTE AS USER = 'USER_3';
SELECT * FROM SensitiveData; -- USER_3 ������ ������ ������ ������ � ������� ������� 3
REVERT;


EXECUTE AS USER = 'USER_1';
SELECT * FROM Sensitive; -- USER_1 ������ ������ ��� ������, ��� ��� ��� ������� ������� 1 (������)
REVERT;

EXECUTE AS USER = 'USER_2';
SELECT * FROM Sensitive; -- USER_2 ������ ������ ������ � ������� ������� 2 � 3
REVERT;

EXECUTE AS USER = 'USER_3';
SELECT * FROM Sensitive; -- USER_3 ������ ������ ������ ������ � ������� ������� 3
REVERT;