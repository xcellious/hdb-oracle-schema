-- =============================================================================
-- 05_timeseries_real_and_model.sql
-- Populates real and modeled time-series tables and statistical summaries:
--   1. Real time series loaded via native HDBDBA.MODIFY_R_BASE_RAW(..., 'N')
--      which validates, standardizes dates, inserts into R_BASE, automatically
--      merges into R_INSTANT, R_HOUR, R_DAY, R_MONTH, R_YEAR, R_WY, R_OTHER,
--      registers CP_TS_ID, and queues active CP_COMP_TASKLIST entries!
--   2. Statistical summary tables: R_HOURSTAT, R_DAYSTAT, R_MONTHSTAT,
--      R_MONTHSTATRANGE, R_YEARSTAT, R_WYSTAT.
--   3. Modeled time series: M_HOUR, M_DAY, M_MONTH, M_MONTHRANGE, M_MONTHSTAT,
--      M_YEAR, M_WY (linked to REF_MODEL_RUN records created in script 04).
--
-- Idempotent: MODIFY_R_BASE_RAW uses DO_UPDATE_Y_OR_N => 'N' (skips existing
-- rows without firing updates/archives/duplicate tasklist items), and all
-- stat/modeled tables use insert-only MERGE.
-- =============================================================================

PROMPT [05] Seeding real time series (via MODIFY_R_BASE_RAW), statistical summaries, and modeled time series...

ALTER SESSION SET CURRENT_SCHEMA = HDBDBA;

DECLARE
  v_edt          DATE;
  v_mri_24ms     NUMBER;
  v_mri_24ms_min NUMBER;
  v_mri_24ms_max NUMBER;
  v_mri_crss1    NUMBER;
  v_mri_crss2    NUMBER;
  v_mri_esp50    NUMBER;
  v_mri_ubday    NUMBER;
  v_mri_glenhr   NUMBER;
  v_val          FLOAT;
  v_s            DATE;
  v_e            DATE;

  PROCEDURE load_rbase(
    p_sdi NUMBER, p_int VARCHAR2, p_sdt DATE, p_edt DATE, p_val FLOAT,
    p_agen NUMBER, p_ow VARCHAR2, p_valid CHAR, p_cs NUMBER,
    p_app NUMBER, p_mth NUMBER, p_cid NUMBER, p_flags VARCHAR2 DEFAULT NULL
  ) IS
    l_edt DATE := p_edt;
  BEGIN
    modify_r_base_raw(
      site_datatype_id       => p_sdi,
      interval               => p_int,
      start_date_time        => p_sdt,
      end_date_time          => l_edt,
      value                  => p_val,
      agen_id                => p_agen,
      overwrite_flag         => p_ow,
      validation             => p_valid,
      collection_system_id   => p_cs,
      loading_application_id => p_app,
      method_id              => p_mth,
      computation_id         => p_cid,
      do_update_y_or_n       => 'N',
      data_flags             => p_flags,
      time_zone              => 'MST'
    );
  END;

BEGIN
  -- ---------------------------------------------------------------------------
  -- 1. R_INSTANT via MODIFY_R_BASE_RAW (15-min telemetry for Sep 29-30, 2025)
  --    3 SDIs x 40 intervals = 120 rows
  -- ---------------------------------------------------------------------------
  FOR i IN 0..39 LOOP
    v_s := DATE '2025-09-29' + (i * 15) / 1440;
    -- Lees Ferry instantaneous discharge (diurnal peaking wave from Glen Canyon)
    load_rbase(2063, 'instant', v_s, v_s, ROUND(11200 + 2400 * SIN(i * 0.314), 1), 2, NULL, 'Z', 1, 1, 2, 0);
    -- Lees Ferry instantaneous stage
    load_rbase(2064, 'instant', v_s, v_s, ROUND(7.85 + 0.65 * SIN(i * 0.314), 2),  2, NULL, 'V', 1, 1, 2, 0);
    -- Lees Ferry instantaneous turbidity (datatype 30 is instant-only!)
    load_rbase(2068, 'instant', v_s, v_s, ROUND(12.4 + 3.1 * COS(i * 0.25), 2),    2, NULL, 'V', 1, 1, 2, 0);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 2. R_HOUR via MODIFY_R_BASE_RAW (48 hours Sep 28-29, 2025 across 4 SDIs = 192 rows)
  -- ---------------------------------------------------------------------------
  FOR h IN 0..47 LOOP
    v_s := DATE '2025-09-28' + h / 24;
    v_e := v_s + 1 / 24;
    -- Lake Powell hourly pool elevation
    load_rbase(2001, 'hour', v_s, v_e, ROUND(3578.40 - h * 0.002, 2),                1, NULL, 'Z', 2, 9, 2, 0);
    -- Lake Powell hourly total release (diurnal WAPA peaking pattern)
    load_rbase(2005, 'hour', v_s, v_e, ROUND(12000 + 3500 * SIN((h - 6) * 0.2618), 0),1, NULL, 'Z', 2, 9, 2, 0);
    -- Lees Ferry hourly discharge (3.5 hr lag behind Glen Canyon)
    load_rbase(2063, 'hour', v_s, v_e, ROUND(11950 + 3200 * SIN((h - 9.5) * 0.2618),0),2, NULL, 'Z', 3, 4, 4, 106);
    -- Lees Ferry hourly stage
    load_rbase(2064, 'hour', v_s, v_e, ROUND(8.10 + 0.72 * SIN((h - 9.5) * 0.2618),2), 2, NULL, 'V', 3, 4, 4, 0);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 3. R_DAY via MODIFY_R_BASE_RAW (30 days Sep 2025 across 14 SDIs = 420 rows)
  -- ---------------------------------------------------------------------------
  FOR d IN 0..29 LOOP
    v_s := DATE '2025-09-01' + d;
    v_e := v_s + 1;
    -- Lake Powell: elev, storage, inflow, release, tailwater, water temp
    load_rbase(2001, 'day', v_s, v_e, ROUND(3580.50 - d * 0.08, 2),              1, NULL, 'Z', 2, 9, 11, 0);
    load_rbase(2002, 'day', v_s, v_e, ROUND(10285000 - d * 7200, 0),             1, NULL, 'Z', 2, 2, 14, 101);
    load_rbase(2003, 'day', v_s, v_e, ROUND(8400 + 900 * SIN(d * 0.21), 0),      1, NULL, 'Z', 2, 2, 15, 109);
    load_rbase(2005, 'day', v_s, v_e, ROUND(12200 + 450 * COS(d * 0.25), 0),     1, NULL, 'Z', 2, 2, 5,  108);
    load_rbase(2011, 'day', v_s, v_e, ROUND(3137.8 + 0.15 * COS(d * 0.25), 2),   1, NULL, 'V', 2, 9, 5,  0);
    -- Lake Mead: elev, storage, release
    load_rbase(2015, 'day', v_s, v_e, ROUND(1063.80 - d * 0.05, 2),              1, NULL, 'Z', 2, 9, 11, 0);
    load_rbase(2016, 'day', v_s, v_e, ROUND(8960000 - d * 3900, 0),              1, NULL, 'Z', 2, 2, 14, 102);
    load_rbase(2018, 'day', v_s, v_e, ROUND(11400 + 600 * SIN(d * 0.30), 0),     1, NULL, 'Z', 2, 9, 5,  0);
    -- Upper Basin Reservoirs: Flaming Gorge, Blue Mesa, Navajo
    load_rbase(2025, 'day', v_s, v_e, ROUND(6026.20 - d * 0.03, 2),              1, NULL, 'Z', 2, 9, 11, 0);
    load_rbase(2032, 'day', v_s, v_e, ROUND(7494.10 - d * 0.06, 2),              1, NULL, 'Z', 2, 9, 11, 0);
    -- Key Streamgages: Lees Ferry, Cisco, Green River UT, Bluff
    load_rbase(2063, 'day', v_s, v_e, ROUND(12280 + 420 * COS(d * 0.25), 0),     2, NULL, 'Z', 3, 4, 5,  107);
    load_rbase(2069, 'day', v_s, v_e, ROUND(3950 + 520 * SIN(d * 0.20), 0),      2, NULL, 'Z', 3, 4, 5,  0);
    load_rbase(2073, 'day', v_s, v_e, ROUND(3120 + 380 * COS(d * 0.18), 0),      2, NULL, 'Z', 3, 4, 5,  0);
    load_rbase(2076, 'day', v_s, v_e, ROUND(1280 + 210 * SIN(d * 0.28), 0),      2, NULL, 'Z', 3, 4, 5,  0);
    -- Diversions & Power & Water Temp
    load_rbase(2093, 'day', v_s, v_e, ROUND(2150 + 180 * COS(d * 0.22), 0),     11, NULL, 'Z', 2, 9, 5,  0);
    load_rbase(2100, 'day', v_s, v_e, ROUND(485 + 32 * COS(d * 0.25), 1),        6, NULL, 'Z', 2, 9, 5,  0);
    load_rbase(2065, 'day', v_s, v_e, ROUND(11.4 + 0.6 * SIN(d * 0.20), 2),      2, NULL, 'Z', 3, 4, 5,  0);
  END LOOP;

  -- Add a few intentional QC edge-case rows in R_BASE (Manual Overwrite 'O', High Warning 'H', Failed Cutoff 'F')
  load_rbase(2001, 'day', DATE '2025-08-15', DATE '2025-08-16', 3583.45, 1, 'O', 'V', 6, 3,  3, 0, 'MAN_ADJ');
  load_rbase(2063, 'day', DATE '2025-08-15', DATE '2025-08-16', 48500.0, 2, NULL,'Z', 3, 4,  5, 0, 'SPIKE_HI'); -- auto-flags 'H' (>45000 expected, <120000 cutoff)
  load_rbase(2063, 'day', DATE '2025-08-16', DATE '2025-08-17', 145000.0,2, NULL,'Z', 3, 4,  5, 0, 'BAD_SEN');  -- auto-flags 'F' (>120000 cutoff, stays in R_BASE only!)
  load_rbase(2065, 'day', DATE '2025-08-16', DATE '2025-08-17', 42.5,    2, NULL,'Z', 3, 4,  5, 0, 'BAD_TMP');  -- auto-flags 'F' (>35 cutoff)

  -- ---------------------------------------------------------------------------
  -- 4. R_MONTH via MODIFY_R_BASE_RAW (12 months WY2025 Oct 2024 - Sep 2025 x 12 SDIs = 144 rows)
  --    Realistic snowmelt runoff hydrograph peaking in May-June!
  -- ---------------------------------------------------------------------------
  FOR m IN 0..11 LOOP
    v_s := ADD_MONTHS(DATE '2024-10-01', m);
    v_e := ADD_MONTHS(v_s, 1);
    DECLARE
      -- Seasonal multiplier peaking in May (m=7) and June (m=8)
      v_seas FLOAT := CASE m
        WHEN 0 THEN 0.55 WHEN 1 THEN 0.50 WHEN 2 THEN 0.45 WHEN 3 THEN 0.42
        WHEN 4 THEN 0.48 WHEN 5 THEN 0.68 WHEN 6 THEN 1.15 WHEN 7 THEN 2.35
        WHEN 8 THEN 2.65 WHEN 9 THEN 1.10 WHEN 10 THEN 0.72 ELSE 0.60 END;
      v_pow_el FLOAT := CASE m
        WHEN 0 THEN 3574.2 WHEN 1 THEN 3571.8 WHEN 2 THEN 3569.1 WHEN 3 THEN 3566.5
        WHEN 4 THEN 3564.8 WHEN 5 THEN 3564.2 WHEN 6 THEN 3566.9 WHEN 7 THEN 3577.4
        WHEN 8 THEN 3588.6 WHEN 9 THEN 3586.2 WHEN 10 THEN 3582.5 ELSE 3578.2 END;
      v_md_el  FLOAT := CASE m
        WHEN 0 THEN 1061.4 WHEN 1 THEN 1062.8 WHEN 2 THEN 1065.2 WHEN 3 THEN 1068.5
        WHEN 4 THEN 1070.1 WHEN 5 THEN 1069.4 WHEN 6 THEN 1067.2 WHEN 7 THEN 1064.5
        WHEN 8 THEN 1062.8 WHEN 9 THEN 1061.9 WHEN 10 THEN 1062.2 ELSE 1062.4 END;
      v_swe    FLOAT := CASE m
        WHEN 0 THEN 1.4  WHEN 1 THEN 5.2  WHEN 2 THEN 10.6 WHEN 3 THEN 15.8
        WHEN 4 THEN 20.4 WHEN 5 THEN 24.9 WHEN 6 THEN 27.3 WHEN 7 THEN 14.5
        WHEN 8 THEN 1.2  WHEN 9 THEN 0.0  WHEN 10 THEN 0.0 ELSE 0.2 END;
    BEGIN
      load_rbase(2001, 'month', v_s, v_e, v_pow_el,                         1, NULL, 'A', 5, 7, 12, 0);
      load_rbase(2002, 'month', v_s, v_e, ROUND((v_pow_el - 3490) * 90000 + 3997000, 0), 1, NULL, 'A', 5, 2, 12, 101);
      load_rbase(2003, 'month', v_s, v_e, ROUND(11200 * v_seas, 0),         1, NULL, 'A', 5, 2, 6,  109);
      load_rbase(2005, 'month', v_s, v_e, ROUND(10800 + 1800 * SIN(m*0.5),0),1,NULL, 'A', 5, 2, 6,  111);
      load_rbase(2015, 'month', v_s, v_e, v_md_el,                          1, NULL, 'A', 5, 7, 12, 0);
      load_rbase(2016, 'month', v_s, v_e, ROUND((v_md_el - 950) * 76000 + 2018000, 0),  1, NULL, 'A', 5, 2, 12, 102);
      load_rbase(2018, 'month', v_s, v_e, ROUND(10900 + 2200 * SIN((m-4)*0.5),0),1,NULL,'A',5, 2, 6,  112);
      load_rbase(2063, 'month', v_s, v_e, ROUND(11000 + 1750 * SIN(m*0.5),0),2,NULL, 'A', 3, 4, 6,  0);
      load_rbase(2069, 'month', v_s, v_e, ROUND(5600 * v_seas, 0),          2, NULL, 'A', 3, 4, 6,  0);
      load_rbase(2073, 'month', v_s, v_e, ROUND(4200 * v_seas, 0),          2, NULL, 'A', 3, 4, 6,  0);
      load_rbase(2101, 'month', v_s, v_e, ROUND(310000 + 65000 * SIN(m*0.5),0),6,NULL,'A',2, 9, 9,  117);
      load_rbase(2106, 'month', v_s, v_e, v_swe,                            4, NULL, 'A', 4, 5, 12, 0);
    END;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 5. R_YEAR & R_WY via MODIFY_R_BASE_RAW (2023-2025 across 8 SDIs = 48 rows)
  -- ---------------------------------------------------------------------------
  FOR y IN 2023..2025 LOOP
    DECLARE
      v_fac FLOAT := CASE y WHEN 2023 THEN 1.32 WHEN 2024 THEN 0.88 ELSE 0.96 END;
      v_yr_s DATE := TO_DATE(y || '-01-01', 'YYYY-MM-DD');
      v_yr_e DATE := TO_DATE((y+1) || '-01-01', 'YYYY-MM-DD');
      v_wy_s DATE := TO_DATE((y-1) || '-10-01', 'YYYY-MM-DD');
      v_wy_e DATE := TO_DATE(y || '-10-01', 'YYYY-MM-DD');
    BEGIN
      load_rbase(2001, 'year', v_yr_s, v_yr_e, ROUND(3565 + (y-2023)*7.5, 2), 1, NULL, 'A', 5, 7, 7, 0);
      load_rbase(2003, 'year', v_yr_s, v_yr_e, ROUND(11800 * v_fac, 0),       1, NULL, 'A', 5, 7, 7, 0);
      load_rbase(2005, 'year', v_yr_s, v_yr_e, ROUND(10600 + (y-2023)*350,0), 1, NULL, 'A', 5, 7, 7, 0);
      load_rbase(2015, 'year', v_yr_s, v_yr_e, ROUND(1058 + (y-2023)*3.2, 2), 1, NULL, 'A', 5, 7, 7, 0);
      load_rbase(2063, 'year', v_yr_s, v_yr_e, ROUND(10800 + (y-2023)*320,0), 2, NULL, 'A', 3, 4, 7, 0);
      load_rbase(2069, 'year', v_yr_s, v_yr_e, ROUND(5900 * v_fac, 0),        2, NULL, 'A', 3, 4, 7, 0);

      load_rbase(2001, 'wy',   v_wy_s, v_wy_e, ROUND(3566 + (y-2023)*7.2, 2), 1, NULL, 'A', 5, 7, 10, 0);
      load_rbase(2013, 'wy',   v_wy_s, v_wy_e, ROUND(8850000 * v_fac, 0),     1, NULL, 'A', 5, 7, 10, 0);
      load_rbase(2014, 'wy',   v_wy_s, v_wy_e, ROUND(7480000 + (y-2023)*250000,0),1,NULL,'A',5,7, 10, 0);
      load_rbase(2015, 'wy',   v_wy_s, v_wy_e, ROUND(1059 + (y-2023)*3.1, 2), 1, NULL, 'A', 5, 7, 10, 0);
      load_rbase(2063, 'wy',   v_wy_s, v_wy_e, ROUND(10750 + (y-2023)*310,0), 2, NULL, 'A', 3, 4, 10, 0);
      load_rbase(2101, 'wy',   v_wy_s, v_wy_e, ROUND(3950000 + (y-2023)*180000,0),6,NULL,'A',2,9, 10, 0);
    END;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 6. R_OTHER via MODIFY_R_BASE_RAW (High-Flow Experimental release & storm events)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 2005 sdi, DATE '2024-11-12' sd, DATE '2024-11-16' ed, 36500.0 val, 1 ag, 'HFE_2024' flg FROM dual UNION ALL
    SELECT 2063,     DATE '2024-11-12',    DATE '2024-11-16',    36900.0,     2,    'HFE_2024'     FROM dual UNION ALL
    SELECT 2029,     DATE '2025-06-05',    DATE '2025-06-14',    8450.0,      1,    'BIOP_PEAK'    FROM dual UNION ALL
    SELECT 2083,     DATE '2025-06-05',    DATE '2025-06-14',    8510.0,      2,    'BIOP_PEAK'    FROM dual UNION ALL
    SELECT 2049,     DATE '2025-05-22',    DATE '2025-06-02',    4900.0,      1,    'SJ_PEAK'      FROM dual UNION ALL
    SELECT 2076,     DATE '2025-05-24',    DATE '2025-06-04',    6120.0,      2,    'SJ_PEAK'      FROM dual UNION ALL
    SELECT 2069,     DATE '2025-06-08',    DATE '2025-06-15',    22400.0,     2,    'SNOWMELT_PK'  FROM dual UNION ALL
    SELECT 2073,     DATE '2025-06-10',    DATE '2025-06-18',    18900.0,     2,    'SNOWMELT_PK'  FROM dual
  ) LOOP
    load_rbase(r.sdi, 'other', r.sd, r.ed, r.val, r.ag, NULL, 'V', 5, 7, 3, 0, r.flg);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 7. Statistical Summary Tables (R_HOURSTAT, R_DAYSTAT, R_MONTHSTAT,
  --    R_MONTHSTATRANGE, R_YEARSTAT, R_WYSTAT)
  -- ---------------------------------------------------------------------------
  -- R_HOURSTAT: 24-hour diurnal average release & discharge (2 SDIs x 24 = 48 rows)
  FOR h IN 0..23 LOOP
    MERGE INTO r_hourstat t USING (SELECT 2005 sdi, h hr FROM dual) s
    ON (t.site_datatype_id = s.sdi AND t.hour = s.hr)
    WHEN NOT MATCHED THEN INSERT (site_datatype_id, hour, value, source_id)
    VALUES (2005, h, ROUND(11800 + 3200 * SIN((h - 6) * 0.2618), 1), 10);

    MERGE INTO r_hourstat t USING (SELECT 2063 sdi, h hr FROM dual) s
    ON (t.site_datatype_id = s.sdi AND t.hour = s.hr)
    WHEN NOT MATCHED THEN INSERT (site_datatype_id, hour, value, source_id)
    VALUES (2063, h, ROUND(11900 + 2900 * SIN((h - 9) * 0.2618), 1), 10);
  END LOOP;

  -- R_DAYSTAT: 30-year climatology daily averages (2 SDIs x 30 representative days = 60 rows)
  FOR d IN 1..30 LOOP
    MERGE INTO r_daystat t USING (SELECT 2069 sdi, d * 12 dy FROM dual) s
    ON (t.site_datatype_id = s.sdi AND t.day = s.dy)
    WHEN NOT MATCHED THEN INSERT (site_datatype_id, day, value, source_id)
    VALUES (2069, d * 12, ROUND(3500 + 9500 * EXP(-POWER((d*12 - 160)/35, 2)), 0), 10);

    MERGE INTO r_daystat t USING (SELECT 2073 sdi, d * 12 dy FROM dual) s
    ON (t.site_datatype_id = s.sdi AND t.day = s.dy)
    WHEN NOT MATCHED THEN INSERT (site_datatype_id, day, value, source_id)
    VALUES (2073, d * 12, ROUND(2800 + 8200 * EXP(-POWER((d*12 - 155)/32, 2)), 0), 10);
  END LOOP;

  -- R_MONTHSTAT: Period-of-record monthly normals (5 SDIs x 12 months = 60 rows)
  FOR m IN 1..12 LOOP
    DECLARE
      v_sm FLOAT := CASE m WHEN 1 THEN 0.45 WHEN 2 THEN 0.48 WHEN 3 THEN 0.65 WHEN 4 THEN 1.15
                           WHEN 5 THEN 2.30 WHEN 6 THEN 2.60 WHEN 7 THEN 1.15 WHEN 8 THEN 0.72
                           WHEN 9 THEN 0.60 WHEN 10 THEN 0.56 WHEN 11 THEN 0.52 ELSE 0.46 END;
    BEGIN
      FOR r IN (
        SELECT 2003 sdi, ROUND(12500 * v_sm, 0) val FROM dual UNION ALL
        SELECT 2063,     ROUND(11500 + 1500 * SIN(m * 0.52), 0) FROM dual UNION ALL
        SELECT 2069,     ROUND(6200 * v_sm, 0) FROM dual UNION ALL
        SELECT 2073,     ROUND(4800 * v_sm, 0) FROM dual UNION ALL
        SELECT 2076,     ROUND(1950 * v_sm, 0) FROM dual
      ) LOOP
        MERGE INTO r_monthstat t USING (SELECT r.sdi sdi, m mo FROM dual) s
        ON (t.site_datatype_id = s.sdi AND t.month = s.mo)
        WHEN NOT MATCHED THEN INSERT (site_datatype_id, month, value, source_id)
        VALUES (r.sdi, m, r.val, 10);
      END LOOP;
    END;
  END LOOP;

  -- R_MONTHSTATRANGE: Apr-Jul runoff & Oct-Sep water year seasonal normals (20 rows)
  FOR r IN (
    SELECT 2003 sdi, 4 sm, 7 em, 6420000 val FROM dual UNION ALL
    SELECT 2003,     10,   9,    9610000     FROM dual UNION ALL
    SELECT 2063,     4,    7,    2980000     FROM dual UNION ALL
    SELECT 2063,     10,   9,    8230000     FROM dual UNION ALL
    SELECT 2069,     4,    7,    3210000     FROM dual UNION ALL
    SELECT 2069,     10,   9,    4720000     FROM dual UNION ALL
    SELECT 2073,     4,    7,    2480000     FROM dual UNION ALL
    SELECT 2073,     10,   9,    3650000     FROM dual UNION ALL
    SELECT 2076,     4,    7,    890000      FROM dual UNION ALL
    SELECT 2076,     10,   9,    1380000     FROM dual
  ) LOOP
    MERGE INTO r_monthstatrange t USING (SELECT r.sdi sdi, r.sm sm, r.em em FROM dual) s
    ON (t.site_datatype_id = s.sdi AND t.start_month = s.sm AND t.end_month = s.em)
    WHEN NOT MATCHED THEN INSERT (site_datatype_id, start_month, end_month, value, source_id)
    VALUES (r.sdi, r.sm, r.em, r.val, 10);
  END LOOP;

  -- R_YEARSTAT & R_WYSTAT (5 years 2021..2025 x 5 SDIs = 25 rows each)
  FOR y IN 2021..2025 LOOP
    DECLARE
      v_f FLOAT := CASE y WHEN 2021 THEN 0.58 WHEN 2022 THEN 0.78 WHEN 2023 THEN 1.32 WHEN 2024 THEN 0.88 ELSE 0.96 END;
    BEGIN
      FOR r IN (
        SELECT 2003 sdi, ROUND(12000 * v_f, 0) val FROM dual UNION ALL
        SELECT 2063,     ROUND(10400 + (y-2021)*220, 0) FROM dual UNION ALL
        SELECT 2069,     ROUND(6000 * v_f, 0) FROM dual UNION ALL
        SELECT 2073,     ROUND(4600 * v_f, 0) FROM dual UNION ALL
        SELECT 2076,     ROUND(1850 * v_f, 0) FROM dual
      ) LOOP
        MERGE INTO r_yearstat t USING (SELECT r.sdi sdi, y yr FROM dual) s
        ON (t.site_datatype_id = s.sdi AND t.year = s.yr)
        WHEN NOT MATCHED THEN INSERT (site_datatype_id, year, value, source_id) VALUES (r.sdi, y, r.val, 10);

        MERGE INTO r_wystat t USING (SELECT r.sdi sdi, y yr FROM dual) s
        ON (t.site_datatype_id = s.sdi AND t.wy = s.yr)
        WHEN NOT MATCHED THEN INSERT (site_datatype_id, wy, value, source_id) VALUES (r.sdi, y, ROUND(r.val * 1.02, 0), 10);
      END LOOP;
    END;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 8. Modeled Time Series (M_HOUR, M_DAY, M_MONTH, M_MONTHRANGE, M_MONTHSTAT, M_YEAR, M_WY)
  -- ---------------------------------------------------------------------------
  SELECT model_run_id INTO v_mri_24ms     FROM ref_model_run WHERE model_run_name = '24-Month Study Aug 2025 Most Probable';
  SELECT model_run_id INTO v_mri_24ms_min FROM ref_model_run WHERE model_run_name = '24-Month Study Aug 2025 Min Probable';
  SELECT model_run_id INTO v_mri_24ms_max FROM ref_model_run WHERE model_run_name = '24-Month Study Aug 2025 Max Probable';
  SELECT model_run_id INTO v_mri_crss1    FROM ref_model_run WHERE model_run_name = 'CRSS 2025 StressTest Trace 1988';
  SELECT model_run_id INTO v_mri_crss2    FROM ref_model_run WHERE model_run_name = 'CRSS 2025 StressTest Trace 2011';
  SELECT model_run_id INTO v_mri_esp50    FROM ref_model_run WHERE model_run_name = 'CBRFC ESP Apr 2025 50% Median';
  SELECT model_run_id INTO v_mri_ubday    FROM ref_model_run WHERE model_run_name = 'Upper Basin Daily Ops Sep 2025';
  SELECT model_run_id INTO v_mri_glenhr   FROM ref_model_run WHERE model_run_name = 'Glen Canyon Hourly Ops 2025-09-15';

  -- M_HOUR: 24 hours x 3 SDIs = 72 rows
  FOR h IN 0..23 LOOP
    v_s := DATE '2025-09-15' + h / 24;
    v_e := v_s + 1 / 24;
    MERGE INTO m_hour t USING (SELECT v_mri_glenhr mri, 2005 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_glenhr, 2005, v_s, v_e, ROUND(12000 + 3800 * SIN((h - 6) * 0.2618), 0));

    MERGE INTO m_hour t USING (SELECT v_mri_glenhr mri, 2006 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_glenhr, 2006, v_s, v_e, ROUND(12000 + 3800 * SIN((h - 6) * 0.2618), 0));

    MERGE INTO m_hour t USING (SELECT v_mri_glenhr mri, 2100 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_glenhr, 2100, v_s, v_e, ROUND(480 + 150 * SIN((h - 6) * 0.2618), 1));
  END LOOP;

  -- M_DAY: 30 days x 4 SDIs = 120 rows
  FOR d IN 0..29 LOOP
    v_s := DATE '2025-09-01' + d;
    v_e := v_s + 1;
    MERGE INTO m_day t USING (SELECT v_mri_ubday mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_ubday, 2001, v_s, v_e, ROUND(3580.4 - d * 0.075, 2));

    MERGE INTO m_day t USING (SELECT v_mri_ubday mri, 2005 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_ubday, 2005, v_s, v_e, ROUND(12100 + 300 * COS(d * 0.25), 0));

    MERGE INTO m_day t USING (SELECT v_mri_ubday mri, 2029 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_ubday, 2029, v_s, v_e, 1650);

    MERGE INTO m_day t USING (SELECT v_mri_ubday mri, 2036 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_ubday, 2036, v_s, v_e, 1250);
  END LOOP;

  -- M_MONTH: 24 months for 24-Month Study (Most/Min/Max) + 12 months for CRSS = 240 rows
  FOR m IN 0..23 LOOP
    v_s := ADD_MONTHS(DATE '2025-08-01', m);
    v_e := ADD_MONTHS(v_s, 1);
    -- Most Probable (Lake Powell elev/storage, Lake Mead elev/storage)
    MERGE INTO m_month t USING (SELECT v_mri_24ms mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms, 2001, v_s, v_e, ROUND(3580 + 14 * SIN((m - 5) * 0.5236), 2));

    MERGE INTO m_month t USING (SELECT v_mri_24ms mri, 2002 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms, 2002, v_s, v_e, ROUND(10250000 + 1250000 * SIN((m - 5) * 0.5236), 0));

    MERGE INTO m_month t USING (SELECT v_mri_24ms mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms, 2015, v_s, v_e, ROUND(1062 + 6 * COS((m - 2) * 0.5236), 2));

    MERGE INTO m_month t USING (SELECT v_mri_24ms mri, 2016 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms, 2016, v_s, v_e, ROUND(8850000 + 480000 * COS((m - 2) * 0.5236), 0));

    -- Min Probable (drought sensitivity)
    MERGE INTO m_month t USING (SELECT v_mri_24ms_min mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms_min, 2001, v_s, v_e, ROUND(3578 - m * 1.15 + 6 * SIN((m - 5) * 0.5236), 2));

    MERGE INTO m_month t USING (SELECT v_mri_24ms_min mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms_min, 2015, v_s, v_e, ROUND(1060 - m * 0.65 + 4 * COS((m - 2) * 0.5236), 2));

    -- Max Probable (wet sensitivity)
    MERGE INTO m_month t USING (SELECT v_mri_24ms_max mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms_max, 2001, v_s, v_e, ROUND(3582 + m * 1.45 + 18 * SIN((m - 5) * 0.5236), 2));

    MERGE INTO m_month t USING (SELECT v_mri_24ms_max mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_24ms_max, 2015, v_s, v_e, ROUND(1064 + m * 0.85 + 6 * COS((m - 2) * 0.5236), 2));
  END LOOP;

  -- CRSS monthly series (12 months x 2 traces x 2 SDIs = 48 rows)
  FOR m IN 0..11 LOOP
    v_s := ADD_MONTHS(DATE '2025-01-01', m);
    v_e := ADD_MONTHS(v_s, 1);
    MERGE INTO m_month t USING (SELECT v_mri_crss1 mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss1, 2001, v_s, v_e, ROUND(3572 + 11 * SIN((m - 2) * 0.5236), 2));

    MERGE INTO m_month t USING (SELECT v_mri_crss2 mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss2, 2001, v_s, v_e, ROUND(3595 + 22 * SIN((m - 2) * 0.5236), 2));
  END LOOP;

  -- M_MONTHRANGE: Apr-Jul seasonal water supply forecast volumes (12 rows)
  FOR r IN (
    SELECT v_mri_esp50 mri, 2013 sdi, DATE '2025-04-01' sd, DATE '2025-07-31' ed, 5850000 val FROM dual UNION ALL
    SELECT v_mri_esp50,     2027,     DATE '2025-04-01',    DATE '2025-07-31',    1120000     FROM dual UNION ALL
    SELECT v_mri_esp50,     2034,     DATE '2025-04-01',    DATE '2025-07-31',    685000      FROM dual UNION ALL
    SELECT v_mri_esp50,     2048,     DATE '2025-04-01',    DATE '2025-07-31',    640000      FROM dual UNION ALL
    SELECT v_mri_24ms,      2013,     DATE '2026-04-01',    DATE '2026-07-31',    6150000     FROM dual UNION ALL
    SELECT v_mri_24ms_min,  2013,     DATE '2026-04-01',    DATE '2026-07-31',    3920000     FROM dual UNION ALL
    SELECT v_mri_24ms_max,  2013,     DATE '2026-04-01',    DATE '2026-07-31',    8750000     FROM dual UNION ALL
    SELECT v_mri_24ms,      2014,     DATE '2025-10-01',    DATE '2026-09-30',    7480000     FROM dual
  ) LOOP
    MERGE INTO m_monthrange t USING (SELECT r.mri mri, r.sdi sdi, r.sd sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_month = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_month, end_date_month, value)
    VALUES (r.mri, r.sdi, r.sd, r.ed, r.val);
  END LOOP;

  -- M_MONTHSTAT: 12 monthly climatology values x 3 SDIs = 36 rows
  FOR m IN 1..12 LOOP
    MERGE INTO m_monthstat t USING (SELECT v_mri_crss1 mri, 2001 sdi, m mo FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.month = s.mo)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, month, value)
    VALUES (v_mri_crss1, 2001, m, ROUND(3575 + 12 * SIN((m - 3) * 0.5236), 2));

    MERGE INTO m_monthstat t USING (SELECT v_mri_crss1 mri, 2015 sdi, m mo FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.month = s.mo)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, month, value)
    VALUES (v_mri_crss1, 2015, m, ROUND(1062 + 5 * COS((m - 1) * 0.5236), 2));

    MERGE INTO m_monthstat t USING (SELECT v_mri_24ms mri, 2005 sdi, m mo FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.month = s.mo)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, month, value)
    VALUES (v_mri_24ms, 2005, m, ROUND(10900 + 2100 * SIN((m - 2) * 0.5236), 0));
  END LOOP;

  -- M_YEAR & M_WY: 6 projected years (2025..2030) x 2 traces x 2 SDIs = 24 rows each
  FOR y IN 2025..2030 LOOP
    v_s := TO_DATE(y || '-01-01', 'YYYY-MM-DD');
    v_e := TO_DATE((y+1) || '-01-01', 'YYYY-MM-DD');
    MERGE INTO m_year t USING (SELECT v_mri_crss1 mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss1, 2001, v_s, v_e, ROUND(3576 - (y-2025)*3.2, 2));

    MERGE INTO m_year t USING (SELECT v_mri_crss1 mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss1, 2015, v_s, v_e, ROUND(1062 - (y-2025)*2.5, 2));

    MERGE INTO m_year t USING (SELECT v_mri_crss2 mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss2, 2001, v_s, v_e, ROUND(3584 + (y-2025)*8.5, 2));

    MERGE INTO m_year t USING (SELECT v_mri_crss2 mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss2, 2015, v_s, v_e, ROUND(1066 + (y-2025)*6.2, 2));

    -- Water years
    v_s := TO_DATE((y-1) || '-10-01', 'YYYY-MM-DD');
    v_e := TO_DATE(y || '-10-01', 'YYYY-MM-DD');
    MERGE INTO m_wy t USING (SELECT v_mri_crss1 mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss1, 2001, v_s, v_e, ROUND(3575 - (y-2025)*3.0, 2));

    MERGE INTO m_wy t USING (SELECT v_mri_crss1 mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss1, 2015, v_s, v_e, ROUND(1061 - (y-2025)*2.4, 2));

    MERGE INTO m_wy t USING (SELECT v_mri_crss2 mri, 2001 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss2, 2001, v_s, v_e, ROUND(3583 + (y-2025)*8.2, 2));

    MERGE INTO m_wy t USING (SELECT v_mri_crss2 mri, 2015 sdi, v_s sd FROM dual) s
    ON (t.model_run_id = s.mri AND t.site_datatype_id = s.sdi AND t.start_date_time = s.sd)
    WHEN NOT MATCHED THEN INSERT (model_run_id, site_datatype_id, start_date_time, end_date_time, value)
    VALUES (v_mri_crss2, 2015, v_s, v_e, ROUND(1065 + (y-2025)*6.0, 2));
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] Real time series, statistical summaries, and modeled time series seeded.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
