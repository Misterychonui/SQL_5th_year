create login TestAdminLogin_Sych with password = 'Admin12345';

create user TestAdmin_Sych for login TestAdminLogin_Sych;

alter role db_datawriter add member TestAdmin_Sych ;
alter role db_datareader add member TestAdmin_Sych ;

drop user TestAdmin_Sych ;

CREATE DATABASE LOGON_DATABASE;
GO
USE LOGON_DATABASE;
GO

create table LogAuditTestAdmin
(
    AuditID int identity(1, 1) primary key,  
    LoginName nvarchar(256),                
    HostName nvarchar(256),                  
    LogDate datetime not null               
);

grant insert on LogAuditTestAdmin to public;

create table Raspisanie
(
    Id int primary key identity,             
    [WeekDay] nvarchar(20) not null,         
    Beginning time not null,                 
    [End] time not null,                     
    Computer nvarchar(100) not null          
);

grant select on Raspisanie to public;

insert into Raspisanie 
values
('Monday', '10:00', '23:00', 'PC402-20');  
-- insert into LogAuditTestAdmin
--values
--(original_login(), host_name(), getdate());
--select * from LogAuditTestAdmin

delete Raspisanie
where Id = 6;

delete LogAuditTestAdmin
where AuditID = 10;

select * from Raspisanie;

--select * 
--from Raspisanie r
--where 'PC402-11' = r.Computer
--and 'Monday' = r.[WeekDay]
--and '10:04:49.4700000' between r.Beginning and r.[End];
select * 
from Raspisanie r
where 'Misterychonui' = r.Computer
and 'воскресенье' = r.[WeekDay]
and '10:04:49.4700000' between r.Beginning and r.[End];

grant insert on LogAuditTestAdmin to TestAdmin_Sych;

select original_login();

select cast(getdate() as time);

select datename(weekday, getdate());

select host_name();

CREATE OR ALTER TRIGGER LoginTestAdmin
ON ALL SERVER FOR LOGON
AS
BEGIN
    DECLARE @LoginName NVARCHAR(256) = ORIGINAL_LOGIN(); 
    DECLARE @HostName NVARCHAR(256) = HOST_NAME(); 
    DECLARE @CurrentTime TIME = CAST(GETDATE() AS TIME); 
    DECLARE @DayOfWeek NVARCHAR(20) = DATENAME(WEEKDAY, GETDATE()); 

    IF @LoginName = 'TestAdminLogin_Sych'
    BEGIN
        IF NOT EXISTS (
            SELECT * 
            FROM Raspisanie r
            WHERE @HostName = r.Computer 
            AND @DayOfWeek = r.[WeekDay] 
            AND @CurrentTime BETWEEN r.Beginning AND r.[End] 
        )
        BEGIN
            INSERT INTO [dbo].[LogAuditTestAdmin] ([LoginName], HostName, [LogDate])
            VALUES (@LoginName, @HostName, GETDATE());


            ROLLBACK;
            PRINT 'Невозможно подключиться. Проверьте расписание занятий и имя компьютера.';
        END
    END
END;

drop trigger LoginTestAdmin on all server;

select * from LogAuditTestAdmin;