-- =============================================================================
-- 06_alarms_and_monitoring.sql
-- Populates OpenDCS/HDB Alarm subsystem tables:
--   ALARM_GROUP, EMAIL_ADDR, FILE_MONITOR, PROCESS_MONITOR, ALARM_EVENT,
--   ALARM_SCREENING, ALARM_LIMIT_SET, ALARM_CURRENT, and ALARM_HISTORY.
--
-- All timestamps use Unix epoch milliseconds (NUMBER(19,0)), matching OpenDCS.
-- All EMAIL_ADDR addresses use synthetic .test RFC-2606 domains (no real PII).
-- =============================================================================

PROMPT [06] Seeding alarm groups, monitoring rules, screenings, limits, and alarm events...

ALTER SESSION SET CURRENT_SCHEMA = HDBDBA;

DECLARE
  v_seq_val NUMBER;
  v_ts_id   NUMBER;
  c_mod_ms  CONSTANT NUMBER(19) := 1759276800000; -- 2025-10-01T00:00:00Z

  FUNCTION get_ts(p_sdi NUMBER, p_int VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    v_id := CP_PROCESSOR.GET_TS_ID(p_sdi, p_int, 'R_', -1);
    IF v_id < 0 THEN
      CP_PROCESSOR.CREATE_TS_ID(p_sdi, p_int, 'R_', -1, v_id);
    END IF;
    RETURN v_id;
  END;

BEGIN
  -- ---------------------------------------------------------------------------
  -- 1. ALARM_GROUP
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'Flood_Watch_Ops' nm    FROM dual UNION ALL
    SELECT 2,    'Dam_Safety_Monitor'    FROM dual UNION ALL
    SELECT 3,    'Hydropower_Dispatch'   FROM dual UNION ALL
    SELECT 4,    'Telemetry_Health'      FROM dual UNION ALL
    SELECT 5,    'Water_Quality_Watch'   FROM dual UNION ALL
    SELECT 6,    'CP_Daemon_Watch'       FROM dual
  ) LOOP
    MERGE INTO alarm_group t USING (SELECT r.id id FROM dual) s ON (t.alarm_group_id = s.id)
    WHEN NOT MATCHED THEN INSERT (alarm_group_id, alarm_group_name, last_modified)
    VALUES (r.id, r.nm, c_mod_ms);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 2. EMAIL_ADDR (synthetic RFC-2606 .test addresses only)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 g, 'uc-flood-duty@example.usbr.test' a FROM dual UNION ALL
    SELECT 1,   'lc-flood-duty@example.usbr.test'   FROM dual UNION ALL
    SELECT 1,   'hydro-ops-lead@example.usbr.test'  FROM dual UNION ALL
    SELECT 2,   'dam-safety-uc@example.usbr.test'   FROM dual UNION ALL
    SELECT 2,   'dam-safety-lc@example.usbr.test'   FROM dual UNION ALL
    SELECT 3,   'glen-dispatch@example.wapa.test'   FROM dual UNION ALL
    SELECT 3,   'hoover-dispatch@example.wapa.test' FROM dual UNION ALL
    SELECT 4,   'decodes-admin@example.usbr.test'   FROM dual UNION ALL
    SELECT 4,   'scada-ops@example.usbr.test'       FROM dual UNION ALL
    SELECT 5,   'wq-biologist@example.usbr.test'    FROM dual UNION ALL
    SELECT 5,   'temp-monitor@example.usgs.test'    FROM dual UNION ALL
    SELECT 6,   'cp-admin@example.usbr.test'        FROM dual
  ) LOOP
    MERGE INTO email_addr t USING (SELECT r.g g, r.a a FROM dual) s
    ON (t.alarm_group_id = s.g AND t.addr = s.a)
    WHEN NOT MATCHED THEN INSERT (alarm_group_id, addr) VALUES (r.g, r.a);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 3. FILE_MONITOR
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 4 g, '/data/hydromet/incoming/daily' p,  2 pr, 500 mf, '12 hours' ml, 'true' en FROM dual UNION ALL
    SELECT 4,   '/data/decodes/goes_spool',         1,    2000,   '30 minutes',  'true'    FROM dual UNION ALL
    SELECT 4,   '/data/usgs/nwis_drop',             2,    300,    '2 hours',     'true'    FROM dual UNION ALL
    SELECT 4,   '/data/snotel/daily_feed',          3,    100,    '26 hours',    'true'    FROM dual UNION ALL
    SELECT 6,   '/var/log/opendcs/cp_daemon.log',   2,    10,     '1 hour',      'true'    FROM dual UNION ALL
    SELECT 6,   '/data/riverware/dmi_export',       3,    50,     '7 days',      'false'   FROM dual
  ) LOOP
    MERGE INTO file_monitor t USING (SELECT r.g g, r.p p FROM dual) s
    ON (t.alarm_group_id = s.g AND t.path = s.p)
    WHEN NOT MATCHED THEN INSERT (
      alarm_group_id, path, priority, max_files, max_files_hint,
      max_lmt, max_lmt_hint, alarm_on_delete, max_size, alarm_on_exists, enabled
    ) VALUES (
      r.g, r.p, r.pr, r.mf, 'Backlog exceeded in ' || r.p,
      r.ml, 'No fresh telemetry files within ' || r.ml, 'true', 104857600, 'false', r.en
    );
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 4. PROCESS_MONITOR & ALARM_EVENT
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 4 g, 1 app, 'true' en FROM dual UNION ALL
    SELECT 4,   4,     'true'    FROM dual UNION ALL
    SELECT 4,   5,     'true'    FROM dual UNION ALL
    SELECT 4,   7,     'true'    FROM dual UNION ALL
    SELECT 4,   9,     'true'    FROM dual UNION ALL
    SELECT 6,   2,     'true'    FROM dual UNION ALL
    SELECT 6,   6,     'false'   FROM dual UNION ALL
    SELECT 6,   8,     'true'    FROM dual
  ) LOOP
    MERGE INTO process_monitor t USING (SELECT r.g g, r.app app FROM dual) s
    ON (t.alarm_group_id = s.g AND t.loading_application_id = s.app)
    WHEN NOT MATCHED THEN INSERT (alarm_group_id, loading_application_id, enabled)
    VALUES (r.g, r.app, r.en);
  END LOOP;

  FOR r IN (
    SELECT 1 id,  4 g, 1 app, 1 pr, '.*LRGS connection lost.*' pat FROM dual UNION ALL
    SELECT 2,     4,   1,     2,    '.*Failed to decode GOES message.*' FROM dual UNION ALL
    SELECT 3,     4,   4,     2,    '.*USGS NWIS HTTP 5[0-9][0-9].*' FROM dual UNION ALL
    SELECT 4,     4,   5,     3,    '.*SNOTEL station timeout.*' FROM dual UNION ALL
    SELECT 5,     4,   7,     2,    '.*Hydromet archive checksum mismatch.*' FROM dual UNION ALL
    SELECT 6,     4,   9,     1,    '.*SCADA bridge heartbeat stale.*' FROM dual UNION ALL
    SELECT 7,     6,   2,     1,    '.*CP_DAEMON ORA-0.*' FROM dual UNION ALL
    SELECT 8,     6,   2,     2,    '.*Computation tasklist backlog > 5000.*' FROM dual UNION ALL
    SELECT 9,     6,   8,     2,    '.*Alarm screening evaluation exception.*' FROM dual UNION ALL
    SELECT 10,    6,   6,     3,    '.*RiverWare DMI export warning.*' FROM dual
  ) LOOP
    MERGE INTO alarm_event t USING (SELECT r.id id FROM dual) s ON (t.alarm_event_id = s.id)
    WHEN NOT MATCHED THEN INSERT (alarm_event_id, alarm_group_id, loading_application_id, priority, pattern)
    VALUES (r.id, r.g, r.app, r.pr, r.pat);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 5. ALARM_SCREENING (18 screenings across major sites/datatypes)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id,  'Powell_Pool_Elev_Scr' nm,     1011 sid, 1 dt,  'true' en, 2 ag, 'Monitor Lake Powell minimum power pool & full pool limits' d, 8 app FROM dual UNION ALL
    SELECT 2,     'Powell_Release_Scr',          1011,     9,     'true',    1,    'Monitor Glen Canyon total release & ramping bounds',          8 FROM dual UNION ALL
    SELECT 3,     'Powell_Inflow_Scr',           1011,     7,     'true',    1,    'Monitor Lake Powell high spring inflow watch',                8 FROM dual UNION ALL
    SELECT 4,     'Mead_Pool_Elev_Scr',          1012,     1,     'true',    2,    'Monitor Lake Mead shortage tier & dead pool elevations',      8 FROM dual UNION ALL
    SELECT 5,     'Mead_Release_Scr',            1012,     9,     'true',    1,    'Monitor Hoover Dam release operational thresholds',           8 FROM dual UNION ALL
    SELECT 6,     'FlamingGorge_Elev_Scr',       1013,     1,     'true',    2,    'Monitor Flaming Gorge surcharge and minimum pool',            8 FROM dual UNION ALL
    SELECT 7,     'BlueMesa_Elev_Scr',           1014,     1,     'true',    2,    'Monitor Blue Mesa flood space and winter drawdown',           8 FROM dual UNION ALL
    SELECT 8,     'Navajo_Elev_Scr',             1017,     1,     'true',    2,    'Monitor Navajo Reservoir spillway & intake bounds',           8 FROM dual UNION ALL
    SELECT 9,     'LeesFerry_Discharge_Scr',     1021,     13,    'true',    1,    'Monitor Colorado River at Lees Ferry flood & min flow',       8 FROM dual UNION ALL
    SELECT 10,    'LeesFerry_WaterTemp_Scr',     1021,     27,    'true',    5,    'Monitor Glen Canyon tailwater temperature for native fish',   8 FROM dual UNION ALL
    SELECT 11,    'Cisco_Discharge_Scr',         1022,     13,    'true',    1,    'Monitor Colorado River near Cisco flood stage/flow',          8 FROM dual UNION ALL
    SELECT 12,    'GreenRiverUT_Discharge_Scr',  1023,     13,    'true',    1,    'Monitor Green River UT high runoff flow',                     8 FROM dual UNION ALL
    SELECT 13,    'Bluff_Discharge_Scr',         1024,     13,    'true',    1,    'Monitor San Juan River near Bluff flood warning',             8 FROM dual UNION ALL
    SELECT 14,    'CAP_Diversion_Scr',           1034,     14,    'true',    3,    'Monitor CAP Mark Wilmer pumping plant flow bounds',           8 FROM dual UNION ALL
    SELECT 15,    'GlenCanyon_Power_Scr',        1039,     21,    'true',    3,    'Monitor Glen Canyon Powerplant generation capacity',          8 FROM dual UNION ALL
    SELECT 16,    'Hoover_Power_Scr',            1040,     21,    'true',    3,    'Monitor Hoover Dam Powerplant generation capacity',           8 FROM dual UNION ALL
    SELECT 17,    'Berthoud_SWE_Scr',            1041,     25,    'true',    4,    'Monitor Berthoud Summit SNOTEL sensor health & bounds',       8 FROM dual UNION ALL
    SELECT 18,    'Powell_Legacy_Test_Scr',      1011,     4,     'false',   2,    'Disabled historical storage screening rule',                  8 FROM dual
  ) LOOP
    MERGE INTO alarm_screening t USING (SELECT r.id id FROM dual) s ON (t.screening_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      screening_id, screening_name, site_id, datatype_id, start_date_time,
      last_modified, enabled, alarm_group_id, screening_desc, loading_application_id
    ) VALUES (
      r.id, r.nm, r.sid, r.dt, 1704067200000, c_mod_ms, r.en, r.ag, r.d, r.app
    );
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 6. ALARM_LIMIT_SET (seasonal high/low/critical/reject thresholds)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id,  1 sc, 'ALL_YEAR' sea, 3715 rh, 3700 ch, 3690 wh, 3525 wl, 3490 cl, 3370 rl, '24 hours' sd, 0.01 st, 'Check Powell pool elevation vs min power pool (3490 ft)' h FROM dual UNION ALL
    SELECT 2,     2,    'ALL_YEAR',     50000,   35000,   28000,   6000,    4500,    0,       '6 hours',     50,   'Verify Glen Canyon release schedule and ramping limits' FROM dual UNION ALL
    SELECT 3,     3,    'SPRING',       140000,  95000,   65000,   5000,    2500,    0,       '24 hours',    100,  'Spring snowmelt inflow watch at Lake Powell' FROM dual UNION ALL
    SELECT 4,     3,    'BASEFLOW',     40000,   25000,   18000,   3000,    1500,    0,       '24 hours',    100,  'Baseflow inflow monitoring at Lake Powell' FROM dual UNION ALL
    SELECT 5,     4,    'ALL_YEAR',     1232,    1221,    1215,    1050,    1025,    895,     '24 hours',    0.01, 'Lake Mead shortage tier threshold (1075/1050/1025 ft)' FROM dual UNION ALL
    SELECT 6,     5,    'ALL_YEAR',     65000,   49000,   32000,   5000,    3500,    0,       '6 hours',     50,   'Verify Hoover Dam turbine release schedule' FROM dual UNION ALL
    SELECT 7,     6,    'ALL_YEAR',     6047,    6040,    6035,    5950,    5871,    5740,    '24 hours',    0.02, 'Flaming Gorge pool elevation monitoring' FROM dual UNION ALL
    SELECT 8,     7,    'ALL_YEAR',     7528,    7519.4,  7515,    7430,    7393,    7358,    '24 hours',    0.02, 'Blue Mesa flood control and power pool limits' FROM dual UNION ALL
    SELECT 9,     8,    'ALL_YEAR',     6108,    6085,    6080,    6010,    5990,    5775,    '24 hours',    0.02, 'Navajo Reservoir pool elevation limits' FROM dual UNION ALL
    SELECT 10,    9,    'ALL_YEAR',     120000,  45000,   32000,   6000,    4500,    500,     '4 hours',     25,   'Lees Ferry compact point streamflow alert' FROM dual UNION ALL
    SELECT 11,    10,   'SUMMER',       35.0,    20.0,    16.0,    7.0,     5.0,     0.0,     '12 hours',    0.1,  'Summer tailwater warm-water threshold (16 degC)' FROM dual UNION ALL
    SELECT 12,    10,   'WINTER',       25.0,    15.0,    12.0,    6.0,     4.0,     0.0,     '12 hours',    0.1,  'Winter tailwater temperature threshold' FROM dual UNION ALL
    SELECT 13,    11,   'ALL_YEAR',     100000,  55000,   35000,   1500,    900,     100,     '6 hours',     25,   'Cisco mainstem flood & low-flow alert' FROM dual UNION ALL
    SELECT 14,    12,   'ALL_YEAR',     90000,   48000,   30000,   1200,    800,     100,     '6 hours',     25,   'Green River UT discharge alert' FROM dual UNION ALL
    SELECT 15,    13,   'ALL_YEAR',     60000,   25000,   15000,   400,     200,     10,      '6 hours',     20,   'San Juan River near Bluff discharge alert' FROM dual UNION ALL
    SELECT 16,    14,   'ALL_YEAR',     4200,    3600,    3200,    200,     0,       0,       '12 hours',    10,   'CAP pumping plant diversion flow bounds' FROM dual UNION ALL
    SELECT 17,    15,   'ALL_YEAR',     1400,    1320,    1250,    150,     50,      0,       '4 hours',     5,    'Glen Canyon powerplant MW alert' FROM dual UNION ALL
    SELECT 18,    16,   'ALL_YEAR',     2200,    2080,    1950,    200,     50,      0,       '4 hours',     5,    'Hoover powerplant MW alert' FROM dual UNION ALL
    SELECT 19,    17,   'ALL_YEAR',     70.0,    45.0,    38.0,    0.0,     0.0,     0.0,     '72 hours',    0.05, 'Berthoud Summit SWE sensor range check' FROM dual
  ) LOOP
    MERGE INTO alarm_limit_set t USING (SELECT r.id id FROM dual) s ON (t.limit_set_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      limit_set_id, screening_id, season_name,
      reject_high, critical_high, warning_high, warning_low, critical_low, reject_low,
      stuck_duration, stuck_tolerance, missing_period, missing_interval, missing_max_values, hint_text
    ) VALUES (
      r.id, r.sc, r.sea, r.rh, r.ch, r.wh, r.wl, r.cl, r.rl,
      r.sd, r.st, '24 hours', '1 hour', 6, r.h
    );
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 7. ALARM_CURRENT (active alarms referencing valid CP_TS_ID rows)
  -- ---------------------------------------------------------------------------
  v_ts_id := get_ts(2015, 'day'); -- Lake Mead elevation below 1075 / near 1050 watch
  MERGE INTO alarm_current t USING (SELECT v_ts_id tid, 8 app FROM dual) s
  ON (t.ts_id = s.tid AND t.loading_application_id = s.app)
  WHEN NOT MATCHED THEN INSERT (
    ts_id, limit_set_id, assert_time, data_value, data_time,
    alarm_flags, message, last_notification_sent, loading_application_id
  ) VALUES (
    v_ts_id, 5, 1759190400000, 1062.35, 1759190400000,
    1, 'WARNING LOW: Lake Mead elevation approaching Tier 2a watch band', 1759194000000, 8
  );

  v_ts_id := get_ts(2065, 'day'); -- Lees Ferry water temp warm warning
  MERGE INTO alarm_current t USING (SELECT v_ts_id tid, 8 app FROM dual) s
  ON (t.ts_id = s.tid AND t.loading_application_id = s.app)
  WHEN NOT MATCHED THEN INSERT (
    ts_id, limit_set_id, assert_time, data_value, data_time,
    alarm_flags, message, last_notification_sent, loading_application_id
  ) VALUES (
    v_ts_id, 11, 1759104000000, 16.4, 1759104000000,
    2, 'WARNING HIGH: Lees Ferry tailwater temperature above 16.0 degC', 1759107600000, 8
  );

  v_ts_id := get_ts(2001, 'day'); -- Lake Powell low elevation watch
  MERGE INTO alarm_current t USING (SELECT v_ts_id tid, 8 app FROM dual) s
  ON (t.ts_id = s.tid AND t.loading_application_id = s.app)
  WHEN NOT MATCHED THEN INSERT (
    ts_id, limit_set_id, assert_time, data_value, data_time,
    alarm_flags, message, last_notification_sent, loading_application_id
  ) VALUES (
    v_ts_id, 1, 1759233600000, 3578.18, 1759233600000,
    1, 'INFO: Lake Powell seasonal drawdown tracking', 1759237200000, 8
  );

  v_ts_id := get_ts(2063, 'hour'); -- Lees Ferry hourly ramping notice
  MERGE INTO alarm_current t USING (SELECT v_ts_id tid, 8 app FROM dual) s
  ON (t.ts_id = s.tid AND t.loading_application_id = s.app)
  WHEN NOT MATCHED THEN INSERT (
    ts_id, limit_set_id, assert_time, data_value, data_time,
    alarm_flags, message, last_notification_sent, loading_application_id
  ) VALUES (
    v_ts_id, 10, 1759147200000, 15150.0, 1759147200000,
    1, 'ADVISORY: Elevated diurnal release peak at Lees Ferry', 1759150800000, 8
  );

  -- ---------------------------------------------------------------------------
  -- 8. ALARM_HISTORY (resolved / acknowledged historical alarms)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 2063 sdi, 'day' iv, 10 ls, 1755216000000 ast, 48500.0 dv, 4 flg, 'CRITICAL HIGH: Lees Ferry spike exceeded 45,000 cfs (sensor QA)' msg, 1755259200000 et, 'HYDRO_ALICE' cb FROM dual UNION ALL
    SELECT 2063,     'day',    10,    1731369600000,     36900.0,    2,     'WARNING HIGH: Planned November 2024 High-Flow Experiment'          , 1731715200000,    'HYDRO_ALICE'    FROM dual UNION ALL
    SELECT 2005,     'day',    2,     1731369600000,     36500.0,    2,     'WARNING HIGH: Glen Canyon HFE bypass + turbine release'            , 1731715200000,    'HYDRO_ALICE'    FROM dual UNION ALL
    SELECT 2003,     'day',    3,     1749600000000,     68400.0,    2,     'WARNING HIGH: Peak June snowmelt inflow to Lake Powell'            , 1750032000000,    'HYDRO_DAVE'     FROM dual UNION ALL
    SELECT 2069,     'day',    13,    1749340800000,     36200.0,    2,     'WARNING HIGH: Colorado River at Cisco snowmelt peak'               , 1749772800000,    'HYDRO_ALICE'    FROM dual UNION ALL
    SELECT 2073,     'day',    14,    1749513600000,     31400.0,    2,     'WARNING HIGH: Green River UT spring peak flow'                     , 1749945600000,    'HYDRO_ALICE'    FROM dual UNION ALL
    SELECT 2015,     'day',    5,     1722470400000,     1061.2,     1,     'WARNING LOW: Lake Mead below Tier 1 threshold (1075 ft)'           , 1735689600000,    'HYDRO_BOB'      FROM dual UNION ALL
    SELECT 2065,     'day',    11,    1755302400000,     42.5,       8,     'REJECT HIGH: Lees Ferry water temp probe fault (42.5 degC)'        , 1755345600000,    'HYDRO_CAROL'    FROM dual UNION ALL
    SELECT 2093,     'day',    16,    1752537600000,     3310.0,     2,     'WARNING HIGH: CAP peak summer agricultural pumping rate'           , 1752883200000,    'HYDRO_BOB'      FROM dual UNION ALL
    SELECT 2100,     'day',    17,    1753833600000,     1280.0,     2,     'WARNING HIGH: Glen Canyon near max generation during heatwave'     , 1753920000000,    'HYDRO_ALICE'    FROM dual UNION ALL
    SELECT 2103,     'day',    18,    1753833600000,     1985.0,     2,     'WARNING HIGH: Hoover peak summer load dispatch'                    , 1753920000000,    'HYDRO_BOB'      FROM dual UNION ALL
    SELECT 2106,     'day',    19,    1743465600000,     39.2,       2,     'WARNING HIGH: Above-normal late-March SWE at Berthoud Summit'      , 1744329600000,    'HYDRO_DAVE'     FROM dual
  ) LOOP
    v_ts_id := get_ts(r.sdi, r.iv);
    MERGE INTO alarm_history t USING (
      SELECT v_ts_id tid, r.ls ls, r.ast ast, 8 app FROM dual
    ) s ON (t.ts_id = s.tid AND t.limit_set_id = s.ls AND t.assert_time = s.ast AND t.loading_application_id = s.app)
    WHEN NOT MATCHED THEN INSERT (
      ts_id, limit_set_id, assert_time, data_value, data_time,
      alarm_flags, message, end_time, cancelled_by, loading_application_id
    ) VALUES (
      v_ts_id, r.ls, r.ast, r.dv, r.ast, r.flg, r.msg, r.et, r.cb, 8
    );
  END LOOP;

  -- Advance alarm sequences past max seeded IDs
  LOOP SELECT alarm_groupidseq.NEXTVAL     INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT alarm_eventidseq.NEXTVAL     INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT alarm_screeningidseq.NEXTVAL INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT alarm_limit_setidseq.NEXTVAL INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] Alarm groups, screenings, limit sets, and alarm history seeded.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
