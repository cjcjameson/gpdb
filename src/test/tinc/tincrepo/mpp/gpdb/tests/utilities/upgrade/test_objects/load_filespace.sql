--
--
--
CREATE DATABASE regress1 TEMPLATE template1;
CREATE DATABASE regress2 TEMPLATE template1;
CREATE DATABASE regress3 TEMPLATE template1;
CREATE DATABASE regress4 TEMPLATE template1;
CREATE DATABASE regress5 TEMPLATE template1;

create tablespace regressionts1 filespace regressionfs1;
create table fstest(a int, b int) tablespace regressionts1;
insert into fstest select i, i from generate_series (1,1000) i;

select count(*) from fstest;

comment on filespace regressionfs1 is 'groovy';
comment on tablespace regressionts1 is 'also groovy';

-- partition coverage

create table cov1 (a int, b int)
distributed by (a)
partition by range (b)
(
  partition p1 start (1) end (2) 
    with (appendonly=true) tablespace regressionts1,
  partition p2 start (2) end (3) tablespace regressionts1,
  partition p3 start (3) end (4) 
    with (appendonly=true) tablespace regressionts1
);

-- view is busted??
select tablename, partitionname, partitiontablename, parenttablespace,
partitiontablespace from pg_partitions where tablename = 'cov1';

drop table cov1;
drop table fstest;

-- caql coverage for tablecmds.c
drop table if exists ttable;
create tablespace ttbspace filespace regressionfs1;
create table ttable (a int, b int) tablespace regressionts1;
alter table ttable set tablespace ttbspace;
drop table ttable;

-- do some alters
create user fsuser1;

alter tablespace regressionts1 rename to rts2;
alter tablespace rts2 rename to regressionts1;

alter filespace regressionfs1 rename to rfs2;
alter filespace rfs2 rename to regressionfs1;

-- privs
alter tablespace regressionts1 owner to fsuser1;
alter filespace regressionfs1 owner to fsuser1;

-- cleanup
drop tablespace regressionts1;
drop tablespace ttbspace;

drop filespace regressionfs1;

drop user fsuser1;
drop user tbs_user1;
drop user tbs_user2;

-- Create new tablespaces
CREATE TABLESPACE regression_ts_a1 FILESPACE regression_fs_a;
CREATE TABLESPACE regression_ts_a2 FILESPACE regression_fs_a;
CREATE TABLESPACE regression_ts_a3 FILESPACE regression_fs_a;
CREATE TABLESPACE regression_ts_b1 FILESPACE regression_fs_b;
CREATE TABLESPACE regression_ts_b2 FILESPACE regression_fs_b;
CREATE TABLESPACE regression_ts_b3 FILESPACE regression_fs_b;
CREATE TABLESPACE regression_ts_c1 FILESPACE regression_fs_c;
CREATE TABLESPACE regression_ts_c2 FILESPACE regression_fs_c;
ALTER FILESPACE regression_fs_c RENAME TO regression_fs_c_renamed;
CREATE TABLESPACE regression_ts_c3 FILESPACE regression_fs_c_renamed;
ALTER FILESPACE regression_fs_c_renamed RENAME TO regression_fs_c;

-- Check if new tablespaces exist in pg_tablespace
SELECT spcname FROM pg_tablespace WHERE spcname LIKE 'regression_ts_a_';

-- Create database with different role
CREATE ROLE fsts_db_owner1;
CREATE DATABASE fsts_db_name1 WITH OWNER = fsts_db_owner1 TEMPLATE template1 CONNECTION LIMIT 2 TABLESPACE = regression_ts_a1;

-- Run some alter database commands
ALTER DATABASE fsts_db_name1 WITH CONNECTION LIMIT 3;
ALTER DATABASE fsts_db_name1 RENAME TO fsts_new_db_name1;
ALTER DATABASE fsts_new_db_name1 RENAME TO fsts_db_name1;
\c fsts_db_name1
SET default_tablespace = 'regression_ts_b3';

-- Create heap list partition table
CREATE TABLE fsts_test_part5 (id int, name text, rank int, year date, gender char(1)) TABLESPACE regression_ts_a3 DISTRIBUTED BY (id)
  PARTITION BY LIST (gender) SUBPARTITION BY RANGE (year) SUBPARTITION TEMPLATE (start (date '2001-01-01')) (values ('M'), values ('F'));

-- Create an index
CREATE INDEX fsts_test_part5_index ON fsts_test_part5(id);

-- Add default partition
ALTER TABLE fsts_test_part5 ADD DEFAULT PARTITION default_part;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_part5;

-- Alter the table to new tablespace, then to pg_default, and...
-- This bugged out in v4.0.0.0 with a cache lookup failure and should be fixed now
ALTER TABLE fsts_test_part5 SET TABLESPACE regression_ts_a2;
ALTER TABLE fsts_test_part5 SET TABLESPACE pg_default;
ALTER TABLE fsts_test_part5 SET TABLESPACE regression_ts_a2;
ALTER TABLE fsts_test_part5 SET TABLESPACE pg_default;
ALTER TABLE fsts_test_part5 SET TABLESPACE regression_ts_a2;

-- Insert few records into the table
INSERT INTO fsts_test_part5 VALUES (1,'ann',1,'2001-01-01','F');
INSERT INTO fsts_test_part5 VALUES (2,'ben',2,'2002-01-01','M');
INSERT INTO fsts_test_part5 VALUES (3,'leni',3,'2003-01-01','F');
INSERT INTO fsts_test_part5 VALUES (4,'sam',4,'2003-01-01','M');

-- Alter the table set distributed by
ALTER TABLE fsts_test_part5 SET DISTRIBUTED BY (id, gender, year);

-- Select from the table
SELECT * FROM fsts_test_part5;

-- Drop Default Partition
ALTER TABLE fsts_test_part5 DROP DEFAULT PARTITION IF EXISTS;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_part5;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_part5 SET TABLESPACE regression_ts_b2;

-- Insert few records into the table
INSERT INTO fsts_test_part5 VALUES (1,'ann',1,'2001-01-01','F');
INSERT INTO fsts_test_part5 VALUES (2,'ben',2,'2002-01-01','M');
INSERT INTO fsts_test_part5 VALUES (3,'leni',3,'2003-01-01','F');
INSERT INTO fsts_test_part5 VALUES (4,'sam',4,'2003-01-01','M');

-- Set distributed randomly
ALTER TABLE fsts_test_part5_1_prt_1_2_prt_1 SET DISTRIBUTED RANDOMLY;
ALTER TABLE fsts_test_part5 ALTER PARTITION FOR('M'::bpchar) ALTER PARTITION FOR(RANK(1)) SET DISTRIBUTED RANDOMLY;
ALTER TABLE fsts_test_part5 SET WITH (reorganize='true') DISTRIBUTED RANDOMLY;

-- Select from the table
SELECT * FROM fsts_test_part5;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_part5_1_prt_1_2_prt_1 SET TABLESPACE regression_ts_c2;

-- Insert and then truncate table
INSERT INTO fsts_test_part5 VALUES (5,'toki',5,'2003-01-01','M');
TRUNCATE fsts_test_part5;

-- Select from the table
SELECT * FROM fsts_test_part5;

-- Alter table add column
ALTER TABLE fsts_test_part5 ADD COLUMN new_int_column int;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_part5;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_part5_1_prt_1 SET TABLESPACE regression_ts_c1;

-- Insert few records into the table
INSERT INTO fsts_test_part5 VALUES (5,'ann',5,'2001-01-01','F',1);
INSERT INTO fsts_test_part5 VALUES (6,'ben',6,'2002-01-01','M',2);
INSERT INTO fsts_test_part5 VALUES (7,'leni',7,'2003-01-01','F',3);
INSERT INTO fsts_test_part5 VALUES (8,'sam',8,'2003-01-01','M',4);

-- Alter the table set distributed by
ALTER TABLE fsts_test_part5 SET WITH (reorganize='true') DISTRIBUTED BY (new_int_column);

-- Select from the table
SELECT * FROM fsts_test_part5;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_part5;

-- Set the default tablespace
SET default_tablespace = 'regression_ts_c1';

-- Table with AO and create an index with it
CREATE TABLE fsts_busted_ao (a int, col001 char DEFAULT 'z', col002 numeric, col003 boolean DEFAULT false, col004 bit(3) DEFAULT '111',
col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', col007 character varying(512) DEFAULT 'Now is the time',
col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8), col011 int, col012 double precision,
col013 bigint, col014 char(8), col015 bytea, col016 timestamp with time zone, col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col025 circle, col026 box, col027 name, col028 path, col029 int2, col031 bit varying(256), col032 date,
col034 lseg, col035 point, col036 polygon, col037 real, col039 time, col040 timestamp) WITH (appendonly=true) TABLESPACE regression_ts_a3;
CREATE INDEX fsts_busted_ao_index ON fsts_busted_ao(a);

-- Alter the table set distributed randomly
ALTER TABLE fsts_busted_ao SET WITH (reorganize='true') DISTRIBUTED RANDOMLY;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_busted_ao;

-- Alter the table to new tablespace
ALTER TABLE fsts_busted_ao SET TABLESPACE regression_ts_c2;

-- Insert few records into the table
INSERT INTO fsts_busted_ao VALUES (1, 'a', 11, true, '111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1', '{one,two,three,four,five}',
  12345678, 1, 111.1111, 11, '1_one_11', 'd', '2001-12-13 01:51:15+1359', '11', '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA', '34.23', '((2,2),1)',
  '((1,2),(2,1))', 'hello', '((1,2),(2,1))', 11, '010101', '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))', 111111, '23:00:00',
  '2001-12-13 01:51:15');

INSERT INTO fsts_busted_ao VALUES (2, 'b', 22, false, '001', '2_one', '{6,7,8,9,10}', 'Hey.. I am good 2', 'Hey .. I am good 2', '{one,two,three,four,five}', 76767669, 1,
  222.2222, 11, '2_two_22', 'c', '2002-12-13 01:51:15+1359', '22', '0.0.0.0', '0.0.0.0', 'BB:BB:BB:BB:BB:BB', '200.00', '((3,3),2)', '((3,2),(2,3))', 'hello',
  '((3,2),(2,3))', 22, '01010100101', '2002-12-13', '((2,2),(3,3))', '(2,2)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))', 11111, '22:00:00', '2002-12-13 01:51:15');

-- Alter the table set distributed by
ALTER TABLE fsts_busted_ao SET WITH (reorganize='true') DISTRIBUTED BY (col010);

-- Select from the table
SELECT * FROM fsts_busted_ao;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_busted_ao;

-- Table with AOCO
CREATE TABLE fsts_busted_co (a int, col001 char DEFAULT 'z', col002 numeric, col003 boolean DEFAULT false, col004 bit(3) DEFAULT
'111', col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', col007 character varying(512) DEFAULT 'Now is the time',
col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8), col011 int, col012 double precision,
col013 bigint, col014 char(8), col015 bytea, col016 timestamp with time zone, col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col025 circle, col026 box, col027 name, col028 path, col029 int2, col031 bit varying(256), col032 date,
col034 lseg, col035 point, col036 polygon, col037 real, col039 time, col040 timestamp ) WITH (orientation=column, appendonly=true) TABLESPACE regression_ts_b1;

-- Create an index on the AOCO table
CREATE INDEX fsts_busted_co_index ON fsts_busted_co(a);

-- Insert a record into the table
INSERT INTO fsts_busted_co VALUES (1, 'a', 11, true, '111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1', '{one,two,three,four,five}',
  12345678, 1, 111.1111, 11, '1_one_11', 'd', '2001-12-13 01:51:15+1359', '11', '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA', '34.23', '((2,2),1)',
  '((1,2),(2,1))', 'hello', '((1,2),(2,1))', 11, '010101', '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))', 111111, '23:00:00',
  '2001-12-13 01:51:15');

-- Alter the table set distributed randomly
ALTER TABLE fsts_busted_co SET WITH (reorganize='true') DISTRIBUTED RANDOMLY;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_busted_co;

-- Alter the table to new tablespace
ALTER TABLE fsts_busted_co SET TABLESPACE regression_ts_a2;

-- Insert few records into the table
INSERT INTO fsts_busted_co VALUES (1, 'a', 11, true, '111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1', '{one,two,three,four,five}',
  12345678, 1, 111.1111, 11, '1_one_11', 'd', '2001-12-13 01:51:15+1359', '11', '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA', '34.23', '((2,2),1)',
  '((1,2),(2,1))', 'hello', '((1,2),(2,1))', 11, '010101', '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))', 111111, '23:00:00',
  '2001-12-13 01:51:15');

INSERT INTO fsts_busted_co VALUES ( 2, 'b', 22, false, '001', '2_one', '{6,7,8,9,10}', 'Hey.. I am good 2', 'Hey .. I am good 2', '{one,two,three,four,five}', 76767669,
  1, 222.2222, 11, '2_two_22', 'c', '2002-12-13 01:51:15+1359', '22', '0.0.0.0', '0.0.0.0', 'BB:BB:BB:BB:BB:BB', '200.00', '((3,3),2)', '((3,2),(2,3))',
  'hello', '((3,2),(2,3))', 22, '01010100101', '2002-12-13', '((2,2),(3,3))', '(2,2)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))', 11111, '22:00:00', '2002-12-13 01:51:15');

-- Alter the table set distributed by
ALTER TABLE fsts_busted_co SET WITH (reorganize='true') DISTRIBUTED BY (col010);

-- Select from the table
SELECT * FROM fsts_busted_co;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_busted_co;

-- Alter database owner
CREATE ROLE fsts_db_owner2;
ALTER DATABASE fsts_db_name1 OWNER TO fsts_db_owner2;

SET default_tablespace = 'regression_ts_c3';

-- Create new heap tables which will be exchanged
CREATE TABLE fsts_part_tbl_partrange2 (unique1 int4, unique2 int4) TABLESPACE regression_ts_c2
  PARTITION BY RANGE (unique1) (PARTITION aa START (0) END (100) EVERY (25), DEFAULT PARTITION default_part);
CREATE TABLE fsts_part_tbl_partrange_A2 (unique1 int4, unique2 int4) TABLESPACE regression_ts_a2;
INSERT INTO fsts_part_tbl_partrange2 VALUES (generate_series(1,20), generate_series(21,40));
INSERT INTO fsts_part_tbl_partrange_A2 VALUES (generate_series(1,5), generate_series(21,25));
SELECT count(*) FROM fsts_part_tbl_partrange2;

-- Exchange partition (exchange default partition should error as it is not supported)
ALTER TABLE fsts_part_tbl_partrange2 EXCHANGE DEFAULT PARTITION WITH TABLE fsts_part_tbl_partrange_A2;
ALTER TABLE fsts_part_tbl_partrange2 EXCHANGE PARTITION FOR (RANK(1)) WITH TABLE fsts_part_tbl_partrange_A2;
SELECT count(*) FROM fsts_part_tbl_partrange2;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_partrange2;

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_partrange2 SET TABLESPACE regression_ts_b2;

-- Insert few records into the table
INSERT INTO fsts_part_tbl_partrange2 VALUES (generate_series(5,50), generate_series(15,60));
INSERT INTO fsts_part_tbl_partrange_A2 VALUES (generate_series(1,10), generate_series(21,30));

-- Alter the table set distributed by
ALTER TABLE fsts_part_tbl_partrange2 SET WITH (reorganize='true') DISTRIBUTED BY (unique2);

-- Select from the table
SELECT count(*) FROM fsts_part_tbl_partrange2;

-- Drop partition for RANK(1), change tablespace, and check row count
ALTER TABLE fsts_part_tbl_partrange2 DROP PARTITION FOR (RANK(1));
ALTER TABLE fsts_part_tbl_partrange2 SET TABLESPACE regression_ts_c3;
SELECT count(*) FROM fsts_part_tbl_partrange2;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_partrange2;

-- Create heap list partition table
CREATE TABLE fsts_test_part8 (id int, name text, rank int, year date, gender char(1)) TABLESPACE regression_ts_a2 DISTRIBUTED RANDOMLY
  PARTITION BY LIST (gender) SUBPARTITION BY RANGE (year) SUBPARTITION TEMPLATE (START (date '2001-01-01')) (VALUES ('M'), VALUES ('F'));

-- Alter partition table alter set distributed by
ALTER TABLE fsts_test_part8 SET DISTRIBUTED BY (id, gender, year);

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_part8;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_part8_1_prt_2 SET TABLESPACE regression_ts_b1;

-- Insert few records into the table
INSERT INTO fsts_test_part8 VALUES (1,'ann',1,'2001-01-01','F');
INSERT INTO fsts_test_part8 VALUES (2,'ben',2,'2002-01-01','M');
INSERT INTO fsts_test_part8 VALUES (3,'leni',3,'2003-01-01','F');
INSERT INTO fsts_test_part8 VALUES (4,'sam',4,'2003-01-01','M');

-- Select from the table
SELECT * FROM fsts_test_part8;

-- Add column
ALTER TABLE fsts_test_part8 ADD COLUMN new_int_column int;

-- Drop Column
ALTER TABLE fsts_test_part8 DROP COLUMN new_int_column;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_part8_1_prt_2 SET TABLESPACE regression_ts_b2;

-- Truncate table
TRUNCATE fsts_test_part8;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_part8;

-- Alter database again
CREATE SCHEMA fsts_myschema;
ALTER DATABASE fsts_db_name1 SET search_path TO fsts_myschema, public, pg_catalog;

SET default_tablespace='regression_ts_b1';

-- Create heap table to alter column type
CREATE TABLE fsts_test_alter_table2(text_col text, bigint_col bigint, char_vary_col character varying(30), numeric_col numeric, int_col int4,
  float_col float4, int_array_col int[], before_rename_col int4, change_datatype_col numeric, a_ts_without timestamp without time zone,
  b_ts_with timestamp with time zone, date_column date, col_set_default numeric) TABLESPACE regression_ts_a1 DISTRIBUTED RANDOMLY;

-- Alter column type
ALTER TABLE fsts_test_alter_table2 ALTER COLUMN change_datatype_col TYPE int4;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_alter_table2;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_alter_table2 SET TABLESPACE regression_ts_b3;

-- Insert few records into the table
INSERT INTO fsts_test_alter_table2 VALUES ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000', 0);
INSERT INTO fsts_test_alter_table2 VALUES ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001', 1);
INSERT INTO fsts_test_alter_table2 VALUES ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002', 2);

-- Add column and insert few records after altering tablespace
ALTER TABLE fsts_test_alter_table2 ADD COLUMN added_col character varying(30) DEFAULT 'test_value';
ALTER TABLE fsts_test_alter_table2 SET TABLESPACE regression_ts_b2;
INSERT INTO fsts_test_alter_table2 VALUES ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000',0);
INSERT INTO fsts_test_alter_table2 VALUES ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001',1);
INSERT INTO fsts_test_alter_table2 VALUES ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',2);

-- Select from the table
SELECT * FROM fsts_test_alter_table2;

-- Alter the newly added column and try to insert some rows after altering tablespace
ALTER TABLE fsts_test_alter_table2 SET TABLESPACE regression_ts_b3;
ALTER TABLE fsts_test_alter_table2 ALTER COLUMN added_col SET DEFAULT 'new_test_value';
INSERT INTO fsts_test_alter_table2 VALUES ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000',0);
INSERT INTO fsts_test_alter_table2 VALUES ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001',1);
ALTER TABLE fsts_test_alter_table2 SET TABLESPACE regression_ts_c1;
ALTER TABLE fsts_test_alter_table2 RENAME COLUMN added_col TO added_col_renamed;
INSERT INTO fsts_test_alter_table2 VALUES ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',2);
ALTER TABLE fsts_test_alter_table2 ALTER COLUMN added_col_renamed DROP DEFAULT;
INSERT INTO fsts_test_alter_table2 VALUES ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',2);

-- Select from the table
SELECT * FROM fsts_test_alter_table2;

-- Drop a toast and non-toast column and then alter tablespace
ALTER TABLE fsts_test_alter_table2 DROP COLUMN text_col;
ALTER TABLE fsts_test_alter_table2 DROP COLUMN numeric_col;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_alter_table2;

-- Try adding a row after changing the tablespace
ALTER TABLE fsts_test_alter_table2 SET TABLESPACE regression_ts_c1;
INSERT INTO fsts_test_alter_table2 VALUES (3, '3_zero', 3, 3, '{3}', 3, 3, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',3);

-- Alter the table set distributed by
ALTER TABLE fsts_test_alter_table2 SET WITH (reorganize='true') DISTRIBUTED BY (bigint_col);

-- Select from the table
SELECT * FROM fsts_test_alter_table2;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_alter_table2;

-- Reset search path
ALTER DATABASE fsts_db_name1 RESET search_path;

-- Create partition table to split
CREATE TABLE fsts_part_tbl_split_range2 (i int) TABLESPACE regression_ts_c1 PARTITION BY RANGE(i) (START(1) END(10) EVERY(5), DEFAULT PARTITION default_part);

-- Split Partition Range
ALTER TABLE fsts_part_tbl_split_range2 SPLIT PARTITION FOR(1) AT (5) INTO (PARTITION aa, PARTITION bb);
ALTER TABLE fsts_part_tbl_split_range2 SPLIT DEFAULT PARTITION START(11) END(12) INTO (PARTITION a3, DEFAULT PARTITION);

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_split_range2;

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_split_range2 SET TABLESPACE regression_ts_b3;

-- Insert few records into the table
INSERT INTO fsts_part_tbl_split_range2 VALUES (generate_series(1,9));

-- Alter the table set distributed by
ALTER TABLE fsts_part_tbl_split_range2 SET WITH (reorganize='true') DISTRIBUTED RANDOMLY;

-- Select from the table
SELECT count(*) FROM fsts_part_tbl_split_range2;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_split_range2;

-- Alter reset all the database
ALTER DATABASE fsts_db_name1 RESET ALL;

-- Create new heap table for more alter tests
CREATE TABLE fsts_alter_table1(col_text text, col_numeric numeric NOT NULL) TABLESPACE regression_ts_a2 DISTRIBUTED RANDOMLY;
INSERT INTO fsts_alter_table1 VALUES ('0_zero', 0);
INSERT INTO fsts_alter_table1 VALUES ('1_one', 1);

-- Test alter column [ set | drop ] not null and then alter tablespace
ALTER TABLE fsts_alter_table1 ALTER COLUMN col_numeric DROP NOT NULL;
ALTER TABLE fsts_alter_table1 ALTER COLUMN col_numeric SET NOT NULL;
ALTER TABLE fsts_alter_table1 SET TABLESPACE regression_ts_b1;
INSERT INTO fsts_alter_table1 VALUES ('0_zero', 0);
INSERT INTO fsts_alter_table1 VALUES ('2_two', 2);
SELECT * FROM fsts_alter_table1;

-- Test altering statistics
ALTER TABLE fsts_alter_table1 ALTER col_numeric SET STATISTICS 1;
SELECT attstattarget FROM pg_attribute WHERE attrelid = 'public.fsts_alter_table1'::regclass AND attname = 'col_numeric';
ALTER TABLE fsts_alter_table1 SET TABLESPACE regression_ts_c2;
INSERT INTO fsts_alter_table1 VALUES ('0_zero', 0);
INSERT INTO fsts_alter_table1 VALUES ('3_three', 3);

-- Test altering storage
ALTER TABLE fsts_alter_table1 ALTER col_text SET STORAGE PLAIN;
ALTER TABLE fsts_alter_table1 SET TABLESPACE regression_ts_c3;
INSERT INTO fsts_alter_table1 VALUES ('4_four', 4);

-- Select from the table
SELECT * FROM fsts_alter_table1;

-- Test altering table owner
ALTER TABLE fsts_alter_table1 OWNER TO fsts_db_owner1;
ALTER TABLE fsts_alter_table1 SET TABLESPACE regression_ts_b3;
INSERT INTO fsts_alter_table1 VALUES ('5_five', 5);

-- Alter the table set distributed by
ALTER TABLE fsts_alter_table1 SET WITH (reorganize=true) DISTRIBUTED BY (col_numeric);

-- Truncate and vacuum analyze
TRUNCATE fsts_alter_table1;
VACUUM ANALYZE fsts_alter_table1;
SELECT * FROM fsts_alter_table1;

-- Create new heap table with constraint
CREATE TABLE fsts_films (code char(5), title varchar(40), did integer, date_prod date, kind varchar(10),
  len interval hour to minute, CONSTRAINT production UNIQUE(date_prod)) TABLESPACE regression_ts_a2;

-- Insert few records
INSERT INTO fsts_films VALUES ('aaa','Heavenly Life',1,'2008-03-03','good','2 hr 30 mins');
INSERT INTO fsts_films VALUES ('bbb','Beautiful Mind',2,'2007-05-05','good','1 hr 30 mins');
INSERT INTO fsts_films VALUES ('ccc','Wonderful Earth',3,'2009-03-03','good','2 hr 15 mins');

-- Select from the table
SELECT * FROM fsts_films;

-- Alter Table Drop Constraint
ALTER TABLE fsts_films DROP CONSTRAINT production RESTRICT;

-- Alter Table Add Unique Constraint
ALTER TABLE fsts_films ADD UNIQUE(date_prod);

-- Drop the unique constraint
ALTER TABLE fsts_films DROP CONSTRAINT fsts_films_date_prod_key;

-- Alter the table to new tablespace
ALTER TABLE fsts_films SET TABLESPACE regression_ts_c2;

-- Insert few records
INSERT INTO fsts_films VALUES ('aaa','Heavenly Life',1,'2008-03-03','good','2 hr 30 mins');
INSERT INTO fsts_films VALUES ('bbb','Beautiful Mind',2,'2007-05-05','good','1 hr 30 mins');
INSERT INTO fsts_films VALUES ('ccc','Wonderful Earth',3,'2009-03-03','good','2 hr 15 mins');

-- Select from the table
SELECT * FROM fsts_films;

-- Truncate table
TRUNCATE fsts_films;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_films;

-- Create some heap tables to test inheritance
CREATE TABLE fsts_parent_table (text_col text, bigint_col bigint, char_vary_col character varying(30),
  numeric_col numeric) TABLESPACE regression_ts_a2 DISTRIBUTED RANDOMLY;

CREATE TABLE fsts_child_table(text_col text, bigint_col bigint, char_vary_col character varying(30),
  numeric_col numeric) TABLESPACE regression_ts_b1 DISTRIBUTED RANDOMLY;

-- Insert few records into the tables
INSERT INTO fsts_parent_table VALUES ('0_zero', 0, '0_zero', 0);
INSERT INTO fsts_parent_table VALUES ('1_zero', 1, '1_zero', 1);
INSERT INTO fsts_parent_table VALUES ('2_zero', 2, '2_zero', 2);
INSERT INTO fsts_child_table VALUES ('3_zero', 3, '3_zero', 3);

-- Select from the table
SELECT * FROM fsts_child_table;

-- Inherit from Parent Table
ALTER TABLE fsts_child_table INHERIT fsts_parent_table;

-- No Inherit from Parent Table
ALTER TABLE fsts_child_table NO INHERIT fsts_parent_table;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_child_table;

-- Alter the table to new tablespace
ALTER TABLE fsts_child_table SET TABLESPACE regression_ts_c2;

-- Insert few records into the tables
INSERT INTO fsts_parent_table VALUES ('0_zero', 0, '0_zero', 0);
INSERT INTO fsts_parent_table VALUES ('1_zero', 1, '1_zero', 1);
INSERT INTO fsts_parent_table VALUES ('2_zero', 2, '2_zero', 2);
INSERT INTO fsts_child_table VALUES ('3_zero', 3, '3_zero', 3);

-- Alter the table set distributed by
ALTER TABLE fsts_child_table SET WITH (reorganize=true) DISTRIBUTED BY (numeric_col);

-- Select from the table
SELECT * FROM fsts_child_table;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_child_table;

-- Create table in different schema and another schema to move the table into
CREATE TABLE fsts_myschema.fsts_csc (stud_id int, stud_name varchar(20)) TABLESPACE regression_ts_c3 DISTRIBUTED RANDOMLY;
CREATE SCHEMA fsts_new_dept;

-- Insert few records into the table
INSERT INTO fsts_myschema.fsts_csc VALUES (1,'ann');
INSERT INTO fsts_myschema.fsts_csc VALUES (2,'ben');
INSERT INTO fsts_myschema.fsts_csc VALUES (3,'sam');

-- Select from the table
SELECT * FROM fsts_myschema.fsts_csc;

-- Alter the table schema
ALTER TABLE fsts_myschema.fsts_csc SET SCHEMA fsts_new_dept;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_new_dept.fsts_csc;

-- Alter the table to new tablespace
ALTER TABLE fsts_new_dept.fsts_csc SET TABLESPACE regression_ts_a1;

-- Insert few records into the table
INSERT INTO fsts_new_dept.fsts_csc VALUES (1,'ann');
INSERT INTO fsts_new_dept.fsts_csc VALUES (2,'ben');
INSERT INTO fsts_new_dept.fsts_csc VALUES (3,'sam');

-- Alter the table to add a toastable column
ALTER TABLE fsts_new_dept.fsts_csc ADD COLUMN text_column text DEFAULT 'just text';

-- Select from the table
SELECT * FROM fsts_new_dept.fsts_csc;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_new_dept.fsts_csc;

-- Create table with oids
CREATE TABLE fsts_table_with_oid (text_col text, bigint_col bigint, char_vary_col character varying(30),
  numeric_col numeric) WITH OIDS TABLESPACE regression_ts_b3 DISTRIBUTED RANDOMLY;

-- Insert few records into the table
INSERT INTO fsts_table_with_oid VALUES ('0_zero', 0, '0_zero', 0);
INSERT INTO fsts_table_with_oid VALUES ('1_zero', 1, '1_zero', 1);
INSERT INTO fsts_table_with_oid VALUES ('2_zero', 2, '2_zero', 2);

-- Select from the table
SELECT * FROM fsts_table_with_oid;

-- Set without OIDS
ALTER TABLE fsts_table_with_oid SET WITHOUT OIDS;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_table_with_oid;

-- Alter the table to new tablespace
ALTER TABLE fsts_table_with_oid SET TABLESPACE regression_ts_a2;

-- Insert few records into the table
INSERT INTO fsts_table_with_oid VALUES ('0_zero', 0, '0_zero', 0);
INSERT INTO fsts_table_with_oid VALUES ('1_zero', 1, '1_zero', 1);
INSERT INTO fsts_table_with_oid VALUES ('2_zero', 2, '2_zero', 2);

-- Alter the table set distributed by
ALTER TABLE fsts_table_with_oid SET WITH (reorganize=true) DISTRIBUTED BY (numeric_col);

-- Select from the table
SELECT * FROM fsts_table_with_oid;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_table_with_oid;

-- Create AO table
CREATE TABLE fsts_table_set_storage_parameters (text_col text, bigint_col bigint, char_vary_col character varying(30),
  numeric_col numeric) WITH (APPENDONLY=TRUE) TABLESPACE regression_ts_b2 DISTRIBUTED RANDOMLY;

-- Create an index for the creation of block dir
CREATE INDEX fsts_table_set_storage_parameters_index on fsts_table_set_storage_parameters(bigint_col);

-- Insert few records into the table
INSERT INTO fsts_table_set_storage_parameters VALUES ('0_zero', 0, '0_zero', 0);
INSERT INTO fsts_table_set_storage_parameters VALUES ('1_zero', 1, '1_zero', 1);
INSERT INTO fsts_table_set_storage_parameters VALUES ('2_zero', 2, '2_zero', 2);

-- Select from the table
SELECT * FROM fsts_table_set_storage_parameters;

-- Alter the table to new tablespace
ALTER TABLE fsts_table_set_storage_parameters SET TABLESPACE regression_ts_c1;

-- Insert few records into the table
INSERT INTO fsts_table_set_storage_parameters VALUES ('0_zero', 0, '0_zero', 0);
INSERT INTO fsts_table_set_storage_parameters VALUES ('1_zero', 1, '1_zero', 1);
INSERT INTO fsts_table_set_storage_parameters VALUES ('2_zero', 2, '2_zero', 2);

-- Alter the table set distributed by
ALTER TABLE fsts_table_set_storage_parameters SET WITH (reorganize='true') DISTRIBUTED BY (numeric_col);

-- Select from the table
SELECT * FROM fsts_table_set_storage_parameters;

-- Create some heap tables to test triggers
CREATE TABLE fsts_price_change (apn CHARACTER(15) NOT NULL, effective TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  price NUMERIC(9,2), UNIQUE (apn, effective)) TABLESPACE regression_ts_a3;
CREATE TABLE fsts_stock(fsts_stock_apn CHARACTER(15) NOT NULL, fsts_stock_effective TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fsts_stock_price NUMERIC(9,2)) TABLESPACE regression_ts_b2 DISTRIBUTED RANDOMLY;


-- Trigger function to insert records as required
CREATE OR REPLACE FUNCTION fsts_insert_fsts_price_change() RETURNS TRIGGER AS '
DECLARE
changed boolean;
BEGIN
IF tg_op = ''DELETE'' THEN
INSERT INTO fsts_price_change(apn, effective, price)
VALUES (old.barcode, CURRENT_TIMESTAMP, NULL);
RETURN old;
END IF;
IF tg_op = ''INSERT'' THEN
changed := TRUE;
ELSE
changed := new.price IS NULL != old.price IS NULL OR new.price != old.price;
END IF;
IF changed THEN
INSERT INTO fsts_price_change(apn, effective, price)
VALUES (new.barcode, CURRENT_TIMESTAMP, new.price);
END IF;
RETURN new;
END' LANGUAGE plpgsql;

-- Create a trigger on one of the tables
CREATE TRIGGER fsts_insert_fsts_price_change AFTER INSERT OR DELETE OR UPDATE ON fsts_stock
  FOR EACH ROW EXECUTE PROCEDURE fsts_insert_fsts_price_change();

-- Disable Trigger
ALTER TABLE fsts_stock DISABLE TRIGGER fsts_insert_fsts_price_change;

-- Enable Trigger
ALTER TABLE fsts_stock ENABLE TRIGGER fsts_insert_fsts_price_change;

-- Alter the table to new tablespace
ALTER TABLE fsts_stock SET TABLESPACE regression_ts_a2;

-- Alter the table set distributed by
ALTER TABLE fsts_stock SET WITH (reorganize='true') DISTRIBUTED BY (fsts_stock_price);

-- Vacuum analyze the table
VACUUM ANALYZE fsts_stock;

-- Create a heap table with an index to cluster with
CREATE TABLE fsts_cluster_index_table (col1 int, col2 int) TABLESPACE regression_ts_c3 DISTRIBUTED RANDOMLY;
CREATE INDEX fsts_clusterindex ON fsts_cluster_index_table(col1);

-- Insert few records into the table
INSERT INTO fsts_cluster_index_table VALUES (1,1);
INSERT INTO fsts_cluster_index_table VALUES (2,2);
INSERT INTO fsts_cluster_index_table VALUES (3,3);
INSERT INTO fsts_cluster_index_table VALUES (4,4);
INSERT INTO fsts_cluster_index_table VALUES (5,5);

-- Select from the table
SELECT * FROM fsts_cluster_index_table;

-- Cluster an Index
ALTER TABLE fsts_cluster_index_table CLUSTER ON fsts_clusterindex;

-- Set without Cluster
ALTER TABLE fsts_cluster_index_table SET WITHOUT CLUSTER;

--Vacuum analyze the table
VACUUM ANALYZE fsts_cluster_index_table;

-- Alter the table to new tablespace
ALTER TABLE fsts_cluster_index_table SET TABLESPACE regression_ts_a2;

-- Insert few records into the table
INSERT INTO fsts_cluster_index_table VALUES (6,6);
INSERT INTO fsts_cluster_index_table VALUES (7,7);
INSERT INTO fsts_cluster_index_table VALUES (8,8);
INSERT INTO fsts_cluster_index_table VALUES (9,9);
INSERT INTO fsts_cluster_index_table VALUES (0,0);

-- Reindex
REINDEX INDEX fsts_clusterindex;

-- Alter the table set distributed by
ALTER TABLE fsts_cluster_index_table SET WITH (reorganize='true') DISTRIBUTED BY (col2);

-- Select from the table
SELECT * FROM fsts_cluster_index_table;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_cluster_index_table;

-- Create heap table and indexes w/ non-default tablespace
CREATE TABLE fsts_test_emp1 (ename text, eno int, salary int, ssn int, gender char(1))
  TABLESPACE regression_ts_a2 DISTRIBUTED BY (ename,eno,gender);
CREATE UNIQUE INDEX fsts_eno_idx ON fsts_test_emp1(eno) TABLESPACE regression_ts_c2;
CREATE INDEX fsts_ename_idex ON fsts_test_emp1((upper(ename))) WITH (fillfactor=80)
  TABLESPACE regression_ts_a1 WHERE upper(ename)='JIM';
CREATE INDEX fsts_gender_bmp_idx ON fsts_test_emp1 USING bitmap(gender) TABLESPACE regression_ts_c3;

-- Insert few records into the table
INSERT INTO fsts_test_emp1 VALUES ('ann',1,700000,12878927,'f');
INSERT INTO fsts_test_emp1 VALUES ('sam',2,600000,23445556,'m');
INSERT INTO fsts_test_emp1 VALUES ('tom',3,800000,444444444,'m');
INSERT INTO fsts_test_emp1 VALUES ('dan',4,900000,78888888,'m');
INSERT INTO fsts_test_emp1 VALUES ('len',5,500000,34567653,'m');

-- Select from the table
SELECT * FROM fsts_test_emp1;

-- Alter fillfactor settings
ALTER INDEX fsts_ename_idex SET (fillfactor=100);
ALTER INDEX fsts_ename_idex RESET (fillfactor);

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_emp1;

-- Alter the Index to new tablespace
ALTER INDEX fsts_eno_idx SET TABLESPACE regression_ts_b2;
ALTER INDEX fsts_ename_idex SET TABLESPACE regression_ts_b2;
ALTER INDEX fsts_gender_bmp_idx SET TABLESPACE regression_ts_b2;

-- Insert few records into the table
INSERT INTO fsts_test_emp1 VALUES ('jen',6,700000,12878927,'f');
INSERT INTO fsts_test_emp1 VALUES ('ian',7,600000,23445556,'m');
INSERT INTO fsts_test_emp1 VALUES ('dave',8,800000,444444444,'m');
INSERT INTO fsts_test_emp1 VALUES ('jeff',9,900000,78888888,'m');
INSERT INTO fsts_test_emp1 VALUES ('jim',10,500000,34567653,'m');

-- Reindex
REINDEX INDEX fsts_eno_idx;
REINDEX INDEX fsts_ename_idex;
REINDEX INDEX fsts_gender_bmp_idx;

-- Select from the table
SELECT * FROM fsts_test_emp1;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_emp1;

-- Create AO partition table
CREATE TABLE fsts_test_aopart (id int, name text, rank int, year date, gender char(1)) WITH (appendonly=true)
  TABLESPACE regression_ts_a3 DISTRIBUTED BY (id, gender, year) PARTITION BY LIST (gender)
  SUBPARTITION BY RANGE (year) SUBPARTITION TEMPLATE (start (date '2001-01-01')) (values ('M'), values ('F'));

-- Create an index for the creation of block dir
CREATE INDEX fsts_test_aopart_index ON fsts_test_aopart(id);

-- Add default partition and rename it
ALTER TABLE fsts_test_aopart ADD DEFAULT PARTITION default_part;
ALTER TABLE fsts_test_aopart RENAME DEFAULT PARTITION to new_default_part;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_aopart;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_aopart SET TABLESPACE regression_ts_a2;

-- Insert few records into the table
INSERT INTO fsts_test_aopart VALUES (1,'ann',1,'2001-01-01','F');
INSERT INTO fsts_test_aopart VALUES (2,'cthulu',2,'2002-01-01','U');
INSERT INTO fsts_test_aopart VALUES (3,'loni',3,'2003-01-01','F');
INSERT INTO fsts_test_aopart VALUES (4,'sam',4,'2003-01-01','M');

-- Rename the table
ALTER TABLE fsts_test_aopart RENAME TO fsts_test_aopart_renamed;

-- Truncate the default partition
ALTER TABLE fsts_test_aopart_renamed TRUNCATE DEFAULT PARTITION;

-- Alter the table to new tablespace
ALTER TABLE fsts_test_aopart_renamed SET TABLESPACE regression_ts_b2;

-- Insert few records into the table
INSERT INTO fsts_test_aopart_renamed VALUES (1,'ann',1,'2001-01-01','F');
INSERT INTO fsts_test_aopart_renamed VALUES (2,'ben',2,'2002-01-01','M');
INSERT INTO fsts_test_aopart_renamed VALUES (3,'leni',3,'2003-01-01','F');
INSERT INTO fsts_test_aopart_renamed VALUES (4,'sam',4,'2003-01-01','M');

-- Drop Default Partition
ALTER TABLE fsts_test_aopart_renamed DROP DEFAULT PARTITION IF EXISTS;

-- Alter the table set distributed by
ALTER TABLE fsts_test_aopart_renamed SET WITH (reorganize='true') DISTRIBUTED BY (id);

-- Restore original table name
ALTER TABLE fsts_test_aopart_renamed RENAME TO fsts_test_aopart;

-- Select from the table
SELECT * FROM fsts_test_aopart;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_test_aopart;

-- Create AOCO partition table
CREATE TABLE fsts_part_tbl_add1(a char, b int, d char,e text) WITH (orientation=column, appendonly=true) TABLESPACE regression_ts_b2
  PARTITION BY RANGE(b) SUBPARTITION BY LIST(d)
  SUBPARTITION TEMPLATE(SUBPARTITION sp1 VALUES ('a'), SUBPARTITION sp2 VALUES ('b'))
  (START (1) END (10) EVERY (5));

-- Create an index for the creation of block dir
CREATE INDEX fsts_part_tbl_add1_index ON fsts_part_tbl_add1(b);

-- Insert few records into the table
INSERT INTO fsts_part_tbl_add1 VALUES ('a',1,'b','test_1');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',2,'b','test_2');
INSERT INTO fsts_part_tbl_add1 VALUES ('b',3,'b','test_3');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',4,'a','test_4');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',5,'a','test_5');

-- Select from the table
SELECT * FROM fsts_part_tbl_add1;

-- Add partition
ALTER TABLE fsts_part_tbl_add1 ADD PARTITION p1 END(11);

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_add1;

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_add1 SET TABLESPACE regression_ts_c3;

-- Insert few records into the table
INSERT INTO fsts_part_tbl_add1 VALUES ('a',1,'b','test_1');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',2,'b','test_2');
INSERT INTO fsts_part_tbl_add1 VALUES ('b',3,'b','test_3');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',4,'a','test_4');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',5,'a','test_5');

-- Set subpartition template
ALTER TABLE fsts_part_tbl_add1 SET SUBPARTITION TEMPLATE();

-- Add Partition
ALTER TABLE fsts_part_tbl_add1 ADD PARTITION p3 END(13) (SUBPARTITION sp3 VALUES ('c'));

-- Set subpartition template
ALTER TABLE fsts_part_tbl_add1 SET SUBPARTITION TEMPLATE (SUBPARTITION sp3 values ('c'));

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_add1_1_prt_1_2_prt_sp1 SET TABLESPACE regression_ts_a3;

-- Insert few records into the table
INSERT INTO fsts_part_tbl_add1 VALUES ('a',6,'b','test_6');
INSERT INTO fsts_part_tbl_add1 VALUES ('a',7,'b','test_7');
INSERT INTO fsts_part_tbl_add1 VALUES ('b',8,'b','test_8');

-- Alter the table set distributed by
ALTER TABLE fsts_part_tbl_add1 SET WITH (reorganize='true') DISTRIBUTED BY (b);

-- Select from the table
SELECT * FROM fsts_part_tbl_add1;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_add1;

-- Create AOCO table
CREATE TABLE fsts_part_tbl_add3(aa date, bb date) WITH (orientation=column, appendonly=true) TABLESPACE regression_ts_a2
  PARTITION BY RANGE(bb) (PARTITION foo START('2008-01-01'));

-- Create an index for the creation of block dir
CREATE INDEX fsts_part_tbl_add3_index ON fsts_part_tbl_add3(aa);

-- Insert few records into the table
INSERT INTO fsts_part_tbl_add3 VALUES ('2007-01-01','2008-01-01');
INSERT INTO fsts_part_tbl_add3 VALUES ('2008-01-01','2009-01-01');
INSERT INTO fsts_part_tbl_add3 VALUES ('2009-01-01','2010-01-01');

-- Select from the table
SELECT * FROM fsts_part_tbl_add3;

-- Add Partition
ALTER TABLE fsts_part_tbl_add3 ADD PARTITION a1 START('2007-01-01') END('2007-02-01');

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_add3_1_prt_foo SET TABLESPACE regression_ts_b1;

-- Insert few records into the table
INSERT INTO fsts_part_tbl_add3 VALUES ('2007-01-02','2008-01-02');
INSERT INTO fsts_part_tbl_add3 VALUES ('2008-01-01','2009-01-01');
INSERT INTO fsts_part_tbl_add3 VALUES ('2009-01-01','2010-01-01');
INSERT INTO fsts_part_tbl_add3 VALUES ('2006-01-01','2007-01-01');

-- Truncate partition
ALTER TABLE fsts_part_tbl_add3 TRUNCATE PARTITION FOR (RANK(1));

-- Select from the table
SELECT * FROM fsts_part_tbl_add3;

-- Drop partition
ALTER TABLE fsts_part_tbl_add3 DROP PARTITION a1;
ALTER TABLE fsts_part_tbl_add3 DROP PARTITION IF EXISTS a1; -- should skip

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_add3 SET TABLESPACE regression_ts_c3;

-- Insert a record into the table
INSERT INTO fsts_part_tbl_add3 VALUES ('2009-01-05','2010-01-05');

-- Select from the table
SELECT * FROM fsts_part_tbl_add3;

-- Truncate table
TRUNCATE fsts_part_tbl_add3;

-- Vacuum Analyze
VACUUM ANALYZE fsts_part_tbl_add3;

-- Create AOCO partition table
CREATE TABLE fsts_part_tbl1(id int, rank int, year int, gender char(1), name text, count int)
  WITH (orientation='column',appendonly=true) TABLESPACE regression_ts_b3 DISTRIBUTED BY (id)
  PARTITION BY LIST (gender) SUBPARTITION BY RANGE (year)
  SUBPARTITION TEMPLATE (SUBPARTITION year1 START (2001), SUBPARTITION year2 START (2002),
                         SUBPARTITION year6 START (2006) END (2007))
  (PARTITION girls VALUES ('F'), PARTITION boys VALUES ('M'));

-- Create an index for the creation of block dir
CREATE INDEX fsts_part_tbl1_index ON fsts_part_tbl1(id);

-- Insert few records into the table
INSERT INTO fsts_part_tbl1 VALUES (1,1,2001,'F',6);
INSERT INTO fsts_part_tbl1 VALUES (2,2,2002,'M',7);
INSERT INTO fsts_part_tbl1 VALUES (3,3,2003,'F',8);
INSERT INTO fsts_part_tbl1 VALUES (4,4,2003,'M',9);

-- Select from the table
SELECT * FROM fsts_part_tbl1;

-- Add default partitions
ALTER TABLE fsts_part_tbl1 ALTER PARTITION girls ADD DEFAULT PARTITION gfuture;
ALTER TABLE fsts_part_tbl1 ALTER PARTITION boys ADD DEFAULT PARTITION bfuture;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl1;

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl1_1_prt_girls SET TABLESPACE regression_ts_c2;

-- Insert few records into the table
INSERT INTO fsts_part_tbl1 VALUES (1,1,2001,'F',6);
INSERT INTO fsts_part_tbl1 VALUES (2,2,2002,'M',7);
INSERT INTO fsts_part_tbl1 VALUES (3,3,2003,'F',8);
INSERT INTO fsts_part_tbl1 VALUES (4,4,2003,'M',9);

-- Alter the table set distributed by
ALTER TABLE fsts_part_tbl1 SET WITH (reorganize='true') DISTRIBUTED RANDOMLY;

-- Select from the table
SELECT * FROM fsts_part_tbl1;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl1;

-- Create new heap tables which will be exchanged
CREATE TABLE fsts_part_tbl_partlist5 (unique1 int4, unique2 int4) TABLESPACE regression_ts_c2 PARTITION BY LIST(unique1)
  (PARTITION aa VALUES(1,2,3,4,5), PARTITION bb VALUES (6,7,8,9,10), DEFAULT PARTITION default_part);
CREATE TABLE fsts_part_tbl_partlist_A5 (unique1 int4, unique2 int4) TABLESPACE regression_ts_a2;

-- Exchange list partition and insert some rows
ALTER TABLE fsts_part_tbl_partlist5 EXCHANGE PARTITION aa WITH TABLE fsts_part_tbl_partlist_A5;
INSERT INTO fsts_part_tbl_partlist_A5 VALUES (generate_series(1,5), generate_series(21,25));

-- Select from the table
SELECT count(*) FROM fsts_part_tbl_partlist5;

-- Truncate table
TRUNCATE fsts_part_tbl_partlist_A5;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_partlist_A5;

-- Rename partition
ALTER TABLE fsts_part_tbl_partlist5 RENAME PARTITION bb to bb_renamed;

-- Alter the table to new tablespace and insert some rows
ALTER TABLE fsts_part_tbl_partlist5_1_prt_aa SET TABLESPACE regression_ts_b3;
INSERT INTO fsts_part_tbl_partlist5 VALUES (generate_series(5,50), generate_series(15,60));

-- Alter the table set distributed by
ALTER TABLE fsts_part_tbl_partlist5 SET WITH (reorganize='true') DISTRIBUTED BY (unique2);

-- Select from the table
SELECT count(*) FROM fsts_part_tbl_partlist5;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_partlist_A5;

-- Create list partition table to split
CREATE TABLE fsts_part_tbl_split_list1(a text, b text) TABLESPACE regression_ts_a1 PARTITION BY LIST (a)
  (PARTITION foo VALUES('foo', 'foonorf'), PARTITION bar VALUES('bar'), DEFAULT PARTITION baz);

-- Insert few records into the table
INSERT INTO fsts_part_tbl_split_list1 VALUES ('foo','foo');
INSERT INTO fsts_part_tbl_split_list1 VALUES ('bar','bar');
INSERT INTO fsts_part_tbl_split_list1 VALUES ('foonorf','bar');

-- Select from the table
SELECT * FROM fsts_part_tbl_split_list1;

-- Truncate Table
TRUNCATE fsts_part_tbl_split_list1;

-- Split default and regular partition
ALTER TABLE fsts_part_tbl_split_list1 SPLIT DEFAULT PARTITION AT('baz') INTO (PARTITION bing, DEFAULT PARTITION);
ALTER TABLE fsts_part_tbl_split_list1 SPLIT PARTITION FOR('foonorf') AT('foo') INTO (partition fooa, partition foonorf);

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_split_list1;

-- Alter the table to new tablespace
ALTER TABLE fsts_part_tbl_split_list1_1_prt_baz SET TABLESPACE regression_ts_a3;

-- Insert few records into the table
INSERT INTO fsts_part_tbl_split_list1 VALUES ('foo','foo');
INSERT INTO fsts_part_tbl_split_list1 VALUES ('bar','bar');
INSERT INTO fsts_part_tbl_split_list1 VALUES ('foo','bar');

-- Alter the table set distributed by
ALTER TABLE fsts_part_tbl_split_list1 SET WITH (reorganize=true) DISTRIBUTED BY (b);

-- Select from the table
SELECT * FROM fsts_part_tbl_split_list1;

-- Vacuum analyze the table
VACUUM ANALYZE fsts_part_tbl_split_list1;

-- Test heap table with dropping a column, insert select from another similar heap table, adding
-- back the column, and altering the tablespace
CREATE TABLE fsts_busted_heap1(a int, b char DEFAULT 'z', c numeric DEFAULT 100, d boolean DEFAULT false)
  TABLESPACE regression_ts_a1 DISTRIBUTED BY (a);
CREATE TABLE fsts_busted_heap2(a int, b char DEFAULT 'z', c numeric DEFAULT 100, d boolean DEFAULT false)
  TABLESPACE regression_ts_b1 DISTRIBUTED BY (a);
INSERT INTO fsts_busted_heap1 VALUES (1, 'a', 22, true);
INSERT INTO fsts_busted_heap1 VALUES (2, 'f', 33, true);
INSERT INTO fsts_busted_heap1 VALUES (4, 'd', 44, false);
INSERT INTO fsts_busted_heap2 VALUES (generate_series(5,10), 'b', generate_series(55,60), false);

ALTER TABLE fsts_busted_heap1 DROP COLUMN b;
INSERT INTO fsts_busted_heap1 VALUES (11, 99, true);
ALTER TABLE fsts_busted_heap2 DROP COLUMN b;
INSERT INTO fsts_busted_heap2 VALUES (generate_series(10,15), generate_series(75,80), false);
SELECT count(*) FROM fsts_busted_heap1;
SELECT count(*) FROM fsts_busted_heap2;
INSERT INTO fsts_busted_heap1 SELECT * FROM fsts_busted_heap2;
SELECT count(*) FROM fsts_busted_heap1;

ALTER TABLE fsts_busted_heap1 ADD COLUMN b char DEFAULT 'z';
INSERT INTO fsts_busted_heap1 SELECT * FROM fsts_busted_heap2;
SELECT count(*) FROM fsts_busted_heap1;

ALTER TABLE fsts_busted_heap1 SET TABLESPACE regression_ts_c2;
ALTER TABLE fsts_busted_heap2 SET TABLESPACE regression_ts_a3;
SELECT count(*) FROM fsts_busted_heap1;
SELECT count(*) FROM fsts_busted_heap2;

--
-- Filespace/Tablespace Transaction tests
--
BEGIN;
CREATE TABLESPACE regression_ts_a5 FILESPACE regression_fs_a;
ROLLBACK;

CREATE TABLESPACE regression_ts_a5 FILESPACE regression_fs_a;
DROP TABLESPACE regression_ts_a5;

BEGIN;
CREATE TABLESPACE regression_ts_a5 FILESPACE regression_fs_a;
COMMIT;

CREATE TABLE fsts_trans_tbl (a int, b text) TABLESPACE regression_ts_a5 DISTRIBUTED BY (a);
INSERT INTO fsts_trans_tbl VALUES (generate_series(1,5), 'test_1');
SELECT count(*) FROM fsts_trans_tbl;

DROP TABLE fsts_trans_tbl;
BEGIN;
--drop table fsts_trans_tbl;
DROP TABLESPACE regression_ts_a5;
ROLLBACK;

BEGIN;
--drop table fsts_trans_tbl;
DROP TABLESPACE regression_ts_a5;
COMMIT;

-- create and drop transaction - rollback
BEGIN;
CREATE TABLESPACE regression_ts_a5 FILESPACE regression_fs_a;
DROP TABLESPACE regression_ts_a5;
ROLLBACK;

-- create and drop transaction - commit
BEGIN;
CREATE TABLESPACE regression_ts_a5 FILESPACE regression_fs_a;
DROP TABLESPACE regression_ts_a5;
COMMIT;

-- create and rename tablespace - rollback
BEGIN;
CREATE TABLESPACE regression_ts_a6 FILESPACE regression_fs_a;
ALTER TABLESPACE regression_ts_a6 rename TO new_regression_ts_a6;
ALTER TABLESPACE new_regression_ts_a6 RENAME TO regression_ts_a6;
CREATE ROLE fsts_user;
ALTER TABLESPACE regression_ts_a6 OWNER TO fsts_user;
ROLLBACK;

-- create and rename tablespace - commit
BEGIN;
CREATE TABLESPACE regression_ts_a6 FILESPACE regression_fs_a;
ALTER TABLESPACE regression_ts_a6 RENAME TO new_ts_a6;
ALTER TABLESPACE new_ts_a6 RENAME TO regression_ts_a6;
CREATE ROLE fsts_user;
ALTER TABLESPACE regression_ts_a6 OWNER TO fsts_user;
COMMIT;

-- Drop role and the tablespace - rollback
BEGIN;
DROP TABLESPACE regression_ts_a6;
DROP ROLE fsts_user;
ROLLBACK;

-- Drop role and the tablespace - commit
BEGIN;
DROP TABLESPACE regression_ts_a6;
DROP ROLE fsts_user;
COMMIT;

BEGIN;
CREATE TABLESPACE regression_ts_a4 FILESPACE regression_fs_a;
CREATE TABLESPACE regression_ts_b4 FILESPACE regression_fs_b;

CREATE TABLE fsts_split_list1(i int) TABLESPACE regression_ts_a4 PARTITION BY LIST(i) (
  PARTITION a VALUES(1, 2, 3, 4) WITH (appendonly=true,checksum=true,blocksize=819200,compresslevel=8),
  PARTITION b VALUES(5, 6, 7, 8), DEFAULT PARTITION default_part);

-- Insert few records into the table
INSERT INTO fsts_split_list1 VALUES (generate_series(1,10));

-- Select from the table
SELECT count(*) FROM fsts_split_list1;

-- Split partition
ALTER TABLE fsts_split_list1 SPLIT PARTITION FOR(1) AT (1,2) INTO (PARTITION f1a, PARTITION f1b);

-- Alter the table to new tablespace
ALTER TABLE fsts_split_list1_1_prt_default_part SET TABLESPACE regression_ts_b4;

-- Insert few records into the table
INSERT INTO fsts_split_list1 VALUES (generate_series(1,10));

-- Alter the table set distributed by
ALTER TABLE fsts_split_list1 SET WITH (reorganize=true) DISTRIBUTED RANDOMLY;

-- Select from the table
SELECT count(*) FROM fsts_split_list1;
ROLLBACK;

BEGIN;
CREATE TABLESPACE regression_ts_a4 FILESPACE regression_fs_a;
CREATE TABLESPACE regression_ts_b4 FILESPACE regression_fs_b;

CREATE TABLE fsts_split_list1(i int) TABLESPACE regression_ts_a4 PARTITION BY LIST(i) (
  PARTITION a VALUES(1, 2, 3, 4) WITH (appendonly=true,checksum=true,blocksize=819200,compresslevel=8),
  PARTITION b VALUES(5, 6, 7, 8), DEFAULT PARTITION default_part);

-- Insert few records into the table
INSERT INTO fsts_split_list1 VALUES (generate_series(1,10));

-- Select from the table
SELECT count(*) FROM fsts_split_list1;

-- Split partition
ALTER TABLE fsts_split_list1 SPLIT PARTITION FOR(1) AT (1,2) INTO (PARTITION f1a, PARTITION f1b);

-- Alter the table to new tablespace
ALTER TABLE fsts_split_list1_1_prt_default_part SET TABLESPACE regression_ts_b4;

-- Insert few records into the table
INSERT INTO fsts_split_list1 VALUES (generate_series(1,10));

-- Alter the table set distributed by
ALTER TABLE fsts_split_list1 SET WITH (reorganize=true) DISTRIBUTED RANDOMLY;

-- Select from the table
SELECT count(*) FROM fsts_split_list1;
COMMIT;

DROP TABLE fsts_split_list1;
DROP TABLESPACE regression_ts_a4;
DROP TABLESPACE regression_ts_b4;

-- Change tablespace owner after renaming
CREATE TABLESPACE regression_ts_a6 FILESPACE regression_fs_a;
ALTER TABLESPACE regression_ts_a6 RENAME TO new_ts_a6;
ALTER TABLESPACE new_ts_a6 RENAME TO regression_ts_a6;

CREATE ROLE fsts_user;
ALTER TABLESPACE regression_ts_a6 OWNER TO fsts_user;

DROP TABLESPACE regression_ts_a6;
DROP ROLE fsts_user;
CHECKPOINT;

-- Test granting and revoking
CREATE ROLE fsts_up_user1;

CREATE TABLESPACE regression_ts_a100 FILESPACE regression_fs_a;
CREATE TABLE fsts_up_table1(a int) TABLESPACE regression_ts_a100 DISTRIBUTED BY (a);

GRANT CREATE ON TABLESPACE regression_ts_a100 TO fsts_up_user1;
SET ROLE fsts_up_user1;
CREATE TABLE fsts_up_table2(a int) TABLESPACE regression_ts_a100 DISTRIBUTED BY (a);
INSERT INTO fsts_up_table2 VALUES(generate_series(1,5));
RESET ROLE;

--REVOKE CREATE ON TABLESPACE regression_ts_a100 FROM fsts_up_user1;
--SET ROLE fsts_up_user1;
--CREATE TABLE fsts_up_table3(a int) TABLESPACE regression_ts_a100 DISTRIBUTED BY (a);
--RESET ROLE;

ALTER ROLE fsts_up_user1 WITH SUPERUSER;
SET ROLE fsts_up_user1;
SELECT * FROM fsts_up_table2;
RESET ROLE;

ALTER ROLE fsts_up_user1 WITH NOSUPERUSER;
SET ROLE fsts_up_user1;
SELECT * FROM fsts_up_table2;
RESET ROLE;

DROP TABLE fsts_up_table1;
DROP TABLE fsts_up_table2;
DROP TABLE fsts_alter_table1;
DROP TABLE fsts_busted_ao;
DROP TABLE fsts_busted_co;
DROP TABLE fsts_child_table;
DROP TABLE fsts_films;
DROP TABLE fsts_parent_table;
DROP TABLE fsts_part_tbl1;
DROP TABLE fsts_part_tbl_add1;
DROP TABLE fsts_part_tbl_add3;
DROP TABLE fsts_part_tbl_partlist_a5;
DROP TABLE fsts_part_tbl_partrange2;
DROP TABLE fsts_part_tbl_partrange_a2;
DROP TABLE fsts_part_tbl_split_list1;
DROP TABLE fsts_part_tbl_split_range2;
DROP TABLE fsts_price_change;
DROP TABLE fsts_stock;
DROP TABLE fsts_table_set_storage_parameters;
DROP TABLE fsts_table_with_oid;
DROP TABLE fsts_test_alter_table2;
DROP TABLE fsts_test_aopart;
DROP TABLE fsts_test_emp1;
DROP TABLE fsts_test_part5;
DROP TABLE fsts_test_part8;
DROP TABLE fsts_busted_heap1;
DROP TABLE fsts_busted_heap2;
DROP TABLE fsts_cluster_index_table;
\c gptest
DROP DATABASE fsts_db_name1;
DROP TABLESPACE regression_ts_a100;
DROP TABLESPACE regression_ts_a1;
DROP TABLESPACE regression_ts_a2;
DROP TABLESPACE regression_ts_a3;
DROP TABLESPACE regression_ts_b1;
DROP TABLESPACE regression_ts_b2;
DROP TABLESPACE regression_ts_b3;
DROP TABLESPACE regression_ts_c1;
DROP TABLESPACE regression_ts_c2;
DROP TABLESPACE regression_ts_c3;
DROP FILESPACE regression_fs_a;
DROP FILESPACE regression_fs_b;
DROP FILESPACE regression_fs_c;
DROP ROLE fsts_up_user1;
DROP ROLE fsts_db_owner1;
DROP ROLE fsts_db_owner2;
DROP DATABASE regress1;
DROP DATABASE regress3;
DROP DATABASE regress5;