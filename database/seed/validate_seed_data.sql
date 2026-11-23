-- =============================================================================
-- validate_seed_data.sql
-- Comprehensive integrity, referential consistency, idempotency, and JOIN
-- verification script for the HDB Oracle sample seed dataset.
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 220
SET PAGESIZE 500
SET TRIMSPOOL ON

PROMPT ============================================================================
PROMPT 1. FLYWAY SCHEMA HISTORY & CONSTRAINT / TRIGGER INTEGRITY CHECK
PROMPT ============================================================================

DECLARE
  v_fw_ok       NUMBER;
  v_fw_fail     NUMBER;
  v_dis_cons    NUMBER;
  v_dis_trigs   NUMBER;
  v_invalid_cnt NUMBER;
  c_hdb_owner   CONSTANT VARCHAR2(128) := UPPER('${hdb_user}');
BEGIN
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "SYS"."flyway_schema_history" WHERE "success" = 1' INTO v_fw_ok;
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "SYS"."flyway_schema_history" WHERE "success" = 0' INTO v_fw_fail;

  SELECT COUNT(*) INTO v_dis_cons
    FROM dba_constraints
   WHERE owner IN (c_hdb_owner, 'DECODES', 'PSSWD_USER')
     AND status <> 'ENABLED';

  SELECT COUNT(*) INTO v_dis_trigs
    FROM dba_triggers
   WHERE owner IN (c_hdb_owner, 'DECODES', 'PSSWD_USER')
     AND status <> 'ENABLED';

  SELECT COUNT(*) INTO v_invalid_cnt
    FROM dba_objects
   WHERE owner IN (c_hdb_owner, 'DECODES', 'PSSWD_USER')
     AND status <> 'VALID';

  DBMS_OUTPUT.PUT_LINE('  Flyway successful migrations : ' || v_fw_ok || ' (failed: ' || v_fw_fail || ')');
  DBMS_OUTPUT.PUT_LINE('  Disabled constraints         : ' || v_dis_cons);
  DBMS_OUTPUT.PUT_LINE('  Disabled triggers            : ' || v_dis_trigs);
  DBMS_OUTPUT.PUT_LINE('  Invalid objects remaining    : ' || v_invalid_cnt || ' (expected: 1 = SENDMAIL without UTL_MAIL)');

  IF v_fw_fail > 0 THEN
    RAISE_APPLICATION_ERROR(-20910, 'Validation failed: Flyway history has failed migrations.');
  END IF;
  IF v_dis_cons > 0 THEN
    RAISE_APPLICATION_ERROR(-20911, 'Validation failed: Found ' || v_dis_cons || ' disabled constraint(s).');
  END IF;
  IF v_dis_trigs > 0 THEN
    RAISE_APPLICATION_ERROR(-20912, 'Validation failed: Found ' || v_dis_trigs || ' disabled trigger(s).');
  END IF;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT 2. DYNAMIC FOREIGN KEY & ORPHANED CHILD RECORD AUDIT (ALL ENABLED FKs)
PROMPT ============================================================================

DECLARE
  v_total_fks   NUMBER := 0;
  v_orphan_fks  NUMBER := 0;
  v_orphan_rows NUMBER := 0;
  v_sql         VARCHAR2(4000);
  v_join        VARCHAR2(2000);
  v_nn          VARCHAR2(2000);
BEGIN
  FOR fk IN (
    SELECT c.owner, c.table_name, c.constraint_name,
           rc.owner AS r_owner, rc.table_name AS r_table_name, c.r_constraint_name
      FROM dba_constraints c
      JOIN dba_constraints rc
        ON rc.owner = c.r_owner AND rc.constraint_name = c.r_constraint_name
     WHERE c.owner IN (UPPER('${hdb_user}'), 'DECODES', 'PSSWD_USER')
       AND c.constraint_type = 'R'
     ORDER BY c.owner, c.table_name, c.constraint_name
  ) LOOP
    v_total_fks := v_total_fks + 1;
    v_join := NULL;
    v_nn   := NULL;

    FOR col IN (
      SELECT cc.column_name AS child_col, rcc.column_name AS parent_col, cc.position
        FROM dba_cons_columns cc
        JOIN dba_cons_columns rcc
          ON rcc.owner = fk.r_owner
         AND rcc.constraint_name = fk.r_constraint_name
         AND rcc.position = cc.position
       WHERE cc.owner = fk.owner
         AND cc.constraint_name = fk.constraint_name
       ORDER BY cc.position
    ) LOOP
      v_join := CASE WHEN v_join IS NULL THEN '' ELSE v_join || ' AND ' END
                || 'p."' || col.parent_col || '" = c."' || col.child_col || '"';
      v_nn   := CASE WHEN v_nn IS NULL THEN '' ELSE v_nn || ' AND ' END
                || 'c."' || col.child_col || '" IS NOT NULL';
    END LOOP;

    v_sql := 'SELECT COUNT(*) FROM "' || fk.owner || '"."' || fk.table_name || '" c '
          || 'WHERE ' || v_nn
          || ' AND NOT EXISTS (SELECT 1 FROM "' || fk.r_owner || '"."' || fk.r_table_name || '" p WHERE ' || v_join || ')';

    EXECUTE IMMEDIATE v_sql INTO v_orphan_rows;
    IF v_orphan_rows > 0 THEN
      v_orphan_fks := v_orphan_fks + 1;
      DBMS_OUTPUT.PUT_LINE('  [FAIL] Orphan rows=' || v_orphan_rows || ' for FK ' || fk.owner || '.' || fk.table_name || '.' || fk.constraint_name);
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('  Total FK constraints audited : ' || v_total_fks);
  DBMS_OUTPUT.PUT_LINE('  FKs with orphaned children   : ' || v_orphan_fks);

  IF v_orphan_fks > 0 THEN
    RAISE_APPLICATION_ERROR(-20913, 'Validation failed: Orphaned child records found in ' || v_orphan_fks || ' FK(s).');
  END IF;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT 3. LOGICAL CROSS-SCHEMA & BUSINESS RULE CONSISTENCY CHECKS
PROMPT ============================================================================

DECLARE
  v_cnt  NUMBER;
  v_fail NUMBER := 0;

  PROCEDURE check_zero(p_label VARCHAR2, p_sql VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql INTO v_cnt;
    IF v_cnt = 0 THEN
      DBMS_OUTPUT.PUT_LINE('  [PASS] ' || RPAD(p_label, 68) || ' (0 violations)');
    ELSE
      v_fail := v_fail + 1;
      DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || RPAD(p_label, 68) || ' (' || v_cnt || ' violations)');
    END IF;
  END;
BEGIN
  -- Logical cross-schema links (not enforced by physical FK in DECODES/ALARM)
  check_zero('DECODES.PLATFORM.SITEID -> ${hdb_user}.HDB_SITE',
    'SELECT COUNT(*) FROM decodes.platform p WHERE p.siteid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ${hdb_user}.hdb_site s WHERE s.site_id = p.siteid)');
  check_zero('DECODES.SITE_PROPERTY.SITE_ID -> ${hdb_user}.HDB_SITE',
    'SELECT COUNT(*) FROM decodes.site_property sp WHERE NOT EXISTS (SELECT 1 FROM ${hdb_user}.hdb_site s WHERE s.site_id = sp.site_id)');
  check_zero('DECODES.PLATFORM.CONFIGID -> DECODES.PLATFORMCONFIG',
    'SELECT COUNT(*) FROM decodes.platform p WHERE p.configid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM decodes.platformconfig c WHERE c.id = p.configid)');
  check_zero('DECODES.PLATFORM_STATUS.PLATFORM_ID -> DECODES.PLATFORM',
    'SELECT COUNT(*) FROM decodes.platform_status ps WHERE NOT EXISTS (SELECT 1 FROM decodes.platform p WHERE p.id = ps.platform_id)');
  check_zero('DECODES.DATATYPEEQUIVALENCE -> DECODES.DATATYPE',
    'SELECT COUNT(*) FROM decodes.datatypeequivalence e WHERE NOT EXISTS (SELECT 1 FROM decodes.datatype d WHERE d.id = e.id0) OR NOT EXISTS (SELECT 1 FROM decodes.datatype d WHERE d.id = e.id1)');
  check_zero('${hdb_user}.ALARM_SCREENING -> HDB_SITE & HDB_DATATYPE',
    'SELECT COUNT(*) FROM ${hdb_user}.alarm_screening a WHERE (a.site_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ${hdb_user}.hdb_site s WHERE s.site_id = a.site_id)) OR NOT EXISTS (SELECT 1 FROM ${hdb_user}.hdb_datatype d WHERE d.datatype_id = a.datatype_id)');
  check_zero('${hdb_user}.ALARM_CURRENT.TS_ID -> ${hdb_user}.CP_TS_ID',
    'SELECT COUNT(*) FROM ${hdb_user}.alarm_current a WHERE NOT EXISTS (SELECT 1 FROM ${hdb_user}.cp_ts_id t WHERE t.ts_id = a.ts_id)');
  check_zero('${hdb_user}.ALARM_HISTORY.TS_ID -> ${hdb_user}.CP_TS_ID',
    'SELECT COUNT(*) FROM ${hdb_user}.alarm_history a WHERE NOT EXISTS (SELECT 1 FROM ${hdb_user}.cp_ts_id t WHERE t.ts_id = a.ts_id)');
  check_zero('${hdb_user}.HDB_DATATYPE synced to DECODES.DATATYPE (HDB std)',
    'SELECT COUNT(*) FROM ${hdb_user}.hdb_datatype h WHERE NOT EXISTS (SELECT 1 FROM decodes.datatype d WHERE d.standard = ''HDB'' AND d.id = h.datatype_id)');
  check_zero('${hdb_user}.HDB_SITE synced to ${hdb_user}.DECODES_SITE_EXT',
    'SELECT COUNT(*) FROM ${hdb_user}.hdb_site s WHERE NOT EXISTS (SELECT 1 FROM ${hdb_user}.decodes_site_ext e WHERE e.site_id = s.site_id)');
  check_zero('${hdb_user}.R_BASE non-F rows merged into R_DAY',
    'SELECT COUNT(*) FROM ${hdb_user}.r_base rb WHERE rb.interval = ''day'' AND NVL(rb.validation,''V'') <> ''F'' AND NOT EXISTS (SELECT 1 FROM ${hdb_user}.r_day rd WHERE rd.site_datatype_id = rb.site_datatype_id AND rd.start_date_time = rb.start_date_time)');
  check_zero('${hdb_user}.R_BASE failed (F) rows excluded from R_DAY',
    'SELECT COUNT(*) FROM ${hdb_user}.r_base rb WHERE rb.interval = ''day'' AND rb.validation = ''F'' AND EXISTS (SELECT 1 FROM ${hdb_user}.r_day rd WHERE rd.site_datatype_id = rb.site_datatype_id AND rd.start_date_time = rb.start_date_time)');
  check_zero('${hdb_user}.REF_SITE_RATING.INDEP_SITE_DATATYPE_ID -> HDB_SITE_DATATYPE',
    'SELECT COUNT(*) FROM ${hdb_user}.ref_site_rating r WHERE NOT EXISTS (SELECT 1 FROM ${hdb_user}.hdb_site_datatype s WHERE s.site_datatype_id = r.indep_site_datatype_id)');

  IF v_fail > 0 THEN
    RAISE_APPLICATION_ERROR(-20914, 'Validation failed: ' || v_fail || ' business-rule/cross-schema check(s) failed.');
  END IF;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT 4. POPULATED TABLE RECORD COUNTS SUMMARY
PROMPT ============================================================================

DECLARE
  v_cnt         NUMBER;
  v_pop_tables  NUMBER := 0;
  v_total_rows  NUMBER := 0;
  v_empty_tbls  NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE(RPAD('SCHEMA.TABLE_NAME', 50) || LPAD('ROW_COUNT', 12));
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 50, '-') || LPAD('-', 12, '-'));

  FOR r IN (
    SELECT owner, table_name
      FROM dba_tables
     WHERE owner IN (UPPER('${hdb_user}'), 'DECODES', 'PSSWD_USER')
     ORDER BY owner, table_name
  ) LOOP
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || r.owner || '"."' || r.table_name || '"' INTO v_cnt;
    IF v_cnt > 0 THEN
      v_pop_tables := v_pop_tables + 1;
      v_total_rows := v_total_rows + v_cnt;
      DBMS_OUTPUT.PUT_LINE(RPAD(r.owner || '.' || r.table_name, 50) || LPAD(TO_CHAR(v_cnt), 12));
    ELSE
      v_empty_tbls := v_empty_tbls + 1;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(RPAD('-', 62, '-'));
  DBMS_OUTPUT.PUT_LINE('Populated tables: ' || v_pop_tables || ' | Empty (archive/staging/unused) tables: ' || v_empty_tbls || ' | Total rows: ' || v_total_rows);
END;
/

PROMPT
PROMPT ============================================================================
PROMPT 5. SAMPLE MULTI-TABLE JOIN QUERIES (END-TO-END WORKFLOW VERIFICATION)
PROMPT ============================================================================

SET HEADING ON
COLUMN site_name        FORMAT A32
COLUMN state_code       FORMAT A5
COLUMN river_name       FORMAT A18
COLUMN damtype_name     FORMAT A22
COLUMN datatype_name    FORMAT A22
COLUMN unit_name        FORMAT A10
COLUMN model_name       FORMAT A22
COLUMN model_run_name   FORMAT A38
COLUMN comp_name        FORMAT A34
COLUMN algo_name        FORMAT A20
COLUMN platform_desc    FORMAT A32
COLUMN medium_id        FORMAT A10
COLUMN alarm_msg        FORMAT A55

PROMPT
PROMPT === Query A: Reservoir Operations Snapshot (HDB_SITE + REF_RES + HDB_STATE + HDB_DAMTYPE + R_DAY) ===
SELECT s.site_common_name                                     AS site_name,
       st.state_code                                          AS state_code,
       dt_dam.damtype_name                                    AS damtype_name,
       ROUND(r.captot / 1000000, 2)                           AS cap_maf,
       ROUND(AVG(d.value), 2)                                 AS avg_sep2025_elev_ft,
       COUNT(d.value)                                         AS daily_obs
  FROM ${hdb_user}.hdb_site s
  JOIN ${hdb_user}.ref_res r            ON r.site_id = s.site_id
  JOIN ${hdb_user}.hdb_state st         ON st.state_id = s.state_id
  JOIN ${hdb_user}.hdb_damtype dt_dam   ON dt_dam.damtype_id = r.damtype_id
  JOIN ${hdb_user}.hdb_site_datatype sd ON sd.site_id = s.site_id AND sd.datatype_id = 1
  JOIN ${hdb_user}.r_day d              ON d.site_datatype_id = sd.site_datatype_id
 GROUP BY s.site_common_name, st.state_code, dt_dam.damtype_name, r.captot
 ORDER BY cap_maf DESC;

PROMPT
PROMPT === Query B: Monthly Hydrograph vs 24-Month Study Projections (R_MONTH + M_MONTH + REF_MODEL_RUN + HDB_MODEL) ===
SELECT m.model_name                                           AS model_name,
       mr.model_run_name                                      AS model_run_name,
       s.site_common_name                                     AS site_name,
       COUNT(mm.value)                                        AS months_proj,
       ROUND(MIN(mm.value), 2)                                AS min_elev_ft,
       ROUND(MAX(mm.value), 2)                                AS max_elev_ft
  FROM ${hdb_user}.m_month mm
  JOIN ${hdb_user}.ref_model_run mr     ON mr.model_run_id = mm.model_run_id
  JOIN ${hdb_user}.hdb_model m          ON m.model_id = mr.model_id
  JOIN ${hdb_user}.hdb_site_datatype sd ON sd.site_datatype_id = mm.site_datatype_id
  JOIN ${hdb_user}.hdb_site s           ON s.site_id = sd.site_id
 WHERE sd.datatype_id = 1
 GROUP BY m.model_name, mr.model_run_name, s.site_common_name
 ORDER BY m.model_name, mr.model_run_name, s.site_common_name;

PROMPT
PROMPT === Query C: Active Computation Pipeline & Triggered Tasklist (CP_COMPUTATION + CP_ALGORITHM + CP_COMP_DEPENDS + CP_TS_ID) ===
SELECT c.computation_name                                     AS comp_name,
       a.algorithm_name                                       AS algo_name,
       c.enabled                                              AS en,
       COUNT(DISTINCT d.ts_id)                                AS input_ts_cnt,
       COUNT(DISTINCT tl.record_num)                          AS queued_tasks
  FROM ${hdb_user}.cp_computation c
  JOIN ${hdb_user}.cp_algorithm a       ON a.algorithm_id = c.algorithm_id
  LEFT JOIN ${hdb_user}.cp_comp_depends d ON d.computation_id = c.computation_id
  LEFT JOIN ${hdb_user}.cp_ts_id t      ON t.ts_id = d.ts_id
  LEFT JOIN ${hdb_user}.cp_comp_tasklist tl
         ON tl.site_datatype_id = t.site_datatype_id
        AND tl.interval = t.interval
        AND tl.table_selector = t.table_selector
 WHERE c.computation_id > 0
 GROUP BY c.computation_name, a.algorithm_name, c.enabled
 ORDER BY c.enabled DESC, queued_tasks DESC, c.computation_name
 FETCH FIRST 12 ROWS ONLY;

PROMPT
PROMPT === Query D: Cross-Schema Telemetry & Active Alarms (DECODES.PLATFORM + TRANSPORTMEDIUM + HDB_SITE + ALARM_CURRENT) ===
SELECT s.site_common_name                                     AS site_name,
       p.agency                                               AS agency,
       tm.mediumid                                            AS medium_id,
       ps.last_contact_time                                   AS last_contact,
       ac.data_value                                          AS alarm_val,
       SUBSTR(ac.message, 1, 55)                              AS alarm_msg
  FROM ${hdb_user}.alarm_current ac
  JOIN ${hdb_user}.cp_ts_id ts          ON ts.ts_id = ac.ts_id
  JOIN ${hdb_user}.hdb_site_datatype sd ON sd.site_datatype_id = ts.site_datatype_id
  JOIN ${hdb_user}.hdb_site s           ON s.site_id = sd.site_id
  JOIN decodes.platform p          ON p.siteid = s.site_id
  JOIN decodes.transportmedium tm  ON tm.platformid = p.id
  JOIN decodes.platform_status ps  ON ps.platform_id = p.id
 ORDER BY s.site_common_name;

PROMPT
PROMPT ============================================================================
PROMPT All validation checks passed!
PROMPT ============================================================================
EXIT 0
