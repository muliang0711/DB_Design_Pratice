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
    AVG(interval_days)  AS avgIntervalDays
FROM (
    SELECT bm.busID,
           LEAD(bm.maintenanceDate) OVER (PARTITION BY bm.busID ORDER BY bm.maintenanceDoneDate) 
               - bm.maintenanceDate AS interval_days
    FROM BusMaintenance bm
    JOIN MaintenanceService ms 
      ON bm.serviceID = ms.serviceID
    WHERE UPPER(ms.category) IN ('MODERATE', 'MAJOR')
) intervals
JOIN Bus b ON intervals.busID = b.busID
JOIN BusCompany c ON b.companyID = c.companyID
WHERE interval_days IS NOT NULL
GROUP BY b.busID
ORDER BY c.companyName, b.busID;

COLUMN companyName      HEADING "Company Name"          FORMAT A20
COLUMN busID            HEADING "Bus ID"                FORMAT A10
COLUMN plateNo          HEADING "Plate No."             FORMAT A10
COLUMN avgIntervalDays  HEADING "Avg. interval days"    FORMAT A5

BREAK ON companyName SKIP 1

SELECT * FROM BusMaintenanceStats;





