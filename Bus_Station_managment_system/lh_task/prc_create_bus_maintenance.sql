CREATE OR REPLACE TYPE t_staffList AS VARRAY(10) OF NUMBER;
/

CREATE SEQUENCE MaintenanceID_Seq
MINVALUE 501
MAXVALUE 999999999999999999999999999
START WITH 501
INCREMENT BY 1
NOCACHE;

CREATE OR REPLACE PROCEDURE prc_create_bus_maintenance(
    in_busID IN Bus.busID%TYPE,
    in_serviceID IN MaintenanceService.serviceID%TYPE,
    in_staffIDList IN t_staffList
) IS

    CURSOR c_staff_is_valid(p_staffID Staff.staffID%TYPE) IS
        SELECT 1
        FROM Staff s
        JOIN StaffRole r USING(roleID)
        WHERE s.staffID = p_staffID
        AND r.roleName = 'Maintenance worker';

    CURSOR c_service_exists IS
        SELECT 1 FROM MaintenanceService WHERE serviceID = in_serviceID;

    CURSOR c_bus_exists IS
        SELECT 1 FROM Bus WHERE busID = in_busID;

    v_dummy NUMBER;
    err_invalid_staff EXCEPTION;
    err_invalid_service EXCEPTION;
    err_invalid_bus EXCEPTION;

    v_currStaffID Staff.staffID%TYPE;
    v_maintenanceID BusMaintenance.maintenanceID%TYPE;

BEGIN
    -- Validate each staff ID using cursor
    FOR i IN 1 .. in_staffIDList.COUNT LOOP
        v_currStaffID := in_staffIDList(i);

        OPEN c_staff_is_valid(v_currStaffID);
        FETCH c_staff_is_valid INTO v_dummy;
        IF c_staff_is_valid%NOTFOUND THEN
            CLOSE c_staff_is_valid;
            RAISE err_invalid_staff;
        END IF;
        CLOSE c_staff_is_valid;
    END LOOP;

    -- Validate service exists using cursor
    OPEN c_service_exists;
    FETCH c_service_exists INTO v_dummy;
    IF c_service_exists%NOTFOUND THEN
        CLOSE c_service_exists;
        RAISE err_invalid_service;
    END IF;
    CLOSE c_service_exists;

    -- Validate bus exists using cursor
    OPEN c_bus_exists;
    FETCH c_bus_exists INTO v_dummy;
    IF c_bus_exists%NOTFOUND THEN
        CLOSE c_bus_exists;
        RAISE err_invalid_bus;
    END IF;
    CLOSE c_bus_exists;

    -- Generate new maintenanceID
    v_maintenanceID := MaintenanceID_Seq.nextval;

    -- Insert BusMaintenance
    INSERT INTO BusMaintenance (maintenanceID, busID, serviceID)
    VALUES (v_maintenanceID, in_busID, in_serviceID);

    DBMS_OUTPUT.PUT_LINE('Inserted BusMaintenance record with ID ' || v_maintenanceID);

    -- Insert MaintenanceStaffAssignment rows (same logic)
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
