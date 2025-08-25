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


--------------

-- Report - nested cursors

-- show maintenance's workers performance
-- for each worker:
-- - total cost of jobs?
-- - number of jobs to have done so far 
-- - number of jobs in the past year

-- ========================
-- ========================
-- StaffID: XXX
-- Name: John Carlson
-- Joined: XX/XX/XXXX
-- ========================
--     Total jobs done:          XX
--     Jobs done in past year:  XX 
-- ========================
-- =========================

-- outer cursor: select all staff whose role is maintenance worker 
-- inner cursor: calculate number of maintenance jobs done by a particular maintenance staff 

CREATE OR REPLACE PROCEDURE prc_report_worker_performance IS

    -- Variables to hold data
    v_worker   c_workers%ROWTYPE;
    v_jobs     c_jobs%ROWTYPE;

    -- Bridge between outer and inner cursors
    v_staffID  Staff.staffID%TYPE;

    -- Outer cursor: all staff who are maintenance workers
    CURSOR c_workers IS
        SELECT s.staffId, s.firstName, s.lastName, s.hireDate
        FROM staff s
        WHERE EXISTS (
            SELECT 1
            FROM StaffRole r
            WHERE r.roleId = s.roleId 
            AND UPPER(r.roleName) = 'MAINTENANCE TECHNICIAN'
        );

    -- Inner cursor: jobs done by a particular staff
    CURSOR c_jobs IS
        SELECT COUNT(*) AS total_jobs,
               SUM(bm.actualCost + bm.additionalCost) AS total_cost,
               SUM(CASE WHEN bm.maintenanceDoneDate >= ADD_MONTHS(TRUNC(SYSDATE), -12) 
                        THEN 1 ELSE 0 END) AS jobs_past_year
        FROM BusMaintenance bm 
        JOIN MaintenanceStaffAssignment msa ON bm.maintenanceID = msa.maintenanceID
        WHERE msa.staffID = v_staffID;    

BEGIN
    -- Loop over all workers
    OPEN c_workers;
    LOOP
        FETCH c_workers INTO v_worker;
        EXIT WHEN c_workers%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('========================');
        DBMS_OUTPUT.PUT_LINE('StaffID: ' || v_worker.staffId);
        DBMS_OUTPUT.PUT_LINE('Name:    ' || v_worker.firstName || ' ' || v_worker.lastName);
        DBMS_OUTPUT.PUT_LINE('Joined:  ' || TO_CHAR(v_worker.hireDate, 'DD/MM/YYYY'));
        DBMS_OUTPUT.PUT_LINE('========================');

        v_staffID := v_worker.staffID;

        -- Nested cursor: jobs for this worker
        OPEN c_jobs;
        FETCH c_jobs INTO v_jobs;

        DBMS_OUTPUT.PUT_LINE('    Total jobs done:         ' || NVL(v_jobs.total_jobs,0)); -- NVL is null coalescing function (like ?? in php)
        DBMS_OUTPUT.PUT_LINE('    Total cost of jobs:      ' || NVL(v_jobs.total_cost,0));
        DBMS_OUTPUT.PUT_LINE('    Jobs done in past month: ' || NVL(v_jobs.jobs_past_year,0));
        DBMS_OUTPUT.PUT_LINE('========================');
        DBMS_OUTPUT.PUT_LINE('========================');

        CLOSE c_jobs;
    END LOOP;
    CLOSE c_workers;
END;
/
