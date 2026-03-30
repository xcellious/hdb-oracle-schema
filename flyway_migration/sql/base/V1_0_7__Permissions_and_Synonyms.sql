ALTER SESSION SET CURRENT_SCHEMA = ${hdb_user};
-- set echo on
-- set feedback on
-- spool hdb_syns.out

CREATE OR REPLACE PUBLIC SYNONYM hdb_agen                    for ${hdb_user}.hdb_agen;
CREATE OR REPLACE PUBLIC SYNONYM hdb_attr                  for ${hdb_user}.hdb_attr;
CREATE OR REPLACE PUBLIC SYNONYM hdb_attr_feature for ${hdb_user}.hdb_attr_feature;
CREATE OR REPLACE PUBLIC SYNONYM hdb_collection_system      for ${hdb_user}.hdb_collection_system;
/* CREATE OR REPLACE PUBLIC SYNONYM hdb_computed_datatype      for ${hdb_user}.hdb_computed_datatype; */
/* CREATE OR REPLACE PUBLIC SYNONYM hdb_computed_datatype_component      	      for ${hdb_user}.hdb_computed_datatype_component;
*/
CREATE OR REPLACE PUBLIC SYNONYM hdb_damtype                  for ${hdb_user}.hdb_damtype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_data_source                   for ${hdb_user}.hdb_data_source;
CREATE OR REPLACE PUBLIC SYNONYM hdb_datatype      for ${hdb_user}.hdb_datatype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_datatype_feature for ${hdb_user}.hdb_datatype_feature;
CREATE OR REPLACE PUBLIC SYNONYM hdb_date_time_unit for ${hdb_user}.hdb_date_time_unit;
-- CREATE OR REPLACE PUBLIC SYNONYM hdb_derivation_flag    for ${hdb_user}.hdb_derivation_flag;
CREATE OR REPLACE PUBLIC SYNONYM hdb_dimension     for ${hdb_user}.hdb_dimension;
CREATE OR REPLACE PUBLIC SYNONYM hdb_divtype                     for ${hdb_user}.hdb_divtype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_dmi_unit_map                    for ${hdb_user}.hdb_dmi_unit_map;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_site_code_sys for ${hdb_user}.hdb_ext_site_code_sys;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_site_code for ${hdb_user}.hdb_ext_site_code;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_site_code_archive for ${hdb_user}.hdb_ext_site_code_archive;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_data_code_sys for ${hdb_user}.hdb_ext_data_code_sys;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_data_code for ${hdb_user}.hdb_ext_data_code;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_data_code_archive for ${hdb_user}.hdb_ext_data_code_archive;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_data_source for ${hdb_user}.hdb_ext_data_source;
CREATE OR REPLACE PUBLIC SYNONYM hdb_ext_data_source_archive for ${hdb_user}.hdb_ext_data_source_archive;
CREATE OR REPLACE PUBLIC SYNONYM hdb_feature for ${hdb_user}.hdb_feature;
CREATE OR REPLACE PUBLIC SYNONYM hdb_feature_class for ${hdb_user}.hdb_feature_class;
CREATE OR REPLACE PUBLIC SYNONYM hdb_feature_property for ${hdb_user}.hdb_feature_property;
CREATE OR REPLACE PUBLIC SYNONYM hdb_gagetype                    for ${hdb_user}.hdb_gagetype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_interval      for ${hdb_user}.hdb_interval;
CREATE OR REPLACE PUBLIC SYNONYM hdb_loading_application      for ${hdb_user}.hdb_loading_application;
CREATE OR REPLACE PUBLIC SYNONYM hdb_method        for ${hdb_user}.hdb_method;
CREATE OR REPLACE PUBLIC SYNONYM hdb_method_class        for ${hdb_user}.hdb_method_class;
CREATE OR REPLACE PUBLIC SYNONYM hdb_method_class_type        for ${hdb_user}.hdb_method_class_type;
CREATE OR REPLACE PUBLIC SYNONYM hdb_model                  for ${hdb_user}.hdb_model;
CREATE OR REPLACE PUBLIC SYNONYM hdb_model_coord            for ${hdb_user}.hdb_model_coord;
CREATE OR REPLACE PUBLIC SYNONYM hdb_modeltype                       for ${hdb_user}.hdb_modeltype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_objecttype    for ${hdb_user}.hdb_objecttype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_operator        for ${hdb_user}.hdb_operator;
CREATE OR REPLACE PUBLIC SYNONYM hdb_overwrite_flag        for ${hdb_user}.hdb_overwrite_flag;
CREATE OR REPLACE PUBLIC SYNONYM hdb_physical_quantity for ${hdb_user}.hdb_physical_quantity;
CREATE OR REPLACE PUBLIC SYNONYM hdb_property for ${hdb_user}.hdb_property;
CREATE OR REPLACE PUBLIC SYNONYM hdb_rating_algorithm for ${hdb_user}.hdb_rating_algorithm;
CREATE OR REPLACE PUBLIC SYNONYM hdb_rating_type for ${hdb_user}.hdb_rating_type;
CREATE OR REPLACE PUBLIC SYNONYM hdb_river                       for ${hdb_user}.hdb_river;
CREATE OR REPLACE PUBLIC SYNONYM hdb_river_reach                   for ${hdb_user}.hdb_river_reach;
CREATE OR REPLACE PUBLIC SYNONYM hdb_site          for ${hdb_user}.hdb_site;
CREATE OR REPLACE PUBLIC SYNONYM hdb_site_datatype for ${hdb_user}.hdb_site_datatype;
CREATE OR REPLACE PUBLIC SYNONYM hdb_state         for ${hdb_user}.hdb_state;
CREATE OR REPLACE PUBLIC SYNONYM hdb_usbr_off      for ${hdb_user}.hdb_usbr_off;
CREATE OR REPLACE PUBLIC SYNONYM hdb_validation                    for ${hdb_user}.hdb_validation;
CREATE OR REPLACE PUBLIC SYNONYM hdb_unit                  for ${hdb_user}.hdb_unit;
CREATE OR REPLACE PUBLIC SYNONYM hm_temp_data                        for ${hdb_user}.hm_temp_data;
CREATE OR REPLACE PUBLIC SYNONYM m_day          for ${hdb_user}.m_day;
CREATE OR REPLACE PUBLIC SYNONYM m_hour         for ${hdb_user}.m_hour;
CREATE OR REPLACE PUBLIC SYNONYM m_month        for ${hdb_user}.m_month;
CREATE OR REPLACE PUBLIC SYNONYM m_monthrange                        for ${hdb_user}.m_monthrange;
CREATE OR REPLACE PUBLIC SYNONYM m_monthstat                            for ${hdb_user}.m_monthstat;
CREATE OR REPLACE PUBLIC SYNONYM m_wy           for ${hdb_user}.m_wy;
CREATE OR REPLACE PUBLIC SYNONYM m_year         for ${hdb_user}.m_year;
CREATE OR REPLACE PUBLIC SYNONYM ratings for ${hdb_user}.ratings;
-- CREATE OR REPLACE PUBLIC SYNONYM ref_agg_disagg                      for ${hdb_user}.ref_agg_disagg; deprecated and removed by IsmailO 10/2022
CREATE OR REPLACE PUBLIC SYNONYM ref_app_data_source                    for ${hdb_user}.ref_app_data_source;
CREATE OR REPLACE PUBLIC SYNONYM ref_auth_site                   for ${hdb_user}.ref_auth_site;
CREATE OR REPLACE PUBLIC SYNONYM ref_auth_site_datatype                  for ${hdb_user}.ref_auth_site_datatype;
create or replace public synonym REF_DB_GENERIC_LIST for ${hdb_user}.REF_DB_GENERIC_LIST;
create or replace public synonym REF_CZAR_DB_GENERIC_LIST for ${hdb_user}.REF_CZAR_DB_GENERIC_LIST;
CREATE OR REPLACE PUBLIC SYNONYM ref_db_list                  for ${hdb_user}.ref_db_list;
-- CREATE OR REPLACE PUBLIC SYNONYM ref_derivation_source        for ${hdb_user}.ref_derivation_source;
-- CREATE OR REPLACE PUBLIC SYNONYM ref_derivation_destination        for ${hdb_user}.ref_derivation_destination;
CREATE OR REPLACE PUBLIC SYNONYM ref_div                     for ${hdb_user}.ref_div;
create or replace public synonym REF_ENSEMBLE for ${hdb_user}.REF_ENSEMBLE;
create or replace public synonym REF_ENSEMBLE_KEYVAL for ${hdb_user}.REF_ENSEMBLE_KEYVAL;
create or replace public synonym REF_ENSEMBLE_TRACE for ${hdb_user}.REF_ENSEMBLE_TRACE;
create or replace public synonym REF_ENSEMBLE_ARCHIVE for ${hdb_user}.REF_ENSEMBLE_ARCHIVE;
create or replace public synonym REF_ENSEMBLE_KEYVAL_ARCHIVE for ${hdb_user}.REF_ENSEMBLE_KEYVAL_ARCHIVE;
create or replace public synonym REF_ENSEMBLE_TRACE_ARCHIVE for ${hdb_user}.REF_ENSEMBLE_TRACE_ARCHIVE;
-- CREATE OR REPLACE PUBLIC SYNONYM ref_dmi_data_map                  for ${hdb_user}.ref_dmi_data_map; deprecated and removed by IsmailO 10/2022
CREATE OR REPLACE PUBLIC SYNONYM ref_ext_site_data_map  for ${hdb_user}.ref_ext_site_data_map;
CREATE OR REPLACE PUBLIC SYNONYM ref_ext_site_data_map_archive  for ${hdb_user}.ref_ext_site_data_map_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_ext_site_data_map_keyval  for ${hdb_user}.ref_ext_site_data_map_keyval;
CREATE OR REPLACE PUBLIC SYNONYM ref_ext_site_data_map_key_arch  for ${hdb_user}.ref_ext_site_data_map_key_arch;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_filetype                  for ${hdb_user}.ref_hm_filetype;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_pcode                      for ${hdb_user}.ref_hm_pcode;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_pcode_objecttype                  for ${hdb_user}.ref_hm_pcode_objecttype;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_site                              for ${hdb_user}.ref_hm_site;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_site_datatype                  for ${hdb_user}.ref_hm_site_datatype;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_site_hdbid                   for ${hdb_user}.ref_hm_site_hdbid;
CREATE OR REPLACE PUBLIC SYNONYM ref_hm_site_pcode                   for ${hdb_user}.ref_hm_site_pcode;
CREATE OR REPLACE PUBLIC SYNONYM ref_interval_redefinition      for ${hdb_user}.ref_interval_redefinition;
CREATE OR REPLACE PUBLIC SYNONYM ref_loading_application_prop     for ${hdb_user}.ref_loading_application_prop;
CREATE OR REPLACE PUBLIC SYNONYM ref_model      for ${hdb_user}.ref_model;
CREATE OR REPLACE PUBLIC SYNONYM ref_model_run                       for ${hdb_user}.ref_model_run;
CREATE OR REPLACE PUBLIC SYNONYM ref_model_run_keyval for ${hdb_user}.ref_model_run_keyval;
CREATE OR REPLACE PUBLIC SYNONYM ref_model_run_archive for ${hdb_user}.ref_model_run_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_model_run_keyval_archive for ${hdb_user}.ref_model_run_keyval_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_rating for ${hdb_user}.ref_rating;
CREATE OR REPLACE PUBLIC SYNONYM ref_rating_archive for ${hdb_user}.ref_rating_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_res        for ${hdb_user}.ref_res;
CREATE OR REPLACE PUBLIC SYNONYM ref_res_flowlu                  for ${hdb_user}.ref_res_flowlu;
CREATE OR REPLACE PUBLIC SYNONYM ref_res_wselu                    for ${hdb_user}.ref_res_wselu;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_attr                  for ${hdb_user}.ref_site_attr;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_attr_archive       for ${hdb_user}.ref_site_attr_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_coef                  for ${hdb_user}.ref_site_coef;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_coeflu   for ${hdb_user}.ref_site_coeflu;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_coef_day                  for ${hdb_user}.ref_site_coef_day;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_coef_month                  for ${hdb_user}.ref_site_coef_month;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_rating for ${hdb_user}.ref_site_rating;
CREATE OR REPLACE PUBLIC SYNONYM ref_site_rating_archive for ${hdb_user}.ref_site_rating_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_str           for ${hdb_user}.ref_str;
CREATE OR REPLACE PUBLIC SYNONYM ref_source_priority           for ${hdb_user}.ref_source_priority;
CREATE OR REPLACE PUBLIC SYNONYM ref_source_priority_archive   for ${hdb_user}.ref_source_priority_archive;
CREATE OR REPLACE PUBLIC SYNONYM ref_user_groups   for ${hdb_user}.ref_user_groups;
CREATE OR REPLACE PUBLIC SYNONYM ref_spatial_relation   for ${hdb_user}.ref_spatial_relation;
CREATE OR REPLACE PUBLIC SYNONYM r_base            for ${hdb_user}.r_base;
CREATE OR REPLACE PUBLIC SYNONYM r_base_archive            for ${hdb_user}.r_base_archive;
-- CREATE OR REPLACE PUBLIC SYNONYM r_base_update            for ${hdb_user}.r_base_update; removed for CP project
CREATE OR REPLACE PUBLIC SYNONYM r_day             for ${hdb_user}.r_day;
CREATE OR REPLACE PUBLIC SYNONYM r_daystat         for ${hdb_user}.r_daystat;
CREATE OR REPLACE PUBLIC SYNONYM r_hour            for ${hdb_user}.r_hour;
CREATE OR REPLACE PUBLIC SYNONYM r_hourstat        for ${hdb_user}.r_hourstat;
CREATE OR REPLACE PUBLIC SYNONYM r_instant         for ${hdb_user}.r_instant;
CREATE OR REPLACE PUBLIC SYNONYM r_month           for ${hdb_user}.r_month;
CREATE OR REPLACE PUBLIC SYNONYM r_monthstat                  for ${hdb_user}.r_monthstat;
CREATE OR REPLACE PUBLIC SYNONYM r_monthstatrange                    for ${hdb_user}.r_monthstatrange;
CREATE OR REPLACE PUBLIC SYNONYM r_other             for ${hdb_user}.r_other;
CREATE OR REPLACE PUBLIC SYNONYM r_wy              for ${hdb_user}.r_wy;
CREATE OR REPLACE PUBLIC SYNONYM r_wystat          for ${hdb_user}.r_wystat;
CREATE OR REPLACE PUBLIC SYNONYM r_year            for ${hdb_user}.r_year;
CREATE OR REPLACE PUBLIC SYNONYM r_yearstat        for ${hdb_user}.r_yearstat ;
CREATE OR REPLACE PUBLIC SYNONYM rm_year_v                   for ${hdb_user}.rm_year_v;
CREATE OR REPLACE PUBLIC SYNONYM rm_wy_v                     for ${hdb_user}.rm_wy_v; 
CREATE OR REPLACE PUBLIC SYNONYM rm_month_v                  for ${hdb_user}.rm_month_v;
CREATE OR REPLACE PUBLIC SYNONYM rm_hour_v                   for ${hdb_user}.rm_hour_v;
CREATE OR REPLACE PUBLIC SYNONYM rm_day_v                    for ${hdb_user}.rm_day_v;

CREATE OR REPLACE PUBLIC SYNONYM v_valid_interval_datatype   for ${hdb_user}.v_valid_interval_datatype;

--Missing Synonymes added on 09/2015  
CREATE OR REPLACE PUBLIC SYNONYM GET_PK_VAL_WRAP FOR ${hdb_user}.GET_PK_VAL_WRAP;
CREATE OR REPLACE PUBLIC SYNONYM CFS2ACFT FOR ${hdb_user}.CFS2ACFT;
CREATE OR REPLACE PUBLIC SYNONYM GET_HDB_SITE_COMMON_NAME FOR ${hdb_user}.GET_HDB_SITE_COMMON_NAME;
CREATE OR REPLACE PUBLIC SYNONYM GET_HDB_SITE_NAME FOR ${hdb_user}.GET_HDB_SITE_NAME;
CREATE OR REPLACE PUBLIC SYNONYM GSNA FOR ${hdb_user}.GSNA;
create or replace public synonym V_HDB_SITE_DATATYPE_NAME for ${hdb_user}.V_HDB_SITE_DATATYPE_NAME;
create or replace public synonym V_DBA_ROLES for ${hdb_user}.V_DBA_ROLES;
create or replace public synonym HDB_DATATYPE_UNIT for ${hdb_user}.HDB_DATATYPE_UNIT;
create or replace public synonym DAYS for ${hdb_user}.DAYS;
CREATE OR REPLACE PUBLIC SYNONYM POPULATE_PK_HDB FOR ${hdb_user}.POPULATE_PK;
CREATE OR REPLACE PUBLIC SYNONYM POPULATE_PK_REF FOR ${hdb_user}.POPULATE_PK;

--Synonyms for new archive tables added on 09/2019 by IsmailO
CREATE OR REPLACE PUBLIC SYNONYM HDB_SITE_ARCHIVE FOR ${hdb_user}.HDB_SITE_ARCHIVE;
CREATE OR REPLACE PUBLIC SYNONYM HDB_DATATYPE_ARCHIVE FOR ${hdb_user}.HDB_DATATYPE_ARCHIVE;
CREATE OR REPLACE PUBLIC SYNONYM HDB_SITE_DATATYPE_ARCHIVE FOR ${hdb_user}.HDB_SITE_DATATYPE_ARCHIVE;

--More Synonyms 03/2026
CREATE OR REPLACE PUBLIC SYNONYM REF_CHANGE_AGENT FOR ${hdb_user}.REF_CHANGE_AGENT;
CREATE OR REPLACE PUBLIC SYNONYM REF_LEGEND FOR ${hdb_user}.REF_LEGEND;
CREATE OR REPLACE PUBLIC SYNONYM IS_ROLE_GRANTED FOR ${hdb_user}.IS_ROLE_GRANTED;

-- spool off
-- exit;
CREATE OR REPLACE PUBLIC SYNONYM ref_hdb_installation for ${hdb_user}.ref_hdb_installation;
CREATE OR REPLACE PUBLIC SYNONYM ref_phys_quan_refresh_monitor for ${hdb_user}.ref_phys_quan_refresh_monitor;
-- set echo on
-- set feedback on
-- spool hdb_userprivs.out
BEGIN EXECUTE IMMEDIATE '
grant select on ${hdb_user}.cp_active_sdi_tsparm_view to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_agen to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_attr to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_attr_feature to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_collection_system to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/*grant select on ${hdb_user}.hdb_computed_datatype to public;  */
/*grant select on ${hdb_user}.hdb_computed_datatype_component to public;*/
BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_damtype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_data_source to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_datatype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_datatype_feature to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_date_time_unit to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_dimension to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/* grant select on ${hdb_user}.hdb_derivation_flag to public; removed for CP Project */
BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_DB_GENERIC_LIST to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_CZAR_DB_GENERIC_LIST to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_div to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_divtype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_dmi_unit_map to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_site_code_sys to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_site_code to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_site_code_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_data_code_sys to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_data_code to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_data_code_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_data_source to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_ext_data_source_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_feature to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_feature_class to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_feature_property to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_gagetype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_interval to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_loading_application to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_method to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_method_class to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_method_class_type to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_model to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_model_coord to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_modeltype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_objecttype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_operator to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_overwrite_flag to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_physical_quantity to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_property to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_rating_algorithm to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_rating_type to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_river to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_river_reach to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_site to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_site_datatype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_state to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_unit to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_usbr_off to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hdb_validation to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.hm_temp_data to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_day to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_hour to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_month to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_monthrange to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_monthstat to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_wy to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.m_year to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_agg_disagg to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_app_data_source to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_auth_site to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_auth_site_datatype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_db_list to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/* grant select on ${hdb_user}.ref_derivation_destination to public; removed for CP Project  */
/* grant select on ${hdb_user}.ref_derivation_source to public; removed for CP Project  */
BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_dmi_data_map to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_ENSEMBLE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_ENSEMBLE_KEYVAL to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_ENSEMBLE_TRACE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_ENSEMBLE_ARCHIVE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_ENSEMBLE_KEYVAL_ARCHIVE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.REF_ENSEMBLE_TRACE_ARCHIVE to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_ext_site_data_map to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_ext_site_data_map_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_ext_site_data_map_keyval to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_ext_site_data_map_key_arch to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_filetype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_pcode to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_pcode_objecttype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_site to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_site_datatype to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_site_hdbid to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hm_site_pcode to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_inter_copy_limits_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_interval_copy_limits to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_inter_copy_limits_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_interval_redefinition to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_interval_redef_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_loading_application_prop to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_model_run to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_model_run_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_model_run_keyval to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_model_run_keyval_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_rating to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_rating_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_res to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_res_flowlu to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_res_wselu to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_rating to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_rating_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_attr to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_attr_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_coef to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_coef_day to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_coef_month to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_site_coeflu to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_spatial_relation to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_source_priority to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_source_priority_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_str to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_user_groups to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_base to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_base_archive to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/*  grant select on ${hdb_user}.r_base_update to public;  removed for CP  */
BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_day to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_daystat to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_hour to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_hourstat to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_instant to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_month to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_monthstat to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_monthstatrange to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_other to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_wy to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_wystat to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_year to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.r_yearstat to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/*   Missing grants added on 09/2015  */
BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.V_HDB_SITE_DATATYPE_NAME to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.HDB_DATATYPE_UNIT to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.DAYS to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.dba_roles to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ${hdb_user}.HDB_SITE_ARCHIVE to PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ${hdb_user}.HDB_DATATYPE_ARCHIVE to PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ${hdb_user}.HDB_SITE_DATATYPE_ARCHIVE to PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/*   Missing grants added on 03/2026  */
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ${hdb_user}.REF_LEGEND TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant EXECUTE on ${hdb_user}.IS_ROLE_GRANTED to PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- spool off
-- exit;

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_hdb_installation to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on ${hdb_user}.ref_phys_quan_refresh_monitor to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- set echo on
-- set feedback on
-- spool hdb_roleprivs.out

/***********************************************************************/
/*  grant privileges to model_priv_role                              */
/***********************************************************************/
/* Messy, but can't grant model_role to role; otherwise, certain
   procedures which *must* fire for app_role will not fire, due to fact that
   model_role is also automatically enabled. So, grant all model privs to 
   model_priv_role, then grant this role to app_role and model_role. */
BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on REF_ENSEMBLE to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on REF_ENSEMBLE_KEYVAL to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on REF_ENSEMBLE_TRACE to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on REF_ENSEMBLE_ARCHIVE to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on REF_ENSEMBLE_KEYVAL_ARCHIVE to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on REF_ENSEMBLE_TRACE_ARCHIVE to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on ref_model_run to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_model_run_keyval to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_model_run_archive to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_model_run_keyval_archive to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_day to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_hour to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_month to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_monthstat to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_monthrange to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_year to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_wy to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/***********************************************************************/
/*  grant privileges to app_role                                       */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant model_priv_role to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant connect to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on hm_temp_data to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant update (max_hourly_date, max_daily_date) on ref_hm_site_datatype to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on ref_interval_copy_limits to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_DB_GENERIC_LIST to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on ref_loading_application_prop to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on r_base to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_daystat to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_hourstat to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_monthstat to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_monthstatrange to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_yearstat to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_wystat to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  select, insert, delete, update on ref_user_groups  to  app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
          
BEGIN EXECUTE IMMEDIATE 'grant alter tablespace to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on ratings to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/***********************************************************************/
/*  grant privileges to derivation_role                                */
/* derivation_role removed for CP Project 2008                         */
/***********************************************************************/
-- grant connect to derivation_role;
-- grant create table to derivation_role;
-- grant insert, update, delete on r_instant to derivation_role;
-- grant insert, update, delete on r_other to derivation_role;
-- grant insert, update, delete on r_hour to derivation_role;
-- grant insert, update, delete on r_day to derivation_role;
-- grant insert, update, delete on r_month to derivation_role;
-- grant insert, update, delete on r_year to derivation_role;
-- grant insert, update, delete on r_wy to derivation_role;
-- grant insert, update, delete on r_base_update to derivation_role;

/***********************************************************************/
/*  grant privileges to ref_meta_role                                   */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant  alter any table to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- grant  insert, delete, update on ref_derivation_source to ref_meta_role;      
-- grant  insert, delete, update on ref_derivation_destination to ref_meta_role;
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_div  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
      
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_ext_site_data_map  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
      
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_ext_site_data_map_keyval  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
      
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_interval_copy_limits to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_interval_redefinition to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_res  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
       
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_str  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
          
BEGIN EXECUTE IMMEDIATE 'grant  select, insert, delete, update on ref_user_groups  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
          
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_source_priority  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
          
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_res_flowlu  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_res_wselu  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
     
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_site_attr  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_site_coef  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_site_coef_day  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_site_coef_month  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_site_coeflu  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
       
BEGIN EXECUTE IMMEDIATE 'grant  insert, update, delete on ref_app_data_source to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
       
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_agg_disagg  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_dmi_data_map  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, update, delete on ref_auth_site  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, update, delete on ref_auth_site_datatype  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_hm_site_pcode to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_hm_site_hdbid to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_hm_site  to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_hm_pcode_objecttype to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_hm_pcode to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on ref_hm_filetype to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update (session_no, db_site_db_name, db_site_code) 
   on ref_db_list  to  ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update (site_datatype_id, hourly, daily, weekly, crsp, 
   hourly_delete, cutoff_minute, hour_offset) on ref_hm_site_datatype to 
   ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_spatial_relation to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/***********************************************************************/
/*  grant privileges to hdb_meta_role                                  */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant  alter any table to hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant ref_meta_role to hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_agen  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
      
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_attr  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
     
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_attr_feature  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
     
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_collection_system  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
/*grant  insert, delete, update on hdb_computed_datatype  to  hdb_meta_role;  */ 
/*grant  insert, delete, update on hdb_computed_datatype_component  to  hdb_meta_role;   */
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_damtype  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_data_source  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_datatype  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE '
grant  insert, delete, update on hdb_datatype_feature  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_date_time_unit  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
-- grant  insert, delete, update on hdb_derivation_flag  to  hdb_meta_role;   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_divtype  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_dmi_unit_map  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_ext_site_code_sys  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_ext_site_code to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_ext_data_code_sys  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_ext_data_code  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_ext_data_source  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN EXECUTE IMMEDIATE '
grant  insert, delete, update on hdb_feature  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_feature_class  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_feature_property  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_gagetype  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
    
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_interval  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
    
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_loading_application  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
    
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_method  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_method_class  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_method_class_type  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_model  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
       
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_model_coord  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
       
BEGIN EXECUTE IMMEDIATE 'grant  insert, update, delete on hdb_modeltype to hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_objecttype  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_operator  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_overwrite_flag  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_property  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
        
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_rating_algorithm  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
        
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_rating_type  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
        
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_river  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
        
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_river_reach  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_site  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
       
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_site_datatype  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_state  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
         
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_usbr_off  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
   
BEGIN EXECUTE IMMEDIATE 'grant  insert, delete, update on hdb_validation  to  hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on ratings to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/***********************************************************************/
/*  grant privileges to monthly                                        */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_monthstat to monthly'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_monthstatrange to monthly'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_month to monthly'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_monthrange to monthly'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_monthstat to monthly'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/***********************************************************************/
/*  grant privileges to savoir_faire                                   */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant  hdb_meta_role to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on ref_loading_application_prop to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_DB_GENERIC_LIST to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_ENSEMBLE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_ENSEMBLE_KEYVAL to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_ENSEMBLE_TRACE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_ENSEMBLE_ARCHIVE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_ENSEMBLE_KEYVAL_ARCHIVE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert,update,delete on REF_ENSEMBLE_TRACE_ARCHIVE to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_day  to  savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_hour  to  savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_month  to  savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_wy  to  savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value), delete on m_year  to  savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update (value) on m_monthstat to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update (value) on m_monthrange to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on r_base to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_interval_copy_limits to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_inter_copy_limits_archive to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_daystat to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_hourstat to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_monthstat to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_monthstatrange to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_yearstat to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update (value, source_id), delete on r_wystat to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

/***********************************************************************/
/*  grant privileges to cp_process                                     */
/***********************************************************************/
/***********************************************************************/
/*  grant privileges to calc_definition_role                           */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant execute on ratings to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_interval_copy_limits to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update, delete on hdb_loading_application to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, update on hdb_site_datatype to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/* Missing privileges added on 09/2015*/
BEGIN EXECUTE IMMEDIATE 'grant select, insert, delete, update on ref_user_groups to savoir_faire'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant execute on riverware_connection to model_priv_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant delete on hdb_loading_application to calc_definition_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on REF_RATING to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on REF_SITE_RATING to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on REF_RATING to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on REF_SITE_RATING to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on REF_SOURCE_PRIORITY_ARCHIVE to ref_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on hdb_site_sequence to app_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select on hdb_site_sequence to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on ref_ext_site_data_map_archive to hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant select,insert,update,delete on ref_ext_site_data_map_key_arch  to hdb_meta_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/* Missing privileges added for Alarm on 07/01/2020 */
BEGIN EXECUTE IMMEDIATE 'GRANT INSERT,UPDATE,DELETE on HDB_LOADING_APPLICATION  to CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_CURRENT TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_CURRENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_CURRENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_CURRENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_CURRENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_CURRENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_CURRENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_CURRENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_CURRENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON ALARM_EVENT TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_EVENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_EVENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_EVENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_EVENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_EVENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_EVENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_EVENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_EVENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON ALARM_GROUP TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_GROUP TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_GROUP TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_GROUP TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_GROUP TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_GROUP TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_GROUP TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_GROUP TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_GROUP TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON ALARM_HISTORY TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_HISTORY TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_HISTORY TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_HISTORY TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_HISTORY TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_HISTORY TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_HISTORY TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_HISTORY TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_HISTORY TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON ALARM_LIMIT_SET TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_LIMIT_SET TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_LIMIT_SET TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_LIMIT_SET TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_LIMIT_SET TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_LIMIT_SET TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_LIMIT_SET TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_LIMIT_SET TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_LIMIT_SET TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON ALARM_SCREENING TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_SCREENING TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_SCREENING TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_SCREENING TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_SCREENING TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON ALARM_SCREENING TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON ALARM_SCREENING TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON ALARM_SCREENING TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON ALARM_SCREENING TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON EMAIL_ADDR TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON EMAIL_ADDR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON EMAIL_ADDR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON EMAIL_ADDR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON EMAIL_ADDR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON EMAIL_ADDR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON EMAIL_ADDR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON EMAIL_ADDR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON EMAIL_ADDR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON FILE_MONITOR TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON FILE_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON FILE_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON FILE_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON FILE_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON FILE_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON FILE_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON FILE_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON FILE_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
GRANT SELECT ON PROCESS_MONITOR TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON PROCESS_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON PROCESS_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON PROCESS_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON PROCESS_MONITOR TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT UPDATE ON PROCESS_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON PROCESS_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT INSERT ON PROCESS_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT DELETE ON PROCESS_MONITOR TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


/* More Grants 03/2026 */
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, UPDATE, DELETE, INSERT ON REF_CHANGE_AGENT TO APP_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, UPDATE, DELETE, INSERT ON REF_CHANGE_AGENT TO REF_META_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, UPDATE, DELETE, INSERT ON REF_CHANGE_AGENT TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, UPDATE, DELETE, INSERT ON REF_CHANGE_AGENT TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON REF_LEGEND TO CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON REF_LEGEND TO SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON REF_LEGEND TO REF_META_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'GRANT REFERENCES ON REF_LEGEND TO DECODES'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- spool off
-- exit;

/***********************************************************************/
/*  grant privileges to czar_role                                      */
/***********************************************************************/
BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on hdb_physical_quantity to czar_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on hdb_unit to czar_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on hdb_dimension to czar_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_hdb_installation to czar_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'grant insert, delete, update on ref_phys_quan_refresh_monitor to czar_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

