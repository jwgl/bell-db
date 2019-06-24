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
    score_number integer
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
