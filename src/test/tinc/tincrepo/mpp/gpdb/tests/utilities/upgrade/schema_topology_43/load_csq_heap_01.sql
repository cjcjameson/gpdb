-- start_ignore
    drop table if exists t5;
    CREATE TABLE t5 (val int, period text);
    insert into t5 values(5, '2001-3');
    insert into t5 values(10, '2001-4');
    insert into t5 values(15, '2002-1');
    insert into t5 values(5, '2002-2');
    insert into t5 values(10, '2002-3');
    insert into t5 values(15, '2002-4');
    insert into t5 values(10, '2003-1');
    insert into t5 values(5, '2003-2');
    insert into t5 values(25, '2003-3');
    insert into t5 values(5, '2003-4');

    drop table if exists csq_emp;
    create table csq_emp(name text, department text, salary numeric);
    insert into csq_emp values('a','adept',11200.00);
    insert into csq_emp values('b','adept',22222.00);
    insert into csq_emp values('c','bdept',99222.00);
    insert into csq_emp values('d','adept',23211.00);
    insert into csq_emp values('e','adept',45222.00);
    insert into csq_emp values('f','adept',992222.00);
    insert into csq_emp values('g','adept',90343.00);
    insert into csq_emp values('h','adept',11200.00);
    insert into csq_emp values('i','bdept',11200.00);
    insert into csq_emp values('j','adept',11200.00);
-- end_ignore

-- CSQ Q1
    select 
	period, vsum
    from 
	(select 
      		period,
      		(select 
			sum(val) 
		from 
			t5 
		where 
			period between a.period and '2002-4') 
	as 
		vsum
      	from 
		t5 a 
	where 
		a.period between '2002-1' and '2002-4') as vsum
    where vsum < 45 order by period, vsum;

-- Basic CSQ using where clause
SELECT name, department, salary FROM csq_emp ea
  WHERE salary = 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea 
  WHERE salary > 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea 
  WHERE salary < 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea 
  WHERE salary IN 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea 
  WHERE salary NOT IN 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea 
  WHERE  salary = ANY 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea 
  WHERE salary = ALL 
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea group by name, department,salary
  HAVING avg(salary) >
    (SELECT MAX(salary) FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;

SELECT name, department, salary FROM csq_emp ea group by name, department,salary
  HAVING avg(salary) > ALL
    (SELECT salary FROM csq_emp eb WHERE eb.department = ea.department) order by name, department, salary;
