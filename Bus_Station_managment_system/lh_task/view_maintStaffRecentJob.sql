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
COLUMN fullName HEADING "Name" 
COLUMN phoneNumber HEADING "Contact no." 
COLUMN email HEADING "Email" 
COLUMN maintenanceId HEADING "Maint. job ID" 
-- COLUMN maintenanceDetails HEADING "Service on bus" FORMAT A50
COLUMN serviceItem HEADING "Service"
COLUMN busId HEADING "Bus ID" 
COLUMN maintenanceDate HEADING "Done on" 
COLUMN remarks HEADING "Remarks" 

-- SELECT * FROM MaintenanceStaffRecentJobView;

CLEAR COLUMN 
