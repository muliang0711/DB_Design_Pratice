-- Fires after a new row is inserted into BusMaintenance
--
-- Updates the `status` of any `DriverListAssignment` records
-- that reference the bus in question to 'inactive'.
CREATE OR REPLACE TRIGGER trg_on_bus_startmaintenance
AFTER INSERT ON BusMaintenance
FOR EACH ROW
-- REFERENCING NEW AS new_maint_rec
BEGIN
    UPDATE DriverListAssignment
    SET status = 'inactive'
    WHERE busID = :NEW.busID
    AND assignedTo >= SYSDATE;

    DBMS_OUTPUT.PUT_LINE('On the event that the bus with ID ' || :NEW.busID || ' is under maintenance, ' || SQL%ROWCOUNT || ' row(s) in DriverListAssignment have been set to `status` = ''inactive''.');
END;
/