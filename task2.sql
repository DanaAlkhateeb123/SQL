create table AccessCards (
CardID INT PRIMARY KEY,
CardNumber VARCHAR(50) NOT NULL UNIQUE,
EmployeeID INT UNIQUE FOREIGN KEY References Employees(EmployeeID)
);

create table projects(
ProjectID INT primary key,
ProjectName VARCHAR(100) NOT NULL
);

create table EmployeeProjects (
EmployeeID INT  FOREIGN KEY References Employees(EmployeeID),
ProjectID INT  FOREIGN KEY References projects(ProjectID),
AssignedDate DATE,
PRIMARY KEY (EmployeeID, ProjectID)
);

insert into AccessCards values (1,'card 101',1),(2,'card 102',2),(3,'card 103',3);
insert into projects values (1,'AI & Security Training' ),(2,'Cloud Migration');
insert into EmployeeProjects values (1,1,'2026-11-11'),(1,2,'2026-11-16'),(2,1,'2026-11-1'),(3,2,'2026-11-20');

select * from EmployeeProjects;

select FullName,Salary,DepartmentName from Employees inner join Departments on 
Employees.DepartmentID= Departments.DepartmentID;

select FullName,DepartmentName from Employees left join Departments on 
Employees.DepartmentID= Departments.DepartmentID;

select FullName ,CardNumber from Employees inner join AccessCards on
Employees.EmployeeID = AccessCards.EmployeeID;

select FullName, ProjectName, AssignedDate from Employees inner join EmployeeProjects on 
Employees.EmployeeID = EmployeeProjects.EmployeeID 
inner join projects on EmployeeProjects.ProjectID = projects.ProjectID; 

select * from Employees;

select sum(Salary) as TotalSalary, count(EmployeeID) as EmployeeCount from Employees group by DepartmentID;

select DepartmentID , avg(Salary) as AvgSalary from Employees group by DepartmentID having avg(Salary) >1000;

select FullName, Salary from Employees where Salary > ( select avg(Salary) from Employees); --avg = 1266.6

create view vw_EmployeeDetails as 
select EmployeeID, FullName, Email, DepartmentName from Employees inner join Departments on
Employees.DepartmentID = Departments.DepartmentID;
SELECT * FROM vw_EmployeeDetails;

create PROCEDURE sp_GetEmployeesByDepartment 
@DeptID INT 
as
BEGIN
select FullName from Employees where DepartmentID = @DeptID;
END;
GO
EXEC sp_GetEmployeesByDepartment @DeptID = 1;
EXEC sp_GetEmployeesByDepartment @DeptID = 2;



create table EmployeeAudit (AuditID INT primary key 
, EmployeeID INT
, Action VARCHAR(50)
, ActionDate DATETIME);

GO
CREATE TRIGGER trg_EmployeeDelete
ON Employees
AFTER DELETE
AS
BEGIN
    INSERT INTO EmployeeAudit (EmployeeID, Action, ActionDate)
    SELECT EmployeeID, 'DELETE', GETDATE()
    FROM deleted;
END;
GO

SELECT * FROM EmployeeAudit;







