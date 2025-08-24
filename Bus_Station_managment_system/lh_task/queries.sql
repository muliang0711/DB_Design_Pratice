-- list all maintenance staff who are free, i.e. do not have maintenance work recently,
-- ordered by maintenancedate of their last maintenance service serviced 
-- (those whose last maintenance service was done least recently will be at the top~)

-- Staff ID, Name (fname + lname), phoneNumber, email, last maintenance service (<service name> on <bus id>), maintenance date, remarks (from BusMaintenance table)

SELECT 
    s.staffID, 
    s.firstName || ' ' || s.lastName AS fullName, 
    s.phoneNumber,
    s.email,
    bm.maintenanceId,
    ms.serviceItem || ' on ' || bm.busId AS maintenanceDetails,
    ms.maintenanceDoneDate,
    ms.remarks
FROM Staff s 
JOIN MaintenanceStaffAssignment USING(staffID)
JOIN BusMaintenance bm USING(maintenanceId)
JOIN MaintenanceService ms USING(serviceId)
ORDERED BY ms.maintenanceDoneDate;

----------------------

-- Query (view) 2: Bus maintenance stats

-- for each bus, calculate the average time between corrective (repair) maintenance services 
-- group by bus company

-- to determine a bus's reliability,
-- also, can predict next maintenance service a bus might need 

SET SERVEROUTPUT ON
SET LINESIZE 120
SET PAGESIZE 200

CREATE OR REPLACE VIEW BusMaintenanceStats AS 
SELECT 
    -- Makes report prettier by printing the company name
    -- only for the first row in each group.
    -- CASE 
    --     WHEN ROW_NUMBER() OVER (PARTITION BY c.companyName ORDER BY b.busID) = 1 
    --     THEN c.companyName 
    --     ELSE NULL 
    -- END AS companyName,
    c.companyName AS "Company Name",
    b.busID AS "Bus ID",
    b.plateNo AS "Plate No.",
    AVG(interval_days) AS "Avg. interval days"
FROM (
    SELECT bm.busID,
           LEAD(bm.maintenanceDate) OVER (PARTITION BY bm.busID ORDER BY bm.maintenanceDate) 
               - bm.maintenanceDate AS interval_days
    FROM BusMaintenance bm
    JOIN MaintenanceService ms 
      ON bm.serviceID = ms.serviceID
    WHERE UPPER(ms.severity) IN ('MODERATE', 'MAJOR')
) intervals
JOIN Bus b ON intervals.busID = b.busID
JOIN BusCompany c ON b.companyID = c.companyID
WHERE interval_days IS NOT NULL
GROUP BY b.busID
ORDER BY c.companyName, b.busID;

COLUMN "Company Name" FORMAT A20
COLUMN "Bus ID" FORMAT A10
COLUMN "Avg. interval days" FORMAT A5

BREAK ON companyName SKIP 1

SELECT * FROM BusMaintenanceStats;





