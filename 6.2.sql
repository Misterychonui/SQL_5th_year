CREATE DATABASE LogonAudit

CREATE TABLE LogonAuditing
(
	SessionID int,
	LogonTime datetime,
	LoginName varchar(50),
	HostName varchar(50)
)

CREATE LOGIN TestAdmin With Password = 'Qwerty12345';

CREATE USER TestAdmin FOR Login TestAdmin;

GRANT INSERT ON [dbo].[LogonAuditing] to TestAdmin;

Alter TRIGGER LogonAuditTrigger
 ON ALL SERVER
 FOR LOGON
 AS
 BEGIN
 DECLARE 
 @HostName NVARCHAR(256), 
 @LogonTriggerData xml,
 @EventTime datetime,
 @LoginName varchar(50),
 @IsAllowed bit,
 @CurrentTime TIME,
 @CurrentDay INT;

 set @HostName = HOST_NAME(); 
 set @IsAllowed = 0;
 set @CurrentDay = DATEPART(WEEKDAY, GETDATE());
 set @CurrentTime = CONVERT(TIME, GETDATE());
 set @LogonTriggerData = eventdata()
 set @EventTime = @LogonTriggerData.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime')
 set @LoginName = @LogonTriggerData.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(50)')

 IF @LoginName <> 'TestAdmin'
    BEGIN
        RETURN; 
    END
  -- Проверка условия подключения для пользователя TestAdmin
  IF @LoginName = 'TestAdmin' 
  BEGIN
	IF @CurrentDay = 6 AND @HostName = 'Misterychonui' AND @CurrentTime BETWEEN '10:45:00' AND '20:00:00'
		BEGIN
			SET @IsAllowed = 1;
        END
  END  
  IF @IsAllowed = 0
  BEGIN
  	rollback;
  BEGIN TRY
    INSERT INTO [LogonAudit].[dbo].[LogonAuditing]
      (SessionId,LogonTime,LoginName, HostName)
    SELECT @@spid, @EventTime, COALESCE(@LoginName, SYSTEM_USER),@HostName ;
   END TRY
   BEGIN CATCH
    PRINT 'Error logging failed';
   END CATCH
  END 
  END

  select * from [dbo].[LogonAuditing]
  revert;


 declare @CurrentDay INT;
 set @CurrentDay = DATEPART(WEEKDAY, GETDATE());
 select @CurrentDay

  declare @CurrentTime TIME;
 set @CurrentTime = CONVERT(TIME, GETDATE());
 select @CurrentTime

 select host_name();