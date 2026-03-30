-- Final check for invalid objects in HDBDBA and DECODES schemas
SELECT owner, object_type, object_name 
FROM dba_objects 
WHERE status = 'INVALID' AND owner IN ('HDBDBA', 'DECODES')
ORDER BY owner, object_type, object_name;
