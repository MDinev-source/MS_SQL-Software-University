CREATE DATABASE TripService

USE TripService

--01. Database Design
CREATE TABLE Cities
(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(20) NOT NULL,
CountryCode CHAR(2) NOT NULL
)

CREATE TABLE Hotels
(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(30) NOT NULL,
CityId INT FOREIGN KEY REFERENCES Cities(Id) NOT NULL,
EmployeeCount INT NOT NULL,
BaseRate DECIMAL(5,2) NOT NULL
)

CREATE TABLE Rooms
(
Id INT PRIMARY KEY IDENTITY,
Price DECIMAL (5,2) NOT NULL,
[Type] NVARCHAR(20) NOT NULL,
Beds INT NOT NULL,
HotelId INT FOREIGN KEY REFERENCES Hotels(Id) NOT NULL
)


CREATE TABLE Trips
(
Id INT PRIMARY KEY IDENTITY,
RoomId INT FOREIGN KEY REFERENCES Rooms(Id) NOT NULL,
BookDate DATE NOT NULL,
ArrivalDate DATE NOT NULL,
ReturnDate DATE NOT NULL,
CancelDate DATE,
CONSTRAINT CHK_BookDate CHECK (BookDate<ArrivalDate),
CONSTRAINT CHK_ArrivalDate CHECK (ArrivalDate<ReturnDate)
)

CREATE TABLE Accounts
(
Id INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(50) NOT NULL,
MiddleName NVARCHAR(20),
LastName NVARCHAR(50) NOT NULL,
CityId INT FOREIGN KEY REFERENCES Cities(Id) NOT NULL,
BirthDate DATE NOT NULL,
Email VARCHAR(100) NOT NULL UNIQUE
)

CREATE TABLE AccountsTrips
(
AccountId INT FOREIGN KEY REFERENCES Accounts(Id) NOT NULL,
TripId INT FOREIGN KEY REFERENCES Trips(Id) NOT NULL,
Luggage INT NOT NULL,
CONSTRAINT CHK_Luggage CHECK (Luggage>=0),
CONSTRAINT PK_Account_Trip PRIMARY KEY (AccountId, TripId)
)

--02. Insert
INSERT INTO Accounts (FirstName, MiddleName, LastName, CityId, BirthDate, Email) VALUES
('John', 'Smith', 'Smith', 34 , '1975-07-21', 'j_smith@gmail.com'),
('Gosho', NULL, 'Petrov', 11 , '1978-05-16', 'g_petrov@gmail.com'),
('Ivan', 'Petrovich', 'Pavlov', 59 , '1849-09-26', 'i_pavlov@softuni.bg'),
('Friedrich', 'Wilhelm', 'Nietzsche', 2 , '1844-10-15', 'f_nietzsche@softuni.bg')

INSERT INTO Trips (RoomId, BookDate, ArrivalDate, ReturnDate, CancelDate) VALUES
(101, '2015-04-12', '2015-04-14', '2015-04-20', '2015-02-02'),
(102, '2015-07-07', '2015-07-15', '2015-07-22', '2015-04-29'),
(103, '2013-07-17', '2013-07-23', '2013-07-24', NULL),
(104, '2012-03-17', '2012-03-31', '2012-04-01', '2012-01-10'),
(109, '2017-08-07', '2017-08-28', '2017-08-29', NULL)

--03. Update
UPDATE Rooms
SET Price*=1.14
WHERE HotelId IN (5,7,9)

--04. DELETE
DELETE 
FROM AccountsTrips
WHERE AccountId = 47

--05. EEE-Mails
SELECT * FROM (SELECT a.FirstName, a.LastName,FORMAT (a.BirthDate, 'MM-dd-yyyy') AS Birthdate , c.[Name] AS Hometown, a.Email 
FROM Accounts AS a
JOIN Cities AS c
ON c.Id=a.CityId) AS c
WHERE c.Email LIKE 'e%'
ORDER BY c.Hometown


--06. City Statistics
SELECT c.[Name] AS City, COUNT(h.Id) AS Hotels
FROM Cities AS c
JOIN Hotels AS h
ON h.CityId=c.Id
GROUP BY c.[Name]
ORDER BY Hotels DESC, City

--07. Longest and Shortest Trips
SELECT a.Id AS AccountId, CONCAT(a.FirstName, ' ', a.LastName) AS FullName, MAX(DATEDIFF(DAY, t.ArrivalDate, t.ReturnDate)) AS LongestTrip, 
    MIN(DATEDIFF(DAY, t.ArrivalDate, t.ReturnDate)) AS ShortestTrip
        FROM Trips AS t
        JOIN AccountsTrips AS [at] ON t.Id = [at].TripId
        LEFT JOIN Accounts AS a ON [at].AccountId = a.Id
        WHERE a.MiddleName IS NULL AND t.CancelDate IS NULL
        GROUP BY a.Id, a.FirstName, a.LastName
        ORDER BY LongestTrip DESC,
                    ShortestTrip ASC


--08. Metropolis
SELECT TOP (10) c.Id, c.[Name] AS City, c.CountryCode AS Country, COUNT(a.CityId) AS Accounts
FROM Cities AS c
JOIN Accounts AS a
ON a.CityId=c.Id
GROUP BY c.Id, c.[Name], c.CountryCode
ORDER BY Accounts DESC


--09. Romantic Getaways
SELECT a.Id, a.Email, a.City, a.Trips
FROM
(
SELECT a.Id,a.Email,c.[Name] AS City , COUNT(ac.TripId) AS Trips
FROM Accounts AS a
JOIN AccountsTrips AS ac
ON a.Id = ac.AccountId
JOIN Cities AS c
ON c.Id= a.CityId
GROUP BY a.Id, a.Email, c.[Name]
) AS a
WHERE a.Trips IS NOT NULL
ORDER BY a.Trips, a.Id

--10. GDPR VIolation
SELECT t.Id, a.FirstName + ' ' + ISNULL(a.MiddleName + ' ', '') + a.LastName AS FullName, c.[Name] AS Hometown,
    ca.[Name] AS [To], 
    CASE 
        WHEN t.CancelDate IS NULL THEN CONCAT(DATEDIFF(DAY, t.ArrivalDate,t.ReturnDate),' ', 'days')
        ELSE 'Canceled'
        END AS Duration
        FROM AccountsTrips AS [at]
            JOIN Accounts AS a ON a.Id = [at].AccountId
            JOIN Trips AS t ON t.Id = [at].TripId
            JOIN Cities AS c ON a.CityId = c.Id
            JOIN Rooms AS r ON t.RoomId = r.Id
            JOIN Hotels AS h ON r.HotelId = h.Id
            JOIN Cities AS ca ON h.CityId = ca.Id
            ORDER BY FullName ASC,
                t.Id ASC


--11. Available Room
GO
CREATE FUNCTION udf_GetAvailableRoom(@HotelId INT, @Date DATE, @People INT)
RETURNS VARCHAR(MAX)
AS 
BEGIN 
    DECLARE @RoomsBooked TABLE (Id INT)
    INSERT INTO @RoomsBooked
        SELECT  r.Id 
        FROM Rooms AS r
      JOIN Trips AS t ON t.RoomId = r.Id
        WHERE r.HotelId = @HotelId AND @Date BETWEEN t.ArrivalDate AND t.ReturnDate AND t.CancelDate IS NULL
 
    DECLARE @Rooms TABLE (Id INT, Price DECIMAL(15,2), [Type] VARCHAR(20), Beds INT, TotalPrice DECIMAL(15,2))
    INSERT INTO @Rooms
        SELECT TOP(1) r.Id, r.Price, r.[Type], r.Beds, ((h.BaseRate + r.Price) * @People) AS TotalPrice
        FROM Rooms AS r
        JOIN Hotels AS h ON r.HotelId = h.Id
        WHERE r.HotelId = @HotelId AND r.Beds >= @People AND r.Id NOT IN (SELECT Id 
                                                                            FROM @RoomsBooked)
        ORDER BY TotalPrice DESC
 
    DECLARE @RoomCount INT = (SELECT COUNT(*)  FROM @Rooms)
    IF (@RoomCount < 1)
        BEGIN
            RETURN 'No rooms available'
        END
 
    DECLARE @Result VARCHAR(MAX) = (SELECT CONCAT('Room ', Id, ': ', [Type],' (', Beds, ' beds',')', ' - ', '$', TotalPrice)
                                        FROM @Rooms)
    RETURN @Result
END
GO

--12. Switch Room
CREATE PROCEDURE usp_SwitchRoom(@TripId int, @TargetRoomId int)
AS
        DECLARE @SourceHotelId INT = (SELECT h.Id
                                        FROM Hotels AS h
                                        JOIN Rooms AS r ON r.HotelId = h.Id
                                        JOIN Trips AS t ON t.RoomId = r.Id
                                        WHERE t.Id = @TripId)
 
        DECLARE @TargetHotelId INT = (SELECT h.Id
                                        FROM Hotels AS h
                                        JOIN Rooms AS r ON h.Id = r.HotelId
                                        WHERE r.Id = @targetRoomId)
 
        IF (@SourceHotelId <> @TargetHotelId)
            THROW 50001, 'Target room is in another hotel!', 1
 
        DECLARE @PeopeCount INT = (SELECT COUNT(*)
                                    FROM AccountsTrips
                                    WHERE TripId = @TripId)
        DECLARE @TargetRoomBeds INT = (SELECT Beds
                                        FROM Rooms
                                        WHERE Id = @TargetRoomId)
        IF (@PeopeCount > @TargetRoomBeds)
            THROW 50002, 'Not enough beds in target room!', 1
 
        UPDATE Trips
        SET RoomId = @TargetRoomId
        WHERE Id = @TripId
GO