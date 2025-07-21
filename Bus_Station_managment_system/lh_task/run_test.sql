SET SERVEROUTPUT ON

START prepare_tables;
START trg_on_bus_start_maintenance;
START trg_on_bus_end_maintenance;
START prc_bus_start_maintenance;


-- INSERT INTO BusMaintenance (maintenanceID, busID) VALUES(1, 1);

-- test prc_bus_start_maintenance
BEGIN
    prc_create_bus_maintenance(1, 4, t_staffList(1, 2));
END;
/

