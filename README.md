# HDB Oracle Database Flyway Migration

This repository contains the Flyway migration scripts and utilities for initializing and managing the HDB (Hydrological Database) Oracle schema. It replaces the legacy interactive `create.script` with a modern, version-controlled CI/CD pipeline approach.

## Overview

The database migration is managed via [Flyway](https://flywaydb.org/) (v9.22.3, bundled in `flyway_tool/`), tracking the database schema state using SQL scripts. This allows for reliable, repeatable deployments across different environments.

### Key Components

*   `build_flyway.sh`: A Linux-compatible bash script that reads the legacy Oracle DDL/SQL source files and compiles them into sequential Flyway version scripts (`V1_0_1__*.sql`, etc.).
*   `flyway_migration/sql/`: The directory where Flyway looks for the compiled SQL migration scripts.
*   `flyway_migration/conf/flyway.conf`: The configuration file containing Flyway settings and the JDBC `internal_logon=sysdba` property for SYS connectivity.

### How the SYS Connection Works

Flyway connects to Oracle as the `SYS` user with `SYSDBA` privileges using the standard JDBC thin driver. This is accomplished by setting the `internal_logon` JDBC property in `flyway.conf`:

```properties
flyway.jdbcProperties.internal_logon=sysdba
```

This is equivalent to running `sqlplus 'sys/<password> as sysdba'` and gives Flyway full administrative privileges to create users, roles, schemas, and grant permissions — exactly what the migration scripts require.

## Getting Started

This installation process is compatible with both Windows and Linux/WSL environments.

### Prerequisites

1.  **Oracle Database**: Access to a running Oracle database instance (local or remote). Docker is recommended for local development:
    ```bash
    docker run -d --name oracle-free \
      -p 1521:1521 \
      -e ORACLE_PWD=<your_sys_password> \
      container-registry.oracle.com/database/free:latest
    ```
2.  **Java**: Flyway requires a Java runtime (JRE 8+). The bundled Flyway distribution in `flyway_tool/` includes its own JRE.
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
- **Linux/WSL**: `./run_flyway.sh migrate`

Other useful Flyway commands:
```bash
# Check migration status
run_flyway.bat info

# Validate pending migrations without applying
run_flyway.bat validate

# Repair the schema history table (e.g., after a failed migration)
run_flyway.bat repair
```

### Tablespace Assumptions

The Oracle environment must be pre-provisioned with the underlying tablespaces required by the HDB schema. Ensure the following tablespaces exist before running the migration:

*   **`HDB_DATA`**: Default data tablespace for the main schema.
*   **`HDB_USER`**: Tablespace for application users and their objects.
*   **`HDB_IDX`**: Default index tablespace.
*   **`HDB_TEMP`**: Temporary tablespace.

### Environmental Dependencies

Some database objects may remain in an `INVALID` state after migration if specific environmental dependencies are missing:

*   **`UTL_MAIL` Package**: The `SENDMAIL` function depends on the Oracle `UTL_MAIL` package. This package is often not installed by default (especially in Oracle Free/Express editions). To resolve invalidity, grant execute on `UTL_MAIL` to `${hdb_user}` after installing the package.
*   **Database Links**: The `SNAPSHOT_MANAGER` package body references several external database links. These will fail to compile unless the corresponding private or public database links are created in your environment.


## Database Cleanup (Teardown)

When maintaining a local development environment, you may need to completely wipe the database to start fresh. Instead of dropping individual objects, the cleanest approach is to drop the entire schemas and any associated public objects.

### Full Drop and Rebuild

1.  **Drop everything** — connect as SYSDBA and run the drop script:
    ```bash
    docker exec -i <container> sqlplus 'sys/<password>@//localhost:1521/FREEPDB1 as sysdba' < flyway_drop_everything.sql
    ```

2.  **Run Flyway migrate** to rebuild from scratch:
    ```bash
    # Linux/WSL
    ./run_flyway.sh migrate

    # Windows
    run_flyway.bat migrate
    ```


## Migration Script Order

The migration scripts execute in the following order:

| Script | Description |
|--------|-------------|
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
- Ensure the required tablespaces (`HDB_DATA`, `HDB_USER`, `HDB_IDX`, `HDB_TEMP`) are created before running migrations.

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
├── run_flyway.sh                   # Linux/WSL Flyway wrapper
├── flyway_drop_everything.sql      # Full teardown script (run as SYSDBA)
├── flyway_migration/
│   ├── conf/flyway.conf            # Flyway configuration
│   └── sql/base/                   # Migration scripts (V1_0_1 through V1_0_12)
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
