ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};


---------------------------------------------------------------------------
-- This file defines the computation meta-data classes for Oracle
---------------------------------------------------------------------------

-- set echo on
-- set feedback on
-- spool hdb_cp_objects.out

---------------------------------------------------------------------------
--  First create a role that will define the privileges to the calculation tables
---------------------------------------------------------------------------

-- taken out of this scripts since the roles have already been created including this one
-- create role calc_definition_role;

---------------------------------------------------------------------------
-- This table is populated by the DB trigger code to start computations
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMP_TASKLIST
(
	RECORD_NUM NUMBER NOT NULL,
	LOADING_APPLICATION_ID NUMBER NOT NULL,
	SITE_DATATYPE_ID NUMBER NOT NULL,
	INTERVAL VARCHAR2(24) NOT NULL,
	TABLE_SELECTOR VARCHAR2(24),               -- not req''d by some DBs
	VALUE FLOAT,                               -- not req''d for deleted data
	DATE_TIME_LOADED DATE NOT NULL,
	START_DATE_TIME DATE NOT NULL,
	DELETE_FLAG VARCHAR2(1) DEFAULT ''N'',
	MODEL_RUN_ID NUMBER DEFAULT NULL,           -- will be null for real data
        VALIDATION  CHAR(1),
        DATA_FLAGS  VARCHAR2(20),
      FAIL_TIME TIMESTAMP (6) WITH TIME ZONE,
	CONSTRAINT "CP_TASKLIST_PK" PRIMARY KEY ("RECORD_NUM") ENABLE
   ) ENABLE ROW MOVEMENT 
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

---------------------------------------------------------------------------
-- The sequence generator for this table
---------------------------------------------------------------------------
create sequence cp_tasklist_sequence  minvalue 1 start with 1 maxvalue 1000000000 CYCLE;
CREATE OR REPLACE PUBLIC SYNONYM cp_tasklist_sequence for cp_tasklist_sequence;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_tasklist_sequence to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on cp_tasklist_sequence to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table cp_tasklist
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_comp_tasklist for cp_comp_tasklist;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_comp_tasklist to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_tasklist to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_tasklist to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- The HDB_LOADING_APPLICATION table should already exist in HDB
---------------------------------------------------------------------------
-- See "tbl.ddl"

---------------------------------------------------------------------------
-- This table ensures that only one instance of a comp proc runs at a time
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMP_PROC_LOCK
(
	LOADING_APPLICATION_ID NUMBER NOT NULL,
	PID NUMBER NOT NULL,
	HOST VARCHAR2(400) NOT NULL,
	HEARTBEAT DATE NOT NULL,
	CUR_STATUS VARCHAR2(64) 
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

--  removed index to create primary key constraint instead
--CREATE UNIQUE INDEX CP_COMP_PROC_LOCK_IDX 
--	ON CP_COMP_PROC_LOCK(LOADING_APPLICATION_ID) tablespace HDB_idx;

-- primary key for table cp_comp_proc_lock
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_proc_lock  add constraint cpcpl_loading_appl_id_pk 
primary key (loading_application_id) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  foreign key loading_application_id
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_proc_lock add constraint cpcpl_loading_appl_id_fk 
foreign key (loading_application_id) 
references hdb_loading_application (loading_application_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table cp_comp_proc_lock
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_comp_proc_lock for cp_comp_proc_lock;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_comp_proc_lock to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_proc_lock to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_proc_lock to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents an algorithm.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_ALGORITHM
(
	ALGORITHM_ID NUMBER NOT NULL,
	ALGORITHM_NAME VARCHAR2(64),
	EXEC_CLASS VARCHAR2(160),
	CMMNT VARCHAR2(1000),
	DB_OFFICE_CODE integer default null    -- new feature
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

---------------------------------------------------------------------------
-- The sequence generator for this table
---------------------------------------------------------------------------
create sequence cp_algorithmidseq start with 50 nocache;
CREATE OR REPLACE PUBLIC SYNONYM cp_algorithmidseq for cp_algorithmidseq;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algorithmidseq to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on cp_algorithmidseq to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- removed to create a primary key constraint instead
--CREATE UNIQUE INDEX CP_COMP_PROC_LOCK_PKIDX
--	ON CP_ALGORITHM(ALGORITHM_ID) tablespace HDB_idx;

--  primary key algorithm_id for table cp_algorithm
BEGIN EXECUTE IMMEDIATE 'alter table cp_algorithm  add constraint cpa_algorithm_id_pk 
primary key (algorithm_id) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



CREATE UNIQUE INDEX CP_COMP_PROC_LOCK_SKIDX
	ON CP_ALGORITHM(ALGORITHM_NAME) tablespace HDB_idx;

---------------------------------------------------------------------------
-- the privileges for table cp_algorithm
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_algorithm for cp_algorithm;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algorithm to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_algorithm to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_algorithm to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents archive of the algorithm table.
-- added DB_OFFICE_CODE NUMBER(38,0) by IsmailO 08/2019
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_ALGORITHM_ARCHIVE
(
	ALGORITHM_ID NUMBER NOT NULL,
	ALGORITHM_NAME VARCHAR2(64),
	EXEC_CLASS VARCHAR2(160),
	CMMNT VARCHAR2(1000),
        ARCHIVE_REASON VARCHAR2(10) NOT NULL,
        DATE_TIME_ARCHIVED DATE     NOT NULL,
        ARCHIVE_CMMNT VARCHAR2(1000),
	DB_OFFICE_CODE NUMBER(38,0)
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_algorithm_archive
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_algorithm_archive for cp_algorithm_archive;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algorithm_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table stores info about time-series params for an algorithm.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_ALGO_TS_PARM
(
	ALGORITHM_ID NUMBER NOT NULL,
	ALGO_ROLE_NAME VARCHAR2(24) NOT NULL,
	PARM_TYPE VARCHAR2(24) NOT NULL
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- removed to create primary key constraint
--CREATE UNIQUE INDEX CP_ALGO_TS_PARM_PKIDX
--	ON CP_ALGO_TS_PARM(ALGORITHM_ID, ALGO_ROLE_NAME) tablespace HDB_idx;

-- primary key for table cp_algo_ts_parm
BEGIN EXECUTE IMMEDIATE 'alter table cp_algo_ts_parm  add constraint cpatp_algo_ts_parm_pk 
primary key (algorithm_id, algo_role_name) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  foreign key algorithm_id for table cp_algo_ts_parm
BEGIN EXECUTE IMMEDIATE 'alter table cp_algo_ts_parm add constraint cpatp_algorithm_id_fk 
foreign key (algorithm_id) 
references cp_algorithm (algorithm_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_algo_ts_parm
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_algo_ts_parm for cp_algo_ts_parm;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algo_ts_parm to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_algo_ts_parm to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_algo_ts_parm to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents archive of the time-series params table.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_ALGO_TS_PARM_ARCHIVE
(
	ALGORITHM_ID NUMBER NOT NULL,
	ALGO_ROLE_NAME VARCHAR2(24) NOT NULL,
	PARM_TYPE VARCHAR2(24) NOT NULL,
        ARCHIVE_REASON VARCHAR2(10) NOT NULL,
        DATE_TIME_ARCHIVED DATE     NOT NULL,
        ARCHIVE_CMMNT VARCHAR2(1000)
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_algo_ts_parm_archive
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_algo_ts_parm_archive for cp_algo_ts_parm_archive;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algo_ts_parm_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table stores additional named properties that apply to an algorithm.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_ALGO_PROPERTY
(
	ALGORITHM_ID NUMBER NOT NULL,
	PROP_NAME VARCHAR2(48) NOT NULL,
	PROP_VALUE VARCHAR2(240) NOT NULL
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- removed to create primary key constraint
-- CREATE UNIQUE INDEX CP_ALGO_PROPERTY_PKIDX
--	ON CP_ALGO_PROPERTY(ALGORITHM_ID, PROP_NAME) tablespace HDB_idx;

-- primary key for table cp_algo_property
BEGIN EXECUTE IMMEDIATE 'alter table cp_algo_property  add constraint cpap_algo_property_pk 
primary key (algorithm_id, prop_name) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- foreign key for table cp_algo_property for algorithm_id of table cp_algorithm
BEGIN EXECUTE IMMEDIATE 'alter table cp_algo_property add constraint cp_ap_algorithm_id_fk 
foreign key (algorithm_id) 
references cp_algorithm (algorithm_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_algo_property
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_algo_property for cp_algo_property;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algo_property to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_algo_property to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_algo_property to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents archive of the algo-property table.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_ALGO_PROPERTY_ARCHIVE
(
	ALGORITHM_ID NUMBER NOT NULL,
	PROP_NAME VARCHAR2(48) NOT NULL,
	PROP_VALUE VARCHAR2(240),
        ARCHIVE_REASON VARCHAR2(10) NOT NULL,
        DATE_TIME_ARCHIVED DATE     NOT NULL,
        ARCHIVE_CMMNT VARCHAR2(1000)
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_algo_property_archive
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_algo_property_archive for cp_algo_property_archive;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_algo_property_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents a computation.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMPUTATION
(
	COMPUTATION_ID NUMBER NOT NULL,
	COMPUTATION_NAME VARCHAR2(64) NOT NULL,
	ALGORITHM_ID NUMBER,                -- Must be assigned to execute.
	CMMNT VARCHAR2(2000),
	LOADING_APPLICATION_ID NUMBER,      -- App to execute this comp.
	                                     -- (null means not currently assigned)
	DATE_TIME_LOADED DATE NOT NULL,
	ENABLED VARCHAR2(1) DEFAULT ''N'',
	EFFECTIVE_START_DATE_TIME DATE NULL,
	EFFECTIVE_END_DATE_TIME DATE NULL,
	GROUP_ID integer default null,         -- for variable-site input params
    DB_OFFICE_CODE integer default null    -- new feature
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

---------------------------------------------------------------------------
-- The sequence generator for this table, not made public for a reason
---------------------------------------------------------------------------
create sequence cp_computationidseq start with 100 nocache;
CREATE OR REPLACE PUBLIC SYNONYM cp_computationidseq for cp_computationidseq;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_computationidseq to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on cp_computationidseq to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



--  removed to create primary key constraint instead
-- CREATE UNIQUE INDEX CP_COMPUTATION_PKIDX
-- 	ON CP_COMPUTATION(COMPUTATION_ID) tablespace HDB_idx;

--  primary key for table cp_computation
BEGIN EXECUTE IMMEDIATE 'alter table cp_computation  add constraint cpc_computation_id_pk 
primary key (computation_id) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


CREATE UNIQUE INDEX CP_COMPUTATION_SKIDX
	ON CP_COMPUTATION(COMPUTATION_NAME) tablespace HDB_idx;

--  check constraint to insure enable only Y or N
BEGIN EXECUTE IMMEDIATE 'alter table cp_computation add constraint check_enabled_YorN 
check (enabled in (''Y'',''N''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- foreign key for table cp_computation of algorithm_id from table cp_algorithm
BEGIN EXECUTE IMMEDIATE 'alter table cp_computation add constraint cpc_algorithm_id_fk 
foreign key (algorithm_id) 
references cp_algorithm (algorithm_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- foreign key for table cp_computation of loading_application_id from table hdb_loading_application
BEGIN EXECUTE IMMEDIATE 'alter table cp_computation add constraint cpc_loading_application_id_fk 
foreign key (loading_application_id) 
references hdb_loading_application (loading_application_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_computation
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_computation for cp_computation;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_computation to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_computation to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_computation to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



---------------------------------------------------------------------------
-- This table represents archive of the computation table.
-- added GROUP_ID and DB_OFFICE_CODE columns by IsmailO on 08/2019
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMPUTATION_ARCHIVE
(
	COMPUTATION_ID NUMBER NOT NULL,
	COMPUTATION_NAME VARCHAR2(64) NOT NULL,
	ALGORITHM_ID NUMBER,                -- Must be assigned to execute.
	CMMNT VARCHAR2(2000),
	LOADING_APPLICATION_ID NUMBER,      -- App to execute this comp.
	                                     -- (null means not currently assigned)
	DATE_TIME_LOADED DATE NOT NULL,
	ENABLED VARCHAR2(1) DEFAULT ''N'',
	EFFECTIVE_START_DATE_TIME DATE NULL,
	EFFECTIVE_END_DATE_TIME DATE NULL,
    ARCHIVE_REASON VARCHAR2(10) NOT NULL,
    DATE_TIME_ARCHIVED DATE     NOT NULL,
    ARCHIVE_CMMNT VARCHAR2(1000),
	GROUP_ID	NUMBER(38,0),
	DB_OFFICE_CODE	NUMBER(38,0)	
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_computation_archive
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_computation_archive for cp_computation_archive;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_computation_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table stores additional info about time-series params for a computation.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMP_TS_PARM
(
	COMPUTATION_ID NUMBER NOT NULL,
	ALGO_ROLE_NAME VARCHAR2(24) NOT NULL,
	SITE_DATATYPE_ID NUMBER,
	INTERVAL VARCHAR2(24),
	TABLE_SELECTOR VARCHAR2(24),      -- not req''d by some DBs
	DELTA_T NUMBER DEFAULT 0,
	MODEL_ID NUMBER DEFAULT NULL,     -- null for real data
    DATATYPE_ID   integer default null,      -- for variable-site output params
    DELTA_T_UNITS varchar2(24) default null  -- new feature
) 
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  primary key for table cp_comp_ts_parm
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_ts_parm  add constraint cpctp_compute_algoname_pk 
primary key (computation_id, algo_role_name) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- removed to use primary key constraint instead
--CREATE UNIQUE INDEX CP_COMP_TS_PARM
--	ON CP_COMP_TS_PARM(COMPUTATION_ID, ALGO_ROLE_NAME) tablespace HDB_idx;

--  foreign key for table cp_comp_ts_parm on computation_id from cp_computation
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_ts_parm add constraint cpctp_computation_id_fk 
foreign key (computation_id) 
references cp_computation (computation_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  following FK dropped for CP upgrade version 3.0 project
--  foreign key for table cp_comp_ts_parm on site_datatype_id from hdb_site_datatype
-- alter table cp_comp_ts_parm add constraint cpctp_site_datatype_id_fk 
-- foreign key (site_datatype_id) 
-- references hdb_site_datatype (site_datatype_id);

--  following FK dropped for CP upgrade version 3.0 project
--  foreign key for table cp_comp_ts_parm on interval from hdb_interval
-- alter table cp_comp_ts_parm add constraint cpctp_interval_fk 
-- foreign key (interval) 
--- references hdb_interval (interval_name);

--  check constraint to insure table_selector only M_ or R_
--disabled or removed for remote computation processor computations
--  M. A.  Bogner July 2010
-- alter table cp_comp_ts_parm add constraint check_ts_MORR 
-- check (table_selector in ('M_','R_'));

---------------------------------------------------------------------------
-- the privileges for table cp_comp_ts_parm
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_comp_ts_parm for cp_comp_ts_parm;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_comp_ts_parm to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_ts_parm to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_ts_parm to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents archive of the cp params table.
-- added DATATYPE_ID,DELTA_T_UNITS,SITE_ID columns by IsmailO on 08/2019
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMP_TS_PARM_ARCHIVE
(
	COMPUTATION_ID NUMBER NOT NULL,
	ALGO_ROLE_NAME VARCHAR2(24) NOT NULL,
	SITE_DATATYPE_ID NUMBER NOT NULL,
	INTERVAL VARCHAR2(24),
	TABLE_SELECTOR VARCHAR2(24),           -- not req''d by some DBs
	DELTA_T NUMBER DEFAULT 0,
	MODEL_ID NUMBER DEFAULT NULL,           -- null for real data
    ARCHIVE_REASON VARCHAR2(10) NOT NULL,
    DATE_TIME_ARCHIVED DATE     NOT NULL,
    ARCHIVE_CMMNT VARCHAR2(1000),
	DATATYPE_ID	NUMBER(38,0),
	DELTA_T_UNITS	VARCHAR2(24 BYTE),
	SITE_ID	NUMBER(38,0)
) 
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the priveleges for table cp_comp_ts_parm_archive
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_comp_ts_parm_archive for cp_comp_ts_parm_archive;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_comp_ts_parm_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table stores additional named properties that apply to a computation.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_COMP_PROPERTY
(
	COMPUTATION_ID NUMBER NOT NULL,
	PROP_NAME VARCHAR2(48) NOT NULL,
	PROP_VALUE VARCHAR2(512) NOT NULL
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  primary key for table cp_comp_property
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_property  add constraint cpcp_compute_propname_pk 
primary key (computation_id, prop_name) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- removed to use primary key constraint instead
--CREATE UNIQUE INDEX CP_COMP_PROPERTY
--	ON CP_COMP_PROPERTY(COMPUTATION_ID, PROP_NAME) tablespace HDB_idx;

-- foreign key for table cp_comp_property of computation_id on table cp_computation
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_property add constraint cpcp_computation_id_fk 
foreign key (computation_id) 
references cp_computation (computation_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table cp_comp_property
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_comp_property for cp_comp_property;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_comp_property to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_property to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on cp_comp_property to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents archive of the cp property table.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE CP_COMP_PROPERTY_ARCHIVE
(
	COMPUTATION_ID NUMBER NOT NULL,
	PROP_NAME VARCHAR2(48) NOT NULL,
	PROP_VALUE VARCHAR2(512) NOT NULL,
    ARCHIVE_REASON VARCHAR2(10) NOT NULL,
    DATE_TIME_ARCHIVED DATE     NOT NULL,
    ARCHIVE_CMMNT VARCHAR2(1000)
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table cp_comp_property_archive
-- everyone should be at least able to read it
---------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM cp_comp_property_archive for cp_comp_property_archive;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_comp_property_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents the cp_historic_computations table.
---------------------------------------------------------------------------

-- REM CP_HISTORIC_COMPUTATIONS
BEGIN EXECUTE IMMEDIATE '
  CREATE TABLE cp_historic_computations
  ( LOADING_APPLICATION_ID NUMBER NOT NULL ENABLE,
    SITE_DATATYPE_ID NUMBER NOT NULL ENABLE,
    INTERVAL VARCHAR2(16) NOT NULL ENABLE,
    START_DATE_TIME DATE NOT NULL ENABLE,
    END_DATE_TIME DATE NOT NULL ENABLE,
    TABLE_SELECTOR VARCHAR2(24) NOT NULL ENABLE,
    MODEL_RUN_ID NUMBER NOT NULL ENABLE,
    DATE_TIME_LOADED DATE NOT NULL ENABLE,
    READY_FOR_DELETE VARCHAR2(1)
)
tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

alter table cp_historic_computations add CONSTRAINT CP_HC_PK
PRIMARY KEY (LOADING_APPLICATION_ID,SITE_DATATYPE_ID,INTERVAL,START_DATE_TIME,END_DATE_TIME)
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table cp_historic_computations add CONSTRAINT CPHC_INTERVAL_FK
FOREIGN KEY (INTERVAL) REFERENCES HDB_INTERVAL(INTERVAL_NAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table cp_historic_computations add CONSTRAINT CPHC_LOADING_APP_ID_FK
FOREIGN KEY (LOADING_APPLICATION_ID)REFERENCES HDB_LOADING_APPLICATION(LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


create or replace public synonym cp_historic_computations for cp_historic_computations;

---------------------------------------------------------------------------
-- the priveleges for table cp_historic_computations
-- everyone should be at least able to read it
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'grant select on cp_historic_computations to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert,update, delete on cp_historic_computations to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert,update, delete on cp_historic_computations to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



---------------------------------------------------------------------------
-- This table represents archive of the cp_remote_triggering table.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE CP_REMOTE_TRIGGERING
(
	SITE_DATATYPE_ID		NUMBER(10) NOT NULL,
	INTERVAL			VARCHAR2(64) NOT NULL,
	TABLE_SELECTOR			VARCHAR2(24) NOT NULL,	
	DB_LINK				VARCHAR2(128) NOT NULL,
	EFFECTIVE_START_DATE_TIME	DATE,
	EFFECTIVE_END_DATE_TIME		DATE,
	ACTIVE_FLAG			VARCHAR2(1)  DEFAULT ''Y'' NOT NULL,
	DATE_TIME_LOADED		DATE
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


create or replace trigger cprt_before_insert_update
before             insert OR update 
on                cp_remote_triggering
for   each row
declare

begin
    
    /* created by M.  Bogner 05/07/2010  */
    /*
    The purpose of this trigger is to keep the date_time_loaded column updated 
    on inserts or updates
    
    */
    
	:new.date_time_loaded := sysdate;
 
end;
/

--drop public synonym CP_REMOTE_TRIGGERING;
create or replace public synonym CP_REMOTE_TRIGGERING for CP_REMOTE_TRIGGERING;
BEGIN EXECUTE IMMEDIATE 'grant select on CP_REMOTE_TRIGGERING to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_REMOTE_TRIGGERING to SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_REMOTE_TRIGGERING to APP_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_REMOTE_TRIGGERING to REF_META_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/




------------------------------------------------------------------------------------
-- This CP_TS_ID table is populated by the DB procedure code using CP Package
-- and the modify_raw procedures
-- This table is for unique timeseries id's based on the HDB columns in this table
------------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE CP_TS_ID
(
	TS_ID NUMBER NOT NULL,
	SITE_DATATYPE_ID NUMBER NOT NULL,
	INTERVAL VARCHAR2(24) NOT NULL,
	TABLE_SELECTOR VARCHAR2(24) NOT NULL,               
	MODEL_ID NUMBER NOT NULL,        -- will be -1 for real data
    DATE_TIME_LOADED DATE
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- the following were deleted due to reverting back to original design
--    TS_CODE VARCHAR2(500) NOT NULL , -- site_common_name.data_common_name.interval.table_selector.model_run_id
--    SITE_ID NUMBER NOT NULL,
--    DATAYPE_ID NUMBER NOT NULL,
--    MODEL_ID NUMBER NOT NULL,
---------------------------------------------------------------------------
-- The sequence generator for this table
---------------------------------------------------------------------------
create sequence cp_ts_id_sequence minvalue 1 start with 1 nocache;
create or replace public synonym cp_ts_id_sequence for cp_ts_id_sequence;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_ts_id_sequence to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on cp_ts_id_sequence to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table CP_TS_ID
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym CP_TS_ID for CP_TS_ID;
BEGIN EXECUTE IMMEDIATE 'grant select on CP_TS_ID to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_TS_ID to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_TS_ID to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table CP_TS_ID
------------------------------------------------------------

-- primary key for table CP_TS_ID
BEGIN EXECUTE IMMEDIATE 'alter table CP_TS_ID  add constraint CP_TS_ID_pk 
primary key (ts_id) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  foreign key for table CP_TS_ID on site_datatype_id from hdb_site_datatype
BEGIN EXECUTE IMMEDIATE 'alter table CP_TS_ID add constraint tsid_site_datatype_id_fk 
foreign key (site_datatype_id) 
references hdb_site_datatype (site_datatype_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  foreign key for table CP_TS_ID on interval from hdb_interval
BEGIN EXECUTE IMMEDIATE 'alter table CP_TS_ID add constraint tsid_interval_fk 
foreign key (interval) 
references hdb_interval (interval_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  check constraint to insure table_selector only M_ or R_
BEGIN EXECUTE IMMEDIATE 'alter table CP_TS_ID add constraint check_tsid_MORR 
check (table_selector in (''M_'',''R_''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Indexes for table CP_TS_ID
CREATE UNIQUE INDEX CP_TSID_IDX 
ON CP_TS_ID(site_datatype_id,interval,table_selector,model_id) tablespace HDB_idx;

-------------------------------------------------------------------------------------
-- This CP_COMPS_DEPENDS table is populated by the DB trigger code using CP Package
-------------------------------------------------------------------------------------
-- this table is an optimization used by trigger & java code to quickly
-- find computations that depend on a given ts_id (sdi++)
BEGIN EXECUTE IMMEDIATE 'create table cp_comp_depends
(
    ts_id integer not null,
    computation_id integer not null
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table cp_comp_depends add constraint cp_comp_depends_pk
    primary key (ts_id, computation_id) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table CP_COMP_DEPENDS
------------------------------------------------------------
-- foreign key for table cp_comp_depends of ts_id on table cp_ts_id
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_depends add constraint cp_comp_depends_ts_fk
foreign key (ts_id)
references cp_ts_id (ts_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- foreign key for table cp_comp_depends of computation_id on table cp_computation
BEGIN EXECUTE IMMEDIATE 'alter table cp_comp_depends add constraint cp_comp_depends_comp_fk
foreign key (computation_id)
references cp_computation (computation_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table CP_COMP_DEPENDS
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym CP_COMP_DEPENDS for CP_COMP_DEPENDS;
BEGIN EXECUTE IMMEDIATE 'grant select on CP_COMP_DEPENDS to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_COMP_DEPENDS to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_COMP_DEPENDS to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-------------------------------------------------------------------------------------
-- This CP_COMP_DEPENDS_SCRATCHPAD table is a workspace are used by the java CP Package
-------------------------------------------------------------------------------------
-- this table is an optimization workspace used by java code to quickly
-- find computations that depend on a given ts_id (sdi++)
BEGIN EXECUTE IMMEDIATE 'create table cp_comp_depends_scratchpad
(
    ts_id integer not null,
    computation_id integer not null
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table CP_COMP_DEPENDS_SCRATCHPAD
------------------------------------------------------------
-- NO foreign key for table cp_comp_depends_scratchpad

---------------------------------------------------------------------------
-- the privileges for table CP_COMP_DEPENDS_SCRATCHPAD
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym CP_COMP_DEPENDS_SCRATCHPAD for CP_COMP_DEPENDS_SCRATCHPAD;
BEGIN EXECUTE IMMEDIATE 'grant select on CP_COMP_DEPENDS_SCRATCHPAD to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_COMP_DEPENDS_SCRATCHPAD to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_COMP_DEPENDS_SCRATCHPAD to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


------------------------------------------------------------------------------------
-- This CP_DEPENDS_NOTIFY table is populated by 
--  Database triggers and java CP code whenever a computation or group is changed
--  and when a new timeseries ID is created or one is deleted
------------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE cp_depends_notify
(
	RECORD_NUM NUMBER NOT NULL,
	EVENT_TYPE CHAR NOT NULL,
	KEY NUMBER NOT NULL,
	DATE_TIME_LOADED TIMESTAMP with TIME ZONE NOT NULL               
)
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

---------------------------------------------------------------------------
-- The sequence generator for this table
---------------------------------------------------------------------------
create sequence cp_notify_sequence minvalue 1 start with 1 nocache;
create or replace public synonym cp_notify_sequence for cp_notify_sequence;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_notify_sequence to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on cp_notify_sequence to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table CP_DEPENDS_NOTIFY
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym CP_DEPENDS_NOTIFY for CP_DEPENDS_NOTIFY;
BEGIN EXECUTE IMMEDIATE 'grant select on CP_DEPENDS_NOTIFY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_DEPENDS_NOTIFY to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on CP_DEPENDS_NOTIFY to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table CP_DEPENDS_NOTIFY
------------------------------------------------------------

-- primary key for table CP_TS_ID
BEGIN EXECUTE IMMEDIATE 'alter table CP_DEPENDS_NOTIFY  add constraint CP_DEPENDS_NOTIFY_PK 
primary key (record_num) 
using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  check constraint to insure event_type in t,c,g,d,f
BEGIN EXECUTE IMMEDIATE 'alter table CP_DEPENDS_NOTIFY add constraint EVENTTYPE_IS_TCGDF 
check (event_type in (''T'',''C'',''G'',''D'',''F''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- Tables for Time Series Groups
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- This table represents the lists of groups for the computations.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'create table tsdb_group
(
    group_id integer not null,
    group_name varchar(64) not null,
    group_type varchar(24) not null,
    group_description varchar(1000),
    db_office_code integer
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table tsdb_group add constraint tsdb_group_pk
    primary key (group_id) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


create unique index tsdb_group_idx
    on tsdb_group(group_name, db_office_code) tablespace hdb_idx;

---------------------------------------------------------------------------
-- the privileges for table TSDB_GROUP
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym TSDB_GROUP for TSDB_GROUP;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUP to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

---------------------------------------------------------------------------
-- The sequence generator for this table
---------------------------------------------------------------------------
create sequence TSDB_GROUPIDSEQ minvalue 1 start with 1 nocache;
create or replace public synonym TSDB_GROUPIDSEQ for TSDB_GROUPIDSEQ;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUPIDSEQ to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUPIDSEQ to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents the lists of groups for the computaions.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'create table tsdb_group_member_ts
(
    group_id integer not null,
    data_id integer not null     -- Equivalent to ts_code in CWMS, ts_id in HDB
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- primary key for table TSDB_GROUP_MEMBER_TS
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_ts add constraint tsdb_group_member_ts_pk
    primary key (group_id, data_id) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table TSDB_GROUP_MEMBER_TS
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_ts add constraint tsdb_gmts_group_fk
    foreign key (group_id) references tsdb_group (group_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_ts add constraint tsdb_gmts_tsid_fk
    foreign key (data_id) references cp_ts_id (ts_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table TSDB_GROUP_MEMBER_TS
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym TSDB_GROUP_MEMBER_TS for TSDB_GROUP_MEMBER_TS;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUP_MEMBER_TS to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_TS to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_TS to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents the lists of groups for the computations.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'create table tsdb_group_member_group
(
    parent_group_id integer not null,
    child_group_id integer not null,
    include_group varchar2(1) default ''A''     --A: add; S: substract; I: intersect
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table tsdb_group_member_group add constraint tsdb_group_member_group_pk
    primary key (parent_group_id, child_group_id) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table TSDB_GROUP_MEMBER_GROUP
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_group add constraint tsdb_gmg_parent_fk
    foreign key (parent_group_id) references tsdb_group (group_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table tsdb_group_member_group add constraint tsdb_gmg_child_fk
    foreign key (child_group_id) references tsdb_group (group_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table TSDB_GROUP_MEMBER_GROUP
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym TSDB_GROUP_MEMBER_GROUP for TSDB_GROUP_MEMBER_GROUP;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUP_MEMBER_GROUP to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_GROUP to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_GROUP to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents the lists of groups for a particular datatype.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'create table tsdb_group_member_dt
(
    group_id integer not null,
    data_type_id integer not null
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Primary Key and Indexes for table TSDB_GROUP_MEMBER_DT
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_dt add constraint tsdb_group_member_dt_pk
    primary key (group_id, data_type_id) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table TSDB_GROUP_MEMBER_DT
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_dt add constraint tsdb_gmdt_group_fk
    foreign key (group_id) references tsdb_group (group_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table tsdb_group_member_dt add constraint tsdb_gmdt_datatype_fk
    foreign key (data_type_id) references hdb_datatype (datatype_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table TSDB_GROUP_MEMBER_DT
-- everyone should be at least able to read it

---------------------------------------------------------------------------
create  or replace public synonym TSDB_GROUP_MEMBER_DT for TSDB_GROUP_MEMBER_DT;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUP_MEMBER_GROUP to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_DT to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_DT to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents the lists of sites that belong to a particular group.
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'create table tsdb_group_member_site
(
    group_id integer not null,
    site_id integer not null
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Primary Key and Indexes for table TSDB_GROUP_MEMBER_SITE
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_site add constraint tsdb_group_member_site_pk
    primary key (group_id, site_id) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table TSDB_GROUP_MEMBER_SITE
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_site add constraint tsdb_gms_site_fk
    foreign key (site_id) references hdb_site (site_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table tsdb_group_member_site add constraint tsdb_gms_group_fk
    foreign key (group_id) references tsdb_group (group_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table TSDB_GROUP_MEMBER_SITE
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym TSDB_GROUP_MEMBER_SITE for TSDB_GROUP_MEMBER_SITE;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUP_MEMBER_SITE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_SITE to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_SITE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- This table represents the lists of attributes for a particular group.
-- groups can be restricted by other attributes like interval, duration, version.
-- this associates a interval code to a group
---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'create table tsdb_group_member_other
(
    group_id integer not null,
    member_type varchar2(24) not null,
    member_value varchar(200) not null
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Primary Key and Indexes for table TSDB_GROUP_MEMBER_OTHER
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_other add constraint tsdb_group_member_other_pk
    primary key (group_id, member_type, member_value) using index tablespace hdb_idx'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the Foreign Keys for table TSDB_GROUP_MEMBER_OTHER
------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table tsdb_group_member_other add constraint tsdb_gmo_group_fk
    foreign key (group_id) references tsdb_group (group_id)
    on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


---------------------------------------------------------------------------
-- the privileges for table TSDB_GROUP_MEMBER_OTHER
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym TSDB_GROUP_MEMBER_OTHER for TSDB_GROUP_MEMBER_OTHER;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_GROUP_MEMBER_OTHER to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_OTHER to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_GROUP_MEMBER_OTHER to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


------------------------------------------------------------------------------------
-- This TSDB_PROPERTY table is populated by 
--  Database triggers and java CP code whenever a computation or group is changed
--  and when a new timeseries ID is created or one is deleted
------------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE tsdb_property
(
    prop_name VARCHAR2(24) NOT NULL,
    prop_value VARCHAR2(240) NOT NULL
) 
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- removed so that value is in standarad data import
-- Initial inserted values for this table...
-- insert into TSDB_PROPERTY ( prop_name,prop_value) values ('autoCreateTs', 'Y');
-- commit;

---------------------------------------------------------------------------
-- unique index to keep prop_name unique per instance
---------------------------------------------------------------------------
CREATE UNIQUE INDEX tsdb_property_nameidx on tsdb_property(prop_name) tablespace HDB_idx ;

---------------------------------------------------------------------------
-- the privileges for table TSDB_PROPERTY
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym TSDB_PROPERTY for TSDB_PROPERTY;
BEGIN EXECUTE IMMEDIATE 'grant select on TSDB_PROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_PROPERTY to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on TSDB_PROPERTY to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



---------------------------------------------------------------------------
-- This table represents version of CP Processor code table.
---------------------------------------------------------------------------

-------------------------------------------------
-- insert the default record value
-------------------------------------------------

-- removed so that data is now in the standard data import
--insert into tsdb_database_version values (8,'Open Source Time Series');
--commit;

---------------------------------------------------------------------------
-- the priveleges for table tsdb_database_version
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create or replace public synonym tsdb_database_version for tsdb_database_version;
BEGIN EXECUTE IMMEDIATE 'grant select on tsdb_database_version to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-------------------------------------------------------
--   the view that is used to determine what computation definitions are active
--

-------------------------------
-- additional needed privileges
-------------------------------
-- the following removed and added to rolepriv.ddl
--grant select,insert,update on hdb_loading_application to calc_definition_role;
--grant select,insert,update on hdb_site_datatype to calc_definition_role;



--------------------------------------------------------------------------
-- This script updates CP tables from an USBR HDB 5.2 CCP Schema to 
-- OpenDCS 6.2 Schema.
--------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CP_ALGORITHM MODIFY(EXEC_CLASS VARCHAR2(240 BYTE))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CP_ALGO_PROPERTY MODIFY(PROP_VALUE  NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE TSDB_DATABASE_VERSION RENAME COLUMN VERSION TO DB_VERSION'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


UPDATE TSDB_GROUP_MEMBER_GROUP SET INCLUDE_GROUP = 'A' WHERE INCLUDE_GROUP IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TSDB_GROUP_MEMBER_GROUP MODIFY(INCLUDE_GROUP VARCHAR2(1 BYTE) NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE TSDB_GROUP_MEMBER_OTHER MODIFY(MEMBER_VALUE VARCHAR2(240 BYTE))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TSDB_GROUP_MEMBER_TS RENAME COLUMN data_id TO TS_ID'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CP_COMP_PROC_LOCK RENAME COLUMN HOST TO HOSTNAME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-----------------------------------------------------------------------
-- This was removed for HDB!
-- ALTER TABLE CP_COMP_TS_PARM RENAME COLUMN INTERVAL TO INTERVAL_ABBR;
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE CP_COMP_TS_PARM MODIFY(TABLE_SELECTOR VARCHAR2(240 BYTE))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CP_COMP_TS_PARM MODIFY(DELTA_T NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE CP_COMP_TS_PARM ADD(SITE_ID NUMBER(*,0))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
DROP INDEX CP_COMP_TASKLIST_IDX_APP'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE UNIQUE INDEX CP_COMP_TASKLIST_IDX_APP ON CP_COMP_TASKLIST
(LOADING_APPLICATION_ID, RECORD_NUM) tablespace HDB_IDX;
BEGIN EXECUTE IMMEDIATE '

ALTER TABLE CP_COMP_DEPENDS_SCRATCHPAD
 ADD CONSTRAINT CP_COMP_DEPENDS_SCRATCHPAD_FK
  FOREIGN KEY (COMPUTATION_ID)
  REFERENCES CP_COMPUTATION (COMPUTATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


update CP_COMPUTATION set GROUP_ID = null where GROUP_ID = -1;
BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CP_COMPUTATION
 ADD CONSTRAINT CP_COMPUTATION_FKGR
  FOREIGN KEY (GROUP_ID)
  REFERENCES TSDB_GROUP (GROUP_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '  
CREATE TABLE CP_ALGO_SCRIPT
(
	ALGORITHM_ID NUMBER(*,0) NOT NULL,
	SCRIPT_TYPE CHAR NOT NULL,
	BLOCK_NUM NUMBER(4,0) NOT NULL,
	SCRIPT_DATA VARCHAR2(4000) NOT NULL,
	PRIMARY KEY (ALGORITHM_ID, SCRIPT_TYPE, BLOCK_NUM)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CP_ALGO_SCRIPT
    ADD CONSTRAINT CP_ALGO_SCRIPT_FK
    FOREIGN KEY (ALGORITHM_ID)
    REFERENCES CP_ALGORITHM (ALGORITHM_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE ' 
GRANT SELECT,INSERT,UPDATE,DELETE ON CP_ALGO_SCRIPT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM CP_ALGO_SCRIPT FOR  CP_ALGO_SCRIPT;
BEGIN EXECUTE IMMEDIATE '
GRANT SELECT,INSERT,UPDATE,DELETE ON DECODES_SITE_EXT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM DECODES_SITE_EXT FOR  DECODES_SITE_EXT;
BEGIN EXECUTE IMMEDIATE '

GRANT REFERENCES ON HDB_LOADING_APPLICATION TO DECODES'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


CREATE OR REPLACE TRIGGER  cp_comp_ts_parm_delete
after delete on cp_comp_ts_parm
for each row
begin
/*  This trigger created by M.  Bogner  04/05/2006
    This trigger archives any deletes to the table
    cp_comp_ts_parm.

    updated 5/19/2008 by M. Bogner to update the date_time_loaded
    collumn of cp_computation table
*/
insert into cp_comp_ts_parm_archive (
   COMPUTATION_ID,
   ALGO_ROLE_NAME,
   SITE_DATATYPE_ID,
   INTERVAL,
   TABLE_SELECTOR,
   DELTA_T,
   MODEL_ID,
   ARCHIVE_REASON,
   DATE_TIME_ARCHIVED,
   ARCHIVE_CMMNT
)
values (
  :old.COMPUTATION_ID,
  :old.ALGO_ROLE_NAME,
  :old.SITE_DATATYPE_ID,
  :old.INTERVAL,
  :old.TABLE_SELECTOR,
  :old.DELTA_T,
  :old.MODEL_ID,
  'DELETE',
  sysdate,
  NULL);

/* now update parent table's date_time_loaded for sql statements issued on this table */
  hdb_utilities.touch_cp_computation(:old.computation_id);
end;
/
BEGIN EXECUTE IMMEDIATE '
DROP VIEW SITE_TO_DECODES_NAME_VIEW'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP VIEW SITE_TO_DECODES_SITE_VIEW'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


commit;


--------------------------------------------------------------------------
-- This script updates CP tables from HDB 6.3 CCP Schema to OpenDCS 6.4 Schema.
--
--------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'alter table cp_algorithm_archive modify exec_class varchar2(240)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table cp_algorithm_archive modify algorithm_name varchar2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

commit;


--------------------------------------------------------------------------
-- This script updates CP tables from an USBR HDB 6.4 CCP Schema to 
-- OpenDCS 6.6 Schema.
--------------------------------------------------------------------------

-- CP_COMP_TS_PARM.SITE_DATATYPE_ID is nullable, modify archive table to match:
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE CP_COMP_TS_PARM_ARCHIVE MODIFY (SITE_DATATYPE_ID NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



------------------------------------------------------------------------------
-- OpenDCS Alarm Tables for Oracle
------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ALARM_CURRENT
(
    TS_ID int NOT NULL,
    LIMIT_SET_ID int NOT NULL,
    ASSERT_TIME NUMBER(19) NOT NULL,
    DATA_VALUE double precision,
    DATA_TIME NUMBER(19),
    ALARM_FLAGS int NOT NULL,
    MESSAGE varchar2(256),
    LAST_NOTIFICATION_SENT NUMBER(19),
    LOADING_APPLICATION_ID INT
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ALARM_EVENT
(
	ALARM_EVENT_ID INT NOT NULL UNIQUE,
	ALARM_GROUP_ID INT NOT NULL,
	LOADING_APPLICATION_ID INT NOT NULL,
	PRIORITY INT NOT NULL,
	PATTERN varchar2(256)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ALARM_GROUP
(
	ALARM_GROUP_ID INT NOT NULL UNIQUE,
	ALARM_GROUP_NAME VARCHAR2(32) NOT NULL UNIQUE,
	LAST_MODIFIED NUMBER(19) NOT NULL
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ALARM_HISTORY
(
    TS_ID int NOT NULL,
    LIMIT_SET_ID int NOT NULL,
    ASSERT_TIME NUMBER(19) NOT NULL,
    DATA_VALUE double precision,
    DATA_TIME NUMBER(19),
    ALARM_FLAGS int NOT NULL,
    MESSAGE varchar2(256),
    END_TIME NUMBER(19) NOT NULL,
    CANCELLED_BY varchar2(32),
    LOADING_APPLICATION_ID INT
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ALARM_LIMIT_SET
(
    LIMIT_SET_ID int NOT NULL UNIQUE,
    SCREENING_ID int NOT NULL,
    season_name varchar2(24),
    reject_high double precision,
    critical_high double precision,
    warning_high double precision,
    warning_low double precision,
    critical_low double precision,
    reject_low double precision,
    stuck_duration varchar2(32),
    stuck_tolerance double precision,
    stuck_min_to_check double precision,
    stuck_max_gap varchar2(32),
    roc_interval varchar2(32),
    reject_roc_high double precision,
    critical_roc_high double precision,
    warning_roc_high double precision,
    warning_roc_low double precision,
    critical_roc_low double precision,
    reject_roc_low double precision,
    missing_period varchar2(32),
    missing_interval varchar2(32),
    missing_max_values int,
    hint_text varchar2(256),
	CONSTRAINT LIMIT_SET_SCRSEA_UNIQUE UNIQUE(SCREENING_ID, season_name)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ALARM_SCREENING
(
    SCREENING_ID int NOT NULL UNIQUE,
    SCREENING_NAME varchar2(32) NOT NULL UNIQUE,
    SITE_ID int,
    DATATYPE_ID int NOT NULL,
    START_DATE_TIME NUMBER(19),
    LAST_MODIFIED NUMBER(19) NOT NULL,
    ENABLED VARCHAR2(5) DEFAULT ''true'' NOT NULL,
    ALARM_GROUP_ID int,
    SCREENING_DESC varchar2(1024),
    LOADING_APPLICATION_ID INT,
	CONSTRAINT AS_SDI_START_UNIQUE UNIQUE(SITE_ID, DATATYPE_ID, START_DATE_TIME, LOADING_APPLICATION_ID)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE EMAIL_ADDR
(
	ALARM_GROUP_ID INT NOT NULL,
	ADDR VARCHAR2(256) NOT NULL,
	PRIMARY KEY (ALARM_GROUP_ID, ADDR)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE FILE_MONITOR
(
	ALARM_GROUP_ID INT NOT NULL,
	PATH VARCHAR2(256) NOT NULL,
	PRIORITY INT NOT NULL,
	MAX_FILES int,
	MAX_FILES_HINT VARCHAR2(128),
	-- Maximum Last Modify Time
	MAX_LMT VARCHAR2(32),
	MAX_LMT_HINT VARCHAR2(128),
	ALARM_ON_DELETE VARCHAR2(5),
	ON_DELETE_HINT VARCHAR2(128),
	MAX_SIZE NUMBER(19),
	MAX_SIZE_HINT VARCHAR2(128),
	ALARM_ON_EXISTS VARCHAR2(5),
	ON_EXISTS_HINT VARCHAR2(128),
	ENABLED VARCHAR2(5),
	PRIMARY KEY (ALARM_GROUP_ID, PATH)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PROCESS_MONITOR
(
	ALARM_GROUP_ID INT NOT NULL,
	LOADING_APPLICATION_ID INT NOT NULL,
	ENABLED VARCHAR2(5),
	PRIMARY KEY (ALARM_GROUP_ID, LOADING_APPLICATION_ID)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE PROCESS_MONITOR
	ADD CONSTRAINT PROCESS_MONITOR_FK1
	FOREIGN KEY (ALARM_GROUP_ID)
	REFERENCES ALARM_GROUP (ALARM_GROUP_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE FILE_MONITOR
	ADD CONSTRAINT FILE_MONITOR_FK1
	FOREIGN KEY (ALARM_GROUP_ID)
	REFERENCES ALARM_GROUP (ALARM_GROUP_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE EMAIL_ADDR
	ADD CONSTRAINT EMAIL_ADDR_FK1
	FOREIGN KEY (ALARM_GROUP_ID)
	REFERENCES ALARM_GROUP (ALARM_GROUP_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE ALARM_EVENT
	ADD CONSTRAINT ALARM_EVENT_FK1
	FOREIGN KEY (ALARM_GROUP_ID, LOADING_APPLICATION_ID)
	REFERENCES PROCESS_MONITOR (ALARM_GROUP_ID, LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PROCESS_MONITOR
	ADD CONSTRAINT PROCESS_MONITOR_FKLA
	FOREIGN KEY (LOADING_APPLICATION_ID)
	REFERENCES HDB_LOADING_APPLICATION(LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_SCREENING
    ADD CONSTRAINT ALARM_SCREENING_FKAGI
	FOREIGN KEY (ALARM_GROUP_ID)
    REFERENCES ALARM_GROUP (ALARM_GROUP_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_SCREENING ADD CONSTRAINT AS_APP_FK
	FOREIGN KEY (LOADING_APPLICATION_ID)
	REFERENCES HDB_LOADING_APPLICATION(LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_HISTORY
    ADD CONSTRAINT ALARM_HISTORY_FKLSI
	FOREIGN KEY (LIMIT_SET_ID)
    REFERENCES ALARM_LIMIT_SET (LIMIT_SET_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_HISTORY ADD CONSTRAINT AH_PK_UNIQUE 
  UNIQUE(TS_ID, LIMIT_SET_ID, ASSERT_TIME, LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '  
ALTER TABLE ALARM_HISTORY ADD CONSTRAINT AH_APP_FK
    FOREIGN KEY (LOADING_APPLICATION_ID)
    REFERENCES HDB_LOADING_APPLICATION(LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_CURRENT
    ADD CONSTRAINT ALARM_CURRENT_FKLSI
	FOREIGN KEY (LIMIT_SET_ID)
    REFERENCES ALARM_LIMIT_SET (LIMIT_SET_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_CURRENT ADD CONSTRAINT AC_PK_UNIQUE UNIQUE(TS_ID, LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_CURRENT ADD CONSTRAINT AC_APP_FK
    FOREIGN KEY (LOADING_APPLICATION_ID)
    REFERENCES HDB_LOADING_APPLICATION(LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ALARM_LIMIT_SET
    ADD CONSTRAINT LIMIT_SET_FKSI
	FOREIGN KEY (SCREENING_ID)
    REFERENCES ALARM_SCREENING (SCREENING_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



CREATE INDEX AS_LAST_MODIFIED ON ALARM_SCREENING (LAST_MODIFIED) tablespace HDB_IDX;

CREATE SEQUENCE ALARM_EVENTIdSeq nocache;
CREATE SEQUENCE ALARM_SCREENINGIdSeq nocache;
CREATE SEQUENCE ALARM_LIMIT_SETIdSeq nocache;

CREATE OR REPLACE PUBLIC SYNONYM ALARM_CURRENT FOR  ALARM_CURRENT;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_EVENT FOR  ALARM_EVENT;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_GROUP FOR  ALARM_GROUP;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_HISTORY FOR  ALARM_HISTORY;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_SCREENING FOR  ALARM_SCREENING;
CREATE OR REPLACE PUBLIC SYNONYM EMAIL_ADDR FOR  EMAIL_ADDR;
CREATE OR REPLACE PUBLIC SYNONYM FILE_MONITOR FOR  FILE_MONITOR;
CREATE OR REPLACE PUBLIC SYNONYM PROCESS_MONITOR FOR  PROCESS_MONITOR;


CREATE OR REPLACE PUBLIC SYNONYM ALARM_EVENTIdSeq FOR  ALARM_EVENTIdSeq;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_SCREENINGIdSeq FOR  ALARM_SCREENINGIdSeq;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_LIMIT_SETIdSeq FOR  ALARM_LIMIT_SETIdSeq;

-- The following 3 lines were missing from the initial release:
CREATE OR REPLACE PUBLIC SYNONYM ALARM_LIMIT_SET FOR  ALARM_LIMIT_SET;
CREATE SEQUENCE ALARM_GROUPIdSeq nocache;
CREATE OR REPLACE PUBLIC SYNONYM ALARM_GROUPIdSeq FOR  ALARM_GROUPIdSeq;


--Missing privileges added for Alarm on 07/01/2020
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT on ALARM_EVENTIDSEQ to CALC_DEFINITION_ROLE,SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT on ALARM_GROUPIDSEQ to CALC_DEFINITION_ROLE,SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT on ALARM_LIMIT_SETIDSEQ to CALC_DEFINITION_ROLE,SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT on ALARM_SCREENINGIDSEQ to CALC_DEFINITION_ROLE,SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



delete from tsdb_database_version;
insert into tsdb_database_version values(17, 'OPENDCS 6.6');

delete from decodesdatabaseversion;
insert into decodesdatabaseversion values(17, 'OPENDCS 6.6');

commit;


-- spool off
-- exit;
