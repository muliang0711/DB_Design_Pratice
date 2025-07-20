DROP TABLE BusStation;

CREATE TABLE BusStation (
    stationID NUMBER(10),
    inactive_from DATE
);

INSERT INTO BusStation (stationID, inactive_from) VALUES(1, NULL);
