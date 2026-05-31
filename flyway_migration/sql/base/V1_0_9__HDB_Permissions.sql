ALTER USER psswd_user QUOTA UNLIMITED ON HDB_idx;
ALTER SESSION SET CURRENT_SCHEMA = psswd_user;
-- set echo on
-- set feedback on
-- spool create_role_psswd.out

/* Run as psswd_user */
--drop table role_psswd;
BEGIN EXECUTE IMMEDIATE '
create table role_psswd (
role varchar2 (30) NOT NULL,
psswd varchar2 (30) NOT NULL
)
pctfree 10
pctused 40
tablespace HDB_data
storage (initial 500k
         next     50k
         pctincrease 25)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE '
alter table role_psswd add (constraint
    role_psswd_pk
    primary key (role)
using index storage(initial 70k next 70k pctincrease 0) tablespace HDB_idx)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

	

/* Insert needed rows */
insert into role_psswd values ('app_role', 'hdb_app_');
insert into role_psswd values ('ref_meta_role', 'ref_meta_');
insert into role_psswd values ('hdb_meta_role', 'hdb_meta_');

/* supposidely removed by C.  Marra during Model Run Project
insert into role_psswd values ('model_role', 'hdb_model_');
*/
/*  insert into role_psswd values ('derivation_role', 'hdb_derivation_'); removed for cp project  */

-- spool off

-- exit;

-- set echo on

create or replace procedure
             check_valid_role_name
              (role      varchar2)
IS
      role_exists integer;
BEGIN
      SELECT count(*)
      INTO role_exists
      FROM sys.user$
      WHERE name = upper (role)
        AND type# = 0;
      if (role_exists = 0) then
            raise_application_error(-20002,' Integrity Failure: Illegal value for role = ' || role);
      end if;
end;
/
-- show errors;
BEGIN EXECUTE IMMEDIATE '
grant execute on check_valid_role_name to public'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- exit;
-- set echo on

create or replace trigger role_psswd_fk
after             insert or update of role
on                role_psswd
for   each row
begin
     check_valid_role_name
 (:new.role);
end;
/
-- show errors trigger unit_chk_val_spec;

-- exit;
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON psswd_user.role_psswd TO PUBLIC'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM role_psswd FOR psswd_user.role_psswd'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON psswd_user.check_valid_role_name TO ${hdb_user}'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
