-- 创建架构
create schema tm_dual authorization tm;

-- 创建外部服务器
create server zf_print foreign data wrapper oracle_fdw options (dbserver '//localhost/zf_print');

-- 授权用户可以使用
grant usage on foreign server zf_print to tm;

-- 创建用户映射
create user mapping for tm server zf_print options (user 'zf_print',password 'zf_print_password');

-- 自助打印系统学生名单，用于学生打印四分制成绩单，为要更新外部表要加options (key 'true')
drop foreign table if exists tm.et_dualdegree_student;
create foreign table tm.et_dualdegree_student(
    id integer options (key 'true'), 
    student_id varchar(20) options (key 'true'), 
    student_name varchar(50), 
    date_created timestamp, 
    date_deleted timestamp, 
    creator varchar(20), 
    deleter varchar(20), 
    enabled boolean, 
    region varchar(20)
) server zf_print options (schema 'BNUEP_PRINT', table 'T_ZZ_XSMD');

CREATE SEQUENCE tm.student_print_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 100283
  CACHE 1;
ALTER TABLE tm.student_print_id_seq
  OWNER TO tm;
ALTER SEQUENCE student_print_id_seq OWNED BY et_dualdegree_student.id;

-- 自助打印系统教学计划号与项目名称对应表，用于学生打印四分制成绩单
drop foreign table if exists tm.et_dualdegree_major_region;
create foreign table tm.et_dualdegree_major_region(
    major_id varchar(10), 
    region varchar(50)
) server zf_print options (schema 'BNUEP_PRINT', table 'T_TMS_PROJECT');

