
-- When a `BusStation` becomes inactive, all its
-- `BusPlatform`s become inactive too.
--
-- Any `RouteStation`s that reference inactive `BusPlatform`s
-- become invalid.
--
-- Related `Route`s will have to be rerouted. Realistically
-- we might schedule a cron job (which is outside the scope 
-- of PL/SQL) that updates the `RouteStation`s of the affected
-- `Route`s, on the day that the `BusStation` goes inactive.
-- Maybe these updates can be wrapped in another procedure.
--
-- And when a `Route` is deactivated, related 
-- `RouteDriverAssignmentList`s become inactive too. 
-- (Related `DriverListAssignment`s remain unchanged)


-- Assume that this procedure is scheduled to run on the day
-- that a `BusStation` goes inactive. This date is recorded in 
-- the `inactive_from` attribute, which has been set previously.
CREATE OR REPLACE PROCEDURE prc_deactivate_busstation(p_station_id IN NUMBER) IS
    v_inactive_from DATE;
    err_early_deactivation EXCEPTION;
BEGIN
-- Make sure that today IS the day that this station goes inactive
    SELECT inactive_from 
    INTO v_inactive_from
    FROM BusStation 
    WHERE stationID = p_station_id;

    IF v_inactive_from > SYSDATE OR v_inactive_from IS NULL THEN
        RAISE err_early_deactivation;
    END IF;
EXCEPTION
    WHEN err_early_deactivation THEN
        DBMS_OUTPUT.PUT_LINE('***ERROR: Early Deactivation***');
        DBMS_OUTPUT.PUT_LINE('This bus station (ID: ' || p_station_id || ') is not scheduled to ');
        DBMS_OUTPUT.PUT_LINE('be deactivated today. ');
        IF v_inactive_from IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('In fact, it is not scheduled for deactivation at all.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('It is scheduled for deactivation on: ' || v_inactive_from);
        END IF;
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Bus station with ID ' || p_station_id || ' does not exist.');

END;
/