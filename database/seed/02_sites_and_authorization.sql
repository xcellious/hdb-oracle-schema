-- =============================================================================
-- 02_sites_and_authorization.sql
-- Populates HDB_SITE (3-pass hierarchy: basins -> subbasins -> operational sites),
-- DECODES_SITE_EXT, REF_AUTH_SITE, HDB_SITE_DATATYPE, REF_AUTH_SITE_DATATYPE,
-- REF_RES, REF_RES_FLOWLU, REF_RES_WSELU, REF_STR, REF_DIV, REF_SITE_ATTR,
-- REF_SITE_COEF*, REF_SPATIAL_RELATION, REF_SITE_RATING, REF_RATING,
-- REF_SOURCE_PRIORITY, REF_INTERVAL_REDEFINITION, REF_INTERVAL_COPY_LIMITS,
-- and REF_USER_GROUPS.
--
-- Idempotent: Insert-only MERGE / natural-key existence checks. Never modifies
-- or deletes existing rows.
-- =============================================================================

PROMPT [02] Seeding sites, authorizations, site-datatypes, reservoir/gage specs, and ratings...

ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};

DECLARE
  v_rating_id NUMBER;
  v_seq_val   NUMBER;

  PROCEDURE add_site(
    p_id NUMBER, p_name VARCHAR2, p_cname VARCHAR2, p_ot NUMBER,
    p_pid NUMBER, p_pot NUMBER, p_st NUMBER, p_bas NUMBER,
    p_lat VARCHAR2, p_lon VARCHAR2, p_huc VARCHAR2, p_seg NUMBER,
    p_rm FLOAT, p_elev FLOAT, p_desc VARCHAR2,
    p_nws VARCHAR2, p_scs VARCHAR2, p_shef VARCHAR2, p_usgs VARCHAR2, p_db VARCHAR2
  ) IS
  BEGIN
    MERGE INTO hdb_site t USING (SELECT p_id id FROM dual) s ON (t.site_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      site_id, site_name, site_common_name, objecttype_id,
      parent_site_id, parent_objecttype_id, state_id, basin_id,
      lat, longi, hydrologic_unit, segment_no, river_mile, elevation,
      description, nws_code, scs_id, shef_code, usgs_id, db_site_code
    ) VALUES (
      p_id, p_name, p_cname, p_ot,
      p_pid, p_pot, p_st, p_bas,
      p_lat, p_lon, p_huc, p_seg, p_rm, p_elev,
      p_desc, p_nws, p_scs, p_shef, p_usgs, p_db
    );
  END;

  PROCEDURE set_site_ext(
    p_id NUMBER, p_city VARCHAR2, p_st VARCHAR2, p_reg VARCHAR2, p_tz VARCHAR2
  ) IS
  BEGIN
    UPDATE decodes_site_ext
       SET nearestcity = p_city,
           state       = p_st,
           region      = p_reg,
           timezone    = p_tz,
           country     = 'USA',
           elevunitabbr = 'ft'
     WHERE site_id = p_id
       AND nearestcity IS NULL;
  END;

  PROCEDURE add_sdi(p_sdi NUMBER, p_site NUMBER, p_dt NUMBER) IS
  BEGIN
    MERGE INTO hdb_site_datatype t USING (SELECT p_sdi id FROM dual) s ON (t.site_datatype_id = s.id)
    WHEN NOT MATCHED THEN INSERT (site_id, datatype_id, site_datatype_id) VALUES (p_site, p_dt, p_sdi);
  END;

  PROCEDURE ensure_rating(
    p_sdi NUMBER, p_type VARCHAR2, p_start DATE, p_end DATE,
    p_agen NUMBER, p_desc VARCHAR2, p_out_id OUT NUMBER
  ) IS
  BEGIN
    SELECT rating_id INTO p_out_id
      FROM ref_site_rating
     WHERE indep_site_datatype_id = p_sdi
       AND rating_type_common_name = p_type
       AND NVL(effective_start_date_time, DATE '1900-01-01') = NVL(p_start, DATE '1900-01-01')
       AND NVL(effective_end_date_time,   DATE '2999-12-31') = NVL(p_end,   DATE '2999-12-31');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO ref_site_rating (
        rating_id, indep_site_datatype_id, rating_type_common_name,
        effective_start_date_time, effective_end_date_time,
        date_time_loaded, agen_id, description
      ) VALUES (
        -1, p_sdi, p_type, p_start, p_end, SYSDATE, p_agen, p_desc
      ) RETURNING rating_id INTO p_out_id;
  END;

  PROCEDURE add_rating_pt(p_rid NUMBER, p_ind NUMBER, p_dep NUMBER) IS
  BEGIN
    MERGE INTO ref_rating t USING (SELECT p_rid rid, p_ind iv FROM dual) s
    ON (t.rating_id = s.rid AND t.independent_value = s.iv)
    WHEN NOT MATCHED THEN INSERT (rating_id, independent_value, dependent_value, date_time_loaded)
    VALUES (p_rid, p_ind, p_dep, SYSDATE);
  END;

BEGIN
  populate_pk.SET_PRE_POPULATED(0);

  -- ---------------------------------------------------------------------------
  -- 1. HDB_SITE Pass 1: Top-level Basins (objecttype_id = 1)
  -- ---------------------------------------------------------------------------
  add_site(1001, 'Upper Colorado River Basin',  'Upper Colorado Basin', 1, NULL, NULL, 2, NULL, '38.5000', '-109.5000', '14030005', 3, NULL, 4200, 'Colorado River drainage above Lees Ferry compact point', 'UCB', NULL, 'UCBASIN', NULL, 'UCH');
  add_site(1002, 'Lower Colorado River Basin',  'Lower Colorado Basin', 1, NULL, NULL, 6, NULL, '36.0160', '-114.7377', '15010001', 5, NULL, 1200, 'Colorado River drainage below Lees Ferry to international border', 'LCB', NULL, 'LCBASIN', NULL, 'LCH');
  add_site(1003, 'Green River Basin',           'Green River Basin',    1, 1001, 1,    3, 1001, '40.9140', '-109.4210', '14040106', 2, NULL, 6040, 'Major northern tributary basin of the Upper Colorado River', 'GRB', NULL, 'GRBASIN', NULL, 'UCH');
  add_site(1004, 'San Juan River Basin',        'San Juan Basin',       1, 1001, 1,    4, 1001, '36.8020', '-107.6120', '14080101', 1, NULL, 5800, 'Southern tributary basin draining San Juan Mountains', 'SJB', NULL, 'SJBASIN', NULL, 'UCH');

  -- ---------------------------------------------------------------------------
  -- 2. HDB_SITE Pass 2: Subbasins (objecttype_id = 2)
  -- ---------------------------------------------------------------------------
  add_site(1005, 'Gunnison River Subbasin',     'Gunnison Subbasin',    2, 1001, 1, 1, 1001, '38.4540', '-107.3340', '14020002', 1, NULL, 7519, 'Aspinall Unit and Gunnison Gorge drainage', 'GUN', NULL, 'GUNSUB', NULL, 'UCH');
  add_site(1006, 'Yampa-White Subbasin',        'Yampa-White Subbasin', 2, 1003, 1, 1, 1003, '40.4850', '-107.5500', '14050001', 1, NULL, 6200, 'Unregulated snowmelt tributaries to Green River', 'YWS', NULL, 'YWSUB',  NULL, 'UCH');
  add_site(1007, 'Glen Canyon Reach Subbasin',  'Glen Canyon Subbasin', 2, 1001, 1, 5, 1001, '36.9375', '-111.4843', '14070006', 4, NULL, 3700, 'Lake Powell and Lees Ferry compact reach', 'GLC', NULL, 'GLCSUB', NULL, 'UCH');
  add_site(1008, 'Mead-Mohave Reach Subbasin',  'Mead-Mohave Subbasin', 2, 1002, 1, 6, 1002, '35.5000', '-114.6500', '15030101', 7, NULL, 900,  'Lower Basin mainstem storage and delivery reach', 'MMR', NULL, 'MMRSUB', NULL, 'LCH');

  -- ---------------------------------------------------------------------------
  -- 3. HDB_SITE Pass 3: Reservoirs (objecttype_id = 5, tag = 'res')
  -- ---------------------------------------------------------------------------
  add_site(1011, 'Lake Powell at Glen Canyon Dam',   'Lake Powell',    5, 1007, 2, 5, 1001, '36.9375', '-111.4843', '14070006', 4, 15.0,  3715, 'CRSP primary storage reservoir on Colorado River', 'GLDA3', NULL, 'GLDA3', '09379900', 'UCH');
  add_site(1012, 'Lake Mead at Hoover Dam',          'Lake Mead',      5, 1008, 2, 6, 1002, '36.0160', '-114.7377', '15010001', 5, 342.0, 1232, 'Primary Lower Basin storage reservoir', 'HOON2', NULL, 'HOON2', '09421000', 'LCH');
  add_site(1013, 'Flaming Gorge Reservoir',          'Flaming Gorge',  5, 1003, 1, 2, 1003, '40.9147', '-109.4216', '14040106', 2, 290.0, 6047, 'Major Green River CRSP storage unit', 'GRNU1', NULL, 'GRNU1', '09234400', 'UCH');
  add_site(1014, 'Blue Mesa Reservoir',              'Blue Mesa',      5, 1005, 2, 1, 1001, '38.4542', '-107.3340', '14020002', 1, 65.0,  7528, 'Largest reservoir in Colorado (Aspinall Unit)', 'BMDC2', NULL, 'BMDC2', '09124600', 'UCH');
  add_site(1015, 'Morrow Point Reservoir',           'Morrow Point',   5, 1005, 2, 1, 1001, '38.4520', '-107.5370', '14020002', 1, 53.0,  7165, 'Middle Aspinall Unit concrete double-curvature arch dam', 'MPRC2', NULL, 'MPRC2', '09125500', 'UCH');
  add_site(1016, 'Crystal Reservoir',                'Crystal',        5, 1005, 2, 1, 1001, '38.5103', '-107.6242', '14020002', 1, 47.0,  6772, 'Afterbay re-regulation reservoir of Aspinall Unit', 'CRYC2', NULL, 'CRYC2', '09127800', 'UCH');
  add_site(1017, 'Navajo Reservoir',                 'Navajo',         5, 1004, 1, 4, 1004, '36.8017', '-107.6122', '14080101', 1, 224.0, 6108, 'San Juan River CRSP storage reservoir', 'NVRN5', NULL, 'NVRN5', '09355100', 'UCH');
  add_site(1018, 'Fontenelle Reservoir',             'Fontenelle',     5, 1003, 1, 3, 1003, '42.0281', '-110.0664', '14040101', 1, 405.0, 6519, 'Seedskadee Project reservoir on Upper Green River', 'GBRW4', NULL, 'GBRW4', '09211150', 'UCH');
  add_site(1019, 'Lake Mohave at Davis Dam',         'Lake Mohave',    5, 1008, 2, 5, 1002, '35.1972', '-114.5700', '15030101', 7, 275.0, 655,  'Re-regulation reservoir below Hoover Dam', 'DAVA3', NULL, 'DAVA3', '09422500', 'LCH');
  add_site(1020, 'Lake Havasu at Parker Dam',        'Lake Havasu',    5, 1008, 2, 7, 1002, '34.2964', '-114.1394', '15030101', 7, 192.0, 455,  'Forebay for CAP and Colorado River Aqueduct diversions', 'PKRA3', NULL, 'PKRA3', '09427500', 'LCH');

  -- ---------------------------------------------------------------------------
  -- 4. HDB_SITE Pass 3: Streamgages (objecttype_id = 6, tag = 'str')
  -- ---------------------------------------------------------------------------
  add_site(1021, 'Colorado River at Lees Ferry AZ',           'Lees Ferry',       6, 1007, 2, 5, 1001, '36.8647', '-111.5880', '14070006', 4, 0.0,   3106, 'Compact division point between Upper and Lower Basins', 'LEFA3', NULL, 'LEFA3', '09380000', 'UCH');
  add_site(1022, 'Colorado River near Cisco UT',              'Cisco',            6, 1001, 1, 2, 1001, '38.8106', '-109.2928', '14030005', 3, 211.0, 4090, 'Key Upper Colorado mainstem gage above Lake Powell', 'CLRU1', NULL, 'CLRU1', '09180500', 'UCH');
  add_site(1023, 'Green River at Green River UT',             'Green River UT',   6, 1003, 1, 2, 1003, '38.9861', '-110.1511', '14060008', 3, 120.0, 4040, 'Primary lower Green River inflow gage to Lake Powell', 'GRVU1', NULL, 'GRVU1', '09315000', 'UCH');
  add_site(1024, 'San Juan River near Bluff UT',              'Bluff',            6, 1004, 1, 2, 1004, '37.1470', '-109.8644', '14080201', 2, 82.0,  4048, 'Primary San Juan River inflow gage to Lake Powell', 'SJBU1', NULL, 'SJBU1', '09379500', 'UCH');
  add_site(1025, 'Colorado River near Cameo CO',              'Cameo',            6, 1001, 1, 1, 1001, '39.2392', '-108.2661', '14010005', 2, 315.0, 4814, 'Mainstem gage above Grand Valley diversions', 'CAMC2', NULL, 'CAMC2', '09095500', 'UCH');
  add_site(1026, 'Colorado River near Kremmling CO',          'Kremmling',        6, 1001, 1, 1, 1001, '40.0367', '-106.4397', '14010001', 1, 442.0, 7320, 'Upper Colorado headwaters gage below Gore Canyon', 'KRMC2', NULL, 'KRMC2', '09058000', 'UCH');
  add_site(1027, 'Gunnison River near Grand Junction CO',     'Gunnison GJ',      6, 1005, 2, 1, 1001, '38.9833', '-108.4500', '14020005', 2, 14.0,  4628, 'Lower Gunnison River discharge above Colorado confluence', 'GJNC2', NULL, 'GJNC2', '09152500', 'UCH');
  add_site(1028, 'Green River near Greendale UT',             'Greendale',        6, 1003, 1, 2, 1003, '40.9083', '-109.4222', '14040106', 2, 289.0, 5594, 'Tailwater compliance gage below Flaming Gorge Dam', 'GRDU1', NULL, 'GRDU1', '09234500', 'UCH');
  add_site(1029, 'Yampa River at Deerlodge Park CO',          'Deerlodge Park',   6, 1006, 2, 1, 1003, '40.4517', '-108.5250', '14050001', 1, 46.0,  5596, 'Major unregulated snowmelt tributary to Green River', 'YDLC2', NULL, 'YDLC2', '09260050', 'UCH');
  add_site(1030, 'Virgin River at Littlefield AZ',            'Littlefield',      6, 1008, 2, 5, 1002, '36.8917', '-113.9242', '15010010', 1, 36.0,  1763, 'Tributary inflow gage to Lake Mead', 'VLFA3', NULL, 'VLFA3', '09415000', 'LCH');
  add_site(1031, 'Colorado River above Diamond Creek AZ',     'Diamond Creek',    6, 1002, 1, 5, 1002, '35.7742', '-113.3636', '15010002', 6, 225.0, 1340, 'Lower Grand Canyon inflow gage above Lake Mead', 'DMCA3', NULL, 'DMCA3', '09404200', 'LCH');
  add_site(1032, 'Colorado River above Imperial Dam AZ-CA',   'Imperial Dam',     6, 1002, 1, 5, 1002, '32.8833', '-114.4670', '15030104', 8, 49.0,  181,  'Lower Basin diversion and Mexico treaty delivery gage', 'IMPA3', NULL, 'IMPA3', '09429490', 'YAO');

  -- ---------------------------------------------------------------------------
  -- 5. HDB_SITE Pass 3: Diversions (objecttype_id = 7, tag = 'div')
  -- ---------------------------------------------------------------------------
  add_site(1033, 'All-American Canal at Imperial Dam',        'All-American Canal', 7, 1002, 1, 7, 1002, '32.8800', '-114.4700', '15030104', 8, 49.0,  180,  'Major Imperial Valley agricultural diversion', 'AACC1', NULL, 'AACC1', '09523000', 'YAO');
  add_site(1034, 'Central Arizona Project Mark Wilmer Pump',  'CAP Diversion',      7, 1008, 2, 5, 1002, '34.3050', '-114.1250', '15030101', 7, 193.0, 450,  'CAP municipal and agricultural pumping diversion at Havasu', 'CAPA3', NULL, 'CAPA3', '09427510', 'LCH');
  add_site(1035, 'Colorado River Aqueduct Whitsett Intake',   'CRA Diversion',      7, 1008, 2, 7, 1002, '34.3160', '-114.1440', '15030101', 7, 194.0, 450,  'MWD Southern California municipal diversion at Lake Havasu', 'CRAC1', NULL, 'CRAC1', '09427505', 'LCH');
  add_site(1036, 'Grand Valley Government Highline Canal',    'Grand Valley Canal', 7, 1001, 1, 1, 1001, '39.1700', '-108.3400', '14010005', 2, 304.0, 4720, 'Upper Basin Grand Valley irrigation diversion', 'GVCC2', NULL, 'GVCC2', '09096000', 'UCH');
  add_site(1037, 'Gunnison Tunnel Uncompahgre Diversion',     'Gunnison Tunnel',    7, 1005, 2, 1, 1001, '38.5250', '-107.6800', '14020002', 1, 41.0,  6528, 'Trans-ridge irrigation diversion below Crystal Dam', 'GUTC2', NULL, 'GUTC2', '09128500', 'UCH');
  add_site(1038, 'Navajo Indian Irrigation Project Canal',    'NIIP Diversion',     7, 1004, 1, 4, 1004, '36.7980', '-107.6150', '14080101', 1, 224.0, 5985, 'San Juan irrigation diversion at Navajo Dam', 'NIPC5', NULL, 'NIPC5', '09355550', 'UCH');

  -- ---------------------------------------------------------------------------
  -- 6. HDB_SITE Pass 3: Powerplants (8), SNOTEL (11), Weather Station (12)
  -- ---------------------------------------------------------------------------
  add_site(1039, 'Glen Canyon Powerplant',              'Glen Canyon PP',    8, 1011, 5, 5, 1001, '36.9370', '-111.4840', '14070006', 4, 15.0,  3140, '8-unit 1320 MW hydroelectric facility at Glen Canyon Dam', 'GCPA3', NULL, 'GCPA3', NULL, 'UCH');
  add_site(1040, 'Hoover Dam Powerplant',               'Hoover PP',         8, 1012, 5, 6, 1002, '36.0155', '-114.7375', '15010001', 5, 342.0, 645,  '17-unit 2080 MW hydroelectric facility at Hoover Dam', 'HPWN2', NULL, 'HPWN2', NULL, 'LCH');
  add_site(1041, 'Berthoud Summit SNOTEL Station',      'Berthoud Summit',   11, 1001, 1, 1, 1001, '39.8039', '-105.7778', '14010001', 1, NULL, 11300, 'High-elevation Upper Colorado snowpack index SNOTEL', 'BRSC2', '335', 'BRSC2', NULL, 'UCH');
  add_site(1042, 'Red Mountain Pass SNOTEL Station',    'Red Mountain Pass', 11, 1005, 2, 1, 1001, '37.8919', '-107.7133', '14020002', 1, NULL, 11200, 'San Juan / Gunnison divide snowpack index SNOTEL', 'RMPC2', '713', 'RMPC2', NULL, 'UCH');
  add_site(1043, 'Page AZ Hydromet Weather Station',    'Page Weather Sta',  12, 1007, 2, 5, 1001, '36.9261', '-111.4483', '14070006', 4, NULL, 4270,  'Meteorological and pan evaporation station near Lake Powell', 'PGAW3', NULL, 'PGAW3', NULL, 'UCH');

  -- Update DECODES_SITE_EXT (rows auto-created by HDB_SITE_EXTENSION_TRIG)
  set_site_ext(1001, 'Moab',           'UT', 'Upper Colorado', 'MST');
  set_site_ext(1002, 'Boulder City',   'NV', 'Lower Colorado', 'MST');
  set_site_ext(1003, 'Dutch John',     'UT', 'Upper Colorado', 'MST');
  set_site_ext(1004, 'Farmington',     'NM', 'Upper Colorado', 'MST');
  set_site_ext(1005, 'Gunnison',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1006, 'Craig',          'CO', 'Upper Colorado', 'MST');
  set_site_ext(1007, 'Page',           'AZ', 'Upper Colorado', 'MST');
  set_site_ext(1008, 'Laughlin',       'NV', 'Lower Colorado', 'MST');
  set_site_ext(1011, 'Page',           'AZ', 'Upper Colorado', 'MST');
  set_site_ext(1012, 'Boulder City',   'NV', 'Lower Colorado', 'MST');
  set_site_ext(1013, 'Dutch John',     'UT', 'Upper Colorado', 'MST');
  set_site_ext(1014, 'Gunnison',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1015, 'Cimarron',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1016, 'Montrose',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1017, 'Navajo Dam',     'NM', 'Upper Colorado', 'MST');
  set_site_ext(1018, 'La Barge',       'WY', 'Upper Colorado', 'MST');
  set_site_ext(1019, 'Bullhead City',  'AZ', 'Lower Colorado', 'MST');
  set_site_ext(1020, 'Parker',         'AZ', 'Lower Colorado', 'MST');
  set_site_ext(1021, 'Marble Canyon',  'AZ', 'Upper Colorado', 'MST');
  set_site_ext(1022, 'Cisco',          'UT', 'Upper Colorado', 'MST');
  set_site_ext(1023, 'Green River',    'UT', 'Upper Colorado', 'MST');
  set_site_ext(1024, 'Bluff',          'UT', 'Upper Colorado', 'MST');
  set_site_ext(1025, 'Palisade',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1026, 'Kremmling',      'CO', 'Upper Colorado', 'MST');
  set_site_ext(1027, 'Grand Junction', 'CO', 'Upper Colorado', 'MST');
  set_site_ext(1028, 'Dutch John',     'UT', 'Upper Colorado', 'MST');
  set_site_ext(1029, 'Dinosaur',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1030, 'Littlefield',    'AZ', 'Lower Colorado', 'MST');
  set_site_ext(1031, 'Peach Springs',  'AZ', 'Lower Colorado', 'MST');
  set_site_ext(1032, 'Yuma',           'AZ', 'Lower Colorado', 'MST');
  set_site_ext(1033, 'Winterhaven',    'CA', 'Lower Colorado', 'MST');
  set_site_ext(1034, 'Parker',         'AZ', 'Lower Colorado', 'MST');
  set_site_ext(1035, 'Parker Dam',     'CA', 'Lower Colorado', 'MST');
  set_site_ext(1036, 'Palisade',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1037, 'Montrose',       'CO', 'Upper Colorado', 'MST');
  set_site_ext(1038, 'Bloomfield',     'NM', 'Upper Colorado', 'MST');
  set_site_ext(1039, 'Page',           'AZ', 'Upper Colorado', 'MST');
  set_site_ext(1040, 'Boulder City',   'NV', 'Lower Colorado', 'MST');
  set_site_ext(1041, 'Empire',         'CO', 'Upper Colorado', 'MST');
  set_site_ext(1042, 'Silverton',      'CO', 'Upper Colorado', 'MST');
  set_site_ext(1043, 'Page',           'AZ', 'Upper Colorado', 'MST');

  -- Advance HDB_SITE_SEQUENCE past max seeded site_id (1043)
  LOOP
    SELECT hdb_site_sequence.NEXTVAL INTO v_seq_val FROM dual;
    EXIT WHEN v_seq_val >= 2000;
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 7. Site Role Authorizations (REF_AUTH_SITE)
  --    Authorizing HDB_META_ROLE & APP_ROLE enables native RBAC checks in
  --    check_sdi_auth / check_site_id_auth without bypassing triggers.
  -- ---------------------------------------------------------------------------
  FOR r IN (SELECT site_id FROM hdb_site WHERE site_id BETWEEN 1001 AND 1043) LOOP
    MERGE INTO ref_auth_site t USING (SELECT 'HDB_META_ROLE' rl, r.site_id sid FROM dual) s
    ON (t.role = s.rl AND t.site_id = s.sid)
    WHEN NOT MATCHED THEN INSERT (role, site_id) VALUES ('HDB_META_ROLE', r.site_id);

    MERGE INTO ref_auth_site t USING (SELECT 'APP_ROLE' rl, r.site_id sid FROM dual) s
    ON (t.role = s.rl AND t.site_id = s.sid)
    WHEN NOT MATCHED THEN INSERT (role, site_id) VALUES ('APP_ROLE', r.site_id);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 8. Site-Datatypes (HDB_SITE_DATATYPE) — 110 deterministic SDIs (2001..2110)
  -- ---------------------------------------------------------------------------
  -- Lake Powell (1011): 10 SDIs
  add_sdi(2001, 1011, 1);  -- pool elevation
  add_sdi(2002, 1011, 4);  -- storage
  add_sdi(2003, 1011, 7);  -- inflow
  add_sdi(2004, 1011, 8);  -- unregulated inflow
  add_sdi(2005, 1011, 9);  -- total release
  add_sdi(2006, 1011, 10); -- turbine release
  add_sdi(2007, 1011, 11); -- spillway release
  add_sdi(2008, 1011, 12); -- bypass release
  add_sdi(2009, 1011, 18); -- evaporation volume
  add_sdi(2010, 1011, 20); -- surface area
  add_sdi(2011, 1011, 2);  -- tailwater elevation
  add_sdi(2012, 1011, 27); -- water temperature
  add_sdi(2013, 1011, 15); -- inflow volume
  add_sdi(2014, 1011, 16); -- release volume

  -- Lake Mead (1012): 10 SDIs
  add_sdi(2015, 1012, 1);  -- pool elevation
  add_sdi(2016, 1012, 4);  -- storage
  add_sdi(2017, 1012, 7);  -- inflow
  add_sdi(2018, 1012, 9);  -- total release
  add_sdi(2019, 1012, 10); -- turbine release
  add_sdi(2020, 1012, 18); -- evaporation volume
  add_sdi(2021, 1012, 20); -- surface area
  add_sdi(2022, 1012, 2);  -- tailwater elevation
  add_sdi(2023, 1012, 15); -- inflow volume
  add_sdi(2024, 1012, 16); -- release volume

  -- Flaming Gorge (1013): 7 SDIs
  add_sdi(2025, 1013, 1);
  add_sdi(2026, 1013, 4);
  add_sdi(2027, 1013, 7);
  add_sdi(2028, 1013, 8);
  add_sdi(2029, 1013, 9);
  add_sdi(2030, 1013, 10);
  add_sdi(2031, 1013, 27);

  -- Blue Mesa (1014): 6 SDIs
  add_sdi(2032, 1014, 1);
  add_sdi(2033, 1014, 4);
  add_sdi(2034, 1014, 7);
  add_sdi(2035, 1014, 8);
  add_sdi(2036, 1014, 9);
  add_sdi(2037, 1014, 21);

  -- Morrow Point (1015): 4 SDIs
  add_sdi(2038, 1015, 1);
  add_sdi(2039, 1015, 4);
  add_sdi(2040, 1015, 7);
  add_sdi(2041, 1015, 9);

  -- Crystal (1016): 4 SDIs
  add_sdi(2042, 1016, 1);
  add_sdi(2043, 1016, 4);
  add_sdi(2044, 1016, 7);
  add_sdi(2045, 1016, 9);

  -- Navajo (1017): 5 SDIs
  add_sdi(2046, 1017, 1);
  add_sdi(2047, 1017, 4);
  add_sdi(2048, 1017, 7);
  add_sdi(2049, 1017, 9);
  add_sdi(2050, 1017, 18);

  -- Fontenelle (1018): 4 SDIs
  add_sdi(2051, 1018, 1);
  add_sdi(2052, 1018, 4);
  add_sdi(2053, 1018, 7);
  add_sdi(2054, 1018, 9);

  -- Lake Mohave (1019): 4 SDIs
  add_sdi(2055, 1019, 1);
  add_sdi(2056, 1019, 4);
  add_sdi(2057, 1019, 7);
  add_sdi(2058, 1019, 9);

  -- Lake Havasu (1020): 4 SDIs
  add_sdi(2059, 1020, 1);
  add_sdi(2060, 1020, 4);
  add_sdi(2061, 1020, 7);
  add_sdi(2062, 1020, 9);

  -- Streamgages (1021..1032): discharge, stage, water temp, conductance, DO, turbidity
  add_sdi(2063, 1021, 13); -- Lees Ferry discharge
  add_sdi(2064, 1021, 3);  -- Lees Ferry stage
  add_sdi(2065, 1021, 27); -- Lees Ferry water temp
  add_sdi(2066, 1021, 28); -- Lees Ferry conductance
  add_sdi(2067, 1021, 29); -- Lees Ferry DO
  add_sdi(2068, 1021, 30); -- Lees Ferry turbidity (instant)

  add_sdi(2069, 1022, 13); -- Cisco discharge
  add_sdi(2070, 1022, 3);  -- Cisco stage
  add_sdi(2071, 1022, 27); -- Cisco water temp
  add_sdi(2072, 1022, 28); -- Cisco conductance

  add_sdi(2073, 1023, 13); -- Green River UT discharge
  add_sdi(2074, 1023, 3);  -- Green River UT stage
  add_sdi(2075, 1023, 27); -- Green River UT water temp

  add_sdi(2076, 1024, 13); -- Bluff discharge
  add_sdi(2077, 1024, 3);  -- Bluff stage

  add_sdi(2078, 1025, 13); -- Cameo discharge
  add_sdi(2079, 1025, 3);  -- Cameo stage

  add_sdi(2080, 1026, 13); -- Kremmling discharge
  add_sdi(2081, 1027, 13); -- Gunnison GJ discharge
  add_sdi(2082, 1027, 3);  -- Gunnison GJ stage
  add_sdi(2083, 1028, 13); -- Greendale discharge
  add_sdi(2084, 1028, 27); -- Greendale water temp
  add_sdi(2085, 1029, 13); -- Deerlodge Park discharge
  add_sdi(2086, 1030, 13); -- Littlefield discharge
  add_sdi(2087, 1031, 13); -- Diamond Creek discharge
  add_sdi(2088, 1031, 27); -- Diamond Creek water temp
  add_sdi(2089, 1032, 13); -- Imperial Dam discharge
  add_sdi(2090, 1032, 28); -- Imperial Dam conductance

  -- Diversions (1033..1038)
  add_sdi(2091, 1033, 14); -- All-American Canal diversion flow
  add_sdi(2092, 1033, 17); -- All-American Canal diversion volume
  add_sdi(2093, 1034, 14); -- CAP diversion flow
  add_sdi(2094, 1034, 17); -- CAP diversion volume
  add_sdi(2095, 1035, 14); -- CRA diversion flow
  add_sdi(2096, 1035, 17); -- CRA diversion volume
  add_sdi(2097, 1036, 14); -- Grand Valley Canal flow
  add_sdi(2098, 1037, 14); -- Gunnison Tunnel flow
  add_sdi(2099, 1038, 14); -- NIIP flow

  -- Powerplants (1039..1040)
  add_sdi(2100, 1039, 21); -- Glen Canyon power
  add_sdi(2101, 1039, 22); -- Glen Canyon energy
  add_sdi(2102, 1039, 23); -- Glen Canyon operating head
  add_sdi(2103, 1040, 21); -- Hoover power
  add_sdi(2104, 1040, 22); -- Hoover energy
  add_sdi(2105, 1040, 23); -- Hoover operating head

  -- SNOTEL & Weather (1041..1043)
  add_sdi(2106, 1041, 25); -- Berthoud Summit SWE
  add_sdi(2107, 1041, 24); -- Berthoud Summit precip
  add_sdi(2108, 1041, 26); -- Berthoud Summit air temp
  add_sdi(2109, 1042, 25); -- Red Mountain Pass SWE
  add_sdi(2110, 1043, 19); -- Page pan evaporation
  add_sdi(2111, 1043, 26); -- Page air temp

  -- REF_AUTH_SITE_DATATYPE (explicit SDI-level permissions)
  FOR r IN (SELECT site_datatype_id FROM hdb_site_datatype WHERE site_datatype_id BETWEEN 2001 AND 2111) LOOP
    MERGE INTO ref_auth_site_datatype t USING (SELECT 'HDB_META_ROLE' rl, r.site_datatype_id sdi FROM dual) s
    ON (t.role = s.rl AND t.site_datatype_id = s.sdi)
    WHEN NOT MATCHED THEN INSERT (role, site_datatype_id) VALUES ('HDB_META_ROLE', r.site_datatype_id);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 9. Reservoir Specifications (REF_RES, REF_RES_FLOWLU, REF_RES_WSELU)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1011 sid, 2 dt, 1 ag, 1 off, '1956-1966' cp, DATE '1963-03-13' cd,
           161390 ar, 24322000 ca, 1893000 cd2, 3997000 ci, 24322000 cl, 26215000 ct,
           3715 ec, 3490 emp, 3700 eta, 3370 etd, 31500 rmax, 5000 rmin, 208000 smax, 710 ht, 3700 wmax FROM dual UNION ALL
    SELECT 1012, 2, 1, 2, '1931-1936', DATE '1935-02-01',
           157900, 26120000, 2549000, 7465000, 26120000, 28669000,
           1232, 950, 1221.4, 895, 49000, 4000, 400000, 726, 1229 FROM dual UNION ALL
    SELECT 1013, 1, 1, 1, '1958-1964', DATE '1962-11-01',
           42020, 3749000, 40000, 233000, 3749000, 3789000,
           6047, 5871, 6040, 5740, 8600, 800, 28800, 502, 6045 FROM dual UNION ALL
    SELECT 1014, 4, 1, 3, '1962-1966', DATE '1965-10-26',
           9180, 829500, 111200, 81100, 829500, 940700,
           7528, 7393, 7519.4, 7358, 5000, 300, 34000, 390, 7525 FROM dual UNION ALL
    SELECT 1015, 1, 1, 3, '1963-1968', DATE '1968-01-24',
           817, 117025, 165, 74900, 117025, 117190,
           7165, 7100, 7160, 6770, 5500, 300, 41000, 468, 7162 FROM dual UNION ALL
    SELECT 1016, 1, 1, 3, '1973-1976', DATE '1977-03-19',
           301, 17540, 7700, 4600, 17540, 25240,
           6772, 6700, 6755, 6670, 4200, 300, 41350, 323, 6765 FROM dual UNION ALL
    SELECT 1017, 4, 1, 3, '1958-1963', DATE '1962-06-27',
           15610, 1696000, 12600, 660000, 1696000, 1708600,
           6108, 5990, 6085, 5775, 5000, 250, 34000, 402, 6101 FROM dual UNION ALL
    SELECT 1018, 4, 1, 4, '1961-1964', DATE '1964-04-02',
           8058, 344800, 563, 93000, 344800, 345363,
           6519, 6463, 6506, 6408, 4200, 350, 20000, 139, 6513 FROM dual UNION ALL
    SELECT 1019, 5, 1, 2, '1942-1951', DATE '1950-01-17',
           28200, 1810000, 8500, 217000, 1810000, 1818500,
           655, 570, 647, 533, 31000, 2000, 192000, 200, 647 FROM dual UNION ALL
    SELECT 1020, 1, 1, 2, '1934-1938', DATE '1938-10-16',
           20400, 619400, 28600, 439000, 619400, 648000,
           455, 440, 450, 400, 22000, 2000, 400000, 320, 450 FROM dual
  ) LOOP
    MERGE INTO ref_res t USING (SELECT r.sid id FROM dual) s ON (t.site_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      site_id, damtype_id, agen_id, off_id, constn_prd, close_date,
      areares, capact, capded, capinac, capliv, captot,
      elevcst, elevminp, elevtac, elevtdc, relmax, relmin, splmax, strht, wsemax
    ) VALUES (
      r.sid, r.dt, r.ag, r.off, r.cp, r.cd,
      r.ar, r.ca, r.cd2, r.ci, r.cl, r.ct,
      r.ec, r.emp, r.eta, r.etd, r.rmax, r.rmin, r.smax, r.ht, r.wmax
    );
  END LOOP;

  -- REF_RES_FLOWLU (tailwater elevation vs discharge for major dams)
  FOR r IN (
    SELECT 1011 sid, 5000 fl, 3133.2 tw FROM dual UNION ALL SELECT 1011, 10000, 3136.5 FROM dual UNION ALL
    SELECT 1011, 15000, 3139.4 FROM dual UNION ALL SELECT 1011, 20000, 3142.0 FROM dual UNION ALL
    SELECT 1011, 25000, 3144.3 FROM dual UNION ALL SELECT 1011, 31500, 3146.9 FROM dual UNION ALL
    SELECT 1012, 5000,  642.1  FROM dual UNION ALL SELECT 1012, 12000, 645.8  FROM dual UNION ALL
    SELECT 1012, 20000, 649.4  FROM dual UNION ALL SELECT 1012, 30000, 653.2  FROM dual UNION ALL
    SELECT 1012, 45000, 658.1  FROM dual UNION ALL
    SELECT 1013, 800,   5595.0 FROM dual UNION ALL SELECT 1013, 2000,  5597.1 FROM dual UNION ALL
    SELECT 1013, 4600,  5600.4 FROM dual UNION ALL SELECT 1013, 8600,  5604.2 FROM dual UNION ALL
    SELECT 1014, 500,   7160.5 FROM dual UNION ALL SELECT 1014, 2000,  7162.8 FROM dual UNION ALL
    SELECT 1014, 4000,  7165.1 FROM dual UNION ALL
    SELECT 1017, 500,   5722.0 FROM dual UNION ALL SELECT 1017, 2500,  5725.4 FROM dual UNION ALL
    SELECT 1017, 5000,  5728.6 FROM dual UNION ALL
    SELECT 1018, 500,   6391.2 FROM dual UNION ALL SELECT 1018, 2000,  6393.5 FROM dual UNION ALL
    SELECT 1018, 4200,  6396.0 FROM dual
  ) LOOP
    MERGE INTO ref_res_flowlu t USING (SELECT r.sid sid, r.fl fl FROM dual) s
    ON (t.site_id = s.sid AND t.flow = s.fl)
    WHEN NOT MATCHED THEN INSERT (site_id, flow, elevtw) VALUES (r.sid, r.fl, r.tw);
  END LOOP;

  -- REF_RES_WSELU (PK is SITE_ID: representative normal operating point per reservoir)
  FOR r IN (
    SELECT 1011 sid, 3580.0 wse, 82500 ar, 10250000 cnt, 14500 rl, 0 sp FROM dual UNION ALL
    SELECT 1012, 1065.0, 74200,  9120000,  11800, 0 FROM dual UNION ALL
    SELECT 1013, 6025.0, 35800,  3180000,  1800,  0 FROM dual UNION ALL
    SELECT 1014, 7495.0, 7640,   635000,   1400,  0 FROM dual UNION ALL
    SELECT 1015, 7152.0, 790,    110500,   1450,  0 FROM dual UNION ALL
    SELECT 1016, 6750.0, 285,    16200,    1500,  0 FROM dual UNION ALL
    SELECT 1017, 6060.0, 12450,  1310000,  650,   0 FROM dual UNION ALL
    SELECT 1018, 6495.0, 6820,   262000,   1250,  0 FROM dual UNION ALL
    SELECT 1019, 642.0,  26800,  1680000,  11500, 0 FROM dual UNION ALL
    SELECT 1020, 448.0,  19800,  580000,   9200,  0 FROM dual
  ) LOOP
    MERGE INTO ref_res_wselu t USING (SELECT r.sid id FROM dual) s ON (t.site_id = s.id)
    WHEN NOT MATCHED THEN INSERT (site_id, wse, areares, cont, rel, spl)
    VALUES (r.sid, r.wse, r.ar, r.cnt, r.rl, r.sp);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 10. Streamgages (REF_STR) & Diversions (REF_DIV)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1021 sid, 111800 ab, 1 gt, 2 ow FROM dual UNION ALL
    SELECT 1022,     24100,     2,    2    FROM dual UNION ALL
    SELECT 1023,     44850,     1,    2    FROM dual UNION ALL
    SELECT 1024,     23000,     2,    2    FROM dual UNION ALL
    SELECT 1025,     8050,      4,    2    FROM dual UNION ALL
    SELECT 1026,     2382,      1,    2    FROM dual UNION ALL
    SELECT 1027,     7928,      3,    2    FROM dual UNION ALL
    SELECT 1028,     19350,     1,    2    FROM dual UNION ALL
    SELECT 1029,     7660,      2,    2    FROM dual UNION ALL
    SELECT 1030,     5090,      5,    2    FROM dual UNION ALL
    SELECT 1031,     141300,    2,    2    FROM dual UNION ALL
    SELECT 1032,     188500,    3,    1    FROM dual
  ) LOOP
    MERGE INTO ref_str t USING (SELECT r.sid id FROM dual) s ON (t.site_id = s.id)
    WHEN NOT MATCHED THEN INSERT (site_id, areabas, gagetype_id, owner_id) VALUES (r.sid, r.ab, r.gt, r.ow);
  END LOOP;

  FOR r IN (
    SELECT 1033 sid, 'I' dt FROM dual UNION ALL
    SELECT 1034,     'M'    FROM dual UNION ALL
    SELECT 1034,     'I'    FROM dual UNION ALL
    SELECT 1035,     'M'    FROM dual UNION ALL
    SELECT 1036,     'I'    FROM dual UNION ALL
    SELECT 1037,     'T'    FROM dual UNION ALL
    SELECT 1038,     'I'    FROM dual
  ) LOOP
    MERGE INTO ref_div t USING (SELECT r.sid sid, r.dt dt FROM dual) s
    ON (t.site_id = s.sid AND t.divtype = s.dt)
    WHEN NOT MATCHED THEN INSERT (site_id, divtype) VALUES (r.sid, r.dt);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 11. Site Attributes (REF_SITE_ATTR) — mix of active/historical & number/string/date
  -- ---------------------------------------------------------------------------
  FOR r IN (
    -- Lake Powell
    SELECT 1011 sid, 1 aid, DATE '2007-12-13' es, CAST(NULL AS DATE) ee, 3490.0 v, CAST(NULL AS VARCHAR2(200)) sv, CAST(NULL AS DATE) dv FROM dual UNION ALL
    SELECT 1011, 3,  DATE '1966-01-01', NULL, 1320.0, NULL, NULL FROM dual UNION ALL
    SELECT 1011, 5,  DATE '2000-01-01', NULL, 8.0,    NULL, NULL FROM dual UNION ALL
    SELECT 1011, 10, DATE '2022-10-01', DATE '2024-09-30', NULL, 'Lower Elevation Balancing Tier', NULL FROM dual UNION ALL
    SELECT 1011, 10, DATE '2024-10-01', NULL,              NULL, 'Mid-Elevation Release Tier',     NULL FROM dual UNION ALL
    SELECT 1011, 12, DATE '2024-05-01', NULL,              NULL, 'Satisfactory - Routine Monitoring', NULL FROM dual UNION ALL
    SELECT 1011, 13, DATE '2022-09-01', NULL,              NULL, NULL, DATE '2022-08-15' FROM dual UNION ALL
    -- Lake Mead
    SELECT 1012, 1,  DATE '2010-01-01', NULL, 950.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1012, 2,  DATE '1984-01-01', NULL, 1500000.0, NULL, NULL FROM dual UNION ALL
    SELECT 1012, 3,  DATE '1961-01-01', NULL, 2080.0, NULL, NULL FROM dual UNION ALL
    SELECT 1012, 10, DATE '2023-01-01', DATE '2023-12-31', NULL, 'Tier 2a Shortage', NULL FROM dual UNION ALL
    SELECT 1012, 10, DATE '2024-01-01', NULL,              NULL, 'Tier 1 Shortage',  NULL FROM dual UNION ALL
    SELECT 1012, 12, DATE '2024-06-15', NULL,              NULL, 'Satisfactory',     NULL FROM dual UNION ALL
    SELECT 1012, 13, DATE '2010-06-01', NULL,              NULL, NULL, DATE '2010-05-20' FROM dual UNION ALL
    -- Flaming Gorge
    SELECT 1013, 1,  DATE '2006-02-16', NULL, 5871.0, NULL, NULL FROM dual UNION ALL
    SELECT 1013, 3,  DATE '1964-01-01', NULL, 152.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1013, 8,  DATE '2006-02-16', NULL, 800.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1013, 10, DATE '2024-05-01', NULL, NULL, 'Moderately Wet Hydrologic Classification', NULL FROM dual UNION ALL
    -- Blue Mesa / Navajo / Fontenelle / Mohave / Havasu
    SELECT 1014, 1,  DATE '2000-01-01', NULL, 7393.0, NULL, NULL FROM dual UNION ALL
    SELECT 1014, 3,  DATE '1967-01-01', NULL, 86.4,   NULL, NULL FROM dual UNION ALL
    SELECT 1014, 12, DATE '2024-04-01', NULL, NULL, 'Satisfactory', NULL FROM dual UNION ALL
    SELECT 1017, 1,  DATE '2006-07-01', NULL, 5990.0, NULL, NULL FROM dual UNION ALL
    SELECT 1017, 8,  DATE '2006-07-01', NULL, 250.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1018, 3,  DATE '1968-01-01', NULL, 10.0,   NULL, NULL FROM dual UNION ALL
    SELECT 1019, 3,  DATE '1951-01-01', NULL, 255.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1020, 3,  DATE '1942-01-01', NULL, 120.0,  NULL, NULL FROM dual UNION ALL
    -- Streamgages
    SELECT 1021, 9,  DATE '1921-01-01', NULL, 111800.0, NULL, NULL FROM dual UNION ALL
    SELECT 1021, 14, DATE '2023-04-12', NULL, NULL, NULL, DATE '2023-04-12' FROM dual UNION ALL
    SELECT 1022, 9,  DATE '1914-01-01', NULL, 24100.0, NULL, NULL FROM dual UNION ALL
    SELECT 1023, 9,  DATE '1905-01-01', NULL, 44850.0, NULL, NULL FROM dual UNION ALL
    SELECT 1024, 9,  DATE '1914-01-01', NULL, 23000.0, NULL, NULL FROM dual UNION ALL
    SELECT 1025, 9,  DATE '1933-01-01', NULL, 8050.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1027, 9,  DATE '1916-01-01', NULL, 7928.0,  NULL, NULL FROM dual UNION ALL
    SELECT 1028, 8,  DATE '2006-02-16', NULL, 800.0,   NULL, NULL FROM dual UNION ALL
    SELECT 1031, 9,  DATE '1989-01-01', NULL, 141300.0, NULL, NULL FROM dual
  ) LOOP
    MERGE INTO ref_site_attr t USING (
      SELECT r.sid sid, r.aid aid, r.es es FROM dual
    ) s ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (
      site_id, attr_id, effective_start_date_time, effective_end_date_time,
      value, string_value, date_value, date_time_loaded
    ) VALUES (r.sid, r.aid, r.es, r.ee, r.v, r.sv, r.dv, SYSDATE);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 12. Site Coefficients (REF_SITE_COEF, _MONTH, _DAY, _COEFLU) & Spatial Relations
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1011 sid, 5 aid, 1 idx, 0.080 c FROM dual UNION ALL
    SELECT 1011,     15,    1,     0.015   FROM dual UNION ALL
    SELECT 1012,     5,     1,     0.065   FROM dual UNION ALL
    SELECT 1012,     15,    1,     0.010   FROM dual UNION ALL
    SELECT 1013,     5,     1,     0.045   FROM dual UNION ALL
    SELECT 1014,     5,     1,     0.030   FROM dual UNION ALL
    SELECT 1017,     5,     1,     0.050   FROM dual UNION ALL
    SELECT 1018,     5,     1,     0.035   FROM dual UNION ALL
    SELECT 1019,     15,    1,     0.012   FROM dual UNION ALL
    SELECT 1020,     15,    1,     0.014   FROM dual
  ) LOOP
    MERGE INTO ref_site_coef t USING (
      SELECT r.sid sid, r.aid aid, r.idx idx, DATE '2020-01-01' es FROM dual
    ) s ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (site_id, attr_id, coef_idx, effective_start_date_time, effective_end_date_time, coef)
    VALUES (r.sid, r.aid, r.idx, DATE '2020-01-01', NULL, r.c);
  END LOOP;

  -- Monthly evaporation coefficients for 4 major reservoirs (4 x 12 = 48 rows)
  FOR m IN 1..12 LOOP
    DECLARE
      v_powell_evap FLOAT := CASE m WHEN 1 THEN 0.24 WHEN 2 THEN 0.28 WHEN 3 THEN 0.42 WHEN 4 THEN 0.56
                                    WHEN 5 THEN 0.72 WHEN 6 THEN 0.88 WHEN 7 THEN 0.94 WHEN 8 THEN 0.85
                                    WHEN 9 THEN 0.68 WHEN 10 THEN 0.48 WHEN 11 THEN 0.34 ELSE 0.25 END;
    BEGIN
      MERGE INTO ref_site_coef_month t USING (SELECT 1011 sid, 4 aid, m mo, 1 idx, DATE '2020-01-01' es FROM dual) s
      ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.month = s.mo AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
      WHEN NOT MATCHED THEN INSERT (site_id, attr_id, month, coef_idx, effective_start_date_time, coef)
      VALUES (1011, 4, m, 1, DATE '2020-01-01', v_powell_evap);

      MERGE INTO ref_site_coef_month t USING (SELECT 1012 sid, 4 aid, m mo, 1 idx, DATE '2020-01-01' es FROM dual) s
      ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.month = s.mo AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
      WHEN NOT MATCHED THEN INSERT (site_id, attr_id, month, coef_idx, effective_start_date_time, coef)
      VALUES (1012, 4, m, 1, DATE '2020-01-01', ROUND(v_powell_evap * 1.18, 3));

      MERGE INTO ref_site_coef_month t USING (SELECT 1013 sid, 4 aid, m mo, 1 idx, DATE '2020-01-01' es FROM dual) s
      ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.month = s.mo AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
      WHEN NOT MATCHED THEN INSERT (site_id, attr_id, month, coef_idx, effective_start_date_time, coef)
      VALUES (1013, 4, m, 1, DATE '2020-01-01', ROUND(v_powell_evap * 0.72, 3));

      MERGE INTO ref_site_coef_month t USING (SELECT 1017 sid, 4 aid, m mo, 1 idx, DATE '2020-01-01' es FROM dual) s
      ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.month = s.mo AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
      WHEN NOT MATCHED THEN INSERT (site_id, attr_id, month, coef_idx, effective_start_date_time, coef)
      VALUES (1017, 4, m, 1, DATE '2020-01-01', ROUND(v_powell_evap * 0.85, 3));
    END;
  END LOOP;

  -- Daily seasonal coefficients (2 reservoirs x 30 representative days = 60 rows)
  FOR d IN 1..30 LOOP
    MERGE INTO ref_site_coef_day t USING (SELECT 1011 sid, 4 aid, d * 12 dy, 1 idx, DATE '2020-01-01' es FROM dual) s
    ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.day = s.dy AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (site_id, attr_id, day, coef_idx, effective_start_date_time, coef)
    VALUES (1011, 4, d * 12, 1, DATE '2020-01-01', ROUND(0.015 + 0.015 * SIN((d * 12 - 90) * 3.14159 / 180), 4));

    MERGE INTO ref_site_coef_day t USING (SELECT 1012 sid, 4 aid, d * 12 dy, 1 idx, DATE '2020-01-01' es FROM dual) s
    ON (t.site_id = s.sid AND t.attr_id = s.aid AND t.day = s.dy AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (site_id, attr_id, day, coef_idx, effective_start_date_time, coef)
    VALUES (1012, 4, d * 12, 1, DATE '2020-01-01', ROUND(0.018 + 0.018 * SIN((d * 12 - 90) * 3.14159 / 180), 4));
  END LOOP;

  -- Lookup-indexed coefficients (REF_SITE_COEFLU: head -> power efficiency factor)
  FOR i IN 1..10 LOOP
    MERGE INTO ref_site_coeflu t USING (
      SELECT 1011 sid, 1 luid, 3490 + i * 20 luv, 3 aid, 1 idx, DATE '2020-01-01' es FROM dual
    ) s ON (t.site_id = s.sid AND t.lu_attr_id = s.luid AND t.lu_value = s.luv
            AND t.attr_id = s.aid AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (site_id, lu_attr_id, lu_value, attr_id, coef_idx, effective_start_date_time, coef)
    VALUES (1011, 1, 3490 + i * 20, 3, 1, DATE '2020-01-01', ROUND(0.76 + i * 0.014, 3));

    MERGE INTO ref_site_coeflu t USING (
      SELECT 1012 sid, 1 luid, 960 + i * 25 luv, 3 aid, 1 idx, DATE '2020-01-01' es FROM dual
    ) s ON (t.site_id = s.sid AND t.lu_attr_id = s.luid AND t.lu_value = s.luv
            AND t.attr_id = s.aid AND t.coef_idx = s.idx AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (site_id, lu_attr_id, lu_value, attr_id, coef_idx, effective_start_date_time, coef)
    VALUES (1012, 1, 960 + i * 25, 3, 1, DATE '2020-01-01', ROUND(0.74 + i * 0.016, 3));
  END LOOP;

  -- Spatial Relations (upstream-downstream routing lag hours & river mile distances)
  FOR r IN (
    SELECT 1026 a, 1025 b, 6 aid, 36.0 v FROM dual UNION ALL  -- Kremmling -> Cameo (lag hr)
    SELECT 1025,   1022,   6,     28.0   FROM dual UNION ALL  -- Cameo -> Cisco
    SELECT 1022,   1011,   6,     48.0   FROM dual UNION ALL  -- Cisco -> Lake Powell
    SELECT 1018,   1013,   6,     24.0   FROM dual UNION ALL  -- Fontenelle -> Flaming Gorge
    SELECT 1013,   1028,   6,     1.0    FROM dual UNION ALL  -- Flaming Gorge -> Greendale
    SELECT 1028,   1023,   6,     72.0   FROM dual UNION ALL  -- Greendale -> Green River UT
    SELECT 1029,   1023,   6,     60.0   FROM dual UNION ALL  -- Deerlodge -> Green River UT
    SELECT 1023,   1011,   6,     36.0   FROM dual UNION ALL  -- Green River UT -> Lake Powell
    SELECT 1017,   1024,   6,     42.0   FROM dual UNION ALL  -- Navajo -> Bluff
    SELECT 1024,   1011,   6,     24.0   FROM dual UNION ALL  -- Bluff -> Lake Powell
    SELECT 1014,   1015,   6,     3.0    FROM dual UNION ALL  -- Blue Mesa -> Morrow Point
    SELECT 1015,   1016,   6,     2.0    FROM dual UNION ALL  -- Morrow Point -> Crystal
    SELECT 1016,   1027,   6,     18.0   FROM dual UNION ALL  -- Crystal -> Gunnison GJ
    SELECT 1027,   1022,   6,     20.0   FROM dual UNION ALL  -- Gunnison GJ -> Cisco
    SELECT 1011,   1021,   6,     3.5    FROM dual UNION ALL  -- Glen Canyon -> Lees Ferry
    SELECT 1021,   1031,   6,     54.0   FROM dual UNION ALL  -- Lees Ferry -> Diamond Creek
    SELECT 1031,   1012,   6,     24.0   FROM dual UNION ALL  -- Diamond Creek -> Lake Mead
    SELECT 1030,   1012,   6,     12.0   FROM dual UNION ALL  -- Littlefield -> Lake Mead
    SELECT 1012,   1019,   6,     14.0   FROM dual UNION ALL  -- Hoover -> Mohave
    SELECT 1019,   1020,   6,     18.0   FROM dual UNION ALL  -- Davis -> Havasu
    SELECT 1020,   1032,   6,     32.0   FROM dual UNION ALL  -- Parker -> Imperial Dam
    SELECT 1011,   1021,   7,     15.5   FROM dual UNION ALL  -- River miles Glen Canyon -> Lees Ferry
    SELECT 1021,   1031,   7,     225.0  FROM dual UNION ALL  -- River miles Lees Ferry -> Diamond Creek
    SELECT 1012,   1019,   7,     67.0   FROM dual UNION ALL  -- River miles Hoover -> Davis
    SELECT 1019,   1020,   7,     88.0   FROM dual            -- River miles Davis -> Parker
  ) LOOP
    MERGE INTO ref_spatial_relation t USING (
      SELECT r.a a, r.b b, r.aid aid, DATE '2020-01-01' es FROM dual
    ) s ON (t.a_site_id = s.a AND t.b_site_id = s.b AND t.attr_id = s.aid AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (a_site_id, b_site_id, attr_id, effective_start_date_time, value)
    VALUES (r.a, r.b, r.aid, DATE '2020-01-01', r.v);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 13. Site Ratings (REF_SITE_RATING & REF_RATING — natural-key idempotent)
  -- ---------------------------------------------------------------------------
  -- Lake Powell Elev-Storage (historical 2010-2022 + active 2022-present)
  ensure_rating(2001, 'Elev-Storage', DATE '2010-01-01', DATE '2022-09-30', 1, 'Lake Powell 1986 bathymetric elevation-capacity table (historical)', v_rating_id);
  add_rating_pt(v_rating_id, 3490, 4120000); add_rating_pt(v_rating_id, 3525, 6230000);
  add_rating_pt(v_rating_id, 3560, 8810000); add_rating_pt(v_rating_id, 3590, 11420000);
  add_rating_pt(v_rating_id, 3620, 14450000); add_rating_pt(v_rating_id, 3660, 19180000);
  add_rating_pt(v_rating_id, 3700, 24322000);

  ensure_rating(2001, 'Elev-Storage', DATE '2022-10-01', NULL, 1, 'Lake Powell 2022 updated bathymetric elevation-capacity table (active)', v_rating_id);
  add_rating_pt(v_rating_id, 3490, 3997000); add_rating_pt(v_rating_id, 3525, 5985000);
  add_rating_pt(v_rating_id, 3550, 7730000); add_rating_pt(v_rating_id, 3575, 9760000);
  add_rating_pt(v_rating_id, 3600, 12120000); add_rating_pt(v_rating_id, 3630, 15280000);
  add_rating_pt(v_rating_id, 3665, 19510000); add_rating_pt(v_rating_id, 3700, 23314000);

  -- Lake Powell Elev-Area
  ensure_rating(2001, 'Elev-Area', DATE '2022-10-01', NULL, 1, 'Lake Powell 2022 elevation-surface area table', v_rating_id);
  add_rating_pt(v_rating_id, 3490, 52100); add_rating_pt(v_rating_id, 3525, 62800);
  add_rating_pt(v_rating_id, 3560, 75400); add_rating_pt(v_rating_id, 3600, 94600);
  add_rating_pt(v_rating_id, 3650, 124800); add_rating_pt(v_rating_id, 3700, 160200);

  -- Lake Mead Elev-Storage
  ensure_rating(2015, 'Elev-Storage', DATE '2010-10-01', NULL, 1, 'Lake Mead 2010 bathymetric elevation-capacity table', v_rating_id);
  add_rating_pt(v_rating_id, 950,  2018000); add_rating_pt(v_rating_id, 1000, 4432000);
  add_rating_pt(v_rating_id, 1050, 7830000); add_rating_pt(v_rating_id, 1075, 9875000);
  add_rating_pt(v_rating_id, 1100, 12140000); add_rating_pt(v_rating_id, 1150, 17320000);
  add_rating_pt(v_rating_id, 1200, 23450000); add_rating_pt(v_rating_id, 1221.4, 26120000);

  -- Lake Mead Elev-Area
  ensure_rating(2015, 'Elev-Area', DATE '2010-10-01', NULL, 1, 'Lake Mead 2010 elevation-surface area table', v_rating_id);
  add_rating_pt(v_rating_id, 950, 40500); add_rating_pt(v_rating_id, 1000, 54200);
  add_rating_pt(v_rating_id, 1050, 69800); add_rating_pt(v_rating_id, 1100, 88900);
  add_rating_pt(v_rating_id, 1150, 113400); add_rating_pt(v_rating_id, 1221.4, 157900);

  -- Flaming Gorge Elev-Storage
  ensure_rating(2025, 'Elev-Storage', DATE '2000-01-01', NULL, 1, 'Flaming Gorge elevation-storage curve', v_rating_id);
  add_rating_pt(v_rating_id, 5871, 610000); add_rating_pt(v_rating_id, 5940, 1340000);
  add_rating_pt(v_rating_id, 5990, 2210000); add_rating_pt(v_rating_id, 6020, 3020000);
  add_rating_pt(v_rating_id, 6040, 3749000);

  -- Blue Mesa Elev-Storage
  ensure_rating(2032, 'Elev-Storage', DATE '2000-01-01', NULL, 1, 'Blue Mesa elevation-storage curve', v_rating_id);
  add_rating_pt(v_rating_id, 7393, 192000); add_rating_pt(v_rating_id, 7440, 355000);
  add_rating_pt(v_rating_id, 7480, 548000); add_rating_pt(v_rating_id, 7505, 712000);
  add_rating_pt(v_rating_id, 7519.4, 829500);

  -- Navajo Elev-Storage
  ensure_rating(2046, 'Elev-Storage', DATE '2000-01-01', NULL, 1, 'Navajo Reservoir elevation-storage curve', v_rating_id);
  add_rating_pt(v_rating_id, 5990, 660000); add_rating_pt(v_rating_id, 6030, 975000);
  add_rating_pt(v_rating_id, 6060, 1310000); add_rating_pt(v_rating_id, 6085, 1696000);

  -- Lees Ferry Stage-Discharge
  ensure_rating(2064, 'Stage-Discharge', DATE '2023-10-01', NULL, 2, 'USGS 09380000 Lees Ferry Rating #24', v_rating_id);
  add_rating_pt(v_rating_id, 4.0, 4200); add_rating_pt(v_rating_id, 6.0, 7400);
  add_rating_pt(v_rating_id, 8.0, 11800); add_rating_pt(v_rating_id, 10.0, 17500);
  add_rating_pt(v_rating_id, 12.0, 24600); add_rating_pt(v_rating_id, 15.0, 38200);

  -- Cisco Stage-Discharge
  ensure_rating(2070, 'Stage-Discharge', DATE '2023-10-01', NULL, 2, 'USGS 09180500 Cisco Rating #19', v_rating_id);
  add_rating_pt(v_rating_id, 2.0, 1850); add_rating_pt(v_rating_id, 4.0, 4600);
  add_rating_pt(v_rating_id, 6.0, 9200); add_rating_pt(v_rating_id, 9.0, 18900);
  add_rating_pt(v_rating_id, 12.0, 32400);

  -- Green River UT Stage-Discharge
  ensure_rating(2074, 'Stage-Discharge', DATE '2023-10-01', NULL, 2, 'USGS 09315000 Green River UT Rating #31', v_rating_id);
  add_rating_pt(v_rating_id, 3.0, 1900); add_rating_pt(v_rating_id, 5.0, 4800);
  add_rating_pt(v_rating_id, 7.5, 10400); add_rating_pt(v_rating_id, 10.0, 19200);
  add_rating_pt(v_rating_id, 13.0, 33800);

  -- Bluff Stage-Discharge
  ensure_rating(2077, 'Stage-Discharge', DATE '2023-10-01', NULL, 2, 'USGS 09379500 Bluff Rating #16', v_rating_id);
  add_rating_pt(v_rating_id, 2.0, 620); add_rating_pt(v_rating_id, 4.0, 2150);
  add_rating_pt(v_rating_id, 6.0, 4900); add_rating_pt(v_rating_id, 8.5, 10200);

  -- ---------------------------------------------------------------------------
  -- 14. Source Priorities, Interval Redefinition, Copy Limits, User Groups
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 2001 sdi, 1 ag, 1 pr FROM dual UNION ALL SELECT 2001, 2, 2 FROM dual UNION ALL
    SELECT 2002,     1,    1    FROM dual UNION ALL SELECT 2003, 1, 1 FROM dual UNION ALL
    SELECT 2005,     1,    1    FROM dual UNION ALL SELECT 2005, 6, 2 FROM dual UNION ALL
    SELECT 2015,     1,    1    FROM dual UNION ALL SELECT 2016, 1, 1 FROM dual UNION ALL
    SELECT 2018,     1,    1    FROM dual UNION ALL SELECT 2018, 6, 2 FROM dual UNION ALL
    SELECT 2025,     1,    1    FROM dual UNION ALL SELECT 2029, 1, 1 FROM dual UNION ALL
    SELECT 2032,     1,    1    FROM dual UNION ALL SELECT 2046, 1, 1 FROM dual UNION ALL
    SELECT 2063,     2,    1    FROM dual UNION ALL SELECT 2063, 1, 2 FROM dual UNION ALL
    SELECT 2069,     2,    1    FROM dual UNION ALL SELECT 2069, 1, 2 FROM dual UNION ALL
    SELECT 2073,     2,    1    FROM dual UNION ALL SELECT 2073, 1, 2 FROM dual UNION ALL
    SELECT 2076,     2,    1    FROM dual UNION ALL SELECT 2078, 2, 1 FROM dual UNION ALL
    SELECT 2081,     2,    1    FROM dual UNION ALL SELECT 2083, 2, 1 FROM dual UNION ALL
    SELECT 2087,     2,    1    FROM dual UNION ALL SELECT 2089, 1, 1 FROM dual UNION ALL
    SELECT 2093,     11,   1    FROM dual UNION ALL SELECT 2093, 1, 2 FROM dual UNION ALL
    SELECT 2095,     12,   1    FROM dual UNION ALL SELECT 2095, 1, 2 FROM dual UNION ALL
    SELECT 2100,     6,    1    FROM dual UNION ALL SELECT 2100, 1, 2 FROM dual UNION ALL
    SELECT 2103,     6,    1    FROM dual UNION ALL SELECT 2103, 1, 2 FROM dual UNION ALL
    SELECT 2106,     4,    1    FROM dual UNION ALL SELECT 2109, 4, 1 FROM dual
  ) LOOP
    MERGE INTO ref_source_priority t USING (SELECT r.sdi sdi, r.ag ag, r.pr pr FROM dual) s
    ON (t.site_datatype_id = s.sdi AND t.agen_id = s.ag AND t.priority_rank = s.pr)
    WHEN NOT MATCHED THEN INSERT (site_datatype_id, agen_id, priority_rank, date_time_loaded)
    VALUES (r.sdi, r.ag, r.pr, SYSDATE);
  END LOOP;

  -- Interval Redefinition: Water Year starts Oct 1 (9 months offset from Jan 1 -> Oct)
  MERGE INTO ref_interval_redefinition t USING (SELECT 'wy' iv FROM dual) s ON (t.interval = s.iv)
  WHEN NOT MATCHED THEN INSERT (interval, time_offset, offset_units, date_time_loaded)
  VALUES ('wy', 9, 'month', SYSDATE);

  -- Interval Copy Limits (realistic QA/QC expected & cutoff ranges)
  FOR r IN (
    SELECT 2001 sdi, 'day' iv,   3490 mne, 3370 mnc, 3700 mxe, 3715 mxc, 0 toff, CAST(NULL AS VARCHAR2(512)) eq FROM dual UNION ALL
    SELECT 2001,     'hour',     3490,     3370,     3700,     3715,     0,      NULL FROM dual UNION ALL
    SELECT 2002,     'day',      3900000,  1800000,  24500000, 26500000, 0,      NULL FROM dual UNION ALL
    SELECT 2003,     'day',      1500,     0,        90000,    150000,   0,      NULL FROM dual UNION ALL
    SELECT 2005,     'day',      4500,     0,        35000,    60000,    0,      NULL FROM dual UNION ALL
    SELECT 2005,     'hour',     4500,     0,        35000,    60000,    0,      NULL FROM dual UNION ALL
    SELECT 2015,     'day',      950,      895,      1221,     1232,     0,      NULL FROM dual UNION ALL
    SELECT 2016,     'day',      2000000,  1000000,  26500000, 29000000, 0,      NULL FROM dual UNION ALL
    SELECT 2018,     'day',      3500,     0,        49000,    80000,    0,      NULL FROM dual UNION ALL
    SELECT 2025,     'day',      5871,     5740,     6040,     6047,     0,      NULL FROM dual UNION ALL
    SELECT 2026,     'day',      600000,   40000,    3760000,  3800000,  0,      NULL FROM dual UNION ALL
    SELECT 2032,     'day',      7393,     7358,     7520,     7528,     0,      NULL FROM dual UNION ALL
    SELECT 2046,     'day',      5990,     5775,     6085,     6108,     0,      NULL FROM dual UNION ALL
    SELECT 2063,     'day',      4500,     500,      45000,    120000,   0,      NULL FROM dual UNION ALL
    SELECT 2063,     'hour',     4500,     500,      45000,    120000,   0,      NULL FROM dual UNION ALL
    SELECT 2063,     'instant',  4500,     500,      45000,    120000,   0,      NULL FROM dual UNION ALL
    SELECT 2065,     'day',      5.0,      0.0,      24.0,     35.0,     0,      NULL FROM dual UNION ALL
    SELECT 2069,     'day',      800,      100,      55000,    100000,   0,      NULL FROM dual UNION ALL
    SELECT 2073,     'day',      700,      100,      50000,    90000,    0,      NULL FROM dual UNION ALL
    SELECT 2076,     'day',      200,      10,       25000,    60000,    0,      NULL FROM dual UNION ALL
    SELECT 2093,     'day',      0,        0,        3600,     4200,     0,      NULL FROM dual UNION ALL
    SELECT 2100,     'day',      100,      0,        1320,     1400,     0,      NULL FROM dual UNION ALL
    SELECT 2103,     'day',      100,      0,        2080,     2200,     0,      NULL FROM dual UNION ALL
    SELECT 2106,     'day',      0,        0,        45,       70,       0,      NULL FROM dual
  ) LOOP
    MERGE INTO ref_interval_copy_limits t USING (
      SELECT r.sdi sdi, r.iv iv, DATE '2020-01-01' es FROM dual
    ) s ON (t.site_datatype_id = s.sdi AND t.interval = s.iv AND t.effective_start_date_time = s.es)
    WHEN NOT MATCHED THEN INSERT (
      site_datatype_id, interval, min_value_expected, min_value_cutoff,
      max_value_expected, max_value_cutoff, time_offset_minutes,
      date_time_loaded, effective_start_date_time, effective_end_date_time, preprocessor_equation
    ) VALUES (
      r.sdi, r.iv, r.mne, r.mnc, r.mxe, r.mxc, r.toff,
      SYSDATE, DATE '2020-01-01', NULL, r.eq
    );
  END LOOP;

  -- User Groups (REF_USER_GROUPS)
  FOR r IN (
    SELECT UPPER('${hdb_user}') u, UPPER('${hdb_user}') g,  'Y' af FROM dual UNION ALL
    SELECT UPPER('${hdb_user}'),   'UPPER_BASIN_OPS',       'Y'    FROM dual UNION ALL
    SELECT UPPER('${hdb_user}'),   'LOWER_BASIN_OPS',       'Y'    FROM dual UNION ALL
    SELECT 'APP_USER',     'UPPER_BASIN_OPS',       'Y'    FROM dual UNION ALL
    SELECT 'APP_USER',     'LOWER_BASIN_OPS',       'Y'    FROM dual UNION ALL
    SELECT 'CP_PROCESS',   'COMPUTATION_PROCESSORS','Y'    FROM dual UNION ALL
    SELECT 'DECODES',      'TELEMETRY_LOADERS',     'Y'    FROM dual UNION ALL
    SELECT 'HYDRO_ALICE',  'UPPER_BASIN_OPS',       'Y'    FROM dual UNION ALL
    SELECT 'HYDRO_BOB',    'LOWER_BASIN_OPS',       'Y'    FROM dual UNION ALL
    SELECT 'HYDRO_CAROL',  'WATER_QUALITY_TEAM',    'Y'    FROM dual UNION ALL
    SELECT 'HYDRO_DAVE',   'FORECAST_MODELERS',     'Y'    FROM dual UNION ALL
    SELECT 'HYDRO_LEGACY', 'UPPER_BASIN_OPS',       'N'    FROM dual
  ) LOOP
    MERGE INTO ref_user_groups t USING (SELECT r.u u, r.g g FROM dual) s
    ON (t.user_name = s.u AND t.group_name = s.g)
    WHEN NOT MATCHED THEN INSERT (user_name, group_name, active_flag, last_modified_date)
    VALUES (r.u, r.g, r.af, SYSDATE);
  END LOOP;

  populate_pk.SET_PRE_POPULATED(1);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] Sites, authorizations, site-datatypes, reservoir/gage specs, and ratings seeded.');
EXCEPTION
  WHEN OTHERS THEN
    populate_pk.SET_PRE_POPULATED(1);
    ROLLBACK;
    RAISE;
END;
/
