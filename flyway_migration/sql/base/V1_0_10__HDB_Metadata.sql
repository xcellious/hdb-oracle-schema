ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};
CREATE OR REPLACE VIEW V_DBA_ROLES as select role from dba_roles
where password_required = 'YES';
BEGIN EXECUTE IMMEDIATE '
grant select on v_dba_roles to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM v_dba_roles for v_dba_roles;
/* ReCREATE OR REPLACE VIEWs invalidated by dropping and recreating tables */
CREATE OR REPLACE VIEW HDB_DATATYPE_UNIT AS
select 'D' unit_ind, datatype_id dest_id, datatype_name dest_name,
  dimension_name dimension_name               
from hdb_datatype, hdb_dimension, hdb_unit
where hdb_datatype.unit_id = hdb_unit.unit_id
  and hdb_unit.dimension_id = hdb_dimension.dimension_id
union   
select 'U' unit_ind, unit_id dest_id, unit_name dest_name, null 
from hdb_unit                                                                
/
BEGIN EXECUTE IMMEDIATE '
grant select on hdb_datatype_unit to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM hdb_datatype_unit for hdb_datatype_unit;
CREATE OR REPLACE VIEW V_HDB_SITE_DATATYPE_NAME AS
SELECT site_datatype_id, site_name||'---'||datatype_name s_d_name               
FROM hdb_site_datatype, hdb_site, hdb_datatype                                  
WHERE                                                                           
     hdb_site_datatype.site_id = hdb_site.site_id                               
AND  hdb_site_datatype.datatype_id = hdb_datatype.datatype_id                   
/
BEGIN EXECUTE IMMEDIATE '
grant select on v_hdb_site_datatype_name to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE OR REPLACE PUBLIC SYNONYM v_hdb_site_datatype_name for v_hdb_site_datatype_name; 


-- PROMPT Creating REF_CODES Table CG_REF_CODES and Indexes
CREATE TABLE CG_REF_CODES
  (RV_DOMAIN VARCHAR2(100) NOT NULL
  ,RV_LOW_VALUE VARCHAR2(240) NOT NULL
  ,RV_HIGH_VALUE VARCHAR2(240)
  ,RV_ABBREVIATION VARCHAR2(240)
  ,RV_MEANING VARCHAR2(240)
  )
tablespace HDB_data
/
CREATE INDEX X_CG_REF_CODES_1 ON CG_REF_CODES
  (RV_DOMAIN
  ,RV_LOW_VALUE) tablespace hdb_idx
/
-- PROMPT Allowable Value Script
-- PROMPT
-- PROMPT Finished.
-- Final recompile to resolve any cross-schema dependencies
BEGIN
  DBMS_UTILITY.COMPILE_SCHEMA(schema => '${hdb_user}');
  DBMS_UTILITY.COMPILE_SCHEMA(schema => 'DECODES');
END;
/
