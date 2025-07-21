DROP TABLE Bus;
CREATE TABLE Bus (
    busID NUMBER(10),
    status VARCHAR2(20)
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

DROP TABLE DriverListAssignment;
CREATE TABLE DriverListAssignment (
    assignmentID NUMBER(10),
    busID NUMBER(10),
    assignedTo DATE,
    status VARCHAR2(20),
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

DROP TABLE BusSchedule;
CREATE TABLE BusSchedule (
    BusScheduleID NUMBER(10),
    routeDriverAssignmentID NUMBER(10),
    status VARCHAR(20)
);


INSERT INTO Bus (busID) VALUES(1);
INSERT INTO Bus (busID) VALUES(2);

INSERT INTO StaffRole (roleID, roleName) VALUES(1, 'Maintenance worker');
INSERT INTO StaffRole (roleID, roleName) VALUES(2, 'Counter staff');
INSERT INTO StaffRole (roleID, roleName) VALUES(3, 'Cleaner');

INSERT INTO Staff (staffID, roleID) VALUES(1, 1);
INSERT INTO Staff (staffID, roleID) VALUES(2, 2);

INSERT INTO MaintenanceService (serviceID) VALUES(1);
INSERT INTO MaintenanceService (serviceID) VALUES(2);
INSERT INTO MaintenanceService (serviceID) VALUES(3);

INSERT INTO DriverListAssignment (assignmentID, busID, assignedTo) VALUES(1, 1, SYSDATE-1);
INSERT INTO DriverListAssignment (assignmentID, busID, assignedTo) VALUES(2, 1, SYSDATE);
INSERT INTO DriverListAssignment (assignmentID, busID, assignedTo) VALUES(3, 2, SYSDATE);
