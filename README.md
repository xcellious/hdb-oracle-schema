# HDB Oracle Database Flyway Migration

This repository contains the Flyway migration scripts and utilities for initializing and managing the HDB (Hydrological Database) Oracle schema. It replaces the legacy interactive `create.script` with a modern, version-controlled CI/CD pipeline approach.

## Overview

The database migration is managed via [Flyway](https://flywaydb.org/) (v9.22.3, bundled in `flyway_tool/`), tracking the database schema state using SQL scripts. This allows for reliable, repeatable deployments across different environments.

### Key Components

*   `build_flyway.sh`: A Linux-compatible bash script that reads the legacy Oracle DDL/SQL source files and compiles them into sequential Flyway version scripts (`V1_0_0__*.sql` through `V1_0_12__*.sql`).
*   `flyway_migration/sql/`: The directory where Flyway looks for the compiled SQL migration scripts.
*   `flyway_migration/conf/flyway.conf`: The configuration file containing Flyway settings and the JDBC `internal_logon=sysdba` property for SYS connectivity.

### How the SYS Connection Works

Flyway connects to Oracle as the `SYS` user with `SYSDBA` privileges using the standard JDBC thin driver. This is accomplished by setting the `internal_logon` JDBC property in `flyway.conf`:

```properties
flyway.jdbcProperties.internal_logon=sysdba
```

This is equivalent to running `sqlplus 'sys/<password> as sysdba'` and gives Flyway full administrative privileges to create users, roles, schemas, and grant permissions — exactly what the migration scripts require.

## Getting Started

This installation process is compatible with both Windows and Linux environments.

### Prerequisites

1.  **Oracle Database**: Access to a running Oracle database instance (local or remote). Docker is recommended for local development:
    ```bash
    docker run -d --name oracle-free \
      -p 1521:1521 \
      -e ORACLE_PWD=<your_sys_password> \
      container-registry.oracle.com/database/free:latest
    ```
2.  **Java**: Flyway requires a Java runtime (JRE 8+). The bundled Flyway distribution in `flyway_tool/` includes a **Windows JRE**. On Linux, ensure Java 8+ is installed on your system (`java -version`).
3.  **Environment Variables**: A configured `.env` file with database credentials (see below).

### Configuration

Configuration is centralized in an environment file (`.env`) to prevent committing sensitive credentials.

1.  Copy the provided template to create your `.env` file:
    ```bash
    cp .env.example .env
    ```
2.  Edit `.env` to match your Oracle environment:
    ```properties
    FLYWAY_URL=jdbc:oracle:thin:@//localhost:1521/FREEPDB1
    FLYWAY_USER=sys
    FLYWAY_PASSWORD=your_sys_password
    FLYWAY_PLACEHOLDERS_HDB_USER=HDBDBA
    FLYWAY_PLACEHOLDERS_HDB_PASSWORD=your_hdb_password
    ```

> **Note**: The `FLYWAY_USER` must be `sys`. The SYSDBA privilege escalation is handled automatically by the `internal_logon=sysdba` JDBC property in `flyway.conf`. Do **not** append "as sysdba" to the username.

### Running Migrations

Use the provided wrapper scripts which load the `.env` file and invoke Flyway:

- **Windows**: `run_flyway.bat migrate`
- **Linux**: `./run_flyway.sh migrate`

> **Linux Note**: If you cloned this repository on Windows or the files have Windows line endings (`\r\n`), run `dos2unix run_flyway.sh .env` or `sed -i 's/\r$//' run_flyway.sh .env` before executing the shell script.

Other useful Flyway commands:
```bash
# Check migration status
run_flyway.bat info          # Windows
./run_flyway.sh info         # Linux

# Validate pending migrations without applying
run_flyway.bat validate      # Windows
./run_flyway.sh validate     # Linux

# Repair the schema history table (e.g., after a failed migration)
run_flyway.bat repair        # Windows
./run_flyway.sh repair       # Linux
```

### Tablespaces

The first migration script (`V1_0_0__Create_Tablespaces.sql`) automatically creates the required tablespaces if they do not already exist. If a tablespace already exists, the script skips it and leaves it untouched.

| Tablespace | Type | Default Size | Autoextend | Purpose |
|------------|------|-------------|------------|---------|
| `HDB_DATA` | Permanent | 50 MB | 10 MB increments, unlimited | Default data tablespace for the main schema |
| `HDB_USER` | Permanent | 50 MB | 10 MB increments, unlimited | Tablespace for application users and their objects |
| `HDB_IDX`  | Permanent | 50 MB | 10 MB increments, unlimited | Default index tablespace |
| `HDB_TEMP` | Temporary | 100 MB | 20 MB increments, max 2 GB | Temporary tablespace for sort, hash join, and PGA spill operations |

#### Customizing Tablespace Configuration

The default sizes above are intended for **development and testing** environments. For production deployments, your DBA should pre-create these tablespaces with appropriate sizing, data file locations, and storage parameters **before** running `flyway migrate`. The migration will detect the existing tablespaces and skip creation.

Example — creating tablespaces with production-grade sizing:
```sql
-- Permanent tablespaces (adjust paths and sizes for your environment)
CREATE TABLESPACE HDB_DATA DATAFILE '/u01/oradata/hdb_data01.dbf' SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 10G;
CREATE TABLESPACE HDB_USER DATAFILE '/u01/oradata/hdb_user01.dbf' SIZE 200M AUTOEXTEND ON NEXT 50M  MAXSIZE 5G;
CREATE TABLESPACE HDB_IDX  DATAFILE '/u01/oradata/hdb_idx01.dbf'  SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 10G;

-- Temporary tablespace (sized for concurrent sort/hash operations)
CREATE TEMPORARY TABLESPACE HDB_TEMP TEMPFILE '/u01/oradata/hdb_temp01.dbf' SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 4G;
```

> **Tip**: `HDB_TEMP` is sized larger by default because it handles sort operations, hash joins, and temporary LOBs generated by the HDB stored procedures and complex queries. Monitor `V$TEMP_SPACE_HEADER` and `V$TEMPSEG_USAGE` in production to right-size it for your workload.

### Environmental Dependencies

Some database objects may remain in an `INVALID` state after migration if specific environmental dependencies are missing:

*   **`UTL_MAIL` Package**: The `SENDMAIL` function depends on the Oracle `UTL_MAIL` package. This package is often not installed by default (especially in Oracle Free/Express editions). To resolve invalidity, grant execute on `UTL_MAIL` to `${hdb_user}` after installing the package.
*   **Database Links**: The `SNAPSHOT_MANAGER` package body references several external database links. These will fail to compile unless the corresponding private or public database links are created in your environment.


## Database Cleanup (Teardown)

When maintaining a local development environment, you may need to completely wipe the database to start fresh. Instead of dropping individual objects, the cleanest approach is to drop the entire schemas and any associated public objects.

### Full Drop and Rebuild

The `flyway_drop_everything.sql` script drops all HDB users, roles, public synonyms, the Flyway history table, **and the four HDB tablespaces** (including contents and datafiles). This ensures a completely clean slate.

1.  **Drop everything** — connect as SYSDBA and run the drop script:
    ```bash
    # Linux
    docker exec -i <container> sqlplus 'sys/<password>@//localhost:1521/FREEPDB1 as sysdba' < flyway_drop_everything.sql

    # Windows (PowerShell)
    Get-Content flyway_drop_everything.sql | docker exec -i <container> sqlplus -s "sys/<password>@//localhost:1521/FREEPDB1 as sysdba"
    ```

2.  **Run Flyway migrate** to rebuild from scratch:
    ```bash
    # Windows
    run_flyway.bat migrate

    # Linux
    ./run_flyway.sh migrate
    ```


## Migration Script Order

The migration scripts execute in the following order:

| Script | Description |
|--------|-------------|
| `V1_0_0` | Create tablespaces (HDB_DATA, HDB_USER, HDB_IDX, HDB_TEMP) if they don't exist |
| `V1_0_1` | Create roles (CZAR_ROLE, APP_ROLE, etc.) and users (HDBDBA, DECODES, CP_PROCESS, PSSWD_USER, APP_USER) |
| `V1_0_2` | Create base tables in HDBDBA schema |
| `V1_0_3` | Base indexes and primary/foreign keys |
| `V1_0_4` | CP (Computation Processor) metadata tables |
| `V1_0_5` | DECODES schema tables |
| `V1_0_6` | Logic: triggers, procedures, packages, functions, and constraints |
| `V1_0_7` | Public synonyms and grants to roles/users |
| `V1_0_8` | Post-migration cleanup and view creation |
| `V1_0_9` | PSSWD_USER schema objects (role_psswd table, triggers) |
| `V1_0_10` | HDB metadata seed data |
| `V1_0_11` | Invalid object check |
| `V1_0_12` | Compilation error check |

## Troubleshooting

### ORA-01017: invalid username/password; logon denied
- Verify `FLYWAY_PASSWORD` in `.env` matches the actual SYS password.
- Ensure `FLYWAY_USER=sys` (lowercase). Do **not** use `SYS AS SYSDBA`.
- The `internal_logon=sysdba` property in `flyway.conf` handles SYSDBA authentication.

### ORA-01918: user does not exist / ORA-00959: tablespace does not exist
- The `V1_0_0` migration auto-creates tablespaces, so this error should be rare. If it occurs, verify the `V1_0_0` migration ran successfully via `run_flyway.bat info`. If running against a pre-existing database where `V1_0_0` was baselined, ensure the tablespaces (`HDB_DATA`, `HDB_USER`, `HDB_IDX`, `HDB_TEMP`) exist.

### Invalid objects after migration
- Some objects like `SENDMAIL` and `SNAPSHOT_MANAGER` depend on external packages (`UTL_MAIL`) or database links that may not exist in your environment. These are expected in a local dev setup.
- Run `V1_0_11__Check_Invalids.sql` output to see the full list.

### Flyway "migration checksum mismatch"
- If you modified a migration script after it was applied, run `run_flyway.bat repair` to update the checksums in the history table.

## Project Structure

```
hdb-oracle-schema/
├── .env.example                    # Template for database credentials
├── .gitignore
├── README.md
├── build_flyway.sh                 # Compiles legacy DDL into Flyway scripts
├── run_flyway.bat                  # Windows Flyway wrapper
├── run_flyway.sh                   # Linux Flyway wrapper
├── flyway_drop_everything.sql      # Full teardown script (run as SYSDBA)
├── flyway_migration/
│   ├── conf/flyway.conf            # Flyway configuration
│   └── sql/base/                   # Migration scripts (V1_0_0 through V1_0_12)
├── flyway_tool/                    # Bundled Flyway CLI (v9.22.3)
├── SCHEMA/                         # Legacy source DDL files
├── PROCEDURES/                     # Legacy stored procedures
├── PACKAGES/                       # Legacy PL/SQL packages
├── FUNCTIONS/                      # Legacy functions
├── TRIGGERS/                       # Legacy triggers
├── VIEWS/                          # Legacy views
├── CONSTRAINTS/                    # Legacy constraints
├── PERMISSIONS/                    # Legacy permission scripts
├── SEQUENCES/                      # Legacy sequences
├── TYPES/                          # Legacy type definitions
├── STANDARD_DATA/                  # Legacy seed data
└── METADATA/                       # Legacy metadata scripts
```
