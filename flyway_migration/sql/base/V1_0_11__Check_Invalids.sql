-- Final check for invalid objects in ${hdb_user} and DECODES schemas
SELECT owner, object_type, object_name 
FROM dba_objects 
WHERE status = 'INVALID' AND owner IN ('${hdb_user}', 'DECODES')
ORDER BY owner, object_type, object_name;
