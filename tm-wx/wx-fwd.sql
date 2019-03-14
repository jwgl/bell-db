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