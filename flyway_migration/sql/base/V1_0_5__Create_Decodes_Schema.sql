ALTER SESSION SET CURRENT_SCHEMA = decodes;
--
-- set echo on
-- spool decodes_schema.out

-----------------------------------------------------------------------
-- Single record DecodesDatabaseVersion table.
-- If this table doesn't exist, it means the database < 6.0
-- Some SQL code acts differently depending on the database version.
-----------------------------------------------------------------------


-- commented out since the table load of standard data will handle this
--INSERT into DECODESDatabaseVersion VALUES(8, NULL) ;
--commit;

/*  remove from HDB creation due to existing hdb tables
-----------------------------------------------------------------------
-- Sites & Site Names
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE Site
(
	id INTEGER NOT NULL,
	latitude VARCHAR(24),
	longitude VARCHAR(24),
	nearestCity VARCHAR(64),
	state VARCHAR(24),
	region VARCHAR(64),
	timezone VARCHAR(64),
	country VARCHAR(64),
	elevation FLOAT,
	elevUnitAbbr VARCHAR(24),
	description VARCHAR(800)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two sites have the same ID:
CREATE UNIQUE INDEX Site_IdIdx on Site (id)  tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE SiteName
(
	siteid INTEGER NOT NULL,
	nameType VARCHAR(24) NOT NULL,
	siteName VARCHAR(24) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees at most one site name of a given time per site.
CREATE UNIQUE INDEX SiteName_IdTypeIdx on SiteName (siteid, nameType)  tablespace HDB_idx;

end of removing comment  */

-----------------------------------------------------------------------
-- EquipmentModel & its properties.
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Site Properties are new for DECODES DB Version 8
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE SITE_PROPERTY
(
    site_id INTEGER NOT NULL,
    prop_name VARCHAR2(24) NOT NULL,
    prop_value VARCHAR2(240) NOT NULL
) 
tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-----------------------------------------------------------------------
-- Guarantees property names are unique within a Site
-----------------------------------------------------------------------
CREATE UNIQUE INDEX Site_Property_IdNameIdx
    on DECODES.SITE_PROPERTY (site_id, prop_name)  tablespace HDB_idx ; 
    
---------------------------------------------------------------------------
-- the privileges for table SITE_PROPERTY
-- everyone should be at least able to read it
---------------------------------------------------------------------------
create  or replace public synonym SITE_PROPERTY for DECODES.SITE_PROPERTY;
BEGIN EXECUTE IMMEDIATE 'grant select on DECODES.SITE_PROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on DECODES.SITE_PROPERTY to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on DECODES.SITE_PROPERTY to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

CREATE TABLE EquipmentModel
(
	id INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	company VARCHAR(64),
	model VARCHAR(64),
	description VARCHAR(400),
	equipmentType VARCHAR(24)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two EquipmentModels have the same ID:
CREATE UNIQUE INDEX EquipmentModel_IdIdx on EquipmentModel (id)  tablespace HDB_idx;

-- Guarantees no two EquipmentModels have the same name:
CREATE UNIQUE INDEX EquipmentModel_NmIdx on EquipmentModel (name)  tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE EquipmentProperty
(
	equipmentId INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	value VARCHAR(240) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees property names are unique within an EquipmentModel:
CREATE UNIQUE INDEX EquipmentProperty_IdNameIdx 
	on EquipmentProperty (equipmentId, name)  tablespace HDB_idx;


-----------------------------------------------------------------------
-- Enumeration & its values
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE Enum
(
	id INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	defaultValue VARCHAR(24)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two Enums have the same ID:
CREATE UNIQUE INDEX EnumIdIdx on Enum(id)  tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE EnumValue
(
	enumId INTEGER NOT NULL,
	enumValue VARCHAR(24) NOT NULL,
	description VARCHAR(400),
	execClass VARCHAR(160),
	editClass VARCHAR(160),
	sortNumber INTEGER
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees each EnumValue is unique within an Enum.
CREATE UNIQUE INDEX EnumValueIdx on EnumValue(enumId, enumValue);

-----------------------------------------------------------------------
-- Data Types & Equivalences
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE DataType 
(
	id INTEGER NOT NULL,
	standard VARCHAR(24) NOT NULL,
	code VARCHAR(24) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two DataTypes have the same ID:
CREATE UNIQUE INDEX DataType_IdIdx on DataType (id)  tablespace HDB_idx;

-- Guarantees no two DataTypes have the same standard & code:
CREATE UNIQUE INDEX DataTypeCode_IdIdx on DataType (standard, code)  tablespace HDB_idx;


-- An entry in the DataTypeEquivalence table says that the two 
-- data types represent the same type of data, but in different standards.
-- For example EPA 00063 is equivalent to SHEF HG
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE DataTypeEquivalence
(
	id0 INTEGER NOT NULL,
	id1 INTEGER NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees that each equivalence assertion is unique.
CREATE UNIQUE INDEX DataTypeEquivalence_Id1Idx 
	on DataTypeEquivalence (id0, id1)  tablespace HDB_idx;


-----------------------------------------------------------------------
-- Platforms & Platform Sensors
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE Platform
(
	id INTEGER NOT NULL,
	agency VARCHAR(64),
	isProduction VARCHAR(5) DEFAULT ''FALSE'',
	siteId INTEGER,
	configId INTEGER,
	description VARCHAR(400),
	lastModifyTime TIMESTAMP WITH TIME ZONE,
	expiration TIMESTAMP WITH TIME ZONE,
        platformDesignator VARCHAR(24)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PlatformProperty
(
	platformId INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	value VARCHAR(240) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two Platforms have the same ID:
CREATE UNIQUE INDEX Platform_IdIdx on Platform (id)  tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PlatformSensor
(
	platformId INTEGER NOT NULL,
	sensorNumber INTEGER NOT NULL,
	siteId INTEGER,
        dd_nu INTEGER
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PlatformSensorProperty
(
	platformId INTEGER NOT NULL,
	sensorNumber INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	value VARCHAR(240) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE TransportMedium
(
	platformId INTEGER NOT NULL,
	mediumType VARCHAR(24) NOT NULL,
	mediumId VARCHAR(64),   -- Holds DCP address or other identifier
	scriptName VARCHAR(24), -- soft link to script in this platform''s config.
	channelNum INTEGER,
	assignedTime INTEGER,
	transmitWindow INTEGER,
	transmitInterval INTEGER,
	equipmentId INTEGER,
	timeAdjustment INTEGER,
	preamble CHAR,
	timeZone VARCHAR(64)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two TransportMedia have same type and ID.
CREATE UNIQUE INDEX TransportMediumIdx on TransportMedium(mediumType,mediumId) tablespace HDB_idx;

-----------------------------------------------------------------------
-- Platform Configurations & Subordinate Entities
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PlatformConfig
(
	id INTEGER NOT NULL,
	name VARCHAR(64) NOT NULL,
	description VARCHAR(400),
	equipmentId INTEGER
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two PlatformConfigs have the same ID:
CREATE UNIQUE INDEX PlatformConfigIdIdx on PlatformConfig(id) tablespace HDB_idx;

-- Guarantees no two PlatformConfigs have the same name:
CREATE UNIQUE INDEX PlatformConfigNameIdx on PlatformConfig(name) tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ConfigSensor
(
	configId INTEGER NOT NULL,
	sensorNumber INTEGER NOT NULL,
	sensorName VARCHAR(64),
	recordingMode CHAR,
	recordingInterval INTEGER,     -- # seconds
	timeOfFirstSample INTEGER,     -- second of day
	equipmentId INTEGER,
	absoluteMin FLOAT,
	absoluteMax FLOAT,
        stat_cd VARCHAR(5)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- This relation associates a data type with a sensor.
-- A sensor may have mulptiple data types, but only one for each standard.
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE ConfigSensorDataType
(
	configId INTEGER NOT NULL,
	sensorNumber INTEGER NOT NULL,
	dataTypeId INTEGER NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ConfigSensorProperty
(
	configId INTEGER NOT NULL,
	sensorNumber INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	value VARCHAR(240) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-----------------------------------------------------------------------
-- Decoding Scripts & Subordinate Entities
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE DecodesScript
(
	id INTEGER NOT NULL,
	configId INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	type VARCHAR(24) NOT NULL,
	dataOrder CHAR         -- A=Ascending D=Descending
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two DecodesScripts have the same ID:
CREATE UNIQUE INDEX DecodesScriptIdx on DecodesScript(id) tablespace HDB_idx;

-- Guarantees script names are unique within a PlatformConfig:
CREATE UNIQUE INDEX DecodesScriptNmIdx on DecodesScript(configId, name) tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE ' 
CREATE TABLE FormatStatement
(
	decodesScriptId INTEGER NOT NULL,
	sequenceNum INTEGER NOT NULL,
	label VARCHAR(24) NOT NULL,
	format VARCHAR(400)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees each format statement has a unique sequence within a script:
CREATE UNIQUE INDEX FormatStatementIdx on 
	FormatStatement(decodesScriptId, sequenceNum) tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE ScriptSensor
(
	decodesScriptId INTEGER NOT NULL,
	sensorNumber INTEGER NOT NULL,
	unitConverterId INTEGER
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees each scriptsensor has unique number within a script:
CREATE UNIQUE INDEX ScriptSensorIdx on 
	ScriptSensor(decodesScriptId, sensorNumber);

-----------------------------------------------------------------------
-- Routing Specs 
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE RoutingSpec
(
	id INTEGER NOT NULL,
	name VARCHAR(64) NOT NULL,
	dataSourceId INTEGER,
	enableEquations VARCHAR(5) DEFAULT ''FALSE'',
	usePerformanceMeasurements VARCHAR(5) DEFAULT ''FALSE'',
	outputFormat VARCHAR(24),
	outputTimeZone VARCHAR(64),
	presentationGroupName VARCHAR(64),
	sinceTime VARCHAR(80),
	untilTime VARCHAR(80),
	consumerType VARCHAR(24),
	consumerArg VARCHAR(400),
	lastModifyTime TIMESTAMP WITH TIME ZONE,
	isProduction VARCHAR(5) DEFAULT ''FALSE''
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two RoutingSpecs have the same ID:
CREATE UNIQUE INDEX RoutingSpecIdIdx on RoutingSpec(id) tablespace HDB_idx;

-- Guarantees no two RoutingSpecs have the same name:
CREATE UNIQUE INDEX RoutingSpecNmIdx on RoutingSpec(name) tablespace HDB_idx;

-- Associates a routing spec to a network list:
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE RoutingSpecNetworkList
(
	routingSpecId INTEGER NOT NULL,
	networkListName VARCHAR(64) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE RoutingSpecProperty
(
	routingSpecId INTEGER NOT NULL,
	name VARCHAR(24) NOT NULL,
	value VARCHAR(240) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-----------------------------------------------------------------------
-- Data Sources
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE DataSource
(
	id INTEGER NOT NULL,
	name VARCHAR(64) NOT NULL,
	dataSourceType VARCHAR(24) NOT NULL,
	dataSourceArg VARCHAR(400)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two DataSources have the same ID:
CREATE UNIQUE INDEX DataSource_IdIdx on DataSource(id)  tablespace HDB_idx;

-- Guarantees no two DataSources have the same name:
CREATE UNIQUE INDEX DataSource_NmIdx on DataSource(name)  tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE DataSourceGroupMember
(
	groupId INTEGER NOT NULL,
	sequenceNum INTEGER NOT NULL,
	memberId INTEGER NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-----------------------------------------------------------------------
-- Network Lists
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE NetworkList
(
	id INTEGER NOT NULL,
	name VARCHAR(64) NOT NULL,
	transportMediumType VARCHAR(24),
	siteNameTypePreference VARCHAR(24),
	lastModifyTime TIMESTAMP WITH TIME ZONE NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two NetworkLists have the same ID:
CREATE UNIQUE INDEX NetworkList_IdIdx on NetworkList(id)  tablespace HDB_idx;

-- Guarantees no two NetworkLists have the same name:
CREATE UNIQUE INDEX NetworkList_NmIdx on NetworkList(name)  tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE NetworkListEntry
(
	networkListId INTEGER NOT NULL,
	transportId VARCHAR(64) NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-----------------------------------------------------------------------
-- Presentation Groups
-----------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PresentationGroup
(
	id INTEGER NOT NULL,
	name VARCHAR(64) NOT NULL,
	inheritsFrom INTEGER,
	lastModifyTime TIMESTAMP WITH TIME ZONE,
	isProduction VARCHAR(5) DEFAULT ''false''
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two PresentationGroups have the same ID:
CREATE UNIQUE INDEX PresGrp_IdIdx on PresentationGroup(id) tablespace HDB_idx;

-- Guarantees no two PresentationGroups have the same name:
CREATE UNIQUE INDEX PresGrp_NmIdx on PresentationGroup(name) tablespace HDB_idx;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE DataPresentation
(
	id INTEGER NOT NULL,
	groupId INTEGER NOT NULL,
	dataTypeId INTEGER,
	unitAbbr VARCHAR(24),
	equipmentId INTEGER,
	maxDecimals INTEGER
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE RoundingRule
(
	dataPresentationId INTEGER NOT NULL,
	upperLimit FLOAT,
	sigDigits INTEGER NOT NULL
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-----------------------------------------------------------------------
-- Engineering Units and Conversions
-----------------------------------------------------------------------
/*  remove due to HDB equivalency table
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE EngineeringUnit
(
	unitAbbr VARCHAR(24) NOT NULL,
	name VARCHAR(64) NOT NULL,
	family VARCHAR(24),
	measures VARCHAR(24)
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two EngineeringUnits have the same abbreviation:
CREATE UNIQUE INDEX EUAbbrIdx on EngineeringUnit(unitAbbr) tablespace HDB_idx;

  end of remove comment   */
BEGIN EXECUTE IMMEDIATE '

CREATE TABLE UnitConverter
(
	id INTEGER NOT NULL,
	fromUnitsAbbr VARCHAR(24),
	toUnitsAbbr VARCHAR(24),
	algorithm VARCHAR(24),
	-- Meaning of coeffients depends on the algorithm:
	a FLOAT,
	b FLOAT,
	c FLOAT,
	d FLOAT,
	e FLOAT,
	f FLOAT
) tablespace HDB_data'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Guarantees no two UnitConverters have the same ID:
CREATE UNIQUE INDEX UnitConverterIdIdx on UnitConverter(id) tablespace HDB_idx;

-- Note: We DON'T put a unique index on from/to abbreviations because
-- Raw converters all have "raw" as the from abbreviation. Many
-- different raw converters may have the same from/to values.




--------------------------------------------------------------------------
-- This script updates DECODES tables from an USBR HDB 5.2 CCP Schema to 
-- OpenDCS 6.2 Schema.
--
--------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ENUM ADD DESCRIPTION VARCHAR2(400)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DATATYPE ADD DISPLAY_NAME VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE SCHEDULE_ENTRY
(
    SCHEDULE_ENTRY_ID NUMBER(*,0) NOT NULL,
    -- Unique name for this schedule entry.
    NAME VARCHAR2(64) NOT NULL,
    LOADING_APPLICATION_ID NUMBER(*,0),
    ROUTINGSPEC_ID INTEGER NOT NULL,
    -- date/time for first execution.
    -- Null means start immediately.
    START_TIME date,
    -- Used to interpret interval adding to start time.
    TIMEZONE VARCHAR2(32),
    -- Any valid interval in this database.
    -- Null means execute one time only.
    RUN_INTERVAL VARCHAR2(64),
    -- true or false
    ENABLED VARCHAR2(5) NOT NULL,
    LAST_MODIFIED date NOT NULL,
    PRIMARY KEY (SCHEDULE_ENTRY_ID),
    CONSTRAINT SENAME_UNIQUE UNIQUE(NAME)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Describes a schedule run.
BEGIN EXECUTE IMMEDIATE 'CREATE TABLE SCHEDULE_ENTRY_STATUS
(
    SCHEDULE_ENTRY_STATUS_ID NUMBER(*,0) NOT NULL,
    SCHEDULE_ENTRY_ID NUMBER(*,0) NOT NULL,
    RUN_START_TIME date NOT NULL,
    -- Null means no messages yet received
    LAST_MESSAGE_TIME date,
    -- Null means still running.
    RUN_COMPLETE_TIME date,
    -- Hostname or IP Address of server where the routing spec was run.
    HOSTNAME VARCHAR2(64) NOT NULL,
    -- Brief string describing current status: "initializing", "running", "complete", "failed".
    RUN_STATUS VARCHAR2(24) NOT NULL,
    -- Number of messages successfully processed during the run.
    NUM_MESSAGES INT DEFAULT 0 NOT NULL,
    -- Number of decoding errors encountered.
    NUM_DECODE_ERRORS INT DEFAULT 0 NOT NULL,
    -- Number of distinct platforms seen
    NUM_PLATFORMS INT DEFAULT 0 NOT NULL,
    LAST_SOURCE VARCHAR2(32),
    LAST_CONSUMER VARCHAR2(32),
    -- Last time this entry was written to the database.
    LAST_MODIFIED date NOT NULL,
    PRIMARY KEY (SCHEDULE_ENTRY_STATUS_ID),
    CONSTRAINT sched_entry_start_unique UNIQUE (SCHEDULE_ENTRY_ID, RUN_START_TIME)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE SCHEDULE_ENTRY
    ADD CONSTRAINT SCHEDULE_ENTRY_FKLA
    FOREIGN KEY (LOADING_APPLICATION_ID)
    REFERENCES ${hdb_user}.HDB_LOADING_APPLICATION (LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE ROUTINGSPEC ADD CONSTRAINT ROUTINGSPEC_PK PRIMARY KEY (ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE SCHEDULE_ENTRY
    ADD CONSTRAINT SCHEDULE_ENTRY_FKRS
    FOREIGN KEY (ROUTINGSPEC_ID)
    REFERENCES ROUTINGSPEC (ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE SCHEDULE_ENTRY_STATUS
    ADD CONSTRAINT SCHEDULE_ENTRY_STATUS_FKSE
    FOREIGN KEY (SCHEDULE_ENTRY_ID)
    REFERENCES SCHEDULE_ENTRY (SCHEDULE_ENTRY_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
CREATE TABLE DACQ_EVENT
(
    -- Surrogate Key. Events are numbered from 0...MAX
    DACQ_EVENT_ID NUMBER(*,0) NOT NULL,
    SCHEDULE_ENTRY_STATUS_ID NUMBER(*,0),
    PLATFORM_ID NUMBER(*,0),
    EVENT_TIME date NOT NULL,
    -- INFO = 3, WARNING = 4, FAILURE = 5, FATAL = 6
    --
    EVENT_PRIORITY INT NOT NULL,
    -- Software subsystem that generated this event
    SUBSYSTEM VARCHAR2(24),
    -- If this is related to a message, this holds the message''s local_recv_time.
    MSG_RECV_TIME DATE,
    EVENT_TEXT VARCHAR2(256) NOT NULL,
    PRIMARY KEY (DACQ_EVENT_ID)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DACQ_EVENT
    ADD CONSTRAINT DACQ_EVENT_FKSE
    FOREIGN KEY (SCHEDULE_ENTRY_STATUS_ID)
    REFERENCES SCHEDULE_ENTRY_STATUS (SCHEDULE_ENTRY_STATUS_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE INDEX DQE_PLATFORM_ID_IDX ON DACQ_EVENT (PLATFORM_ID) tablespace HDB_IDX;
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE PLATFORM_STATUS
(
    PLATFORM_ID NUMBER(*,0) NOT NULL,
    -- Time of last station contact, whether or not a message was successfully received.
    LAST_CONTACT_TIME date,
    -- Time stamp of last message received. This is the message time stamp parsed from the header.
    -- Null means no message ever received.
    LAST_MESSAGE_TIME date,
    -- Up to 8 failure codes describing data acquisition and decoding.
    LAST_FAILURE_CODES VARCHAR2(8),
    -- Null means no errors encountered ever.
    LAST_ERROR_TIME date,
    -- Points to status of last routing spec / schedule entry run.
    -- Null means that the schedule entry is too old and has been purged.
    LAST_SCHEDULE_ENTRY_STATUS_ID NUMBER(*,0),
    ANNOTATION VARCHAR2(400),
    PRIMARY KEY (PLATFORM_ID)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PLATFORM_STATUS
    ADD CONSTRAINT PLATFORM_STATUS_FKSE
    FOREIGN KEY (LAST_SCHEDULE_ENTRY_STATUS_ID)
    REFERENCES SCHEDULE_ENTRY_STATUS (SCHEDULE_ENTRY_STATUS_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '

ALTER TABLE NETWORKLISTENTRY ADD PLATFORM_NAME VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE NETWORKLISTENTRY ADD DESCRIPTION VARCHAR2(80)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE TRANSPORTMEDIUM ADD LOGGERTYPE VARCHAR2(24)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD BAUD INT'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD STOPBITS INT'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD PARITY VARCHAR2(1)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD DATABITS INT'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD DOLOGIN VARCHAR2(5)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD USERNAME VARCHAR2(32)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE TRANSPORTMEDIUM ADD PASSWORD VARCHAR2(32)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



----------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE '
CREATE TABLE SERIAL_PORT_STATUS
(
    -- Combo of DigiHostName:PortNumber
    PORT_NAME VARCHAR2(48) NOT NULL,
    -- True when port is locked.
    IN_USE VARCHAR2(5) DEFAULT ''FALSE'' NOT NULL,
    -- Name of routing spec (or other process) that last used (or is currently using) the port.
    -- Null means never been used.
    LAST_USED_BY_PROC VARCHAR2(64),
    -- Hostname or IP Address from which this port was last used (or is currently being used).
    -- Null means never been used.
    LAST_USED_BY_HOST VARCHAR2(64),
    -- Java msec Date/Time this port was last used.
    LAST_ACTIVITY_TIME DATE,
    -- Java msec Date/Time that a message was successfully received on this port.
    LAST_RECEIVE_TIME DATE,
    -- The Medium ID (e.g. logger name) from which a message was last received on this port.
    LAST_MEDIUM_ID VARCHAR2(64),
    -- Java msec Date/Time of the last time an error occurred on this port.
    LAST_ERROR_TIME DATE,
    -- Short string. Usually one of the following:
    -- idle, dialing, login, receiving, goodbye, error
    PORT_STATUS VARCHAR2(32),
    PRIMARY KEY (PORT_NAME)
) tablespace HDB_DATA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DATATYPE MODIFY(CODE VARCHAR2(65 BYTE))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DECODESDATABASEVERSION RENAME COLUMN VERSION TO VERSION_NUM'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE DECODESDATABASEVERSION RENAME COLUMN options TO DB_OPTIONS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE EQUIPMENTPROPERTY RENAME COLUMN VALUE TO PROP_VALUE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


UPDATE NETWORKLIST SET TRANSPORTMEDIUMTYPE = 'goes' WHERE TRANSPORTMEDIUMTYPE IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE NETWORKLIST MODIFY(TRANSPORTMEDIUMTYPE  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

UPDATE NETWORKLIST SET SITENAMETYPEPREFERENCE = 'hdb' WHERE SITENAMETYPEPREFERENCE IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE NETWORKLIST MODIFY(SITENAMETYPEPREFERENCE  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PRESENTATIONGROUP MODIFY(LASTMODIFYTIME NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

UPDATE PRESENTATIONGROUP SET ISPRODUCTION = 'FALSE' WHERE ISPRODUCTION IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE PRESENTATIONGROUP MODIFY(ISPRODUCTION  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE PRESENTATIONGROUP MODIFY(ISPRODUCTION  DEFAULT ''FALSE'')'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


UPDATE ROUTINGSPEC SET ENABLEEQUATIONS = 'FALSE' WHERE ENABLEEQUATIONS IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE ROUTINGSPEC MODIFY(ENABLEEQUATIONS  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


UPDATE ROUTINGSPEC SET USEPERFORMANCEMEASUREMENTS = 'FALSE' 
  WHERE USEPERFORMANCEMEASUREMENTS IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE ROUTINGSPEC MODIFY(USEPERFORMANCEMEASUREMENTS  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

UPDATE ROUTINGSPEC SET ISPRODUCTION = 'FALSE' WHERE ISPRODUCTION IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE ROUTINGSPEC MODIFY(ISPRODUCTION NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ROUTINGSPECPROPERTY RENAME COLUMN NAME TO PROP_NAME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE ROUTINGSPECPROPERTY RENAME COLUMN VALUE TO PROP_VALUE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


CREATE UNIQUE INDEX DS_GROUP_SEQ_UNIQUE ON DATASOURCEGROUPMEMBER
(GROUPID, SEQUENCENUM) tablespace HDB_IDX;

CREATE UNIQUE INDEX NL_TRANSPORT_UNIQUE ON NETWORKLISTENTRY
(NETWORKLISTID, TRANSPORTID) tablespace HDB_IDX;

UPDATE CONFIGSENSOR SET SENSORNAME = 'X' WHERE SENSORNAME IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE CONFIGSENSOR MODIFY(SENSORNAME  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

UPDATE CONFIGSENSOR SET RECORDINGMODE = 'U' WHERE RECORDINGMODE IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE CONFIGSENSOR MODIFY(RECORDINGMODE  NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CONFIGSENSORPROPERTY RENAME COLUMN NAME TO PROP_NAME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE CONFIGSENSORPROPERTY RENAME COLUMN VALUE TO PROP_VALUE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DATAPRESENTATION ADD (MAX_VALUE  FLOAT(126))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE DATAPRESENTATION ADD (MIN_VALUE  FLOAT(126))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE UNIQUE INDEX PRES_DT_UNIQUE ON DATAPRESENTATION (GROUPID, DATATYPEID) tablespace HDB_IDX;
BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DECODESSCRIPT RENAME COLUMN TYPE TO SCRIPT_TYPE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

UPDATE DECODESSCRIPT SET DATAORDER = 'A' WHERE DATAORDER IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE DECODESSCRIPT MODIFY(DATAORDER NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE DECODESSCRIPT MODIFY(DATAORDER DEFAULT ''A'')'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


UPDATE PLATFORM SET ISPRODUCTION = 'FALSE' WHERE ISPRODUCTION IS NULL;
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE PLATFORM MODIFY(ISPRODUCTION NOT NULL)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PLATFORMPROPERTY RENAME COLUMN NAME TO PROP_NAME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE PLATFORMPROPERTY RENAME COLUMN VALUE TO PROP_VALUE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PLATFORMSENSORPROPERTY RENAME COLUMN NAME TO PROP_NAME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'ALTER TABLE PLATFORMSENSORPROPERTY RENAME COLUMN VALUE TO PROP_VALUE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DATASOURCEGROUPMEMBER ADD PRIMARY KEY (GROUPID, MEMBERID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DATASOURCEGROUPMEMBER ADD CONSTRAINT GROUP_SEQ_UNIQUE
  UNIQUE (GROUPID, SEQUENCENUM)
  USING INDEX tablespace HDB_IDX'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '  
ALTER TABLE ENUM
 ADD CONSTRAINT ENNAME_UNIQUE
  UNIQUE (NAME)
  USING INDEX tablespace HDB_IDX'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ROUTINGSPECNETWORKLIST
 ADD PRIMARY KEY (ROUTINGSPECID, NETWORKLISTNAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ROUTINGSPECPROPERTY
 ADD PRIMARY KEY (ROUTINGSPECID, PROP_NAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CONFIGSENSOR
 ADD PRIMARY KEY (CONFIGID, SENSORNUMBER)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE CONFIGSENSORPROPERTY
 ADD PRIMARY KEY (CONFIGID, SENSORNUMBER, PROP_NAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DATAPRESENTATION ADD CONSTRAINT PRES_DT_UNIQUE
  UNIQUE (GROUPID, DATATYPEID) USING INDEX tablespace HDB_IDX'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- MJM the following doesn't work because there are platforms with same site/desig
-- but with different expiration. Furthermore, Oracle doesn't allow a timestamp with
-- timezone to be part of a unique key, so I can't simply add EXPIRATION to the
-- column list.
--ALTER TABLE PLATFORM
-- ADD CONSTRAINT SITE_DESIGNATOR_UNIQUE
--  UNIQUE (SITEID, PLATFORMDESIGNATOR)
--  USING INDEX tablespace HDB_IDX;
BEGIN EXECUTE IMMEDIATE '  
ALTER TABLE PLATFORMPROPERTY ADD PRIMARY KEY (PLATFORMID, PROP_NAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '  
ALTER TABLE PLATFORMSENSOR ADD PRIMARY KEY (PLATFORMID, SENSORNUMBER)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PLATFORMSENSORPROPERTY ADD PRIMARY KEY (PLATFORMID, SENSORNUMBER, PROP_NAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE TRANSPORTMEDIUM ADD PRIMARY KEY (PLATFORMID, MEDIUMTYPE)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE PLATFORMSENSORPROPERTY
 ADD CONSTRAINT PLATFORMSENSORPROPERTY_FKPS
  FOREIGN KEY (PLATFORMID, SENSORNUMBER)
  REFERENCES PLATFORMSENSOR (PLATFORMID,SENSORNUMBER)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

  
update unitconverter set A = 6894.74729 where lower(fromunitsabbr) = 'psi' and lower(tounitsabbr) = 'pa';

-----------------------------------------------------------------
-- two new sequences for the high volume ccp/decodes tables so they don't use CWMS_SEQ:
-----------------------------------------------------------------
CREATE SEQUENCE DACQ_EVENTIDSEQ MINVALUE 1 START WITH 1 MAXVALUE 2000000000 NOCACHE CYCLE;
CREATE SEQUENCE SCHEDULE_ENTRY_STATUSIDSEQ MINVALUE 1 START WITH 1 MAXVALUE 2000000000 NOCACHE CYCLE;
CREATE SEQUENCE SCHEDULE_ENTRYIDSEQ MINVALUE 1 START WITH 1 MAXVALUE 2000000000 NOCACHE CYCLE;

-----------------------------------------------------------------
-- permissions for the new stuff.
-----------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON SCHEDULE_ENTRY TO DECODES_ROLE, CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON SCHEDULE_ENTRY_STATUS TO DECODES_ROLE, CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON DACQ_EVENT TO DECODES_ROLE, CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON PLATFORM_STATUS TO DECODES_ROLE, CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON DACQ_EVENTIDSEQ TO DECODES_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON SCHEDULE_ENTRY_STATUSIDSEQ TO DECODES_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON SCHEDULE_ENTRYIDSEQ TO DECODES_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-----------------------------------------------------------------
-- public synonyms for the new stuff
-----------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM DACQ_EVENT FOR  DACQ_EVENT;
CREATE OR REPLACE PUBLIC SYNONYM SCHEDULE_ENTRY FOR  SCHEDULE_ENTRY;
CREATE OR REPLACE PUBLIC SYNONYM SCHEDULE_ENTRY_STATUS FOR  SCHEDULE_ENTRY_STATUS;
CREATE OR REPLACE PUBLIC SYNONYM PLATFORM_STATUS FOR  PLATFORM_STATUS;
CREATE OR REPLACE PUBLIC SYNONYM SERIAL_PORT_STATUS FOR  SERIAL_PORT_STATUS;

CREATE OR REPLACE PUBLIC SYNONYM DACQ_EVENTIDSEQ FOR  DACQ_EVENTIDSEQ;
CREATE OR REPLACE PUBLIC SYNONYM SCHEDULE_ENTRY_STATUSIDSEQ FOR  SCHEDULE_ENTRY_STATUSIDSEQ;
CREATE OR REPLACE PUBLIC SYNONYM SCHEDULE_ENTRYIDSEQ FOR  SCHEDULE_ENTRYIDSEQ;

-----------------------------------------------------------------
-- Finally, update the database version numbers in the database
-----------------------------------------------------------------
delete from DecodesDatabaseVersion;
insert into DecodesDatabaseVersion values(13, 'Updated to OpenDCS 6.2 RC06');
delete from tsdb_database_version;
insert into tsdb_database_version values(13, 'Updated to OpenDCS 6.2 RC06');

commit;


--------------------------------------------------------------------------
-- This script updates DECODES tables from an USBR HDB 6.3 CCP Schema to 
-- OpenDCS 6.4 Schema.
--------------------------------------------------------------------------

DELETE FROM DACQ_EVENT;
BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DACQ_EVENT ADD LOADING_APPLICATION_ID NUMBER(*,0)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE DACQ_EVENT ADD CONSTRAINT DACQ_EVENT_FKLA
    FOREIGN KEY (LOADING_APPLICATION_ID) REFERENCES ${hdb_user}.HDB_LOADING_APPLICATION(LOADING_APPLICATION_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
DROP SEQUENCE DACQ_EVENTIDSEQ'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE SEQUENCE DACQ_EVENTIDSEQ MINVALUE 1 START WITH 1 NOCACHE;

-----------------------------------------------------------------
-- Finally, update the database version numbers in the database
-----------------------------------------------------------------
delete from DecodesDatabaseVersion;
insert into DecodesDatabaseVersion values(15, 'Updated to OpenDCS 6.4');
delete from tsdb_database_version;
insert into tsdb_database_version values(15, 'Updated to OpenDCS 6.4');

commit;


-- spool off

-- exit;
-- $Id: createORACLEDecodesSequences.sql,v 1.2 2006/05/23 18:04:32 hdba Exp $
--
-- $Log: createORACLEDecodesSequences.sql,v $
-- Revision 1.2  2006/05/23 18:04:32  hdba
-- mods for decodes phase 0 re-development effort
--
-- Revision 1.1  2006/01/04 16:58:18  hdba
-- new files and documentation to add phase 0 to cvs
--
-- Revision 1.1  2003/11/17 14:55:56  mjmaloney
-- These are the sequences used in Postgres for generating new surrogate keys.
--
--

--
-- This file contains definitions for the SEQUENCES used to generate
-- surrogate keys. Do not execute this file if your database uses
-- some other mechanism to generate surrogate keys.
--

-- Used to assign IDs for new sites:
-- remove the siteid sequence since we will be using HDB site ids
--CREATE SEQUENCE SiteIdSeq NOCACHE;

-- Used to assign IDs to new EquipmentModel records:
CREATE SEQUENCE EquipmentIdSeq NOCACHE;

-- Used to assign IDs to new Enum records:
CREATE SEQUENCE EnumIdSeq start with 17 NOCACHE;

-- Used to assign IDs to new DataType records:
CREATE SEQUENCE DataTypeIdSeq start with 10500 NOCACHE;

-- Used to assign IDs to new Platform records:
CREATE SEQUENCE PlatformIdSeq NOCACHE;

-- Used to assign IDs to new PlatformConfig records:
CREATE SEQUENCE PlatformConfigIdSeq NOCACHE;

-- Used to assign IDs to new DecodesScript records:
CREATE SEQUENCE DecodesScriptIdSeq NOCACHE;

-- Used to assign IDs to new RoutingSpec records:
CREATE SEQUENCE RoutingSpecIdSeq NOCACHE;

-- Used to assign IDs to new DataSource records:
CREATE SEQUENCE DataSourceIdSeq NOCACHE;

-- Used to assign IDs to new Network List records:
CREATE SEQUENCE NetworkListIdSeq NOCACHE;

-- Used to assign IDs to new PresentationGroup records:
CREATE SEQUENCE PresentationGroupIdSeq NOCACHE;

-- Used to assign IDs to new DataPresentation records:
CREATE SEQUENCE DataPresentationIdSeq NOCACHE;

-- Used to assign IDs to new UnitConverter records:
CREATE SEQUENCE UnitConverterIdSeq start with 100 NOCACHE;

-- exit;

-- set echo on
-- set feedback on

-- spool set_decodes_privs.out

CREATE OR REPLACE PUBLIC SYNONYM CONFIGSENSOR for decodes.CONFIGSENSOR;                                                            
CREATE OR REPLACE PUBLIC SYNONYM CONFIGSENSORDATATYPE for decodes.CONFIGSENSORDATATYPE;                                            
CREATE OR REPLACE PUBLIC SYNONYM CONFIGSENSORPROPERTY for decodes.CONFIGSENSORPROPERTY;                                            
CREATE OR REPLACE PUBLIC SYNONYM DECODESDATABASEVERSION for decodes.DECODESDATABASEVERSION;
CREATE OR REPLACE PUBLIC SYNONYM DATAPRESENTATION for decodes.DATAPRESENTATION;                                                    
CREATE OR REPLACE PUBLIC SYNONYM DATASOURCE for decodes.DATASOURCE;                                                                
CREATE OR REPLACE PUBLIC SYNONYM DATASOURCEGROUPMEMBER for decodes.DATASOURCEGROUPMEMBER;                                          
CREATE OR REPLACE PUBLIC SYNONYM DATATYPE for decodes.DATATYPE;

CREATE OR REPLACE PUBLIC SYNONYM DATATYPEEQUIVALENCE for decodes.DATATYPEEQUIVALENCE;                                              
CREATE OR REPLACE PUBLIC SYNONYM DECODESSCRIPT for decodes.DECODESSCRIPT;                                                          
CREATE OR REPLACE PUBLIC SYNONYM ENUM for decodes.ENUM;                                                                            
CREATE OR REPLACE PUBLIC SYNONYM ENUMVALUE for decodes.ENUMVALUE;                                                                  
CREATE OR REPLACE PUBLIC SYNONYM EQUIPMENTMODEL for decodes.EQUIPMENTMODEL;                                                        
CREATE OR REPLACE PUBLIC SYNONYM EQUIPMENTPROPERTY for decodes.EQUIPMENTPROPERTY;                                                  
CREATE OR REPLACE PUBLIC SYNONYM FORMATSTATEMENT for decodes.FORMATSTATEMENT;                                                      
CREATE OR REPLACE PUBLIC SYNONYM NETWORKLIST for decodes.NETWORKLIST;                                                              
CREATE OR REPLACE PUBLIC SYNONYM NETWORKLISTENTRY for decodes.NETWORKLISTENTRY;                                                    
CREATE OR REPLACE PUBLIC SYNONYM PLATFORM for decodes.PLATFORM;                                                                    
CREATE OR REPLACE PUBLIC SYNONYM PLATFORMCONFIG for decodes.PLATFORMCONFIG;                                                        
CREATE OR REPLACE PUBLIC SYNONYM PLATFORMPROPERTY for decodes.PLATFORMPROPERTY;                                                    
CREATE OR REPLACE PUBLIC SYNONYM PLATFORMSENSOR for decodes.PLATFORMSENSOR;                                                        
CREATE OR REPLACE PUBLIC SYNONYM PLATFORMSENSORPROPERTY for decodes.PLATFORMSENSORPROPERTY;                                        
CREATE OR REPLACE PUBLIC SYNONYM PRESENTATIONGROUP for decodes.PRESENTATIONGROUP;                                                  
CREATE OR REPLACE PUBLIC SYNONYM ROUNDINGRULE for decodes.ROUNDINGRULE;                                                            
CREATE OR REPLACE PUBLIC SYNONYM ROUTINGSPEC for decodes.ROUTINGSPEC;                                                              
CREATE OR REPLACE PUBLIC SYNONYM ROUTINGSPECNETWORKLIST for decodes.ROUTINGSPECNETWORKLIST;                                        
CREATE OR REPLACE PUBLIC SYNONYM ROUTINGSPECPROPERTY for decodes.ROUTINGSPECPROPERTY;                                              
CREATE OR REPLACE PUBLIC SYNONYM SCRIPTSENSOR for decodes.SCRIPTSENSOR;                                                            
CREATE OR REPLACE PUBLIC SYNONYM TRANSPORTMEDIUM for decodes.TRANSPORTMEDIUM;                                                      
CREATE OR REPLACE PUBLIC SYNONYM UNITCONVERTER for decodes.UNITCONVERTER;                                                          
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.CONFIGSENSOR to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                         
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.CONFIGSENSORDATATYPE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                 
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.CONFIGSENSORPROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                 
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DECODESDATABASEVERSION to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                      
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DATAPRESENTATION to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                     
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DATAPRESENTATIONIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                          
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DATASOURCE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                           
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DATASOURCEGROUPMEMBER to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DATASOURCEIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DATATYPE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                  
BEGIN EXECUTE IMMEDIATE '
grant select on decodes.DATATYPEIdSeq to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                  
BEGIN EXECUTE IMMEDIATE '
grant select on decodes.DATATYPEEQUIVALENCE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                  
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DECODESSCRIPT to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                        
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.DECODESSCRIPTIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                             
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ENUM to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                                 
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ENUMIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                      
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ENUMVALUE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                            
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.EQUIPMENTIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                 
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.EQUIPMENTMODEL to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                       
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.EQUIPMENTPROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                    
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.FORMATSTATEMENT to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                      
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.NETWORKLIST to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                          
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.NETWORKLISTENTRY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                     
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.NETWORKLISTIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                               
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORM to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                             
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORMCONFIG to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                       
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORMCONFIGIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                            
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORMIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                  
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORMPROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                     
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORMSENSOR to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                       
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PLATFORMSENSORPROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                               
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PRESENTATIONGROUP to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                    
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.PRESENTATIONGROUPIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                         
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ROUNDINGRULE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                         
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ROUTINGSPEC to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                          
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ROUTINGSPECIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                               
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ROUTINGSPECNETWORKLIST to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                               
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.ROUTINGSPECPROPERTY to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                  
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.SCRIPTSENSOR to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                         
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.TRANSPORTMEDIUM to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                      
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.UNITCONVERTER to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                                        
BEGIN EXECUTE IMMEDIATE 'grant select on decodes.UNITCONVERTERIDSEQ to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
                                                             
BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.CONFIGSENSOR to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.CONFIGSENSORDATATYPE to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.CONFIGSENSORPROPERTY to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DECODESDATABASEVERSION to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DATAPRESENTATION to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DATASOURCE to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DATASOURCEGROUPMEMBER to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DATATYPE to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DATATYPEEQUIVALENCE to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.DECODESSCRIPT to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ENUM to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ENUMVALUE to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.EQUIPMENTMODEL to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.EQUIPMENTPROPERTY to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.FORMATSTATEMENT to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.NETWORKLIST to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.NETWORKLISTENTRY to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.PLATFORM to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.PLATFORMCONFIG to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.PLATFORMPROPERTY to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.PLATFORMSENSOR to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.PLATFORMSENSORPROPERTY to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.PRESENTATIONGROUP to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ROUNDINGRULE to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ROUTINGSPEC to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ROUTINGSPECNETWORKLIST to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ROUTINGSPECPROPERTY to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.SCRIPTSENSOR to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.TRANSPORTMEDIUM to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.UNITCONVERTER to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
grant select, insert, update, delete on decodes.ENUM to ${hdb_user} with grant option'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select, insert, update, delete on decodes.ENUMVALUE to ${hdb_user} with grant option'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- spool off
-- exit;

