-- 用户视图
create or replace view tm.bi_user as
select u.* from tm.system_user u
join ea.teacher t on u.id = t.id
where not account_expired and not account_locked and enabled;

alter table tm.bi_user owner to tm;

-- 用户角色视图
create or replace view tm.bi_user_role as
select user_id, role_id from tm.dv_teacher_role
union all
select distinct user_id, role_id from tm.user_role;

alter table tm.bi_user_role owner to tm;

-- 部门视图
create or replace view tm.bi_department as
select * from ea.department where enabled;

alter table tm.bi_department owner to tm;
