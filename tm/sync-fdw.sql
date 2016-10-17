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

--- 教学场地-允许借用用户类型
DROP FOREIGN TABLE IF EXISTS tm.sv_place_user_type;
CREATE FOREIGN TABLE tm.sv_place_user_type (
    place_id char(6),
    user_type integer
) SERVER zf OPTIONS (schema 'TM', table 'SV_PLACE_USER_TYPE', readonly 'true');

-- 教学场地-当前使用情况
DROP FOREIGN TABLE IF EXISTS tm.ev_place_usage;
CREATE FOREIGN TABLE tm.ev_place_usage (
    term_id integer,
    place_id varchar(10),
    start_week integer,
    end_week integer,
    odd_even integer,
    day_of_week integer,
    start_section integer,
    total_section integer,
    type varchar(4),
    department  varchar(70),
    description varchar(240)
) SERVER zf OPTIONS (schema 'TM', table 'DV_PLACE_USAGE', readonly 'true');
