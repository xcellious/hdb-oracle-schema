# HDB Oracle Database Flyway Migration

This repository contains the Flyway migration scripts and utilities for initializing and managing the HDB (Hydrological Database) Oracle schema. It replaces the legacy interactive `create.script` with a modern, version-controlled CI/CD pipeline approach.

## Overview

The database migration is managed via [Flyway](https://flywaydb.org/), tracking the database schema state using SQL scripts. This allows for reliable, repeatable deployments across different environments.

### Key Components

*   `build_flyway.sh`: A Linux-compatible bash script that reads the legacy Oracle DDL/SQL source files and compiles them into sequential Flyway version scripts (`V1_0_1__*.sql`, etc.).
*   `flyway_migration/sql/`: The directory where Flyway looks for the compiled SQL migration scripts.
*   `flyway_migration/conf/flyway.conf`: The configuration file containing database connection details and Flyway settings.

## Getting Started (Linux Environment)

This installation process is fully compatible with Linux environments (including WSL). 

### Prerequisites

1.  **Oracle Database**: Access to a running Oracle database instance (local or remote).
2.  **Flyway**: The `flyway` command-line tool must be installed and accessible in your system's PATH.
3.  **Environment Variables**: Ensure you have exported the required database credentials.

### Configuration

Edit the `flyway_migration/conf/flyway.conf` file to point to your specific Oracle database instance:

```properties
flyway.url=jdbc:oracle:thin:@//<host>:<port>/<service_name>
flyway.user=<your_admin_user>
flyway.password=<your_admin_password>
# Enable mixed mode for Oracle recompilation PL/SQL blocks
flyway.oracle.sqlplus=true
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
*   **Database Links**: The `SNAPSHOT_MANAGER` package body references several external database links (e.g., `LCHDB`, `YAOHDB`). These will fail to compile unless the corresponding private or public database links are created in your environment.


## Database Cleanup (Teardown)

When maintaining a local development environment, you may need to completely wipe the database to start fresh. Instead of dropping individual objects, the cleanest approach is to drop the entire schemas and any associated public objects.

1.  **Flyway Clean**: You can use Flyway's built-in clean command, which drops all objects, tables, and privileges owned by the schemas managed by Flyway:
    ```bash
    flyway -configFiles="flyway_migration/conf/flyway.conf" clean
    ```

2. **Complete Environment Reset (Recommended)**: If you are in a local environment and wish to easily and thoroughly wipe the main `HDBDBA` schema, the `DECODES` schema, the `CP_PROCESS` schema, the application users, and all related roles/synonyms, you can run the comprehensive drop script:
    ```sql
    -- Connect as a SYSDBA user
    @drop_everything.sql
    ```
