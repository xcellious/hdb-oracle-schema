-- =============================================================================
-- 00_preflight_and_prereqs.sql
-- Pre-flight verification and standalone-database prerequisite compilation
--
-- Purpose:
--   1. Verify Flyway schema migrations (through V1_0_12) completed successfully.
--   2. Verify required schemas (HDBDBA, DECODES, PSSWD_USER) exist.
--   3. Compile HDBDBA.SNAPSHOT_MANAGER package body using dynamic SQL for the 5
--      unused external USBR DB-link refresh calls (only if currently INVALID).
--      This standalone master database has no remote USBR DB links, and triggers
--      HDB_SITE_SITE_PERM and SDI_CHK_PERM invoke SNAPSHOT_MANAGER.SNAPSHOT_MODIFIED
--      on every INSERT/UPDATE/DELETE to HDB_SITE and HDB_SITE_DATATYPE.
--      All triggers, foreign keys, and constraints remain 100% ENABLED.
-- =============================================================================

PROMPT [00] Running pre-flight checks...

DECLARE
  v_fw_cnt       NUMBER := 0;
  v_fw_fail_cnt  NUMBER := 0;
  v_v12_cnt      NUMBER := 0;
  v_schema_cnt   NUMBER := 0;
  v_sm_status    VARCHAR2(30);
BEGIN
  -- 1. Confirm Flyway schema history table exists and migrations succeeded
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "SYS"."flyway_schema_history" WHERE "success" = 1' INTO v_fw_cnt;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "SYS"."flyway_schema_history" WHERE "success" = 0' INTO v_fw_fail_cnt;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "SYS"."flyway_schema_history" WHERE "version" = ''1.0.12'' AND "success" = 1' INTO v_v12_cnt;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20901,
        'Pre-flight failed: Unable to verify SYS."flyway_schema_history". Run Flyway migrations first. Detail: ' || SQLERRM);
  END;

  IF v_fw_fail_cnt > 0 THEN
    RAISE_APPLICATION_ERROR(-20902,
      'Pre-flight failed: Found ' || v_fw_fail_cnt || ' failed Flyway migration(s). Resolve migrations before seeding.');
  END IF;

  IF v_v12_cnt = 0 THEN
    RAISE_APPLICATION_ERROR(-20903,
      'Pre-flight failed: Flyway migration 1.0.12 has not completed successfully. Run Flyway migrate first.');
  END IF;

  DBMS_OUTPUT.PUT_LINE('  [OK] Flyway schema history verified (' || v_fw_cnt || ' successful entries, version 1.0.12 present).');

  -- 2. Confirm target schemas exist
  SELECT COUNT(*) INTO v_schema_cnt
    FROM dba_users
   WHERE username IN ('HDBDBA', 'DECODES', 'PSSWD_USER');

  IF v_schema_cnt < 3 THEN
    RAISE_APPLICATION_ERROR(-20904,
      'Pre-flight failed: Expected schemas HDBDBA, DECODES, and PSSWD_USER to exist.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('  [OK] Target schemas HDBDBA, DECODES, and PSSWD_USER verified.');

  -- 3. Check SNAPSHOT_MANAGER package body validity
  SELECT NVL(MAX(status), 'MISSING') INTO v_sm_status
    FROM dba_objects
   WHERE owner = 'HDBDBA'
     AND object_name = 'SNAPSHOT_MANAGER'
     AND object_type = 'PACKAGE BODY';

  IF v_sm_status = 'INVALID' THEN
    DBMS_OUTPUT.PUT_LINE('  [INFO] HDBDBA.SNAPSHOT_MANAGER body is INVALID (missing external USBR DB links).');
    DBMS_OUTPUT.PUT_LINE('  [INFO] Recompiling HDBDBA.SNAPSHOT_MANAGER body with dynamic SQL for standalone DB...');

    EXECUTE IMMEDIATE q'[
CREATE OR REPLACE PACKAGE BODY HDBDBA.SNAPSHOT_MANAGER AS

   PROCEDURE SNAPSHOT_MODIFIED(
    P_TABLE_NAME VARCHAR2 ) IS
      l_procedure_indicator varchar2(100);
   BEGIN
      l_procedure_indicator := 'SNAPSHOT_MODIFIED FAILED FOR: ';
      IF P_TABLE_NAME IS NULL THEN
        DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
      END IF;
      INSERT INTO REF_DB_GENERIC_LIST (RECORD_KEY, RECORD_KEY_VALUE1) VALUES
        (G_SNAPSHOT_MANAGER_KEY, UPPER(P_TABLE_NAME));
   END;

   PROCEDURE PERFORM_REFRESH(P_TABLE_NAME VARCHAR2) IS
      l_table_names VARCHAR2(512);
      l_procedure_indicator varchar2(100);
      l_count number;
   BEGIN
      l_procedure_indicator := 'PERFORM_REFRESH FAILED FOR: ';
      IF P_TABLE_NAME IS NULL THEN
        DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
      END IF;

      IF UPPER(P_TABLE_NAME) = 'ALL' THEN
        l_table_names := 'ALL';
      ELSIF P_TABLE_NAME = '%' THEN
        SELECT listagg(table_name, ',') WITHIN GROUP (ORDER BY table_name) INTO l_table_names FROM
          (SELECT DISTINCT record_key_value1 "TABLE_NAME" FROM ref_db_generic_list
            WHERE record_key = G_SNAPSHOT_MANAGER_KEY);
      ELSE
        l_table_names := P_TABLE_NAME;
      END IF;

      SELECT count(*) INTO l_count FROM ref_db_generic_list
       WHERE record_key = G_SNAPSHOT_MANAGER_KEY
         AND record_key_value1 LIKE decode(l_table_names,'ALL','%',l_table_names);

      IF l_count > 0 THEN
        EXECUTE IMMEDIATE 'BEGIN refresh_hdb_snap(:1); END;' USING l_table_names;
        EXECUTE IMMEDIATE 'BEGIN refresh_hdb_snap2(:1); END;' USING l_table_names;
      END IF;

      DELETE FROM REF_DB_GENERIC_LIST WHERE record_key = G_SNAPSHOT_MANAGER_KEY
        AND record_key_value1 LIKE decode(UPPER(P_TABLE_NAME),'ALL','%','%','%',l_table_names);
   END;

   PROCEDURE SNAPSHOT_CZAR_MODIFIED(
    P_TABLE_NAME VARCHAR2 ) IS
      l_procedure_indicator varchar2(100);
   BEGIN
      l_procedure_indicator := 'SNAPSHOT_CZAR_MODIFIED FAILED FOR: ';
      IF P_TABLE_NAME IS NULL THEN
        DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
      END IF;
      INSERT INTO REF_CZAR_DB_GENERIC_LIST (RECORD_KEY, RECORD_KEY_VALUE1) VALUES
        (G_SNAPSHOT_CZAR_MANAGER_KEY, UPPER(P_TABLE_NAME));
   END;

   PROCEDURE PERFORM_CZAR_REFRESH(P_TABLE_NAME VARCHAR2) IS
      l_table_names VARCHAR2(512);
      l_procedure_indicator varchar2(100);
      l_count number;
   BEGIN
      l_procedure_indicator := 'PERFORM_CZAR_REFRESH FAILED FOR: ';
      IF P_TABLE_NAME IS NULL THEN
        DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
      END IF;

      IF UPPER(P_TABLE_NAME) = 'ALL' THEN
        l_table_names := 'ALL';
      ELSIF P_TABLE_NAME = '%' THEN
        SELECT listagg(table_name, ',') WITHIN GROUP (ORDER BY table_name) INTO l_table_names FROM
          (SELECT DISTINCT record_key_value1 "TABLE_NAME" FROM ref_czar_db_generic_list
            WHERE record_key = G_SNAPSHOT_CZAR_MANAGER_KEY);
      ELSE
        l_table_names := P_TABLE_NAME;
      END IF;

      SELECT count(*) INTO l_count FROM ref_czar_db_generic_list
       WHERE record_key = G_SNAPSHOT_CZAR_MANAGER_KEY
         AND record_key_value1 LIKE decode(l_table_names,'ALL','%',l_table_names);

      IF l_count > 0 THEN
        EXECUTE IMMEDIATE 'BEGIN LCHDBA.REFRESH_PHYS_QUAN_SNAP@LCHDB.UC.USBR.GOV; END;';
        EXECUTE IMMEDIATE 'BEGIN YAOHDBA.REFRESH_PHYS_QUAN_SNAP@YAOHDB.UC.USBR.GOV; END;';
        EXECUTE IMMEDIATE 'BEGIN ECODBA.REFRESH_PHYS_QUAN_SNAP@ECOHDB.UC.USBR.GOV; END;';
      END IF;

      DELETE FROM REF_CZAR_DB_GENERIC_LIST WHERE record_key = G_SNAPSHOT_CZAR_MANAGER_KEY
        AND record_key_value1 LIKE decode(UPPER(P_TABLE_NAME),'ALL','%','%','%',l_table_names);
   END;

END SNAPSHOT_MANAGER;]';

    SELECT status INTO v_sm_status
      FROM dba_objects
     WHERE owner = 'HDBDBA'
       AND object_name = 'SNAPSHOT_MANAGER'
       AND object_type = 'PACKAGE BODY';

    IF v_sm_status <> 'VALID' THEN
      RAISE_APPLICATION_ERROR(-20905, 'Pre-flight failed: HDBDBA.SNAPSHOT_MANAGER body is still ' || v_sm_status);
    END IF;
    DBMS_OUTPUT.PUT_LINE('  [OK] HDBDBA.SNAPSHOT_MANAGER body compiled VALID.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  [OK] HDBDBA.SNAPSHOT_MANAGER body is already ' || v_sm_status || '.');
  END IF;
END;
/
