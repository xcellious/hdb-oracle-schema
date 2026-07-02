-- V1_0_0__Create_Tablespaces.sql
-- Auto-create HDB tablespaces if they do not already exist.
-- Runs as SYS AS SYSDBA before any user/schema creation.
--
-- Dynamically discovers the datafile directory from the existing PDB,
-- so this works with or without Oracle Managed Files (OMF).
--
-- Tablespaces created (if missing):
--   HDB_DATA  - Default data tablespace for HDB schema objects (50MB, autoextend)
--   HDB_USER  - Tablespace for application users and their objects (50MB, autoextend)
--   HDB_IDX   - Default index tablespace (50MB, autoextend)
--   HDB_TEMP  - Temporary tablespace for sort/hash operations (100MB, autoextend)

DECLARE
    v_count    NUMBER;
    v_datadir  VARCHAR2(500);
BEGIN
    -- Discover the datafile directory from the first existing data file
    SELECT SUBSTR(file_name, 1, INSTR(file_name, '/', -1))
      INTO v_datadir
      FROM dba_data_files
     WHERE ROWNUM = 1;

    -- HDB_DATA (permanent, data tablespace)
    SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = 'HDB_DATA';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLESPACE HDB_DATA DATAFILE ''' || v_datadir || 'hdb_data01.dbf'' SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED';
    END IF;

    -- HDB_USER (permanent, user tablespace)
    SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = 'HDB_USER';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLESPACE HDB_USER DATAFILE ''' || v_datadir || 'hdb_user01.dbf'' SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED';
    END IF;

    -- HDB_IDX (permanent, index tablespace)
    SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = 'HDB_IDX';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLESPACE HDB_IDX DATAFILE ''' || v_datadir || 'hdb_idx01.dbf'' SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED';
    END IF;

    -- HDB_TEMP (temporary tablespace — sized larger for sort/hash/PGA spill operations)
    SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = 'HDB_TEMP';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TEMPORARY TABLESPACE HDB_TEMP TEMPFILE ''' || v_datadir || 'hdb_temp01.dbf'' SIZE 100M AUTOEXTEND ON NEXT 20M MAXSIZE 2G';
    END IF;
END;
/
