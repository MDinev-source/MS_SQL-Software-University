CREATE DATABASE WMS
USE WMS

--01 Database design
CREATE TABLE Clients
(
    ClientId  int PRIMARY KEY IDENTITY,
    FirstName varchar(50) NOT NULL,
    LastName  varchar(50) NOT NULL,
    Phone     char(12) CHECK (LEN(Phone) = 12)

)

CREATE TABLE Mechanics
(
    MechanicId int PRIMARY KEY IDENTITY,
    FirstName  varchar(50)  NOT NULL,
    LastName   varchar(50)  NOT NULL,
    Address    varchar(max) NOT NULL

)

CREATE TABLE Models
(
    ModelId int PRIMARY KEY IDENTITY,
    Name    varchar(50) NOT NULL UNIQUE

)


CREATE TABLE Jobs
(
    JobId      int PRIMARY KEY IDENTITY,
    ModelId    int  NOT NULL REFERENCES Models (ModelId),
    Status     varchar(11) CHECK (Status IN ('Pending', 'In Progress', 'Finished')) DEFAULT 'Pending',
    ClientId   int  NOT NULL REFERENCES Clients (ClientId),
    MechanicId int REFERENCES Mechanics (MechanicId),
    IssueDate  date NOT NULL,
    FinishDate date

)
CREATE TABLE Orders
(
    OrderId   int PRIMARY KEY IDENTITY,
    JobId     int NOT NULL REFERENCES Jobs (JobId),
    IssueDate date,
    Delivered bit NOT NULL DEFAULT 0

)
CREATE TABLE Vendors
(
    VendorId int PRIMARY KEY IDENTITY,
    Name     varchar(50) NOT NULL UNIQUE

)
CREATE TABLE Parts
(
    PartId       int PRIMARY KEY IDENTITY,
    SerialNumber varchar(50)   NOT NULL UNIQUE,
    Description  varchar(max),
    Price        decimal(6, 2) NOT NULL CHECK (Price > 0),
    VendorId     int           NOT NULL REFERENCES Vendors (VendorId),
    StockQty     int           NOT NULL CHECK (StockQty >= 0) DEFAULT 0

)

CREATE TABLE OrderParts
(
    OrderId  int NOT NULL REFERENCES Orders (OrderId),
    PartId   int NOT NULL REFERENCES Parts (PartId),
    Quantity int NOT NULL CHECK (Quantity > 0) DEFAULT 1
        PRIMARY KEY (OrderId, PartId)
)
CREATE TABLE PartsNeeded
(
    JobId    int NOT NULL REFERENCES Jobs (JobId),
    PartId   int NOT NULL REFERENCES Parts (PartId),
    Quantity int NOT NULL CHECK (Quantity > 0) DEFAULT 1
        PRIMARY KEY (JobId, PartId)

)
--02. Insert
INSERT INTO Clients(FirstName, LastName, Phone) VALUES
('Teri', 'Ennaco', '570-889-5187'),
('Merlyn', 'Lawler', '201-588-7810'),
('Georgene', 'Montezuma', '925-615-5185'),
('Jettie', 'Mconnell', '908-802-3564'),
('Lemuel', 'Latzke', '631-748-6479'),
('Melodie', 'Knipp', '805-690-1682'),
('Candida', 'Corbley', '908-275-8357')

INSERT INTO Parts (SerialNumber, Description, Price, VendorId) VALUES
('WP8182119', 'Door Boot Seal', 117.86, 2),
('W10780048', 'Suspension Rod', 42.81, 1),
('W10841140', 'Silicone Adhesive ', 6.77, 4),
('WPY055980', 'High Temperature Adhesive', 13.94, 3)

--03. Update
UPDATE Jobs
SET MechanicId = (SELECT m.MechanicId 
                 FROM Mechanics AS m
				 WHERE m.FirstName= 'Ryan'
				 AND m.LastName='Harnos')
WHERE [Status] = 'Pending'


UPDATE Jobs
SET [Status] = 'In Progress'
WHERE [Status]='Pending'
AND MechanicId = (SELECT m.MechanicId 
                 FROM Mechanics AS m
				 WHERE m.FirstName= 'Ryan'
				 AND m.LastName='Harnos')


--04. Delete
DELETE FROM OrderParts
WHERE OrderId=19

DELETE FROM Orders
WHERE OrderId=19

--05. Mechanic Assignments
SELECT 
CONCAT(m.FirstName,' ', m.LastName) AS Mechanic,
j.[Status],
j.IssueDate
FROM Mechanics AS m
JOIN Jobs AS j
ON j.MechanicId=m.MechanicId
ORDER BY m.MechanicId, j.IssueDate, j.JobId

--06. Current Clients
SELECT 
CONCAT(c.FirstName,' ', c.LastName) AS Client,
DATEDIFF (DAY, j.IssueDate, '2017-04-24') AS [Days going],
j.[Status]
FROM Clients AS c
JOIN Jobs AS j
ON j.ClientId=c.ClientId
WHERE j.[Status] NOT LIKE 'Finished'
ORDER BY [Days going] DESC, c.ClientId

--07. Mechanic Performance
SELECT
CONCAT(m.FirstName,' ', m.LastName) AS Mechanic,
AVG ( DATEDIFF(DAY, j.IssueDate, j.FinishDate)) AS [Average Days]
FROM Mechanics AS m
JOIN Jobs AS j
ON j.MechanicId=m.MechanicId
GROUP BY m.FirstName, m.LastName, m.MechanicId
ORDER BY m.MechanicId

--08. Available Mechanics


