-- =============================================================================
-- 01_core_lookup_reference.sql
-- Populates core HDB lookup, domain, unit, datatype, feature, attribute,
-- property, river, model, and method reference tables in topological order.
--
-- Idempotent: Uses MERGE (insert-only when not matched) with deterministic IDs
-- via ${hdb_user}.populate_pk.SET_PRE_POPULATED(0). Never overwrites existing data.
-- =============================================================================

PROMPT [01] Seeding core HDB lookup and reference tables...

ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};

DECLARE
  v_cnt NUMBER;

  PROCEDURE add_dim(p_id NUMBER, p_name VARCHAR2) IS
  BEGIN
    MERGE INTO hdb_dimension t USING (SELECT p_id id FROM dual) s ON (t.dimension_id = s.id)
    WHEN NOT MATCHED THEN INSERT (dimension_id, dimension_name) VALUES (p_id, p_name);
  END;

  PROCEDURE add_unit(
    p_id NUMBER, p_name VARCHAR2, p_cname VARCHAR2, p_dim NUMBER, p_base NUMBER,
    p_my CHAR, p_omy CHAR, p_isf NUMBER, p_mult FLOAT,
    p_from VARCHAR2, p_to VARCHAR2, p_fam VARCHAR2
  ) IS
  BEGIN
    MERGE INTO hdb_unit t USING (SELECT p_id id FROM dual) s ON (t.unit_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      unit_id, unit_name, unit_common_name, dimension_id, base_unit_id,
      month_year, over_month_year, is_factor, mult_factor,
      from_stored_expression, to_stored_expression, family
    ) VALUES (
      p_id, p_name, p_cname, p_dim, p_base,
      p_my, p_omy, p_isf, p_mult,
      p_from, p_to, p_fam
    );
  END;

  PROCEDURE add_pq(p_name VARCHAR2, p_dim NUMBER, p_unit NUMBER) IS
  BEGIN
    MERGE INTO hdb_physical_quantity t USING (SELECT p_name nm FROM dual) s ON (t.physical_quantity_name = s.nm)
    WHEN NOT MATCHED THEN INSERT (physical_quantity_name, dimension_id, customary_unit_id) VALUES (p_name, p_dim, p_unit);
  END;

  PROCEDURE add_agen(p_id NUMBER, p_name VARCHAR2, p_abbr VARCHAR2) IS
  BEGIN
    MERGE INTO hdb_agen t USING (SELECT p_id id FROM dual) s ON (t.agen_id = s.id)
    WHEN NOT MATCHED THEN INSERT (agen_id, agen_name, agen_abbrev) VALUES (p_id, p_name, p_abbr);
  END;

  PROCEDURE add_state(p_id NUMBER, p_code VARCHAR2, p_name VARCHAR2) IS
  BEGIN
    MERGE INTO hdb_state t USING (SELECT p_id id FROM dual) s ON (t.state_id = s.id)
    WHEN NOT MATCHED THEN INSERT (state_id, state_code, state_name) VALUES (p_id, p_code, p_name);
  END;

  PROCEDURE add_dt(
    p_id NUMBER, p_name VARCHAR2, p_cname VARCHAR2, p_pq VARCHAR2,
    p_unit NUMBER, p_int VARCHAR2, p_agen NUMBER, p_cmmnt VARCHAR2
  ) IS
  BEGIN
    MERGE INTO hdb_datatype t USING (SELECT p_id id FROM dual) s ON (t.datatype_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      datatype_id, datatype_name, datatype_common_name, physical_quantity_name,
      unit_id, allowable_intervals, agen_id, cmmnt
    ) VALUES (
      p_id, p_name, p_cname, p_pq, p_unit, p_int, p_agen, p_cmmnt
    );
  END;
BEGIN
  populate_pk.SET_PRE_POPULATED(0);

  -- ---------------------------------------------------------------------------
  -- 1. Installation & Database Metadata
  -- ---------------------------------------------------------------------------
  SELECT COUNT(*) INTO v_cnt FROM ref_installation;
  IF v_cnt = 0 THEN
    INSERT INTO ref_installation (meta_data_installation_type) VALUES ('island');
  END IF;

  MERGE INTO ref_db_list t USING (SELECT 1 id FROM dual) s ON (t.session_no = s.id)
  WHEN NOT MATCHED THEN INSERT (session_no, db_site_db_name, db_site_code, min_coord_model_run_id, max_coord_model_run_id)
  VALUES (1, 'UCHDB', 'UCH', 1000, 1999);
  MERGE INTO ref_db_list t USING (SELECT 2 id FROM dual) s ON (t.session_no = s.id)
  WHEN NOT MATCHED THEN INSERT (session_no, db_site_db_name, db_site_code, min_coord_model_run_id, max_coord_model_run_id)
  VALUES (2, 'LCHDB', 'LCH', 2000, 2999);
  MERGE INTO ref_db_list t USING (SELECT 3 id FROM dual) s ON (t.session_no = s.id)
  WHEN NOT MATCHED THEN INSERT (session_no, db_site_db_name, db_site_code, min_coord_model_run_id, max_coord_model_run_id)
  VALUES (3, 'YAOHDB', 'YAO', 3000, 3999);

  MERGE INTO ref_hdb_installation t USING (SELECT 'UCHDB' nm FROM dual) s ON (t.db_site_db_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (db_site_db_name, db_site_code, is_czar_db) VALUES ('UCHDB', 'UCH', 'Y');
  MERGE INTO ref_hdb_installation t USING (SELECT 'LCHDB' nm FROM dual) s ON (t.db_site_db_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (db_site_db_name, db_site_code, is_czar_db) VALUES ('LCHDB', 'LCH', 'N');
  MERGE INTO ref_hdb_installation t USING (SELECT 'YAOHDB' nm FROM dual) s ON (t.db_site_db_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (db_site_db_name, db_site_code, is_czar_db) VALUES ('YAOHDB', 'YAO', 'N');

  MERGE INTO ref_phys_quan_refresh_monitor t USING (SELECT 'UCHDB' nm FROM dual) s ON (t.db_site_db_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (db_site_db_name, message, success_code) VALUES ('UCHDB', 'Standalone master installation verified', 1);
  MERGE INTO ref_phys_quan_refresh_monitor t USING (SELECT 'LCHDB' nm FROM dual) s ON (t.db_site_db_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (db_site_db_name, message, success_code) VALUES ('LCHDB', 'Remote snapshot disabled in standalone mode', 1);
  MERGE INTO ref_phys_quan_refresh_monitor t USING (SELECT 'YAOHDB' nm FROM dual) s ON (t.db_site_db_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (db_site_db_name, message, success_code) VALUES ('YAOHDB', 'Remote snapshot disabled in standalone mode', 1);

  -- ---------------------------------------------------------------------------
  -- 2. Date/Time Units & Intervals (self-referencing chain)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 'second' u, 'Seconds' c FROM dual UNION ALL
    SELECT 'minute',   'Minutes'   FROM dual UNION ALL
    SELECT 'hour',     'Hours'     FROM dual UNION ALL
    SELECT 'day',      'Calendar days' FROM dual UNION ALL
    SELECT 'week',     'Seven-day weeks' FROM dual UNION ALL
    SELECT 'month',    'Calendar months' FROM dual UNION ALL
    SELECT 'year',     'Calendar years' FROM dual UNION ALL
    SELECT 'wy',       'Water years (Oct-Sep)' FROM dual
  ) LOOP
    MERGE INTO hdb_date_time_unit t USING (SELECT r.u u FROM dual) s ON (t.date_time_unit = s.u)
    WHEN NOT MATCHED THEN INSERT (date_time_unit, cmmnt) VALUES (r.u, r.c);
  END LOOP;

  -- Insert intervals in parent-first order for PREVIOUS_INTERVAL_NAME FK
  MERGE INTO hdb_interval t USING (SELECT 'instant' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('instant', 1, NULL, 'second', 'Instantaneous point observation');
  MERGE INTO hdb_interval t USING (SELECT 'hour' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('hour', 2, 'instant', 'hour', 'Hourly interval');
  MERGE INTO hdb_interval t USING (SELECT 'day' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('day', 3, 'hour', 'day', 'Daily interval');
  MERGE INTO hdb_interval t USING (SELECT 'month' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('month', 4, 'day', 'month', 'Monthly interval');
  MERGE INTO hdb_interval t USING (SELECT 'year' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('year', 5, 'month', 'year', 'Calendar year interval');
  MERGE INTO hdb_interval t USING (SELECT 'wy' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('wy', 6, 'month', 'wy', 'Water year interval (Oct 1 - Sep 30)');
  MERGE INTO hdb_interval t USING (SELECT 'other' nm FROM dual) s ON (t.interval_name = s.nm)
  WHEN NOT MATCHED THEN INSERT (interval_name, interval_order, previous_interval_name, interval_unit, cmmnt)
  VALUES ('other', 7, NULL, 'day', 'Irregular or multi-day event interval');

  -- ---------------------------------------------------------------------------
  -- 3. Dimensions, Units (base first, then derived), Physical Quantities
  -- ---------------------------------------------------------------------------
  add_dim(1,  'Length');
  add_dim(2,  'Area');
  add_dim(3,  'Volume');
  add_dim(4,  'Flow');
  add_dim(5,  'Temperature');
  add_dim(6,  'Power');
  add_dim(7,  'Energy');
  add_dim(8,  'Velocity');
  add_dim(9,  'Concentration');
  add_dim(10, 'Conductivity');
  add_dim(11, 'Dimensionless');
  add_dim(12, 'Time');

  -- Base units (self-referencing base_unit_id = unit_id)
  add_unit(1,  'feet',                    'ft',       1,  1,  NULL, NULL, 1, 1.0,       NULL, NULL, 'English');
  add_unit(2,  'acres',                   'acre',     2,  2,  NULL, NULL, 1, 1.0,       NULL, NULL, 'English');
  add_unit(3,  'acre-feet',               'ac-ft',    3,  3,  NULL, NULL, 1, 1.0,       NULL, NULL, 'English');
  add_unit(4,  'cubic feet per second',   'cfs',      4,  4,  NULL, NULL, 1, 1.0,       NULL, NULL, 'English');
  add_unit(5,  'degrees Fahrenheit',      'degF',     5,  5,  NULL, NULL, 1, 1.0,       NULL, NULL, 'English');
  add_unit(6,  'megawatts',               'MW',       6,  6,  NULL, NULL, 1, 1.0,       NULL, NULL, 'Metric');
  add_unit(7,  'megawatt-hours',          'MWh',      7,  7,  NULL, NULL, 1, 1.0,       NULL, NULL, 'Metric');
  add_unit(8,  'feet per second',         'ft/s',     8,  8,  NULL, NULL, 1, 1.0,       NULL, NULL, 'English');
  add_unit(9,  'milligrams per liter',    'mg/L',     9,  9,  NULL, NULL, 1, 1.0,       NULL, NULL, 'Metric');
  add_unit(10, 'microsiemens per cm',     'uS/cm',    10, 10, NULL, NULL, 1, 1.0,       NULL, NULL, 'Metric');
  add_unit(11, 'percent',                 'pct',      11, 11, NULL, NULL, 1, 1.0,       NULL, NULL, 'univ');
  add_unit(12, 'seconds',                 'sec',      12, 12, NULL, NULL, 1, 1.0,       NULL, NULL, 'univ');

  -- Derived units
  add_unit(13, 'meters',                  'm',        1,  1,  NULL, NULL, 1, 3.28084,   NULL, NULL, 'Metric');
  add_unit(14, 'inches',                  'in',       1,  1,  NULL, NULL, 1, 0.083333,  NULL, NULL, 'English');
  add_unit(15, 'millimeters',             'mm',       1,  1,  NULL, NULL, 1, 0.003281,  NULL, NULL, 'Metric');
  add_unit(16, 'miles',                   'mi',       1,  1,  NULL, NULL, 1, 5280.0,    NULL, NULL, 'English');
  add_unit(17, 'square miles',            'mi2',      2,  2,  NULL, NULL, 1, 640.0,     NULL, NULL, 'English');
  add_unit(18, 'thousand acre-feet',      'kaf',      3,  3,  NULL, NULL, 1, 1000.0,    NULL, NULL, 'English');
  add_unit(19, 'cubic meters',            'm3',       3,  3,  NULL, NULL, 1, 0.0008107, NULL, NULL, 'Metric');
  add_unit(20, 'cubic meters per second', 'cms',      4,  4,  NULL, NULL, 1, 35.31467,  NULL, NULL, 'Metric');
  add_unit(21, 'acre-feet per day',       'af/d',     4,  4,  NULL, NULL, 1, 0.504167,  NULL, NULL, 'English');
  add_unit(22, 'degrees Celsius',         'degC',     5,  5,  NULL, NULL, 0, NULL,      '((x - 32) * 5 / 9)', '((x * 9 / 5) + 32)', 'Metric');
  add_unit(23, 'gigawatt-hours',          'GWh',      7,  7,  NULL, NULL, 1, 1000.0,    NULL, NULL, 'Metric');
  add_unit(24, 'hours',                   'hr',       12, 12, NULL, NULL, 1, 3600.0,    NULL, NULL, 'univ');
  add_unit(25, 'NTU turbidity',           'NTU',      11, 11, NULL, NULL, 1, 1.0,       NULL, NULL, 'univ');

  -- Physical quantities (customary unit matches primary datatype unit)
  add_pq('elevation',              1,  1);
  add_pq('stage',                  1,  1);
  add_pq('precipitation',          1,  14);
  add_pq('snow water equivalent',  1,  14);
  add_pq('evaporation',            1,  14);
  add_pq('head',                   1,  1);
  add_pq('surface area',           2,  2);
  add_pq('storage',                3,  3);
  add_pq('volume',                 3,  3);
  add_pq('flow',                   4,  4);
  add_pq('air temperature',        5,  5);
  add_pq('water temperature',      5,  22);
  add_pq('power',                  6,  6);
  add_pq('energy',                 7,  7);
  add_pq('velocity',               8,  8);
  add_pq('dissolved oxygen',       9,  9);
  add_pq('specific conductance',   10, 10);
  add_pq('turbidity',              11, 25);

  -- ---------------------------------------------------------------------------
  -- 4. Agencies, States, USBR Offices, Dam/Div/Gage/Object Types
  -- ---------------------------------------------------------------------------
  add_agen(1,  'U.S. Bureau of Reclamation',                   'USBR');
  add_agen(2,  'U.S. Geological Survey',                       'USGS');
  add_agen(3,  'National Weather Service CBRFC',               'NWS');
  add_agen(4,  'Natural Resources Conservation Service',       'NRCS');
  add_agen(5,  'U.S. Army Corps of Engineers',                 'USACE');
  add_agen(6,  'Western Area Power Administration',            'WAPA');
  add_agen(7,  'Colorado Water Conservation Board',            'CWCB');
  add_agen(8,  'Utah Division of Water Resources',             'UDWR');
  add_agen(9,  'Arizona Department of Water Resources',        'ADWR');
  add_agen(10, 'International Boundary and Water Commission',  'IBWC');
  add_agen(11, 'Central Arizona Water Conservation District',  'CAWCD');
  add_agen(12, 'Metropolitan Water District of So. Calif.',    'MWD');

  add_state(1,  'CO', 'Colorado');
  add_state(2,  'UT', 'Utah');
  add_state(3,  'WY', 'Wyoming');
  add_state(4,  'NM', 'New Mexico');
  add_state(5,  'AZ', 'Arizona');
  add_state(6,  'NV', 'Nevada');
  add_state(7,  'CA', 'California');
  add_state(8,  'ID', 'Idaho');
  add_state(9,  'MT', 'Montana');
  add_state(10, 'NE', 'Nebraska');

  FOR r IN (
    SELECT 1 id, 'Upper Colorado Basin Regional Office - Salt Lake City' nm FROM dual UNION ALL
    SELECT 2, 'Lower Colorado Basin Regional Office - Boulder City'      FROM dual UNION ALL
    SELECT 3, 'Western Colorado Area Office - Grand Junction'            FROM dual UNION ALL
    SELECT 4, 'Provo Area Office - Provo'                                FROM dual UNION ALL
    SELECT 5, 'Albuquerque Area Office - Albuquerque'                    FROM dual UNION ALL
    SELECT 6, 'Phoenix Area Office - Glendale'                           FROM dual UNION ALL
    SELECT 7, 'Yuma Area Office - Yuma'                                  FROM dual UNION ALL
    SELECT 8, 'Denver Technical Service Center - Lakewood'               FROM dual
  ) LOOP
    MERGE INTO hdb_usbr_off t USING (SELECT r.id id FROM dual) s ON (t.off_id = s.id)
    WHEN NOT MATCHED THEN INSERT (off_id, off_name) VALUES (r.id, r.nm);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'Concrete Arch' nm FROM dual UNION ALL
    SELECT 2, 'Concrete Arch-Gravity' FROM dual UNION ALL
    SELECT 3, 'Concrete Gravity'      FROM dual UNION ALL
    SELECT 4, 'Zoned Earthfill'       FROM dual UNION ALL
    SELECT 5, 'Earth and Rockfill'    FROM dual UNION ALL
    SELECT 6, 'Diversion Weir'        FROM dual UNION ALL
    SELECT 7, 'Roller-Compacted Concrete' FROM dual UNION ALL
    SELECT 8, 'Composite Concrete/Earth'  FROM dual
  ) LOOP
    MERGE INTO hdb_damtype t USING (SELECT r.id id FROM dual) s ON (t.damtype_id = s.id)
    WHEN NOT MATCHED THEN INSERT (damtype_id, damtype_name) VALUES (r.id, r.nm);
  END LOOP;

  FOR r IN (
    SELECT 'I' c, 'Irrigation' nm FROM dual UNION ALL
    SELECT 'M', 'Municipal'       FROM dual UNION ALL
    SELECT 'P', 'Power'           FROM dual UNION ALL
    SELECT 'T', 'Transbasin'      FROM dual UNION ALL
    SELECT 'E', 'Environ'         FROM dual
  ) LOOP
    MERGE INTO hdb_divtype t USING (SELECT r.c c FROM dual) s ON (t.divtype = s.c)
    WHEN NOT MATCHED THEN INSERT (divtype, divtype_name) VALUES (r.c, r.nm);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'Nitrogen Bubbler Pressure' nm FROM dual UNION ALL
    SELECT 2, 'Non-Contact Radar Stage'         FROM dual UNION ALL
    SELECT 3, 'Acoustic Doppler Velocity Meter' FROM dual UNION ALL
    SELECT 4, 'Stilling Well Shaft Encoder'     FROM dual UNION ALL
    SELECT 5, 'Submersible Pressure Transducer' FROM dual UNION ALL
    SELECT 6, 'Manual Staff Gage'               FROM dual
  ) LOOP
    MERGE INTO hdb_gagetype t USING (SELECT r.id id FROM dual) s ON (t.gagetype_id = s.id)
    WHEN NOT MATCHED THEN INSERT (gagetype_id, gagetype_name) VALUES (r.id, r.nm);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'basin' nm,           'bas' tag,  1 ord FROM dual UNION ALL
    SELECT 2,    'subbasin',           'sbas',     2     FROM dual UNION ALL
    SELECT 3,    'river',              'riv',      3     FROM dual UNION ALL
    SELECT 4,    'reach',              'rch',      4     FROM dual UNION ALL
    SELECT 5,    'reservoir',          'res',      5     FROM dual UNION ALL
    SELECT 6,    'streamgage',         'str',      6     FROM dual UNION ALL
    SELECT 7,    'diversion',          'div',      7     FROM dual UNION ALL
    SELECT 8,    'powerplant',         'pwr',      8     FROM dual UNION ALL
    SELECT 9,    'station',            'sta',      9     FROM dual UNION ALL
    SELECT 10,   'canal',              'can',      10    FROM dual UNION ALL
    SELECT 11,   'snotel',             'snot',     11    FROM dual UNION ALL
    SELECT 12,   'weather station',    'wx',       12    FROM dual
  ) LOOP
    MERGE INTO hdb_objecttype t USING (SELECT r.id id FROM dual) s ON (t.objecttype_id = s.id)
    WHEN NOT MATCHED THEN INSERT (objecttype_id, objecttype_name, objecttype_tag, objecttype_parent_order)
    VALUES (r.id, r.nm, r.tag, r.ord);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 5. Flags, Validation, Operators, Collection Systems, Data Sources, Loading Apps
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 'O' f, 'Overwrite' nm, 'Locked manual overwrite; protected from automated loaders' c FROM dual UNION ALL
    SELECT 'N',   'Normal',       'Normal automated load; eligible for updates' FROM dual UNION ALL
    SELECT 'M',   'Manual',       'Manual operational adjustment' FROM dual
  ) LOOP
    MERGE INTO hdb_overwrite_flag t USING (SELECT r.f f FROM dual) s ON (t.overwrite_flag = s.f)
    WHEN NOT MATCHED THEN INSERT (overwrite_flag, overwrite_flag_name, cmmnt) VALUES (r.f, r.nm, r.c);
  END LOOP;

  FOR r IN (
    SELECT 'V' v, 'Validated within expected operational limits' c FROM dual UNION ALL
    SELECT 'Z',   'Unvalidated raw observation pending QA/QC'      FROM dual UNION ALL
    SELECT 'F',   'Failed cutoff validation check; excluded from r_interval' FROM dual UNION ALL
    SELECT 'H',   'High warning: exceeded expected maximum but below cutoff' FROM dual UNION ALL
    SELECT 'L',   'Low warning: below expected minimum but above cutoff'     FROM dual UNION ALL
    SELECT 'E',   'Estimated value filling telemetry gap'          FROM dual UNION ALL
    SELECT 'A',   'Approved final published hydrological record'   FROM dual UNION ALL
    SELECT 'P',   'Provisional near-real-time telemetry record'    FROM dual
  ) LOOP
    MERGE INTO hdb_validation t USING (SELECT r.v v FROM dual) s ON (t.validation = s.v)
    WHEN NOT MATCHED THEN INSERT (validation, cmmnt) VALUES (r.v, r.c);
  END LOOP;

  FOR r IN (
    SELECT '+' op, 'Addition' c FROM dual UNION ALL
    SELECT '-',    'Subtraction' FROM dual UNION ALL
    SELECT '*',    'Multiplication' FROM dual UNION ALL
    SELECT '/',    'Division' FROM dual UNION ALL
    SELECT 'AVG',  'Arithmetic mean across period' FROM dual UNION ALL
    SELECT 'SUM',  'Summation across period' FROM dual
  ) LOOP
    MERGE INTO hdb_operator t USING (SELECT r.op op FROM dual) s ON (t.operator = s.op)
    WHEN NOT MATCHED THEN INSERT (operator, cmmnt) VALUES (r.op, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'GOES DCP Telemetry' nm,  'NESDIS GOES satellite DCP transmissions' c FROM dual UNION ALL
    SELECT 2,    'USBR SCADA',             'Real-time dam & powerplant SCADA polling'  FROM dual UNION ALL
    SELECT 3,    'USGS NWIS Web Service',  'Automated USGS WaterServices JSON/RDB ingest' FROM dual UNION ALL
    SELECT 4,    'NRCS SNOTEL Network',    'Meteor-burst & satellite snowpack telemetry' FROM dual UNION ALL
    SELECT 5,    'USBR Hydromet',          'Legacy Hydromet archive and daily feeds'   FROM dual UNION ALL
    SELECT 6,    'Manual Operator Log',    'Direct control room or hydrologist entry'  FROM dual UNION ALL
    SELECT 7,    'RiverWare DMI',          'RiverWare operational modeling interface'  FROM dual UNION ALL
    SELECT 8,    'NWS CBRFC Feed',         'Colorado Basin River Forecast Center ESP'  FROM dual
  ) LOOP
    MERGE INTO hdb_collection_system t USING (SELECT r.id id FROM dual) s ON (t.collection_system_id = s.id)
    WHEN NOT MATCHED THEN INSERT (collection_system_id, collection_system_name, cmmnt) VALUES (r.id, r.nm, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'SCADA Real-Time' nm,       'Direct USBR SCADA operational telemetry' c FROM dual UNION ALL
    SELECT 2,    'USGS Real-Time Gage',      'USGS instantaneous & daily streamflow feeds' FROM dual UNION ALL
    SELECT 3,    'Hydromet Daily Feed',      'Automated Hydromet daily ingestion' FROM dual UNION ALL
    SELECT 4,    'Operator Manual Entry',    'Dam operator or hydrologist entry via POET' FROM dual UNION ALL
    SELECT 5,    'CBRFC Ensemble Forecast',  'NWS CBRFC inflow forecast traces' FROM dual UNION ALL
    SELECT 6,    'RiverWare Operations',     'Modeled operational schedule outputs' FROM dual UNION ALL
    SELECT 7,    'NRCS SNOTEL Telemetry',    'Snow water equivalent and precip sensors' FROM dual UNION ALL
    SELECT 8,    'WAPA Generation Dispatch', 'Hydroelectric generation and energy logs' FROM dual UNION ALL
    SELECT 9,    'Computation Processor',    'Derived series generated by OpenDCS CP' FROM dual UNION ALL
    SELECT 10,   'QA/QC Statistical Archive','Validated historical period-of-record stats' FROM dual
  ) LOOP
    MERGE INTO hdb_data_source t USING (SELECT r.id id FROM dual) s ON (t.source_id = s.id)
    WHEN NOT MATCHED THEN INSERT (source_id, source_name, cmmnt) VALUES (r.id, r.nm, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'DECODES' nm,          'N' m, 'OpenDCS DECODES real-time telemetry decoder' c FROM dual UNION ALL
    SELECT 2,    'CP_DAEMON',           'N',   'OpenDCS Computation Processor daemon' FROM dual UNION ALL
    SELECT 3,    'POET',                'Y',   'HDB web/desktop manual editing & QA tool' FROM dual UNION ALL
    SELECT 4,    'USGS_NWIS_LOADER',    'N',   'Automated USGS NWIS streamflow loader' FROM dual UNION ALL
    SELECT 5,    'SNOTEL_LOADER',       'N',   'NRCS SNOTEL daily snowpack loader' FROM dual UNION ALL
    SELECT 6,    'RIVERWARE_DMI',       'N',   'RiverWare HDB Data Management Interface' FROM dual UNION ALL
    SELECT 7,    'HYDROMET_LOADER',     'N',   'USBR Hydromet archive/daily ingest daemon' FROM dual UNION ALL
    SELECT 8,    'ALARM_MONITOR',       'N',   'OpenDCS alarm screening & notification daemon' FROM dual UNION ALL
    SELECT 9,    'SCADA_BRIDGE',        'N',   'SCADA-to-HDB real-time operational bridge' FROM dual UNION ALL
    SELECT 10,   'BATCH_QA_IMPORTER',   'Y',   'Hydrologist batch correction & backfill utility' FROM dual
  ) LOOP
    MERGE INTO hdb_loading_application t USING (SELECT r.id id FROM dual) s ON (t.loading_application_id = s.id)
    WHEN NOT MATCHED THEN INSERT (loading_application_id, loading_application_name, manual_edit_app, cmmnt)
    VALUES (r.id, r.nm, r.m, r.c);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 6. Method Class Types, Method Classes, Methods
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 'OBSERVATION' t,     'Direct sensor or gage measurement' c FROM dual UNION ALL
    SELECT 'AGGREGATION',       'Temporal roll-up from finer to coarser interval' FROM dual UNION ALL
    SELECT 'DISAGGREGATION',    'Temporal breakdown from coarser to finer interval' FROM dual UNION ALL
    SELECT 'COMPUTATION',       'Hydrologic equation, mass balance, or rating lookup' FROM dual UNION ALL
    SELECT 'ESTIMATION',        'Gap-filling, interpolation, or regression estimate' FROM dual
  ) LOOP
    MERGE INTO hdb_method_class_type t USING (SELECT r.t t FROM dual) s ON (t.method_class_type = s.t)
    WHEN NOT MATCHED THEN INSERT (method_class_type, cmmnt) VALUES (r.t, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 id, 'Direct Telemetry' nm,  'Telemetry' cn,   'OBSERVATION' tp,    'Automated sensor reading' c FROM dual UNION ALL
    SELECT 2,    'Manual Reading',       'Manual',         'OBSERVATION',       'Staff gage or logbook reading' FROM dual UNION ALL
    SELECT 3,    'Time Averaging',       'Average',        'AGGREGATION',       'Arithmetic or time-weighted mean' FROM dual UNION ALL
    SELECT 4,    'Time Summation',       'Sum',            'AGGREGATION',       'Accumulated volume or energy' FROM dual UNION ALL
    SELECT 5,    'Boundary Sampling',    'EOP/BOP',        'AGGREGATION',       'End-of-period or beginning-of-period snapshot' FROM dual UNION ALL
    SELECT 6,    'Uniform Split',        'Split',          'DISAGGREGATION',    'Equal distribution over sub-intervals' FROM dual UNION ALL
    SELECT 7,    'Rating Curve Lookup',  'Rating',         'COMPUTATION',       'Table interpolation (stage-discharge, elev-storage)' FROM dual UNION ALL
    SELECT 8,    'Reservoir Balance',    'Mass Balance',   'COMPUTATION',       'Inflow = Outflow + Delta Storage + Evap' FROM dual UNION ALL
    SELECT 9,    'Linear Interpolation', 'Interp',         'ESTIMATION',        'Linear fill between valid neighbors' FROM dual UNION ALL
    SELECT 10,   'Unknown / Default',    'Unknown',        'OBSERVATION',       'Default unspecified method' FROM dual
  ) LOOP
    MERGE INTO hdb_method_class t USING (SELECT r.id id FROM dual) s ON (t.method_class_id = s.id)
    WHEN NOT MATCHED THEN INSERT (method_class_id, method_class_name, method_class_common_name, method_class_type, cmmnt)
    VALUES (r.id, r.nm, r.cn, r.tp, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 id,  'Unknown' nm,                    'Unknown' cn,        10 mc, 'Default fallback method' c FROM dual UNION ALL
    SELECT 2,     'Direct Sensor Observation',     'Direct Obs',        1,     'Unmodified telemetry reading' FROM dual UNION ALL
    SELECT 3,     'Manual Staff Observation',      'Manual Obs',        2,     'Field technician staff gage reading' FROM dual UNION ALL
    SELECT 4,     'Hourly Mean from Instant',      'Hourly Mean',       3,     'Mean of 15-min observations' FROM dual UNION ALL
    SELECT 5,     'Daily Mean from Hourly',        'Daily Mean',        3,     '24-hour arithmetic mean' FROM dual UNION ALL
    SELECT 6,     'Monthly Mean from Daily',       'Monthly Mean',      3,     'Calendar month average of daily values' FROM dual UNION ALL
    SELECT 7,     'Annual Mean from Monthly',      'Annual Mean',       3,     '12-month arithmetic average' FROM dual UNION ALL
    SELECT 8,     'Daily Sum from Hourly',         'Daily Sum',         4,     '24-hour accumulated total' FROM dual UNION ALL
    SELECT 9,     'Monthly Sum from Daily',        'Monthly Sum',       4,     'Monthly volume or energy total' FROM dual UNION ALL
    SELECT 10,    'Water Year Total',              'WY Total',          4,     'Oct-Sep cumulative runoff or generation' FROM dual UNION ALL
    SELECT 11,    'Daily End-of-Period (24:00)',   'Daily EOP',         5,     'Midnight pool elevation or storage' FROM dual UNION ALL
    SELECT 12,    'Monthly End-of-Period',         'Monthly EOP',       5,     'Last day of month pool elevation or storage' FROM dual UNION ALL
    SELECT 13,    'Stage-Discharge Rating',        'Stage-Q Rating',    7,     'Discharge computed from shifted rating table' FROM dual UNION ALL
    SELECT 14,    'Elevation-Storage Rating',      'Elev-Stor Rating',  7,     'Reservoir content from elevation-capacity table' FROM dual UNION ALL
    SELECT 15,    'Reservoir Inflow Mass Balance', 'Res Inflow Calc',   8,     'Computed inflow from release + dS + evap' FROM dual UNION ALL
    SELECT 16,    'Linear Gap Interpolation',      'Linear Interp',     9,     'Interpolated across short sensor outage' FROM dual UNION ALL
    SELECT 17,    'Uniform Daily Disaggregation',  'Uniform Split',     6,     'Monthly forecast split to daily values' FROM dual UNION ALL
    SELECT 18,    'Turbine Rating Calculation',    'Turbine Calc',      7,     'Power/release computed from head and gate' FROM dual
  ) LOOP
    MERGE INTO hdb_method t USING (SELECT r.id id FROM dual) s ON (t.method_id = s.id)
    WHEN NOT MATCHED THEN INSERT (method_id, method_name, method_common_name, method_class_id, cmmnt)
    VALUES (r.id, r.nm, r.cn, r.mc, r.c);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 7. Model Types, Models, Model Coordination
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 'O' t, 'Operational' nm FROM dual UNION ALL
    SELECT 'P',   'Planning'       FROM dual UNION ALL
    SELECT 'F',   'Forecast'       FROM dual UNION ALL
    SELECT 'H',   'Historical'     FROM dual UNION ALL
    SELECT 'S',   'Sensitivity Study' FROM dual
  ) LOOP
    MERGE INTO hdb_modeltype t USING (SELECT r.t t FROM dual) s ON (t.modeltype = s.t)
    WHEN NOT MATCHED THEN INSERT (modeltype, modeltype_name) VALUES (r.t, r.nm);
  END LOOP;

  FOR r IN (
    SELECT 1 id,  'CRSS' nm,                       'Y' crd, 'Colorado River Simulation System long-term planning model' c FROM dual UNION ALL
    SELECT 2,     'MTOM',                          'Y',     'Mid-Term Probabilistic Operations Model (5-year)' FROM dual UNION ALL
    SELECT 3,     '24-Month Study',                'Y',     'Official monthly USBR 24-Month operational projection' FROM dual UNION ALL
    SELECT 4,     'CBRFC ESP Forecast',            'N',     'NWS Colorado Basin River Forecast Center ensemble traces' FROM dual UNION ALL
    SELECT 5,     'Upper Basin Daily Ops',         'N',     'Daily RiverWare operational scheduling for Upper Basin' FROM dual UNION ALL
    SELECT 6,     'Glen Canyon Hourly Schedule',   'N',     'Hourly turbine release & WAPA peaking schedule' FROM dual UNION ALL
    SELECT 7,     'Flaming Gorge BiOp Ops',        'N',     'Green River endangered fish spring peak flow model' FROM dual UNION ALL
    SELECT 8,     'San Juan Recovery Ops',         'N',     'Navajo Dam release model for San Juan River recovery' FROM dual UNION ALL
    SELECT 9,     'Aspinall Unit Daily Model',     'N',     'Gunnison River Blue Mesa/Morrow Point/Crystal ops' FROM dual UNION ALL
    SELECT 10,    'Lower Basin Water Accounting',  'Y',     'Lake Mead-Mohave-Havasu diversion & delivery model' FROM dual
  ) LOOP
    MERGE INTO hdb_model t USING (SELECT r.id id FROM dual) s ON (t.model_id = s.id)
    WHEN NOT MATCHED THEN INSERT (model_id, model_name, coordinated, cmmnt) VALUES (r.id, r.nm, r.crd, r.c);
  END LOOP;

  FOR r IN (
    SELECT 1 m, 'UCH' db FROM dual UNION ALL SELECT 1, 'LCH' FROM dual UNION ALL SELECT 1, 'YAO' FROM dual UNION ALL
    SELECT 2,   'UCH'    FROM dual UNION ALL SELECT 2, 'LCH' FROM dual UNION ALL
    SELECT 3,   'UCH'    FROM dual UNION ALL SELECT 3, 'LCH' FROM dual UNION ALL SELECT 3, 'YAO' FROM dual UNION ALL
    SELECT 10,  'UCH'    FROM dual UNION ALL SELECT 10, 'LCH' FROM dual UNION ALL SELECT 10, 'YAO' FROM dual
  ) LOOP
    MERGE INTO hdb_model_coord t USING (SELECT r.m m, r.db db FROM dual) s
    ON (t.model_id = s.m AND t.db_site_code = s.db)
    WHEN NOT MATCHED THEN INSERT (model_id, db_site_code) VALUES (r.m, r.db);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 8. Rivers & River Reaches
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'Colorado River' nm FROM dual UNION ALL
    SELECT 2,    'Green River'       FROM dual UNION ALL
    SELECT 3,    'San Juan River'    FROM dual UNION ALL
    SELECT 4,    'Gunnison River'    FROM dual UNION ALL
    SELECT 5,    'Yampa River'       FROM dual UNION ALL
    SELECT 6,    'White River'       FROM dual UNION ALL
    SELECT 7,    'Dolores River'     FROM dual UNION ALL
    SELECT 8,    'Virgin River'      FROM dual UNION ALL
    SELECT 9,    'Little Colorado River' FROM dual UNION ALL
    SELECT 10,   'Gila River'        FROM dual
  ) LOOP
    MERGE INTO hdb_river t USING (SELECT r.id id FROM dual) s ON (t.river_id = s.id)
    WHEN NOT MATCHED THEN INSERT (river_id, river_name) VALUES (r.id, r.nm);
  END LOOP;

  FOR r IN (
    SELECT '14010001' huc, 1 seg, 1 riv FROM dual UNION ALL -- Upper Colorado Headwaters
    SELECT '14010005',     2,     1     FROM dual UNION ALL -- Colorado-Plateau (Cameo/Grand Junction)
    SELECT '14030005',     3,     1     FROM dual UNION ALL -- Upper Colorado-Kane Springs (Cisco)
    SELECT '14070006',     4,     1     FROM dual UNION ALL -- Lower Lake Powell / Glen Canyon / Lees Ferry
    SELECT '15010001',     5,     1     FROM dual UNION ALL -- Lower Colorado-Lake Mead
    SELECT '15010002',     6,     1     FROM dual UNION ALL -- Grand Canyon / Diamond Creek
    SELECT '15030101',     7,     1     FROM dual UNION ALL -- Havasu-Mohave Lakes
    SELECT '15030104',     8,     1     FROM dual UNION ALL -- Imperial Reservoir / Yuma
    SELECT '14040101',     1,     2     FROM dual UNION ALL -- Upper Green (Fontenelle)
    SELECT '14040106',     2,     2     FROM dual UNION ALL -- Upper Green-Flaming Gorge
    SELECT '14060008',     3,     2     FROM dual UNION ALL -- Lower Green (Green River UT)
    SELECT '14080101',     1,     3     FROM dual UNION ALL -- Upper San Juan (Navajo)
    SELECT '14080201',     2,     3     FROM dual UNION ALL -- Lower San Juan (Bluff)
    SELECT '14020002',     1,     4     FROM dual UNION ALL -- Upper Gunnison (Aspinall Unit)
    SELECT '14020005',     2,     4     FROM dual UNION ALL -- Lower Gunnison (Whitewater)
    SELECT '14050001',     1,     5     FROM dual UNION ALL -- Upper Yampa
    SELECT '14050005',     1,     6     FROM dual UNION ALL -- Upper White
    SELECT '15010010',     1,     8     FROM dual           -- Lower Virgin (Littlefield)
  ) LOOP
    MERGE INTO hdb_river_reach t USING (SELECT r.huc huc, r.seg seg FROM dual) s
    ON (t.hydrologic_unit = s.huc AND t.segment_no = s.seg)
    WHEN NOT MATCHED THEN INSERT (hydrologic_unit, segment_no, river_id) VALUES (r.huc, r.seg, r.riv);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 9. Datatypes (auto-synced into DECODES.DATATYPE by HDB_DATATYPE_PK_TRIG!)
  -- ---------------------------------------------------------------------------
  -- Note: agen_id left NULL on shared multi-agency datatypes so multiple agencies
  -- can load observations cleanly; set explicitly on agency-specific datatypes.
  add_dt(1,  'pool elevation',                 'pool elev',        'elevation',            1,  'either',      NULL, 'Reservoir water surface elevation (ft NAVD88/NGVD29)');
  add_dt(2,  'tailwater elevation',            'tailwater elev',   'elevation',            1,  'either',      NULL, 'Dam tailwater surface elevation');
  add_dt(3,  'gage height',                    'stage',            'stage',                1,  'either',      NULL, 'Streamgage water stage above gage datum');
  add_dt(4,  'storage',                        'storage',          'storage',              3,  'either',      NULL, 'Total reservoir storage content');
  add_dt(5,  'live storage',                   'live storage',     'storage',              3,  'either',      NULL, 'Active live conservation storage');
  add_dt(6,  'bank storage change',            'bank stor chg',    'volume',               3,  'non-instant', 1,    'Estimated monthly reservoir bank storage change');
  add_dt(7,  'inflow',                         'inflow',           'flow',                 4,  'either',      NULL, 'Total reservoir inflow rate');
  add_dt(8,  'unregulated inflow',             'unreg inflow',     'flow',                 4,  'non-instant', 1,    'Computed unregulated inflow without upstream storage ops');
  add_dt(9,  'total release',                  'release',          'flow',                 4,  'either',      NULL, 'Total reservoir outflow / release');
  add_dt(10, 'turbine release',                'power release',    'flow',                 4,  'either',      NULL, 'Release through hydroelectric turbines');
  add_dt(11, 'spillway release',               'spill',            'flow',                 4,  'either',      NULL, 'Release over spillway gates');
  add_dt(12, 'bypass release',                 'bypass',           'flow',                 4,  'either',      NULL, 'Release through river outlet works / bypass tubes');
  add_dt(13, 'streamflow discharge',           'discharge',        'flow',                 4,  'either',      NULL, 'Streamgage volumetric discharge');
  add_dt(14, 'diversion flow',                 'diversion',        'flow',                 4,  'either',      NULL, 'Canal or aqueduct diversion flow rate');
  add_dt(15, 'inflow volume',                  'inflow vol',       'volume',               3,  'non-instant', NULL, 'Accumulated reservoir inflow volume');
  add_dt(16, 'release volume',                 'release vol',      'volume',               3,  'non-instant', NULL, 'Accumulated reservoir release volume');
  add_dt(17, 'diversion volume',               'diversion vol',    'volume',               3,  'non-instant', NULL, 'Accumulated canal diversion volume');
  add_dt(18, 'evaporation volume',             'evap vol',         'volume',               3,  'non-instant', 1,    'Computed reservoir evaporation volume loss');
  add_dt(19, 'pan evaporation',                'pan evap',         'evaporation',          14, 'non-instant', NULL, 'Class A pan evaporation depth');
  add_dt(20, 'reservoir surface area',         'surface area',     'surface area',         2,  'either',      NULL, 'Reservoir water surface area');
  add_dt(21, 'power generation',               'power',            'power',                6,  'either',      NULL, 'Instantaneous or average hydroelectric power output');
  add_dt(22, 'energy generation',              'energy',           'energy',               7,  'non-instant', NULL, 'Accumulated hydroelectric energy generated');
  add_dt(23, 'operating head',                 'head',             'head',                 1,  'either',      NULL, 'Gross hydraulic head (forebay minus tailwater)');
  add_dt(24, 'precipitation increment',        'precip',           'precipitation',        14, 'non-instant', NULL, 'Incremental precipitation depth');
  add_dt(25, 'snow water equivalent',          'SWE',              'snow water equivalent',14, 'either',      4,    'NRCS SNOTEL snowpack water equivalent');
  add_dt(26, 'air temperature',                'air temp',         'air temperature',      5,  'either',      NULL, 'Ambient air temperature');
  add_dt(27, 'water temperature',              'water temp',       'water temperature',    22, 'either',      NULL, 'River or tailwater temperature');
  add_dt(28, 'specific conductance',           'spec cond',        'specific conductance', 10, 'either',      NULL, 'Water specific conductance at 25 degC');
  add_dt(29, 'dissolved oxygen',               'DO',               'dissolved oxygen',     9,  'either',      NULL, 'Dissolved oxygen concentration');
  add_dt(30, 'water turbidity',                'turbidity',        'turbidity',            25, 'instant',     NULL, 'Instantaneous sensor turbidity reading');

  -- ---------------------------------------------------------------------------
  -- 10. Rating Algorithms & Rating Types
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 'LINEAR' a,      'RATINGS_PKG.LINEAR_INTERP' p,   'Piecewise linear interpolation' d FROM dual UNION ALL
    SELECT 'LOGARITHMIC',   'RATINGS_PKG.LOG_INTERP',        'Log-log stage-discharge rating interpolation' FROM dual UNION ALL
    SELECT 'SHIFT_LINEAR',  'RATINGS_PKG.SHIFT_LINEAR',      'Shifted piecewise linear stage-discharge lookup' FROM dual UNION ALL
    SELECT 'POWER_LAW',     'RATINGS_PKG.POWER_INTERP',      'Power-curve equation lookup' FROM dual UNION ALL
    SELECT 'STEP',          'RATINGS_PKG.STEP_LOOKUP',       'Step-function discrete gate opening table' FROM dual
  ) LOOP
    MERGE INTO hdb_rating_algorithm t USING (SELECT r.a a FROM dual) s ON (t.rating_algorithm = s.a)
    WHEN NOT MATCHED THEN INSERT (rating_algorithm, procedure_name, description) VALUES (r.a, r.p, r.d);
  END LOOP;

  FOR r IN (
    SELECT 'Stage-Discharge' cn,    'Stage to Streamflow Discharge' nm,  'LOGARITHMIC' alg, 3 ind, 13 dep, 'USGS streamgage stage-discharge rating curve' d FROM dual UNION ALL
    SELECT 'Elev-Storage',          'Elevation to Reservoir Storage',    'LINEAR',          1,     4,      'Reservoir bathymetric elevation-capacity table' FROM dual UNION ALL
    SELECT 'Elev-Area',             'Elevation to Surface Area',         'LINEAR',          1,     20,     'Reservoir elevation-surface area table' FROM dual UNION ALL
    SELECT 'Flow-Tailwater',        'Release Flow to Tailwater Elev',    'LINEAR',          9,     2,      'Tailwater rating curve vs total dam release' FROM dual UNION ALL
    SELECT 'Elev-Spillway',         'Elevation to Max Spillway Flow',    'POWER_LAW',       1,     11,     'Spillway crest discharge capacity curve' FROM dual UNION ALL
    SELECT 'Head-Power',            'Operating Head to Max Power',       'LINEAR',          23,    21,     'Powerplant generation capability vs hydraulic head' FROM dual UNION ALL
    SELECT 'Stage-Diversion',       'Canal Stage to Diversion Flow',     'SHIFT_LINEAR',    3,     14,     'Canal headworks flume stage-discharge rating' FROM dual UNION ALL
    SELECT 'Elev-LiveStorage',      'Elevation to Active Live Storage',  'LINEAR',          1,     5,      'Active conservation pool elevation-storage curve' FROM dual
  ) LOOP
    MERGE INTO hdb_rating_type t USING (SELECT r.cn cn FROM dual) s ON (t.rating_type_common_name = s.cn)
    WHEN NOT MATCHED THEN INSERT (
      rating_type_common_name, rating_type_name, rating_algorithm,
      indep_datatype_id, dep_datatype_id, description
    ) VALUES (r.cn, r.nm, r.alg, r.ind, r.dep, r.d);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 11. Features, Feature Classes, Properties, Attributes & Cross-References
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'Hydrologic Domain' nm FROM dual UNION ALL
    SELECT 2,    'Operational Role'     FROM dual UNION ALL
    SELECT 3,    'Measurement Category' FROM dual UNION ALL
    SELECT 4,    'Regulatory Program'   FROM dual UNION ALL
    SELECT 5,    'Data Quality Class'   FROM dual
  ) LOOP
    MERGE INTO hdb_feature_class t USING (SELECT r.id id FROM dual) s ON (t.feature_class_id = s.id)
    WHEN NOT MATCHED THEN INSERT (feature_class_id, feature_class_name) VALUES (r.id, r.nm);
  END LOOP;

  FOR r IN (
    SELECT 1 id,  'Surface Water' nm,        1 fc FROM dual UNION ALL
    SELECT 2,     'Snowpack & Climate',      1    FROM dual UNION ALL
    SELECT 3,     'Water Quality',           1    FROM dual UNION ALL
    SELECT 4,     'Hydropower',              1    FROM dual UNION ALL
    SELECT 5,     'Flood Control',           2    FROM dual UNION ALL
    SELECT 6,     'Water Supply Delivery',   2    FROM dual UNION ALL
    SELECT 7,     'Environmental Flow',      2    FROM dual UNION ALL
    SELECT 8,     'Continuous Telemetry',    3    FROM dual UNION ALL
    SELECT 9,     'Computed Balance',        3    FROM dual UNION ALL
    SELECT 10,    'Compact Accounting',      4    FROM dual UNION ALL
    SELECT 11,    'ESA Recovery Program',    4    FROM dual UNION ALL
    SELECT 12,    'Interim Guidelines 2007', 4    FROM dual UNION ALL
    SELECT 13,    'Operational Real-Time',   5    FROM dual UNION ALL
    SELECT 14,    'Published Final',         5    FROM dual UNION ALL
    SELECT 15,    'Forecast Planning',       5    FROM dual
  ) LOOP
    MERGE INTO hdb_feature t USING (SELECT r.id id FROM dual) s ON (t.feature_id = s.id)
    WHEN NOT MATCHED THEN INSERT (feature_id, feature_name, feature_class_id) VALUES (r.id, r.nm, r.fc);
  END LOOP;

  -- HDB_PROPERTY (number MUST have unit_id; string/date MUST have NULL unit_id)
  FOR r IN (
    SELECT 1 id,  'Default Reporting Interval' nm, 'Report Interval' cn, 'number' tp, 12 u FROM dual UNION ALL
    SELECT 2,     'Nominal Precision Tolerance',   'Precision Tol',      'number',    11   FROM dual UNION ALL
    SELECT 3,     'Lead Coordinating Agency',      'Lead Agency',        'string',    NULL FROM dual UNION ALL
    SELECT 4,     'Statutory Authority',           'Authority',          'string',    NULL FROM dual UNION ALL
    SELECT 5,     'Program Effective Date',        'Effective Date',     'date',      NULL FROM dual UNION ALL
    SELECT 6,     'Next Review Milestone',         'Review Date',        'date',      NULL FROM dual UNION ALL
    SELECT 7,     'Target Retention Window',       'Retention',          'number',    24   FROM dual UNION ALL
    SELECT 8,     'QA Protocol Standard',          'QA Protocol',        'string',    NULL FROM dual
  ) LOOP
    MERGE INTO hdb_property t USING (SELECT r.id id FROM dual) s ON (t.property_id = s.id)
    WHEN NOT MATCHED THEN INSERT (property_id, property_name, property_common_name, property_value_type, unit_id)
    VALUES (r.id, r.nm, r.cn, r.tp, r.u);
  END LOOP;

  -- HDB_FEATURE_PROPERTY (value/string_value/date_value strictly matched to property_value_type)
  FOR r IN (
    SELECT 1 f,  1 p, 900.0 v,  CAST(NULL AS VARCHAR2(200)) sv, CAST(NULL AS DATE) dv FROM dual UNION ALL
    SELECT 1,    3,   NULL,     'USBR / USGS Joint',            NULL FROM dual UNION ALL
    SELECT 2,    1,   3600.0,   NULL,                           NULL FROM dual UNION ALL
    SELECT 2,    3,   NULL,     'NRCS NWCC',                    NULL FROM dual UNION ALL
    SELECT 3,    2,   2.5,      NULL,                           NULL FROM dual UNION ALL
    SELECT 3,    8,   NULL,     'USGS Techniques & Methods 1-D3', NULL FROM dual UNION ALL
    SELECT 4,    3,   NULL,     'WAPA / USBR',                  NULL FROM dual UNION ALL
    SELECT 5,    3,   NULL,     'USACE / USBR',                 NULL FROM dual UNION ALL
    SELECT 6,    4,   NULL,     'Boulder Canyon Project Act',   NULL FROM dual UNION ALL
    SELECT 7,    5,   NULL,     NULL,                           DATE '1999-10-01' FROM dual UNION ALL
    SELECT 8,    1,   900.0,    NULL,                           NULL FROM dual UNION ALL
    SELECT 9,    8,   NULL,     'HDB Mass Balance QA v3',       NULL FROM dual UNION ALL
    SELECT 10,   4,   NULL,     '1922 Colorado River Compact',  NULL FROM dual UNION ALL
    SELECT 10,   5,   NULL,     NULL,                           DATE '1922-11-24' FROM dual UNION ALL
    SELECT 11,   6,   NULL,     NULL,                           DATE '2027-09-30' FROM dual UNION ALL
    SELECT 12,   5,   NULL,     NULL,                           DATE '2007-12-13' FROM dual UNION ALL
    SELECT 12,   6,   NULL,     NULL,                           DATE '2026-12-31' FROM dual UNION ALL
    SELECT 13,   7,   720.0,    NULL,                           NULL FROM dual UNION ALL
    SELECT 14,   8,   NULL,     'Annual Water Year Certification', NULL FROM dual UNION ALL
    SELECT 15,   3,   NULL,     'NWS CBRFC / USBR',             NULL FROM dual
  ) LOOP
    MERGE INTO hdb_feature_property t USING (SELECT r.f f, r.p p FROM dual) s
    ON (t.feature_id = s.f AND t.property_id = s.p)
    WHEN NOT MATCHED THEN INSERT (feature_id, property_id, value, string_value, date_value)
    VALUES (r.f, r.p, r.v, r.sv, r.dv);
  END LOOP;

  -- HDB_ATTR (string/date MUST have NULL unit_id per CHECK_ATTR_TYPE_AND_UNIT)
  FOR r IN (
    SELECT 1 id,  'Minimum Power Pool Elevation' nm, 'Min Power Pool' cn,   'number' tp, 'MIN_PWR_EL' cd, 1 u FROM dual UNION ALL
    SELECT 2,     'Flood Control Space Target',      'Flood Space',         'number',    'FLD_SPC',       3   FROM dual UNION ALL
    SELECT 3,     'Installed Generating Capacity',   'Gen Capacity',        'number',    'GEN_CAP',       6   FROM dual UNION ALL
    SELECT 4,     'Monthly Evaporation Rate Coef',   'Evap Coef',           'number',    'EVAP_COEF',     14  FROM dual UNION ALL
    SELECT 5,     'Bank Storage Factor',             'Bank Stor Fac',       'number',    'BANK_FAC',      11  FROM dual UNION ALL
    SELECT 6,     'Channel Routing Lag Time',        'Routing Lag',         'number',    'LAG_HR',        24  FROM dual UNION ALL
    SELECT 7,     'River Mile Distance',             'River Dist',          'number',    'RIV_MI',        16  FROM dual UNION ALL
    SELECT 8,     'Target Baseflow Minimum',         'Min Baseflow',        'number',    'MIN_FLOW',      4   FROM dual UNION ALL
    SELECT 9,     'Drainage Basin Area',             'Basin Area',          'number',    'BASIN_MI2',     17  FROM dual UNION ALL
    SELECT 10,    'Operational Tier Status',         'Ops Tier',            'string',    'OPS_TIER',      NULL FROM dual UNION ALL
    SELECT 11,    'ACL Site Group Name',             'ACL Group',           'string',    'ACL_GRP',       NULL FROM dual UNION ALL
    SELECT 12,    'Dam Safety Inspection Status',    'Safety Status',       'string',    'SAFETY_ST',     NULL FROM dual UNION ALL
    SELECT 13,    'Last Bathymetric Survey Date',    'Survey Date',         'date',      'SURVEY_DT',     NULL FROM dual UNION ALL
    SELECT 14,    'Telemetry Modernization Date',    'Modernize Date',      'date',      'TEL_MOD_DT',    NULL FROM dual UNION ALL
    SELECT 15,    'Seepage Loss Coefficient',        'Seepage Coef',        'number',    'SEEP_COEF',     11  FROM dual
  ) LOOP
    MERGE INTO hdb_attr t USING (SELECT r.id id FROM dual) s ON (t.attr_id = s.id)
    WHEN NOT MATCHED THEN INSERT (attr_id, attr_name, attr_common_name, attr_value_type, attr_code, unit_id)
    VALUES (r.id, r.nm, r.cn, r.tp, r.cd, r.u);
  END LOOP;

  -- HDB_ATTR_FEATURE
  FOR r IN (
    SELECT 1 a,  1 fc, 4 f  FROM dual UNION ALL
    SELECT 2,    2,    5    FROM dual UNION ALL
    SELECT 3,    1,    4    FROM dual UNION ALL
    SELECT 4,    1,    1    FROM dual UNION ALL
    SELECT 5,    3,    9    FROM dual UNION ALL
    SELECT 6,    1,    1    FROM dual UNION ALL
    SELECT 7,    1,    1    FROM dual UNION ALL
    SELECT 8,    2,    7    FROM dual UNION ALL
    SELECT 9,    1,    1    FROM dual UNION ALL
    SELECT 10,   4,    12   FROM dual UNION ALL
    SELECT 11,   5,    13   FROM dual UNION ALL
    SELECT 12,   2,    5    FROM dual UNION ALL
    SELECT 13,   5,    14   FROM dual UNION ALL
    SELECT 14,   3,    8    FROM dual UNION ALL
    SELECT 15,   3,    9    FROM dual
  ) LOOP
    MERGE INTO hdb_attr_feature t USING (SELECT r.a a, r.fc fc FROM dual) s
    ON (t.attr_id = s.a AND t.feature_class_id = s.fc)
    WHEN NOT MATCHED THEN INSERT (attr_id, feature_class_id, feature_id) VALUES (r.a, r.fc, r.f);
  END LOOP;

  -- HDB_DATATYPE_FEATURE
  FOR r IN (
    SELECT 1 dt,  1 fc, 1 f FROM dual UNION ALL SELECT 1,  2, 6  FROM dual UNION ALL
    SELECT 2,     1,    1   FROM dual UNION ALL SELECT 3,  1, 1  FROM dual UNION ALL
    SELECT 4,     1,    1   FROM dual UNION ALL SELECT 4,  4, 12 FROM dual UNION ALL
    SELECT 5,     2,    6   FROM dual UNION ALL SELECT 6,  3, 9  FROM dual UNION ALL
    SELECT 7,     1,    1   FROM dual UNION ALL SELECT 8,  3, 9  FROM dual UNION ALL
    SELECT 9,     2,    6   FROM dual UNION ALL SELECT 9,  4, 10 FROM dual UNION ALL
    SELECT 10,    1,    4   FROM dual UNION ALL SELECT 11, 2, 5  FROM dual UNION ALL
    SELECT 12,    2,    7   FROM dual UNION ALL SELECT 13, 1, 1  FROM dual UNION ALL
    SELECT 13,    3,    8   FROM dual UNION ALL SELECT 14, 2, 6  FROM dual UNION ALL
    SELECT 15,    4,    10  FROM dual UNION ALL SELECT 16, 4, 10 FROM dual UNION ALL
    SELECT 17,    4,    10  FROM dual UNION ALL SELECT 18, 3, 9  FROM dual UNION ALL
    SELECT 19,    1,    2   FROM dual UNION ALL SELECT 20, 1, 1  FROM dual UNION ALL
    SELECT 21,    1,    4   FROM dual UNION ALL SELECT 22, 1, 4  FROM dual UNION ALL
    SELECT 23,    1,    4   FROM dual UNION ALL SELECT 24, 1, 2  FROM dual UNION ALL
    SELECT 25,    1,    2   FROM dual UNION ALL SELECT 26, 1, 2  FROM dual UNION ALL
    SELECT 27,    1,    3   FROM dual UNION ALL SELECT 28, 1, 3  FROM dual UNION ALL
    SELECT 29,    1,    3   FROM dual UNION ALL SELECT 30, 1, 3  FROM dual
  ) LOOP
    MERGE INTO hdb_datatype_feature t USING (SELECT r.dt dt, r.fc fc FROM dual) s
    ON (t.datatype_id = s.dt AND t.feature_class_id = s.fc)
    WHEN NOT MATCHED THEN INSERT (datatype_id, feature_class_id, feature_id) VALUES (r.dt, r.fc, r.f);
  END LOOP;

  populate_pk.SET_PRE_POPULATED(1);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] Core lookup and reference tables seeded.');
EXCEPTION
  WHEN OTHERS THEN
    populate_pk.SET_PRE_POPULATED(1);
    ROLLBACK;
    RAISE;
END;
/
