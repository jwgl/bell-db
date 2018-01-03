-- 创建用户
create user tm_dual with password 'bell_tm_dual_password';

-- 创建架构
create schema tm_dual authorization tm_dual;

-- 创建外部服务器
create server zf_print foreign data wrapper oracle_fdw options (dbserver '//localhost/zf_print');

-- 授权用户可以使用
grant usage on foreign server zf_print to tm_dual;

-- 创建用户映射
create user mapping for tm_dual server zf_print options (user 'zf_print',password 'zf_print_password');

-- 自助打印系统学生名单，用于学生打印四分制成绩单
drop foreign table if exists tm_dual.et_dualdegree_student;
create foreign table tm_dual.et_dualdegree_student(
    id integer, 
    student_id varchar(20), 
    student_name varchar(50), 
    date_created timestamp, 
    date_deleted timestamp, 
    creator varchar(20), 
    deleter varchar(20), 
    enabled boolean, 
    region varchar(20)
) server zf_print options (schema 'BNUEP_PRINT', table 'T_ZZ_XSMD');

-- 自助打印系统教学计划号与项目名称对应表，用于学生打印四分制成绩单
drop foreign table if exists tm_dual.et_dualdegree_major_region;
create foreign table tm_dual.et_dualdegree_major_region(
    major_id varchar(10), 
    region varchar(50)
) server zf_print options (schema 'BNUEP_PRINT', table 'T_TMS_PROJECT');

