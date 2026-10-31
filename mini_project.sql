create table TempInstructors (
TempID INT, 
TempName VARCHAR(50),
JoinedDate DATE );

create table Departments (
DepartmentID INT Primary Key,
DepartmentName VARCHAR(100) NOT NULL UNIQUE );

create table Students (
StudentID INT Primary key ,
FullName VARCHAR(100) NOT NULL , 
Email VARCHAR(100) UNIQUE,
GPA DECIMAL(3,2),
DepartmentID INT Foreign key references Departments(DepartmentID));

create table StudentProfiles (
ProfileID INT primary key,
StudentID INT UNIQUE Foreign key references Students(StudentID),
Address VARCHAR(200),
EmergencyPhone VARCHAR(20));

create table Courses (
CourseID INT Primary key ,
CourseName VARCHAR(100) NOT NULL,
Credits INT,
DepartmentID INT Foreign key references Departments(DepartmentID));

create table StudentCourses (
StudentID INT Foreign key references Students(StudentID),
CourseID INT Foreign key references Courses(CourseID),
EnrollmentDate DATE DEFAULT GETDATE(), 
Primary Key (StudentID, CourseID));

alter table Students add Age INT ; 
select * from Students;

drop table TempInstructors ; -- (select * from TempInstructors) -> error


insert into Departments values (1, 'Computer Science'),
(2, 'Software Engineering'),
(3, 'Business Administration');

insert into Students values(101, 'Ali Smadi','ali@coursehub.com',3.80 ,1 ,22),
(102,'Omar Ahmad','omar@coursehub.com' ,2.90 ,1,21),
(103,'Laila Hassan','laila@coursehub.com',3.50,2,23),
(104,'Tariq Zaid','tariq@coursehub.com' ,2.10,3, 20);

insert into StudentProfiles values(1, 101, 'Amman, Jordan', '0791111111'),
(2, 102, 'Irbid, Jordan', '0792222222'),
(3, 103, 'Zarqa, Jordan', '0793333333');

insert into Courses values(201, 'Database Systems', 3, 1),
(202, 'Web Development', 3, 1), 
(203, 'Software Architecture', 3, 2);

insert into StudentCourses values (101,201,null),(101,202,null),(102,201,null),(103,203,null);

update Students set GPA = 2.50 where StudentID= 104 ;
select * from Students;

DELETE from Students where StudentID=104 ;-- tariq is deleted 

select FullName, GPA, DepartmentName from Students inner join Departments on
Students.DepartmentID=Departments.DepartmentID;

select DepartmentName, FullName from Departments left join Students on
Departments.DepartmentID = Students.DepartmentID;

select FullName, Address,  EmergencyPhone from Students inner join StudentProfiles on 
Students.StudentID = StudentProfiles.StudentID;

select FullName, CourseName, EnrollmentDate from Students inner join StudentCourses on
Students.StudentID = StudentCourses.StudentID 
inner join Courses on
StudentCourses.CourseID = Courses.CourseID;

select COUNT(*)as total_std,AVG(GPA)as avg,max(GPA)as max,min(GPA)as min from Students;

select COUNT(*)as total_std,AVG(GPA)as avg from Students group by DepartmentID;

select DepartmentID , avg(GPA)as avg from Students group by DepartmentID having avg(GPA)>3;

select DepartmentID , COUNT(*) as total_std from Students where GPA > 2.5 group by DepartmentID having COUNT(*)>1;

--task 6.1 -> StudentID
CREATE NONCLUSTERED INDEX IX_Students_Email ON Students (Email);

select FullName from Students where GPA >(select AVG(GPA) from Students);


CREATE VIEW vw_StudentAcademicDetails
AS
SELECT s.StudentID, s.FullName, s.GPA, d.DepartmentName
FROM Students AS s
INNER JOIN Departments AS d
ON s.DepartmentID = d.DepartmentID;
SELECT * FROM vw_StudentAcademicDetails;


CREATE PROCEDURE sp_GetStudentsByDepartment
@DeptID INT
AS
BEGIN
    SELECT *
    FROM Students
    WHERE DepartmentID = @DeptID;
END;
EXEC sp_GetStudentsByDepartment @DeptID = 1;














