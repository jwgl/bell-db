-- 用户视图
create or replace view tm_bi.user as
select u.* from tm.system_user u
join ea.teacher t on u.id = t.id
where not account_expired and not account_locked and enabled;

alter table tm_bi.user owner to tm;

-- 用户角色视图
create or replace view tm_bi.user_role as
select user_id, role_id from tm.dv_teacher_role
union all
select distinct user_id, role_id from tm.user_role;

alter table tm_bi.user_role owner to tm;

-- 部门视图
create or replace view tm_bi.department as
select * from ea.department where enabled;

alter table tm_bi.department owner to tm;

-- 学生视图
create or replace view tm_bi.student as
select s.*, m.grade, sj.name as subject_name
from ea.student s join ea.major m on s.major_id = m.id 
join ea.subject sj on m.subject_id = sj.id 
where at_school;

alter table tm_bi.student owner to tm;
