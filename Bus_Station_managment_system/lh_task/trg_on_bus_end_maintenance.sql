CREATE OR REPLACE TRIGGER trg_on_bus_end_maintenance 
AFTER UPDATE OF status ON BusMaintenance
FOR EACH ROW
BEGIN
    IF :OLD.status = 'in_progress' AND :NEW.status = 'completed' THEN
        -- Update bus's status to active
        UPDATE Bus
        SET status = 'active',
            updatedAt = CURRENT_TIMESTAMP
        WHERE busID = :NEW.busID;
        DBMS_OUTPUT.PUT_LINE('Bus ' || :NEW.busID || ' status set to active.');

        -- Update affected driver list assignments' status to active
        UPDATE DriverListAssignment dla
        SET status = 'active'
        WHERE dla.busID = :NEW.busID
        AND dla.assignedTo >= SYSDATE;
        DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' driver assignments reactivated.');

        -- Update affected route-driver assignments' status to active
        UPDATE RouteDriverAssignmentList rdal
        SET status = 'active'
        WHERE EXISTS (
            SELECT 1 
            FROM DriverListAssignment dla
            WHERE dla.assignmentID = rdal.assignmentID
            AND dla.busID = :NEW.busID
        );
        DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' route-driver assignments reactivated.');
    END IF;
END;
/
