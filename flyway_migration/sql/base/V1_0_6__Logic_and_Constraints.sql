ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};
-- APEX compatibility: define dummy v() function if APEX is not installed
BEGIN
  EXECUTE IMMEDIATE 'CREATE OR REPLACE FUNCTION v(p_name IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN NULL; END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
create or replace procedure deny_action (text varchar2)
IS
              check_val integer;
BEGIN
      raise_application_error(-20001, '"' || text || '"');
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on deny_action to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- set echo on
-- set feeback on
-- spool hdb_types.out

-- Expanding: ./TYPES/date_object.ddl

CREATE OR REPLACE type date_object AS object(date_time DATE);
/
-- Expanding: ./TYPES/date_array.ddl

CREATE OR REPLACE type date_array AS TABLE OF date_object;
/


-- Expanding: ./TYPES/hdb4_types.ddl
CREATE OR REPLACE TYPE DATEARRAY as table of date;
/

CREATE OR REPLACE TYPE NUMBER_ARRAY as table of number;
/

CREATE OR REPLACE TYPE T_TF_ROW AS OBJECT (
  row_dates DATE,
  row_values NUMBER
);
/

CREATE OR REPLACE TYPE T_TF_TAB IS TABLE OF t_tf_row;
/


-- spool off
-- exit;

-- set echo on
-- set feedback on
-- spool hdb_sequences.out

-- Expanding: ./SEQUENCES/hdb_site_sequence.seq
create sequence hdb_site_sequence start with 1 nocache;


/*  create the synonymns and priveleges for the sequences previously created  */
BEGIN EXECUTE IMMEDIATE 'grant select on hdb_site_sequence to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM SiteIdSeq for hdb_site_sequence;

-- Expanding: ./SEQUENCES/ref_site_rating_sequence.seq
create sequence ref_site_rating_seq start with 1 nocache order nocycle;
BEGIN EXECUTE IMMEDIATE 'grant select on ref_site_rating_seq to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./SEQUENCES/ref_db_generic_list_sequence.seq
create sequence ref_db_generic_list_sequence start with 1 nocache;


/*  create the synonymns and priveleges for the sequences previously created  */
BEGIN EXECUTE IMMEDIATE 'grant select on ref_db_generic_list_sequence to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM ref_db_generic_list_sequence for ref_db_generic_list_sequence;


/* create ref_czar_db_generic_list_sequence sequence for czar refresh*/
create sequence ref_czar_db_generic_list_sequence start with 1 nocache;
BEGIN EXECUTE IMMEDIATE '
grant select on ref_czar_db_generic_list_sequence to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM ref_czar_db_generic_list_sequence for ref_db_generic_list_sequence; 

-- spool off
-- exit;
-- set echo on
-- set feedback on
-- spool hdb_packages.out

-- Expanding: ./PACKAGES/cp_remote_trigger.sps
create or replace package CP_REMOTE_TRIGGER as
/*  PACKAGE CP_REMOTE_TRIGGER is the package designed to contain all
    the procedures and functions for the Remote computation triggering use.
    
    Created by M. Bogner April 2010   
*/

/*  DECLARE ALL GLOBAL variables  */
/*  none so far */


 PROCEDURE POST_ON_TASKLIST(
    P_LOADING_APPLICATION_ID	NUMBER,
    P_SITE_DATATYPE_ID			NUMBER,
    P_INTERVAL					VARCHAR2,
    P_TABLE_SELECTOR			VARCHAR2,
    P_START_DATE_TIME			DATE,
	P_MODEL_RUN_ID				NUMBER,
	P_VALUE						NUMBER,
	P_VALIDATION				VARCHAR2,
    P_DERIVATION_FLAGS			VARCHAR2,
    P_DELETE_FLAG				VARCHAR2) ;
  
 PROCEDURE REMOTE_DATA_CHANGED(
    P_SITE_DATATYPE_ID		NUMBER,
    P_INTERVAL				VARCHAR2,
    P_START_DATE_TIME		DATE,
    P_MODEL_RUN_ID			NUMBER,
	P_VALUE					NUMBER,
	P_VALIDATION			VARCHAR2,
    P_DERIVATION_FLAGS		VARCHAR2,
    P_DELETE_FLAG			VARCHAR2);
 
 PROCEDURE TRIGGER_REMOTE_CP(
    P_DB_LINK				VARCHAR2,
    P_SITE_DATATYPE_ID		NUMBER,
    P_INTERVAL				VARCHAR2,
    P_START_DATE_TIME		DATE,
    P_MODEL_RUN_ID			NUMBER,
	P_VALUE					NUMBER,
	P_VALIDATION			VARCHAR2,
    P_DERIVATION_FLAGS		VARCHAR2,
    P_DELETE_FLAG			VARCHAR2);
     
END CP_REMOTE_TRIGGER;

/

create or replace public synonym CP_REMOTE_TRIGGER for CP_REMOTE_TRIGGER;
BEGIN EXECUTE IMMEDIATE 'grant execute on CP_REMOTE_TRIGGER to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/cp_remote_trigger.spb

CREATE OR REPLACE PACKAGE BODY CP_REMOTE_TRIGGER AS 

  PROCEDURE POST_ON_TASKLIST(
    P_LOADING_APPLICATION_ID	NUMBER,
    P_SITE_DATATYPE_ID			NUMBER,
    P_INTERVAL					VARCHAR2,
    P_TABLE_SELECTOR			VARCHAR2,
    P_START_DATE_TIME			DATE,
	P_MODEL_RUN_ID				NUMBER,
	P_VALUE						NUMBER,
	P_VALIDATION				VARCHAR2,
    P_DERIVATION_FLAGS			VARCHAR2,
    P_DELETE_FLAG				VARCHAR2) IS
    
    
    BEGIN
    
	/*  this procedure written by M. Bogner  May 2010
      the purpose of this procedure is to place rows into the cp_comp_tasklist table when
      with the data passed to this procedure 
												  */
    
		insert into cp_comp_tasklist(
		record_num, loading_application_id,
		site_datatype_id,interval,table_selector,
		value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
		)
		values (
		cp_tasklist_sequence.nextval,P_LOADING_APPLICATION_ID,
		P_SITE_DATATYPE_ID,P_INTERVAL,P_TABLE_SELECTOR,P_VALUE,sysdate,P_START_DATE_TIME,P_DELETE_FLAG,
		P_MODEL_RUN_ID,P_VALIDATION,P_DERIVATION_FLAGS
		);

  END; /*  POST_ON_TASKLIST procedure  */

  PROCEDURE REMOTE_DATA_CHANGED(
    P_SITE_DATATYPE_ID		NUMBER,
    P_INTERVAL				VARCHAR2,
    P_START_DATE_TIME		DATE,
    P_MODEL_RUN_ID			NUMBER,
	P_VALUE					NUMBER,
	P_VALIDATION			VARCHAR2,
    P_DERIVATION_FLAGS		VARCHAR2,
    P_DELETE_FLAG			VARCHAR2) IS
    
    CURSOR is_rec_a_parameter(sdi NUMBER, p_interval VARCHAR2, sdt DATE) IS  
		select site_datatype_id, loading_application_id, interval, table_selector,
		model_id, computation_id,computation_name,algorithm_id,algorithm_name
		from cp_active_sdi_tsparm_view
		where site_datatype_id = sdi
		and table_selector not in ('R_','M_')
		and interval = p_interval
		and sdt between effective_start_date_time and effective_end_date_time;  
    
    BEGIN
    
	/*  this procedure written by M. Bogner  May 2010
      the purpose of this procedure is to place rows into the cp_comp_tasklist table when
      Data has been received from a remote database call and this data is defined as an 
      input parameter of an active calculation  */
      
   
	/*  now go see if there are any active computation definitions for this record      */
	/*  if there are records from this cursor then put all records from the cursor
		into the cp_comp_task_list table                                                */

		FOR p1 IN is_rec_a_parameter(p_site_datatype_id, p_interval, p_start_date_time) LOOP
    
			cp_remote_trigger.post_on_tasklist(p1.loading_application_id,p_site_datatype_id,
			p_interval,p1.table_selector,p_start_date_time,p_model_run_id,
			p_value,p_validation,p_derivation_flags,p_delete_flag);
    
		END LOOP;


    END; /*  REMOTE_DATA_CHANGED procedure  */

  	
 PROCEDURE TRIGGER_REMOTE_CP(
    P_DB_LINK				VARCHAR2,
    P_SITE_DATATYPE_ID		NUMBER,
    P_INTERVAL				VARCHAR2,
    P_START_DATE_TIME		DATE,
    P_MODEL_RUN_ID			NUMBER,
	P_VALUE					NUMBER,
	P_VALIDATION			VARCHAR2,
    P_DERIVATION_FLAGS		VARCHAR2,
    P_DELETE_FLAG			VARCHAR2)
  IS
  /* do not remove this pragma statement !!!!  */
  pragma autonomous_transaction;
                                                                  
  ex_statement varchar2(2000);
                                                                               
BEGIN                                                                           

  /*  this procedure written by M. Bogner  JUNE 2010
      the purpose of this procedure is to call a remote database to put a record in the
      cp_tasklist table to trigger it's local computations
  
  Note: that this procedure is an autonomous transaction and must remain so for current processing
  
  */
  		/* build the sql block statement to call the proper remote database  */
  		ex_statement :=
		'BEGIN CP_REMOTE_TRIGGER.REMOTE_DATA_CHANGED@' || p_db_link || 
		'(:b1,:b2,:b3,:b4,:b5,:b6,:b7,:b8); END;'; 

		/* now execute the sql block using the proper bind variables   */
		execute immediate (ex_statement) using P_SITE_DATATYPE_ID,P_INTERVAL,P_START_DATE_TIME,
			P_MODEL_RUN_ID,P_VALUE,P_VALIDATION,P_DERIVATION_FLAGS,P_DELETE_FLAG;  
   
  /*  autonomous transactions must be explicitly commited or rolled back or an error will result  */
  commit;
     
END;  /*  end of trigger_remote_cp  */                                                                             	



END CP_REMOTE_TRIGGER; 


/
-- Expanding: ./PACKAGES/hdb_poet.sps
create or replace package HDB_POET as
/*  PACKAGE HDB_POET is the package designed to contain all
    the procedures and functions for general HDB_POET use.
    
    Created by M. Bogner NOVEMBER 2008   
*/

/*  DECLARE ALL GLOBAL variables  */
/*  none so far */


  PROCEDURE CALCULATE_SERIES(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_TIME DATE, TIME_ZONE VARCHAR2 DEFAULT NULL);
  
    
END HDB_POET;

/

create or replace public synonym HDB_POET for HDB_POET;
BEGIN EXECUTE IMMEDIATE 'grant execute on HDB_POET to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/hdb_poet.spb

CREATE OR REPLACE PACKAGE BODY HDB_POET AS 

   PROCEDURE CALCULATE_SERIES(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_TIME       DATE,
    TIME_ZONE        VARCHAR2 DEFAULT NULL) IS
	procedure_indicator varchar2(100);
	STATUS_TEMP varchar2(100);
    temp_chars varchar2(30);
    START_TIME_TEMP DATE;
    END_TIME_TEMP DATE;
    total_count NUMBER;
    good_count NUMBER;
    bad_count NUMBER;
    ts_start DATE;
    ts_end DATE;
    db_timezone VARCHAR2(3);
    
    /* this is the cursor and the sql to get all sdi's that are input for an output sdi  */
    /* now use the new cp_input_output_view that lists all inputs for a particular output */
    /* this cursor only works right now for "REAL"  data!!!                               */
    CURSOR get_all_input_sdis(SDI_IN NUMBER, INTERVAL_IN VARCHAR2, START_DATE_IN DATE) IS  
	select  cio.input_sdi "SITE_DATATYPE_ID", 
	        START_DATE_IN + 
	        (nvl(cio.INPUT_DELTA_T,0)/DECODE(nvl(cio.INPUT_DELTA_T_UNITS,'Seconds'),'Seconds',86400,
	        'Hour',24,'Day',1,86400)) "TS_TIME",
            cio.input_interval "INTERVAL"
	from  cp_input_output_view cio
	where
	     cio.output_sdi = SDI_IN
	and  cio.output_interval = INTERVAL_IN
	and  cio.output_table_selector = 'R_';

    /*  this was the  old way before the existance of group computations and the cp_input_output_view */
    /* CURSOR get_all_input_sdis(SDI_IN NUMBER, INTERVAL_IN VARCHAR2, START_DATE_IN DATE) IS  
	select distinct castv.site_datatype_id, START_DATE_IN + (nvl(ccts2.DELTA_T,0)/86400) "TS_TIME",
        ccts2.interval
	from  cp_computation cc, cp_comp_ts_parm ccts, cp_algorithm ca, cp_comp_ts_parm ccts2,
		  cp_algo_ts_parm catp, cp_active_sdi_tsparm_view castv
	where
		 cc.enabled = 'Y'
	and  cc.loading_application_id is not null
	and  cc.computation_id = ccts.computation_id
	and  cc.algorithm_id = ca.algorithm_id
	and  ca.algorithm_id = catp.algorithm_id
	and  ccts.algo_role_name = catp.algo_role_name
	and  catp.parm_type like 'o%'
	and  ccts.site_datatype_id = SDI_IN
	and  ccts.interval = INTERVAL_IN
	and  ccts.table_selector = 'R_'
	and  ccts2.computation_id = ccts.computation_id
	and  castv.site_datatype_id = ccts2.site_datatype_id
	and  castv.computation_id = cc.computation_id;
    old cursor is commented out */
    
 BEGIN
/*  This procedure was written to assist in "calculating" a record in HDB
    via the application HDB_POET and may be called separately so that the 
    real interval records that are inputs to a calculation would 
    appear to have been modified and hence, spawn any computations 
    that would result in the passed SDI as output. 
                          
    this procedure written by Mark Bogner   November 2008                   */

/*  Modified by M.  Bogner  06/01/2009 to add mods to accept different time_zone parameter */ 
/*  Modified by M.  Bogner  04/24/2013 to Use the new cp_input_output view that considers all computations
    including new group computations                                                                       */ 

	procedure_indicator := 'CALCULATE_SERIES FAILED FOR: ';
/*  first do error checking  */
    IF SITE_DATATYPE_ID IS NULL THEN 
		DENY_ACTION( procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID');
	ELSIF INTERVAL IS NULL THEN 
		DENY_ACTION( procedure_indicator || 'INVALID <NULL> INTERVAL');
	ELSIF START_TIME IS NULL THEN 
		DENY_ACTION( procedure_indicator || 'INVALID <NULL> START_DATE_TIME');
    END IF;

/* get the databases default time zone  */
    BEGIN
      select param_value into db_timezone
        from ref_db_parameter, global_name
        where param_name = 'TIME_ZONE'
        and global_name.global_name = ref_db_parameter.global_name
        and nvl(active_flag,'Y') = 'Y';
       exception when others then 
       db_timezone := NULL;
    END;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = interval;
       exception when others then 
       DENY_ACTION( procedure_indicator || 'INVALID ' || interval || ' INTERVAL');
    END;

/*  if end time was passed in null or used default null then set to start_time  */
/*  commented out since we will not support a series of time
	END_TIME_TEMP := END_TIME;
	IF END_TIME IS NULL THEN 
	  END_TIME_TEMP := START_TIME;
	END IF;
*/

	start_time_temp := START_TIME;
/* now convert the start_time to the database time if different, both exist, 
   and only for the instantaneous and hourly interval           */
    IF (TIME_ZONE <> db_timezone AND INTERVAL in ('instant','hour')) THEN
       start_time_temp:= new_time(start_time_temp,TIME_ZONE,db_timezone);
    END IF;

	/* now loop through all sdi's that are inputs and "touch" them all */
	/* not just one SDI since we can't be sure all records for a single sdi
	   are there for the whole specified time period, without a whole
	   bunch of processing and checking counts etc...                 */
	bad_count := 0;
	good_count := 0;
	total_count := 0;
	procedure_indicator := ' FAILED ';
	
	/* loop through all the input sdis to touch them for a recomputation  */
	FOR p1 IN get_all_input_sdis(SITE_DATATYPE_ID, INTERVAL, START_TIME_TEMP) LOOP
		BEGIN
			total_count := total_count + 1;
			TS_START := p1.TS_TIME;
			/* standardize the dates for result sdi based on input sdi start_date_time  */
			hdb_utilities.standardize_dates( SITE_DATATYPE_ID,INTERVAL, TS_START, TS_END);
			/* now touch based on standardize dates for input interval in case the intervals don't coincide  */
			hdb_utilities.touch_for_recompute(p1.SITE_DATATYPE_ID, p1.INTERVAL, TS_START, TS_END);
			good_count := good_count + 1;	
			procedure_indicator := ' SUCCEEDED ';
			exception when others then 
				/* deny_action(sqlerrm);  commented out; for testing only  */
				bad_count := bad_count + 1;
		END;

	END LOOP;
	
  /* if the good_count is still zero then throw failed exception and how many SDIs were touched */
    IF (good_count = 0) THEN
		DENY_ACTION( 'CALCULATE_SERIES Procedure COMPLETED and' || procedure_indicator || ' for: '
		|| to_char(total_count) || ' Input SDIs with '
		|| interval || ' INTERVAL and START DATE: ' || to_char(start_time_temp,'dd-mon-yyyy HH24:mi'));
	END IF;
    
  END; /*  CALCULATE_SERIES procedure  */

END HDB_POET; 


/
-- Expanding: ./PACKAGES/hdb_utilities.sps
create or replace package HDB_UTILITIES as
/*  PACKAGE HDB_UTILITIES is the package designed to contain all
    the procedures and functions for general HDB use.
    
    Created by M. Bogner  August 2007   
    Modified January 2008 to add COMPUTATIONS_CLEANUP procedure
    Modified March 2008 to modify validation procedure signature with IN OUT for validation parameter 
    Modified March 2010 by M. Bogner to add additional Access Control List Functionality
    Modified October 2011 by M. Bogner to add Version II Access Control List Functionality
    Modified May 2012 by M. Bogner to fix  validation and overwrite flag bug not working in other time zone
    Modified July 2012 by M. Bogner  to add requirement for CP to store all data_time loaded values in same TZ
    Modified Feb 2016 by Ismail Ozdemir  to add RE_CALCULATE_ALGORITHM Procedure
*/

/*  DECLARE ALL GLOBAL variables  */

	 MANUAL_EDIT VARCHAR2(1) := NULL;
	 ACLG_NAME VARCHAR2(25) := 'Access Control List Group'; 
	 ACL_NAME VARCHAR2(25) := 'ACCESS CONTROL LIST GROUP'; 
	 ACL_NAME_II VARCHAR2(40) := 'ACCESS CONTROL LIST GROUP VERSION II'; 

  FUNCTION SET_MANUAL_EDIT (INPUT_VALUE VARCHAR2) RETURN VARCHAR2;	
  FUNCTION GET_MANUAL_EDIT RETURN VARCHAR2;	
  FUNCTION IS_FEATURE_ACTIVATED(P_FEATURE VARCHAR2) RETURN VARCHAR2; 
  FUNCTION IS_ROLE_ACTIVATED(P_ROLE_NAME VARCHAR2) RETURN VARCHAR2;
  FUNCTION IS_SDI_IN_ACL(P_SITE_DATATYPE_ID NUMBER) RETURN VARCHAR2;
  FUNCTION DATE_IN_WINDOW (INTERVAL VARCHAR2, INPUT_DATE_TIME DATE) RETURN VARCHAR2;	
  FUNCTION GET_SDI_UNIT_FACTOR (SDI NUMBER) RETURN FLOAT;	
  FUNCTION GET_SITE_ACL_ATTR  RETURN NUMBER;	
  FUNCTION DAYLIGHTSAVINGSTIMESTART(P_DATE IN DATE) RETURN DATE;
  FUNCTION DAYLIGHTSAVINGSTIMEEND(P_DATE IN DATE) RETURN DATE;
  FUNCTION IS_DATE_IN_DST(P_DATE IN DATE,p_DST_ZONE IN VARCHAR2,p_default_zone IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION MOD_DATE_FOR_TIME_ZONE(P_DATE IN DATE, P_TIME_ZONE IN VARCHAR2) RETURN DATE;
  FUNCTION GET_DB_PARAMETER (P_PARAMETER IN VARCHAR2) RETURN VARCHAR2;	
  
  PROCEDURE STANDARDIZE_DATES(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_DATE_TIME  IN OUT DATE,
    END_DATE_TIME    IN OUT DATE);

  PROCEDURE VALIDATE_R_BASE_RECORD(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_TIME DATE, VALUE NUMBER, VALIDATION IN OUT VARCHAR2);
  
  PROCEDURE MERGE_INTO_R_INTERVAL(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_DATE_TIME  DATE, END_DATE_TIME DATE,
    VALUE FLOAT, VALIDATION CHAR, OVERWRITE_FLAG VARCHAR2, METHOD_ID NUMBER, DATA_FLAGS VARCHAR2, DATE_TIME_LOADED DATE);

  PROCEDURE DELETE_FROM_INTERVAL(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_DATE_TIME DATE,
    END_DATE_TIME DATE, DATE_TIME_LOADED DATE);

  PROCEDURE COMPUTATIONS_CLEANUP;
  PROCEDURE DAILY_OPS;
  PROCEDURE COMPUTATIONS_PROCESSING(LOADING_APP_ID NUMBER, SDI NUMBER, INTERVAL VARCHAR2, INPUT_DATE_TIME DATE, 
            TABLE_SELECTOR VARCHAR2, COMPUTATION_ID NUMBER, COMPUTATION_NAME VARCHAR2, ALGORITHM_ID NUMBER,
            ALGORITHM_NAME VARCHAR2, MODEL_RUN_ID NUMBER, DELETE_FLAG VARCHAR2, DATA_FLAGS VARCHAR2);
  
  PROCEDURE TOUCH_FOR_RECOMPUTE(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_TIME  DATE, END_TIME DATE DEFAULT NULL);
  
  PROCEDURE TOUCH_CP_COMPUTATION(COMPUTATION_ID NUMBER);
    
  PROCEDURE RE_EVALUATE_RBASE(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_TIME  DATE, END_TIME DATE DEFAULT NULL);
  

-- added Time zone parameter to fix POET BUG for modifying Overwrite flag from other Time zones  
  PROCEDURE SET_OVERWRITE_FLAG(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_DATE_TIME DATE, 
    END_DATE_TIME DATE DEFAULT NULL, OVERWRITE_FLAG VARCHAR2, TIME_ZONE VARCHAR2 DEFAULT NULL);
    
-- added Time zone parameter to fix POET BUG for modifying Validation flag from other Time zones
  PROCEDURE SET_VALIDATION(SITE_DATATYPE_ID NUMBER, INTERVAL VARCHAR2, START_DATE_TIME DATE, 
    END_DATE_TIME DATE DEFAULT NULL, VALIDATION_FLAG VARCHAR2, TIME_ZONE VARCHAR2 DEFAULT NULL);
    
  PROCEDURE MODIFY_ACL(P_USER_NAME VARCHAR2, P_GROUP_NAME VARCHAR2, P_ACTIVE_FLAG VARCHAR2 DEFAULT 'Y',
    P_DELETE_FLAG VARCHAR2 DEFAULT 'N');   

  PROCEDURE MODIFY_SITE_GROUP_NAME(P_SITE_ID NUMBER, P_GROUP_NAME VARCHAR2, P_DELETE_FLAG VARCHAR2 DEFAULT 'N');   

  /*  PROCEDURE RE_CALCULATE_ALGORITHM designed to contain all
      the procedures and functions to recalculate a whole slew of
      data that are outputs to calculations if they were wrongly calculated in the first place.
  
      Created by M. Bogner September 2009
  */  
  
    PROCEDURE RE_CALCULATE_ALGORITHM(ALGORITHM_ID NUMBER, INTERVAL VARCHAR2, START_TIME DATE, END_TIME DATE);


END HDB_UTILITIES;

/

create or replace public synonym hdb_utilities for hdb_utilities;
BEGIN EXECUTE IMMEDIATE 'grant execute on hdb_utilities to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on hdb_utilities to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/hdb_utilities.spb
CREATE OR REPLACE PACKAGE BODY HDB_UTILITIES AS 

	FUNCTION SET_MANUAL_EDIT (INPUT_VALUE VARCHAR2)
	RETURN VARCHAR2 IS
	BEGIN 
		MANUAL_EDIT := INPUT_VALUE;
		RETURN(MANUAL_EDIT); 
	END;
	

	FUNCTION GET_MANUAL_EDIT 
	RETURN VARCHAR2 IS
	BEGIN 
		RETURN(NVL(MANUAL_EDIT,'Y')); 
	END;


	FUNCTION GET_SITE_ACL_ATTR 
	RETURN NUMBER IS
	temp_num NUMBER;
	
	BEGIN 
		/* this function was written to return the attribute primary key
		   for the ACL group attribute for a site
		*/
		/* written by M. Bogner for ACL project March 2010  */   
		
		begin   
			/*  do a query to get the sites ACL attribute ID  */	
			select distinct attr_id into temp_num from hdb_attr,ref_db_parameter, global_name
			where hdb_attr.attr_name = ACLG_NAME
			and  global_name.global_name = ref_db_parameter.global_name
			and  (ref_db_parameter.param_name = ACL_NAME
			 or   ref_db_parameter.param_name = ACL_NAME_II)
			and  ref_db_parameter.active_flag = 'Y';

			exception when others then temp_num := -1;

		end;
			
		return temp_num;
		
	END;  /* function get_site_acl_attr  */


	FUNCTION IS_FEATURE_ACTIVATED(P_FEATURE VARCHAR2) 
	RETURN VARCHAR2 IS
      temp_num NUMBER;
	BEGIN 
		/* this function was written to return a y or n for a
		   request of whether a release feature is currently 
		   enabled for the current database
		*/
		/* written by M. Bogner for ACL project II October 2011  */   

        begin		   
		  /*  see if feature is activated  */	
		  select count(*) into temp_num  
		   from ref_db_parameter, global_name where
		   global_name.global_name = ref_db_parameter.global_name
		   and ref_db_parameter.active_flag = 'Y'
		   and ref_db_parameter.param_name = P_FEATURE;

          /* something is wrong with the sql or database so don't return a Y  */
		  exception when others then temp_num := -1;
		
		end;
		
		/* if project is activated then continue by returning a Y       */
		IF (temp_num > 0) THEN
			RETURN 'Y';
		END IF;
		/* otherwise it must not be enabled  */
		RETURN 'N';
		
	END;  /* function is_feature_activated  */


	FUNCTION IS_ROLE_ACTIVATED(P_ROLE_NAME VARCHAR2) 
	RETURN VARCHAR2 IS
	BEGIN 
		/* this function was written to return a y or n for a
		   request of whether a role is currently enabled for a
		   user
		*/
		/* written by M. Bogner for ACL project March 2010  */   
		   
		/*  see if role is activated  */	
		IF (DBMS_SESSION.IS_ROLE_ENABLED(P_ROLE_NAME)) THEN
			RETURN 'Y';
		END IF;
		/* othewise it must not be enabled  */
		RETURN 'N';
		
	END;  /* function is_role_activated  */


	FUNCTION IS_SDI_IN_ACL(P_SITE_DATATYPE_ID NUMBER) 
	RETURN VARCHAR2 IS
	temp_num NUMBER;
	ACLversionI Boolean;
	ACLversionII Boolean;
	
	BEGIN 
		/* this function was written to return a y or n for a
		   request of whether an SDI  is currently enabled for a
		   particular user and his ACL group
		*/
		/* written by M. Bogner for ACL project March 2010  */   
		/* modified by M. Bogner for ACL project Version II OCT 2011  */   
		   
	    ACLversionI := false;
	    ACLversionII := false;
	    
	    /* if sdi is null return N */
	    IF (p_site_datatype_id is null) THEN
	      RETURN 'N';
	    END IF;

	    /* if sdi doesn't exist return N */
	    select count(*) into temp_num  from  hdb_site_datatype where
	    site_datatype_id = p_site_datatype_id;   	
	    IF (temp_num = 0) THEN
	      RETURN 'N';
	    END IF;
	    
		/* see if ACL Project is enabled  */
	    IF (hdb_utilities.is_feature_activated(ACL_NAME) = 'Y') THEN
	      ACLversionI := true;
	    END IF;
	    
		/* see if ACL PROJECT II is enabled  */
	    IF (hdb_utilities.is_feature_activated(ACL_NAME_II) = 'Y') THEN
	      ACLversionII := true;
	    END IF;
	    
		/* if neither project is activated then continue by returning a Y       */
		IF (NOT ACLversionI AND NOT ACLversionII) THEN
			RETURN 'Y';
		END IF;
		   
		/* see if user account is an active ${hdb_user} ACCOUNT  */
		select count(*) into temp_num  from ref_user_groups 
		where user_name = user and group_name = '${hdb_user}' and active_flag = 'Y';
		IF (temp_num > 0) THEN
			RETURN 'Y';
		END IF;

        /*  Is the user an active special ${hdb_user} ACL member?                    */
		/*  see if sdi is not under some other Group name control    */	
        /*  this additional check added for ACL version II           */
        /*  only do this if ACL version II is enabled                */
        
		IF ( ACLversionII ) THEN
		  select count(*) into temp_num  from
		   (select distinct site_id from hdb_site_datatype,ref_user_groups 
		   where user_name = user
		   and active_flag = 'Y'
		   and site_datatype_id = p_site_datatype_id
		   and group_name = '${hdb_user} ACLII'
		   minus
		   select site_id from acl_view where group_name <> '${hdb_user} ACLII');

		  IF (temp_num > 0) THEN
		    RETURN 'Y';
		  END IF;
		
		END IF;
		
		/*  see if sdi is under an active user and its group name perview  */	

		select count(*) into temp_num  from acl_view where group_name in
		(select group_name from ref_user_groups where user_name = user and active_flag = 'Y')
		and site_id in 
		(select distinct site_id from hdb_site_datatype 
		 where site_datatype_id = p_site_datatype_id);

		IF (temp_num > 0) THEN
			RETURN 'Y';
		END IF;

		/* otherwise this sdi must not be enabled for this user and groupname  */
		RETURN 'N';
		
	END;  /* function is_sdi_in_acl  */


 FUNCTION DATE_IN_WINDOW (   
    INTERVAL         VARCHAR2,
    INPUT_DATE_TIME  DATE)
    RETURN VARCHAR2 IS	
    new_start_date_time date;
    new_end_date_time date;
    redef   number;
    temp_num number;
    temp_char varchar2(100);
    in_window varchar2(1) := 'N';
    
	BEGIN
	/*  This function was written to be determine if the date of a sample is in the current
		date window.
                          
    this procedure written by Mark Bogner   August 2007          */

	/*  see if there is a definition of an interval at the database level in the  */
	/*  ref_interval_redefinition  table if not,  redef will be zero              */
	/*  currently only Water Year WY has been redefined                           */
     BEGIN
      temp_char := interval;
      select time_offset into redef
        from ref_interval_redefinition 
        where interval = temp_char;
       exception when others then 
       redef := 0;
     END;

	/* now calculate the current date window for this interval based on redefinitions                   */
	/* this code is written assuming an interval can only be redefined to the next lowest interval unit */
	/* even though the redefinition table allows you to specify a unit.  this makes little sense        */
	/* and probably will never be utilized anyway                                                       */
	/*  the following code just used for testing and debugging......
	insert into temp1 values ('time1: '|| to_char(new_start_date_time));
	insert into temp1 values ('redef: '|| to_char(redef));
	insert into temp1 values ('offset: '|| to_char(offset));
	insert into temp1 values ('END DATE: ' || to_char(new_end_date_time));
	*/

    CASE  interval
     WHEN 'instant' THEN 
        new_start_date_time := trunc(sysdate - redef/1440,'HH') + redef/1440;
        new_end_date_time := new_start_date_time + 1/24;
     WHEN 'hour' THEN 
        new_start_date_time := trunc(sysdate - redef/1440,'HH') + redef/1440;
        new_end_date_time := new_start_date_time + 1/24;
     WHEN 'day' THEN 
        new_start_date_time := trunc(sysdate - redef/24,'DD') + redef/24;
        new_end_date_time := new_start_date_time + 1;
     WHEN 'month' THEN 
        new_start_date_time := trunc(sysdate - redef,'MON') + redef;
        new_end_date_time := add_months(new_start_date_time,1);
     WHEN 'year' THEN 
        new_start_date_time := add_months(sysdate,redef*-1);
        new_start_date_time := add_months(trunc(new_start_date_time,'Y'),redef);
        new_end_date_time := add_months(new_start_date_time,12);
     WHEN 'wy' THEN 
        new_start_date_time := add_months(sysdate,redef*-1);
        new_start_date_time := add_months(trunc(new_start_date_time,'Y'),redef);
        new_end_date_time := add_months(new_start_date_time,12);
    END CASE;


    /* now we are done  with the checks so set the inwindow if the input date is between     */
    /* the two determined window dates                                                       */
 
	IF (new_start_date_time <= input_date_time and input_date_time <= new_end_date_time) THEN
       in_window := 'Y';
	END IF;
 
    RETURN(in_window); 
  end;


	FUNCTION GET_SDI_UNIT_FACTOR (
	  SDI NUMBER) 
	RETURN FLOAT IS
		return_value FLOAT;
	BEGIN 
	/* this function returns the multiplication factor of the unit associated with 
	   the input site_datatype_id
	*/
	
	/*  this function written by M. Bogner  12/06/2007  */
	
		begin
		return_value := 0.0;
		select c.mult_factor  into return_value
		  from hdb_site_datatype a, hdb_datatype b, hdb_unit c
		  where a.site_datatype_id = sdi
		  and a.datatype_id = b.datatype_id
		  and b.unit_id = c.unit_id;
		
		exception when others then return_value := 0.0;
		end;
		
	   return (return_value);
	END;

	Function DAYLIGHTSAVINGSTIMESTART (p_Date IN Date) 
	Return Date Is 
		v_Date       Date; 
		v_LoopIndex  Integer; 
		l_sunday_count Integer;
	Begin 
	/*  this function written by M. Bogner  11/09/2010  */
    /* this function returns the date the DST time period ends  */ 
	--Set the date to the 1st day of March  
		v_Date := to_date('03/01/' || to_char(p_Date,'YYYY') || '02:00:00 AM','MM/DD/YYYY HH:MI:SS PM'); 
		--Advance to the second Sunday. 
		l_sunday_count := 0;
		FOR v_LoopIndex IN 0..14 LOOP 
		  If (RTRIM(to_char(v_Date + v_LoopIndex,'DAY')) = 'SUNDAY') Then 
			l_sunday_count := l_sunday_count + 1;
			If (l_sunday_count = 2) then
				Return v_Date + v_LoopIndex; 
			End if;
		  End If; 
		END LOOP; 
	End; 

	Function DAYLIGHTSAVINGSTIMEEND(p_Date IN Date) 
	Return Date Is 
		v_Date       Date; 
		v_LoopIndex  Integer; 
	Begin
	/*  this function written by M. Bogner  11/09/2010  */
	/* this function returns the date the DST time period ends  */ 
	--Set Date to the first of November this year 
	v_Date := to_date('11/01/' || to_char(p_Date,'YYYY') || '02:00:00 AM','MM/DD/YYYY HH:MI:SS PM'); 
	--Advance to the first Sunday 
		FOR v_LoopIndex IN 0..7 LOOP 
		 If (RTRIM(to_char(v_Date + v_LoopIndex,'DAY')) = 'SUNDAY') Then 
			Return v_Date + v_LoopIndex; 
		 End If; 
		END LOOP; 
	End; 

	Function IS_DATE_IN_DST (p_Date IN Date,p_DST_ZONE IN VARCHAR2,p_default_zone IN VARCHAR2) 
	Return VARCHAR2 Is 
		v_Date       Date; 
		v_LoopIndex  Integer; 
		l_is_it_DST VARCHAR2(5);
	Begin 
	/*  this function written by M. Bogner  11/09/2010  */
	/* this function tells whether a date is within the DST time period  */
		l_is_it_dst := P_DEFAULT_ZONE;
		BEGIN
			select p_DST_ZONE into l_is_it_dst from dual where p_date between 
			DAYLIGHTSAVINGSTIMESTART(p_date)and 
			DAYLIGHTSAVINGSTIMEEND(p_date);
			exception when others then
			  l_is_it_dst := p_default_zone;
		END;
		RETURN l_is_it_dst;
	End; 

    FUNCTION MOD_DATE_FOR_TIME_ZONE(P_DATE IN DATE, P_TIME_ZONE IN VARCHAR2)
	Return Date Is 
		l_db_timezone VARCHAR2(3);
	Begin
	/*  this function written by M. Bogner  May 11 2012  */
	/* this function returns the parameter date based on the parameter P_TIME_ZONE  */ 
    /*  NOTE: ONLY call this function for intervals of instant and hour  */
 
    IF (P_DATE is null  OR P_TIME_ZONE is null) THEN
      RETURN P_DATE;
    END IF;
    
    /* get the databases default time zone  */
      BEGIN
        select param_value into l_db_timezone
          from ref_db_parameter, global_name
          where param_name = 'TIME_ZONE'
          and global_name.global_name = ref_db_parameter.global_name
          and nvl(active_flag,'Y') = 'Y';
         exception when others then 
          l_db_timezone := NULL;
      END;

    /* now convert the start_time to the database time if different  */ 
    IF (P_TIME_ZONE <> l_db_timezone) THEN
       RETURN new_time(P_DATE,P_TIME_ZONE,l_db_timezone);     
    END IF;

    /*  Otherwise the time zones must be the same or undefined so just return the same date  */
    RETURN P_DATE;

	End;  /* end of Function MOD_DATE_FOR_TIME_ZONE  */

    FUNCTION GET_DB_PARAMETER(P_PARAMETER VARCHAR2)
	Return VARCHAR2 Is 
		l_db_parameter VARCHAR2(64) := NULL;
	Begin
	/*  this function written by M. Bogner  July 20 2012  */
	/* this function returns the parameter value from ref_db_parameter based on the parameter P_PARAMETER  */ 
    
    IF (P_PARAMETER is null ) THEN
      RETURN l_db_parameter;
    END IF;
    
    /* get the databases parameter  */
      BEGIN
        select param_value into l_db_parameter
          from ref_db_parameter, global_name
          where param_name = P_PARAMETER
          and global_name.global_name = ref_db_parameter.global_name
          and nvl(active_flag,'Y') = 'Y';
         exception when others then 
          l_db_parameter := NULL;
      END;

    /*  just return the local parameter from the query  */
    RETURN l_db_parameter;

	End;  /* end of Function GET_DB_PARAMETER  */

PROCEDURE standardize_dates(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_DATE_TIME  IN OUT DATE,
    END_DATE_TIME    IN OUT DATE) IS
    new_start_date_time date;
    new_end_date_time date;
    offset  number;
    redef   number;
    temp_num number;
    temp_char varchar2(100);
    
BEGIN
/*  This procedure was written to be the interface to 
    HDB by standardizing start and end dates of records in R_BASE.
                          
    this procedure written by Mark Bogner   December 2006          */
/* modified by M. Bogner  December 2006 for date standardizing with windowing    */
/* modified by M. Bogner  Jan 2007 for date standardizing without windowing     */
/* modified by M. Bogner  August 2007 for date standardizing without windowing     */
/* modified by M. Bogner  May 2008 for use of ref_interval_copy_limits for time offsets     */


/* first find if there is a time offset for this particular SDI  */
/*  in the ref_interval_copy_limits table if none then the offset will be zero */
    BEGIN
      temp_num := site_datatype_id;
      temp_char := interval;
      select nvl(time_offset_minutes,0)/1440 into offset
        from ref_interval_copy_limits 
        where site_datatype_id = temp_num and interval = temp_char;
       exception when others then 
       offset := 0;
    END;

/*  see if there is a definition of an interval at the database level in the  */
/*  ref_interval_redefinition  table if not,  redef will be zero              */
/*  currently only Water Year WY has been redefined                           */
    BEGIN
      temp_char := interval;
      select time_offset into redef
        from ref_interval_redefinition 
        where interval = temp_char;
       exception when others then 
       redef := 0;
    END;

/* now calculate the destination window for this record based on redefinitions and time offsets */
/* this code is written assuming an interval can only be redefined to the next lowest interval unit */
/* even though the redefinition table allows you to specify a unit.  this makes little sense        */
/* and probably will never be utilized anyway                                                       */
/*  the following code just used for testing and debugging......
insert into temp1 values ('time1: '|| to_char(new_start_date_time));
insert into temp1 values ('redef: '|| to_char(redef));
insert into temp1 values ('offset: '|| to_char(offset));
insert into temp1 values ('END DATE: ' || to_char(new_end_date_time));
*/
/*insert into temp1 values ('Beginsdt: '|| to_char(start_date_time,'dd-mon-yyyy HH24:mi:ss')); */

    CASE  interval
     WHEN 'instant' THEN 
          new_start_date_time := start_date_time;
          new_end_date_time := start_date_time;
     WHEN 'hour' THEN 
        new_start_date_time := trunc(start_date_time - offset - redef/1440,'HH') + redef/1440;
        new_end_date_time := new_start_date_time + 1/24;
     WHEN 'day' THEN 
        new_start_date_time := trunc(start_date_time - offset - redef/24,'DD') + redef/24;
        new_end_date_time := new_start_date_time + 1;
     WHEN 'month' THEN 
        new_start_date_time := trunc(start_date_time - offset - redef,'MON') + redef;
        new_end_date_time := add_months(new_start_date_time,1);
     WHEN 'year' THEN 
        new_start_date_time := add_months(start_date_time - offset,redef*-1);
        new_start_date_time := add_months(trunc(new_start_date_time,'Y'),redef);
        new_end_date_time := add_months(new_start_date_time,12);
     WHEN 'wy' THEN 
        new_start_date_time := add_months(start_date_time - offset,redef*-1);
        new_start_date_time := add_months(trunc(new_start_date_time,'Y'),redef);
        new_end_date_time := add_months(new_start_date_time,12);
     ELSE 
          new_start_date_time := start_date_time;
          new_end_date_time := end_date_time;
    END CASE;


/* now we are done  with the checks so set the return dates    */

     start_date_time := new_start_date_time;
     end_date_time := new_end_date_time;
       
END; /* end of procedure standardize dates  */

PROCEDURE validate_r_base_record(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_TIME		 DATE,
    VALUE            NUMBER,
    VALIDATION  IN OUT VARCHAR2) IS
    temp_validation varchar2(1);
    temp_min_exp    number;
    temp_max_exp    number;
    temp_min_cut    number;
    temp_max_cut    number;
    temp_sdi        number;
    temp_interval   varchar2(16);
    
BEGIN
/*  This procedure was written to be the interface to 
    HDB for the validation of an input record.  This procedure only validates for records that
    exist in ref_derivation_source table.  This procedure currently only duplicates the
    basic validation that was done by the derivation application.
                          
    this procedure written by Mark Bogner   November 2006          */
    
/* modified by M. Bogner  Jan 2007 to incorporate new ref_interval_copy_limits table   */
/* modified by M. Bogner  March 2008 to not require entry ref_interval_copy_limits table   */

    temp_sdi := site_datatype_id;
    temp_interval := interval;
    temp_validation := 'V';
      
    /* do some basic math of the value against the defined ranges and cutoffs
       null math here will pass the validation                                 */  
    select min_value_expected-value,min_value_cutoff-value,
           max_value_expected-value,max_value_cutoff-value
    into temp_min_exp,temp_min_cut,
         temp_max_exp,temp_max_cut
    from ref_interval_copy_limits where site_datatype_id = temp_sdi
     and interval = temp_interval
     and effective_start_date_time <= start_time
     and nvl(effective_end_date_time,sysdate+1) > start_time;
     
     /* now check to see if the value is within specifications   */
     IF temp_min_cut > 0 then  temp_validation := 'F';
     ELSIF temp_max_cut < 0 then  temp_validation := 'F';
     ELSIF temp_min_exp > 0 then  temp_validation := 'L';
     ELSIF temp_max_exp < 0 then  temp_validation := 'H';
     END IF;      
     
     /* temp_validation will have the validation result by now so set the validation variable  */
     validation := temp_validation;
     
     /*  if there was no definition, validation will be what was passed in when procedure returns  */
     EXCEPTION
     WHEN OTHERS THEN null;

  END;  /* procedure validate_r_base_record  */
 	
 PROCEDURE computations_cleanup IS
                                                                    
  CURSOR get_historic_recs is
  select site_datatype_id, interval, loading_application_id, start_date_time, end_date_time, 
  table_selector, model_run_id
  from cp_historic_computations where ready_for_delete is not null;
  
  mrid_part   varchar2(1000);
  i_statement varchar2(2000);
                                                                              
BEGIN                                                                           

  /*  this procedure written by M. Bogner  December 2007
      the purpose of this procedure is to place rows into the cp_comp_tasklist table when
      Data has been inserted into the cp_historic_calculations table for historic calculations
      to be performed once the interval time spread has past and this data is defined as 
      an input parameter of an active calculation  */
  
  /* first update all records in cp_historic_calculations where end_date_time is now in the past  */
  update cp_historic_computations set ready_for_delete = 'Y' where end_date_time < sysdate;
      
/*  if there are time series records from this cursor then put the first record we find with the
    specifications of the record into the cp_comp_task_list table                    */

	FOR p1 IN get_historic_recs LOOP
		
		/* add the model_run_id criteria if this is model data */
        IF (p1.table_selector = 'M_') then 
			mrid_part := ' model_run_id = ' || to_char(p1.model_run_id);   
		ELSE
			mrid_part := ' 1=1 ';
		END IF;
    
		i_statement :=
		'insert into cp_comp_tasklist(record_num, loading_application_id,site_datatype_id,interval,' ||
		'table_selector,value,date_time_loaded,start_date_time,delete_flag,model_run_id) ' ||
		' select cp_tasklist_sequence.nextval, ' || to_char(p1.loading_application_id) || ',site_datatype_id,''' ||
		p1.interval || ''', ''' || p1.table_selector || ''',value,sysdate,start_date_time,''N'',' ||
		to_char(p1.model_run_id) || ' from ' || p1.table_selector || p1.interval || ' where  ' ||
		' rownum = 1 and ' ||
		' site_datatype_id = ' || to_char(p1.site_datatype_id) || ' and ' ||
		' start_date_time >= ' || 
        ' to_date(''' || to_char(p1.start_date_time,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		' start_date_time <= ' ||
        ' to_date(''' || to_char(p1.end_date_time,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		mrid_part;
		
		/* now execute this dynamic sql statement */
		--insert into temp1 values (i_statement);
		execute immediate (i_statement);
	

	END LOOP;  /* internal loop for all calculations for this particular 
  

  /*  finally cleanup all the records in cp_historic_computations that have ready_for_delete set  */
  delete from cp_historic_computations where ready_for_delete is not null;
   
END;  /*  end of computations_cleanup  */                                                                             	
 	
 	
  	
 PROCEDURE COMPUTATIONS_PROCESSING(LOADING_APP_ID NUMBER, SDI NUMBER, INTERVAL VARCHAR2, INPUT_DATE_TIME DATE, 
            TABLE_SELECTOR VARCHAR2, COMPUTATION_ID NUMBER, COMPUTATION_NAME VARCHAR2, ALGORITHM_ID NUMBER, 
            ALGORITHM_NAME VARCHAR2, MODEL_RUN_ID NUMBER, DELETE_FLAG VARCHAR2, DATA_FLAGS VARCHAR2)
  IS
  /* do not remove this pragma statement !!!!  */
  pragma autonomous_transaction;
                                                                  
  mrid_part   varchar2(1000);
  i_statement varchar2(2000);
  s_statement varchar2(2000);
  interval_SDT DATE;
  interval_EDT DATE;
  oi_SDT DATE;
  oi_EDT DATE;
  new_interval VARCHAR2(24);
  temp_char VARCHAR2(100);
  temp_id NUMBER;
  temp_count NUMBER;
  earliest_sdt DATE;
                                                                               
BEGIN                                                                           

  /*  this procedure written by M. Bogner  January 2008
      the purpose of this procedure is to perform additional processing if needed on any record deemed
      an input parameter to a computation.
  
  Presently the only additional processing is for EOPinterpolated and time weighted algorithms but I added e
  everything one may need as parameters in case other computations need more stuff done too
  
  Note: that this procedure is an autonomous transaction and must remain so for current processing
  
  Modified 8/27/2008 by M. Bogner to also trigger EOP calculations for previous period
  */
   
  /*  if the algorithms are eopinterpolated or Time weighted then do a bunch of testing to see if the previous
      or the following time periods are affected otherwise do nothing and just return  */

  
  IF UPPER(algorithm_name) IN ('EOPINTERPALG','TIMEWEIGHTEDAVERAGEALG') THEN  /*  BOP BLOCK  */

   /* this block will test to see if the record was the the BOP record */
   /* now go get the overall interval for this record  */
 
   temp_id := computation_id;
   temp_char := table_selector;
   select interval into new_interval from cp_comp_ts_parm where computation_id = temp_id and  
   algo_role_name = 'output' and table_selector = temp_char;
   
  /* now use standardize dates to get the overall interval  */

   interval_sdt :=   input_date_time;
   standardize_dates (SDI,new_interval,interval_SDT,interval_EDT);
   oi_SDT := interval_sdt - 60/86400;  /* a minute before */
   standardize_dates (SDI,new_interval,oi_SDT,oi_EDT); 

	/* see if this record is the first record in the time interval   */
	  /* add the model_run_id criteria if this is model data */
      IF (table_selector = 'M_') then 
			mrid_part := ' model_run_id = ' || to_char(model_run_id);   
	  ELSE
			mrid_part := ' 1=1 ';
	  END IF;
    
		s_statement :=
		' select count(*) from ' || table_selector || interval || ' where  ' ||
		' site_datatype_id = ' || to_char(sdi) || ' and ' ||
		' start_date_time >= ' || 
        ' to_date(''' || to_char(interval_SDT,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		' start_date_time < ' ||
        ' to_date(''' || to_char(input_date_time,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		mrid_part;
		
		/* now execute this dynamic sql select statement */
		execute immediate (s_statement) INTO temp_count;
		
	  if (temp_count = 0) then
		/* then was first record in the interval and will impact the previous interval's computation  */
		i_statement :=
		'insert into cp_comp_tasklist(record_num, loading_application_id,site_datatype_id,interval,' ||
		'table_selector,value,date_time_loaded,start_date_time,delete_flag,model_run_id,data_flags) ' ||
		' select cp_tasklist_sequence.nextval, ' || to_char(loading_app_id) || ',site_datatype_id,''' ||
		interval || ''', ''' || table_selector || ''',value,sysdate,start_date_time,''N'',' ||
		to_char(model_run_id) || ', derivation_flags from ' || table_selector || interval || ' where  ' ||
		' rownum = 1 and ' ||
		' site_datatype_id = ' || to_char(sdi) || ' and ' ||
		' start_date_time >= ' || 
        ' to_date(''' || to_char(oi_sdt,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		' start_date_time < ' ||
        ' to_date(''' || to_char(oi_edt,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		mrid_part;
		
		/* now execute this dynamic sql statement */
		/* and insert a record into the complist table to initiate a  computation  */
		execute immediate (i_statement);

	  end if;  /* the record was the first in the series  */


   END IF;  /* the bulk of the interpolated and time weighted average processing  for BOP record*/


   
  IF UPPER(algorithm_name) IN ('TIMEWEIGHTEDAVERAGEALG') THEN  /*  TWA EOP BLOCK  */
   /* this block will test to see if the record was the  EOP record  to see if we need to initiate
      a TWA computation for the following interval 
  */
  
  /* now go get the overall interval for this record  */
   temp_id := computation_id;
   temp_char := table_selector;
   select interval into new_interval from cp_comp_ts_parm where computation_id = temp_id and  
   algo_role_name = 'output' and table_selector = temp_char;
   
   /* now use standardize dates to get the overall interval for the following interval period */
   interval_sdt :=   input_date_time;
   standardize_dates (SDI,new_interval,interval_SDT,interval_EDT);
   oi_SDT := interval_edt + 60/86400;  /* a minute after current interval*/
   standardize_dates (SDI,new_interval,oi_SDT,oi_EDT); 

	/* see if this record is the first record in the time interval   */
	  /* add the model_run_id criteria if this is model data */
      IF (table_selector = 'M_') then 
			mrid_part := ' model_run_id = ' || to_char(model_run_id);   
	  ELSE
			mrid_part := ' 1=1 ';
	  END IF;
    
		s_statement :=
		' select count(*) from ' || table_selector || interval || ' where  ' ||
		' site_datatype_id = ' || to_char(sdi) || ' and ' ||
		' start_date_time <= ' || 
        ' to_date(''' || to_char(interval_EDT,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		' start_date_time > ' ||
        ' to_date(''' || to_char(input_date_time,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		mrid_part;
		
		/* now execute this dynamic sql select statement to see if there is a later record in 
		   this time interval*/
		execute immediate (s_statement) INTO temp_count;
		
	  if (temp_count = 0) then
		/* then was last record in the interval and will impact the following interval's computation  */
		i_statement :=
		'insert into cp_comp_tasklist(record_num, loading_application_id,site_datatype_id,interval,' ||
		'table_selector,value,date_time_loaded,start_date_time,delete_flag,model_run_id,data_flags) ' ||
		' select cp_tasklist_sequence.nextval, ' || to_char(loading_app_id) || ',site_datatype_id,''' ||
		interval || ''', ''' || table_selector || ''',value,sysdate,start_date_time,''N'',' ||
		to_char(model_run_id) || ', derivation_flags from ' || table_selector || interval || ' where  ' ||
		' rownum = 1 and ' ||
		' site_datatype_id = ' || to_char(sdi) || ' and ' ||
		' start_date_time >= ' || 
        ' to_date(''' || to_char(oi_sdt,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		' start_date_time < ' ||
        ' to_date(''' || to_char(oi_edt,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'') and ' ||
		mrid_part;
		
		/* now execute this dynamic sql statement */
		/* and insert a record into the complist table to initiate a  computation  */
		execute immediate (i_statement);

	  end if;  /* the record was the first in the series  */

   END IF;  /* the bulk of the time weighted average processing  for EOP record*/
   
   
  /*  autonomous transactions must be explicitly commited or rolled back or an error will result  */
  commit;
     
END;  /*  end of computations_processing  */                                                                             	


PROCEDURE merge_into_r_interval(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_DATE_TIME  DATE,
    END_DATE_TIME    DATE,
    VALUE            FLOAT,
    VALIDATION       CHAR,
    OVERWRITE_FLAG   VARCHAR2,
    METHOD_ID        NUMBER,
    DATA_FLAGS       VARCHAR2,
    DATE_TIME_LOADED DATE  ) IS
    usingpart   varchar2(1000);
    part0   varchar2(1000);
    part1   varchar2(1000);
    part2   varchar2(1000);
    part3   varchar2(1000);
    indicator varchar2(1);
    m_statement varchar2(2000);
    
BEGIN
/*  This procedure was written to be the interface to 
    HDB from the COMPUTATION application whenever data was inserted
    into the table R_BASE then a copy of that record into it's
    respective r_interval table is also expected.  The logic to call
    this merge statement is in the r_base triggers and those triggers
    only call this procedure if the r_base data was validated 
*/

/*    or an overwrite flag of 'O' was set.  removed August 2007 by M.  Bogner   */
/*  modified 8/31/07 by M. Bogner to put in call to set manual_edit             */
/*  modified 4/09/08 by M. Bogner to put in passage of method_id                */
/*  modified 6/16/09 by M. Bogner to correct use of sysdate in merge statement  */
                          
/* now its time to put the data into the interval table, using a merge statement       */
/* since the record may already be there.  To avoid a messy if then else structure,  */
/* a dynamic merge statement will be created to do this dml.                           */
/* create the using part which will query the passed in parameters from the dual table */
   usingpart := '( select ' || 
     to_char(site_datatype_id) || ' SITE_DATATYPE_ID,' ||
     '''' || interval || '''' || ' INTERVAL,' ||
     'to_date(''' || to_char(start_date_time,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'')' || ' START_DATE_TIME,' ||
     'to_date(''' || to_char(end_date_time,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'')' || ' END_DATE_TIME,' ||
     to_char(value) || ' VALUE,' ||
     '''' || overwrite_flag || '''' || ' OVERWRITE_FLAG,' ||
     to_char(method_id) || ' METHOD_ID,' ||
     '''' || data_flags || '''' || ' DATA_FLAGS,' ||
     '''' || validation || '''' || ' VALIDATION,' ||
     'to_date(''' || to_char(date_time_loaded,'dd-MON-YYYY HH24:MI:SS') || ''',''dd-MON-YYYY HH24:MI:SS'')' || ' DATE_TIME_LOADED' ||
     ' from dual ) rb';
      
/* create a dynamic merge statement that will merge the values received by R_base trigger with the correct interval table  */
   part0 := 'merge into r_'|| interval ||' rt using ';
   part1 :=   ' on (rt.site_datatype_id = rb.site_datatype_id and rt.start_date_time = rb.start_date_time' ||
     '  and rt.end_date_time= rb.end_date_time' ||
     '  and rb.site_datatype_id = ';

   part2 := to_char(site_datatype_id) || ' and rb.interval = ''' || interval || '''' ;

   part3 := '  and rb.start_date_time = to_date(''' ||
     to_char(start_date_time,'dd-MON-YYYY HH24:MI:SS') || 
     ''',''dd-MON-YYYY HH24:MI:SS'')  and rb.end_date_time = to_date(''' ||
     to_char(end_date_time,'dd-MON-YYYY HH24:MI:SS') || 
     ''',''dd-MON-YYYY HH24:MI:SS''))';

/* now form the whole merge statement by combining parts 1,2,3, usingpart and the final part of the statement  */
   m_statement := part0 || usingpart|| part1 || part2 || part3 ||
     ' when matched then update ' ||
     ' set value =rb.value, date_time_loaded = rb.date_time_loaded, overwrite_flag = rb.overwrite_flag, ' ||
     ' method_id = rb.method_id, derivation_flags = rb.data_flags, validation = rb.validation ' ||
     ' when not matched then insert ' ||
     ' (rt.site_datatype_id,rt.start_date_time,rt.end_date_time,rt.date_time_loaded,rt.value,rt.validation,rt.method_id,rt.derivation_flags,rt.overwrite_flag) ' ||
     ' values ' ||
     ' (rb.site_datatype_id,rb.start_date_time,rb.end_date_time,rb.date_time_loaded,rb.value,rb.validation,rb.method_id,rb.data_flags,rb.overwrite_flag) ';

/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');

/* now execute this dynamic sql statement */
    execute immediate (m_statement);
  
END; /*  end of procedure merge into r_interval  */

PROCEDURE delete_from_interval(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_DATE_TIME  DATE,
    END_DATE_TIME    DATE,
    DATE_TIME_LOADED DATE ) IS
    del_statement varchar2(2000);
BEGIN
/*  This procedure was written to be the interface to 
    HDB from the COMPUTATION application whenever data was deleted
    from the table R_BASE the copy of that record in it's
    respective r_interval table is also expected to be deleted.
                          
    this procedure written by Mark Bogner   November 2006          */
/*  modified by M.  Bogner DEcember 2006 to add delete by the date time loaded  */

/* create a dynamic sql statement that will delete the record from the r_ interval
   table  based on the passed in sdi and dates.                                    */
   
   del_statement := 'delete from r_' || interval || ' where site_datatype_id = ' || to_char(site_datatype_id) ||
   '  and start_date_time = to_date(''' ||
   to_char(start_date_time,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')  and end_date_time = to_date(''' ||
   to_char(end_date_time,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')' || 
   '  and date_time_loaded = to_date(''' ||
   to_char(date_time_loaded,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')';

/* now execute this dynamic sql statement */
   execute immediate (del_statement);

END; /*  delete from interval procedures  */



PROCEDURE touch_for_recompute(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_TIME  DATE,
    END_TIME    DATE DEFAULT NULL) IS
    up_statement varchar2(2000);
	procedure_indicator varchar2(100);
    indicator varchar2(1);
    temp_chars varchar2(30);
    END_TIME_TEMP DATE;
    rows_touched NUMBER;
 BEGIN
/*  This procedure was written to assist people in "touching" a record in HDB
    so that the record would appeared to be changed and hence, spawn any 
    computations that this record may be a part of. 
                          
    this procedure written by Mark Bogner   May 2008          */

/* modified by M. Bogner 9/06/2008 to put commit in to reduce 
   table locking possibilities in a multiuser environment        */
   
	procedure_indicator := 'TOUCH_FOR_RECOMPUTE FAILED FOR: ';
/*  first do error checking  */
    IF SITE_DATATYPE_ID IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL IS NULL THEN DENY_ACTION ( procedure_indicator || 'INVALID <NULL> INTERVAL' );
	ELSIF START_TIME IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> START_TIME' );
	ELSIF END_TIME < START_TIME THEN DENY_ACTION (procedure_indicator || 'INVALID END_TIME : < START_TIME' );
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = interval;
       exception when others then 
       DENY_ACTION (procedure_indicator || 'INVALID ' || interval || ' INTERVAL' );
    END;

/*  if end time was passed in null or used default null then set to start_time  */
	END_TIME_TEMP := END_TIME;
	IF END_TIME IS NULL THEN 
	  END_TIME_TEMP := START_TIME;
	END IF;
	
/* create a dynamic sql statement that will update the records in the r_ interval
   table  based on the passed in sdi and dates.                                    */
   
   up_statement := 'update r_' || interval || ' set source_id = source_id where site_datatype_id = ' || to_char(site_datatype_id) ||
   '  and start_date_time >= to_date(''' ||
   to_char(start_time,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')  and start_date_time <= to_date(''' ||
   to_char(END_TIME_TEMP,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')';
   
/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');

/* now execute this dynamic sql statement */
   execute immediate (up_statement);
   rows_touched := SQL%ROWCOUNT;
   /* error out if no rows were update!!!  */
   IF rows_touched < 1 THEN
     DENY_ACTION (procedure_indicator || ' SDI:  ' || to_char(site_datatype_id) || ' with ' 
     || interval || ' INTERVAL and START DATE: ' || to_char(start_time) || ' Resulted in no rows update.');
   END IF;

/* finally do a commit since this procedure was successful and 
   a commit will reduce possible deadlock issues  */
   commit;

END; /*  touch_for_recompute procedures  */


PROCEDURE touch_cp_computation(
    COMPUTATION_ID NUMBER) IS	
  /* do not remove this pragma statement !!!!  */
  /* removed by M. Bogner  13 AUg 2012 because of commit was causing a reace condition with depends daemon  */
  /*pragma autonomous_transaction; */
  procedure_indicator varchar2(100);    
  COMP_ID NUMBER;
BEGIN
/*
  THis procedure written to update the date_time_loaded column for
  the cp_computation table so that people can modify the properties 
  and parameters via sql and the triggers will call this procedure to 
  update the column with the sysdate.
                          
  this procedure written by Mark Bogner   MAY 2008  
  modified by M. Bogner 13-AUG-2013 to remove autonomous transaction since it
  was causing a race condition for the DEPENDS DAEMON
  
*/
  procedure_indicator := 'UPDATE_CP_COMPUTATION FAILED FOR: ';
  comp_id := computation_id;
  
  IF COMP_ID IS NULL THEN 
    DENY_ACTION (procedure_indicator || 'INVALID <NULL> COMPUTATION_ID' );
  END IF;

/* update the start_date_time column in the cp_computation table  */
  BEGIN
      update cp_computation set date_time_loaded = sysdate where computation_id = comp_id;
    exception when others then null;
  END;

/*  autonomous transactions must be explicitly commited or rolled back or an error will result  */
/*  commit;  */
/* This commit and the autonomous transaction was purposefully removed by M. Bogner  */
 
END; /*  touch_cp_computation procedure  */
  

PROCEDURE daily_ops IS	
BEGIN
/*
  THis procedure written to perform any daily operations that must be performed
  on the database since the implementation of the Calculation Application.
                          
  this procedure written by Mark Bogner   JUNE 2008                   */
 /* this procedure modified 28-JUNE-2013 my M. Bogner
    when it was discovered that there was a conflict with upper and 
    lowercase standards of "HDB" and "hdb"
    in the DECODES.datattype table                                    */ 
  BEGIN
-- this line finishes up partial calculations
    hdb_utilities.computations_cleanup;

-- this line will add any datatypes that may have been recently created
    insert into datatype
    (id, standard, code) select datatype_id,'HDB',datatype_id from hdb_datatype 
    minus select id,standard,id from datatype where standard = 'HDB';

    exception when others then DENY_ACTION ('Daily Operations Procedure Failed' );

  END;
 
END; /*  daily_ops procedure  */
  

PROCEDURE RE_EVALUATE_RBASE(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_TIME  DATE,
    END_TIME    DATE DEFAULT NULL) IS
    del_statement varchar2(2000);
	procedure_indicator varchar2(100);
    indicator varchar2(1);
    temp_chars varchar2(30);
    END_TIME_TEMP DATE;
    rows_touched NUMBER;
    p_site_datatype_id NUMBER;
    p_interval VARCHAR2(16);
    
 BEGIN
/*  This procedure was written to assist people in "touching" a record in HDB
    R_BASE table so that the record would appeared to be changed and hence, 
    trigger an update to this record so that the record would be treated as 
    an update an re-validated. 
                          
    this procedure written by Mark Bogner   March 2009          */

   
	procedure_indicator := 'RE_EVALUATE_RBASE FAILED FOR: ';
/*  first do error checking  */
    IF SITE_DATATYPE_ID IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL IS NULL THEN DENY_ACTION ( procedure_indicator || 'INVALID <NULL> INTERVAL' );
	ELSIF START_TIME IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> START_TIME' );
	ELSIF END_TIME < START_TIME THEN DENY_ACTION (procedure_indicator || 'INVALID END_TIME : < START_TIME' );
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = interval;
       exception when others then 
       DENY_ACTION (procedure_indicator || 'INVALID ' || interval || ' INTERVAL' );
    END;

	/* set up the temporary parameters needed for the SQL */
	p_site_datatype_id := site_datatype_id;
	p_interval := interval;
	
/*  if end time was passed in null or used default null then set to start_time  */
	END_TIME_TEMP := END_TIME;
	IF END_TIME IS NULL THEN 
	  END_TIME_TEMP := START_TIME;
	END IF;
	
/* create a dynamic sql statement that will delete any existing records in the r_ interval
   table  based on the passed in sdi and dates in case the records may now fail validation.                              */
   
   del_statement := 'delete from r_' || interval || ' rt where exists ( select ''x'' from r_base rb ' ||
   ' where rb.site_datatype_id = ' || to_char(site_datatype_id) ||
   ' and rb.interval = ''' || interval || '''' ||
   ' and rb.start_date_time >= to_date(''' ||
   to_char(start_time,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')  and rb.start_date_time <= to_date(''' ||
   to_char(END_TIME_TEMP,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')' ||
   ' and rb.site_datatype_id = rt.site_datatype_id ' ||
   ' and rb.start_date_time = rt.start_date_time )';
   
/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');

/* now execute this dynamic sql statement */
   execute immediate (del_statement);
   
   /* now touch the rows in r_base so that they are re-evaluated  */
   update r_base set validation = null, data_flags= null,
    date_time_loaded = to_date('10-DEC-1815') where site_datatype_id = p_site_datatype_id
    and interval = p_interval and 
    start_date_time between start_time and end_time_temp;

   rows_touched := SQL%ROWCOUNT;
   /* error out if no rows were update!!!  */
   IF rows_touched < 1 THEN
     DENY_ACTION (procedure_indicator || ' SDI:  ' || to_char(site_datatype_id) || ' with ' 
     || interval || ' INTERVAL and START DATE: ' || to_char(start_time) || ' Resulted in no rows updated.');
   END IF;

/* finally do a commit since this procedure was successful and 
   a commit will reduce possible deadlock issues  */
   commit;

END; /*  re_evaluate_rbase procedure  */

  
PROCEDURE SET_OVERWRITE_FLAG(
    SITE_DATATYPE_ID	NUMBER,
    INTERVAL			VARCHAR2,
    START_DATE_TIME		DATE,
    END_DATE_TIME		DATE DEFAULT NULL,
    OVERWRITE_FLAG		VARCHAR2,
    TIME_ZONE           VARCHAR2 DEFAULT NULL) IS
	procedure_indicator varchar2(100);
	indicator varchar2(1);
	temp_chars varchar2(30);
    rows_touched NUMBER;
    p_site_datatype_id NUMBER;
    p_interval VARCHAR2(16);
    p_overwrite_flag VARCHAR2(1);
    p_start_date_time DATE;
    p_end_date_time DATE;
    
    
 BEGIN
/*  This procedure was written to assist people in clearing or setting a record in HDB
    R_BASE table so that the record would modify the overwrite _flag, 
    trigger an update to this record so that the record would be either locked or have 
    the lock cleared. 
                          
    this procedure written by Mark Bogner   October 2009          */

/* added Time zone parameter May 2012 to fix POET BUG for modifying Overwrite flag from other Time zones  */
   
	procedure_indicator := 'SET OVERWRITE FLAG: ';
/*  first do error checking  */
    IF SITE_DATATYPE_ID IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL IS NULL THEN DENY_ACTION ( procedure_indicator || 'INVALID <NULL> INTERVAL' );
	ELSIF START_DATE_TIME IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> START_DATE_TIME' );
	ELSIF END_DATE_TIME < START_DATE_TIME THEN DENY_ACTION (procedure_indicator || 'INVALID END_DATE_TIME : < START_DATE_TIME' );
	ELSIF nvl(OVERWRITE_FLAG,'^') not in ('O','^') THEN DENY_ACTION (procedure_indicator || 'INVALID OVERWRITE FLAG : ' || OVERWRITE_FLAG );
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = interval;
       exception when others then 
       DENY_ACTION (procedure_indicator || 'INVALID ' || interval || ' INTERVAL' );
    END;

	/* set up the temporary parameters needed for the SQL */
	p_site_datatype_id := site_datatype_id;
	p_interval := interval;
	p_overwrite_flag := overwrite_flag;
	p_start_date_time := START_DATE_TIME;
/* modified May 2012 to consider the flags may be modified from users who set the time zone differently  */
/*  so rest the dates based on if the interval is instant or hour and if the time zone is different      */
    p_end_date_time := END_DATE_TIME;
	IF (p_interval in ('instant','hour')) THEN
	  p_start_date_time := MOD_DATE_FOR_TIME_ZONE(p_start_date_time, TIME_ZONE);
   	  p_end_date_time := MOD_DATE_FOR_TIME_ZONE(p_end_date_time, TIME_ZONE);
	END IF;	
/*  if end time was passed in null or used default null then set to start_date_time  */
	IF P_END_DATE_TIME IS NULL THEN 
	  P_END_DATE_TIME := p_start_date_time;
	END IF;
	   
/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');
   
   /* now touch the rows in r_base so that the overwrite_flag is update  */
   update r_base set overwrite_flag = p_overwrite_flag,
    date_time_loaded = to_date('10-DEC-1815') where site_datatype_id = p_site_datatype_id
    and interval = p_interval and 
    start_date_time between p_start_date_time and p_end_date_time;

   rows_touched := SQL%ROWCOUNT;
   /* error out if no rows were update!!!  */
   IF rows_touched < 1 THEN
     DENY_ACTION (procedure_indicator || ' SDI:  ' || to_char(site_datatype_id) || ' with ' 
     || interval || ' INTERVAL and START DATE: ' || to_char(start_date_time) || ' Resulted in no rows updated.');
   END IF;

/* finally do a commit since this procedure was successful and 
   a commit will reduce possible deadlock issues  */
   commit;

END; /*  set_overwrite procedure  */
    
   
PROCEDURE SET_VALIDATION(
    SITE_DATATYPE_ID	NUMBER,
    INTERVAL			VARCHAR2,
    START_DATE_TIME		DATE,
    END_DATE_TIME		DATE DEFAULT NULL,
    VALIDATION_FLAG		VARCHAR2,
    TIME_ZONE           VARCHAR2 DEFAULT NULL) IS
	procedure_indicator varchar2(100);
	indicator varchar2(1);
	temp_chars varchar2(30);
    rows_touched NUMBER;
    p_site_datatype_id NUMBER;
    p_interval VARCHAR2(16);
    p_validation VARCHAR2(1);
    p_start_date_time DATE;
    p_end_date_time DATE;
    
    
 BEGIN
/*  This procedure was written to assist people in clearing or setting a record in HDB
    R_BASE table so that the record would modify the validation column, 
    trigger an update to this record so that the record would be either be accepted or have 
    the validation cleared. 
                          
    this procedure written by Mark Bogner   October 2009          */

/* added Time zone parameter May 2012 to fix POET BUG for modifying Validation flag from other Time zones  */
   
	procedure_indicator := 'SET VALIDATION: ';
/*  first do error checking  */
    IF SITE_DATATYPE_ID IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL IS NULL THEN DENY_ACTION ( procedure_indicator || 'INVALID <NULL> INTERVAL' );
	ELSIF START_DATE_TIME IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> START_DATE_TIME' );
	ELSIF END_DATE_TIME < START_DATE_TIME THEN DENY_ACTION (procedure_indicator || 'INVALID END_DATE_TIME : < START_DATE_TIME' );
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = interval;
       exception when others then 
       DENY_ACTION (procedure_indicator || 'INVALID ' || interval || ' INTERVAL' );
    END;

/* validate the validation via a select from the hdb_validation table  */
    BEGIN
      IF validation_flag is not null THEN
		select validation into temp_chars
			from hdb_validation
			where validation = validation_flag;
	  END IF;
	  exception when others then 
	  DENY_ACTION (procedure_indicator || 'INVALID ' || validation_flag || ' VALIDATION VALUE' );
    END;

	/* set up the temporary parameters needed for the SQL */
	p_site_datatype_id := site_datatype_id;
	p_interval := interval;
	p_validation := validation_flag;
    p_start_date_time := START_DATE_TIME;
 /* modified May 2012 to consider the flags may be modified from users who set the time zone differently  */
 /*  so rest the dates based on if the interval is instant or hour and if the time zone is different      */
    p_end_date_time := END_DATE_TIME;
	IF (p_interval in ('instant','hour')) THEN
	  p_start_date_time := MOD_DATE_FOR_TIME_ZONE(p_start_date_time, TIME_ZONE);
   	  p_end_date_time := MOD_DATE_FOR_TIME_ZONE(p_end_date_time, TIME_ZONE);
	END IF;

/*  if end time was passed in null or used default null then set to start_date_time  */
	IF P_END_DATE_TIME IS NULL THEN 
	  P_END_DATE_TIME := p_start_date_time;
	END IF;
	   
/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');
   
   /* now touch the rows in r_base so that the validation is update  */
   update r_base set validation = p_validation,
    date_time_loaded = to_date('10-DEC-1815') where site_datatype_id = p_site_datatype_id
    and interval = p_interval and 
    start_date_time between p_start_date_time and p_end_date_time;

   rows_touched := SQL%ROWCOUNT;
   /* error out if no rows were update!!!  */
   IF rows_touched < 1 THEN
     DENY_ACTION (procedure_indicator || ' SDI:  ' || to_char(site_datatype_id) || ' with ' 
     || interval || ' INTERVAL and START DATE: ' || to_char(start_date_time) || ' Resulted in no rows updated.');
   END IF;

/* finally do a commit since this procedure was successful and 
   a commit will reduce possible deadlock issues  */
   commit;

END; /*  set_validation procedure  */
       
PROCEDURE MODIFY_ACL(
    P_USER_NAME		VARCHAR2,
    P_GROUP_NAME	VARCHAR2,
    P_ACTIVE_FLAG	VARCHAR2 DEFAULT 'Y',
    P_DELETE_FLAG	VARCHAR2 DEFAULT 'N') IS

    indicator varchar2(1);
    m_statement varchar2(2000);
    temp_num number;
    
BEGIN
/*  This procedure was written to be the interface to 
    HDB from any application that will modify the ACL control list
    that is controlled by the data within table ref_user_groups
*/

/*  original development March 2010 by M.  Bogner   */
/*  modified October 2011 by M. Bogner for ACL II project  */

	/* make sure ACL project is activated  */
	IF (hdb_utilities.GET_SITE_ACL_ATTR < 0) THEN
		DENY_ACTION('ILLEGAL ACL DATABASE OPERATION -- ACL projects not enabled');
	END IF;                          
	    
	/* see if ACL PROJECT II is enabled and if user is permitted */
	IF (hdb_utilities.is_feature_activated(ACL_NAME_II) = 'Y') THEN
	  begin			   
	    temp_num := 0;
		/* see if user account is an active ${hdb_user} or ACLII ACCOUNT */
		select count(*) into temp_num  from ref_user_groups 
		where user_name = user and group_name in ('${hdb_user}','${hdb_user} ACLII') and active_flag = 'Y';
		exception when others then temp_num := -1;
	  end;
	  	
	  IF (temp_num < 1) THEN
		DENY_ACTION('ILLEGAL ACL VERSION II MODIFY_ACL DATABASE OPERATION -- No Permissions');
	  END IF;

	END IF;
	    
/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');

IF (p_delete_flag = 'N') THEN
/* now its time to put the data into the ref_user_group table, using a merge statement       */
/* since the record may already be there.  To avoid a messy if then else structure,  */
/* a dynamic merge statement will be created to do this dml.                           */
      
/* create a dynamic merge statement that will merge the values received by this procedure */

   m_statement := 'merge into ref_user_groups rug using ' ||
	' ( select ''' || p_user_name || ''' USER_NAME, ''' || p_group_name || ''' GROUP_NAME,''' ||
	  p_active_flag || ''' ACTIVE_FLAG from dual ) rb' ||
	' on (rug.user_name = rb.user_name and rug.group_name = rb.group_name ) ' ||
    ' when matched then update ' ||
    ' set  active_flag = rb.active_flag, last_modified_date = sysdate ' ||
    ' when not matched then insert ' ||
    ' (rug.user_name,rug.group_name,rug.active_flag,rug.last_modified_date) ' ||
    ' values ' ||
    ' (rb.user_name,rb.group_name,rb.active_flag,sysdate) ';

/* now execute this dynamic sql statement */
    execute immediate (m_statement);
ELSE
	/* then we delete the record based on the input  */
	Delete from ref_user_groups where user_name = p_user_name and group_name = p_group_name;
END IF;

/* now commit  */
commit;
	  
END; /*  end of procedure modify_acl  */
 
 
PROCEDURE MODIFY_SITE_GROUP_NAME(
    P_SITE_ID		NUMBER,
    P_GROUP_NAME	VARCHAR2,
    P_DELETE_FLAG	VARCHAR2 DEFAULT 'N') IS

    indicator varchar2(1);
    m_statement varchar2(2000);
    l_acl_attr_id NUMBER;
	temp_num NUMBER;
	    
BEGIN
/*  This procedure was written to be the interface to 
    HDB from any application that will modify a Site's Grouping
    that is controlled by the data within table ref_site_attr
*/

/*  original development March 2010 by M.  Bogner   */
/*  modified October 2011 by M. Bogner for ACL II Project  */
                          
/* get the ACL site attribute id  */
   l_acl_attr_id := hdb_utilities.GET_SITE_ACL_ATTR;
   IF (l_acl_attr_id < 0) THEN
	DENY_ACTION('ILLEGAL ACL DATABASE OPERATION -- ACL Projects not enabled');
   END IF;
	    
	/* see if ACL PROJECT II is enabled and if user is permitted */
	IF (hdb_utilities.is_feature_activated(ACL_NAME_II) = 'Y') THEN
	  begin			   
	    temp_num := 0;
		/* see if user account is an active ${hdb_user} or ACLII ACCOUNT */
		select count(*) into temp_num  from ref_user_groups 
		where user_name = user and group_name in ('${hdb_user}','${hdb_user} ACLII') and active_flag = 'Y';
		exception when others then temp_num := -1;
	  end;
	  	
	  IF (temp_num < 1) THEN
		DENY_ACTION('ILLEGAL ACL VERSION II MODIFY_ACL DATABASE OPERATION -- No Permissions');
	  END IF;

	END IF;

/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');

IF (p_delete_flag = 'N') THEN
/* now its time to put the data into the ref_user_group table, using a merge statement       */
/* since the record may already be there.  To avoid a messy if then else structure,  */
/* a dynamic merge statement will be created to do this dml.                           */
      
/* create a dynamic merge statement that will merge the values received by this procedure */

   m_statement := 'merge into ref_site_attr rsa using ' ||
	' ( select ' || p_site_id || ' SITE_ID, ''' || p_group_name || ''' GROUP_NAME' ||
	'    from dual ) rb' ||
	' on (rsa.site_id = rb.site_id ' || 
	' and rsa.attr_id = ' || to_char(l_acl_attr_id) || ' ) ' ||
    ' when matched then update ' ||
    ' set  string_value = rb.group_name, date_time_loaded = sysdate ' ||
    ' when not matched then insert ' ||
    ' (rsa.site_id,rsa.attr_id,rsa.string_value,rsa.effective_start_date_time,rsa.date_time_loaded) ' ||
    ' values ' ||
    ' (rb.site_id,' || to_char(l_acl_attr_id) || ',rb.group_name,sysdate,sysdate) ';

/* now execute this dynamic sql statement */
    execute immediate (m_statement);
ELSE
	/* then we delete the record based on the input  */
	Delete from ref_site_attr where site_id = p_site_id and string_value = p_group_name 
	  and attr_id = l_acl_attr_id;
END IF;

/* now commit  */
commit;
	  
END; /*  end of procedure modify_site_group_name  */


 PROCEDURE touch_for_re_calculate_algo(
    SITE_DATATYPE_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_TIME DATE,
    END_TIME    DATE ) IS
    up_statement varchar2(2000);
	procedure_indicator varchar2(100);
    indicator varchar2(1);
    temp_chars varchar2(30);
    END_TIME_TEMP DATE;
    rows_touched NUMBER;
 BEGIN

	procedure_indicator := 'touch_for_re_calculate_algo FAILED FOR: ';
/*  first do error checking  */
    IF SITE_DATATYPE_ID IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL IS NULL THEN DENY_ACTION ( procedure_indicator || 'INVALID <NULL> INTERVAL' );
	ELSIF START_TIME IS NULL THEN DENY_ACTION (procedure_indicator || 'INVALID <NULL> START_TIME' );
	ELSIF END_TIME < START_TIME THEN DENY_ACTION (procedure_indicator || 'INVALID END_TIME : < START_TIME' );
    END IF;


/*  if end time was passed in null or used default null then set to start_time  */
	END_TIME_TEMP := END_TIME;
	IF END_TIME IS NULL THEN
	  END_TIME_TEMP := START_TIME;
	END IF;

/* create a dynamic sql statement that will update the records in the r_ interval
   table  based on the passed in sdi and dates.                                    */


   up_statement := 'update r_' || interval || ' set source_id = source_id where site_datatype_id = ' || to_char(site_datatype_id) ||
   '  and date_time_loaded >= to_date(''' ||
   to_char(start_time,'dd-MON-YYYY HH24:MI:SS') ||
   ''',''dd-MON-YYYY HH24:MI:SS'')  and date_time_loaded <= to_date(''' ||
   to_char(END_TIME,'dd-MON-YYYY HH24:MI:SS') ||
   ''',''dd-MON-YYYY HH24:MI:SS'')';

/*  insert into update_temp values (up_statement);  */
commit;

/* HDB_UTILITIES to set the manual edit to 'N'  */
   indicator := hdb_utilities.set_manual_edit('N');

/* now execute this dynamic sql statement */
   execute immediate (up_statement);
   rows_touched := SQL%ROWCOUNT;
   /* error out if no rows were update!!!  */
   IF rows_touched < 1 THEN
     DENY_ACTION (procedure_indicator || ' SDI:  ' || to_char(site_datatype_id) || ' with '
     || interval || ' INTERVAL and START DATE: ' || to_char(start_time) || ' Resulted in no rows update.');
   END IF;

/* finally do a commit since this procedure was successful and
   a commit will reduce possible deadlock issues  */
   commit;

END; /*  touch_for_re_calculate_algo procedures  */






   PROCEDURE RE_CALCULATE_ALGORITHM(
    ALGORITHM_ID NUMBER,
    INTERVAL         VARCHAR2,
    START_TIME       DATE,
    END_TIME       DATE
    ) IS
	procedure_indicator varchar2(100);
	STATUS_TEMP varchar2(100);
    temp_chars varchar2(30);
    START_TIME_TEMP DATE;
    END_TIME_TEMP DATE;
    total_count NUMBER;
    good_count NUMBER;
    bad_count NUMBER;
    ts_start DATE;
    TS_END DATE;
    db_timezone VARCHAR2(3);
    time_zone VARCHAR2(3);

    /* this is the cursor and the sql to get all sdi's that are input for an output sdi  */
    CURSOR get_all_input_sdis(ALG_ID_IN NUMBER, INTERVAL_IN VARCHAR2, START_DATE_IN DATE) IS
	select distinct castv.site_datatype_id, START_DATE_IN + (nvl(ccts2.DELTA_T,0)/86400) "TS_TIME",
        ccts2.interval
	from  cp_computation cc, cp_comp_ts_parm ccts, cp_algorithm ca, cp_comp_ts_parm ccts2,
		  cp_algo_ts_parm catp, cp_active_sdi_tsparm_view castv
	where
		 cc.enabled = 'Y'
	and  cc.loading_application_id is not null
	and  cc.computation_id = ccts.computation_id
	and  cc.algorithm_id = ca.algorithm_id
	and  ca.algorithm_id = catp.algorithm_id
	and  ca.algorithm_id = ALG_ID_IN
	and  ccts.algo_role_name = catp.algo_role_name
	and  catp.parm_type like 'o%'
	and  ccts.interval = INTERVAL_IN
	and  ccts.table_selector = 'R_'
	and  ccts2.computation_id = ccts.computation_id
	and  castv.site_datatype_id = ccts2.site_datatype_id
	and  castv.computation_id = cc.computation_id;

/*	and  castv.site_datatype_id = 1536;  /*temp in here for testing  */

 BEGIN
/*  This procedure was written to assist in "calculating" a record in HDB
    via the application UC_CP_FIX and may be called separately so that the
    real interval records that are inputs to a calculation would
    appear to have been modified and hence, spawn any computations
    that would result in the passed SDI as output.

    this procedure written by Mark Bogner   November 2008                   */

/*  Modified by M.  Bogner  06/01/2009 to add mods to accept different time_zone parameter */

	procedure_indicator := 'CALCULATE_ALGORITHM FAILED FOR: ';
/*  first do error checking  */
    IF ALGORITHM_ID IS NULL THEN
		DENY_ACTION( procedure_indicator || 'INVALID <NULL> ALGORITHM_ID');
	ELSIF INTERVAL IS NULL THEN
		DENY_ACTION( procedure_indicator || 'INVALID <NULL> INTERVAL');
	ELSIF START_TIME IS NULL THEN
		DENY_ACTION( procedure_indicator || 'INVALID <NULL> START_TIME');
    END IF;

/* get the databases default time zone  */
    BEGIN
      select param_value into db_timezone
        from ref_db_parameter, global_name
        where param_name = 'TIME_ZONE'
        and global_name.global_name = ref_db_parameter.global_name
        and nvl(active_flag,'Y') = 'Y';
       exception when others then
       db_timezone := NULL;
    END;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = interval;
       exception when others then
       DENY_ACTION( procedure_indicator || 'INVALID ' || interval || ' INTERVAL');
    END;

/*  if end time was passed in null or used default null then set to start_time  */
/*  commented out since we will not support a series of time
	END_TIME_TEMP := END_TIME;
	IF END_TIME IS NULL THEN
	  END_TIME_TEMP := START_TIME;
	END IF;
*/

	start_time_temp := START_TIME;
/* now convert the start_time to the database time if different, both exist,
   and only for the instantaneous and hourly interval           */
    IF (TIME_ZONE <> db_timezone AND INTERVAL in ('instant','hour')) THEN
       start_time_temp:= new_time(start_time_temp,TIME_ZONE,db_timezone);
    END IF;

	/* now loop through all sdi's that are inputs and "touch" them all */
	/* not just one SDI since we can't be sure all records for a single sdi
	   are there for the whole specified time period, without a whole
	   bunch of processing and checking counts etc...                 */
	bad_count := 0;
	good_count := 0;
	total_count := 0;
	procedure_indicator := ' FAILED ';

	/* loop through all the input sdis to touch them for a recomputation  */
	FOR p1 IN get_all_input_sdis(ALGORITHM_ID, INTERVAL, START_TIME_TEMP) LOOP
		BEGIN
			total_count := total_count + 1;
			TS_START := p1.TS_TIME;
			/* standardize the dates for result sdi based on input sdi start_date_time  */
			/*hdb_utilities.standardize_dates( SITE_DATATYPE_ID,INTERVAL, TS_START, TS_END); */
			/* now touch based on standardize dates for input interval in case the intervals don't coincide  */
/*insert into update_temp values (to_char(p1.SITE_DATATYPE_ID)|| '   ' || p1.INTERVAL);*/
commit;

			touch_for_re_calculate_algo(p1.SITE_DATATYPE_ID, p1.INTERVAL, START_TIME, END_TIME);
			good_count := good_count + 1;
			procedure_indicator := ' SUCCEEDED ';
			exception when others then
				/*deny_action(sqlerrm);  */
				bad_count := bad_count + 1;
		END;

	END LOOP;

  /* if the good_count is still zero then throw failed exception and how many SDIs were touched */
    IF (good_count = 0) THEN
		DENY_ACTION( 'CALCULATE_SERIES Procedure COMPLETED and' || procedure_indicator || ' for: '
		|| to_char(total_count) || ' Input SDIs with '
		|| interval || ' INTERVAL and START DATE: ' || to_char(start_time_temp,'dd-mon-yyyy HH24:mi'));
	END IF;

  END; /*  CALCULATE_SERIES procedure  */


END HDB_UTILITIES; 

/
-- Expanding: ./PACKAGES/pop_pk.sps
CREATE OR REPLACE PACKAGE populate_pk IS
   pkval_pre_populated	BOOLEAN := FALSE;
   FUNCTION get_pk_val ( table_name IN  VARCHAR2, set_pkval IN BOOLEAN ) RETURN number;
-- This procedure added by M. Bogner May 2012 to keep site_id from being updated via trigger
   PROCEDURE SET_PRE_POPULATED ( P_SET_VALUE IN NUMBER);
END;
/

GRANT EXECUTE ON populate_pk TO PUBLIC
/
-- Expanding: ./PACKAGES/pop_pk.spb
CREATE OR REPLACE PACKAGE BODY populate_pk IS
   FUNCTION get_pk_val ( table_name IN  VARCHAR2, set_pkval IN BOOLEAN ) RETURN number
   IS
      select_stmt     VARCHAR2(300) := NULL;
      curs_col_name   INTEGER := DBMS_SQL.OPEN_CURSOR;
      curs_nxt_val    INTEGER := DBMS_SQL.OPEN_CURSOR;
      curs_ret_val    INTEGER;
      loc_col_name    VARCHAR2(100) := NULL;
      loc_pk_val      number(11) := NULL;
      couldnt_generate_pk     EXCEPTION;
      PRAGMA EXCEPTION_INIT( couldnt_generate_pk, -20001 );
   BEGIN
      select_stmt := 'SELECT a.column_name';
      select_stmt := select_stmt||' FROM all_cons_columns a, all_constraints b';
      select_stmt := select_stmt||' WHERE a.constraint_name = b.constraint_name';
      select_stmt := select_stmt||' AND   b.table_name = '''||table_name||'''';
      select_stmt := select_stmt||' AND   b.constraint_type = ''P''';
      dbms_output.put_line(select_stmt);
      DBMS_SQL.PARSE( curs_col_name, select_stmt, DBMS_SQL.NATIVE );
      DBMS_SQL.DEFINE_COLUMN_CHAR( curs_col_name, 1, loc_col_name, 100 );
      curs_ret_val := DBMS_SQL.EXECUTE_AND_FETCH( curs_col_name );
      DBMS_SQL.COLUMN_VALUE_CHAR( curs_col_name, 1, loc_col_name );
      DBMS_SQL.CLOSE_CURSOR( curs_col_name );
      IF loc_col_name IS NULL THEN
         -- UH, OH!!!!  We could not get the name of the primary key
         -- We need this to generate the next value for the primary key.
         -- I will raise an application error here...
         raise couldnt_generate_pk;
         return 0;
      ELSE
         -- now, dynamically lookup the max(<primary_key>) value, and add one to it.
         select_stmt := 'SELECT max('||loc_col_name||') FROM '||table_name;
         DBMS_SQL.PARSE( curs_nxt_val, select_stmt, DBMS_SQL.NATIVE );
         DBMS_SQL.DEFINE_COLUMN( curs_nxt_val, 1, loc_pk_val );
         curs_ret_val := DBMS_SQL.EXECUTE_AND_FETCH( curs_nxt_val );
         DBMS_SQL.COLUMN_VALUE( curs_nxt_val, 1, loc_pk_val );
         DBMS_SQL.CLOSE_CURSOR( curs_nxt_val );
         IF loc_pk_val IS NULL THEN
	    -- No longer assume error; instead, assume that table is 
	    -- empty and set the PK value to 1. Marra, 6/00
	    -- 
            -- UH, OH!!!  Couldn't get the max value from the table.
            -- raise application error
            -- raise couldnt_generate_pk;
            -- return 0;
	    loc_pk_val := 1;
	    return loc_pk_val;
         ELSE
            loc_pk_val := loc_pk_val + 1;
            /* this is required to integrate DECODES into HDB  since DECODES uses sequences
               we need to insure that anyone adding sites must use the sequence
               modification by Mark Bogner  Mary 2005  */
            if (upper(table_name) = 'HDB_SITE') then
              select hdb_site_sequence.nextval into loc_pk_val from dual;
            end if;
            return loc_pk_val;
         END IF;
      END IF;
      -- Oracle Consulting: Gary Coy 5-NOV-1998
      -- This is only left here for historical purposes.
      -- This is the "other" method for getting the primary key.
      -- On 5, NOV, 1998, Tom Ryan and I decided to use the method
      -- of selecting the max(<primary_key>) value from the table,
      -- and adding one to it.  This was decided to elimate any question
      -- of sequences getting "out of whack", or using "strange numbers"
      -- If anyone decides to "switch back" and implement sequences,
      -- the commented code below is all that is needed...
      --select_stmt := 'SELECT '||table_name||'_seq.nextval FROM DUAL';
      --DBMS_SQL.PARSE( curs, select_stmt , DBMS_SQL.NATIVE );
      --DBMS_SQL.DEFINE_COLUMN( curs, 1, loc_pk_val );
      --curs_ret_val := DBMS_SQL.EXECUTE_AND_FETCH( curs );
      --DBMS_SQL.COLUMN_VALUE( curs, 1, loc_pkval );
      --DBMS_SQL.CLOSE_CURSOR( curs );
      --IF set_pkval THEN
      --   populate_pk.pkval_pre_populated := TRUE;
      --ELSE
      --   populate_pk.pkval_pre_populated := FALSE;
      --END IF;
      --return loc_pkval;
   END get_pk_val;

  PROCEDURE SET_PRE_POPULATED ( P_SET_VALUE  NUMBER)
   IS
    BEGIN
    /*  This procedure was written to set the PK populated boolean
         0  = TRUE
         anything else = FALSE
        
        this procedure written by Mark Bogner   May 2012                            */

      IF P_SET_VALUE = 0 THEN
        populate_pk.pkval_pre_populated := TRUE;
      ELSE
       populate_pk.pkval_pre_populated := FALSE;
      END IF;

        
    END;  /* End of Procedure SET_PRE_POPULATED  */     


END;
/
-- Expanding: ./PACKAGES/pre_processor.sps
create or replace package PRE_PROCESSOR as
/*  PACKAGE PRE_PROCESSOR is the package designed to contain all
    the procedures and functions for general PRE_PROCESSOR use.
    
    Created by M. Bogner OCTOBER 2008   
*/

/* modified October 2011 by M. Bogner to change signature of REVERIFICATION PROCEDURE  */

/*  DECLARE ALL GLOBAL variables  */
/*  none so far */


  PROCEDURE PREPROCESSOR(SDI NUMBER, INTERVAL_PERIOD VARCHAR2, START_TIME  DATE, 
		RESULT IN OUT FLOAT, VALIDATION IN OUT CHAR, DATA_FLAGS IN OUT VARCHAR2);
  
  PROCEDURE REVERIFICATION(P_SDI NUMBER, P_INTERVAL_PERIOD VARCHAR2, P_START_TIME  DATE, 
		P_END_TIME DATE DEFAULT NULL, P_DO_INTERVAL_DELETE VARCHAR2 DEFAULT 'N');

  PROCEDURE TEST_PACKAGE(SDI NUMBER, INTERVAL_PERIOD VARCHAR2, START_TIME  DATE, 
		END_TIME DATE);
		
    
END PRE_PROCESSOR;

/

create or replace public synonym PRE_PROCESSOR for PRE_PROCESSOR;
BEGIN EXECUTE IMMEDIATE 'grant execute on PRE_PROCESSOR to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/pre_processor.spb

CREATE OR REPLACE PACKAGE BODY PRE_PROCESSOR AS 

   PROCEDURE PREPROCESSOR(
    SDI NUMBER,
    INTERVAL_PERIOD         VARCHAR2,
    START_TIME  DATE,
    RESULT IN OUT FLOAT,
    VALIDATION IN OUT CHAR,
    DATA_FLAGS IN OUT VARCHAR2) IS
	procedure_indicator varchar2(100);
    END_TIME_TEMP DATE;
	temp_chars varchar2(100);
	sql_stmt varchar2(1000);
	result_chars varchar2(100);
	result_value number;
	start_time_chars  varchar2(100);
    equation_stmt     varchar2(1000);
    
 BEGIN
/*  This procedure was written to assist in "pre-processing" a record in HDB
    so that the pre-processing can re-calculate an input value based on a user defined
    equation
    
    this procedure written by Mark Bogner   October 2008         
    sysdate replaced with start_time in equation statement by CarolM. August 2017

*/
   
	procedure_indicator := 'PREPROCESSOR FAILED FOR: ';
/*  first do error checking  */
    IF SDI IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID');
	ELSIF INTERVAL_PERIOD IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> INTERVAL');
	ELSIF START_TIME IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> START_DATE_TIME');
	ELSIF RESULT is NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> RESULT');
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = INTERVAL_PERIOD;
       exception when others then 
       DENY_ACTION(procedure_indicator || 'INVALID ' || INTERVAL_PERIOD || ' INTERVAL');
    END;

	/* go see if there is an equation for the pre-processor */
	/*  if not, then just return							*/
    BEGIN
      select preprocessor_equation into equation_stmt
        from ref_interval_copy_limits
        where site_datatype_id = SDI 
         and interval = INTERVAL_PERIOD
         and effective_start_date_time <= start_time
         and nvl(effective_end_date_time,sysdate) >= start_time
         and preprocessor_equation is not null;
       exception when others then        
	   RETURN;
    END;
		
		/*equation_stmt := '<<value>> * 3.145';*/
		/*equation_stmt := '(sysdate - 5) - <<tsbt>>'; */
		
		/* we have an equation , so do some substitution  */
		equation_stmt := replace(equation_stmt,'<<value>>',to_char(round(result,7)));	
		equation_stmt := replace(equation_stmt,'<<tsbt>>','to_date(''' || 
	-- sysdate replaced with start_time
		to_char(start_time,'dd-mon-yyyy hh24:mi:ss') || ''',''dd-mon-yyyy hh24:mi:ss'')');
		sql_stmt := 'select ' || equation_stmt || ' from dual';

	BEGIN
		/* now we have the calculation figured out so submit the statement to get the result  */
		execute immediate (sql_stmt) into result_value;
        exception when others then 
			/*  set the return parameters to indicate failure, leave result the same  */
			validation := 'F';
			data_flags := 'FAILED PREPROCESSOR';
            /* deny_action(sqlerrm);  removed testing purposes only */
   			RETURN;
	END;  
	
	/* so things should have succeeded here so finish up and return  */
	result := result_value;
	/*deny_action('PASSED !!!! ' || sql_stmt||'  : '|| to_char(result));*/
	
  END; /*  preprocessor procedure  */


PROCEDURE delete_matching_records(
    SDI				 NUMBER,
    INTERVAL_PERIOD  VARCHAR2,
    START_TIME       DATE,
    END_TIME         DATE,
    P_VALIDATION     VARCHAR2 DEFAULT '%') IS
    delete_stmt varchar2(2000);
BEGIN
/*  This procedure was written to be the interface to 
    HDB in order to reprocess records currently existing in R_BASE
    The records in R_BASE are scheduled to be re-processed and 
    this procedure will also delete any records in the corresponding
    interval table that failed the reprocessing if requested with
    the P_DO_INTERVAL_DELETE parameter set to "Y"
                          
    this procedure written by Mark Bogner   October 2008          */
/* modified by M. Bogner, SUtron Corporation October 2011 to process 
   things differently                                             */
   
/* create a dynamic sql statement that will delete the records from 
   the r_ interval table that currently exists in r_base based on 
   the passed in sdi, interval and dates.                         */
   
   delete_stmt := 
   'delete from r_' || INTERVAL_PERIOD || ' tbl1 where exists ' || 
   ' ( select ''x'' from r_base where site_datatype_id = ' || to_char(SDI) ||
   ' and start_date_time >= to_date(''' ||
   to_char(START_TIME,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')' ||
   ' and start_date_time <= to_date(''' ||
   to_char(END_TIME,'dd-MON-YYYY HH24:MI:SS') || 
   ''',''dd-MON-YYYY HH24:MI:SS'')' ||
   ' and interval = ''' || INTERVAL_PERIOD || '''' ||
   ' and validation LIKE ''' || P_VALIDATION || '''' ||
   ' and site_datatype_id = tbl1.site_datatype_id ' ||
   ' and start_date_time = tbl1.start_date_time )';

/* now execute this dynamic sql statement */
  BEGIN 
		execute immediate (delete_stmt); 
   /* deny_action(delete_stmt);  removed for testing only  */
		exception when others then 
		null;
  END;

END; /*  delete_matching_records procedures  */


   PROCEDURE REVERIFICATION(
    P_SDI NUMBER,
    P_INTERVAL_PERIOD         VARCHAR2,
    P_START_TIME  DATE,
    P_END_TIME    DATE DEFAULT NULL,
    P_DO_INTERVAL_DELETE VARCHAR2 DEFAULT 'N') IS
    
    CURSOR get_rbase_data(sdi NUMBER, intvl VARCHAR2, sdt DATE, edt DATE) IS  
    select *
    from r_base where site_datatype_id = sdi and interval = intvl 
    and start_date_time between sdt and edt;
	
	procedure_indicator varchar2(100);
    END_TIME_TEMP DATE;
	temp_chars varchar2(100);
    VALIDATION_NEW		R_BASE.VALIDATION%TYPE;
    DATA_FLAGS_NEW		R_BASE.DATA_FLAGS%TYPE;
    RESULTS_NEW		    R_BASE.VALUE%TYPE;

 BEGIN
/*  This procedure was written to assist in "reverifying" a record in HDB
    so that the processing acts as if the data for the specified time 
    period was re-entered into the system.  
                      
    this procedure written by Mark Bogner   October 2008          */

/* modified by M. Bogner, Sutron Corporation for Lower Colorado and Reno to work
   as intended, but to change the processing a little to be less intrusive
   to the r_base data and only delete from the interval table only what
   is necessary and if requested. This procedure will call modify_r_base
   for all records with the specified input_parameters                            */
   
	procedure_indicator := 'REVERIFICATION FAILED FOR: ';
/*  do input parameter error checking  */
    IF P_SDI IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID');
	ELSIF P_INTERVAL_PERIOD IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> INTERVAL');
	ELSIF P_START_TIME IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> START_DATE_TIME');
	ELSIF P_END_TIME < P_START_TIME THEN 
		DENY_ACTION(procedure_indicator || 'INVALID (< START_TIME) END_TIME');
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = P_INTERVAL_PERIOD;
       exception when others then 
       DENY_ACTION(procedure_indicator || 'INVALID ' || P_INTERVAL_PERIOD || ' INTERVAL');
    END;

/*  if end time was passed in null or used default null then set to start_time  */
	END_TIME_TEMP := P_END_TIME;
	IF P_END_TIME IS NULL THEN 
	  END_TIME_TEMP := P_START_TIME;
	END IF;
	
	/* roll through all the r_base records for the input with preprocessor values */
    /* and do the revierification by calling modify_r_base                        */
    FOR p1 IN get_rbase_data(P_SDI,P_INTERVAL_PERIOD,P_START_TIME,END_TIME_TEMP) LOOP
      
      /* call modify_r_base with the cursor values */
      MODIFY_R_BASE (p1.site_datatype_id,p1.interval,p1.start_date_time, p1.end_date_time,
        p1.value,p1.agen_id,p1.overwrite_flag,'',p1.collection_system_id,p1.loading_application_id,
        p1.method_id,p1.computation_id,'Y','RV');
        		
	END LOOP;   /*  end of the r_base cursor loop  */
    
    IF P_DO_INTERVAL_DELETE = 'Y' THEN	
	  /* delete any matching records in the interval table  that failed the reverification */
 	  DELETE_MATCHING_RECORDS(P_SDI,P_INTERVAL_PERIOD,P_START_TIME,END_TIME_TEMP,'F');
    END IF;
    
    /* finally do a commit since this procedure was successful and 
       a commit will reduce possible deadlock issues  */
    commit;
	
  END; /*  reverification procedure  */


 
PROCEDURE TEST_PACKAGE(
    SDI				 NUMBER,
    INTERVAL_PERIOD	 VARCHAR2,
    START_TIME       DATE,
    END_TIME         DATE) IS
    delete_stmt varchar2(2000);
BEGIN
 
 /* This procedure is only to be used to test the procedures in this package  */
 /* this procedure written by Mark Bogner   October 2008          */
  
 /* enter the procedure calls to test below here  */
 
 /*delete_matching_records(SDI,INTERVAL_PERIOD,START_TIME,END_TIME);*/
 null;

END; /* TEST_PACKAGE */



END PRE_PROCESSOR;  /* Package End  */


/
-- Expanding: ./PACKAGES/ratings_pkg.sps
CREATE OR REPLACE PACKAGE ratings AS
  
/** 
 * Ratings package
 * connects to four tables: hdb_rating_algorithm, hdb_rating_type, 
 * ref_site_rating and ref_rating
 * Currently only supports 2-dimension x to y ratings
 * 3 dimension (x,y to z) ratings should
 * use two more tables, ref_site_3d_rating, and ref_3d_rating
 * also would require do_3d_rating, find_site_3d_rating, rating_3d_linear,
 * rating_3d_logarithmic algorithms and so forth.
*/


/** do_rating: actually does a rating. Must have previously looked up a rating_id
 * this procedure will use the rating algorithm defined in the hdb_rating_type
 * for the specified rating_id
 * Inputs:  rating_in - rating id from ref_site_rating
          indep_value - the independent value being rated
  Outputs: indep_base - the lower bound on indep_value found in the table
            dep_value - the y value resulting from the rating
          match_check - status of rating. Null, E for exact, A for extrapolation
          above maximum value, or B for extrapolation below min value.
*/
  
  PROCEDURE do_rating(rating_in in number,
  indep_value in number,
  indep_date in date,
  indep_base out number,
  dep_value out number,
  match_check out nocopy varchar2);

/* deletes all rows in ref_rating for a specific rating_id */

  procedure delete_rating_points(rating_in number);
  
/* creates a ref_site_rating entry */
  
  procedure create_site_rating(indep_site_datatype_id in number,
  rating_type_common_name in varchar2,
  effective_start_date_time in date,
  effective_end_date_time in date,
  agen_id in number,
  description in varchar2);
  
/* finds the minimum and maximum independent values for a specific rating_id */
  
  procedure find_rating_limits (rating_in in number,
  min_value out number,
  max_value out number);
  
/* finds the bounding independent and dependent values for a specified value and
  rating_id, as well as the same codes as do_rating for match_check */
  
  procedure find_rating_points (rating_in in number,
  indep_value in number,
  x1 out number,
  x2 out number,
  y1 out number,
  y2 out number,
  match_check out nocopy varchar2);

/*
Function to return a rating id if one exists that matches the input parameters
indep_sdi and rating_type are required
value_date_time is optional, and defaults to null
if it is null, ratings will only match if both start and end are null
if eff start or end are not null, they must be before or after value_date
respectively.
There is nothing in ref_site_rating prohibiting overlapping ratings.
Use of this function for time interpolated ratings is problematic because in that
case, we want two ratings, one from before, and one from after the date.

That case is currently left for applications to handle.
The most likely way to implement that is to put all ratings for time interpolation
in the database with  start and end effective dates as instants in time, then
query for the two ratings that span the value date of interest. Then do separate ratings
using those two rating ids, and then do time interpolation between them.
*/
 
  function find_site_rating( rating_type in varchar2,
  indep_sdi in number,
  value_date_time in date) 
  return ref_site_rating.rating_id%type;
  
/* alters a single row in ref_rating, good candiate for a merge statement, but
have not used that yet.*/

  procedure modify_rating_point (rating_in in number, 
  indep_value in number,
  dep_value in number);
  
/*
does a linear interpolation:
if an exact match is found, returns.
assumes the same equation for extrapolation as for interpolation
*/
  procedure rating_linear (rating_in in number,
      indep_value in number,
      indep_date in date,
      indep_base out number,
      dep_value out number,
      match_check out nocopy varchar2);

/*
LOG-LOG algorithm after Hydromet loglog and GSLOGLOG algorithms
Shift and offset are not applied here.
This function does no rounding on output, so it is likely to have many significant
figures (15+)

mathematic exceptions like log of a negative number cause exceptions just like other errors
*/
  procedure rating_logarithm (rating_in in number,
      indep_value in number,
      indep_date in date,
      indep_base out number,
      dep_value out number,
      match_check out nocopy varchar2);

/* want the row matching or immediately below the input
 * makes no sense to handle table bounds here,
 * so we just return B if the input x value is below the lowest number.
 * this should checked by the calling code
 */

  procedure rating_lookup (rating_in in number,
      indep_value in number,
      indep_date in date,
      indep_base out number,
      dep_value out number,
      match_check out nocopy varchar2);

/*
After Hydromet semilogx algorithm
Shift and offset are not applied here.
This function does no rounding on output, so it is likely to have many significant
figures (15+)
*/

  procedure rating_semilogx (rating_in in number,
      indep_value in number,
      indep_date in date,
      indep_base out number,
      dep_value out number,
      match_check out nocopy varchar2);

  PROCEDURE rating_time_interp_lookup(rating_in IN NUMBER,
      indep_value IN NUMBER,
      indep_date IN date,
      indep_base out number,
      dep_value OUT NUMBER,
      match_check OUT nocopy VARCHAR2);
      
   PROCEDURE rating_time_interp_linear(rating_in IN NUMBER,
      indep_value IN NUMBER,
      indep_date IN date,
      indep_base out number,
      dep_value OUT NUMBER,
      match_check OUT nocopy VARCHAR2);
 
/* alters the description field in ref_site_rating for a specified rating_id*/
  
  procedure update_rating_desc ( rating_in in number,
  description_in in varchar2);

END ratings;

/
-- Expanding: ./PACKAGES/ratings_pkg.spb
CREATE OR REPLACE PACKAGE BODY RATINGS 
AS

  PROCEDURE create_site_rating(indep_site_datatype_id IN NUMBER,
  rating_type_common_name IN VARCHAR2,
  effective_start_date_time IN DATE,
  effective_end_date_time IN DATE,
  agen_id IN NUMBER,
  description IN VARCHAR2)
  AS
  BEGIN

    IF(indep_site_datatype_id IS NULL) THEN
      deny_action('Invalid <NULL> indep_site_datatype_id');
    ELSIF(rating_type_common_name IS NULL) THEN
      deny_action('Invalid <NULL> rating_type_common_name');
    ELSIF(agen_id IS NULL) THEN
      deny_action('Invalid <NULL> agen_id');
    END IF;

    INSERT
    INTO ref_site_rating(rating_id, indep_site_datatype_id,
      rating_type_common_name, effective_start_date_time,
      effective_end_date_time, date_time_loaded,
      agen_id, description)
    VALUES(NULL, indep_site_datatype_id,
      rating_type_common_name, effective_start_date_time,
      effective_end_date_time, sysdate,
      agen_id, description);

  END create_site_rating;


  PROCEDURE delete_rating_points(rating_in NUMBER)
  AS
  v_count NUMBER;
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM ref_site_rating
    WHERE rating_id = rating_in;

    IF v_count = 0 THEN
      deny_action('Invalid non-existing rating_id ' ||
      rating_in || ' attempted for deletion of table');
    END IF;

    DELETE FROM ref_rating
    WHERE rating_id = rating_in;

  END delete_rating_points;

  PROCEDURE do_rating(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base OUT NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
  algorithm hdb_rating_type.rating_algorithm%TYPE;
  sqlstmt VARCHAR2(100);
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    IF(indep_value IS NULL) THEN
      deny_action('Invalid <NULL> independent value');
    END IF;

    BEGIN
      SELECT procedure_name
      INTO algorithm
      FROM hdb_rating_algorithm a,
        hdb_rating_type b,
        ref_site_rating c
      WHERE a.rating_algorithm = b.rating_algorithm
       AND b.rating_type_common_name = c.rating_type_common_name
       AND c.rating_id = rating_in;

    EXCEPTION
    WHEN others THEN
      deny_action('Unable to find algorithm for rating ' || rating_in);
    END;

    /* native dynamic SQL call to the procedure named in the hdb_rating_algorithm table */
    sqlstmt := 'begin ratings.' || algorithm || '(:2, :3, :4, :5, :6, :7); end;';

    EXECUTE IMMEDIATE(sqlstmt) USING IN rating_in,
      IN indep_value,
      IN indep_date,
      OUT indep_base,
      OUT dep_value,
      OUT match_check;

  END do_rating;

  PROCEDURE find_rating_limits(rating_in IN NUMBER,
  min_value OUT NUMBER,
  max_value OUT NUMBER)
  AS
  v_count NUMBER;
  BEGIN
    SELECT COUNT(*),
      MIN(independent_value),
      MAX(independent_value)
    INTO v_count,
      min_value,
      max_value
    FROM ref_rating
    WHERE rating_id = rating_in;

    IF(v_count = 0) THEN
      deny_action('Rating_id ' ||
      rating_in || ' does not have any rows in rating table');
    END IF;

  END find_rating_limits;

  PROCEDURE find_rating_points(rating_in IN NUMBER,
  indep_value IN NUMBER,
  x1 OUT NUMBER,
  x2 OUT NUMBER,
  y1 OUT NUMBER,
  y2 OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
  v_count NUMBER;
  min_value NUMBER;
  max_value NUMBER;
  x_search_above NUMBER;
  x_search_below NUMBER;
  BEGIN

    /* check input */

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    IF(indep_value IS NULL) THEN
      deny_action('Invalid <NULL> independent value');
    END IF;

    /* search points */
    x_search_above := indep_value;
    x_search_below := indep_value;

    /* check for exact match */
    SELECT COUNT(*)
    INTO v_count
    FROM ref_rating
    WHERE rating_id = rating_in
     AND independent_value = indep_value;

    IF(v_count > 0) THEN

      /*exact, return two copies of same data */
      match_check := 'E';
      x1 := indep_value;
      x2 := indep_value;

      SELECT dependent_value,
        dependent_value
      INTO y1,
        y2
      FROM ref_rating
      WHERE rating_id = rating_in
       AND independent_value = indep_value;

      RETURN;
      -- unreachable?
    END IF;

    /* non exact, find outer limits of table */
    find_rating_limits(rating_in, min_value, max_value);

    IF(indep_value < max_value) THEN  /* must search for x2 */
      IF(indep_value < min_value) THEN

        /* x1 is min_value, search above for x2 */
        match_check := 'B';
        x1 := min_value;
        x_search_above := min_value;
      END IF;

      SELECT MIN(independent_value)
      INTO x2
      FROM ref_rating
      WHERE rating_id = rating_in
       AND independent_value > x_search_above;
    END IF;

    IF(indep_value > min_value) THEN /* must search for x1 */
      IF(indep_value > max_value) THEN

        /* x2 is max value, search below for x1 */
        match_check := 'A';
        x2 := max_value;
        x_search_below := max_value;
      END IF;

      SELECT MAX(independent_value)
      INTO x1
      FROM ref_rating
      WHERE rating_id = rating_in
       AND independent_value < x_search_below;
    END IF;

    /* get y values for resulting x */
    SELECT dependent_value
    INTO y1
    FROM ref_rating
    WHERE rating_id = rating_in
     AND independent_value = x1;

    SELECT dependent_value
    INTO y2
    FROM ref_rating
    WHERE rating_id = rating_in
     AND independent_value = x2;

  END find_rating_points;

  FUNCTION find_site_rating(rating_type IN VARCHAR2,
  indep_sdi IN NUMBER,
  value_date_time IN DATE)
  RETURN ref_site_rating.rating_id%TYPE
  AS
  rating ref_site_rating.rating_id%TYPE;
  duprating ref_site_rating.rating_id%TYPE;
  v_count NUMBER;

  CURSOR c1 IS
  SELECT rating_id
  INTO rating
  FROM ref_site_rating
  WHERE indep_site_datatype_id = indep_sdi
   AND rating_type_common_name = rating_type
   AND((effective_start_date_time IS NULL
        AND effective_end_date_time IS NULL)
      OR (value_date_time >= effective_start_date_time
          AND effective_end_date_time IS NULL)
      OR (value_date_time <= effective_end_date_time
          AND effective_start_date_time IS NULL)
      OR (value_date_time >= effective_start_date_time
          AND value_date_time < effective_end_date_time));

  BEGIN

  /*procedure from O'Reilly PL/SQL programming
  determine if more than one rating matches
  if so, we have a problem
  */

    OPEN c1;
    FETCH c1
    INTO rating;

    IF c1 % NOTFOUND THEN
      CLOSE c1;
      RETURN NULL;

      /*no rating at all matched*/
    ELSE
      FETCH c1
      INTO duprating;

      IF c1 % NOTFOUND THEN
        CLOSE c1;
        RETURN rating;
      ELSE
        /* more than one match!*/
        CLOSE c1;
        deny_action('More than one rating matched input!');
        RETURN NULL;
      END IF;
    END IF;

  END find_site_rating;

  PROCEDURE modify_rating_point(rating_in IN NUMBER,
  indep_value IN NUMBER,
  dep_value IN NUMBER)
  AS
  v_count NUMBER;
  BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ref_rating
    WHERE rating_id = rating_in
     AND independent_value = indep_value;

    IF v_count = 0 THEN
      INSERT
      INTO ref_rating(rating_id, independent_value, dependent_value)
      VALUES(rating_in, indep_value, dep_value);
    ELSE
      UPDATE ref_rating
      SET dependent_value = dep_value
      WHERE rating_id = rating_in
       AND independent_value = indep_value;
    END IF;

  END modify_rating_point;

  PROCEDURE rating_linear(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base OUT NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
  x1 NUMBER;
  x2 NUMBER;
  y1 NUMBER;
  y2 NUMBER;
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    BEGIN
      find_rating_points(rating_in,
        indep_value, x1, x2, y1, y2, match_check);

      indep_base := x1;

      IF(match_check = 'E') THEN
        dep_value := y1;
      ELSE
        dep_value := y1 + (y2 -y1)/(x2 -x1)*(indep_value -x1);
      END IF;

    EXCEPTION
    WHEN others THEN
      deny_action('Unable to complete linear rating for rating ' ||
        rating_in || ' value ' || indep_value);
    END;

  END rating_linear;

  PROCEDURE rating_logarithm(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base OUT NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
  x1 NUMBER;
  x2 NUMBER;
  y1 NUMBER;
  y2 NUMBER;
  dy NUMBER;
  dx NUMBER;
  x NUMBER;
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    BEGIN
   
  -- This first outer IF statement added by Ismail Ozdemir on 08/20/2010
  -- to check if the shiftedGH <=0 , the flow is 0.  
  -- Another if statement to check unshifted GH=0 then flow=0 is 
  -- added in uc_algorithms.jar file
  
 IF(indep_value <= 0) THEN
 dep_value :=0;
 ELSE
      find_rating_points(rating_in,
      indep_value, x1, x2, y1, y2, match_check);

      indep_base := x1;
      
      IF (y1 = 0 OR y2 = 0 or x1 = 0 or x2 = 0 OR indep_value = 0) THEN
        deny_action('Unable to complete logarithmic rating for rating ' ||
      rating_in || ', rating points = 0 are not usable in logarithmic rating, value ' || indep_value);
      END IF;

      IF(match_check = 'E') THEN
        dep_value := y1;
      ELSE
        y1 := LOG(10,   y1);
        y2 := LOG(10,   y2);
        x1 := LOG(10,   x1);
        x2 := LOG(10,   x2);
        x := LOG(10,   indep_value);
        dy :=(y2 -y1);
        dx :=(x2 -x1);

        dep_value := POWER(10,   y1 + dy / dx *(x -x1));
      END IF;
 END IF;
    
    EXCEPTION
    WHEN others THEN
      deny_action('Unable to complete logarithmic rating for rating ' ||
      rating_in || ' value ' || indep_value);
    END;

  END rating_logarithm;

  PROCEDURE rating_lookup(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base OUT NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    BEGIN
      SELECT independent_value,
        dependent_value
      INTO indep_base,
        dep_value
      FROM ref_rating
      WHERE rating_id = rating_in
       AND independent_value =
        (SELECT MAX(independent_value)
         FROM ref_rating
         WHERE rating_id = rating_in
         AND independent_value <= indep_value);

    EXCEPTION
    WHEN no_data_found THEN
      match_check := 'B';
    WHEN others THEN
      deny_action('Unable to complete lookup rating for rating ' ||
      rating_in || ' value ' || indep_value);
    END;

  END rating_lookup;

  PROCEDURE rating_semilogx(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base OUT NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
  x1 NUMBER;
  x2 NUMBER;
  y1 NUMBER;
  y2 NUMBER;
  dy NUMBER;
  dx NUMBER;
  x NUMBER;
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    BEGIN
      find_rating_points(rating_in,
      indep_value, x1, x2, y1, y2, match_check);

      IF (x1 = 0 or x2 = 0 or indep_value = 0) THEN
        deny_action('Unable to complete logarithmic rating for rating ' ||
      rating_in || ', rating points = 0 are not usable in logarithmic rating, value ' || indep_value);
      END IF;
      
      indep_base := x1;

      IF(match_check = 'E') THEN
        dep_value := y1;
      ELSE
        x1 := LOG(10,   x1);
        x2 := LOG(10,   x2);
        x := LOG(10,   indep_value);
        dy :=(y2 -y1);
        dx :=(x2 -x1);

        dep_value := y1 + dy / dx *(x -x1);
      END IF;

    EXCEPTION
    WHEN others THEN

      deny_action('Unable to complete logarithmic rating for rating ' ||
      rating_in || ' value ' || indep_value);
    END;

  END rating_semilogx;

  PROCEDURE rating_time_interp_lookup(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base out NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
/** Function to do a time interpolated rating. The algorithm:
   Do a lookup rating with this rating table.
   See if a rating exists for the time period after this rating id.
   If it does exist, then perform a lookup rating with that table.
   Interpolate between the two results in time, and return that value
  */
  sdi ref_site_rating.indep_site_datatype_id%type;
  rating ref_site_rating.rating_type_common_name%type;
  sdate ref_site_rating.effective_start_date_time%type;
  edate ref_site_rating.effective_end_date_time%type;
  after_rating ref_site_rating.rating_id%type;
  after_dep_value NUMBER;
  x1 date;
  x2 date;
  y1 NUMBER;
  y2 NUMBER;
  BEGIN

    rating_lookup(rating_in,indep_value,indep_date,indep_base,dep_value,match_check);

    /*find information about this rating */
    select indep_site_datatype_id, rating_type_common_name,
      effective_start_date_time,effective_end_date_time
    into sdi, rating, sdate, edate
    from ref_site_rating
    where rating_id = rating_in;

    if indep_date <sdate or indep_date >= edate then
      deny_action ('Date for time interpolated rating is not within effective range
        for rating id '|| rating_in);
    end if;

    /* find rating id for values after we end (our end date or later) */
    select find_site_rating(rating,sdi,edate)
    into after_rating
    from dual;

    if after_rating is not null and after_rating != rating_in then
    /* sanity check, after rating id must have a effective_start_date_time
      equal to our end time */
      begin
        select rating_id
        into after_rating
        from ref_site_rating where
        rating_id = after_rating and
        effective_start_date_time = edate;
        exception when no_data_found then
          deny_action('Rating '|| after_rating ||' does not have expected start_time, cannot complete time interpolation!');
      end;

      /* do a rating in the rating table after us */
      rating_lookup(after_rating,indep_value,indep_date,indep_base,after_dep_value,match_check);

      /* now interpolate */
      y1:=dep_value;
      y2:=after_dep_value;
      x1:=sdate;
      x2:=edate;

      IF (indep_date = sdate) THEN
        dep_value := y1;
      ELSE
        dep_value := y1 + (y2 -y1)/(x2 -x1)*(indep_date -x1);
      END IF;
    /* else no rating found after us, we just use the first result. */
    end if;

  END rating_time_interp_lookup;

  PROCEDURE rating_time_interp_linear(rating_in IN NUMBER,
  indep_value IN NUMBER,
  indep_date IN DATE,
  indep_base out NUMBER,
  dep_value OUT NUMBER,
  match_check OUT nocopy VARCHAR2)
  AS
/** Function to do a time interpolated rating. The algorithm:
   Do a linear rating with this table.
   See if a rating exists for the time period after this rating id.
   If it does exist, then perform a linear rating with that table.
   Interpolate between the two results in time, and return that value
  */
  sdi ref_site_rating.indep_site_datatype_id%type;
  rating ref_site_rating.rating_type_common_name%type;
  sdate ref_site_rating.effective_start_date_time%type;
  edate ref_site_rating.effective_end_date_time%type;
  after_rating ref_site_rating.rating_id%type;
  after_dep_value NUMBER;
  x1 date;
  x2 date;
  y1 NUMBER;
  y2 NUMBER;
  BEGIN

    rating_linear(rating_in,indep_value,indep_date,indep_base,dep_value,match_check);

    /*find information about this rating */
    select indep_site_datatype_id, rating_type_common_name,
      effective_start_date_time,effective_end_date_time
    into sdi, rating, sdate, edate
    from ref_site_rating
    where rating_id = rating_in;

    if indep_date <sdate or indep_date >= edate then
      deny_action ('Date for time interpolated rating is not within effective range
        for rating id '|| rating_in);
    end if;

    /* find rating id for values after we end (our end date or later) */
    select find_site_rating(rating,sdi,edate)
    into after_rating
    from dual;

    /* see if there is an after rating, and it is a different table than first */
    if after_rating is not null and after_rating != rating_in then
    /* sanity check, after rating id must have a effective_start_date_time
      equal to our end time */
      begin
        select rating_id
        into after_rating
        from ref_site_rating where
        rating_id = after_rating and
        effective_start_date_time = edate;
        exception when no_data_found then
          deny_action('Rating '|| after_rating ||' does not have expected start_time, cannot complete time interpolation!');
      end;

      /* do a rating in the rating table after us */
      rating_linear(after_rating,indep_value,indep_date,indep_base,after_dep_value,match_check);

      /* now interpolate */
      y1:=dep_value;
      y2:=after_dep_value;
      x1:=sdate;
      x2:=edate;

      IF (indep_date = sdate) THEN
        dep_value := y1;
      ELSE
        dep_value := y1 + (y2 -y1)/(x2 -x1)*(indep_date -x1);
      END IF;
    /* else no rating found after us, we just use the first result. */
    end if;

  END rating_time_interp_linear;


  PROCEDURE update_rating_desc(rating_in IN NUMBER,
  description_in IN VARCHAR2)
  AS
  v_count NUMBER;
  BEGIN

    IF(rating_in IS NULL) THEN
      deny_action('Invalid <NULL> rating_id');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM ref_site_rating
    WHERE rating_id = rating_in;

    IF v_count = 0 THEN
      deny_action('Invalid non-existing rating_id ' ||
      rating_in || ' attempted for description update');
    END IF;

    UPDATE ref_site_rating
    SET description = description_in
    WHERE rating_id = rating_in;

  END update_rating_desc;

END ratings;


/
-- Expanding: ./PACKAGES/riverware_connection.sps
CREATE OR REPLACE PACKAGE RIVERWARE_CONNECTION as
/*  PACKAGE riverware_connection is the package designed to contain all
    the procedures and functions necessary to incorporate the 
    requirements for the Riverware - hdb direct connection capability
 
    Created by M. Bogner  March 2007   
    Modified 4/09/2007  to take out status and error messaging
    Modified by M. Bogner January 2014to add Riverware ensemble procedures
    Modified by IsmailO March 16 2017 to add Validation column with  read_db_data_flag_to_riverware and read_real_data_flag
*/
	/* declare the associative array table types for this package   */
	TYPE numberTable is TABLE of NUMBER INDEX BY BINARY_INTEGER;
	TYPE stringTable is TABLE of VARCHAR2(32) INDEX BY BINARY_INTEGER;
	TYPE stringTableLrg is TABLE of VARCHAR2(256) INDEX BY BINARY_INTEGER;
    	TYPE charTable is TABLE of CHAR(1) INDEX BY BINARY_INTEGER;
	TYPE stringTableCLOB is TABLE of VARCHAR2(2000) INDEX BY BINARY_INTEGER;
    
    --TYPE string_nt IS TABLE OF VARCHAR2 (1000);
    --TYPE numbers_nt IS TABLE OF NUMBER;
	
	/*  CURR_START_OF_TIME is a date that Riverware uses to indicate it's start
    of time.  THis package will be written in a way that if this date changes 
    in Riverware then this date will change dynamically since the start of time
    date is passed into the various procedures as a modifiable parameter
    */
	
	CURR_START_OF_TIME DATE := NULL; 
	
	/* declare all the keys that will be used when calling the HDB stored Procedures  */
	CURR_DATA_SOURCE_ID HDB_EXT_DATA_SOURCE.EXT_DATA_SOURCE_ID%TYPE;
	CURR_AGENCY_ID		HDB_AGEN.AGEN_ID%TYPE;
	CURR_COLLECTION_ID	HDB_COLLECTION_SYSTEM.COLLECTION_SYSTEM_ID%TYPE;
	CURR_OVERWRITE_FLAG R_BASE.OVERWRITE_FLAG%TYPE;
	CURR_MODEL_RUN_ID	REF_MODEL_RUN.MODEL_RUN_ID%TYPE;
	CURR_DATA_TABLES    VARCHAR2(30);
	CURR_DATA_TYPE      VARCHAR2(30);
	
	/* now all the default values used for this Stored Procedure  */
	/*  first declare all internal variables need for call to modify_r_base_raw 
        and to modify m_tables_raw
        NOTE!!!!! THe ${hdb_user} who installs this package must assure that these defaults
        agree with their tables version of the default values
                                                       */
    DEF_VALIDATION             R_BASE.VALIDATION%TYPE := NULL;
    DEF_METHOD_ID              R_BASE.METHOD_ID%TYPE := 18;  /* unknown  */
    DEF_COMPUTATION_ID         R_BASE.COMPUTATION_ID%TYPE := 1;  /* unknown  */
    DEF_LOADING_APPLICATION_ID R_BASE.LOADING_APPLICATION_ID%TYPE:= 7;  /* RIVERWARE DMI */
	
	/* SECONDS_PER_DAY is a constant for the # of seconds in a day */
	SECONDS_PER_DAY CONSTANT NUMBER := 86400;

/*	procedure init_riverware_dmi passes in all needed HDB parameters  
    for this DMI event                                                ` */
	procedure init_riverware_dmi(  
	  parameter_names IN stringTable,
	  parameter_values IN stringTable);

/*	procedure init_riverware_dataset passes in all needed HDB parameters  
    for this DMI  DATASET event                                                ` */
	procedure init_riverware_dataset(  
	  parameter_names IN stringTable,
	  parameter_values IN stringTable);
	  
/*  procedure get_info_for_riverware_slot  looks up the unit and the SDI for a object and slot name  */
	procedure get_info_for_riverware_slot(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  parameter_names    stringTable,
	  parameter_values   stringTable,
	  output_parameter_names  OUT stringTable,
	  output_parameter_values OUT stringTable);

/*	procedure write_riverware_data_to_db writes data to database from Riverware    */  
	procedure write_riverware_data_to_db(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  date_array            numberTable,
	  value_array           numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable);


/*	procedure write_rw_group_data_to_db writes group data to database from Riverware    */  
	procedure write_rw_group_data_to_db(  
	  number_of_grouped_slots NUMBER,
      riverware_object_names	stringTableCLOB,
	  riverware_slot_names	stringTableCLOB,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
      slot_date_value_counts numberTable,
	  date_array            numberTable,
	  value_array           numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable);


/*	procedure delete_riverware_data_from_db deletes data in database from Riverware    */  
	procedure delete_riverware_data_from_db(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  date_array            numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable);	  
      
/*	procedure delete_rw_group_data_from_db deletes group data in database from Riverware    */  
	procedure delete_rw_group_data_from_db( 
      number_of_grouped_slots NUMBER,
      riverware_object_names	stringTableCLOB,
	  riverware_slot_names	stringTableCLOB,
      interval_number       NUMBER,
	  interval_name         VARCHAR2,
      slot_date_value_counts numberTable,
	  date_array            numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable);	      
      

/*	procedure read_db_data_to_riverware reads data from database to pass to Riverware    */  
	procedure read_db_data_to_riverware(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  start_time			NUMBER,
	  end_time				NUMBER,
	  parameter_names       stringTable,
	  parameter_values      stringTable,
	  date_array        OUT numberTable,
	  value_array       OUT numberTable);

/*	procedure read_db_data_flag_to_riverware reads data from database to pass to Riverware    */  
	procedure read_db_data_flag_to_riverware(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  start_time			NUMBER,
	  end_time				NUMBER,
	  parameter_names       stringTable,
	  parameter_values      stringTable,
	  date_array        OUT numberTable,
	  value_array       OUT numberTable,
    flag_array	OUT	charTable);

/* the following procedures were create January 2014 for the Riverware ensemble project  */
/* the procedures and functions were written by M. Bogner, Sutron Corporation January 2014    */

    
/*  function get_ensemble_trace_mri returns the model run_id for the input ensemble_id, trace_id  */
	function get_ensemble_trace_mri( p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
	                                 p_trace_id  REF_ENSEMBLE_TRACE.TRACE_ID%TYPE )
	                                 RETURN NUMBER;

/*	procedure init_ensemble passes in all needed HDB parameters  
    for this ensemble event                                                  */
	procedure init_ensemble( p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE);

/*  procedure read_ensemble_metadata looks up the metadata for a given ensemble  */
	procedure read_ensemble_metadata(  
	  p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
	  output_parameter_names  OUT stringTable,
	  output_parameter_values OUT stringTableLrg);

/*  procedure read_ensemble_trace_metadata looks up the metadata for a given ensemble trace */
	procedure read_ensemble_trace_metadata(  
	  p_ensemble_id REF_ENSEMBLE_TRACE.ENSEMBLE_ID%TYPE,
	  p_trace_id  REF_ENSEMBLE_TRACE.TRACE_ID%TYPE,
	  output_parameter_names  OUT stringTable,
	  output_parameter_values OUT stringTableLrg);

/*	procedure write_ensemble_metadata passes in all needed HDB Ensemble parameters  
    for this DMI Ensemble event                                                    */
	procedure write_ensemble_metadata(  
	  p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
	  p_parameter_names IN stringTable,
	  p_parameter_values IN stringTableLrg);

/*	procedure write_ensemble_trace_metadata passes in all needed HDB 
    Ensemble Trace parameters  for this DMI Ensemble event                         */
	procedure write_ensemble_trace_metadata(  
	  p_ensemble_id REF_ENSEMBLE_TRACE.ENSEMBLE_ID%TYPE,
	  p_trace_id  REF_ENSEMBLE_TRACE.TRACE_ID%TYPE,
	  p_parameter_names IN stringTable,
	  p_parameter_values IN stringTableLrg);


/*  procedure testing is for testing any procedure in this package  */
/*
	procedure testing(
	test_number NUMBER,
	test_char   VARCHAR2);
*/

  procedure create_ensemble_id (
  p_ensemble_id OUT REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
  p_ensemble_name IN REF_ENSEMBLE.ENSEMBLE_NAME%TYPE,
  p_model_id IN REF_MODEL_RUN.MODEL_ID%TYPE,
  p_number_traces IN number,
  p_agency_id IN REF_ENSEMBLE.AGEN_ID%TYPE,
  p_trace_domain IN REF_ENSEMBLE.TRACE_DOMAIN%TYPE,
  p_cmmnt IN REF_ENSEMBLE.CMMNT%TYPE );

  procedure update_ensemble_id (
p_ensemble_id IN REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
p_ensemble_name IN REF_ENSEMBLE.ENSEMBLE_NAME%TYPE,
p_model_id IN REF_MODEL_RUN.MODEL_ID%TYPE,
p_number_traces IN number,
p_agency_id IN REF_ENSEMBLE.AGEN_ID%TYPE,
p_trace_domain IN REF_ENSEMBLE.TRACE_DOMAIN%TYPE,
p_cmmnt IN REF_ENSEMBLE.CMMNT%TYPE );

  procedure create_ref_model_run_rec (
  p_ensemble_name IN REF_ENSEMBLE.ENSEMBLE_NAME%TYPE,
  p_model_id IN REF_MODEL_RUN.MODEL_ID%TYPE,
  p_model_run_id OUT REF_MODEL_RUN.MODEL_ID%TYPE,
  p_trace_number IN number);

  procedure create_ref_ensemble_trace_rec (
  p_ensemble_id IN REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
  p_model_run_id IN REF_MODEL_RUN.MODEL_RUN_ID%TYPE,
  p_trace_number IN number);

end riverware_connection;

/

--grant execute on riverware_connection to model_priv_role;
--create or replace public synonym riverware_connection for riverware_connection;
-- Expanding: ./PACKAGES/riverware_connection.spb
CREATE OR REPLACE PACKAGE BODY RIVERWARE_CONNECTION as
 
	procedure read_model_data(  
		interval		HDB_INTERVAL.INTERVAL_NAME%TYPE,
		sdi_number		REF_EXT_SITE_DATA_MAP.HDB_SITE_DATATYPE_ID%TYPE,
		run_id			REF_MODEL_RUN.MODEL_RUN_ID%TYPE,
		start_of_time	DATE,
		begin_date		R_BASE.START_DATE_TIME%TYPE,
		end_date		R_BASE.START_DATE_TIME%TYPE,
		date_array	OUT	numberTable,
		value_array	OUT	numberTable) is

		CURSOR C_HOUR (mri IN NUMBER, sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((start_date_time - sot + 1/24) * spd ), value from m_hour
		where model_run_id = mri and site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_DAY (mri IN NUMBER, sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((start_date_time - sot + 1) * spd ), value from m_day
		where  model_run_id = mri and site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_MONTH (mri IN NUMBER, sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,1) - sot) * spd ), value from m_month
		where  model_run_id = mri and site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_YEAR (mri IN NUMBER, sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,12) - sot) * spd ), value from m_year
		where  model_run_id = mri and site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_WY (mri IN NUMBER, sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,12) - sot) * spd ), value from m_wy
		where  model_run_id = mri and site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 
	
	/*
	  Procedure read_model_data reads HDB data from the "model" tables based on the input parameters
	  Riverware expects the dates in seconds since it's start of time for that model. Hence, the 
	  calulations on HDB dates is : start_date_time minus the Riverware beginning of time multiplied
	  by the number of seconds per day.  Also since riverware expects the dates to be at the end of 
	  period, we must add an interval of time to the start_date_time for each period.
	  
	 Initial Programming  by M. Bogner     April 2007
	 Modified April 25 by M. Bogner to have cursors return data ordered by start_date_time
	*/
	 
	 /* first declare all the temporary variables needed for this procedure   */
	 BEGIN	 
	 
	  IF interval = 'hour' THEN
		OPEN C_HOUR(run_id,sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_HOUR BULK COLLECT into date_array, value_array;
		CLOSE C_HOUR;
	  ELSIF interval = 'day' THEN
		OPEN C_DAY(run_id,sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_DAY BULK COLLECT into date_array, value_array;
		CLOSE C_DAY;
	  ELSIF interval = 'month' THEN
		OPEN C_MONTH(run_id,sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_MONTH BULK COLLECT into date_array, value_array;
		CLOSE C_MONTH;
	  ELSIF interval = 'year' THEN
		OPEN C_YEAR(run_id,sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_YEAR BULK COLLECT into date_array, value_array;
		CLOSE C_YEAR;
	  ELSIF interval = 'wy' THEN
		OPEN C_WY(run_id,sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_WY BULK COLLECT into date_array, value_array;
		CLOSE C_WY;
	  END IF;
	end read_model_data;  /* end of the read model data procedure  */	


 
	procedure read_real_data(  
		interval		HDB_INTERVAL.INTERVAL_NAME%TYPE,
		sdi_number		REF_EXT_SITE_DATA_MAP.HDB_SITE_DATATYPE_ID%TYPE,
		start_of_time	DATE,
		begin_date		R_BASE.START_DATE_TIME%TYPE,
		end_date		R_BASE.START_DATE_TIME%TYPE,
		timestep        NUMBER,
		date_array	OUT	numberTable,
		value_array	OUT	numberTable) is

		CURSOR C_HOUR (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((start_date_time - sot + 1/24) * spd ), value from r_hour
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_DAY (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((start_date_time - sot + 1) * spd ), value from r_day
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_MONTH (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,1) - sot) * spd ), value from r_month
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_YEAR (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,12) - sot) * spd ), value from r_year
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_WY (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,12) - sot) * spd ), value from r_wy
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 
	
		/* c_other is not so well defined.  It will be hard to determine the end of period */
		/* so this code needs to be looked at if r_other starts being used but we will use the end_date 
		   time as a start to see if this works for folks.  timestep will be expected to be in days     */
		CURSOR C_OTHER (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER, timestep IN NUMBER) IS
		select round((end_date_time - sot) * spd ), value from r_other
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		and end_date_time - start_date_time = timestep
		order by start_date_time; 
	
	/*
	  Procedure read_real_data reads HDB data from the "real" tables based on the input parameters
	  Riverware expects the dates in seconds since it's start of time for that model. Hence, the 
	  calulations on HDB dates is : start_date_time minus the Riverware beginning of time multiplied
	  by the number of seconds per day.  Also since riverware expects the dates to be at the end of 
	  period, we must add an interval of time to the start_date_time for each period.
	  
	 Initial Programming  by M. Bogner     April 2007
	 Modified April 25 by M. Bogner to have cursors return data ordered by start_date_time
	*/
	 
	 /* first declare all the temporary variables needed for this procedure  */
	 BEGIN	 
	 
	  IF interval = 'hour' THEN
		OPEN C_HOUR(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_HOUR BULK COLLECT into date_array, value_array;
		CLOSE C_HOUR;
	  ELSIF interval = 'day' THEN
		OPEN C_DAY(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_DAY BULK COLLECT into date_array, value_array;
		CLOSE C_DAY;
	  ELSIF interval = 'month' THEN
		OPEN C_MONTH(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_MONTH BULK COLLECT into date_array, value_array;
		CLOSE C_MONTH;
	  ELSIF interval = 'year' THEN
		OPEN C_YEAR(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_YEAR BULK COLLECT into date_array, value_array;
		CLOSE C_YEAR;
	  ELSIF interval = 'wy' THEN
		OPEN C_WY(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_WY BULK COLLECT into date_array, value_array;
		CLOSE C_WY;
	  ELSIF interval = 'other' THEN
		OPEN C_OTHER(sdi_number,start_of_time,begin_date,end_date,seconds_per_day,timestep);
		FETCH C_OTHER BULK COLLECT into date_array, value_array;
		CLOSE C_OTHER;
	  END IF;
	end read_real_data;  /* end of the read real data procedure  */	

 	procedure read_real_data_flag(  
		interval		HDB_INTERVAL.INTERVAL_NAME%TYPE,
		sdi_number		REF_EXT_SITE_DATA_MAP.HDB_SITE_DATATYPE_ID%TYPE,
		start_of_time	DATE,
		begin_date		R_BASE.START_DATE_TIME%TYPE,
		end_date		  R_BASE.START_DATE_TIME%TYPE,
		timestep        NUMBER,
		date_array	OUT	numberTable,
		value_array	OUT	numberTable,
    flag_array	OUT	charTable) is

		CURSOR C_HOUR (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((start_date_time - sot + 1/24) * spd ), value, validation from r_hour
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_DAY (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((start_date_time - sot + 1) * spd ), value, validation from r_day
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_MONTH (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,1) - sot) * spd ), value, validation from r_month
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_YEAR (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,12) - sot) * spd ), value, validation from r_year
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 

		CURSOR C_WY (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER) IS
		select round((add_months(start_date_time,12) - sot) * spd ), value, validation from r_wy
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		order by start_date_time; 
	
		/* c_other is not so well defined.  It will be hard to determine the end of period */
		/* so this code needs to be looked at if r_other starts being used but we will use the end_date 
		   time as a start to see if this works for folks.  timestep will be expected to be in days     */
		CURSOR C_OTHER (sdi in NUMBER, sot IN DATE, start_date IN DATE, end_date IN DATE, spd IN NUMBER, timestep IN NUMBER) IS
		select round((end_date_time - sot) * spd ), value, validation from r_other
		where site_datatype_id = sdi and start_date_time >= start_date and start_date_time <= end_date
		and end_date_time - start_date_time = timestep
		order by start_date_time; 
	
	/*
	  Procedure read_real_data reads HDB data from the "real" tables based on the input parameters
	  Riverware expects the dates in seconds since it's start of time for that model. Hence, the 
	  calulations on HDB dates is : start_date_time minus the Riverware beginning of time multiplied
	  by the number of seconds per day.  Also since riverware expects the dates to be at the end of 
	  period, we must add an interval of time to the start_date_time for each period.
	  
	 Initial Programming  by M. Bogner     April 2007
	 Modified April 25 by M. Bogner to have cursors return data ordered by start_date_time
   Modified by IsmailO March 16 2017 to add Validation column with  read_db_data_flag_to_riverware and read_real_data_flag
	*/
	 
	 /* first declare all the temporary variables needed for this procedure  */
	 BEGIN	 
	 
	  IF interval = 'hour' THEN
		OPEN C_HOUR(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_HOUR BULK COLLECT into date_array, value_array, flag_array;
		CLOSE C_HOUR;
	  ELSIF interval = 'day' THEN
		OPEN C_DAY(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_DAY BULK COLLECT into date_array, value_array, flag_array;
		CLOSE C_DAY;
	  ELSIF interval = 'month' THEN
		OPEN C_MONTH(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_MONTH BULK COLLECT into date_array, value_array, flag_array;
		CLOSE C_MONTH;
	  ELSIF interval = 'year' THEN
		OPEN C_YEAR(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_YEAR BULK COLLECT into date_array, value_array, flag_array;
		CLOSE C_YEAR;
	  ELSIF interval = 'wy' THEN
		OPEN C_WY(sdi_number,start_of_time,begin_date,end_date,seconds_per_day);
		FETCH C_WY BULK COLLECT into date_array, value_array, flag_array;
		CLOSE C_WY;
	  ELSIF interval = 'other' THEN
		OPEN C_OTHER(sdi_number,start_of_time,begin_date,end_date,seconds_per_day,timestep);
		FETCH C_OTHER BULK COLLECT into date_array, value_array, flag_array;
		CLOSE C_OTHER;
	  END IF;
	end read_real_data_flag;  /* end of the read real data flag procedure  */	
 
	function set_hdb_date (date_in_seconds NUMBER, timesteps NUMBER, interval_name varchar2, date_indicator varchar2) RETURN DATE is
	/*  
		function set_hdb_date takes the Riverware date in seconds information received from 
		riverware and converts it to a proper HDB date.  Riverware reports dates at the end  
		of period while HDB is at the beginning of period so some date math is necessary.
	  
	 Initial Programming  by M. Bogner     April 2007
	*/
	
	riverware_timestep	VARCHAR2(20);
	return_date DATE;
	
	BEGIN
	 /* set up the riverware timestep and calulate the date value from the beginning of time variable  */
	 riverware_timestep := to_char(timesteps) || lower(interval_name);
	 return_date := curr_start_of_time + date_in_seconds/seconds_per_day;
	 
	 IF riverware_timestep = '1water year' AND date_indicator = 'edt' THEN
	   return_date := add_months(return_date,-3); /* subtract 3 months */
	 END IF;
	 
	 IF date_indicator = 'sdt' THEN 
		/* now test the intervals and set start date to beginning of interval  */
		IF riverware_timestep = '1hour' then return_date := return_date - 1/24 ; /* subtract 1 hour  */
		  ELSIF riverware_timestep = '6hour' then return_date := return_date - 6/24 ; /* subtract 6 hours  */
		  ELSIF riverware_timestep = '12hour' then return_date := return_date - 12/24 ; /* subtract 12 hours  */
		  ELSIF riverware_timestep = '1day' then return_date := return_date - 1; /* subtract 1 day */
		  ELSIF riverware_timestep = '1week' then return_date := return_date - 7 ; /* subtract 7 days */
		  ELSIF riverware_timestep = '1month' then return_date := add_months(return_date,-1); /* subtract 1 month */
		  ELSIF riverware_timestep = '1year' then return_date := add_months(return_date,-12); /* subtract 1 year */
		  ELSIF riverware_timestep = '1water year' then return_date := add_months(return_date,-15); /* subtract 15 months */
		END IF;
	 END IF;
	 /* now just return the return date */
	 /* note: this function purposely just returns the default date back if no matching
	    timestep and interval match                                                      */
	 return(return_date);
	  
	END set_hdb_date;  /* end of set_hdb_date function  */
	
	
	
	function set_hdb_timestep (timesteps NUMBER, interval_name varchar2) RETURN VARCHAR2 is
	/*  
		function set_hdb_timestep takes the timestep information received from 
		riverware and converts it to a number in days the interval represents.
		
		0 is returned if it doesn't match anything HDB know about
		This function was created mainlt to determine the interval time betweem the odd
		intervals that HDB doesn't have a table for like week, 6 and 12 hour intervals
		that we will attempt to put into the r_other table 
	  
	 Initial Programming  by M. Bogner     April 2007
	*/
	
	riverware_timestep	VARCHAR2(20);
	timestep NUMBER;  /* the approximate time in days that the interval represents  */       
	BEGIN
	 riverware_timestep := to_char(timesteps) || lower(interval_name);
	 timestep := 0;
	 /* now test the intervals  */
	 IF riverware_timestep = '1hour' then timestep := 1/24;
	 ELSIF riverware_timestep = '6hour' then timestep := 6/24;
	 ELSIF riverware_timestep = '12hour' then timestep := 12/24;
	 ELSIF riverware_timestep = '1day' then timestep := 1;
	 ELSIF riverware_timestep = '1week' then timestep := 7;
	 ELSIF riverware_timestep = '1month' then timestep := 30;
	 ELSIF riverware_timestep = '1year' then timestep := 365;
	 ELSIF riverware_timestep = '1water year' then timestep := 365;
	 END IF;
	 /* now just return the interval */
	 return(timestep);
	  
	END set_hdb_timestep;  /* end of set_hdb_timestep function  */
 
	function set_hdb_interval (timesteps NUMBER, interval_name varchar2) RETURN VARCHAR2 is
	/*  
		function set_hdb_interval takes the timestep information received from 
		riverware and converts it to a proper HDB interval.
		
		'NONE' is returned if it doesn't match anything HDB know about
	  
	 Initial Programming  by M. Bogner     March 2007
	*/
	
	riverware_timestep	VARCHAR2(20);
	interval			HDB_INTERVAL.INTERVAL_NAME%TYPE;       
	BEGIN
	 riverware_timestep := to_char(timesteps) || lower(interval_name);
	 interval := 'NONE';
	 /* now test the intervals  */
	 IF riverware_timestep = '1hour' then interval := 'hour';
	 ELSIF riverware_timestep = '6hour' then interval := 'other';
	 ELSIF riverware_timestep = '12hour' then interval := 'other';
	 ELSIF riverware_timestep = '1day' then interval := 'day';
	 ELSIF riverware_timestep = '1week' then interval := 'other';
	 ELSIF riverware_timestep = '1month' then interval := 'month';
	 ELSIF riverware_timestep = '1year' then interval := 'year';
	 ELSIF riverware_timestep = '1water year' then interval := 'wy';
	 END IF;
	 /* now just return the interval */
	 return(interval);
	  
	END set_hdb_interval;  /* end of set_hdb_interval function  */
	

	procedure get_site_riverware_map (
	  ext_data_source_id_in     HDB_EXT_DATA_SOURCE.EXT_DATA_SOURCE_ID%TYPE,
	  riverware_object_name	    REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	    REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  site_datatype_id_out  OUT REF_EXT_SITE_DATA_MAP.HDB_SITE_DATATYPE_ID%TYPE) is

        /* procedure get_site_riverware_map is a second chance mapping strategy
           when the site_data_map lookup fails to find any sdis
           
           The concept is that the RiverWare slot names are mapped to 
           their 'normal' hdb datatypes.
           
           The RiverWare object names are mapped first using the ext_data_source_id
           selected ext_site_code_sys_id, and if that fails to find any,
           just find any site_code that matches.
           
           The SDI is just found via a selection from hdb_site_datatype.
           
           Initial Programming: Andrew Gilmore, April 2008
           */

        begin              
          select site_datatype_id
          into site_datatype_id_out
          from hdb_ext_data_code data, hdb_ext_data_code_sys datasys, 
               hdb_ext_site_code sites, hdb_ext_data_source source,
               hdb_site_datatype sdis
          where datasys.ext_data_code_sys_name = 'RiverWare slot names'
            and data.ext_data_code_sys_id = datasys.ext_data_code_sys_id
            and data.primary_data_code = riverware_slot_name 
            and source.ext_site_code_sys_id = sites.ext_site_code_sys_id
            and source.ext_data_source_id = ext_data_source_id_in
            and sites.primary_site_code = riverware_object_name 
            and sdis.datatype_id = data.hdb_datatype_id 
            and sdis.site_id = sites.hdb_site_id;

          /* if the above query fails to find any sdis, 
             then try with no limitations to site coding system
             (do not join with data_source table to get site_code_sys_id
             
             This provides the maximal flexibility. If more than one site_id
             is found, we cannot provide a mapping.
             */
          exception when no_data_found then
          begin
            select distinct site_datatype_id
            into site_datatype_id_out
            from hdb_ext_data_code data, hdb_ext_data_code_sys datasys, 
                 hdb_ext_site_code sites, hdb_site_datatype sdis
            where datasys.ext_data_code_sys_name = 'RiverWare slot names'
              and data.ext_data_code_sys_id = datasys.ext_data_code_sys_id
              and data.primary_data_code = riverware_slot_name 
              and sites.primary_site_code = riverware_object_name 
              and sdis.datatype_id = data.hdb_datatype_id 
              and sdis.site_id = sites.hdb_site_id;

            exception
              when no_data_found then /* We have failed! */
                deny_action('No active mappings found in any mapping, with source='||ext_data_source_id_in||', site='||riverware_object_name||', data='||riverware_slot_name);
              when TOO_MANY_ROWS then /* hdb_ext_site has more than one possible site for this site_code */
                deny_action('More than one mapping found, probably more than one site in hdb_ext_site_code with site='||riverware_object_name);
          end;
	end get_site_riverware_map;


	procedure get_riverware_sdi(  
	  ext_data_source_id    HDB_EXT_DATA_SOURCE.EXT_DATA_SOURCE_ID%TYPE,
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  site_datatype_id  OUT REF_EXT_SITE_DATA_MAP.HDB_SITE_DATATYPE_ID%TYPE) is

	/*  
		procedure get_riverware_sdi only looks up the the SDI for a object 
		and slot name  and returns the sdi
	  
	 Initial Programming  by M. Bogner     March 2007
	 Modified by Andrew Gilmore, April 2008	to provide more flexible mapping
	*/
	
	/* first declare the temporary variables needed for proc calls  and etc... */
	method_id   HDB_METHOD.METHOD_ID%TYPE;
	computation_id HDB_COMPUTED_DATATYPE.COMPUTATION_ID%TYPE;
	interval    R_BASE.INTERVAL%TYPE;
	agency_id   HDB_AGEN.AGEN_ID%TYPE;
	  
	BEGIN
		/* go get the sdi for this mapping                */
		get_site_data_map(ext_data_source_id,riverware_object_name,riverware_slot_name,0,
			site_datatype_id,interval,method_id,computation_id,agency_id,null,null);
	EXCEPTION 
	when others THEN /* Specific site/data code to site_datatype_id mapping failed */
		if SQLCODE = -20001 and
		SQLERRM LIKE '%No active mappings%' then /* failed because no mapping */
			/* try separate site, riverware slot name mapping */
			get_site_riverware_map(ext_data_source_id,riverware_object_name,
				riverware_slot_name, site_datatype_id);
		else
			raise; /* do not handle exception, just raise it again */
		end if;
	end get_riverware_sdi;
	
	procedure validate_ensemble(  
		p_ensemble_id	NUMBER,
		p_proc_abbr   VARCHAR2  ) is
		
	/*
	  Procedure validate_ensemble checks that the parameter p_ensemble_id is a legitimate value defined 
	  in the database.  Any failure of the checks is an exception error with an 
	  appropriate message
	 
	 Initial Programming  by M. Bogner     January 2014
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 l_key  NUMBER;
	 BEGIN	 
	    select ensemble_id into l_key from REF_ENSEMBLE where ensemble_id = P_ENSEMBLE_ID;
		EXCEPTION when OTHERS  THEN DENY_ACTION('Invalid ENSEMBLE_ID: '||
		  nvl(to_char(p_ensemble_id),'<<NULL>>')||' PROC: '|| p_proc_abbr);
	end validate_ensemble;	
	
	
	procedure validate_ensemble_trace(  
		p_ensemble_id	NUMBER,
		p_trace_id	NUMBER,
		p_proc_abbr   VARCHAR2  ) is
		
	/*
	  Procedure validate_ensemble checks that the parameter p_trace_id is a legitimate value defined 
	  in the database.  Any failure of the checks is an exception error with an 
	  appropriate message
	 
	 Initial Programming  by M. Bogner     January 2014
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 l_key  NUMBER;
	 BEGIN	 
	    select trace_id into l_key from REF_ENSEMBLE_TRACE  
	    where ensemble_id = P_ENSEMBLE_ID and trace_id = P_TRACE_ID;
		EXCEPTION when OTHERS  THEN DENY_ACTION('Invalid TRACE_ID: '||
		  nvl(to_char(p_trace_id),'<<NULL>>')||' PROC: '|| p_proc_abbr);
	end validate_ensemble_trace;	
	
	procedure validate_data_source(  
		source_id	HDB_EXT_DATA_SOURCE.EXT_DATA_SOURCE_ID%TYPE,
		proc_abbr   varchar2  ) is
		
	/*
	  Procedure validate_data_source checks that the mapping
	  id is a legitimate value defined in the database.  Any failure of the checks is an 
	  exception error  with an appropriate message
	 
	 Initial Programming  by M. Bogner     March 2007
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 temp_num  NUMBER;
	 BEGIN
	 
		begin
		/*  now check the data source number  */
		    select ext_data_source_id into temp_num 
		    from hdb_ext_data_source where ext_data_source_id = source_id;
		    
			EXCEPTION
			when OTHERS  THEN DENY_ACTION('Invalid Data Source Identifier: '||
			nvl(to_char(source_id),'<<NULL>>')||'  PROC: '|| proc_abbr);
		end; /* check source_id code */
		
	end validate_data_source;	
	
	procedure validate_agency(  
		agency_id	HDB_AGEN.AGEN_ID%TYPE,
		proc_abbr   varchar2  ) is
		
	/*
	  Procedure validate_agency checks that the agency_id is a legitimate value defined 
	  in the database.  Any failure of the checks is an exception error with an 
	  appropriate message
	 
	 Initial Programming  by M. Bogner     March 2007
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 temp_num  NUMBER;
	 BEGIN	 
		/*  now check the agency number  */
		    select agen_id into temp_num from hdb_agen where agen_id = agency_id;
		    
			EXCEPTION
			when OTHERS  THEN DENY_ACTION('Invalid Agency Identifier: '||
			nvl(to_char(agency_id),'<<NULL>>')||' PROC: '|| proc_abbr);
	end validate_agency;	
	
	
	procedure validate_collection_system(  
		collection_id	HDB_COLLECTION_SYSTEM.COLLECTION_SYSTEM_ID%TYPE,
		proc_abbr   varchar2  ) is
		
	/*
	  Procedure validate_collection_system checks that the collection_id is a legitimate value defined 
	  in the database.  Any failure of the checks is an exception error with an 
	  appropriate message
	 
	 Initial Programming  by M. Bogner     March 2007
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 temp_num  NUMBER;
	 BEGIN	 
		/*  now check the collection system id  */
		  select collection_system_id into temp_num 
		  from hdb_collection_system where collection_system_id = collection_id;
		
		EXCEPTION
		when OTHERS  THEN DENY_ACTION('Invalid Collection System Identifier: '||
		nvl(to_char(collection_id),'<<NULL>>')||' PROC: '|| proc_abbr);
     end validate_collection_system;	
	
	procedure validate_model_run(  
		run_id		REF_MODEL_RUN.MODEL_RUN_ID%TYPE,
		proc_abbr   varchar2  ) is
		
	/*
	  Procedure validate_model_run checks that the run_id is a legitimate 
	  model_run_id value from the REF_MODEL_RUN table 
	  in the database.  Any failure of the checks is an exception error with an 
	  appropriate message
	 
	 Initial Programming  by M. Bogner     March 2007
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 temp_num  NUMBER;
	 BEGIN	 
		/*  now check the model_run_id  */
		    select model_run_id into temp_num 
		    from ref_model_run where model_run_id = run_id;
		    
			EXCEPTION
			when OTHERS  THEN DENY_ACTION('Invalid Model Run Number: '||
			nvl(to_char(run_id),'<<NULL>>')||' PROC: '|| proc_abbr);
	end validate_model_run;	

	procedure model_run_id_actions (
		run_id		REF_MODEL_RUN.MODEL_RUN_ID%TYPE,
		proc_abbr   varchar2  ) is
	
	begin			
-- Commented out writing values to temp_test  Daren Critelli March 2015
--			/* now delete all the previous model_run_id data from the model tables  */
--			insert into temp_test values ('Action call for DELETING MRI: ' || to_char(run_id) || '  ' 
--			|| to_char(sysdate,'dd-mon-yyyy HH24:mi:ss'));
--			commit;
			begin
				delete from m_hour where model_run_id = run_id;
				delete from m_day where model_run_id = run_id;
				delete from m_month where model_run_id = run_id;
				delete from m_year where model_run_id = run_id;
				delete from m_wy where model_run_id = run_id;
				commit;
							    
				EXCEPTION
				when OTHERS  THEN 
				DENY_ACTION('Issue Deleting Existing Model data. Model Run Identifier: '||
				to_char(run_id)|| ' ' || proc_abbr);
			end ;  /*  end of remove data from the model_tables  */
	
	   /* now I think I should touch the model_run_id table to indicate new data coming in */
	   touch_model_run_id(run_id);
			
	end model_run_id_actions;
	
	procedure init_riverware_dmi(  
	  parameter_names  IN stringTable,
	  parameter_values IN stringTable) is
		
	/*
	  Procedure init_riverware_DMI checks that the input parameters and values are 
	  legitimate values defined in the database.  Any failure of the checks is an 
	  exception error  with an appropriate message.  If all checks are OK then all
	  the model data with that model_run_id are deleted from the model tables
	 
	 Initial Programming  by M. Bogner     March 2007
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 items   NUMBER;
     parameter varchar2(32);
     
	 BEGIN
	    /* first null out the start date time of the model  */
	    curr_start_of_time := NULL;
	    /*  now parse the array of parameters  */
		items := parameter_names.count();
		For i IN 1..items LOOP	    
	     parameter := parameter_names(i);

			IF parameter = 'begin_year' then 
	       	  /* if the begin year parameter set the package curr_start_of_time variable  */
			  curr_start_of_time := to_date('01-JAN-'||parameter_values(i),'dd-MON-yyyy');  
			ELSIF parameter = 'model_run_id' THEN
				 curr_model_run_id := to_number(parameter_values(i));
    			/*  now check the run_id number  */
				validate_model_run(curr_model_run_id,'RC.IRDMI');	 
				model_run_id_actions(curr_model_run_id,'RC.IRDMI');	 
		    END IF;
		
		END  LOOP;
	end init_riverware_dmi;

	procedure init_riverware_dataset(  
	  parameter_names  IN stringTable,
	  parameter_values IN stringTable) is

	/*  
		procedure init_riverware_dataset is used to set up any and all values needed for
		the riverware connection program. 
		
	 Initial Programming  by M. Bogner     March 2007
	 Mod by M. Bogner April 2007 to be called by both read, write and delete procedures
	*/

	 items   NUMBER;
     parameter varchar2(32);
     BEGIN
		/* first null out all potential package values that this procedure can pass */
     	CURR_DATA_SOURCE_ID := NULL;
		CURR_AGENCY_ID		:= NULL;
		CURR_COLLECTION_ID	:= NULL;
		CURR_OVERWRITE_FLAG := NULL;
		CURR_MODEL_RUN_ID	:= NULL;
		CURR_DATA_TABLES    := NULL;
		CURR_DATA_TYPE		:= NULL;

		items := parameter_names.count();
		For i IN 1..items LOOP	    
	     parameter := parameter_names(i);

			IF parameter = 'agency_id' then 
	       		curr_agency_id := to_number(parameter_values(i));
				validate_agency(curr_agency_id,'RC.IRDS');
			ELSIF parameter = 'ext_data_source' THEN
			/*  now check the data source number  */
				 curr_data_source_id := to_number(parameter_values(i));
				 validate_data_source(curr_data_source_id,'RC.IRDS');	 
			ELSIF parameter = 'collection_system_id' THEN
				 curr_collection_id := to_number(parameter_values(i));
    			/*  now check the collection_system_id number  */
				validate_collection_system(curr_collection_id,'RC.IRDS');	 
			ELSIF parameter = 'overwrite' AND UPPER(parameter_values(i)) = 'Y' THEN
				 curr_overwrite_flag := 'O';
			ELSIF parameter = 'tables' THEN
				 curr_data_tables := parameter_values(i);
			ELSIF parameter = 'type' THEN
				 curr_data_type := parameter_values(i);
			ELSIF parameter = 'model_run_id' THEN
				 curr_model_run_id := to_number(parameter_values(i));
    			/*  now check the model_run_id number  */
				validate_model_run(curr_model_run_id,'RC.IRDS');
			ELSIF parameter = 'begin_year' then 
	       	  /* if the begin year parameter set the package curr_start_of_time variable  */
			  curr_start_of_time := to_date('01-JAN-'||parameter_values(i),'dd-MON-yyyy');  					 
		    END IF;
		
		END  LOOP;
	end init_riverware_dataset;

	procedure get_info_for_riverware_slot(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  parameter_names    stringTable,
	  parameter_values   stringTable,
	  output_parameter_names  OUT stringTable,
	  output_parameter_values OUT stringTable) is

	/*  
		procedure get_info_for_riverware_slot is used to look up any and all values needed for
		the riverware connection program.  Presently only looks up the unit and the SDI for a object 
		and slot name  and returns the unit and the common_name for it
	  
	 Initial Programming  by M. Bogner     March 2007
     Modified April 09 2007  to remove status and return message
	*/
	
	/* first declare the temporary variables needed for proc calls  and etc... */
	sdi_number  HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	unit_name   HDB_UNIT.UNIT_COMMON_NAME%TYPE;
	BEGIN	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.GIFRS');
		
		/* next go get the sdi for this mapping                */
		begin
		   get_riverware_sdi(curr_data_source_id,riverware_object_name,riverware_slot_name,sdi_number);
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		
		/* now go get the unit common_name for that sdi   */
		begin
			select c.unit_common_name  into unit_name
			from hdb_site_datatype a, hdb_datatype b,  hdb_unit c
			where a.site_datatype_id = sdi_number
			  and a.datatype_id = b.datatype_id
			  and b.unit_id = c.unit_id;

		EXCEPTION
		when others then
			DENY_ACTION('WARNING... Unit Name retrieve failed. SOURCE ID: ' || 
			to_char(curr_data_source_id) || ' Object: ' || riverware_object_name ||
			' Slot: ' || riverware_slot_name);
		end;
		
		/* otherwise everything went smoothly so return after setting the unit and unit name value  */
		output_parameter_names(1) := 'unit';
		output_parameter_values(1) :=  unit_name;
		
	end get_info_for_riverware_slot;

/*	procedure write_riverware_data_to_db writes data to database from Riverware    */  
	procedure write_riverware_data_to_db(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  date_array            numberTable,
	  value_array           numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable) IS
	/*  
		procedure write_riverware_data_to_db writes the data passed from Riverware to 
		the HDB database.  Previously written procedures are called to do the actual
		database writing.
		
	 Initial Programming  by M. Bogner     March 2007
     Modified April 09 2007  to remove status and return message
	*/	

    /* declare internal variables */
 	sdi_number	HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	interval	R_BASE.INTERVAL%TYPE;
    items       NUMBER;
    sdt			R_BASE.START_DATE_TIME%TYPE;
    edt			R_BASE.START_DATE_TIME%TYPE;
    
	BEGIN /* initial begin for this procedure  */
	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.WRDTDB');
		
		/* next go get the sdi for this mapping                */
		begin
		  get_riverware_sdi(curr_data_source_id,riverware_object_name,riverware_slot_name,sdi_number);
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		/* determine the HDB interval pass exception if interval passed back = 'NONE' */
        interval := set_hdb_interval(interval_number,interval_name); 
        IF interval = 'NONE' then 
			DENY_ACTION('Unsupported combination for Timesteps: ' || to_char(interval_number)
            || '  ' || interval_name);
		END IF;
		
		/* make sure that the start_date _time variable dat has been set  */
		if curr_start_of_time is null then
			DENY_ACTION('Start of Riverware Time Date is <<NULL>>');
		end if;
		
		/* validate the setable input variables to HDB stored procedures  */
		IF curr_data_tables = 'real' then
		  validate_agency(curr_agency_id,'RC.WRDTB');
		  validate_collection_system(curr_collection_id,'RC.WRDTB');
		ELSIF curr_data_tables = 'model' and interval = 'other' then
			DENY_ACTION('Illegal interval of "OTHER" for WRITING to Model tables');
		ELSIF curr_data_tables = 'model' then
		  validate_model_run(curr_model_run_id,'RC.WRDTB');
		ELSE DENY_ACTION('Illegal value for "tables" parameter of : ' || nvl(curr_data_tables,'<<NULL>>'));
		END IF;

		begin  /* begin block for HDB stored Procedures exceptions */
			items := date_array.count();
			For i IN 1..items LOOP	    
				sdt := set_hdb_date(date_array(i),interval_number,interval_name,'sdt');	
				edt := set_hdb_date(date_array(i),interval_number,interval_name,'edt');	
				IF curr_data_tables = 'real' THEN
					modify_r_base_raw (sdi_number,interval,sdt,edt,value_array(i),curr_agency_id,
					curr_overwrite_flag,def_validation,curr_collection_id,def_loading_application_id,
					def_method_id,def_computation_id,'Y');
				ELSE
					modify_m_table_raw(curr_model_run_id,sdi_number,sdt,edt,value_array(i),interval,'Y');
			    END IF;

			END LOOP;
		EXCEPTION
		when others then
		    rollback;
			raise_application_error(-20003, SQLERRM);
		end;  /* end block for HDB stored procedure exception  */	
		/* the process went smoothly if we got here so do a commit   */
        COMMIT;
        
	END WRITE_RIVERWARE_DATA_TO_DB;  /* end of write_riverware_data_to_db  procedure  */


/*	procedure write_rw_group_data_to_db writes group data to database from Riverware    */  
	procedure write_rw_group_data_to_db(  
      number_of_grouped_slots NUMBER,
      riverware_object_names	stringTableCLOB,
	  riverware_slot_names	stringTableCLOB,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
      slot_date_value_counts numberTable,
	  date_array            numberTable,
	  value_array           numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable ) IS
	/*  
		procedure write_rw_group_data_to_db writes the group data passed from Riverware to 
		the HDB database. 		
  	    Initial Programming  by Ismail O.     December 2017
  	*/	

    /* declare internal variables */
 	sdi_number	HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	interval	R_BASE.INTERVAL%TYPE;
    items       NUMBER;
    sdt			R_BASE.START_DATE_TIME%TYPE;
    edt			R_BASE.START_DATE_TIME%TYPE;
    
   --new variables
   n_counter_first NUMBER :=1;
   n_counter_last NUMBER :=0;
    
	BEGIN /* initial begin for this procedure  */
	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.WRDTDB');
		
		/* determine the HDB interval pass exception if interval passed back = 'NONE' */
        interval := set_hdb_interval(interval_number,interval_name); 
        IF interval = 'NONE' then 
			DENY_ACTION('Unsupported combination for Timesteps: ' || to_char(interval_number)
            || '  ' || interval_name);
		END IF;
		
		/* make sure that the start_date _time variable dat has been set  */
		if curr_start_of_time is null then
			DENY_ACTION('Start of Riverware Time Date is <<NULL>>');
		end if;
		
		/* validate the setable input variables to HDB stored procedures  */
		IF curr_data_tables = 'real' then
		  validate_agency(curr_agency_id,'RC.WRDTB');
		  validate_collection_system(curr_collection_id,'RC.WRDTB');
		ELSIF curr_data_tables = 'model' and interval = 'other' then
			DENY_ACTION('Illegal interval of "OTHER" for WRITING to Model tables');
		ELSIF curr_data_tables = 'model' then
		  validate_model_run(curr_model_run_id,'RC.WRDTB');
		ELSE DENY_ACTION('Illegal value for "tables" parameter of : ' || nvl(curr_data_tables,'<<NULL>>'));
		END IF;

		begin  /* begin block for HDB stored Procedures exceptions */           
 
           FOR l_row1 IN 1 .. slot_date_value_counts.count
           LOOP
           n_counter_last := n_counter_last + slot_date_value_counts(l_row1);
                
                FOR l_row2 IN n_counter_first .. n_counter_last
                LOOP
                
                get_riverware_sdi(curr_data_source_id,riverware_object_names(l_row1),riverware_slot_names(l_row1),sdi_number);
                    
				sdt := set_hdb_date(date_array(l_row2),interval_number,interval_name,'sdt');	
				edt := set_hdb_date(date_array(l_row2),interval_number,interval_name,'edt');	
                
				IF curr_data_tables = 'real' THEN
					modify_r_base_raw (sdi_number,interval,sdt,edt,value_array(l_row2),curr_agency_id,
					curr_overwrite_flag,def_validation,curr_collection_id,def_loading_application_id,
					def_method_id,def_computation_id,'Y');
				ELSE
					modify_m_table_raw(curr_model_run_id,sdi_number,sdt,edt,value_array(l_row2),interval,'Y');
			    END IF;                
                
                --DBMS_OUTPUT.put_line ( date_array(l_row2) || '-' || value_array(l_row2) || '-' || riverware_object_names(l_row1) || ' - ' ||  riverware_slot_names(l_row1) );
               
                n_counter_first := n_counter_last+1;
                END LOOP; 
         END LOOP;      

		EXCEPTION
		when others then
		    rollback;
			raise_application_error(-20003, SQLERRM);
		end;  /* end block for HDB stored procedure exception  */	
		/* the process went smoothly if we got here so do a commit   */
        COMMIT;
        
	END WRITE_RW_GROUP_DATA_TO_DB;  /* end of write_rw_group_data_to_db  procedure  */




/*	procedure delete_riverware_data_from_db deletes data in database from Riverware    */  
	procedure delete_riverware_data_from_db(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  date_array            numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable) IS
	/*  
		procedure delete_riverware_data_from_db deletes the data passed from Riverware from 
		the HDB database r_base table.  Previously written procedures are called to do the actual
		database deleting from r_base.
		
	 Initial Programming  by M. Bogner     April 2007
     Modified April 09 2007  to remove status and return message
	*/	

    /* declare internal variables */
 	sdi_number	HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	interval	R_BASE.INTERVAL%TYPE;
    items       NUMBER;
    sdt			R_BASE.START_DATE_TIME%TYPE;
    edt			R_BASE.START_DATE_TIME%TYPE;
    
	BEGIN /* initial begin for this procedure  */
	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.DRDFDB');
		
		/* next go get the sdi for this mapping                */
		begin
		  get_riverware_sdi(curr_data_source_id,riverware_object_name,riverware_slot_name,sdi_number);
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		/* determine the HDB interval pass exception if interval passed back = 'NONE' */
        interval := set_hdb_interval(interval_number,interval_name); 
        IF interval = 'NONE' then 
			DENY_ACTION('Illegal combination for Timesteps: ' || to_char(interval_number)
            || '  ' || interval_name);
		END IF;
		
		/* make sure that the start_date _time variable dat has been set  */
		if curr_start_of_time is null then
			DENY_ACTION('Start of Riverware Time Date is <<NULL>>');
		end if;
		
		/* validate the setable input variables to HDB stored procedures  */
		IF curr_data_tables = 'real' then
		  validate_agency(curr_agency_id,'RC.DRDFB');
		  validate_collection_system(curr_collection_id,'RC.DRDFB');
		ELSE DENY_ACTION('Illegal value for "tables" parameter of : ' || nvl(curr_data_tables,'<<NULL>>'));
		END IF;

		begin  /* begin block for HDB stored Procedures exceptions */
			items := date_array.count();
			For i IN 1..items LOOP	    
			  begin  /* begin block for HDB stored Procedures exceptions  in loop*/
				/* start date time is the adjusted date,  end date time will be the date given by riverware */
				sdt := set_hdb_date(date_array(i),interval_number,interval_name,'sdt');	
				edt := set_hdb_date(date_array(i),interval_number,interval_name,'edt');
				delete_r_base(sdi_number,interval,sdt,edt,curr_agency_id,def_loading_application_id);	

			  EXCEPTION when others then null;
			  end;  /* end block for HDB stored procedure exception within loop */
		
			END LOOP;

		EXCEPTION
		when others then
		    rollback;
			raise_application_error(-20003, SQLERRM);
		end;  /* end block for HDB stored procedure exception  */

		/* Everything went fine if we got to here so do a commit  */
        COMMIT;
        
	END DELETE_RIVERWARE_DATA_FROM_DB;  /* end of delete_riverware_data_from_db  procedure  */


/*	procedure delete_rw_group_data_from_db deletes group data in database from Riverware    */  
	procedure delete_rw_group_data_from_db(  
      number_of_grouped_slots NUMBER,
      riverware_object_names	stringTableCLOB,
	  riverware_slot_names	stringTableCLOB,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
      slot_date_value_counts numberTable,
	  date_array            numberTable,
	  parameter_names       stringTable,
	  parameter_values      stringTable ) IS
	/*  
		procedure delete_rw_group_data_from_db deletes the group data passed from Riverware to 
		the HDB database. 		
  	    Initial Programming  by Ismail O.     March 2018
  	*/	

    /* declare internal variables */
 	sdi_number	HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	interval	R_BASE.INTERVAL%TYPE;
    items       NUMBER;
    sdt			R_BASE.START_DATE_TIME%TYPE;
    edt			R_BASE.START_DATE_TIME%TYPE;
    
      --new variables
   n_counter_first NUMBER :=1;
   n_counter_last NUMBER :=0; 
    
    
	BEGIN /* initial begin for this procedure  */
	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.DRDFDB');
		
		/* determine the HDB interval pass exception if interval passed back = 'NONE' */
        interval := set_hdb_interval(interval_number,interval_name); 
        IF interval = 'NONE' then 
			DENY_ACTION('Illegal combination for Timesteps: ' || to_char(interval_number)
            || '  ' || interval_name);
		END IF;
		
		/* make sure that the start_date _time variable dat has been set  */
		if curr_start_of_time is null then
			DENY_ACTION('Start of Riverware Time Date is <<NULL>>');
		end if;
		
		/* validate the setable input variables to HDB stored procedures  */
		IF curr_data_tables = 'real' then
		  validate_agency(curr_agency_id,'RC.DRDFB');
		  validate_collection_system(curr_collection_id,'RC.DRDFB');
		ELSIF curr_data_tables = 'model' and interval = 'other' then
			DENY_ACTION('Illegal interval of "OTHER" for WRITING to Model tables');
		ELSIF curr_data_tables = 'model' then
		  validate_model_run(curr_model_run_id,'RC.DRDFB');
		ELSE DENY_ACTION('Illegal value for "tables" parameter of : ' || nvl(curr_data_tables,'<<NULL>>'));
		END IF;


		begin  /* begin block for HDB stored Procedures exceptions */
        
           FOR l_row1 IN 1 .. slot_date_value_counts.count
           LOOP
           n_counter_last := n_counter_last + slot_date_value_counts(l_row1);
                
                FOR l_row2 IN n_counter_first .. n_counter_last
                LOOP
                
                /* next go get the sdi for this mapping                */
		        get_riverware_sdi(curr_data_source_id,riverware_object_names(l_row1),riverware_slot_names(l_row1),sdi_number);
                
				sdt := set_hdb_date(date_array(l_row2),interval_number,interval_name,'sdt');	
				edt := set_hdb_date(date_array(l_row2),interval_number,interval_name,'edt');	
             
  				IF curr_data_tables = 'real' THEN
					delete_r_base(sdi_number,interval,sdt,edt,curr_agency_id,def_loading_application_id);	
				ELSE
					delete_m_table(curr_model_run_id,sdi_number,sdt,edt,interval);	
			    END IF;    
                

                --DBMS_OUTPUT.put_line ( date_array(l_row2) || '-' || value_array(l_row2) || '-' || riverware_object_names(l_row1) || ' - ' ||  riverware_slot_names(l_row1) );               
                n_counter_first := n_counter_last+1;
                END LOOP; 
		
			END LOOP;

		EXCEPTION
		when others then
		    rollback;
			raise_application_error(-20003, SQLERRM);
		end;  /* end block for HDB stored procedure exception  */

		/* Everything went fine if we got to here so do a commit  */
        COMMIT;
        
	END DELETE_RW_GROUP_DATA_FROM_DB;  /* end of delete_rw_group_data_from_db  procedure  */


/*	procedure read_db_data_flag_to_riverware reads data including data flags from database to pass to Riverware    */  
	procedure read_db_data_flag_to_riverware(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  start_time			NUMBER,
	  end_time				NUMBER,
	  parameter_names       stringTable,
	  parameter_values      stringTable,
	  date_array        OUT numberTable,
	  value_array       OUT numberTable,
    flag_array	OUT	charTable) IS
	/*  
		procedure read_db_data_flag_to_riverware reads the data along with data flags from the HDB database and then
		passes this data to Riverware
		
	 Initial Programming  by M. Bogner     April 2007
   Modified by IsmailO March 16 2017 to add Validation column with  read_db_data_flag_to_riverware and read_real_data_flag
	*/	

    /* declare internal variables */
 	sdi_number	HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	interval	R_BASE.INTERVAL%TYPE;
    items       NUMBER;
    sdt			R_BASE.START_DATE_TIME%TYPE;
    edt			R_BASE.START_DATE_TIME%TYPE;
    interval_in_days NUMBER;  /* used for querying r_other table with existing multiple intervals */
    
	BEGIN /* initial begin for this procedure  */
	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.WRDTDB');
		
		/* next go get the sdi for this mapping                */
		begin
		  get_riverware_sdi(curr_data_source_id,riverware_object_name,riverware_slot_name,sdi_number);
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		/* determine the HDB interval pass exception if interval passed back = 'NONE' */
        interval := set_hdb_interval(interval_number,interval_name); 
        IF interval = 'NONE' then 
			DENY_ACTION('Illegal combination for Timesteps: ' || to_char(interval_number)
            || '  ' || interval_name);
		END IF;

		/* determine the HDB interval timestep */
        interval_in_days := set_hdb_timestep(interval_number,interval_name); 
		
		/* make sure that the start_date _time variable date has been set  */
		if curr_start_of_time is null then
			DENY_ACTION('Start of Riverware Time Date is <<NULL>>');
		end if;
		
		/* go set the dates for the querying of HDB tables  */
		/* adjust both dates for beginning of interval      */
		sdt := set_hdb_date(start_time,interval_number,interval_name,'sdt');	
		edt := set_hdb_date(end_time,interval_number,interval_name,'sdt');
			
		/* validate the setable input variables to HDB stored procedures and/or go get the data */
		IF curr_data_tables = 'real' then
			read_real_data_flag(interval,sdi_number,curr_start_of_time,sdt,edt,interval_in_days,date_array,value_array,flag_array);
		ELSIF curr_data_tables = 'model' and interval = 'other' then
			DENY_ACTION('Illegal interval of "OTHER" for READING of Model tables');
		ELSIF curr_data_tables = 'model' then
			validate_model_run(curr_model_run_id,'RC.RDDTR');
			read_model_data(interval,sdi_number,curr_model_run_id,curr_start_of_time,sdt,edt,date_array,value_array); 
		ELSE DENY_ACTION('Illegal value for "tables" parameter of : ' || nvl(curr_data_tables,'<<NULL>>'));
		END IF;

        
	END READ_DB_DATA_FLAG_TO_RIVERWARE;  /* end of read_db_data_flag_to_riverware  procedure  */


/*	procedure read_db_data_to_riverware reads data from database to pass to Riverware    */  
	procedure read_db_data_to_riverware(  
	  riverware_object_name	REF_EXT_SITE_DATA_MAP.PRIMARY_SITE_CODE%TYPE,
	  riverware_slot_name	REF_EXT_SITE_DATA_MAP.PRIMARY_DATA_CODE%TYPE,
	  interval_number       NUMBER,
	  interval_name         VARCHAR2,
	  start_time			NUMBER,
	  end_time				NUMBER,
	  parameter_names       stringTable,
	  parameter_values      stringTable,
	  date_array        OUT numberTable,
	  value_array       OUT numberTable) IS
	/*  
		procedure read_db_data_to_riverware reads the data from the HDB database and then
		passes this data to Riverware
		
	 Initial Programming  by M. Bogner     April 2007
     Modified April 09 2007  to remove status and return message
	*/	

    /* declare internal variables */
 	sdi_number	HDB_SITE_DATATYPE.SITE_DATATYPE_ID%TYPE;
	interval	R_BASE.INTERVAL%TYPE;
    items       NUMBER;
    sdt			R_BASE.START_DATE_TIME%TYPE;
    edt			R_BASE.START_DATE_TIME%TYPE;
    interval_in_days NUMBER;  /* used for querying r_other table with existing multiple intervals */
    
	BEGIN /* initial begin for this procedure  */
	
	    /* set all the parameters for this call   */
	    init_riverware_dataset(parameter_names,parameter_values);
	    
		/* validate the external data source identifier  */
		validate_data_source(curr_data_source_id,'RC.WRDTDB');
		
		/* next go get the sdi for this mapping                */
		begin
		  get_riverware_sdi(curr_data_source_id,riverware_object_name,riverware_slot_name,sdi_number);
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		/* determine the HDB interval pass exception if interval passed back = 'NONE' */
        interval := set_hdb_interval(interval_number,interval_name); 
        IF interval = 'NONE' then 
			DENY_ACTION('Illegal combination for Timesteps: ' || to_char(interval_number)
            || '  ' || interval_name);
		END IF;

		/* determine the HDB interval timestep */
        interval_in_days := set_hdb_timestep(interval_number,interval_name); 
		
		/* make sure that the start_date _time variable date has been set  */
		if curr_start_of_time is null then
			DENY_ACTION('Start of Riverware Time Date is <<NULL>>');
		end if;
		
		/* go set the dates for the querying of HDB tables  */
		/* adjust both dates for beginning of interval      */
		sdt := set_hdb_date(start_time,interval_number,interval_name,'sdt');	
		edt := set_hdb_date(end_time,interval_number,interval_name,'sdt');
			
		/* validate the setable input variables to HDB stored procedures and/or go get the data */
		IF curr_data_tables = 'real' then
			read_real_data(interval,sdi_number,curr_start_of_time,sdt,edt,interval_in_days,date_array,value_array);
		ELSIF curr_data_tables = 'model' and interval = 'other' then
			DENY_ACTION('Illegal interval of "OTHER" for READING of Model tables');
		ELSIF curr_data_tables = 'model' then
			validate_model_run(curr_model_run_id,'RC.RDDTR');
			read_model_data(interval,sdi_number,curr_model_run_id,curr_start_of_time,sdt,edt,date_array,value_array); 
		ELSE DENY_ACTION('Illegal value for "tables" parameter of : ' || nvl(curr_data_tables,'<<NULL>>'));
		END IF;

        
	END READ_DB_DATA_TO_RIVERWARE;  /* end of read_db_data_and_flags_to_riverware  procedure  */

	
	procedure init_ensemble( p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE) is
		
	/*
	  Procedure init_ensemble clears any information that is currently identified
	  by the input ensemble
	 
	 Initial Programming  by M. Bogner     January 2014
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 l_temp_num  NUMBER;
	 l_proc_abbr VARCHAR2(32) := 'INIT_ENSEMBLE';
	 l_ensemble_name VARCHAR2(256);
	 
	 cursor c1 is select model_run_id from REF_ENSEMBLE_TRACE where ensemble_id = P_ENSEMBLE_ID;
	 
	 BEGIN	 
	    /* get the ensemble_name from the ensemble table  for use later  */
	        select ensemble_name into l_ensemble_name from REF_ENSEMBLE 
	        where ensemble_id = P_ENSEMBLE_ID;
	        
		/* 1. Clear out all non key columns of table REF_ENSEMBLE  */
		    update REF_ENSEMBLE set agen_id = null, trace_domain = null, cmmnt = null
		      where ensemble_id = P_ENSEMBLE_ID;

		/* 2. Clear out all non key columns of table REF_ENSEMBLE_TRACE for all
		      Traces that are child records of this ensemble                    */
		    update REF_ENSEMBLE_TRACE set trace_numeric = null, trace_name = null
		      where ensemble_id = P_ENSEMBLE_ID;
		
		/* 3. delete all keys for this ensemble from table REF_ENSEMBLE_KEYVAL */
		    delete REF_ENSEMBLE_KEYVAL where ensemble_id = P_ENSEMBLE_ID;
		
		/* 4. delete all REF_MODEL_RUN_KEYVAL records for all traces related to this ensemble  */
		    delete REF_MODEL_RUN_KEYVAL where model_run_id in (
		    select model_run_id from REF_ENSEMBLE_TRACE where ensemble_id = P_ENSEMBLE_ID);
		    
		/* 5. set model_run_name in REF_MODEL_RUN records to a generic name   */
		    update REF_MODEL_RUN RMR set RMR.model_run_name =
            (select distinct substr(l_ensemble_name,1,60) || substr(to_char(10000+RET.trace_id),2,4)
             from REF_ENSEMBLE_TRACE RET where RET.ensemble_id = P_ENSEMBLE_ID
              and RET.model_run_id = RMR.model_run_id )
            where RMR.model_run_id in (select model_run_id from REF_ENSEMBLE_TRACE 
                                       where ensemble_id = P_ENSEMBLE_ID);
		    
		/* 6. delete all model_run data from the database for all model_run_id's associated
		      with this ensemble                                                             */
		    
		    FOR trace_rec in c1
		    LOOP  
		      model_run_id_actions (trace_rec.model_run_id, l_proc_abbr);
		    END LOOP;
		      
			EXCEPTION
			when OTHERS  THEN DENY_ACTION('Invalid ENSEMBLE ID: '||
			nvl(to_char(P_ENSEMBLE_ID),'<<NULL>>')||' PROC: '|| l_proc_abbr);
	
	end init_ensemble;	
	

  FUNCTION GET_ENSEMBLE_TRACE_MRI(P_ENSEMBLE_ID REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
                                  P_TRACE_ID REF_ENSEMBLE_TRACE.TRACE_ID%TYPE )
    RETURN number is
    l_model_run_id REF_MODEL_RUN.MODEL_RUN_ID%TYPE;

    BEGIN
    /*  This function was written to assist in finding the unique surrogate MODEL_RUN_ID
        Number for a given ENSEMBLE, TRACE in HDB.  The record is found in table REF_ENSEMBLE_TRACE 
        Joined with TABLE REF_MODEL_RUN.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2014
    */
      begin
        select ret.model_run_id into l_model_run_id
          from ref_ensemble_trace ret, ref_model_run rmr
          where 
              ret.ensemble_id = P_ENSEMBLE_ID
          and ret.trace_id = P_TRACE_ID
          and ret.model_run_id = rmr.model_run_id;

        exception when others then        
	       l_model_run_id := -999;
      end;
      
    RETURN (l_model_run_id);
  
  END;  /* End of Function GET_ENSEMBLE_TRACE_MRI  */ 
  

	procedure read_ensemble_metadata(  
	  p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
	  output_parameter_names  OUT stringTable,
	  output_parameter_values OUT stringTableLrg) is

	/*  
		procedure read_ensemble_metadata is used to look up any and all ENSEMBLE Metatdata values needed for
		the riverware connection program.  
	  
	 Initial Programming  by M. Bogner    January 2014
	*/
	
	/* first declare the temporary variables needed for proc calls  and etc... */
	l_ensemble_name REF_ENSEMBLE.ENSEMBLE_NAME%TYPE;
	l_agen_id REF_ENSEMBLE.AGEN_ID%TYPE;
	l_trace_domain REF_ENSEMBLE.TRACE_DOMAIN%TYPE;
	l_cmmnt REF_ENSEMBLE.CMMNT%TYPE;
	l_index number;
	
	BEGIN	
		/* 1. get ensemble table columns for the input ensemble_id                */
		begin
         select ensemble_name,agen_id,trace_domain,cmmnt 
           into l_ensemble_name,l_agen_id,l_trace_domain,l_cmmnt
           from REF_ENSEMBLE where ensemble_id = P_ENSEMBLE_ID;
		
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		
		/* otherwise everything went smoothly so setting the REF_ENSEMBLE name value pairs  */
		output_parameter_names(1) := 'name';
		output_parameter_values(1) := l_ensemble_name;
		output_parameter_names(2) := 'agen_id';
		output_parameter_values(2) := to_char(l_agen_id);
		output_parameter_names(3) := 'domain';
		output_parameter_values(3) := l_trace_domain;
		output_parameter_names(4) := 'comment';
		output_parameter_values(4) := l_cmmnt;
		
		/* now go get the keyval pairs from the REF_ENSEMBLE_KEYVAL table   */
		l_index := 5;
		    
		FOR ensemble_key in (select * from REF_ENSEMBLE_KEYVAL where ensemble_id = P_ENSEMBLE_ID)
		  LOOP  
   		    output_parameter_names(l_index) := ensemble_key.key_name;
		    output_parameter_values(l_index) := ensemble_key.key_value;
		    l_index := l_index + 1;
		 END LOOP;

	end read_ensemble_metadata;  


	procedure read_ensemble_trace_metadata(  
	  p_ensemble_id REF_ENSEMBLE_TRACE.ENSEMBLE_ID%TYPE,
	  p_trace_id  REF_ENSEMBLE_TRACE.TRACE_ID%TYPE,
	  output_parameter_names  OUT stringTable,
	  output_parameter_values OUT stringTableLrg) is

	/*  
		procedure read_ensemble_trace_metadata is used to look up any and all ENSEMBLE Trace Metatdata values 
		needed for the riverware connection program.  
	  
	 Initial Programming  by M. Bogner    January 2014
	*/
	
	/* first declare the temporary variables needed for proc calls  and etc... */
	l_trace_numeric REF_ENSEMBLE_TRACE.TRACE_NUMERIC%TYPE;
	l_trace_name REF_ENSEMBLE_TRACE.TRACE_NAME%TYPE;
	l_model_run_id REF_ENSEMBLE_TRACE.MODEL_RUN_ID%TYPE;
	l_index number;
	
	BEGIN	
		/* 1. get ref_ensemble_trace table columns for the input ensemble_id, trace_id   */
		begin
         select trace_numeric,trace_name,model_run_id 
           into l_trace_numeric,l_trace_name,l_model_run_id
           from REF_ENSEMBLE_TRACE where ensemble_id = P_ENSEMBLE_ID and trace_id = P_TRACE_ID;
		
		EXCEPTION
		when others then
			raise_application_error(-20003, SQLERRM);
		end;
		
		/* otherwise everything went smoothly so setting the REF_ENSEMBLE_TRACE name value pairs  */
		output_parameter_names(1) := 'numeric';
		output_parameter_values(1) := l_trace_numeric;
		output_parameter_names(2) := 'name';
		output_parameter_values(2) := l_trace_name;
		output_parameter_names(3) := 'model_run_id';
		output_parameter_values(3) := to_char(l_model_run_id);
		
		/* 2. go get the keyval pairs from the REF_MODEL_RUN_KEYVAL table for the input ensemble_id, trace_id */
		l_index := 4;
		    
		FOR trace_key in (select * from REF_MODEL_RUN_KEYVAL where model_run_id in
		      (select model_run_Id from REF_ENSEMBLE_TRACE where ensemble_id = P_ENSEMBLE_ID
		      and trace_id = P_TRACE_ID))
		  LOOP  
   		    output_parameter_names(l_index) := trace_key.key_name;
		    output_parameter_values(l_index) := trace_key.key_value;
		    l_index := l_index + 1;
		 END LOOP;

	end read_ensemble_trace_metadata;  
	
	procedure write_ensemble_metadata(  
	  p_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
	  p_parameter_names  IN stringTable,
	  p_parameter_values IN stringTableLrg) is
		
	/*
	  Procedure write_ensemble_metadata writes the metadata for a given ensemble
	  including all key names and a matching list of key values
	 
	 Initial Programming  by M. Bogner     January 2014
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 l_count   NUMBER;
	 l_items   NUMBER;
     l_parameter REF_ENSEMBLE_KEYVAL.KEY_NAME%TYPE;
     
	 BEGIN
        /* validate the passed in P_ENSEMBLE_ID parameter  */
        validate_ensemble(P_ENSEMBLE_ID,'WRITE_ENSEMBLE_METADATA');
	    /*  parse the array of parameters  */
		l_items := p_parameter_names.count();
		For i IN 1..l_items LOOP	    
	     l_parameter := UPPER(p_parameter_names(i));
            /* test to see if this is metatdata for the REF_ENSEMBLE record  */ 
			IF l_parameter = 'NAME' THEN 
			  update REF_ENSEMBLE set ensemble_name = p_parameter_values(i) where ensemble_id = P_ENSEMBLE_ID;
			ELSIF l_parameter = 'AGEN_ID' THEN
			  update REF_ENSEMBLE set agen_id = STN(p_parameter_values(i)) where ensemble_id = P_ENSEMBLE_ID;
			ELSIF l_parameter = 'DOMAIN' THEN
			  update REF_ENSEMBLE set trace_domain = p_parameter_values(i) where ensemble_id = P_ENSEMBLE_ID;
			ELSIF l_parameter = 'COMMENT' THEN
			  update REF_ENSEMBLE set cmmnt = p_parameter_values(i) where ensemble_id = P_ENSEMBLE_ID;
			ELSE
			  /* otherwise this is a key for the appropriate key table  */
			  insert into REF_ENSEMBLE_KEYVAL (ensemble_id,key_name,key_value,date_time_loaded)
			    values (P_ENSEMBLE_ID,p_parameter_names(i),p_parameter_values(i),sysdate);
			END IF;
		
		END  LOOP;
        /* all done so commit the changes  */
		commit;
	end write_ensemble_metadata;

	
	procedure write_ensemble_trace_metadata(  
	  p_ensemble_id REF_ENSEMBLE_TRACE.ENSEMBLE_ID%TYPE,
	  p_trace_id REF_ENSEMBLE_TRACE.TRACE_ID%TYPE,
	  p_parameter_names  IN stringTable,
	  p_parameter_values IN stringTableLrg) is
		
	/*
	  Procedure write_ensemble_trace_metadata writes the metadata for a given ensemble trace
	  including all key names and a matching list of key values
	 
	 Initial Programming  by M. Bogner     January 2014
	*/
	 
	 /* first declare all the temporary variables needed for these checks   */
	 l_count   NUMBER;
	 l_items   NUMBER;
     l_parameter REF_ENSEMBLE_KEYVAL.KEY_NAME%TYPE;
     l_model_run_id REF_ENSEMBLE_TRACE.MODEL_RUN_ID%TYPE;
     l_trace_numeric REF_ENSEMBLE_TRACE.TRACE_NUMERIC%TYPE := NULL;
     l_ensemble_name REF_ENSEMBLE.ENSEMBLE_NAME%TYPE := NULL;
     l_trace_name REF_ENSEMBLE_TRACE.TRACE_NAME%TYPE := NULL;
     
	 BEGIN
        /* validate the passed in P_ENSEMBLE_ID                      */
        validate_ensemble_trace(P_ENSEMBLE_ID,P_TRACE_ID,'WRITE_ENSEMBLE_TRACE_METADATA');
        /* get the ensemble_name for this ensemble_trace  */
        select ensemble_name into l_ensemble_name from REF_ENSEMBLE
          where ensemble_id = P_ENSEMBLE_ID;
        /* get the model_run_id for this ensemble_trace  */
        select model_run_id into l_model_run_id from REF_ENSEMBLE_TRACE 
          where ensemble_id = P_ENSEMBLE_ID and trace_id = P_TRACE_ID;
	    /*  parse the array of parameters  */
		l_items := p_parameter_names.count();
		For i IN 1..l_items LOOP	    
	     l_parameter := UPPER(p_parameter_names(i));
            /* test to see if this is metadata for the REF_ENSEMBLE_TRACE record  */ 
			IF l_parameter = 'NAME' THEN 
			  update REF_ENSEMBLE_TRACE set trace_name = p_parameter_values(i) 
			  where ensemble_id = P_ENSEMBLE_ID and trace_id = P_TRACE_ID;
			  l_trace_name := p_parameter_values(i);
			ELSIF l_parameter = 'NUMERIC' THEN
			  update REF_ENSEMBLE_TRACE set trace_numeric = STN(p_parameter_values(i)) 
			  where ensemble_id = P_ENSEMBLE_ID and trace_id = P_TRACE_ID;
			  l_trace_numeric := STN(p_parameter_values(i));
			ELSIF l_parameter = 'MODEL_RUN_ID' THEN
			  update REF_ENSEMBLE_TRACE set model_run_id = STN(p_parameter_values(i)) 
			  where ensemble_id = P_ENSEMBLE_ID and trace_id = P_TRACE_ID;
			ELSE
			  /* otherwise this is a key for the appropriate key table  */
			  insert into REF_MODEL_RUN_KEYVAL (model_run_id,key_name,key_value,date_time_loaded)
			    values (l_model_run_id,p_parameter_names(i),p_parameter_values(i),sysdate);
			END IF;
		
		END  LOOP;
        /* go set the REF_MODEL_RUN MODEL_RUN_NAME, Hydrologic Indicator */
        /* set model_name = ensemble_name || (trace_numeric (if not null) otherwise trace_name)  */
        /* set Hydrologic indicator if trace_numeric is not null                                 */
        update REF_MODEL_RUN set 
          model_run_name = substr(l_ensemble_name,1,50) || 
            decode(nvl(l_trace_numeric,-999),-999,substr(l_trace_name,1,14),to_char(l_trace_numeric)),
          hydrologic_indicator =  
            decode(nvl(l_trace_numeric,-999),-999,hydrologic_indicator,to_char(l_trace_numeric)),
          extra_keys_y_n = 'Y'  
         where model_run_id = l_model_run_id;
        /* all done so commit the changes  */
		commit;
	end write_ensemble_trace_metadata;

	procedure testing (
		test_number NUMBER,
		test_char   VARCHAR2) is
	
	temp_num number;
	temp_char1 varchar2(24);
	temp_char2 varchar2(64);
	temp_char3 varchar2(100);
	parmnames stringTable;
	parmvalues stringTable;
	out_parmnames stringTable;
	out_parmvalues stringTableLrg;
	in_dates      numberTable;
	in_values     numberTable;
	out_dates      numberTable;
	out_values     numberTable;
	temp_date1    DATE;
		
	begin
	/*
	    curr_data_source_id := 1;
	    curr_agency_id := 1;
	    curr_collection_id := 1;
	    curr_data_tables := 'real';
	    curr_model_run_id := 1;
	    curr_start_of_time := to_date('01-JAN-1800','dd-MON-yyyy');
	*/
	    parmnames(1) := 'name'; parmvalues(1) := 'my trace testing--1';    
	    parmnames(2) := 'domain'; parmvalues(2) := 'My Domain';    
	    parmnames(3) := 'numeric'; parmvalues(3) := '69';
	    parmnames(4) := 'collection_system_id'; parmvalues(4) := '1';    
	    parmnames(5) := 'begin_year'; parmvalues(5) := '1800';
		parmnames(6) := 'model_run_id'; parmvalues(6) := '1';    
	    parmnames(7) := 'comment'; parmvalues(7) := 'No real good comment';    
--	    parmnames(8) := 'type'; parmvalues(8) := 'write';    
	    parmnames(8) := 'type'; parmvalues(8) := 'read';    
	    parmnames(9) := 'tables'; parmvalues(9) := 'real';    
    
	    in_dates(1) := 6311347200;
	    in_values(1) := 12345.99;
	    in_dates(2) := 6524922800;
	    in_values(2) := 98765.99;

	    in_dates(3) := 6525532800;
	    in_values(3) := 7777;
	    in_dates(4) := 6526137600;
	    in_values(4) := 55.66;

--        init_ensemble(1);
--      write_ensemble_trace_metadata (1,1,parmnames,parmvalues);    
--      write_ensemble_metadata (1,parmnames,parmvalues);    
--       read_ensemble_metadata(1,out_parmnames,out_parmvalues);
--     read_ensemble_trace_metadata(1,1,out_parmnames,out_parmvalues);
--     for temp_num in 1..out_parmnames.count() loop
--     insert into temp1 values (out_parmnames(temp_num)||':' || out_parmvalues(temp_num) || ', ');
--     end loop;
--    commit;

--       write_riverware_data_to_db('a','b',test_number,test_char,in_dates,in_values,parmnames,parmvalues);
--              deny_action('RETURN MESSAGE: '||temp_char3); 
--      read_db_data_to_riverware('a','b',test_number,test_char,0,6540345186,parmnames,parmvalues,out_dates,out_values);
--         deny_action('First Value: '||to_char(out_dates(1))); 
--     temp_char3 := null;
--     for temp_num in 1..out_values.count() loop
--     temp_char3 := temp_char3 || to_char(out_values(temp_num)) || ',';
--     end loop;
--     deny_action('Numbers: '|| temp_char3); 
--        write_riverware_data_to_db('a','b',1,'DAY',in_dates,in_values,parmnames,parmvalues,temp_num,temp_char3);
--		  init_riverware_dataset(parmnames,parmvalues);
--	      read_real_data('hour',1,curr_start_of_time,curr_start_of_time,sysdate,out_dates,out_values);	      
--	      deny_action('First Value: '||to_char(out_dates(1))); 
--        delete_riverware_data_from_db('a','b',1,'HOUR',in_dates,parmnames,parmvalues,temp_num,temp_char3);
--        write_riverware_data_to_db('a','b',1,'DAY',in_dates,in_values,parmnames,parmvalues,temp_num,temp_char3);
--	    temp_date1 := set_hdb_date(6311347200,test_number,test_char);
--	    deny_action('DATE: '||to_char(temp_date1));
--        write_riverware_data_to_db('a','b',6,'HOUR',in_dates,in_values,parmnames,parmvalues,temp_num,temp_char3);
--		deny_action('UNIT:  ' || parmvalues(1) || ' MSSG:  '||temp_char3);
--        init_riverware_dmi(parmnames,parmvalues);
--		get_unit_for_riverware_slot(test_number,'a','a',temp_char1,temp_num,temp_char2);
--	    deny_action('error NUmber:'||to_char(temp_num) || ' UNIT: ' ||temp_char1||' ERROR: ' ||temp_char2);
--	    deny_action('The ERROR NUmber is :'||to_char(temp_num) || ' ERROR: ' ||temp_char2);
--		validate_model_run(test_number,'RC.IRRW');	 
--		select (to_date('01-JAN-2000','dd-MON-YYYY') - start_of_time) * SECONDS_PER_DAY into temp_num from dual;
--     EXCEPTION
---     when OTHERS THEN
-- 	  deny_action('The NUmber is :'||to_char(test_number));
	end testing;

  FUNCTION GET_ENSEMBLE_ID(P_ENSEMBLE_NAME VARCHAR2)
    RETURN NUMBER IS
      l_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate ENSEMBLE_ID
        Number for a given ENSEMBLE_NAME in HDB.  The record is found in table REF_ENSEMBLE.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2013
    */
         begin
        select ensemble_id into l_ensemble_id
          from ref_ensemble
          where ensemble_name = P_ENSEMBLE_NAME; 
         exception when others then        
	       l_ensemble_id := -999;
       end;
    RETURN (l_ensemble_id);
  
  END;  /* End of Function GET_ENSEMBLE_ID  */ 

FUNCTION GET_MODEL_RUN_ID(P_MODEL_ID NUMBER, P_MODEL_RUN_NAME VARCHAR2 DEFAULT NULL, P_RUN_DATE DATE DEFAULT NULL, P_IS_RUNDATE_KEY VARCHAR2 DEFAULT 'N')
  RETURN NUMBER IS
      l_model_run_id REF_MODEL_RUN.MODEL_RUN_ID%TYPE;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate MODEL_RUN_ID
        Number for a given MODEL_ID, MODEL_RUN_NAME and possibly p_RUN_DATE in HDB.  The record is found 
        in table TABLE REF_MODEL_RUN.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2013
    */
     IF P_IS_RUNDATE_KEY = 'Y' THEN
       begin
        select rmr.model_run_id into l_model_run_id
          from  ref_model_run rmr
          where 
              rmr.model_id = P_MODEL_ID
          and rmr.run_date = P_RUN_DATE
          and rmr.model_run_name = P_MODEL_RUN_NAME; 
         exception when others then        
	       l_model_run_id := -999;
       end;
       ELSE
       begin
        select rmr.model_run_id into l_model_run_id
          from ref_model_run rmr
          where 
              rmr.model_id = P_MODEL_ID
              and rmr.model_run_name = P_MODEL_RUN_NAME;
         exception when others then        
	       l_model_run_id := -999;
	    end;
       END IF;
    RETURN (l_model_run_id);
  
  END;  /* End of Function GET_MODEL_RUN_ID  */ 
  
  procedure create_ref_ensemble_trace_rec (
  p_ensemble_id IN REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
  p_model_run_id IN REF_MODEL_RUN.MODEL_RUN_ID%TYPE,
  p_trace_number IN number) is
 
  /* the local variables         */
  procedure_indicator varchar2(100);
      
  l_trace_numeric REF_ENSEMBLE_TRACE.TRACE_NUMERIC%TYPE;
  l_trace_name REF_ENSEMBLE_TRACE.TRACE_NAME%TYPE DEFAULT NULL;
      
  BEGIN
  /*  This procedure was written to assist in the ENSEMBLE processing to create a record in HDB
    in table REF_ENSEMBLE_TRACE.
    
    this procedure written by Daren Critelli February 2015
  */

  procedure_indicator := 'ENSEMBLE_TRACE Create FAILED FOR: ';

    /*  first do error checking  */
	  IF P_MODEL_RUN_ID < 1 THEN 
		  DENY_ACTION(procedure_indicator || '<NULL> MODEL_RUN_ID');
    END IF;

    l_trace_numeric := p_trace_number;

	  /*  do the insert */
    BEGIN
      insert into REF_ENSEMBLE_TRACE RET
      (RET.ENSEMBLE_ID,RET.TRACE_ID,RET.TRACE_NUMERIC,RET.TRACE_NAME,RET.MODEL_RUN_ID)
      values (P_ENSEMBLE_ID,P_TRACE_NUMBER,L_TRACE_NUMERIC,L_TRACE_NAME,P_MODEL_RUN_ID);
    END;
    
end create_ref_ensemble_trace_rec;

procedure create_ref_model_run_rec (
  p_ensemble_name IN REF_ENSEMBLE.ENSEMBLE_NAME%TYPE,
  p_model_id IN REF_MODEL_RUN.MODEL_ID%TYPE,
  p_model_run_id OUT REF_MODEL_RUN.MODEL_ID%TYPE,
  p_trace_number IN number) is
 
  /* the local variables         */
  procedure_indicator varchar2(100);

  L_MODEL_RUN_NAME REF_MODEL_RUN.MODEL_RUN_NAME%TYPE;
  L_MODEL_ID REF_MODEL_RUN.MODEL_ID%TYPE; 
  L_RUN_DATE REF_MODEL_RUN.RUN_DATE%TYPE; 
  L_EXTRA_KEYS_Y_N REF_MODEL_RUN.EXTRA_KEYS_Y_N%TYPE DEFAULT 'N'; 
  L_START_DATE REF_MODEL_RUN.START_DATE%TYPE DEFAULT NULL; 
  L_END_DATE REF_MODEL_RUN.END_DATE%TYPE DEFAULT NULL;
  L_HYDROLOGIC_INDICATOR REF_MODEL_RUN.HYDROLOGIC_INDICATOR%TYPE DEFAULT NULL; 
  L_MODELTYPE REF_MODEL_RUN.MODELTYPE%TYPE DEFAULT NULL;
  L_TIME_STEP_DESCRIPTOR REF_MODEL_RUN.TIME_STEP_DESCRIPTOR%TYPE DEFAULT NULL;
  L_CMMNT REF_MODEL_RUN.CMMNT%TYPE DEFAULT NULL;
      
  l_model_run_id REF_MODEL_RUN.MODEL_RUN_ID%TYPE; 
      
  BEGIN
  /*  This procedure was written to assist in the ENSEMBLE processing to create a record in HDB
    in table REF_MODEL_RUN.
    
    this procedure written by Daren Critelli February 2015
  */

  L_MODEL_ID := p_model_id;
  L_RUN_DATE := sysdate;
  procedure_indicator := 'MODEL_RUN_ID Create FAILED FOR: ';

  /*  first do error checking  */
	IF L_MODEL_ID IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL_ID');
	ELSIF L_RUN_DATE IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> RUN DATE');
	ELSIF L_MODEL_ID < 1 THEN 
		DENY_ACTION(procedure_indicator || 'NEGATIVE or ZERO MODEL_ID');
  END IF;

    L_MODEL_RUN_NAME := substr(P_ENSEMBLE_NAME,1,60) || substr(to_char(10000+P_TRACE_NUMBER),2,4);

	  /*  do the insert */
    BEGIN
    
      insert into REF_MODEL_RUN RMR
      (RMR.MODEL_RUN_ID,RMR.MODEL_RUN_NAME,RMR.MODEL_ID,RMR.RUN_DATE,RMR.EXTRA_KEYS_Y_N,RMR.START_DATE,
      RMR.END_DATE,RMR.HYDROLOGIC_INDICATOR,RMR.MODELTYPE,RMR.TIME_STEP_DESCRIPTOR,RMR.CMMNT)
      values
      (-1,L_MODEL_RUN_NAME,L_MODEL_ID,L_RUN_DATE,L_EXTRA_KEYS_Y_N,L_START_DATE,L_END_DATE,
      L_HYDROLOGIC_INDICATOR,L_MODELTYPE,L_TIME_STEP_DESCRIPTOR,L_CMMNT);
    END;
 
    p_model_run_id := GET_MODEL_RUN_ID(L_MODEL_ID, L_MODEL_RUN_NAME, NULL, 'N'); 
  
end create_ref_model_run_rec;
 
procedure create_ensemble_id (
  p_ensemble_id OUT REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
  p_ensemble_name IN REF_ENSEMBLE.ENSEMBLE_NAME%TYPE,
  p_model_id IN REF_MODEL_RUN.MODEL_ID%TYPE,
  p_number_traces IN number,
  p_agency_id IN REF_ENSEMBLE.AGEN_ID%TYPE,
  p_trace_domain IN REF_ENSEMBLE.TRACE_DOMAIN%TYPE,
  p_cmmnt IN REF_ENSEMBLE.CMMNT%TYPE ) is
 
  /* the local variables         */
  procedure_indicator varchar2(100);
  l_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE;
  l_agency_id REF_ENSEMBLE.AGEN_ID%TYPE := -999;
  l_trace_domain REF_ENSEMBLE.TRACE_DOMAIN%TYPE DEFAULT NULL;
  l_cmmnt REF_ENSEMBLE.CMMNT%TYPE DEFAULT NULL;
  l_trace_number number;
  
  p_model_run_id REF_MODEL_RUN.MODEL_RUN_ID%TYPE; 
    
  BEGIN
  /*  This procedure was written to assist in the ENSEMBLE processing to create a record in HDB
    in table REF_ENSEMBLE so that the unique representation of a ENSEMBLE NAME record can be 
    represented.
    
    this procedure written by Daren Critelli February 2015
  */

  procedure_indicator := 'ENSEMBLE Create FAILED FOR: ';

  /*  first do error checking  */
  l_ensemble_id := GET_ENSEMBLE_ID(P_ENSEMBLE_NAME);
  IF P_ENSEMBLE_NAME IS NULL THEN 
    DENY_ACTION(procedure_indicator || '<NULL> ENSEMBLE_NAME');
  ELSIF P_MODEL_ID < 1 THEN 
    DENY_ACTION(procedure_indicator || '<NULL> MODEL_ID');
  ELSIF P_AGENCY_ID IS NULL THEN 
    DENY_ACTION(procedure_indicator || '<NULL> AGENCY_ID');
  ELSIF L_ENSEMBLE_ID > 0 THEN 
    DENY_ACTION(procedure_indicator || 'EXISTING ENSEMBLE NAME');
  END IF;
  
  l_agency_id := P_AGENCY_ID;
  l_trace_domain := P_TRACE_DOMAIN;
  l_cmmnt := P_CMMNT;
    
  /*  do the insert, using -1 as ensemble_id since on insert trigger will populate  */
  BEGIN

    insert into REF_ENSEMBLE RE
    (RE.ENSEMBLE_ID,RE.ENSEMBLE_NAME,RE.AGEN_ID,RE.TRACE_DOMAIN,RE.CMMNT)
    values (-1,P_ENSEMBLE_NAME,l_agency_id,l_trace_domain,l_cmmnt);
  END;
 
  p_ensemble_id := GET_ENSEMBLE_ID(P_ENSEMBLE_NAME);
 
  for l_trace_number IN 1..p_number_traces LOOP
    create_ref_model_run_rec(p_ensemble_name,p_model_id,p_model_run_id,l_trace_number);
    create_ref_ensemble_trace_rec(p_ensemble_id,p_model_run_id,l_trace_number);
  END LOOP;

  commit;
  
end create_ensemble_id;

procedure update_ensemble_id (
p_ensemble_id IN REF_ENSEMBLE.ENSEMBLE_ID%TYPE,
p_ensemble_name IN REF_ENSEMBLE.ENSEMBLE_NAME%TYPE,
p_model_id IN REF_MODEL_RUN.MODEL_ID%TYPE,
p_number_traces IN number,
p_agency_id IN REF_ENSEMBLE.AGEN_ID%TYPE,
p_trace_domain IN REF_ENSEMBLE.TRACE_DOMAIN%TYPE,
p_cmmnt IN REF_ENSEMBLE.CMMNT%TYPE ) is

  /* the local variables         */
  procedure_indicator varchar2(100);
  l_agency_id REF_ENSEMBLE.AGEN_ID%TYPE;
  l_trace_domain REF_ENSEMBLE.TRACE_DOMAIN%TYPE DEFAULT NULL;
  l_cmmnt REF_ENSEMBLE.CMMNT%TYPE DEFAULT NULL;
  
  L_MODEL_RUN_NAME REF_MODEL_RUN.MODEL_RUN_NAME%TYPE;
  L_MODEL_RUN_ID REF_ENSEMBLE_TRACE.MODEL_RUN_ID%TYPE DEFAULT 0;

  t_ensemble_name REF_ENSEMBLE.ENSEMBLE_NAME%TYPE;
  t_agency_id REF_ENSEMBLE.AGEN_ID%TYPE;
  t_trace_domain REF_ENSEMBLE.TRACE_DOMAIN%TYPE;
  t_cmmnt REF_ENSEMBLE.CMMNT%TYPE;

  t_number_traces number;
  T_MODEL_RUN_ID REF_ENSEMBLE_TRACE.MODEL_RUN_ID%TYPE;
  T_MODEL_ID REF_MODEL_RUN.MODEL_ID%TYPE DEFAULT 0;
  
begin

 /*  This procedure was written to assist in the ENSEMBLE processing to update a record in HDB
    in table HDB_ENSEMBLE so that the unique representation of a ENSEMBLE NAME record can be 
    represented.
    
    this procedure written by Daren Critelli February 2015
  */

  procedure_indicator := 'ENSEMBLE Edit FAILED FOR: ';

  /*  first do error checking  */
  IF P_ENSEMBLE_NAME IS NULL THEN 
    DENY_ACTION(procedure_indicator || '<NULL> ENSEMBLE_NAME');
  ELSIF P_MODEL_ID < 1 THEN 
    DENY_ACTION(procedure_indicator || '<NULL> MODEL_ID');
  ELSIF P_AGENCY_ID IS NULL THEN 
    DENY_ACTION(procedure_indicator || '<NULL> AGENCY_ID');
  ELSIF P_ENSEMBLE_ID < 1 THEN 
    DENY_ACTION(procedure_indicator || 'MISSING ENSEMBLE NAME');
  END IF;

  l_agency_id := P_AGENCY_ID;
  l_trace_domain := P_TRACE_DOMAIN;
  l_cmmnt := P_CMMNT;

  select
    RE.ENSEMBLE_NAME,RE.AGEN_ID,RE.TRACE_DOMAIN,RE.CMMNT
    into t_ensemble_name,t_agency_id,t_trace_domain,t_cmmnt
    from REF_ENSEMBLE RE
    where RE.ENSEMBLE_ID = p_ensemble_id;

  select count(*) into t_number_traces from REF_ENSEMBLE_TRACE RET where RET.ENSEMBLE_ID = P_ENSEMBLE_ID;
--  dbms_output.Put_line(t_number_traces);

  if t_number_traces > 0 then
    select RET.MODEL_RUN_ID into l_model_run_id from REF_ENSEMBLE_TRACE RET where RET.ENSEMBLE_ID = P_ENSEMBLE_ID AND RET.TRACE_ID = 1;
  end if;

  if l_model_run_id > 0 then
    select RMR.MODEL_ID into t_model_id from REF_MODEL_RUN RMR where RMR.MODEL_RUN_ID = l_model_run_id;
  end if;
    
  /*  do the update */
  BEGIN

  if p_ensemble_name <> t_ensemble_name then
    update REF_ENSEMBLE RE SET RE.ENSEMBLE_NAME = P_ENSEMBLE_NAME where RE.ENSEMBLE_ID = P_ENSEMBLE_ID;    
        for l_trace_number IN 1..t_number_traces LOOP
        L_MODEL_RUN_NAME := substr(P_ENSEMBLE_NAME,1,60) || substr(to_char(10000+L_TRACE_NUMBER),2,4);
        select RET.MODEL_RUN_ID into l_model_run_id from REF_ENSEMBLE_TRACE RET where RET.ENSEMBLE_ID = P_ENSEMBLE_ID AND RET.TRACE_ID = l_trace_number;
        update REF_MODEL_RUN RMR SET RMR.MODEL_RUN_NAME = l_model_run_name where RMR.MODEL_RUN_ID = l_model_run_id;
        END LOOP;
  end if;  
 
  if l_agency_id <> t_agency_id then
    update REF_ENSEMBLE RE SET RE.AGEN_ID = l_agency_id where RE.ENSEMBLE_ID = P_ENSEMBLE_ID;
  end if; 

  if l_trace_domain <> t_trace_domain OR l_trace_domain IS NULL then
    update REF_ENSEMBLE RE SET RE.TRACE_DOMAIN = l_trace_domain where RE.ENSEMBLE_ID = P_ENSEMBLE_ID;
  end if;  

  if l_cmmnt <> t_cmmnt OR l_cmmnt IS NULL then
    update REF_ENSEMBLE RE SET RE.CMMNT = l_cmmnt where RE.ENSEMBLE_ID = P_ENSEMBLE_ID;
  end if;  
  END;
 
  if (t_number_traces <> p_number_traces) OR (t_model_id <> p_model_id) then
    for l_trace_number IN 1..t_number_traces LOOP
      select RET.MODEL_RUN_ID into l_model_run_id from REF_ENSEMBLE_TRACE RET where RET.ENSEMBLE_ID = P_ENSEMBLE_ID AND RET.TRACE_ID = l_trace_number; 
-- delete model data
      delete from m_hour where model_run_id = l_model_run_id;
      delete from m_day where model_run_id = l_model_run_id;
      delete from m_month where model_run_id = l_model_run_id;
      delete from m_year where model_run_id = l_model_run_id;
      delete from m_wy where model_run_id = l_model_run_id;
-- delete all REF_MODEL_RUN_KEYVAL records for all traces related to this ensemble       
      delete REF_MODEL_RUN_KEYVAL where model_run_id = l_model_run_id;        
-- delete ref_model_run data
      delete from REF_MODEL_RUN RMR where RMR.MODEL_RUN_ID = l_model_run_id;
-- delete ref_ensemble_trace traces
      delete from REF_ENSEMBLE_TRACE RET where RET.ENSEMBLE_ID = P_ENSEMBLE_ID AND RET.TRACE_ID = l_trace_number;
    END LOOP;
    for l_trace_number IN 1..p_number_traces LOOP
-- create ref_model_run data
      create_ref_model_run_rec(p_ensemble_name,p_model_id,l_model_run_id,l_trace_number);
-- create ref_ensemble_trace traces
      create_ref_ensemble_trace_rec(p_ensemble_id,l_model_run_id,l_trace_number);
    END LOOP;
  end if;

  commit;

end update_ensemble_id;

end riverware_connection;

/
--  cp_processor package added for CP upgrade 3.0
-- Expanding: ./PACKAGES/cp_processor.sps
create or replace package CP_PROCESSOR as
/*  PACKAGE CP_PROCESSOR is the package designed to contain all
    the procedures and functions for general CP_PROCESSOR use.
    
    Created by M. Bogner April 2012   
*/


/*  DECLARE ALL GLOBAL variables  */
/*  For HDB we will use a datatype_standard set to 'hdb'   */
    DATATYPE_STANDARD VARCHAR2(5) := 'hdb';

-- This function returns the ts_id for an existing record in table CP_TS_ID; retruns a -99 if it doesn't exist
  FUNCTION GET_TS_ID(P_SDI NUMBER, P_INTERVAL VARCHAR2, P_TABLE_SELECTOR VARCHAR2, P_MODEL_ID NUMBER)
   RETURN NUMBER;

-- This procedure insures a record is in table CP_TS_ID with the input Parameters via a merge statement
  PROCEDURE CREATE_TS_ID(P_SDI NUMBER, P_INTERVAL VARCHAR2, P_TABLE_SELECTOR VARCHAR2, P_MODEL_ID NUMBER,
  P_TS_ID IN OUT NUMBER);

-- This procedure insures a record is in table POPULATE_CP_COMP_DEPENDS with the input Parameters via a merge statement
  PROCEDURE POPULATE_CP_COMP_DEPENDS(P_TS_ID NUMBER, P_COMPUTATION_ID NUMBER);

-- This procedure creates records CP_COMP_DEPENDS table from input SDI's exiting non-group computations  
  PROCEDURE PRE_POPULATE_COMP_DEPENDS;

  -- Procedure NOTIFY_TSCREATED is a procedure originally written for the CWMS version of the CP application
  -- The signature was modified since the TS_ID and TS_CODE columns storage datatypes were switched
  --  PROCEDURE NOTIFY_TSCREATED (P_TSID INTEGER, P_TS_CODE VARCHAR2); 
  
  PROCEDURE TEST_PACKAGE(P_SDI NUMBER, P_INTERVAL VARCHAR2, P_TABLE_SELECTOR VARCHAR2, P_MODEL_ID NUMBER);
 		
    
END CP_PROCESSOR;

/

create or replace public synonym CP_PROCESSOR for CP_PROCESSOR;
BEGIN EXECUTE IMMEDIATE 'grant execute on CP_PROCESSOR to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on CP_PROCESSOR to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/cp_processor.spb

CREATE OR REPLACE PACKAGE BODY CP_PROCESSOR AS 
  
  FUNCTION GET_TS_ID(P_SDI NUMBER, P_INTERVAL VARCHAR2, P_TABLE_SELECTOR VARCHAR2, P_MODEL_ID NUMBER)
    RETURN NUMBER IS
      l_ts_id NUMBER;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate TS_ID
        Number for a given timeseries in HDB.  The record is found in table CP_TS_ID.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   April 2012                            */

         begin
        select ts_id into l_ts_id
          from cp_ts_id
          where site_datatype_id = P_SDI 
            and interval = P_INTERVAL
            and table_selector = P_TABLE_SELECTOR 
            and model_id = P_MODEL_ID;
         exception when others then        
	       l_ts_id := -999;
       end;
    RETURN (l_ts_id);
  
  END;  /* End of Function GET_TS_ID  */ 


   PROCEDURE CREATE_TS_ID(
    P_SDI NUMBER, 
    P_INTERVAL VARCHAR2, 
    P_TABLE_SELECTOR VARCHAR2, 
    P_MODEL_ID NUMBER,
    P_TS_ID IN OUT NUMBER ) IS

      /* the local variables         */
      l_ts_id number;
      l_count number;
      l_model_id number;
      procedure_indicator varchar2(100);
      temp_chars varchar2(100);
      l_text     varchar2(200);
      
 BEGIN
/*  This procedure was written to assist in the CP processing to create a record in HDB
    in table CP_TS_ID so that the unique representation of a time series record can be 
    represented.
    
    NOTE:  p_model_id is -1 for real time data
    
    NOTE: This procedure not only creates a new TS_ID, but it also will check
          for an existing ts_id based on the input parameters and either way
          return a correct TS_ID.
          
    this procedure written by Mark Bogner   April 2012          
    Modified July 31 2012 by M. Bogner to to add sanity checks for new entries   
    */

    procedure_indicator := 'CREATE_TS_ID FAILED FOR: ';
/*  first do error checking  */
    IF P_SDI IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> SITE_DATATYPE_ID');
	ELSIF P_INTERVAL IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> INTERVAL');
	ELSIF P_TABLE_SELECTOR IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> TABLE SELECTOR');
	ELSIF P_MODEL_ID is NULL THEN 
		DENY_ACTION(procedure_indicator || 'INVALID <NULL> MODEL_ID');
    END IF;

/* validate the interval via a select from the hdb_interval table  */
    BEGIN
      select interval_name into temp_chars
        from hdb_interval
        where interval_name = P_INTERVAL;
       exception when others then 
       DENY_ACTION(procedure_indicator || 'INVALID ' || P_INTERVAL || ' INTERVAL');
    END;

     /* validate the Table Selector  */
	IF P_TABLE_SELECTOR not in ('R_','M_') THEN 
		DENY_ACTION(procedure_indicator || 'INVALID ' || P_TABLE_SELECTOR || 'TABLE SELECTOR');
    END IF;
    
	IF P_TABLE_SELECTOR = 'R_' AND P_MODEL_ID > 0 THEN 
		DENY_ACTION(procedure_indicator || 'INVALID ' || P_TABLE_SELECTOR || 'TABLE SELECTOR' ||
		 ' WITH NON_VALID MODEL_ID: ' || to_char(P_MODEL_ID));
    END IF;
        
	IF P_TABLE_SELECTOR = 'M_' AND P_MODEL_ID < 1 THEN 
		DENY_ACTION(procedure_indicator || 'INVALID ' || P_TABLE_SELECTOR || 'TABLE SELECTOR' ||
		 ' WITH NON_VALID MODEL_ID: ' || to_char(P_MODEL_ID));
    END IF;
 
 /* temp disable sanity checks */
if ( 'xxx' = 'yyy' ) then
    /* check for valid interval types for this records attributes  */
    if (P_INTERVAL = 'instant') then

     if ( P_TABLE_SELECTOR = 'M_' ) then
        l_text := 'Instant interval invalid for Modeled Data';
        deny_action(l_text);
     end if;

     select count(*) into l_count 
     from hdb_datatype dt, hdb_site_datatype sd
     where dt.allowable_intervals in ('instant','either') 
       and sd.site_datatype_id = P_SDI
       and sd.datatype_id = dt.datatype_id;

     if (l_count = 0) then
        l_text := 'Invalid INSTANT Interval for this SDI: ' || to_char(P_SDI);
        deny_action(l_text);
     end if;

    end if;

    /* 
      Datatype's allowable intervals must be either or non-instant 
      for non-instant data */
    if (P_INTERVAL <> 'instant') then

       select count(*) into l_count 
       from hdb_datatype dt, hdb_site_datatype sd
       where dt.allowable_intervals in ('non-instant','either') 
         and sd.site_datatype_id = P_SDI
         and sd.datatype_id = dt.datatype_id;

       if (l_count = 0) then
          l_text := 'Invalid NON-INSTANT Interval: ' || P_INTERVAL || ' for this SDI: ' || to_char(P_SDI);
          deny_action(l_text);
       end if;

    end if;
    /* end of the data sanity checks  */
     end if;  /* temp shutoff of sanity checks  */
 
	/* Do a merge to go see if there is a record with these values already in CP_TS_ID */
	/*  if not, then the merge will do an insert, using -1 as ts_id since on insert trigger will populate  */
    BEGIN
       merge into CP_TS_ID CPT
       using (
       select P_SDI "SDI",P_INTERVAL "INTERVAL",P_TABLE_SELECTOR "TABLE_SELECTOR", P_MODEL_ID "MODEL_ID"
       from dual
       ) MV
       on (CPT.SITE_DATATYPE_ID = MV.SDI and CPT.INTERVAL = MV.INTERVAL and CPT.TABLE_SELECTOR = MV.TABLE_SELECTOR
           and CPT.MODEL_ID = MV.MODEL_ID)
       WHEN NOT MATCHED THEN INSERT 
       (CPT.TS_ID,CPT.SITE_DATATYPE_ID,CPT.INTERVAL,CPT.TABLE_SELECTOR,CPT.MODEL_ID,CPT.DATE_TIME_LOADED)
       values (-1,MV.SDI,MV.INTERVAL,MV.TABLE_SELECTOR,MV.MODEL_ID,sysdate);
    END;
		
	/* so things should have succeeded here so finish up and return  the assigned
	   TS_ID. for the input parameters
	*/
	P_TS_ID := GET_TS_ID(P_SDI, P_INTERVAL, P_TABLE_SELECTOR, P_MODEL_ID);
	
  END; /*  create_ts_id procedure  */


  PROCEDURE POPULATE_CP_COMP_DEPENDS(P_TS_ID NUMBER, P_COMPUTATION_ID NUMBER)
   IS
    BEGIN
    /*  This procedure was written to Populate table CP_COMP_DEPENDS
        as a preliminary requirement for the HDB phase 3.0 requirement
        Design decision was to do a merge statement and have this as a stand alone procedure
        to do the merge statement since this procedure will come in handy in other needs
        
        this procedure written by Mark Bogner   April 2012                            */

        merge into CP_COMP_DEPENDS CPD
        using ( select P_TS_ID "TS_ID",P_COMPUTATION_ID "COMPUTATION_ID" from dual ) MV
        on (CPD.TS_ID = MV.TS_ID and CPD.COMPUTATION_ID = MV.COMPUTATION_ID)
        WHEN NOT MATCHED THEN INSERT (CPD.TS_ID,CPD.COMPUTATION_ID)
        values (MV.TS_ID,MV.COMPUTATION_ID);
        
    END;  /* End of Procedure POPULATE_CP_COMP_DEPENDS  */     


  PROCEDURE PRE_POPULATE_COMP_DEPENDS IS
      l_ts_id NUMBER;
    BEGIN
    /*  This procedure was written to assist in the population of the CP_TS_ID and CP_COMP_DEPENDS
        for existing non-group computations already defined in exiting HDB databases and
        as a preliminary requirement for the HDB phase 3.0 requirement
    
        this procedure written by Mark Bogner   April 2012                            */
     /* now handle current computations a bit differently so as to populate CP_COMP_DEPENDS  */
     FOR C1 in  
     (
       /* get the needed input for table CP_TS_ID from all the defined active computations */
       select distinct cc.computation_id, ccts.site_datatype_id, ccts.interval, ccts.table_selector, 
       nvl(ccts.model_id,-1) "MODEL_ID"
       from  cp_computation cc, cp_comp_ts_parm ccts, cp_algo_ts_parm catp
       where 
             UPPER(cc.enabled) = 'Y' 
        and  cc.loading_application_id is not null
        and  cc.computation_id = ccts.computation_id
        and  cc.algorithm_id = catp.algorithm_id
        and  ccts.algo_role_name = catp.algo_role_name
        and  LOWER(catp.parm_type) like 'i%'
        and  ccts.table_selector in ('R_','M_')
        and  nvl(cc.group_id, -1) = -1
      )
      LOOP
         /* loop through these rows and enter each into CP_TS_ID via procedure call */
         CP_PROCESSOR.create_ts_id (C1.SITE_DATATYPE_ID,C1.INTERVAL,C1.TABLE_SELECTOR,C1.MODEL_ID,l_ts_id);
         /* take the computation_id and the l_ts_id from the procedure call and do a merge into CP_COMP_DEPENDS */
         CP_PROCESSOR.populate_cp_comp_depends(l_ts_id,C1.COMPUTATION_ID); 
         /* commit the two merge statements that were accomplished */
         commit;
      END LOOP;   /* end of for C1 loop */      
   
    END;  /* End of Procedure PRE_POPULATE_TSID  */     
  

  PROCEDURE TEST_PACKAGE(P_SDI NUMBER, P_INTERVAL VARCHAR2, P_TABLE_SELECTOR VARCHAR2, P_MODEL_ID NUMBER)
    IS
      l_ts_id NUMBER;
      l_temp_code VARCHAR2(1);
    BEGIN
    /*  This function was written to assist in the testing of this packages objects
    
        this function written by Mark Bogner   April 2012                            */

      l_ts_id := 0;
--    CP_PROCESSOR.create_ts_id (P_SDI, P_INTERVAL, P_TABLE_SELECTOR, P_MODEL_ID,l_ts_id);
--    commit;
--    CP_PROCESSOR.EVAL_HIERARCHICAL_GROUP_SITE(P_SDI, P_MODEL_ID, l_temp_code);
--    --DENY_ACTION('TS_ID: ' || to_char(l_ts_id));
  
  END;  /* End of Function TEST_PACKAGE  */ 

END CP_PROCESSOR;  /* Package End  */


/
-- Expanding: ./PACKAGES/snapshot_manager.sps
create or replace package SNAPSHOT_MANAGER as
/*  PACKAGE SNAPSHOT_MANAGER is the package designed to contain all
    the procedures and functions for general SNAPSHOT_MANAGER use.
    
    Created by M. Bogner April 2013  
    Added new CZAR procedures by Ismail O - Dec 2021
*/


/*  DECLARE ALL GLOBAL variables  */
   G_SNAPSHOT_MANAGER_KEY VARCHAR2(50) := 'SNAPSHOT_MANAGER';
   G_SNAPSHOT_CZAR_MANAGER_KEY VARCHAR2(50) := 'SNAPSHOT_CZAR_MANAGER';

-- This procedure performs all the business rules required when a master table has been modified
  PROCEDURE SNAPSHOT_MODIFIED(P_TABLE_NAME VARCHAR2);

-- This procedure performs all the required actions the snapshot manager must do during a refresh  
  PROCEDURE PERFORM_REFRESH(P_TABLE_NAME VARCHAR2);
  
  -- This procedure performs all the business rules required when a master table has been modified for CZAR tables
  PROCEDURE SNAPSHOT_CZAR_MODIFIED(P_TABLE_NAME VARCHAR2);

-- This procedure performs all the required actions the snapshot manager must do during a refresh  for CZAR tables
  PROCEDURE PERFORM_CZAR_REFRESH(P_TABLE_NAME VARCHAR2);
    
END SNAPSHOT_MANAGER;

/

create or replace public synonym SNAPSHOT_MANAGER for SNAPSHOT_MANAGER;
BEGIN EXECUTE IMMEDIATE 'grant execute on SNAPSHOT_MANAGER to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on SNAPSHOT_MANAGER to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/snapshot_manager.spb
CREATE OR REPLACE PACKAGE BODY SNAPSHOT_MANAGER AS 
  
   PROCEDURE SNAPSHOT_MODIFIED(
    P_TABLE_NAME VARCHAR2 ) IS

      /* the local variables         */
      l_procedure_indicator varchar2(100);

 BEGIN
/*  This procedure was written to assist in the maintenance of the Master/SLave table/snapshot
    situation at several HDB sites.
    this procedure written by Mark Bogner   April 2013
    */

    l_procedure_indicator := 'SNAPSHOT_MODIFIED FAILED FOR: ';
/*  first do error checking  */
    IF P_TABLE_NAME IS NULL THEN 
		DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
    END IF;

	/* insert the tablename into the generic database list table  */
	INSERT INTO REF_DB_GENERIC_LIST (RECORD_KEY, RECORD_KEY_VALUE1) VALUES
    (G_SNAPSHOT_MANAGER_KEY, UPPER(P_TABLE_NAME));

  END; /*  snapshot_modified procedure  */

  PROCEDURE PERFORM_REFRESH(P_TABLE_NAME VARCHAR2)
   IS
     l_table_names VARCHAR2(512);
     l_procedure_indicator varchar2(100);
     l_count number;
   BEGIN
    /*  This procedure was written to perform the required refreshes based on the input 
        parameter or the entries for snapshot manager in the table ref_db_generic_list

        this procedure written by Mark Bogner   April 2013                            */

    l_procedure_indicator := 'PERFORM_REFRESH FAILED FOR: ';
/*  first do error checking  */
    IF P_TABLE_NAME IS NULL THEN 
		DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
    END IF;

/* set the l_table_name that will be used to call the remote refresh procedures */    
    IF UPPER(P_TABLE_NAME) = 'ALL' THEN 
      l_table_names := 'ALL';
     ELSIF P_TABLE_NAME = '%' THEN
      select listagg(table_name, ',') WITHIN GROUP (ORDER BY table_name) into l_table_names from 
      (select distinct record_key_value1 "TABLE_NAME" from ref_db_generic_list 
       where record_key = G_SNAPSHOT_MANAGER_KEY);       
     ELSE l_table_names := P_TABLE_NAME;
    END IF;

/*  see if there is any work to do                         */
    select count(*) into l_count from ref_db_generic_list 
       where record_key = G_SNAPSHOT_MANAGER_KEY
       and record_key_value1 LIKE decode(l_table_names,'ALL','%',l_table_names);    

   IF l_count > 0 THEN
     /* call the remote refresh procedures */
     refresh_hdb_snap(l_table_names);
     refresh_hdb_snap2(l_table_names);
   END IF;

/* Clean up the SNAPSHOT MANAGER ENTRIES IN the REF_DB_GENERIC_LIST TABLE  */
   delete from REF_DB_GENERIC_LIST where record_key = G_SNAPSHOT_MANAGER_KEY
   and record_key_value1 LIKE decode(UPPER(P_TABLE_NAME),'ALL','%','%','%',l_table_names);    

    END;  /* End of Procedure PERFORM_REFRESH  */     
    

   PROCEDURE SNAPSHOT_CZAR_MODIFIED(
    P_TABLE_NAME VARCHAR2 ) IS

      /* the local variables         */
      l_procedure_indicator varchar2(100);

 BEGIN
/*  This procedure was written to assist in the maintenance of the Master/SLave CZAR table/snapshot
    situation at several HDB sites.
    this procedure written by Ismail O - Dec 2021
    */

    l_procedure_indicator := 'SNAPSHOT_CZAR_MODIFIED FAILED FOR: ';
/*  first do error checking  */
    IF P_TABLE_NAME IS NULL THEN 
		DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
    END IF;

	/* insert the tablename into the generic database list table  */
	INSERT INTO REF_CZAR_DB_GENERIC_LIST (RECORD_KEY, RECORD_KEY_VALUE1) VALUES
    (G_SNAPSHOT_CZAR_MANAGER_KEY, UPPER(P_TABLE_NAME));

  END; /*  snapshot_czar_modified procedure  */

  PROCEDURE PERFORM_CZAR_REFRESH(P_TABLE_NAME VARCHAR2)
   IS
     l_table_names VARCHAR2(512);
     l_procedure_indicator varchar2(100);
     l_count number;
   BEGIN
    /*  This procedure was written to perform the required refreshes based on the input 
        parameter or the entries for snapshot manager in the table ref_czar_db_generic_list

        this procedure rewritten for CZAR tables  by Ismail O - Dec 2021                       */

    l_procedure_indicator := 'PERFORM_CZAR_REFRESH FAILED FOR: ';
/*  first do error checking  */
    IF P_TABLE_NAME IS NULL THEN 
		DENY_ACTION(l_procedure_indicator || 'INVALID <NULL> TABLE_NAME');
    END IF;

/* set the l_table_name that will be used to call the remote refresh procedures */    
    IF UPPER(P_TABLE_NAME) = 'ALL' THEN 
      l_table_names := 'ALL';
     ELSIF P_TABLE_NAME = '%' THEN
      select listagg(table_name, ',') WITHIN GROUP (ORDER BY table_name) into l_table_names from 
      (select distinct record_key_value1 "TABLE_NAME" from ref_czar_db_generic_list 
       where record_key = G_SNAPSHOT_CZAR_MANAGER_KEY);       
     ELSE l_table_names := P_TABLE_NAME;
    END IF;

/*  see if there is any work to do                         */
    select count(*) into l_count from ref_czar_db_generic_list 
       where record_key = G_SNAPSHOT_CZAR_MANAGER_KEY
       and record_key_value1 LIKE decode(l_table_names,'ALL','%',l_table_names);    

   IF l_count > 0 THEN
     /* call the remote refresh procedures */
    LCHDBA.REFRESH_PHYS_QUAN_SNAP@LCHDB.UC.USBR.GOV;
    YAOHDBA.REFRESH_PHYS_QUAN_SNAP@YAOHDB.UC.USBR.GOV;
	ECODBA.REFRESH_PHYS_QUAN_SNAP@ECOHDB.UC.USBR.GOV;
    --KBHDBA.REFRESH_PHYS_QUAN_SNAP@KBOHDB.UC.USBR.GOV;
   END IF;

/* Clean up the SNAPSHOT MANAGER ENTRIES IN the REF_CZAR_DB_GENERIC_LIST TABLE  */
   delete from REF_CZAR_DB_GENERIC_LIST where record_key = G_SNAPSHOT_CZAR_MANAGER_KEY
   and record_key_value1 LIKE decode(UPPER(P_TABLE_NAME),'ALL','%','%','%',l_table_names);    

    END;  /* End of Procedure PERFORM_CZAR_REFRESH  */         

END SNAPSHOT_MANAGER;  /* Package End  */

/
--  packages added for ensemble
-- Expanding: ./PACKAGES/ensemble.sps
create or replace package ENSEMBLE as
/*  PACKAGE ENSEMBLE is the package designed to contain all
    the procedures and functions for general ENSEMBLE use.
    
    Created by M. Bogner January 2013 for work to make TSTool 
    able to write ensembles to the ECAO HDB database
    Modified April 2014 to add the P_AGEN_ID to the procedure call to set AGEN_ID in REF_ENSEMBLE table   
*/

/*  DECLARE ALL GLOBAL variables  */
/*  For HDB and TSTool we will use a trace_domain standard set to 'TRACE NUMBER'   */
    G_TRACE_DOMAIN_STANDARD VARCHAR2(15) := 'TRACE NUMBER';
    G_DEFAULT_CMMNT VARCHAR2(100) := 'DEFAULT COMMENT ADDED BY ENSEMBLE PACKAGE VIA CREATE PROCEDURE CALL';
    G_MODEL_ID NUMBER := -999;
    G_MODEL_RUN_ID NUMBER := -999;
    G_ENSEMBLE_ID NUMBER := -999;
    G_TRACE_ID NUMBER := -999;
    
-- This procedure is the interface to TSTool in managing ensembles and returning the model_run_id for a
-- particular ensemble and trace number
PROCEDURE GET_TSTOOL_ENSEMBLE_MRI(
  OP_MODEL_RUN_ID OUT NUMBER, P_ENSEMBLE_NAME VARCHAR2, P_TRACE_NUMBER NUMBER, P_MODEL_NAME VARCHAR2,
  P_RUN_DATE DATE DEFAULT sysdate, P_IS_RUNDATE_KEY VARCHAR2 DEFAULT 'N', P_AGEN_ID NUMBER DEFAULT NULL);  		
   
END ENSEMBLE;

/

create or replace public synonym ENSEMBLE for ENSEMBLE;
BEGIN EXECUTE IMMEDIATE 'grant execute on ENSEMBLE to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on ENSEMBLE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PACKAGES/ensemble.spb

CREATE OR REPLACE PACKAGE BODY ENSEMBLE AS 
  
  FUNCTION GET_MODEL_ID(P_MODEL_NAME VARCHAR2)
    RETURN NUMBER IS
      l_model_id HDB_MODEL.MODEL_ID%TYPE;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate MODEL_ID
        Number for a given MODEL_NAME in HDB.  The record is found in table HDB_MODEL.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2013                   
    */
         
      begin
        select model_id into l_model_id
          from hdb_model
          where model_name = P_MODEL_NAME; 
         exception when others then        
	       l_model_id := -999;
       end;
    RETURN (l_model_id);
  
  END;  /* End of Function GET_MODEL_ID  */ 

  
  FUNCTION GET_ENSEMBLE_ID(P_ENSEMBLE_NAME VARCHAR2)
    RETURN NUMBER IS
      l_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate ENSEMBLE_ID
        Number for a given ENSEMBLE_NAME in HDB.  The record is found in table REF_ENSEMBLE.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2013
    */
         begin
        select ensemble_id into l_ensemble_id
          from ref_ensemble
          where ensemble_name = P_ENSEMBLE_NAME; 
         exception when others then        
	       l_ensemble_id := -999;
       end;
    RETURN (l_ensemble_id);
  
  END;  /* End of Function GET_ENSEMBLE_ID  */ 

  FUNCTION GET_MODEL_RUN_ID(P_MODEL_ID NUMBER, P_MODEL_RUN_NAME VARCHAR2 DEFAULT NULL, P_RUN_DATE DATE DEFAULT NULL, P_IS_RUNDATE_KEY VARCHAR2 DEFAULT 'N')
  RETURN NUMBER IS
      l_model_run_id REF_MODEL_RUN.MODEL_RUN_ID%TYPE;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate MODEL_RUN_ID
        Number for a given MODEL_ID, MODEL_RUN_NAME and possibly p_RUN_DATE in HDB.  The record is found 
        in table TABLE REF_MODEL_RUN.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2013
    */
     IF P_IS_RUNDATE_KEY = 'Y' THEN
       begin
        select rmr.model_run_id into l_model_run_id
          from  ref_model_run rmr
          where 
              rmr.model_id = P_MODEL_ID
          and rmr.run_date = P_RUN_DATE
          and rmr.model_run_name = P_MODEL_RUN_NAME; 
         exception when others then        
	       l_model_run_id := -999;
       end;
       ELSE
       begin
        select rmr.model_run_id into l_model_run_id
          from ref_model_run rmr
          where 
              rmr.model_id = P_MODEL_ID
              and rmr.model_run_name = P_MODEL_RUN_NAME;
         exception when others then        
	       l_model_run_id := -999;
	    end;
       END IF;
    RETURN (l_model_run_id);
  
  END;  /* End of Function GET_MODEL_RUN_ID  */ 


  FUNCTION GET_ENSEMBLE_MRI(P_ENSEMBLE_ID NUMBER, P_TRACE_ID NUMBER, P_MODEL_ID NUMBER, 
  P_MODEL_RUN_NAME VARCHAR2, P_RUN_DATE DATE DEFAULT NULL, P_IS_RUNDATE_KEY VARCHAR2 DEFAULT 'N')
  RETURN NUMBER IS
      l_model_run_id REF_MODEL_RUN.MODEL_RUN_ID%TYPE;
    BEGIN
    /*  This function was written to assist in finding the unique surrogate MODEL_RUN_ID
        Number for a given ENSEMBLE, TRACE in HDB.  The record is found in table REF_ENSEMBLE_TRACE 
        Joined with TABLE REF_MODEL_RUN.
        If the record is not found, a negative -999 is returned.
    
        this function written by Mark Bogner   January 2013
    */
     IF P_IS_RUNDATE_KEY = 'Y' THEN
       begin
        select ret.model_run_id into l_model_run_id
          from ref_ensemble_trace ret, ref_model_run rmr
          where 
              ret.ensemble_id = P_ENSEMBLE_ID
          and ret.trace_id = P_TRACE_ID
          and ret.model_run_id = rmr.model_run_id
          and rmr.model_id = P_MODEL_ID
          and rmr.run_date = P_RUN_DATE
          and rmr.model_run_name = P_MODEL_RUN_NAME; 
         exception when others then        
	       l_model_run_id := -999;
       end;
       ELSE
       begin
        select ret.model_run_id into l_model_run_id
          from ref_ensemble_trace ret, ref_model_run rmr
          where 
              ret.ensemble_id = P_ENSEMBLE_ID
          and ret.trace_id = P_TRACE_ID
          and ret.model_run_id = rmr.model_run_id
          and rmr.model_id = P_MODEL_ID
          and rmr.model_run_name = P_MODEL_RUN_NAME;
         exception when others then        
	       l_model_run_id := -999;
	    end;
       END IF;
    RETURN (l_model_run_id);
  
  END;  /* End of Function GET_ENSEMBLE_MRI  */ 


  PROCEDURE CREATE_MODEL(
    P_MODEL_NAME VARCHAR2, 
    P_COORDINATED VARCHAR2 DEFAULT 'N', 
    P_CMMNT VARCHAR2 DEFAULT G_DEFAULT_CMMNT) 
  IS
      /* the local variables         */
      procedure_indicator varchar2(100);
      l_text     varchar2(200);
      l_model_id HDB_MODEL.MODEL_ID%TYPE;
      l_coordinated HDB_MODEL.COORDINATED%TYPE;
      l_cmmnt    HDB_MODEL.CMMNT%TYPE;
      
 BEGIN
 /*  This procedure was written to assist in the CP processing to create a record in HDB
    in table HDB_MODEL so that the unique representation of a Model NAME record can be 
    represented.
    
    this procedure written by Mark Bogner   January 2013
 */

  procedure_indicator := 'Model Create FAILED FOR: ';

 /*  first do error checking  */
    l_model_id := GET_MODEL_ID(P_MODEL_NAME);
    IF P_MODEL_NAME IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL_NAME');
	ELSIF P_COORDINATED IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL COORDINATED');
	ELSIF L_MODEL_ID > 0 THEN 
		DENY_ACTION(procedure_indicator || 'EXISTING MODEL_NAME');
    END IF;

    l_coordinated := substr(P_COORDINATED,1,1);
    l_cmmnt := P_CMMNT;
	/*  do the insert, using -1 as model_id since on insert trigger will populate  */
    BEGIN

       insert into HDB_MODEL HM
       (HM.MODEL_ID,HM.MODEL_NAME,HM.COORDINATED,HM.CMMNT)
        values (-1,P_MODEL_NAME,l_coordinated,l_cmmnt);
    END;
			
END; /*  create_model procedure  */


  PROCEDURE CREATE_ENSEMBLE(
    P_ENSEMBLE_NAME VARCHAR2,
    P_AGEN_ID NUMBER DEFAULT NULL,
    P_TRACE_DOMAIN VARCHAR2 DEFAULT G_TRACE_DOMAIN_STANDARD,
    P_CMMNT VARCHAR2 DEFAULT G_DEFAULT_CMMNT)
  IS
      /* the local variables         */
      procedure_indicator varchar2(100);
      l_ensemble_id REF_ENSEMBLE.ENSEMBLE_ID%TYPE;
      l_trace_domain_standard REF_ENSEMBLE.TRACE_DOMAIN%TYPE := G_TRACE_DOMAIN_STANDARD;
      l_default_cmmnt REF_ENSEMBLE.CMMNT%TYPE := G_DEFAULT_CMMNT;
      
 BEGIN
 /*  This procedure was written to assist in the ENSEMBLE processing to create a record in HDB
    in table HDB_ENSEMBLE so that the unique representation of a ENSEMBLE NAME record can be 
    represented.
    
    this procedure written by Mark Bogner   January 2013
 */

  procedure_indicator := 'ENSEMBLE Create FAILED FOR: ';

 /*  first do error checking  */
    l_ensemble_id := GET_ENSEMBLE_ID(P_ENSEMBLE_NAME);
    IF P_ENSEMBLE_NAME IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> ENSEMBLE_NAME');
	ELSIF L_ENSEMBLE_ID > 0 THEN 
		DENY_ACTION(procedure_indicator || 'EXISTING ENSEMBLE NAME');
    END IF;

    IF P_TRACE_DOMAIN IS NOT NULL THEN 
       l_trace_domain_standard := P_TRACE_DOMAIN;
    END IF;

    IF P_CMMNT IS NOT NULL THEN 
       l_default_cmmnt := P_CMMNT;
    END IF;
    
	/*  do the insert, using -1 as ensemble_id since on insert trigger will populate  */
    BEGIN

       insert into REF_ENSEMBLE RE
       (RE.ENSEMBLE_ID,RE.ENSEMBLE_NAME,RE.AGEN_ID,RE.TRACE_DOMAIN,RE.CMMNT)
        values (-1,P_ENSEMBLE_NAME,P_AGEN_ID,l_trace_domain_standard,l_default_cmmnt);
    END;
			
END; /*  create_ensemble procedure  */

PROCEDURE CREATE_ENSEMBLE_TRACE(
  P_ENSEMBLE_ID NUMBER, 
  P_TRACE_ID NUMBER, 
  P_TRACE_NUMERIC NUMBER, 
  P_TRACE_NAME VARCHAR2, 
  P_MODEL_RUN_ID NUMBER)
  IS
      /* the local variables         */
      procedure_indicator varchar2(100);
      
 BEGIN
 /*  This procedure was written to assist in the ENSEMBLE processing to create a record in HDB
    in table HDB_ENSEMBLE_TRACE so that the unique representation of a ENSEMBLE and TRACE record 
    to a model_run_id can be represented.
    
    this procedure written by Mark Bogner   January 2013
    modified by M. Bogner March 26 2013 for business rule # 16 (see below)
 */

  procedure_indicator := 'ENSEMBLE_TRACE Create FAILED FOR: ';

 /*  first do error checking  */
    IF P_ENSEMBLE_ID IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> ENSEMBLE_ID');
	ELSIF P_TRACE_ID IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> TRACE_ID');
	ELSIF P_MODEL_RUN_ID < 1 THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL_RUN_ID');
	ELSIF P_TRACE_NUMERIC IS NULL AND P_TRACE_NAME IS NULL THEN 
		DENY_ACTION(procedure_indicator || 'BOTH <NULL> TRACE_NUMBER AND TRACE NAME');
    END IF;

	/*  do the insert */
    BEGIN

       insert into REF_ENSEMBLE_TRACE RET
       (RET.ENSEMBLE_ID,RET.TRACE_ID,RET.TRACE_NUMERIC,RET.TRACE_NAME,RET.MODEL_RUN_ID)
        values (P_ENSEMBLE_ID,P_TRACE_ID,P_TRACE_NUMERIC,P_TRACE_NAME,P_MODEL_RUN_ID);
    END;
			
END; /*  create_ensemble_trace procedure  */

  PROCEDURE CREATE_MODEL_RUN (
    P_MODEL_RUN_NAME VARCHAR2, 
    P_MODEL_ID NUMBER, 
    P_RUN_DATE DATE, 
    P_EXTRA_KEYS_Y_N VARCHAR2 DEFAULT 'N', 
    P_START_DATE DATE DEFAULT NULL, 
    P_END_DATE DATE DEFAULT NULL,
    P_HYDROLOGIC_INDICATOR VARCHAR2 DEFAULT NULL, 
    P_MODELTYPE VARCHAR2 DEFAULT NULL,
    P_TIME_STEP_DESCRIPTOR VARCHAR2 DEFAULT NULL, 
    P_CMMNT VARCHAR2 DEFAULT G_DEFAULT_CMMNT)
  IS
      /* the local variables         */
      procedure_indicator varchar2(100);
      
 BEGIN
 /*  This procedure was written to assist in the ENSEMBLE processing to create a record in HDB
    in table REF_MODEL_RUN so that the unique representation of a MODEL_RUN_NAME,MODEL_ID,RUN_DATE 
    to a model_run_id can be represented.
    
    this procedure written by Mark Bogner   January 2013
 */

  procedure_indicator := 'MODEL_RUN_ID Create FAILED FOR: ';

 /*  first do error checking  */
    IF P_MODEL_RUN_NAME IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL_RUN_NAME');
	ELSIF P_MODEL_ID IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL_ID');
	ELSIF P_RUN_DATE IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> RUN DATE');
	ELSIF P_MODEL_ID < 1 THEN 
		DENY_ACTION(procedure_indicator || 'NEGATIVE or ZERO MODEL_ID');
    END IF;

	/*  do the insert */
    BEGIN
       insert into REF_MODEL_RUN RMR
       (RMR.MODEL_RUN_ID,RMR.MODEL_RUN_NAME,RMR.MODEL_ID,RMR.RUN_DATE,RMR.EXTRA_KEYS_Y_N,RMR.START_DATE,
        RMR.END_DATE,RMR.HYDROLOGIC_INDICATOR,RMR.MODELTYPE,RMR.TIME_STEP_DESCRIPTOR,RMR.CMMNT)
        values
        (-1,P_MODEL_RUN_NAME,P_MODEL_ID,P_RUN_DATE,P_EXTRA_KEYS_Y_N,P_START_DATE,P_END_DATE,
         P_HYDROLOGIC_INDICATOR,P_MODELTYPE,P_TIME_STEP_DESCRIPTOR,P_CMMNT);
    END;
			
END; /*  create_model_run_id procedure  */

PROCEDURE GET_TSTOOL_ENSEMBLE_MRI (
  OP_MODEL_RUN_ID OUT NUMBER,
  P_ENSEMBLE_NAME VARCHAR2,
  P_TRACE_NUMBER NUMBER,
  P_MODEL_NAME VARCHAR2,
  P_RUN_DATE DATE DEFAULT sysdate, 
  P_IS_RUNDATE_KEY VARCHAR2 DEFAULT 'N',
  P_AGEN_ID NUMBER DEFAULT NULL)
IS
      /* the local variables         */
      procedure_indicator varchar2(100):= 'GET_TSTOOL_ENSEMBLE_MRI FAILED FOR: ';
      l_run_date DATE;
      l_model_run_name REF_MODEL_RUN.MODEL_RUN_NAME%TYPE;
      
 BEGIN
 /*  This procedure was written to assist in the ENSEMBLE processing of TsTool to: 
    
    1. return a model_run_id for the specified TsTool input parameters 
    2. apply a business rule: run_date in REF_MODEL_RUN for TsTool is truncated to the minute
       (this is a modified business rule from the original since it was originally intended to
        be truncated at the hour)
    3. apply a business rule: the model_run_name for any new REF_MODEL_RUN records will
       be a concatenation of the P_ENSEMBLE with the P_TRACE_NUMBER (up to 9999)
    --4. create a HDB_Model record if the P_MODEL_NAME doesn't already exist
    -- # 4 business rule modified per March 25 2013 meeting agreement
    4. Abort the procedure if the P_MODEL_NAME doesn't already exist
    5. create a REF_ENSEMBLE record if the P_ENSEMBLE_NAME doesn't already exist
    6. create a REF_ENSEMBLE_TRACE record if that combination of input parameters to a 
       particular model_run_id record does not already exist
    7. create a REF_MODEL_RUN record if the above business rules and input parameters 
       dictate that necessity
    8. Business rule: P_MODEL_NAME can not be NULL
    9. Business rule: P_ENSEMBLE_NAME can not be NULL
   10. Business rule: P_TRACE_NUMBER can not be NULL
   11. Business rule: P_IS_RUNDATE_KEY must be a "Y" or "N"
   12. Business rule: If using Run_DATE as part of the key, it must be a valid date and not NULL
   --13. Any use of P_RUN_DATE utilizes the truncation to the hour (minutes and seconds do not apply here)
   13. Any use of P_RUN_DATE utilizes the truncation to the minute (modified 03262013)
   14. Multiple runs of a single ensemble and trace can be stored if the Run_date is key specified
   15. HYDROLOGIC_INDICATOR column will be populated with the character representation of the trace number when
       a ref_model_run record is created
   16. A REF_ENSEMBLE_TRACE record must have either one of the trace_numeric or the trace_name populated.
   17. For TsTool ensembles, populate both trace_id and trace_numeric with the P_TRACE_NUMBER value
   18. Set AGEN_ID in the REF_ENSEMBLE table if known, otherwise default to NULL
   
    This procedure applies business rules specifically designed for the TsTool application interface
    to HDB as it pertains to Ensemble data table storage.  These business rules were not designed for 
    generic use of the Ensemble and model tables, or coordinated models so caution should be given to
    anyone who wishes to use this package and specifially this procedure if the use is not directly 
    affiliated with the Tstool application.
    
    this procedure written by Mark Bogner   January 2013
    modified by M. Bogner March 26 2013 for modified business rules 2,13,15,16,17
    modified by M. Bogner April 15 2014 for new  business rule 18
 */

 /*  first do error checking  */
    IF P_MODEL_NAME IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> MODEL_NAME');
	ELSIF P_ENSEMBLE_NAME IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> ENSEMBLE_NAME');
	ELSIF P_TRACE_NUMBER IS NULL THEN 
		DENY_ACTION(procedure_indicator || '<NULL> TRACE_NUMBER');
	ELSIF P_IS_RUNDATE_KEY <> 'Y' AND P_IS_RUNDATE_KEY <> 'N' THEN 
		DENY_ACTION(procedure_indicator || 'Invalid P_IS_RUNDATE_KEY: '|| P_IS_RUNDATE_KEY);
	ELSIF P_RUN_DATE IS NULL AND P_IS_RUNDATE_KEY = 'Y' THEN 
		DENY_ACTION(procedure_indicator || '<NULL> RUN_DATE');
    END IF;

	/*  do the necessary processing to get the existing model_run_id or create all the necessary
        records in the appropriate tables to accomplish objective (#1 in the comments above)
	*/
    BEGIN
  
    /* truncate the run_date to the hour:  Business rule  # 13  */
    --l_run_date := TRUNC(P_RUN_DATE,'HH24');  Removed and modified by M. Bogner 03-26-2013
    /* truncate the run_date to the minute:  Business rule  # 13  */
    l_run_date := TRUNC(P_RUN_DATE,'MI');
    /* formulate the model_run_name from the ensemble name and trace #  :  Business rule # 3  */
    l_model_run_name := substr(P_ENSEMBLE_NAME,1,60) || substr(to_char(10000+P_TRACE_NUMBER),2,4);
    /* get the model_id using the input parameter P_MODEL_NAME  */

     G_MODEL_ID := GET_MODEL_ID(P_MODEL_NAME);
     IF G_MODEL_ID < 0 THEN
     	 -- Modified by M. Bogner 26-March-2013 for new business rule # 4
     	 -- this procedure will not create a new hdb_model record as previously coded
     	 DENY_ACTION(procedure_indicator || ' Non-existent MODEL_NAME: '|| P_MODEL_NAME);
     --  /* the model doesn't exist yet, so create the Model:  Business rule # 4  */
     --  CREATE_MODEL(P_MODEL_NAME);
     --  G_MODEL_ID := GET_MODEL_ID(P_MODEL_NAME);
     END IF;

    /* get the ensemble_id using the input parameter P_ENSEMBLE_NAME  */
     G_ENSEMBLE_ID := GET_ENSEMBLE_ID(P_ENSEMBLE_NAME);    
     IF G_ENSEMBLE_ID < 0 THEN
       /* the ENSEMBLE NAME doesn't exist yet, so create the ENSEMBLE:  Business rule # 5, 18  */
       CREATE_ENSEMBLE(P_ENSEMBLE_NAME,P_AGEN_ID);
       G_ENSEMBLE_ID := GET_ENSEMBLE_ID(P_ENSEMBLE_NAME);
     END IF;
   
     /* see if the records exist for the combination of input parameters */
	 G_MODEL_RUN_ID := GET_ENSEMBLE_MRI(G_ENSEMBLE_ID, P_TRACE_NUMBER, G_MODEL_ID,l_model_run_name,
	                    l_run_date,P_IS_RUNDATE_KEY);		

     IF G_MODEL_RUN_ID > 0 THEN
       IF P_IS_RUNDATE_KEY = 'N' THEN
        /* this is a new run of existing ensemble, so update the run_date on the ref_model_run table  */
        update REF_MODEL_RUN set run_date=l_run_date where model_run_ID = G_MODEL_RUN_ID;
       END IF;
     ELSE
       /* the records don't exist so create new REF_MODEL_RUN and REF_ENSEMBLE_TRACE RECORDS  */
       /* create the REF_MODEL_RUN record */
       --CREATE_MODEL_RUN(l_model_run_name,G_MODEL_ID,l_run_date);
       /* modified by M. Bogner 0326201 for new business rule 15  */
       /* modified by A. Gilmore 102013 to provide 'N' extra_keys_y_n, as null cannot be used */
       CREATE_MODEL_RUN(l_model_run_name,G_MODEL_ID,l_run_date,'N',NULL,NULL,TO_CHAR(P_TRACE_NUMBER) );
       /* get the newly create model_run_id  */
       G_MODEL_RUN_ID := GET_MODEL_RUN_ID(G_MODEL_ID,l_model_run_name,l_run_date,'Y');
       /* create the REF_ENSEMBLE_TRACE record  */
       --CREATE_ENSEMBLE_TRACE(G_ENSEMBLE_ID, P_TRACE_NUMBER, NULL, NULL, G_MODEL_RUN_ID);
       /* modified by M. Bogner 0326201 for new business rule 17  */
       CREATE_ENSEMBLE_TRACE(G_ENSEMBLE_ID, P_TRACE_NUMBER, P_TRACE_NUMBER, NULL, G_MODEL_RUN_ID);
     END IF;

     /* the model_run_id should have already been determined or newly created so set the
        output parameter and exit the procedure                                       
     */
	 OP_MODEL_RUN_ID := G_MODEL_RUN_ID;
	 
	END;
	
END; /*  GET_TSTOOL_ENSEMBLE_MRI procedure  */


END ENSEMBLE;  /* Package End  */


/
-- datatype package
-- Expanding: ./PACKAGES/datatype_pkg.sps
CREATE OR REPLACE PACKAGE DATATYPE_PKG as
   type      rowid_tab_type is table of rowid index by binary_integer;
   type      dt_id_tab_type is table of number(11) index by binary_integer;
   type      dt_type_tab_type is table of varchar2(32) index by binary_integer;

   rowid_tab    rowid_tab_type;
   dt_id_tab    dt_id_tab_type;
   dt_type_tab  dt_type_tab_type;
   datatype_index binary_integer;
end datatype_pkg;
/

create or replace public synonym DATATYPE_PKG for DATATYPE_PKG;
BEGIN EXECUTE IMMEDIATE 'grant execute on DATATYPE_PKG to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on DATATYPE_PKG to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- TS_XFER packages added
-- Expanding: ./PACKAGES/ts_xfer.sps
CREATE OR REPLACE PACKAGE TS_XFER as
/*  PACKAGE TS_XFER is designed to contain fast methods for timeseries
    writing and retrieval

    Created by A. Gilmore October 2015
*/
	/* declare the associative array table types for this package   */

--TYPE number_array is table of NUMBER;
--TYPE date_array is table of DATE; -- overriding main date_array date object array


procedure GET_REAL_DATA 
(
  sdi IN NUMBER 
, start_date IN DATE 
, end_date IN DATE
, interval IN HDB_INTERVAL.INTERVAL_NAME%type 
, dates OUT datearray
, ts_values OUT number_array
, inst_interval IN NUMBER DEFAULT 15 --interval for r_instant data
);

procedure GET_MODEL_DATA
(
  sdi IN NUMBER 
, start_date IN DATE 
, end_date IN DATE
, interval in HDB_INTERVAL.INTERVAL_NAME%type
, dates OUT datearray
, ts_values OUT number_array
, mri in REF_MODEL_RUN.MODEL_RUN_ID%type
);

-- the above two do little or no validation, as it would repeat what is in get_data
-- calling the above directly will be a bit faster as they avoid sdi. interval.
-- and mri table lookups.

-- get_date
-- given site_datatype_id, begin and end dates, an interval,
--       optional real or modeled indicator, and timeseries interval in minutes
-- return a correlated array of dates and values containing all the dates in 
-- the range, and any missing values as null
--
-- checks for valid site_datatype_id, end date after begin date,
-- interval, and model_run_id if modeled data


procedure GET_DATA
(
  sdi IN NUMBER 
, start_date IN DATE 
, end_date IN DATE
, interval in HDB_INTERVAL.INTERVAL_NAME%type
, dates OUT datearray
, ts_values OUT number_array
, real_or_model IN VARCHAR2 default 'R_'
, mri_or_interval in NUMBER default 15
);

-- Write data procedures for 2016 HDB Support Task
-- initially written by Andrew Gilmore Dec 2016

procedure WRITE_REAL_DATA
(
  sdi IN NUMBER
, INTERVAL IN hdb_interval.interval_name%TYPE
, dates IN datearray
, ts_values IN number_array
, agen_id NUMBER
, overwrite_flag VARCHAR2
, VALIDATION CHAR
, COLLECTION_SYSTEM_ID NUMBER
, LOADING_APPLICATION_ID NUMBER
, METHOD_ID NUMBER
, computation_id NUMBER
, do_update_y_n VARCHAR2
, data_flags IN VARCHAR2 DEFAULT NULL
, TIME_ZONE IN VARCHAR2 DEFAULT NULL
);

procedure WRITE_MODEL_DATA
(
  sdi IN NUMBER
, INTERVAL IN hdb_interval.interval_name%TYPE
, dates IN datearray
, ts_values IN number_array
, model_run_id IN NUMBER
, do_update_y_n IN VARCHAR2
);


END TS_XFER;
/
-- Expanding: ./PACKAGES/ts_xfer.spb
CREATE OR REPLACE PACKAGE BODY TS_XFER as

procedure GET_REAL_DATA
(
  sdi IN NUMBER 
, start_date IN DATE 
, end_date IN DATE
, interval in HDB_INTERVAL.INTERVAL_NAME%type 
, dates OUT DATEARRAY
, ts_values OUT number_array
, inst_interval IN NUMBER DEFAULT 15 --interval for r_instant, r_other data
) is

  CURSOR instant (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select instants.date_time, r_instant.value from r_instant,
    table (instants_between(start_date,end_date, inst_interval)) instants
    where r_instant.site_datatype_id(+) = sdi and
    r_instant.start_date_time(+) = instants.date_time
    order by instants.date_time;

  CURSOR hour (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select hours.date_time, r_hour.value from r_hour,
    table (dates_between(start_date, end_date, 'hour')) hours
    where r_hour.site_datatype_id(+) = sdi and
    r_hour.start_date_time(+) = hours.date_time
   order by hours.date_time;

  CURSOR day (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select days.date_time, r_day.value from r_day,
    table (dates_between(start_date, end_date, 'day')) days
    where r_day.site_datatype_id(+) = sdi and
    r_day.start_date_time(+) = days.date_time
    order by days.date_time;

  CURSOR month (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select months.date_time, r_month.value from r_month,
    table (dates_between(start_date, end_date, 'month')) months
    where r_month.site_datatype_id(+) = sdi and
    r_month.start_date_time(+) = months.date_time
    order by months.date_time;

  CURSOR year (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select years.date_time, r_year.value from r_year,
    table (dates_between(start_date, end_date, 'year')) years
    where r_year.site_datatype_id(+) = sdi and
    r_year.start_date_time(+) = years.date_time
    order by years.date_time;

  CURSOR wy (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select wys.date_time, r_wy.value from r_wy,
    table (dates_between(start_date, end_date, 'wy')) wys
    where r_wy.site_datatype_id(+) = sdi and
    r_wy.start_date_time(+) = wys.date_time
    order by wys.date_time;

  CURSOR other (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select others.date_time, r_other.value from r_other,
    table (instants_between(start_date, end_date, inst_interval)) others
    where r_other.site_datatype_id(+) = sdi and
    r_other.start_date_time(+) = others.date_time
    order by others.date_time;    

--  val NUMBER;

  BEGIN

    CASE interval
    WHEN 'instant' THEN
      OPEN instant (sdi,start_date,end_date);
      FETCH instant BULK COLLECT into dates,ts_values;
      CLOSE instant;

    WHEN 'hour' THEN
      OPEN HOUR (sdi,start_date,end_date);
      FETCH HOUR BULK COLLECT into dates,ts_values;
      CLOSE HOUR;

    WHEN 'day' THEN
      OPEN day (sdi,start_date,end_date);
      FETCH day BULK COLLECT into dates,ts_values;
      CLOSE day;

    WHEN 'month' THEN
      OPEN month (sdi,start_date,end_date);
      FETCH month BULK COLLECT into dates,ts_values;
      CLOSE month;

    WHEN 'year' THEN
      OPEN year (sdi,start_date,end_date);
      FETCH year BULK COLLECT into dates,ts_values;
      CLOSE year;

    WHEN 'wy' THEN
      OPEN wy (sdi,start_date,end_date);
      FETCH wy BULK COLLECT into dates,ts_values;
      CLOSE wy;

    WHEN 'other' THEN
      OPEN other (sdi,start_date,end_date);
      FETCH other BULK COLLECT into dates,ts_values;
      CLOSE other;

    END CASE;

--testing   
--      val:=0;
--      for temp_num in 1..dates.count() loop
--        val:= val +1;
--      end loop;
--      deny_action('Numbers: '|| val);


  END GET_REAL_DATA;

procedure GET_MODEL_DATA
(
  sdi IN NUMBER 
, start_date IN DATE 
, end_date IN DATE
, interval IN HDB_INTERVAL.INTERVAL_NAME%type
, dates OUT DATEARRAY
, ts_values OUT number_array
, mri IN REF_MODEL_RUN.MODEL_RUN_ID%type
) is

  CURSOR hour (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select hours.date_time, m_hour.value from m_hour,
    table (dates_between(start_date, end_date, 'hour')) hours
    where m_hour.site_datatype_id(+) = sdi and
    m_hour.start_date_time(+) = hours.date_time and
    m_hour.model_run_id(+) = mri
    order by hours.date_time;

  CURSOR day (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select days.date_time, m_day.value from m_day,
    table (dates_between(start_date, end_date, 'day')) days
    where m_day.site_datatype_id(+) = sdi and
    m_day.start_date_time(+) = days.date_time and
    m_day.model_run_id(+) = mri
    order by days.date_time;

  CURSOR month (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select months.date_time, m_month.value from m_month,
    table (dates_between(start_date, end_date, 'month')) months
    where m_month.site_datatype_id(+) = sdi and
    m_month.start_date_time(+) = months.date_time and
    m_month.model_run_id(+) = mri
    order by months.date_time;

  CURSOR year (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select years.date_time, m_year.value from m_year,
    table (dates_between(start_date, end_date, 'year')) years
    where m_year.site_datatype_id(+) = sdi and
    m_year.start_date_time(+) = years.date_time and
    m_year.model_run_id(+) = mri
    order by years.date_time;

  CURSOR wy (sdi in NUMBER, start_date in DATE, end_date in DATE) is
    select wys.date_time, m_wy.value from m_wy,
    table (dates_between(start_date, end_date, 'wy')) wys
    where m_wy.site_datatype_id(+) = sdi and
    m_wy.start_date_time(+) = wys.date_time and
    m_wy.model_run_id(+) = mri
    order by wys.date_time; 

  BEGIN

    CASE interval
    WHEN 'instant' THEN
      deny_action('TS_XFER.GET_MODEL_DATA invalid INTERVAL, no m_ table for: ' || interval);
    WHEN 'other' THEN
      deny_action('TS_XFER.GET_MODEL_DATA invalid INTERVAL, no m_ table for: ' || interval);

    WHEN 'hour' THEN
      OPEN HOUR (sdi,start_date,end_date);
      FETCH HOUR BULK COLLECT into dates,ts_values;
      CLOSE HOUR;

    WHEN 'day' THEN
      OPEN day (sdi,start_date,end_date);
      FETCH day BULK COLLECT into dates,ts_values;
      CLOSE day;

    WHEN 'month' THEN
      OPEN month (sdi,start_date,end_date);
      FETCH month BULK COLLECT into dates,ts_values;
      CLOSE month;

    WHEN 'year' THEN
      OPEN year (sdi,start_date,end_date);
      FETCH year BULK COLLECT into dates,ts_values;
      CLOSE year;

    WHEN 'wy' THEN
      OPEN wy (sdi,start_date,end_date);
      FETCH wy BULK COLLECT into dates,ts_values;
      CLOSE wy;


    END CASE;

  END GET_MODEL_DATA;


procedure GET_DATA
(
  sdi IN NUMBER 
, start_date IN DATE 
, end_date IN DATE
, interval IN HDB_INTERVAL.INTERVAL_NAME%type
, dates OUT DATEARRAY
, ts_values OUT number_array
, real_or_model IN VARCHAR2 default 'R_'
, mri_or_interval IN NUMBER default 15 --
) is

  temp_num NUMBER;
  temp_inter HDB_INTERVAL.INTERVAL_NAME%type;

BEGIN
  -- validate inputs
  BEGIN
    SELECT site_datatype_id
    INTO temp_num
    FROM hdb_site_datatype
    WHERE site_datatype_id = sdi;
  EXCEPTION WHEN others THEN
    deny_action('TS_XFER.GET_DATA invalid SITE_DATATYPE_ID: ' || sdi);
  END;  

  if end_date < start_date then
    deny_action('TS_XFER.GET_DATA end_date must be before start_date: ' || start_date || ' ' || end_date);
  end if;

  BEGIN
    SELECT interval_name
    INTO temp_inter
    FROM hdb_interval
    WHERE interval_name = interval;

  EXCEPTION WHEN others THEN
    deny_action('TS_XFER.GET_DATA invalid INTERVAL: ' || interval);
  END;

  CASE real_or_model 
  WHEN 'R_' THEN
    GET_REAL_DATA (sdi, start_date, end_date, interval, dates, ts_values, mri_or_interval);
  WHEN 'M_' THEN
  -- validate inputs
    BEGIN
      SELECT model_run_id
      INTO temp_num
      FROM ref_model_run
      WHERE model_run_id = mri_or_interval; --default 15 might trip folks up here
    EXCEPTION WHEN others THEN
      deny_action('TS_XFER.GET_DATA invalid MODEL_RUN_ID: ' || mri_or_interval);
    END;

    GET_MODEL_DATA (sdi, start_date, end_date, interval, dates, ts_values, mri_or_interval);
  ELSE
    deny_action('Invalid real_or_model selector: ' || real_or_model);
  END CASE;

END GET_DATA;

PROCEDURE write_real_data
(
  sdi IN NUMBER
, INTERVAL IN hdb_interval.interval_name%TYPE
, dates IN DATEARRAY
, ts_values IN number_array
, agen_id NUMBER
, overwrite_flag VARCHAR2
, VALIDATION CHAR
, COLLECTION_SYSTEM_ID NUMBER
, LOADING_APPLICATION_ID NUMBER
, METHOD_ID NUMBER
, computation_id NUMBER
, do_update_y_n VARCHAR2
, data_flags IN VARCHAR2 DEFAULT NULL
, TIME_ZONE IN VARCHAR2 DEFAULT NULL
) IS
   items       NUMBER;
  -- validate inputs
BEGIN
  IF dates.count() != ts_values.count() THEN
     deny_action('TS_XFER.WRITE_REAL_DATA arrays must contain equal number of items!');
  END IF;

  begin  /* begin block for HDB stored Procedures exceptions */
			items := dates.count();
			FOR i IN 1..items loop	    
					modify_r_base (sdi,INTERVAL,dates(i),NULL,ts_values(i),agen_id,
          overwrite_flag,validation,collection_system_id,loading_application_id,
					method_id,computation_id,do_update_y_n, data_flags, time_zone);
			END loop;
  end;
END write_real_data;       

PROCEDURE write_model_data
(
  sdi IN NUMBER
, INTERVAL IN hdb_interval.interval_name%TYPE
, dates IN DATEARRAY
, ts_values IN number_array
, model_run_id IN NUMBER
, do_update_y_n IN VARCHAR2
) IS
   items       NUMBER;
BEGIN
  -- validate inputs, most validations are performed by modify_ procedures
  -- potential improvement to validate once instead for every row?
  IF dates.count() != ts_values.count() THEN
     deny_action('TS_XFER.WRITE_MODEL_DATA arrays must contain equal number of items!');
  END IF;

  begin  /* begin block for HDB stored Procedures exceptions */
			items := dates.count();
			FOR i IN 1..items loop	    
					modify_m_table(model_run_id,sdi,dates(i),null,ts_values(i),INTERVAL,do_update_y_n);
			END loop;
  end;  
END write_model_data;

END TS_XFER;
/




-- spool off
-- exit;
-- set echo on
-- set feedback on
-- spool hdb_functions.out

-- Expanding: ./FUNCTIONS/acl_mail.func

BEGIN
BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'oraclemail.xml', 
    description  => 'ACL for ORACLE MAIL',
    principal    => 'APP_ROLE',
    is_grant     => TRUE, 
    privilege    => 'connect',
    start_date   => SYSTIMESTAMP,
    end_date     => NULL);
END;
EXCEPTION WHEN OTHERS THEN NULL;
END;

/

BEGIN
BEGIN
   DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
    acl          => 'oraclemail.xml',                
    host         => 'localhost');
   COMMIT;

END;
EXCEPTION WHEN OTHERS THEN NULL;
END;

/

BEGIN
BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege ( 
    acl         => 'oraclemail.xml', 
    principal   => '${hdb_user}',
    is_grant    => TRUE, 
    privilege   => 'connect', 
    position    => NULL, 
    start_date  => NULL,
    end_date    => NULL);

END;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Expanding: ./FUNCTIONS/colorize_value.func
CREATE OR REPLACE FUNCTION colorize_value(value IN NUMBER,
                                          overwrite IN VARCHAR2,
                                          validation IN VARCHAR2,
                                          method_id IN NUMBER,
                                          derivation_flags IN VARCHAR2)
RETURN VARCHAR2
 /* This function returns a color name to apply to a cell containing
       this value.
       These color names are from the known named colors, originating with X11, 
       but also present in web browsers, .NET, and elsewhere.
       
       Colors were chosen to keep more normally editted data in pale colors, 
       while making failed validations and computation process outputs stand out
       
       LightGray - missing
       Red - failed validation
       SkyBlue - overwrite
       Yellow - computation processor algorithm
       MistyRose - derivation flags is not null
       PaleGreen - none of the above
       
       Example colors at http://en.wikipedia.org/wiki/Web_colors
       
       Initially written by Andrew Gilmore, May 20, 2008
    */
IS
/* Function to help display data for HDB Poet and other tools:
   given a value and some information, return a color name to
--    show as a background for a cell containing that value.

  Example query:
  
  select date_time, value, 
  colorize_value(value, overwrite_flag, validation,method_id,
  derivation_flags) as Color
  from r_day, table(dates_between(TO_Date('05/14/2008', 'MM/dd/yyyy'),
                                  TO_Date('05/19/2008', 'MM/dd/yyyy'),
                                  'day')) dates
  where
  start_date_time(+) = dates.date_time and
  site_datatype_id(+) = 1923
  order by dates.date_time;
  
  Output:
  
  DATE_TIME	VALUE	COLOR
14-MAY-08 00:00	7467.78	SkyBlue
15-MAY-08 00:00	null	LightGray
16-MAY-08 00:00	7400.09	MistyRose
17-MAY-08 00:00	7469.35	PaleGreen
18-MAY-08 00:00	7470.09	Yellow
19-MAY-08 00:00	null	LightGray

Red is not in this list because it only applies to failed validations,
which are only in r_base.

   */

BEGIN
  IF value IS NULL THEN
    RETURN 'LightGray';
  ELSIF validation = 'F' THEN
    RETURN 'Red';
  ELSIF overwrite IS NOT NULL THEN
    RETURN 'SkyBlue';
  ELSIF method_id = 21 THEN
    RETURN 'Yellow';
  ELSIF derivation_flags IS NOT NULL THEN
    RETURN 'MistyRose';
  ELSE
    RETURN 'PaleGreen';
  END IF;

END colorize_value;

/
-- show errors
BEGIN EXECUTE IMMEDIATE '
GRANT EXECUTE ON colorize_value TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM colorize_value FOR colorize_value;

-- Expanding: ./FUNCTIONS/colorize_with_rbase.func
CREATE OR REPLACE FUNCTION colorize_with_rbase(
	p_sdi IN NUMBER,
	p_interval IN VARCHAR2,
	p_start_time DATE,
	p_value IN NUMBER)
RETURN VARCHAR2
 /* This function returns a color name to apply to a cell containing
       this value.
       These color names are from the known named colors, originating with X11, 
       but also present in web browsers, .NET, and elsewhere.
       
       Colors were chosen to keep more normally editted data in pale colors, 
       while making failed validations and computation process outputs stand out
       
       LightGray - missing
       Red - failed validation
       SkyBlue - overwrite
       Yellow - computation processor algorithm
       MistyRose - derivation flags is not null
       PaleGreen - none of the above
       
       Example colors at http://en.wikipedia.org/wiki/Web_colors
       
       Initially written by Andrew Gilmore, May 20, 2008
       Modified and function name change by M. Bogner 03/20/09
       Modified for different color features and to include Riverware by M. Bogner 07/27/11
    */
IS
/* Function to help display data for HDB Poet and other tools:
   given a value and some information, return a color name to
--    show as a background for a cell containing that value.

  Example query:
  
  select date_time, value, 
  colorize_value(value, overwrite_flag, validation,method_id,
  derivation_flags) as Color
  from r_day, table(dates_between(TO_Date('05/14/2008', 'MM/dd/yyyy'),
                                  TO_Date('05/19/2008', 'MM/dd/yyyy'),
                                  'day')) dates
  where
  start_date_time(+) = dates.date_time and
  site_datatype_id(+) = 1923
  order by dates.date_time;
  
  Output:
  
  DATE_TIME	VALUE	COLOR
14-MAY-08 00:00	7467.78	SkyBlue
15-MAY-08 00:00	null	LightGray
16-MAY-08 00:00	7400.09	MistyRose
17-MAY-08 00:00	7469.35	PaleGreen
18-MAY-08 00:00	7470.09	Yellow
19-MAY-08 00:00	null	LightGray


   */

/* now the local variables needed  */

l_value NUMBER;
l_overwrite VARCHAR2(1);
l_validation VARCHAR2(1);
l_app_id NUMBER;
l_comp_id NUMBER;
l_data_flags VARCHAR2(20);
l_collect_id NUMBER;

BEGIN

  BEGIN
  
	select value,overwrite_flag,validation,loading_application_id,computation_id,data_flags,
	collection_system_id
	into l_value,l_overwrite,l_validation,l_app_id,l_comp_id,l_data_flags,l_collect_id
	from r_base where
	site_datatype_id = p_sdi and interval = p_interval and start_date_time = p_start_time;
	exception when others then l_value := null;
  END;

  IF p_value IS NULL AND l_value IS NULL THEN
    RETURN 'LightGray';
  ELSIF l_validation = 'F' THEN
    RETURN 'Red';
  ELSIF ABS(p_value - l_value) > .01 THEN
    RETURN 'HotPink';
  ELSIF p_value IS NOT NULL AND l_value IS NULL THEN
    RETURN 'DarkOrange';
  ELSIF l_app_id = 7 and l_collect_id = 5 and l_overwrite = 'O' then
    RETURN 'DarkTurquoise'; 
  ELSIF l_app_id = 7 and l_collect_id = 5 then
    RETURN 'Aquamarine'; 
  ELSIF l_app_id = 7 and l_collect_id = 9 and l_overwrite = 'O' then
    RETURN 'DarkKhaki'; 
  ELSIF l_app_id = 7 and l_collect_id = 9 then
    RETURN 'PaleGoldenrod'; 
  ELSIF l_app_id not in (31,32,33,34,35,36,37,38,41,43,44,45,46,47,54,55,57,58,59,60,61,62,63,65,71)
  and l_overwrite is null THEN
	RETURN  'PaleGreen';
  ELSIF l_app_id not in (31,32,33,34,35,36,37,38,41,43,44,45,46,47,54,55,57,58,59,60,61,62,63,65,71)
  and l_overwrite = 'O' THEN
	RETURN  'DarkSeaGreen';
  ELSIF l_app_id in (31,32,33,34,35,36,37,38,41,43,44,45,46,47,54,57,60,61,62,63) and
	l_overwrite = 'O' THEN
	RETURN 'RoyalBlue';
  ELSIF l_app_id in (31,32,33,34,35,36,37,38,41,43,44,45,46,47,54,57,60,61,62,63) and 
	l_overwrite IS NULL THEN
    RETURN 'SkyBlue';
  ELSIF l_app_id in (55,58,59,65,71) and l_overwrite = 'O' THEN
	RETURN 'Goldenrod';
  ELSIF l_app_id in (55,58,59,71) THEN
    RETURN 'Yellow';
  ELSIF l_app_id in (65) THEN
	RETURN 'Gold';
  ELSIF l_data_flags IS NOT NULL THEN
    RETURN 'MistyRose';
  ELSE
    RETURN 'PaleGreen';
  END IF;

END colorize_with_rbase;

/
BEGIN EXECUTE IMMEDIATE '
GRANT EXECUTE ON colorize_with_rbase TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM colorize_with_rbase FOR colorize_with_rbase;

-- Expanding: ./FUNCTIONS/colorize_with_validation.func
CREATE OR REPLACE FUNCTION colorize_with_validation(
	p_sdi IN NUMBER,
	p_interval IN VARCHAR2,
	p_start_time DATE,
	p_value IN NUMBER)
RETURN VARCHAR2
 /* This function returns a color name to apply to a cell containing
       this validation code.
       These color names are from the known named colors, originating with X11, 
       but also present in web browsers, .NET, and elsewhere.
       
       Colors were chosen to keep more normally editted data in pale colors, 
       while making failed validations and computation process outputs stand out
       
       LightGray - missing
       Red - failed validation
       SkyBlue - overwrite
       Yellow - computation processor algorithm
       MistyRose - derivation flags is not null
       PaleGreen - none of the above
       
       Example colors at http://en.wikipedia.org/wiki/Web_colors
       
       Initially written by Andrew Gilmore, May 20, 2008
       Modified and function name change by M. Bogner 10/19/2009
    */
IS
/* Function to help display data for HDB Poet and other tools:
   given a value and some information, return a color name to
--    show as a background for a cell containing certain validation values.

  Example query:
  
  select date_time, value, 
  colorize_with validation( r_day.site_datatype_id,'day',dates.date_time, r_day.value) as Color
  from r_day, table(dates_between(TO_Date('05/14/2008', 'MM/dd/yyyy'),
                                  TO_Date('05/19/2008', 'MM/dd/yyyy'),
                                  'day')) dates
  where
  start_date_time(+) = dates.date_time and
  site_datatype_id(+) = 1923
  order by dates.date_time;
  
   */

/* now the local variables needed  */

l_validation VARCHAR2(1);

BEGIN

  BEGIN
  
	select validation
	into l_validation
	from r_base where
	site_datatype_id = p_sdi and interval = p_interval and start_date_time = p_start_time;
	exception when others then l_validation := null;
	
  END;

  IF p_value IS NULL OR l_validation IS NULL THEN
    RETURN 'Wheat';
  ELSIF l_validation = 'V' THEN
    RETURN 'Green';
  ELSIF l_validation = 'A' THEN
    RETURN 'Green';
  ELSIF l_validation = 'P' THEN
    RETURN 'DeepSkyBlue';
  ELSE
    RETURN 'Wheat';
  END IF;

END colorize_with_validation;

/
BEGIN EXECUTE IMMEDIATE '
GRANT EXECUTE ON colorize_with_validation TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM colorize_with_validation FOR colorize_with_validation;

-- Expanding: ./FUNCTIONS/dates_between.func
CREATE OR REPLACE FUNCTION DATES_BETWEEN (start_date_time IN DATE,
                                         end_date_time IN DATE DEFAULT NULL,
                                         interval VARCHAR2 DEFAULT 'day')
RETURN date_array
PIPELINED

 /* This function returns a list of datetimes beginning at the 
    specified start_date, spaced at the specified interval,
    and ending at the specified end time. 

    Initially written by Andrew Gilmore, May 23, 2008

    Altered to an open end interval by Andrew Gilmore, Jan 24, 2018 
    Note: Inconsistent behavior is in use by many queries, and in LC,YAO is left in old state(without open-end interval change)
  */

IS
end_date DATE := end_date_time;
start_date DATE := start_date_time;
dates date_object := date_object(NULL);
temp_chars VARCHAR2(30);
BEGIN
  IF end_date < start_date THEN
    deny_action('End date must be after start date!');
  END IF;

  BEGIN
    SELECT interval_name
    INTO temp_chars
    FROM hdb_interval
    WHERE interval_name = interval;

  EXCEPTION WHEN others THEN
    deny_action('Dates between function INVALID ' || interval || ' interval');
  END;

  CASE interval
  WHEN 'instant' THEN
    deny_action('Cannot use instant interval in dates_between! Use instants_between.');

  WHEN 'hour' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate,   'HH24') + 1 / 24;
    END IF;
    FOR i IN 0 ..(end_date -start_date) *24 - 1
    LOOP
      dates.date_time := start_date_time + i / 24;
      pipe ROW(dates);
    END LOOP;

  WHEN 'day' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate,   'DD') + 1;
    END IF;
    FOR i IN 0 ..(end_date -start_date) - 1
    LOOP
      dates.date_time := start_date_time + i;
      pipe ROW(dates);
    END LOOP;

  WHEN 'month' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate,   'MM');
    END IF;
    /* months_between takes the later date first */
    FOR i IN 0 .. months_between(end_date,   start_date)
    LOOP
      dates.date_time := add_months(start_date,   i);
      pipe ROW(dates);
    END LOOP;

  WHEN 'year' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate,   'YYYY');
    END IF;
    /* months_between takes the later date first */
    FOR i IN 0 .. months_between(end_date,   start_date) / 12 
    LOOP
      dates.date_time := add_months(start_date,   i *12);
      pipe ROW(dates);
    END LOOP;

  WHEN 'wy' THEN
    IF end_date IS NULL THEN
      end_date := add_months(TRUNC(sysdate,   'YYYY'),   -3);
    END IF;
    /* months_between takes the later date first */
    FOR i IN 0 .. months_between(end_date,   start_date) / 12
    LOOP
      dates.date_time := add_months(start_date,   i *12);
      pipe ROW(dates);
    END LOOP;
  END CASE;

  RETURN;
END dates_between;

/

-- show errors
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON dates_between TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM dates_between FOR dates_between;
-- Expanding: ./FUNCTIONS/flow_fwssd.func
  
create or replace FUNCTION FLOW_FWSSD(
	  GATE_HT FLOAT, RES_ELEV FLOAT, TAIL_ELEV FLOAT) 
	RETURN FLOAT IS
		return_value FLOAT;
	BEGIN 
	/* this function returns the flow calculation for the FWSSD 
	   Fish and wildlife Service South Dike site according 
	   to the DENVER, CO flow calculation for that site
	*/
	
	/*  this function written by M. Bogner  06/15/2011  */
	
		begin
		return_value := NULL;
		select CASE

        WHEN (RES_ELEV > TAIL_ELEV AND GATE_HT >= TAIL_ELEV) THEN 
        3.67*2.229*power((RES_ELEV - GATE_HT),1.5)

        WHEN (TAIL_ELEV > RES_ELEV AND GATE_HT >= RES_ELEV) THEN 
        -2.11*2.229*power((TAIL_ELEV - GATE_HT),1.5)

        WHEN (TAIL_ELEV > RES_ELEV AND RES_ELEV > GATE_HT) THEN 
        -4.51*2.229*power((TAIL_ELEV - GATE_HT),1.5)*power((1-power((RES_ELEV - GATE_HT)/(TAIL_ELEV - GATE_HT),1.5)),.385)

        WHEN (RES_ELEV > TAIL_ELEV AND TAIL_ELEV > GATE_HT) THEN 
        3.67*2.229*power((TAIL_ELEV - GATE_HT),1.5)*power((1-power((TAIL_ELEV - GATE_HT)/(RES_ELEV - GATE_HT),1.5)),.385)

        ELSE 0.0 END
		
		into return_value from dual;
		exception when others then return_value := NULL;
		end;
		
	   return (return_value);
	END;

/

create or replace public synonym flow_fwssd for flow_fwssd;
BEGIN EXECUTE IMMEDIATE 'grant execute on flow_fwssd to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./FUNCTIONS/gsc.func
create or replace FUNCTION GSC(
	  Site NUMBER,ATTR NUMBER,EFF_DATE DATE,IDX NUMBER DEFAULT 1) 
	RETURN FLOAT IS
		return_value FLOAT;
	BEGIN 
	/* this function returns the coefficient value in the ref_site_coef table 
	with the input site, attribute id, index, and effective date
	*/
	
	/*  this function written by M. Bogner  02/27/2008  */
	/*  modified by M. bogner 3/14/2008 to return a null if no value is there  */
	/*  modified by M. bogner 3/14/2008 to add the coef_idx to the parameter list and the query  */
	/*  modified by M. bogner 4/1/2008 to make the coef_idx optional (defaults to 1)  */
		begin
		return_value := NULL;
		select a.coef  into return_value
		  from ref_site_coef a
		  where a.site_id = site
		  and a.attr_id = attr
		  and a.coef_idx = idx
		  and eff_date >= a.effective_start_date_time
          and eff_date < nvl(a.effective_end_date_time,sysdate);
		
		exception when others then return_value := NULL;
		end;
		
	   return (return_value);
	END;

/

-- show errors
CREATE OR REPLACE PUBLIC SYNONYM gsc for gsc;
BEGIN EXECUTE IMMEDIATE 'grant execute on gsc to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./FUNCTIONS/instants_between.func

CREATE OR REPLACE FUNCTION instants_between(start_date_time IN DATE,
                                            end_date_time IN DATE,
                                            minutes IN INTEGER DEFAULT 1440)
RETURN date_array
PIPELINED
IS
/* Function to return dates for instantaneous data, or any regular interval
   start_date_time required date to begin returning dates
   end_date_time   required ending date
   minutes         optional minutes between dates returned, defaults to one day
   
   Use this instead of dates_between for instantaneous data, because one needs to
   specify the expected interval between instantaneous data. It could be
   hourly, 30 minutes, 15 minutes, 10, 5 or even 5 seconds.
   */

/* Function to help display data for HDB Poet and other tools:
   instants_between: given two dates and a number of minutes, return list of
   all dates that many minutes apart between the two dates.

  Example query:
  
  select date_time, value, 
  colorize_value(value, overwrite_flag, validation,method_id,
  derivation_flags) as Color
  from r_day, table(dates_between(TO_Date('05/14/2008', 'MM/dd/yyyy'),
                                  TO_Date('05/19/2008', 'MM/dd/yyyy'),
                                  'day')) dates
  where
  start_date_time(+) = dates.date_time and
  site_datatype_id(+) = 1923
  order by dates.date_time;
  
  Output:
  
  DATE_TIME	VALUE	COLOR
14-MAY-08 00:00	7467.78	SkyBlue
15-MAY-08 00:00	null	LightGray
16-MAY-08 00:00	7400.09	MistyRose
17-MAY-08 00:00	7469.35	PaleGreen
18-MAY-08 00:00	7470.09	Yellow
19-MAY-08 00:00	null	LightGray

Red is not in this list because it only applies to failed validations,
which are only in r_base.

   */

intervalsperday NUMBER := 1440 / minutes;
dates date_object := date_object(NULL);
BEGIN
  IF end_date_time < start_date_time THEN
    deny_action('End date must be after start date!');
  END IF;

-- below the line was modified to return 1 less value due to count starting at zero math error
-- modified by M. Bogner  May 9 2012
  FOR i IN 0 .. (end_date_time -start_date_time) *(intervalsperday) - 1

  LOOP
    dates.date_time := start_date_time + i / intervalsperday;
    pipe ROW(dates);
  END LOOP;

  RETURN;
END instants_between;

/

-- show errors
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON instants_between TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM instants_between FOR instants_between;


-- Expanding: ./FUNCTIONS/stat_value.func
create or replace FUNCTION STAT_VALUE(
	  SDI NUMBER,INTERVAL VARCHAR2, EFF_DATE DATE) 
	RETURN FLOAT IS
		return_value FLOAT;
		s_statement varchar2(2000);
		interval_num varchar2(100);
	BEGIN 
	/* this function returns the stat value in the r_ stat tables 
	with the input site_datatype_id interval, and effective date
	*/
	
	/*  this function written by M. Bogner  03/09/2009  */
	/*  this function modified by M. Bogner  10/05/2009  to correct the indexing 
	    for the day and month   stat tables            */
	/*  this function modified by M. Bogner  11/29/2009  to account for non leap year  
	    since the indexing always has a feb-29 day in the table */ 
	    
   CASE  LOWER(interval)
     WHEN 'instant' THEN 
       interval_num := '0';
     WHEN 'hour' THEN 
       interval_num := ltrim(to_char(EFF_DATE,'HH24'),'0');
     WHEN 'day' THEN
     /* day is referenced from 01-OCT of the water year  */ 
       SELECT TRUNC(EFF_DATE) - TO_DATE( CASE WHEN TO_NUMBER( TO_CHAR( EFF_DATE,'MM') ) IN ( 10, 11, 12 )
                THEN '1-Oct-' || TO_CHAR(EFF_DATE,'YYYY') 
                ELSE '1-Oct-' || TO_CHAR( TO_NUMBER( TO_CHAR(EFF_DATE,'YYYY') ) - 1 )
                END )  + 1 into interval_num from dual;
     /* since the indexing always includes a day for leap year, you have to add one to the indexing
        for non leap years                                                                          */  
        IF ((TO_NUMBER( TO_CHAR( EFF_DATE,'MM') ) between 3 and 9 ) AND 
            (TO_CHAR(LAST_DAY(TO_DATE('01-FEB-'||TO_CHAR(EFF_DATE,'YYYY'))),'dd') = '28')) THEN
          interval_num := interval_num + 1;
        END IF;  
     WHEN 'month' THEN 
     /* month is referenced from October of the current water year  */
       SELECT CASE WHEN TO_NUMBER( TO_CHAR( EFF_DATE,'MM') ) IN ( 10, 11, 12 )
                THEN TO_NUMBER( TO_CHAR( EFF_DATE,'MM') ) - 9
                ELSE TO_NUMBER( TO_CHAR( EFF_DATE,'MM') ) + 3
                END  into interval_num from dual;

     WHEN 'year' THEN 
     /* year should be based on just year, otherwise no difference compared to WY */
       interval_num := ltrim(to_char(EFF_DATE,'YYYY'),'0');
     WHEN 'wy' THEN 
       /* water year should be based on Water year */
       /* interval_num := ltrim(to_char(EFF_DATE,'YYYY'),'0');  */
         SELECT CASE WHEN TO_NUMBER( TO_CHAR( EFF_DATE,'MM') ) IN ( 10, 11, 12 )
			THEN TO_NUMBER( TO_CHAR( EFF_DATE,'YYYY') ) + 1
			ELSE TO_NUMBER( TO_CHAR( EFF_DATE,'YYYY') )
         END  into interval_num from dual;
    END CASE;	
		begin
		return_value := NULL;
		s_statement :=
		' select value from R_' || interval || 'STAT where  ' ||
		' site_datatype_id = ' || to_char(sdi) || ' and ' ||
		interval || ' = ' || to_char(interval_num) ;
		
		/* now execute this dynamic sql select statement */
		execute immediate (s_statement) INTO return_value;		
		exception when others then return_value := NULL;
		end;
		
	   return (return_value);
	END;

/
--
CREATE OR REPLACE PUBLIC SYNONYM STAT_VALUE for STAT_VALUE;
BEGIN EXECUTE IMMEDIATE 'grant execute on STAT_VALUE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./FUNCTIONS/stn.func
create or replace function STN(txt in varchar2) 
 return number is 
begin

/*  Function STN is a safe TO_NUMBER function, it returns the TO_NUMBER value
    of the passed in txt and retruns a null if the TO_NUMBER function results 
    in an exception                                                            */
/* This function was discovered on the internet and adapted for HDB use 
    by M. Bogner April 2013                                                    */

  return to_number(txt);
  exception when value_error then
  return null; 
end STN;

/

create or replace public synonym STN for STN;
BEGIN EXECUTE IMMEDIATE 'grant execute on STN to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./FUNCTIONS/sendmail.func
create or replace FUNCTION SENDMAIL(
      P_ADDRESS VARCHAR2,
	  P_TEXT VARCHAR2) 
	RETURN Number IS
		l_return_value NUMBER;
		l_sender VARCHAR2(100) := 'echdba@ibr6ecadb001.bor.doi.net';
		l_subject VARCHAR2(100) := 'HDB Notification';
	BEGIN 
	/* this function sends an email using the utl_send procedure
	*/
	
	/*  this function written by M. Bogner  05/03/2013  */
		begin
		l_return_value := 1;
        UTL_MAIL.SEND(sender => l_sender, 
                      recipients => P_ADDRESS,
                      subject => l_subject, 
                      message => P_TEXT );		
		exception when others then l_return_value := sqlcode();
		end;
		
	   return (l_return_value);
	END;

/

create or replace public synonym SENDMAIL for SENDMAIL;
BEGIN EXECUTE IMMEDIATE 'grant execute on SENDMAIL to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./FUNCTIONS/plve.func
create or replace FUNCTION PLVE(
	  P_SDI NUMBER,P_TABLE_SELECTOR VARCHAR2, P_LIMIT_VALUE FLOAT, P_EFF_DATE DATE, P_HOURS_BACK NUMBER) 
	RETURN NUMBER is
		return_value NUMBER;
		l_statement  VARCHAR2(2000);
		
	BEGIN 
	/* this PLVE (Prior Limit Value Exceedence) function returns the the number of rows in the table 
	   that equals or exceeds the P_LIMIT_VALUE for an sdi value in the P_TABLE_SELECTOR table with 
	   the highest limit of the truncated day or the P_EFF_DATE minus the P_BACK_HOURS
	*/
	
	/*  this function written by M. Bogner  06/21/2013  */
	
		begin
		return_value := NULL;
        
        /* build the query based on passed parameters  */
		l_statement :=
		' select count(*) from ' || p_table_selector  || ' where  ' ||
		' site_datatype_id = ' || to_char(P_SDI) || ' and ' ||
		' start_date_time >= ' || 
        ' greatest(trunc(to_date(''' || to_char(P_EFF_DATE,'dd-MON-YYYY HH24:MI') || ''',''dd-MON-YYYY HH24:MI'')),' ||
        ' to_date(''' || to_char(P_EFF_DATE,'dd-MON-YYYY HH24:MI') || ''',''dd-MON-YYYY HH24:MI'') - (' || to_char(P_HOURS_BACK) || '/24)) ' || 
		' and start_date_time < ' ||
		' to_date(''' || to_char(P_EFF_DATE,'dd-MON-YYYY HH24:MI') || ''',''dd-MON-YYYY HH24:MI'')' ||
        ' and value > ' || to_char(P_LIMIT_VALUE);

		/* now execute this dynamic sql select statement */
    	execute immediate (l_statement) INTO return_value;
		
		exception when others then return_value := NULL;
		end;
		
	   return (return_value);
--	   return (rtrim(l_statement));
	END;

/

create or replace public synonym PLVE for PLVE;
BEGIN EXECUTE IMMEDIATE 'grant execute on PLVE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./FUNCTIONS/gscm.func
create or replace
function gscm 
(
  site in number,  
  attr in number,
  mon in date default sysdate,
  idx in number DEFAULT 1,
  eff_date in date default sysdate
) return number IS
return_value NUMBER;
begin
/* this function returns the coefficient value in the ref_site_coef_month table
with the input site, attribute id, month, index, and effective date
  why is effective date a required column in ref_site_coef_month, if it's not in the PK?
*/

/*  this function written by A. Gilmore  07/03/2013, shamelessly stolen from Mark...  */
begin
  return_value := NULL;
  select a.coef  into return_value
  from ref_site_coef_month a
  where a.site_id = site
    and a.attr_id = attr
    and a.month = extract(MONTH from mon)
    and a.coef_idx = idx
    and eff_date >= a.effective_start_date_time
    and eff_date <= nvl(a.effective_end_date_time,sysdate);

exception when others then return_value := NULL;
end;

return (return_value);
  
end gscm;

/

CREATE OR REPLACE PUBLIC SYNONYM gscm for gscm;
BEGIN EXECUTE IMMEDIATE 'grant execute on gscm to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./FUNCTIONS/CFS2ACFT.func
CREATE OR REPLACE FUNCTION CFS2ACFT (cfs in NUMBER)
return NUMBER
IS

BEGIN

   return (cfs * (86400/43560));


END;
/

-- show errors;
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON CFS2ACFT TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./FUNCTIONS/GET_HDB_SITE_COMMON_NAME.func
CREATE OR REPLACE FUNCTION GET_HDB_SITE_COMMON_NAME (site_no in NUMBER)
return VARCHAR2
IS

  object_name VARCHAR2(240);
BEGIN

   SELECT site_common_name into object_name
   FROM hdb_site
   WHERE site_id = site_no;

   if object_name = null then object_name := ' '; end if;

   return (object_name);


END;
/

-- show errors;
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON GET_HDB_SITE_COMMON_NAME TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./FUNCTIONS/GET_HDB_SITE_NAME.func
CREATE OR REPLACE FUNCTION GET_HDB_SITE_NAME (site_no in NUMBER)
return VARCHAR2
IS

  object_name VARCHAR2(240);
BEGIN

   SELECT site_name into object_name
   FROM hdb_site
   WHERE site_id = site_no;

   if object_name = null then object_name := ' '; end if;

   return (object_name);


END;
/

-- show errors;
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON GET_HDB_SITE_NAME TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./FUNCTIONS/GET_PK_VAL_WRAP.func
CREATE OR REPLACE FUNCTION GET_PK_VAL_WRAP ( table_name IN  VARCHAR2, set_pkval IN BOOLEAN ) RETURN number IS

	new_pk_val number(11) := NULL;

 BEGIN
   IF table_name LIKE 'HDB%' THEN
    	new_pk_val := populate_pk_hdb.get_pk_val (table_name, set_pkval);
   ELSE
        new_pk_val := populate_pk_ref.get_pk_val (table_name, set_pkval);
   END IF;

   return new_pk_val;
 END get_pk_val_wrap;
/

-- show errors;
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON GET_PK_VAL_WRAP TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./FUNCTIONS/GSNA.func
create or replace FUNCTION GSNA(
	  P_SITE_ID NUMBER,P_ATTR_ID NUMBER,P_EFF_DATE DATE DEFAULT sysdate)
	RETURN FLOAT IS
		return_value FLOAT;
	BEGIN
	/* this function returns the Numeric value in the ref_site_attr table
	with the input site, attribute id, and effective date
	*/

	/*  this function written by M. Bogner  11/15/2012 */
		begin
		return_value := NULL;
		select a.value  into return_value
		  from ref_site_attr a
		  where a.site_id = P_SITE_ID
		  and a.attr_id = P_ATTR_ID
		  and P_EFF_DATE >= a.effective_start_date_time
		  and P_EFF_DATE < nvl(a.effective_end_date_time,sysdate+365000);

		exception when others then return_value := NULL;
		end;

	   return (return_value);
	END;
/
-- show errors;
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON GSNA TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./FUNCTIONS/timesteps_between.func
CREATE OR REPLACE FUNCTION TIMESTEPS_BETWEEN (start_date_time IN DATE,
                                            end_date_time IN DATE,
                                            interval VARCHAR2 DEFAULT 'day',
                                            minutes IN INTEGER DEFAULT 1440)
RETURN date_array
PIPELINED

/*  This function returns a list of datetimes beginning at the
      specified start_date, spaced at the specified interval,
      and ending at the specified end time.

    Change Log:
    23MAY2008: dates_between and instants_between written by Andrew Gilmore
    07FEB2017: consolidated 2 functions into 1 and added logic to 'snap' dates
                based on the selected interval, jrocha
    24JAN2018: Hour and day intervals have open end intervals like the rest
*/

IS
end_date DATE := end_date_time;
start_date DATE := start_date_time;
dates date_object := date_object(NULL);
temp_chars VARCHAR2(30);
intervalsperday NUMBER := 1440 / minutes;

BEGIN
  IF end_date < start_date THEN
    deny_action('End date must come after start date!');
  END IF;

  BEGIN
    SELECT interval_name
    INTO temp_chars
    FROM hdb_interval
    WHERE interval_name = interval;

  EXCEPTION WHEN others THEN
    deny_action('Dates between function INVALID ' || interval || ' interval');
  END;

  CASE interval
  WHEN 'instant' THEN
    IF end_date_time < start_date_time THEN
      deny_action('End date must be after start date!');
    END IF;
    FOR i IN 0 .. (end_date - start_date) * (intervalsperday) - 1
    LOOP
      dates.date_time := start_date_time + i / intervalsperday;
      pipe ROW(dates);
    END LOOP;

  WHEN 'hour' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate, 'HH24') + 1 / 24;
    END IF;
    FOR i IN 0 ..(end_date - start_date) * 24 - 1
    LOOP
      dates.date_time := start_date_time + i / 24;
      pipe ROW(dates);
    END LOOP;

  WHEN 'day' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate,   'DD') + 1;
    END IF;
    FOR i IN 0 ..(end_date -start_date) - 1 
    LOOP
      dates.date_time := start_date_time + i;
      pipe ROW(dates);
    END LOOP;

  WHEN 'month' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate, 'MM');
    END IF;
    /* months_between takes the later date first */
    start_date := TRUNC(start_date, 'MM');
    end_date := TRUNC(end_date, 'MM');
    FOR i IN 0 .. months_between(end_date, start_date)
    LOOP
      dates.date_time := add_months(start_date, i);
      pipe ROW(dates);
    END LOOP;

  WHEN 'year' THEN
    IF end_date IS NULL THEN
      end_date := TRUNC(sysdate, 'YYYY');
    END IF;
    /* months_between takes the later date first */
    start_date := TRUNC(start_date, 'YYYY');
    end_date := TRUNC(end_date, 'YYYY');
    FOR i IN 0 .. months_between(end_date, start_date) / 12
    LOOP
      dates.date_time := add_months(start_date, i * 12);
      pipe ROW(dates);
    END LOOP;

  WHEN 'wy' THEN
    IF end_date IS NULL THEN
      end_date := add_months(TRUNC(sysdate, 'YYYY'), -3);
    END IF;
    /* months_between takes the later date first */
    start_date := add_months(TRUNC(start_date, 'YYYY'), 9);
    end_date := add_months(TRUNC(end_date, 'YYYY'), 9);
    FOR i IN 0 .. months_between(end_date, start_date) / 12
    LOOP
      dates.date_time := add_months(start_date, i * 12);
      pipe ROW(dates);
    END LOOP;
  END CASE;

  RETURN;
END timesteps_between;
/

-- show errors
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON TIMESTEPS_BETWEEN TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM TIMESTEPS_BETWEEN FOR TIMESTEPS_BETWEEN;
-- Expanding: ./FUNCTIONS/GET_TS_XFER_DATA.func
CREATE OR REPLACE FUNCTION GET_TS_XFER_DATA (p_sdi IN NUMBER,p_sdate IN date,p_edate IN date,p_interval IN VARCHAR2,p_REAL_OR_MODEL IN VARCHAR2,p_MRI_OR_INTERVAL IN number) RETURN t_tf_tab PIPELINED AS

  SDI NUMBER;
  START_DATE DATE;
  END_DATE DATE;
  INTERVAL VARCHAR2(16);
  DATES DATEARRAY;
  TS_VALUES NUMBER_ARRAY;
  REAL_OR_MODEL VARCHAR2(200);
  MRI_OR_INTERVAL NUMBER;
BEGIN
  SDI := p_sdi;
  START_DATE := p_sdate; 
  END_DATE := p_edate;
  INTERVAL := p_interval;
  REAL_OR_MODEL := p_REAL_OR_MODEL;
  MRI_OR_INTERVAL := p_MRI_OR_INTERVAL;

  TS_XFER.GET_DATA(
    SDI => SDI,
    START_DATE => START_DATE,
    END_DATE => END_DATE,
    INTERVAL => INTERVAL,
    DATES => DATES,
    TS_VALUES => TS_VALUES,
    REAL_OR_MODEL => REAL_OR_MODEL,
    MRI_OR_INTERVAL => MRI_OR_INTERVAL
  );
 
FOR indx IN 1 .. DATES.COUNT 
        LOOP
    --DBMS_OUTPUT.PUT_LINE(DATES(indx) || ' ' || TS_VALUES(indx));
    PIPE ROW(t_tf_row(DATES(indx), TS_VALUES(indx)));  
        END LOOP;
  RETURN;
END;
/
-- show errors
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON GET_TS_XFER_DATA TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM GET_TS_XFER_DATA FOR GET_TS_XFER_DATA;
-- Expanding: ./FUNCTIONS/get_min_max_annotation.func
CREATE OR REPLACE FUNCTION GET_MIN_MAX_ANNOTATION 
  (sdi IN integer,
   year IN varchar2,
   value_in IN float)
  RETURN varchar2
IS
  date_string VARCHAR2(50);
  min_date DATE;
  max_date DATE;
  value_count INTEGER;
BEGIN

  SELECT count(value), min(start_date_time), max(start_date_time)
  INTO value_count, min_date, max_date
  FROM r_day
  WHERE to_char (start_date_time,'yyyy') = year
    AND site_datatype_id = sdi
    AND value = value_in;

  IF value_count = 0 THEN
    date_string := 'ERROR';
  ELSIF value_count = 1 THEN
    date_string := to_char(min_date,'FMMonth DD');
  ELSIF value_count = 2 THEN
    IF (to_char(min_date,'mm') = to_char(max_date,'mm')) THEN
      date_string := to_char(min_date,'FMMonth DD')||', '|| to_char(max_date,'FMDD');
    ELSE
      date_string := to_char(min_date,'FMMonth DD')||', '|| to_char(max_date,'FMMonth DD');
    END IF;
  ELSIF (max_date - min_date + 1 = value_count) THEN
    IF (to_char(min_date,'mm') = to_char(max_date,'mm')) THEN
      date_string := to_char(min_date,'FMMonth DD')||' - '|| to_char(max_date,'FMDD');
    ELSE
      date_string := to_char(min_date,'FMMonth DD')||' - '|| to_char(max_date,'FMMonth DD');
    END IF;
  ELSE
    date_string := 'numerous occasions';
  END IF;

  return (date_string);
END;
/

-- show errors
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON GET_MIN_MAX_ANNOTATION TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM GET_MIN_MAX_ANNOTATION FOR GET_MIN_MAX_ANNOTATION;
-- Expanding: ./FUNCTIONS/find_rating.func
CREATE OR REPLACE FUNCTION FIND_RATING 
( rating_type in varchar2
, indep_sdi in number
, value_date_time in date default null
) return number is
rating number;
begin

  select rating_id into rating
  from ref_site_rating
  where
  indep_site_datatype_id = indep_sdi and
  rating_type_common_name = rating_type and
  value_date_time between effective_start_date_time and effective_end_date_time;

  if rating is null
  then rating := -1;
  end if;
  
  return rating;
  
end find_rating;
/

-- show errors
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON FIND_RATING TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM FIND_RATING FOR FIND_RATING;
-- Expanding: ./FUNCTIONS/is_role_granted.func
create or replace FUNCTION IS_ROLE_GRANTED 
(
  ROLE_NAME IN VARCHAR2 
) RETURN BOOLEAN AS 
/*
   Replacement for the now-broken behavior of DBMS_SESSION.Is_Role_Enabled
   Per Oracle 12cR2 docs: "All roles are disabled in any named PL/SQL block that executes with definer's rights."
https://docs.oracle.com/en/database/oracle/oracle-database/12.2/dbseg/configuring-privilege-and-role-authorization.html#GUID-5C57B842-AF82-4462-88E9-5E9E8FD59874
   We can only check that the current user is granted the specified role as default, we cannot check if they have the role
   actually enabled!

    Written February 24, 2018 by Andrew Gilmore
*/
    is_valid_role   NUMBER;
BEGIN
    BEGIN
    SELECT
        COUNT(*)
    INTO        is_valid_role
    FROM        user_role_privs
    WHERE       default_role = 'YES'
        AND   granted_role IN (ROLE_NAME);
   return is_valid_role>0;
   EXCEPTION WHEN OTHERS THEN RETURN FALSE;  
   END;
END IS_ROLE_GRANTED;
/
-- show errors
BEGIN EXECUTE IMMEDIATE '
GRANT EXECUTE ON IS_ROLE_GRANTED TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM IS_ROLE_GRANTED FOR IS_ROLE_GRANTED;

-- spool off
-- exit;
-- set echo on
-- set feedback on
-- spool hdb_procedures.out

-- Expanding: ./PROCEDURES/check_sdi_auth.prc
create or replace procedure check_sdi_auth (sdi number)
IS
cur_site number;
cursor c1 (c_site NUMBER) is
    select role from ref_auth_site where site_id = c_site;
cursor c2 (c_sdi NUMBER) is
    select role from ref_auth_site_datatype where site_datatype_id = c_sdi;
result VARCHAR2(24);
BEGIN
    select site_id INTO cur_site FROM hdb_site_datatype
    where site_datatype_id = sdi;
    if (is_role_granted ('APP_ROLE')) then
        return;
    end if;
    if (is_role_granted ('SAVOIR_FAIRE')) then
        return;
    end if;
    for role_record IN c1(cur_site) LOOP
        result := role_record.role;
        if (is_role_granted (rtrim(result))) then
            return;
        end if;
    end LOOP;
    for role_record IN c2(sdi) LOOP
        result := role_record.role;
        if (is_role_granted (rtrim(result))) then
            return;
        end if;
    end LOOP;
    raise_application_error(-20001,'Error: Could not select from ref_auth_site_datatype with site_datatype_id = ' || sdi);
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_sdi_auth to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_sdi_auth_with_site.prc
create or replace procedure check_sdi_auth_with_site (sdi number, cur_site number)
IS
cursor c1 (c_site NUMBER) is
    select role from ref_auth_site where site_id = c_site;
cursor c2 (c_sdi NUMBER) is
    select role from ref_auth_site_datatype where site_datatype_id = c_sdi;
result VARCHAR2(24);
BEGIN
    if (is_role_granted ('APP_ROLE')) then
        return;
    end if;
    if (is_role_granted ('SAVOIR_FAIRE')) then
        return;
    end if;
    for role_record IN c1(cur_site) LOOP
        result := role_record.role;
        if (is_role_granted (rtrim(result))) then
            return;
        end if;
    end LOOP;
    for role_record IN c2(sdi) LOOP
        result := role_record.role;
        if (is_role_granted (rtrim(result))) then
            return;
        end if;
    end LOOP;
    raise_application_error(-20001,'Error: Could not select from ref_auth_site_datatype with site_datatype_id = ' || sdi);
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_sdi_auth to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_site_id_auth.prc
create or replace procedure check_site_id_auth (cur_site number,
	the_user VARCHAR2, the_app_user VARCHAR2)
IS
cursor c1 (c_site NUMBER) is
    select role from ref_auth_site where site_id = c_site;

result VARCHAR2(24);
is_valid_role NUMBER;
BEGIN
    if (is_role_granted ('APP_ROLE') OR
	is_role_granted ('SAVOIR_FAIRE')) then
        return;
    end if;

    for role_record IN c1(cur_site) LOOP
        result := role_record.role;

	if (the_user = 'APEX_PUBLIC_USER') then
	  select count(*)
	  into is_valid_role
	  from dba_role_privs
	  where grantee = the_app_user
	    and granted_role = result
            and default_role = 'YES';

  	  /* the user logged into APEX has permissions */
 	  if (is_valid_role > 0) then
	    return;
	  end if;
	else
  	  /* the user connected to the db has permissions;
	     could use the check from above, but this is a bit
	     better as it checks for what is active, not just granted */
          if (is_role_granted (rtrim(result))) then
              return;
          end if;
        end if;
    end LOOP;
    raise_application_error(-20001, 'Permission Failure: User '||the_app_user||' does not have role permissions to modify values for site_id = ' || cur_site);
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_site_id_auth to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_valid_attr_value.prc
create or replace procedure check_valid_attr_value (cur_attr_id number, cur_value float, cur_string_value varchar2, cur_date_value date)
IS
    cur_attr_value_type varchar2(10);
BEGIN
    SELECT attr_value_type 
	INTO cur_attr_value_type
	FROM hdb_attr
	WHERE attr_id = cur_attr_id;

    if cur_attr_value_type = 'number' then
	if (cur_value is null OR cur_string_value is not null OR cur_date_value is not null) then
	   raise_application_error (-20001,'Attr_value_type is ' || cur_attr_value_type || '. Value must be NOT NULL; string_value and date_value must be NULL.');
        end if;
    elsif cur_attr_value_type = 'string' then
	if (cur_string_value is null OR cur_value is not null OR cur_date_value is not null) then
	   raise_application_error (-20002,'Attr_value_type is ' || cur_attr_value_type || '. String_value must be NOT NULL; value and date_value must be NULL.');
        end if;
    else
	if (cur_date_value is null OR cur_value is not null OR cur_string_value is not null) then
	   raise_application_error (-20003,'Attr_value_type is ' || cur_attr_value_type || '. Date_value must be NOT NULL; value and string_value must be NULL.');
        end if;
    end if;
END;
/
-- show errors;
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_attr_value to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM check_valid_attr_value for check_valid_attr_value;
-- Expanding: ./PROCEDURES/check_valid_site_objtype.prc
create or replace procedure check_valid_site_objtype (cur_objecttype_tag varchar2, cur_site_id number)
IS
    check_val number;
BEGIN
        SELECT count(*) INTO check_val FROM hdb_site a, hdb_objecttype b WHERE a.site_id = cur_site_id AND a.objecttype_id = b.objecttype_id AND b.objecttype_tag = cur_objecttype_tag;
    if check_val < 1 then
        SELECT count(*) INTO check_val FROM hdb_site WHERE site_id = cur_site_id;
        if check_val < 1 then
            raise_application_error(-20001,'No site_id = ' || cur_site_id ||  ' in hdb_site');
        end if;
        raise_application_error(-20002,'Objecttype ' || cur_objecttype_tag ||' is inappropriate for site_id = ' || cur_site_id);
    end if;
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_site_objtype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_valid_site_ot_id.prc
create or replace procedure check_valid_site_ot_id (cur_objecttype_id number, cur_site_id number)
IS
    check_val number;
BEGIN
    SELECT count(*) INTO check_val FROM hdb_site WHERE site_id = cur_site_id AND objecttype_id = cur_objecttype_id;
    if check_val < 1 then
        SELECT count(*) INTO check_val FROM hdb_site WHERE site_id = cur_site_id;
        if check_val < 1 then
            raise_application_error (-20001,'No site_id = ' || cur_site_id || ' in hdb_site.');
        end if;
        raise_application_error (-20002,'Objecttype_id ' || cur_objecttype_id || ' is inappropriate for site_id = ' || cur_site_id);
    end if;
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_site_ot_id to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_valid_datatype.prc
create or replace procedure check_valid_datatype(cur_datatype_id number,
						 source_datatype_id number)
IS
     check_val   number;
     check_val2  number;
begin
     select count(*) into check_val from hdb_datatype
            where  hdb_datatype.datatype_id = cur_datatype_id;
     if  SQL%NOTFOUND then
        raise_application_error(-20001,'Error: Error selecting from hdb_datatype with datatype_id = ' || cur_datatype_id);
     end if;
     if check_val < 1 then
        raise_application_error(-20002,'Integrity Failure: No datatype_id = ' || cur_datatype_id);
     end if;
     /* now check to see if dimension of source and destination datatype_ids
	match, or if one is flow and the other volume, or one is power
	and the other is energy. */
     select count(*) into check_val2
     from hdb_datatype a, hdb_datatype b, hdb_unit aa, hdb_unit bb, 
	hdb_dimension aaa, hdb_dimension bbb
     where a.datatype_id = source_datatype_id
       and a.unit_id = aa.unit_id
       and aa.dimension_id = aaa.dimension_id
       and b.datatype_id = cur_datatype_id
       and b.unit_id = bb.unit_id
       and bb.dimension_id = bbb.dimension_id
       and (aaa.dimension_id = bbb.dimension_id OR
	    (aaa.dimension_name in ('flow', 'volume') AND
	     bbb.dimension_name in ('flow', 'volume')) OR
	    (aaa.dimension_name in ('energy', 'power') AND
	     bbb.dimension_name in ('energy', 'power')));
     if  SQL%NOTFOUND then
        raise_application_error(-20001,'Error: Error selecting from hdb_datatype with datatype_id = ' || cur_datatype_id || ' or ' || source_datatype_id);
     end if;
     if check_val2 < 1 then
        raise_application_error(-20002,'Integrity Failure: Source and destination datatypes must have same dimension_id, or they must be flow and volume OR power and energy');
     end if;
end;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_datatype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_valid_noop.prc
create or replace procedure
     check_valid_noop (source_observation number, dest_observation number)
IS
         msg                      varchar2(200);
         cur_source_observation   number;
         cur_dest_observation     number;
BEGIN
         cur_source_observation := source_observation;
         cur_dest_observation   := dest_observation;
         if (source_observation <> dest_observation) then
             raise_application_error(-20001,'Error: When no operator, source and  destination intervals must be equal');
         end if;
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_noop to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_valid_property_value.prc
create or replace procedure check_valid_property_value (cur_property_id number, cur_value float, cur_string_value varchar2, cur_date_value date)
IS
    cur_property_value_type varchar2(10);
BEGIN
    SELECT property_value_type 
	INTO cur_property_value_type
	FROM hdb_property
	WHERE property_id = cur_property_id;

    if cur_property_value_type = 'number' then
	if (cur_value is null OR cur_string_value is not null OR cur_date_value is not null) then
	   raise_application_error (-20001,'Property_value_type is ' || cur_property_value_type || '. Value must be NOT NULL; string_value and date_value must be NULL.');
        end if;
    elsif cur_property_value_type = 'string' then
	if (cur_string_value is null OR cur_value is not null OR cur_date_value is not null) then
	   raise_application_error (-20002,'Property_value_type is ' || cur_property_value_type || '. String_value must be NOT NULL; value and date_value must be NULL.');
        end if;
    else
	if (cur_date_value is null OR cur_value is not null OR cur_string_value is not null) then
	   raise_application_error (-20003,'Property_value_type is ' || cur_property_value_type || '. Date_value must be NOT NULL; value and string_value must be NULL.');
        end if;
    end if;
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_property_value to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM check_valid_property_value for check_valid_property_value;
-- start ./PROCEDURES/check_valid_agg_disagg_method.prc; removed for CP Project 10/2022
-- Expanding: ./PROCEDURES/check_valid_unit.prc
create or replace procedure check_valid_unit(cur_unit_id number)
IS
     check_val   number;
begin
     select count(*) into check_val from hdb_unit
            where  hdb_unit.unit_id = cur_unit_id;
     if  SQL%NOTFOUND then
        raise_application_error(-20001,'Error: Error selecting from hdb_unit with unit_id = ' || cur_unit_id);
     end if;
     if check_val < 1 then
        raise_application_error(-20002,'Integrity Failure: No unit_id = ' || cur_unit_id);
     end if;
end;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on  check_valid_unit to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/check_valid_unit_spec.prc
create or replace procedure
          check_valid_unit_spec
              (is_factor             integer,
               factor                float,
               from_expression       varchar2,
               to_expression         varchar2,
               month_year            varchar2,
               over_month_year       varchar2)
IS
               check_val integer;
BEGIN
      if ((is_factor <> 0) and (is_factor <> 1)) then
         raise_application_error(-20001, 'Integrity Failure: Illegal value for is_factor = ' || is_factor);
      end if;
      if ((is_factor = 1) and (factor is null)) then
         raise_application_error(-20003, 'Integrity Failure: Null mult_factor when is_factor = 1');
      end if;
      if ((is_factor = 0) AND
          (from_expression is null OR
           to_expression   is null)) then
         raise_application_error(-20003, 'Integrity Failure: Null expression when is_factor = 0');
      end if;
      if( month_year      IS NOT NULL AND
          over_month_year IS NOT NULL) then
          raise_application_error(-20004, 'Integrity Failure: Month_year and over_month_year cannot both be set');
      end if;
      if ((month_year <> 'M') AND
          (month_year <> 'Y') AND
          (month_year <> 'W')) then
           raise_application_error(-20005, 'Integrity Failure: Month_year must have value of M, Y or W');
      end if;
      if ((over_month_year <> 'M') AND
          (month_year <> 'Y') AND
          (month_year <> 'W')) then
           raise_application_error(-20006, 'Integrity Failure: Over_month_year must have value of M, Y or W');
      end if;
end;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on check_valid_unit_spec to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/deny_action.prc
create or replace procedure deny_action (text varchar2)
IS
              check_val integer;
BEGIN
      raise_application_error(-20001, '"' || text || '"');
END;
/
-- show errors;
/
BEGIN EXECUTE IMMEDIATE 'grant execute on deny_action to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/
-- Expanding: ./PROCEDURES/delete_r_base.prc
CREATE OR REPLACE PROCEDURE delete_r_base ( SITE_DATATYPE_ID_IN NUMBER,                       
			  INTERVAL_IN VARCHAR2,                                                      
			  START_DATE_TIME_IN DATE,                                                   
			  END_DATE_TIME_IN DATE,                                                     
			  AGEN_ID_IN NUMBER,                                                         
			  LOADING_APPLICATION_ID_IN NUMBER)                                                 
IS                                                                              
old_agen_id NUMBER;   
old_loading_application_id NUMBER;
old_priority number := 0;                                                       
new_priority NUMBER := 0;
old_overwrite_flag VARCHAR2(1);
                                                       
BEGIN                                                                           

/* The calling procedure must check that a delete is required */
/* modified 29-November-2007 by M. Bogner to take out manual editing feature
   and to not raise exception if a delete was issued and no record existed  */
/* Modified 10-AUG-2011 by M. Bogner to not allow any deletion for a record 
   with the overwrite flag set  */
                                                                                
/* Data priority determination - delete the database row only if
   --  (both old and new rows have priority, and new is higher (closer to 0)
   --   OR new row has the same agen_id as the old row)) */

                                                                                
    BEGIN
	select nvl(priority_rank,0)
          into new_priority                                                     
	  from ref_source_priority                                                     
	 where site_datatype_id = SITE_DATATYPE_ID_IN                                  
	   and agen_id = AGEN_ID_IN;                                                   
 	exception when others THEN null; /*not an error to not have entry for this agency and sdi*/                                                                   
                                                                                
    end;                                                                        

    begin /* get the old agency and priority and the overwrite flag` */ 
          /* if overrwite flag is null then return a 'N'             */                        
        SELECT nvl(b.priority_rank,0), a.agen_id, a.loading_application_id, nvl(a.overwrite_flag,'N')
    	  INTO old_priority, old_agen_id, old_loading_application_id, old_overwrite_flag
    	  FROM r_base a, ref_source_priority b                                     
    	 WHERE a.site_datatype_id = site_datatype_id_in                            
    	   AND a.INTERVAL = interval_in                                            
    	   AND a.start_date_time = start_date_time_in                              
    	   and a.end_date_time = END_DATE_TIME_IN                                  
    	   and a.agen_id = b.agen_id(+)                                            
    	   and a.site_datatype_id = b.site_datatype_id(+);                         
       exception when others THEN null; /*not an error to attempt to delete something that doesn't exist  */
    end;                                                                        
	
                                                                        
/* DO THE DELETE IF:*/                                                          
	 IF (( old_overwrite_flag = 'N') AND (((old_priority >= new_priority) AND (old_priority > 0 and new_priority > 0)) OR 
 	   (agen_id_in = old_agen_id)))
     THEN
	 BEGIN
      DELETE FROM R_BASE                                                               
      WHERE site_datatype_id = SITE_DATATYPE_ID_IN                               
       AND interval = INTERVAL_IN                                              
       AND start_date_time = START_DATE_TIME_IN                                 
       and end_date_time = END_DATE_TIME_IN;                                    
      exception when others THEN null; /*not an error to attempt to delete something that doesn't exist  */
     END;  /* begin of the delete statement */

    ELSE                                                                        
	NULL; /* delete was not done*/                                                 
    END IF;                                                                     
                                                                                
END;
/
 
-- show errors;
/
create or replace public synonym delete_r_base for delete_r_base;
BEGIN EXECUTE IMMEDIATE 'grant execute on delete_r_base to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

 
-- Expanding: ./PROCEDURES/update_r_base_raw.prc
-- PROMPT CREATE or REPLACE PROCEDURE update_r_base_raw

create or replace PROCEDURE update_r_base_raw ( SITE_DATATYPE_ID_IN NUMBER,
			  INTERVAL_IN VARCHAR2,
			  START_DATE_TIME_IN DATE,
			  END_DATE_TIME_IN DATE,
			  VALUE_IN FLOAT,
			  AGEN_ID_IN NUMBER,
			  OVERWRITE_FLAG_IN VARCHAR2,
			  VALIDATION_IN CHAR,
			  COLLECTION_SYSTEM_ID_IN NUMBER,
			  LOADING_APPLICATION_ID_IN NUMBER,
			  METHOD_ID_IN NUMBER,
			  COMPUTATION_ID_IN NUMBER,
			  DATA_FLAGS_IN VARCHAR2,
			  DATE_TIME_IN DATE )
IS
old_priority number := 0;
new_priority NUMBER := 0;
old_value FLOAT := 0;
old_overwrite_flag VARCHAR2 (1);
old_validation CHAR;
old_collection_system_id NUMBER;
old_loading_application_id NUMBER;
old_method_id NUMBER;
old_computation_id NUMBER;
old_data_flags R_BASE.DATA_FLAGS%TYPE;
epsilon FLOAT := 1E-7;
do_update boolean := false;
data_changed boolean := false;
BEGIN
    /*  Modified by M.  Bogner  6/21/07  to add the data quality flags column to r_base */
    /*  Modified by M.  Bogner  11/19/07  to remove the manual edit criteria */
    /*  Modified by M.  Bogner  05/22/08  to keep old records from update when previous data coming in  */
    /*  Modified by M.  Bogner  07/28/08  to allow overwrites to go in regardless  */
    /*  Modified by M.  Bogner  10/26/08  to allow overwrites to to be removed by same application  */
    
/* The calling procedure must check that an update is required, and that only one row is affected. */
/* Data priority determination. */
/* Old and new priorities default to 0, if no priorities are found in the following queries,
   then the priority of the old data and new data will be considered equal.
   This means that data from an agency with a defined priority will not overwrite data from an agency without priority.
*/
    begin
	select nvl(priority_rank,0)
          into new_priority
	  from ref_source_priority
	 where site_datatype_id = SITE_DATATYPE_ID_IN
	   and agen_id = AGEN_ID_IN;
 	exception when others THEN new_priority := 0; /*not an error to not have entry for this agency and sdi*/
    end;

    begin /* get the old foreign keys and priorities */
        SELECT nvl(priority_rank,0), a.value, nvl(a.overwrite_flag,'N'),
               nvl(a.validation,'x'), a.collection_system_id, a.loading_application_id,
               a.method_id, a.computation_id, nvl(a.data_flags,'x')
    	  INTO old_priority, old_value, old_overwrite_flag,
    	       old_validation, old_collection_system_id, old_loading_application_id,
    	       old_method_id, old_computation_id, old_data_flags
    	  FROM r_base a, ref_source_priority b
    	 WHERE a.site_datatype_id = site_datatype_id_in
    	   AND a.INTERVAL = interval_in
    	   AND a.start_date_time = start_date_time_in
    	   and a.end_date_time = END_DATE_TIME_IN
    	   and a.agen_id = b.agen_id(+)
    	   and a.site_datatype_id = b.site_datatype_id(+);
    end;

   /* check to see if any real major data columns have been modified */
   IF ( abs(old_value - value_in) > epsilon    -- and value is different (difference larger than epsilon!
        or nvl(overwrite_flag_in,'N') != old_overwrite_flag  -- or one of the foreign keys (except agen_id) is different
        or collection_system_id_in != old_collection_system_id
        or loading_application_id_in != old_loading_application_id
        or method_id_in != old_method_id
        or computation_id_in != old_computation_id ) then
     data_changed := true;  
   END IF;                          

/* DO THE UPDATE IF:*/
    IF (nvl(overwrite_flag_in,'N') = 'O'                    -- the new record is now an overwrite
    OR  (old_overwrite_flag = 'N'                           -- the old was not
	    and ((new_priority < old_priority                   -- and the new priority is higher (closer to 0) than the old
                  and new_priority > 0)                         -- but not 0, since 0 is default or no priority
                 or (new_priority = old_priority                -- or agencies have same priority
                     AND ( data_changed
                          or nvl(validation_in,'x') != old_validation
                          or nvl(data_flags_in,'x') != old_data_flags )
                    )
                )
        )
       )         
    then
      do_update := true;
    END IF;

   /* check to see if this is just a call from the same application to change the overwrite flag */
   IF ( data_changed                                         -- obviously something is different record 
		and NOT do_update                                    -- but did not pass all the overwirites and priorities
        and abs(old_value - value_in) <= epsilon             -- and the value is the same
        and nvl(overwrite_flag_in,'N') != old_overwrite_flag  -- only the overwrite_flag is different
        and collection_system_id_in = old_collection_system_id -- and the rest of the identifiers are the same
        and loading_application_id_in = old_loading_application_id
        and method_id_in = old_method_id
        and computation_id_in = old_computation_id 
        and nvl(overwrite_flag_in,'N') != 'O' )
      then
     /* then this is a call to just change the overwrite flag back to nothing, so allow it */
     do_update := true;
   END IF;                          

/* now check to see if the only difference coming in was based on Hydromet data movements and the
   validation code may have changed via validation. This modification done 22 May 2008 to fix
   issues where we were updating r_base but the only reason was we previously validated, or moved the 
   hydromet codes to the data_flags column when really the exact same input data was received  */
/*   
  IF ( do_update 
       and abs(old_value - value_in) <= epsilon
       and NOT data_changed 
       and nvl(validation_in,'x') in ('Z','E','+','-','w','n','|','^','~','x')
       and old_validation in ('V','F','L','H','x'))  THEN
     do_update := false;
  END IF;*/   

  /* after all the checks above then do update if do_update boolean is still true  */
  IF (do_update) THEN
    UPDATE R_BASE
       SET value = VALUE_IN,
	   agen_id = AGEN_ID_IN,
	   overwrite_flag = OVERWRITE_FLAG_IN,
	   validation = VALIDATION_IN,
	   collection_system_id = COLLECTION_SYSTEM_ID_IN,
	   loading_application_id = LOADING_APPLICATION_ID_IN,
	   method_id = METHOD_ID_IN,
	   computation_id = COMPUTATION_ID_IN,
	   data_flags = DATA_FLAGS_IN,
	   date_time_loaded = DATE_TIME_IN
     WHERE site_datatype_id = SITE_DATATYPE_ID_IN
       AND interval = INTERVAL_IN
       AND start_date_time = START_DATE_TIME_IN
       and end_date_time = END_DATE_TIME_IN;
   END IF;

END;
/

/* This procedure does not have execute permissions granted on purpose
   Only modify_r_base_raw should call it.  */

-- show errors;


-- Expanding: ./PROCEDURES/insert_r_base.prc
CREATE OR REPLACE PROCEDURE insert_r_base ( SITE_DATATYPE_ID NUMBER,
			  INTERVAL VARCHAR2,
			  START_DATE_TIME DATE,
			  END_DATE_TIME DATE,
			  VALUE FLOAT,
			  AGEN_ID NUMBER,
			  OVERWRITE_FLAG VARCHAR2,
			  VALIDATION CHAR,
			  COLLECTION_SYSTEM_ID NUMBER,
			  LOADING_APPLICATION_ID NUMBER,
			  METHOD_ID NUMBER,
			  COMPUTATION_ID NUMBER,
			  DATA_FLAGS VARCHAR2,
			  DATE_TIME DATE ) IS
BEGIN
    INSERT INTO R_BASE ( SITE_DATATYPE_ID,
			 INTERVAL,
			 START_DATE_TIME,
			 END_DATE_TIME,
			 VALUE,
			 AGEN_ID,
			 OVERWRITE_FLAG,
			 DATE_TIME_LOADED,
			 VALIDATION,
			 COLLECTION_SYSTEM_ID,
			 LOADING_APPLICATION_ID,
			 METHOD_ID,
			 COMPUTATION_ID,
			 DATA_FLAGS )
    VALUES ( SITE_DATATYPE_ID,
	     INTERVAL,
	     START_DATE_TIME,
	     END_DATE_TIME,
	     VALUE,
	     AGEN_ID,
	     OVERWRITE_FLAG,
	     DATE_TIME,
	     VALIDATION,
	     COLLECTION_SYSTEM_ID,
	     LOADING_APPLICATION_ID,
	     METHOD_ID,
	     COMPUTATION_ID,
	     DATA_FLAGS);
END;
/

-- show errors;
/
create or replace public synonym insert_r_base for insert_r_base;
BEGIN EXECUTE IMMEDIATE 'grant execute on insert_r_base to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./PROCEDURES/update_r_base.prc
CREATE OR REPLACE PROCEDURE update_r_base ( SITE_DATATYPE_ID_IN NUMBER,
			  INTERVAL_IN VARCHAR2,
			  START_DATE_TIME_IN DATE,
			  END_DATE_TIME_IN DATE,
			  VALUE_IN FLOAT,
			  AGEN_ID_IN NUMBER,
			  OVERWRITE_FLAG_IN VARCHAR2,
			  VALIDATION_IN CHAR,
			  COLLECTION_SYSTEM_ID_IN NUMBER,
			  LOADING_APPLICATION_ID_IN NUMBER,
			  METHOD_ID_IN NUMBER,
			  COMPUTATION_ID_IN NUMBER,
			  DATA_FLAGS_IN VARCHAR2 DEFAULT NULL,
			  DATE_TIME_IN DATE DEFAULT SYSDATE ) IS
    rowcount NUMBER;
BEGIN
    SELECT count ( * )
      INTO rowcount
      FROM r_base
     WHERE site_datatype_id = site_datatype_id_in
       AND INTERVAL = interval_in
       AND start_date_time = start_date_time_in
       and end_date_time = end_date_time_in;
    IF rowcount < 1 THEN
	DENY_ACTION ( 'UPDATE FAILED. RECORD with SDI: ' || to_char ( SITE_DATATYPE_ID_IN ) ||
      ' INTERVAL: ' || INTERVAL_IN || ' START_DATE_TIME: ' || to_char ( start_date_time_IN,
      'dd-MON-yyyy HH24:MI:SS' ) || ' DOES NOT EXIST.' );
    ELSIF  rowcount > 1 THEN
	DENY_ACTION ( 'UPDATE FAILED. RECORD with SDI: ' || to_char ( SITE_DATATYPE_ID_IN ) ||
      ' INTERVAL: ' || INTERVAL_IN || ' START_DATE_TIME: ' || to_char ( start_date_time_IN,
      'dd-MON-yyyy HH24:MI:SS' ) || ' END_DATE_TIME: '|| to_char ( end_date_time_IN,
      'dd-MON-yyyy HH24:MI:SS' ) || ' HAS MULTIPLE ENTRIES. DANGER! DANGER! DANGER!.' );
    END IF;

/*  Modified by M. Bogner for compatibility for derivation replacement coding  */

    UPDATE_R_BASE_RAW(SITE_DATATYPE_ID_IN,
		       INTERVAL_IN,
		       START_DATE_TIME_IN,
		       END_DATE_TIME_IN,
		       VALUE_IN,
		       AGEN_ID_IN,
		       OVERWRITE_FLAG_IN,
		       VALIDATION_IN,
        	       COLLECTION_SYSTEM_ID_IN,
		       LOADING_APPLICATION_ID_IN,
		       METHOD_ID_IN,
		       COMPUTATION_ID_IN,
		       DATA_FLAGS_IN,
		       DATE_TIME_IN );
END;
/

-- show errors;

create or replace public synonym update_r_base for update_r_base;
BEGIN EXECUTE IMMEDIATE 'grant execute on update_r_base to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/lookup_application.prc

create or replace procedure lookup_application
			   (  AGEN_NAME IN VARCHAR2,
			      COLLECTION_SYSTEM_NAME IN VARCHAR2,
			      LOADING_APPLICATION_NAME IN VARCHAR2,
			      METHOD_NAME IN VARCHAR2,
			      COMPUTATION_NAME IN VARCHAR2,
                              AGEN_ID IN OUT NUMBER,
                              COLLECTION_SYSTEM_ID IN OUT NUMBER,
                              LOADING_APPLICATION_ID IN OUT NUMBER,
                              METHOD_ID IN OUT NUMBER,
                              COMPUTATION_ID IN OUT NUMBER
                           ) IS

    TEMP_NAME VARCHAR2 ( 64 );
BEGIN
        /* First check all inputs */
    IF AGEN_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> AGEN_NAME' );
	ELSIF COLLECTION_SYSTEM_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> COLLECTION_SYSTEM_NAME' );
	ELSIF LOADING_APPLICATION_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> LOADING_APPLICATION_NAME' );
	ELSIF METHOD_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> METHOD_NAME' );
	ELSIF COMPUTATION_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> COMPUTATION_NAME' );
    END IF;

    BEGIN
	temp_name := AGEN_NAME;
	SELECT agen_id
	  INTO AGEN_ID
	  FROM hdb_agen
	 WHERE agen_name = temp_name;
	EXCEPTION
	    WHEN OTHERS THEN DENY_ACTION ( 'INVALID AGENCY NAME:' || AGEN_NAME );
    END;

    /* now go get the collection_system_id  */
    BEGIN
	temp_name := collection_system_name;
	SELECT collection_system_ID
	  INTO COLLECTION_SYSTEM_ID
	  FROM hdb_collection_system
	 WHERE collection_system_name = TEMP_NAME;
	EXCEPTION
	    WHEN OTHERS THEN DENY_ACTION ( 'INVALID COLLECTION SYSTEM NAME:' || COLLECTION_SYSTEM_NAME );
    END;

    /* now go get the loading_application_id  */
    BEGIN
	temp_name := LOADING_APPLICATION_NAME;
	SELECT loading_application_id
	  INTO LOADING_APPLICATION_ID
	  FROM hdb_loading_application
	 WHERE loading_application_name = TEMP_NAME;
	EXCEPTION
	    WHEN OTHERS THEN DENY_ACTION ( 'INVALID LOADING APPLICATION NAME:' || LOADING_APPLICATION_NAME );
    END;

    /* now go get the method_id  */
    BEGIN
	temp_name := METHOD_NAME;
	SELECT method_id
	  INTO METHOD_ID
	  FROM hdb_method
	 WHERE method_name = TEMP_NAME;
	EXCEPTION
	    WHEN OTHERS THEN DENY_ACTION ( 'INVALID METHOD NAME:' || METHOD_NAME );
    END;

    /* now go get the computation_id  */
    BEGIN
	temp_name := COMPUTATION_NAME;
	SELECT computation_id
	  INTO COMPUTATION_ID
	  FROM hdb_computed_datatype
	 WHERE computation_name = temp_name;
	EXCEPTION
	    WHEN OTHERS THEN DENY_ACTION ( 'INVALID COMPUTATION NAME:' || COMPUTATION_NAME );
    END;
END;

/

-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on lookup_application to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM lookup_application for lookup_application;
-- Expanding: ./PROCEDURES/lookup_hydromet_sdi.prc

create or replace procedure lookup_hydromet_sdi
                ( SITE_CODE IN VARCHAR2,
                  DATATYPE_PCODE IN VARCHAR2,
		  FILE_TYPE IN VARCHAR2,
                  SITE_DATATYPE_ID OUT NUMBER
                ) IS
/* now go get the sdi if its hydromet data  */
BEGIN
        IF SITE_CODE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_CODE' );
	        ELSIF DATATYPE_PCODE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> DATATYPE_PCODE' );
                ELSIF FILE_TYPE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> FILE TYPE FOR HYDROMET SITE CODE / P-CODES' );
        END IF;

        SELECT site_datatype_id
	        INTO SITE_DATATYPE_ID
                FROM ref_hm_site_pcode
                WHERE hm_site_code = SITE_CODE
                AND hm_pcode = DATATYPE_PCODE
                AND hm_filetype = FILE_TYPE;
	EXCEPTION
                WHEN OTHERS THEN DENY_ACTION ( 'INVALID SITE CODE: ' || SITE_CODE || ' and/or P-CODE: ' || DATATYPE_PCODE || ' COMBINATION FOR HYDROMET DATA' );
END;

/

-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on lookup_hydromet_sdi to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM lookup_hydromet_sdi for lookup_hydromet_sdi;
-- Expanding: ./PROCEDURES/lookup_sdi.prc

create or replace procedure lookup_sdi
                ( SITE_NAME IN VARCHAR2,
                  DATATYPE_NAME IN VARCHAR2,
                  SITE_DATATYPE_ID OUT NUMBER
                ) IS
BEGIN
        IF SITE_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_NAME' );
	        ELSIF DATATYPE_NAME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> DATATYPE_NAME' );
        END IF;
	
	SELECT site_datatype_id
	      INTO SITE_DATATYPE_ID
	      FROM hdb_site_datatype hsd,
		   hdb_site hs,
		   hdb_datatype hd
	     WHERE hsd.site_id = hs.site_id
	       AND hd.datatype_id = hsd.datatype_id
	       AND hs.site_name = SITE_NAME
	       AND hd.datatype_name = DATATYPE_NAME;
	EXCEPTION
		WHEN OTHERS THEN DENY_ACTION ( 'INVALID SITE NAME: ' || SITE_NAME || ' and/or DATATYPE NAME: ' || DATATYPE_NAME || ' COMBINATION' );
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on lookup_sdi to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM lookup_sdi for lookup_sdi;
-- Expanding: ./PROCEDURES/modify_r_base_raw.prc
create or replace PROCEDURE modify_r_base_raw ( SITE_DATATYPE_ID NUMBER,
			      INTERVAL VARCHAR2,
			      START_DATE_TIME DATE,
			      END_DATE_TIME IN OUT DATE,
			      VALUE FLOAT,
                  AGEN_ID NUMBER,
			      OVERWRITE_FLAG VARCHAR2,
			      VALIDATION CHAR,
                  COLLECTION_SYSTEM_ID NUMBER,
                  LOADING_APPLICATION_ID NUMBER,
                  METHOD_ID NUMBER,
                  COMPUTATION_ID NUMBER,
			      DO_UPDATE_Y_OR_N VARCHAR2,
			      DATA_FLAGS IN VARCHAR2 DEFAULT NULL,
			      TIME_ZONE        VARCHAR2 DEFAULT NULL ) IS
    TEMP_SDI R_BASE.SITE_DATATYPE_ID%TYPE;
    TEMP_INT R_BASE.INTERVAL%TYPE;
    TEMP_SDT R_BASE.START_DATE_TIME%TYPE;
    TEMP_EDT R_BASE.START_DATE_TIME%TYPE;
    START_DATE_TIME_NEW R_BASE.START_DATE_TIME%TYPE;
    END_DATE_TIME_NEW   R_BASE.END_DATE_TIME%TYPE;
    DATE_TIME_NEW       R_BASE.DATE_TIME_LOADED%TYPE;
    VALUE_NEW			R_BASE.VALUE%TYPE;
    VALIDATION_NEW		R_BASE.VALIDATION%TYPE;
    DATA_FLAGS_NEW		R_BASE.DATA_FLAGS%TYPE;
    ROWCOUNT NUMBER;
    db_timezone VARCHAR2(3);
    l_ts_id NUMBER;

BEGIN
    /*  Modified by M.  Bogner  6/21/07  to add the data quality flags column to r_base  */
    /*  Modified by M.  Bogner  8/28/07  to used the standardize dates procedure         */
    /*  Modified by M.  Bogner  10/27/08  to add the call to the pre-processor procedure */
	/*  Modified by M.  Bogner  06/01/2009 to add mods to accept different time_zone parameter */ 
	/*  Modified by M.  Bogner  10/01/2011 to add mods to check for ACL II permissions */ 
	/*  Modified by M.  Bogner  05/23/2012 to add Phase 3.0 mod to add entry to CP_TS_ID Table */ 
    /*  Modified by K. Cavalier 29-APR-2016 to move Validation and Data Flag Checking Code from R_BASE_BEFORE_INSERT_UPDATE Trigger to here to avoid unnecessary duplicate archives  */

  	/* see if ACL PROJECT II is enabled and if user is permitted */
	IF (hdb_utilities.is_feature_activated('ACCESS CONTROL LIST GROUP VERSION II') = 'Y' AND 
	    hdb_utilities.IS_SDI_IN_ACL(SITE_DATATYPE_ID) <> 'Y' ) THEN
   		DENY_ACTION('ILLEGAL ACL VERSION II MODIFY_R_BASE_RAW OPERATION -- No Permissions To Modify Data');
    END IF;
        
    /*  First check for any null field that where passed  */
    IF SITE_DATATYPE_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL IS NULL THEN DENY_ACTION ( 'INVALID <NULL> INTERVAL' );
	ELSIF START_DATE_TIME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> START_DATE_TIME' );
	ELSIF VALUE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> VALUE' );
	ELSIF AGEN_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> AGEN_ID' );
	ELSIF COLLECTION_SYSTEM_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> COLLECTION_SYSTEM_ID' );
	ELSIF LOADING_APPLICATION_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> LOADING_APPLICATION_ID' );
	ELSIF METHOD_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> METHOD_ID' );
	ELSIF COMPUTATION_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> COMPUTATION_ID' );
    END IF;

   /* for phase 3.0 add this record to the CP_TS_ID table if it isn't already there  */
   /* this procedure call added for Phase 3.0 project                                */
   CP_PROCESSOR.create_ts_id (SITE_DATATYPE_ID,INTERVAL,'R_',-1,l_ts_id);

   /* Now call the procedure to standardize the dates to one single date representation  */
   START_DATE_TIME_NEW := START_DATE_TIME;
   END_DATE_TIME_NEW := END_DATE_TIME;
   VALUE_NEW := VALUE;
   VALIDATION_NEW := VALIDATION;
   DATA_FLAGS_NEW := DATA_FLAGS;


/* get the databases default time zone  */
    BEGIN
      select param_value into db_timezone
        from ref_db_parameter, global_name
        where param_name = 'TIME_ZONE'
        and global_name.global_name = ref_db_parameter.global_name
        and nvl(active_flag,'Y') = 'Y';
       exception when others then 
       db_timezone := NULL;
    END;

   /* now convert the start_time to the database time if different, both exist, 
   and only for the instantaneous and hourly interval           */
   IF (TIME_ZONE <> db_timezone AND INTERVAL in ('instant','hour')) THEN
     
       START_DATE_TIME_NEW:= new_time(START_DATE_TIME_NEW,TIME_ZONE,db_timezone);
       END_DATE_TIME_NEW:= new_time(END_DATE_TIME_NEW,TIME_ZONE,db_timezone);
     
   END IF;

   HDB_UTILITIES.STANDARDIZE_DATES(
       SITE_DATATYPE_ID,
       INTERVAL,
       START_DATE_TIME_NEW,
       END_DATE_TIME_NEW);
 
    /* set the END_DATE_TIME for calling APPLICATION  */
    END_DATE_TIME := END_DATE_TIME_NEW;

	/* Call the preprocessor if the validation is not a "V"   */
	IF ( nvl(VALIDATION,'x') != 'V') THEN
		PRE_PROCESSOR.PREPROCESSOR ( 
			SITE_DATATYPE_ID,
			INTERVAL,
			START_DATE_TIME_NEW,
			VALUE_NEW,
			VALIDATION_NEW,
			DATA_FLAGS_NEW);
	END IF;

/* Moved Validation and Data Flag Checking Code from R_BASE_BEFORE_INSERT_UPDATE Trigger to here 
     to avoid unnecessary duplicate archives -kcavalier 29-APR-2016 */
  
  -- Moves legacy validation codes to data flags
  IF VALIDATION_NEW in ('E','+','-','w','n','|','^','~',chr(32)) then
     DATA_FLAGS_NEW := VALIDATION_NEW || substr(DATA_FLAGS_NEW,1,19);
     VALIDATION_NEW := NULL;
  end if;
  
  -- Validate the data before it goes into the table
  if (nvl(VALIDATION_NEW,'Z') in ('Z')) then
    hdb_utilities.validate_r_base_record
      (site_datatype_id,
       interval,
       START_DATE_TIME_NEW,
       VALUE_NEW,
       VALIDATION_NEW);
  end if;
  /* End of Move Validation Code */

    /*  go see if a record already exists ; if not do an insert otherwise do an update as long as do_update <> 'N'  */
    /*  Default date time of ADA Byron birthdate to indicate record came through procedures  */
    DATE_TIME_NEW := to_date('10-DEC-1815','dd-MON-yyyy');
    TEMP_SDI := SITE_DATATYPE_ID;
    TEMP_INT := INTERVAL;
    TEMP_SDT := START_DATE_TIME_NEW;
    TEMP_EDT := END_DATE_TIME_NEW;
    SELECT count ( * )
      INTO rowcount
      FROM r_base
     WHERE site_datatype_id = TEMP_SDI
       AND INTERVAL = TEMP_INT
       AND start_date_time = TEMP_SDT
       and end_date_time = TEMP_EDT;
    IF rowcount = 0 THEN
	/* insert the data into the database  */
	INSERT_R_BASE ( SITE_DATATYPE_ID,
			INTERVAL,
			START_DATE_TIME_NEW,
			END_DATE_TIME_NEW,
			VALUE_NEW,
			AGEN_ID,
			OVERWRITE_FLAG,
			VALIDATION_NEW,
			COLLECTION_SYSTEM_ID,
			LOADING_APPLICATION_ID,
			METHOD_ID,
			COMPUTATION_ID,
			DATA_FLAGS_NEW,
			DATE_TIME_NEW );
  /*  update the data into the database, if desired */
	ELSIF rowcount > 1 THEN
           DENY_ACTION ( 'RECORD with SDI: ' || to_char ( SITE_DATATYPE_ID ) ||
           ' INTERVAL: ' || INTERVAL || ' START_DATE_TIME: ' || to_char ( start_date_time,
           'dd-MON-yyyy HH24:MI:SS' ) || ' END_DATE_TIME: '|| to_char ( end_date_time_new,
           'dd-MON-yyyy HH24:MI:SS' ) || ' HAS MULTIPLE ENTRIES. DANGER! DANGER! DANGER!.' );
        ELSIF UPPER ( NVL ( DO_UPDATE_Y_OR_N,           
			    'Y' ) ) = 'Y' THEN UPDATE_R_BASE_RAW ( SITE_DATATYPE_ID,
							       INTERVAL,
							       START_DATE_TIME_NEW,
							       END_DATE_TIME_NEW,
							       VALUE_NEW,
							       AGEN_ID,
							       OVERWRITE_FLAG,
							       VALIDATION_NEW,
							       COLLECTION_SYSTEM_ID,
							       LOADING_APPLICATION_ID,
							       METHOD_ID,
							       COMPUTATION_ID,
							       DATA_FLAGS_NEW,
							       DATE_TIME_NEW );
    END IF;

END;
/


-- show errors;
/
create or replace public synonym modify_r_base_raw for modify_r_base_raw;
BEGIN EXECUTE IMMEDIATE 'grant execute on modify_r_base_raw to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on modify_r_base_raw to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./PROCEDURES/modify_r_base.prc
-- PROMPT CREATE OR REPLACE PROCEDURE modify_r_base

CREATE OR REPLACE PROCEDURE modify_r_base ( SITE_DATATYPE_ID NUMBER,
			      INTERVAL VARCHAR2,
			      START_DATE_TIME DATE,
			      END_DATE_TIME DATE,
			      VALUE FLOAT,
                  AGEN_ID NUMBER,
			      OVERWRITE_FLAG VARCHAR2,
			      VALIDATION CHAR,
                  COLLECTION_SYSTEM_ID NUMBER,
                  LOADING_APPLICATION_ID NUMBER,
                  METHOD_ID NUMBER,
                  COMPUTATION_ID NUMBER,
			      DO_UPDATE_Y_OR_N VARCHAR2,
			      DATA_FLAGS IN VARCHAR2 DEFAULT NULL,
			      TIME_ZONE  IN VARCHAR2 DEFAULT NULL  ) IS
 END_DATE_TIME_NEW DATE;
BEGIN
	/*  Modified by M.  Bogner  06/01/2009 to add mods to accept different time_zone parameter */ 

    /*  set the end_date_time variable to the value passed in, this gets around the issue if you pass in a null */
    END_DATE_TIME_NEW := END_DATE_TIME;

    MODIFY_R_BASE_RAW ( SITE_DATATYPE_ID,
			INTERVAL,
			START_DATE_TIME,
			END_DATE_TIME_NEW,
			VALUE,
			AGEN_ID,
			OVERWRITE_FLAG,
			VALIDATION,
			COLLECTION_SYSTEM_ID,
			LOADING_APPLICATION_ID,
			METHOD_ID,
			COMPUTATION_ID,
			DO_UPDATE_Y_OR_N,
			DATA_FLAGS,
			TIME_ZONE );

END;
/

-- show errors;
create or replace public synonym modify_r_base for modify_r_base;
BEGIN EXECUTE IMMEDIATE 'grant execute on modify_r_base to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on modify_r_base to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./PROCEDURES/decodes_to_rbase.prc
create or replace PROCEDURE DECODES_TO_RBASE (
			      SITE_ID          NUMBER,
			      DATATYPE_ID      NUMBER,
			      SAMPLE_DATE_TIME DATE,
			      SAMPLE_VALUE     FLOAT
)  IS

/*  This procedure was written to be the generic interface to 
    R_BASE from the DECODES application                       
    this procedure written by Mark Bogner   June 2005          */

    /*  first declare all internal variables need for call to modify_r_base_raw  */
    SITE_DATATYPE_ID       R_BASE.SITE_DATATYPE_ID%TYPE;
    INTERVAL               R_BASE.INTERVAL%TYPE;
    START_DATE_TIME        R_BASE.START_DATE_TIME%TYPE;
    END_DATE_TIME          R_BASE.END_DATE_TIME%TYPE;
    VALUE                  R_BASE.VALUE%TYPE;
    AGEN_ID                R_BASE.AGEN_ID%TYPE;
    OVERWRITE_FLAG         R_BASE.OVERWRITE_FLAG%TYPE;
    VALIDATION             R_BASE.VALIDATION%TYPE;
    COLLECTION_SYSTEM_ID   R_BASE.COLLECTION_SYSTEM_ID%TYPE;
    LOADING_APPLICATION_ID R_BASE.LOADING_APPLICATION_ID%TYPE;
    METHOD_ID              R_BASE.METHOD_ID%TYPE;
    COMPUTATION_ID         R_BASE.COMPUTATION_ID%TYPE;

    /* some temp variables for use in this procedures internal queries  */
    TEMP_NUMBER     NUMBER;
    TEMP_SITEID     NUMBER;
    TEMP_DATATYPEID NUMBER;
BEGIN

    /*  First check for any required fields that where passed in as NULL  */
    IF SITE_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_ID' );
	ELSIF DATATYPE_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> DATATYPE_ID' );
	ELSIF SAMPLE_DATE_TIME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_DATE_TIME' );
	ELSIF SAMPLE_VALUE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_VALUE' );
    END IF;

    /*  now set the variables for the data input parameters     */
    START_DATE_TIME := SAMPLE_DATE_TIME;
    VALUE := SAMPLE_VALUE;
    TEMP_SITEID := SITE_ID;
    TEMP_DATATYPEID := DATATYPE_ID;

      BEGIN
      /* go get the site_datatype_id for the site/datatype combination that was passed in as 
         input parameteres                                                                    */
      select site_datatype_id into site_datatype_id from hdb_site_datatype 
           where site_id = temp_siteid 
           and datatype_id = temp_datatypeid;

      /* if there is no site_datatype_Id then no reason to continue  */
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  
         DENY_ACTION ( 'NO SITE_DATATYPE_ID FOR SITE_ID: '|| to_char(SITE_ID) || ' DATATYPE_ID: ' || to_char(datatype_id) );
      END;

      BEGIN
      /*  go get the interval, method, and computation id's if the users decided to define 
          them and use the generic mapping table for these data      */
      select a.hdb_interval_name,a.hdb_method_id,a.hdb_computation_id
            into INTERVAL,METHOD_ID,COMPUTATION_ID
      	  from ref_ext_site_data_map a, hdb_ext_data_source b
          where a.hdb_site_datatype_id = site_datatype_id
            and a.ext_data_source_id = b.ext_data_source_id
            and upper(b.ext_data_source_name) = 'DECODES';
 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  /* don't care, will use defaults.. so do nothing  */  
        TEMP_NUMBER := 0;
      END;

      BEGIN
      /*  go get the agen_id from the generic mapping tables  since decodes must use these 
          tables data to get the site data anyway  But it may be null so its set later as a
          default if  that is the case                                                        */
      select min(agen_id) into agen_id from  hdb_ext_site_code a , hdb_ext_site_code_sys  b
        where a.hdb_site_id = temp_siteid and a.ext_site_code_sys_id = b.ext_site_code_sys_id;
 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN    /* don't care, will use defaults.. so do nothing  */
        TEMP_NUMBER := 0;
      END;

    /*  set all the default system and agency ids for this application 
        since they will be known.  IT was decided to hardcode these to be site 
        specific to reduce the number of queries necessary to put in a R_base record  
        These default settings may need to be changed based on the values at each 
        specific HDB installation  */

    /*  Interval query above gives the installation the chance to define a different 
        interval for a particular site if they want it, otherwise default the interval 
        to instant                 */                                          
    IF INTERVAL is NULL THEN 
       INTERVAL := 'instant';
    END IF;

    IF AGEN_ID is NULL THEN  /*  see query above if there is a problem here  */
       AGEN_ID := 33;             /*  See Loading application  */
    END IF;

    COLLECTION_SYSTEM_ID := 13;    /*  see loading application  */
    LOADING_APPLICATION_ID := 41;  /*  whatever DECODES loading applications number is   */
    
    IF METHOD_ID is NULL THEN    /*  possibly already set if user defined method for this SDI  */
       METHOD_ID := 18;               /* unknown  */
    END IF;

    IF COMPUTATION_ID is NULL THEN    /*  possibly already set if user defined computation_id for this SDI  */
       COMPUTATION_ID := 2;           /*  N/A  */
    END IF;


    /*  now we should have passed all the logic and validity checks so
    just call the normal procedure to put data into r_base          */

    modify_r_base_raw ( SITE_DATATYPE_ID,
                        INTERVAL,
			START_DATE_TIME,
			END_DATE_TIME,
			VALUE,
                        AGEN_ID,
			OVERWRITE_FLAG,
			VALIDATION,
                        COLLECTION_SYSTEM_ID,
                        LOADING_APPLICATION_ID,
                        METHOD_ID,
                        COMPUTATION_ID,
                        'Y');

END;  /* end of the procedure  */

/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM decodes_to_rbase for decodes_to_rbase;
BEGIN EXECUTE IMMEDIATE 'grant execute on decodes_to_rbase to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on decodes_to_rbase to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/delete_m_table.prc
CREATE OR REPLACE PROCEDURE delete_m_table ( MODEL_RUN_ID_IN NUMBER,
			  SITE_DATATYPE_ID_IN NUMBER,                       
			  START_DATE_TIME_IN DATE,                                                   
			  END_DATE_TIME_IN DATE,
			  INTERVAL_IN VARCHAR2)
IS                                                                              
BEGIN                                                                           
/* The calling procedure must check that a delete is required */
   
     IF interval_in = 'hour' THEN                                                                      
       DELETE FROM M_HOUR                                                               
       WHERE model_run_id = model_run_id_in
         AND site_datatype_id = SITE_DATATYPE_ID_IN                               
         AND start_date_time = START_DATE_TIME_IN                                 
         and end_date_time = END_DATE_TIME_IN;                                    
     ELSIF interval_in = 'day' THEN                                                                      
       DELETE FROM M_DAY                                                            
       WHERE model_run_id = model_run_id_in
         AND site_datatype_id = SITE_DATATYPE_ID_IN                               
         AND start_date_time = START_DATE_TIME_IN                                 
         and end_date_time = END_DATE_TIME_IN;                                    
	NULL; 
     ELSIF interval_in = 'month' THEN                                                                      
       DELETE FROM M_MONTH                                                          
       WHERE model_run_id = model_run_id_in
         AND site_datatype_id = SITE_DATATYPE_ID_IN                               
         AND start_date_time = START_DATE_TIME_IN                                 
         and end_date_time = END_DATE_TIME_IN;                                    
	NULL; 
     ELSIF interval_in = 'wy' THEN                                                                      
       DELETE FROM M_WY                                                           
       WHERE model_run_id = model_run_id_in
         AND site_datatype_id = SITE_DATATYPE_ID_IN                               
         AND start_date_time = START_DATE_TIME_IN                                 
         and end_date_time = END_DATE_TIME_IN;                                    
	NULL; 
     ELSIF interval_in = 'year' THEN                                                                      
       DELETE FROM M_YEAR                                                          
       WHERE model_run_id = model_run_id_in
         AND site_datatype_id = SITE_DATATYPE_ID_IN                               
         AND start_date_time = START_DATE_TIME_IN                                 
         and end_date_time = END_DATE_TIME_IN;                                    
	NULL; 
     ELSE
       DENY_ACTION ('INVALID INTERVAL');
    END IF;                                                                     
END;
/

-- show errors;
/
create or replace public synonym delete_m_table for delete_m_table;
BEGIN EXECUTE IMMEDIATE 'grant execute on delete_m_table to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on delete_m_table to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on delete_m_table to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/insert_m_table.prc
-- PROMPT CREATE OR REPLACE PROCEDURE insert_m_table;

CREATE OR REPLACE PROCEDURE insert_m_table (
        MODEL_RUN_ID NUMBER,
        SITE_DATATYPE_ID NUMBER,
        START_DATE_TIME DATE,
        END_DATE_TIME  DATE,
        VALUE FLOAT,
        INTERVAL VARCHAR2)
   IS

   BEGIN
/* Blecherous Nasty Duplicated Code 
   We could make this into native dynamic sql with a execute immediate ('insert into m_'||interval||' (model_run_id...')
   But I understand that would be slower. Slower than all these string comparisons, I expect? */
     IF INTERVAL = 'hour' THEN
             INSERT INTO m_hour (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE)
             VALUES (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE);
     ELSIF INTERVAL = 'day' THEN 
             INSERT INTO m_day (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE)
             VALUES (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE);
     ELSIF INTERVAL = 'month' THEN 
             INSERT INTO m_month (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE)
             VALUES (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE);
     ELSIF INTERVAL = 'wy' THEN 
             INSERT INTO m_wy (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE)
             VALUES (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE);
     ELSIF INTERVAL = 'year' THEN 
             INSERT INTO m_year (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE)
             VALUES (MODEL_RUN_ID, SITE_DATATYPE_ID, START_DATE_TIME, END_DATE_TIME, VALUE);
     END IF;

   END;
/
--  show errors;
/

create or replace public synonym insert_m_table for insert_m_table;
BEGIN EXECUTE IMMEDIATE 'grant execute on insert_m_table to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on insert_m_table to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on insert_m_table to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/
-- Expanding: ./PROCEDURES/update_m_table_raw.prc
-- PROMPT CREATE OR REPLACE PROCEDURE update_m_table_raw;

CREATE OR REPLACE PROCEDURE update_m_table_raw (
        MODEL_RUN_ID_IN NUMBER,
        SITE_DATATYPE_ID_IN NUMBER,
        START_DATE_TIME_IN DATE,
        VALUE_IN FLOAT,
        INTERVAL VARCHAR2)
IS
epsilon FLOAT := 1E-7;
BEGIN

/*    DENY_ACTION(to_char(MODEL_RUN_ID_IN)||to_char(SITE_DATATYPE_ID_IN)||INTERVAL||TO_CHAR(START_DATE_TIME_IN)||'  REC COUNT: assumed >0'); */

/* These are duplicated for speed, see comments in insert_m_table and modify_m_table */
     IF INTERVAL = 'hour' THEN
        UPDATE m_hour 
           set value = VALUE_IN
        where model_run_id = model_run_id_in 
	and site_datatype_id = site_datatype_id_in 
	and start_date_time = start_date_time_in
	and abs(value - value_in) > epsilon;

     ELSIF INTERVAL = 'day' THEN 
        UPDATE m_day 
           set value = VALUE_IN
        where model_run_id = model_run_id_in 
	and site_datatype_id = site_datatype_id_in 
	and start_date_time = start_date_time_in
	and abs(value - value_in) > epsilon;

     ELSIF INTERVAL = 'month' THEN 
        UPDATE m_month
           set value = VALUE_IN
        where model_run_id = model_run_id_in 
	and site_datatype_id = site_datatype_id_in 
	and start_date_time = start_date_time_in
	and abs(value - value_in) > epsilon;

     ELSIF INTERVAL = 'wy' THEN 
        UPDATE m_wy
           set value = VALUE_IN
        where model_run_id = model_run_id_in 
	and site_datatype_id = site_datatype_id_in 
	and start_date_time = start_date_time_in
	and abs(value - value_in) > epsilon;

     ELSIF INTERVAL = 'year' THEN 
        UPDATE m_year
           set value = VALUE_IN
        where model_run_id = model_run_id_in 
	and site_datatype_id = site_datatype_id_in 
	and start_date_time = start_date_time_in
	and abs(value - value_in) > epsilon;

     END IF;
   END;
/

/* Permission not granted to anything on purpose. Only modify_m_table_raw should call this */
--  show errors;
/


-- Expanding: ./PROCEDURES/modify_m_table_raw.prc
-- PROMPT CREATE OR REPLACE PROCEDURE modify_m_table_raw;

CREATE OR REPLACE PROCEDURE modify_m_table_raw  ( 
                              MODEL_RUN_ID_IN NUMBER,
                              SITE_DATATYPE_ID_IN NUMBER,
                              START_DATE_TIME_IN DATE,
                              END_DATE_TIME IN OUT DATE,
                              VALUE FLOAT,
                              INTERVAL_IN VARCHAR2,
                              DO_UPDATE_Y_OR_N VARCHAR2 )
IS
    ROWCOUNT NUMBER;
    l_ts_id NUMBER;
    l_model_id NUMBER;
    END_DATE_TIME_NEW DATE;
BEGIN
	/*  Modified by M.  Bogner  05/23/2012 to add Phase 3.0 mod to add entry to CP_TS_ID Table */ 
	
    /*  First check for any null field that were passed  */
    IF MODEL_RUN_ID_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> MODEL_RUN_ID' );
        ELSIF SITE_DATATYPE_ID_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_DATATYPE_ID' );
        ELSIF INTERVAL_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> INTERVAL' );
        ELSIF START_DATE_TIME_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> START_DATE_TIME' );
        ELSIF VALUE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> VALUE' );
    END IF;

    /* for phase 3.0 add this record to the CP_TS_ID table if it isn't already there  */
    /* this procedure call added for Phase 3.0 project                                */
      SELECT model_id
        INTO l_model_id
        FROM ref_model_run
       WHERE model_run_id = MODEL_RUN_ID_IN;
    CP_PROCESSOR.create_ts_id (SITE_DATATYPE_ID_IN,INTERVAL_IN,'M_',l_model_id,l_ts_id);

    /*  if user did not pass an end_date time, set the end date TIME based on START_DATE_TIME AND THE INTERVAL */
    END_DATE_TIME_NEW := END_DATE_TIME;
    IF END_DATE_TIME IS NULL THEN
        IF INTERVAL_IN = 'hour' THEN END_DATE_TIME_NEW := START_DATE_TIME_IN + 1 / 24;
        ELSIF INTERVAL_IN = 'day' THEN END_DATE_TIME_NEW := START_DATE_TIME_IN + 1;
        ELSIF INTERVAL_IN = 'month' THEN END_DATE_TIME_NEW := ADD_MONTHS ( START_DATE_TIME_IN,
                                                                            1 );
        ELSIF INTERVAL_IN ='year' OR INTERVAL_IN = 'wy' THEN END_DATE_TIME_NEW := ADD_MONTHS ( START_DATE_TIME_IN,
                                                                                              12 );
        ELSE
            DENY_ACTION ( INTERVAL_IN || ' IS AN INVALID INTERVAL WITH A NULL END DATE TIME.' );
        END IF;

        END_DATE_TIME := END_DATE_TIME_NEW;
    END IF;

    /*  go see if a record already exists ; if not do an insert otherwise do an update as long as upper(do_update_y_or_n) = 'Y'  
        we could do this with dynamic sql, but that is probably slower */

   IF INTERVAL_IN = 'hour' THEN 
      SELECT count ( * )
        INTO rowcount
        FROM m_hour
       WHERE model_run_id = MODEL_RUN_ID_IN
         AND site_datatype_id = SITE_DATATYPE_ID_IN
         AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'day' THEN 
      SELECT count ( * )
        INTO rowcount
        FROM m_day
       WHERE model_run_id = MODEL_RUN_ID_IN
         AND site_datatype_id = SITE_DATATYPE_ID_IN
         AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'month' THEN 
      SELECT count ( * )
        INTO rowcount
        FROM m_month
       WHERE model_run_id = MODEL_RUN_ID_IN
         AND site_datatype_id = SITE_DATATYPE_ID_IN
         AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'wy' THEN 
      SELECT count ( * )
        INTO rowcount
        FROM m_wy
       WHERE model_run_id = MODEL_RUN_ID_IN
         AND site_datatype_id = SITE_DATATYPE_ID_IN
         AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'year' THEN 
      SELECT count ( * )
        INTO rowcount
        FROM m_year
       WHERE model_run_id = MODEL_RUN_ID_IN
         AND site_datatype_id = SITE_DATATYPE_ID_IN
         AND start_date_time = START_DATE_TIME_IN;
   ELSE
        DENY_ACTION('INVALID INTERVAL');
   END IF;
     /*    DENY_ACTION(to_char(MODEL_RUN_ID_IN)||to_char(SITE_DATATYPE_ID_IN)||INTERVAL_IN||TO_CHAR(START_DATE_TIME_IN)||'  REC COUNT:'||TO_CHAR(rowcount)); */

    IF rowcount = 0 THEN
        /* insert the data into the database  */
        INSERT_M_TABLE (MODEL_RUN_ID_IN, 
                        SITE_DATATYPE_ID_IN,
                        START_DATE_TIME_IN,
                        END_DATE_TIME_NEW,
                        VALUE,
                        INTERVAL_IN);
  /*  update the data into the database, if desired */
        ELSIF rowcount > 1 THEN
              DENY_ACTION ( 'RECORD with with MRI: ' || to_char(MODEL_RUN_ID_IN) || 
              ' SDI: ' || to_char ( SITE_DATATYPE_ID_IN ) ||
              ' INTERVAL: ' || INTERVAL_IN || ' START_DATE_TIME: ' || to_char ( START_DATE_TIME_IN,
              'dd-MON-yyyy HH24:MI:SS' ) || ' HAS MULTIPLE ENTRIES. DANGER! DANGER! DANGER!.' );
        ELSIF UPPER ( NVL ( DO_UPDATE_Y_OR_N,           
                            'Y' ) ) = 'Y' THEN UPDATE_M_TABLE_RAW ( 
                                                                    MODEL_RUN_ID_IN, 
                                                                    SITE_DATATYPE_ID_IN,
                                                                    START_DATE_TIME_IN,
                                                                    VALUE,
	                                                            INTERVAL_IN);
    END IF;

END;
/

--  show errors;
/

create or replace public synonym modify_m_table_raw for modify_m_table_raw;
BEGIN EXECUTE IMMEDIATE 'grant execute on modify_m_table_raw to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on modify_m_table_raw to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on modify_m_table_raw to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/

-- Expanding: ./PROCEDURES/modify_m_table.prc
-- PROMPT CREATE OR REPLACE PROCEDURE modify_m_table;

CREATE OR REPLACE PROCEDURE MODIFY_M_TABLE (
                              MODEL_RUN_ID NUMBER,
                              SITE_DATATYPE_ID NUMBER,
			      START_DATE_TIME DATE,
			      END_DATE_TIME DATE,
			      VALUE FLOAT,
			      INTERVAL VARCHAR2,
			      DO_UPDATE_Y_OR_N VARCHAR2 ) IS
 END_DATE_TIME_NEW DATE;
BEGIN
    /*  set the end_date_time variable to the value passed in, this gets around the issue if you pass in a null */
    END_DATE_TIME_NEW := END_DATE_TIME;

    MODIFY_M_TABLE_RAW (
                        MODEL_RUN_ID,
                        SITE_DATATYPE_ID,
			START_DATE_TIME,
			END_DATE_TIME_NEW,
			VALUE,
			INTERVAL,
			DO_UPDATE_Y_OR_N );

END;
/

--  show errors;
/

create or replace public synonym modify_m_table for modify_m_table;
BEGIN EXECUTE IMMEDIATE 'grant execute on modify_m_table to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on modify_m_table to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on modify_m_table to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/

-- Expanding: ./PROCEDURES/update_m_table.prc
-- PROMPT CREATE OR REPLACE PROCEDURE update_m_table;

CREATE OR REPLACE PROCEDURE update_m_table (
        MODEL_RUN_ID_IN NUMBER,
        SITE_DATATYPE_ID_IN NUMBER,
        START_DATE_TIME_IN DATE,
        VALUE_IN FLOAT,
        INTERVAL_IN VARCHAR2)
   IS
       
   rowcount_new NUMBER;

   BEGIN

   IF INTERVAL_IN = 'hour' THEN 
         SELECT count ( * )
           INTO rowcount_new
           FROM m_hour
          WHERE model_run_id = MODEL_RUN_ID_IN
            AND site_datatype_id = SITE_DATATYPE_ID_IN
            AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'day' THEN 
         SELECT count ( * )
           INTO rowcount_new
           FROM m_day
          WHERE model_run_id = MODEL_RUN_ID_IN
            AND site_datatype_id = SITE_DATATYPE_ID_IN
            AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'month' THEN 
         SELECT count ( * )
           INTO rowcount_new
           FROM m_month
          WHERE model_run_id = MODEL_RUN_ID_IN
            AND site_datatype_id = SITE_DATATYPE_ID_IN
            AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'wy' THEN 
         SELECT count ( * )
           INTO rowcount_new
           FROM m_wy
          WHERE model_run_id = MODEL_RUN_ID_IN
            AND site_datatype_id = SITE_DATATYPE_ID_IN
            AND start_date_time = START_DATE_TIME_IN;
   ELSIF INTERVAL_IN = 'year' THEN 
         SELECT count ( * )
           INTO rowcount_new
           FROM m_year
          WHERE model_run_id = MODEL_RUN_ID_IN
            AND site_datatype_id = SITE_DATATYPE_ID_IN
            AND start_date_time = START_DATE_TIME_IN;
   END IF;

   IF rowcount_new < 1 THEN
      DENY_ACTION('UPDATE FAILED. RECORD with MRI: ' || to_char(MODEL_RUN_ID_IN) || 
                  ' SDI: ' || to_char(SITE_DATATYPE_ID_IN) || ' INTERVAL: ' || INTERVAL_IN ||
                  ' START_DATE_TIME: ' || to_char(start_date_time_IN,'dd-MON-yyyy HH24:MI:SS') || ' DOES NOT EXIST.');
   ELSIF rowcount_new > 1 THEN
      DENY_ACTION('UPDATE FAILED. RECORD with MRI: ' || to_char(MODEL_RUN_ID_IN) || 
                  ' SDI: ' || to_char(SITE_DATATYPE_ID_IN) || ' INTERVAL: ' || INTERVAL_IN ||
                  ' START_DATE_TIME: ' || to_char(start_date_time_IN,'dd-MON-yyyy HH24:MI:SS') || ' HAS MULTIPLE ENTRIES. DANGER! DANGER! DANGER!.' );
   END IF;

/* These are duplicated for speed, see comments in insert_m_table and modify_m_table */
   UPDATE_M_TABLE_RAW (
        MODEL_RUN_ID_IN,
        SITE_DATATYPE_ID_IN,
        START_DATE_TIME_IN,
        VALUE_IN,
        INTERVAL_IN
);
   END;
/

--  show errors;
/

create or replace public synonym update_m_table for update_m_table;
BEGIN EXECUTE IMMEDIATE 'grant execute on update_m_table to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on update_m_table to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on update_m_table to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/
-- Expanding: ./PROCEDURES/validate_sdi_interval.prc

CREATE OR REPLACE PROCEDURE validate_sdi_interval ( 
SITE_DATATYPE_ID_IN NUMBER, INTERVAL_IN VARCHAR2)
IS
interval_order_in number;
sdi_holder number;
BEGIN
	IF SITE_DATATYPE_ID_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_DATATYPE_ID' );
	ELSIF INTERVAL_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> INTERVAL' );
	end if;
	
	begin
		Select c.interval_order
        	into interval_order_in
        	from hdb_interval c
		where
        	c.interval_name = INTERVAL_IN;
	exception when others THEN
       		DENY_ACTION ( 'INVALID INTERVAL: ' || INTERVAL_IN );
       		return;
    	end;
    	
	begin  	
        	select e.site_datatype_id
        	into sdi_holder /*not used for anything*/
        	from hdb_site_datatype e
        	where e.site_datatype_id = SITE_DATATYPE_ID_IN;
        exception when others THEN
		DENY_ACTION ( 'INVALID SDI: ' || SITE_DATATYPE_ID_IN );
      		return;
	end;
END;

/

CREATE OR REPLACE PUBLIC SYNONYM validate_sdi_interval for validate_sdi_interval;
BEGIN EXECUTE IMMEDIATE 'grant execute on validate_sdi_interval to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/create_site_data_map.prc
create or replace PROCEDURE create_site_data_map ( 
                              EXT_DATA_SOURCE_ID NUMBER,
			      PRIMARY_SITE_CODE VARCHAR2,
			      PRIMARY_DATA_CODE VARCHAR2,
                              NUM_EXTRA_KEYS NUMBER,
                              HDB_SITE_DATATYPE_ID NUMBER, 
			      HDB_INTERVAL_NAME VARCHAR2,
                              HDB_METHOD_ID NUMBER, 
                              HDB_COMPUTATION_ID NUMBER, 
                              HDB_AGEN_ID NUMBER,
                              IS_ACTIVE VARCHAR2,
                              CMMNT VARCHAR2,
                              EXTRA_KEYS VARCHAR2)
IS
  equals_check number;
  comma_check number;
  start_pos number;
  equals_pos number;
  comma_pos number;
  str_size number;
  i number;
  key_name varchar2(32);
  key_value varchar2(32);
  new_mapping_id number;
  is_active_y_n varchar2(1);
BEGIN
  /*  First check for inappropriate NULL values */
  if (ext_data_source_id is null) then
      deny_action ( 'Invalid <NULL> ext_data_source_id');
  elsif (primary_site_code is null) then
      deny_action ( 'Invalid <NULL> primary_site_code');
  elsif (primary_data_code is null) then
      deny_action ( 'Invalid <NULL> primary_data_code');
  elsif (num_extra_keys is null) then
      deny_action ( 'Invalid <NULL> num_extra_keys');
  elsif (hdb_site_datatype_id is null) then
      deny_action ( 'Invalid <NULL> hdb_site_datatype_id');
  elsif (hdb_interval_name is null) then
      deny_action ( 'Invalid <NULL> hdb_interval_name');
  end if;

  /* if is_active is null, set it to Y */
  if (is_active is null) then
    is_active_y_n := 'Y';
  else
    is_active_y_n := is_active;
  end if;
    
  /* If there are no extra keys, insert record into ref_ext_site_data_map */
  if (num_extra_keys = 0) then
    if (extra_keys is not null) then
      deny_action ('Extra_keys must be NULL when num_extra_keys = 0');
    end if;
  
    insert into ref_ext_site_data_map (
      mapping_id,
      ext_data_source_id,
      primary_site_code,
      primary_data_code,
      extra_keys_y_n,
      hdb_site_datatype_id,
      hdb_interval_name,
      hdb_method_id,
      hdb_computation_id,
      hdb_agen_id,
      is_active_y_n,
      cmmnt)
    values (
      0, 
      ext_data_source_id, 
      primary_site_code, 
      primary_data_code,    
      'N',
      hdb_site_datatype_id,
      hdb_interval_name,
      hdb_method_id,
      hdb_computation_id,
      hdb_agen_id,
      is_active_y_n,
      cmmnt);

    commit; 
  else
    /* Do some checks on the extra_keys string to see if it looks valid */
    /* Not enough pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys)
    into equals_check
    from dual;

    if (equals_check = 0) then
      deny_action ('Extra_keys string does not appear to contain enough key=value pairs; not enough = signs. Mapping will not be created.');  
    end if;

    /* Too many pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys+1)
    into equals_check
    from dual;

    if (equals_check > 0) then
      deny_action ('There appear to be more than '||num_extra_keys||' key=value pairs in extra_keys. Mapping will not be created.');
    end if;

    /* Not enough delineation? */
    if (num_extra_keys > 1) then
      select instr(extra_keys, ',', 1, num_extra_keys-1)
      into comma_check
      from dual;

      if (comma_check = 0) then
        deny_action ('Cannot delineate key=value pairs in extra_keys string; not enough commas between pairs. Mapping will not be created.');  
      end if;
    end if;

    /* Continue with inserting mapping */
    insert into ref_ext_site_data_map (
      mapping_id,
      ext_data_source_id,
      primary_site_code,
      primary_data_code,
      extra_keys_y_n,
      hdb_site_datatype_id,
      hdb_interval_name,
      hdb_method_id,
      hdb_computation_id,
      hdb_agen_id,
      is_active_y_n,
      cmmnt)
     values (
      0, 
      ext_data_source_id, 
      primary_site_code, 
      primary_data_code,    
      'Y',
      hdb_site_datatype_id,
      hdb_interval_name,
      hdb_method_id,
      hdb_computation_id,
      hdb_agen_id,
      is_active_y_n,
      cmmnt);

    /* Parse extra_keys and insert row for each pair; if there are
       extra key=value pairs, the mapping will not be created. */
    start_pos := 1;
    for i in 1..num_extra_keys loop
      select instr(extra_keys, '=', 1, i)
      into equals_pos 
      from dual;

      str_size := equals_pos - start_pos;
      key_name := substr (extra_keys, start_pos, str_size);

      if (i < num_extra_keys) then
        select instr(extra_keys, ',', 1, i)
        into comma_pos
        from dual;

        str_size := comma_pos - equals_pos - 1;
        key_value := substr (extra_keys, equals_pos + 1, str_size);
      else
        /* Get the last key_value */
        str_size := length(extra_keys) - equals_pos;
        key_value := substr (extra_keys, equals_pos + 1, str_size);
      end if;

      select max(mapping_id) 
      into new_mapping_id
      from ref_ext_site_data_map;
      
      insert into ref_ext_site_data_map_keyval (
        mapping_id,
        key_name,
        key_value)
      values
        (new_mapping_id,
         key_name,
         key_value);

      start_pos := comma_pos + 1;
    end loop;
    
    commit;
  end if;
end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM create_site_data_map for create_site_data_map;
BEGIN EXECUTE IMMEDIATE 'grant execute on create_site_data_map to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/get_site_data_map.prc
create or replace PROCEDURE get_site_data_map ( 
                              EXT_DATA_SOURCE_ID_IN NUMBER,
			      PRIMARY_SITE_CODE_IN VARCHAR2,
			      PRIMARY_DATA_CODE_IN VARCHAR2,
                              NUM_EXTRA_KEYS NUMBER,
                              HDB_SITE_DATATYPE_ID_OUT OUT NUMBER,
			      HDB_INTERVAL_NAME_OUT OUT VARCHAR2,
                              HDB_METHOD_ID_OUT OUT NUMBER,
                              HDB_COMPUTATION_ID_OUT OUT NUMBER,
                              HDB_AGEN_ID_OUT OUT NUMBER,
                              IS_ACTIVE VARCHAR2,
                              EXTRA_KEYS VARCHAR2)
IS
  equals_check number;
  comma_check number;
  start_pos number;
  equals_pos number;
  comma_pos number;
  str_size number;
  i number;
  key_name varchar2(32);
  key_value varchar2(32);
  map_count number;
  sel_count_stmt varchar2(2000);
  sel_stmt varchar2(2000);
  where_stmt varchar2(2000);
  active_stmt varchar2(2000);
  not_exists_stmt varchar2(2000);
  key_value_stmt varchar2(2000);
  map_id_stmt varchar2(2000);
  count_stmt varchar2(2000);
  whole_stmt varchar2(2000);
  is_active_y_n_in varchar2(1);
  active_ind varchar2(10);
BEGIN

  if (num_extra_keys is null) then
      deny_action ( 'Invalid <NULL> num_extra_keys');
  end if;

  /* if is_active is null, set it to y */
  if (is_active is null) then
    is_active_y_n_in := 'y';
  else
    is_active_y_n_in := is_active;
  end if;

  /* set is_active indicator string */
  if (lower(is_active_y_n_in) = 'y') then
    active_ind := 'active ';
  elsif (lower(is_active_y_n_in) = 'n') then
    active_ind := 'inactive ';
  else
    active_ind := NULL;
  end if;

  /* If there are no extra keys, get lookup values from ref_ext_site_data_map */
  if (num_extra_keys = 0) then
    select count(mapping_id)    
    into map_count
    from ref_ext_site_data_map
    where ext_data_source_id = ext_data_source_id_in
      and primary_site_code = primary_site_code_in
      and primary_data_code = primary_data_code_in
      and lower (extra_keys_y_n) = 'n'
      and ((lower (is_active_y_n_in) <> 'a'
            and lower (is_active_y_n) = lower(is_active_y_n_in)) OR
           (lower (is_active_y_n_in) = 'a'));

    if (map_count = 1) then
      select hdb_site_datatype_id, hdb_interval_name, hdb_method_id,
             hdb_computation_id, hdb_agen_id
      into hdb_site_datatype_id_out, hdb_interval_name_out, hdb_method_id_out,
           hdb_computation_id_out, hdb_agen_id_out
      from ref_ext_site_data_map
      where ext_data_source_id = ext_data_source_id_in
        and primary_site_code = primary_site_code_in
        and primary_data_code = primary_data_code_in
        and lower (extra_keys_y_n) = 'n'
        and ((lower (is_active_y_n_in) <> 'a'
              and lower (is_active_y_n) = lower(is_active_y_n_in)) OR
             (lower (is_active_y_n_in) = 'a'));
      
    elsif (map_count = 0) then
      deny_action('No '||active_ind ||'mappings with source='||ext_data_source_id_in||', site='||primary_site_code_in||', data='||primary_data_code_in);
    else
      deny_action('Too many mappings ('||map_count||') with source='||ext_data_source_id_in||', site='||primary_site_code_in||', data='||primary_data_code_in);
    end if;

  /* Lookup mapping where there are extra keys */
  else
    /* Do some checks on the extra_keys string to see if it looks valid */
    /* Not enough pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys)
    into equals_check
    from dual;

    if (equals_check = 0) then
      deny_action ('Extra_keys string does not appear to contain enough key=value pairs; not enough = signs. Cannot retrieve mapping.');  
    end if;

    /* Too many pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys+1)
    into equals_check
    from dual;

    if (equals_check > 0) then
      deny_action ('There appear to be more than '||num_extra_keys||' key=value pairs in extra_keys. Cannot retrieve mapping.');
    end if;

    /* Not enough delineation? */
    if (num_extra_keys > 1) then
      select instr(extra_keys, ',', 1, num_extra_keys-1)
      into comma_check
      from dual;

      if (comma_check = 0) then
        deny_action ('Cannot delineate key=value pairs in extra_keys string; not enough commas between pairs. Cannot retrieve mapping.');  
      end if;
    end if;

    sel_stmt := 'select distinct a.hdb_site_datatype_id, a.hdb_interval_name, a.hdb_method_id, a.hdb_computation_id, a.hdb_agen_id from ref_ext_site_data_map a';
    sel_count_stmt := 'select count (distinct a.mapping_id) from ref_ext_site_data_map a';
    where_stmt := ' where a.ext_data_source_id = '||ext_data_source_id_in||' and a.primary_site_code = '''||primary_site_code_in||''' and a.primary_data_code = '''||primary_data_code_in||''' and a.mapping_id = key1.mapping_id';

    if (lower (is_active_y_n_in) <> 'a') then
	active_stmt := ' and lower(is_active_y_n) = '''||is_active_y_n_in||'''';
    else
	active_stmt := NULL;
    end if;

    not_exists_stmt := ' and not exists (select count(z.mapping_id) from ref_ext_site_data_map_keyval z where z.mapping_id = key1.mapping_id having count(z.mapping_id) <> '||num_extra_keys||')';

    /* Parse extra_keys and build key_value part of query */
    start_pos := 1;

    for i in 1..num_extra_keys loop
      select instr(extra_keys, '=', 1, i)
      into equals_pos 
      from dual;

      str_size := equals_pos - start_pos;
      key_name := substr (extra_keys, start_pos, str_size);

      if (i < num_extra_keys) then
        select instr(extra_keys, ',', 1, i)
        into comma_pos
        from dual;

        str_size := comma_pos - equals_pos - 1;
        key_value := substr (extra_keys, equals_pos + 1, str_size);
      else
        /* Get the last key_value */
        str_size := length(extra_keys) - equals_pos;
        key_value := substr (extra_keys, equals_pos + 1, str_size);
      end if;

      sel_stmt := concat (sel_stmt, ', ref_ext_site_data_map_keyval key'||i);
      sel_count_stmt := concat (sel_count_stmt, ', ref_ext_site_data_map_keyval key'||i);
      key_value_stmt := concat (key_value_stmt, ' and key'||i||'.key_name = '''||key_name||''' and key'||i||'.key_value = '''||key_value||'''');
      if (i > 1) then
        map_id_stmt := concat (map_id_stmt, ' and key'||i||'.mapping_id = key'||to_char(i-1)||'.mapping_id');
      end if;

      start_pos := comma_pos + 1;
    end loop;

    count_stmt := sel_count_stmt || where_stmt || active_stmt || key_value_stmt || map_id_stmt || not_exists_stmt;
    whole_stmt := sel_stmt || where_stmt || active_stmt || key_value_stmt || map_id_stmt || not_exists_stmt;

    dbms_output.put_line ('COUNT');
    dbms_output.put_line (sel_count_stmt);
    dbms_output.put_line ('WHOLE');
    dbms_output.put_line (sel_stmt);
    dbms_output.put_line (where_stmt);
    dbms_output.put_line (active_stmt);
    dbms_output.put_line (key_value_stmt);
    dbms_output.put_line (map_id_stmt);
    dbms_output.put_line (not_exists_stmt);

    execute immediate count_stmt 
    into map_count; 

    if (map_count = 1) then
      execute immediate whole_stmt 
      into  hdb_site_datatype_id_out, hdb_interval_name_out, hdb_method_id_out,
            hdb_computation_id_out, hdb_agen_id_out;
    elsif (map_count = 0) then
      deny_action('No '||active_ind||'mappings with source='||ext_data_source_id_in||', site='||primary_site_code_in||', data='||primary_data_code_in||' and extra keys '||key_value_stmt);
    else
      deny_action('Too many mappings ('||map_count||') with source='||ext_data_source_id_in||', site='||primary_site_code_in||', data='||primary_data_code_in||' and extra keys '||key_value_stmt);
    end if;

  end if;
end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM get_site_data_map for get_site_data_map;
BEGIN EXECUTE IMMEDIATE 'grant execute on get_site_data_map to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/





-- Expanding: ./PROCEDURES/model_is_coord.prc

CREATE OR REPLACE PROCEDURE model_is_coord
  (model_id_in IN number,
   is_coord OUT number) IS

text varchar2(1000);
BEGIN
  is_coord := 0;

  select 1
  into is_coord
  from hdb_model a
  where a.model_id = model_id_in
    and a.coordinated = 'Y';

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
     text := 'no action; this is OK';
   WHEN OTHERS THEN
     text := 'ERROR: '||sqlcode||' '||substr(sqlerrm,1,100)||' when checking to see if model'||model_id_in||' is coordinated';
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on model_is_coord to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM model_is_coord for model_is_coord;
-- Expanding: ./PROCEDURES/get_next_model_run_id.prc

CREATE OR REPLACE PROCEDURE get_next_model_run_id
  (is_coord IN NUMBER,
   installation_type IN varchar2,
   model_run_id_out OUT number) IS

  cur_max_uncoord_id      number;
  cur_max_coord_id        number;
  max_coord_id            number;
  local_max_coord_id      number;
  local_min_coord_id      number;
  uncoord_upper_limit     number;

  v_count                 number;
  text                    varchar2(1000);

  e_range_expired         exception;
  PRAGMA EXCEPTION_INIT(e_range_expired, -20102);

BEGIN
  model_run_id_out := -1;

  /* Simplest case -- no checking to do. */
  if (installation_type = 'island') then
    SELECT max(model_run_id) + 1
    INTO model_run_id_out
    FROM ref_model_run;

    /* Handle case of first model_run_id */
    if (model_run_id_out is null) then
      model_run_id_out := 1;
    end if;
	
  /* Not coordinated */
  elsif (is_coord = 0) then

    SELECT max(a.model_run_id)
    INTO cur_max_uncoord_id
    FROM ref_model_run a, hdb_model b
    WHERE a.model_id = b.model_id
      AND b.coordinated = 'N';
   
    SELECT max(max_coord_model_run_id) 
    INTO max_coord_id
    FROM ref_db_list;

    /* Handle case where there are not yet any uncoordinated
       model_run_ids. First case will increment this number by 1. */
    if (cur_max_uncoord_id is null) then
      cur_max_uncoord_id := max_coord_id;
    end if;
    
    /* Easy case, where coordinated IDs are below uncoordinated */
    if (cur_max_uncoord_id >= max_coord_id) then
      model_run_id_out := cur_max_uncoord_id + 1;
    else
      SELECT min(min_coord_model_run_id)
      INTO uncoord_upper_limit
      FROM ref_db_list
      WHERE min_coord_model_run_id > cur_max_uncoord_id;
       
      /* Coordinated IDs have gone beyond uncoordinated, but
         uncoordinated haven't hit their cap yet */
      if (cur_max_uncoord_id+1 < uncoord_upper_limit) then
        model_run_id_out := cur_max_uncoord_id + 1;

      /* Uncoordinated have hit cap and need to go beyond 
	 coordinated */
      else
        model_run_id_out := max_coord_id + 1;
      end if;
    end if;
  else
  /* Coordinated run */
    SELECT min_coord_model_run_id, max_coord_model_run_id
    INTO local_min_coord_id, local_max_coord_id
    FROM ref_db_list
    WHERE session_no = 1;

    SELECT count(model_run_id) 
    INTO v_count
    FROM ref_model_run
    WHERE model_run_id between local_min_coord_id and local_max_coord_id;

    /* Case where we have a new range for coordinated IDs that has
	not yet been used. Set new model run to bottom of range. */
    if (v_count = 0) then
      model_run_id_out := local_min_coord_id;
    else
      /* Get max coordinated model_run_id in use at this site. */
      SELECT max(model_run_id)
      INTO cur_max_coord_id
      FROM ref_model_run
      WHERE model_run_id between local_min_coord_id and local_max_coord_id;

      /* Common case; can assign max+1 for new model_run_id */
      if (cur_max_coord_id < local_max_coord_id) then
        model_run_id_out := cur_max_coord_id + 1;
      else
        /* Raise specific error so message is correct */
        text := 'ERROR: Coordinated model_run_id range for this site is used up. Update min_ and max_coord_model_run_id in ref_db_list to next valid range for this site. Do this on all coordinated databases. Next model_run_id creation will automatically find and use the new range.';
        raise_application_error (-20102, text);
      end if;
    end if; /* v_count = 0 */
  end if; /* installation = island */

  EXCEPTION
   WHEN e_range_expired THEN
     deny_action (text);
   WHEN OTHERS THEN
     text := 'ERROR: '||sqlcode||' '||substr(sqlerrm,1,100)||' when getting next model_run_id.';
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on get_next_model_run_id to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM get_next_model_run_id for get_next_model_run_id;
-- Expanding: ./PROCEDURES/insert_coord_model_run_id.prc
CREATE OR REPLACE PROCEDURE insert_coord_model_run_id
  (model_run_id_in              IN number,
   model_run_name_in            IN varchar2,
   model_id_in                  IN number,
   date_time_loaded_in          IN date,
   user_name_in                 IN varchar2,
   extra_keys_in                IN varchar2,
   run_date_in                  IN date,
   start_date_in                IN date,
   end_date_in                  IN date,
   hydrologic_indicator_in      IN varchar2,
   modeltype_in                 IN varchar2,
   time_step_descriptor_in      IN varchar2,
   cmmnt_in                     IN varchar2) IS

  v_count   number;
  e_bad_db  exception;
  PRAGMA EXCEPTION_INIT(e_bad_db, -20102);

  remote_db varchar2(25);
  db_link   varchar2(25);
  ins_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b
  WHERE b.model_id = model_id_in
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  /* Verify that FK constraint is working: make sure DB in hdb_model_coord
     is also in ref_db_list. Error if not. */
  SELECT count(*) 
  INTO v_count
  FROM hdb_model_coord 
  WHERE db_site_code not in (select db_site_code from ref_db_list);

  if (v_count > 0) then
    /* Raise specific error so message is correct */
    text := 'Problem on insert: model '||model_id_in||' lists coord DB not in ref_db_list.';
    raise_application_error (-20102, text);
  end if;

  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    ins_stmt := 'INSERT INTO ref_model_run@'||remote_db||' (model_run_id, model_run_name, model_id, date_time_loaded, user_name, extra_keys_y_n, run_date, start_date, end_date, hydrologic_indicator, modeltype, time_step_descriptor, cmmnt) VALUES (:1,:2,:3,:4,:5,:6, :7, :8, :9, :10, :11, :12, :13)';

    EXECUTE IMMEDIATE ins_stmt USING model_run_id_in, model_run_name_in, model_id_in, date_time_loaded_in, user_name_in, extra_keys_in, run_date_in, start_date_in, end_date_in, hydrologic_indicator_in, modeltype_in, time_step_descriptor_in, cmmnt_in;

  END LOOP;

  EXCEPTION
   WHEN e_bad_db THEN
     deny_action (text);
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to insert at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on insert_coord_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM insert_coord_model_run_id for insert_coord_model_run_id;
-- Expanding: ./PROCEDURES/update_coord_model_run_id.prc
CREATE OR REPLACE PROCEDURE update_coord_model_run_id
  (old_model_run_id_in          IN number,
   new_model_run_id_in          IN number,
   model_run_name_in            IN varchar2,
   model_id_in                  IN number,
   date_time_loaded_in          IN date,
   user_name_in                 IN varchar2,
   extra_keys_in                IN varchar2,
   run_date_in                  IN date,
   start_date_in                IN date,
   end_date_in                  IN date,
   hydrologic_indicator_in      IN varchar2,
   modeltype_in                 IN varchar2,
   time_step_descriptor_in      IN varchar2,
   cmmnt_in                     IN varchar2) IS

  v_count   number;
  e_bad_db  exception;
  PRAGMA EXCEPTION_INIT(e_bad_db, -20102);

  remote_db varchar2(25);
  db_link   varchar2(25);
  upd_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b
  WHERE b.model_id = model_id_in
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  /* Verify that FK constraint is working: make sure DB in hdb_model_coord
     is also in ref_db_list. Error if not. */
  SELECT count(*) 
  INTO v_count
  FROM hdb_model_coord 
  WHERE db_site_code not in (select db_site_code from ref_db_list);

  if (v_count > 0) then
    /* Raise specific error so message is correct */
    text := 'Problem on update: model '||model_id_in||' lists coord DB not in ref_db_list.';
    raise_application_error (-20102, text);
  end if;

  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    upd_stmt := 'UPDATE ref_model_run@'||remote_db||' SET model_run_id=:1,model_run_name=:2,model_id=:3,date_time_loaded=:4,user_name=:5,extra_keys_y_n=:6,run_date=:7,start_date=:8,end_date=:9,hydrologic_indicator=:10,modeltype=:11,time_step_descriptor=:12,cmmnt=:13 WHERE model_run_id=:14';

    EXECUTE IMMEDIATE upd_stmt USING new_model_run_id_in, model_run_name_in, model_id_in, date_time_loaded_in, user_name_in, extra_keys_in, run_date_in, start_date_in, end_date_in, hydrologic_indicator_in, modeltype_in, time_step_descriptor_in, cmmnt_in, old_model_run_id_in;

  END LOOP;

  EXCEPTION
   WHEN e_bad_db THEN
     deny_action (text);
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to update at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on update_coord_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM update_coord_model_run_id for update_coord_model_run_id;
-- Expanding: ./PROCEDURES/delete_coord_model_run_id.prc
CREATE OR REPLACE PROCEDURE delete_coord_model_run_id
  (model_run_id_in              IN number,
   model_id_in                  IN number) IS

  v_count   number;
  e_bad_db  exception;
  PRAGMA EXCEPTION_INIT(e_bad_db, -20102);

  remote_db varchar2(25);
  db_link   varchar2(25);
  del_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b
  WHERE b.model_id = model_id_in
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  /* Verify that FK constraint is working: make sure DB in hdb_model_coord
     is also in ref_db_list. Error if not. */
  SELECT count(*) 
  INTO v_count
  FROM hdb_model_coord 
  WHERE db_site_code not in (select db_site_code from ref_db_list);

  if (v_count > 0) then
    /* Raise specific error so message is correct */
    text := 'Problem on delete: model '||model_id_in||' lists coord DB not in ref_db_list.';
    raise_application_error (-20102, text);
  end if;

  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    del_stmt := 'DELETE FROM ref_model_run@'||remote_db||' WHERE model_run_id = :1';

    EXECUTE IMMEDIATE del_stmt USING model_run_id_in;

  END LOOP;

  EXCEPTION
   WHEN e_bad_db THEN
     deny_action (text);
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to delete at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on delete_coord_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM delete_coord_model_run_id for delete_coord_model_run_id;
-- Expanding: ./PROCEDURES/insert_coord_model_run_keyval.prc
CREATE OR REPLACE PROCEDURE insert_coord_model_run_keyval
  (model_run_id_in              IN number,
   key_name_in                  IN varchar2,
   key_value_in                 IN varchar2,
   date_time_loaded_in          IN date) IS

  v_count   number;
  e_bad_db  exception;
  PRAGMA EXCEPTION_INIT(e_bad_db, -20102);

  remote_db varchar2(25);
  db_link   varchar2(25);
  ins_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b, ref_model_run c
  WHERE c.model_run_id = model_run_id_in
   and b.model_id = c.model_id
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  /* Verify that FK constraint is working: make sure DB in hdb_model_coord
     is also in ref_db_list. Error if not. */
  SELECT count(*) 
  INTO v_count
  FROM hdb_model_coord 
  WHERE db_site_code not in (select db_site_code from ref_db_list);

  if (v_count > 0) then
    /* Raise specific error so message is correct */
    text := 'Problem on insert: model for MRI '||model_run_id_in||' lists coord DB not in ref_db_list.';
    raise_application_error (-20102, text);
  end if;

  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    ins_stmt := 'INSERT INTO ref_model_run_keyval@'||remote_db||' (model_run_id, key_name, key_value, date_time_loaded) VALUES (:1,:2,:3,:4)';

    EXECUTE IMMEDIATE ins_stmt USING model_run_id_in, key_name_in, key_value_in, date_time_loaded_in;

  END LOOP;

  EXCEPTION
   WHEN e_bad_db THEN
     deny_action (text);
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to insert at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on insert_coord_model_run_keyval to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM insert_coord_model_run_keyval for insert_coord_model_run_keyval;
-- Expanding: ./PROCEDURES/update_coord_model_run_keyval.prc
CREATE OR REPLACE PROCEDURE update_coord_model_run_keyval
  (old_model_run_id_in          IN number,
   new_model_run_id_in          IN number,
   old_key_name_in              IN varchar2,
   new_key_name_in              IN varchar2,
   key_value_in                 IN varchar2,
   date_time_loaded_in          IN date) IS

  v_count   number;
  e_bad_db  exception;
  PRAGMA EXCEPTION_INIT(e_bad_db, -20102);

  remote_db varchar2(25);
  db_link   varchar2(25);
  upd_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b, ref_model_run c
  WHERE c.model_run_id = old_model_run_id_in
   and b.model_id = c.model_id
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  /* Verify that FK constraint is working: make sure DB in hdb_model_coord
     is also in ref_db_list. Error if not. */
  SELECT count(*) 
  INTO v_count
  FROM hdb_model_coord 
  WHERE db_site_code not in (select db_site_code from ref_db_list);

  if (v_count > 0) then
    /* Raise specific error so message is correct */
    text := 'Problem on update: model for MRI '||old_model_run_id_in||' lists coord DB not in ref_db_list.';
    raise_application_error (-20102, text);
  end if;

  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    upd_stmt := 'UPDATE ref_model_run_keyval@'||remote_db||' SET model_run_id=:1,key_name=:2,key_value=:3,date_time_loaded=:4 WHERE model_run_id=:5 and key_name = :6';

    EXECUTE IMMEDIATE upd_stmt USING new_model_run_id_in, new_key_name_in, key_value_in, date_time_loaded_in, old_model_run_id_in, old_key_name_in;

  END LOOP;

  EXCEPTION
   WHEN e_bad_db THEN
     deny_action (text);
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to update at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on update_coord_model_run_keyval to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM update_coord_model_run_keyval for update_coord_model_run_keyval;
-- Expanding: ./PROCEDURES/delete_coord_model_run_keyval.prc
CREATE OR REPLACE PROCEDURE delete_coord_model_run_keyval
  (model_run_id_in              IN number) IS

  v_count   number;
  e_bad_db  exception;
  PRAGMA EXCEPTION_INIT(e_bad_db, -20102);

  remote_db varchar2(25);
  db_link   varchar2(25);
  del_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b, ref_model_run c
  WHERE c.model_run_id = model_run_id_in
   and b.model_id = c.model_id
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  /* Verify that FK constraint is working: make sure DB in hdb_model_coord
     is also in ref_db_list. Error if not. */
  SELECT count(*) 
  INTO v_count
  FROM hdb_model_coord 
  WHERE db_site_code not in (select db_site_code from ref_db_list);

  if (v_count > 0) then
    /* Raise specific error so message is correct */
    text := 'Problem on delete: model for MRI '||model_run_id_in||' lists coord DB not in ref_db_list.';
    raise_application_error (-20102, text);
  end if;

  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    del_stmt := 'DELETE FROM ref_model_run_keyval@'||remote_db||' WHERE model_run_id = :1';

    EXECUTE IMMEDIATE del_stmt USING model_run_id_in;

  END LOOP;

  EXCEPTION
   WHEN e_bad_db THEN
     deny_action (text);
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to delete at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on delete_coord_model_run_keyval to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM delete_coord_model_run_keyval for delete_coord_model_run_keyval;
-- Expanding: ./PROCEDURES/get_just_created_model_run_id.prc
/* Determine new model_run_id by selecting largest MRI
   with most recent date_time_loaded where parameters are 
   equal to those passed in. Intended to be called
   only from create_model_run_id procedure, and the Meta Data
   application. */

create or replace PROCEDURE get_just_created_model_run_id ( 
   model_run_id_out             OUT number,
   model_run_name_in            IN varchar2,
   model_id_in                  IN number,
   run_date_in                  IN date,
   num_extra_keys               IN number,
   start_date_in                IN date,
   end_date_in                  IN date,
   hydrologic_indicator_in      IN varchar2,
   modeltype_in                 IN varchar2,
   time_step_descriptor_in      IN varchar2,
   cmmnt_in                     IN varchar2)
IS
  num_ext  varchar2(100);
  st_dt    varchar2(100);
  end_dt   varchar2(100);
  hyd_ind  varchar2(100);
  modtype  varchar2(100);
  tmstp    varchar2(200);
  cmt      varchar2(2000);
  prim_sel_stmt varchar2(1000);
  sec_sel_stmt  varchar2(1000);
  ter_sel_stmt  varchar2(1000);
  where_stmt    varchar2(2000);
  sel_stmt varchar2(2000);
  text varchar2(1000);
BEGIN
  /* Determine new model_run_id by selecting largest MRI
     with most recent date_time_loaded 
     where parameters are equal to those passed in. */
  if (num_extra_keys = 0) then 
    num_ext := 'extra_keys_y_n = ''N''';
  else
    num_ext := 'extra_keys_y_n = ''Y''';
  end if;

  if (start_date_in is null) then 
    st_dt := 'start_date IS NULL';
  else
    st_dt := 'to_date(start_date,''dd-mon-yyyy hh24:mi:ss'') = to_date('''||start_date_in||''',''dd-mon-yyyy hh24:mi:ss'')';
  end if;

  if (end_date_in is null) then 
    end_dt := ' and end_date IS NULL';
  else
    end_dt := ' and to_date(end_date,''dd-mon-yyyy hh24:mi:ss'') = to_date('''||end_date_in||''',''dd-mon-yyyy hh24:mi:ss'')';
  end if;

  if (hydrologic_indicator_in is null) then 
    hyd_ind := ' and hydrologic_indicator IS NULL';
  else
    hyd_ind := ' and hydrologic_indicator = '''||hydrologic_indicator_in||''' ';
  end if;

  if (modeltype_in is null) then 
    modtype := ' and modeltype IS NULL';
  else
    modtype := ' and modeltype = '''||modeltype_in||''' ';
  end if;

  if (time_step_descriptor_in is null) then 
    tmstp := ' and time_step_descriptor IS NULL';
  else
    tmstp := ' and time_step_descriptor = '''||time_step_descriptor_in||''' ';
  end if;

  if (cmmnt_in is null) then 
    cmt := ' and cmmnt IS NULL';
  else
    cmt := ' and cmmnt = '''||cmmnt_in||''' ';
  end if;

  prim_sel_stmt := 'SELECT model_run_id FROM ref_model_run ';
  where_stmt := 'WHERE model_run_name=:1 and model_id=:2 and '||num_ext||' and run_date=:3 and '||st_dt||end_dt||hyd_ind||modtype||tmstp||cmt;
  sec_sel_stmt := ' and date_time_loaded = (select max(date_time_loaded) from ref_model_run ' || where_stmt ||')';
  ter_sel_stmt := ' and model_run_id = (select max(model_run_id) from ref_model_run ' || where_stmt ||')';
  sel_stmt := prim_sel_stmt || where_stmt || sec_sel_stmt || ter_sel_stmt;

  EXECUTE IMMEDIATE sel_stmt INTO model_run_id_out USING model_run_name_in,model_id_in,run_date_in,model_run_name_in,model_id_in,run_date_in,model_run_name_in,model_id_in,run_date_in;

  EXCEPTION
   WHEN OTHERS THEN 
     rollback;
     text := sqlerrm||' when trying to get just created model_run_id';
     deny_action (text);

end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM get_just_created_model_run_id 
  for get_just_created_model_run_id;
BEGIN EXECUTE IMMEDIATE '
grant execute on get_just_created_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/create_model_run_id.prc
/* Will create a new model_run_id with the given attributes.
   The newly-assigned model_run_id is returned in the output
   variable model_run_id_out. Date_time_loaded and user_name
   are set automatically by the table-level trigger.

   Num_extra_keys is the number of key-value pairs this model_run_id
   will be created with.

   Coordinated model_run_ids are handled at the trigger level;
   that is, created as needed.
*/

create or replace PROCEDURE create_model_run_id ( 
   model_run_id_out             OUT number,
   model_run_name_in            IN varchar2,
   model_id_in                  IN number,
   run_date_in                  IN date,
   num_extra_keys               IN number,
   start_date_in                IN date,
   end_date_in                  IN date,
   hydrologic_indicator_in      IN varchar2,
   modeltype_in                 IN varchar2,
   time_step_descriptor_in      IN varchar2,
   cmmnt_in                     IN varchar2,
   extra_keys                   IN varchar2)
IS
  equals_check number;
  comma_check number;
  start_pos number;
  equals_pos number;
  comma_pos number;
  str_size number;
  i number;
  key_name varchar2(32);
  key_value varchar2(32);
  null_date date;

  one_quote varchar2(1);
  two_quotes varchar2(2);
 
  hydrologic_indicator_new varchar2(32);
  time_step_descriptor_new varchar2(128);
  cmmnt_new                varchar2(1000);

  text varchar2(1000);
BEGIN
  one_quote := '''';
  two_quotes := '''''';

  /*  First check for inappropriate NULL values */
  if (model_run_name_in is null) then
      deny_action ( 'Invalid <NULL> model_run_name');
  elsif (model_id_in is null) then
      deny_action ( 'Invalid <NULL> model_id');
  elsif (run_date_in is null) then
      deny_action ( 'Invalid <NULL> run_date');
  elsif (num_extra_keys is null) then
      deny_action ( 'Invalid <NULL> num_extra_keys');
  end if;

  null_date := to_date ('01-jan-1900','dd-mon-yyyy');

  /* Check consistency of extra_keys specification */
  if (num_extra_keys = 0) then
    if (extra_keys is not null) then
      deny_action ('Extra_keys must be NULL when num_extra_keys = 0');
    end if;
  else
    /* Do some checks on the extra_keys string to see if it looks valid */
    /* Not enough pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys)
    into equals_check
    from dual;

    if (equals_check = 0) then
      deny_action ('Extra_keys string does not appear to contain enough key=value pairs; not enough = signs. MRI will not be created.');  
    end if;

    /* Too many pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys+1)
    into equals_check
    from dual;

    if (equals_check > 0) then
      deny_action ('There appears to be more than '||num_extra_keys||' key=value pairs in extra_keys. MRI will not be created.');
    end if;

    /* Not enough delineation? */
    if (num_extra_keys > 1) then
      select instr(extra_keys, ',', 1, num_extra_keys-1)
      into comma_check
      from dual;

      if (comma_check = 0) then
        deny_action ('Cannot delineate key=value pairs in extra_keys string; not enough commas between pairs. MRI will not be created.');  
      end if;
    end if;
  end if; /* num_extra_keys = 0 */

  hydrologic_indicator_new := replace (hydrologic_indicator_in,one_quote,two_quotes);
  time_step_descriptor_new := replace (time_step_descriptor_in,one_quote,two_quotes);
  cmmnt_new := replace (cmmnt_in,one_quote,two_quotes);

  /* Continue with creating model_run_id. */
  insert into ref_model_run (
    model_run_id,
    model_run_name,
    model_id,
    date_time_loaded,
    user_name,
    extra_keys_y_n,
    run_date,
    start_date,
    end_date,
    hydrologic_indicator,
    modeltype,
    time_step_descriptor,
    cmmnt)
   values (
    0,
    model_run_name_in,
    model_id_in,
    null,
    null,
    decode (num_extra_keys, 0, 'N', 'Y'),
    run_date_in,
    start_date_in,
    end_date_in,
    hydrologic_indicator_in,
    modeltype_in,
    time_step_descriptor_in,
    cmmnt_in);

  get_just_created_model_run_id (model_run_id_out, model_run_name_in,
    model_id_in, run_date_in, num_extra_keys, start_date_in, end_date_in,
    hydrologic_indicator_new, modeltype_in, time_step_descriptor_new, 
    cmmnt_new);

  /* Insert key-value pairs */
  if (num_extra_keys <> 0) then
    /* Parse extra_keys and insert row for each pair; if there are
       extra key=value pairs, the MRI will not be created. */
    start_pos := 1;
    for i in 1..num_extra_keys loop
      select instr(extra_keys, '=', 1, i)
      into equals_pos 
      from dual;

      str_size := equals_pos - start_pos;
      key_name := substr (extra_keys, start_pos, str_size);

      if (i < num_extra_keys) then
        select instr(extra_keys, ',', 1, i)
        into comma_pos
        from dual;

        str_size := comma_pos - equals_pos - 1;
        key_value := substr (extra_keys, equals_pos + 1, str_size);
      else
        /* Get the last key_value */
        str_size := length(extra_keys) - equals_pos;
        key_value := substr (extra_keys, equals_pos + 1, str_size);
      end if;

      insert into ref_model_run_keyval (
        model_run_id,
        key_name,
        key_value,
        date_time_loaded)
      values
        (model_run_id_out,
         key_name,
         key_value,
         null);

      start_pos := comma_pos + 1;
    end loop;
  end if; /* num_extra_keys = 0 */

  /* Got through all inserts, local and remote; OK to commit */
  commit;

  EXCEPTION
   WHEN OTHERS THEN 
     rollback;
     text := sqlerrm||' when trying to create new model_run_id';
     deny_action (text);

end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM create_model_run_id for create_model_run_id;
BEGIN EXECUTE IMMEDIATE 'grant execute on create_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/update_model_run_id.prc
/* Will update all attributes of a model_run_id except for
   the model_run_id itself and the model_id. All null-supplied
   attributes remain unchanged. Date_time_loaded and user_name
   are automatically updated by the table-level trigger.

   Note that the parameter num_extra_keys indicates the number
   of key-value pairs being updated, which may or may not be
   the number of key-value pairs associated with the model_run_id.
   Because the model_run_id in question is known -- passed in --
   the number of key-value pairs for the model_run_id is not needed
   to identify it. Only the key_value can be updated, not the key_name.
   The key_name in the extra_keys string specifies which key is to
   be updated.

   Coordinated model_run_ids are handled at the trigger level;
   that is, updated as needed.

   Because this procedure does not allow the addition of new
   key-value pairs, by definition it does not update the value
   of extra_keys_y_n.
*/

create or replace PROCEDURE update_model_run_id ( 
   model_run_id_in              IN number,
   model_run_name_in            IN varchar2,
   run_date_in                  IN date,
   num_extra_keys               IN number,
   start_date_in                IN date,
   end_date_in                  IN date,
   hydrologic_indicator_in      IN varchar2,
   modeltype_in                 IN varchar2,
   time_step_descriptor_in      IN varchar2,
   cmmnt_in                     IN varchar2,
   extra_keys                   IN varchar2,
   ignore_nulls                 IN varchar2)
IS
  equals_check number;
  comma_check number;
  start_pos number;
  equals_pos number;
  comma_pos number;
  str_size number;
  i number;
  v_count number;
  v_key_name varchar2(32);
  v_key_value varchar2(32);

  mr_name  varchar2(100);
  run_dt   varchar2(100);
  st_dt    varchar2(100);
  end_dt   varchar2(100);
  hyd_ind  varchar2(100);
  modtype  varchar2(100);
  tmstp    varchar2(200);
  cmt      varchar2(2000);
  upd_stmt varchar2(2000);
  upd_keyval_stmt varchar2(2000);

  one_quote varchar2(1);
  two_quotes varchar2(2);

  e_no_match  exception;
  PRAGMA EXCEPTION_INIT(e_no_match, -20102);

  text varchar2(1000);
BEGIN
  one_quote := '''';
  two_quotes := '''''';

  /*  First check for inappropriate NULL values */
  if (model_run_id_in is null) then
    deny_action ( 'Invalid <NULL> model_run_id');
  end if;

  /* Before going any further, make sure this model_run_id
     exists. If not, send back an error message. */
  select count(*)
  into v_count
  from ref_model_run
  where model_run_id = model_run_id_in;

  if (v_count = 0) then
    text := 'WARNING! There is no model_run_id = '||model_run_id_in||'. No update processed.';
    raise_application_error (-20102, text);
  end if;

  /* Check consistency of extra_keys specification */
  if (num_extra_keys = 0) then
    if (extra_keys is not null) then
      deny_action ('Extra_keys must be NULL when num_extra_keys = 0');
    end if;
  else
    /* Do some checks on the extra_keys string to see if it looks valid */
    /* Not enough pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys)
    into equals_check
    from dual;

    if (equals_check = 0) then
      deny_action ('Extra_keys string does not appear to contain enough key=value pairs; not enough = signs. MRI will not be updated.');  
    end if;

    /* Too many pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys+1)
    into equals_check
    from dual;

    if (equals_check > 0) then
      deny_action ('There appears to be more than '||num_extra_keys||' key=value pairs in extra_keys. MRI will not be updated.');
    end if;

    /* Not enough delineation? */
    if (num_extra_keys > 1) then
      select instr(extra_keys, ',', 1, num_extra_keys-1)
      into comma_check
      from dual;

      if (comma_check = 0) then
        deny_action ('Cannot delineate key=value pairs in extra_keys string; not enough commas between pairs. MRI will not be updated.');  
      end if;
    end if;
  end if; /* num_extra_keys = 0 */

  /* Continue with updating model_run_id. Need to create a statement
     based on values passed in. */
  if (model_run_name_in is null) then
    mr_name := ' model_run_name = model_run_name,';
  else
    mr_name := ' model_run_name = '''||replace(model_run_name_in,one_quote,two_quotes)||''',';
  end if;

  if (run_date_in is null) then
    run_dt := ' run_date = run_date,';
  else
    run_dt := ' run_date = to_date('''||to_char(run_date_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss''),';
  end if;

  if (start_date_in is null and upper(ignore_nulls) = 'Y') then
    st_dt := ' start_date = start_date,';
  else
    st_dt := ' start_date = to_date('''||to_char(start_date_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss''),';
  end if;

  if (end_date_in is null and upper(ignore_nulls) = 'Y') then
    end_dt := ' end_date = end_date,';
  else
    end_dt := ' end_date = to_date('''||to_char(end_date_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss''),';
  end if;

  if (hydrologic_indicator_in is null and upper(ignore_nulls) = 'Y') then 
    hyd_ind := ' hydrologic_indicator = hydrologic_indicator,';
  else
    hyd_ind := ' hydrologic_indicator = '''||replace(hydrologic_indicator_in,one_quote,two_quotes)||''',';
  end if;

  if (modeltype_in is null and upper(ignore_nulls) = 'Y') then 
    modtype := ' modeltype = modeltype,';
  else
    modtype := ' modeltype = '''||modeltype_in||''',';
  end if;

  if (time_step_descriptor_in is null and upper(ignore_nulls) = 'Y') then 
    tmstp := ' time_step_descriptor = time_step_descriptor,';
  else
    tmstp := ' time_step_descriptor = '''||replace(time_step_descriptor_in,one_quote,two_quotes)||''',';
  end if;

  if (cmmnt_in is null and upper(ignore_nulls) = 'Y') then 
    cmt := ' cmmnt = cmmnt';
  else
    cmt := ' cmmnt = '''||replace(cmmnt_in,one_quote,two_quotes)||'''';
  end if;

  upd_stmt := 'UPDATE ref_model_run SET'||mr_name||run_dt||st_dt||end_dt||hyd_ind||modtype||tmstp||cmt||' WHERE model_run_id = :1';

  EXECUTE IMMEDIATE upd_stmt USING model_run_id_in;

  /* Update key-value pairs */
  if (num_extra_keys <> 0) then
    /* Parse extra_keys and update row for each pair; if there are
       extra key=value pairs, the MRI will not be updated. */
    start_pos := 1;
    for i in 1..num_extra_keys loop
      select instr(extra_keys, '=', 1, i)
      into equals_pos 
      from dual;

      str_size := equals_pos - start_pos;
      v_key_name := substr (extra_keys, start_pos, str_size);

      if (i < num_extra_keys) then
        select instr(extra_keys, ',', 1, i)
        into comma_pos
        from dual;

        str_size := comma_pos - equals_pos - 1; 
        v_key_value := substr (extra_keys, equals_pos + 1, str_size);
      else
        /* Get the last key_value */
        str_size := length(extra_keys) - equals_pos;
        v_key_value := substr (extra_keys, equals_pos + 1, str_size);
      end if;

      /* Before going any further, make sure this key_name
         exists for this model_run_id. If not, send back an error message. */
      select count(*)
      into v_count
      from ref_model_run_keyval
      where model_run_id = model_run_id_in
        and key_name = v_key_name;

      if (v_count = 0) then
        text := 'WARNING! There is no key_name = '''||v_key_name||''' for model_run_id '||model_run_id_in||'. No update processed.';
        raise_application_error (-20102, text);
      end if;

      upd_keyval_stmt := 'UPDATE ref_model_run_keyval SET key_value = '''||replace(v_key_value,one_quote,two_quotes)||''' WHERE model_run_id = :2 and key_name = '''||replace(v_key_name,one_quote,two_quotes)||'''';
      EXECUTE IMMEDIATE upd_keyval_stmt USING model_run_id_in;

      start_pos := comma_pos + 1;
    end loop;
  end if; /* num_extra_keys <> 0 */

  /* Got through all updates, local and remote; OK to commit */
  commit;

  EXCEPTION
   WHEN e_no_match THEN
     deny_action (text);
   WHEN OTHERS THEN 
     rollback;
     text := sqlerrm||' when trying to update MRI '||model_run_id_in;
     deny_action (text);

end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM update_model_run_id for update_model_run_id;
BEGIN EXECUTE IMMEDIATE 'grant execute on update_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/touch_model_run_id.prc
/* Will touch the indicated model_run_id, updating only its
   date_time_loaded and user_name. Coordinated model_run_id
   records are also touched; date_time_loaded and user_name
   are set to the same values as those on the local database. */

create or replace PROCEDURE touch_model_run_id ( 
   model_run_id_in              IN number)
IS
  v_count number;

  upd_stmt varchar2(2000);

  e_no_match  exception;
  PRAGMA EXCEPTION_INIT(e_no_match, -20102);

  text varchar2(1000);
BEGIN
  /*  First check for inappropriate NULL values */
  if (model_run_id_in is null) then
    deny_action ( 'Invalid <NULL> model_run_id');
  end if;

  /* Before going any further, make sure this model_run_id
     exists. If not, send back an error message. */
  select count(*)
  into v_count
  from ref_model_run
  where model_run_id = model_run_id_in;

  if (v_count = 0) then
    text := 'WARNING! There is no model_run_id = '||model_run_id_in||'. No touch processed.';
    raise_application_error (-20102, text);
  end if;

  /* Process a no-action update statement to cause table-level triggers to
     re-set date_time_loaded and user_name. Do not update ref_model_run_keyval;
     its date_time_loaded does not need to match that in ref_model_run. */
  update ref_model_run 
  set extra_keys_y_n = extra_keys_y_n
  where model_run_id = model_run_id_in;

  /* Got through all updates, local and remote; OK to commit */
  commit;

  EXCEPTION
   WHEN e_no_match THEN
     deny_action (text);
   WHEN OTHERS THEN 
     rollback;
     text := sqlerrm||' when trying to touch MRI '||model_run_id_in;
     deny_action (text);

end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM touch_model_run_id for touch_model_run_id;
BEGIN EXECUTE IMMEDIATE 'grant execute on touch_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/delete_model_run_id.prc
/* Will delete specified model_run_id and any associated key-value
   pairs. */


create or replace PROCEDURE delete_model_run_id ( 
   model_run_id_in              IN number)
IS
  text varchar2(1000);
BEGIN
  /*  First check for inappropriate NULL values */
  if (model_run_id_in is null) then
    deny_action ( 'Invalid <NULL> model_run_id');
  end if;

  delete from ref_model_run_keyval
  where model_run_id = model_run_id_in;

  delete from ref_model_run
  where model_run_id = model_run_id_in;

  commit;

  EXCEPTION
   WHEN OTHERS THEN 
     rollback;
     text := sqlerrm||' when trying to delete MRI '||model_run_id_in;
     deny_action (text);

end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM delete_model_run_id for delete_model_run_id;
BEGIN EXECUTE IMMEDIATE 'grant execute on delete_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/get_model_run_id.prc
/* Will get and return a model_run_id based on the supplied
   parameter values, including key-value pairs.

   All parameters can be null except model_id_in.

   If date_time_loaded_in is null, the procedure returns
   the model_run_id with the most recent date_time_loaded
   that matches the other input specifications. 

   For dates that are specified, if the hh24:mi:ss portion
   of the input date is 00:00:00 (either specified as 00:00:00,
   or defaulting to it), then the database date will be matched 
   to the day. If the hh24:mi:ss portion of the input date is
   non-0, then the database date will be matched on the full
   (dd-mon-yyyy hh24:mi:ss) date.

   If num_extra_keys = -1, the procedure does not care how
   many extra keys, if any, the model_run_id has, so long
   as other parameters match. If num_extra_keys = 0, the
   procedure will return only a model_run_id with 0 extra keys
   where all other input specifications are a match. If 
   num_extra_keys > 0, the procedure will return only a 
   model_run_id with exactly n extra keys, where the key names
   and values match those specified in extra_keys, and where all 
   other input specifications are a match.

   The only time that finding more than one matching model_run_id
   is acceptable is in the case where date_time_loaded is left
   null, and the most recently loaded model_run_id is returned. In
   all other cases, finding more than one match causes an error.

   Finding no matches always causes an error.

 */

create or replace PROCEDURE get_model_run_id ( 
   model_run_id_out             OUT number,
   model_run_name_in            IN varchar2,
   model_id_in                  IN number,
   date_time_loaded_in          IN date,
   user_name_in                 IN varchar2,
   num_extra_keys               IN number,
   run_date_in                  IN date,
   start_date_in                IN date,
   end_date_in                  IN date,
   hydrologic_indicator_in      IN varchar2,
   modeltype_in                 IN varchar2,
   time_step_descriptor_in      IN varchar2,
   cmmnt_in                     IN varchar2,
   extra_keys                   IN varchar2)
IS
  equals_check number;
  comma_check number;
  start_pos number;
  equals_pos number;
  comma_pos number;
  str_size number;
  i number;
  v_key_name varchar2(32);
  v_key_value varchar2(32);

  mr_name  varchar2(100);
  rn_dt    varchar2(100);
  usr_name varchar2(100);
  st_dt    varchar2(100);
  end_dt   varchar2(100);
  hyd_ind  varchar2(100);
  modtype  varchar2(100);
  tmstp    varchar2(200);
  cmt      varchar2(2000);

  sel_stmt varchar2(1000);
  where_stmt varchar2(1000);
  not_exists_stmt varchar2(1000);
  key_value_stmt varchar2(1000);  
  mri_stmt varchar2(1000);  
  dt_load  varchar2(2000);
  qry_stmt varchar2(2000);

  one_quote varchar2(1);
  two_quotes varchar2(2);
 
  dt_load_out   DATE;
  text varchar2(1000);
BEGIN
  one_quote := '''';
  two_quotes := '''''';

  model_run_id_out := -1;

  /*  First check for inappropriate NULL values */
  if (model_id_in is null) then
    deny_action ( 'Invalid <NULL> model_id');
  end if;

  if (num_extra_keys is null) then
    deny_action ( 'Invalid <NULL> num_extra_keys');
  end if;

  /* Check consistency of extra_keys specification */
  if (num_extra_keys = 0 or num_extra_keys = -1) then
    if (extra_keys is not null) then
      deny_action ('Extra_keys must be NULL when num_extra_keys = 0 or -1');
    end if;
  else
    /* Do some checks on the extra_keys string to see if it looks valid */
    /* Not enough pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys)
    into equals_check
    from dual;

    if (equals_check = 0) then
      deny_action ('Extra_keys string does not appear to contain enough key=value pairs; not enough = signs.');  
    end if;

    /* Too many pairs? */
    select instr(extra_keys, '=', 1, num_extra_keys+1)
    into equals_check
    from dual;

    if (equals_check > 0) then
      deny_action ('There appears to be more than '||num_extra_keys||' key=value pairs in extra_keys.');
    end if;

    /* Not enough delineation? */
    if (num_extra_keys > 1) then
      select instr(extra_keys, ',', 1, num_extra_keys-1)
      into comma_check
      from dual;

      if (comma_check = 0) then
        deny_action ('Cannot delineate key=value pairs in extra_keys string; not enough commas between pairs.');  
      end if;
    end if;
  end if; /* num_extra_keys = 0 */

  /* Continue with finding model_run_id. Need to create a statement
     based on values passed in. */

  /* If date_time_loaded is null, exclude date_time_loaded clause;
     The ORDER BY date_time_loaded descending will get largest /
     most recent date_time_loaded row first, and the exception
     handler will allow this row in, if indeed there is more than
     one match and date_time_loaded is important. */
  if (date_time_loaded_in is null) then
    dt_load := ' ';
  elsif (to_char(date_time_loaded_in,'hh24:mi:ss') = '00:00:00') then
    dt_load := ' and trunc(a.date_time_loaded) = to_date('''||to_char(date_time_loaded_in,'dd-mon-yyyy')||''',''dd-mon-yyyy'')';
  else
    dt_load := ' and a.date_time_loaded = to_date('''||to_char(date_time_loaded_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss'')';
  end if;

  if (model_run_name_in is null) then
    mr_name := ' ';
  else
    mr_name := ' and lower(model_run_name) like lower(''%'||replace(model_run_name_in,one_quote,two_quotes)||'%'')';
  end if;

  if (user_name_in is null) then
    usr_name := ' ';
  else
    usr_name := ' and lower(user_name) like lower(''%'||replace(user_name_in,one_quote,two_quotes)||'%'')';
  end if;

  if (run_date_in is null) then
    rn_dt := ' ';
  elsif (to_char(run_date_in,'hh24:mi:ss') = '00:00:00') then
    rn_dt := ' and trunc(a.run_date) = to_date('''||to_char(run_date_in,'dd-mon-yyyy')||''',''dd-mon-yyyy'')';
  else
    rn_dt := ' and a.run_date = to_date('''||to_char(run_date_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss'')';
  end if;

  if (start_date_in is null) then
    st_dt := ' ';
  elsif (to_char(start_date_in,'hh24:mi:ss') = '00:00:00') then
    st_dt := ' and trunc(a.start_date) = to_date('''||to_char(start_date_in,'dd-mon-yyyy')||''',''dd-mon-yyyy'')';
  else
    st_dt := ' and a.start_date = to_date('''||to_char(start_date_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss'')';
  end if;

  if (end_date_in is null) then
    end_dt := ' ';
  elsif (to_char(end_date_in,'hh24:mi:ss') = '00:00:00') then
    end_dt := ' and trunc(a.end_date) = to_date('''||to_char(end_date_in,'dd-mon-yyyy')||''',''dd-mon-yyyy'')';
  else
    end_dt := ' and a.end_date = to_date('''||to_char(end_date_in,'dd-mon-yyyy hh24:mi:ss')||''',''dd-mon-yyyy hh24:mi:ss'')';
  end if;

  if (hydrologic_indicator_in is null) then 
    hyd_ind := ' ';
  else
    hyd_ind := ' and lower(hydrologic_indicator) like lower(''%'||replace(hydrologic_indicator_in,one_quote,two_quotes)||'%'')';
  end if;

  if (modeltype_in is null) then 
    modtype := ' ';
  else
    modtype := ' and modeltype = '''||modeltype_in||'''';
  end if;

  if (time_step_descriptor_in is null) then 
    tmstp := ' ';
  else
    tmstp := ' and lower(time_step_descriptor) like lower(''%'||replace(time_step_descriptor_in,one_quote,two_quotes)||'%'')';
  end if;

  if (cmmnt_in is null) then 
    cmt := ' ';
  else
    cmt := ' and lower(cmmnt) like lower(''%'||replace(cmmnt_in,one_quote,two_quotes)||'%'')';
  end if;

  /* Build query statement for when there are no extra keys... */
  if (num_extra_keys = 0) then
    sel_stmt := 'SELECT a.model_run_id, a.date_time_loaded FROM ref_model_run a';
    where_stmt := ' WHERE model_id = :1 and extra_keys_y_n = ''N'' '||mr_name||usr_name||rn_dt||st_dt||end_dt||hyd_ind||modtype||tmstp||cmt;

    not_exists_stmt := ' ';
    key_value_stmt :=  ' ';
    mri_stmt := ' ';
  /* and when we don't care if there are extra keys */
  elsif (num_extra_keys = -1) then
    sel_stmt := 'SELECT a.model_run_id, a.date_time_loaded FROM ref_model_run a';
    where_stmt := ' WHERE model_id = :1 '||mr_name||usr_name||rn_dt||st_dt||end_dt||hyd_ind||modtype||tmstp||cmt;

    not_exists_stmt := ' ';
    key_value_stmt :=  ' ';
    mri_stmt := ' ';
  /* and when there are extra keys... */
  else
    sel_stmt := 'SELECT a.model_run_id, a.date_time_loaded FROM ref_model_run a';
    where_stmt := ' WHERE model_id = :1 and extra_keys_y_n = ''Y'' and a.model_run_id = key1.model_run_id'||mr_name||usr_name||rn_dt||st_dt||end_dt||hyd_ind||modtype||tmstp||cmt;
    not_exists_stmt := ' and not exists (select count(z.model_run_id) from ref_model_run_keyval z where z.model_run_id = key1.model_run_id having count(z.model_run_id) <> '||num_extra_keys||')';

    /* Parse extra_keys and build key_value part of query */
    start_pos := 1;

    for i in 1..num_extra_keys loop
      select instr(extra_keys, '=', 1, i)
      into equals_pos 
      from dual;

      str_size := equals_pos - start_pos;
      v_key_name := substr (extra_keys, start_pos, str_size);

      if (i < num_extra_keys) then
        select instr(extra_keys, ',', 1, i)
        into comma_pos
        from dual;

        str_size := comma_pos - equals_pos - 1;
        v_key_value := substr (extra_keys, equals_pos + 1, str_size);
      else
        /* Get the last key_value */
        str_size := length(extra_keys) - equals_pos;
        v_key_value := substr (extra_keys, equals_pos + 1, str_size);
      end if;

      sel_stmt := concat (sel_stmt, ', ref_model_run_keyval key'||i);
      key_value_stmt := concat (key_value_stmt, ' and key'||i||'.key_name = '''||replace(v_key_name,one_quote,two_quotes)||''' and key'||i||'.key_value = '''||replace(v_key_value,one_quote,two_quotes)||'''');
      if (i > 1) then
        mri_stmt := concat (mri_stmt, ' and key'||i||'.model_run_id = key'||to_char(i-1)||'.model_run_id');
      end if;

      start_pos := comma_pos + 1;
    end loop;

  end if; /* num_extra_keys = 0 */

  /* Add the order by clause so that most recent date_time_loaded
     is guaranteed to be first row returned. */
  qry_stmt := sel_stmt || where_stmt || key_value_stmt || mri_stmt || not_exists_stmt || dt_load ||' order by a.date_time_loaded desc';
 

  /* Execute query */
  EXECUTE IMMEDIATE qry_stmt INTO model_run_id_out, dt_load_out
   USING model_id_in;

  EXCEPTION
   WHEN no_data_found THEN
     deny_action ('No model_run_ids match the input specifications.'); 
   WHEN too_many_rows THEN
     /* Error if we're not getting most recent date_time_loaded where
        there may be more than one match. */
     if (date_time_loaded_in is not null) then 
       deny_action ('More than one model_run_id matches the input specifications.'); 
     end if; 
   WHEN OTHERS THEN 
     rollback;
     text := sqlerrm||' when trying to get model_run_id.';
     deny_action (text);

end;
/

-- show errors;
/
CREATE OR REPLACE PUBLIC SYNONYM get_model_run_id for get_model_run_id;
BEGIN EXECUTE IMMEDIATE 'grant execute on get_model_run_id to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./PROCEDURES/update_coord_mri_archive_cmmnt.prc
CREATE OR REPLACE PROCEDURE update_coord_mri_archive_cmmnt
  (model_run_id_in             IN number,
   model_id_in                  IN number,
   archive_cmmnt_in             IN varchar2) IS

  remote_db varchar2(25);
  db_link   varchar2(25);
  upd_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b
  WHERE b.model_id = model_id_in
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    upd_stmt := 'UPDATE ref_model_run_archive@'||remote_db||' SET archive_cmmnt=:1 WHERE model_run_id=:2 and date_time_archived = (select max(date_time_archived) from ref_model_run_archive@'||remote_db||' WHERE model_run_id = :3)';

    EXECUTE IMMEDIATE upd_stmt USING archive_cmmnt_in, model_run_id_in, 
      model_run_id_in;

  END LOOP;

  EXCEPTION
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to update MRI archive_cmmnt at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on update_coord_mri_archive_cmmnt to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM update_coord_mri_archive_cmmnt for update_coord_mri_archive_cmmnt;
-- Expanding: ./PROCEDURES/update_coord_mri_kv_arch_cmmnt.prc
CREATE OR REPLACE PROCEDURE update_coord_mri_kv_arch_cmmnt
  (model_run_id_in              IN number,
   key_name_in                  IN varchar2,
   archive_cmmnt_in             IN varchar2) IS

  remote_db varchar2(25);
  db_link   varchar2(25);
  upd_stmt  varchar2(1000);
  text      varchar2(1000);

  /* Cursor to get all remote coordinated DBs for
     this model; session_no = 1 is always local db */
  CURSOR remote_coord_dbs IS
  SELECT a.db_site_db_name
  FROM ref_db_list a, hdb_model_coord b, ref_model_run c
  WHERE c.model_run_id = model_run_id_in
   and b.model_id = c.model_id
   AND a.db_site_code = b.db_site_code
   AND a.session_no <> 1;

BEGIN
  FOR db_link IN remote_coord_dbs LOOP
    remote_db := db_link.db_site_db_name;

    upd_stmt := 'UPDATE ref_model_run_keyval_archive@'||remote_db||' SET archive_cmmnt=:1 WHERE model_run_id=:2 and key_name =:3 and date_time_archived = (select max(date_time_archived) from ref_model_run_keyval_archive@'||remote_db||' WHERE model_run_id =:4 and key_name =:5)';

    EXECUTE IMMEDIATE upd_stmt USING archive_cmmnt_in, model_run_id_in, key_name_in, model_run_id_in, key_name_in;

  END LOOP;

  EXCEPTION
   WHEN OTHERS THEN 
     text := sqlerrm||' when trying to update MRI keyval archive_cmmnt at '||remote_db;
     deny_action (text);
END;

/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on update_coord_mri_kv_arch_cmmnt to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM update_coord_mri_kv_arch_cmmnt for update_coord_mri_kv_arch_cmmnt;
-- Expanding: ./PROCEDURES/delete_from_hdb.prc
create or replace
PROCEDURE DELETE_FROM_HDB (
			      SAMPLE_SDI            NUMBER,
			      SAMPLE_DATE_TIME      DATE,
			      SAMPLE_END_TIME       DATE,
                  SAMPLE_INTERVAL       VARCHAR2,
                  LOADING_APP_ID        NUMBER,
                  MODELRUN_ID           NUMBER,
                  AGENCY_ID             NUMBER DEFAULT 33, /* see loading application */
				  TIME_ZONE				VARCHAR2 DEFAULT NULL
)  IS

/*  This procedure was written to be the generic interface to
    delete records from either r_BASE or the model tables in
    HDB from the COMPUTATION application
    this procedure written by Mark Bogner   November 2006          */

/* modified 8/28/07  by M.  Bogner to bring procedure up to date with stated goals  */
/* modified 11/21/07 by M. Bogner to use standardized dates on delete  */
/* modified 5/8/08   by A. Gilmore to use agency_id as parameter  */
/* Modified 06/01/09 by M. Bogner to add mods to accept different time_zone parameter */ 

    /*  first declare all internal variables need for call to delete_r_base
        and to delete_m_table                                               */
    SITE_DATATYPE_ID       R_BASE.SITE_DATATYPE_ID%TYPE;
    INTERVAL               R_BASE.INTERVAL%TYPE;
    START_DATE_TIME        R_BASE.START_DATE_TIME%TYPE;
    END_DATE_TIME          R_BASE.END_DATE_TIME%TYPE;
    AGEN_ID                R_BASE.AGEN_ID%TYPE;
    LOADING_APPLICATION_ID R_BASE.LOADING_APPLICATION_ID%TYPE;
    MODEL_RUN_ID           M_DAY.MODEL_RUN_ID%TYPE;
    db_timezone VARCHAR2(3);

BEGIN

    /*  First check for any required fields that where passed in as NULL  */
    IF SAMPLE_SDI IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_SDI' );
	ELSIF SAMPLE_DATE_TIME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_DATE_TIME' );
--	ELSIF SAMPLE_END_TIME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_END_TIME' );
	ELSIF SAMPLE_INTERVAL IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_INTERVAL' );
	ELSIF LOADING_APP_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> LOADING_APP_ID' );
	ELSIF MODELRUN_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> MODELRUN_ID' );
    END IF;

    /*  now set the variables for the data input parameters     */
    SITE_DATATYPE_ID := SAMPLE_SDI;
    START_DATE_TIME := SAMPLE_DATE_TIME;
    END_DATE_TIME := SAMPLE_END_TIME;
    LOADING_APPLICATION_ID := LOADING_APP_ID;
    MODEL_RUN_ID := MODELRUN_ID;
    INTERVAL :=  SAMPLE_INTERVAL;
    AGEN_ID := AGENCY_ID;

/* get the databases default time zone  */
    BEGIN
      select param_value into db_timezone
        from ref_db_parameter, global_name
        where param_name = 'TIME_ZONE'
        and global_name.global_name = ref_db_parameter.global_name
        and nvl(active_flag,'Y') = 'Y';
       exception when others then 
       db_timezone := NULL;
    END;

  /* now convert the start_time to the database time if different, both exist, 
   and only for the instantaneous and hourly interval           */
   
   IF (TIME_ZONE <> db_timezone AND INTERVAL in ('instant','hour')) THEN
       START_DATE_TIME := new_time(START_DATE_TIME,TIME_ZONE,db_timezone);
       END_DATE_TIME := new_time(END_DATE_TIME,TIME_ZONE,db_timezone);
	END IF;
	
   /* Now call the procedure to standardize the dates to one single date representation  */
   HDB_UTILITIES.STANDARDIZE_DATES(
       SITE_DATATYPE_ID,
       INTERVAL,
       START_DATE_TIME,
       END_DATE_TIME);

    /*  now we should have passed all the logic and validity checks so
    just call the normal procedure to delete data from r_base or an M_ table
    if model_run_id = 0 then delete record from R_BASE otherwise delete it from the model_ tables  */

    IF MODEL_RUN_ID = 0 THEN
      delete_r_base ( SITE_DATATYPE_ID,
                      INTERVAL,
      		          START_DATE_TIME,
  		              END_DATE_TIME,
                      AGEN_ID,
                      LOADING_APPLICATION_ID);
     END IF;

    IF MODEL_RUN_ID > 0 THEN
      delete_m_table ( MODEL_RUN_ID,
                       SITE_DATATYPE_ID,
      		           START_DATE_TIME,
  		               END_DATE_TIME,
                       INTERVAL);
     END IF;

END;  /* end of the procedure  */

/

-- show errors;

create or replace public synonym DELETE_FROM_HDB for DELETE_FROM_HDB;
BEGIN EXECUTE IMMEDIATE 'grant execute on DELETE_FROM_HDB to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on DELETE_FROM_HDB to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/write_to_hdb.prc
CREATE OR REPLACE
PROCEDURE WRITE_TO_HDB (                                                        
			      SAMPLE_SDI            NUMBER,                                          
			      SAMPLE_DATE_TIME      DATE,                                            
			      SAMPLE_VALUE          FLOAT,                                           
                  SAMPLE_INTERVAL       VARCHAR2,                               
                  LOADING_APP_ID        NUMBER,                                 
                  COMPUTE_ID            NUMBER,                                 
                  MODELRUN_ID           NUMBER,                                 
                  VALIDATION_FLAG       CHAR,                                   
                  DATA_FLAGS            VARCHAR2,
                  TIME_ZONE				VARCHAR2 DEFAULT NULL,
                  OVERWRITE_FLAG	    VARCHAR2 DEFAULT NULL,
                  AGEN_ID				NUMBER   DEFAULT NULL, 
			      SAMPLE_END_DATE_TIME  DATE     DEFAULT NULL                                           
)  IS                                                                           
                                                                                
/*  This procedure was written to be the generic interface to                   
    HDB from the DECODES and the COMPUTATION application                        
    this procedure written by Mark Bogner   June 2005                           
                                                                                
    Modified June 2007 by M. Bogner for the new R_BASE data quality flags       
    Modified July 2007 by M. Bogner to add the validation_flag to procedure 
    call
    Modified April 2008 by M. Bogner for new use of method_id for the C.P.       
    Modified June 2009 by M. Bogner to default agen_id to 7 BOR, use time_zone...       
    Modified january 2013 by M. Bogner to add overwrite_flag and AGEN_ID as parameters
    Modified April 16 2013 by M. Bogner to add SAMPLE_END_DATE_TIME as parameter

*/                                                                         
                                                                                
                                                                                
    /*  first declare all internal variables need for call to modify_r_base_raw 
        and to modify m_tables_raw                                              
    */                                                                             
                                                                                
    SITE_DATATYPE_ID       R_BASE.SITE_DATATYPE_ID%TYPE;                        
    INTERVAL               R_BASE.INTERVAL%TYPE;                                
    START_DATE_TIME        R_BASE.START_DATE_TIME%TYPE;                         
    END_DATE_TIME          R_BASE.END_DATE_TIME%TYPE;                           
    VALUE                  R_BASE.VALUE%TYPE;                                   
--  following line Modified since AGEN_ID will be parameter as of Jan 2013
    L_AGEN_ID              R_BASE.AGEN_ID%TYPE;                                 
--  following line commented out since overwrite_flag will be parameter as of Jan 2013
--  OVERWRITE_FLAG         R_BASE.OVERWRITE_FLAG%TYPE;                          
    VALIDATION             R_BASE.VALIDATION%TYPE;                              
    COLLECTION_SYSTEM_ID   R_BASE.COLLECTION_SYSTEM_ID%TYPE;                    
    METHOD_ID              R_BASE.METHOD_ID%TYPE;                               
    COMPUTATION_ID         R_BASE.COMPUTATION_ID%TYPE;                          
    LOADING_APPLICATION_ID R_BASE.LOADING_APPLICATION_ID%TYPE;                  
    MODEL_RUN_ID           M_DAY.MODEL_RUN_ID%TYPE;                             
    QUALITY_FLAGS          R_BASE.DATA_FLAGS%TYPE;                              
	db_timezone		VARCHAR2(3);
                                                                                
    /* some temp variables for use in this procedures  for internal             
       processing and queries  */                                               
                                                                                
    TEMP_NUMBER     NUMBER;                                                     
    DEF_COMP_ID     NUMBER;                                                     
    DEF_METHOD_ID   NUMBER;                                                     
    DEF_COLLECTION_ID   NUMBER;                                                 
    DEF_AGEN_ID     NUMBER;                                                     
    DECODES_ID      NUMBER;                                                     
                                                                                
BEGIN                                                                           
                                                                                

    /*  set these default assignments according to the primary key values in your database  */                                                                  
                                                                                
    DEF_COMP_ID  := 2;    /*  N/A    */                                         
--    DEF_AGEN_ID  := 33;   /* Remove to agree with delete from HDB and all Users   see loading application  */                        
    DEF_AGEN_ID  := 7;   /* BOR if this is what the site wants  */                        
    DEF_METHOD_ID  := 18;   /* unknown  */                                      
    DEF_COLLECTION_ID  := 13;   /* see loading application  */                  
    DECODES_ID    :=  41;   /*  loading application_id for DECODES  */          
                                                                                
    /*  First check for any required fields that where passed in as NULL  */    
    IF SAMPLE_SDI IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_SDI' );     
	ELSIF SAMPLE_DATE_TIME IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_DATE_TIME' );                                                                         
	ELSIF SAMPLE_VALUE IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_VALUE' ); 
	ELSIF SAMPLE_INTERVAL IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SAMPLE_INTERVAL' );                                                                           
	ELSIF LOADING_APP_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> LOADING_APP_ID');                                                                             
	ELSIF MODELRUN_ID IS NULL THEN DENY_ACTION ( 'INVALID <NULL> MODELRUN_ID' );   
    END IF;                                                                     

/* get the databases default time zone  */
    BEGIN
      select param_value into db_timezone
        from ref_db_parameter, global_name
        where param_name = 'TIME_ZONE'
        and global_name.global_name = ref_db_parameter.global_name
        and nvl(active_flag,'Y') = 'Y';
       exception when others then 
       db_timezone := NULL;
    END;
                                                                                
    /*  now set the variables for the data input parameters     */              
    SITE_DATATYPE_ID := SAMPLE_SDI;                                             

    START_DATE_TIME := SAMPLE_DATE_TIME;                                        
    VALUE := SAMPLE_VALUE;                                                      
    COMPUTATION_ID := COMPUTE_ID;                                               
    LOADING_APPLICATION_ID := LOADING_APP_ID;                                   
    MODEL_RUN_ID := MODELRUN_ID;                                                
    VALIDATION := VALIDATION_FLAG;                                              
    QUALITY_FLAGS := DATA_FLAGS;
    L_AGEN_ID := AGEN_ID;                                                
                                                                                
    /* the next two queries should be done only if the data is coming from the 
       DECODES application we will use the loading_application_id for this since 
       its the only indicator we have where the data is comming from                                                          
    */                                                  
                                                                                
    if LOADING_APPLICATION_ID = DECODES_ID THEN                                 
      BEGIN                                                                     
      /*  go get the interval and  method if the users decided to define        
          them and use the generic mapping table for these data      */         
      select a.hdb_interval_name,a.hdb_method_id                                
            into INTERVAL,METHOD_ID                                             
      	  from ref_ext_site_data_map a, hdb_ext_data_source b                    
          where a.hdb_site_datatype_id = site_datatype_id                       
            and a.ext_data_source_id = b.ext_data_source_id                     
            and upper(b.ext_data_source_name) = 'DECODES';                      
                                                                                
      EXCEPTION                                                                 
        WHEN NO_DATA_FOUND THEN  /* don't care, will use defaults.. so do nothing  */                                                                           
        TEMP_NUMBER := 0;                                                       
      END;                                                                      
                                                                                
     ELSIF UPPER(user) = 'CP_PROCESS' THEN  /* then its data from the Computation Processor  */
      BEGIN                                                                     
      /*  go get the method_id from the hdb_method table to indicate that this record came from
      the computation processor. Modified Jan 2013 since the CP should be run with user account CP_PROCESS
      */                                                                
                                                                                
      select method_id into method_id 
      from  hdb_method
      where lower(method_name) like 'computation processor%';
                                                                                
      EXCEPTION                                                                 
        WHEN NO_DATA_FOUND THEN 
        /* don't care, will use defaults.. so do nothing  */                                                                         
        NULL;                                                       
      END;                                                                      

                                                                                
    END IF;  /* the end of queries to do specific to the DECODES Application   */                                                                               

    /*  set all the default system and agency ids for this application          
        since they will be known.  IT was decided to hardcode these to be site  
        specific to reduce the number of queries necessary to put in a R_base 
        record These default settings may need to be changed based on the values 
        at each specific HDB installation  
    */                                           
                                                                                
    /*  Interval query above gives the installation the chance to define a different                                                                            
        interval for a particular site if they want it, otherwise default the interval
        to  to the passed in variable                
    */                         
                                                                                
    if INTERVAL is null THEN                                                    
       INTERVAL :=  SAMPLE_INTERVAL;                                            
    END IF;                                                                     
                                                                                
    IF L_AGEN_ID is NULL THEN  /*  see query above if there is a problem here  */ 
       L_AGEN_ID := DEF_AGEN_ID;         /* see loading application  */           
    END IF;                                                                     
                                                                                
    IF COLLECTION_SYSTEM_ID is NULL THEN                                        
      COLLECTION_SYSTEM_ID := DEF_COLLECTION_ID;    /*  see loading application  */                                                                             
    END IF;                                                                     
                                                                                
    IF METHOD_ID is NULL THEN    /*  possibly already set if user defined method for this SDI  */                                                               
       METHOD_ID := DEF_METHOD_ID;               /* unknown  */                 
    END IF;                                                                     

    IF COMPUTATION_ID is NULL THEN    /*  possibly already set if user defined computation_id for this SDI  */                                                  
       COMPUTATION_ID := DEF_COMP_ID;           /*  N/A  */                     
    END IF;                                                                     
 
 
  /* now convert the start_time to the database time if different, both exist, 
   and only for the instantaneous and hourly interval           */
   
   IF (TIME_ZONE <> db_timezone AND INTERVAL in ('instant','hour')) THEN
       START_DATE_TIME := new_time(START_DATE_TIME,TIME_ZONE,db_timezone);
       END_DATE_TIME := new_time(SAMPLE_END_DATE_TIME,TIME_ZONE,db_timezone);
	END IF;
                                                                                
    /*  now we should have passed all the logic and validity checks so          
    just call the normal procedure to put data into r_base or an M_ table       
    if model_run_id = 0 then insert record into R_BASE otherwise send it to the 
	model_ tables  
	*/                                                               
                                                                             
    IF MODEL_RUN_ID = 0 THEN                                                    
      modify_r_base_raw ( SITE_DATATYPE_ID,                                     
                          INTERVAL,                                             
      			          START_DATE_TIME,                                             
  			              END_DATE_TIME,                                               
			              VALUE,                                                         
                          L_AGEN_ID,                                              
			              OVERWRITE_FLAG,                                                
			              VALIDATION,                                                    
                          COLLECTION_SYSTEM_ID,                                 
                          LOADING_APPLICATION_ID,                               
                          METHOD_ID,                                            
                          COMPUTATION_ID,                                       
                          'Y',                                                  
                          QUALITY_FLAGS);                                       
     END IF;                                                                    
                                                                                
    IF MODEL_RUN_ID > 0 THEN                                                    
      modify_m_table_raw ( MODEL_RUN_ID,                                        
                          SITE_DATATYPE_ID,                                     
      			          START_DATE_TIME,                                             
  			              END_DATE_TIME,                                               
			              VALUE,                                                         
                          INTERVAL,                                             
                          'Y');                                                 
     END IF;                                                                    

                                                                                
END;  /* end of the procedure  */                                               

/

-- show errors;

create or replace public synonym WRITE_TO_HDB for WRITE_TO_HDB;
BEGIN EXECUTE IMMEDIATE 'grant execute on WRITE_TO_HDB to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on WRITE_TO_HDB to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/cp_agg_sum.prc
create or replace PROCEDURE CP_AGG_SUM( P_IN_SDI NUMBER, P_DATE_TIME DATE,
     P_OUT_SDI NUMBER, P_MMDD VARCHAR2)
	IS

	PRAGMA AUTONOMOUS_TRANSACTION; -- Needed to be called from SQL, not necessary from a stored procedure

    /* This cursor uses the dates_between function to get enough dates around the requested dates  */
    CURSOR get_agg_sum (c_sdi NUMBER, c_sdt DATE, c_edt DATE) IS
	select DAYS2.DAYS,DAYS2.RSUM from
	 (select DAYS.days,
      sum(rd.value) Over (order by days.days) "RSUM"
	  from r_day rd,
      (select c_sdi "SDI", date_time "DAYS" from table(dates_between(c_sdt,c_edt+1,'day'))) DAYS
		where  DAYS.days = rd.start_date_time (+)
		and    DAYS.sdi = rd.site_datatype_id (+)
		and    DAYS.days <= sysdate ) DAYS2
	where
	       days2.days >= c_sdt
       and days2.days <= c_edt
       and days2.rsum is not null
	order by 1;

    /* now the local variables needed  */

    l_count NUMBER;
	l_agg_value FLOAT;
    l_SDT  date;
    l_EDT  date;
	l_year number;

	BEGIN
	/* this function calculates the rolling sum of daily values for a
	   user specified start date (P_MMDD) for the whole year period
	*/

	/*  this procedure written by M. Bogner for Eastern Colorado 12/18/2012  
        Validation in Write_to_hdb call changed by IsmailO 10/04/2018 from empty string('') to null due to its type CHAR . 
    */

    /* get the year of the triggering record's date */
    l_year := to_number(to_char(P_DATE_TIME,'yyyy'));

    /*  Compute the begin and end dates for the query based on the P_MMDD parameter  */
    IF to_number(to_char(P_DATE_TIME,'mmdd')) < to_number(P_MMDD) THEN
       /* the triggering value is before the cutoff date  */
       l_SDT := to_date (P_MMDD ||to_char(l_year -1),'mmddyyyy');
       l_EDT := to_date (P_MMDD ||to_char(l_year),'mmddyyyy') - 1;
    ELSE
       /* the triggering value is after the cutoff date  */
       l_SDT := to_date (P_MMDD ||to_char(l_year),'mmddyyyy');
       l_EDT := to_date (P_MMDD ||to_char(l_year +1),'mmddyyyy')- 1;
    END IF;

        /* Loop in cursor records for the interval and perform DML accordingly  */
		FOR p1 IN get_agg_sum(P_IN_SDI,l_SDT,l_EDT) LOOP

		    /* this summing computation works so write it to the DB  */
		    /* use the default value 45 to indicate the CP Process was responsible for this data  */
		    --deny_action (to_char(P_OUT_SDI)||p1.days||round(p1.rsum,5)||'day');

            WRITE_TO_HDB (P_OUT_SDI,p1.days,round(p1.rsum,5),'day',45,2,0,null,null);

		END LOOP;

	   /* now commit this stuff since it is an autonomous transaction  */
	   commit;


	END;
/


-- show errors;

create or replace public synonym CP_AGG_SUM for CP_AGG_SUM;
BEGIN EXECUTE IMMEDIATE 'grant execute on CP_AGG_SUM to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on CP_AGG_SUM to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/mavg_trigger.prc
CREATE OR REPLACE PROCEDURE MAVG_TRIGGER ( P_IN_SDI NUMBER, P_DATE_TIME DATE, 
    P_INTERVAL_WINDOW NUMBER, P_MIN_VALUES_REQUIRED NUMBER, P_OUT_SDI NUMBER,
	P_COMPUTATION_ID NUMBER DEFAULT 2, P_LOADING_ID NUMBER DEFAULT 45) 
	IS
	
	PRAGMA AUTONOMOUS_TRANSACTION; -- Needed to be called from SQL, not necessary from a stored procedure

	return_value FLOAT;  /* keep in case we need to revert back to function  */

    /* special windowing query used for this procedure(function) that will do moving averages	                  */  
    /* This cursor uses the dates_between function to get enough dates around the requested interval  */
    CURSOR get_moving_avg (c_sdi NUMBER, c_intervals NUMBER , c_sdt DATE) IS  
	select HRS2.HOURS,HRS2.RECS,HRS2.MAVG from
	 (select hrs.hours, 
	  sum(decode(rh.site_datatype_id,NULL,0,1)) Over (order by hrs.hours rows between c_intervals-1 preceding and current row) "RECS",
      avg(rh.value) Over (order by hrs.hours rows between c_intervals-1 preceding and current row) "MAVG"
	  from r_hour rh, 
      (select c_sdi "SDI", date_time "HOURS" from table(dates_between(c_sdt-(c_intervals*2)/24,c_sdt+(c_intervals*2)/24,'hour'))) HRS
		where  HRS.hours = rh.start_date_time (+)
		and    HRS.sdi = rh.site_datatype_id (+)) HRS2
	where 
	       hrs2.hours >= c_sdt
       and hrs2.hours <  c_sdt + c_intervals/24  
	order by 1;  

    /* now the local variables needed  */

    l_count NUMBER;
	l_intervals NUMBER;
	l_mvavg_value FLOAT;	

	BEGIN 
	/* this function calculates the moving hourly average of values
	   the interval (number of hours is based on input parameter P_INTERVAL_WINDOW
	   The P_MIN_VALUES_REQUIRED determines if enough records exist to return
	   a value other than null
	*/

	/*  this procedure written by M. Bogner for Eastern Colorado 011/07/2011  
      Mod  by M Bogner 1/27/2015 to add loading_app and computation id as params, not as defaults 
      Validation in Write_to_hdb call changed by IsmailO 10/04/2018 from empty string('') to null due to its type CHAR . 
    */

		return_value := 0;

        /* Loop in cursor records for the interval and perform DML accordingly  */
		FOR p1 IN get_moving_avg(P_IN_SDI,P_INTERVAL_WINDOW,P_DATE_TIME) LOOP

		  /* see if there were enough values to produce the calculation.  If not, delete output */
		  IF p1.recs < P_MIN_VALUES_REQUIRED  THEN
		    DELETE_FROM_HDB (P_OUT_SDI,p1.hours,NULL,'hour',P_LOADING_ID,P_COMPUTATION_ID,0);
		  ELSE 
		    /* this was a good moving average computation so write it to the DB  */
		    /* use the default value 45 to indicate the CP Process was responsible for this data  */
		    return_value := return_value + 1;
		    WRITE_TO_HDB (P_OUT_SDI,p1.hours,round(p1.mavg,5),'hour',P_LOADING_ID,P_COMPUTATION_ID,0,null,null);
		  END IF;

		END LOOP;

	   /* now commit this stuff since it is an autonomous transaction  */
	   commit;

	   /* all processing is done so return the return value  */
       /* Not necessary if used as a procedure               */
--	   --return (return_value);
	END;
/


-- show errors;

create or replace public synonym MAVG_TRIGGER for MAVG_TRIGGER;
BEGIN EXECUTE IMMEDIATE 'grant execute on MAVG_TRIGGER to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on MAVG_TRIGGER to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/modify_site_coef.prc
CREATE OR REPLACE PROCEDURE MODIFY_SITE_COEF ( SITE_ID_IN NUMBER,
                              ATTR_ID_IN NUMBER,
                              COEF_IDX_IN NUMBER,
                              EFFECTIVE_START_DATE_TIME_IN DATE,
                              EFFECTIVE_END_DATE_TIME_IN DATE,
                              COEF_IN FLOAT ) IS
    TEMP_SITE REF_SITE_COEF.SITE_ID%TYPE;
    TEMP_ATTR REF_SITE_COEF.ATTR_ID%TYPE;
    TEMP_SDT REF_SITE_COEF.EFFECTIVE_START_DATE_TIME%TYPE;
    ROWCOUNT NUMBER;
    END_DATE_TIME_NEW DATE;
BEGIN

    /*  First check for any null field that where passed  */

    IF SITE_ID_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> SITE_ID' );
	ELSIF ATTR_ID_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> ATTR_ID' );
	ELSIF EFFECTIVE_START_DATE_TIME_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> EFFECTIVE_START_DATE_TIME' );
	ELSIF COEF_IDX_IN IS NULL THEN DENY_ACTION ( 'INVALID <NULL> COEF_IDX' );
    END IF;

    TEMP_SITE := SITE_ID_IN;
    TEMP_ATTR := ATTR_ID_IN;
    TEMP_SDT := EFFECTIVE_START_DATE_TIME_IN;

    /*  Determine if a record already exists ; if not do an insert otherwise do an update as long as do_update <> 'N'  */

    SELECT count ( * )
      INTO rowcount
      FROM ref_site_coef
      WHERE site_id = TEMP_SITE
       AND attr_id = TEMP_ATTR
       AND effective_start_date_time = TEMP_SDT;

    /* Insert the data into the database  */

    IF rowcount = 0 THEN
	insert into ref_site_coef values
                      ( SITE_ID_IN,
			ATTR_ID_IN,
                        COEF_IDX_IN,
			EFFECTIVE_START_DATE_TIME_IN,
			EFFECTIVE_END_DATE_TIME_IN,
			COEF_IN);

  /*  Update the data into the database, if desired */

        ELSIF rowcount = 1 THEN

	update ref_site_coef set
	effective_end_date_time = EFFECTIVE_END_DATE_TIME_IN,
	coef = COEF_IN
        where site_id = SITE_ID_IN and
        attr_id = ATTR_ID_IN and
        coef_idx = COEF_IDX_IN and
        effective_start_date_time = EFFECTIVE_START_DATE_TIME_IN;

  /*  In case the primary key constraint was disabled */

	ELSIF rowcount > 1 THEN
           DENY_ACTION ( 'RECORD with SITE_ID: ' || to_char ( SITE_ID_IN ) ||
           ' ATTR_ID: ' || ATTR_ID_IN || ' EFFECTIVE_START_DATE_TIME: ' || to_char ( EFFECTIVE_start_date_time_IN,
           'dd-MON-yyyy HH24:MI:SS' ) ||
           ' HAS MULTIPLE ENTRIES. DANGER! DANGER! DANGER!.' );

    END IF;

END;
/

-- show errors;

create or replace public synonym MODIFY_SITE_COEF for MODIFY_SITE_COEF;
BEGIN EXECUTE IMMEDIATE 'grant execute on MODIFY_SITE_COEF to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on MODIFY_SITE_COEF to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./PROCEDURES/get_cgi.prc
create or replace PROCEDURE  GET_HDB_CGI_DATA
/*
Notes:
- This procedure gets data from HDB for use in the CGI program using a 
    specified set of inputs as described below:
      o_cursorOutput  Container for outputs        
      i_sdiList       List of SDI #'s as a CSV
                      example: '1930,2146,2101'
      i_tStep         Data timestep
                      Either 'INSTANT', 'HOUR', 'DAY', 'MONTH', or 'YEAR' only!
      i_startDate     Starting timestep in 'DD-MMM-YYY' format
                      example: '01-JAN-2014'
      i_endDate       Ending timestep in 'DD-MMM-YYY' format
                      example: '31-DEC-2014'            
      i_sourceTable   [Optional] Data table source, the program defaults to 'R'
                      Either 'R' for real, or 'M' for modeled
      i_modelRunIds   [Optional] Required only if i_sourceTable='M'
                      List of MRID #'s as a CSV
                      example: '2191,2054'
- Search for '[JR]' in this code file for areas that could use some work
- POC: Jon Rocha, USBR, jrocha@usbr.gov
 
Change Log:
23JAN2015 - Started program. Succesfully gets data from the 'R' tables
13FEB2015 - Fixed date sorting. Added capability to also get data from the 
            'M' tables
10APR2015 - Added capability to query the INSTANT tables
*/
(
  o_cursorOutput  OUT sys_refcursor,        
  i_sdiList       IN VARCHAR2,              
  i_tstep         IN VARCHAR2,              
  i_startDate     IN VARCHAR2,              
  i_endDate       IN VARCHAR2,              
  i_sourceTable   IN VARCHAR2 DEFAULT 'R',  
  i_modelRunIds   IN VARCHAR2 DEFAULT NULL  
) 
IS
  l_sqlStatement  VARCHAR2(32767);
  l_sdiList VARCHAR2(9999);
  l_startIdx BINARY_INTEGER;
  l_endIdx   BINARY_INTEGER;
  l_curValue VARCHAR2(9999);
  l_tstep VARCHAR2(10);
  l_periodEnd VARCHAR (20);
BEGIN
  l_sdilist := i_sdilist || ',';
  l_startIdx := 0;
  l_endIdx   := instr(l_sdilist, ','); 
  
  IF i_tstep = 'INSTANT' OR i_tstep = 'HOUR' THEN
    l_tstep := 'HOUR';
    l_periodEnd := 'END_DATE_TIME';
  ELSE
    l_tstep := i_tstep;
    l_periodEnd := 'START_DATE_TIME';
  END IF;
    
  -- BUILD OUTER SQL SEARCH STATEMENT
  IF i_sourceTable = 'M' THEN -- GET DATA FROM M TABLES
    l_sqlstatement := 'SELECT HDB_DATETIME, MODEL_RUN_ID, ';
  -- ELSE IF i_sourceTable = '?' THEN -- [JR] FOR BUILDING ADDITIONAL FUNCTIONALITY
  ELSE -- DEFAULT GET DATA FROM R TABLES
    l_sqlstatement := 'SELECT HDB_DATETIME, ';
  END IF;
  
  WHILE(l_endIdx > 0) LOOP -- Loop through each station
    l_curValue := substr(l_sdilist, l_startIdx+1, l_endIdx - l_startIdx - 1);
    l_sqlstatement := l_sqlstatement || 'MAX(CASE WHEN SITE_DATATYPE_ID = ' || 
      l_curValue || ' THEN HDB_VALUE ELSE NULL END) AS SDI_' || l_curValue || 
      ', ';
    l_startIdx := l_endIdx;
    l_endIdx := instr(l_sdilist, ',', l_startIdx + 1);  
  END LOOP;
  
  -- DELETE ENDING COMMA FROM THE LOOP ABOVE
  l_sqlstatement := SUBSTR(l_sqlstatement , 1, INSTR(l_sqlstatement , ',', -1)-1);
    
  -- BUILD INNER SQL SEARCH STATEMENT
  IF i_sourceTable = 'M' THEN -- GET DATA FROM M TABLES
    l_sqlstatement := l_sqlstatement || ' FROM (SELECT SITE_DATATYPE_ID, ' || 
    'MODEL_RUN_ID, ' || l_periodEnd || ' AS HDB_DATETIME, ' ||
    'CAST(VALUE AS VARCHAR(10)) AS HDB_VALUE FROM ' || i_sourcetable || '_' ||
    i_tstep || ' WHERE SITE_DATATYPE_ID IN (' || i_sdiList || 
    ') AND MODEL_RUN_ID IN (' || i_modelrunids || ') ' ||
    'ORDER BY SITE_DATATYPE_ID, ' || l_periodEnd || ') GROUP BY ' || 
    'HDB_DATETIME, MODEL_RUN_ID ORDER BY MODEL_RUN_ID, HDB_DATETIME';
  -- ELSE IF i_sourceTable = '?' THEN -- [JR] FOR BUILDING ADDITIONAL FUNCTIONALITY
  ELSE -- DEFAULT GET DATA FROM R TABLES
    l_sqlstatement := l_sqlstatement || ' FROM (SELECT SITE_DATATYPE_ID, ' || 
    
    -- [JR] NEXT 6 LINES DOES NOT FILL IN MISSING VALUES
    --l_periodEnd || ' AS HDB_DATETIME, ' ||
    --'CAST(VALUE AS VARCHAR(10)) AS HDB_VALUE FROM ' || i_sourcetable || '_' ||
    --i_tstep || ' WHERE SITE_DATATYPE_ID IN (' || i_sdiList || 
    --') AND ' || l_periodEnd || ' >= ''' || i_startdate || ''' AND ' || l_periodEnd || ' <= ''' ||
    --i_enddate || ''' ORDER BY SITE_DATATYPE_ID, ' || l_periodEnd || ') GROUP BY ' || 
    --'HDB_DATETIME ORDER BY HDB_DATETIME';
    
    -- [JR] NEXT 6 LINES FILLS IN MISSING VALUES WITH NULL
    't.DATE_TIME AS HDB_DATETIME, CAST(NVL(VALUE,NULL) AS VARCHAR(10)) AS HDB_VALUE ' ||
    'FROM (' || i_sourcetable || '_' || l_tstep || ') v PARTITION BY (v.SITE_DATATYPE_ID) ' ||
    'RIGHT OUTER JOIN TABLE(DATES_BETWEEN(''' || i_startdate || ''', ''' || i_enddate ||
    ''', LOWER(''' || l_tstep || '''))) t ON v.' || l_periodEnd || ' = t.DATE_TIME WHERE ' ||
    'v.SITE_DATATYPE_ID IN (' || i_sdiList || ')) ' ||
    'GROUP BY HDB_DATETIME ORDER BY HDB_DATETIME';
    
  END IF;
  
  -- EXECUTE
  OPEN o_cursoroutput FOR l_sqlstatement;
  --OPEN o_cursoroutput FOR SELECT l_sqlstatement FROM dual; -- Used for testing
  
  -- CATCH ERRORS
  EXCEPTION WHEN OTHERS THEN
    OPEN o_cursoroutput FOR SELECT 'QUERY ERROR' FROM dual;
    
END GET_HDB_CGI_DATA;
/
-- show errors;
/

create or replace public synonym get_hdb_cgi_data for get_hdb_cgi_data;
BEGIN EXECUTE IMMEDIATE 'grant execute on get_hdb_cgi_data to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on get_hdb_cgi_data to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/




create or replace PROCEDURE  GET_HDB_CGI_INFO 
/*
Notes:
- This procedure gets SDI information  from HDB for use in the external CGI 
    program using a specified set of inputs as described below:
      o_cursorOutput  Container for outputs        
      i_sdiList       List of SDI #'s as a CSV
                      example: '1930,2146,2101'
- Search for '[JR]' in this code file for areas that could use some work
- POC: Jon Rocha, USBR, jrocha@usbr.gov
 
Change Log:
13FEB2015 - Started. Succesfully gets SDI info from HDB
*/
(
  o_cursorOutput  OUT sys_refcursor,        
  i_sdiList       IN VARCHAR2
)
IS
  l_sqlStatement  VARCHAR2(32767);
BEGIN
  l_sqlstatement := 'SELECT HDB_SITE_DATATYPE.SITE_DATATYPE_ID, '||
  'HDB_SITE.SITE_NAME, HDB_DATATYPE.DATATYPE_NAME, HDB_UNIT.UNIT_COMMON_NAME, ' ||
  'HDB_SITE.LAT, HDB_SITE.LONGI, HDB_SITE.ELEVATION, ' || 
  'HDB_SITE.DB_SITE_CODE ' || 
  'FROM HDB_SITE ' ||
  'INNER JOIN HDB_SITE_DATATYPE ' || 
  'ON HDB_SITE.SITE_ID=HDB_SITE_DATATYPE.SITE_ID ' ||
  'INNER JOIN HDB_DATATYPE ' ||
  'ON HDB_SITE_DATATYPE.DATATYPE_ID=HDB_DATATYPE.DATATYPE_ID ' ||
  'INNER JOIN HDB_UNIT ' ||
  'ON HDB_DATATYPE.UNIT_ID=HDB_UNIT.UNIT_ID ' ||
  'WHERE HDB_SITE_DATATYPE.SITE_DATATYPE_ID IN (' || i_sdiList || ') ';

  -- EXECUTE
  OPEN o_cursoroutput FOR l_sqlstatement;
  
  -- CATCH ERRORS
  EXCEPTION WHEN OTHERS THEN
    OPEN o_cursoroutput FOR SELECT 'QUERY ERROR' FROM dual;
    
END GET_HDB_CGI_INFO;
/
-- show errors;
/

create or replace public synonym get_hdb_cgi_info for get_hdb_cgi_info;
BEGIN EXECUTE IMMEDIATE 'grant execute on get_hdb_cgi_info to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on get_hdb_cgi_info to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- spool off
-- exit;

-- Expanding: ./PROCEDURES/refresh_phys_quan_snap_wrap.prc
CREATE OR REPLACE PROCEDURE refresh_phys_quan_snap_wrap (slave_db_site_code IN VARCHAR2) IS
   my_stmt VARCHAR2(1000);
   err_num NUMBER;
   BEGIN
     my_stmt := 'BEGIN run_refresh_phys_quan_snap_' || slave_db_site_code || '; END;';
     err_num := SQLCODE;

     execute immediate my_stmt;

     EXCEPTION
	  when others then
          err_num := SQLCODE;

          if err_num = -6550 then     
            RAISE_APPLICATION_ERROR (-20001, 'identifier not declared'); 
          else 
            RAISE_APPLICATION_ERROR (-20002, 'some other error');
          end if;

   END refresh_phys_quan_snap_wrap;
/
-- show errors
/
BEGIN EXECUTE IMMEDIATE '
grant execute on refresh_phys_quan_snap_wrap to czar_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

--drop public synonym refresh_phys_quan_snap_wrap;
CREATE OR REPLACE PUBLIC SYNONYM refresh_phys_quan_snap_wrap for refresh_phys_quan_snap_wrap;

-- Expanding: ./METADATA/checkSupersystemConnection.sql
CREATE OR REPLACE FUNCTION check_supersystem_connection (select_string IN VARCHAR2) RETURN INTEGER IS
   test_count INTEGER;
   BEGIN
    test_count := -1;
    execute immediate select_string into test_count;

    if (test_count >= 0) then
     return (0);
    end if;

   EXCEPTION
     WHEN OTHERS THEN
       return (-1);

   END check_supersystem_connection;
/
BEGIN EXECUTE IMMEDIATE '
grant execute on check_supersystem_connection to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

--drop public synonym check_supersystem_connection;
CREATE OR REPLACE PUBLIC SYNONYM check_supersystem_connection for check_supersystem_connection;
-- set echo on
-- set feedback on
-- spool hdb_views.out

-- Expanding: ./VIEWS/acl_view.view
create or replace view ACL_VIEW as
select hdb_site.site_id,hdb_site.site_name,ref_site_attr.string_value "GROUP_NAME"
from hdb_site,ref_site_attr
where ref_site_attr.attr_id = hdb_utilities.get_site_acl_attr
and   ref_site_attr.site_id = hdb_site.site_id;

create or replace public synonym ACL_VIEW for ACL_VIEW;
BEGIN EXECUTE IMMEDIATE 'grant select on ACL_VIEW to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./VIEWS/engineeringunit.view

/* The view against HDB_UNIT table is still needed to interface correctly with DECODES   */
/* now  create the view to make it look like a decodes table for the engineering unit table  */
/* and give the right permissions to this view  */
create or replace view unit_to_decodes_unit_view as
select a.unit_common_name "UNITABBR", a.unit_name "NAME",
a.family, b.dimension_name "MEASURES"
from hdb_unit a, hdb_dimension b
where a.dimension_id = b.dimension_id;
BEGIN EXECUTE IMMEDIATE '
grant select on unit_to_decodes_unit_view to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on unit_to_decodes_unit_view to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

create or replace public synonym engineeringunit for unit_to_decodes_unit_view;


-- Expanding: ./VIEWS/decodes_site.view
/* now the view for the decodes site table  */
/* create the sites view for the decode site table  */
/* this view modified 12/13/06 by M.Bogner  to eliminate record redundancies  */

create or replace view SITE_TO_DECODES_SITE_VIEW as
select a.site_id "ID", a.lat "LATITUDE", a.longi "LONGITUDE",
b.nearestcity,b.state,b.region, b.timezone,b.country,a.elevation,b.elevunitabbr,
substr(a.site_name||chr(10)||a.description,1,801) "DESCRIPTION"
from hdb_site a, decodes_site_ext b, ref_db_list d
where a.site_id = b.site_id(+)
and d.db_site_code = a.db_site_code
and d.session_no = 1;
BEGIN EXECUTE IMMEDIATE '

grant select on site_to_decodes_site_view to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on site_to_decodes_site_view to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

create or replace public synonym site for site_to_decodes_site_view;



-- Expanding: ./VIEWS/decodes_sitename.view
/* now the view for the DECODES sitename table  */

create or replace view site_to_decodes_name_view as
  SELECT 
-- THIS VIEW MODIFIED TWO PLACES BY M. BOGNER 04022013 FOR PROPER 
-- CP AND OPENDCS OPERATIONS.  SEE COMMENTS BELOW
    siteid,
    nametype,
    sitename,
    dbnum,
    agency_cd
  FROM
    (SELECT a.hdb_site_id "SITEID",
      b.ext_site_code_sys_name "NAMETYPE",
      a.primary_site_code "SITENAME",
      SUBSTR(SUBSTR(secondary_site_code,1,instr(secondary_site_code,'|')-1),1,2) "DBNUM",
      SUBSTR(secondary_site_code,instr(secondary_site_code,'|')         +1,5) "AGENCY_CD",
      f.sortnumber sortnum
    FROM hdb_ext_site_code a,
      hdb_ext_site_code_sys b,
      hdb_site c,
      ref_db_list d,
      decodes.enum e,
      decodes.enumvalue f
    WHERE a.ext_site_code_sys_id  = b.ext_site_code_sys_id
    AND a.hdb_site_id             = c.site_id
    AND c.db_site_code            = d.db_site_code
    AND d.session_no              = 1
    AND e.name                    = 'SiteNameType'
    AND e.id                      = f.enumid
    AND f.enumvalue               = b.ext_site_code_sys_name
    AND b.ext_site_code_sys_name <> 'hdb'
    UNION
    SELECT c.site_id,
      f.enumvalue,
---   TRANSLATE THE NAME TO GET RID OF PARENTHESIS AND PERIODS IN THE SITENAME
--    SINCE THIS CAUSES ISSUES WITH THE CP AND OPENDCS
--    TRANSLATE ADDED BY M. BOGNER 04022013
      TO_CHAR(translate(c.site_name,'().','|| ')
      || ': '
      || c.site_id
      || ': '
      ||c.description),
      NULL,
      NULL,
      f.sortnumber sortnum
    FROM hdb_site c,
      decodes.enum e,
      decodes.enumvalue f,
      ref_db_list d
    WHERE e.name       = 'SiteNameType'
    AND e.id           = f.enumid
    AND f.enumvalue    = 'hdb'
    AND c.db_site_code = d.db_site_code
    AND d.session_no   = 1
    ORDER BY sortnum
    );
BEGIN EXECUTE IMMEDIATE '

grant select on site_to_decodes_name_view to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on site_to_decodes_name_view to decodes_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

create or replace public synonym sitename for site_to_decodes_name_view;


-- Expanding: ./VIEWS/hdb_computed_datatype.view
-- this view is a replacement for the hdb_computed_dataype table that
-- was replaced with the cp_computation table once the computation processor went live in 2008

create or replace view hdb_computed_datatype as
select computation_id,computation_name,
to_number(null) "DATATYPE_ID",cmmnt
 from cp_computation where computation_id < 100;

create or replace public synonym hdb_computed_datatype for hdb_computed_datatype;
BEGIN EXECUTE IMMEDIATE 'grant select on hdb_computed_datatype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./VIEWS/cp_active_sdi_tsparm_view.view
create or replace view cp_active_sdi_tsparm_view
as
/* this view written by M. Bogner CADSWES APRIL 2006
   the purpose of this view is to select all site_datatype_ids and the respective
   loading application_id for all active definitions for the sdi's that are defined as
   input parameters for some defined calculation                                        
   modified by M. Bogner Jan 2008 to get a few more columns from the same tables
*/
/* Modified by M. Bogner May 2012 to change the view to look at the new CP_TS_ID and
   the CP_COMP_DEPENDS Table. I decided changing the view was  more effective than to 
   change every time series table trigger. The effective dates were made to be a very wide
   range since the effective check will now be performed within the CP code
                                                                                        */
select distinct ccts.site_datatype_id, ccts.interval, ccts.table_selector, cc.loading_application_id, 
       to_date(1,'J') "EFFECTIVE_START_DATE_TIME",
       sysdate+365000 "EFFECTIVE_END_DATE_TIME",
       ccts.ts_id,
       ccts.model_id, ca.algorithm_id,ca.algorithm_name, cc.computation_id, cc.computation_name
from  cp_computation cc, cp_ts_id ccts, cp_algorithm ca, cp_comp_depends ccd
where 
       cc.enabled = 'Y' 
  and  cc.loading_application_id is not null
  and  cc.computation_id = ccd.computation_id
  and  cc.algorithm_id = ca.algorithm_id
  and  ccd.ts_id = ccts.ts_id;

/* might as well give a public select for this view  */
create or replace public synonym cp_active_sdi_tsparm_view for cp_active_sdi_tsparm_view;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_active_sdi_tsparm_view to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/*
This was the old way of doing the view before phase 3.0 which is the application of groups to
the Computation processor.  It was a programming decision to change the view instead of all the triggers
  
select ccts.site_datatype_id, ccts.interval, ccts.table_selector, cc.loading_application_id, 
       nvl(cc.effective_start_date_time,to_date(1,'J')) "EFFECTIVE_START_DATE_TIME",
       nvl(cc.effective_end_date_time,sysdate+365000) "EFFECTIVE_END_DATE_TIME",
       ccts.model_id, ca.algorithm_id,ca.algorithm_name, cc.computation_id, cc.computation_name
from  cp_computation cc, cp_comp_ts_parm ccts, cp_algorithm ca, cp_algo_ts_parm catp
where 
       cc.enabled = 'Y' 
  and  cc.loading_application_id is not null
  and  cc.computation_id = ccts.computation_id
  and  cc.algorithm_id = ca.algorithm_id
  and  ca.algorithm_id = catp.algorithm_id
  and  ccts.algo_role_name = catp.algo_role_name
  and  catp.parm_type like 'i%';

*/
-- Expanding: ./VIEWS/cp_active_remote_sdi_view.view
create or replace view cp_active_remote_sdi_view
("SITE_DATATYPE_ID","INTERVAL","TABLE_SELECTOR","TABLE_NAME","DB_LINK","EFFECTIVE_START_DATE_TIME",
 "EFFECTIVE_END_DATE_TIME")
as
/* this view written by M. Bogner SUTRON 2010
   the purpose of this view is to select all site_datatype_ids and the respective
   row data for all active definitions for the sdi's that are defined as
   input parameters for remotely defined calculations                                        
*/
select distinct crt.site_datatype_id, crt.interval, crt.table_selector, 
	upper(crt.table_selector|| crt.interval),crt.db_link,
	nvl(crt.effective_start_date_time,to_date(1,'J')),
	nvl(crt.effective_end_date_time,sysdate+365000)
from  cp_remote_triggering crt, ref_db_parameter dbp, global_name gn
where 
       crt.active_flag = 'Y' 
  and  dbp.active_flag = 'Y'
  and  dbp.param_name = 'REMOTE COMPUTATIONS'
  and  dbp.global_name = gn.global_name;
  
-- Expanding: ./VIEWS/cp_input_output_view.view
create or replace view  cp_input_output_view
("COMPUTATION_ID","INPUT_TSID","INPUT_SDI","INPUT_INTERVAL","INPUT_TABLE_SELECTOR","INPUT_MODEL_ID",
 "INPUT_DELTA_T","INPUT_DELTA_T_UNITS",
 "OUTPUT_TSID","OUTPUT_SDI","OUTPUT_INTERVAL","OUTPUT_TABLE_SELECTOR","OUTPUT_MODEL_ID","ENABLED")
 as
/* this view written by M. Bogner Sutron Corp April 2013
   the purpose of this view is to select all active computations and the respective
   input and output parameters' definitions for each defined calculation                                        
   MODIFIED:  30-DECEMBER-2013 by M. Bogner to include DISABLED non-group computations
   to aid in the query of computations in the OPENDCS application
*/
		select distinct
        ccd.computation_id,  
        cti.ts_id,
	    cti.site_datatype_id, 
        cti.interval,
        cti.table_selector,
        nvl(cti.model_id,-1),
        ccts2.DELTA_T,
        ccts2.DELTA_T_UNITS,
        CP_PROCESSOR.GET_TS_ID(
          decode(nvl(ccts.site_datatype_id,-1),-1,cti.site_datatype_id,ccts.site_datatype_id), 
          ccts.interval,
          ccts.table_selector,
          ccts.model_id),
	    decode(nvl(ccts.site_datatype_id,-1),-1,cti.site_datatype_id,ccts.site_datatype_id), 
        ccts.interval,
        ccts.table_selector,
        nvl(ccts.model_id,-1),
        'ENABLED'
	from  cp_computation cc, cp_comp_ts_parm ccts, cp_algorithm ca, cp_comp_ts_parm ccts2,
		  cp_algo_ts_parm catp, cp_comp_depends ccd, cp_ts_id cti
	where
		 cc.computation_id = ccd.computation_id
    and  cti.ts_id = ccd.ts_id
	and  cc.computation_id = ccts.computation_id
	and  cc.algorithm_id = ca.algorithm_id
	and  ca.algorithm_id = catp.algorithm_id
	and  ccts.algo_role_name = catp.algo_role_name
	and  catp.parm_type like 'o%'
	and  ccts2.computation_id = ccts.computation_id
UNION
/* this union added 12/30/2014 by M. Bogner to get all enabled non-group computations with no output parametere */
	select distinct
     ccd.computation_id,  
     cti.ts_id,
	 cti.site_datatype_id, 
     cti.interval,
     cti.table_selector,
     nvl(cti.model_id,-1),
     ccts.DELTA_T,
     ccts.DELTA_T_UNITS,
     null,
     null,
     null,
     null,
     null,
     'ENABLED (NO OUTPUT PARAMETER)'
	from  cp_computation cc, cp_comp_ts_parm ccts, 
        cp_comp_ts_parm ccts2,
		    cp_comp_depends ccd, cp_ts_id cti
	where
         cc.computation_id = ccd.computation_id
    and  cti.ts_id = ccd.ts_id
	and  cc.computation_id = ccts.computation_id
    and  cc.computation_id not in 
    (select distinct
        cc.computation_id  
	from  cp_computation cc, cp_comp_ts_parm ccts, cp_algorithm ca,
		  cp_algo_ts_parm catp
	where
	     cc.algorithm_id = ca.algorithm_id
    and  cc.computation_id = ccts.computation_id
	and  ca.algorithm_id = catp.algorithm_id
	and  ccts.algo_role_name = catp.algo_role_name
	and  catp.parm_type like 'o%')
UNION
/* this union added 12/30/2013 by M. Bogner to get all disabled non-group computations  */
		select distinct
        cc.computation_id,  
        CP_PROCESSOR.GET_TS_ID(ccts.site_datatype_id, ccts.interval,ccts.table_selector,nvl(ccts.model_id,-1)),
	    ccts.site_datatype_id, 
        ccts.interval,
        ccts.table_selector,
        nvl(ccts.model_id,-1),
        ccts.DELTA_T,
        ccts.DELTA_T_UNITS,
        CP_PROCESSOR.GET_TS_ID(ccts2.site_datatype_id, ccts2.interval,ccts2.table_selector,nvl(ccts2.model_id,-1)),
	    ccts2.site_datatype_id, 
        ccts2.interval,
        ccts2.table_selector,
        nvl(ccts2.model_id,-1),
        'DISABLED'
	from  cp_computation cc, cp_comp_ts_parm ccts, cp_algorithm ca1, cp_comp_ts_parm ccts2,
		  cp_algo_ts_parm catp1, cp_algorithm ca2, cp_algo_ts_parm catp2
	where
		 NVL(cc.enabled,'N') <> 'Y'
	and  cc.group_id is null
	and  cc.computation_id = ccts.computation_id
	and  cc.computation_id = ccts2.computation_id
	and  cc.algorithm_id = ca1.algorithm_id
	and  cc.algorithm_id = ca2.algorithm_id
	and  ca1.algorithm_id = catp1.algorithm_id
	and  ca2.algorithm_id = catp2.algorithm_id
	and  ccts.algo_role_name = catp1.algo_role_name
	and  ccts2.algo_role_name = catp2.algo_role_name
	and  catp1.parm_type like 'i%'
	and  catp2.parm_type like 'o%';

create or replace public synonym cp_input_output_view for cp_input_output_view;
BEGIN EXECUTE IMMEDIATE 'grant select on cp_input_output_view to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./VIEWS/days.view
CREATE OR REPLACE FORCE VIEW DAYS
 ( "START_DATE_TIME"
  )  AS 
  select to_date('01-OCT-1877','DD-MON-YYYY') + rownum  start_date_time
from r_day where rownum between 0 and 50000 ;
BEGIN EXECUTE IMMEDIATE 'grant select on DAYS to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./VIEWS/dba_roles.view
CREATE OR REPLACE FORCE VIEW V_DBA_ROLES 
 ( "ROLE"
  )  AS 
  select role from dba_roles
where password_required = 'YES';
BEGIN EXECUTE IMMEDIATE '
grant select on V_DBA_ROLES to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./VIEWS/hdb_datatype_unit.view
CREATE OR REPLACE FORCE VIEW HDB_DATATYPE_UNIT 
 ( "UNIT_IND", "DEST_ID", "DEST_NAME", "DIMENSION_NAME"
  )  AS 
  select 'D' unit_ind, datatype_id dest_id, datatype_name dest_name,
  dimension_name dimension_name
from hdb_datatype, hdb_dimension, hdb_unit
where hdb_datatype.unit_id = hdb_unit.unit_id
  and hdb_unit.dimension_id = hdb_dimension.dimension_id
union
select 'U' unit_ind, unit_id dest_id, unit_name dest_name, null
from hdb_unit;
BEGIN EXECUTE IMMEDIATE '
grant select on HDB_DATATYPE_UNIT to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./VIEWS/hdb_site_datatype_name.view

CREATE OR REPLACE FORCE VIEW V_HDB_SITE_DATATYPE_NAME 
 ( "SITE_DATATYPE_ID", "S_D_NAME"
  )  AS 
  SELECT site_datatype_id, site_name||'---'||datatype_common_name s_d_name
FROM hdb_site_datatype, hdb_site, hdb_datatype
WHERE
     hdb_site_datatype.site_id = hdb_site.site_id
AND  hdb_site_datatype.datatype_id = hdb_datatype.datatype_id ; 
BEGIN EXECUTE IMMEDIATE '
grant select on V_HDB_SITE_DATATYPE_NAME to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- spool off
-- exit;
-- set echo on
-- set feeback on
-- spool hdb_constraints.out

-- Expanding: ./CONSTRAINTS/decodes_site_ext.ddl
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE DECODES_Site_ext ADD CONSTRAINT
 decodes_site_ext_fk1 FOREIGN KEY
  (SITE_ID) REFERENCES ${hdb_user}.HDB_SITE
  (SITE_ID)
  ON DELETE CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_attr_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_attr
add constraint hdb_attr_fk1
foreign key    (unit_id)
REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_attr add constraint
    check_attr_value_type
      check (attr_value_type in (''number'', ''string'', ''date''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_attr_feature_ref.ddl
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE hdb_attr_feature
add constraint hdb_attr_feature_fk1
foreign key (attr_id)
REFERENCES ${hdb_user}.hdb_attr (attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE hdb_attr_feature
add constraint hdb_attr_feature_fk2
foreign key (feature_class_id, feature_id)
REFERENCES ${hdb_user}.hdb_feature (feature_class_id, feature_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/* start ./CONSTRAINTS/hdb_computed_datatype_component_ref.ddl; */
/* start ./CONSTRAINTS/hdb_computed_datatype_ref.ddl;  */
-- Expanding: ./CONSTRAINTS/hdb_datatype_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_datatype
add constraint hdb_datatype_fk1
foreign key    (physical_quantity_name)
REFERENCES ${hdb_user}.hdb_physical_quantity(physical_quantity_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_datatype
add constraint hdb_datatype_fk2
foreign key    (unit_id)
REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_datatype
add constraint hdb_datatype_fk3
foreign key    (agen_id)
REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    hdb_datatype
add
   constraint  hdb_datatype_ck1
   check       (allowable_intervals in (''non-instant'',''instant'',''either''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./CONSTRAINTS/hdb_datatype_feature_ref.ddl
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE hdb_datatype_feature
add constraint hdb_datatype_feature_fk1
foreign key (datatype_id)
REFERENCES ${hdb_user}.hdb_datatype (datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE hdb_datatype_feature
add constraint hdb_datatype_feature_fk2
foreign key (feature_class_id, feature_id)
REFERENCES ${hdb_user}.hdb_feature (feature_class_id, feature_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_dmi_unit_map_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_dmi_unit_map
add
   constraint    hdb_dmi_unit_map_fk1
   foreign key   (unit_id)
   REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_ext_site_code_sys_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_ext_site_code_sys
add
  constraint  hdb_ext_site_code_sys_fk1
  foreign key (agen_id)
  REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_site_code_sys
add
  constraint  hdb_ext_site_code_sys_fk2
  foreign key (model_id)
  REFERENCES ${hdb_user}.hdb_model(model_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_ext_data_code_sys_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_ext_data_code_sys
add
  constraint  hdb_ext_data_code_sys_fk1
  foreign key (agen_id)
  REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_data_code_sys
add
  constraint  hdb_ext_data_code_sys_fk2
  foreign key (model_id)
  REFERENCES ${hdb_user}.hdb_model(model_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_ext_site_code_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_ext_site_code
add
  constraint  hdb_ext_site_code_fk1
  foreign key (ext_site_code_sys_id)
  REFERENCES ${hdb_user}.hdb_ext_site_code_sys(ext_site_code_sys_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_site_code
add
  constraint  hdb_ext_site_code_fk2
  foreign key (hdb_site_id)
  REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_ext_data_code_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_ext_data_code
add
  constraint  hdb_ext_data_code_fk1
  foreign key (ext_data_code_sys_id)
  REFERENCES ${hdb_user}.hdb_ext_data_code_sys(ext_data_code_sys_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_data_code
add
  constraint  hdb_ext_data_code_fk2
  foreign key (hdb_datatype_id)
  REFERENCES ${hdb_user}.hdb_datatype(datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_ext_data_source_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_ext_data_source
add
  constraint  hdb_ext_data_source_fk1
  foreign key (agen_id)
  REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_data_source
add
  constraint  hdb_ext_data_source_fk2
  foreign key (model_id)
  REFERENCES ${hdb_user}.hdb_model(model_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_data_source
add
  constraint  hdb_ext_data_source_fk3
  foreign key (ext_site_code_sys_id)
  REFERENCES ${hdb_user}.hdb_ext_site_code_sys(ext_site_code_sys_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_data_source
add
  constraint  hdb_ext_data_source_fk4
  foreign key (ext_data_code_sys_id)
  REFERENCES ${hdb_user}.hdb_ext_data_code_sys(ext_data_code_sys_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_ext_data_source
add
  constraint  hdb_ext_data_source_fk5
  foreign key (collection_system_id)
  REFERENCES ${hdb_user}.hdb_collection_system(collection_system_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_feature_ref.ddl
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE hdb_feature
add constraint hdb_feature_fk1
foreign key (feature_class_id)
REFERENCES ${hdb_user}.hdb_feature_class (feature_class_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_feature_property_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_feature_property
add constraint hdb_feature_property_fk1
foreign key    (feature_id)
REFERENCES ${hdb_user}.hdb_feature(feature_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_feature_property
add constraint hdb_feature_property_fk2
foreign key    (property_id)
REFERENCES ${hdb_user}.hdb_property(property_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_interval_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_interval
add constraint hdb_interval_fk1
foreign key    (previous_interval_name)
REFERENCES ${hdb_user}.hdb_interval(interval_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_interval
add constraint hdb_interval_fk2
foreign key    (interval_unit)
REFERENCES ${hdb_user}.hdb_date_time_unit(date_time_unit)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_method_class_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_method_class
add constraint hdb_method_class_fk1
foreign key    (method_class_type)
REFERENCES ${hdb_user}.hdb_method_class_type (method_class_type)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_method_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_method
add constraint hdb_method_fk1
foreign key    (method_class_id)
REFERENCES ${hdb_user}.hdb_method_class (method_class_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_model_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_model
add constraint hdb_model_ck1
check (coordinated in (''Y'',''N''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_model_coord_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_model_coord
add constraint hdb_model_coord_fk1
foreign key (model_id)
REFERENCES ${hdb_user}.hdb_model (model_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_model_coord
add constraint hdb_model_coord_fk2
foreign key (db_site_code)
references ref_db_list (db_site_code)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_physical_quantity_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_physical_quantity
add constraint hdb_physical_quantity_fk1
foreign key    (dimension_id)
REFERENCES ${hdb_user}.hdb_dimension(dimension_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_physical_quantity
add constraint hdb_physical_quantity_fk2
foreign key    (customary_unit_id)
REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_property_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_property
add constraint hdb_property_fk1
foreign key    (unit_id)
REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_property add constraint
    check_property_value_type
      check (property_value_type in (''number'', ''string'', ''date''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/hdb_rating_type.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_rating_type
add constraint hdb_rating_algorithm_fk1 
foreign key (rating_algorithm)
REFERENCES ${hdb_user}.hdb_rating_algorithm (rating_algorithm)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_river_reach_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table  hdb_river_reach
add 
   constraint hdb_river_reach_fk1
   foreign key (river_id)
   REFERENCES ${hdb_user}.hdb_river(river_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_site_datatype_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_site_datatype
add constraint hdb_site_datatype_fk1
foreign key    (site_id)
REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site_datatype
add constraint hdb_site_datatype_fk2
foreign key   (datatype_id)
REFERENCES ${hdb_user}.hdb_datatype ( datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_site_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_site
add
  constraint  hdb_site_fk1
  foreign key (objecttype_id)
  REFERENCES ${hdb_user}.hdb_objecttype(objecttype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site
add
  constraint  hdb_site_fk2
  foreign key (parent_site_id)
  REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site
add
  constraint  hdb_site_fk3
  foreign key (parent_objecttype_id)
  REFERENCES ${hdb_user}.hdb_objecttype(objecttype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site
add
  constraint  hdb_site_fk4
  foreign key (hydrologic_unit,segment_no)
  REFERENCES ${hdb_user}.hdb_river_reach(hydrologic_unit,segment_no)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site
add
  constraint  hdb_site_fk5
  foreign key (state_id)
  REFERENCES ${hdb_user}.hdb_state(state_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site
add
  constraint  hdb_site_fk6
  foreign key (basin_id)
  REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_site
add
    constraint   hdb_site_fk7
    foreign key  (db_site_code)
    references   ref_db_list(db_site_code)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/hdb_unit_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table hdb_unit
add constraint hdb_unit_fk1
foreign key    (dimension_id)
REFERENCES ${hdb_user}.hdb_dimension(dimension_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_unit
add constraint hdb_unit_fk2
foreign key    (base_unit_id)
REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table hdb_unit
add constraint
check_is_factor
check (is_factor in (0,1))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- start ./CONSTRAINTS/ref_agg_disagg_ref.ddl; removed for CP Project 10/2022
-- Expanding: ./CONSTRAINTS/ref_app_data_source_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_app_data_source
add constraint ref_app_data_sourcefk1
foreign key    (source_id)
REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_auth_site_datatype_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_auth_site_datatype
add constraint ref_auth_site_dt_fk1
foreign key    (site_datatype_id)
REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_auth_site_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_auth_site
add constraint ref_auth_site_fk1
foreign key    (site_id)
REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- start ./CONSTRAINTS/ref_derivation_destination_ref.ddl;  removed for CP Project
-- start ./CONSTRAINTS/ref_derivation_source_ref.ddl;  removed for CP Project
-- Expanding: ./CONSTRAINTS/ref_div_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_div
add   
    constraint   ref_div_fk1
    foreign key  (site_id)
    REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_div
add   
    constraint   ref_div_fk2
    foreign key  (divtype)
    REFERENCES ${hdb_user}.hdb_divtype(divtype)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- start ./CONSTRAINTS/ref_dmi_data_map_ref.ddl; removed for CP Project 10/2022
-- Expanding: ./CONSTRAINTS/ref_ensemble_ref.ddl
--  foreign key for table REF_ENSEMBLE on agen_id from hdb_agen
BEGIN EXECUTE IMMEDIATE 'alter table REF_ENSEMBLE add constraint REF_ENSEMBLE_AGEN_ID_FK 
foreign key (agen_id) 
REFERENCES ${hdb_user}.hdb_agen (agen_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_ensemble_keyval_ref.ddl
--  foreign key for table REF_ENSEMBLE_KEYVAL on ensemble_id from REF_ENSEMBLE
BEGIN EXECUTE IMMEDIATE 'alter table REF_ENSEMBLE_KEYVAL add constraint ENSEMBLE_KEY_ENSEMBLE_ID_FK 
foreign key (ensemble_id) 
references REF_ENSEMBLE (ensemble_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_ensemble_trace_ref.ddl
--  foreign key for table REF_ENSEMBLE_TRACE on ensemble_id from ref_ensemble
BEGIN EXECUTE IMMEDIATE 'alter table REF_ENSEMBLE_TRACE add constraint ensemble_tr_ensemble_id_fk 
foreign key (ensemble_id) 
references ref_ensemble (ensemble_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


--  foreign key for table REF_ENSEMBLE_TRACE on site_datatype_id from hdb_site_datatype
BEGIN EXECUTE IMMEDIATE 'alter table REF_ENSEMBLE_TRACE add constraint ensemble_model_run_id_fk 
foreign key (model_run_id) 
references ref_model_run (model_run_id) on delete cascade'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_ext_site_data_map_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_ext_site_data_map
add
  constraint ref_ext_site_data_map_fk1
  foreign key (ext_data_source_id)
  REFERENCES ${hdb_user}.hdb_ext_data_source(ext_data_source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map
add
  constraint ref_ext_site_data_map_fk2
  foreign key (hdb_site_datatype_id)
  REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map
add
  constraint ref_ext_site_data_map_fk3
  foreign key (hdb_interval_name)
  REFERENCES ${hdb_user}.hdb_interval(interval_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map
add
  constraint ref_ext_site_data_map_fk4
  foreign key (hdb_method_id)
  REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map
add
  constraint ref_ext_site_data_map_fk6
  foreign key (hdb_agen_id)
  REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map
add 
  constraint check_extra_keys_y_n
  check (extra_keys_y_n in (''y'', ''Y'', ''n'', ''N''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map
add 
  constraint check_is_active_y_n
  check (is_active_y_n in (''y'', ''Y'', ''n'', ''N''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_ext_site_data_map 
  add constraint ref_esdm_computation_id_fk
  foreign key (hdb_computation_id) references cp_computation (computation_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./CONSTRAINTS/ref_ext_site_data_map_keyval_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_ext_site_data_map_keyval
add
  constraint ref_ext_site_data_map_keyv_fk1
  foreign key (mapping_id)
  references  ref_ext_site_data_map(mapping_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_hm_filetype_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    ref_hm_filetype
add
   constraint  ref_hm_filetype_ck1
   check       (hm_filetype = ''A'' or hm_filetype = ''D'')'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_hm_pcode_objecttype_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_hm_pcode_objecttype
add
   constraint  ref_hm_pcode_objecttype_fk1
   foreign key (hm_pcode) 
   references  ref_hm_pcode(hm_pcode)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_hm_pcode_objecttype
add
   constraint  ref_hm_pcode_objecttype_fk2
   foreign key (objecttype_id)
   REFERENCES ${hdb_user}.hdb_objecttype(objecttype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_hm_pcode_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    ref_hm_pcode
add    
   constraint  ref_hm_pcode_fk1
   foreign key (unit_id)
   REFERENCES ${hdb_user}.hdb_unit(unit_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_hm_site_datatype_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_hm_site_datatype
add
    constraint ref_hm_site_datatype_fk1
    foreign key (site_datatype_id)
    REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_hm_site_hdbid_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_hm_site_hdbid
add
    constraint ref_hm_site_hdbid_fk1
    foreign key (hm_site_code)
    references  ref_hm_site(hm_site_code)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_hm_site_hdbid
add
    constraint ref_hm_site_hdbid_fk2
    foreign key (objecttype_id)
    REFERENCES ${hdb_user}.hdb_objecttype(objecttype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_hm_site_hdbid
add
    constraint ref_hm_site_hdbid_fk3
    foreign key (site_id)
    REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_hm_site_pcode_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_hm_site_pcode
add
    constraint ref_hm_site_pcode_fk1
    foreign key (hm_site_code)
    references  ref_hm_site(hm_site_code)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_hm_site_pcode
add
    constraint ref_hm_site_pcode_fk2
    foreign key (hm_pcode)     
    references  ref_hm_pcode(hm_pcode)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_hm_site_pcode
add
    constraint ref_hm_site_pcode_fk3
    foreign key (hm_filetype)
    references  ref_hm_filetype(hm_filetype)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_hm_site_pcode
add
    constraint ref_hm_site_pcode_fk4
    foreign key (site_datatype_id)
    REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_interval_redefinition_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_interval_redefinition add constraint
    ref_interval_redefinition_fk1
    foreign key  (interval)
    REFERENCES ${hdb_user}.hdb_interval(interval_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table ref_interval_redefinition add constraint
    ref_interval_redefinition_fk2
    foreign key  (offset_units)
    REFERENCES ${hdb_user}.hdb_date_time_unit(date_time_unit)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_installation.ddl
BEGIN EXECUTE IMMEDIATE '
alter table    ref_installation
add
   constraint  check_meta_data_install_type
   check       (meta_data_installation_type in (''master'',''snapshot'',''island''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./CONSTRAINTS/ref_loading_application_prop.ddl
BEGIN EXECUTE IMMEDIATE '
alter table ref_loading_application_prop
add  constraint ref_loading_application_id_fk foreign key (loading_application_id)
REFERENCES ${hdb_user}.hdb_loading_application (loading_application_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/ref_model_run_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_model_run
add
   constraint ref_model_run_fk1
   foreign key (model_id)
   REFERENCES ${hdb_user}.hdb_model(model_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_model_run
add
   constraint ref_model_run_fk2
   foreign key (modeltype)
   REFERENCES ${hdb_user}.hdb_modeltype(modeltype)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_model_run_keyval_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_model_run_keyval
add
   constraint ref_model_run_keyval_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/ref_rating.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_rating 
add  constraint ref_rating_rating_id_fk1 foreign key (rating_id)
references ref_site_rating (rating_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_site_rating.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_site_rating
add constraint rsr_date_sanity_ck1
check(effective_start_date_time is null or effective_end_date_time is null 
or effective_start_date_time <= effective_end_date_time)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_rating
add constraint rsr_rating_type_common_name_fk 
foreign key (rating_type_common_name)
REFERENCES ${hdb_user}.hdb_rating_type (rating_type_common_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_rating
add constraint REF_SITE_RATING_SANITY_UK 
UNIQUE ("INDEP_SITE_DATATYPE_ID","RATING_TYPE_COMMON_NAME","EFFECTIVE_START_DATE_TIME","EFFECTIVE_END_DATE_TIME")'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_res_flowlu_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_res_flowlu
add
  constraint  ref_res_flowlu_fk1
  foreign key (site_id)
  REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_res_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_res
add
   constraint   ref_res_fk1
   foreign key  (site_id)
   REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_res
add
   constraint   ref_res_fk2
   foreign key  (agen_id)
   REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_res
add
   constraint   ref_res_fk3
   foreign key  (damtype_id)
   REFERENCES ${hdb_user}.hdb_damtype(damtype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_res
add
   constraint   ref_res_fk4
   foreign key  (off_id)
   REFERENCES ${hdb_user}.hdb_usbr_off(off_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_res_wselu_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_res_wselu
add
  constraint  ref_res_wselu_fk1
  foreign key (site_id)
  REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_site_attr_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_site_attr
add constraint ref_site_attr_fk1
foreign key    (site_id)
REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_attr
add constraint ref_site_attr_fk2
foreign key    (attr_id)
REFERENCES ${hdb_user}.hdb_attr(attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_site_coef_day_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_site_coef_day
add constraint ref_site_coef_day_ck1
check (day between ''0'' and ''366'')'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_coef_day
add constraint ref_site_coef_day_fk1
foreign key   (site_id)
REFERENCES ${hdb_user}.hdb_site (site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_coef_day
add constraint ref_site_coef_day_fk2
foreign key   (attr_id)
REFERENCES ${hdb_user}.hdb_attr (attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_site_coef_month_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_site_coef_month
add constraint ref_site_coef_month_ck1
check (month between ''1'' and ''12'')'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_coef_month
add constraint ref_site_coef_month_fk1
foreign key   (site_id)
REFERENCES ${hdb_user}.hdb_site (site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_coef_month
add constraint ref_site_coef_month_fk2
foreign key   (attr_id)
REFERENCES ${hdb_user}.hdb_attr (attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_site_coef_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_site_coef
add
  constraint  ref_site_coef_fk1
  foreign key (site_id)
  REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table ref_site_coef
add
  constraint  ref_site_coef_fk2
  foreign key (attr_id)
  REFERENCES ${hdb_user}.hdb_attr(attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_site_coeflu_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    ref_site_coeflu
add 
   constraint  ref_site_coeflu_fk1
   foreign key (site_id)
   REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    ref_site_coeflu
add 
   constraint  ref_site_coeflu_fk2
   foreign key (attr_id)
   REFERENCES ${hdb_user}.hdb_attr(attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    ref_site_coeflu
add 
   constraint  ref_site_coeflu_fk3
   foreign key (lu_attr_id)
   REFERENCES ${hdb_user}.hdb_attr(attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_str_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    ref_str
add
   constraint  ref_str_fk1
   foreign key (site_id)
   REFERENCES ${hdb_user}.hdb_site(site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    ref_str
add
   constraint  ref_str_fk2
   foreign key (owner_id)
   REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    ref_str
add
   constraint  ref_str_fk3
   foreign key (gagetype_id)
   REFERENCES ${hdb_user}.hdb_gagetype(gagetype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_source_priority_ref.ddl
BEGIN EXECUTE IMMEDIATE 'ALTER TABLE ref_source_priority ADD CONSTRAINT ref_source_priority_fk1 FOREIGN KEY
(site_datatype_id)
 REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ref_source_priority ADD CONSTRAINT ref_source_priority_fk2 FOREIGN KEY
(agen_id)
 REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ref_source_priority ADD CONSTRAINT positive_priority check (priority_rank >= 1)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/




-- Expanding: ./CONSTRAINTS/ref_spatial_relation.ddl
BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ref_spatial_relation
add constraint ref_spatial_relation_fk1
foreign key (a_site_id)
REFERENCES ${hdb_user}.hdb_site (site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ref_spatial_relation
add constraint ref_spatial_relation_fk2
foreign key (b_site_id)
REFERENCES ${hdb_user}.hdb_site (site_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
ALTER TABLE ref_spatial_relation
add constraint ref_spatial_relation_fk3
foreign key (attr_id)
REFERENCES ${hdb_user}.hdb_attr (attr_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/m_day_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_day
add
   constraint  m_day_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_day
add
   constraint  m_day_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/m_hour_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_hour
add
   constraint  m_hour_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_hour
add
   constraint  m_hour_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/m_month_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_month
add
   constraint  m_month_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_month
add
   constraint  m_month_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/m_monthrange_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_monthrange
add
   constraint  m_monthrange_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_monthrange
add
   constraint  m_monthrange_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/m_monthstat_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_monthstat
add
   constraint  m_monthstat_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_monthstat
add
   constraint  m_monthstat_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_monthstat
add
   constraint  m_monthstat_ck1
   check (month between ''1'' and ''12'')'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/m_wy_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_wy
add
   constraint  m_wy_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_wy
add
   constraint  m_wy_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/m_year_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    m_year
add
   constraint  m_year_fk1
   foreign key (model_run_id)
   references  ref_model_run(model_run_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    m_year
add
   constraint  m_year_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_base_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
    r_base_fk1
    foreign key  (site_datatype_id)
    REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
    r_base_fk2
    foreign key  (interval)
    REFERENCES ${hdb_user}.hdb_interval(interval_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
    r_base_fk3
    foreign key  (agen_id)
    REFERENCES ${hdb_user}.hdb_agen(agen_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
    r_base_fk5
    foreign key  (method_id)
    REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
    r_base_fk6
    foreign key  (collection_system_id)
    REFERENCES ${hdb_user}.hdb_collection_system(collection_system_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
    r_base_fk7
    foreign key  (loading_application_id)
    REFERENCES ${hdb_user}.hdb_loading_application(loading_application_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
   r_base_fk8
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint
   r_base_fk9
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- this added for the computation processor project
BEGIN EXECUTE IMMEDIATE 'alter table r_base add constraint 
   r_base_computation_id_fk
   foreign key (computation_id) references cp_computation (computation_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/* start ./CONSTRAINTS/r_base_update_ref.ddl;  removed for CP Project   */
-- Expanding: ./CONSTRAINTS/r_day_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_day
add
   constraint  r_day_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_day
add
   constraint  r_day_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_day
add
   constraint  r_day_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_day
add
   constraint  r_day_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_day
add
   constraint  r_day_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/r_daystat_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_daystat
add
   constraint  r_daystat_fk1
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_daystat
add
   constraint  r_daystat_fk2
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_daystat
add
   constraint  r_daystat_ck1
   check       (day between 1 and 366)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_hour_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_hour
add
   constraint  r_hour_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_hour
add
   constraint  r_hour_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_hour
add
   constraint  r_hour_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_hour
add
   constraint  r_hour_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_hour
add
   constraint  r_hour_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/r_hourstat_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_hourstat
add
   constraint  r_hourstat_fk1
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_hourstat
add
   constraint  r_hourstat_fk2
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_hourstat
add
   constraint  r_hourstat_ck1
   check       (hour between 0 and 23)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_instant_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_instant
add
   constraint  r_instant_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_instant
add
   constraint  r_instant_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_instant
add
   constraint  r_instant_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_instant
add
   constraint  r_instant_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_instant
add
   constraint  r_instant_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/r_month_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_month
add
   constraint  r_month_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_month
add
   constraint  r_month_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_month
add
   constraint  r_month_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_month
add
   constraint  r_month_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_month
add
   constraint  r_month_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_monthstat_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_monthstat
add
   constraint  r_monthstat_fk1
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_monthstat
add
   constraint  r_monthstat_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_monthstat
add
   constraint  r_monthstat_ck1
   check (month between 1 and 12)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_monthstatrange_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_monthstatrange
add
   constraint  r_monthstatrange_fk1
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_monthstatrange
add
   constraint  r_monthstatrange_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_monthstatrange
add
   constraint  r_monthstatrange_ck1
   check (start_month between 1 and 12)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_monthstatrange
add
   constraint  r_monthstatrange_ck2
   check (end_month between 1 and 12)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_other_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_other
add
   constraint  r_other_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table    r_other
add
   constraint  r_other_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'alter table    r_other
add
   constraint  r_other_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_other
add
   constraint  r_other_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_other
add
   constraint  r_other_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- Expanding: ./CONSTRAINTS/r_wy_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_wy
add
   constraint  r_wy_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_wy
add
   constraint  r_wy_fk2
   foreign key (site_datatype_id)
REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_wy
add
   constraint  r_wy_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_wy
add
   constraint  r_wy_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_wy
add
   constraint  r_wy_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_wystat_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_wystat
add
   constraint  r_wystat_fk1
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_wystat
add
   constraint  r_wystat_fk2
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_wystat
add
   constraint  r_wystat_ck1
   check (wy > 1900)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_year_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_year
add
   constraint  r_year_fk1
   foreign key (validation)
   REFERENCES ${hdb_user}.hdb_validation(validation)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_year
add
   constraint  r_year_fk2
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_year
add
   constraint  r_year_fk3
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_year
add
   constraint  r_year_fk4
   foreign key (overwrite_flag)
   REFERENCES ${hdb_user}.hdb_overwrite_flag(overwrite_flag)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_year
add
   constraint  r_year_fk5
   foreign key (method_id)
   REFERENCES ${hdb_user}.hdb_method(method_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/r_yearstat_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    r_yearstat
add
   constraint  r_yearstat_fk1
   foreign key (site_datatype_id)
   REFERENCES ${hdb_user}.hdb_site_datatype(site_datatype_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_yearstat
add
   constraint  r_yearstat_fk2
   foreign key (source_id)
   REFERENCES ${hdb_user}.hdb_data_source(source_id)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table    r_yearstat
add
   constraint  r_yearstat_ck1
   check (year > 1900)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Expanding: ./CONSTRAINTS/ref_interval_copy_limits.ddl
BEGIN EXECUTE IMMEDIATE 'alter table REF_INTERVAL_COPY_LIMITS
add constraint RICL_INTERVAL_FK
foreign key   (INTERVAL)
REFERENCES ${hdb_user}.HDB_INTERVAL (INTERVAL_NAME)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table REF_INTERVAL_COPY_LIMITS
add constraint RICL_SITE_DATATYPE_ID_FK
foreign key   (SITE_DATATYPE_ID)
REFERENCES ${hdb_user}.HDB_SITE_DATATYPE (SITE_DATATYPE_ID)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/* start ./CONSTRAINTS/hdb_derivation_flag.ddl;  removed for CP Project */

-- spool off
-- exit;

-- Expanding: ./CONSTRAINTS/ref_hdb_installation_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table    ref_hdb_installation
add
   constraint  ref_hdb_installation_ck1
   check       (is_czar_db in (''Y'',''N''))'; EXCEPTION WHEN OTHERS THEN NULL; END;
/



-- Expanding: ./CONSTRAINTS/ref_phys_quan_refresh_monitor_ref.ddl
BEGIN EXECUTE IMMEDIATE 'alter table ref_phys_quan_refresh_monitor
add constraint ref_phys_quan_refresh_mon_fk1
foreign key    (db_site_db_name)
references     ref_hdb_installation(db_site_db_name)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- set echo on
-- set feedback on
-- spool hdb_triggers.out

-- Expanding: ./TRIGGERS/auth_sdi_chk_role.trg
create or replace trigger auth_sdi_chk_role
after             insert or update of role
on                ref_auth_site_datatype
for   each row
begin
     psswd_user.check_valid_role_name(:new.role);
end;
/
-- show errors trigger auth_sdi_chk_role;
/
-- Expanding: ./TRIGGERS/auth_site_chk_role.trg
create or replace trigger auth_site_chk_role
after             insert or update of role
on                ref_auth_site
for   each row
begin
     psswd_user.check_valid_role_name (:new.role);
end;
/
-- show errors trigger auth_site_chk_role;
/
/* @ ./TRIGGERS/check_computed_datatype_id.trg;  removed  */
-- Expanding: ./TRIGGERS/check_attr_type_and_unit.trg
create or replace trigger check_attr_type_and_unit 
after insert or update
on hdb_attr
for each row
begin
     if (:new.attr_value_type <> 'number' and :new.unit_id is not null) then
	  raise_application_error(-20005,'Error: Unit_id appropriate only for attributes with type: number');
     end if;

end;
/
-- show errors trigger check_attr_type_and_unit;


-- Expanding: ./TRIGGERS/check_property_type_and_unit.trg
create or replace trigger check_property_type_and_unit 
after insert or update
on hdb_property
for each row
begin
     if (:new.property_value_type <> 'number' and :new.unit_id is not null) then
	  raise_application_error(-20005,'Error: Unit_id appropriate only for property with type: number');
     end if;

     if (:new.property_value_type = 'number' and :new.unit_id is null) then
	  raise_application_error(-20005,'Error: Unit_id needs to be set for property with type: number');
     end if;

end;
/
-- show errors trigger check_property_type_and_unit;
/

-- @ ./TRIGGERS/combined_disagg_chk_val.trg; removed for CP Project 10/2022
-- Expanding: ./TRIGGERS/combined_ref_div_chk.trg
create or replace trigger combined_ref_div_chk
after             insert or update
on                ref_div
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     check_valid_site_objtype ('div', :new.site_id);

     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/

-- show errors trigger combined_ref_div_chk;
/
-- Expanding: ./TRIGGERS/combined_ref_res_chk.trg
create or replace TRIGGER combined_ref_res_chk
after             insert or update
on                ref_res
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     check_valid_site_objtype ('res', :new.site_id);

     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger combined_ref_res_chk;
/
-- Expanding: ./TRIGGERS/combined_ref_str_chk.trg
create or replace TRIGGER combined_ref_str_chk
after             insert or update
on                ref_str
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     check_valid_site_objtype ('str', :new.site_id);

     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger combined_ref_str_chk;
/
-- Expanding: ./TRIGGERS/cp_algorithm_triggers.trg

create or replace trigger cp_algorithm_update                                                                    
after update on cp_algorithm 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/04/2006
    This trigger archives any updates to the table
    cp_algorithm.
	
	updated to add DB_OFFICE_CODE column in archive table by IsmailO. 08/26/2019
*/
insert into cp_algorithm_archive (                     
ALGORITHM_ID,
ALGORITHM_NAME,
EXEC_CLASS,
CMMNT,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT,
DB_OFFICE_CODE
) 
values (                                           
:old.ALGORITHM_ID,
:old.ALGORITHM_NAME,
:old.EXEC_CLASS,
:old.CMMNT,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
:old.DB_OFFICE_CODE); 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_algorithm_update;                                                                         

                                                                                                                        
create or replace trigger cp_algorithm_delete                                                                    
after delete on cp_algorithm 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/04/2006
    This trigger archives any deletes to the table
    cp_algorithm.
	
	updated to add DB_OFFICE_CODE column in archive table by IsmailO. 08/26/2019
*/
insert into cp_algorithm_archive (                     
ALGORITHM_ID,
ALGORITHM_NAME,
EXEC_CLASS,
CMMNT,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT,
DB_OFFICE_CODE
) 
values (                                           
:old.ALGORITHM_ID,
:old.ALGORITHM_NAME,
:old.EXEC_CLASS,
:old.CMMNT,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
:old.DB_OFFICE_CODE); 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_algorithm_delete;                                                                         

-- Expanding: ./TRIGGERS/cp_algo_property_triggers.trg

create or replace trigger cp_algo_property_update                                                                    
after update on cp_algo_property 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/04/2006
    This trigger archives any updates to the table
    cp_algo_property.
*/
insert into cp_algo_property_archive (                     
ALGORITHM_ID,
PROP_NAME,
PROP_VALUE,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT
) 
values (                                           
:old.ALGORITHM_ID,
:old.PROP_NAME,
:old.PROP_VALUE,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_algo_property_update;                                                                         

                                                                                                                        
create or replace trigger cp_algo_property_delete                                                                    
after delete on cp_algo_property 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/04/2006
    This trigger archives any deletes to the table
    cp_algo_property.
*/
insert into cp_algo_property_archive (                     
ALGORITHM_ID,
PROP_NAME,
PROP_VALUE,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT
) 
values (                                           
:old.ALGORITHM_ID,
:old.PROP_NAME,
:old.PROP_VALUE,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_algo_property_delete;                                                                         

-- Expanding: ./TRIGGERS/cp_algo_ts_parm_triggers.trg

create or replace trigger cp_algo_ts_parm_update                                                                    
after update on cp_algo_ts_parm 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/04/2006
    This trigger archives any updates to the table
    cp_algo_ts_parm.
*/
insert into cp_algo_ts_parm_archive (                     
ALGORITHM_ID,
ALGO_ROLE_NAME,
PARM_TYPE,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT
) 
values (                                           
:old.ALGORITHM_ID,
:old.ALGO_ROLE_NAME,
:old.PARM_TYPE,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_algo_ts_parm_update;                                                                         

                                                                                                                        
create or replace trigger cp_algo_ts_parm_delete                                                                    
after delete on cp_algo_ts_parm 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/04/2006
    This trigger archives any deletes to the table
    cp_algo_ts_parm.
*/
insert into cp_algo_ts_parm_archive (                     
ALGORITHM_ID,
ALGO_ROLE_NAME,
PARM_TYPE,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT
) 
values (                                           
:old.ALGORITHM_ID,
:old.ALGO_ROLE_NAME,
:old.PARM_TYPE,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_algo_ts_parm_delete;                                                                         

-- Expanding: ./TRIGGERS/cp_computation_triggers.trg

create or replace trigger cp_comp_insertupdate                                                                    
before insert or update on cp_computation 
for each row 
begin 
/*  This trigger created by M.  Bogner  05/11/2012
    This trigger the cp_comp_depends notification for any
    inserts to the table cp_computation.
    Modified July 23 2012 to adjust the date time loaded to the DB time zone
    Modified August 28 2012 to adjust the date time loaded back to a simple sysdate
*/
--   :NEW.DATE_TIME_LOADED := hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE'));
     :NEW.DATE_TIME_LOADED := sysdate;
   
end;
/

create or replace trigger cp_computation_insert                                                                    
after insert on cp_computation 
for each row 
begin 
/*  This trigger created by M.  Bogner  05/11/2012
    This trigger the cp_comp_depends notification for any
    inserts to the table cp_computation.
    Modified August 28 2012 to adjust the date time loaded back to a simple sysdate
*/

  /* for PHASE 3.0 a change in Computation will trigger a notification to address CP_COMP_DEPENDS */
  insert into cp_depends_notify (record_num,event_type,key,date_time_loaded) values (-1,'C',:NEW.COMPUTATION_ID,sysdate);
--  hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')));
-- removed Aug 2012 to change back to a simpel sysdate

end;
/

create or replace trigger cp_computation_update                                                                    
after update on cp_computation 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/05/2006
    modified by M. Bogner 05/11/2012 to add the cp_depends_notify logic
    This trigger archives any updates to the table
    cp_computation.
    Modified August 28 2012 to adjust the date time loaded back to a simple sysdate
	    
    updated to add GROUP_ID,DB_OFFICE_CODE columns in archive table by IsmailO. 08/26/2019
*/

/* for PHASE 3.0 a change in computation will trigger a notification to adress CP_COMP_DEPENDS */
insert into cp_depends_notify (record_num,event_type,key,date_time_loaded) values (-1,'C',:NEW.COMPUTATION_ID,sysdate);
-- hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')));
-- removed Aug 2012 to change back to a simpel sysdate

insert into cp_computation_archive (                     
   COMPUTATION_ID,
   COMPUTATION_NAME,
   ALGORITHM_ID,
   CMMNT,
   LOADING_APPLICATION_ID,
   DATE_TIME_LOADED,
   ENABLED,
   EFFECTIVE_START_DATE_TIME,
   EFFECTIVE_END_DATE_TIME,
   ARCHIVE_REASON,
   DATE_TIME_ARCHIVED,
   ARCHIVE_CMMNT,
   GROUP_ID,
   DB_OFFICE_CODE
) 
values (                                           
   :old.COMPUTATION_ID,
   :old.COMPUTATION_NAME,
   :old.ALGORITHM_ID,
   :old.CMMNT,
   :old.LOADING_APPLICATION_ID,
   :old.DATE_TIME_LOADED,
   :old.ENABLED,
   :old.EFFECTIVE_START_DATE_TIME,
   :old.EFFECTIVE_END_DATE_TIME,
   'UPDATE', 
   sysdate,
   coalesce(
             sys_context('APEX$SESSION','app_user')
            ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
            ,sys_context('userenv','session_user')
            ) || ':' || sys_context('userenv','os_user') 
            || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
   :old.GROUP_ID,
   :old.DB_OFFICE_CODE); 
-- the following removed from the archive insert and replaced with simple sysdate
--   hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')), 

end;                                                                    
/                                                                                                                       
-- show errors trigger cp_computation_update;                                                                         

                                                                                                                        
create or replace trigger cp_computation_delete                                                                    
after delete on cp_computation 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/05/2006
    modified by M. Bogner 05/15/2012 to add the cp_depends_notify logic
    This trigger archives any deletes to the table
    cp_computation.
    Modified August 28 2012 to adjust the date time loaded back to a simple sysdate
	
    updated to add GROUP_ID,DB_OFFICE_CODE columns in archive table by IsmailO. 08/26/2019
*/

  /* for PHASE 3.0 a change in Computation will trigger a notification to address CP_COMP_DEPENDS */
  insert into cp_depends_notify (record_num,event_type,key,date_time_loaded) values (-1,'C',:OLD.COMPUTATION_ID,sysdate);
-- the following removed from the archive insert and replaced with simple sysdate
--  hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')));

insert into cp_computation_archive (                     
   COMPUTATION_ID,
   COMPUTATION_NAME,
   ALGORITHM_ID,
   CMMNT,
   LOADING_APPLICATION_ID,
   DATE_TIME_LOADED,
   ENABLED,
   EFFECTIVE_START_DATE_TIME,
   EFFECTIVE_END_DATE_TIME,
   ARCHIVE_REASON,
   DATE_TIME_ARCHIVED,
   ARCHIVE_CMMNT,
   GROUP_ID,
   DB_OFFICE_CODE
) 
values (                                           
   :old.COMPUTATION_ID,
   :old.COMPUTATION_NAME,
   :old.ALGORITHM_ID,
   :old.CMMNT,
   :old.LOADING_APPLICATION_ID,
   :old.DATE_TIME_LOADED,
   :old.ENABLED,
   :old.EFFECTIVE_START_DATE_TIME,
   :old.EFFECTIVE_END_DATE_TIME,
   'DELETE',
   sysdate, 
   coalesce(
             sys_context('APEX$SESSION','app_user')
            ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
            ,sys_context('userenv','session_user')
            ) || ':' || sys_context('userenv','os_user') 
            || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
   :old.GROUP_ID,
   :old.DB_OFFICE_CODE); 
-- the following removed from the archive insert and replaced with simple sysdate
--   hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')), 
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_computation_delete;                                                                         

-- Expanding: ./TRIGGERS/cp_comp_property_triggers.trg

create or replace trigger cp_comp_property_update                                                                    
after insert or update on cp_comp_property 
for each row 
DECLARE 
temp_computation_id cp_computation.computation_id%TYPE;

begin 
/*  This trigger created by M.  Bogner  04/05/2006
    This trigger archives any updates to the table
    cp_comp_property.
*/

temp_computation_id := :new.computation_id;

IF (UPDATING) THEN
 temp_computation_id := :old.computation_id;
 insert into cp_comp_property_archive (                     
   COMPUTATION_ID,
   PROP_NAME,
   PROP_VALUE,
   ARCHIVE_REASON,
   DATE_TIME_ARCHIVED,
   ARCHIVE_CMMNT
) 
values (                                           
   :old.COMPUTATION_ID,
   :old.PROP_NAME,
   :old.PROP_VALUE,
   'UPDATE', 
   sysdate, 
   coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
END IF;

/* now update parent table's date_time_loaded for sql statements issued on this table */ 
hdb_utilities.touch_cp_computation(temp_computation_id);

end;                                                                    
/                                                                                                                       
-- show errors trigger cp_comp_property_update;                                                                         

                                                                                                                        
create or replace trigger cp_comp_property_delete                                                                    
after delete on cp_comp_property 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/05/2006
    This trigger archives any deletes to the table
    cp_comp_property.
*/
insert into cp_comp_property_archive (                     
   COMPUTATION_ID,
   PROP_NAME,
   PROP_VALUE,
   ARCHIVE_REASON,
   DATE_TIME_ARCHIVED,
   ARCHIVE_CMMNT
) 
values (                                           
   :old.COMPUTATION_ID,
   :old.PROP_NAME,
   :old.PROP_VALUE,
   'DELETE', 
   sysdate, 
   coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 

/* now update parent table's date_time_loaded for sql statements issued on this table */ 
hdb_utilities.touch_cp_computation(:old.computation_id);

end;                                                                    
/                                                                                                                       
-- show errors trigger cp_comp_property_delete;                                                                         

-- Expanding: ./TRIGGERS/cp_comp_ts_parm_triggers.trg

create or replace trigger cp_comp_ts_parm_update                                                                    
after update or update on cp_comp_ts_parm 
for each row 
DECLARE 
temp_computation_id cp_computation.computation_id%TYPE;
begin 
/*  This trigger created by M.  Bogner  04/05/2006
    This trigger archives any updates to the table
    cp_comp_ts_parm.
    
    updated 5/19/2008 by M. Bogner to update the date_time_loaded
    column of cp_computation table
	
	updated to add DATATYPE_ID,DELTA_T_UNITS,SITE_ID columns in archive table by IsmailO. 08/27/2019
*/
temp_computation_id := :new.computation_id;

IF (UPDATING) THEN
  temp_computation_id := :old.computation_id;

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
   ARCHIVE_CMMNT,
   DATATYPE_ID,
   DELTA_T_UNITS,
   SITE_ID
) 
values (                                           
  :old.COMPUTATION_ID,
  :old.ALGO_ROLE_NAME,
  :old.SITE_DATATYPE_ID,
  :old.INTERVAL,
  :old.TABLE_SELECTOR,
  :old.DELTA_T,
  :old.MODEL_ID,
  'UPDATE', 
  sysdate, 
    coalesce(
            sys_context('APEX$SESSION','app_user')
           ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
           ,sys_context('userenv','session_user')
           ) || ':' || sys_context('userenv','os_user') 
           || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
  :old.DATATYPE_ID,
  :old.DELTA_T_UNITS,
  :old.SITE_ID); 
END IF;

/* now update parent table's date_time_loaded for sql statements issued on this table */ 
  hdb_utilities.touch_cp_computation(temp_computation_id);

end;                                                                    
/                                                                                                                       
-- show errors trigger cp_comp_ts_parm_update;                                                                         

                                                                                                                        
create or replace trigger cp_comp_ts_parm_delete                                                                    
after delete on cp_comp_ts_parm 
for each row 
begin 
/*  This trigger created by M.  Bogner  04/05/2006
    This trigger archives any deletes to the table
    cp_comp_ts_parm.
    
    updated 5/19/2008 by M. Bogner to update the date_time_loaded
    collumn of cp_computation table
	
	updated to add DATATYPE_ID,DELTA_T_UNITS,SITE_ID columns in archive table by IsmailO. 08/27/2019
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
   ARCHIVE_CMMNT,
   DATATYPE_ID,
   DELTA_T_UNITS,
   SITE_ID
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
    coalesce(
            sys_context('APEX$SESSION','app_user')
           ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
           ,sys_context('userenv','session_user')
           ) || ':' || sys_context('userenv','os_user') 
           || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
  :old.DATATYPE_ID,
  :old.DELTA_T_UNITS,
  :old.SITE_ID); 

/* now update parent table's date_time_loaded for sql statements issued on this table */ 
  hdb_utilities.touch_cp_computation(:old.computation_id);
end;                                                                    
/                                                                                                                       
-- show errors trigger cp_comp_ts_parm_delete;                                                                         

-- Expanding: ./TRIGGERS/cp_depends_notify_triggers.trg
CREATE OR REPLACE TRIGGER CP_DN_PK_TRIG 
BEFORE INSERT OR UPDATE 
ON CP_DEPENDS_NOTIFY 
FOR EACH ROW 
BEGIN 
    
    /* create by M. Bogner May 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
    
     populate the primary key through a sequence 
     update the date_time_loaded column
    
    Modified by M. Bogner July 2012 to put date_time_loaded time into same DB Time_ZONE instead of
    the system time
    Modified August 28 2012 to adjust the date time loaded back to a simple sysdate
    */

	IF inserting THEN
          /*  get the next sequence for the primary key  */
	      SELECT CP_NOTIFY_SEQUENCE.NEXTVAL INTO :NEW.RECORD_NUM FROM DUAL;
    ELSIF updating THEN 
     /*  do nothing as of now  */
     null;
    END IF; 
/* update the date_time_loaded field to a DB time_zone corrected value*/
--   :NEW.DATE_TIME_LOADED := hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE'));
     :NEW.DATE_TIME_LOADED := sysdate;
END;         
                                                                                

/
-- Expanding: ./TRIGGERS/cp_ts_id_triggers.trg
CREATE OR REPLACE TRIGGER CP_TSID_PK_TRIG 
BEFORE INSERT OR UPDATE 
ON CP_TS_ID
FOR EACH ROW 
declare
  l_count            number;
  l_text               varchar2(200);
BEGIN 
    
    /* create by M. Bogner May 2012 for the CP upgrade Phase 3.0  */
    /* modified by M. Bogner July 2012 for the sanity check and valid intervals checks */
    /*
    the purpose of this trigger is to:
    
     check to see if the row is a possible valid interval for the datatype used
     check to see if the entries are valid based on table_selector
     populate the primary key through a sequence 
     update the date_time_loaded column
     Modified July 23 2012 by M. Bogner to use a sysdate modified to the DB time zone

/* update the PK from the sequence for a new record insertion  */
	IF inserting THEN
	      SELECT CP_TS_ID_SEQUENCE.NEXTVAL INTO :NEW.TS_ID FROM DUAL;
    ELSIF updating THEN 
     /*  do nothing as of now  */
     null;
    END IF; 
  
  /* set the date_time_loaded column for this record to the sysdate modified to the databases time zone */
/* modified the date_time_loaded function to go back to using the simple sysdate  
--  :new.date_time_loaded := hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE'));
*/
   :new.date_time_loaded := sysdate;
 

   if (:new.table_selector = 'M_' and :new.model_id < 1) then
      deny_action ('Invalid model_id: ' || to_char(:new.model_id) || '  for MODELED TS Identifier');
   end if;
 
   if (:new.table_selector = 'R_' and :new.model_id > 0 ) then
      deny_action ('Invalid model_id: ' || to_char(:new.model_id) || '   for REAL TS Identifier');
   end if;

  
   
END;                                                                                         

/

CREATE OR REPLACE TRIGGER CP_TSID_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON CP_TS_ID
FOR EACH ROW 
declare
  l_ts_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     insert a record into cp_notify depends to signal a time series record change/creation/deletion
    */

 	IF inserting  OR updating THEN
	      l_ts_id := :NEW.ts_id;
    ELSIF deleting THEN 
	      l_ts_id := :OLD.ts_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TIME SERIES will trigger a notification to address CP_COMP_DEPENDS */
  insert into cp_depends_notify (record_num,event_type,key,date_time_loaded) values (-1,'T',l_ts_id,sysdate);
  /* moved back to using a simplified sysdate for date_time_loaded on 28-AUG-2012
    hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')));
  */
END;                                                                                         

/
-- Expanding: ./TRIGGERS/datatype_unit_check.trg
create or replace trigger datatype_unit_check
after insert or update of unit_id
on hdb_datatype
for each row
declare
  v_count  number;
  status   number;
  buffer   varchar2(2000);
  unit_mismatch EXCEPTION;
begin
     /* See if this datatype's unit is same as its physical quantity
	customary unit. Warn only if it's not; don't stop the edit. */
     select count(*) 
     into v_count
     from hdb_physical_quantity pq
     where pq.physical_quantity_name = :new.physical_quantity_name
       and pq.customary_unit_id = :new.unit_id;

     if (v_count = 0) then
       dbms_output.put_line ('WARNING: Datatype unit_id does not match its physical quantity customary_unit_id. Allowing edit.'); 
     end if;

end;
/
-- show errors trigger datatype_unit_check.trg;
/

-- Expanding: ./TRIGGERS/decodes_site.trg
create or replace trigger decodes_site_update
instead of update on site_to_decodes_site_view 
for each row
declare
 TEMP_SCS_ID number;
 TEMP_INT number;
 TEMP_INT1 number;
 TEMP_INT2 number;
 TEMP_SITE_NAME HDB_SITE.SITE_NAME%TYPE;
 TEMP_DESCRIPTION HDB_SITE.DESCRIPTION%TYPE;
begin

/*  this trigger is designed to update appropriate records in the site_to_decodes_site_view
--     whenever an update to the view is detected
    written by M. Bogner  May 2005
    modified by M. Bogner May 2006 because of testing incompatibilities
    modified by M. Bogner April 2011 to make a merge statement on decodes extension table
    and new architectural decisions
*/


  temp_int := instr(:new.description,chr(10));
  temp_int1 := temp_int - 1;
  temp_int2 := temp_int + 1;

  /*  if there's no line feed then there is a data entry error or just the site name has been sent */
  if (temp_int = 0) then  
      temp_int1 := 240;
      temp_int2 := 241;
--    raise_application_error(-20000,'Description Must have a <RETURN> within it to determine system name!!!');
  end if;

  /*  if the carriage return is a  place beyond 240 then the site name is too long  */
  if (temp_int > 240) then  
      temp_int1 := 240;
      temp_int2 := 241;
--    raise_application_error(-20000,'The system name must not be longer than 240 characters!!!');
  end if;

  /*  now set the site_name and description  based on the location of the line feed  */
  /*  or the determination of the splitting location                                 */
  temp_site_name := substr(:new.description,1,temp_int1);
  temp_description:= substr(:new.description,temp_int2);

/*  update the hdb_site table for the appropriate columns in this view  */

update hdb_site set
site_name = temp_site_name,
description =  temp_description,
lat = :new.latitude,
longi = :new.longitude,
elevation = :new.elevation
where site_id = :new.id;

/*  update the decodes_site_ext table for the appropriate columns in this view  */
/*  commented out to be replaced with merge statement  */
/*
update decodes_site_ext set 
nearestcity = :new.nearestcity,
state = :new.state,
region = :new.region,
timezone = :new.timezone,
country = :new.country,
elevunitabbr = :new.elevunitabbr
where site_id = :new.id;
*/

/* now here is the new merge statement to replace the update of decodes_site_ext  */

merge into decodes_site_ext DSE
using (
  select :new.nearestcity "NEARESTCITY",:new.state "STATE",:new.region "REGION",
  :new.timezone "TIMEZONE",:new.country "COUNTRY",:new.elevunitabbr "ELEVUNITABBR",
  :new.id "SITE_ID" from dual 
  ) DV  
on (DSE.SITE_ID = DV.SITE_ID)
WHEN MATCHED THEN UPDATE SET 
  nearestcity = DV.NEARESTCITY, state = DV.STATE, region = DV.REGION,
  timezone = DV.TIMEZONE, country = DV.COUNTRY, elevunitabbr = DV.ELEVUNITABBR
  WHEN NOT MATCHED THEN INSERT (DSE.SITE_ID,DSE.NEARESTCITY,DSE.STATE,DSE.REGION,DSE.TIMEZONE,
  DSE.COUNTRY,DSE.ELEVUNITABBR)
     VALUES (DV.SITE_ID,DV.NEARESTCITY,DV.STATE,DV.REGION,DV.TIMEZONE,
             DV.COUNTRY,DV.ELEVUNITABBR);

END;

/


create or replace trigger decodes_site_delete
instead of delete on site_to_decodes_site_view 
for each row
declare
 TEMP_SCS_ID number;
 TEMP_INT number;
begin

/*  this trigger is designed to delete appropriate records in the site_to_decodes_site_view
--     whenever an delete to the view is detected
    written by M. Bogner  May 2005
*/

--delete from hdb_ext_site_code where hdb_site_id = :old.id;
delete from hdb_site where site_id = :old.id;


END;

/

create or replace trigger decodes_site_insert
instead of insert on site_to_decodes_site_view 
for each row
declare
 TEMP_INT number;
 TEMP_INT1 number;
 TEMP_INT2 number;
 TEMP_DBS_CODE REF_DB_LIST.DB_SITE_CODE%TYPE;
 TEMP_SITE_NAME HDB_SITE.SITE_NAME%TYPE;
 TEMP_DESCRIPTION HDB_SITE.DESCRIPTION%TYPE;

begin

/*  this trigger is designed to insert appropriate records in the site_to_decodes_site_view
--     whenever an insert to the site_to_decodes_site_view view is detected
    written by M. Bogner  May 2005
    modified by M. Bogner May 2006 because of testing incompatibilities
    modified by M. Bogner April 2011 to make a merge statement on decodes extension table
    and new architectural decisions
*/


  /*  for inserts into hdb_site go get the db_site code from the ref_db_list table */
  select db_site_code into temp_dbs_code from ref_db_list where session_no = 1;

  /* the description is suppose to be the system name along with the description */

  temp_int := instr(:new.description,chr(10));
  temp_int1 := temp_int - 1;
  temp_int2 := temp_int + 1;

  /*  if there's no line feed then there is a data entry error or just the site name has been sent */
  if (temp_int = 0) then  
      temp_int1 := 240;
      temp_int2 := 241;
--    raise_application_error(-20000,'Description Must have a <RETURN> within it to determine system name!!!');
  end if;

  /*  if the carriage return is a  place beyond 240 then the site name is too long  */
  if (temp_int > 240) then  
      temp_int1 := 240;
      temp_int2 := 241;
--    raise_application_error(-20000,'The system name must not be longer than 240 characters!!!');
  end if;

  /*  now set the site_name and description  based on the location of the line feed  */
  /*  or the determination of the splitting location                                 */
  temp_site_name := substr(:new.description,1,temp_int1);
  temp_description:= substr(:new.description,temp_int2);

  /*  insert the record into the hdb_site table  */
  populate_pk.SET_PRE_POPULATED (0);
  insert into hdb_site
  (SITE_ID,SITE_NAME,SITE_COMMON_NAME,OBJECTTYPE_ID,DB_SITE_CODE,DESCRIPTION,LAT,LONGI,ELEVATION)
  values (:new.id,temp_site_name,temp_site_name,9,temp_dbs_code,
      temp_description,:new.latitude,:new.longitude,:new.elevation);
  /* above modified 05.04.2006 by M Bogner to insert values that where missing from the insert statement  */
  /* above modified 05.15.2006 by M Bogner to insert values for a new procedure to determine site and description*/
  populate_pk.SET_PRE_POPULATED (1);

  /* now insert the other data into the site extension table  */
  /* the insert should have already been done so we are going to do an update instead but I will leave this code here 
     but commented out just in case we may need it later...
  insert into DECODES_SITE_EXT 
  (SITE_ID,NEARESTCITY,STATE,REGION,TIMEZONE,COUNTRY,ELEVUNITABBR)
  values (NEW.ID,:NEW.NEARESTCITY,:NEW.STATE,:NEW.REGION,:NEW.TIMEZONE,:NEW.COUNTRY,:NEW.ELEVUNITABBR);
  
  end of the commented out block  */


  /*  update the decodes_site_ext table for the appropriate columns in this view  */
  /*  commented out to be replaced with merge statement  */
/*
  update decodes_site_ext set 
  nearestcity = :new.nearestcity,
  state = :new.state,
  region = :new.region,
  timezone = :new.timezone,
  country = :new.country,
  elevunitabbr = :new.elevunitabbr
  where site_id = :new.id;
*/

/* now here is the new merge statement to replace the update of decodes_site_ext  */

merge into decodes_site_ext DSE
using (
  select :new.nearestcity "NEARESTCITY",:new.state "STATE",:new.region "REGION",
  :new.timezone "TIMEZONE",:new.country "COUNTRY",:new.elevunitabbr "ELEVUNITABBR",
  :new.id "SITE_ID" from dual 
  ) DV  
on (DSE.SITE_ID = DV.SITE_ID)
WHEN MATCHED THEN UPDATE SET 
  nearestcity = DV.NEARESTCITY, state = DV.STATE, region = DV.REGION,
  timezone = DV.TIMEZONE, country = DV.COUNTRY, elevunitabbr = DV.ELEVUNITABBR
  WHEN NOT MATCHED THEN INSERT (DSE.SITE_ID,DSE.NEARESTCITY,DSE.STATE,DSE.REGION,DSE.TIMEZONE,
  DSE.COUNTRY,DSE.ELEVUNITABBR)
     VALUES (DV.SITE_ID,DV.NEARESTCITY,DV.STATE,DV.REGION,DV.TIMEZONE,
             DV.COUNTRY,DV.ELEVUNITABBR);

END;

/
-- Expanding: ./TRIGGERS/decodes_sitename.trg

CREATE OR REPLACE TRIGGER DECODES_SITENAME_UPDATE
 instead of update on SITE_TO_DECODES_NAME_VIEW 
referencing old as old new as new 
for each row
declare
 TEMP_SCS_ID number;
begin
  /* nametypes of "HDB" removed fromm procesing as of new view and per A. Gilmore 2/07/07  */
  if (:new.nametype <> 'hdb') then
   select ext_site_code_sys_id into TEMP_SCS_ID
   from hdb_ext_site_code_sys 
   where ext_site_code_sys_name = :new.nametype;
   
   update hdb_ext_site_code
   set
     primary_site_code = :new.sitename,
     secondary_site_code = :new.dbnum||'|'||:new.agency_cd
     where
     ext_site_code_sys_id = TEMP_SCS_ID and
     hdb_site_id = :new.siteid;
  end if;
end;

/

create or replace trigger decodes_sitename_delete
instead of delete on site_to_decodes_name_view 
declare
 TEMP_COUNT number;

begin


/* first go find if there are any records in the exhdb_ext_site_code table  */
select count(*)  into temp_count from hdb_ext_site_code where hdb_site_id = :old.siteid;

if (temp_count > 0 and :old.nametype <> 'hdb') then
  delete from hdb_ext_site_code where hdb_site_id = :old.siteid and primary_site_code = :old.sitename;
end if;


END;

/
create or replace trigger decodes_sitename_insert
instead of insert on site_to_decodes_name_view 
for each row
declare
 TEMP_SCS_ID number;
begin
  /* nametypes of "HDB" removed fromm procesing as of new view and per A. Gilmore 2/07/07  */
  if (:new.nametype <> 'hdb') then
   select ext_site_code_sys_id into TEMP_SCS_ID from hdb_ext_site_code_sys where ext_site_code_sys_name = :new.nametype;
   insert into hdb_ext_site_code ( ext_site_code_sys_id,primary_site_code,secondary_site_code,hdb_site_id)
   values (TEMP_SCS_ID,:new.sitename,:new.dbnum||'|'||:new.agency_cd,:new.siteid);
  end if;
END;

/
-- Expanding: ./TRIGGERS/decodes_engineeringunit_do_nothing.trg
/* this set of triggers is now obsolete due to the czar strategy employed for the datatypes rework  project  */
/* so this set of triggers which basically do nothing but allow code to do dml against the view              */
/* should be deployed as of 09/01/2006  */

create or replace trigger decodes_unit_delete
instead of delete on unit_to_decodes_unit_view 
for each row
declare
 TEMP_COUNT number;

begin


/* right now just delete if the abbreviation is there  */
/* actually don't do any deletes cause the use of rledit would destroy the database  */
/* so effectively shut off delete capabilities */
/*  delete from hdb_unit where unit_common_name = :old.unitabbr;   */
temp_count := 0;

END;

/

create or replace trigger decodes_unit_update
instead of update on unit_to_decodes_unit_view 
for each row
declare
 TEMP_DIM_ID number;
begin

/* effectively don't do anything so that everything works that tries to update the database via this view */
/* but in actuallity nothing will actually be done                                                         */
TEMP_DIM_ID := 0;

END;

/


create or replace trigger decodes_unit_insert
instead of insert on unit_to_decodes_unit_view 
declare
 TEMP_DIM_ID number;
 TEMP_UNIT_ID number;
begin

/* effectively don't do anything so that everything works that tries to update the database via this view */
/* but in actuallity nothing will actually be done                                                         */
TEMP_DIM_ID := 0;

END;

/
-- Expanding: ./TRIGGERS/decodes_hdb_site.trg

CREATE OR REPLACE TRIGGER HDB_SITE_PK_TRIG 
BEFORE INSERT OR UPDATE ON HDB_SITE FOR EACH ROW 
/*  this trigger was created to replace the normally installed trigger that defines the site_id
    primary key via a call to the stored procedure.  This trigger was replaced with this code 
    because of the effort to integrate DECODES into the maintream HDB environment.  THere was little chance
    to get decodes to modify the primary key generator it used which was a sequence.  So to keep the sequence
    correct regardless of the method used to put data into hdb_site.  A sequence was necessary.

    this trigger written by M. Bogner  May 2005   */
BEGIN 
  /*  if the site_id is null comming in here then call the sequence to get the next available key
      otherwise the assume the key was generated outside via the sequence or an other method
      so leave it alone and continue processing  */
  IF inserting AND :new.SITE_ID is null THEN 
      select hdb_site_sequence.nextval into :new.SITE_ID from dual; 
  ELSIF updating THEN 
    /*  leave the site_id the same if updating  */
    :new.SITE_ID := :old.SITE_ID; 
  END IF; 
END;

/

CREATE OR REPLACE TRIGGER HDB_SITE_EXTENSION_TRIG 
AFTER INSERT ON HDB_SITE FOR EACH ROW 
/*  this trigger was created to insure that no matter how a record was placed into HDB that an 
    corresponding record in the decodes_site_ext table was also inserted.   This makes sure there 
    row consistency between these two tables.
    this trigger written by M. Bogner  May 2005   
    modified by M Bogner 7/31/08 to do a merge instead of an insert to fix a 
    bug created during a refresh on a slave database
    */
BEGIN 
/* nothing great we have to do here but to insert a record into the decodessite_ext  table  
   only if it doesn't already exist  */
   
    merge into decodes_site_ext dse using (select :new.site_id new_site_id from dual) dv
    on (dse.site_id = dv.new_site_id)
    when matched then update set region=dse.region
    when not matched then insert (site_id) values (dv.new_site_id);
    
    -- insert doesn't cut it on snapshot refreshes since the refresh triggers inserts for
    -- records already in the extension table
    -- insert into DECODES_Site_ext (site_id) values (:new.site_id);
END;

/
-- Expanding: ./TRIGGERS/hdb_site_site_perm.trg
create or replace TRIGGER hdb_site_site_perm
after             insert OR update OR delete
on                hdb_site
for   each row
declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;
begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','HDB_META_ROLE');
     else
	the_app_user := the_user;
        if not (is_role_granted ('SAVOIR_FAIRE')
             OR is_role_granted ('HDB_META_ROLE')) then
    	  is_valid_role := 0;
	else
	  is_valid_role := 1;
	end if;
     end if;

--     raise_application_error (-20001,'THE USER: '|| the_user||'APP_USER: '||the_app_user||'ROLE VALID '||is_valid_role);

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
     
     /* populate the ref_db_generic_list table for the snapshot_manager  */
     /* added by M. Bogner April 2013  */
     snapshot_manager.snapshot_modified('HDB_SITE');
end;
/
-- show errors trigger hdb_site_site_perm;
/

create or replace trigger hdb_site_archive_update                                                                    
after update on hdb_site 
for each row 
begin 
insert into hdb_site_archive (  
SITE_ID,
SITE_NAME,
SITE_COMMON_NAME,
OBJECTTYPE_ID,
PARENT_SITE_ID,
PARENT_OBJECTTYPE_ID,
STATE_ID,
BASIN_ID,
LAT,
LONGI,
HYDROLOGIC_UNIT,
SEGMENT_NO,
RIVER_MILE,
ELEVATION,
DESCRIPTION,
NWS_CODE,
SCS_ID,
SHEF_CODE,
USGS_ID,
DB_SITE_CODE,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT) 
values (                                           
:old.SITE_ID,
:old.SITE_NAME,
:old.SITE_COMMON_NAME,
:old.OBJECTTYPE_ID,
:old.PARENT_SITE_ID,
:old.PARENT_OBJECTTYPE_ID,
:old.STATE_ID,
:old.BASIN_ID,
:old.LAT,
:old.LONGI,
:old.HYDROLOGIC_UNIT,
:old.SEGMENT_NO,
:old.RIVER_MILE,
:old.ELEVATION,
:old.DESCRIPTION,
:old.NWS_CODE,
:old.SCS_ID,
:old.SHEF_CODE,
:old.USGS_ID,
:old.DB_SITE_CODE,                                                                                                                                                                                                
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_site_archive_update;                                                                         
/
                                                                                                                        
create or replace trigger hdb_site_archive_delete                                                                    
after delete on hdb_site 
for each row 
begin 
insert into hdb_site_archive (                     
SITE_ID,
SITE_NAME,
SITE_COMMON_NAME,
OBJECTTYPE_ID,
PARENT_SITE_ID,
PARENT_OBJECTTYPE_ID,
STATE_ID,
BASIN_ID,
LAT,
LONGI,
HYDROLOGIC_UNIT,
SEGMENT_NO,
RIVER_MILE,
ELEVATION,
DESCRIPTION,
NWS_CODE,
SCS_ID,
SHEF_CODE,
USGS_ID,
DB_SITE_CODE,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT
) values (                                           
:old.SITE_ID,
:old.SITE_NAME,
:old.SITE_COMMON_NAME,
:old.OBJECTTYPE_ID,
:old.PARENT_SITE_ID,
:old.PARENT_OBJECTTYPE_ID,
:old.STATE_ID,
:old.BASIN_ID,
:old.LAT,
:old.LONGI,
:old.HYDROLOGIC_UNIT,
:old.SEGMENT_NO,
:old.RIVER_MILE,
:old.ELEVATION,
:old.DESCRIPTION,
:old.NWS_CODE,
:old.SCS_ID,
:old.SHEF_CODE,
:old.USGS_ID,
:old.DB_SITE_CODE,  
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_site_archive_delete;   
/
-- Expanding: ./TRIGGERS/hdb_datatype_triggers.trg
CREATE OR REPLACE TRIGGER HDB_DATATYPE_PK_TRIG 
BEFORE INSERT OR UPDATE 
ON HDB_DATATYPE 
FOR EACH ROW 
BEGIN 
	IF inserting THEN 
	   IF populate_pk.pkval_pre_populated = FALSE THEN 
	      :new.DATATYPE_ID := populate_pk.get_pk_val( 'HDB_DATATYPE', FALSE );  
	   END IF;
       /* modified by M. Bogner, Sutron Corporation on 17-June_2011 to automatically 
          insert any new datatypes into the decodes datatype table to keep 
          datatype tables concurrent
       */   
       
       /* insert record into decodes.datatype table if record does not exist  */
       insert into datatype
       select :new.datatype_id,'HDB',:new.datatype_id from dual 
       minus select id,standard,id from datatype where standard = 'HDB';

    ELSIF updating THEN 
     :new.DATATYPE_ID := :old.DATATYPE_ID; 
    END IF; 
END;         
                                                                                

/

create or replace trigger hdb_datatype_archive_update                                                                    
after update on hdb_datatype 
for each row 
begin 
insert into hdb_datatype_archive (  
DATATYPE_ID,
DATATYPE_NAME,
DATATYPE_COMMON_NAME,
PHYSICAL_QUANTITY_NAME,
UNIT_ID,
ALLOWABLE_INTERVALS,
AGEN_ID,
CMMNT,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT) 
values (                                           
:old.DATATYPE_ID,                                                                                              
:old.DATATYPE_NAME,                                                                                                 
:old.DATATYPE_COMMON_NAME,
:old.PHYSICAL_QUANTITY_NAME,
:old.UNIT_ID,
:old.ALLOWABLE_INTERVALS,
:old.AGEN_ID,
:old.CMMNT,                                                                                                                                                                                                
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_datatype_archive_update;  
/                                                                       

                                                                                                                        
create or replace trigger hdb_datatype_archive_delete                                                                    
after delete on hdb_datatype 
for each row 
begin 
insert into hdb_datatype_archive (                     
DATATYPE_ID,
DATATYPE_NAME,
DATATYPE_COMMON_NAME,
PHYSICAL_QUANTITY_NAME,
UNIT_ID,
ALLOWABLE_INTERVALS,
AGEN_ID,
CMMNT,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT
) values (                                           
:old.DATATYPE_ID,                                                                                              
:old.DATATYPE_NAME,                                                                                                 
:old.DATATYPE_COMMON_NAME,
:old.PHYSICAL_QUANTITY_NAME,
:old.UNIT_ID,
:old.ALLOWABLE_INTERVALS,
:old.AGEN_ID,
:old.CMMNT,  
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_datatype_archive_delete;  
/
-- Expanding: ./TRIGGERS/hdb_ext_site_code_triggers.trg
create or replace trigger hdb_ext_site_code_dt_load                                                                     
before insert or update on hdb_ext_site_code                                                                     
for each row                                                                                                            
begin                                                                                                                   
:new.date_time_loaded := sysdate; end;                                                                                  
                                                                                                                        
/                                                                                                                       
-- show errors trigger hdb_ext_site_code_dt_load;                                                                          


create or replace trigger hdb_ext_site_code_arch_upd                                                                    
after update on hdb_ext_site_code 
for each row 
begin 
insert into hdb_ext_site_code_archive (                     
EXT_SITE_CODE_SYS_ID,                                                                                                   
PRIMARY_SITE_CODE,                                                                                                      
SECONDARY_SITE_CODE,                                                                                                    
HDB_SITE_ID,                                                                                                            
DATE_TIME_LOADED, 
ARCHIVE_REASON,
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.EXT_SITE_CODE_SYS_ID,                                                                                              
:old.PRIMARY_SITE_CODE,                                                                                                 
:old.SECONDARY_SITE_CODE,                                                                                               
:old.HDB_SITE_ID,                                                                                                       
:old.date_time_loaded,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_ext_site_code_arch_upd;                                                                         
/                                                                                                                       
commit;                                                                                                                 
                                                                                                                        
create or replace trigger hdb_ext_site_code_arch_del                                                                    
after delete on hdb_ext_site_code 
for each row 
begin 
insert into hdb_ext_site_code_archive (                     
EXT_SITE_CODE_SYS_ID,                                                                                                   
PRIMARY_SITE_CODE,                                                                                                      
SECONDARY_SITE_CODE,                                                                                                    
HDB_SITE_ID,                                                                                                            
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.EXT_SITE_CODE_SYS_ID,                                                                                              
:old.PRIMARY_SITE_CODE,                                                                                                 
:old.SECONDARY_SITE_CODE,                                                                                               
:old.HDB_SITE_ID,                                                                                                       
:old.date_time_loaded,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_ext_site_code_arch_del;                                                                         
/                                                                                                                       
-- Expanding: ./TRIGGERS/hdb_ext_data_code_triggers.trg
create or replace trigger hdb_ext_data_code_dt_load                                                                     
before insert or update on hdb_ext_data_code                                                                     
for each row                                                                                                            
begin                                                                                                                   
:new.date_time_loaded := sysdate; 
end;                                                                                  
                                                                                                                        
/                                                                                                                       
-- show errors trigger hdb_ext_data_code_dt_load;                                                                          


create or replace trigger hdb_ext_data_code_arch_upd                                                                    
after update on hdb_ext_data_code 
for each row 
begin 
insert into hdb_ext_data_code_archive (                     
EXT_DATA_CODE_SYS_ID,                                                                                                   
PRIMARY_DATA_CODE,                                                                                                      
SECONDARY_DATA_CODE,                                                                                                    
HDB_DATATYPE_ID,                                                                                                        
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.EXT_DATA_CODE_SYS_ID,                                                                                              
:old.PRIMARY_DATA_CODE,                                                                                                 
:old.SECONDARY_DATA_CODE,                                                                                               
:old.HDB_DATATYPE_ID,                                                                                                   
:old.date_time_loaded,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_ext_data_code_arch_upd;                                                                         

                                                                                                                        
create or replace trigger hdb_ext_data_code_arch_del                                                                    
after delete on hdb_ext_data_code 
for each row 
begin 
insert into hdb_ext_data_code_archive (                     
EXT_DATA_CODE_SYS_ID,                                                                                                   
PRIMARY_DATA_CODE,                                                                                                      
SECONDARY_DATA_CODE,                                                                                                    
HDB_DATATYPE_ID,                                                                                                        
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) values (                                           
:old.EXT_DATA_CODE_SYS_ID,                                                                                              
:old.PRIMARY_DATA_CODE,                                                                                                 
:old.SECONDARY_DATA_CODE,                                                                                               
:old.HDB_DATATYPE_ID,                                                                                                   
:old.date_time_loaded,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_ext_data_code_arch_del;                                                                         

-- Expanding: ./TRIGGERS/hdb_ext_data_source_triggers.trg
create or replace trigger hdb_ext_data_source_dt_load                                                                   
before insert or update on hdb_ext_data_source                                                                   
for each row                                                                                                            
begin                                                                                                                   
:new.date_time_loaded := sysdate; 
end;                                                                                  
/                                                                                                                       
-- show errors trigger hdb_ext_data_source_dt_load;                                                                        


create or replace trigger hdb_ext_data_source_arch_upd                                                                  
after update on hdb_ext_data_source 
for each row 
begin 
insert into hdb_ext_data_source_archive (                 
EXT_DATA_SOURCE_ID,                                                                                                     
EXT_DATA_SOURCE_NAME,                                                                                                   
AGEN_ID,                                                                                                                
MODEL_ID,                                                                                                               
EXT_SITE_CODE_SYS_ID,                                                                                                   
EXT_DATA_CODE_SYS_ID,                                                                                                   
COLLECTION_SYSTEM_ID,                                                                                                   
DATA_QUALITY,                                                                                                           
DESCRIPTION,                                                                                                            
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.EXT_DATA_SOURCE_ID,                                                                                                
:old.EXT_DATA_SOURCE_NAME,                                                                                              
:old.AGEN_ID,                                                                                                           
:old.MODEL_ID,                                                                                                          
:old.EXT_SITE_CODE_SYS_ID,                                                                                              
:old.EXT_DATA_CODE_SYS_ID,                                                                                              
:old.COLLECTION_SYSTEM_ID,                                                                                              
:old.DATA_QUALITY,                                                                                                      
:old.DESCRIPTION,                                                                                                       
:old.date_time_loaded,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_ext_data_source_arch_upd;                                                                       
/                                                                                                                       
commit;                                                                                                                 
                                                                                                                        
create or replace trigger hdb_ext_data_source_arch_del                                                                  
after delete on hdb_ext_data_source 
for each row 
begin 
insert into hdb_ext_data_source_archive (                 
EXT_DATA_SOURCE_ID,                                                                                                     
EXT_DATA_SOURCE_NAME,                                                                                                   
AGEN_ID,                                                                                                                
MODEL_ID,                                                                                                               
EXT_SITE_CODE_SYS_ID,                                                                                                   
EXT_DATA_CODE_SYS_ID,                                                                                                   
COLLECTION_SYSTEM_ID,                                                                                                   
DATA_QUALITY,                                                                                                           
DESCRIPTION,                                                                                                            
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.EXT_DATA_SOURCE_ID,                                                                                                
:old.EXT_DATA_SOURCE_NAME,                                                                                              
:old.AGEN_ID,                                                                                                           
:old.MODEL_ID,                                                                                                          
:old.EXT_SITE_CODE_SYS_ID,                                                                                              
:old.EXT_DATA_CODE_SYS_ID,                                                                                              
:old.COLLECTION_SYSTEM_ID,                                                                                              
:old.DATA_QUALITY,                                                                                                      
:old.DESCRIPTION,                                                                                                       
:old.date_time_loaded,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_ext_data_source_arch_del;                                                                       
-- Expanding: ./TRIGGERS/hdb_feature_property_trigs.trg
-- install the trigger to:
-- check property value type
--

create or replace trigger hdb_feature_property_chk_val
before             insert or update
on                 hdb_feature_property
for   each row
begin

     check_valid_property_value(:new.property_id, :new.value, :new.string_value, :new.date_value);
end;
/
-- show errors trigger hdb_feature_property_chk_val;
/


-- Expanding: ./TRIGGERS/hdbid_chk_val_site_ot_id.trg
create or replace trigger hdbid_chk_val_site_ot_id
after             insert or update
on                ref_hm_site_hdbid
for   each row
begin
     check_valid_site_ot_id(:new.objecttype_id, :new.site_id);
end;
/
-- show errors trigger hdbid_chk_val_site_ot_id;
/
-- Expanding: ./TRIGGERS/hm_hourly_daily_valid.trg
create or replace trigger hm_hourly_daily_valid
after             insert or update of
                          hourly,
                          daily,
                          max_hourly_date,
                          max_daily_date
on                ref_hm_site_datatype
for   each row
declare
     text                varchar2(200);
begin
    if (:new.daily = 'Y' and :new.max_daily_date is NULL) then
        text := 'Integrity Failure: Max_daily_date is null in ref_hm_site_datatype when daily = Y';
        deny_action(text);
    end if;
    if (:new.hourly = 'Y' and :new.max_hourly_date is NULL) then
        text := 'Integrity Failure: Max_hourly_date is null in ref_hm_site_datatype when hourly = Y';
        deny_action(text);
    end if;
    if (:new.hourly = 'Y' and :new.cutoff_minute is NULL) then
        text := 'Integrity Failure:  Cutoff_minute is null in ref_hm_site_datatype when hourly = Y';
        deny_action(text);
    end if;
    if (:new.hourly = 'Y' and :new.hour_offset is NULL) then
        text := 'Integrity Failure: Hour_offset is null in ref_hm_site_datatype when hourly = Y';
        deny_action(text);
    end if;
end;
/
-- show errors trigger hm_hourly_daily_valid;
/
-- @ ./TRIGGERS/ref_derivation_destination_triggers.trg;  removed for CP project	
-- @ ./TRIGGERS/ref_derivation_source_triggers.trg;  removed for CP project	
-- Expanding: ./TRIGGERS/m_hour_triggers.trg
CREATE OR REPLACE TRIGGER m_hour_after_insert_update
AFTER INSERT OR UPDATE ON M_HOUR FOR EACH ROW 
declare        
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_HOUR';
  l_interval VARCHAR2(16) := 'hour';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                  
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'hour'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Model Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                 */
  
  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time, :new.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',:new.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :new.model_run_id, 'N', '');
    
   END LOOP;
 
  l_model_run_id := :new.model_run_id;
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,null,null,l_delete_flag);   
  END IF;
  
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_hour_after_insert_update;

CREATE OR REPLACE TRIGGER m_hour_after_delete
AFTER DELETE ON M_HOUR FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_HOUR';
  l_interval VARCHAR2(16) := 'hour';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                 
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'hour'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
  
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time, :old.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',:old.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :old.model_run_id, 'Y', '');
    
   END LOOP;
 
  l_model_run_id := :old.model_run_id;   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_hour_after_delete;
-- Expanding: ./TRIGGERS/m_day_triggers.trg
CREATE OR REPLACE TRIGGER m_day_after_insert_update
AFTER INSERT OR UPDATE ON M_DAY FOR EACH ROW 
declare       
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_DAY';
  l_interval VARCHAR2(16) := 'day';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'day'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Model Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time, :new.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',:new.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :new.model_run_id, 'N', '');
    
   END LOOP;
 
  l_model_run_id := :new.model_run_id;
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_day_after_insert_update;

CREATE OR REPLACE TRIGGER m_day_after_delete
AFTER DELETE ON M_DAY FOR EACH ROW 
declare       
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_DAY';
  l_interval VARCHAR2(16) := 'day';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'day'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
  
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time, :old.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',:old.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :old.model_run_id, 'Y', '');
    
   END LOOP;
 
  l_model_run_id := :old.model_run_id;   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,null,null,l_delete_flag);   
  END IF;
    
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_day_after_delete;
-- Expanding: ./TRIGGERS/m_month_triggers.trg
CREATE OR REPLACE TRIGGER m_month_after_insert_update
AFTER INSERT OR UPDATE ON M_MONTH FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_MONTH';
  l_interval VARCHAR2(16) := 'month';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'month'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Model Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                 */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time, :new.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',:new.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :new.model_run_id, 'N', '');
    
   END LOOP;
 
  l_model_run_id := :new.model_run_id;
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_month_after_insert_update;

CREATE OR REPLACE TRIGGER m_month_after_delete
AFTER DELETE ON M_MONTH FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_MONTH';
  l_interval VARCHAR2(16) := 'month';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'month'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
  
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time, :old.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',:old.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :old.model_run_id, 'Y', '');
    
   END LOOP;
 
  l_model_run_id := :old.model_run_id;   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_month_after_delete;
-- Expanding: ./TRIGGERS/m_year_triggers.trg
CREATE OR REPLACE TRIGGER m_year_after_insert_update
AFTER INSERT OR UPDATE ON M_YEAR FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_YEAR';
  l_interval VARCHAR2(16) := 'year';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'year'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Model Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                 */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time, :new.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',:new.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :new.model_run_id, 'N', '');
    
   END LOOP;
 
  l_model_run_id := :new.model_run_id;
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_year_after_insert_update;

CREATE OR REPLACE TRIGGER m_year_after_delete
AFTER DELETE ON M_YEAR FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_YEAR';
  l_interval VARCHAR2(16) := 'year';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'year'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
  
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
   
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time, :old.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',:old.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :old.model_run_id, 'Y', '');
    
   END LOOP;
 
  l_model_run_id := :old.model_run_id;   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_year_after_delete;
-- Expanding: ./TRIGGERS/m_wy_triggers.trg
CREATE OR REPLACE TRIGGER m_wy_after_insert_update
AFTER INSERT OR UPDATE ON M_WY FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_WY';
  l_interval VARCHAR2(16) := 'wy';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'wy'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Model Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                 */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time, :new.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',:new.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :new.model_run_id, 'N', '');
    
   END LOOP;
 
  l_model_run_id := :new.model_run_id;
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_wy_after_insert_update;

CREATE OR REPLACE TRIGGER m_wy_after_delete
AFTER DELETE ON M_WY FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'M_WY';
  l_interval VARCHAR2(16) := 'wy';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE, mri NUMBER) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'M_'
  and interval = 'wy'
  and sdt between effective_start_date_time and effective_end_date_time
  and model_id in (select model_id from ref_model_run where model_run_id = mri);
  
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_tasklist table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time, :old.model_run_id) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',:old.model_run_id
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, :old.model_run_id, 'Y', '');
    
   END LOOP;
 
  l_model_run_id := :old.model_run_id;   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,null,null,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger m_wy_after_delete;
-- Expanding: ./TRIGGERS/ref_db_generic_list_triggers.trg
CREATE OR REPLACE TRIGGER DB_GENERIC_LIST_PK_TRIG 
BEFORE INSERT OR UPDATE 
ON REF_DB_GENERIC_LIST
FOR EACH ROW 
declare
  l_count            number;
  l_text               varchar2(200);
BEGIN 
    
    /* create by M. Bogner May 2013 for the UC SNAPSHOT_MANAGER project  */
    /*
    the purpose of this trigger is to:
    
     populate the primary key through a sequence 
     update the date_time_loaded column
 
/* update the PK from the sequence for a new record insertion  */
	IF inserting THEN
	      SELECT REF_DB_GENERIC_LIST_SEQUENCE.NEXTVAL INTO :NEW.RECORD_ID FROM DUAL;
    ELSIF updating THEN 
     /*  do nothing as of now  */
     null;
    END IF; 
  
   :new.date_time_loaded := sysdate;
END;                                                                                         

/
-- Expanding: ./TRIGGERS/ref_czar_db_generic_list_triggers.trg
CREATE OR REPLACE TRIGGER CZAR_GENERIC_LIST_PK_TRIG 
BEFORE INSERT OR UPDATE 
ON REF_CZAR_DB_GENERIC_LIST
FOR EACH ROW 
declare
  l_count            number;
  l_text               varchar2(200);
BEGIN 
    
    /* create by Ismail Ozdemir on Dec 2021 for the UC SNAPSHOT_MANAGER project  */
    /*
    the purpose of this trigger is to:
    
     populate the primary key through a sequence 
     update the date_time_loaded column
 
/* update the PK from the sequence for a new record insertion  */
	IF inserting THEN
	      SELECT REF_CZAR_DB_GENERIC_LIST_SEQUENCE.NEXTVAL INTO :NEW.RECORD_ID FROM DUAL;
    ELSIF updating THEN 
     /*  do nothing as of now  */
     null;
    END IF; 
  
   :new.date_time_loaded := sysdate;
END;                                                                                         

/
-- Expanding: ./TRIGGERS/ref_ext_site_data_map_triggers.trg
create or replace trigger ref_ext_site_data_map_check
before insert or update
on ref_ext_site_data_map
for each row
declare
  count_0_keys   number;
begin
  if (lower(:new.extra_keys_y_n) = 'n' and lower(:old.extra_keys_y_n) = 'y') then
    deny_action ('Updating from extra keys to no extra keys is not allowed. Delete old mapping record and create a new one.');
  elsif (lower(:new.extra_keys_y_n) = 'n' and lower(:old.extra_keys_y_n) is null) then
    select count(*) 
    into count_0_keys
    from ref_ext_site_data_map
    where ext_data_source_id = :new.ext_data_source_id
      and primary_site_code = :new.primary_site_code
      and primary_data_code = :new.primary_data_code
      and lower(extra_keys_y_n) = 'n'
      and mapping_id <> nvl(:new.mapping_id,-9999);
 
    if (count_0_keys > 0) then
      deny_action ('There is already a mapping for this source/site/data code with no extra keys.');
    end if;

  end if;
end;
/
-- show errors;



create or replace trigger ref_ext_site_data_map_dt_load
before insert or update on ref_ext_site_data_map
for each row
begin
  :new.date_time_loaded := sysdate;
end;
/
-- show errors trigger ref_ext_site_data_map_dt_load;


create or replace trigger ref_ext_site_data_map_arch_upd
after update on ref_ext_site_data_map
for each row
begin
-- archive the row that was changed
  insert into ref_ext_site_data_map_archive
   (mapping_id,
    ext_data_source_id,
    primary_site_code,   
    primary_data_code,    
    extra_keys_y_n,    
    hdb_site_datatype_id,
    hdb_interval_name, 
    hdb_method_id,       
    hdb_computation_id,
    hdb_agen_id,   
    is_active_y_n,
    cmmnt,        
    date_time_loaded, 
    archive_reason,
    date_time_archived,
    archive_cmmnt              )
  values
   (:old.mapping_id,
    :old.ext_data_source_id,
    :old.primary_site_code,   
    :old.primary_data_code,    
    :old.extra_keys_y_n,    
    :old.hdb_site_datatype_id,
    :old.hdb_interval_name, 
    :old.hdb_method_id,       
    :old.hdb_computation_id,
    :old.hdb_agen_id,   
    :old.is_active_y_n,
    :old.cmmnt,        
    :old.date_time_loaded, 
     'UPDATE',
     sysdate,
    coalesce(
                  sys_context('APEX$SESSION','app_user')
                 ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                 ,sys_context('userenv','session_user')
                 ) || ':' || sys_context('userenv','os_user') 
                 || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
    );
end;
/
-- show errors trigger ref_ext_site_data_map_arch_upd;


create or replace trigger ref_ext_site_data_map_arch_del
after delete on ref_ext_site_data_map
for each row
begin
-- archive the row that was changed
  insert into ref_ext_site_data_map_archive
   (mapping_id,
    ext_data_source_id,
    primary_site_code,   
    primary_data_code,    
    extra_keys_y_n,    
    hdb_site_datatype_id,
    hdb_interval_name, 
    hdb_method_id,       
    hdb_computation_id,
    hdb_agen_id,   
    is_active_y_n,
    cmmnt,        
    date_time_loaded, 
    archive_reason,
    date_time_archived,
    archive_cmmnt              )
  values
   (:old.mapping_id,
    :old.ext_data_source_id,
    :old.primary_site_code,   
    :old.primary_data_code,    
    :old.extra_keys_y_n,    
    :old.hdb_site_datatype_id,
    :old.hdb_interval_name, 
    :old.hdb_method_id,       
    :old.hdb_computation_id,
    :old.hdb_agen_id,   
    :old.is_active_y_n,
    :old.cmmnt,        
    :old.date_time_loaded, 
     'DELETE',
     sysdate,
    coalesce(
              sys_context('APEX$SESSION','app_user')
             ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
             ,sys_context('userenv','session_user')
             ) || ':' || sys_context('userenv','os_user') 
             || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_ext_site_data_map_arch_del;

-- Expanding: ./TRIGGERS/ref_ext_site_data_map_keyval_triggers.trg
create or replace trigger ref_ext_site_data_mapk_dt_load 
before insert or update on ref_ext_site_data_map_keyval  
for each row 
begin
 :new.date_time_loaded := sysdate; 
end;   
/
-- show errors trigger ref_ext_site_data_mapk_dt_load;   



create or replace trigger site_data_map_keyval_arch_upd                                                                
after update on ref_ext_site_data_map_keyval 
for each row 
begin 
insert into ref_ext_site_data_map_key_arch (     
MAPPING_ID,                                                                                                             
KEY_NAME,                                                                                                               
KEY_VALUE,                                                                                                              
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.MAPPING_ID,                                                                                                        
:old.KEY_NAME,                                                                                                          
:old.KEY_VALUE,                                                                                                         
:old.date_time_loaded,
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger site_data_map_keyval_arch_upd;                                                                      

                                                                                                                        
create or replace trigger site_data_map_keyval_arch_del                                                                
after delete on ref_ext_site_data_map_keyval 
for each row 
begin 
insert into ref_ext_site_data_map_key_arch (     
MAPPING_ID,                                                                                                             
KEY_NAME,                                                                                                               
KEY_VALUE,                                                                                                              
DATE_TIME_LOADED, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.MAPPING_ID,                                                                                                        
:old.KEY_NAME,                                                                                                          
:old.KEY_VALUE,                                                                                                         
:old.date_time_loaded,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger site_data_map_keyval_arch_del;                                                                      

-- Expanding: ./TRIGGERS/ref_interval_redefinition_triggers.trg
-- install the triggers to:
--  -- set the date_time_loaded in ref_interval_redefinition
--  -- load a row to ref_interval_redef_archive
-- 10/02/01
--

create or replace trigger ref_interval_redef_dt_load
before insert or update on ref_interval_redefinition
for each row
begin
  :new.date_time_loaded := sysdate;
end;
/
-- show errors trigger ref_interval_redef_dt_load;

create or replace trigger ref_interval_redef_arch_update
after update on ref_interval_redefinition
for each row
begin
-- archive the row that was changed
  insert into ref_interval_redef_archive
   (interval                  ,
    time_offset               ,
    offset_units              ,
    date_time_loaded          , 
    archive_reason            , 
    date_time_archived        , 
    archive_cmmnt              )
  values
   (:old.interval                  ,
    :old.time_offset               ,
    :old.offset_units              ,
    :old.date_time_loaded          ,
     'UPDATE',
     sysdate,
    coalesce(
              sys_context('APEX$SESSION','app_user')
             ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
             ,sys_context('userenv','session_user')
             ) || ':' || sys_context('userenv','os_user') 
             || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_interval_redef_arch_update;

create or replace trigger ref_interval_redef_arch_delete
after delete on ref_interval_redefinition
for each row
begin
-- archive the row that was changed
  insert into ref_interval_redef_archive
   (interval                  ,
    time_offset               ,
    offset_units              ,
    date_time_loaded          ,
    archive_reason            , 
    date_time_archived        , 
    archive_cmmnt              )
  values
   (:old.interval                  ,
    :old.time_offset               ,
    :old.offset_units              ,
    :old.date_time_loaded          ,
     'DELETE',
     sysdate,
    coalesce(
              sys_context('APEX$SESSION','app_user')
             ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
             ,sys_context('userenv','session_user')
             ) || ':' || sys_context('userenv','os_user') 
             || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_interval_redef_arch_delete;



-- Expanding: ./TRIGGERS/ref_interval_copy_limits_triggers.trg

create or replace trigger ref_interval_cp_lim_b4_ins_up
before             insert OR update 
on                ref_interval_copy_limits
for   each row
begin
    
    /* created by M.  Bogner 01/07/11  */
    /*
    the purpose of this trigger is to make sure the date_time_loaded is modified
    to sysdate
    */
    
      :new.date_time_loaded := sysdate;

end;
/

create or replace trigger ref_interval_cp_limits_update                                                                    
after update on  ref_interval_copy_limits 
for each row 
begin 
/*  This trigger created by M.  Bogner  11/19/2007
    This trigger archives any updates to the table
    ref_interval_copy_limits.
    
    modified by M. Bogner 27 Oct 2008 to account for
    new preprocessor columns
*/
insert into  ref_inter_copy_limits_archive (                     
SITE_DATATYPE_ID,
INTERVAL,
MIN_VALUE_EXPECTED,
MIN_VALUE_CUTOFF,
MAX_VALUE_EXPECTED,
MAX_VALUE_CUTOFF,
TIME_OFFSET_MINUTES,
DATE_TIME_LOADED,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT,
EFFECTIVE_START_DATE_TIME,
EFFECTIVE_END_DATE_TIME,
PREPROCESSOR_EQUATION
) 
VALUES (
:old.SITE_DATATYPE_ID,
:old.INTERVAL,
:old.MIN_VALUE_EXPECTED,
:old.MIN_VALUE_CUTOFF,
:old.MAX_VALUE_EXPECTED,
:old.MAX_VALUE_CUTOFF,
:old.TIME_OFFSET_MINUTES,
:old.DATE_TIME_LOADED,
'UPDATE',
sysdate,
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
:old.EFFECTIVE_START_DATE_TIME,
:old.EFFECTIVE_END_DATE_TIME,
:old.PREPROCESSOR_EQUATION
);
end;                                                                    

/                                                                                                                       
-- show errors trigger ref_interval_cp_limits_update;                                                                         

                                                                                                                        
create or replace trigger ref_interval_cp_limits_delete                                                            
after delete on ref_interval_copy_limits 
for each row 
begin 
/*  This trigger created by M.  Bogner  11/19/2007
    This trigger archives any updates to the table
    ref_interval_copy_limits.
    
    modified by M. Bogner 27 Oct 2008 to account for
    new preprocessor columns
*/
insert into  ref_inter_copy_limits_archive (                     
SITE_DATATYPE_ID,
INTERVAL,
MIN_VALUE_EXPECTED,
MIN_VALUE_CUTOFF,
MAX_VALUE_EXPECTED,
MAX_VALUE_CUTOFF,
TIME_OFFSET_MINUTES,
DATE_TIME_LOADED,
ARCHIVE_REASON,
DATE_TIME_ARCHIVED,
ARCHIVE_CMMNT,
EFFECTIVE_START_DATE_TIME,
EFFECTIVE_END_DATE_TIME,
PREPROCESSOR_EQUATION
) 
VALUES (
:old.SITE_DATATYPE_ID,
:old.INTERVAL,
:old.MIN_VALUE_EXPECTED,
:old.MIN_VALUE_CUTOFF,
:old.MAX_VALUE_EXPECTED,
:old.MAX_VALUE_CUTOFF,
:old.TIME_OFFSET_MINUTES,
:old.DATE_TIME_LOADED,
'DELETE',
sysdate,
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME'),
:old.EFFECTIVE_START_DATE_TIME,
:old.EFFECTIVE_END_DATE_TIME,
:old.PREPROCESSOR_EQUATION
);
end;                                                                    
/                                                                                                                       
-- show errors trigger ref_interval_cp_limits_delete;                                                                         

-- Expanding: ./TRIGGERS/ref_rating_triggers.trg
create or replace trigger ref_rating_insert_update
before insert or update on ref_rating
for each row
begin
:new.date_time_loaded := sysdate; 
end;

/
-- show errors trigger ref_rating_insert_update;


create or replace trigger ref_rating_arch_upd
after update on ref_rating for each row 
begin 
insert into ref_rating_archive (
RATING_ID,
INDEPENDENT_VALUE,
DEPENDENT_VALUE,
DATE_TIME_LOADED, ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.RATING_ID,
:old.INDEPENDENT_VALUE,
:old.DEPENDENT_VALUE,
:old.date_time_loaded,'UPDATE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;
/

-- show errors trigger ref_rating_arch_upd;


create or replace trigger ref_rating_arch_del
after delete on ref_rating for each row 
begin 
insert into ref_rating_archive (
RATING_ID,
INDEPENDENT_VALUE,
DEPENDENT_VALUE,
DATE_TIME_LOADED, ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.RATING_ID,
:old.INDEPENDENT_VALUE,
:old.DEPENDENT_VALUE,
:old.date_time_loaded,'DELETE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;
/
-- show errors trigger ref_rating_arch_del;

-- Expanding: ./TRIGGERS/ref_site_rating_triggers.trg
CREATE OR REPLACE TRIGGER REF_SITE_RATING_PK_TRIG
before INSERT OR UPDATE
ON "REF_SITE_RATING"
FOR EACH ROW
BEGIN

  IF inserting THEN
    SELECT ref_site_rating_seq.nextval
    INTO :NEW.rating_id
    FROM dual;
  ELSIF updating THEN
      :NEW.rating_id := :OLD.rating_id;
  END IF;

  :NEW.date_time_loaded := sysdate;
END;

/
-- show errors trigger REF_SITE_RATING_PK_TRIG;


create or replace trigger ref_site_rating_arch_upd
after update on ref_site_rating for each row 
begin 
insert into ref_site_rating_archive (
RATING_ID,
INDEP_SITE_DATATYPE_ID,
RATING_TYPE_COMMON_NAME,
EFFECTIVE_START_DATE_TIME,
EFFECTIVE_END_DATE_TIME,
DATE_TIME_LOADED,
AGEN_ID,
DESCRIPTION,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.RATING_ID,
:old.INDEP_SITE_DATATYPE_ID,
:old.RATING_TYPE_COMMON_NAME,
:old.EFFECTIVE_START_DATE_TIME,
:old.EFFECTIVE_END_DATE_TIME,
:old.DATE_TIME_LOADED,
:old.AGEN_ID,
:old.DESCRIPTION,
'UPDATE', sysdate, 
    coalesce(
              sys_context('APEX$SESSION','app_user')
             ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
             ,sys_context('userenv','session_user')
             ) || ':' || sys_context('userenv','os_user') 
             || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
 end;
/
-- show errors trigger ref_site_rating_arch_upd;



create or replace trigger ref_site_rating_arch_del
after delete on ref_site_rating for each row 
begin 
insert into ref_site_rating_archive (
RATING_ID,
INDEP_SITE_DATATYPE_ID,
RATING_TYPE_COMMON_NAME,
EFFECTIVE_START_DATE_TIME,
EFFECTIVE_END_DATE_TIME,
DATE_TIME_LOADED,
AGEN_ID,
DESCRIPTION,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.RATING_ID,
:old.INDEP_SITE_DATATYPE_ID,
:old.RATING_TYPE_COMMON_NAME,
:old.EFFECTIVE_START_DATE_TIME,
:old.EFFECTIVE_END_DATE_TIME,
:old.DATE_TIME_LOADED,
:old.AGEN_ID,
:old.DESCRIPTION,
'DELETE', sysdate, 
    coalesce(
              sys_context('APEX$SESSION','app_user')
             ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
             ,sys_context('userenv','session_user')
             ) || ':' || sys_context('userenv','os_user') 
             || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_site_rating_arch_del;


-- Expanding: ./TRIGGERS/ref_res_flowlu_site_perm.trg
create or replace TRIGGER ref_res_flowlu_site_perm
after             insert or update or delete
on                ref_res_flowlu
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger ref_res_flowlu_site_perm;
/
-- Expanding: ./TRIGGERS/ref_res_wselu_site_perm.trg
create or replace TRIGGER ref_res_wselu_site_perm
after             insert or update or delete
on                ref_res_wselu
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger ref_res_wselu_site_perm;
/
-- Expanding: ./TRIGGERS/ref_site_attr_trigs.trg
-- install the triggers to:
-- set the effective_start_date_time and check attr value type
-- load a row to ref_site_attr_archive
-- 10/02/01
--

  CREATE OR REPLACE TRIGGER REF_SITE_ATTR_DT_LOAD_CHK_VAL
  BEFORE INSERT OR UPDATE ON REF_SITE_ATTR
  REFERENCING FOR EACH ROW
  DECLARE
temp_num NUMBER;
begin
     check_valid_attr_value(:new.attr_id, :new.value, :new.string_value, :new.date_value);
     :new.date_time_loaded := SYSDATE;

    /* Added by M.  Bogner 10/01/11 for ACL II project */

    /*
    the purpose of this part of the trigger is to make sure that the user has permissions
    to modify this table since only ${hdb_user} or ${hdb_user} ACLII people can modify this table if ACL
    VERSION II is an active feature
    */

	/* see if ACL PROJECT II is enabled and if this is a group attribute if user is permitted */
	IF (hdb_utilities.is_feature_activated('ACCESS CONTROL LIST GROUP VERSION II') = 'Y'
	    AND hdb_utilities.GET_SITE_ACL_ATTR = :new.attr_id ) THEN
	  begin
	    temp_num := 0;
		/* see if user account is an active ${hdb_user} or ACLII ACCOUNT */
		select count(*) into temp_num  from ref_user_groups
		where user_name = user and group_name in ('${hdb_user}','${hdb_user} ACLII');
		exception when others then
--		DENY_ACTION(SQLERRM);
		temp_num := -1;
	  end;

	  IF (temp_num < 1) THEN
		DENY_ACTION('ILLEGAL ACL VERSION II REF_SITE_ATTR DATABASE OPERATION -- No Permissions');
	  END IF;

	END IF;

end;
/
-- show errors trigger ref_site_attr_dt_load_chk_val;


create or replace trigger ref_site_attr_arch_update
after update on ref_site_attr
REFERENCING NEW AS NEW OLD AS OLD
for each row
begin
  insert into ref_site_attr_archive
   (site_id,
    attr_id,
    effective_start_date_time,
    effective_end_date_time,
    value,
    string_value,
    date_value,
    date_time_loaded,
    archive_reason,
    date_time_archived,
    archive_cmmnt)
  values
   (:old.site_id,
    :old.attr_id,
    :old.effective_start_date_time,
    :old.effective_end_date_time,
    :old.value,
    :old.string_value,
    :old.date_value,
    :old.date_time_loaded,
     'UPDATE',
     sysdate,
        coalesce(
                  sys_context('APEX$SESSION','app_user')
                 ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                 ,sys_context('userenv','session_user')
                 ) || ':' || sys_context('userenv','os_user') 
                 || ':' || sys_context('userenv','HOST') 
             || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_site_attr_arch_update;

  CREATE OR REPLACE TRIGGER REF_SITE_ATTR_ARCH_DELETE
  AFTER DELETE ON REF_SITE_ATTR
  REFERENCING FOR EACH ROW
  DECLARE
temp_num NUMBER;
begin

    /* Added by M.  Bogner 10/01/11 for ACL II project */

    /*
    the purpose of this part of the trigger is to make sure that the user has permissions
    to modify this table since only ${hdb_user} or ${hdb_user} ACLII people can modify this table if ACL
    VERSION II is an active feature
    */

	/* see if ACL PROJECT II is enabled and if this is a group attribute if user is permitted */
	IF (hdb_utilities.is_feature_activated('ACCESS CONTROL LIST GROUP VERSION II') = 'Y'
	    AND hdb_utilities.GET_SITE_ACL_ATTR = :old.attr_id ) THEN
	  begin
	    temp_num := 0;
		/* see if user account is an active ${hdb_user} or ACLII ACCOUNT */
		select count(*) into temp_num  from ref_user_groups
		where user_name = user and group_name in ('${hdb_user}','${hdb_user} ACLII');
		exception when others then
--		DENY_ACTION(SQLERRM);
		temp_num := -1;
	  end;

	  IF (temp_num < 1) THEN
		DENY_ACTION('ILLEGAL ACL VERSION II REF_SITE_ATTR DATABASE OPERATION -- No Permissions');
	  END IF;

	END IF;

/* now if the delete was allowed; then archive the old data  */

  insert into ref_site_attr_archive
   (site_id,
    attr_id,
    effective_start_date_time,
    effective_end_date_time,
    value,
    string_value,
    date_value,
    date_time_loaded,
    archive_reason,
    date_time_archived,
    archive_cmmnt)
  values
   (:old.site_id,
    :old.attr_id,
    :old.effective_start_date_time,
    :old.effective_end_date_time,
    :old.value,
    :old.string_value,
    :old.date_value,
    :old.date_time_loaded,
    'DELETE',
     sysdate,
        coalesce(
                  sys_context('APEX$SESSION','app_user')
                 ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                 ,sys_context('userenv','session_user')
                 ) || ':' || sys_context('userenv','os_user') 
                 || ':' || sys_context('userenv','HOST') 
             || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_site_attr_arch_delete;


-- Expanding: ./TRIGGERS/ref_site_coef_day_site_perm.trg
create or replace TRIGGER ref_site_coef_day_site_perm
after             insert or update or delete
on                ref_site_coef_day
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger ref_site_coef_day_site_perm;
/
-- Expanding: ./TRIGGERS/ref_site_coef_month_site_perm.trg
create or replace TRIGGER ref_site_coef_month_site_perm
after             insert or update or delete
on                ref_site_coef_month
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger ref_site_coef_month_site_perm;
/
-- Expanding: ./TRIGGERS/ref_site_coef_site_perm.trg
create or replace TRIGGER ref_site_coef_site_perm
after             insert or update or delete
on                ref_site_coef
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger ref_site_coef_site_perm;
/
-- Expanding: ./TRIGGERS/ref_site_coeflu_site_perm.trg
create or replace trigger ref_site_coeflu_site_perm
after             insert OR update OR delete
on                ref_site_coeflu
for   each row
declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
and default_role = 'YES'
and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
the_app_user := the_user;

    if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
        is_valid_role := 0;
 else
    is_valid_role := 1;
 end if;
     end if;

     if not (is_valid_role > 0) then
  check_site_id_auth (:new.site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger ref_site_coeflu_site_perm;
/
-- Expanding: ./TRIGGERS/ref_source_priority.trg
-- install the triggers to:
--  -- set the date_time_loaded in ref_source_priority
--  -- load a row to ref_source_priority_archive
-- 10/02/01
--

create or replace trigger ref_source_priority_dt_load
before insert or update on ref_source_priority
for each row
begin
  :new.date_time_loaded := sysdate;
end;
/
-- show errors trigger ref_source_priority_dt_load;


create or replace trigger ref_src_priority_arch_update
after update on ref_source_priority
REFERENCING NEW AS NEW OLD AS OLD
for each row
begin
-- archive the row that was changed
  insert into ref_source_priority_archive
   (site_datatype_id           ,
    agen_id     ,
    priority_rank              , 
    date_time_loaded          ,  
    archive_reason            , 
    date_time_archived        , 
    archive_cmmnt              )
  values
   (:old.site_datatype_id          , 
    :old.agen_id    ,
    :old.priority_rank             ,
    :old.date_time_loaded          ,  
     'UPDATE',
     sysdate,
        coalesce(
                  sys_context('APEX$SESSION','app_user')
                 ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                 ,sys_context('userenv','session_user')
                 ) || ':' || sys_context('userenv','os_user') 
                 || ':' || sys_context('userenv','HOST') 
             || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_src_priority_arch_update;

create or replace trigger ref_src_priority_arch_delete
after delete on ref_source_priority
for each row
begin
-- archive the row that was changed
  insert into ref_source_priority_archive
   (site_datatype_id           ,
    agen_id     ,
    priority_rank              ,   
    date_time_loaded          ,  
    archive_reason            , 
    date_time_archived        , 
    archive_cmmnt              )
  values
   (:old.site_datatype_id          , 
    :old.agen_id    ,
    :old.priority_rank             ,
    :old.date_time_loaded          ,  
     'DELETE',
     sysdate,
        coalesce(
                  sys_context('APEX$SESSION','app_user')
                 ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                 ,sys_context('userenv','session_user')
                 ) || ':' || sys_context('userenv','os_user') 
                 || ':' || sys_context('userenv','HOST') 
             || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_src_priority_arch_delete;


-- Expanding: ./TRIGGERS/r_base_triggers.trg
-- install the triggers to load a row to r_base_update that
-- notifies derivation application of data to process
-- 10/02/01  
--
-- Modified 2006 by C. Marra to accomodate new datatype management
-- Modified JANuary 2007 by M.bogner for derivation application retirement plan
-- Modified August 2007 by M.bogner for new commitee decisions regarding overwrite
-- Modified November 2007 by M. Bogner to insure usage of stored procedure  and move invalid flags
-- Modified March 2008 by M. Bogner to not require validation and only keep failed records from merging
-- Modified April 2008 by M. Bogner to pass along the method_id and toindicate the data may have come from the CP
-- Modified October 2008 by M. Bogner for change in validate proc for preprocessor project
-- Modified May 2009 by M. Bogner to handle unknown and wierd error of a blank validation '' as an ascii 32

create or replace trigger r_base_before_insert_update
before insert or update
on r_base
for each row
declare
  v_count            number;
  v_source_entry     number;
  v_invalid_interval number;
  e_bad_row          exception;
  text               varchar2(200);
begin

   if not (is_role_granted ('SAVOIR_FAIRE')) then
      check_sdi_auth (:new.site_datatype_id);
   end if;

   if (trunc(:new.start_date_time) > trunc(SYSDATE + 2/24)  ) then
      text := 'No future dates allowed in r_base tables';
      deny_action(text);
   end if;

  if :new.validation in ('E','+','-','w','n','|','^','~',chr(32)) then
     :new.data_flags := :new.validation || substr(:new.data_flags,1,19);
     :new.validation := NULL;
  end if;


  /* logic below added to attempt to foil Stored Procedures non-utilization  */
  if :new.date_time_loaded <> to_date('10-DEC-1815','dd-MON-yyyy') then
    :new.validation := 'F';
    :new.data_flags := 'Bad Load: Use Proc.';
  end if;

  :new.date_time_loaded:=sysdate;

  /* Start and end date must be equal for instant data.
     Datatype's allowable intervals must be either or instant
     for instant data */
  if (:new.interval = 'instant') then

     if ( :new.start_date_time <> :new.end_date_time) then
        text := 'Instant interval start and end date times must be equal';
        deny_action(text);
     end if;

     select count(*) into v_count
     from hdb_datatype dt, hdb_site_datatype sd
     where dt.allowable_intervals in ('instant','either')
       and sd.site_datatype_id = :new.site_datatype_id
       and sd.datatype_id = dt.datatype_id;

     if (v_count = 0) then
        text := 'Invalid Interval for this datatype';
        deny_action(text);
     end if;

  end if;

  /* Start date must be < end date for non-instant data.
     Datatype's allowable intervals must be either or non-instant
     for non-instant data */
  if (:new.interval <> 'instant') then

     if ( :new.start_date_time > :new.end_date_time) then
        text := 'Non-instant interval start date time must be less than the end date time';
        deny_action(text);
     end if;
     if ( :new.start_date_time = :new.end_date_time) then
        text := 'Non-instant interval start and end date times cannot be equal';
        deny_action(text);
     end if;

     select count(*) into v_count
     from hdb_datatype dt, hdb_site_datatype sd
     where dt.allowable_intervals in ('non-instant','either')
       and sd.site_datatype_id = :new.site_datatype_id
       and sd.datatype_id = dt.datatype_id;

     if (v_count = 0) then
        text := 'Invalid Interval for this datatype';
        deny_action(text);
     end if;

  end if;

  /* Validate record's agen_id against the datatype's agen_id
     (if there is one). */
  select count(*) into v_count
  from hdb_datatype dt, hdb_site_datatype sd
  where dt.agen_id is not null
    and sd.site_datatype_id = :new.site_datatype_id
    and sd.datatype_id = dt.datatype_id;

  if (v_count > 0) then
    select count(*) into v_count
    from hdb_datatype dt, hdb_site_datatype sd
    where dt.agen_id = :new.agen_id
      and sd.site_datatype_id = :new.site_datatype_id
      and sd.datatype_id = dt.datatype_id;

    if (v_count = 0) then
       text := 'Invalid Agency for this datatype';
       deny_action(text);
    end if;

  end if;

--  now validate the record before it goes into the table
--  old logic for validation removed because of business rule that modify_r_base_RAW will be used always
--  if (INSERTING and nvl(:new.validation,'Z') in ('Z')) or UPDATING then
  if (nvl(:new.validation,'Z') in ('Z')) then
    hdb_utilities.validate_r_base_record
      (:new.site_datatype_id,
       :new.interval,
       :new.start_date_time,
       :new.value,
       :new.validation);
  end if;

end;
/
-- show errors trigger r_base_before_insert_update;




create or replace trigger r_base_after_insert
after insert on r_base
for each row
declare
  v_count            number;
begin
-- Modified August 2007 by M.bogner for decision to force overwrites to be validated
-- and to add the new data_flags column
-- Modified March 2008 by M. Bogner for decision to to remove Validation requirement
-- As of March 2008 only keep data from being merged if it has an F (failed) validation

--  if nvl(:new.validation,'F') not in ('F','Z') or :new.overwrite_flag='O' then 
--  if nvl(:new.validation,'F') not in ('F','Z') then 
--    select count(*) into v_count from ref_interval_copy_limits
--      where :new.site_datatype_id=site_datatype_id
--        and :new.interval=interval;
--    only if there's a derivation spec
--      if v_count!=0 or :new.overwrite_flag='O' then
--   above logic removed for derivation replacement project
--      if v_count!=0 then

      if nvl(:new.validation,'x') not in ('F') then
          hdb_utilities.merge_into_r_interval(
            :new.site_datatype_id,
            :new.interval,
            :new.start_date_time,
            :new.end_date_time,
            :new.value,
            :new.validation,
            :new.overwrite_flag,
            :new.method_id,
            :new.data_flags,
            :new.date_time_loaded      
           );
      end if;
end;
/
-- show errors trigger r_base_after_insert;

CREATE OR REPLACE TRIGGER r_base_after_update
AFTER UPDATE ON r_base
FOR EACH ROW
DECLARE
    v_change_agent_id NUMBER;
BEGIN
    -- Lookup or insert into change_agent table
    BEGIN
        SELECT id INTO v_change_agent_id
        FROM ref_change_agent
        WHERE session_user = COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),SYS_CONTEXT('USERENV', 'SESSION_USER'))
          AND client_identifier = COALESCE(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), 'UNKNOWN_CLIENT_IDENTIFIER') 
          AND os_user = SYS_CONTEXT('USERENV', 'OS_USER')
          AND host = SYS_CONTEXT('USERENV', 'HOST')
          AND client_program_name = SYS_CONTEXT('USERENV', 'MODULE')
        FETCH FIRST ROW ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO ref_change_agent (
                session_user,
                client_identifier,
                os_user,
                host,
                client_program_name
            )
            VALUES (
                COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),SYS_CONTEXT('USERENV', 'SESSION_USER')),
                COALESCE(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), 'UNKNOWN_CLIENT_IDENTIFIER'),
                SYS_CONTEXT('USERENV', 'OS_USER'),
                SYS_CONTEXT('USERENV', 'HOST'),
                SYS_CONTEXT('USERENV', 'MODULE')
            )
            RETURNING id INTO v_change_agent_id;
    END;

    -- Archive the row that was changed
    INSERT INTO r_base_archive (
        site_datatype_id,
        interval,
        start_date_time,
        end_date_time,
        value,
        agen_id,
        overwrite_flag,
        date_time_loaded,
        validation,
        collection_system_id,
        loading_application_id,
        method_id,
        computation_id,
        archive_reason,
        date_time_archived,
        data_flags,
        change_agent_id
    )
    VALUES (
        :old.site_datatype_id,
        :old.interval,
        :old.start_date_time,
        :old.end_date_time,
        :old.value,
        :old.agen_id,
        :old.overwrite_flag,
        :old.date_time_loaded,
        :old.validation,
        :old.collection_system_id,
        :old.loading_application_id,
        :old.method_id,
        :old.computation_id,
        'UPDATE',
        SYSDATE,
        :old.data_flags,
        v_change_agent_id
    );
     
-- removed overwrite flag logic August 2007 by M. Bogner due to HDB committee decision
-- removed validation logic March 2008 by M. Bogner due to HDB committee decision
-- As of March 2008 only keep data from being merged if it has an F (failed) validation

--  if nvl(:new.validation,'F') not in ('F','Z') or :new.overwrite_flag='O' then
--  if nvl(:new.validation,'F') not in ('F','Z') then
--    select count(*) into v_count from ref_interval_copy_limits
--      where :new.site_datatype_id=site_datatype_id
--        and :new.interval=interval;
--    only if there's a derivation spec or it's a forced 'O'verwrite
--      if v_count!=0 or :new.overwrite_flag='O' then
      if nvl(:new.validation,'x') not in ('F') then
          hdb_utilities.merge_into_r_interval(
            :new.site_datatype_id,
            :new.interval,
            :new.start_date_time,
            :new.end_date_time,
            :new.value,
            :new.validation,
            :new.overwrite_flag,
            :new.method_id,
            :new.data_flags,
            :new.date_time_loaded
           );
      end if;
end;
/
-- show errors trigger r_base_after_update;

create or replace trigger r_base_before_delete
before delete on r_base
for each row
declare
  v_count            number;
begin

   if not (is_role_granted ('SAVOIR_FAIRE')) then
      check_sdi_auth (:old.site_datatype_id);
   end if;

end;
/
-- show errors trigger r_base_before_delete;

CREATE OR REPLACE TRIGGER r_base_after_delete
AFTER DELETE ON r_base
FOR EACH ROW
DECLARE
    v_change_agent_id NUMBER;
BEGIN
    -- Lookup or insert into change_agent table
    BEGIN
        SELECT id INTO v_change_agent_id
        FROM ref_change_agent
        WHERE session_user = COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),SYS_CONTEXT('USERENV', 'SESSION_USER'))
          AND client_identifier = COALESCE(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), 'UNKNOWN_CLIENT_IDENTIFIER') 
          AND os_user = SYS_CONTEXT('USERENV', 'OS_USER')
          AND host = SYS_CONTEXT('USERENV', 'HOST')
          AND client_program_name = SYS_CONTEXT('USERENV', 'MODULE')
        FETCH FIRST ROW ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO ref_change_agent (
                session_user,
                client_identifier,
                os_user,
                host,
                client_program_name
                
            )
            VALUES (
                COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),SYS_CONTEXT('USERENV', 'SESSION_USER')),
                COALESCE(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), 'UNKNOWN_CLIENT_IDENTIFIER'),
                SYS_CONTEXT('USERENV', 'OS_USER'),
                SYS_CONTEXT('USERENV', 'HOST'),
                SYS_CONTEXT('USERENV', 'MODULE')
            )
            RETURNING id INTO v_change_agent_id;
    END;

    -- Insert into r_base_archive with change_agent_id
    INSERT INTO r_base_archive (
        site_datatype_id,
        interval,
        start_date_time,
        end_date_time,
        value,
        agen_id,
        overwrite_flag,
        date_time_loaded,
        validation,
        collection_system_id,
        loading_application_id,
        method_id,
        computation_id,
        archive_reason,
        date_time_archived,
        data_flags,
        change_agent_id
    )
    VALUES (
        :old.site_datatype_id,
        :old.interval,
        :old.start_date_time,
        :old.end_date_time,
        :old.value,
        :old.agen_id,
        :old.overwrite_flag,
        :old.date_time_loaded,
        :old.validation,
        :old.collection_system_id,
        :old.loading_application_id,
        :old.method_id,
        :old.computation_id,
        'DELETE',
        SYSDATE,
        :old.data_flags,
        v_change_agent_id
    );


/*  now delete from the interval table if it exists  the thought was just try the delete
    if it works then OK otherwise a query to do the count and then do the delete seems
    to do twice the amount of work

*/
--  modified the delete August 2007 by M.  Bogner to delete regardless of date_time_loaded
--  decided to keep it simple and don't over complicate it ,  for now...
--  modified the delete December 2007 by M.  Bogner to delete with respect to date_time_loaded
--  we just can't make up our minds...
        hdb_utilities.delete_from_interval(
         :old.site_datatype_id,
         :old.interval,
         :old.start_date_time,
         :old.end_date_time,
         :old.date_time_loaded);

end;
/

-- show errors trigger r_base_after_delete;
/
-- Expanding: ./TRIGGERS/r_day_triggers.trg

create or replace trigger r_day_before_insert_update
before             insert OR update 
on                r_day
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    
    /* modified by M.  Bogner 08/31/07  */
    /*
    the purpose of this trigger is to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivatiuon flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;

end;
/

-- show errors trigger r_day_before_insert_update;

CREATE OR REPLACE TRIGGER r_day_after_insert_update
AFTER INSERT OR UPDATE ON R_DAY FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(5) := 'R_DAY';
  l_interval VARCHAR2(16) := 'day';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                     
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'day'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */
      
  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
   
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
    
    
   END LOOP;

  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   	      
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               

-- show errors trigger r_day_after_insert_update;

CREATE OR REPLACE TRIGGER r_day_after_delete
AFTER DELETE ON R_DAY FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(5) := 'R_DAY';
  l_interval VARCHAR2(16) := 'day';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                   
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'day'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */
            
  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */

/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
    
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
   
   END LOOP;
 
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
 
END;  /*  end of delete interval table trigger  */                                                                            
/
-- show errors trigger r_day_after_delete;
-- Expanding: ./TRIGGERS/r_daystat_sdi_perm.trg
create or replace TRIGGER  r_daystat_sdi_perm
after             insert OR update OR delete
on                r_daystat
for   each row
begin
	if not (is_role_granted ('SAVOIR_FAIRE')) then
	   check_sdi_auth (:new.site_datatype_id);
	end if;
end;
/
-- show errors trigger r_daystat_sdi_perm;
/
-- Expanding: ./TRIGGERS/r_hour_triggers.trg

create or replace trigger r_hour_before_insert_update
before             insert OR update 
on                r_hour
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    
    /* modified by M.  Bogner 08/31/07  */
    /*
    the purpose of this trigger is to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivatiuon flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;

end;
/
-- show errors trigger r_hour_before_insert_update;


CREATE OR REPLACE TRIGGER r_hour_after_insert_update
AFTER INSERT OR UPDATE ON R_HOUR FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_HOUR';
  l_interval VARCHAR2(16) := 'hour';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'hour'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */   

/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );

   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
        
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_hour_after_insert_update;

CREATE OR REPLACE TRIGGER r_hour_after_delete
AFTER DELETE ON R_HOUR FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_HOUR';
  l_interval VARCHAR2(16) := 'hour';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'hour'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
      
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
    
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
    
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_hour_after_delete;


-- Expanding: ./TRIGGERS/r_hourstat_sdi_perm.trg
create or replace TRIGGER  r_hourstat_sdi_perm
after             insert OR update OR delete
on                r_hourstat
for   each row
begin
	if not (is_role_granted ('SAVOIR_FAIRE')) then
	   check_sdi_auth (:new.site_datatype_id);
	end if;
end;
/
-- show errors trigger r_hourstat_sdi_perm;
/
-- Expanding: ./TRIGGERS/r_instant_triggers.trg

create or replace trigger r_instant_before_insert_update
before             insert OR update 
on                r_instant
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    /* modified by M.  Bogner 08/31/07  */
    /*
    to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivatiuon flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;


end;
/
-- show errors trigger r_instant_before_insert_update;


CREATE OR REPLACE TRIGGER r_instant_after_insert_update
AFTER INSERT OR UPDATE ON R_INSTANT FOR EACH ROW 
declare      
 
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_INSTANT';
  l_interval VARCHAR2(16) := 'instant';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'instant'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */
      
  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
   
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_instant_after_insert_update;

CREATE OR REPLACE TRIGGER r_instant_after_delete
AFTER DELETE ON R_INSTANT FOR EACH ROW 
declare      
 
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_INSTANT';
  l_interval VARCHAR2(16) := 'instant';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'instant'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
   
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
    
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
        
   END LOOP;
    
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
 
END;  /*  end of delete interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_instant_after_delete;


-- Expanding: ./TRIGGERS/r_month_triggers.trg

create or replace trigger r_month_before_insert_update
before             insert OR update 
on                r_month
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    
    /* modified by M.  Bogner 08/31/07  */
    /*
    the purpose of this trigger is to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivation flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;

end;
/
-- show errors trigger r_month_before_insert_update;

CREATE OR REPLACE TRIGGER r_month_after_insert_update
AFTER INSERT OR UPDATE ON R_MONTH FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_MONTH';
  l_interval VARCHAR2(16) := 'month';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'month'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
   
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );
       
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_month_after_insert_update;

CREATE OR REPLACE TRIGGER r_month_after_delete
AFTER DELETE ON R_MONTH FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_MONTH';
  l_interval VARCHAR2(16) := 'month';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'month'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */
 
  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
  
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
     
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
   
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/
-- show errors trigger r_month_after_delete;
-- Expanding: ./TRIGGERS/r_monthstat_sdi_perm.trg
create or replace TRIGGER  r_monthstat_sdi_perm
after             insert OR update OR delete
on                r_monthstat
for   each row
begin
	if not (is_role_granted ('SAVOIR_FAIRE')) then
	   check_sdi_auth (:new.site_datatype_id);
	end if;
end;
/
-- show errors trigger r_monthstat_sdi_perm;
/
-- Expanding: ./TRIGGERS/r_monthstatrange_sdi_perm.trg
create or replace TRIGGER  r_monthstatrange_sdi_perm
after             insert OR update OR delete
on                r_monthstatrange
for   each row
begin
	if not (is_role_granted ('SAVOIR_FAIRE')) then
	   check_sdi_auth (:new.site_datatype_id);
	end if;
end;
/
-- show errors trigger r_monthstatrange_sdi_perm;
/
-- Expanding: ./TRIGGERS/r_other_triggers.trg

create or replace trigger r_other_before_insert_update
before             insert OR update 
on                r_other
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    
    /* modified by M.  Bogner 08/31/07  */
    /*
    the purpose of this trigger is to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivatiuon flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;

end;
/
-- show errors trigger r_other_before_insert_update;

CREATE OR REPLACE TRIGGER r_other_after_insert_update
AFTER INSERT OR UPDATE ON R_OTHER FOR EACH ROW 
declare      
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_OTHER';
  l_interval VARCHAR2(16) := 'other';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'other'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */   
  
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_other_after_insert_update;

CREATE OR REPLACE TRIGGER r_other_after_delete
AFTER DELETE ON R_OTHER FOR EACH ROW 
declare      
 
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_OTHER';
  l_interval VARCHAR2(16) := 'other';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                   
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'other'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
    
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
  
END;  /*  end of delete interval table trigger  */                                                                            
/
-- show errors trigger r_other_after_delete;
-- Expanding: ./TRIGGERS/r_wy_triggers.trg

create or replace trigger r_wy_before_insert_update
before             insert OR update 
on                r_wy
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    
    /* modified by M.  Bogner 08/31/07  */
    /*
    the purpose of this trigger is to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivatiuon flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;

end;
/
-- show errors trigger r_wy_before_insert_update;

CREATE OR REPLACE TRIGGER r_wy_after_insert_update
AFTER INSERT OR UPDATE ON R_WY FOR EACH ROW 
declare      
 
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_WY';
  l_interval VARCHAR2(16) := 'wy';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                   
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'wy'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
           
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_wy_after_insert_update;

CREATE OR REPLACE TRIGGER r_wy_after_delete
AFTER DELETE ON R_WY FOR EACH ROW 
declare      

  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_WY';
  l_interval VARCHAR2(16) := 'wy';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                    
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'wy'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
     
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
    
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/
-- show errors trigger r_wy_after_delete;
-- Expanding: ./TRIGGERS/r_wystat_sdi_perm.trg
create or replace TRIGGER  r_wystat_sdi_perm
after             insert OR update OR delete
on                r_wystat
for   each row
begin
	if not (is_role_granted ('SAVOIR_FAIRE')) then
	   check_sdi_auth (:new.site_datatype_id);
	end if;
end;
/
-- show errors trigger r_wystat_sdi_perm;
/
-- Expanding: ./TRIGGERS/r_year_triggers.trg

create or replace trigger r_year_before_insert_update
before             insert OR update 
on                r_year
for   each row
declare
  v_manual_edit   varchar2(1);
begin
    
    /* modified by M.  Bogner 08/31/07  */
    /*
    the purpose of this trigger is to check to see if the
    insert or the update to this table was a result of a manual sql command or
    through the normal r_base triggers route. if it is a manual edit then the 
    M is appended to  the derivatiuon flag and the date_time_loaded is modified
    to sysdate
    */
    
    v_manual_edit := hdb_utilities.get_manual_edit();
    
    if (v_manual_edit = 'Y') then
      :new.derivation_flags := substr(:new.derivation_flags,1,19) || 'M';
      :new.date_time_loaded := sysdate;
    end if;

end;
/
-- show errors trigger r_year_before_insert_update;

CREATE OR REPLACE TRIGGER r_year_after_insert_update
AFTER INSERT OR UPDATE ON R_YEAR FOR EACH ROW 
declare      
 
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_YEAR';
  l_interval VARCHAR2(16) := 'year';
  l_delete_flag VARCHAR2(1) := 'N';
                                                                   
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'year'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      Data has been received into this interval table 
      and this data is defined as an input parameter of an
      active calculation  */
 
  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
         
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:new.site_datatype_id, :new.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :new.value,sysdate,:new.start_date_time,'N',0,:new.validation,:new.derivation_flags
    );
   
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :new.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'N', :new.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :new.site_datatype_id 
	  and table_name = l_table_name 
	  and :new.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:new.site_datatype_id,l_interval,:new.start_date_time,
		l_model_run_id,:new.value,:new.validation,:new.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of insert update interval table trigger  */                                                                            
/                                                                               
-- show errors trigger r_year_after_insert_update;

CREATE OR REPLACE TRIGGER r_year_after_delete
AFTER DELETE ON R_YEAR FOR EACH ROW 
declare      
 
  l_count	NUMBER;
  l_db_link VARCHAR2(128);
  l_model_run_id NUMBER := 0;
  l_table_name VARCHAR2(10) := 'R_YEAR';
  l_interval VARCHAR2(16) := 'year';
  l_delete_flag VARCHAR2(1) := 'Y';
                                                                   
  CURSOR is_rec_a_parameter(sdi NUMBER, sdt DATE) IS  
  select site_datatype_id, loading_application_id, interval, table_selector,
  model_id, computation_id,computation_name,algorithm_id,algorithm_name
  from cp_active_sdi_tsparm_view
  where site_datatype_id = sdi
  and table_selector = 'R_'
  and interval = 'year'
  and sdt between effective_start_date_time and effective_end_date_time;
                                                                                 
BEGIN                                                                           

  /*  this trigger written by M. Bogner  APRIL 2006
      the purpose of this trigger is to place rows into the cp_comp_tasklist table when
      a row in this interval table has been deleted 
      and this data is defined as an input parameter of an
      active calculation  */

  /* modified by M. Bogner Jan 2008 to add procedure call to do additional processing  */
  /* modified by M. Bogner May 2010 to add procedure call to do remote calc processing  */
    
/*  now go see if there are any active computation definitions for this record      */
/*  if there are records from this cursor then put all records from the cursor
    into the cp_comp_task_list table                                                */

  FOR p1 IN is_rec_a_parameter(:old.site_datatype_id, :old.start_date_time) LOOP
    
    insert into cp_comp_tasklist(
    record_num, loading_application_id,
    site_datatype_id,interval,table_selector,
    value,date_time_loaded,start_date_time,delete_flag,model_run_id,validation,data_flags
    )
    values (
    cp_tasklist_sequence.nextval,p1.loading_application_id,
    p1.site_datatype_id,p1.interval,p1.table_selector,
    :old.value,sysdate,:old.start_date_time,'Y',0,:old.validation,:old.derivation_flags
    );
    
   /* now run the procedure to do additional processing for computations  */
   hdb_utilities.COMPUTATIONS_PROCESSING
           (p1.loading_application_id, p1.site_datatype_id, p1.interval, :old.start_date_time, 
            p1.table_selector, p1.computation_id, p1.computation_name, p1.algorithm_id, 
            p1.algorithm_name, 0, 'Y', :old.derivation_flags);
    
   END LOOP;
   
  /* check for remote computation triggering if this is a remote computation */
  /* then call the procedure to trigger the remote computation               */
  select count(*), min(db_link) into l_count, l_db_link 
  from cp_active_remote_sdi_view
	where site_datatype_id = :old.site_datatype_id 
	  and table_name = l_table_name 
	  and :old.start_date_time between effective_start_date_time and effective_end_date_time;

  IF l_count > 0 THEN
    cp_remote_trigger.trigger_remote_cp(l_db_link,:old.site_datatype_id,l_interval,:old.start_date_time,
		l_model_run_id,:old.value,:old.validation,:old.derivation_flags,l_delete_flag);   
  END IF;
   
END;  /*  end of delete interval table trigger  */                                                                            
/
-- show errors trigger r_year_after_delete;
-- Expanding: ./TRIGGERS/r_yearstat_sdi_perm.trg
create or replace TRIGGER  r_yearstat_sdi_perm
after             insert OR update OR delete
on                r_yearstat
for   each row
begin
	if not (is_role_granted ('SAVOIR_FAIRE')) then
	   check_sdi_auth (:new.site_datatype_id);
	end if;
end;
/
-- show errors trigger r_yearstat_sdi_perm;
/
-- Expanding: ./TRIGGERS/sdi_chk_perm.trg
create or replace TRIGGER sdi_chk_perm
after             insert OR update OR delete
on                hdb_site_datatype
for   each row
declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;
begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','HDB_META_ROLE');
     else
	the_app_user := the_user;

        if not (is_role_granted ('SAVOIR_FAIRE')
                OR is_role_granted ('HDB_META_ROLE')) then
    	  is_valid_role := 0;
	else
	  is_valid_role := 1;
	end if;
     end if;

--     raise_application_error (-20001,'THE USER: '|| the_user||'APP_USER: '||the_app_user||'ROLE VALID '||is_valid_role);

     if not (is_valid_role > 0) then
	   check_sdi_auth_with_site (:new.site_datatype_id, :new.site_id);
     end if;
      
     /* populate the ref_db_generic_list table for the snapshot_manager  */
     /* added by M. Bogner April 2013  */
     snapshot_manager.snapshot_modified('HDB_SITE_DATATYPE');
       
end;     
/
-- show errors trigger sdi_chk_perm;
/
-- Expanding: ./TRIGGERS/ref_model_run_triggers.trg
-- install the triggers to
--	do archiving on update or delete
--	set user_name and date_time_loaded
--	process coordinated model_runs to remote databases
-- 12/06 Carol Marra
--

create or replace trigger ref_model_run_before
before insert or update or delete
on ref_model_run
for each row
when (user <> 'META_DATA_USER')
declare
  v_user	     	varchar2(30);
  v_date		date;
  v_where		varchar2(10);
  v_mri_is_coord        number;
  v_model_id            number;
  v_valid_coord_db      number;
  v_installation_type   varchar2(32);
  v_count               number;
  new_model_run_id      number;
  text                  varchar2(1000);
begin

  /* Set new values for date_time_loaded and user_name */
  v_user := user;
  v_date := sysdate;

  if (inserting or updating) then
    :new.date_time_loaded := v_date;
    :new.user_name := v_user;
  end if;

  v_where := 'other';

  /* Do not allow setting extra_keys_y_n to N when
     there are key-value pairs */
  if (updating AND upper(:new.extra_keys_y_n) = 'N') then
    select count(*)
    into v_count
    from ref_model_run_keyval
    where model_run_id = :new.model_run_id;

    if (v_count > 0) then
      deny_action ('You must delete all key-value pairs before setting extra_keys_y_n to N');
    end if;
  end if;

  select meta_data_installation_type
  into v_installation_type
  from ref_installation;

  /* See if this model_run_id is coordinated by checking its model; only 
     need to check master and snapshot installations */
  if (v_installation_type <> 'island') then
    if (inserting or updating) then
        v_model_id := :new.model_id;
    else
        v_model_id := :old.model_id;
    end if;

    model_is_coord (v_model_id, v_mri_is_coord);
  else
     v_mri_is_coord := 0;
  end if;

  /* Get next model_run_id; depends on if coordinated or not */
  if (inserting) then
    get_next_model_run_id (v_mri_is_coord, v_installation_type, new_model_run_id);
    :new.model_run_id := new_model_run_id;
  end if;

  if (v_mri_is_coord <> 0) then
      /* Ensure local DB is one of DBs listed for this coordinated model */
      select count(a.db_site_code) 
      into v_valid_coord_db
      from hdb_model_coord a, ref_db_list b
      where a.model_id = v_model_id
	and a.db_site_code = b.db_site_code
	and b.session_no = 1;

      if (v_valid_coord_db = 0) then
        text := 'Local database is not valid for coordinated model '||v_model_id;
	deny_action (text);
      end if;

      /* Process rows into remote database(s) */
      if (inserting) then
	v_where := 'insert';
        insert_coord_model_run_id (:new.model_run_id, :new.model_run_name, 
	  :new.model_id, v_date, v_user, :new.extra_keys_y_n, :new.run_date, 
          :new.start_date, :new.end_date,
	  :new.hydrologic_indicator, :new.modeltype, :new.time_step_descriptor,
	  :new.cmmnt);
      elsif (updating) then
	v_where := 'update';
        /* Pass in old and new model_run_id so it will be updated 
           on remote DB if someone manually changes a model_run_id
           locally. */
        update_coord_model_run_id (:old.model_run_id, :new.model_run_id,
          :new.model_run_name, :new.model_id, v_date, v_user, 
          :new.extra_keys_y_n, :new.run_date, :new.start_date, :new.end_date,
	  :new.hydrologic_indicator, :new.modeltype, :new.time_step_descriptor,
	  :new.cmmnt);
      else
        v_where := 'delete';
	delete_coord_model_run_id (:old.model_run_id, :old.model_id);
      end if;
  end if; /* is coordinated */

  EXCEPTION
    WHEN others THEN
      if (v_where <> 'other') then
        text := 'Problem on '||v_where||' of coord run. '||sqlerrm;
      else
        text := sqlerrm;
      end if;

      deny_action (text);
  
end;
/
-- show errors trigger ref_model_run_before
/

create or replace trigger ref_model_run_after_update
after update on ref_model_run
for each row
begin

-- archive the row that was changed
  insert into ref_model_run_archive
    (model_run_id,
     model_run_name,
     model_id,
     date_time_loaded,
     user_name,
     extra_keys_y_n,
     run_date,
     start_date,
     end_date,
     hydrologic_indicator,
     modeltype,
     time_step_descriptor,
     cmmnt,
     archive_reason,
     date_time_archived)
  values
    (:old.model_run_id,
     :old.model_run_name,
     :old.model_id,
     :old.date_time_loaded,
     :old.user_name,
     :old.extra_keys_y_n,
     :old.run_date,
     :old.start_date,
     :old.end_date,
     :old.hydrologic_indicator,
     :old.modeltype,
     :old.time_step_descriptor,
     :old.cmmnt,
     'UPDATE',
     sysdate);
end;
/
-- show errors trigger ref_model_run_after_update;
/

create or replace trigger ref_model_run_after_delete
after delete on ref_model_run
for each row
begin

-- archive the row that was changed
  insert into ref_model_run_archive
    (model_run_id,
     model_run_name,
     model_id,
     date_time_loaded,
     user_name,
     extra_keys_y_n,
     run_date,
     start_date,
     end_date,
     hydrologic_indicator,
     modeltype,
     time_step_descriptor,
     cmmnt,
     archive_reason,
     date_time_archived)
  values
    (:old.model_run_id,
     :old.model_run_name,
     :old.model_id,
     :old.date_time_loaded,
     :old.user_name,
     :old.extra_keys_y_n,
     :old.run_date,
     :old.start_date,
     :old.end_date,
     :old.hydrologic_indicator,
     :old.modeltype,
     :old.time_step_descriptor,
     :old.cmmnt,
     'DELETE',
     sysdate);
end;
/
-- show errors trigger ref_model_run_after_delete;
/
-- Expanding: ./TRIGGERS/ref_model_run_keyval_triggers.trg
-- install the triggers to
--	do archiving on update or delete
--	set user_name and date_time_loaded
--	process coordinated model_runs to remote databases
-- 12/06 Carol Marra
--

create or replace trigger ref_model_run_keyval_before
before insert or update or delete
on ref_model_run_keyval
for each row
when (user <> 'META_DATA_USER')
declare
  v_date                date;
  v_where		varchar2(10);
  v_mri_is_coord        number;
  v_model_id            number;
  v_valid_coord_db      number;
  v_installation_type   varchar2(32);
  text                  varchar2(1000);
begin

  v_date := sysdate;

  if (inserting or updating) then
    :new.date_time_loaded := v_date;
  end if;

  v_where := 'other';

  select meta_data_installation_type
  into v_installation_type
  from ref_installation;

  /* See if this model_run_id is coordinated by checking its model; only 
     need to check master and snapshot installations */
  if (v_installation_type <> 'island') then
    if (inserting or updating) then
        SELECT model_id
        INTO v_model_id
        FROM ref_model_run
        WHERE model_run_id = :new.model_run_id;
    else
        SELECT model_id
        INTO v_model_id
        FROM ref_model_run
        WHERE model_run_id = :old.model_run_id;
    end if;

    model_is_coord (v_model_id, v_mri_is_coord);
  else
     v_mri_is_coord := 0;
  end if;

  if (v_mri_is_coord <> 0) then
      /* Ensure local DB is one of DBs listed for this coordinated model */
      select count(a.db_site_code) 
      into v_valid_coord_db
      from hdb_model_coord a, ref_db_list b
      where a.model_id = v_model_id
	and a.db_site_code = b.db_site_code
	and b.session_no = 1;

      if (v_valid_coord_db = 0) then
        text := 'Local database is not valid for coordinated model '||v_model_id;
	deny_action (text);
      end if;

      /* Process rows into remote database(s) */
      if (inserting) then
	v_where := 'insert';
        insert_coord_model_run_keyval (:new.model_run_id, :new.key_name, 
	  :new.key_value, v_date);
      elsif (updating) then
	v_where := 'update';
        /* Pass in old and new model_run_id so it will be updated 
           on remote DB if someone manually changes a model_run_id
           locally. */
        update_coord_model_run_keyval (:old.model_run_id, :new.model_run_id,
          :old.key_name, :new.key_name, :new.key_value, v_date);
      else
        v_where := 'delete';
	delete_coord_model_run_keyval (:old.model_run_id);
      end if;
  end if; /* is coordinated */

  EXCEPTION
    WHEN others THEN
      if (v_where <> 'other') then
        text := 'Problem on '||v_where||' of coordinated run keyvals. '||sqlerrm;
      else
        text := sqlerrm;
      end if;

      deny_action (text);
  
end;
/
-- show errors trigger ref_model_run_keyval_before
/

create or replace trigger ref_model_run_key_after_update
after update on ref_model_run_keyval
for each row
begin

-- archive the row that was changed
  insert into ref_model_run_keyval_archive
    (model_run_id,
     key_name,
     key_value,
     date_time_loaded,
     archive_reason,
     date_time_archived,
     ARCHIVE_CMMNT)
  values
    (:old.model_run_id,
     :old.key_name,
     :old.key_value,
     :old.date_time_loaded,
     'UPDATE',
     sysdate,
     coalesce(
               sys_context('APEX$SESSION','app_user')
              ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
              ,sys_context('userenv','session_user')
              ) || ':' || sys_context('userenv','os_user') 
              || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
     );
end;
/
-- show errors trigger ref_model_run_key_after_update;
/

create or replace trigger ref_model_run_key_after_delete
after delete on ref_model_run_keyval
for each row
begin

-- archive the row that was changed
  insert into ref_model_run_keyval_archive
    (model_run_id,
     key_name,
     key_value,
     date_time_loaded,
     archive_reason,
     date_time_archived,
     ARCHIVE_CMMNT)
  values
    (:old.model_run_id,
     :old.key_name,
     :old.key_value,
     :old.date_time_loaded,
     'DELETE',
     sysdate,
     coalesce(
               sys_context('APEX$SESSION','app_user')
              ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
              ,sys_context('userenv','session_user')
              ) || ':' || sys_context('userenv','os_user') 
              || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
     );
end;
/
-- show errors trigger ref_model_run_key_after_delete;
/
-- Expanding: ./TRIGGERS/ref_db_list_triggers.trg
-- install the trigger to ensure that, if min or max 
-- coord_model_run_id is non-null, the other also
-- is, and vice-versa.

create or replace trigger ref_db_list_before_ins_upd
before insert or update
on ref_db_list
for each row
declare
  v_coord_count         number;
  v_date		date;
  v_where		varchar2(10);
  v_mri_is_coord        number;
  v_model_id            number;
  v_valid_coord_db      number;
  v_installation_type   varchar2(32);
  new_model_run_id      number;
  text                  varchar2(1000);
begin

  if ((:new.min_coord_model_run_id is null and 
       :new.max_coord_model_run_id is not null) OR 
      (:new.min_coord_model_run_id is not null and 
       :new.max_coord_model_run_id is null)) then
    deny_action ('Min and max_coord_model_run_id must both be either null or non-null for a given database.');
  end if;

  if (:new.min_coord_model_run_id is not null and
      (:new.min_coord_model_run_id >= :new.max_coord_model_run_id)) then
    deny_action ('Min_coord_model_run_id must be less than max.');
  end if;

  EXCEPTION
    WHEN others THEN
      if (v_where <> 'other') then
        text := 'Problem on '||v_where||' of coord run. '||sqlerrm;
      else
        text := sqlerrm;
      end if;

      deny_action (text);
  
end;
/
-- show errors trigger ref_db_list_before_ins_upd;
/

-- Expanding: ./TRIGGERS/ref_model_run_archive_triggers.trg
-- install the trigger to
--	update the archive_cmmnt on coordinated databases
-- 12/06 Carol Marra
--

create or replace trigger ref_model_run_archive_cmmnt
before update of archive_cmmnt
on ref_model_run_archive
for each row
when (user <> 'META_DATA_USER')
declare
  v_mri_is_coord        number;
  v_installation_type   varchar2(32);
  text                  varchar2(1000);
begin

  select meta_data_installation_type
  into v_installation_type
  from ref_installation;

  /* See if this model_run_id is coordinated by checking its model; only 
     need to check master and snapshot installations */
  if (v_installation_type <> 'island') then
    model_is_coord (:new.model_id, v_mri_is_coord);
  else
     v_mri_is_coord := 0;
  end if;

  if (v_mri_is_coord <> 0) then

    /* Update archive_cmmnt on remote database(s) */
    update_coord_mri_archive_cmmnt (:new.model_run_id, :new.model_id,
      :new.archive_cmmnt);

  end if; /* is coordinated */

  EXCEPTION
    WHEN others THEN
      text := sqlerrm;
      deny_action (text);
  
end;
/
-- show errors trigger ref_model_run_archive_cmmnt
/

-- Expanding: ./TRIGGERS/ref_model_run_keyval_archive_triggers.trg
-- install the trigger to
--	update the archive_cmmnt on coordinated databases
-- 12/06 Carol Marra
--

create or replace trigger ref_model_run_kv_arch_cmmnt
before update of archive_cmmnt
on ref_model_run_keyval_archive
for each row
when (user <> 'META_DATA_USER')
declare
  v_model_id            number;
  v_mri_is_coord        number;
  v_installation_type   varchar2(32);
  text                  varchar2(1000);
begin

  select meta_data_installation_type
  into v_installation_type
  from ref_installation;

  /* See if this model_run_id is coordinated by checking its model; only 
     need to check master and snapshot installations */
  if (v_installation_type <> 'island') then
    SELECT model_id
    INTO v_model_id
    FROM ref_model_run
    WHERE model_run_id = :new.model_run_id;
 
   model_is_coord (v_model_id, v_mri_is_coord);
  else
     v_mri_is_coord := 0;
  end if;

  if (v_mri_is_coord <> 0) then

    /* Update archive_cmmnt on remote database(s) */
    update_coord_mri_kv_arch_cmmnt (:new.model_run_id, :new.key_name, 
      :new.archive_cmmnt);

  end if; /* is coordinated */

  EXCEPTION
    WHEN others THEN
      text := sqlerrm;
      deny_action (text);
  
end;
/
-- show errors trigger ref_model_run_kv_arch_cmmnt
/

-- Expanding: ./TRIGGERS/tsdb_group_member_dt_triggers.trg

CREATE OR REPLACE TRIGGER TSDB_GMDT_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON TSDB_GROUP_MEMBER_DT
FOR EACH ROW 
declare
  l_group_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 15 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     Modify the parent tsdb_group record to signal a computation group record change/creation/deletion
     to the cp_depends_notify table
    */

 	IF inserting  OR updating THEN
	      l_group_id := :NEW.group_id;
    ELSIF deleting THEN 
	      l_group_id := :OLD.group_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TSDB_GROUP_MEMBER_DT will modify the parent TSDB_GROUP table in order
     to trigger a notification to the CP_DEPENDS_NOTIFY table */
    begin
     /* update the parent table if it exists */
     update TSDB_GROUP set db_office_code = db_office_code where group_id = l_group_id; 
     exception when others then null;
    end;
    
END;                                                                                         

/
-- Expanding: ./TRIGGERS/tsdb_group_member_group_triggers.trg

CREATE OR REPLACE TRIGGER TSDB_GMG_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON TSDB_GROUP_MEMBER_GROUP
FOR EACH ROW 
declare
  l_group_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 23 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     Modify the parent tsdb_group record to signal a computation group record change/creation/deletion
     to the cp_depends_notify table
    */

 	IF inserting  OR updating THEN
	      l_group_id := :NEW.parent_group_id;
    ELSIF deleting THEN 
	      l_group_id := :OLD.parent_group_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TSDB_GROUP_MEMBER_GROUP will modify the parent TSDB_GROUP table in order
     to trigger a notification to the CP_DEPENDS_NOTIFY table */
    begin
     /* update the parent table if it exists */
     update TSDB_GROUP set db_office_code = db_office_code where group_id = l_group_id; 
     exception when others then null;
    end;
    
END;                                                                                         

/
-- Expanding: ./TRIGGERS/tsdb_group_member_other_triggers.trg

CREATE OR REPLACE TRIGGER TSDB_GMO_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON TSDB_GROUP_MEMBER_OTHER
FOR EACH ROW 
declare
  l_group_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 15 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     Modify the parent tsdb_group record to signal a computation group record change/creation/deletion
     to the cp_depends_notify table
    */

 	IF inserting  OR updating THEN
	      l_group_id := :NEW.group_id;
    ELSIF deleting THEN 
	      l_group_id := :OLD.group_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TSDB_GROUP_MEMBER_OTHER will modify the parent TSDB_GROUP table in order
     to trigger a notification to the CP_DEPENDS_NOTIFY table */
    begin
     /* update the parent table if it exists */
     update TSDB_GROUP set db_office_code = db_office_code where group_id = l_group_id; 
     exception when others then null;
    end;
    
END;                                                                                         

/
-- Expanding: ./TRIGGERS/tsdb_group_member_site_triggers.trg

CREATE OR REPLACE TRIGGER TSDB_GMSITE_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON TSDB_GROUP_MEMBER_SITE
FOR EACH ROW 
declare
  l_group_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 15 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     Modify the parent tsdb_group record to signal a computation group record change/creation/deletion
     to the cp_depends_notify table
    */

 	IF inserting  OR updating THEN
	      l_group_id := :NEW.group_id;
    ELSIF deleting THEN 
	      l_group_id := :OLD.group_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TSDB_GROUP_MEMBER_SITE will modify the parent TSDB_GROUP table in order
     to trigger a notification to the CP_DEPENDS_NOTIFY table */
    begin
     /* update the parent table if it exists */
     update TSDB_GROUP set db_office_code = db_office_code where group_id = l_group_id; 
     exception when others then null;
    end;
    
END;                                                                                         

/
-- Expanding: ./TRIGGERS/tsdb_group_member_ts_triggers.trg

CREATE OR REPLACE TRIGGER TSDB_GMTS_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON TSDB_GROUP_MEMBER_TS
FOR EACH ROW 
declare
  l_group_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 15 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     Modify the parent tsdb_group record to signal a computation group record change/creation/deletion
     to the cp_depends_notify table
    */

 	IF inserting  OR updating THEN
	      l_group_id := :NEW.group_id;
    ELSIF deleting THEN 
	      l_group_id := :OLD.group_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TSDB_GROUP_MEMBER_TS will modify the parent TSDB_GROUP table in order
     to trigger a notification to the CP_DEPENDS_NOTIFY table */
    begin
     /* update the parent table if it exists */
     update TSDB_GROUP set db_office_code = db_office_code where group_id = l_group_id; 
     exception when others then null;
    end;
    
END;                                                                                         

/
-- Expanding: ./TRIGGERS/tsdb_group_triggers.trg

CREATE OR REPLACE TRIGGER TSDB_GROUP_CUD_TRIG 
after INSERT OR UPDATE OR DELETE 
ON TSDB_GROUP
FOR EACH ROW 
declare
  l_group_id   NUMBER;
  BEGIN 
    
    /* create by M. Bogner May 15 2012 for the CP upgrade Phase 3.0  */
    /*
    the purpose of this trigger is to:
     insert a record into cp_notify depends to signal a computation group record change/creation/deletion
    Modified July 23 2012 By M. Bogner to mod the sysdate to the DB time zone.
    */

 	IF inserting  OR updating THEN
	      l_group_id := :NEW.group_id;
    ELSIF deleting THEN 
	      l_group_id := :OLD.group_id;
    END IF;   
  
  /* for PHASE 3.0 a change in a TSDB_GROUP will trigger a notification to address CP_COMP_DEPENDS */
  insert into cp_depends_notify (record_num,event_type,key,date_time_loaded) values (-1,'G',l_group_id,
  hdb_utilities.mod_date_for_time_zone(sysdate,hdb_utilities.get_db_parameter('SERVER_TIME_ZONE')));

END;                                                                                         

/
-- Expanding: ./TRIGGERS/ref_ensemble_keyval_triggers.trg

create or replace trigger ref_ensemble_keyval_upd
after update on ref_ensemble_keyval for each row begin
insert into ref_ensemble_keyval_archive (
ENSEMBLE_ID,
KEY_NAME,
KEY_VALUE,
DATE_TIME_LOADED,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.ENSEMBLE_ID,
:old.KEY_NAME,
:old.KEY_VALUE,
:old.DATE_TIME_LOADED,
'UPDATE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_ensemble_keyval_upd;

create or replace trigger ref_ensemble_keyval_del
after delete on ref_ensemble_keyval for each row begin
insert into ref_ensemble_keyval_archive (
ENSEMBLE_ID,
KEY_NAME,
KEY_VALUE,
DATE_TIME_LOADED,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.ENSEMBLE_ID,
:old.KEY_NAME,
:old.KEY_VALUE,
:old.DATE_TIME_LOADED,
'DELETE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_ensemble_keyval_del;
-- Expanding: ./TRIGGERS/ref_ensemble_trace_triggers.trg


create or replace trigger ref_ensemble_trace_upd
after update on REF_ENSEMBLE_TRACE for each row begin 
insert into REF_ENSEMBLE_TRACE_ARCHIVE (
ENSEMBLE_ID,
TRACE_ID,
TRACE_NUMERIC,
TRACE_NAME,
MODEL_RUN_ID,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.ENSEMBLE_ID,
:old.TRACE_ID,
:old.TRACE_NUMERIC,
:old.TRACE_NAME,
:old.MODEL_RUN_ID,
'UPDATE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_ensemble_trace_upd;

create or replace trigger ref_ensemble_trace_del
after delete on REF_ENSEMBLE_TRACE for each row begin
insert into REF_ENSEMBLE_TRACE_ARCHIVE(
ENSEMBLE_ID,
TRACE_ID,
TRACE_NUMERIC,
TRACE_NAME,
MODEL_RUN_ID,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.ENSEMBLE_ID,
:old.TRACE_ID,
:old.TRACE_NUMERIC,
:old.TRACE_NAME,
:old.MODEL_RUN_ID,
'DELETE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
);
end;
/
-- show errors trigger ref_ensemble_trace_del;
-- Expanding: ./TRIGGERS/ref_ensemble_triggers.trg
CREATE OR REPLACE TRIGGER REF_ENSEMBLE_PK_TRIG 
BEFORE INSERT OR UPDATE
ON REF_ENSEMBLE
FOR EACH ROW 
BEGIN 
	IF inserting THEN 
	   IF populate_pk.pkval_pre_populated = FALSE THEN 
	      :new.ENSEMBLE_ID := populate_pk.get_pk_val( 'REF_ENSEMBLE', FALSE );  
	   END IF;

    ELSIF updating THEN 
     :new.ENSEMBLE_ID := :old.ENSEMBLE_ID; 
    END IF; 
END;         
                                                                                

/

create or replace trigger ref_ensemble_upd
after update on ref_ensemble for each row begin 
insert into ref_ensemble_archive (
ENSEMBLE_ID,
ENSEMBLE_NAME,
AGEN_ID,
TRACE_DOMAIN,
CMMNT,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.ENSEMBLE_ID,
:old.ENSEMBLE_NAME,
:old.AGEN_ID,
:old.TRACE_DOMAIN,
:old.CMMNT,
'UPDATE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
 );
end;
/
-- show errors trigger ref_ensemble_upd;

create or replace trigger ref_ensemble_del
after delete on ref_ensemble for each row begin 
insert into ref_ensemble_archive (
ENSEMBLE_ID,
ENSEMBLE_NAME,
AGEN_ID,
TRACE_DOMAIN,
CMMNT,
ARCHIVE_REASON, DATE_TIME_ARCHIVED, ARCHIVE_CMMNT) values (
:old.ENSEMBLE_ID,
:old.ENSEMBLE_NAME,
:old.AGEN_ID,
:old.TRACE_DOMAIN,
:old.CMMNT,
'DELETE', sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
 ); 
end;
/
-- show errors trigger ref_ensemble_del;
-- Expanding: ./TRIGGERS/HDB_AGEN_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_AGEN_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_AGEN
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.AGEN_ID := populate_pk.get_pk_val( 'HDB_AGEN', FALSE );  END IF; ELSIF updating THEN :new.AGEN_ID := :old.AGEN_ID; END IF; END;
/
-- show errors trigger HDB_AGEN_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_ATTR_PK_TRIG.trg
CREATE OR REPLACE TRIGGER HDB_ATTR_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_ATTR
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.ATTR_ID := populate_pk.get_pk_val( 'HDB_ATTR', FALSE );  END IF; ELSIF updating THEN :new.ATTR_ID := :old.ATTR_ID; END IF; END;
/
-- show errors trigger HDB_ATTR_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_COLLECTION_SYSTEM_PK_TRIG.trg
CREATE OR REPLACE TRIGGER HDB_COLLECTION_SYSTEM_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_COLLECTION_SYSTEM
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.COLLECTION_SYSTEM_ID := populate_pk.get_pk_val( 'HDB_COLLECTION_SYSTEM', FALSE );  END IF; ELSIF updating THEN :new.COLLECTION_SYSTEM_ID := :old.COLLECTION_SYSTEM_ID; END IF; END;
/
-- show errors trigger HDB_COLLECTION_SYSTEM_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_DAMTYPE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_DAMTYPE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_DAMTYPE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.DAMTYPE_ID := populate_pk.get_pk_val( 'HDB_DAMTYPE', FALSE );  END IF; ELSIF updating THEN :new.DAMTYPE_ID := :old.DAMTYPE_ID; END IF; END;
/
-- show errors trigger HDB_DAMTYPE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_DATA_SOURCE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_DATA_SOURCE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_DATA_SOURCE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.SOURCE_ID := populate_pk.get_pk_val( 'HDB_DATA_SOURCE', FALSE );  END IF; ELSIF updating THEN :new.SOURCE_ID := :old.SOURCE_ID; END IF; END;
/
-- show errors trigger HDB_DATA_SOURCE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_EXT_DATA_CODE_SYS_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_EXT_DATA_CODE_SYS_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_EXT_DATA_CODE_SYS
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.EXT_DATA_CODE_SYS_ID := populate_pk.get_pk_val( 'HDB_EXT_DATA_CODE_SYS', FALSE );  END IF; ELSIF updating THEN :new.EXT_DATA_CODE_SYS_ID := :old.EXT_DATA_CODE_SYS_ID; END IF; END;
/
-- show errors trigger HDB_EXT_DATA_CODE_SYS_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_EXT_DATA_SOURCE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_EXT_DATA_SOURCE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_EXT_DATA_SOURCE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.EXT_DATA_SOURCE_ID := populate_pk.get_pk_val( 'HDB_EXT_DATA_SOURCE', FALSE );  END IF; ELSIF updating THEN :new.EXT_DATA_SOURCE_ID := :old.EXT_DATA_SOURCE_ID; END IF; END;
/
-- show errors trigger HDB_EXT_DATA_SOURCE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_EXT_SITE_CODE_SYS_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_EXT_SITE_CODE_SYS_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_EXT_SITE_CODE_SYS
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.EXT_SITE_CODE_SYS_ID := populate_pk.get_pk_val( 'HDB_EXT_SITE_CODE_SYS', FALSE );  END IF; ELSIF updating THEN :new.EXT_SITE_CODE_SYS_ID := :old.EXT_SITE_CODE_SYS_ID; END IF; END;
/
-- show errors trigger HDB_EXT_SITE_CODE_SYS_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_FEATURE_CLASS_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_FEATURE_CLASS_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_FEATURE_CLASS
  REFERENCING FOR EACH ROW
  begin
IF inserting THEN
  IF populate_pk.pkval_pre_populated = FALSE THEN
     :new.FEATURE_CLASS_ID := populate_pk.get_pk_val( 'HDB_FEATURE_CLASS', FALSE );
  END IF;
ELSIF updating THEN
  :new.FEATURE_CLASS_ID := :old.FEATURE_CLASS_ID;
END IF;
end;
/

-- show errors trigger HDB_FEATURE_CLASS_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_FEATURE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_FEATURE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_FEATURE
  REFERENCING FOR EACH ROW
  begin
IF inserting THEN
  IF populate_pk.pkval_pre_populated = FALSE THEN
     :new.FEATURE_ID := populate_pk.get_pk_val( 'HDB_FEATURE', FALSE );
  END IF;
ELSIF updating THEN
  :new.FEATURE_ID := :old.FEATURE_ID;
END IF;
end;
/

-- show errors trigger HDB_FEATURE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_GAGETYPE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_GAGETYPE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_GAGETYPE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.GAGETYPE_ID := populate_pk.get_pk_val( 'HDB_GAGETYPE', FALSE );  END IF; ELSIF updating THEN :new.GAGETYPE_ID := :old.GAGETYPE_ID; END IF; END;
/


-- show errors trigger HDB_GAGETYPE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_LOADING_APPLICATIO_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_LOADING_APPLICATIO_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_LOADING_APPLICATION
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.LOADING_APPLICATION_ID := populate_pk.get_pk_val( 'HDB_LOADING_APPLICATION', FALSE );  END IF; ELSIF updating THEN :new.LOADING_APPLICATION_ID := :old.LOADING_APPLICATION_ID; END IF; END;
/

-- show errors trigger HDB_LOADING_APPLICATIO_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_METHOD_CLASS_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_METHOD_CLASS_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_METHOD_CLASS
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.METHOD_CLASS_ID := populate_pk.get_pk_val( 'HDB_METHOD_CLASS', FALSE );  END IF; ELSIF updating THEN :new.METHOD_CLASS_ID := :old.METHOD_CLASS_ID; END IF; END;
/

-- show errors trigger HDB_METHOD_CLASS_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_METHOD_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_METHOD_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_METHOD
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.METHOD_ID := populate_pk.get_pk_val( 'HDB_METHOD', FALSE );  END IF; ELSIF updating THEN :new.METHOD_ID := :old.METHOD_ID; END IF; END;
/

-- show errors trigger HDB_METHOD_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_MODEL_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_MODEL_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_MODEL
  REFERENCING FOR EACH ROW
  BEGIN
IF inserting THEN
  IF populate_pk.pkval_pre_populated = FALSE THEN
    :new.MODEL_ID := populate_pk.get_pk_val( 'HDB_MODEL', FALSE );
  END IF;
ELSIF updating THEN
  :new.MODEL_ID := :old.MODEL_ID;
END IF;
END;
/

-- show errors trigger HDB_MODEL_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_OBJECTTYPE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_OBJECTTYPE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_OBJECTTYPE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.OBJECTTYPE_ID := populate_pk.get_pk_val( 'HDB_OBJECTTYPE', FALSE );  END IF; ELSIF updating THEN :new.OBJECTTYPE_ID := :old.OBJECTTYPE_ID; END IF; END;
/

-- show errors trigger HDB_OBJECTTYPE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_PROPERTY_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_PROPERTY_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_PROPERTY
  REFERENCING FOR EACH ROW
  begin
IF inserting THEN
  IF populate_pk.pkval_pre_populated = FALSE THEN
     :new.PROPERTY_ID := populate_pk.get_pk_val( 'HDB_PROPERTY', FALSE );
  END IF;
ELSIF updating THEN
  :new.PROPERTY_ID := :old.PROPERTY_ID;
END IF;
end;
/

-- show errors trigger HDB_PROPERTY_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_RIVER_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_RIVER_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_RIVER
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.RIVER_ID := populate_pk.get_pk_val( 'HDB_RIVER', FALSE );  END IF; ELSIF updating THEN :new.RIVER_ID := :old.RIVER_ID; END IF; END;
/

-- show errors trigger HDB_RIVER_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_SITE_DATATYPE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_SITE_DATATYPE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_SITE_DATATYPE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.SITE_DATATYPE_ID := populate_pk.get_pk_val( 'HDB_SITE_DATATYPE', FALSE );  END IF; ELSIF updating THEN :new.SITE_DATATYPE_ID := :old.SITE_DATATYPE_ID; END IF; END;
/

-- show errors trigger HDB_SITE_DATATYPE_PK_TRIG;
/

create or replace trigger hdb_site_datatype_arch_update                                                                    
after update on hdb_site_datatype 
for each row 
begin 
insert into hdb_site_datatype_archive (  
SITE_ID,
DATATYPE_ID,
SITE_DATATYPE_ID,     
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) 
values (                                           
:old.SITE_ID,                                                                                              
:old.DATATYPE_ID,                                                                                                 
:old.SITE_DATATYPE_ID,                                                                                                                                                                                                
'UPDATE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_site_datatype_arch_update;
/                                                                         

                                                                                                                        
create or replace trigger hdb_site_datatype_arch_delete                                                                    
after delete on hdb_site_datatype 
for each row 
begin 
insert into hdb_site_datatype_archive (                     
SITE_ID,
DATATYPE_ID,
SITE_DATATYPE_ID, 
ARCHIVE_REASON, 
DATE_TIME_ARCHIVED, 
ARCHIVE_CMMNT) values (                                           
:old.SITE_ID,                                                                                              
:old.DATATYPE_ID,                                                                                                 
:old.SITE_DATATYPE_ID,
'DELETE', 
sysdate, 
coalesce(
          sys_context('APEX$SESSION','app_user')
         ,regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
         ,sys_context('userenv','session_user')
         ) || ':' || sys_context('userenv','os_user') 
         || ':' || sys_context('userenv','HOST') 
         || ':' || sys_context('userenv','CLIENT_PROGRAM_NAME')
); 
end;                                                                    
/                                                                                                                       
-- show errors trigger hdb_site_datatype_arch_delete;  
/
-- Expanding: ./TRIGGERS/HDB_STATE_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_STATE_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_STATE
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.STATE_ID := populate_pk.get_pk_val( 'HDB_STATE', FALSE );  END IF; ELSIF updating THEN :new.STATE_ID := :old.STATE_ID; END IF; END;
/

-- show errors trigger HDB_STATE_PK_TRIG;
-- Expanding: ./TRIGGERS/HDB_USBR_OFF_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER HDB_USBR_OFF_PK_TRIG
  BEFORE INSERT OR UPDATE ON HDB_USBR_OFF
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.OFF_ID := populate_pk.get_pk_val( 'HDB_USBR_OFF', FALSE );  END IF; ELSIF updating THEN :new.OFF_ID := :old.OFF_ID; END IF; END;
/

-- show errors trigger HDB_USBR_OFF_PK_TRIG;
-- Expanding: ./TRIGGERS/REF_EXT_SITE_DATA_MAP_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER REF_EXT_SITE_DATA_MAP_PK_TRIG
  BEFORE INSERT OR UPDATE ON REF_EXT_SITE_DATA_MAP
  REFERENCING FOR EACH ROW
  BEGIN IF inserting THEN IF populate_pk.pkval_pre_populated = FALSE THEN :new.MAPPING_ID := populate_pk.get_pk_val( 'REF_EXT_SITE_DATA_MAP', FALSE );  END IF; ELSIF updating THEN :new.MAPPING_ID := :old.MAPPING_ID; END IF; END;
/

-- show errors trigger REF_EXT_SITE_DATA_MAP_PK_TRIG;
-- Expanding: ./TRIGGERS/REF_RATING_DT_LOAD.trg
  CREATE OR REPLACE TRIGGER REF_RATING_DT_LOAD
  BEFORE INSERT OR UPDATE ON REF_RATING
  REFERENCING FOR EACH ROW
  begin
:new.date_time_loaded := sysdate; end;
/

-- show errors trigger REF_RATING_DT_LOAD;
-- Expanding: ./TRIGGERS/REF_DB_LIST_PK_TRIG.trg
  CREATE OR REPLACE TRIGGER REF_DB_LIST_PK_TRIG
  BEFORE INSERT OR UPDATE ON REF_DB_LIST
  REFERENCING FOR EACH ROW
  BEGIN
IF inserting THEN
  IF populate_pk.pkval_pre_populated = FALSE THEN
    :new.SESSION_NO := populate_pk.get_pk_val( 'REF_DB_LIST', FALSE );
  END IF;
ELSIF updating THEN
  :new.SESSION_NO := :old.SESSION_NO;
END IF;
END;
/

-- show errors trigger REF_DB_LIST_PK_TRIG;
-- @ ./TRIGGERS/REF_AGG_DISAGG_PK_TRIG.trg removed for CP Project 10/2022
-- Expanding: ./TRIGGERS/REF_SPATIAL_RELATION_SITE_PERM.trg
create or replace TRIGGER ref_spatial_relation_site_perm
after             insert or update or delete
on                ref_spatial_relation
for   each row

declare
  the_user varchar2(30);
  the_app_user varchar2(30);
  is_valid_role NUMBER;

begin
     the_user := USER;
     if (the_user = 'APEX_PUBLIC_USER') then
       the_app_user := nvl(v('APP_USER'),USER);

       select count(*)
       into is_valid_role
       from dba_role_privs
       where grantee = the_app_user
	 and default_role = 'YES'
	 and granted_role in ('SAVOIR_FAIRE','REF_META_ROLE');
     else
	the_app_user := the_user;

   	if not (is_role_granted ('SAVOIR_FAIRE')
              OR is_role_granted ('REF_META_ROLE')) then
    	     is_valid_role := 0;
	  else
	     is_valid_role := 1;
	  end if;
     end if;

     if not (is_valid_role > 0) then
	   check_site_id_auth (:new.a_site_id, the_user, the_app_user);
	   check_site_id_auth (:new.b_site_id, the_user, the_app_user);
     end if;
end;
/
-- show errors trigger REF_SPATIAL_RELATION_SITE_PERM;
/

-- spool off
-- exit;
-- Expanding: ./TRIGGERS/hdb_unit_pk_trig.trg
create or replace trigger hdb_unit_pk_trig 
before insert or update 
on hdb_unit
for each row 
begin
IF inserting THEN 
  IF populate_pk.pkval_pre_populated = FALSE THEN 
     :new.UNIT_ID := populate_pk.get_pk_val( 'HDB_UNIT', FALSE );  
  END IF; 
ELSIF updating THEN 
  :new.UNIT_ID := :old.UNIT_ID; 
END IF; 
end;
/
-- show errors trigger hdb_unit_pk_trig;
/
-- Expanding: ./TRIGGERS/hdb_dimension_pk_trig.trg
create or replace trigger hdb_dimension_pk_trig 
before insert or update 
on hdb_dimension
for each row 
begin
IF inserting THEN 
  IF populate_pk.pkval_pre_populated = FALSE THEN 
     :new.DIMENSION_ID := populate_pk.get_pk_val( 'HDB_DIMENSION', FALSE );  
  END IF; 
ELSIF updating THEN 
  :new.DIMENSION_ID := :old.DIMENSION_ID; 
END IF; 
end;
/
-- show errors trigger hdb_dimension_pk_trig;
/
-- Expanding: ./TRIGGERS/unit_chk_val_spec.trg
create or replace trigger unit_chk_val_spec
after             insert or update of unit_id
on                hdb_unit
for   each row
begin
     check_valid_unit_spec
 (:new.is_factor, :new.mult_factor, :new.from_stored_expression, :new.to_stored_expression, :new.month_year, :new.over_month_year);
end;
/
-- show errors trigger unit_chk_val_spec;
/
-- WARNING: Could not find file /mnt/c/Users/ozdem/Desktop/HDB-Antigravity/oracle_script/SCHEMA/BASE_SCRIPTS/view.ddl
-- WARNING: Could not find file /mnt/c/Users/ozdem/Desktop/HDB-Antigravity/oracle_script/SCHEMA/BASE_SCRIPTS/trigger.ddl
