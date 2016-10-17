-- 用户表
insert into tm.system_user(id, name, login_name, password, email, long_phone, enabled, user_type, department_id)
select id, name, login_name, password, email, long_phone, enabled, user_type, department_id from tm.sv_system_user
on conflict(id) do update set
name          = EXCLUDED.name,
login_name    = EXCLUDED.login_name,
password      = EXCLUDED.password,
email         = EXCLUDED.email,
long_phone    = EXCLUDED.long_phone,
enabled       = EXCLUDED.enabled,
user_type     = EXCLUDED.user_type,
department_id = EXCLUDED.department_id;

 -- 教学场地-允许借用用户类型
insert into tm.place_user_type(place_id, user_type)
select place_id, user_type from tm.sv_place_user_type
on conflict(place_id, user_type) do nothing;
