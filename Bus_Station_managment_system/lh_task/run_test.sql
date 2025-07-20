SET SERVEROUTPUT ON

START prepare_tables;
START prc_deactivate_busstation;

EXEC prc_deactivate_busstation(2);