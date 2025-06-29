use painting_Sych;
GO

CREATE TABLE Squares (
    Id INT PRIMARY KEY NOT NULL,         
    [Name] NVARCHAR(50) NOT NULL          
) AS NODE;                                
GO

CREATE TABLE Baloons (
    Id INT PRIMARY KEY NOT NULL,          
    [Name] VARCHAR(50) NOT NULL,          
    Color CHAR(1) NOT NULL                
) AS NODE;                               
GO


CREATE TABLE Paints (
    Volume INT NOT NULL,                  
    Paint_Time DATETIME NOT NULL          
) AS EDGE;                                
GO

/* ��������� ������� ������� */

INSERT INTO Squares
SELECT * FROM utQ;

INSERT INTO Baloons
SELECT * FROM utV;

INSERT INTO Paints
SELECT 
    s.$node_id AS Square_ID,              
    b.$node_id AS Baloon_ID,              
    p.B_VOL AS Volume,                    
    p.B_DATETIME AS Paint_Time            
FROM utB AS p 
JOIN Squares AS s ON p.B_Q_ID = s.Id     
JOIN Baloons AS b ON p.B_V_ID = b.Id;     

-----------------------------------------------------------------------------------
/* ������� */

-- 1. ����� ��������, ������� ������������ ������� �������. ������� ������������� �������� � ����� ������� ������.
SELECT 
    s.Id,                                
    SUM(p.Volume) AS 'Quantity'           
FROM 
    Squares s, Paints p, Baloons b
WHERE 
    MATCH(s-(p)->b) AND b.Color = 'R'     
GROUP BY 
    s.Id;

-- 2. ����� ��������, ������� ������������ ��� �������, ��� � ����� �������. �������: �������� ��������.
SELECT 
    s.[Name]                              
FROM 
    Squares s, Paints p, Baloons b
WHERE 
    MATCH(s-(p)->b) AND (b.Color = 'R' OR b.Color = 'B') 
GROUP BY 
    s.[Name]
HAVING 
    COUNT(DISTINCT b.Color) = 2;          

-- 3. ����� ��������, ������� ������������ ����� ����� �������.
SELECT 
    s.[Name]                              
FROM 
    Squares s, Paints p, Baloons b
WHERE 
    MATCH(s-(p)->b) AND (b.Color = 'R' OR b.Color = 'B' OR b.Color = 'G') 
GROUP BY 
    s.[Name]
HAVING 
    COUNT(DISTINCT b.Color) = 3;          

-- 4. ����� ����������, �������� ���������� ����� ������ ��������.
SELECT 
    b.[Name]                              
FROM 
    Squares s, Paints p, Baloons b
WHERE 
    MATCH(s-(p)->b)                       
GROUP BY 
    b.[Name]
HAVING 
    COUNT(DISTINCT s.Id) > 1;            

-----------------------------------------------------------------------------------
/* ���� ������� */
-- 5. �������, ������ ������������ ��� ������� ������ �������.
SELECT 
    Square_Name, 
    STRING_AGG(Baloon_Name, ', ') AS Baloons
FROM (
    SELECT 
        s.[Name] AS Square_Name,          
        b.[Name] AS Baloon_Name           
    FROM 
        Squares AS s, Paints AS p, Baloons AS b
    WHERE 
        MATCH(s-(p)->b)                   
) AS Table1
GROUP BY 
    Square_Name;

-- 6. ����� �������� ������ ����� (����� ������ �������, ������� � ����� ������ �����).
SELECT 
    [Name]                               
FROM (
    SELECT 
        [Name], 
        SUM(CASE WHEN Color = 'R' THEN Volume ELSE 0 END) AS Red,    
        SUM(CASE WHEN Color = 'G' THEN Volume ELSE 0 END) AS Green,   
        SUM(CASE WHEN Color = 'B' THEN Volume ELSE 0 END) AS Blue    
    FROM (
        SELECT 
            s.[Name], b.Color, p.Volume
        FROM 
            Squares AS s, Paints AS p, Baloons AS b
        WHERE 
            MATCH(s-(p)->b)               
    ) AS Table1
    GROUP BY 
        [Name]
) AS Table2
WHERE 
    Red = Green AND Green = Blue;         