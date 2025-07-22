-- Add missing tables needed for the procedure
DROP TABLE BusCompany;
CREATE TABLE BusCompany (
    companyID NUMBER(10),
    companyName VARCHAR2(100)
);

DROP TABLE BusStation;
CREATE TABLE BusStation (
    stationID NUMBER(10),
    stationName VARCHAR2(100),
    location VARCHAR2(150),
    status VARCHAR2(20)
);

DROP TABLE Route;
CREATE TABLE Route (
    routeID NUMBER(10),
    routeName VARCHAR2(50),
    startPoint NUMBER(10),
    endPoint NUMBER(10),
    distanceKM NUMBER(6,2),
    estimatedDuration NUMBER(10),
    plannedDepartureTime TIMESTAMP,
    plannedArrivalTime TIMESTAMP,
    status VARCHAR2(20)
);

DROP TABLE BusDriver;
CREATE TABLE BusDriver (
    driverID NUMBER(10),
    companyID NUMBER(10),
    licenseNo VARCHAR2(50),
    licenseExpiry DATE,
    firstName VARCHAR2(50),
    lastName VARCHAR2(50),
    phoneNumber VARCHAR2(20),
    status VARCHAR2(20)
);

-- Modify existing Bus table to include companyID
DROP TABLE Bus;
CREATE TABLE Bus (
    busID NUMBER(10),
    companyID NUMBER(10),
    plateNo VARCHAR2(20),
    model VARCHAR2(50),
    capacity NUMBER(10),
    status VARCHAR2(20),
    year NUMBER(4),
    remarks VARCHAR2(200),
    createdAt TIMESTAMP,
    updatedAt TIMESTAMP
);

DROP TABLE StaffRole;
CREATE TABLE StaffRole (
    roleID NUMBER(10),
    roleName VARCHAR(50)
);

DROP TABLE Staff;
CREATE TABLE Staff (
    staffID NUMBER(10),
    roleID NUMBER(10)
);

DROP TABLE MaintenanceService;
CREATE TABLE MaintenanceService (
    serviceID NUMBER(10)
);

DROP TABLE BusMaintenance;
CREATE TABLE BusMaintenance (
    maintenanceID NUMBER(10),
    busID NUMBER(10),
    serviceID NUMBER(10),
    status VARCHAR2(20)
);

DROP TABLE MaintenanceStaffAssignment;
CREATE TABLE MaintenanceStaffAssignment (
    maintenanceID NUMBER(10),
    staffID NUMBER(10)
);

-- Modify existing DriverListAssignment to include driver references
DROP TABLE DriverListAssignment;
CREATE TABLE DriverListAssignment (
    assignmentID NUMBER(10),
    mainDriverID NUMBER(10),
    supportDriverID NUMBER(10),
    busID NUMBER(10),
    assignedFrom TIMESTAMP,
    assignedTo DATE,
    status VARCHAR2(20),
    remarks VARCHAR2(200),
    CONSTRAINT chk_status_dla CHECK (status IN ('active', 'inactive', 'not_assigned'))
);

DROP TABLE RouteDriverAssignmentList;
CREATE TABLE RouteDriverAssignmentList (
    routeDriverAssignmentID NUMBER(10),  
    routeID NUMBER(10) NOT NULL,
    assignmentID NUMBER(10) NOT NULL,
    frequency VARCHAR2(10) NOT NULL,
    weekdays VARCHAR2(20) NOT NULL,
    effectiveFrom DATE NOT NULL,
    effectiveTo DATE,
    status VARCHAR2(10) DEFAULT 'active',
    expectedProfit NUMBER(8,2),
    remarks VARCHAR2(200),
    -- Frequency must be daily, weekly, or monthly
    CONSTRAINT chk_frequency CHECK (frequency IN ('daily', 'weekly', 'monthly')),
    -- Status must be active or inactive
    CONSTRAINT chk_status_rdal CHECK (status IN ('active', 'inactive')),
    -- Foreign keys
    -- CONSTRAINT fk_route FOREIGN KEY (routeID) REFERENCES Route(routeID),
    -- CONSTRAINT fk_assignment FOREIGN KEY (assignmentID) REFERENCES DriverListAssignment(assignmentID),
    -- Unique index
    CONSTRAINT uq_routedriverassignmentlist UNIQUE (routeID, assignmentID, effectiveFrom)
);

-- Modify existing BusSchedule to include required fields
DROP TABLE BusSchedule;
CREATE TABLE BusSchedule (
    BusScheduleID NUMBER(10),
    routeDriverAssignmentID NUMBER(10),
    plannedDepartureTime TIMESTAMP,
    plannedArrivalTime TIMESTAMP,
    status VARCHAR(20),
    remarks VARCHAR2(200),
    expectedProfit NUMBER(8,2),
    createdAt TIMESTAMP,
    updatedAt TIMESTAMP,
    CONSTRAINT chk_status_bs CHECK (status IN ('planned', 'cancelled', 'completed', 'in_progress', 'pending'))
);

-- Sample data for new tables
INSERT INTO BusCompany (companyID, companyName) VALUES(1, 'Metro Bus Lines');
INSERT INTO BusCompany (companyID, companyName) VALUES(2, 'City Express');

INSERT INTO BusStation (stationID, stationName, location, status) VALUES(1, 'Central Terminal', 'Downtown Area', 'active');
INSERT INTO BusStation (stationID, stationName, location, status) VALUES(2, 'North Station', 'North District', 'active');
INSERT INTO BusStation (stationID, stationName, location, status) VALUES(3, 'South Hub', 'South District', 'active');

INSERT INTO Route (routeID, routeName, startPoint, endPoint, status) VALUES(1, 'R001', 1, 2, 'active');
INSERT INTO Route (routeID, routeName, startPoint, endPoint, status) VALUES(2, 'R002', 2, 3, 'active');

INSERT INTO BusDriver (driverID, companyID, firstName, lastName, licenseNo, licenseExpiry, status) VALUES(1, 1, 'John', 'Smith', 'DL001', DATE '2025-12-31', 'active');
INSERT INTO BusDriver (driverID, companyID, firstName, lastName, licenseNo, licenseExpiry, status) VALUES(2, 1, 'Jane', 'Doe', 'DL002', DATE '2026-06-30', 'active');
INSERT INTO BusDriver (driverID, companyID, firstName, lastName, licenseNo, licenseExpiry, status) VALUES(3, 1, 'Bob', 'Wilson', 'DL003', DATE '2025-09-15', 'active');

-- Modified existing inserts
INSERT INTO Bus (busID, companyID, plateNo, model, status) VALUES(1, 1, 'ABC123', 'Volvo B8R', 'active');
INSERT INTO Bus (busID, companyID, plateNo, model, status) VALUES(2, 1, 'DEF456', 'Mercedes Citaro', 'active');

INSERT INTO StaffRole (roleID, roleName) VALUES(1, 'Maintenance worker');
INSERT INTO StaffRole (roleID, roleName) VALUES(2, 'Counter staff');
INSERT INTO StaffRole (roleID, roleName) VALUES(3, 'Cleaner');

INSERT INTO Staff (staffID, roleID) VALUES(1, 1);
INSERT INTO Staff (staffID, roleID) VALUES(2, 2);

INSERT INTO MaintenanceService (serviceID) VALUES(1);
INSERT INTO MaintenanceService (serviceID) VALUES(2);
INSERT INTO MaintenanceService (serviceID) VALUES(3);

INSERT INTO DriverListAssignment (assignmentID, mainDriverID, supportDriverID, busID, assignedTo, status) VALUES(1, 1, 2, 1, SYSDATE-1, 'active');
INSERT INTO DriverListAssignment (assignmentID, mainDriverID, busID, assignedTo, status) VALUES(2, 2, NULL, 1, SYSDATE, 'active');
INSERT INTO DriverListAssignment (assignmentID, mainDriverID, supportDriverID, busID, assignedTo, status) VALUES(3, 3, 1, 2, SYSDATE, 'active');

INSERT INTO RouteDriverAssignmentList (routeDriverAssignmentID, routeID, assignmentID, frequency, weekdays, effectiveFrom) VALUES(1, 1, 1, 'daily', '1,2,3,4,5', DATE '2024-01-01');
INSERT INTO RouteDriverAssignmentList (routeDriverAssignmentID, routeID, assignmentID, frequency, weekdays, effectiveFrom) VALUES(2, 2, 2, 'weekly', '1,3,5', DATE '2024-01-01');

-- Sample cancelled schedules for testing
INSERT INTO BusSchedule (BusScheduleID, routeDriverAssignmentID, plannedDepartureTime, plannedArrivalTime, status) VALUES(1, 1, TIMESTAMP '2025-08-01 08:00:00', TIMESTAMP '2025-08-01 10:00:00', 'cancelled');
INSERT INTO BusSchedule (BusScheduleID, routeDriverAssignmentID, plannedDepartureTime, plannedArrivalTime, status) VALUES(2, 2, TIMESTAMP '2025-08-02 14:30:00', TIMESTAMP '2025-08-02 16:30:00', 'cancelled');
-- Past date, should not appear
INSERT INTO BusSchedule (BusScheduleID, routeDriverAssignmentID, plannedDepartureTime, plannedArrivalTime, status) VALUES(3, 1, TIMESTAMP '2025-07-20 09:00:00', TIMESTAMP '2025-07-20 11:00:00', 'cancelled'); 