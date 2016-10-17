-- 菜单
create or replace view tm.dv_menu as
with recursive r as (
    select m.id, m.name, m.label_cn, m.label_en,
        m.id as root,
        1 as path_level,
        to_char(m.display_order, '09') as display_order
    from tm.menu m
    where array_length(regexp_split_to_array(m.id, E'\\.'), 1) = 1
    union all
    select m.id, m.name, m.label_cn, m.label_en,
        r.root as root,
        array_length(regexp_split_to_array(m.id, E'\\.'), 1),
        r.display_order || to_char(m.display_order, '09')
    from tm.menu m
    join r on strpos(m.id, r.id) = 1 and array_length(regexp_split_to_array(m.id, E'\\.'), 1) = r.path_level + 1
)
select id, name, label_cn, label_en, path_level -1 as menu_level, root from r
where path_level > 1
order by display_order;

-- 应用角色
create or replace view tm.dv_teacher_role as
select t.id as user_id, 'ROLE_IN_SCHOOL_TEACHER' as role_id
from ea.teacher t
where t.at_school = true
union all
select t.id as user_id, 'ROLE_SUBJECT_DIRECTOR' as role_id
from ea.teacher t
where exists(
    select *
    from tm.subject_director
    where subject_director.teacher_id = t.id
)
union all
select t.id as user_id, 'ROLE_COURSE_TEACHER' as role_id
from ea.teacher t
where exists(
    select *
    from ea.course_class
    join ea.task on task.course_class_id = course_class.id
    join ea.task_schedule on task_schedule.task_id = task.id
    where course_class.term_id = (select id from ea.term where active = true)
    and task_schedule.teacher_id = t.id
);

create or replace view tm.dv_student_role as
select s.id as user_id, 'ROLE_IN_SCHOOL_STUDENT' as role_id
from ea.student s
where s.at_school = true
;

create or replace view tm.dv_external_role as
    select '' as userId, '' as role_id where 1 = 2
;
-- 计划-课程
create or replace view tm.dv_scheme_course as
select c.id, c.name, c.credit,
    c.period_theory as theory_period,
    c.period_experiment as experiment_period,
    c.period_weeks as period_weeks,
    c.education_level,
    c.assess_type,
    d.id as department_id,
    coalesce(d.short_name, d.name) as department_name,
    false as is_temp_course
from ea.course c
join ea.department d on c.department_id = d.id
where c.enabled = true
union
select c.id || '', c.name, c.credit,
    c.period_theory as theory_period,
    c.period_experiment as experiment_period,
    c.period_weeks as period_weeks,
    c.education_level,
    c.assess_type,
    d.id as department_id,
    coalesce(d.short_name, d.name) as department_name,
    true as is_temp_course
from tm.temp_course c
join ea.department d on c.department_id = d.id;

-- 补办学生证申请表-统计
create or replace view tm.dv_card_reissue_form_rank as
select id as form_id, rank() over (partition by student_id order by date_created) as rank
from tm.card_reissue_form;

-- 场地使用情况视图
create or replace view tm.dv_place_usage as
select * from ev_place_usage;
