-- =============================================================================
-- run_all_seed.sql
-- Master SQL*Plus entrypoint for HDB Oracle sample seed data.
--
-- Usage (local sqlplus from repo root):
--   sqlplus -s "sys/<password>@//localhost:1521/FREEPDB1 as sysdba" @database/seed/run_all_seed.sql
--
-- For one-command execution using .env (Docker or local sqlplus):
--   Windows: database\seed\run_seed.bat
--   Linux:   ./database/seed/run_seed.sh
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
WHENEVER OSERROR  EXIT FAILURE ROLLBACK

SET DEFINE OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET ECHO OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 500

PROMPT ============================================================================
PROMPT HDB Oracle Sample Seed Data Loader
PROMPT ============================================================================

@@00_preflight_and_prereqs.sql
@@01_core_lookup_reference.sql
@@02_sites_and_authorization.sql
@@03_external_hydromet_mappings.sql
@@04_models_ensembles_and_cp.sql
@@05_timeseries_real_and_model.sql
@@06_alarms_and_monitoring.sql
@@07_decodes_telemetry.sql

PROMPT ============================================================================
PROMPT Sample seed data load completed successfully.
PROMPT ============================================================================
EXIT 0
