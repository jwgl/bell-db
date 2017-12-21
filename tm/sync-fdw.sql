/**
 * database bell/tm
 */

-- 用户
drop foreign table if exists tm.sv_system_user;
create foreign table tm.sv_system_user (
    id varchar(10),
    name varchar(50),
    login_name varchar(20),
    password varchar(100),
    email varchar(50),
    long_phone varchar(80),
    enabled boolean,
    user_type integer,
    department_id varchar(2)
) server zf options (schema 'TM', table 'SV_SYSTEM_USER');

-- 教学场地-允许借用用户类型
drop foreign table if exists tm.sv_place_user_type;
create foreign table tm.sv_place_user_type (
    place_id char(6),
    user_type integer
) server zf options (schema 'TM', table 'SV_PLACE_USER_TYPE', readonly 'true');

-- 教学场地-当前使用情况
drop foreign table if exists tm.ev_place_usage;
create foreign table tm.ev_place_usage (
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
) server zf options (schema 'TM', table 'DV_PLACE_USAGE', readonly 'true');

-- 教学计划-课程，用于插入ZF
drop foreign table if exists tm.et_program_course;
create foreign table tm.et_program_course (
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
) server zf options (schema 'TM', table 'IV_PROGRAM_COURSE');

-- 教学场地借用，用于插入ZF
drop foreign table if exists tm.et_booking_form;
create foreign table tm.et_booking_form (
    id varchar(40) options (key 'true'),
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
) server zf options (schema 'TM', table 'IV_BOOKING_FORM');

-- 学生选课，用于查询选课状态。
-- 由于oracle 11限制，将test_scheduled和locked合并到et_task_student中
-- 更新时会产生异常。
drop foreign table if exists tm.dv_task_student;
create foreign table tm.dv_task_student (
    task_code varchar(31) options (key 'true'),
    student_id varchar(10) options (key 'true'),
    exam_flag varchar(10),
    operator varchar(5),
    test_scheduled boolean,
    score_committed boolean
) server zf options (schema 'TM', table 'DV_TASK_STUDENT');

-- 学生选课，用于更新取消考试资格
drop foreign table if exists tm.et_task_student;
create foreign table tm.et_task_student (
    task_code varchar(31) options (key 'true'),
    student_id varchar(10) options (key 'true'),
    exam_flag varchar(10),
    operator varchar(5)
) server zf options (schema 'TM', table 'IV_TASK_STUDENT');

-- 自助打印系统学生名单，用于学生打印四分制成绩单
drop foreign table if exists tm.et_dualdegree_student;
create foreign table tm.et_dualdegree_student(
    id integer, 
    student_id varchar(20), 
    student_name varchar(50), 
    add_date timestamp, 
    delete_date timestamp, 
    add_operator varchar(20), 
    delete_operator varchar(20), 
    is_dualdegree integer, 
    region varchar(20)
) server zf_print options (schema 'BNUEP_PRINT', table 'T_ZZ_XSMD');

-- 自助打印系统教学计划号与项目名称对应表，用于学生打印四分制成绩单
drop foreign table if exists tm.et_dualdegree_major_region;
create foreign table tm.et_dualdegree_major_region(
    major_id varchar(10), 
    region varchar(50)
) server zf_print options (schema 'BNUEP_PRINT', table 'T_TMS_PROJECT');
