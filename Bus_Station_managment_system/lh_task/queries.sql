-- list all maintenance staff who are free, i.e. do not have maintenance work recently,
-- ordered by maintenancedate of their last maintenance service serviced 
-- (those whose last maintenance service was done least recently will be at the top~)

-- Staff ID, Name (fname + lname), phoneNumber, email, last maintenance service (<service name> on <bus id>), maintenance date, remarks (from BusMaintenance table)

SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 200
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

DROP INDEX idx_maint_done_date;
CREATE INDEX idx_maint_done_date ON BusMaintenance (maintenanceDoneDate);

CREATE OR REPLACE VIEW MaintenanceStaffRecentJobView AS 
SELECT 
    s.staffID AS staffID, 
    s.firstName || ' ' || s.lastName AS fullName, 
    s.phoneNumber AS phoneNumber,
    s.email AS email,
    bm2.maintenanceId AS maintenanceId,
    ms.serviceItem AS serviceItem,
    bm2.busId AS busId,
    -- ms.serviceItem || ' on ' || bm2.busId AS maintenanceDetails,
    bm2.maintenanceDoneDate AS maintenanceDate,
    bm2.remarks AS remarks
FROM (
    -- Join BusMaintenance with MaintenanceStaffAssignment,
    -- then take only the record with the latest maintenanceDoneDate
    -- for each unique staffID
    SELECT * 
    FROM (
        SELECT 
            bm.*, 
            msa.staffID,
            ROW_NUMBER() OVER (PARTITION BY msa.staffID ORDER BY bm.maintenanceDoneDate DESC) AS rn
        FROM BusMaintenance bm
        JOIN MaintenanceStaffAssignment msa ON bm.maintenanceID = msa.maintenanceID
    ) 
    WHERE rn = 1
) bm2 
JOIN Staff s ON bm2.staffID = s.staffID
JOIN MaintenanceService ms ON bm2.serviceID = ms.serviceID
ORDER BY bm2.maintenanceDoneDate;

COLUMN staffID HEADING "Staff ID" 
COLUMN fullName HEADING "Name" FORMAT A20
COLUMN phoneNumber HEADING "Contact no." 
COLUMN email HEADING "Email" 
COLUMN maintenanceId HEADING "Maint. job ID" 
-- COLUMN maintenanceDetails HEADING "Service on bus" FORMAT A50
COLUMN serviceItem HEADING "Service"
COLUMN busId HEADING "Bus ID" 
COLUMN maintenanceDate HEADING "Done on" 
COLUMN remarks HEADING "Remarks" 

SELECT * FROM MaintenanceStaffRecentJobView;

CLEAR COLUMN




----------------------

-- Query (view) 2: Bus maintenance stats

-- for each bus, calculate the average time between corrective (repair) maintenance services 
-- group by bus company

-- to determine a bus's reliability,
-- also, can predict next maintenance service a bus might need 

SET SERVEROUTPUT ON
SET LINESIZE 120
SET PAGESIZE 200

DROP INDEX idx_company_name;
CREATE INDEX idx_company_name ON BusCompany (companyName);

CREATE OR REPLACE VIEW BusMaintenanceStatsView AS 
SELECT 
    -- Makes report prettier by printing the company name
    -- only for the first row in each group.
    -- CASE 
    --     WHEN ROW_NUMBER() OVER (PARTITION BY c.companyName ORDER BY b.busID) = 1 
    --     THEN c.companyName 
    --     ELSE NULL 
    -- END AS companyName,
    c.companyName       AS companyName,
    b.busID             AS busID,
    b.plateNo           AS plateNo,
    ROUND(AVG(interval_days))  AS avgIntervalDays
FROM (
    SELECT 
        bm.busID,
        CAST(LEAD(bm.maintenanceDoneDate) OVER (PARTITION BY bm.busID ORDER BY bm.maintenanceDoneDate) AS DATE) 
        - CAST(bm.maintenanceDoneDate AS DATE)
            AS interval_days
    FROM BusMaintenance bm
    JOIN MaintenanceService ms 
      ON bm.serviceID = ms.serviceID
    WHERE UPPER(ms.category) IN ('MODERATE', 'MAJOR')
) intervals
JOIN Bus b ON intervals.busID = b.busID
JOIN BusCompany c ON b.companyID = c.companyID
WHERE interval_days IS NOT NULL
GROUP BY b.busID, c.companyName, b.plateNo
ORDER BY c.companyName, b.busID;

-- bm, ms, b, bc

COLUMN companyName      HEADING "Company Name"          FORMAT A20
COLUMN busID            HEADING "Bus ID"                FORMAT A10
COLUMN plateNo          HEADING "Plate No."             FORMAT A10
COLUMN avgIntervalDays  HEADING "Avg. interval days"    

BREAK ON companyName SKIP 1

SELECT * FROM BusMaintenanceStatsView;

CLEAR COLUMN
CLEAR BREAK




