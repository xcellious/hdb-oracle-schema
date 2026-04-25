#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$BASE_DIR/flyway_migration/sql/base"

shopt -s nocasematch

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*.sql

# Fix legacy DATATYPE insert statements that miss column names
fix_legacy_datatype_insert() {
    perl -0777 -pe 's/(insert\s+into\s+datatype\s+)(select)/$1(id, standard, code) $2/gis'
}

# Expand SQL and handle SQL*Plus commands
expand_sql() {
    local input_file="$1"
    local current_dir=$(dirname "$input_file")
    
    # Check if file exists
    if [[ ! -f "$input_file" ]]; then
        echo "-- WARNING: Could not find file $input_file"
        return
    fi

    local prev_line=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        local rel_path=""
        if [[ "$line" =~ ^[[:space:]]*start[[:space:]]+([^;[:space:]]+) ]]; then
            rel_path="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*@[[:space:]]*([^;[:space:]]+) ]]; then
            rel_path="${BASH_REMATCH[1]}"
        fi

        if [[ -n "$rel_path" ]]; then
            # Support both ./ and paths relative to BASE_DIR
            local target_path=""
            if [[ "$rel_path" == ./* ]]; then
                target_path="$BASE_DIR/${rel_path#./}"
            else
                target_path="$BASE_DIR/$rel_path"
            fi
            
            echo "-- Expanding: $rel_path"
            expand_sql "$target_path"
        elif [[ "$line" =~ ^[[:space:]]*(spool|exit|whenever|rem|remark|show|SPOOL|EXIT|WHENEVER|REM|REMARK|SHOW)([[:space:];]|$) ]]; then
            # Comment out noise that might interfere with Flyway
            echo "-- $line"
        elif [[ "$line" =~ ^[[:space:]]*(set|prompt|spool|exit|show[[:space:]]+errors|whenever|\\.)[[:space:]]* ]]; then
            # Check if it's a SQL 'SET' (part of UPDATE)
            # SQL SET usually has an '=' after the first word on the same line or follows 'UPDATE'
            if [[ "$line" =~ ^[[:space:]]*(set|SET)[[:space:]]+[^[:space:]=]+[[:space:]]*= ]]; then
                echo "$line"
            elif [[ "$prev_line" =~ [[:space:]]*update[[:space:]] ]]; then
                echo "$line"
            else
                # Likely a SQL*Plus command or buffer end '.', comment it out
                echo "-- $line"
            fi
        else
            # Print the line normally
            echo "$line"
        fi
        prev_line="$line"
    done < "$input_file"
}

# Function to wrap SQL statements in safe PL/SQL blocks
wrap_safe_sql() {
    # Using Perl slurp mode to handle multi-line statements
    # We use a more sophisticated regex to ignore semicolons inside comments and strings
    perl -0777 -pe '
        s{^(\s*(?:DROP\s+(?:TABLE|VIEW|SEQUENCE|PROCEDURE|FUNCTION|PACKAGE|SYNONYM|PUBLIC\s+SYNONYM|USER|ROLE|INDEX)|ALTER\s+TABLE|GRANT|CREATE\s+TABLE)\b
            (?:
                --[^\n]*\n      |   # Line comments
                /\*.*?\*/       |   # Block comments
                \x27(?:\x27\x27|[^\x27])*\x27 | # String literals
                [^/;]               # Any other char except / or ;
            )*?
          )\s*;
        }{
            my $stmt = $1; 
            $stmt =~ s/\x27/\x27\x27/g; 
            "BEGIN EXECUTE IMMEDIATE \x27$stmt\x27; EXCEPTION WHEN OTHERS THEN NULL; END;\n/\n"
        }geimsx'
}

fix_acl_idempotency() {
    # Wrap DBMS_NETWORK_ACL_ADMIN blocks in EXCEPTION handlers to make them idempotent
    perl -0777 -pe 's/(BEGIN\s+DBMS_NETWORK_ACL_ADMIN\..+?END;)/BEGIN\n$1\nEXCEPTION WHEN OTHERS THEN NULL;\nEND;/gis'
}

placeholder_replace() {
    sed 's/\bDBA\b/${hdb_user}/g'
}

# Function to convert CREATE VIEW to CREATE OR REPLACE VIEW
convert_view_idempotent() {
    sed -E 's/CREATE[[:space:]]+VIEW/CREATE OR REPLACE VIEW/Ig'
}

# Function to convert CREATE PUBLIC SYNONYM to CREATE OR REPLACE PUBLIC SYNONYM
convert_synonym_idempotent() {
    sed -E 's/CREATE[[:space:]]+PUBLIC[[:space:]]+SYNONYM/CREATE OR REPLACE PUBLIC SYNONYM/Ig'
}

# Function to remove redundant version table creations
remove_version_table_creation() {
    perl -0777 -pe 's/CREATE\s+TABLE\s+(TSDB_DATABASE_VERSION|DECODESDATABASEVERSION)\s*\([^;]+\)\s*[^;]*;//gi'
}

# Function to fix cross-schema references to HDB tables
fix_hdb_references() {
    perl -0777 -pe 's/REFERENCES\s+(HDB_[A-Z_0-9]+)/REFERENCES \${hdb_user}.\1/gi'
}

# Function to remove SQLPlus-only terminators
fix_sqlplus_terminators() {
    sed -E 's/^[[:space:]]*\.[[:space:]]*$//Ig'
}

# Function to wrap COMMENT ON statements in safe PL/SQL blocks (handles obsolete/missing tables)
wrap_safe_comments() {
    perl -0777 -pe '
        s{(comment\s+on\s+(?:table|column)\s+(?:\x27(?:\x27\x27|[^\x27])*\x27|[^\x27;])*?;)\s*}{
            my $stmt = $1;
            $stmt =~ s/\x27/\x27\x27/g;
            "BEGIN EXECUTE IMMEDIATE \x27$stmt\x27; EXCEPTION WHEN OTHERS THEN NULL; END;\n/\n"
        }geis'
}

# Function to convert SQLPlus EXECUTE calls to proper PL/SQL BEGIN/END blocks
fix_sqlplus_execute() {
    sed -E 's/^[[:space:]]*execute[[:space:]]+([^;]+);[[:space:]]*/BEGIN \1; EXCEPTION WHEN OTHERS THEN NULL; END;\n\//Ig'
}

# V1_0_1: Users and Roles
cat << 'EOF' > "$OUT_DIR/V1_0_1__Create_Users_and_Roles.sql"
-- V1_0_1__Create_Users_and_Roles.sql
-- Baseline schema setup: Roles and Users

-- Roles
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE CZAR_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE HDB_META_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE REF_META_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE APP_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE DECODES_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE CALC_DEFINITION_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE SAVOIR_FAIRE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE MODEL_PRIV_ROLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE MONTHLY'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Users
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER ${hdb_user} IDENTIFIED BY "${hdb_password}" DEFAULT TABLESPACE HDB_data TEMPORARY TABLESPACE HDB_temp QUOTA UNLIMITED ON HDB_data QUOTA UNLIMITED ON HDB_idx';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
GRANT CONNECT, RESOURCE, HDB_META_ROLE, REF_META_ROLE, DECODES_ROLE to ${hdb_user};
-- Grant access to dictionary views needed by triggers
GRANT SELECT ON SYS.DBA_ROLE_PRIVS TO ${hdb_user};
GRANT SELECT ON SYS.DBA_ROLES TO ${hdb_user};

BEGIN
    EXECUTE IMMEDIATE 'CREATE USER decodes IDENTIFIED BY "${hdb_password}" DEFAULT TABLESPACE HDB_data TEMPORARY TABLESPACE HDB_temp QUOTA UNLIMITED ON HDB_data QUOTA UNLIMITED ON HDB_idx';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
GRANT CONNECT, RESOURCE, DECODES_ROLE to decodes;

BEGIN
    EXECUTE IMMEDIATE 'CREATE USER CP_PROCESS IDENTIFIED BY "${hdb_password}" DEFAULT TABLESPACE HDB_data TEMPORARY TABLESPACE HDB_temp QUOTA UNLIMITED ON HDB_data QUOTA UNLIMITED ON HDB_idx';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
GRANT CONNECT, RESOURCE to CP_PROCESS;

-- Permissions for CP_PROCESS
GRANT app_role TO CP_PROCESS;
GRANT decodes_role TO CP_PROCESS;
GRANT calc_definition_role TO CP_PROCESS;
ALTER USER CP_PROCESS DEFAULT ROLE ALL;

-- SYSDBA grants to HDBDBA for migration tasks (if needed, but usually SYS performs migration)
-- GRANT DBA TO ${hdb_user};
GRANT SELECT ON DBA_ROLES TO ${hdb_user};
GRANT UNLIMITED TABLESPACE TO ${hdb_user};

-- Additional HDB Users (from PERMISSIONS/BASE_SCRIPTS/permissions.sh)
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER psswd_user IDENTIFIED BY "${hdb_password}" DEFAULT TABLESPACE HDB_data TEMPORARY TABLESPACE HDB_temp QUOTA 10M ON HDB_data';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
GRANT CONNECT, CREATE PROCEDURE, CREATE TABLE, CREATE TRIGGER TO psswd_user;
GRANT SELECT ON SYS.dba_role_privs TO psswd_user;
GRANT SELECT ON SYS.user$ TO psswd_user;

BEGIN
    EXECUTE IMMEDIATE 'CREATE USER app_user IDENTIFIED BY "${hdb_password}" DEFAULT TABLESPACE HDB_user TEMPORARY TABLESPACE HDB_temp QUOTA UNLIMITED ON HDB_user';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
GRANT CREATE SESSION TO app_user;
GRANT app_role TO app_user;
GRANT ref_meta_role TO app_user;
GRANT hdb_meta_role TO app_user;
GRANT model_priv_role TO app_user;
ALTER USER app_user DEFAULT ROLE NONE;
EOF

# V1_0_2: Base Tables
echo "ALTER SESSION SET CURRENT_SCHEMA = \${hdb_user};" > "$OUT_DIR/V1_0_2__Create_Base_Tables.sql"
cat << 'EOF' >> "$OUT_DIR/V1_0_2__Create_Base_Tables.sql"
-- Pre-create version tables to resolve circular dependencies
-- 1. HDB version table
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE TSDB_DATABASE_VERSION (VERSION NUMBER, DESCRIPTION VARCHAR2(400)) tablespace HDB_data';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM TSDB_DATABASE_VERSION FOR ${hdb_user}.TSDB_DATABASE_VERSION';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 2. DECODES version table (in its own schema)
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE decodes.DECODESDATABASEVERSION (VERSION NUMBER, DESCRIPTION VARCHAR2(400)) tablespace HDB_data';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM DECODESDATABASEVERSION FOR decodes.DECODESDATABASEVERSION';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
GRANT SELECT, INSERT, UPDATE, DELETE ON decodes.DECODESDATABASEVERSION TO ${hdb_user};
GRANT SELECT, INSERT, UPDATE, DELETE ON decodes.DECODESDATABASEVERSION TO savoir_faire;
GRANT SELECT, INSERT, UPDATE, DELETE ON decodes.DECODESDATABASEVERSION TO calc_definition_role;
EOF
expand_sql "$BASE_DIR/SCHEMA/BASE_SCRIPTS/tbl.ddl" | placeholder_replace | remove_version_table_creation | wrap_safe_sql | convert_synonym_idempotent | fix_sqlplus_terminators >> "$OUT_DIR/V1_0_2__Create_Base_Tables.sql"
expand_sql "$BASE_DIR/SCHEMA/BASE_SCRIPTS/timeSeries.ddl" | placeholder_replace | remove_version_table_creation | wrap_safe_sql | convert_synonym_idempotent | fix_sqlplus_terminators >> "$OUT_DIR/V1_0_2__Create_Base_Tables.sql"
expand_sql "$BASE_DIR/SCHEMA/BASE_SCRIPTS/czar_tbl.ddl" | placeholder_replace | remove_version_table_creation | wrap_safe_sql | convert_synonym_idempotent | fix_sqlplus_terminators >> "$OUT_DIR/V1_0_2__Create_Base_Tables.sql"

# V1_0_3: Indexes and Keys
echo "ALTER SESSION SET CURRENT_SCHEMA = \${hdb_user};" > "$OUT_DIR/V1_0_3__Base_Indexes_and_Keys.sql"
expand_sql "$BASE_DIR/SCHEMA/BASE_SCRIPTS/index.ddl" | placeholder_replace | remove_version_table_creation | wrap_safe_sql | convert_synonym_idempotent | fix_sqlplus_terminators >> "$OUT_DIR/V1_0_3__Base_Indexes_and_Keys.sql"
expand_sql "$BASE_DIR/SCHEMA/BASE_SCRIPTS/primkey.ddl" | placeholder_replace | remove_version_table_creation | wrap_safe_sql | convert_synonym_idempotent | fix_sqlplus_terminators >> "$OUT_DIR/V1_0_3__Base_Indexes_and_Keys.sql"
expand_sql "$BASE_DIR/SCHEMA/BASE_SCRIPTS/czar_primkey.ddl" | placeholder_replace | remove_version_table_creation | wrap_safe_sql | convert_synonym_idempotent | fix_sqlplus_terminators >> "$OUT_DIR/V1_0_3__Base_Indexes_and_Keys.sql"
cat << 'EOF' >> "$OUT_DIR/V1_0_3__Base_Indexes_and_Keys.sql"
-- Cross-schema grants needed for subsequent constraint creation
GRANT REFERENCES ON ${hdb_user}.HDB_LOADING_APPLICATION TO decodes;
EOF


echo "Build complete."
