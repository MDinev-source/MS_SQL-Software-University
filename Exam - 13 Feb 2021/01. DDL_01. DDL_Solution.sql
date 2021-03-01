CREATE DATABASE Bitbucket
USE Bitbucket

--01. Database Design

CREATE TABLE Users
(
Id INT PRIMARY KEY IDENTITY NOT NULL,
Username VARCHAR(30) NOT NULL,
[Password] VARCHAR(30) NOT NULL,
Email VARCHAR(50) NOT NULL
)

CREATE TABLE Repositories
(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Name] VARCHAR (50) NOT NULL
)

CREATE TABLE RepositoriesContributors
(
RepositoryId INT FOREIGN KEY REFERENCES Repositories(Id) NOT NULL,
ContributorId INT FOREIGN KEY REFERENCES Users(Id) NOT NULL
CONSTRAINT Pk_Name PRIMARY KEY (RepositoryId, ContributorId)
)

CREATE TABLE Issues
(
Id INT PRIMARY KEY IDENTITY NOT NULL,
Title VARCHAR(255) NOT NULL,
IssueStatus CHAR (6) NOT NULL,
RepositoryId INT FOREIGN KEY REFERENCES Repositories(Id) NOT NULL,
AssigneeId INT FOREIGN KEY REFERENCES Users(Id) NOT NULL
)

CREATE TABLE Commits
(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Message] VARCHAR(255) NOT NULL,
IssueId INT FOREIGN KEY REFERENCES Issues(Id),
RepositoryId INT FOREIGN KEY REFERENCES Repositories(Id) NOT NULL,
ContributorId INT FOREIGN KEY REFERENCES Users(Id) NOT NULL
)

CREATE TABLE Files
(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Name] VARCHAR (100) NOT NULL,
Size DECIMAL(15,2) NOT NULL,
ParentId INT FOREIGN KEY REFERENCES Files(Id) ,
CommitId INT FOREIGN KEY REFERENCES Commits(Id) NOT NULL
)

--02. Insert
INSERT INTO Files VALUES
('Trade.idk', 2598.0, 1, 1),
('menu.net', 9238.31, 2, 2),
('Administrate.soshy', 1246.93, 3, 3),
('Controller.php', 7353.15, 4, 4),
('Find.java',9957.86, 5, 5),
('Controller.json', 14034.87, 3, 6),
('Operate.xix', 7662.92, 7, 7)

INSERT INTO Issues VALUES
('Critical Problem with HomeController.cs file', 'open', 1, 4),
('Typo fix in Judge.html', 'open', 4, 3),
('Implement documentation for UsersService.cs', 'closed', 8, 2),
('Unreachable code in Index.cs', 'open', 9, 8)

--03. Update
UPDATE Issues
SET IssueStatus = 'closed'
WHERE Id = 6

--04. Delete
DELETE FROM RepositoriesContributors
WHERE RepositoryId IN (SELECT Id
						FROM Repositories
						WHERE [Name] = 'Softuni-Teamwork')

DELETE FROM Issues
WHERE RepositoryId IN ( SELECT Id
						FROM Repositories
						WHERE [Name] = 'Softuni-Teamwork')

--05. Commits
SELECT c.Id, c.[Message], c.RepositoryId, c.ContributorId 
FROM Commits AS c
ORDER BY c.Id, c.[Message], c.RepositoryId, c.ContributorId

--06. Front-end
SELECT f.Id, f.[Name], f.Size
FROM Files AS f
WHERE f.Size>1000 AND f.[Name] LIKE '%html%'
ORDER BY f.Size DESC, f.Id, f.[Name]

--07. Issue Assignment
SELECT i.Id, CONCAT (u.Username,' : ', i.Title) AS IssueAssignee
FROM Issues AS i
JOIN Users AS u
ON u.Id=i.AssigneeId
ORDER BY i.Id DESC , IssueAssignee

--08. Single Files
SELECT f.Id, f.[Name] , CONCAT(f.Size, 'KB') AS Size
FROM Files AS f
LEFT JOIN Files AS f2
ON f2.ParentId = f.Id
WHERE f2.ParentId IS NULL
ORDER BY f.Id, f.[Name], f.Size DESC

--09. Commits in Repositories
SELECT TOP(5) r.Id, r.[Name], COUNT(c.Id) AS Commits 
FROM Repositories AS r
JOIN Commits AS c
ON c.RepositoryId=r.Id
JOIN RepositoriesContributors AS rc
ON r.Id=rc.RepositoryId
GROUP BY r.Id, r.[Name] 
ORDER BY Commits DESC, r.Id, r.[Name]

--10. Average Size
SELECT u.Username, AVG(f.Size) AS Size
FROM Users AS u
JOIN Commits AS c
ON c.ContributorId=u.Id
JOIN Files AS f
ON f.CommitId= c.Id
GROUP BY u.Username
ORDER BY Size DESC, u.Username 

--11. All User Commits
GO
CREATE FUNCTION udf_AllUserCommits(@username VARCHAR(50)) 
RETURNS INT 
AS
BEGIN
      RETURN (SELECT COUNT(*)
	          FROM Users AS u
			  JOIN Commits AS c
			  ON u.Id=c.ContributorId
			  WHERE u.Username=@username)
END
GO

  SELECT dbo.udf_AllUserCommits('UnderSinduxrein')


--12. Search FOR Files
GO
CREATE PROCEDURE usp_SearchForFiles(@fileExtension VARCHAR(50))
AS 
BEGIN 
     SELECT f.Id, f.[Name], CONCAT(f.Size, 'KB') AS Size
	 FROM Files AS f
	 WHERE CHARINDEX(@fileExtension, f.[Name])>0
	 ORDER BY f.Id, f.[Name], f.Size DESC
END

EXEC usp_SearchForFiles'txt'