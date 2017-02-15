create database db_test_bed;
\c db_test_bed
CREATE RESOURCE QUEUE db_resque1 ACTIVE THRESHOLD 2 COST THRESHOLD 2000.00;
CREATE RESOURCE QUEUE db_resque2 COST THRESHOLD 3000.00 OVERCOMMIT;
CREATE RESOURCE QUEUE DB_RESque3 COST THRESHOLD 2000.0 NOOVERCOMMIT;
CREATE RESOURCE QUEUE DB_RESQUE4 ACTIVE THRESHOLD 2  IGNORE THRESHOLD  1000.0;

ALTER RESOURCE QUEUE db_resque1 ACTIVE THRESHOLD 3 COST THRESHOLD 1000.00;
ALTER RESOURCE QUEUE db_resque2 COST THRESHOLD 300.00 NOOVERCOMMIT;
ALTER RESOURCE QUEUE DB_RESque3 COST THRESHOLD 200.0 OVERCOMMIT;
ALTER RESOURCE QUEUE DB_RESQUE4 ACTIVE THRESHOLD 5  IGNORE THRESHOLD  500.0;
