create table User1 (
id int primary key ,
name varchar(50),
age int ,
gender bit );

create table ND(
ND_id int primary key ,
birthdate date ,
address varchar(max),
User1id int foreign key references User1(id)
);


create table department(
id int primary key ,
dep_name  varchar(50));


create table employee(
id int primary key ,
name varchar(50),
age int ,
gender bit,
depid int foreign key references department(id),);



create table std(
id int primary key ,
name varchar(50));

create table courses(
id int primary key ,
name varchar(50));

create table std_courses(
stdid int foreign key references std(id),
courseid int foreign key references courses(id)
);


select * from User1;
select * from ND;
select * from department;
select * from employee;
select * from std;
select * from courses;
select * from std_courses;

insert into department values(1,'hr'),(2,'marketing');
insert into employee values ( 1,'dana',23,1,1),( 2,'nada',23,1,2),( 3,'sara',22,1,1);

select * from employee AS e inner join department as d on e.depid = d.id;


CREATE VIEW view2 As
select d.dep_name,e.name from employee as e  inner join department as d on e.depid = d.id; 

select * from view2
















