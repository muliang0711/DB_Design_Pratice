DROP TABLE Bus;
CREATE TABLE Bus (
    busID NUMBER(10)
);

DROP TABLE BusMaintenance;
CREATE TABLE BusMaintenance (
    maintenanceID NUMBER(10),
    busID NUMBER(10)
);

DROP TABLE DriverListAssignment;
CREATE TABLE DriverListAssignment (
    assignmentID NUMBER(10),
    busID NUMBER(10),
    assignedTo DATE,
    status VARCHAR2(20),
    CONSTRAINT chk_status CHECK (status IN ('active', 'inactive', 'not_assigned'))
);

INSERT INTO Bus (busID) VALUES(1);
INSERT INTO Bus (busID) VALUES(2);

INSERT INTO DriverListAssignment (assignmentID, busID, assignedTo) VALUES(1, 1, SYSDATE-1);
INSERT INTO DriverListAssignment (assignmentID, busID, assignedTo) VALUES(2, 1, SYSDATE);
INSERT INTO DriverListAssignment (assignmentID, busID, assignedTo) VALUES(3, 2, SYSDATE);
