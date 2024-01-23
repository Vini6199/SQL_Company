CREATE SCHEMA IF NOT EXISTS company_constraints;
use company_constraints;

create table employee(
	fname varchar(15) not null,
	minit char,
	Lname varchar(15) not null,
	Ssn char(9),
	Bdate date,
	Address varchar(30),
	sex char,
	Salary decimal(10,2),
	-- referencia o Ssn de gerentes em outros empregados:
	Super_ssn char(9),
	Dno int not null,
	constraint chk_salary_employee check(Salary> 2000.0),
	constraint pk_employee primary key(Ssn)
);

create table department(
	Dname varchar(15) not null,
    	Dnumber int not null,
    	Mgr_ssn char(9),
    	Mgr_start_date date,
    	Dept_create_date date,
    	-- verificar se a data que o gerente começou é maior que criação do departamento, que seria erro:
    	constraint chk_date_dept check (Dept_create_date< Mgr_start_date),
    	constraint pk_dept primary key(Dnumber),
	constraint unique_name_department Unique(Dname),
    	foreign key (Mgr_ssn) references employee(Ssn)
);


create table dept_locations(
	Dnumber int not null,
    	Dlocation varchar(15) not null,
    	constraint pk_dept_location primary key (Dnumber, Dlocation),
    	constraint fk_dept_location foreign key (Dnumber) references department (Dnumber)    
);

create table project(
	Pname varchar(15) not null,
    	Pnumber int not null,
    P	location varchar(15),
    	Dnum int not null,
    	primary key (Pnumber),
    	constraint unique_project unique (Pname),
    	constraint fk_project foreign key (Dnum) references department(Dnumber)
);

create table works_on(
	Essn char(9) not null,
        Pno int not null,
        Hours decimal(3,1) not null,
        primary key (Essn, Pno),
        constraint fk_employee_works_on foreign key (Essn) references employee (Ssn),
        constraint fk_projects_works_on foreign key (Pno) references project (Pnumber)
);

create table dependent(
	Essn char(9) not null,
        Dependent_name varchar(15) not null,
        Sex char ,
        Bdate date,
        Relationship varchar(8),
        primary key (Essn, dependent_name),
        constraint fk_dependent foreign key(Essn) references employee(Ssn)
);

alter table employee
add constraint fk_employee
foreign key(Super_ssn) references employee(Ssn)
on delete set null
on update cascade;
    
-- modificar constraint: drop e add:
alter table department drop constraint department_ibfk_1;
alter table department 
add constraint fk_department foreign key(Mgr_ssn) references employee(Ssn)
on update cascade,
add Mgr_start_date date,
add Dept_create_date date;
    
alter table dept_locations drop constraint fk_dept_locations;

alter table dept_locations
add constraint fk_dept_locations foreign key(Dnumber) references department(Dnumber)
on delete cascade
on update cascade;

select * from information_schema.table_constraints
where constraint_schema = 'company_constraints';

-- inserção de dados no bd company:
use company_constraints;
show tables;

insert into employee values ('John','B','Smith',123456789,'1965-01-09','731-Froundren-Hoouston-TX','M',30000,null,5);
insert into employee values ('Franklin','J','Houston',887654321,'1998-06-23','44-Salvador-Bahia','M',20000,null,4);
insert into employee values ('Rosana','J','Morrow',444555999,'1978-06-15','88-China-Florida','F',4000,123456789,5);

select * from employee;

insert into dependent values (123456789,'Alice','F','1999-04-05','Daughter'),
			     (887654321,'Theodore','M','1998-06-23','Brother'),
                             (444555999,'Jessy','F','2001-02-01','Son');
                        
select * from dependent;

insert into department values ('Research',5,123456789,'1990-05-22','1990-05-22'),
			      ('Administration',4,887654321,'2020-05-22','1990-05-22');
                         
select * from department;

insert into dept_locations values ('5','Houston'),
				  ('4','Florida');
                                  
select * from dept_locations;

insert into project values ('ProductX','1','Houston','5'),
			   ('ProductY','2','Houston','5'),
                           ('ProductV','3','Florida','4'),
                           ('ProductZ','4','Houston','4');

select * from project;

insert into works_on values ('123456789','1',10.0),
			    ('887654321','2',10.0),
                            ('444555999','1',8.0);
								
desc works_on;

-- Gerente, seu Ssn e departamento. Uso de ALIAS
select Ssn, Fname, Dname from employee as e, department as d where (e.Ssn = Mgr_ssn);

-- Recuperando dependentes dos empregados
select Ssn, Fname, dependent_name, relationship from employee, dependent where Essn = Ssn;

-- Recuperando dados do empregado pelo nome
select Bdate, Address from employee where Fname = 'John' and Minit = 'B';

-- Recuperando departamento específico
select * from department where Dname = 'Research';

select Fname, Lname, Address from employee, department
	where Dname = 'Research' and Dnumber = Dno;
    
-- Juntar informações, nesse caso, concatenar os nomes e dar nome à essa nova tabela:
select concat(Fname, ' ', Lname) as Employee from employee;

-- Criar porcentagem de INSS baseado no salario, usando alias (para dar nome ao INSS) e round (para deiar decimal)
select Fname, Lname, Salary, round(Salary*0.011,2) as INSS from employee;

-- Definir um aumento de salário para os que trabalham associado ao produtoX
select concat(Fname,' ',Lname) as Complete_name, Salary, round(Salary*1.1,2) as increased_salary
			  from employee as e, works_on as w, project as p
			  where (e.Ssn = w.Essn and w.Pno = p.Pnumber and p.Pname = 'ProductX');

-- like e between
select concat(Fname, ' ',Lname) Complete_Name, Dname as Department_Name, Address from employee, department
		where (Address like '%Florida%');
        
select Fname, Lname, Salary from employee where( Salary between 10000 and 40000);

select distinct Pnumber from project
		where Pnumber in
        (select distinct Pnumber from project, department, employee where
        Mgr_ssn = Ssn and Lname = 'Smith' and Dnum = Dnumber)
        or
        (select distinct Pno from works_on, employee
			where (Essn = Ssn and Lname = 'Smith'));
            
-- Cláusulas com exists

-- Quais employees possuem dependentes?
select e.Fname, e.Lname from employee as e, department as d 
	where (e.Ssn = d.Mgr_ssn) and
    exists (select * from dependent as d where e.Ssn = d.Essn);
  
-- Setando atributos a partir de condições com CASE
update employee set Salary =
		case 
			when Dno = 5 then Salary + 2000
            when Dno = 4 then Salary + 1500
			else Salary + 0
		end;
        
select Fname, Salary, Dno from employee;