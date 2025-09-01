SET SERVEROUTPUT ON

-- START prepare_tables;
-- START trg_on_bus_start_maintenance;
-- START trg_on_bus_end_maintenance;
-- START prc_create_bus_maintenance;
-- START prc_list_cancelled_schedules;

-- INSERT INTO BusMaintenance (maintenanceID, busID) VALUES(1, 1);

-- test prc_bus_start_maintenance
-- NOTE: dont change these BusID (all belong to company C010) and StaffID (all are maintenance technicians). 
-- BEGIN
--     prc_create_bus_maintenance('B0305', 'S020', t_staffList('ST0002', 'ST0009'));
--     prc_create_bus_maintenance('B0330', 'S015', t_staffList('ST0215', 'ST0365'));
--     prc_create_bus_maintenance('B0372', 'S006', t_staffList('ST0377', 'ST0390'));
-- END;
-- /

-- EXEC prc_list_cancelled_schedules('C010');

-- test trg_on_bus_end_maintenance
-- maintenanceID may need changing, look at output of prc_bus_start_maintenance
UPDATE BusMaintenance 
SET status = 'completed'
WHERE maintenanceID = 'M00502';

