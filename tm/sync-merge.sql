/**
 * database bell/tm
 */

-- 用户表
insert into tm.system_user(id, name, login_name, password, email, long_phone, enabled, user_type, department_id)
select u1.id, u1.name, u1.login_name, u1.password, u1.email, u1.long_phone, u1.enabled, u1.user_type, u1.department_id
from tm.sv_system_user u1
left join tm.system_user u2 on u1.id = u2.id
on conflict(id) do update set
name          = EXCLUDED.name,
login_name    = EXCLUDED.login_name,
password      = EXCLUDED.password,
email         = coalesce(system_user.email, EXCLUDED.email),
long_phone    = coalesce(system_user.long_phone, EXCLUDED.long_phone),
enabled       = EXCLUDED.enabled,
user_type     = EXCLUDED.user_type,
department_id = EXCLUDED.department_id;

 -- 教学场地-允许借用用户类型
insert into tm.place_user_type(place_id, user_type)
select place_id, user_type from tm.sv_place_user_type
on conflict(place_id, user_type) do nothing;

update tm.system_user
set enabled = false
where id not in (
	select id from tm.sv_system_user
	union
	select '61500'
);
