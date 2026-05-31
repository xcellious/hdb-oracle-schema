ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};
-- Incorporating comments.sql
--------------------------------------------------------------------------
-- This script add comments on HDB_ REF_ tables and columns
-- IMPORTANT!!! This script should be executed as main schema user that owns the tables.
-- created on 02/19/2023 by IsmailO
--------------------------------------------------------------------------


-- COMMENTS on HDB_ tables 

BEGIN EXECUTE IMMEDIATE 'comment on table HDB_AGEN is ''Holds all the different agencies that are potential sources of data. The agency id is required in r_base table to define the source agency of the data being stored.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_ATTR is ''Holds attributes that are used to describe characteristics of sites,datatypes and features.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_ATTR_FEATURE is ''Connects an attribute from hdb_attribute with a feature in hdb_feature.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_COLLECTION_SYSTEM is ''Holds the system used by an agency to collect the source data. Collection_system_id is required in r_base table.Since the collection system is not usually known, it is usually set to an id of 14 (see agency).'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DAMTYPE is ''Holds the construction type of a dam. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DATA_SOURCE is ''Obsolete as of hdb2. It is a precursor to the HDB_AGEN table. Still required for referential integrity for pre-hdb2 records in the interval tables'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DATATYPE is ''Represents and describes what data is being stored.The datatype in this table is half of the site and datatype combination which is used to identify all time series data by SDI. Every datatype must have a unit defined in hdb_unit and a physical quantity defined in hdb_physical_quantity. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.DATATYPE_ID IS ''Unique identifier of the datatype. No implicit meaning'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.DATATYPE_NAME IS ''Name of the datatype, in full'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.DATATYPE_COMMON_NAME IS ''Name of datatype, in shortened common name for display purpose'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.PHYSICAL_QUANTITY_NAME IS ''Physical quantity name of the datatype'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.UNIT_ID IS ''Unit_id in which this datatype is stored.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.ALLOWABLE_INTERVALS IS ''Allowable intervals of the datatype (non-instant,instant,either)'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.AGEN_ID IS ''ID of Agency responsible for the datatype'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_DATATYPE.CMMNT IS ''Comment'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DATATYPE_ARCHIVE is ''Archive table of HDB_DATATYPE'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DATATYPE_FEATURE is ''Holds data to describe features of datatypes.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DATE_TIME_UNIT is ''Holds the date and time units.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DERIVATION_FLAG is ''Obsolete since we are no longer using the derivation application. A validation flag is now used for data that goes through validation.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DIMENSION is ''Defines the potential dimensions that units and physical quantities represent.The dimension_id is linked to the unit_id in hdb_unit and to the physical quantity in hdb_physical_quantity. Every hdb unit must have a dimension defined and every hdb physical quantity must also have a dimension defined.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DIVTYPE is ''Holds diversion types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_DMI_UNIT_MAP is ''Connects units between HDB and RiverWare DMI.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_DATA_CODE is ''Connects external data codes. Part of Generic Mapping, links names of datatypes used by other entities to datatype_ids.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_DATA_CODE_ARCHIVE is ''Archive table of HDB_EXT_DATA_CODE '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_DATA_CODE_SYS is ''Holds external data code systems. Part of Generic Mapping. It links the external systems to the agency id in hdb_agen.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_DATA_SOURCE is ''Holds the external data sources. Part of Generic Mapping. Presented as the "mapping id" in RiverWare HDB Database DMIs, it commonly has the same name as a model in hdb_model.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_DATA_SOURCE_ARCHIVE is ''Archive table of HDB_EXT_DATA_SOURCE'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_SITE_CODE is ''Part of Generic Mapping, links names of sites used by other entities to site_ids.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_SITE_CODE_ARCHIVE is ''Archive table of HDB_EXT_SITE_CODE'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_EXT_SITE_CODE_SYS is ''Connects external site code systems. Part of Generic Mapping, links the external systems to the agency id in hdb_agen.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_FEATURE is ''Holds features that are used extensively in representing Consumptive Uses and Losses data like crops, livestock, etc.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_FEATURE_CLASS is ''Holds feature classes that are used extensively in representing Consumptive Uses and Losses data like crops, livestock, etc.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_FEATURE_PROPERTY is ''Holds feature properties, connects features with properties and assigns values to the properties. Used extensively in representing Consumptive Uses and Losses data like crops, livestock, etc.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_GAGETYPE is ''Holds gage types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_INTERVAL is ''Holds intervals used in hdb   instant, hour, day, etc.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_LOADING_APPLICATION is ''Holds the valid loading applications. Loading application id is required in r_base table.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_METHOD is ''Holds the method by which time series data is computed, if applicable. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_METHOD_CLASS is ''Holds method classes. Higher level of method, one must be assigned to each method in hdb_method. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_METHOD_CLASS_TYPE is ''Holds method class types. Yet one level higher in the method chain, one must be assigned to each method class in hdb_method_class.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_MODEL is ''Describes the model information. Every model is defined in this table and assigned an id.Typically this is a RiverWare model, but it is also used for water use forecasts and schedules.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_MODEL_COORD is ''Holds the model id of coordinated models, and the site codes that share the model.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_MODELTYPE is ''Holds model types. Connects to ref_model_run M:mid-month P:preliminary F:Final '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_OBJECTTYPE is ''Holds object types. Connects to hdb_site, categorizes the site by type or function '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_OPERATOR is ''Holds arithmetic operators for addition, subtraction, multiplication, division'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_OVERWRITE_FLAG is ''Holds overwrite flags that is used to indicate that this datum is an overwrite, and cannot be overwritten by any computation. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_PHYSICAL_QUANTITY is ''Holds physical quantities that are used to describe data in hdb_datatype. Each datatype must be assigned to a physical quantity name.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_PROPERTY is ''Holds properties that are used in representing Consumptive Uses and Losses data like crops, livestock, etc. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_RATING_ALGORITHM is ''Holds algorithms used for rating table lookups.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_RATING_TYPE is ''Holds types of rating tables. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_RIVER is ''Holds rivers and assigns an id for each.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_RIVER_REACH is ''Holds river reaches and assigns an id for each. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_SITE is ''Describes all sites that store data in hdb. The site_id comprises half of the SDI which is used to identify all time series data. Major hdb table.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.SITE_ID IS ''Unique identifier. No implicit meaning.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.SITE_NAME IS ''Name of site, in full.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.SITE_COMMON_NAME IS ''Name of site, in shortened common name for display purpose.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.OBJECTTYPE_ID IS ''Indicator of objecttype that this site is. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.PARENT_SITE_ID IS ''Identifier of site that sits at this same geographic location,if there is one. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.PARENT_OBJECTTYPE_ID IS ''Identifier of objecttype that the parent site is.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.STATE_ID IS ''State in which this site resides.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.BASIN_ID IS ''Basin in which this site resides.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.LAT IS ''Latitude of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.LONGI IS ''Longitude of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.HYDROLOGIC_UNIT IS ''Hydrologic unit of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.SEGMENT_NO IS ''Segment number of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.RIVER_MILE IS ''River mile.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.ELEVATION IS ''Elevation of site, in customary units for this installation.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.NWS_CODE IS ''National Weather Service code of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.SCS_ID IS ''National Resource Conservation Service (formerly Soil Conservation Service) code of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.SHEF_CODE IS ''SHEF code of site.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.USGS_ID IS ''United States Geological Survey identifier of site'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE.DB_SITE_CODE IS ''Database site code for database which is responsible for data for this site. Foreign key to ref_db_list. Used for island/snapshot databases as well in master database.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_SITE_ARCHIVE is ''Archive table of HDB_SITE '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_SITE_DATATYPE is ''Describes site_datatypes that identifies all time series data by combining the site_id and datatype_id to create a site_datatype_id (SDI). All SDIs are unique and any data that is stored must have an SDI. Major hdb table.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE_DATATYPE.SITE_ID IS ''Site to which this site-datatype applies'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE_DATATYPE.DATATYPE_ID IS ''Datatype to which this site-datatype belongs'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column HDB_SITE_DATATYPE.SITE_DATATYPE_ID IS ''Unique identifier of site-datatype combination. No implicit meaning.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_SITE_DATATYPE_ARCHIVE is ''Archive table of HDB_SITE_DATATYPE '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_STATE is ''Holds all states with a state id. State_id is a part of the hdb_site table. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_UNIT is ''Holds all units with a unit id. Unit_id is a required field of the hdb_datatype table. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_USBR_OFF is ''Holds regional and field office names within United States Bureau of Reclamation. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table HDB_VALIDATION is ''Holds the allowable validation flags.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- COMMENTS on REF_ tables 

BEGIN EXECUTE IMMEDIATE 'comment on table REF_APP_DATA_SOURCE is ''Holds the application data sources. Foreign key to hdb_data_source'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_AUTH_SITE is ''Holds site IDs with roles'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_AUTH_SITE_DATATYPE is ''Holds site-datatype-ids with roles'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_DB_LIST is ''Holds database names, database site codes and the minimum and maximum coordinated model run id for each site. Referenced in model run management and also when refreshing snapshots (materialized views) of the hdb_ tables'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_DB_PARAMETER is ''Holds HDB database global parameters like acl group, timezone, db_release_version etc. Referenced in modify_r_base_raw, hdb_poet, write_to_hdb, delete_from_hdb and hdb_utilities. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_DIV is ''Holds diversion information, connecting diversion sites to types of diversions. Foreign key to hdb_divtype. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_ENSEMBLE is ''Main ensemble table that identifies and describes all ensembles'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_ENSEMBLE_ARCHIVE is ''Archive table of REF_ENSEMBLE'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_ENSEMBLE_KEYVAL is ''Lookup table for key_name and key_value for the ensemble '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_ENSEMBLE_KEYVAL_ARCHIVE is ''Archive table of REF_ENSEMBLE_KEYVAL '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_ENSEMBLE_TRACE is ''Lookup table for ensemble trace '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_ENSEMBLE_TRACE_ARCHIVE is ''Archive table of REF_ENSEMBLE_TRACE '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_EXT_SITE_DATA_MAP is ''Maps external site and datatype names to specific HDB SDIs. Must be unique per site/datatype/SDI combo for a specific data source. Part of Generic Mapping, used extensively for RiverWare object/slot names, as well as data loaders and reporting tools. Can be used to map any external codes to SDIs.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_EXT_SITE_DATA_MAP_ARCHIVE is ''Archive table of REF_EXT_SITE_DATA_MAP'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_EXT_SITE_DATA_MAP_KEYVAL is ''Additional key/value pairs that can be used for specific mappings in ref_ext_site_data_map. Part of Generic Mapping.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_EXT_SITE_DATA_MAP_KEY_ARCH is ''Archive table of REF_EXT_SITE_DATA_MAP_KEYVAL'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_FILETYPE is ''Represents Hydromet archive and dayfile types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_PCODE is ''Describes Hydromet parameter codes (pcodes) with units and scales.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_PCODE_OBJECTTYPE is ''Connects Hydromet pcodes to HDB objecttypes, obsolete after datatype restrictions on objecttypes were dropped.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_SITE is ''Describes hydromet sites'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_SITE_DATATYPE is ''Manages processing of hydromet sources of SDIs. May be obsolete since Java Hydromet loader was written.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_SITE_HDBID is ''Connects hydromet site codes to objectypes and HDB site_ids.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HM_SITE_PCODE is ''Connects Hydromet site/pcode/filetypes to HDB SDIs.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_INSTALLATION is ''Identifies the database instance as a snapshot or a master installation'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_INTERVAL_COPY_LIMITS is ''Holds the limits for data that is checked for validation by the validation procedure.It is checked by SDI and interval after it enters r_base. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_INTER_COPY_LIMITS_ARCHIVE is ''Archive table of REF_INTERVAL_COPY_LIMITS'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_INTERVAL_REDEFINITION is ''Allows the definition of the offset of any HDB interval. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_INTERVAL_REDEF_ARCHIVE is ''Archive table of REF_INTERVAL_REDEFINITION. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_LOADING_APPLICATION_PROP is ''Used to store properties of any loading application.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_MODEL_RUN is ''Holds all the model run information.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.MODEL_RUN_ID IS ''Unique identifier of the model run. No implicit meaning.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.MODEL_RUN_NAME IS ''Name descriptor of model run.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.MODEL_ID IS ''Model used to generate this model run. Foreign key to hdb_model.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.DATE_TIME_LOADED IS ''Date and time on which this model run was loaded.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.USER_NAME IS ''Audit information indicating the db user name who last modified the model run or its time series data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.EXTRA_KEYS_Y_N IS ''Y or N to indicate if the model run has any extra keys (key value pair data is stored in ref_model_run_keyval).'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.RUN_DATE IS ''Forecast date of the model run (only really applies to 24 month study).'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.START_DATE IS ''Start date of the forecast period for the model run.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.END_DATE IS ''End date of the forecast period for the model run.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.HYDROLOGIC_INDICATOR IS ''Text indicating hydrology used.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.MODELTYPE IS ''Valid model type from hdb_modeltype. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.TIME_STEP_DESCRIPTOR IS ''Text describing time step used in model run.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column REF_MODEL_RUN.CMMNT IS ''Comment.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_MODEL_RUN_ARCHIVE is ''Archive table of REF_MODEL_RUN.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_MODEL_RUN_KEYVAL is ''Holds additional model run information if extra_keys_y_n in ref_model_run is set to y.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_MODEL_RUN_KEYVAL_ARCHIVE is ''Archive table of REF_MODEL_RUN_KEYVAL.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_PHYS_QUAN_REFRESH_MONITOR is ''Holds status of a refresh for czar tables.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_RATING is ''Holds the actual rating table information for a rating_id. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_RATING_ARCHIVE is ''Archive table of REF_RATING.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_REFRESH_MONITOR is ''Holds status of a refresh for non-czar tables.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_RATING_TABLE is ''Describes the rating. Description for the rating table defined by all rows in ref_rating with that rating_id. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_RES is ''Holds reservoir and dam information.Table is mostly empty   use table ref_site_attr instead.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_RES_FLOWLU is ''Obsolete'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_RES_WSELU is ''Obsolete'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_ATTR is ''Holds values for attributes defined in hdb_attr and connects attributes to sites.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_ATTR_ARCHIVE is ''Archive table of REF_SITE_ATTR.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_COEF is ''Holds attribute values for sites. Can be used to store shifts for gaging sites, but those are generally stored as computation properties.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_COEF_DAY is ''Holds coefficients that change depending on the day of the month.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_COEF_MONTH is ''Holds coefficients that change depending on the calendar month.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_COEFLU is ''Obsolete'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_RATING is ''Holds the rating type (from hdb_rating_type) for sites that have rating table information in ref_rating. Same rating_id can be used for multiple sites.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SITE_RATING_ARCHIVE is ''Archive table of REF_SITE_RATING.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SOURCE_PRIORITY is ''Holds priority of sources, if the same site has more than one source for its data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SOURCE_PRIORITY_ARCHIVE is ''Archive table of REF_SOURCE_PRIORITY.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_SPATIAL_RELATION is ''Defines the spatial relationship between sites using HDB_ATTR entries, and can represent a fractional value.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_STR is ''Holds information on stream gages. Better to define common gage attributes in hdb_attr and populate ref_attr table, as this table only allows area, gage type, and owner. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_USER_GROUPS is ''Holds database user information with assigned group name. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ACCT is ''Lookup table for all accounts and account specific information.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ACCTTYPE is ''Lookup table for water account types. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ANNOTATION is ''Lookup table for all annotations on releases.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ANNOTATION_BORROW is ''Lookup table for all details on borrow annotations.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ANNOTATION_LEASE is ''Lookup table for lease annotation details.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ANNOTATION_LETTER is ''Lookup table for all details on letter annotations.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_ANNOTATIONTYPE is ''Lookup table for annotation types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_BORROWTYPE is '' Lookup table for types of borrows.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_DESTINATION is '' Lookup table for release destinations.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_DMI_SITE_MAP is ''Mapping of modeling objects onto HDB site IDs. Mapping can vary by model,object type, and date.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_EXCHANGE is '' Lookup table for all exchange specific information.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_EXCHANGE_PAYBACK is ''Lookup for exchange payback definitions.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_LEASETYPE is '' Lookup table for lease types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_MODEL_SITE_CONFIG is ''For each model in HDB, indicates sites and site configurations which are valid at a point in time. Initially intended for use with logical (account, supply, exchange) sites and subbasins, not physical sites. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_RELEASETYPE is ''Lookup table for all release types. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_REPORT is ''Lookup table for reports.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_REPORT_ANNOTATION is ''Lookup table for report annotation. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_SLOT_DATA is ''Lookup table for slot data. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_SUBBASIN_MEMBERS is '' Lookup table for all subbasin member relations; can vary by model and date.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_SUPPLY is ''Lookup table for all supplies and supply specific information.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_SUPPLY_ROLE is ''Lookup table for all supply roles as defined in Riverware.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_SUPPLYTYPE is ''Lookup table for all supply types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_WATER_OWNER is ''Lookup table for all water owners, or contractors.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_WA_WATERTYPE is ''Lookup table for water types.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- COMMENTS on interval, timeseries, CP and OTHER tables 

BEGIN EXECUTE IMMEDIATE 'comment on table ALARM_CURRENT is ''Holds currently asserted alarms.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table ALARM_EVENT is ''Holds alarm event information. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table ALARM_GROUP is ''Holds list of email address records. It is also associated with PROCESS_MONITOR and FILE_MONITOR records.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table ALARM_HISTORY is ''Holds alarms that have been asserted and resolved in the past. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table ALARM_LIMIT_SET is ''Holds the limits used to generate the alarm. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table ALARM_SCREENING is ''Describes alarm screening information. It is associated with a DATATYPE and optionally a SITE. Records without SITE assignment can define a kind of default for a data type. For example, you might define a screening with datatype=Incremental Precip and no site assignment. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGO_PROPERTY is ''Describes the properties associated with the algorithm. The properties apply to all computations using that algorithm.The property value in this table is the default value for any computation using the algorithm.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGO_PROPERTY_ARCHIVE is ''Archive table of CP_ALGO_PROPERTY'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGO_SCRIPT is ''Holds Base64 encoded scripts for algorithms, including Python code.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGO_TS_PARM is ''Defines the time series parameters associated with the algorithm and the number of input and output that the algorithm will accept.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGO_TS_PARM_ARCHIVE is ''Archive table of CP_ALGO_TS_PARM '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGORITHM is ''Holds all defined algorithms. Every computation must be assigned to an algorithm.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_ALGORITHM_ARCHIVE is ''Archive table of CP_ALGORITHM '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_DEPENDS is ''Represents the input parameters and dependencies of computations. Maintained by the compdepends process.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_DEPENDS_SCRATCHPAD is ''Scratchpad for the compdepends process.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_PROC_LOCK is ''Heartbeat table for computation processes. To gracefully shut down a computation process, remove its row from this table.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_PROPERTY is ''Holds the property name and value for a computation_id. The property names are dependent on the assigned algorithm. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_PROPERTY_ARCHIVE is ''Archive table of CP_COMP_PROPERTY'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_TASKLIST is ''Holds records to be processed by the Computation Processor-CP. Records deleted after processed by the CP. Data are written to this table by database procedures.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_TS_PARM is ''Holds the SDI associated with the input and output parameters for each computation. Specifies interval so the CP knows which interval table to retrieve the data from. Specifies model id (-1 if an r_ table).'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMP_TS_PARM_ARCHIVE is ''Archive table of CP_COMP_TS_PARM '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMPUTATION is ''Holds all defined computations.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_COMPUTATION_ARCHIVE is ''Archive table of CP_COMPUTATION '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_DEPENDS_NOTIFY is ''Populated by computation triggers and Java CP code whenever a computation or group is changed or deleted.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_HISTORIC_COMPUTATIONS is ''Used for historic computations to be performed once the interval time spread has past and this data is defined as an input parameter of an active calculation. Referenced in hdb_utilities.computations_cleanup.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_REMOTE_TRIGGERING is ''Used by computations that depend on input parameters in another database.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table CP_TS_ID is ''Completely specifies computation parameters, connecting SDIs, intervals, and real/model data to a specific single key.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table DECODES_SITE_EXT is ''Additional site data used by DECODES not represented in the HDB_SITE table. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table EMAIL_ADDR is ''Used by the Alarm Processor as alarm destinations.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table FILE_MONITOR is ''Describes and defines file_monitor. A File Monitor allows you to watch a directory or normal file for abnormal conditions, and then to send email notifications when they are detected. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_DAY is ''Holds model-generated data associated with daily intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_HOUR is ''Holds model-generated data associated with hourly intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_MONTH is ''Holds model-generated data associated with monthly intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_MONTHRANGE is ''Defines month range for model_run_id and SITE_DATATYPE_ID.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_MONTHSTAT is ''Holds statistical values computed for every month of the year of model data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_WY is ''Holds model-generated data associated with wateryear intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table M_YEAR is ''Holds model-generated data associated with yearly intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table PROCESS_MONITOR is ''Describes and defines process_monitor. For Process Monitors, the alarm monitor task will connect to one of the supported OpenDCS processes and collect events as they happen. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_BASE is ''Main entry point for all data coming into HDB.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.SITE_DATATYPE_ID IS ''The identifier for this site and datatype.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.INTERVAL IS ''The interval which the piece of data represents.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.START_DATE_TIME IS ''The beginning of the interval represented.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.END_DATE_TIME IS ''The end of the interval represented'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.VALUE IS ''Value'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.AGEN_ID IS ''ID of Agency responsible for data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.OVERWRITE_FLAG IS ''Used to tell applications that this data may not be overwritten by any data that does not also have an overwrite flag set. Often used to preserve manual edits of poorly transmitted data and approved data from USGS or other agencies.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.DATE_TIME_LOADED IS ''Date and time the value was loaded into HDB.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.VALIDATION IS ''Validation flag'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.COLLECTION_SYSTEM_ID IS ''Identifier representing the system from which the data came.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.LOADING_APPLICATION_ID IS ''Identifier representing the application which loaded the data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.METHOD_ID IS ''External method used to arrive at the data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.COMPUTATION_ID IS ''External computation used to arrive at the data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on column R_BASE.DATA_FLAGS IS ''Data Flag'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_BASE_ARCHIVE is ''Archive table of R_BASE. Holds the data that previously resided in r_base but was modified or deleted. This archive table can be queried to regenerate the data set that was active at any point in time.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_DAY is ''Holds real, observed data associated with daily intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_DAYSTAT is ''Holds statistical values computed for every day of the month of real data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_HOUR is ''Holds real, observed data associated with hourly intervals. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_HOURSTAT is ''Holds statistical values computed for every hour of the day arrived at from examining several days, months, or years of real data. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_INSTANT is ''Holds real, observed data where each value is associated with an instant in time.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_MONTH is ''Holds real, observed data associated with monthly intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_MONTHSTAT is ''Holds statistical values computed for every month of the year of real data. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_MONTHSTATRANGE is ''Holds statistical monthly range data arrived at from examining several years of monthly range data.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_OTHER is ''Holds other interval time series data, including irregular or non-business intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_WY is ''Holds real, observed data associated with wateryearly intervals.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_WYSTAT is ''Holds statistical values computed for wateryear. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_YEAR is ''Holds real, observed data associated with yearly intervals. '';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table R_YEARSTAT is ''Holds statistical values computed for year.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_DATABASE_VERSION is ''OpenDCS database schema version.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_GROUP is ''Represents time series groups for computations.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_GROUP_MEMBER_DT is ''Timeseries group members defined by datatype_id.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_GROUP_MEMBER_GROUP is ''Timeseries group members defined by subgroup.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_GROUP_MEMBER_OTHER is ''Timeseries group members defined by other parameters (objecttype, etc.).'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_GROUP_MEMBER_SITE is ''Timeseries group members defined by site_id.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_GROUP_MEMBER_TS is ''Timeseries group members defined by specific cp_ts_ids.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table TSDB_PROPERTY is ''Holds OPENDCS Global properties on the database components and HDB version.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'COMMENT ON TABLE REF_CHANGE_AGENT  IS ''Logs session and client metadata for auditing changes, allowing traceability of who made modifications to R_BASE.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'comment on table REF_LEGEND is ''Stores the colors and descriptions of legends.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
--For UC only. Other databases will expect to fail. 
BEGIN EXECUTE IMMEDIATE 'comment on table REF_HDB_INSTALLATION is ''Used in master czar database only and holds list of db_site names that require refreshes. Referenced in refresh_phys_quan_snap_wrap_ap and ref_phys_quan_refresh_monitor.'';'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
--Commit
commit;

-- Incorporating update_global_names.sql
-- set echo on
-- spool hdb_global_names_update.out

update ref_db_parameter set global_name = (select global_name from global_name);
commit;

-- spool off
-- exit;

-- Incorporating additional_db_mods.sql
-- set echo on
-- spool additional_db_mods.out

update DECODES.datatype set standard='HDB' where standard = 'hdb';
commit;

-- do the daily_ops procedure to update the DECODES.datatypes
BEGIN hdb_utilities.daily_ops; EXCEPTION WHEN OTHERS THEN NULL; END;
/

commit;

-- spool off
-- exit;

-- Recompiling schema objects (replacement for recompile_invalids.sql)
BEGIN
  DBMS_UTILITY.COMPILE_SCHEMA(schema => '${hdb_user}');
  DBMS_UTILITY.COMPILE_SCHEMA(schema => 'DECODES');
END;
/
