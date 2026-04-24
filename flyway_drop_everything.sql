BEGIN
  -- 1. Drop Users and all their schema objects
  FOR u IN (SELECT username FROM dba_users WHERE username IN ('HDBDBA', 'DECODES', 'CP_PROCESS', 'APP_USER', 'PSSWD_USER', 'CZAR_USER', 'META_DATA_USER')) LOOP
    EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
  END LOOP;
  
  -- 2. Drop Roles
  FOR r IN (SELECT role FROM dba_roles WHERE role IN ('APP_ROLE', 'HDB_META_ROLE', 'REF_META_ROLE', 'MONTHLY', 'SAVOIR_FAIRE', 'MODEL_PRIV_ROLE', 'DECODES_ROLE', 'CALC_DEFINITION_ROLE')) LOOP
    EXECUTE IMMEDIATE 'DROP ROLE ' || r.role;
  END LOOP;

  -- 3. Drop Public Synonyms pointing to our dropped schemas
  -- This safely finds and drops any lingering public synonyms that point to tables/objects in HDBDBA, DECODES, CP_PROCESS, APP_USER, or PSSWD_USER
  FOR s IN (SELECT synonym_name FROM dba_synonyms WHERE owner = 'PUBLIC' AND table_owner IN ('HDBDBA', 'DECODES', 'CP_PROCESS', 'APP_USER', 'PSSWD_USER', 'CZAR_USER', 'META_DATA_USER')) LOOP
    EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM ' || s.synonym_name;
  END LOOP;

  -- 4. Drop Public Database Links (Modify link names if specific ones exist)
  -- FOR l IN (SELECT db_link FROM dba_db_links WHERE owner = 'PUBLIC' AND db_link IN ('YOUR_DB_LINK_NAME')) LOOP
  --   EXECUTE IMMEDIATE 'DROP PUBLIC DATABASE LINK ' || l.db_link;
  -- END LOOP;
  
  -- 5. Drop Flyway history if it exists
  FOR t IN (SELECT table_name FROM dba_tables WHERE owner = 'SYS' AND table_name = 'FLYWAY_SCHEMA_HISTORY') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE SYS.FLYWAY_SCHEMA_HISTORY CASCADE CONSTRAINTS';
  END LOOP;
END;
/
exit;
