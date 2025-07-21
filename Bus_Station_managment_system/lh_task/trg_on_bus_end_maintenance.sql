CREATE OR REPLACE TRIGGER trg_on_bus_end_maintenance 
AFTER UPDATE OF status ON BusMaintenance
FOR EACH ROW
-- DECLARE

BEGIN
    IF :OLD.status = 'in_progress' AND :NEW.status = 'completed' THEN
    -- Update bus's status to active
        UPDATE Bus
        SET status = 'active'
        WHERE busID = :NEW.busID;

    -- Update affected driver list assignments' status to active
        UPDATE DriverListAssignment dla
        SET status = 'active'
        WHERE dla.busID = :NEW.busID
        AND dla.assignedTo >= SYSDATE;

    -- Update affected route-driver assignments' status to active
        UPDATE RouteDriverAssignmentList rdal
        SET status = 'active'
        WHERE EXISTS (
            SELECT 1 
            FROM DriverListAssignment dla
            WHERE dla.assignmentID = rdal.assignmentID
            AND dla.busID = :NEW.busID
        );
        END IF;
-- EXCEPTION

END;
/
