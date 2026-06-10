set pagesize 500
set linesize 200
set feedback on

PROMPT === OBJECT COUNTS BY TYPE ===
SELECT object_type, COUNT(*) as cnt
FROM dba_objects
WHERE (owner LIKE '%DBA' OR owner LIKE 'PSS%' OR owner = 'DECODES')
AND object_type IN ('PROCEDURE','FUNCTION','VIEW','PACKAGE','PACKAGE BODY','TRIGGER','SEQUENCE','INDEX','TABLE','DATABASE LINK')
GROUP BY object_type
ORDER BY object_type;

PROMPT === TOTAL OBJECTS ===
SELECT COUNT(*) as total_objects
FROM dba_objects
WHERE (owner LIKE '%DBA' OR owner LIKE 'PSS%' OR owner = 'DECODES')
AND object_type IN ('PROCEDURE','FUNCTION','VIEW','PACKAGE','PACKAGE BODY','TRIGGER','SEQUENCE','INDEX','TABLE','DATABASE LINK');

PROMPT === CONSTRAINT COUNT ===
SELECT COUNT(*) as total_constraints
FROM dba_constraints
WHERE (owner LIKE '%DBA' OR owner LIKE 'PSS%')
AND constraint_name NOT LIKE 'SYS%';

PROMPT === SYNONYM COUNT ===
SELECT COUNT(*) as total_synonyms
FROM dba_synonyms
WHERE (table_owner LIKE '%DBA' OR table_owner LIKE 'PSS%');

PROMPT === ROLE COUNT ===
SELECT COUNT(*) as total_roles FROM dba_roles
WHERE role IN ('APP_ROLE','HDB_META_ROLE','REF_META_ROLE','MONTHLY','SAVOIR_FAIRE','MODEL_PRIV_ROLE','DECODES_ROLE','CALC_DEFINITION_ROLE','CZAR_ROLE');

PROMPT === INVALID OBJECTS ===
SELECT owner, object_type, object_name
FROM dba_objects
WHERE status = 'INVALID' AND (owner LIKE '%DBA' OR owner LIKE 'PSS%' OR owner = 'DECODES')
ORDER BY owner, object_type, object_name;

PROMPT === COMPILATION ERRORS ===
SELECT name, type, text
FROM dba_errors
WHERE (owner LIKE '%DBA' OR owner LIKE 'PSS%' OR owner = 'DECODES')
ORDER BY owner, name, type, line;

quit;
