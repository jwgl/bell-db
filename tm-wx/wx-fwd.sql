-- 创建外部服务器(采用//IP|解析主机名/实例名)
create server wxgzh foreign data wrapper oracle_fdw options (dbserver '//localhost/zf_wx');

-- 授权用户可以使用
grant usage on foreign server wxgzh to tm;

-- 创建用户映射
create user mapping for tm server wxgzh options (user 'wxgzh',password 'wxgzh_password');

-- 学生成绩外部表
drop foreign table if exists tm_wx.et_score;
create foreign table tm_wx.et_score(
    department_name varchar(50), 
    xn varchar(9), 
    xq integer, 
    course_id varchar(50), 
    student_id varchar(10),
    student_name varchar(100), 
    course_name varchar(100), 
    credit varchar(10), 
    score varchar(20),
    score_number numeric(4,1),
    property varchar(20)
) server wxgzh options (schema 'BNUZ_WX', table 'SCORES');

-- 学生等级考试成绩外部表
drop foreign table if exists tm_wx.et_level_exam;
create foreign table tm_wx.et_level_exam(
    xn varchar(9),
    xq integer,
    student_id varchar(10),
    student_name varchar(100),
    exam_name varchar(100),
    date_of_exam varchar(20),
    score varchar(10),
    exam_id varchar(20),
    score_listening varchar(10),
    score_reading varchar(10),
    score_writing varchar(10),
    score_comprehensive varchar(10),
    score_speaking varchar(10),
    exam_speaking_id varchar(20),
    certificate_id varchar(20)
) server wxgzh options (schema 'BNUZ_WX', table 'LEVEL_EXAM');

-- 异动信息外部表
drop foreign table if exists tm_wx.et_major_switch;
create foreign table tm_wx.et_major_switch(
    xn varchar(9),
    xq integer,
    sex varchar(2),
    student_id varchar(10),
    student_name varchar(100),
    class_name varchar(100),
    department_old varchar(50),
    department_new varchar(50),
    major_old varchar(100),
    major_new varchar(100)
) server wxgzh options (schema 'BNUZ_WX', table 'MAJOR_SWITCH');

--四六级监考用户信息外部表
drop foreign table if exists tm_wx.et_cet_teacher;
create foreign table tm_wx.et_cet_teacher(
    id integer,
    name varchar(20),
    teacher_id varchar(20),
    department varchar(50),
    sex varchar(20),
    phone varchar(20)
) server wxgzh options (schema 'BNUZ_WX', table 'CET_USER');

--学生用户信息外部表
drop foreign table if exists tm_wx.et_student;
create foreign table tm_wx.et_student(
    id varchar(20),
    name varchar(50),
    password varchar(50),
    grade integer,
    department varchar(50),
    major varchar(50),
    admin_class varchar(50),
    type varchar(50),
    enroll varchar(5),
    at_school varchar(5)
) server wxgzh options (schema 'BNUZ_WX', table 'STUDENT');

--辅修名单
drop foreign table if exists tm_wx.et_minor;
create foreign table tm_wx.et_minor(
    id varchar(20)
) server wxgzh options (schema 'BNUZ_WX', table 'MINOR');

--出国名单
drop foreign table if exists tm_wx.et_student_abroad;
create foreign table tm_wx.et_student_abroad(
    id varchar(20)
) server wxgzh options (schema 'BNUZ_WX', table 'STUDENT_ABROAD');