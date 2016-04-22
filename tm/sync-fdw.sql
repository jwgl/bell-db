--- 用户
DROP FOREIGN TABLE IF EXISTS tm.sv_system_user;
CREATE FOREIGN TABLE tm.sv_system_user (
    id varchar(10),
    name varchar(50),
    login_name varchar(20),
    password varchar(100),
    email varchar(50),
    long_phone varchar(80),
    enabled boolean,
    user_type integer,
    department_id varchar(2)
) SERVER zf OPTIONS (schema 'TM', table 'SV_SYSTEM_USER');