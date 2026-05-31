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

Configuration is centralized in an environment file (`.env`) to prevent committing sensitive credentials.

1.  Copy the provided template to create your `.env` file:
    ```bash
    cp .env.example .env
    ```
2.  Edit `.env` to match your Oracle environment:
    ```properties
    FLYWAY_URL=jdbc:oracle:thin:@//localhost:1521/FREEPDB1
    FLYWAY_USER=flyway_admin
    FLYWAY_PASSWORD=your_admin_password
    FLYWAY_PLACEHOLDERS_HDB_USER=HDBDBA
    FLYWAY_PLACEHOLDERS_HDB_PASSWORD=your_hdb_password
    ```

> **Note**: Flyway Community Edition cannot connect as `SYSDBA`. You must create a dedicated `flyway_admin` user with DBA privileges instead of using `SYS`. See the **First-Time Setup** section below.

### First-Time Setup

Before running Flyway for the first time, connect as `SYSDBA` and create the `flyway_admin` user:

```sql
-- Connect as SYSDBA (e.g., via Docker)
-- docker exec -i <container> sqlplus 'sys/<password>@//localhost:1521/FREEPDB1 as sysdba'

CREATE USER flyway_admin IDENTIFIED BY <your_password>;
GRANT DBA TO flyway_admin;
GRANT CREATE SESSION TO flyway_admin;
ALTER USER flyway_admin QUOTA UNLIMITED ON USERS;
```

Then run the pre-grants script to grant SYS-owned object privileges that only SYSDBA can issue:

```bash
docker exec -i <container> sqlplus 'sys/<password>@//localhost:1521/FREEPDB1 as sysdba' < pre_grants.sql
```

### Running Migrations
To ensure the environment variables are loaded correctly, use the provided wrapper scripts:
- **Windows**: `run_flyway.bat migrate`
- **Linux/WSL**: `./run_flyway.sh migrate`

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

2.  **Re-run pre-grants** (required after drop since target users were removed):
    ```bash
    docker exec -i <container> sqlplus 'sys/<password>@//localhost:1521/FREEPDB1 as sysdba' < pre_grants.sql
    ```

3.  **Run Flyway migrate** to rebuild from scratch:
    ```bash
    # Linux/WSL
    ./run_flyway.sh migrate

    # Windows
    run_flyway.bat migrate
    ```
