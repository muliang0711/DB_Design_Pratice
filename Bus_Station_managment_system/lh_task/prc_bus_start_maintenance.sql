CREATE OR REPLACE TYPE t_staffList AS TABLE OF NUMBER;
/

CREATE OR REPLACE PROCEDURE prc_bus_start_maintenance(
    in_busID IN Bus.busID%TYPE,
    in_serviceID IN MaintenanceService.serviceID%TYPE,
    in_staffIDList IN t_staffList
) IS
    v_inactive_from DATE;

    v_staffIsValid NUMBER;
    v_serviceExists NUMBER;
    v_busExists NUMBER;
    err_invalid_staff EXCEPTION;
    err_invalid_service EXCEPTION;
    err_invalid_bus EXCEPTION;

    v_currStaffID Staff.staffID%TYPE;
    v_maintenanceID BusMaintenance.maintenanceID%TYPE;
BEGIN
    -- Validate each staff ID
    FOR i IN 1 .. in_staffIDList.COUNT LOOP
        v_currStaffID := in_staffIDList(i);

        SELECT COUNT(*)
        INTO v_staffIsValid
        FROM Staff s
        JOIN StaffRole r USING(roleID)
        WHERE s.staffID = v_currStaffID
        AND r.roleName = 'Maintenance worker';

        IF v_staffIsValid = 0 THEN
            RAISE err_invalid_staff;
        END IF;
    END LOOP;

    -- Validate service exists
    SELECT COUNT(*)
    INTO v_serviceExists
    FROM MaintenanceService ms
    WHERE ms.serviceID = in_serviceID; 

    IF v_serviceExists = 0 THEN
        RAISE err_invalid_service;
    END IF;

    -- Validate bus exists
    SELECT COUNT(*)
    INTO v_busExists
    FROM Bus b
    WHERE b.busID = in_busID;

    IF v_busExists = 0 THEN
        RAISE err_invalid_bus;
    END IF;   


    -- Generate a new maintenanceID (naive version)
    SELECT NVL(MAX(maintenanceID), 0) + 1
    INTO v_maintenanceID
    FROM BusMaintenance;

    -- Insert BusMaintenance
    INSERT INTO BusMaintenance (maintenanceID, busID, serviceID)
    VALUES (v_maintenanceID, in_busID, in_serviceID);

    DBMS_OUTPUT.PUT_LINE('Inserted BusMaintenance record with ID ' || v_maintenanceID);

    -- Insert MaintenanceStaffAssignment rows
    FOR i IN 1 .. in_staffIDList.COUNT LOOP
        v_currStaffID := in_staffIDList(i);

        INSERT INTO MaintenanceStaffAssignment (maintenanceID, staffID)
        VALUES (v_maintenanceID, v_currStaffID);

        DBMS_OUTPUT.PUT_LINE('Assigned staff ID ' || v_currStaffID || ' to maintenance ID ' || v_maintenanceID);
    END LOOP;

    -- Update Bus status to 'inactive'
    UPDATE Bus
    SET status = 'inactive'
    WHERE busID = in_busID;

    DBMS_OUTPUT.PUT_LINE('Updated bus ID ' || in_busID || ' to status ''inactive''');

EXCEPTION
    WHEN err_invalid_staff THEN
        DBMS_OUTPUT.PUT_LINE('Invalid param given: in_staffID. Staff member with ID ' || v_currStaffID || ' either is not a maintenance worker or does not exist.');
    WHEN err_invalid_service THEN
        DBMS_OUTPUT.PUT_LINE('Invalid param given: in_serviceID. Maintenance service with ID ' || in_serviceID || ' does not exist.');
    WHEN err_invalid_bus THEN
        DBMS_OUTPUT.PUT_LINE('Invalid param given: in_busID. Bus with ID ' || in_busID || ' does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
