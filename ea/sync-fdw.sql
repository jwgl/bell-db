-- 新建数据库
> createdb -Upostgres bell

-- 使用psql登录
> psql -Upostgres bell

-- 创建用户
create user ea with password 'bell_ea_password';
create user tm with password 'bell_tm_password';

-- 创建架构
create schema ea authorization ea;
create schema tm authorization tm;

-- 创建外部数据封装器
create extension oracle_fdw;

-- 创建外部服务器
create server zf foreign data wrapper oracle_fdw options (dbserver '//localhost/zf');

-- 授权用户可以使用
grant usage on foreign server zf to ea;
grant usage on foreign server zf to tm;

-- 创建用户映射
create user mapping for ea server zf options (user 'ea',password 'zf_ea_password');
create user mapping for tm server zf options (user 'tm',password 'zf_tm_password');

-- 创建外部表
\c bell ea

-- 学期
drop foreign table if exists ea.sv_term;
create foreign table ea.sv_term (
    id integer,
    start_date date,
    start_week integer,
    mid_left integer,
    mid_right integer,
    end_week integer,
    max_week integer
) server zf options (schema 'EA', table 'TERM', readonly 'true');

-- 学院
drop foreign table if exists ea.sv_department;
create foreign table ea.sv_department (
    id char(2),
    name varchar(30),
    english_name varchar(60),
    short_name varchar(20),
    is_teaching boolean,
    has_students boolean,
    enabled boolean
) server zf options (schema 'EA', table 'SV_DEPARTMENT', readonly 'true');

-- 场地
drop foreign table if exists ea.sv_place;
create foreign table ea.sv_place (
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
) server zf options (schema 'EA', table 'SV_PLACE', readonly 'true');

-- 教学场地-允许使用单位
drop foreign table if exists ea.sv_place_department;
create foreign table ea.sv_place_department (
    place_id char(6),
    department_id varchar(2)
) server zf options (schema 'EA', table 'SV_PLACE_DEPARTMENT', readonly 'true');

-- 教学场地-允许借用学期
drop foreign table if exists ea.sv_place_booking_term;
create foreign table ea.sv_place_booking_term (
    place_id char(6),
    term_id integer
) server zf options (schema 'EA', table 'SV_PLACE_BOOKING_TERM', readonly 'true');

-- 学科门类
drop foreign table if exists ea.sv_discipline;
create foreign table ea.sv_discipline (
    id numeric(6),
    code char(2),
    name varchar(10)
) server zf options (schema 'EA', table 'DISCIPLINE', readonly 'true');

-- 专业类
drop foreign table if exists ea.sv_field_class;
create foreign table ea.sv_field_class (
    id numeric(8),
    discipline_id numeric(6),
    code char(4),
    name varchar(20)
) server zf options (schema 'EA', table 'FIELD_CLASS', readonly 'true');

-- 专业目录
drop foreign table if exists ea.sv_field;
create foreign table ea.sv_field (
    id numeric(10),
    field_class_id numeric(8),
    code char(6),
    name varchar(50),
    flag varchar(2)
) server zf options (schema 'EA', table 'FIELD', readonly 'true');

-- 专业目录
drop foreign table if exists ea.sv_field_allow_degree;
create foreign table ea.sv_field_allow_degree (
    field_id numeric(10),
    discipline_id numeric(6)
) server zf options (schema 'EA', table 'FIELD_ALLOW_DEGREE', readonly 'true');

-- 校内专业
drop foreign table if exists ea.sv_subject;
create foreign table ea.sv_subject (
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
) server zf options (schema 'EA', table 'SV_SUBJECT', readonly 'true');

-- 校内专业
drop foreign table if exists ea.sv_major;
create foreign table ea.sv_major (
    id integer,
    subject_id char(4),
    grade integer,
    candidate_type integer,
    field_id numeric(10),
    degree_id numeric(6),
    department_id char(2)
) server zf options (schema 'EA', table 'SV_MAJOR', readonly 'true');

-- 专业方向
drop foreign table if exists ea.sv_direction;
create foreign table ea.sv_direction (
    id integer,
    program_id integer,
    name varchar(30)
) server zf options (schema 'EA', table 'SV_DIRECTION', readonly 'true');

-- 教学计划
drop foreign table if exists ea.sv_program;
create foreign table ea.sv_program (
    id integer,
    type integer,
    major_id integer,
    credit integer
) server zf options (schema 'EA', table 'SV_PROGRAM', readonly 'true');

-- 课程性质
drop foreign table if exists ea.sv_property;
create foreign table ea.sv_property (
    id integer,
    name varchar(20),
    short_name varchar(6),
    is_compulsory boolean,
    is_primary boolean
) server zf options (schema 'EA', table 'SV_PROPERTY', readonly 'true');

-- 教学计划-课程性质
drop foreign table if exists ea.sv_program_property;
create foreign table ea.sv_program_property (
    program_id integer,
    property_id integer,
    credit integer,
    is_weighted boolean
) server zf options (schema 'EA', table 'SV_PROGRAM_PROPERTY', readonly 'true');

-- 课程
drop foreign table if exists ea.sv_course;
create foreign table ea.sv_course (
    id char(8),
    name varchar(100),
    english_name varchar(120),
    credit numeric(3, 1),
    period_theory numeric(3, 1),
    period_experiment numeric(3, 1),
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
) server zf options (schema 'EA', table 'SV_COURSE', readonly 'true');

-- 课程项目
drop foreign table if exists ea.sv_course_item;
create foreign table ea.sv_course_item (
    id char(10),
    name varchar(100),
    ordinal integer,
    is_primary boolean,
    course_id char(8),
    task_course_id char(8)
) server zf options (schema 'EA', table 'SV_COURSE_ITEM', readonly 'true');

-- 教学计划-课程
drop foreign table if exists ea.sv_program_course;
create foreign table ea.sv_program_course (
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
) server zf options (schema 'EA', table 'SV_PROGRAM_COURSE', readonly 'true');

-- 教师
drop foreign table if exists ea.sv_teacher;
create foreign table ea.sv_teacher (
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
) server zf options (schema 'EA', table 'SV_TEACHER', readonly 'true');

-- 行政班
drop foreign table if exists ea.sv_admin_class;
create foreign table ea.sv_admin_class (
    id bigint,
    name varchar(50),
    major_id integer,
    department_id char(2),
    supervisor_id char(5),
    counsellor_id char(5)
) server zf options (schema 'EA', table 'SV_ADMIN_CLASS', readonly 'true');

-- 录取信息
drop foreign table if exists ea.sv_admission;
create foreign table ea.sv_admission (
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
) server zf options (schema 'EA', table 'SV_ADMISSION', readonly 'true');

-- 学生
drop foreign table if exists ea.sv_student;
create foreign table ea.sv_student (
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
    is_registered boolean,
    train_range varchar(50),
    category integer,
    foreign_language char(2),
    foreign_language_level integer,
    change_type integer,
    department_id char(2),
    admin_class_id bigint,
    major_id integer,
    direction_id integer,
    admission_id bigint
) server zf options (schema 'EA', table 'SV_STUDENT', readonly 'true');

-- 学生-等级
drop foreign table if exists ea.sv_student_level;
create foreign table ea.sv_student_level (
    student_id char(10),
    type varchar(20),
    level integer
) server zf options (schema 'EA', table 'SV_STUDENT_LEVEL');

-- 板块课程
drop foreign table if exists ea.sv_timeplate_course;
create foreign table ea.sv_timeplate_course (
    id char(3),
    course_id char(8)
) server zf options (schema 'EA', table 'SV_TIMEPLATE_COURSE');

-- 排课板块
drop foreign table if exists ea.sv_timeplate;
create foreign table ea.sv_timeplate (
    id bigint,
    term_id integer,
    course_id char(10),
    grade integer,
    ordinal integer,
    name text
) server zf options (schema 'EA', table 'SV_TIMEPLATE');

-- 排课板块-时段
drop foreign table if exists ea.sv_timeplate_slot;
create foreign table ea.sv_timeplate_slot (
    timeplate_id bigint,
    odd_even integer,
    day_of_week integer,
    start_section integer,
    total_section integer
) server zf options (schema 'EA', table 'SV_TIMEPLATE_SLOT');

-- 排课板块-行政班
drop foreign table if exists ea.sv_timeplate_admin_class;
create foreign table ea.sv_timeplate_admin_class (
    timeplate_id bigint,
    admin_class_id bigint
) server zf options (schema 'EA', table 'SV_TIMEPLATE_ADMIN_CLASS');

-- 排课板块-任务
drop foreign table if exists ea.sv_timeplate_task;
create foreign table ea.sv_timeplate_task (
    id bigint,
    timeplate_id bigint,
    start_week integer,
    end_week integer,
    period integer,
    course_item_id char(10)
) server zf options (schema 'EA', table 'SV_TIMEPLATE_TASK');

-- 教学班ID映射，使用insert触发
drop foreign table if exists ea.sv_course_class_map;
create foreign table ea.sv_course_class_map (
    term_id numeric(5),
    course_class_id uuid,
    course_class_code varchar(31),
    date_created timestamp
) server zf options (schema 'EA', table 'SV_COURSE_CLASS_MAP');

-- 教学任务ID映射实体表，使用insert触发
drop foreign table if exists ea.sv_task_map;
create foreign table ea.sv_task_map (
    term_id numeric(5),
    task_id uuid,
    task_code varchar(31),
    course_item_id char(10),
    date_created timestamp
) server zf options (schema 'EA', table 'SV_TASK_MAP');

-- 教学班
drop foreign table if exists ea.sv_course_class;
create foreign table ea.sv_course_class (
    term_id numeric(5),
    id uuid,
    code varchar(31),
    name varchar(50),
    period_theory numeric(3, 1),
    period_experiment numeric(3, 1),
    period_weeks integer,
    property_id integer,
    assess_type integer,
    test_type integer,
    start_week integer,
    end_week integer,
    course_id char(8),
    department_id char(2),
    teacher_id char(5),
    timeplate_id bigint
) server zf options (schema 'EA', table 'SV_COURSE_CLASS', readonly 'true');

-- 教学班-选课条件
drop foreign table if exists ea.sv_course_class_condition;
create foreign table ea.sv_course_class_condition (
    term_id numeric(5),
    course_class_id uuid,
    include boolean,
    condition_group integer,
    condition_name text,
    condition_value text
) server zf options (schema 'EA', table 'SV_COURSE_CLASS_CONDITION', readonly 'true');

-- 教学班-计划
drop foreign table if exists ea.sv_course_class_program;
create foreign table ea.sv_course_class_program (
    term_id numeric(5),
    course_class_id uuid,
    program_id integer
) server zf options (schema 'EA', table 'SV_COURSE_CLASS_PROGRAM', readonly 'true');

-- 教学任务
drop foreign table if exists ea.sv_task;
create foreign table ea.sv_task (
    term_id numeric(5),
    id uuid,
    code varchar(31),
    is_primary boolean,
    start_week integer,
    end_week integer,
    course_item_id char(10),
    course_class_id uuid
) server zf options (schema 'EA', table 'SV_TASK', readonly 'true');

-- 教学任务-教师
drop foreign table if exists ea.sv_task_teacher;
create foreign table ea.sv_task_teacher (
    term_id numeric(5),
    task_id uuid,
    teacher_id char(5)
) server zf options (schema 'EA', table 'SV_TASK_TEACHER', readonly 'true');

-- 教学安排
drop foreign table if exists ea.sv_task_schedule;
create foreign table ea.sv_task_schedule (
    term_id numeric(5),
    id uuid,
    task_id uuid,
    teacher_id char(5),
    place_id char(6),
    start_week integer,
    end_week integer,
    odd_even integer,
    day_of_week integer,
    start_section integer,
    total_section integer,
    root_id uuid
) server zf options (schema 'EA', table 'SV_TASK_SCHEDULE', readonly 'true');

-- 学生选课
drop foreign table if exists ea.sv_task_student;
create foreign table ea.sv_task_student (
    term_id numeric(5),
    task_id uuid,
    student_id char(10),
    date_created timestamp,
    register_type integer,
    repeat_type integer,
    exam_flag integer
) server zf options (schema 'EA', table 'SV_TASK_STUDENT', readonly 'true');
