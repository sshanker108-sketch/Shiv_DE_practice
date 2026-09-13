create database SCD_practice
use SCD_practice
----***************************************SCD1*****************************************************
---Bronze Table
create table officedata_bronze
(
   employee_id int,
   employee_name varchar(30),
   department varchar(30),
   state varchar(20),
   salary int,
   age int,
   bonus int,
   updated_at DATETIME default GETDATE()
)

---Silver Table
CREATE TABLE officedata_silver
(
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(30),
    department VARCHAR(30),
    state VARCHAR(20),
    salary INT,
    age INT,
    bonus INT,
    updated_at DATETIME
);

---Sample Data to Bronze Table
INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(1,'John','IT','Texas',70000,30,5000),
(2,'David','HR','California',60000,35,4000),
(3,'Sarah','Finance','New York',80000,32,7000);


CREATE OR ALTER PROCEDURE sp_load_officedata_scd1_update_insert

AS
BEGIN

SET NOCOUNT ON;
------------------------------------------------
-- UPDATE EXISTING RECORDS
------------------------------------------------
UPDATE TARGET
SET
TARGET.employee_name = SOURCE.employee_name,
TARGET.department    = SOURCE.department,
TARGET.state         = SOURCE.state,
TARGET.salary        = SOURCE.salary,
TARGET.age           = SOURCE.age,
TARGET.bonus         = SOURCE.bonus,
TARGET.updated_at    = SOURCE.updated_at

FROM officedata_silver TARGET
INNER JOIN officedata_bronze SOURCE
ON TARGET.employee_id = SOURCE.employee_id;


------------------------------------------------
-- INSERT NEW RECORDS
------------------------------------------------
INSERT INTO officedata_silver
(
    employee_id,
    employee_name,
    department,
    state,
    salary,
    age,
    bonus,
    updated_at
)
SELECT
SOURCE.employee_id,
SOURCE.employee_name,
SOURCE.department,
SOURCE.state,
SOURCE.salary,
SOURCE.age,
SOURCE.bonus,
SOURCE.updated_at FROM officedata_bronze SOURCE
WHERE NOT EXISTS
(
SELECT 1 FROM officedata_silver TARGET WHERE TARGET.employee_id = SOURCE.employee_id
);

END;

exec sp_load_officedata_scd1_update_insert


INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(4,'John','IT','Texas',70000,30,5000),
(5,'David','HR','California',60000,35,4000),
(6,'Sarah','Finance','New York',80000,32,7000);

update officedata_bronze
set 
department = 'HR',
updated_at = CURRENT_TIMESTAMP
where employee_id = 1

select * from officedata_bronze
select * from officedata_silver

truncate table officedata_bronze
truncate table officedata_silver



----***************************************SCD2*****************************************************
-----Bronze table will be use same as used in SCD1
-----Silver table
CREATE TABLE officedata_silver_scd2 (
    surrogate_key INT IDENTITY(1,1) PRIMARY KEY,
    employee_id int,
    employee_name varchar(30),
    department varchar(30),
    state varchar(20),
    salary int,
    age int,
    bonus int,
    start_date DATETIME,
    end_date DATETIME,
    is_current BIT
);

CREATE OR ALTER PROCEDURE sp_load_officedata_scd2_update_insert

AS
BEGIN

SET NOCOUNT ON;

------------------------------------------------
-- STEP 1
-- CLOSE OLD RECORD
------------------------------------------------
UPDATE TARGET
SET
TARGET.end_date = GETDATE(),
TARGET.is_current = 0
FROM officedata_silver_scd2 TARGET
INNER JOIN officedata_bronze SOURCE
ON TARGET.employee_id = SOURCE.employee_id
AND TARGET.is_current = 1
WHERE
(
TARGET.employee_name <> SOURCE.employee_name
OR TARGET.department <> SOURCE.department
OR TARGET.state <> SOURCE.state
OR TARGET.salary <> SOURCE.salary
OR TARGET.age <> SOURCE.age
OR TARGET.bonus <> SOURCE.bonus
);



------------------------------------------------
-- STEP 2
-- INSERT NEW VERSION
------------------------------------------------

INSERT INTO officedata_silver_scd2
(
	employee_id,
	employee_name,
	department,
	state,
	salary,
	age,
	bonus,
	start_date,
	end_date,
	is_current
)
SELECT
	SOURCE.employee_id,
	SOURCE.employee_name,
	SOURCE.department,
	SOURCE.state,
	SOURCE.salary,
	SOURCE.age,
	SOURCE.bonus,
	GETDATE(),
	NULL,
	1
FROM officedata_bronze SOURCE WHERE NOT EXISTS
(
SELECT 1 FROM officedata_silver_scd2 TARGET
WHERE TARGET.employee_id = SOURCE.employee_id
AND TARGET.is_current = 1
);

END;


INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(7,'John','IT','Texas',70000,30,5000),
(8,'David','HR','California',60000,35,4000),
(9,'Sarah','Finance','New York',80000,32,7000);

update officedata_bronze
set 
department = 'IT',
updated_at = CURRENT_TIMESTAMP
where employee_id = 5

exec sp_load_officedata_scd2_update_insert

select * from officedata_bronze
select * from officedata_silver_scd2

-- Agar galti hui:
ROLLBACK TRANSACTION;

