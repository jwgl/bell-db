-- 新建数据库
> createdb -Upostgres bell

-- 登录
> psql -Upostgres bell

-- 创建用户
create user ea with password 'bell_ea_password';

-- 创建架构
create schema ea authorization ea;
