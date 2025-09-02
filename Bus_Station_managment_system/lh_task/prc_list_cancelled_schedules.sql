CREATE OR REPLACE PROCEDURE prc_list_cancelled_schedules(
    v_companyID IN BusCompany.companyID%TYPE
)
IS
    -- Cursor to fetch cancelled bus schedules for the specified company
    CURSOR cancelled_schedules_cur IS
        SELECT 
            bs.BusScheduleID,
            bs.routeDriverAssignmentID,
            bs.plannedDepartureTime,
            bs.plannedArrivalTime,
            r.routeID,
            start_station.stationName AS start_point,
            end_station.stationName AS end_point,
            main_driver.firstName AS main_first_name,
            main_driver.lastName AS main_last_name,
            support_driver.firstName AS support_first_name,
            support_driver.lastName AS support_last_name
        FROM BusSchedule bs
        JOIN RouteDriverAssignmentList rdal ON bs.routeDriverAssignmentID = rdal.routeDriverAssignmentID
        JOIN Route r ON rdal.routeID = r.routeID
        JOIN BusStation start_station ON r.startPoint = start_station.stationID
        JOIN BusStation end_station ON r.endPoint = end_station.stationID
        JOIN DriverListAssignment dla ON rdal.assignmentID = dla.assignmentID
        JOIN Bus b ON dla.busID = b.busID
        JOIN BusDriver main_driver ON dla.mainDriverID = main_driver.driverID
        LEFT JOIN BusDriver support_driver ON dla.supportDriverID = support_driver.driverID
        WHERE bs.status = 'cancelled'
          AND bs.plannedDepartureTime >= CURRENT_TIMESTAMP
          AND b.companyID = v_companyID
        ORDER BY bs.plannedDepartureTime;

    -- Variables to hold cursor data
    v_bus_schedule_id            busSchedule.busScheduleId%TYPE;
    v_route_driver_assignment_id busSchedule.routeDriverAssignmentId%TYPE;
    v_planned_departure          busSchedule.plannedDepartureTime%TYPE;
    v_planned_arrival            busSchedule.plannedArrivalTime%TYPE;
    v_route_id                   route.routeId%TYPE;
    v_start_point                busStation.stationName%TYPE;
    v_end_point                  busStation.stationName%TYPE;
    v_main_first_name            busDriver.firstName%TYPE;
    v_main_last_name             busDriver.lastName%TYPE;
    v_support_first_name         busDriver.firstName%TYPE;
    v_support_last_name          busDriver.lastName%TYPE;

    v_companyName                BusCompany.companyName%TYPE;
    
    -- Formatted output variables
    v_route_points VARCHAR2(250);
    v_time_range VARCHAR2(100);
    v_main_driver_name VARCHAR2(101);
    v_support_driver_name VARCHAR2(101);
    
    -- Counter for results
    v_count NUMBER := 0;

    -- Flag variable
    v_companyExists NUMBER;

BEGIN
    -- Check if v_companyID exists,
    -- NO_DATA_FOUND error will be raised by SELECT...INTO if not!!
    SELECT companyName INTO v_companyName 
    FROM BusCompany 
    WHERE companyID = v_companyID;

    -- IF v_companyExists = 0 THEN 
    --     RAISE_APPLICATION_ERROR(-20001, 'Provided company ID does not exist!');
    -- END IF;

    -- Print header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    DBMS_OUTPUT.PUT_LINE('   CANCELLED BUS SCHEDULES FOR COMPANY: ' || v_companyName || ' (' || v_companyID || ')');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    DBMS_OUTPUT.PUT_LINE('');

    -- Open and process cursor
    OPEN cancelled_schedules_cur;
    
    LOOP
        FETCH cancelled_schedules_cur INTO 
            v_bus_schedule_id,
            v_route_driver_assignment_id,
            v_planned_departure,
            v_planned_arrival,
            v_route_id,
            v_start_point,
            v_end_point,
            v_main_first_name,
            v_main_last_name,
            v_support_first_name,
            v_support_last_name;
            
        EXIT WHEN cancelled_schedules_cur%NOTFOUND;
        
        -- Increment counter
        v_count := v_count + 1;
        
        -- Format the output strings
        v_route_points := v_start_point || ' -> ' || v_end_point;
        v_time_range := TO_CHAR(v_planned_departure, 'DD-MON-YYYY HH24:MI') || 
                       ' -> ' || 
                       TO_CHAR(v_planned_arrival, 'DD-MON-YYYY HH24:MI');
        v_main_driver_name := v_main_first_name || ' ' || v_main_last_name;
        
        -- Handle support driver (may be null)
        IF v_support_first_name IS NOT NULL THEN
            v_support_driver_name := v_support_first_name || ' ' || v_support_last_name;
        ELSE
            v_support_driver_name := 'N/A';
        END IF;
        
        -- Print the schedule information
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE(' Schedule #' || v_count);
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE('  Route ID       : ' || v_route_id);
        DBMS_OUTPUT.PUT_LINE('  Route          : ' || v_route_points);
        DBMS_OUTPUT.PUT_LINE('  Departure -> Arrival : ' || v_time_range);
        DBMS_OUTPUT.PUT_LINE('  Main Driver    : ' || v_main_driver_name);
        DBMS_OUTPUT.PUT_LINE('  Support Driver : ' || v_support_driver_name);
        DBMS_OUTPUT.PUT_LINE('');
        
    END LOOP;
    
    -- Close cursor
    CLOSE cancelled_schedules_cur;

    -- Print summary
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total cancelled schedules found: ' || v_count);
    
    -- Handle case when no results found
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No cancelled bus schedules found for company ID: ' || v_companyID);
        DBMS_OUTPUT.PUT_LINE('with departure time >= current timestamp.');
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN 
        DBMS_OUTPUT.PUT_LINE('Provided company ID does not exist!');

    WHEN OTHERS THEN
        -- Ensure cursor is closed in case of error
        IF cancelled_schedules_cur%ISOPEN THEN
            CLOSE cancelled_schedules_cur;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;
        
END prc_list_cancelled_schedules;
/

