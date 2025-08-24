-- LH's personal script 
-- quickly nukes and recreates user
drop user test cascade;

create user test
identified by test
default tablespace users
profile school;

grant dba to test;