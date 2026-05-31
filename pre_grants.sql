-- Pre-grants that only SYSDBA can execute.
-- Run this BEFORE flyway migrate when starting from scratch.

-- Allow flyway_admin to grant SYS base-table objects
GRANT SELECT ON SYS.user$ TO flyway_admin WITH GRANT OPTION;
GRANT SELECT ANY DICTIONARY TO flyway_admin;

exit;
