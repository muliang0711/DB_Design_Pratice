-- list maintenance services ranked by number of services provided in the past year

-- outer cursor: select all maintenance services 
-- inner cursor: calculate number of jobs for a particular maintenance service in the past year.

-- involved tables:
-- - maintenanceService
-- - busMaintenance

CREATE OR REPLACE PROCEDURE prc_maint_service_ranking AS
   -- Variables for outer cursor (maintenanceService)
   v_serviceId     maintenanceService.serviceId%TYPE;
   v_serviceItem   maintenanceService.serviceItem%TYPE;

   -- Variables for inner cursor (job counts)
   v_jobCount      NUMBER;

   -- Outer cursor: all maintenance services
   CURSOR service_cursor IS
      SELECT serviceId, serviceItem
      FROM maintenanceService;

   -- Inner cursor: count of jobs for one service in the past year
   CURSOR jobCount_cursor IS
      SELECT COUNT(*) 
      FROM busMaintenance
      WHERE serviceId = v_serviceId
        AND maintenanceDoneDate >= ADD_MONTHS(SYSDATE, -12);

BEGIN
   OPEN service_cursor;
   FETCH service_cursor INTO v_serviceId, v_serviceItem;

   WHILE service_cursor%FOUND LOOP
      DBMS_OUTPUT.PUT_LINE('Service: ' || v_serviceItem || ' (' || v_serviceId || ')');

      OPEN jobCount_cursor;
      FETCH jobCount_cursor INTO v_jobCount;

      IF jobCount_cursor%FOUND THEN
         DBMS_OUTPUT.PUT_LINE('Jobs in past year: ' || v_jobCount);
      ELSE
         DBMS_OUTPUT.PUT_LINE('Jobs in past year: 0');
      END IF;

      CLOSE jobCount_cursor;
      DBMS_OUTPUT.PUT_LINE('------------------------------');

      FETCH service_cursor INTO v_serviceId, v_serviceItem;
   END LOOP;

   CLOSE service_cursor;
END;
/

