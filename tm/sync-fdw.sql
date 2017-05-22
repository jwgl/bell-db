/**
 * database bell/tm
 */

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

-- 教学计划-课程，用于插入ZF
DROP FOREIGN TABLE IF EXISTS tm.et_program_course;
CREATE FOREIGN TABLE tm.et_program_course (
    program_id integer,
    course_id char(8),
    period_theory numeric(3, 1),
    period_experiment numeric(3, 1),
    period_weeks integer,
    is_compulsory boolean,
    is_practical boolean,
    property_id integer,
    assess_type integer,
    test_type integer,
    start_week integer,
    end_week integer,
    suggested_term integer,
    allowed_term integer,
    schedule_type integer,
    department_id char(2),
    direction_id integer
) SERVER zf OPTIONS (schema 'TM', table 'IV_PROGRAM_COURSE');

DROP FOREIGN TABLE IF EXISTS tm.et_booking_form;
CREATE FOREIGN TABLE tm.et_booking_form (
    id varchar(40) OPTIONS (key 'true'),
    form_id integer,
    school_year char(9),
    term char(1),
    place_id char(6),
    place_name varchar(20),
    start_week integer,
    end_week integer,
    odd_even char(1),
    day_of_week integer,
    start_section integer,
    total_section integer,
    section_name varchar(14),
    department_name varchar(50),
    user_id varchar(10),
    user_name varchar(30),
    user_phone varchar(15), 
    reason varchar(200),
    booking_date varchar(40),
    checker_phone varchar(15),
    approver_id char(6),
    source varchar(4),
    status char(1)
) SERVER zf OPTIONS (schema 'TM', table 'IV_BOOKING_FORM');
