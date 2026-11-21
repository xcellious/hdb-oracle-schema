# HDB Oracle Sample Seed Data

Reusable, idempotent sample seed scripts for populating the local development/test HDB Oracle database (`HDBDBA` and `DECODES` schemas) **after** Flyway migrations (`V1_0_0` through `V1_0_12`) have completed successfully.

> **Local Development / Testing Only**: These scripts are kept outside `flyway_migration/sql/base/` so sample data is never executed by production Flyway migrations and `flyway_schema_history` remains untouched.

## What Is Seeded

The dataset models a realistic, interconnected **Colorado River Basin (Upper & Lower Colorado)** hydrological operations scenario across **HDBDBA** and **DECODES**:

| Script | Scope |
|--------|-------|
| `00_preflight_and_prereqs.sql` | Verifies Flyway migration `1.0.12` succeeded, confirms target schemas exist, and compiles `HDBDBA.SNAPSHOT_MANAGER` body with dynamic SQL for its 5 unused remote USBR DB-link calls so triggers on `HDB_SITE` and `HDB_SITE_DATATYPE` run cleanly in this standalone database. |
| `01_core_lookup_reference.sql` | Installation/DB metadata, date-time units, intervals, dimensions, base & derived units, physical quantities, agencies, states, USBR offices, dam/diversion/gage/object types, validation & overwrite flags, collection systems, data sources, loading apps, method hierarchy, models, rivers & reaches, 30 datatypes (auto-synced to `DECODES.DATATYPE`), rating types, features, properties, and attributes. |
| `02_sites_and_authorization.sql` | 41 hierarchical `HDB_SITE` records (basins → subbasins → reservoirs, streamgages, diversions, powerplants, SNOTEL, weather station), `DECODES_SITE_EXT`, role authorizations (`REF_AUTH_SITE`, `REF_AUTH_SITE_DATATYPE`), 111 `HDB_SITE_DATATYPE` series, reservoir/gage/diversion specs (`REF_RES*`, `REF_STR`, `REF_DIV`), site attributes, monthly/daily/lookup coefficients, spatial routing relations, rating curves (`REF_SITE_RATING`, `REF_RATING`), source priorities, QA/QC copy limits, and user groups. |
| `03_external_hydromet_mappings.sql` | External code systems (USGS, SHEF, Hydromet, SNOTEL, SCADA, RiverWare), external data sources, site/data code crosswalks, active/inactive mappings & key-values, Hydromet reference tables (`REF_HM_*`), DMI unit map, loading app properties, legends, `CG_REF_CODES`, and `TSDB_PROPERTY`. |
| `04_models_ensembles_and_cp.sql` | 24 `REF_MODEL_RUN` entries (24-Month Study, CRSS, MTOM, CBRFC ESP, Daily/Hourly Ops) + key-values, 5 ensembles + traces, 10 hierarchical `TSDB_GROUP` definitions + memberships, 12 `CP_ALGORITHM` definitions + properties/parms/scripts, 21 `CP_COMPUTATION` definitions (active & retired) + parms/properties, `CP_TS_ID`, `CP_COMP_DEPENDS`, process locks, and historic computations. |
| `05_timeseries_real_and_model.sql` | Real time series loaded through `HDBDBA.MODIFY_R_BASE_RAW(..., DO_UPDATE_Y_OR_N => 'N')` so native validation, date standardization, automatic merges into `R_INSTANT`/`R_HOUR`/`R_DAY`/`R_MONTH`/`R_YEAR`/`R_WY`/`R_OTHER`, `CP_TS_ID`, and `CP_COMP_TASKLIST` all execute naturally; statistical summaries (`R_*STAT`); modeled time series (`M_HOUR` through `M_WY`). |
| `06_alarms_and_monitoring.sql` | Alarm groups, synthetic `.test` notification emails, file & process monitors, event patterns, 18 screening definitions, seasonal limit sets, active alarms (`ALARM_CURRENT`), and resolved historical alarms (`ALARM_HISTORY`). |
| `07_decodes_telemetry.sql` | DECODES enums, non-HDB datatypes (`SHEF-PE`, `USGS`) & equivalences, unit converters, equipment models, platform configs/sensors/scripts, LRGS/web/directory data sources, presentation groups & rounding rules, network lists, 22 DCP platforms & transport media, routing specs, schedule entries & run history, platform status, `DACQ_EVENT`, and serial port status. |

## Prerequisites

1. Oracle Docker container is running and healthy on port `1521` (or local `sqlplus` is installed).
2. Repository root `.env` is configured (`FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD`, `FLYWAY_PLACEHOLDERS_HDB_USER`).
3. Flyway migrations have completed cleanly (`run_flyway.bat info` shows `1.0.12 Success`).

## How to Run

### Load Sample Data (One Command)

- **Windows**:
  ```cmd
  database\seed\run_seed.bat
  ```
- **Windows (load + validate in one step)**:
  ```cmd
  database\seed\run_seed.bat --validate
  ```
- **Linux / macOS**:
  ```bash
  ./database/seed/run_seed.sh
  # or load + validate:
  ./database/seed/run_seed.sh --validate
  ```

> If you have multiple Docker containers running or a custom port mapping, set `ORACLE_DOCKER_CONTAINER=<container_name>` before running the script.

### Validate Data Integrity Independently

- **Windows**:
  ```cmd
  database\seed\run_validate.bat
  ```
- **Linux / macOS**:
  ```bash
  ./database/seed/run_validate.sh
  ```

## Rerunning / Idempotency

All scripts are safe to run repeatedly:
- Existing data is never truncated, deleted, or overwritten.
- Deterministic IDs use insert-only `MERGE` (`WHEN NOT MATCHED THEN INSERT`).
- Trigger-assigned keys (`REF_MODEL_RUN`, `REF_SITE_RATING`, `CP_TS_ID`) check existence by natural key before inserting.
- Real time series use `MODIFY_R_BASE_RAW(..., DO_UPDATE_Y_OR_N => 'N')` so reruns skip existing records without creating duplicate `R_BASE_ARCHIVE` or `CP_COMP_TASKLIST` entries.
- Oracle sequences are advanced past the highest seeded ID so subsequent application inserts never collide with seeded keys.

## Intentionally Unpopulated Tables

- **Preserved System/Version Tables** (untouched): `HDBDBA.TSDB_DATABASE_VERSION`, `DECODES.DECODESDATABASEVERSION`, `HDBDBA.REF_DB_PARAMETER`, `PSSWD_USER.ROLE_PSSWD`.
- **Archive Tables** (26 `*_ARCHIVE` tables): Populated automatically by `AFTER UPDATE`/`AFTER DELETE` audit triggers.
- **Internal / Remote-Link / Staging Tables**: `CP_COMP_DEPENDS_SCRATCHPAD`, `CP_REMOTE_TRIGGERING` (requires remote DB links), `REF_CZAR_DB_GENERIC_LIST` (unused in standalone master DB), `REF_CHANGE_AGENT` (audit agent metadata), `HM_TEMP_DATA` (transient Hydromet staging).
