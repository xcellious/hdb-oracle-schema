-- Check for compilation errors
SELECT name, type, text 
FROM dba_errors 
WHERE owner IN ('HDBDBA', 'DECODES') 
ORDER BY owner, name, type, line;
