CREATE DATABASE School
USE School

--1. Database Design
CREATE TABLE Students
(
Id INT PRIMARY KEY IDENTITY(1, 1),
FirstName NVARCHAR(30) NOT NULL,
MiddleName NVARCHAR(25),
LastName NVARCHAR(30) NOT NULL,
Age SMALLINT CHECK(Age BETWEEN 5 AND 100),
--CONSTRAINT CHK_AgeBetween5And100
--CHECK(Age>=5 AND Age<=100),
[Address] NVARCHAR(50),
Phone NCHAR(10)
)

CREATE TABLE Subjects
(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(20) NOT NULL,
Lessons INT CHECK(Lessons>0) NOT NULL
)

CREATE TABLE StudentsSubjects
(
Id INT PRIMARY KEY IDENTITY,
StudentId INT FOREIGN KEY REFERENCES Students(Id) NOT NULL,
SubjectId INT FOREIGN KEY REFERENCES Subjects(Id) NOT NULL,
Grade DECIMAL(3,2) CHECK (Grade BETWEEN 2 AND 6) NOT NULL
)

CREATE TABLE Exams
(
Id INT PRIMARY KEY IDENTITY,
[Date] DATETIME2,
SubjectId INT FOREIGN KEY REFERENCES Subjects(Id) NOT NULL
)

CREATE TABLE StudentsExams
(
StudentId INT FOREIGN KEY REFERENCES Students(Id) NOT NULL,
ExamId INT FOREIGN KEY REFERENCES Exams(Id) NOT NULL,
Grade DECIMAL(3,2) CHECK (Grade BETWEEN 2 AND 6) NOT NULL
)

CREATE TABLE Teachers
(
Id INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(20) NOT NULL,
LastName NVARCHAR(20) NOT NULL,
[Address] NVARCHAR(20) NOT NULL,
Phone CHAR(10),
SubjectId INT FOREIGN KEY REFERENCES Subjects(Id) NOT NULL
)

CREATE TABLE StudentsTeachers
(
StudentId INT FOREIGN KEY REFERENCES Students(Id) NOT NULL,
TeacherId INT FOREIGN KEY REFERENCES Teachers(Id) NOT NULL
CONSTRAINT PK_CompositeStudentIdTeacherId
PRIMARY KEY(StudentId, TeacherId)
)

--2. Insert

INSERT INTO Subjects([Name], [Lessons]) VALUES
('Geometry', 12),
('Health', 10),
('Drama', 7),
('Sports', 9)

INSERT INTO Teachers([FirstName], [LastName], [Address], [Phone], [SubjectId]) VALUES
('Ruthanne', 'Bamb', '84948 Mesta Junction', '3105500146', 6),
('Gerrard', 'Lowin', '370 Talisman Plaza', '3324874824', 2),
('Merrile', 'Lambdin', '81 Dahle Plaza', '4373065154', 5),
('Merrile', 'Ivie', '2 Gateway Circle', '4409584510', 4)

--3 Update
UPDATE StudentsSubjects
SET Grade = 6.00
WHERE SubjectId IN (1,2) AND Grade>=5.50

--4 Delete
DELETE FROM StudentsTeachers
WHERE TeacherId IN (
SELECT Id
FROM Teachers
WHERE Phone LIKE '%72%')

DELETE FROM Teachers
WHERE CHARINDEX('72', Phone)>0

--5 Teen Students
SELECT FirstName, LastName, Age FROM Students 
WHERE Age>=12
ORDER BY FirstName, LastName

--6 Cool Addresses
SELECT FirstName + ' ' + ISNULL(MiddleName, '') + ' ' + LastName AS FullName, 
Address FROM Students
WHERE Address LIKE '%Road%'
ORDER BY FirstName, LastName, Address

--07. 42 Phones 
SELECT FirstName, Address, Phone 
FROM Students
WHERE Phone LIKE '42%' AND MiddleName IS NOT NULL
ORDER BY FirstName

--8 Students Teachers
SELECT s.FirstName, s.LastName, COUNT(st.TeacherId) AS [TeachersCount]
FROM STUDENTS AS s
LEFT JOIN StudentsTeachers AS st
ON st.StudentId=s.Id
GROUP BY s.FirstName, s.LastName

--09. Subjects with Students 
SELECT t.FirstName + ' ' + t.LastName AS [FullName], s.[Name] + '-' + CAST(s.Lessons AS NVARCHAR(5)) AS Subjects,
COUNT(ss.StudentId) AS Students
FROM Teachers AS t
JOIN Subjects AS s
ON s.Id = t.SubjectId
JOIN StudentsTeachers AS ss
ON ss.TeacherId = t.Id
GROUP BY t.FirstName, t.LastName, s.Name,s.Lessons
ORDER BY COUNT(ss.StudentId) DESC, Name, Subjects

--10 Students to Go
SELECT CONCAT(FirstName, ' ', LastName) AS [Full Name]
FROM Students AS s
LEFT JOIN StudentsExams AS se
ON se.StudentId=s.Id
WHERE se.ExamId IS NULL
ORDER BY [Full Name]


--11. Most Busy Teachers
   SELECT TOP(10) t.FirstName, t.LastName, COUNT(*) AS StudentsCount
     FROM Students AS s
	 JOIN StudentsTeachers AS st ON st.StudentId = s.Id
	 JOIN Teachers AS t ON t.Id = st.TeacherId 
 GROUP BY t.FirstName, t.LastName
 ORDER BY StudentsCount DESC, FirstName, LastName

--12 Top Students
SELECT TOP(10) s.FirstName, s.LastName,CAST(AVG(se.Grade) AS DECIMAL(3,2)) AS [Grade] 
FROM Students AS s
JOIN StudentsExams AS se
ON se.StudentId=s.Id
GROUP BY S.FirstName, s.LastName
ORDER BY [Grade] DESC, s.FirstName, s.LastName

 -- 13. Second Highest Grade
SELECT k.FirstName, k.LastName, k.Grade
  FROM (
   SELECT FirstName, LastName, Grade, 
          ROW_NUMBER() OVER (PARTITION BY FirstName, LastName ORDER BY Grade DESC) AS RowNumber
     FROM Students AS s
	 JOIN StudentsSubjects AS ss ON ss.StudentId = s.Id
 ) AS k
 WHERE k.RowNumber = 2
 ORDER BY FirstName, LastName

--14 Not So In The Studying
SELECT CONCAT(s.FirstName, ' ', s.MiddleName +' ', s.LastName) AS [Full Name]
FROM Students AS s
LEFT JOIN StudentsSubjects AS ss
ON ss.StudentId=s.Id
WHERE ss.StudentId IS NULL
ORDER BY [Full Name]


--15. Top Student per Teacher
SELECT j.[Teacher Full Name], j.SubjectName ,j.[Student Full Name], FORMAT(j.TopGrade, 'N2') AS Grade
  FROM (
SELECT k.[Teacher Full Name],k.SubjectName, k.[Student Full Name], k.AverageGrade  AS TopGrade,
	   ROW_NUMBER() OVER (PARTITION BY k.[Teacher Full Name] ORDER BY k.AverageGrade DESC) AS RowNumber
  FROM (
  SELECT t.FirstName + ' ' + t.LastName AS [Teacher Full Name],
  	   s.FirstName + ' ' + s.LastName AS [Student Full Name],
  	   AVG(ss.Grade) AS AverageGrade,
  	   su.Name AS SubjectName
    FROM Teachers AS t 
    JOIN StudentsTeachers AS st ON st.TeacherId = t.Id
    JOIN Students AS s ON s.Id = st.StudentId
    JOIN StudentsSubjects AS ss ON ss.StudentId = s.Id
    JOIN Subjects AS su ON su.Id = ss.SubjectId AND su.Id = t.SubjectId
GROUP BY t.FirstName, t.LastName, s.FirstName, s.LastName, su.Name
) AS k
) AS j
   WHERE j.RowNumber = 1 
ORDER BY j.SubjectName,j.[Teacher Full Name], TopGrade DESC


--16 Average Grade Per Subject
SELECT s.[Name], AVG(ss.Grade) AS [AverageGrade]
FROM Subjects AS s
JOIN StudentsSubjects AS ss
ON ss.SubjectId=s.Id
GROUP BY s.[Name], s.Id
ORDER BY s.Id

--17 Exams Information
SELECT  k.Quarter, k.SubjectName, COUNT(k.StudentId) AS StudentsCount
  FROM (
  SELECT s.Name AS SubjectName,
		 se.StudentId,
		 CASE
		 WHEN DATEPART(MONTH, Date) BETWEEN 1 AND 3 THEN 'Q1'
		 WHEN DATEPART(MONTH, Date) BETWEEN 4 AND 6 THEN 'Q2'
		 WHEN DATEPART(MONTH, Date) BETWEEN 7 AND 9 THEN 'Q3'
		 WHEN DATEPART(MONTH, Date) BETWEEN 10 AND 12 THEN 'Q4'
		 WHEN Date IS NULL THEN 'TBA'
		 END AS [Quarter]
    FROM Exams AS e
	JOIN Subjects AS s ON s.Id = e.SubjectId 
	JOIN StudentsExams AS se ON se.ExamId = e.Id
	WHERE se.Grade >= 4
) AS k
GROUP BY k.Quarter, k.SubjectName
ORDER BY k.Quarter

--18 Exam Grades
GO
CREATE FUNCTION udf_ExamGradesToUpdate(@studentId INT, @grade DECIMAL(3,2))
RETURNS NVARCHAR(100)
AS
BEGIN
   DECLARE @studentName NVARCHAR(30) = (SELECT TOP(1) FirstName FROM Students WHERE Id = @studentId)

   IF (@studentName IS NULL)
   BEGIN
       RETURN 'The student with provided id does not exist in the school!';
   END

   IF (@grade>6.00)
   BEGIN
       RETURN 'Grade cannot be above 6.00!';
   END
   
   DECLARE @studentGradesCount INT =(SELECT COUNT(Grade) FROM StudentsExams WHERE StudentId=@studentId AND (Grade>@grade AND Grade<=(Grade+0.5));

   RETURN CONCAT ('You have to update', @studentGradesCount, ' grades for the student ', @studentName);
END
GO

--19 Exclude from school
GO
CREATE PROC usp_ExcludeFromSchool(@StudentId INT)
AS
BEGIN
DECLARE @studentsMatchingIdCount  BIT = (SELECT COUNT(*) FROM Students WHERE Id=@StudentId)

IF (@studentsMatchingIdCount=0)
BEGIN
RAISERROR('This school has no student with the provided id!', 16,1);
RETURN;
END

DELETE FROM StudentsExams
WHERE StudentId=@StudentId

DELETE FROM StudentsSubjects
WHERE StudentId=@StudentId

DELETE FROM StudentsTeachers
WHERE StudentId=@StudentId

DELETE FROM Students
WHERE Id=@StudentId

END

--20. Deleted Students
CREATE TABLE ExcludedStudents
(
StudentId INT, 
StudentName VARCHAR(30)
)

GO
CREATE TRIGGER tr_StudentsDelete ON Students
INSTEAD OF DELETE
AS
INSERT INTO ExcludedStudents(StudentId, StudentName)
		SELECT Id, FirstName + ' ' + LastName FROM deleted