SET SERVEROUTPUT ON

-- START prepare_tables;
-- START trg_on_bus_start_maintenance;
-- START trg_on_bus_end_maintenance;
-- START prc_create_bus_maintenance;
-- START prc_list_cancelled_schedules;

-- INSERT INTO BusMaintenance (maintenanceID, busID) VALUES(1, 1);

-- test: prc_bus_start_maintenance
-- NOTE: dont change these BusID (all belong to company C010) and StaffID (all are maintenance technicians). 
-- BEGIN
--     prc_create_bus_maintenance('B0305', 'S020', t_staffList('ST0002', 'ST0009'));
--     prc_create_bus_maintenance('B0330', 'S015', t_staffList('ST0215', 'ST0365'));
--     prc_create_bus_maintenance('B0372', 'S006', t_staffList('ST0377', 'ST0390'));
-- END;
-- /

-- EXEC prc_list_cancelled_schedules('C010');

-- test: trg_on_bus_end_maintenance
-- maintenanceID may need changing, look at output of prc_bus_start_maintenance
UPDATE BusMaintenance 
SET status = 'completed'
WHERE maintenanceID = 'M00502';

-- test: view_busMaintenanceStats
-- SET SERVEROUTPUT ON
-- SET LINESIZE 120
-- SET PAGESIZE 200

-- COLUMN companyName      HEADING "Company Name"          FORMAT A20
-- COLUMN busID            HEADING "Bus ID"                FORMAT A10
-- COLUMN plateNo          HEADING "Plate No."             FORMAT A10
-- COLUMN avgIntervalDays  HEADING "Avg. interval days"    

-- BREAK ON companyName SKIP 1

-- SELECT * FROM BusMaintenanceStatsView;

-- CLEAR COLUMN
-- CLEAR BREAK


-- test: view_maintStaffRecentJob
-- SET SERVEROUTPUT ON
-- SET LINESIZE 200
-- SET PAGESIZE 200
-- ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- COLUMN staffID HEADING "Staff ID" FORMAT A10
-- COLUMN fullName HEADING "Name" FORMAT A20
-- COLUMN phoneNumber HEADING "Contact no." 
-- COLUMN email HEADING "Email" FORMAT A30
-- COLUMN maintenanceId HEADING "Maint. job ID" FORMAT A14
-- -- COLUMN maintenanceDetails HEADING "Service on bus" FORMAT A50
-- COLUMN serviceItem HEADING "Service" FORMAT A30
-- COLUMN busId HEADING "Bus ID" 
-- COLUMN maintenanceDate HEADING "Done on" FORMAT A15
-- COLUMN remarks HEADING "Remarks" FORMAT A30

-- SELECT * FROM MaintenanceStaffRecentJobView;

-- CLEAR COLUMN 

