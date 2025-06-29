GO
CREATE OR ALTER VIEW Backups AS
SELECT bs.backup_set_id, bs.database_name, bs.type, bs.position, bs.backup_start_date, 
bs.backup_finish_date, bmf.physical_device_name backup_file
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE bmf.physical_device_name = 'C:\Users\Misterychonui\Desktop\Diff_backup\Backup_database.bak'
AND bs.database_name = 'Backup_database'
GO

SELECT * FROM Backups;


DROP DATABASE IF EXISTS Backup_database;
GO
USE master
GO


DECLARE @FullPos INT;
-- Последняя полная копия
SELECT TOP 1 @FullPos = position
FROM LastBackups
WHERE [type] = 'D'
ORDER BY backup_start_date DESC;

IF @FullPos IS NOT NULL
BEGIN
	RESTORE DATABASE Backup_database_New
	FROM DISK = 'C:\Users\Misterychonui\Desktop\Diff_backup\Backup_database.bak'
	WITH FILE = @FullPos,
	MOVE 'Backup_database' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Backup_database.mdf',
	MOVE 'Backup_database_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Backup_database_log.ldf',
	NORECOVERY, REPLACE;
END

DECLARE @DiffPos INT;
-- Последняя дифференциальная копия после полной
SELECT TOP 1 @DiffPos = position
FROM LastBackups
WHERE [type] = 'I'
  AND backup_start_date > (
      SELECT MAX(backup_start_date)
      FROM LastBackups
      WHERE [type] = 'D'
  )
ORDER BY backup_start_date DESC;

IF @DiffPos IS NOT NULL
BEGIN
	RESTORE DATABASE Backup_database_New
	FROM DISK = 'C:\Users\Misterychonui\Desktop\Diff_backup\Backup_database.bak'
	WITH FILE = @DiffPos,
	RECOVERY;
END;