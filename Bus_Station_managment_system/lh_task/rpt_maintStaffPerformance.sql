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

    -- Bridge between outer and inner cursors
    v_staffID  Staff.staffID%TYPE;

    -- Inner cursor: jobs done by a particular staff
    CURSOR c_jobs IS
        SELECT COUNT(*) AS total_jobs,
               SUM(bm.actualCost + bm.additionalCost) AS total_cost,
               SUM(CASE WHEN bm.maintenanceDoneDate >= ADD_MONTHS(TRUNC(SYSDATE), -12) 
                        THEN 1 ELSE 0 END) AS jobs_past_year
        FROM BusMaintenance bm 
        JOIN MaintenanceStaffAssignment msa ON bm.maintenanceID = msa.maintenanceID
        WHERE msa.staffID = v_staffID;  

    -- Variables to hold data
    v_worker   c_workers%ROWTYPE;
    v_jobs     c_jobs%ROWTYPE;  

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    DBMS_OUTPUT.PUT_LINE(' Worker Performance Report');

    -- Loop over all workers
    OPEN c_workers;
    LOOP
        FETCH c_workers INTO v_worker;
        EXIT WHEN c_workers%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
        DBMS_OUTPUT.PUT_LINE(' Staff ID   : ' || v_worker.staffId);
        DBMS_OUTPUT.PUT_LINE(' Name       : ' || v_worker.firstName || ' ' || v_worker.lastName);
        DBMS_OUTPUT.PUT_LINE(' Hire Date  : ' || TO_CHAR(v_worker.hireDate, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));

        v_staffID := v_worker.staffID;

        -- Nested cursor: jobs for this worker
        OPEN c_jobs;
        FETCH c_jobs INTO v_jobs;

        DBMS_OUTPUT.PUT_LINE('   Total Jobs Completed   : ' || NVL(v_jobs.total_jobs, 0));
        DBMS_OUTPUT.PUT_LINE('   Total Maintenance Cost : RM ' || TO_CHAR(NVL(v_jobs.total_cost, 0), 'FM999,999.00'));
        DBMS_OUTPUT.PUT_LINE('   Jobs in Past Year      : ' || NVL(v_jobs.jobs_past_year, 0));

        DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
        DBMS_OUTPUT.PUT_LINE('');

        CLOSE c_jobs;
    END LOOP;
    CLOSE c_workers;
END;
/
