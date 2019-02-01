-- 创建bi用户
create user bi with password 'bell_ea_password';
-- 创建架构
create schema tm_bi authorization bi;

-- 授权查询
grant usage on schema ea to bi;
grant usage on schema tm to bi;

--
grant select on tm_bi.user       to bi;    ----用户表
grant select on tm_bi.department to bi;    ----部门表
grant select on tm_bi.user_role  to bi;    ----角色表
grant select on tm_bi.student    to bi;    ----学生表	
