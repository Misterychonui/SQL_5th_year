CREATE DATABASE PersonalDataDB_SYCH;
GO
USE PersonalDataDB_SYCH;
GO
CREATE TABLE Persons (
    PersonID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    DateOfBirth DATE,
    Email NVARCHAR(100)
);
GO
CREATE TABLE Addresses (
    AddressID INT PRIMARY KEY IDENTITY(1,1),
    PersonID INT,
    Street NVARCHAR(100),
    City NVARCHAR(50),
    State NVARCHAR(50),
    ZipCode NVARCHAR(10),
    FOREIGN KEY (PersonID) REFERENCES Persons(PersonID)
);
GO
INSERT INTO Persons (FirstName, LastName, DateOfBirth, Email) VALUES
('John', 'Doe', '1985-05-15', 'john.doe@example.com'),
('Jane', 'Smith', '1990-03-22', 'jane.smith@example.com'),
('Alice', 'Johnson', '1988-07-30', 'alice.johnson@example.com'),
('Bob', 'Brown', '1975-12-01', 'bob.brown@example.com'),
('Charlie', 'Davis', '1995-02-14', 'charlie.davis@example.com'),
('Diana', 'Wilson', '1982-09-10', 'diana.wilson@example.com'),
('Edward', 'Taylor', '1993-11-25', 'edward.taylor@example.com'),
('Fiona', 'Moore', '1980-06-18', 'fiona.moore@example.com'),
('George', 'Anderson', '1978-04-05', 'george.anderson@example.com'),
('Hannah', 'Thomas', '1992-08-12', 'hannah.thomas@example.com');
GO
INSERT INTO Addresses (PersonID, Street, City, State, ZipCode) VALUES
(1, '123 Elm St', 'Springfield', 'IL', '62701'),
(2, '456 Oak St', 'Springfield', 'IL', '62702'),
(3, '789 Pine St', 'Chicago', 'IL', '60601'),
(4, '321 Maple St', 'Peoria', 'IL', '61602'),
(5, '654 Cedar St', 'Naperville', 'IL', '60540'),
(6, '987 Birch St', 'Aurora', 'IL', '60505'),
(7, '135 Willow St', 'Rockford', 'IL', '61101'),
(8, '246 Walnut St', 'Joliet', 'IL', '60431'),
(9, '357 Chestnut St', 'Champaign', 'IL', '61820'),
(10, '468 Spruce St', 'Bloomington', 'IL', '61701');
GO
SELECT * FROM Persons;
GO
SELECT * FROM Addresses;
GO
-------------------------------------------------------------------------------

create role Operator
create role Registrar
create role Chief

create login op_User1 with password = 'Admin12345';
create login op_User2 with password = 'Admin12345';
create login op_User3 with password = 'Admin12345';
create login reg_User1 with password = 'Admin12345';
create login reg_User2 with password = 'Admin12345';
create login reg_User3 with password = 'Admin12345';
create login ch_User1 with password = 'Admin12345';
create login ch_User2 with password = 'Admin12345';
create login ch_User3 with password = 'Admin12345';

create user op_User1 for login op_User1;
create user op_User2 for login op_User2;
create user op_User3 for login op_User3;
create user reg_User1 for login reg_User1;
create user reg_User2 for login reg_User2;
create user reg_User3 for login reg_User3;
create user ch_User1 for login ch_User1;
create user ch_User2 for login ch_User2;
create user ch_User3 for login ch_User3;

alter role Operator add member op_User1
alter role Operator add member op_User2
alter role Operator add member op_User3
alter role Registrar add member reg_User1
alter role Registrar add member reg_User2
alter role Registrar add member reg_User3
alter role Chief add member ch_User1
alter role Chief add member ch_User2
alter role Chief add member ch_User3
------------------------------------------------------
--TDE
use master;
go
create master key encryption by password = 'VeryStrongPassword12345';
go
create certificate CertTDE_Sych with subject = 'Certificate for PersonalDataDB_SYCH';
go
use PersonalDataDB_SYCH;
go
create database encryption key with algorithm = aes_256
encryption by server certificate  CertTDE_Sych;
go
alter database PersonalDataDB_SYCH
	set encryption off;
go

select * from sys.dm_database_encryption_keys
--------------------------------------------------------------------------------------

/*CLE*/
--?	CLE шифрование с использованием парольной фразы
alter table Addresses add EncryptedCity varbinary(max)

select * from Addresses

create or alter procedure EncryptCityData
as
begin
	declare @EncrPhrase nvarchar(128) = '123qwerty123'
	update Addresses set EncryptedCity = ENCRYPTBYPASSPHRASE(@EncrPhrase, City)
end;

exec EncryptCityData

create or alter procedure DecryptCityData
as
begin
	if (CURRENT_USER = 'op_User1' or CURRENT_USER = 'op_User2' or CURRENT_USER = 'op_User3')
	begin
		declare @EncrPhrase nvarchar(128) = '123qwerty123'
		declare @DecryptCity nvarchar(100)
		declare @Id_Address int
		declare [cursor] cursor
		for
		select AddressID, convert(nvarchar(100), DECRYPTBYPASSPHRASE(@EncrPhrase, EncryptedCity))
		from Addresses

		open [cursor]
		fetch next from [cursor] into @Id_Address, @DecryptCity

		while @@FETCH_STATUS = 0
		begin
			print cast(@Id_Address as nvarchar) + ' - ' + @DecryptCity
			fetch next from [cursor] into @Id_Address, @DecryptCity
		end
		close [cursor]
		deallocate [cursor]
	end
	else
	begin
		print 'У вас нет прав'
	end
end

grant exec on DecryptCityData to Operator

grant select (AddressID, PersonID, Street, [State], ZipCode, EncryptedCity) on Addresses to Registrar, Chief, Operator

/*Проверим*/
execute as user = 'op_User1'
select * from Addresses
exec DecryptCityData
revert

execute as user = 'reg_User1'
select AddressID, PersonID, Street, [State], ZipCode, EncryptedCity from Addresses
revert
-------------------------------------------------------------------------------------
--?	CLE шифрование с использованием асимметричного ключа
create master key encryption by password = 'VeryStrongPassword12345'
create asymmetric key AKey with algorithm = rsa_2048

alter table Persons add EncryptedFirstName varbinary(max)

update Persons set EncryptedFirstName = ENCRYPTBYASYMKEY(ASYMKEY_ID('AKey'), FirstName)

create or alter procedure DecryptFirstName
as
begin 
	if (CURRENT_USER = 'ch_User1' or CURRENT_USER = 'ch_User2' or CURRENT_USER = 'ch_User3')
	begin 
		declare @DecrFirstName nvarchar(80)
		declare @PersonId int
		declare [cursor] cursor
		for
		select PersonID, convert(nvarchar(80), DECRYPTBYASYMKEY(ASYMKEY_ID('AKey'), EncryptedFirstName))
		from Persons

		open [cursor]
		fetch next from [cursor] into @PersonId, @DecrFirstName
		while @@FETCH_STATUS = 0
		begin
			print cast(@PersonId as nvarchar) + ' - ' + @DecrFirstName
			fetch next from [cursor] into @PersonId, @DecrFirstName
		end

		close [cursor]
		deallocate [cursor]
	end
	else 
	begin
		print 'У Вас нет прав'
	end
end

grant exec on DecryptFirstName to Chief
grant select (PersonID, LastName, DateOfBirth, Email, EncryptedFirstName) on Persons to Registrar, Chief, Operator;
grant update on Persons to Chief
grant control on asymmetric key::AKey to Chief

/*Проверим*/
execute as user = 'ch_User1'
select * from Persons
exec DecryptFirstName
revert
----------------------------------------------------------------------------------------
--?	CLE шифрование с использованием сертификата 
create certificate CLECert with subject = 'Certificate for LastName PersonalDataDB';

alter table Persons add EncryptedLastName varbinary(max);

update Persons set EncryptedLastName = ENCRYPTBYCERT(CERT_ID('CLECert'), LastName);

create or alter procedure DecryptLastName
as
begin
    if (current_user = 'op_User1' or current_user = 'op_User2' or current_user = 'op_User3') 
    begin
        declare @DecryptLastName nvarchar(50);
        declare @PersonID int;

        declare [cursor] cursor for
        select PersonID, convert(nvarchar(50), DECRYPTBYCERT(CERT_ID('CLECert'), EncryptedLastName))
        from Persons;

        open [cursor];
        fetch next from [cursor] into @PersonID, @DecryptLastName;

        while @@FETCH_STATUS = 0
        begin
            print cast(@PersonID as nvarchar) + ' - ' + @DecryptLastName;
            fetch next from [cursor] into @PersonID, @DecryptLastName;
        end;

        close [cursor];
        deallocate [cursor];
    end
    else
    begin
        print 'У Вас нет прав';
    end
end;

grant execute on DecryptLastName to Operator

grant control on certificate::CLECert to [Operator]

execute as user = 'op_User1';
exec DecryptLastName;
revert;
---------------------------------------------------------------------------------------

select * from Addresses
select * from Persons

--column encryption setting=enabled