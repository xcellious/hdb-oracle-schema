-- =============================================================================
-- 04_models_ensembles_and_cp.sql
-- Populates REF_MODEL_RUN, REF_MODEL_RUN_KEYVAL, REF_ENSEMBLE,
-- REF_ENSEMBLE_KEYVAL, REF_ENSEMBLE_TRACE, TSDB_GROUP & TSDB_GROUP_MEMBER_*,
-- CP_ALGORITHM, CP_ALGO_PROPERTY, CP_ALGO_TS_PARM, CP_ALGO_SCRIPT,
-- CP_COMPUTATION, CP_COMP_PROPERTY, CP_COMP_TS_PARM, CP_TS_ID,
-- CP_COMP_DEPENDS, CP_COMP_PROC_LOCK, and CP_HISTORIC_COMPUTATIONS.
--
-- Idempotent: Natural-key lookup for trigger-assigned REF_MODEL_RUN IDs,
-- CP_PROCESSOR.CREATE_TS_ID / POPULATE_CP_COMP_DEPENDS for TS/depends,
-- and insert-only MERGE for all other tables.
-- =============================================================================

PROMPT [04] Seeding model runs, ensembles, TSDB groups, and computation processor metadata...

ALTER SESSION SET CURRENT_SCHEMA = HDBDBA;

DECLARE
  TYPE t_id_map IS TABLE OF NUMBER INDEX BY VARCHAR2(100);
  v_mri       t_id_map;
  v_ts_id     NUMBER;
  v_seq_val   NUMBER;
  v_mri_val   NUMBER;

  PROCEDURE ensure_model_run(
    p_key VARCHAR2, p_name VARCHAR2, p_model_id NUMBER, p_ek VARCHAR2,
    p_run_dt DATE, p_start DATE, p_end DATE, p_hydro VARCHAR2,
    p_mtype VARCHAR2, p_tsdesc VARCHAR2, p_cmmnt VARCHAR2
  ) IS
    v_id NUMBER;
  BEGIN
    BEGIN
      SELECT model_run_id INTO v_id
        FROM ref_model_run
       WHERE model_run_name = p_name
         AND model_id = p_model_id
         AND run_date = p_run_dt;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO ref_model_run (
          model_run_id, model_run_name, model_id, date_time_loaded,
          user_name, extra_keys_y_n, run_date, start_date, end_date,
          hydrologic_indicator, modeltype, time_step_descriptor, cmmnt
        ) VALUES (
          -1, p_name, p_model_id, SYSDATE,
          USER, p_ek, p_run_dt, p_start, p_end,
          p_hydro, p_mtype, p_tsdesc, p_cmmnt
        ) RETURNING model_run_id INTO v_id;
    END;
    v_mri(p_key) := v_id;
  END;

  PROCEDURE add_mri_kv(p_key VARCHAR2, p_k VARCHAR2, p_v VARCHAR2) IS
    v_id NUMBER := v_mri(p_key);
  BEGIN
    MERGE INTO ref_model_run_keyval t USING (SELECT v_id id, p_k k FROM dual) s
    ON (t.model_run_id = s.id AND t.key_name = s.k)
    WHEN NOT MATCHED THEN INSERT (model_run_id, key_name, key_value, date_time_loaded)
    VALUES (v_id, p_k, p_v, SYSDATE);
  END;

  PROCEDURE add_trace(p_ens NUMBER, p_tid NUMBER, p_tnum NUMBER, p_tname VARCHAR2, p_key VARCHAR2) IS
    v_id NUMBER := v_mri(p_key);
  BEGIN
    MERGE INTO ref_ensemble_trace t USING (
      SELECT p_ens eid, p_tid tid, v_id mid FROM dual
    ) s ON (t.ensemble_id = s.eid AND t.trace_id = s.tid AND t.model_run_id = s.mid)
    WHEN NOT MATCHED THEN INSERT (ensemble_id, trace_id, trace_numeric, trace_name, model_run_id)
    VALUES (p_ens, p_tid, p_tnum, p_tname, v_id);
  END;

  PROCEDURE add_comp(
    p_id NUMBER, p_name VARCHAR2, p_alg NUMBER, p_cmmnt VARCHAR2,
    p_app NUMBER, p_en VARCHAR2, p_es DATE, p_ee DATE, p_grp NUMBER
  ) IS
  BEGIN
    MERGE INTO cp_computation t USING (SELECT p_id id FROM dual) s ON (t.computation_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      computation_id, computation_name, algorithm_id, cmmnt,
      loading_application_id, date_time_loaded, enabled,
      effective_start_date_time, effective_end_date_time, group_id, db_office_code
    ) VALUES (
      p_id, p_name, p_alg, p_cmmnt,
      p_app, SYSDATE, p_en, p_es, p_ee, p_grp, 1
    );
  END;

  PROCEDURE add_comp_parm(
    p_cid NUMBER, p_role VARCHAR2, p_sdi NUMBER, p_int VARCHAR2,
    p_ts VARCHAR2, p_dt NUMBER, p_mid NUMBER, p_dtid NUMBER, p_dtu VARCHAR2, p_sid NUMBER
  ) IS
  BEGIN
    MERGE INTO cp_comp_ts_parm t USING (SELECT p_cid cid, p_role rl FROM dual) s
    ON (t.computation_id = s.cid AND t.algo_role_name = s.rl)
    WHEN NOT MATCHED THEN INSERT (
      computation_id, algo_role_name, site_datatype_id, interval,
      table_selector, delta_t, model_id, datatype_id, delta_t_units, site_id
    ) VALUES (
      p_cid, p_role, p_sdi, p_int, p_ts, p_dt, p_mid, p_dtid, p_dtu, p_sid
    );
  END;

BEGIN
  populate_pk.SET_PRE_POPULATED(0);

  -- ---------------------------------------------------------------------------
  -- 1. Model Runs (REF_MODEL_RUN) — 24 realistic runs across operational/planning/forecast models
  -- ---------------------------------------------------------------------------
  ensure_model_run('24MS_2025_APR_MOST', '24-Month Study Apr 2025 Most Probable',  3, 'Y', DATE '2025-04-15', DATE '2025-04-01', DATE '2027-03-31', 'Most Probable',   'O', '1 Month', 'Official April 2025 24-Month Study Most Probable inflow');
  ensure_model_run('24MS_2025_APR_MIN',  '24-Month Study Apr 2025 Min Probable',   3, 'Y', DATE '2025-04-15', DATE '2025-04-01', DATE '2027-03-31', 'Min Probable',    'O', '1 Month', 'Official April 2025 24-Month Study Minimum Probable inflow');
  ensure_model_run('24MS_2025_APR_MAX',  '24-Month Study Apr 2025 Max Probable',   3, 'Y', DATE '2025-04-15', DATE '2025-04-01', DATE '2027-03-31', 'Max Probable',    'O', '1 Month', 'Official April 2025 24-Month Study Maximum Probable inflow');
  ensure_model_run('24MS_2025_AUG_MOST', '24-Month Study Aug 2025 Most Probable',  3, 'Y', DATE '2025-08-15', DATE '2025-08-01', DATE '2027-07-31', 'Most Probable',   'O', '1 Month', 'Annual Operating Plan tier-determination August 24-Month Study');
  ensure_model_run('24MS_2025_AUG_MIN',  '24-Month Study Aug 2025 Min Probable',   3, 'Y', DATE '2025-08-15', DATE '2025-08-01', DATE '2027-07-31', 'Min Probable',    'O', '1 Month', 'August 2025 Minimum Probable sensitivity run');
  ensure_model_run('24MS_2025_AUG_MAX',  '24-Month Study Aug 2025 Max Probable',   3, 'Y', DATE '2025-08-15', DATE '2025-08-01', DATE '2027-07-31', 'Max Probable',    'O', '1 Month', 'August 2025 Maximum Probable sensitivity run');
  ensure_model_run('24MS_2024_AUG_MOST', '24-Month Study Aug 2024 Most Probable',  3, 'Y', DATE '2024-08-15', DATE '2024-08-01', DATE '2026-07-31', 'Most Probable',   'H', '1 Month', 'Historical WY2025 tier-determination August 2024 24-Month Study');

  ensure_model_run('CRSS_2025_ST_T01',   'CRSS 2025 StressTest Trace 1988',        1, 'Y', DATE '2025-01-20', DATE '2025-01-01', DATE '2030-12-31', 'Stress Test 1988','P', '1 Month', 'Post-2026 EIS planning run, ISM trace 1988');
  ensure_model_run('CRSS_2025_ST_T02',   'CRSS 2025 StressTest Trace 2000',        1, 'Y', DATE '2025-01-20', DATE '2025-01-01', DATE '2030-12-31', 'Stress Test 2000','P', '1 Month', 'Post-2026 EIS planning run, ISM trace 2000');
  ensure_model_run('CRSS_2025_ST_T03',   'CRSS 2025 StressTest Trace 2011',        1, 'Y', DATE '2025-01-20', DATE '2025-01-01', DATE '2030-12-31', 'Stress Test 2011','P', '1 Month', 'Post-2026 EIS planning run, wet ISM trace 2011');
  ensure_model_run('CRSS_2025_ST_T04',   'CRSS 2025 StressTest Trace 2021',        1, 'Y', DATE '2025-01-20', DATE '2025-01-01', DATE '2030-12-31', 'Stress Test 2021','P', '1 Month', 'Post-2026 EIS planning run, dry ISM trace 2021');

  ensure_model_run('MTOM_2025_MAY_T10',  'MTOM May 2025 ESP Trace 1991',           2, 'Y', DATE '2025-05-05', DATE '2025-05-01', DATE '2029-12-31', 'ESP 1991',        'F', '1 Month', 'Mid-term probabilistic operations trace 1991');
  ensure_model_run('MTOM_2025_MAY_T20',  'MTOM May 2025 ESP Trace 1997',           2, 'Y', DATE '2025-05-05', DATE '2025-05-01', DATE '2029-12-31', 'ESP 1997',        'F', '1 Month', 'Mid-term probabilistic operations wet trace 1997');
  ensure_model_run('MTOM_2025_MAY_T30',  'MTOM May 2025 ESP Trace 2002',           2, 'Y', DATE '2025-05-05', DATE '2025-05-01', DATE '2029-12-31', 'ESP 2002',        'F', '1 Month', 'Mid-term probabilistic operations drought trace 2002');
  ensure_model_run('MTOM_2025_MAY_T40',  'MTOM May 2025 ESP Trace 2019',           2, 'Y', DATE '2025-05-05', DATE '2025-05-01', DATE '2029-12-31', 'ESP 2019',        'F', '1 Month', 'Mid-term probabilistic operations trace 2019');

  ensure_model_run('ESP_2025_APR_P10',   'CBRFC ESP Apr 2025 10% Exceedance',      4, 'N', DATE '2025-04-03', DATE '2025-04-01', DATE '2025-09-30', 'ESP 10% Wet',     'F', '1 Month', 'CBRFC April 1 water supply forecast 10% exceedance');
  ensure_model_run('ESP_2025_APR_P50',   'CBRFC ESP Apr 2025 50% Median',          4, 'N', DATE '2025-04-03', DATE '2025-04-01', DATE '2025-09-30', 'ESP 50% Median',  'F', '1 Month', 'CBRFC April 1 water supply forecast 50% median');
  ensure_model_run('ESP_2025_APR_P90',   'CBRFC ESP Apr 2025 90% Exceedance',      4, 'N', DATE '2025-04-03', DATE '2025-04-01', DATE '2025-09-30', 'ESP 90% Dry',     'F', '1 Month', 'CBRFC April 1 water supply forecast 90% exceedance');

  ensure_model_run('UB_DAILY_2025_SEP',  'Upper Basin Daily Ops Sep 2025',         5, 'N', DATE '2025-09-01', DATE '2025-09-01', DATE '2025-09-30', 'Operational',     'O', '1 Day',   'Daily release & storage routing schedule for September 2025');
  ensure_model_run('GLEN_HR_2025_SEP15', 'Glen Canyon Hourly Ops 2025-09-15',      6, 'N', DATE '2025-09-14', DATE '2025-09-15', DATE '2025-09-18', 'WAPA Schedule',   'O', '1 Hour',  'Hourly peaking release schedule coordinated with WAPA');
  ensure_model_run('FG_BIOP_2025_SPR',   'Flaming Gorge Spring Peak 2025',         7, 'N', DATE '2025-05-10', DATE '2025-05-15', DATE '2025-07-15', 'Moderately Wet',  'O', '1 Day',   'Green River larval trigger spring release model');
  ensure_model_run('SJ_REC_2025_SPR',    'San Juan Spring Release 2025',           8, 'N', DATE '2025-05-01', DATE '2025-05-15', DATE '2025-07-15', 'Normal',          'O', '1 Day',   'Navajo Dam spring peak release plan');
  ensure_model_run('ASP_DAILY_2025_JUN', 'Aspinall Unit Daily Ops Jun 2025',       9, 'N', DATE '2025-06-01', DATE '2025-06-01', DATE '2025-06-30', 'Spring Runoff',   'O', '1 Day',   'Blue Mesa / Morrow Point / Crystal daily flood-control ops');
  ensure_model_run('LB_ACCT_2025_AOP',   'Lower Basin AOP Delivery Schedule 2025', 10,'Y', DATE '2025-01-10', DATE '2025-01-01', DATE '2025-12-31', 'Tier 1 Shortage', 'O', '1 Month', 'Annual Operating Plan Lower Basin diversion schedules');

  -- Model Run Key-Values (REF_MODEL_RUN_KEYVAL)
  add_mri_kv('24MS_2025_APR_MOST', 'POLICY_VERSION', '2007_IG_DROUGHT_2024');
  add_mri_kv('24MS_2025_APR_MOST', 'INFLOW_SCENARIO','MOST_PROBABLE');
  add_mri_kv('24MS_2025_APR_MIN',  'POLICY_VERSION', '2007_IG_DROUGHT_2024');
  add_mri_kv('24MS_2025_APR_MIN',  'INFLOW_SCENARIO','MIN_PROBABLE');
  add_mri_kv('24MS_2025_APR_MAX',  'POLICY_VERSION', '2007_IG_DROUGHT_2024');
  add_mri_kv('24MS_2025_APR_MAX',  'INFLOW_SCENARIO','MAX_PROBABLE');
  add_mri_kv('24MS_2025_AUG_MOST', 'POLICY_VERSION', '2007_IG_DROUGHT_2024');
  add_mri_kv('24MS_2025_AUG_MOST', 'AOP_DETERMINATION', 'WY2026_OFFICIAL');
  add_mri_kv('24MS_2025_AUG_MIN',  'INFLOW_SCENARIO','MIN_PROBABLE');
  add_mri_kv('24MS_2025_AUG_MAX',  'INFLOW_SCENARIO','MAX_PROBABLE');
  add_mri_kv('24MS_2024_AUG_MOST', 'AOP_DETERMINATION', 'WY2025_OFFICIAL');
  add_mri_kv('CRSS_2025_ST_T01',   'ALTERNATIVE',    'POST2026_NO_ACTION');
  add_mri_kv('CRSS_2025_ST_T01',   'ISM_START_YEAR', '1988');
  add_mri_kv('CRSS_2025_ST_T02',   'ALTERNATIVE',    'POST2026_NO_ACTION');
  add_mri_kv('CRSS_2025_ST_T02',   'ISM_START_YEAR', '2000');
  add_mri_kv('CRSS_2025_ST_T03',   'ALTERNATIVE',    'POST2026_NO_ACTION');
  add_mri_kv('CRSS_2025_ST_T03',   'ISM_START_YEAR', '2011');
  add_mri_kv('CRSS_2025_ST_T04',   'ALTERNATIVE',    'POST2026_NO_ACTION');
  add_mri_kv('CRSS_2025_ST_T04',   'ISM_START_YEAR', '2021');
  add_mri_kv('MTOM_2025_MAY_T10',  'TRACE_YEAR',     '1991');
  add_mri_kv('MTOM_2025_MAY_T20',  'TRACE_YEAR',     '1997');
  add_mri_kv('MTOM_2025_MAY_T30',  'TRACE_YEAR',     '2002');
  add_mri_kv('MTOM_2025_MAY_T40',  'TRACE_YEAR',     '2019');
  add_mri_kv('LB_ACCT_2025_AOP',   'SHORTAGE_TIER',  'TIER_1');
  add_mri_kv('LB_ACCT_2025_AOP',   'CAP_CUTBACK_AF', '512000');

  -- ---------------------------------------------------------------------------
  -- 2. Ensembles (REF_ENSEMBLE, REF_ENSEMBLE_KEYVAL, REF_ENSEMBLE_TRACE)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, '24MS_2025_APR_SUITE' nm,      1 ag, 'PROBABILITY_BOUND' dom, 'April 2025 24-Month Study Min/Most/Max suite' c FROM dual UNION ALL
    SELECT 2,    '24MS_2025_AUG_SUITE',         1,    'PROBABILITY_BOUND',     'August 2025 AOP 24-Month Study suite' FROM dual UNION ALL
    SELECT 3,    'CRSS_2025_STRESS_TEST_ISM',   1,    'HISTORICAL_YEAR',       'CRSS Stress Test 1988-2021 ISM hydrology ensemble' FROM dual UNION ALL
    SELECT 4,    'MTOM_2025_MAY_ESP_ENSEMBLE',  1,    'ESP_YEAR',              'MTOM May 2025 5-year probabilistic ESP ensemble' FROM dual UNION ALL
    SELECT 5,    'CBRFC_2025_APR_FORECAST',     3,    'EXCEEDANCE_PCT',        'CBRFC April 1 Water Supply Forecast quantiles' FROM dual
  ) LOOP
    MERGE INTO ref_ensemble t USING (SELECT r.id id FROM dual) s ON (t.ensemble_id = s.id)
    WHEN NOT MATCHED THEN INSERT (ensemble_id, ensemble_name, agen_id, trace_domain, cmmnt)
    VALUES (r.id, r.nm, r.ag, r.dom, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 eid, 'PUBLISH_DATE' k, '2025-04-15' v FROM dual UNION ALL
    SELECT 1,     'MODEL_NAME',     '24-Month Study' FROM dual UNION ALL
    SELECT 2,     'PUBLISH_DATE',   '2025-08-15' FROM dual UNION ALL
    SELECT 2,     'TIER_BASIS',     'WY2026'     FROM dual UNION ALL
    SELECT 3,     'HYDROLOGY_SET',  'STRESS_TEST_1988_2021' FROM dual UNION ALL
    SELECT 3,     'EIS_PHASE',      'DRAFT_2025' FROM dual UNION ALL
    SELECT 4,     'FORECAST_MONTH', 'MAY_2025'   FROM dual UNION ALL
    SELECT 4,     'HORIZON_YEARS',  '5'          FROM dual UNION ALL
    SELECT 5,     'FORECAST_CENTER','CBRFC'      FROM dual UNION ALL
    SELECT 5,     'SEASON_WINDOW',  'APR_JUL'    FROM dual
  ) LOOP
    MERGE INTO ref_ensemble_keyval t USING (SELECT r.eid eid, r.k k FROM dual) s
    ON (t.ensemble_id = s.eid AND t.key_name = s.k)
    WHEN NOT MATCHED THEN INSERT (ensemble_id, key_name, key_value, date_time_loaded)
    VALUES (r.eid, r.k, r.v, SYSDATE);
  END LOOP;

  add_trace(1, 1, 10,   'Min Probable',  '24MS_2025_APR_MIN');
  add_trace(1, 2, 50,   'Most Probable', '24MS_2025_APR_MOST');
  add_trace(1, 3, 90,   'Max Probable',  '24MS_2025_APR_MAX');
  add_trace(2, 1, 10,   'Min Probable',  '24MS_2025_AUG_MIN');
  add_trace(2, 2, 50,   'Most Probable', '24MS_2025_AUG_MOST');
  add_trace(2, 3, 90,   'Max Probable',  '24MS_2025_AUG_MAX');
  add_trace(3, 1, 1988, 'ISM_1988',      'CRSS_2025_ST_T01');
  add_trace(3, 2, 2000, 'ISM_2000',      'CRSS_2025_ST_T02');
  add_trace(3, 3, 2011, 'ISM_2011',      'CRSS_2025_ST_T03');
  add_trace(3, 4, 2021, 'ISM_2021',      'CRSS_2025_ST_T04');
  add_trace(4, 1, 1991, 'ESP_1991',      'MTOM_2025_MAY_T10');
  add_trace(4, 2, 1997, 'ESP_1997',      'MTOM_2025_MAY_T20');
  add_trace(4, 3, 2002, 'ESP_2002',      'MTOM_2025_MAY_T30');
  add_trace(4, 4, 2019, 'ESP_2019',      'MTOM_2025_MAY_T40');
  add_trace(5, 1, 10,   'P10_Wet',       'ESP_2025_APR_P10');
  add_trace(5, 2, 50,   'P50_Median',    'ESP_2025_APR_P50');
  add_trace(5, 3, 90,   'P90_Dry',       'ESP_2025_APR_P90');

  -- ---------------------------------------------------------------------------
  -- 3. TSDB Groups (TSDB_GROUP & TSDB_GROUP_MEMBER_*)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'All_Colorado_Reservoirs' nm, 'basin' tp,    'All 10 CRSP & Lower Basin reservoirs' d FROM dual UNION ALL
    SELECT 2,    'Upper_Basin_Reservoirs',     'basin',       'CRSP reservoirs above Lees Ferry' FROM dual UNION ALL
    SELECT 3,    'Lower_Basin_Reservoirs',     'basin',       'Mead, Mohave, and Havasu reservoirs' FROM dual UNION ALL
    SELECT 4,    'Aspinall_Unit_Cascade',      'project',     'Blue Mesa, Morrow Point, and Crystal cascade' FROM dual UNION ALL
    SELECT 5,    'Powell_Inflow_Gages',        'hydrologic',  'Cisco, Green River UT, and Bluff inflow gages' FROM dual UNION ALL
    SELECT 6,    'Mainstem_Streamgages',       'hydrologic',  'Key mainstem and tributary USGS gages' FROM dual UNION ALL
    SELECT 7,    'Lower_Basin_Diversions',     'delivery',    'All-American Canal, CAP, and CRA diversions' FROM dual UNION ALL
    SELECT 8,    'Hydropower_Facilities',      'power',       'Glen Canyon and Hoover powerplants' FROM dual UNION ALL
    SELECT 9,    'SNOTEL_Index_Stations',      'climate',     'High-elevation snowpack index SNOTEL sites' FROM dual UNION ALL
    SELECT 10,   'Daily_CP_Rollup_Series',     'computation', 'Active daily aggregation time-series group' FROM dual
  ) LOOP
    MERGE INTO tsdb_group t USING (SELECT r.id id FROM dual) s ON (t.group_id = s.id)
    WHEN NOT MATCHED THEN INSERT (group_id, group_name, group_type, group_description, db_office_code)
    VALUES (r.id, r.nm, r.tp, r.d, 1);
  END LOOP;

  -- Hierarchical group membership (parent -> child)
  FOR r IN (
    SELECT 1 p, 2 c, 'A' inc FROM dual UNION ALL
    SELECT 1,   3,   'A'     FROM dual UNION ALL
    SELECT 2,   4,   'A'     FROM dual UNION ALL
    SELECT 6,   5,   'A'     FROM dual
  ) LOOP
    MERGE INTO tsdb_group_member_group t USING (SELECT r.p p, r.c c FROM dual) s
    ON (t.parent_group_id = s.p AND t.child_group_id = s.c)
    WHEN NOT MATCHED THEN INSERT (parent_group_id, child_group_id, include_group)
    VALUES (r.p, r.c, r.inc);
  END LOOP;

  -- Group member sites
  FOR r IN (
    SELECT 2 g, 1011 sid FROM dual UNION ALL SELECT 2, 1013 FROM dual UNION ALL
    SELECT 2,   1014     FROM dual UNION ALL SELECT 2, 1015 FROM dual UNION ALL
    SELECT 2,   1016     FROM dual UNION ALL SELECT 2, 1017 FROM dual UNION ALL
    SELECT 2,   1018     FROM dual UNION ALL
    SELECT 3,   1012     FROM dual UNION ALL SELECT 3, 1019 FROM dual UNION ALL SELECT 3, 1020 FROM dual UNION ALL
    SELECT 4,   1014     FROM dual UNION ALL SELECT 4, 1015 FROM dual UNION ALL SELECT 4, 1016 FROM dual UNION ALL
    SELECT 5,   1022     FROM dual UNION ALL SELECT 5, 1023 FROM dual UNION ALL SELECT 5, 1024 FROM dual UNION ALL
    SELECT 6,   1021     FROM dual UNION ALL SELECT 6, 1025 FROM dual UNION ALL SELECT 6, 1027 FROM dual UNION ALL
    SELECT 6,   1028     FROM dual UNION ALL SELECT 6, 1031 FROM dual UNION ALL SELECT 6, 1032 FROM dual UNION ALL
    SELECT 7,   1033     FROM dual UNION ALL SELECT 7, 1034 FROM dual UNION ALL SELECT 7, 1035 FROM dual UNION ALL
    SELECT 8,   1039     FROM dual UNION ALL SELECT 8, 1040 FROM dual UNION ALL
    SELECT 9,   1041     FROM dual UNION ALL SELECT 9, 1042 FROM dual
  ) LOOP
    MERGE INTO tsdb_group_member_site t USING (SELECT r.g g, r.sid sid FROM dual) s
    ON (t.group_id = s.g AND t.site_id = s.sid)
    WHEN NOT MATCHED THEN INSERT (group_id, site_id) VALUES (r.g, r.sid);
  END LOOP;

  -- Group member datatypes
  FOR r IN (
    SELECT 1 g, 1 dt FROM dual UNION ALL SELECT 1, 4 FROM dual UNION ALL
    SELECT 1,   7    FROM dual UNION ALL SELECT 1, 9 FROM dual UNION ALL
    SELECT 5,   13   FROM dual UNION ALL SELECT 5, 3 FROM dual UNION ALL
    SELECT 6,   13   FROM dual UNION ALL SELECT 6, 27 FROM dual UNION ALL
    SELECT 7,   14   FROM dual UNION ALL SELECT 7, 17 FROM dual UNION ALL
    SELECT 8,   21   FROM dual UNION ALL SELECT 8, 22 FROM dual UNION ALL
    SELECT 9,   25   FROM dual UNION ALL SELECT 9, 24 FROM dual
  ) LOOP
    MERGE INTO tsdb_group_member_dt t USING (SELECT r.g g, r.dt dt FROM dual) s
    ON (t.group_id = s.g AND t.data_type_id = s.dt)
    WHEN NOT MATCHED THEN INSERT (group_id, data_type_id) VALUES (r.g, r.dt);
  END LOOP;

  -- Group member other (interval/table_selector filters)
  FOR r IN (
    SELECT 1 g,  'Interval' mt,      'day' mv   FROM dual UNION ALL
    SELECT 1,    'TableSelector',    'R_'       FROM dual UNION ALL
    SELECT 5,    'Interval',         'day'      FROM dual UNION ALL
    SELECT 6,    'Interval',         'hour'     FROM dual UNION ALL
    SELECT 7,    'Interval',         'day'      FROM dual UNION ALL
    SELECT 8,    'Interval',         'hour'     FROM dual UNION ALL
    SELECT 9,    'Interval',         'day'      FROM dual UNION ALL
    SELECT 10,   'Interval',         'day'      FROM dual UNION ALL
    SELECT 10,   'TableSelector',    'R_'       FROM dual
  ) LOOP
    MERGE INTO tsdb_group_member_other t USING (SELECT r.g g, r.mt mt, r.mv mv FROM dual) s
    ON (t.group_id = s.g AND t.member_type = s.mt AND t.member_value = s.mv)
    WHEN NOT MATCHED THEN INSERT (group_id, member_type, member_value) VALUES (r.g, r.mt, r.mv);
  END LOOP;

  -- Advance TSDB_GROUPIDSEQ past max seeded group_id
  LOOP
    SELECT tsdb_groupidseq.NEXTVAL INTO v_seq_val FROM dual;
    EXIT WHEN v_seq_val >= 50;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 4. Computation Processor Algorithms (CP_ALGORITHM, _PROPERTY, _TS_PARM, _SCRIPT)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id,  'NoComputation' nm,        'decodes.tsdb.algo.NoOpAlgorithm' cls,            'Placeholder algorithm for raw non-computed loads' c FROM dual UNION ALL
    SELECT 2,     'AverageAlgorithm',        'decodes.tsdb.algo.AverageAlgorithm',             'Averages single input series over output interval' FROM dual UNION ALL
    SELECT 3,     'SumOverTimeAlgorithm',    'decodes.tsdb.algo.SumOverTimeAlgorithm',         'Sums input values across output period' FROM dual UNION ALL
    SELECT 4,     'CopyAlgorithm',           'decodes.tsdb.algo.CopyAlgorithm',                'Copies input to output with optional multiplier/offset' FROM dual UNION ALL
    SELECT 5,     'SubSample',               'decodes.tsdb.algo.SubSample',                    'Extracts end-of-period or sampled value for coarser interval' FROM dual UNION ALL
    SELECT 6,     'DisAggregate',            'decodes.tsdb.algo.DisAggregate',                 'Spreads coarser interval values into finer intervals' FROM dual UNION ALL
    SELECT 7,     'HdbRating',               'decodes.hdb.algo.HdbRating',                     'Looks up dependent value from REF_SITE_RATING table' FROM dual UNION ALL
    SELECT 8,     'FlowResIn',               'decodes.hdb.algo.FlowResIn',                     'Computes reservoir inflow from release, storage change, and evap' FROM dual UNION ALL
    SELECT 9,     'BigAdder',                'decodes.tsdb.algo.BigAdder',                     'Sums up to 20 weighted input time series' FROM dual UNION ALL
    SELECT 10,    'AddToPrevious',           'decodes.tsdb.algo.AddToPrevious',                'Cumulative running sum over contiguous time steps' FROM dual UNION ALL
    SELECT 11,    'PythonAlgorithm',         'decodes.tsdb.algo.PythonAlgorithm',              'Custom Jython scripted hydrological calculation' FROM dual UNION ALL
    SELECT 12,    'ScalerAdder',             'decodes.tsdb.algo.ScalerAdder',                  'Linear combination a*x + b*y + c' FROM dual
  ) LOOP
    MERGE INTO cp_algorithm t USING (SELECT r.id id FROM dual) s ON (t.algorithm_id = s.id)
    WHEN NOT MATCHED THEN INSERT (algorithm_id, algorithm_name, exec_class, cmmnt, db_office_code)
    VALUES (r.id, r.nm, r.cls, r.c, 1);
  END LOOP;

  FOR r IN (
    SELECT 2 aid, 'minSamplesNeeded' k, '1' v FROM dual UNION ALL
    SELECT 2,     'input_MISSING',      'IGNORE' FROM dual UNION ALL
    SELECT 3,     'minSamplesNeeded',   '1' FROM dual UNION ALL
    SELECT 4,     'multiplier',         '1.0' FROM dual UNION ALL
    SELECT 4,     'offset',             '0.0' FROM dual UNION ALL
    SELECT 4,     'input_MISSING',      'IGNORE' FROM dual UNION ALL
    SELECT 5,     'method',             'EOP' FROM dual UNION ALL
    SELECT 6,     'method',             'SPLIT' FROM dual UNION ALL
    SELECT 7,     'ratingType',         'Elev-Storage' FROM dual UNION ALL
    SELECT 7,     'exceedLowerBound',   'false' FROM dual UNION ALL
    SELECT 7,     'exceedUpperBound',   'false' FROM dual UNION ALL
    SELECT 8,     'doSetOutputFlags',   'true' FROM dual UNION ALL
    SELECT 8,     'evap_MISSING',       'IGNORE' FROM dual UNION ALL
    SELECT 9,     'coeff1',             '1.0' FROM dual UNION ALL
    SELECT 9,     'coeff2',             '1.0' FROM dual UNION ALL
    SELECT 9,     'coeff3',             '1.0' FROM dual UNION ALL
    SELECT 11,    'scriptLang',         'python' FROM dual UNION ALL
    SELECT 12,    'coeff1',             '1.0' FROM dual UNION ALL
    SELECT 12,    'coeff2',             '-1.0' FROM dual
  ) LOOP
    MERGE INTO cp_algo_property t USING (SELECT r.aid aid, r.k k FROM dual) s
    ON (t.algorithm_id = s.aid AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (algorithm_id, prop_name, prop_value) VALUES (r.aid, r.k, r.v);
  END LOOP;

  FOR r IN (
    SELECT 2 aid,  'input' rl,    'i' pt FROM dual UNION ALL SELECT 2,  'average',  'o' FROM dual UNION ALL
    SELECT 3,      'input',       'i'    FROM dual UNION ALL SELECT 3,  'sum',      'o' FROM dual UNION ALL
    SELECT 4,      'input',       'i'    FROM dual UNION ALL SELECT 4,  'output',   'o' FROM dual UNION ALL
    SELECT 5,      'input',       'i'    FROM dual UNION ALL SELECT 5,  'output',   'o' FROM dual UNION ALL
    SELECT 6,      'input',       'i'    FROM dual UNION ALL SELECT 6,  'output',   'o' FROM dual UNION ALL
    SELECT 7,      'indep',       'i'    FROM dual UNION ALL SELECT 7,  'dep',      'o' FROM dual UNION ALL
    SELECT 8,      'totalRelease','i'    FROM dual UNION ALL SELECT 8,  'storage',  'i' FROM dual UNION ALL
    SELECT 8,      'evap',        'i'    FROM dual UNION ALL SELECT 8,  'inflow',   'o' FROM dual UNION ALL
    SELECT 9,      'input1',      'i'    FROM dual UNION ALL SELECT 9,  'input2',   'i' FROM dual UNION ALL
    SELECT 9,      'input3',      'i'    FROM dual UNION ALL SELECT 9,  'output',   'o' FROM dual UNION ALL
    SELECT 10,     'input',       'i'    FROM dual UNION ALL SELECT 10, 'output',   'o' FROM dual UNION ALL
    SELECT 11,     'input1',      'i'    FROM dual UNION ALL SELECT 11, 'input2',   'i' FROM dual UNION ALL
    SELECT 11,     'output',      'o'    FROM dual UNION ALL
    SELECT 12,     'input1',      'i'    FROM dual UNION ALL SELECT 12, 'input2',   'i' FROM dual UNION ALL
    SELECT 12,     'output',      'o'    FROM dual
  ) LOOP
    MERGE INTO cp_algo_ts_parm t USING (SELECT r.aid aid, r.rl rl FROM dual) s
    ON (t.algorithm_id = s.aid AND t.algo_role_name = s.rl)
    WHEN NOT MATCHED THEN INSERT (algorithm_id, algo_role_name, parm_type) VALUES (r.aid, r.rl, r.pt);
  END LOOP;

  -- Sample script blocks for PythonAlgorithm (algorithm_id = 11)
  FOR r IN (
    SELECT 11 aid, 'I' st, 1 bn, 'cfs_to_af_day = 1.983471' txt FROM dual UNION ALL
    SELECT 11,     'T',    1,    'if isPresent("input1") and isPresent("input2"): setOutput("output", input1 - input2)' FROM dual UNION ALL
    SELECT 11,     'A',    1,    'debug("Completed head differential computation")' FROM dual
  ) LOOP
    MERGE INTO cp_algo_script t USING (SELECT r.aid aid, r.st st, r.bn bn FROM dual) s
    ON (t.algorithm_id = s.aid AND t.script_type = s.st AND t.block_num = s.bn)
    WHEN NOT MATCHED THEN INSERT (algorithm_id, script_type, block_num, script_data)
    VALUES (r.aid, r.st, r.bn, r.txt);
  END LOOP;

  -- Advance CP_ALGORITHMIDSEQ past max seeded algorithm_id
  LOOP
    SELECT cp_algorithmidseq.NEXTVAL INTO v_seq_val FROM dual;
    EXIT WHEN v_seq_val >= 100;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 5. Computations (CP_COMPUTATION, _PROPERTY, _TS_PARM)
  --    COMPUTATION_ID = 0 is the standard non-computed raw-load sentinel used by R_BASE.
  --    101..120 include active ('Y') and inactive/historical ('N') hydrological workflows.
  -- ---------------------------------------------------------------------------
  add_comp(0,   'No Computation (Raw Load)',          1,  'Sentinel computation ID for raw direct observations in R_BASE', 1, 'N', DATE '1900-01-01', NULL, NULL);
  add_comp(101, 'Powell_Elev_to_Storage_Day',         7,  'Compute Lake Powell daily storage from EOP pool elevation via Elev-Storage rating', 2, 'Y', DATE '2022-10-01', NULL, NULL);
  add_comp(102, 'Mead_Elev_to_Storage_Day',           7,  'Compute Lake Mead daily storage from EOP pool elevation via Elev-Storage rating',   2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(103, 'FlamingGorge_Elev_to_Storage_Day',   7,  'Compute Flaming Gorge daily storage from pool elevation',                           2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(104, 'BlueMesa_Elev_to_Storage_Day',       7,  'Compute Blue Mesa daily storage from pool elevation',                               2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(105, 'Navajo_Elev_to_Storage_Day',         7,  'Compute Navajo Reservoir daily storage from pool elevation',                        2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(106, 'LeesFerry_Stage_to_Discharge_Hr',    7,  'Compute Lees Ferry hourly discharge from stage via USGS rating #24',                2, 'Y', DATE '2023-10-01', NULL, NULL);
  add_comp(107, 'LeesFerry_Discharge_Hr_to_Day',      2,  'Aggregate Lees Ferry hourly discharge to daily mean discharge',                     2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(108, 'Powell_Release_Hr_to_Day',           2,  'Aggregate Glen Canyon hourly release to daily mean release',                        2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(109, 'Powell_Inflow_MassBalance_Day',      8,  'Compute Lake Powell daily inflow from release + storage change + evap',             2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(110, 'Powell_Gaged_Tribs_Sum_Day',         9,  'Sum Cisco + Green River UT + Bluff daily inflow to Lake Powell',                    2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(111, 'Powell_Release_Day_to_Month',        2,  'Aggregate Lake Powell daily release to monthly mean release',                       2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(112, 'Mead_Release_Day_to_Month',          2,  'Aggregate Lake Mead daily release to monthly mean release',                         2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(113, 'Powell_Release_cfs_to_Vol_Day',      4,  'Convert Lake Powell daily release (cfs) to daily release volume (ac-ft)',           2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(114, 'Mead_Release_cfs_to_Vol_Day',        4,  'Convert Lake Mead daily release (cfs) to daily release volume (ac-ft)',             2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(115, 'GlenCanyon_Head_Calc_Day',           11, 'Compute Glen Canyon gross head = forebay elevation - tailwater elevation',          2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(116, 'Hoover_Head_Calc_Day',               11, 'Compute Hoover Dam gross head = forebay elevation - tailwater elevation',           2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(117, 'GlenCanyon_Power_to_Energy_Day',     4,  'Convert daily mean MW to daily MWh energy (x24)',                                   2, 'Y', DATE '2020-01-01', NULL, NULL);
  add_comp(118, 'LowerBasin_Diversion_Total_Day',     9,  'Sum All-American Canal + CAP + CRA daily diversions',                               2, 'Y', DATE '2020-01-01', NULL, 7);
  add_comp(119, 'Powell_Elev_to_Storage_Legacy2010',  7,  'Retired 1986 bathymetry rating computation (superseded Oct 2022)',                  2, 'N', DATE '2010-01-01', DATE '2022-09-30', NULL);
  add_comp(120, 'CRSS_Powell_Month_to_WY_Avg',        2,  'Aggregate CRSS modeled monthly Lake Powell elevation to water year average',        2, 'Y', DATE '2025-01-01', NULL, 2);

  -- CP_COMP_PROPERTY
  FOR r IN (
    SELECT 101 cid, 'ratingType' k,    'Elev-Storage' v FROM dual UNION ALL
    SELECT 102,     'ratingType',      'Elev-Storage' FROM dual UNION ALL
    SELECT 103,     'ratingType',      'Elev-Storage' FROM dual UNION ALL
    SELECT 104,     'ratingType',      'Elev-Storage' FROM dual UNION ALL
    SELECT 105,     'ratingType',      'Elev-Storage' FROM dual UNION ALL
    SELECT 106,     'ratingType',      'Stage-Discharge' FROM dual UNION ALL
    SELECT 107,     'minSamplesNeeded','20'           FROM dual UNION ALL
    SELECT 108,     'minSamplesNeeded','20'           FROM dual UNION ALL
    SELECT 111,     'minSamplesNeeded','28'           FROM dual UNION ALL
    SELECT 112,     'minSamplesNeeded','28'           FROM dual UNION ALL
    SELECT 113,     'multiplier',      '1.983471'     FROM dual UNION ALL
    SELECT 114,     'multiplier',      '1.983471'     FROM dual UNION ALL
    SELECT 117,     'multiplier',      '24.0'         FROM dual UNION ALL
    SELECT 119,     'ratingType',      'Elev-Storage' FROM dual UNION ALL
    SELECT 119,     'retiredReason',   'Superseded by 2022 bathymetric survey' FROM dual UNION ALL
    SELECT 120,     'minSamplesNeeded','12'           FROM dual
  ) LOOP
    MERGE INTO cp_comp_property t USING (SELECT r.cid cid, r.k k FROM dual) s
    ON (t.computation_id = s.cid AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (computation_id, prop_name, prop_value) VALUES (r.cid, r.k, r.v);
  END LOOP;

  -- CP_COMP_TS_PARM (linking computations to input/output SDIs, intervals, and table selectors)
  add_comp_parm(101, 'indep',        2001, 'day',   'R_', 0, NULL, 1,  NULL, 1011);
  add_comp_parm(101, 'dep',          2002, 'day',   'R_', 0, NULL, 4,  NULL, 1011);
  add_comp_parm(102, 'indep',        2015, 'day',   'R_', 0, NULL, 1,  NULL, 1012);
  add_comp_parm(102, 'dep',          2016, 'day',   'R_', 0, NULL, 4,  NULL, 1012);
  add_comp_parm(103, 'indep',        2025, 'day',   'R_', 0, NULL, 1,  NULL, 1013);
  add_comp_parm(103, 'dep',          2026, 'day',   'R_', 0, NULL, 4,  NULL, 1013);
  add_comp_parm(104, 'indep',        2032, 'day',   'R_', 0, NULL, 1,  NULL, 1014);
  add_comp_parm(104, 'dep',          2033, 'day',   'R_', 0, NULL, 4,  NULL, 1014);
  add_comp_parm(105, 'indep',        2046, 'day',   'R_', 0, NULL, 1,  NULL, 1017);
  add_comp_parm(105, 'dep',          2047, 'day',   'R_', 0, NULL, 4,  NULL, 1017);
  add_comp_parm(106, 'indep',        2064, 'hour',  'R_', 0, NULL, 3,  NULL, 1021);
  add_comp_parm(106, 'dep',          2063, 'hour',  'R_', 0, NULL, 13, NULL, 1021);
  add_comp_parm(107, 'input',        2063, 'hour',  'R_', 0, NULL, 13, NULL, 1021);
  add_comp_parm(107, 'average',      2063, 'day',   'R_', 0, NULL, 13, NULL, 1021);
  add_comp_parm(108, 'input',        2005, 'hour',  'R_', 0, NULL, 9,  NULL, 1011);
  add_comp_parm(108, 'average',      2005, 'day',   'R_', 0, NULL, 9,  NULL, 1011);
  add_comp_parm(109, 'totalRelease', 2005, 'day',   'R_', 0, NULL, 9,  NULL, 1011);
  add_comp_parm(109, 'storage',      2002, 'day',   'R_', 0, NULL, 4,  NULL, 1011);
  add_comp_parm(109, 'evap',         2009, 'day',   'R_', 0, NULL, 18, NULL, 1011);
  add_comp_parm(109, 'inflow',       2003, 'day',   'R_', 0, NULL, 7,  NULL, 1011);
  add_comp_parm(110, 'input1',       2069, 'day',   'R_', 0, NULL, 13, NULL, 1022);
  add_comp_parm(110, 'input2',       2073, 'day',   'R_', 0, NULL, 13, NULL, 1023);
  add_comp_parm(110, 'input3',       2076, 'day',   'R_', 0, NULL, 13, NULL, 1024);
  add_comp_parm(110, 'output',       2003, 'day',   'R_', 0, NULL, 7,  NULL, 1011);
  add_comp_parm(111, 'input',        2005, 'day',   'R_', 0, NULL, 9,  NULL, 1011);
  add_comp_parm(111, 'average',      2005, 'month', 'R_', 0, NULL, 9,  NULL, 1011);
  add_comp_parm(112, 'input',        2018, 'day',   'R_', 0, NULL, 9,  NULL, 1012);
  add_comp_parm(112, 'average',      2018, 'month', 'R_', 0, NULL, 9,  NULL, 1012);
  add_comp_parm(113, 'input',        2005, 'day',   'R_', 0, NULL, 9,  NULL, 1011);
  add_comp_parm(113, 'output',       2014, 'day',   'R_', 0, NULL, 16, NULL, 1011);
  add_comp_parm(114, 'input',        2018, 'day',   'R_', 0, NULL, 9,  NULL, 1012);
  add_comp_parm(114, 'output',       2024, 'day',   'R_', 0, NULL, 16, NULL, 1012);
  add_comp_parm(115, 'input1',       2001, 'day',   'R_', 0, NULL, 1,  NULL, 1011);
  add_comp_parm(115, 'input2',       2011, 'day',   'R_', 0, NULL, 2,  NULL, 1011);
  add_comp_parm(115, 'output',       2102, 'day',   'R_', 0, NULL, 23, NULL, 1039);
  add_comp_parm(116, 'input1',       2015, 'day',   'R_', 0, NULL, 1,  NULL, 1012);
  add_comp_parm(116, 'input2',       2022, 'day',   'R_', 0, NULL, 2,  NULL, 1012);
  add_comp_parm(116, 'output',       2105, 'day',   'R_', 0, NULL, 23, NULL, 1040);
  add_comp_parm(117, 'input',        2100, 'day',   'R_', 0, NULL, 21, NULL, 1039);
  add_comp_parm(117, 'output',       2101, 'day',   'R_', 0, NULL, 22, NULL, 1039);
  add_comp_parm(118, 'input1',       2091, 'day',   'R_', 0, NULL, 14, NULL, 1033);
  add_comp_parm(118, 'input2',       2093, 'day',   'R_', 0, NULL, 14, NULL, 1034);
  add_comp_parm(118, 'input3',       2095, 'day',   'R_', 0, NULL, 14, NULL, 1035);
  add_comp_parm(118, 'output',       2089, 'day',   'R_', 0, NULL, 13, NULL, 1032);
  add_comp_parm(119, 'indep',        2001, 'day',   'R_', 0, NULL, 1,  NULL, 1011);
  add_comp_parm(119, 'dep',          2002, 'day',   'R_', 0, NULL, 4,  NULL, 1011);
  add_comp_parm(120, 'input',        2001, 'month', 'M_', 0, 1,    1,  NULL, 1011);
  add_comp_parm(120, 'average',      2001, 'wy',    'M_', 0, 1,    1,  NULL, 1011);

  -- Advance CP_COMPUTATIONIDSEQ past max seeded computation_id
  LOOP
    SELECT cp_computationidseq.NEXTVAL INTO v_seq_val FROM dual;
    EXIT WHEN v_seq_val >= 200;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 6. Register CP_TS_ID & CP_COMP_DEPENDS using native CP_PROCESSOR package
  -- ---------------------------------------------------------------------------
  -- Native procedure registers all active non-group computation inputs into CP_TS_ID & CP_COMP_DEPENDS
  CP_PROCESSOR.PRE_POPULATE_COMP_DEPENDS;

  -- Also register additional key real & modeled time-series IDs for alarms and TSDB_GROUP_MEMBER_TS
  FOR r IN (
    SELECT 2001 sdi, 'hour' iv,  'R_' ts, -1 mid FROM dual UNION ALL
    SELECT 2001,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2001,     'month',    'R_',    -1     FROM dual UNION ALL
    SELECT 2002,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2003,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2005,     'hour',     'R_',    -1     FROM dual UNION ALL
    SELECT 2005,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2015,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2016,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2018,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2025,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2032,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2046,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2063,     'instant',  'R_',    -1     FROM dual UNION ALL
    SELECT 2063,     'hour',     'R_',    -1     FROM dual UNION ALL
    SELECT 2063,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2065,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2069,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2073,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2076,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2093,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2100,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2103,     'day',      'R_',    -1     FROM dual UNION ALL
    SELECT 2106,     'day',      'R_',    -1     FROM dual UNION ALL
    -- Modeled time series IDs (model_id >= 1)
    SELECT 2001,     'month',    'M_',    1      FROM dual UNION ALL
    SELECT 2001,     'month',    'M_',    3      FROM dual UNION ALL
    SELECT 2002,     'month',    'M_',    3      FROM dual UNION ALL
    SELECT 2015,     'month',    'M_',    3      FROM dual UNION ALL
    SELECT 2016,     'month',    'M_',    3      FROM dual UNION ALL
    SELECT 2005,     'hour',     'M_',    6      FROM dual UNION ALL
    SELECT 2005,     'day',      'M_',    5      FROM dual
  ) LOOP
    CP_PROCESSOR.CREATE_TS_ID(r.sdi, r.iv, r.ts, r.mid, v_ts_id);
    IF r.ts = 'R_' AND r.iv = 'day' THEN
      MERGE INTO tsdb_group_member_ts t USING (SELECT 10 gid, v_ts_id tid FROM dual) s
      ON (t.group_id = s.gid AND t.ts_id = s.tid)
      WHEN NOT MATCHED THEN INSERT (group_id, ts_id) VALUES (10, v_ts_id);
    END IF;
  END LOOP;

  -- Ensure group-based computation 118 dependencies are registered too
  FOR r IN (SELECT ts_id FROM cp_ts_id WHERE site_datatype_id IN (2091, 2093, 2095) AND interval = 'day' AND table_selector = 'R_') LOOP
    CP_PROCESSOR.POPULATE_CP_COMP_DEPENDS(r.ts_id, 118);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 7. Process Locks (CP_COMP_PROC_LOCK) & Historic Computations (CP_HISTORIC_COMPUTATIONS)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 app, 41201 pid, 'uchdb-decodes-01.usbr.test' hst, 'Running - 24 platforms active' st FROM dual UNION ALL
    SELECT 2,     41245,     'uchdb-cp-01.usbr.test',          'Idle - Polling tasklist'       FROM dual UNION ALL
    SELECT 8,     41310,     'uchdb-alarm-01.usbr.test',       'Active - 20 screenings loaded' FROM dual UNION ALL
    SELECT 9,     41388,     'uchdb-scada-01.usbr.test',       'Connected - 5 min cycle'       FROM dual
  ) LOOP
    MERGE INTO cp_comp_proc_lock t USING (SELECT r.app app FROM dual) s ON (t.loading_application_id = s.app)
    WHEN NOT MATCHED THEN INSERT (loading_application_id, pid, hostname, heartbeat, cur_status)
    VALUES (r.app, r.pid, r.hst, SYSDATE - 1/1440, r.st);
  END LOOP;

  v_mri_val := v_mri('24MS_2025_AUG_MOST');
  FOR r IN (
    SELECT 2 app, 2001 sdi, 'day' iv,   DATE '2025-09-01' sd, DATE '2025-09-30' ed, 'R_' ts, 0 mri,         'N' rfd FROM dual UNION ALL
    SELECT 2,     2005,     'day',      DATE '2025-09-01',    DATE '2025-09-30',    'R_',    0,             'N'     FROM dual UNION ALL
    SELECT 2,     2015,     'day',      DATE '2025-09-01',    DATE '2025-09-30',    'R_',    0,             'N'     FROM dual UNION ALL
    SELECT 2,     2063,     'hour',     DATE '2025-09-25',    DATE '2025-09-30',    'R_',    0,             'N'     FROM dual UNION ALL
    SELECT 2,     2069,     'day',      DATE '2025-09-01',    DATE '2025-09-30',    'R_',    0,             'N'     FROM dual UNION ALL
    SELECT 2,     2001,     'month',    DATE '2025-08-01',    DATE '2026-07-31',    'M_',    v_mri_val,     'N'     FROM dual
  ) LOOP
    MERGE INTO cp_historic_computations t USING (
      SELECT r.app app, r.sdi sdi, r.iv iv, r.sd sd, r.ed ed FROM dual
    ) s ON (t.loading_application_id = s.app AND t.site_datatype_id = s.sdi
            AND t.interval = s.iv AND t.start_date_time = s.sd AND t.end_date_time = s.ed)
    WHEN NOT MATCHED THEN INSERT (
      loading_application_id, site_datatype_id, interval, start_date_time, end_date_time,
      table_selector, model_run_id, date_time_loaded, ready_for_delete
    ) VALUES (r.app, r.sdi, r.iv, r.sd, r.ed, r.ts, r.mri, SYSDATE, r.rfd);
  END LOOP;

  populate_pk.SET_PRE_POPULATED(1);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] Model runs, ensembles, TSDB groups, and CP metadata seeded.');
EXCEPTION
  WHEN OTHERS THEN
    populate_pk.SET_PRE_POPULATED(1);
    ROLLBACK;
    RAISE;
END;
/
