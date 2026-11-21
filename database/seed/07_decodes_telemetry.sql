-- =============================================================================
-- 07_decodes_telemetry.sql
-- Populates the DECODES schema (35 application tables; DECODESDATABASEVERSION
-- is preserved untouched):
--   ENUM, ENUMVALUE, DATATYPE (non-HDB standards), DATATYPEEQUIVALENCE,
--   UNITCONVERTER, EQUIPMENTMODEL, EQUIPMENTPROPERTY, PLATFORMCONFIG,
--   CONFIGSENSOR, CONFIGSENSORDATATYPE, CONFIGSENSORPROPERTY, DECODESSCRIPT,
--   FORMATSTATEMENT, SCRIPTSENSOR, DATASOURCE, DATASOURCEGROUPMEMBER,
--   PRESENTATIONGROUP, DATAPRESENTATION, ROUNDINGRULE, NETWORKLIST,
--   NETWORKLISTENTRY, PLATFORM, PLATFORMPROPERTY, PLATFORMSENSOR,
--   PLATFORMSENSORPROPERTY, TRANSPORTMEDIUM, SITE_PROPERTY, ROUTINGSPEC,
--   ROUTINGSPECNETWORKLIST, ROUTINGSPECPROPERTY, SCHEDULE_ENTRY,
--   SCHEDULE_ENTRY_STATUS, PLATFORM_STATUS, DACQ_EVENT, SERIAL_PORT_STATUS.
--
-- Cross-schema references:
--   PLATFORM.SITEID, PLATFORMSENSOR.SITEID, SITE_PROPERTY.SITE_ID -> HDBDBA.HDB_SITE
--   SCHEDULE_ENTRY.LOADING_APPLICATION_ID, DACQ_EVENT.LOADING_APPLICATION_ID -> HDBDBA.HDB_LOADING_APPLICATION
--   DATATYPEEQUIVALENCE links SHEF-PE / USGS codes to HDBDBA-synced HDB datatypes (IDs 1..30).
-- =============================================================================

PROMPT [07] Seeding DECODES telemetry metadata, platforms, routing specs, and acquisition logs...

ALTER SESSION SET CURRENT_SCHEMA = DECODES;

DECLARE
  v_seq_val NUMBER;
  c_ts_now  CONSTANT TIMESTAMP WITH TIME ZONE := TIMESTAMP '2025-10-01 00:00:00 -07:00';
BEGIN
  -- ---------------------------------------------------------------------------
  -- 1. ENUM & ENUMVALUE (aligned with STANDARD_DATA/EnumList.xml)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'UnitFamily' nm,         'english' dv,     'Measurement unit system family' d FROM dual UNION ALL
    SELECT 2,    'LookupAlgorithm',       'linear',         'Interpolation algorithm for unit/rating lookup' FROM dual UNION ALL
    SELECT 3,    'OutputFormat',          'shef',           'DECODES consumer output formatter' FROM dual UNION ALL
    SELECT 4,    'RecordingMode',         'f',              'Sensor recording mode (fixed vs variable)' FROM dual UNION ALL
    SELECT 5,    'TransportMediumType',   'goes-st',        'Telemetry transport channel type' FROM dual UNION ALL
    SELECT 6,    'DataSourceType',        'lrgs',           'DECODES telemetry data source protocol' FROM dual UNION ALL
    SELECT 7,    'EquipmentType',         'dcp',            'Field telemetry hardware category' FROM dual UNION ALL
    SELECT 8,    'SiteNameType',          'hdb',            'Site naming standard preference' FROM dual
  ) LOOP
    MERGE INTO decodes.enum t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, name, defaultvalue, description) VALUES (r.id, r.nm, r.dv, r.d);
  END LOOP;

  FOR r IN (
    SELECT 1 eid, 'english' v,      'English / US Customary units' d,      CAST(NULL AS VARCHAR2(160)) ec, 1 sn FROM dual UNION ALL
    SELECT 1,     'metric',         'International SI Metric units',        NULL, 2 FROM dual UNION ALL
    SELECT 2,     'linear',         'Linear interpolation',                 'decodes.db.LinearConverter', 1 FROM dual UNION ALL
    SELECT 2,     'poly',           'Polynomial conversion',                'decodes.db.PolyConverter', 2 FROM dual UNION ALL
    SELECT 2,     'none',           'Identity / no conversion',             'decodes.db.NullConverter', 3 FROM dual UNION ALL
    SELECT 3,     'shef',           'Standard Hydrometeorological Exchange','decodes.consumer.ShefFormatter', 1 FROM dual UNION ALL
    SELECT 3,     'human-readable', 'Human-readable display format',        'decodes.consumer.HumanReadableFormatter', 2 FROM dual UNION ALL
    SELECT 3,     'stdmsg',         'USGS Standard Message Format',         'decodes.consumer.StdmsgFormatter', 3 FROM dual UNION ALL
    SELECT 3,     'raw',            'Raw message pass-through',             'decodes.consumer.RawFormatter', 4 FROM dual UNION ALL
    SELECT 4,     'f',              'Fixed interval recording',             NULL, 1 FROM dual UNION ALL
    SELECT 4,     'v',              'Variable / event-triggered recording', NULL, 2 FROM dual UNION ALL
    SELECT 5,     'goes-st',        'GOES Self-Timed satellite channel',    NULL, 1 FROM dual UNION ALL
    SELECT 5,     'goes-rd',        'GOES Random alert channel',            NULL, 2 FROM dual UNION ALL
    SELECT 5,     'iridium',        'Iridium SBD satellite link',           NULL, 3 FROM dual UNION ALL
    SELECT 5,     'polled-modem',   'Dial-up / cellular polled modem',      NULL, 4 FROM dual UNION ALL
    SELECT 6,     'lrgs',           'LRGS DDS telemetry server',            NULL, 1 FROM dual UNION ALL
    SELECT 6,     'lrgsgroup',      'Hot-backup group of LRGS servers',     NULL, 2 FROM dual UNION ALL
    SELECT 6,     'directory',      'Local file drop directory',            NULL, 3 FROM dual UNION ALL
    SELECT 6,     'web',            'HTTP/REST polling source',             NULL, 4 FROM dual UNION ALL
    SELECT 7,     'dcp',            'Data Collection Platform / logger',    NULL, 1 FROM dual UNION ALL
    SELECT 7,     'sensor',         'Field hydrological sensor',            NULL, 2 FROM dual UNION ALL
    SELECT 7,     'transmitter',    'GOES/Iridium radio transmitter',       NULL, 3 FROM dual UNION ALL
    SELECT 8,     'hdb',            'USBR HDB numeric site ID',             NULL, 1 FROM dual UNION ALL
    SELECT 8,     'usgs',           'USGS 8-digit station number',          NULL, 2 FROM dual UNION ALL
    SELECT 8,     'shef',           'NWS 5-char SHEF location ID',          NULL, 3 FROM dual
  ) LOOP
    MERGE INTO decodes.enumvalue t USING (SELECT r.eid eid, r.v v FROM dual) s
    ON (t.enumid = s.eid AND t.enumvalue = s.v)
    WHEN NOT MATCHED THEN INSERT (enumid, enumvalue, description, execclass, editclass, sortnumber)
    VALUES (r.eid, r.v, r.d, r.ec, NULL, r.sn);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 2. Non-HDB DECODES.DATATYPE (IDs 10501..10520) & DATATYPEEQUIVALENCE
  --    (HDB standard IDs 1..30 were auto-inserted by HDB_DATATYPE_PK_TRIG!)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 10501 id, 'SHEF-PE' std, 'HP' cd,     'Pool Elevation' dn,       1  hdb_id FROM dual UNION ALL
    SELECT 10502,    'SHEF-PE',     'HT',        'Tailwater Elevation',     2         FROM dual UNION ALL
    SELECT 10503,    'SHEF-PE',     'HG',        'River Stage / Gage Ht',   3         FROM dual UNION ALL
    SELECT 10504,    'SHEF-PE',     'LS',        'Reservoir Storage',       4         FROM dual UNION ALL
    SELECT 10505,    'SHEF-PE',     'QI',        'Reservoir Inflow',        7         FROM dual UNION ALL
    SELECT 10506,    'SHEF-PE',     'QT',        'Total Dam Release',       9         FROM dual UNION ALL
    SELECT 10507,    'SHEF-PE',     'QR',        'Streamflow Discharge',    13        FROM dual UNION ALL
    SELECT 10508,    'SHEF-PE',     'QD',        'Canal Diversion Flow',    14        FROM dual UNION ALL
    SELECT 10509,    'SHEF-PE',     'PP',        'Precipitation Increment', 24        FROM dual UNION ALL
    SELECT 10510,    'SHEF-PE',     'SW',        'Snow Water Equivalent',   25        FROM dual UNION ALL
    SELECT 10511,    'SHEF-PE',     'TA',        'Air Temperature',         26        FROM dual UNION ALL
    SELECT 10512,    'SHEF-PE',     'TW',        'Water Temperature',       27        FROM dual UNION ALL
    SELECT 10513,    'SHEF-PE',     'WC',        'Specific Conductance',    28        FROM dual UNION ALL
    SELECT 10514,    'SHEF-PE',     'WO',        'Dissolved Oxygen',        29        FROM dual UNION ALL
    SELECT 10515,    'SHEF-PE',     'WT',        'Water Turbidity',         30        FROM dual UNION ALL
    SELECT 10516,    'USGS',        '00060',     'USGS Discharge cfs',      13        FROM dual UNION ALL
    SELECT 10517,    'USGS',        '00065',     'USGS Gage Height ft',     3         FROM dual UNION ALL
    SELECT 10518,    'USGS',        '00010',     'USGS Water Temp degC',    27        FROM dual UNION ALL
    SELECT 10519,    'USGS',        '00095',     'USGS Spec Cond uS/cm',    28        FROM dual UNION ALL
    SELECT 10520,    'USGS',        '00300',     'USGS Dissolved Oxygen',   29        FROM dual
  ) LOOP
    MERGE INTO decodes.datatype t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, standard, code, display_name) VALUES (r.id, r.std, r.cd, r.dn);

    MERGE INTO decodes.datatypeequivalence t USING (SELECT r.hdb_id i0, r.id i1 FROM dual) s
    ON (t.id0 = s.i0 AND t.id1 = s.i1)
    WHEN NOT MATCHED THEN INSERT (id0, id1) VALUES (r.hdb_id, r.id);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 3. UNITCONVERTER (IDs 101..114)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 101 id, 'raw' fu,   'ft' tu,    'linear' alg, 1.0 a,      0.0 b   FROM dual UNION ALL
    SELECT 102,    'raw',      'cfs',      'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 103,    'raw',      'degC',     'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 104,    'raw',      'degF',     'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 105,    'raw',      'in',       'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 106,    'raw',      'uS/cm',    'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 107,    'raw',      'mg/L',     'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 108,    'raw',      'MW',       'linear',     1.0,        0.0     FROM dual UNION ALL
    SELECT 109,    'm',        'ft',       'linear',     3.28084,    0.0     FROM dual UNION ALL
    SELECT 110,    'ft',       'm',        'linear',     0.3048,     0.0     FROM dual UNION ALL
    SELECT 111,    'cms',      'cfs',      'linear',     35.31467,   0.0     FROM dual UNION ALL
    SELECT 112,    'degC',     'degF',     'linear',     1.8,        32.0    FROM dual UNION ALL
    SELECT 113,    'degF',     'degC',     'linear',     0.555556,   -17.778 FROM dual UNION ALL
    SELECT 114,    'mm',       'in',       'linear',     0.03937,    0.0     FROM dual
  ) LOOP
    MERGE INTO decodes.unitconverter t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, fromunitsabbr, tounitsabbr, algorithm, a, b)
    VALUES (r.id, r.fu, r.tu, r.alg, r.a, r.b);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 4. EQUIPMENTMODEL & EQUIPMENTPROPERTY
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'SatLink3-DCP' nm,   'OTT HydroMet / Sutron' co, 'SatLink3' md,      'GOES HDR V2 satellite logger/transmitter' d, 'dcp' et FROM dual UNION ALL
    SELECT 2,    'CR1000X-Logger',    'Campbell Scientific',      'CR1000X',          'Programmable hydrological datalogger',       'dcp'    FROM dual UNION ALL
    SELECT 3,    'Axiom-H2-DCP',      'FTS Forest Technology',    'Axiom H2',         'GOES/Iridium hydrological telemetry logger', 'dcp'    FROM dual UNION ALL
    SELECT 4,    'H-350XL-Bubbler',   'Design Analysis / Xylem',  'H-350XL',          'Nitrogen purge bubbler pressure sensor',     'sensor' FROM dual UNION ALL
    SELECT 5,    'OTT-RLS-Radar',     'OTT HydroMet',             'RLS',              'Non-contact pulse radar water level sensor', 'sensor' FROM dual UNION ALL
    SELECT 6,    'YSI-EXO2-Sonde',    'Xylem YSI',                'EXO2',             'Multiparameter water quality sonde',         'sensor' FROM dual UNION ALL
    SELECT 7,    'Sutron-Accubar',    'OTT HydroMet / Sutron',    'Accubar 5600-0131','Precision reservoir forebay pressure sensor','sensor' FROM dual UNION ALL
    SELECT 8,    'NRCS-SnowPillow',   'Sommer / NRCS',            'SS-120',           'Stainless steel snow pillow pressure sensor','sensor' FROM dual
  ) LOOP
    MERGE INTO decodes.equipmentmodel t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, name, company, model, description, equipmenttype)
    VALUES (r.id, r.nm, r.co, r.md, r.d, r.et);
  END LOOP;

  FOR r IN (
    SELECT 1 eid, 'baudRate' k,      '300' v FROM dual UNION ALL
    SELECT 1,     'goesVersion',     'V2-HDR' FROM dual UNION ALL
    SELECT 2,     'scanIntervalSec', '60' FROM dual UNION ALL
    SELECT 2,     'sdi12Support',    'true' FROM dual UNION ALL
    SELECT 3,     'dualTelemetry',   'GOES+Iridium' FROM dual UNION ALL
    SELECT 4,     'accuracyFt',      '0.005' FROM dual UNION ALL
    SELECT 5,     'rangeFt',         '115' FROM dual UNION ALL
    SELECT 6,     'parameters',      'Temp,SpecCond,DO,Turbidity' FROM dual UNION ALL
    SELECT 7,     'accuracyFt',      '0.002' FROM dual UNION ALL
    SELECT 8,     'maxSweIn',        '120' FROM dual
  ) LOOP
    MERGE INTO decodes.equipmentproperty t USING (SELECT r.eid eid, r.k k FROM dual) s
    ON (t.equipmentid = s.eid AND t.name = s.k)
    WHEN NOT MATCHED THEN INSERT (equipmentid, name, prop_value) VALUES (r.eid, r.k, r.v);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 5. PLATFORMCONFIG, CONFIGSENSOR, CONFIGSENSORDATATYPE, CONFIGSENSORPROPERTY,
  --    DECODESSCRIPT, FORMATSTATEMENT, SCRIPTSENSOR
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'USBR_Res_Standard_Cfg' nm,    'Standard reservoir forebay/tailwater/release SatLink3 config' d, 1 eq FROM dual UNION ALL
    SELECT 2,    'USGS_Gage_StageQ_Cfg',        'Standard USGS streamgage stage + discharge + water temp config', 1    FROM dual UNION ALL
    SELECT 3,    'USGS_Gage_WQ_Sonde_Cfg',      'USGS streamgage with YSI EXO2 water quality multiparameter sonde', 2  FROM dual UNION ALL
    SELECT 4,    'Diversion_Canal_Cfg',         'Canal headworks diversion flow and stage DCP config',            3    FROM dual UNION ALL
    SELECT 5,    'SNOTEL_Snowpack_Cfg',         'NRCS SNOTEL SWE, precipitation, and air temperature config',     2    FROM dual UNION ALL
    SELECT 6,    'Powerplant_SCADA_Cfg',        'Hydroelectric powerplant MW generation telemetry config',        2    FROM dual
  ) LOOP
    MERGE INTO decodes.platformconfig t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, name, description, equipmentid) VALUES (r.id, r.nm, r.d, r.eq);
  END LOOP;

  FOR r IN (
    -- Config 1: Reservoir (Forebay Elev, Release, Water Temp)
    SELECT 1 cid, 1 sn, 'PoolElev' nm,   'f' rm, 3600 ri, 0 tfs, 7 eq, 400.0 mn,  7600.0 mx, 'EOP' sc,  1 dt,  10501 dt2, 101 uc FROM dual UNION ALL
    SELECT 1,     2,    'TotalRelease',  'f',    3600,    0,     1,    0.0,       150000.0,  'AVG',     9,     10506,     102    FROM dual UNION ALL
    SELECT 1,     3,    'TailwaterElev', 'f',    3600,    0,     5,    350.0,     7200.0,    'EOP',     2,     10502,     101    FROM dual UNION ALL
    -- Config 2: USGS Gage (Stage, Discharge, Water Temp)
    SELECT 2,     1,    'Stage',         'f',    900,     0,     4,    0.0,       60.0,      'INST',    3,     10503,     101    FROM dual UNION ALL
    SELECT 2,     2,    'Discharge',     'f',    900,     0,     1,    0.0,       200000.0,  'INST',    13,    10507,     102    FROM dual UNION ALL
    SELECT 2,     3,    'WaterTemp',     'f',    3600,    0,     6,    0.0,       40.0,      'INST',    27,    10512,     103    FROM dual UNION ALL
    -- Config 3: USGS Gage + WQ Sonde
    SELECT 3,     1,    'Stage',         'f',    900,     0,     4,    0.0,       60.0,      'INST',    3,     10517,     101    FROM dual UNION ALL
    SELECT 3,     2,    'Discharge',     'f',    900,     0,     1,    0.0,       200000.0,  'INST',    13,    10516,     102    FROM dual UNION ALL
    SELECT 3,     3,    'WaterTemp',     'f',    900,     0,     6,    0.0,       40.0,      'INST',    27,    10518,     103    FROM dual UNION ALL
    SELECT 3,     4,    'SpecCond',      'f',    900,     0,     6,    10.0,      5000.0,    'INST',    28,    10519,     106    FROM dual UNION ALL
    SELECT 3,     5,    'DissolvedO2',   'f',    900,     0,     6,    0.0,       25.0,      'INST',    29,    10520,     107    FROM dual UNION ALL
    -- Config 4: Diversion
    SELECT 4,     1,    'DiversionFlow', 'f',    3600,    0,     5,    0.0,       15000.0,   'AVG',     14,    10508,     102    FROM dual UNION ALL
    -- Config 5: SNOTEL
    SELECT 5,     1,    'SWE',           'f',    3600,    0,     8,    0.0,       100.0,     'EOP',     25,    10510,     105    FROM dual UNION ALL
    SELECT 5,     2,    'Precip',        'f',    3600,    0,     8,    0.0,       20.0,      'SUM',     24,    10509,     105    FROM dual UNION ALL
    SELECT 5,     3,    'AirTemp',       'f',    3600,    0,     2,    -50.0,     120.0,     'INST',    26,    10511,     104    FROM dual UNION ALL
    -- Config 6: Powerplant
    SELECT 6,     1,    'PowerMW',       'f',    3600,    0,     2,    0.0,       2500.0,    'AVG',     21,    10506,     108    FROM dual
  ) LOOP
    MERGE INTO decodes.configsensor t USING (SELECT r.cid cid, r.sn sn FROM dual) s
    ON (t.configid = s.cid AND t.sensornumber = s.sn)
    WHEN NOT MATCHED THEN INSERT (
      configid, sensornumber, sensorname, recordingmode, recordinginterval,
      timeoffirstsample, equipmentid, absolutemin, absolutemax, stat_cd
    ) VALUES (r.cid, r.sn, r.nm, r.rm, r.ri, r.tfs, r.eq, r.mn, r.mx, r.sc);

    MERGE INTO decodes.configsensordatatype t USING (SELECT r.cid cid, r.sn sn, r.dt dt FROM dual) s
    ON (t.configid = s.cid AND t.sensornumber = s.sn AND t.datatypeid = s.dt)
    WHEN NOT MATCHED THEN INSERT (configid, sensornumber, datatypeid) VALUES (r.cid, r.sn, r.dt);

    MERGE INTO decodes.configsensordatatype t USING (SELECT r.cid cid, r.sn sn, r.dt2 dt FROM dual) s
    ON (t.configid = s.cid AND t.sensornumber = s.sn AND t.datatypeid = s.dt)
    WHEN NOT MATCHED THEN INSERT (configid, sensornumber, datatypeid) VALUES (r.cid, r.sn, r.dt2);

    MERGE INTO decodes.configsensorproperty t USING (SELECT r.cid cid, r.sn sn, 'units' k FROM dual) s
    ON (t.configid = s.cid AND t.sensornumber = s.sn AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (configid, sensornumber, prop_name, prop_value)
    VALUES (r.cid, r.sn, 'units', CASE r.uc WHEN 101 THEN 'ft' WHEN 102 THEN 'cfs' WHEN 103 THEN 'degC' WHEN 104 THEN 'degF' WHEN 105 THEN 'in' WHEN 106 THEN 'uS/cm' WHEN 107 THEN 'mg/L' ELSE 'MW' END);
  END LOOP;

  -- DECODESSCRIPT, FORMATSTATEMENT, SCRIPTSENSOR
  FOR r IN (
    SELECT 1 id, 1 cid, 'GOES_STD_RES' nm,  'decodes' st, 'D' ord, 'S(1),S(2),S(3)' fmt FROM dual UNION ALL
    SELECT 2,    2,     'GOES_STD_GAGE',    'decodes',    'D',     'S(1),S(2),S(3)'     FROM dual UNION ALL
    SELECT 3,    3,     'GOES_WQ_GAGE',     'decodes',    'D',     'S(1),S(2),S(3),S(4),S(5)' FROM dual UNION ALL
    SELECT 4,    4,     'GOES_DIVERSION',   'decodes',    'D',     'S(1)'               FROM dual UNION ALL
    SELECT 5,    5,     'SNOTEL_CSV',       'decodes',    'A',     'S(1),S(2),S(3)'     FROM dual UNION ALL
    SELECT 6,    6,     'SCADA_POWER_CSV',  'decodes',    'A',     'S(1)'               FROM dual
  ) LOOP
    MERGE INTO decodes.decodesscript t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, configid, name, script_type, dataorder)
    VALUES (r.id, r.cid, r.nm, r.st, r.ord);

    MERGE INTO decodes.formatstatement t USING (SELECT r.id id, 1 sn FROM dual) s
    ON (t.decodesscriptid = s.id AND t.sequencenum = s.sn)
    WHEN NOT MATCHED THEN INSERT (decodesscriptid, sequencenum, label, format)
    VALUES (r.id, 1, 'header', '1x,t(yyyyMMddHHmm),x');

    MERGE INTO decodes.formatstatement t USING (SELECT r.id id, 2 sn FROM dual) s
    ON (t.decodesscriptid = s.id AND t.sequencenum = s.sn)
    WHEN NOT MATCHED THEN INSERT (decodesscriptid, sequencenum, label, format)
    VALUES (r.id, 2, 'body', 'f(s,' || r.fmt || ')');
  END LOOP;

  FOR r IN (
    SELECT 1 sid, 1 sn, 101 uc FROM dual UNION ALL SELECT 1, 2, 102 FROM dual UNION ALL SELECT 1, 3, 101 FROM dual UNION ALL
    SELECT 2,     1,    101    FROM dual UNION ALL SELECT 2, 2, 102 FROM dual UNION ALL SELECT 2, 3, 103 FROM dual UNION ALL
    SELECT 3,     1,    101    FROM dual UNION ALL SELECT 3, 2, 102 FROM dual UNION ALL SELECT 3, 3, 103 FROM dual UNION ALL
    SELECT 3,     4,    106    FROM dual UNION ALL SELECT 3, 5, 107 FROM dual UNION ALL
    SELECT 4,     1,    102    FROM dual UNION ALL
    SELECT 5,     1,    105    FROM dual UNION ALL SELECT 5, 2, 105 FROM dual UNION ALL SELECT 5, 3, 104 FROM dual UNION ALL
    SELECT 6,     1,    108    FROM dual
  ) LOOP
    MERGE INTO decodes.scriptsensor t USING (SELECT r.sid sid, r.sn sn FROM dual) s
    ON (t.decodesscriptid = s.sid AND t.sensornumber = s.sn)
    WHEN NOT MATCHED THEN INSERT (decodesscriptid, sensornumber, unitconverterid)
    VALUES (r.sid, r.sn, r.uc);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 6. DATASOURCE & DATASOURCEGROUPMEMBER
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'LRGS_Primary_CDNS' nm,  'lrgs' tp,      'host=lrgs1.example.usbr.test, port=16003, username=hdb_ingest' arg FROM dual UNION ALL
    SELECT 2,    'LRGS_Backup_EDDN',      'lrgs',         'host=eddn.example.usgs.test, port=16003, username=hdb_ingest'  FROM dual UNION ALL
    SELECT 3,    'LRGS_UC_Failover_Grp',  'lrgsgroup',    'memberPriority=1,2'                                            FROM dual UNION ALL
    SELECT 4,    'USGS_NWIS_REST',        'web',          'url=https://waterservices.usgs.gov/nwis/iv/'                   FROM dual UNION ALL
    SELECT 5,    'SCADA_Drop_Dir',        'directory',    'directory=/data/scada/drop, filenameTemplate=*.csv'            FROM dual UNION ALL
    SELECT 6,    'SNOTEL_AWDB_Feed',      'web',          'url=https://wcc.sc.egov.usda.gov/awdbRestApi/'                 FROM dual
  ) LOOP
    MERGE INTO decodes.datasource t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, name, datasourcetype, datasourcearg) VALUES (r.id, r.nm, r.tp, r.arg);
  END LOOP;

  MERGE INTO decodes.datasourcegroupmember t USING (SELECT 3 gid, 1 mid FROM dual) s ON (t.groupid = s.gid AND t.memberid = s.mid)
  WHEN NOT MATCHED THEN INSERT (groupid, sequencenum, memberid) VALUES (3, 1, 1);
  MERGE INTO decodes.datasourcegroupmember t USING (SELECT 3 gid, 2 mid FROM dual) s ON (t.groupid = s.gid AND t.memberid = s.mid)
  WHEN NOT MATCHED THEN INSERT (groupid, sequencenum, memberid) VALUES (3, 2, 2);

  -- ---------------------------------------------------------------------------
  -- 7. PRESENTATIONGROUP, DATAPRESENTATION, ROUNDINGRULE
  -- ---------------------------------------------------------------------------
  MERGE INTO decodes.presentationgroup t USING (SELECT 1 id FROM dual) s ON (t.id = s.id)
  WHEN NOT MATCHED THEN INSERT (id, name, inheritsfrom, lastmodifytime, isproduction)
  VALUES (1, 'HDB_English_Base', NULL, c_ts_now, 'TRUE');

  MERGE INTO decodes.presentationgroup t USING (SELECT 2 id FROM dual) s ON (t.id = s.id)
  WHEN NOT MATCHED THEN INSERT (id, name, inheritsfrom, lastmodifytime, isproduction)
  VALUES (2, 'HDB_UC_Operations', 1, c_ts_now, 'TRUE');

  MERGE INTO decodes.presentationgroup t USING (SELECT 3 id FROM dual) s ON (t.id = s.id)
  WHEN NOT MATCHED THEN INSERT (id, name, inheritsfrom, lastmodifytime, isproduction)
  VALUES (3, 'HDB_WQ_Metric', 1, c_ts_now, 'TRUE');

  FOR r IN (
    SELECT 1 id,  1 gid, 1 dt,  'ft' u,    2 dec, 0.0 mn, 10000.0 mx, 5 sd FROM dual UNION ALL
    SELECT 2,     1,     3,     'ft',      2,     0.0,    100.0,      4    FROM dual UNION ALL
    SELECT 3,     1,     4,     'ac-ft',   0,     0.0,    30000000.0, 6    FROM dual UNION ALL
    SELECT 4,     1,     9,     'cfs',     0,     0.0,    200000.0,   4    FROM dual UNION ALL
    SELECT 5,     1,     13,    'cfs',     0,     0.0,    250000.0,   4    FROM dual UNION ALL
    SELECT 6,     1,     14,    'cfs',     1,     0.0,    20000.0,    4    FROM dual UNION ALL
    SELECT 7,     1,     21,    'MW',      1,     0.0,    3000.0,     4    FROM dual UNION ALL
    SELECT 8,     1,     25,    'in',      1,     0.0,    100.0,      3    FROM dual UNION ALL
    SELECT 9,     3,     27,    'degC',    2,     0.0,    40.0,       3    FROM dual UNION ALL
    SELECT 10,    3,     28,    'uS/cm',   0,     0.0,    5000.0,     4    FROM dual UNION ALL
    SELECT 11,    3,     29,    'mg/L',    2,     0.0,    25.0,       3    FROM dual
  ) LOOP
    MERGE INTO decodes.datapresentation t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, groupid, datatypeid, unitabbr, equipmentid, maxdecimals, max_value, min_value)
    VALUES (r.id, r.gid, r.dt, r.u, NULL, r.dec, r.mx, r.mn);

    MERGE INTO decodes.roundingrule t USING (SELECT r.id id, 1000000.0 ul FROM dual) s
    ON (t.datapresentationid = s.id AND t.upperlimit = s.ul)
    WHEN NOT MATCHED THEN INSERT (datapresentationid, upperlimit, sigdigits) VALUES (r.id, 1000000.0, r.sd);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 8. NETWORKLIST & NETWORKLISTENTRY
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'UC_Reservoirs_GOES' nm,  'goes-st' tm, 'hdb' sn FROM dual UNION ALL
    SELECT 2,    'LC_Reservoirs_GOES',     'goes-st',    'hdb'    FROM dual UNION ALL
    SELECT 3,    'Mainstem_Gages_GOES',    'goes-st',    'usgs'   FROM dual UNION ALL
    SELECT 4,    'LowerBasin_Diversions',  'goes-st',    'hdb'    FROM dual UNION ALL
    SELECT 5,    'SNOTEL_Index_Network',   'iridium',    'hdb'    FROM dual UNION ALL
    SELECT 6,    'All_Colorado_Active',    'goes-st',    'hdb'    FROM dual
  ) LOOP
    MERGE INTO decodes.networklist t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (id, name, transportmediumtype, sitenametypepreference, lastmodifytime)
    VALUES (r.id, r.nm, r.tm, r.sn, c_ts_now);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 9. PLATFORM, PLATFORMPROPERTY, PLATFORMSENSOR, PLATFORMSENSORPROPERTY,
  --    TRANSPORTMEDIUM, NETWORKLISTENTRY, SITE_PROPERTY (22 active/historical platforms)
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 pid,  'USBR' ag, 'TRUE' pr, 1011 sid, 1 cfg, 'Lake Powell Glen Canyon DCP' d,   'CE101101' tid, 1 nl, 101 ch FROM dual UNION ALL
    SELECT 2,      'USBR',    'TRUE',    1012,     1,     'Lake Mead Hoover Dam DCP',        'CE101201',     2,    102    FROM dual UNION ALL
    SELECT 3,      'USBR',    'TRUE',    1013,     1,     'Flaming Gorge Dam DCP',           'CE101301',     1,    103    FROM dual UNION ALL
    SELECT 4,      'USBR',    'TRUE',    1014,     1,     'Blue Mesa Dam DCP',               'CE101401',     1,    104    FROM dual UNION ALL
    SELECT 5,      'USBR',    'TRUE',    1015,     1,     'Morrow Point Dam DCP',            'CE101501',     1,    105    FROM dual UNION ALL
    SELECT 6,      'USBR',    'TRUE',    1016,     1,     'Crystal Dam DCP',                 'CE101601',     1,    106    FROM dual UNION ALL
    SELECT 7,      'USBR',    'TRUE',    1017,     1,     'Navajo Dam DCP',                  'CE101701',     1,    107    FROM dual UNION ALL
    SELECT 8,      'USBR',    'TRUE',    1018,     1,     'Fontenelle Dam DCP',              'CE101801',     1,    108    FROM dual UNION ALL
    SELECT 9,      'USBR',    'TRUE',    1019,     1,     'Davis Dam Lake Mohave DCP',       'CE101901',     2,    109    FROM dual UNION ALL
    SELECT 10,     'USBR',    'TRUE',    1020,     1,     'Parker Dam Lake Havasu DCP',      'CE102001',     2,    110    FROM dual UNION ALL
    SELECT 11,     'USGS',    'TRUE',    1021,     3,     'Lees Ferry USGS WQ & Gage DCP',   'CE102101',     3,    111    FROM dual UNION ALL
    SELECT 12,     'USGS',    'TRUE',    1022,     3,     'Colorado R near Cisco USGS DCP',  'CE102201',     3,    112    FROM dual UNION ALL
    SELECT 13,     'USGS',    'TRUE',    1023,     2,     'Green River UT USGS DCP',         'CE102301',     3,    113    FROM dual UNION ALL
    SELECT 14,     'USGS',    'TRUE',    1024,     2,     'San Juan R near Bluff USGS DCP',  'CE102401',     3,    114    FROM dual UNION ALL
    SELECT 15,     'USGS',    'TRUE',    1025,     2,     'Colorado R near Cameo USGS DCP',  'CE102501',     3,    115    FROM dual UNION ALL
    SELECT 16,     'USGS',    'TRUE',    1027,     2,     'Gunnison R at GJ USGS DCP',       'CE102701',     3,    116    FROM dual UNION ALL
    SELECT 17,     'USGS',    'TRUE',    1028,     2,     'Green R near Greendale DCP',      'CE102801',     3,    117    FROM dual UNION ALL
    SELECT 18,     'USGS',    'TRUE',    1031,     2,     'Diamond Creek Grand Canyon DCP',  'CE103101',     3,    118    FROM dual UNION ALL
    SELECT 19,     'CAWCD',   'TRUE',    1034,     4,     'CAP Mark Wilmer Pump DCP',        'CE103401',     4,    119    FROM dual UNION ALL
    SELECT 20,     'MWD',     'TRUE',    1035,     4,     'CRA Whitsett Intake DCP',         'CE103501',     4,    120    FROM dual UNION ALL
    SELECT 21,     'NRCS',    'TRUE',    1041,     5,     'Berthoud Summit SNOTEL Platform', 'IR104101',     5,    NULL   FROM dual UNION ALL
    SELECT 22,     'WAPA',    'FALSE',   1039,     6,     'Glen Canyon Powerplant Dev Test', 'CE103901',     1,    121    FROM dual
  ) LOOP
    MERGE INTO decodes.platform t USING (SELECT r.pid id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      id, agency, isproduction, siteid, configid, description, lastmodifytime, expiration, platformdesignator
    ) VALUES (
      r.pid, r.ag, r.pr, r.sid, r.cfg, r.d, c_ts_now,
      CASE WHEN r.pr = 'FALSE' THEN TIMESTAMP '2025-12-31 23:59:59 -07:00' ELSE NULL END,
      'PRIMARY'
    );

    MERGE INTO decodes.platformproperty t USING (SELECT r.pid pid, 'maintainer' k FROM dual) s
    ON (t.platformid = s.pid AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (platformid, prop_name, prop_value) VALUES (r.pid, 'maintainer', r.ag || '_Field_Ops');

    MERGE INTO decodes.platformsensor t USING (SELECT r.pid pid, 1 sn FROM dual) s
    ON (t.platformid = s.pid AND t.sensornumber = s.sn)
    WHEN NOT MATCHED THEN INSERT (platformid, sensornumber, siteid, dd_nu) VALUES (r.pid, 1, r.sid, 1);

    MERGE INTO decodes.platformsensorproperty t USING (SELECT r.pid pid, 1 sn, 'hdb_interval' k FROM dual) s
    ON (t.platformid = s.pid AND t.sensornumber = s.sn AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (platformid, sensornumber, prop_name, prop_value)
    VALUES (r.pid, 1, 'hdb_interval', CASE WHEN r.cfg IN (2,3) THEN 'instant' ELSE 'hour' END);

    MERGE INTO decodes.transportmedium t USING (
      SELECT r.pid pid, CASE WHEN r.cfg = 5 THEN 'iridium' ELSE 'goes-st' END mt FROM dual
    ) s ON (t.platformid = s.pid AND t.mediumtype = s.mt)
    WHEN NOT MATCHED THEN INSERT (
      platformid, mediumtype, mediumid, scriptname, channelnum,
      assignedtime, transmitwindow, transmitinterval, equipmentid, timezone
    ) VALUES (
      r.pid,
      CASE WHEN r.cfg = 5 THEN 'iridium' ELSE 'goes-st' END,
      r.tid,
      CASE r.cfg WHEN 1 THEN 'GOES_STD_RES' WHEN 2 THEN 'GOES_STD_GAGE' WHEN 3 THEN 'GOES_WQ_GAGE'
                 WHEN 4 THEN 'GOES_DIVERSION' WHEN 5 THEN 'SNOTEL_CSV' ELSE 'SCADA_POWER_CSV' END,
      r.ch, MOD(r.pid * 180, 3600), 10, 3600,
      CASE WHEN r.cfg = 5 THEN 2 ELSE 1 END, 'MST'
    );

    MERGE INTO decodes.networklistentry t USING (SELECT r.nl nl, r.tid tid FROM dual) s
    ON (t.networklistid = s.nl AND t.transportid = s.tid)
    WHEN NOT MATCHED THEN INSERT (networklistid, transportid, platform_name, description)
    VALUES (r.nl, r.tid, SUBSTR(r.d, 1, 64), SUBSTR(r.d, 1, 80));

    IF r.cfg <> 5 THEN
      MERGE INTO decodes.networklistentry t USING (SELECT 6 nl, r.tid tid FROM dual) s
      ON (t.networklistid = s.nl AND t.transportid = s.tid)
      WHEN NOT MATCHED THEN INSERT (networklistid, transportid, platform_name, description)
      VALUES (6, r.tid, SUBSTR(r.d, 1, 64), SUBSTR(r.d, 1, 80));
    END IF;

    MERGE INTO decodes.site_property t USING (SELECT r.sid sid, 'dcp_agency' k FROM dual) s
    ON (t.site_id = s.sid AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (site_id, prop_name, prop_value) VALUES (r.sid, 'dcp_agency', r.ag);
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 10. ROUTINGSPEC, ROUTINGSPECNETWORKLIST, ROUTINGSPECPROPERTY
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'RS_UC_Reservoirs_RT' nm,   3 ds, 'shef' fmt,           'HDB_UC_Operations' pg, 'now - 4 hours' sn, 'now' un, 'hdb' ct, 'UCHDB' ca, 'TRUE' pr, 'UC_Reservoirs_GOES' nl FROM dual UNION ALL
    SELECT 2,    'RS_LC_Reservoirs_RT',      3,    'shef',               'HDB_English_Base',     'now - 4 hours',    'now',    'hdb',    'UCHDB',    'TRUE',    'LC_Reservoirs_GOES'    FROM dual UNION ALL
    SELECT 3,    'RS_Mainstem_Gages_RT',     3,    'stdmsg',             'HDB_WQ_Metric',        'now - 2 hours',    'now',    'hdb',    'UCHDB',    'TRUE',    'Mainstem_Gages_GOES'   FROM dual UNION ALL
    SELECT 4,    'RS_Diversions_Hourly',     3,    'shef',               'HDB_English_Base',     'now - 6 hours',    'now',    'hdb',    'UCHDB',    'TRUE',    'LowerBasin_Diversions' FROM dual UNION ALL
    SELECT 5,    'RS_SNOTEL_Daily',          6,    'human-readable',     'HDB_English_Base',     'now - 24 hours',   'now',    'hdb',    'UCHDB',    'TRUE',    'SNOTEL_Index_Network'  FROM dual UNION ALL
    SELECT 6,    'RS_All_Basin_Backfill',    3,    'shef',               'HDB_English_Base',     'now - 48 hours',   'now',    'hdb',    'UCHDB',    'FALSE',   'All_Colorado_Active'   FROM dual
  ) LOOP
    MERGE INTO decodes.routingspec t USING (SELECT r.id id FROM dual) s ON (t.id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      id, name, datasourceid, enableequations, useperformancemeasurements,
      outputformat, outputtimezone, presentationgroupname, sincetime, untiltime,
      consumertype, consumerarg, lastmodifytime, isproduction
    ) VALUES (
      r.id, r.nm, r.ds, 'TRUE', 'TRUE',
      r.fmt, 'MST', r.pg, r.sn, r.un, r.ct, r.ca, c_ts_now, r.pr
    );

    MERGE INTO decodes.routingspecnetworklist t USING (SELECT r.id id, r.nl nl FROM dual) s
    ON (t.routingspecid = s.id AND t.networklistname = s.nl)
    WHEN NOT MATCHED THEN INSERT (routingspecid, networklistname) VALUES (r.id, r.nl);

    MERGE INTO decodes.routingspecproperty t USING (SELECT r.id id, 'hdbValidation' k FROM dual) s
    ON (t.routingspecid = s.id AND t.prop_name = s.k)
    WHEN NOT MATCHED THEN INSERT (routingspecid, prop_name, prop_value) VALUES (r.id, 'hdbValidation', 'Z');
  END LOOP;

  -- ---------------------------------------------------------------------------
  -- 11. SCHEDULE_ENTRY, SCHEDULE_ENTRY_STATUS, PLATFORM_STATUS, DACQ_EVENT, SERIAL_PORT_STATUS
  -- ---------------------------------------------------------------------------
  FOR r IN (
    SELECT 1 id, 'Sched_UC_Res_Hourly' nm,   1 app, 1 rs, '1 hour' ri,   'true' en FROM dual UNION ALL
    SELECT 2,    'Sched_LC_Res_Hourly',      1,     2,    '1 hour',      'true'    FROM dual UNION ALL
    SELECT 3,    'Sched_Gages_15Min',        1,     3,    '15 minutes',  'true'    FROM dual UNION ALL
    SELECT 4,    'Sched_Diversions_Hourly',  1,     4,    '1 hour',      'true'    FROM dual UNION ALL
    SELECT 5,    'Sched_SNOTEL_Daily',       5,     5,    '24 hours',    'true'    FROM dual UNION ALL
    SELECT 6,    'Sched_Backfill_Manual',    1,     6,    'manual',      'false'   FROM dual
  ) LOOP
    MERGE INTO decodes.schedule_entry t USING (SELECT r.id id FROM dual) s ON (t.schedule_entry_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      schedule_entry_id, name, loading_application_id, routingspec_id,
      start_time, timezone, run_interval, enabled, last_modified
    ) VALUES (
      r.id, r.nm, r.app, r.rs, DATE '2025-09-01', 'MST', r.ri, r.en, DATE '2025-09-30'
    );
  END LOOP;

  -- Historical completed/warning schedule runs (18 runs: 3 runs per schedule entry)
  FOR se IN 1..6 LOOP
    FOR k IN 1..3 LOOP
      DECLARE
        v_ses_id NUMBER := (se - 1) * 3 + k;
        v_rst    DATE   := DATE '2025-09-28' + (k - 1) + (se / 24);
      BEGIN
        MERGE INTO decodes.schedule_entry_status t USING (SELECT v_ses_id id FROM dual) s
        ON (t.schedule_entry_status_id = s.id)
        WHEN NOT MATCHED THEN INSERT (
          schedule_entry_status_id, schedule_entry_id, run_start_time,
          last_message_time, run_complete_time, hostname, run_status,
          num_messages, num_decode_errors, num_platforms, last_source, last_consumer, last_modified
        ) VALUES (
          v_ses_id, se, v_rst,
          v_rst + 3/1440, v_rst + 4/1440, 'uchdb-decodes-01.usbr.test',
          CASE WHEN se = 6 AND k = 1 THEN 'WARN' ELSE 'COMPLETE' END,
          40 + k * 8, CASE WHEN se = 3 AND k = 2 THEN 1 ELSE 0 END,
          CASE se WHEN 1 THEN 7 WHEN 2 THEN 3 WHEN 3 THEN 8 WHEN 4 THEN 2 WHEN 5 THEN 1 ELSE 20 END,
          'LRGS_Primary_CDNS', 'HDBConsumer', v_rst + 4/1440
        );
      END;
    END LOOP;
  END LOOP;

  -- PLATFORM_STATUS for all 22 platforms
  FOR p IN 1..22 LOOP
    MERGE INTO decodes.platform_status t USING (SELECT p pid FROM dual) s ON (t.platform_id = s.pid)
    WHEN NOT MATCHED THEN INSERT (
      platform_id, last_contact_time, last_message_time, last_failure_codes,
      last_error_time, last_schedule_entry_status_id, annotation
    ) VALUES (
      p,
      DATE '2025-09-30' - MOD(p, 3)/24,
      DATE '2025-09-30' - MOD(p, 3)/24,
      CASE WHEN p = 22 THEN 'T' ELSE NULL END,
      CASE WHEN p = 22 THEN DATE '2025-09-29' ELSE NULL END,
      CASE WHEN p <= 10 THEN 3 WHEN p <= 18 THEN 9 WHEN p <= 20 THEN 12 ELSE 15 END,
      CASE WHEN p = 22 THEN 'Dev test platform offline for maintenance' ELSE 'Nominal telemetry reception' END
    );
  END LOOP;

  -- DACQ_EVENT acquisition audit events (24 events)
  FOR i IN 1..24 LOOP
    MERGE INTO decodes.dacq_event t USING (SELECT i id FROM dual) s ON (t.dacq_event_id = s.id)
    WHEN NOT MATCHED THEN INSERT (
      dacq_event_id, schedule_entry_status_id, platform_id, event_time,
      event_priority, subsystem, msg_recv_time, event_text, loading_application_id
    ) VALUES (
      i, MOD(i - 1, 18) + 1, MOD(i - 1, 22) + 1,
      DATE '2025-09-28' + (i * 2) / 24,
      CASE WHEN MOD(i, 7) = 0 THEN 4 ELSE 6 END,
      CASE WHEN MOD(i, 3) = 0 THEN 'LRGS' ELSE 'DECODER' END,
      DATE '2025-09-28' + (i * 2) / 24,
      CASE WHEN MOD(i, 7) = 0 THEN 'Minor checksum retry succeeded on secondary LRGS feed'
           ELSE 'Decoded message and stored validated samples to HDB R_BASE' END,
      1
    );
  END LOOP;

  -- SERIAL_PORT_STATUS
  FOR r IN (
    SELECT '/dev/ttyS0' pn, 'FALSE' iu, 'uchdb-decodes-01.usbr.test' h, 'CE101101' lm, 'IDLE' st FROM dual UNION ALL
    SELECT '/dev/ttyS1',    'FALSE',    'uchdb-decodes-01.usbr.test', 'CE102101',     'IDLE'    FROM dual UNION ALL
    SELECT '/dev/ttyUSB0',  'TRUE',     'uchdb-scada-01.usbr.test',   'SCADA_GLEN',   'POLLING' FROM dual UNION ALL
    SELECT '/dev/ttyUSB1',  'FALSE',    'uchdb-scada-01.usbr.test',   'SCADA_HOOV',   'READY'   FROM dual
  ) LOOP
    MERGE INTO decodes.serial_port_status t USING (SELECT r.pn pn FROM dual) s ON (t.port_name = s.pn)
    WHEN NOT MATCHED THEN INSERT (
      port_name, in_use, last_used_by_proc, last_used_by_host,
      last_activity_time, last_receive_time, last_medium_id, port_status
    ) VALUES (
      r.pn, r.iu, 'DECODES', r.h, DATE '2025-09-30', DATE '2025-09-30', r.lm, r.st
    );
  END LOOP;

  -- Advance DECODES sequences past max seeded IDs
  LOOP SELECT decodes.enumidseq.NEXTVAL                  INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.datatypeidseq.NEXTVAL              INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 10600; END LOOP;
  LOOP SELECT decodes.unitconverteridseq.NEXTVAL         INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 200; END LOOP;
  LOOP SELECT decodes.equipmentidseq.NEXTVAL             INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.platformconfigidseq.NEXTVAL        INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.decodesscriptidseq.NEXTVAL         INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.datasourceidseq.NEXTVAL            INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.presentationgroupidseq.NEXTVAL     INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.datapresentationidseq.NEXTVAL      INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.networklistidseq.NEXTVAL           INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.platformidseq.NEXTVAL              INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 100; END LOOP;
  LOOP SELECT decodes.routingspecidseq.NEXTVAL           INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.schedule_entryidseq.NEXTVAL        INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 50; END LOOP;
  LOOP SELECT decodes.schedule_entry_statusidseq.NEXTVAL INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 100; END LOOP;
  LOOP SELECT decodes.dacq_eventidseq.NEXTVAL            INTO v_seq_val FROM dual; EXIT WHEN v_seq_val >= 100; END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  [OK] DECODES telemetry tables seeded.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
