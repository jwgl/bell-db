-- 新建数据库
> createdb -Upostgres bell

-- 使用psql登录
> psql -Upostgres bell

-- 创建用户
CREATE USER ea WITH PASSWORD 'ea';
CREATE USER tm WITH PASSWORD 'tm';

-- 创建架构
CREATE SCHEMA ea AUTHORIZATION ea;
CREATE SCHEMA tm AUTHORIZATION tm;

-- 创建外部数据封装器
CREATE EXTENSION oracle_fdw;

-- 创建外部服务器
CREATE SERVER zf FOREIGN DATA WRAPPER oracle_fdw OPTIONS (dbserver '//localhost/jw');

-- 授权用户可以使用
GRANT USAGE ON FOREIGN SERVER zf TO ea;
GRANT USAGE ON FOREIGN SERVER zf TO tm;

-- 创建用户映射
CREATE USER MAPPING FOR ea SERVER zf OPTIONS (user 'ea',password 'ea');
CREATE USER MAPPING FOR tm SERVER zf OPTIONS (user 'tm',password 'tm');

-- 创建外部表

--- 学期
DROP FOREIGN TABLE IF EXISTS ea.sv_term;
CREATE FOREIGN TABLE ea.sv_term (
    id integer,
    start_date date,
    start_week integer,
    mid_left integer,
    mid_right integer,
    end_week integer,
    max_week integer
) SERVER zf OPTIONS (schema 'EA', table 'TERM');

--- 学院
DROP FOREIGN TABLE IF EXISTS ea.sv_department;
CREATE FOREIGN TABLE ea.sv_department (
    id char(2),
    name varchar(30),
    english_name varchar(60),
    short_name varchar(20),
    is_teaching	boolean,
    has_students boolean,
    enabled	boolean
) SERVER zf OPTIONS (schema 'EA', table 'SV_DEPARTMENT');

--- 场地
DROP FOREIGN TABLE IF EXISTS ea.sv_place;
CREATE FOREIGN TABLE ea.sv_place (
    id char(6),
    name varchar(20),
    english_name varchar(20),
    type varchar(20),
    seat integer,
    test_seat integer,
    building varchar(8),
    enabled boolean,
    can_test boolean,
    booking_term integer,
    booking_user integer,
    is_external boolean,
    note varchar(200)
) SERVER zf OPTIONS (schema 'EA', table 'SV_PLACE');

--- 教学场地-允许使用单位
DROP FOREIGN TABLE IF EXISTS ea.sv_place_department;
CREATE FOREIGN TABLE ea.sv_place_department (
    place_id char(6),
    department_id varchar(2)
) SERVER zf OPTIONS (schema 'EA', table 'SV_PLACE_DEPARTMENT');

--- 教学场地-允许借用学期
DROP FOREIGN TABLE IF EXISTS ea.sv_place_booking_term;
CREATE FOREIGN TABLE ea.sv_place_booking_term (
    place_id char(6),
    term_id integer
) SERVER zf OPTIONS (schema 'EA', table 'SV_PLACE_BOOKING_TERM');

--- 教学场地-允许借用用户类型
DROP FOREIGN TABLE IF EXISTS ea.sv_place_booking_user_type;
CREATE FOREIGN TABLE ea.sv_place_booking_user_type (
    place_id char(6),
    user_type integer
) SERVER zf OPTIONS (schema 'EA', table 'SV_PLACE_BOOKING_USER_TYPE');

--- 学科门类
DROP FOREIGN TABLE IF EXISTS ea.sv_discipline;
CREATE FOREIGN TABLE ea.sv_discipline (
    id numeric(6),
    code char(2),
    name varchar(10)
) SERVER zf OPTIONS (schema 'EA', table 'DISCIPLINE');

--- 专业类
DROP FOREIGN TABLE IF EXISTS ea.sv_field_class;
CREATE FOREIGN TABLE ea.sv_field_class (
    id numeric(8),
    discipline_id numeric(6),
    code char(4),
    name varchar(20)
) SERVER zf OPTIONS (schema 'EA', table 'FIELD_CLASS');

--- 专业目录
DROP FOREIGN TABLE IF EXISTS ea.sv_field;
CREATE FOREIGN TABLE ea.sv_field (
    id numeric(10),
    field_class_id numeric(8),
    code char(6),
    name varchar(50),
    flag varchar(2)
) SERVER zf OPTIONS (schema 'EA', table 'FIELD');

--- 专业目录
DROP FOREIGN TABLE IF EXISTS ea.sv_field_allow_degree;
CREATE FOREIGN TABLE ea.sv_field_allow_degree (
    field_id numeric(10),
    discipline_id numeric(6)
) SERVER zf OPTIONS (schema 'EA', table 'FIELD_ALLOW_DEGREE');

--- 校内专业
DROP FOREIGN TABLE IF EXISTS ea.sv_subject;
CREATE FOREIGN TABLE ea.sv_subject (
    id char(4),
    name varchar(4000),
    english_name varchar(70),
    short_name varchar(4000),
    education_level integer,
    length_of_schooling integer,
    stop_enroll boolean,
    is_joint_program boolean,
    is_dual_degree boolean,
    is_top_up boolean,
    field_id numeric(10),
    degree_id numeric(6),
    department_id char(2)
) SERVER zf OPTIONS (schema 'EA', table 'SV_SUBJECT');

--- 校内专业
DROP FOREIGN TABLE IF EXISTS ea.sv_major;
CREATE FOREIGN TABLE ea.sv_major (
    id integer,
    subject_id char(4),
    grade integer,
    candidate_type integer,
    field_id numeric(10),
    degree_id numeric(6),
    department_id char(2)
) SERVER zf OPTIONS (schema 'EA', table 'SV_MAJOR');

--- 专业方向
DROP FOREIGN TABLE IF EXISTS ea.sv_direction;
CREATE FOREIGN TABLE ea.sv_direction (
    id integer,
    program_id integer,
    name varchar(30)
) SERVER zf OPTIONS (schema 'EA', table 'SV_DIRECTION');

--- 教学计划
DROP FOREIGN TABLE IF EXISTS ea.sv_program;
CREATE FOREIGN TABLE ea.sv_program (
    id integer,
    type integer,
    major_id integer,
    credit integer
) SERVER zf OPTIONS (schema 'EA', table 'SV_PROGRAM');

--- 课程性质
DROP FOREIGN TABLE IF EXISTS ea.sv_property;
CREATE FOREIGN TABLE ea.sv_property (
    id integer,
    name varchar(20),
    short_name varchar(6),
    is_compulsory boolean,
    is_primary boolean
) SERVER zf OPTIONS (schema 'EA', table 'SV_PROPERTY');

--- 教学计划-课程性质
DROP FOREIGN TABLE IF EXISTS ea.sv_program_property;
CREATE FOREIGN TABLE ea.sv_program_property (
    program_id integer,
    property_id integer,
    credit integer,
    is_weighted boolean
) SERVER zf OPTIONS (schema 'EA', table 'SV_PROGRAM_PROPERTY');

--- 课程
DROP FOREIGN TABLE IF EXISTS ea.sv_course;
CREATE FOREIGN TABLE ea.sv_course (
    id char(8),
    name varchar(100),
    english_name varchar(120),
    credit numeric(3, 1),
    period_theory integer,
    period_experiment integer,
    period_weeks integer,
    property_id integer,
    is_compulsory boolean,
    is_practical boolean,
    education_level integer,
    assess_type integer,
    schedule_type integer,
    introduction varchar(2000),
    enabled boolean,
    department_id char(2)
) SERVER zf OPTIONS (schema 'EA', table 'SV_COURSE');


--- 课程项目
DROP FOREIGN TABLE IF EXISTS ea.sv_course_item;
CREATE FOREIGN TABLE ea.sv_course_item (
    id char(10),
    name varchar(100),
    ordinal integer,
    is_primary boolean,
    course_id char(8),
    task_course_id char(8)
) SERVER zf OPTIONS (schema 'EA', table 'SV_COURSE_ITEM');

--- 教学计划-课程
DROP FOREIGN TABLE IF EXISTS ea.sv_program_course;
CREATE FOREIGN TABLE ea.sv_program_course (
    program_id integer,
    course_id char(8),
    period_theory integer,
    period_experiment integer,
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
) SERVER zf OPTIONS (schema 'EA', table 'SV_PROGRAM_COURSE');

--- 教师
DROP FOREIGN TABLE IF EXISTS ea.sv_teacher;
CREATE FOREIGN TABLE ea.sv_teacher (
    id char(5),
    name varchar(50),
    sex char(2),
    birthday date,
    political_status varchar(50),
    nationality varchar(30),
    academic_title varchar(30),
    academic_level varchar(20),
    academic_degree char(4),
    educational_background varchar(28),
    graduate_school varchar(50),
    graduate_major varchar(40),
    date_graduated date,
    post_type varchar(20),
    has_qualification boolean,
    is_lab_technician boolean,
    is_external boolean,
    at_school boolean,
    can_guidance_graduate boolean,
    department_id char(2),
    resume varchar(3000)
) SERVER zf OPTIONS (schema 'EA', table 'SV_TEACHER');

--- 行政班
DROP FOREIGN TABLE IF EXISTS ea.sv_admin_class;
CREATE FOREIGN TABLE ea.sv_admin_class (
    id bigint,
    name varchar(50),
    major_id integer,
    department_id char(2)
) SERVER zf OPTIONS (schema 'EA', table 'SV_ADMIN_CLASS');

--- 录取信息
DROP FOREIGN TABLE IF EXISTS ea.sv_admission;
CREATE FOREIGN TABLE ea.sv_admission (
    id numeric(12),
    student_id char(10),
    subject_id char(4),
    grade integer,
    name varchar(50),
    used_name varchar(20),
    sex char(2),
    birthday date,
    political_status varchar(20),
    nationality varchar(15),
    phone_number varchar(30),
    from_province varchar(20),
    from_city varchar(100),
    home_address varchar(120),
    household_address varchar(50),
    postal_code varchar(10),
    middle_school varchar(50),
    candidate_number varchar(50),
    examination_number varchar(20),
    total_score integer,
    english_score integer,
    id_number varchar(20),
    bank_number varchar(25)
) SERVER zf OPTIONS (schema 'EA', table 'SV_ADMISSION');

--- 学生
DROP FOREIGN TABLE IF EXISTS ea.sv_student;
CREATE FOREIGN TABLE ea.sv_student (
    id char(10),
    password varchar(50),
    name varchar(50),
    pinyin_name varchar(50),
    sex char(2),
    birthday date,
    nationality integer,
    political_status integer,
    grade integer,
    date_enrolled date,
    date_graduated date,
    is_enrolled boolean,
    at_school boolean,
    is_registed boolean,
    train_range varchar(50),
    category integer,
    forign_language char(2),
    forign_language_level integer,
    change_type integer,
    department_id char(2),
    admin_class_id bigint,
    major_id integer,
    direction_id integer,
    admission_id bigint
) SERVER zf OPTIONS (schema 'EA', table 'SV_STUDENT');

--- 教学班
DROP FOREIGN TABLE IF EXISTS ea.sv_course_class;
CREATE FOREIGN TABLE ea.sv_course_class (
    id numeric(13),
    period_theory integer,
    period_experiment integer,
    period_weeks integer,
    property_id integer,
    assess_type integer,
    test_type integer,
    start_week integer,
    end_week integer,
    term_id numeric(5),
    course_id char(8),
    department_id char(2),
    teacher_id char(5),
    original_id varchar(32)
) SERVER zf OPTIONS (schema 'EA', table 'SV_COURSE_CLASS');

--- 教学班-计划
DROP FOREIGN TABLE IF EXISTS ea.sv_course_class_program;
CREATE FOREIGN TABLE ea.sv_course_class_program (
    course_class_id bigint,
    program_id integer
) SERVER zf OPTIONS (schema 'EA', table 'SV_COURSE_CLASS_PROGRAM');

--- 教学任务
DROP FOREIGN TABLE IF EXISTS ea.sv_task;
CREATE FOREIGN TABLE ea.sv_task (
    id bigint,
    is_primary boolean,
    start_week integer,
    end_week integer,
    course_item_id char(10),
    course_class_id bigint,
    original_id varchar(31)
) SERVER zf OPTIONS (schema 'EA', table 'SV_TASK');

--- 教学安排
DROP FOREIGN TABLE IF EXISTS ea.sv_arrangement;
CREATE FOREIGN TABLE ea.sv_arrangement (
    id varchar(32),
    task_id numeric(17),
    teacher_id char(5),
    place_id char(6),
    start_week integer,
    end_week integer,
    odd_even integer,
    day_of_week integer,
    start_section integer,
    total_section integer
) SERVER zf OPTIONS (schema 'EA', table 'SV_ARRANGEMENT');