-- Fires after a new row is inserted into BusMaintenance
--
-- Updates the `status` of any `DriverListAssignment` records
-- that reference the bus in question to 'inactive'.
CREATE OR REPLACE TRIGGER trg_on_bus_startmaintenance
AFTER INSERT ON BusMaintenance
FOR EACH ROW    
BEGIN
-- Update bus's status to under_maintenance
    UPDATE Bus
    SET status = 'under_maintenance'
    WHERE busID = :NEW.busID;

-- Update affected driver list assignments' status to inactive
    UPDATE DriverListAssignment dla
    SET status = 'inactive'
    WHERE dla.busID = :NEW.busID
    AND dla.assignedTo >= SYSDATE;

-- Updated affected route-driver assignments' status to inactive
    UPDATE RouteDriverAssignmentList rdal
    SET status = 'inactive'
    WHERE EXISTS (
        SELECT 1 
        FROM DriverListAssignment dla
        WHERE dla.assignmentID = rdal.assignmentID
        AND dla.busID = :NEW.busID
    );

END;
/

-- -- Fires after a new row is inserted into BusMaintenance
-- --
-- -- Updates the `status` of any `DriverListAssignment` records
-- -- that reference the bus in question to 'inactive'.
-- --
-- -- Attempted to use nested cursors, but it could not compile
-- CREATE OR REPLACE TRIGGER trg_on_bus_startmaintenance
-- AFTER INSERT ON BusMaintenance
-- FOR EACH ROW
-- DECLARE
--     TYPE cur_routeDriver_type IS REF CURSOR;
--     cur_routeDriver   cur_routeDriver_type;   

-- -- Nested cursor
--     CURSOR cur_driverList IS
--         SELECT dla.assignmentID, CURSOR (
--             SELECT rdal.routeDriverAssignmentID
--             FROM RouteDriverAssignmentList rdal
--             WHERE rdal.assignmentID = dla.assignmentID
--         ) affectedRouteDriverID
--         FROM DriverListAssignment dla
--         WHERE dla.busID = :NEW.busID
--         AND dla.assignedTo >= SYSDATE;

--     -- v_driver_list cur_driverList%ROWTYPE;
--     v_affectedAssignmentID DriverListAssignment.assignmentID%TYPE;
--     v_affectedRouteDriverID RouteDriverAssignmentList.routeDriverAssignmentID%TYPE;
-- -- Inner cursor
--     -- CURSOR cur_routeDriver IS
--     --     SELECT *
--     --     FROM RouteDriverAssignmentList
--     --     WHERE assignmentID = v_affectedAssignmentID;

--     -- v_routeDriver cur_routeDriver%ROWTYPE;

-- BEGIN
--     OPEN cur_driverList;
--     LOOP
--         FETCH cur_driverList INTO v_affectedAssignmentID, cur_routeDriver;
--         EXIT WHEN cur_driverList%NOTFOUND;

--         UPDATE DriverListAssignment
--         SET status = 'inactive'
--         WHERE assignmentID = v_affectedAssignmentID;

-- -- For each affected DriverListAssignment row,
-- -- set all RouteDriverAssignmentList rows that
-- -- reference the affected DLA row.
--         OPEN cur_routeDriver;
--         LOOP 
--             FETCH cur_routeDriver INTO v_affectedRouteDriverID;
--             EXIT WHEN cur_routeDriver%NOTFOUND;

--             UPDATE RouteDriverAssignmentList
--             SET status = 'inactive'
--             WHERE routeDriverAssignmentID = v_affectedRouteDriverID;

--         END LOOP;
--         CLOSE cur_routeDriver;

--     END LOOP;
--     CLOSE cur_driverList;



--     -- DBMS_OUTPUT.PUT_LINE('On the event that the bus with ID ' || :NEW.busID || ' is under maintenance, ' || SQL%ROWCOUNT || ' row(s) in DriverListAssignment have been set to `status` = ''inactive''.');
-- END;
-- /

-- -- Fires after a new row is inserted into BusMaintenance
-- -- This version demonstrates proper nested cursor usage
-- -- Claude's attempt at fixing my nested cursor implementation,
-- -- but it still could not compile.
-- CREATE OR REPLACE TRIGGER trg_on_bus_startmaintenance
-- AFTER INSERT ON BusMaintenance
-- FOR EACH ROW
-- DECLARE
--     -- Method 1: Using a strongly-typed cursor variable
--     -- This approach declares a specific cursor type that matches
--     -- the structure of our nested cursor
--     TYPE route_cursor_type IS REF CURSOR RETURN RouteDriverAssignmentList%ROWTYPE;
    
--     -- Main cursor with nested cursor expression
--     -- The CURSOR() expression returns a cursor that we'll handle specially
--     CURSOR cur_driverList IS
--         SELECT dla.assignmentID, 
--                CURSOR (
--                    SELECT rdal.*
--                    FROM RouteDriverAssignmentList rdal
--                    WHERE rdal.assignmentID = dla.assignmentID
--                    AND rdal.status = 'active'  -- Only get active routes
--                ) AS route_cursor
--         FROM DriverListAssignment dla
--         WHERE dla.busID = :NEW.busID
--           AND dla.assignedTo >= SYSDATE
--           AND dla.status != 'inactive';  -- Don't process already inactive assignments
    
--     -- Variables to hold fetched data
--     v_assignment_id DriverListAssignment.assignmentID%TYPE;
--     v_route_cursor  route_cursor_type;
--     v_route_record  RouteDriverAssignmentList%ROWTYPE;
    
--     -- Counters for tracking our work
--     v_driver_assignments_updated NUMBER := 0;
--     v_route_assignments_updated NUMBER := 0;
    
-- BEGIN
--     -- Open and process the main cursor
--     OPEN cur_driverList;
    
--     LOOP
--         -- Fetch the assignment ID and the nested cursor
--         FETCH cur_driverList INTO v_assignment_id, v_route_cursor;
--         EXIT WHEN cur_driverList%NOTFOUND;
        
--         -- Update the driver assignment status
--         UPDATE DriverListAssignment
--         SET status = 'inactive'
--         WHERE assignmentID = v_assignment_id;
        
--         -- Count this update
--         v_driver_assignments_updated := v_driver_assignments_updated + 1;
        
--         -- Now process the nested cursor containing route assignments
--         -- This is where the magic happens - we're working with the cursor
--         -- that was returned by the CURSOR() expression
--         LOOP
--             FETCH v_route_cursor INTO v_route_record;
--             EXIT WHEN v_route_cursor%NOTFOUND;
            
--             -- Update each route assignment to inactive
--             UPDATE RouteDriverAssignmentList
--             SET status = 'inactive'
--             WHERE routeDriverAssignmentID = v_route_record.routeDriverAssignmentID;
            
--             -- Count this update
--             v_route_assignments_updated := v_route_assignments_updated + 1;
            
--         END LOOP;
        
--         -- Important: Close the nested cursor after processing each group
--         -- Think of this like closing a file after reading it - good housekeeping
--         CLOSE v_route_cursor;
        
--     END LOOP;
    
--     -- Close the main cursor
--     CLOSE cur_driverList;
    
--     -- Optional logging to see what we accomplished
--     DBMS_OUTPUT.PUT_LINE('Bus ' || :NEW.busID || ' maintenance started using nested cursors.');
--     DBMS_OUTPUT.PUT_LINE('Updated ' || v_driver_assignments_updated || ' driver assignments.');
--     DBMS_OUTPUT.PUT_LINE('Updated ' || v_route_assignments_updated || ' route assignments.');
    
-- END;
-- /