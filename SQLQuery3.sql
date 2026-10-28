create table TemporaryStaff
(StaffID INT primary key,
StaffName VARCHAR(50),
HireDate DATE
);

create table Departments
(DepartmentID INT PRIMARY KEY,
DepartmentName VARCHAR(50)  NOT NULL UNIQUE
);

create table Employees
(EmployeeID INT PRIMARY KEY, 
FullName VARCHAR(100) NOT NULL,
Email VARCHAR(100) UNIQUE,
Salary DECIMAL(10,2),
DepartmentID INT
);

alter table Employees add PhoneNumber VARCHAR(20);

insert into Departments values(1,'IT');
insert into Departments values(2,'HR');
insert into Departments values(3,'Finance');

select * from Departments;
select * from Employees;
select * from TemporaryStaff;

insert into Employees values (1,'Ahmad Ali', 'ahmad@techworld.com' , 1200.00 , 1 ,'0791111111'),
(2 ,'Sara Hassan' ,'sara@techworld.com' , 950.00 ,2 ,'0792222222'),
(3 ,'Zaid Omar','zaid@techworld.com',1500.00 ,1 ,'0793333333'),
(4 ,'Mona Khaled' ,'mona@techworld.com', 800.00,3 ,'0794444444');

update Employees set Salary = 1350.00  where EmployeeID = 1 ;

delete from Employees where EmployeeID = 4;

select * from Employees ;
select FullName from Employees ;
select sum(Salary)as TotalSalaries from Employees ;
select avg(Salary)as AverageSalary from Employees ;
select max(Salary)as HighestSalary, min(Salary)as LowestSalary from Employees ;
select count(EmployeeID)as TotalEmployees from Employees ;




