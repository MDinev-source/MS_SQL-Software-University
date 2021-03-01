CREATE DATABASE ColonialJourney
USE ColonialJourney

--1. Create Tables
CREATE TABLE Planets
(
Id INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(30) NOT NULL
)

CREATE TABLE Spaceports
(
Id INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(50) NOT NULL,
PlanetId INT FOREIGN KEY REFERENCES Planets(Id) NOT NULL
)

CREATE TABLE Spaceships
(
Id INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(50) NOT NULL,
Manufacturer VARCHAR(30) NOT NULL,
LightSpeedRate INT DEFAULT (0)
)

CREATE TABLE Colonists
(
Id INT PRIMARY KEY IDENTITY,
FirstName VARCHAR(20) NOT NULL,
LastName VARCHAR(20) NOT NULL,
Ucn VARCHAR(10) UNIQUE NOT NULL,
BirthDate DATE NOT NULL
)

CREATE TABLE Journeys
(
Id INT PRIMARY KEY IDENTITY,
JourneyStart DATETIME NOT NULL,
JourneyEnd DATETIME NOT NULL,
Purpose VARCHAR (11) CHECK(Purpose IN ('Medical', 'Technical', 'Educational', 'Military')),
DestinationSpaceportId INT FOREIGN KEY REFERENCES Spaceports(Id) NOT NULL,
SpaceshipId INT FOREIGN KEY REFERENCES Spaceships(Id) NOT NULL
)

CREATE TABLE TravelCards
(
Id INT PRIMARY KEY IDENTITY,
CardNumber CHAR(10) NOT NULL,
JobDuringJourney VARCHAR (8) CHECK(JobDuringJourney IN('Pilot','Engineer','Trooper','Cleaner','Cook')),
ColonistId INT  FOREIGN KEY REFERENCES Colonists(Id) NOT NULL ,
JourneyId INT  FOREIGN KEY REFERENCES Journeys(Id) NOT NULL
)

--2. Insert

INSERT INTO Planets VALUES
('Mars'),
('Earth'),
('Jupiter'),
('Saturn')

INSERT INTO Spaceships VALUES
('Golf', 'VW', 3),
('WakaWaka', 'Wakanda', 4),
('Falcon9', 'SpaceX', 1),
('Bed', 'Vidolov', 6)

--3. Update
UPDATE Spaceships
SET LightSpeedRate+=1
WHERE (Id BETWEEN 8 AND 12)

--4. Delete
DELETE FROM TravelCards 
WHERE JourneyId IN(1,2,3)

DELETE FROM Journeys
WHERE Id IN (1,2,3)

--5. Select all travel cards
SELECT tc.CardNumber, tc.JobDuringJourney
FROM TravelCards AS tc
ORDER BY  tc.CardNumber

--6. Select all colonists
SELECT c.Id, CONCAT (c.FirstName ,' ',c.LastName) AS FullName, c.Ucn 
FROM Colonists AS c
ORDER BY c.FirstName, c.LastName, c.Id

--7. Select all military journeys
SELECT j.Id, CONVERT(varchar, j.JourneyStart, 103) AS JourneyStart, CONVERT(varchar, j.JourneyEnd, 103) AS JourneyEnd 
FROM Journeys AS j
WHERE j.Purpose IN('Military')
ORDER BY j.JourneyStart

--8. Select All Pilots
SELECT c.Id, CONCAT(c.FirstName,' ', c.LastName) AS full_name
FROM Colonists AS c
JOIN TravelCards AS tc 
ON tc.ColonistId=c.Id
WHERE tc.JobDuringJourney='Pilot'
ORDER BY c.Id

--9. Count colonists
SELECT COUNT(c.Id) AS [count]
FROM Colonists AS c
JOIN TravelCards AS tc
ON tc.ColonistId=c.Id
JOIN Journeys AS j
ON j.Id=tc.JourneyId
WHERE j.Purpose='Technical'

--10. Select The Fastest Spaceship
SELECT TOP(1) s.Name AS [SpaceshipName], sp.Name AS [SpaceportName]
FROM Spaceships AS s
JOIN Journeys AS j
ON j.SpaceshipId=s.Id
JOIN Spaceports AS sp
ON sp.Id=j.DestinationSpaceportId
ORDER BY s.LightSpeedRate DESC

--11. Select Spaceships With Pilots
Select s.[Name], s.Manufacturer
FROM Colonists AS c
JOIN TravelCards AS tc 
ON tc.ColonistId=c.Id
JOIN Journeys AS j 
ON tc.JourneyId=j.Id
JOIN Spaceships AS s ON j.SpaceshipId=s.Id
WHERE DATEDIFF(YEAR, c.Birthdate, '01/01/2019') < 30 AND tc.JobDuringJourney = 'Pilot'
ORDER BY s.Name

--12. Select All Educational 
SELECT p.[Name] AS PlanetName, sp.[Name] AS SpaceportName
FROM Planets AS p
JOIN Spaceports AS sp
ON sp.PlanetId=p.Id
JOIN Journeys AS j
ON sp.Id=j.DestinationSpaceportId
WHERE j.Purpose='Educational'
ORDER BY SpaceportName DESC

--13. Planets And Journeys 
SELECT pl.PlanetName, COUNT(pl.PlanetName) AS JourneysCount
FROM (
        SELECT p.Name AS PlanetName
        FROM Planets AS p
        JOIN Spaceports AS sp ON p.id = sp.PlanetId
        JOIN Journeys AS j ON sp.id = j.DestinationSpaceportId
     )AS pl
GROUP BY pl.PlanetName
ORDER BY JourneysCount DESC, pl.PlanetName

--14. Select
SELECT TOP(1) j.Id, pl.[Name] AS PlanetName, sp.[Name] AS SpaceportName, j.Purpose AS JourneyPurpose
FROM Journeys AS j
JOIN Spaceports AS sp
ON sp.Id = j.DestinationSpaceportId
JOIN Planets AS pl
ON pl.Id=sp.PlanetId
ORDER BY DATEDIFF(SECOND, j.JourneyStart, j.JourneyEnd)

--15. Select the less popular job
SELECT TOP(1) tc.JourneyId, tc.JobDuringJourney AS JobName
FROM TravelCards AS tc
WHERE tc.JourneyId=
    (
    SELECT TOP(1) j.Id
    FROM Journeys AS j
    ORDER BY DATEDIFF(MINUTE, j.JourneyStart, j.JourneyEnd) DESC
    )
GROUP BY tc.JobDuringJourney, tc.JourneyId
ORDER BY COUNT(tc.JobDuringJourney)

--16. Select Second Oldest Important Colonist
SELECT k.JobDuringJourney, c.FirstName + ' ' + c.LastName AS FullName, k.JobRank
  FROM (
  SELECT tc.JobDuringJourney AS JobDuringJourney, tc.ColonistId,
DENSE_RANK() OVER (PARTITION BY tc.JobDuringJourney ORDER BY co.Birthdate ASC) AS JobRank
  FROM TravelCards AS tc
  JOIN Colonists AS co ON co.Id = tc.ColonistId
  GROUP BY tc.JobDuringJourney, co.Birthdate, tc.ColonistId
  ) AS k
  JOIN Colonists AS c ON c.Id = k.ColonistId
  WHERE k.JobRank = 2
  ORDER BY k.JobDuringJourney

  --17. Planets and Spaceports
 SELECT p.Name, COUNT(s.Name) AS Count
  FROM Planets AS p
  LEFT JOIN Spaceports AS s ON s.PlanetId = p.Id
GROUP BY p.Name
ORDER BY Count DESC, Name ASC

--18. Get Colonists Count 
GO
CREATE FUNCTION udf_GetColonistsCount(@PlanetName VARCHAR(30))
RETURNS INT
AS
BEGIN
	RETURN (SELECT COUNT(*) FROM Journeys AS j
	JOIN Spaceports AS s ON s.Id = j.DestinationSpaceportId
	JOIN Planets AS p ON p.Id = s.PlanetId
	JOIN TravelCards AS tc ON tc.JourneyId = j.Id
	JOIN Colonists AS c ON c.Id = tc.ColonistId
	WHERE p.Name = @PlanetName)
END

--19. Change Journey Purpose 
GO
CREATE PROCEDURE usp_ChangeJourneyPurpose(@JourneyId INT, @NewPurpose VARCHAR(30))
AS
BEGIN
	DECLARE @TargetJourneyId INT = (SELECT Id FROM Journeys WHERE Id = @JourneyId)

	IF (@TargetJourneyId IS NULL)
	BEGIN
		;THROW 51000, 'The journey does not exist!', 1
	END

	DECLARE @CurrentJourneyPurpose VARCHAR(30) = (SELECT Purpose FROM Journeys WHERE Id = @JourneyId)

	IF (@CurrentJourneyPurpose = @NewPurpose)
	BEGIN
		;THROW 51000, 'You cannot change the purpose!', 2
	END

	UPDATE Journeys
	SET Purpose = @NewPurpose
	WHERE Id = @JourneyId
END

--20. Deleted Journeys
CREATE TABLE DeletedJourneys
(
	Id INT,
	JourneyStart DATETIME,
	JourneyEnd DATETIME,
	Purpose VARCHAR(11),
	DestinationSpaceportId INT,
	SpaceshipId INT
)
GO
CREATE TRIGGER t_DeleteJourney
	ON Journeys
	AFTER DELETE
AS
	BEGIN
		INSERT INTO DeletedJourneys(Id,JourneyStart,JourneyEnd,Purpose,DestinationSpaceportId,
		SpaceshipId)
		SELECT Id,JourneyStart,JourneyEnd, Purpose, DestinationSpaceportId, SpaceshipId FROM deleted
	END