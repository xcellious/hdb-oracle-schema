-- =============================================================================
-- 03_external_hydromet_mappings.sql
-- Populates external site/data code systems, external data sources, external
-- mappings & key-values, Hydromet reference tables, DMI unit maps, loading
-- application properties, legends, CG_REF_CODES, and TSDB_PROPERTY.
--
-- Note: REF_EXT_SITE_DATA_MAP has FK to CP_COMPUTATION(COMPUTATION_ID), so we
-- seed the baseline COMPUTATION_ID = 0 ('No Computation') first (also used by
-- R_BASE) or leave HDB_COMPUTATION_ID NULL here and link active ones cleanly.
-- Here HDB_COMPUTATION_ID is nullable; we leave it NULL for raw external loads.
-- =============================================================================

PROMPT [03] Seeding external data mappings, Hydromet tables, and application metadata...

ALTER SESSION SET CURRENT_SCHEMA = HDBDBA;

BEGIN
  populate_pk.SET_PRE_POPULATED(0);

  -- ---------------------------------------------------------------------------
  -- 1. External Site Code Systems & Data Code Systems
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'USGS' nm,        2 ag, CAST(NULL AS NUMBER) md FROM dual UNION ALL
    SELECT 2,    'SHEF',           3,    NULL FROM dual UNION ALL
    SELECT 3,    'USBR_HYDROMET',  1,    NULL FROM dual UNION ALL
    SELECT 4,    'NRCS_SNOTEL',    4,    NULL FROM dual UNION ALL
    SELECT 5,    'USBR_SCADA',     1,    NULL FROM dual UNION ALL
    SELECT 6,    'RIVERWARE_SLOT', 1,    1    FROM dual
  ) LOOP
    MERGE INTO hdb_ext_site_code_sys t USING (SELECT r.id id FROM dual) s ON (t.ext_site_code_sys_id = s.id)
    WHEN NOT MATCHED THEN INSERT (ext_site_code_sys_id, ext_site_code_sys_name, agen_id, model_id)
    VALUES (r.id, r.nm, r.ag, r.md);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'USGS_PCODE' nm,     2 ag, CAST(NULL AS NUMBER) md FROM dual UNION ALL
    SELECT 2,    'SHEF_PE',           3,    NULL FROM dual UNION ALL
    SELECT 3,    'HYDROMET_PCODE',    1,    NULL FROM dual UNION ALL
    SELECT 4,    'SNOTEL_ELEMENT',    4,    NULL FROM dual UNION ALL
    SELECT 5,    'SCADA_TAG',         1,    NULL FROM dual UNION ALL
    SELECT 6,    'RIVERWARE_SLOT_DT', 1,    1    FROM dual
  ) LOOP
    MERGE INTO hdb_ext_data_code_sys t USING (SELECT r.id id FROM dual) s ON (t.ext_data_code_sys_id = s.id)
    WHEN NOT MATCHED THEN INSERT (ext_data_code_sys_id, ext_data_code_sys_name, agen_id, model_id)
    VALUES (r.id, r.nm, r.ag, r.md);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 2. External Data Sources (HDB_EXT_DATA_SOURCE)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'USGS NWIS Instantaneous' nm, 2 ag, CAST(NULL AS NUMBER) md, 1 sc, 1 dc, 3 cs, 'Provisional' dq, 'USGS real-time 15-min streamflow service' d FROM dual UNION ALL
    SELECT 2,    'USGS NWIS Daily Values',     2,    NULL, 1, 1, 3, 'Approved',    'USGS daily mean streamflow & stage service' FROM dual UNION ALL
    SELECT 3,    'GOES DCP SHEF Feed',         3,    NULL, 2, 2, 1, 'Provisional', 'NESDIS GOES satellite SHEF transmissions' FROM dual UNION ALL
    SELECT 4,    'USBR UC SCADA Bridge',       1,    NULL, 5, 5, 2, 'Operational', 'Upper Colorado dam SCADA real-time feed' FROM dual UNION ALL
    SELECT 5,    'USBR LC SCADA Bridge',       1,    NULL, 5, 5, 2, 'Operational', 'Lower Colorado dam SCADA real-time feed' FROM dual UNION ALL
    SELECT 6,    'NRCS SNOTEL Daily Feed',     4,    NULL, 4, 4, 4, 'Provisional', 'NRCS SNOTEL snowpack and climate daily service' FROM dual UNION ALL
    SELECT 7,    'USBR Hydromet Archive',      1,    NULL, 3, 3, 5, 'Approved',    'Hydromet daily reservoir & gage archive' FROM dual UNION ALL
    SELECT 8,    'RiverWare CRSS DMI',         1,    1,    6, 6, 7, 'Modeled',     'RiverWare CRSS planning model interface' FROM dual
  ) LOOP
    MERGE INTO hdb_ext_data_source t USING (SELECT r.id id FROM dual) s ON (t.ext_data_source_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      ext_data_source_id, ext_data_source_name, agen_id, model_id,
      ext_site_code_sys_id, ext_data_code_sys_id, collection_system_id,
      data_quality, description, date_time_loaded
    ) VALUES (r.id, r.nm, r.ag, r.md, r.sc, r.dc, r.cs, r.dq, r.d, SYSDATE);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 3. External Site Codes (HDB_EXT_SITE_CODE) & Data Codes (HDB_EXT_DATA_CODE)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    -- USGS station numbers
    SELECT 1 sc, '09380000' pc, 'AZ' sec, 1021 sid FROM dual UNION ALL
    SELECT 1,    '09180500',    'UT',     1022     FROM dual UNION ALL
    SELECT 1,    '09315000',    'UT',     1023     FROM dual UNION ALL
    SELECT 1,    '09379500',    'UT',     1024     FROM dual UNION ALL
    SELECT 1,    '09095500',    'CO',     1025     FROM dual UNION ALL
    SELECT 1,    '09058000',    'CO',     1026     FROM dual UNION ALL
    SELECT 1,    '09152500',    'CO',     1027     FROM dual UNION ALL
    SELECT 1,    '09234500',    'UT',     1028     FROM dual UNION ALL
    SELECT 1,    '09260050',    'CO',     1029     FROM dual UNION ALL
    SELECT 1,    '09415000',    'AZ',     1030     FROM dual UNION ALL
    SELECT 1,    '09404200',    'AZ',     1031     FROM dual UNION ALL
    SELECT 1,    '09429490',    'AZ',     1032     FROM dual UNION ALL
    -- SHEF codes
    SELECT 2,    'GLDA3',       'USBR',   1011     FROM dual UNION ALL
    SELECT 2,    'HOON2',       'USBR',   1012     FROM dual UNION ALL
    SELECT 2,    'GRNU1',       'USBR',   1013     FROM dual UNION ALL
    SELECT 2,    'BMDC2',       'USBR',   1014     FROM dual UNION ALL
    SELECT 2,    'NVRN5',       'USBR',   1017     FROM dual UNION ALL
    SELECT 2,    'GBRW4',       'USBR',   1018     FROM dual UNION ALL
    SELECT 2,    'LEFA3',       'USGS',   1021     FROM dual UNION ALL
    SELECT 2,    'CLRU1',       'USGS',   1022     FROM dual UNION ALL
    SELECT 2,    'GRVU1',       'USGS',   1023     FROM dual UNION ALL
    SELECT 2,    'SJBU1',       'USGS',   1024     FROM dual UNION ALL
    -- SNOTEL IDs
    SELECT 4,    '335:CO:SNTL', 'CO',     1041     FROM dual UNION ALL
    SELECT 4,    '713:CO:SNTL', 'CO',     1042     FROM dual UNION ALL
    -- SCADA site IDs
    SELECT 5,    'SCADA_GLEN',  'UC',     1011     FROM dual UNION ALL
    SELECT 5,    'SCADA_HOOV',  'LC',     1012     FROM dual UNION ALL
    SELECT 5,    'SCADA_FLAM',  'UC',     1013     FROM dual UNION ALL
    SELECT 5,    'SCADA_BLUE',  'UC',     1014     FROM dual UNION ALL
    SELECT 5,    'SCADA_NAVA',  'UC',     1017     FROM dual UNION ALL
    SELECT 5,    'SCADA_CAP',   'LC',     1034     FROM dual UNION ALL
    -- RiverWare object names
    SELECT 6,    'Powell',      'Res',    1011     FROM dual UNION ALL
    SELECT 6,    'Mead',        'Res',    1012     FROM dual UNION ALL
    SELECT 6,    'FlamingGorge','Res',    1013     FROM dual UNION ALL
    SELECT 6,    'BlueMesa',    'Res',    1014     FROM dual UNION ALL
    SELECT 6,    'Navajo',      'Res',    1017     FROM dual UNION ALL
    SELECT 6,    'Mohave',      'Res',    1019     FROM dual UNION ALL
    SELECT 6,    'Havasu',      'Res',    1020     FROM dual
  ) LOOP
    MERGE INTO hdb_ext_site_code t USING (
      SELECT r.sc sc, r.pc pc, r.sid sid FROM dual
    ) s ON (t.ext_site_code_sys_id = s.sc AND t.primary_site_code = s.pc AND t.hdb_site_id = s.sid)
    WHEN NOT MATCHED THEN INSERT (ext_site_code_sys_id, primary_site_code, secondary_site_code, hdb_site_id, date_time_loaded)
    VALUES (r.sc, r.pc, r.sec, r.sid, SYSDATE);
  END LOOP;

  FOR r IN (
    -- USGS parameter codes
    SELECT 1 dc, '00060' pc, '00003' sec, 13 dt FROM dual UNION ALL
    SELECT 1,    '00065',    '00003',     3     FROM dual UNION ALL
    SELECT 1,    '00010',    '00003',     27    FROM dual UNION ALL
    SELECT 1,    '00095',    '00003',     28    FROM dual UNION ALL
    SELECT 1,    '00300',    '00003',     29    FROM dual UNION ALL
    SELECT 1,    '63680',    '00000',     30    FROM dual UNION ALL
    -- SHEF physical elements
    SELECT 2,    'HP',       'IRZ',       1     FROM dual UNION ALL
    SELECT 2,    'HT',       'IRZ',       2     FROM dual UNION ALL
    SELECT 2,    'HG',       'IRZ',       3     FROM dual UNION ALL
    SELECT 2,    'LS',       'IRZ',       4     FROM dual UNION ALL
    SELECT 2,    'QI',       'DRZ',       7     FROM dual UNION ALL
    SELECT 2,    'QT',       'DRZ',       9     FROM dual UNION ALL
    SELECT 2,    'QR',       'IRZ',       13    FROM dual UNION ALL
    SELECT 2,    'TW',       'IRZ',       27    FROM dual UNION ALL
    SELECT 2,    'TA',       'IRZ',       26    FROM dual UNION ALL
    SELECT 2,    'PP',       'DRZ',       24    FROM dual UNION ALL
    -- SNOTEL elements
    SELECT 4,    'WTEQ',     'DAILY',     25    FROM dual UNION ALL
    SELECT 4,    'PREC',     'DAILY',     24    FROM dual UNION ALL
    SELECT 4,    'TAVG',     'DAILY',     26    FROM dual UNION ALL
    -- SCADA tags
    SELECT 5,    'FOREBAY_EL','FT',       1     FROM dual UNION ALL
    SELECT 5,    'STORAGE_AF','AF',       4     FROM dual UNION ALL
    SELECT 5,    'REL_TOTAL', 'CFS',      9     FROM dual UNION ALL
    SELECT 5,    'REL_TURB',  'CFS',      10    FROM dual UNION ALL
    SELECT 5,    'REL_SPILL', 'CFS',      11    FROM dual UNION ALL
    SELECT 5,    'GEN_MW',    'MW',       21    FROM dual UNION ALL
    -- RiverWare slot names
    SELECT 6,    'Pool Elevation','EOP',  1     FROM dual UNION ALL
    SELECT 6,    'Storage',       'EOP',  4     FROM dual UNION ALL
    SELECT 6,    'Inflow',        'AVG',  7     FROM dual UNION ALL
    SELECT 6,    'Outflow',       'AVG',  9     FROM dual UNION ALL
    SELECT 6,    'Evaporation',   'SUM',  18    FROM dual
  ) LOOP
    MERGE INTO hdb_ext_data_code t USING (
      SELECT r.dc dc, r.pc pc, r.dt dt FROM dual
    ) s ON (t.ext_data_code_sys_id = s.dc AND t.primary_data_code = s.pc AND t.hdb_datatype_id = s.dt)
    WHEN NOT MATCHED THEN INSERT (ext_data_code_sys_id, primary_data_code, secondary_data_code, hdb_datatype_id, date_time_loaded)
    VALUES (r.dc, r.pc, r.sec, r.dt, SYSDATE);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 4. External Site-Data Mappings (REF_EXT_SITE_DATA_MAP & KEYVAL)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id,  1 src, '09380000' ps, '00060' pd, 'N' ek, 2063 sdi, 'instant' iv, 2 mth, 2 ag, 'Y' act, 'Lees Ferry 15-min USGS discharge' c FROM dual UNION ALL
    SELECT 2,     2,     '09380000',    '00060',    'N',    2063,     'day',        5,     2,    'Y',     'Lees Ferry daily USGS discharge' FROM dual UNION ALL
    SELECT 3,     2,     '09380000',    '00010',    'Y',    2065,     'day',        5,     2,    'Y',     'Lees Ferry daily water temp (sensor key)' FROM dual UNION ALL
    SELECT 4,     2,     '09180500',    '00060',    'N',    2069,     'day',        5,     2,    'Y',     'Cisco daily USGS discharge' FROM dual UNION ALL
    SELECT 5,     2,     '09315000',    '00060',    'N',    2073,     'day',        5,     2,    'Y',     'Green River UT daily USGS discharge' FROM dual UNION ALL
    SELECT 6,     2,     '09379500',    '00060',    'N',    2076,     'day',        5,     2,    'Y',     'Bluff daily USGS discharge' FROM dual UNION ALL
    SELECT 7,     2,     '09095500',    '00060',    'N',    2078,     'day',        5,     2,    'Y',     'Cameo daily USGS discharge' FROM dual UNION ALL
    SELECT 8,     2,     '09058000',    '00060',    'N',    2080,     'day',        5,     2,    'Y',     'Kremmling daily USGS discharge' FROM dual UNION ALL
    SELECT 9,     2,     '09152500',    '00060',    'N',    2081,     'day',        5,     2,    'Y',     'Gunnison GJ daily USGS discharge' FROM dual UNION ALL
    SELECT 10,    2,     '09234500',    '00060',    'N',    2083,     'day',        5,     2,    'Y',     'Greendale daily USGS discharge' FROM dual UNION ALL
    SELECT 11,    2,     '09260050',    '00060',    'N',    2085,     'day',        5,     2,    'Y',     'Deerlodge Park daily USGS discharge' FROM dual UNION ALL
    SELECT 12,    2,     '09415000',    '00060',    'N',    2086,     'day',        5,     2,    'Y',     'Littlefield daily USGS discharge' FROM dual UNION ALL
    SELECT 13,    2,     '09404200',    '00060',    'N',    2087,     'day',        5,     2,    'Y',     'Diamond Creek daily USGS discharge' FROM dual UNION ALL
    SELECT 14,    4,     'SCADA_GLEN',  'FOREBAY_EL','N',   2001,     'hour',       2,     1,    'Y',     'Glen Canyon hourly forebay elevation' FROM dual UNION ALL
    SELECT 15,    4,     'SCADA_GLEN',  'REL_TOTAL','N',    2005,     'hour',       2,     1,    'Y',     'Glen Canyon hourly total release' FROM dual UNION ALL
    SELECT 16,    4,     'SCADA_GLEN',  'GEN_MW',   'Y',    2100,     'hour',       2,     6,    'Y',     'Glen Canyon powerplant MW (unit bus key)' FROM dual UNION ALL
    SELECT 17,    5,     'SCADA_HOOV',  'FOREBAY_EL','N',   2015,     'hour',       2,     1,    'Y',     'Hoover hourly forebay elevation' FROM dual UNION ALL
    SELECT 18,    5,     'SCADA_HOOV',  'REL_TOTAL','N',    2018,     'hour',       2,     1,    'Y',     'Hoover hourly total release' FROM dual UNION ALL
    SELECT 19,    5,     'SCADA_HOOV',  'GEN_MW',   'Y',    2103,     'hour',       2,     6,    'Y',     'Hoover powerplant MW (unit bus key)' FROM dual UNION ALL
    SELECT 20,    4,     'SCADA_FLAM',  'FOREBAY_EL','N',   2025,     'day',        11,    1,    'Y',     'Flaming Gorge daily EOP elevation' FROM dual UNION ALL
    SELECT 21,    4,     'SCADA_BLUE',  'FOREBAY_EL','N',   2032,     'day',        11,    1,    'Y',     'Blue Mesa daily EOP elevation' FROM dual UNION ALL
    SELECT 22,    4,     'SCADA_NAVA',  'FOREBAY_EL','N',   2046,     'day',        11,    1,    'Y',     'Navajo daily EOP elevation' FROM dual UNION ALL
    SELECT 23,    6,     '335:CO:SNTL', 'WTEQ',     'N',    2106,     'day',        2,     4,    'Y',     'Berthoud Summit daily SWE' FROM dual UNION ALL
    SELECT 24,    6,     '335:CO:SNTL', 'PREC',     'N',    2107,     'day',        8,     4,    'Y',     'Berthoud Summit daily precip' FROM dual UNION ALL
    SELECT 25,    6,     '713:CO:SNTL', 'WTEQ',     'N',    2109,     'day',        2,     4,    'Y',     'Red Mountain Pass daily SWE' FROM dual UNION ALL
    SELECT 26,    3,     'LEFA3',       'QR',       'Y',    2063,     'hour',       4,     2,    'N',     'Retired legacy SHEF mapping for Lees Ferry' FROM dual
  ) LOOP
    DECLARE
      v_exists NUMBER;
    BEGIN
      SELECT COUNT(*) INTO v_exists FROM ref_ext_site_data_map WHERE mapping_id = r.id;
      IF v_exists = 0 THEN
        INSERT INTO ref_ext_site_data_map (
          mapping_id, ext_data_source_id, primary_site_code, primary_data_code,
          extra_keys_y_n, hdb_site_datatype_id, hdb_interval_name,
          hdb_method_id, hdb_computation_id, hdb_agen_id, is_active_y_n, cmmnt, date_time_loaded
        ) VALUES (
          r.id, r.src, r.ps, r.pd, r.ek, r.sdi, r.iv, r.mth, NULL, r.ag, r.act, r.c, SYSDATE
        );
      END IF;
    END;
  END LOOP;

  FOR r IN (
    SELECT 3 mid,  'STAT_CD' k, '00003' v FROM dual UNION ALL
    SELECT 3,      'SENSOR_POS','TAILWATER' FROM dual UNION ALL
    SELECT 16,     'BUS_NAME',  'GLEN_MAIN_230KV' FROM dual UNION ALL
    SELECT 16,     'DISPATCH',  'WAPA_CRSP' FROM dual UNION ALL
    SELECT 19,     'BUS_NAME',  'HOOVER_MAIN_230KV' FROM dual UNION ALL
    SELECT 19,     'DISPATCH',  'WAPA_DSW' FROM dual UNION ALL
    SELECT 26,     'SHEF_DUR',  'H' FROM dual UNION ALL
    SELECT 26,     'SHEF_SRC',  'G' FROM dual
  ) LOOP
    MERGE INTO ref_ext_site_data_map_keyval t USING (
      SELECT r.mid mid, r.k k, r.v v FROM dual
    ) s ON (t.mapping_id = s.mid AND t.key_name = s.k AND t.key_value = s.v)
    WHEN NOT MATCHED THEN INSERT (mapping_id, key_name, key_value, date_time_loaded)
    VALUES (r.mid, r.k, r.v, SYSDATE);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 5. Hydromet Reference Tables (REF_HM_*)
  -- ---------------------------------------------------------------------------
  MERGE INTO ref_hm_filetype t USING (SELECT 'A' ft FROM dual) s ON (t.hm_filetype = s.ft)
  WHEN NOT MATCHED THEN INSERT (hm_filetype, hm_filetype_name) VALUES ('A', 'Hydromet Archive File');
  MERGE INTO ref_hm_filetype t USING (SELECT 'D' ft FROM dual) s ON (t.hm_filetype = s.ft)
  WHEN NOT MATCHED THEN INSERT (hm_filetype, hm_filetype_name) VALUES ('D', 'Hydromet Daily File');

  FOR r IN (
    SELECT 'GLDA' c, 'Glen Canyon Dam / Lake Powell' nm, 5 ot, 1011 sid FROM dual UNION ALL
    SELECT 'HOOV',   'Hoover Dam / Lake Mead',           5,    1012     FROM dual UNION ALL
    SELECT 'FGR',    'Flaming Gorge Reservoir',          5,    1013     FROM dual UNION ALL
    SELECT 'BMR',    'Blue Mesa Reservoir',              5,    1014     FROM dual UNION ALL
    SELECT 'MPR',    'Morrow Point Reservoir',           5,    1015     FROM dual UNION ALL
    SELECT 'CRY',    'Crystal Reservoir',                5,    1016     FROM dual UNION ALL
    SELECT 'NAV',    'Navajo Reservoir',                 5,    1017     FROM dual UNION ALL
    SELECT 'FTR',    'Fontenelle Reservoir',             5,    1018     FROM dual UNION ALL
    SELECT 'LEEF',   'Colorado River at Lees Ferry',     6,    1021     FROM dual UNION ALL
    SELECT 'CISC',   'Colorado River near Cisco',        6,    1022     FROM dual UNION ALL
    SELECT 'GRUT',   'Green River at Green River UT',    6,    1023     FROM dual UNION ALL
    SELECT 'BLUF',   'San Juan River near Bluff',        6,    1024     FROM dual
  ) LOOP
    MERGE INTO ref_hm_site t USING (SELECT r.c c FROM dual) s ON (t.hm_site_code = s.c)
    WHEN NOT MATCHED THEN INSERT (hm_site_code, hm_site_name) VALUES (r.c, r.nm);

    MERGE INTO ref_hm_site_hdbid t USING (SELECT r.c c, r.ot ot FROM dual) s
    ON (t.hm_site_code = s.c AND t.objecttype_id = s.ot)
    WHEN NOT MATCHED THEN INSERT (hm_site_code, objecttype_id, site_id) VALUES (r.c, r.ot, r.sid);
  END LOOP;

  FOR r IN (
    SELECT 'FB' pc, 'Forebay Elevation' nm,    1 u,  1 sc FROM dual UNION ALL
    SELECT 'AF',    'Reservoir Storage',       3,    1    FROM dual UNION ALL
    SELECT 'IN',    'Reservoir Inflow',        4,    1    FROM dual UNION ALL
    SELECT 'QU',    'Total Dam Release',       4,    1    FROM dual UNION ALL
    SELECT 'QP',    'Turbine Power Release',   4,    1    FROM dual UNION ALL
    SELECT 'QS',    'Spillway Release',        4,    1    FROM dual UNION ALL
    SELECT 'QD',    'Streamgage Discharge',    4,    1    FROM dual UNION ALL
    SELECT 'GH',    'Streamgage Stage',        1,    1    FROM dual UNION ALL
    SELECT 'TW',    'Water Temperature',       22,   1    FROM dual UNION ALL
    SELECT 'EV',    'Reservoir Evaporation',   3,    1    FROM dual
  ) LOOP
    MERGE INTO ref_hm_pcode t USING (SELECT r.pc pc FROM dual) s ON (t.hm_pcode = s.pc)
    WHEN NOT MATCHED THEN INSERT (hm_pcode, hm_pcode_name, unit_id, scale) VALUES (r.pc, r.nm, r.u, r.sc);
  END LOOP;

  FOR r IN (
    SELECT 'FB' pc, 5 ot FROM dual UNION ALL SELECT 'AF', 5 FROM dual UNION ALL
    SELECT 'IN',    5    FROM dual UNION ALL SELECT 'QU', 5 FROM dual UNION ALL
    SELECT 'QP',    5    FROM dual UNION ALL SELECT 'QS', 5 FROM dual UNION ALL
    SELECT 'EV',    5    FROM dual UNION ALL SELECT 'TW', 5 FROM dual UNION ALL
    SELECT 'QD',    6    FROM dual UNION ALL SELECT 'GH', 6 FROM dual UNION ALL
    SELECT 'TW',    6    FROM dual
  ) LOOP
    MERGE INTO ref_hm_pcode_objecttype t USING (SELECT r.pc pc, r.ot ot FROM dual) s
    ON (t.hm_pcode = s.pc AND t.objecttype_id = s.ot)
    WHEN NOT MATCHED THEN INSERT (hm_pcode, objecttype_id) VALUES (r.pc, r.ot);
  END LOOP;

  -- REF_HM_SITE_DATATYPE (honoring HM_HOURLY_DAILY_VALID trigger)
  FOR r IN (
    SELECT 2001 sdi, 'Y' h, 'Y' d, 'N' w, 'Y' cr, 'N' hd FROM dual UNION ALL
    SELECT 2002,     'N',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2003,     'N',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2005,     'Y',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2015,     'Y',   'Y',   'N',   'N',    'N'    FROM dual UNION ALL
    SELECT 2016,     'N',   'Y',   'N',   'N',    'N'    FROM dual UNION ALL
    SELECT 2018,     'Y',   'Y',   'N',   'N',    'N'    FROM dual UNION ALL
    SELECT 2025,     'Y',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2026,     'N',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2029,     'Y',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2032,     'N',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2046,     'N',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2063,     'Y',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2069,     'Y',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2073,     'Y',   'Y',   'N',   'Y',    'N'    FROM dual UNION ALL
    SELECT 2076,     'N',   'Y',   'N',   'Y',    'N'    FROM dual
  ) LOOP
    MERGE INTO ref_hm_site_datatype t USING (SELECT r.sdi sdi FROM dual) s ON (t.site_datatype_id = s.sdi)
    WHEN NOT MATCHED THEN INSERT (
      site_datatype_id, hourly, daily, weekly, crsp, hourly_delete,
      max_hourly_date, max_daily_date, cutoff_minute, hour_offset
    ) VALUES (
      r.sdi, r.h, r.d, r.w, r.cr, r.hd,
      CASE WHEN r.h = 'Y' THEN DATE '2025-09-30' ELSE NULL END,
      CASE WHEN r.d = 'Y' THEN DATE '2025-09-30' ELSE NULL END,
      15, 0
    );
  END LOOP;

  FOR r IN (
    SELECT 'GLDA' sc, 'FB' pc, 'D' ft, 2001 sdi FROM dual UNION ALL
    SELECT 'GLDA',    'AF',    'D',    2002     FROM dual UNION ALL
    SELECT 'GLDA',    'IN',    'D',    2003     FROM dual UNION ALL
    SELECT 'GLDA',    'QU',    'D',    2005     FROM dual UNION ALL
    SELECT 'GLDA',    'QP',    'D',    2006     FROM dual UNION ALL
    SELECT 'GLDA',    'EV',    'A',    2009     FROM dual UNION ALL
    SELECT 'HOOV',    'FB',    'D',    2015     FROM dual UNION ALL
    SELECT 'HOOV',    'AF',    'D',    2016     FROM dual UNION ALL
    SELECT 'HOOV',    'QU',    'D',    2018     FROM dual UNION ALL
    SELECT 'FGR',     'FB',    'D',    2025     FROM dual UNION ALL
    SELECT 'FGR',     'AF',    'D',    2026     FROM dual UNION ALL
    SELECT 'FGR',     'QU',    'D',    2029     FROM dual UNION ALL
    SELECT 'BMR',     'FB',    'D',    2032     FROM dual UNION ALL
    SELECT 'BMR',     'AF',    'D',    2033     FROM dual UNION ALL
    SELECT 'NAV',     'FB',    'D',    2046     FROM dual UNION ALL
    SELECT 'NAV',     'AF',    'D',    2047     FROM dual UNION ALL
    SELECT 'LEEF',    'QD',    'D',    2063     FROM dual UNION ALL
    SELECT 'LEEF',    'GH',    'D',    2064     FROM dual UNION ALL
    SELECT 'LEEF',    'TW',    'D',    2065     FROM dual UNION ALL
    SELECT 'CISC',    'QD',    'D',    2069     FROM dual UNION ALL
    SELECT 'GRUT',    'QD',    'D',    2073     FROM dual UNION ALL
    SELECT 'BLUF',    'QD',    'D',    2076     FROM dual
  ) LOOP
    MERGE INTO ref_hm_site_pcode t USING (
      SELECT r.sc sc, r.pc pc, r.ft ft FROM dual
    ) s ON (t.hm_site_code = s.sc AND t.hm_pcode = s.pc AND t.hm_filetype = s.ft)
    WHEN NOT MATCHED THEN INSERT (hm_site_code, hm_pcode, hm_filetype, site_datatype_id)
    VALUES (r.sc, r.pc, r.ft, r.sdi);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 6. DMI Unit Map, App Data Sources, Loading App Props, Legends, CG_REF_CODES, TSDB_PROPERTY
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 'feet' pr,        1 u,  1 sc FROM dual UNION ALL
    SELECT 'meters',         13,   1    FROM dual UNION ALL
    SELECT 'inches',         14,   1    FROM dual UNION ALL
    SELECT 'acre',           2,    1    FROM dual UNION ALL
    SELECT 'acre-ft',        3,    1    FROM dual UNION ALL
    SELECT 'kaf',            18,   1000 FROM dual UNION ALL
    SELECT 'cfs',            4,    1    FROM dual UNION ALL
    SELECT 'cms',            20,   1    FROM dual UNION ALL
    SELECT 'acre-ft/day',    21,   1    FROM dual UNION ALL
    SELECT 'degF',           5,    1    FROM dual UNION ALL
    SELECT 'degC',           22,   1    FROM dual UNION ALL
    SELECT 'MW',             6,    1    FROM dual UNION ALL
    SELECT 'MWh',            7,    1    FROM dual UNION ALL
    SELECT 'GWh',            23,   1000 FROM dual
  ) LOOP
    MERGE INTO hdb_dmi_unit_map t USING (SELECT r.pr pr, r.u u FROM dual) s
    ON (t.pr_unit_name = s.pr AND t.unit_id = s.u)
    WHEN NOT MATCHED THEN INSERT (pr_unit_name, unit_id, scale) VALUES (r.pr, r.u, r.sc);
  END LOOP;

  FOR r IN (
    SELECT 'decodes_rt' ex,     1 src FROM dual UNION ALL
    SELECT 'usgs_nwis_loader',  2     FROM dual UNION ALL
    SELECT 'hydromet_daily',    3     FROM dual UNION ALL
    SELECT 'poet_web',          4     FROM dual UNION ALL
    SELECT 'cbrfc_esp_ingest',  5     FROM dual UNION ALL
    SELECT 'riverware_dmi',     6     FROM dual UNION ALL
    SELECT 'snotel_daily',      7     FROM dual UNION ALL
    SELECT 'wapa_gen_loader',   8     FROM dual UNION ALL
    SELECT 'cp_daemon',         9     FROM dual UNION ALL
    SELECT 'stat_rollup_job',   10    FROM dual
  ) LOOP
    MERGE INTO ref_app_data_source t USING (SELECT r.ex ex FROM dual) s ON (t.executable_name = s.ex)
    WHEN NOT MATCHED THEN INSERT (executable_name, source_id) VALUES (r.ex, r.src);
  END LOOP;

  FOR r IN (
    SELECT 1 app, 'appType' k,            'RoutingScheduler' v FROM dual UNION ALL
    SELECT 1,     'defaultTimezone',      'MST' FROM dual UNION ALL
    SELECT 1,     'maxDecodeThreads',     '4'   FROM dual UNION ALL
    SELECT 2,     'appType',              'ComputationProcess' FROM dual UNION ALL
    SELECT 2,     'pollIntervalSec',      '30'  FROM dual UNION ALL
    SELECT 2,     'maxCompRetries',       '3'   FROM dual UNION ALL
    SELECT 2,     'commitBatchSize',      '250' FROM dual UNION ALL
    SELECT 3,     'appType',              'ManualEditor' FROM dual UNION ALL
    SELECT 3,     'requireCommentOnEdit', 'true' FROM dual UNION ALL
    SELECT 4,     'serviceEndpoint',      'https://waterservices.usgs.gov/nwis/' FROM dual UNION ALL
    SELECT 4,     'lookbackHours',        '48'  FROM dual UNION ALL
    SELECT 5,     'awdbRegion',           'CO-UT-WY' FROM dual UNION ALL
    SELECT 6,     'modelSuite',           'CRSS-MTOM-24MS' FROM dual UNION ALL
    SELECT 7,     'archiveRoot',          '/data/hydromet/uc' FROM dual UNION ALL
    SELECT 8,     'appType',              'AlarmMonitor' FROM dual UNION ALL
    SELECT 8,     'smtpEnabled',          'false' FROM dual UNION ALL
    SELECT 8,     'alarmEvalIntervalSec', '60'  FROM dual UNION ALL
    SELECT 9,     'scadaPollIntervalSec', '300' FROM dual
  ) LOOP
    MERGE INTO ref_loading_application_prop t USING (SELECT r.app app, r.k k FROM dual) s
    ON (t.loading_application_id = s.app AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (loading_application_id, prop_name, prop_value)
    VALUES (r.app, r.k, r.v);
  END LOOP;

  FOR r IN (
    SELECT 'GREEN' c,  'Validated normal operational value' d FROM dual UNION ALL
    SELECT 'BLUE',     'Approved published hydrological record' FROM dual UNION ALL
    SELECT 'YELLOW',   'Warning: value outside expected bounds (H/L)' FROM dual UNION ALL
    SELECT 'RED',      'Critical / Failed validation cutoff (F)' FROM dual UNION ALL
    SELECT 'ORANGE',   'Manual overwrite active (O)' FROM dual UNION ALL
    SELECT 'PURPLE',   'Estimated or interpolated gap-fill value (E)' FROM dual UNION ALL
    SELECT 'GRAY',     'Unvalidated raw observation (Z)' FROM dual UNION ALL
    SELECT 'CYAN',     'Modeled forecast or operational schedule' FROM dual
  ) LOOP
    MERGE INTO ref_legend t USING (SELECT r.c c FROM dual) s ON (t.color = s.c)
    WHEN NOT MATCHED THEN INSERT (color, description) VALUES (r.c, r.d);
  END LOOP;

  FOR r IN (
    SELECT 'YES_NO' dom,      'Y' lv, 'Yes' ab, 'Affirmative' mn FROM dual UNION ALL
    SELECT 'YES_NO',          'N',    'No',     'Negative' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'V',    'VAL',    'Validated within expected limits' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'Z',    'RAW',    'Unvalidated raw value' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'F',    'FAIL',   'Failed cutoff validation' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'H',    'HIGH',   'Above expected maximum' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'L',    'LOW',    'Below expected minimum' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'E',    'EST',    'Estimated value' FROM dual UNION ALL
    SELECT 'VALIDATION_FLAG', 'A',    'APPR',   'Approved published record' FROM dual UNION ALL
    SELECT 'ALLOW_INTERVAL',  'instant',     'INST', 'Instantaneous only' FROM dual UNION ALL
    SELECT 'ALLOW_INTERVAL',  'non-instant', 'NINST','Aggregated intervals only' FROM dual UNION ALL
    SELECT 'ALLOW_INTERVAL',  'either',      'BOTH', 'Instantaneous or aggregated' FROM dual UNION ALL
    SELECT 'TABLE_SELECTOR',  'R_',          'REAL', 'Real / Observed time series' FROM dual UNION ALL
    SELECT 'TABLE_SELECTOR',  'M_',          'MOD',  'Modeled / Forecast time series' FROM dual UNION ALL
    SELECT 'INSTALL_TYPE',    'master',      'MSTR', 'Master metadata database' FROM dual UNION ALL
    SELECT 'INSTALL_TYPE',    'snapshot',    'SNAP', 'Snapshot replica database' FROM dual UNION ALL
    SELECT 'INSTALL_TYPE',    'island',      'ISLD', 'Standalone island database' FROM dual UNION ALL
    SELECT 'OPS_TIER',        'NORMAL',      'NORM', 'Normal Lake Powell / Mead operations' FROM dual UNION ALL
    SELECT 'OPS_TIER',        'TIER1',       'T1',   'Lower Basin Tier 1 shortage' FROM dual UNION ALL
    SELECT 'OPS_TIER',        'TIER2A',      'T2A',  'Lower Basin Tier 2a shortage' FROM dual
  ) LOOP
    MERGE INTO cg_ref_codes t USING (SELECT r.dom dom, r.lv lv FROM dual) s
    ON (t.rv_domain = s.dom AND t.rv_low_value = s.lv)
    WHEN NOT MATCHED THEN INSERT (rv_domain, rv_low_value, rv_high_value, rv_abbreviation, rv_meaning)
    VALUES (r.dom, r.lv, NULL, r.ab, r.mn);
  END LOOP;

  FOR r IN (
    SELECT 'dbType' k,             'HDB' v FROM dual UNION ALL
    SELECT 'basinName',            'Colorado River Basin' FROM dual UNION ALL
    SELECT 'defaultTimeZone',      'MST' FROM dual UNION ALL
    SELECT 'waterYearStartMonth',  '10'  FROM dual UNION ALL
    SELECT 'preferredSiteNameType','hdb' FROM dual UNION ALL
    SELECT 'preferredUnitSystem',  'English' FROM dual UNION ALL
    SELECT 'cpDaemonEnabled',      'true' FROM dual UNION ALL
    SELECT 'alarmDaemonEnabled',   'true' FROM dual UNION ALL
    SELECT 'decodesVersion',       '6.4'  FROM dual UNION ALL
    SELECT 'seedDatasetName',      'Colorado_River_Sample_v1' FROM dual
  ) LOOP
    MERGE INTO tsdb_property t USING (SELECT r.k k FROM dual) s ON (t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (prop_name, prop_value) VALUES (r.k, r.v);
  END LOOP;

  populate_pk.SET_PRE_POPULATED(1);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] External mappings, Hydromet tables, and application metadata seeded.');
EXCEPTION
  WHEN OTHERS THEN
    populate_pk.SET_PRE_POPULATED(1);
    ROLLBACK;
    RAISE;
END;
/
