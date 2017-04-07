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
with admin_class_at_school as (
    select ac.supervisor_id, ac.counsellor_id
    from ea.admin_class ac
    join ea.major m on ac.major_id = m.id
    join ea.subject s on m.subject_id = s.id
    where current_date < make_date(grade + length_of_schooling, 7, 1)
)
select t.id as user_id, 'ROLE_IN_SCHOOL_TEACHER' as role_id
from ea.teacher t
where t.at_school = true
union all
select t.id as user_id, 'ROLE_SUBJECT_DIRECTOR' as role_id
from ea.teacher t
where exists(select * from tm.subject_settings where director_id = t.id)
union all
select t.id as user_id, 'ROLE_SUBJECT_SECRETARY' as role_id
from ea.teacher t
where exists(select * from tm.subject_settings where secretary_id = t.id)
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
)
union all
select t.id as user_id, 'ROLE_PLACE_BOOKING_CHECKER' as role_id
from ea.teacher t
join booking_auth ba on ba.checker_id = t.id
union all
select t.id as user_id, 'ROLE_CLASS_SUPERVISOR' as role_id
from ea.teacher t
where exists(select * from admin_class_at_school where supervisor_id = t.id)
union all
select t.id as user_id, 'ROLE_STUDENT_COUNSELLOR' as role_id
from ea.teacher t
where exists(select * from admin_class_at_school where counsellor_id = t.id)
;

create or replace view tm.dv_student_role as
select s.id as user_id, 'ROLE_IN_SCHOOL_STUDENT' as role_id
from ea.student s
where s.at_school = true
union all
select s.id as user_id, 'ROLE_POSTPONED_STUDENT' as role_id
from ea.student s
where s.at_school = false
and exists (
    select *
    from ea.course_class
    join ea.task on task.course_class_id = course_class.id
    join ea.task_student on task_student.task_id = task.id
    join ea.term on term.id = course_class.term_id
    where task_student.student_id = s.id
    and ea.course_class.term_id =  (select id from ea.term where active = true)
)
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

-- 直接获取的同步视图，计划-课程
create or replace view tm.dv_program_course as
select * from ea.sv_program_course;

-- 学生出勤情况视图
create or replace view tm.dv_student_attendance as
with free_listen as (
  select form.id as form_id, course_class.term_id, form.student_id, item.task_schedule_id
  from tm.free_listen_form form
  join tm.free_listen_item item on item.form_id = form.id
  join ea.task_schedule on item.task_schedule_id = task_schedule.id
  join ea.task on task_schedule.task_id = task.id
  join ea.course_class on task.course_class_id = course_class.id
  where form.status = 'APPROVED'
), student_leave as (
  select form.id as form_id, form.term_id, form.approver_id, form.student_id, item.week, task_schedule.id as task_schedule_id
  from tm.student_leave_form form
  join tm.student_leave_item item on form.id = item.form_id
  join ea.task_student on form.student_id = task_student.student_id
  join ea.task on task_student.task_id = task.id
  join ea.course_class on task.course_class_id = course_class.id and form.term_id = course_class.term_id
  join ea.task_schedule on task_schedule.task_id = task.id
   and (
     item.task_schedule_id = task_schedule.id or
     item.day_of_week = task_schedule.day_of_week or
     item.day_of_week is null and item.task_schedule_id is null
   )
   and item.week between task_schedule.start_week and task_schedule.end_week
   and (
     task_schedule.odd_even = 0 or
     task_schedule.odd_even = 1 and item.week % 2 = 1 or
     task_schedule.odd_even = 2 and item.week % 2 = 0
   )
  where form.status in ('APPROVED', 'FINISHED')
)
select course_class.term_id,
       rollcall.student_id,
       rollcall.week,
       rollcall.task_schedule_id,
       rollcall.type,
       student_leave.form_id as student_leave_form_id,
       free_listen.form_id as free_listen_form_id,
       student_leave.form_id is null and free_listen.form_id is null as valid,
       rollcall.teacher_id       
from tm.rollcall
join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
join ea.task_student on task.id = task_student.task_id and rollcall.student_id = task_student.student_id
join ea.course_class on task.course_class_id = course_class.id
left join student_leave on (
  rollcall.student_id       = student_leave.student_id and
  rollcall.week             = student_leave.week and
  rollcall.task_schedule_id = student_leave.task_schedule_id
)
left join free_listen on (
  rollcall.student_id       = free_listen.student_id and
  rollcall.task_schedule_id = free_listen.task_schedule_id
)
union all
select student_leave.term_id,
       student_leave.student_id,
       student_leave.week,
       student_leave.task_schedule_id,
       4, -- type
       student_leave.form_id, -- student-leave id
       free_listen.form_id, -- free-listen id
       free_listen.form_id is null as valid, -- valid
       student_leave.approver_id --teacher_id
from student_leave
left join free_listen on (
  student_leave.student_id       = free_listen.student_id and
  student_leave.task_schedule_id = free_listen.task_schedule_id
);
