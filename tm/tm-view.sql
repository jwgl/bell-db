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
    union all
    select ac.supervisor_id, ac.counsellor_id
    from ea.admin_class ac
    join ea.major m on ac.major_id = m.id
    join ea.subject s on m.subject_id = s.id
    where current_date >= make_date(grade + length_of_schooling, 7, 1)
    and exists (
      select 1
      from ea.course_class
      join ea.task on course_class.id = task.course_class_id
      join ea.task_student on task_student.task_id = task.id
      join ea.student on student.id = task_student.student_id
      where student.admin_class_id = ac.id
      and ea.course_class.term_id = (select id from ea.term where active = true)
    )
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
select distinct course_class.teacher_id as user_id, case term.active
    when true then 'ROLE_COURSE_CLASS_TEACHER'
    else 'ROLE_ONCE_COURSE_CLASS_TEACHER'
  end as role_id
from ea.course_class
join ea.term on course_class.term_id = term.id
where term.id >= (select value::integer from tm.system_config where key='rollcall.start_term')
union all
select distinct task_schedule.teacher_id as user_id, case term.active
    when true then 'ROLE_TASK_SCHEDULE_TEACHER'
    else 'ROLE_ONCE_TASK_SCHEDULE_TEACHER'
  end as role_id
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.task_schedule on task_schedule.task_id = task.id
join ea.term on course_class.term_id = term.id
where term.id >= (select value::integer from tm.system_config where key='rollcall.start_term')
union all
select t.id as user_id, 'ROLE_PLACE_BOOKING_CHECKER' as role_id
from ea.teacher t
join tm.booking_auth ba on ba.checker_id = t.id
union all
select distinct supervisor_id as user_id, 'ROLE_CLASS_SUPERVISOR' as role_id
from admin_class_at_school
union all
select distinct counsellor_id as user_id, 'ROLE_STUDENT_COUNSELLOR' as role_id
from admin_class_at_school
union all
select distinct s.teacher_id as user_id, 'ROLE_OBSERVER' as role_id
from tm.observer s
join ea.term t on s.term_id = t.id
where t.active is true
union all
select distinct s.teacher_id as user_id, 'ROLE_DUALDEGREE_ADMIN_DEPT' as role_id
from tm_dual.department_administrator s
union all
select distinct s.teacher_id as user_id, 'ROLE_DUALDEGREE_MENTOR' as role_id
from tm_dual.mentor s
union all
select distinct c.teacher_id as user_id, 'ROLE_HUNT_CHECKER' as role_id
from tm_hunt.checker c
union all
select distinct e.teacher_id as user_id, 'ROLE_HUNT_EXPERT' as role_id
from tm_hunt.expert e
where e.is_external is not true;

-- 学生角色
create or replace view tm.dv_student_role as
select s.id as user_id, 'ROLE_IN_SCHOOL_STUDENT' as role_id
from ea.student s
where s.at_school = true
union all
select s.id as user_id, 'ROLE_POSTPONED_STUDENT' as role_id
from ea.student s
where s.at_school = false
and exists (
    select 1
    from ea.course_class
    join ea.task on task.course_class_id = course_class.id
    join ea.task_student on task_student.task_id = task.id
    join ea.term on term.id = course_class.term_id
    where task_student.student_id = s.id
    and ea.course_class.term_id =  (select id from ea.term where active = true)
)
union all
select s.student_id as user_id, 'ROLE_DUALDEGREE_STUDENT' as role_id
from tm_dual.student_abroad s;

-- 外部用户角色
create or replace view tm.dv_external_role as
select id as user_id, 'ROLE_BUILDING_KEEPER' as role_id
from tm.system_user
where user_type = 9 and name like '%楼管理员%'
union all
select distinct s.id as user_id, 'ROLE_HUNT_EXPERT' as role_id
from tm.system_user s join tm_hunt.expert e on s.id = e.teacher_id
where e.is_external is true;

-- 计划-课程
create or replace view tm.dv_scheme_course as
select c.id, c.name, c.credit,
    c.period_theory as theory_period,
    c.period_experiment as experiment_period,
    c.period_weeks as period_weeks,
    c.education_level,
    c.assess_type,
    c.property_id,
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
    0 as property_id,
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
select program_id,
       course_id,
       period_theory,
       period_experiment,
       period_weeks,
       is_compulsory,
       is_practical,
       property_id,
       assess_type,
       test_type,
       start_week,
       end_week,
       suggested_term,
       allowed_term,
       schedule_type,
       department_id,
       direction_id
from ea.sv_program_course;

-- 学生出勤情况视图
create or replace view tm.dv_student_attendance as
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
left join tm.dva_valid_student_leave student_leave on (
  rollcall.student_id       = student_leave.student_id and
  rollcall.week             = student_leave.week and
  rollcall.task_schedule_id = student_leave.task_schedule_id
)
left join tm.dva_valid_free_listen free_listen on (
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
       student_leave.teacher_id --approver_id
from tm.dva_valid_student_leave student_leave
left join tm.dva_valid_free_listen free_listen on (
  student_leave.student_id       = free_listen.student_id and
  student_leave.task_schedule_id = free_listen.task_schedule_id
);

-- 有效免听视图，用于函数统计
create or replace view tm.dva_valid_free_listen as
select item.id as item_id,
       form.id as form_id,
       form.term_id,
       form.student_id,
       course_class.id as course_class_id,
       task.id as task_id,
       task_schedule.id as task_schedule_id
from tm.free_listen_form form
join tm.free_listen_item item on item.form_id = form.id
join ea.task_schedule on item.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
join ea.course_class on task.course_class_id = course_class.id
where form.status = 'APPROVED'
union
select item.id as item_id,
       form.id as form_id,
       form.term_id,
       form.student_id,
       course_class.id as course_class_id,
       task.id as task_id,
       task_schedule.id as task_schedule_id
from tm.free_listen_form form
join tm.free_listen_item item on item.form_id = form.id
join ea.task_schedule on item.task_schedule_id = task_schedule.root_id
join ea.task on task_schedule.task_id = task.id
join ea.course_class on task.course_class_id = course_class.id
where form.status = 'APPROVED';

-- 有效请假视图，用于函数统计
create or replace view tm.dva_valid_student_leave as
select item.id as item_id,
       form.id as form_id,
       form.term_id,
       form.student_id,
       item.week,
       course_class.course_id,
       task.course_item_id,
       task.course_class_id,
       task_schedule.task_id,
       task_schedule.id as task_schedule_id,
       task_schedule.day_of_week,
       task_schedule.start_section,
       task_schedule.total_section,
       form.type,
       form.approver_id as teacher_id
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
 and case task_schedule.odd_even
   when 0 then true
   when 1 then item.week % 2 = 1
   when 2 then item.week % 2 = 0
 end
where form.status in ('APPROVED', 'FINISHED');

-- 有效点名视图，用于函数统计
create or replace view tm.dva_valid_rollcall as
select rollcall.id as rollcall_id,
       course_class.term_id,
       rollcall.student_id,
       rollcall.week,
       course_class.course_id,
       task.course_item_id,
       task.course_class_id,
       task_schedule.task_id,
       task_schedule.id as task_schedule_id,
       task_schedule.day_of_week,
       task_schedule.start_section,
       task_schedule.total_section,
       rollcall.type,
       rollcall.teacher_id
from tm.rollcall
join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
join ea.task_student on task.id = task_student.task_id and rollcall.student_id = task_student.student_id
join ea.course_class on task.course_class_id = course_class.id
where rollcall.type <> 6;

-- 辅助视图：最新培养方案课程
create or replace view tm.av_latest_scheme_course as
with latest_scheme as (
  select program_id, max(version_number) as version_number
  from Scheme
  where status = 'APPROVED'
  group by program_id
)
select department.name as department,
    p.id as program_id,
    m.grade as grade,
    s.name as subject,
    d.name as direction,
    property.name as property,
    course.id::text as course_id,
    course.name as course_name,
    course.credit,
    sc.practice_credit,
    suggested_term,
    sc.revise_version,
    sc.id as scheme_course_id,
    scheme.id as scheme_id
from scheme_course sc
join ea.course on sc.course_id = course.id
join scheme on scheme.id = sc.scheme_id
join ea.program p on p.id = scheme.program_id
join ea.major m on m.id = p.major_id
join ea.subject s on s.id = m.subject_id
join latest_scheme on latest_scheme.program_id = scheme.program_id
join ea.property on property.id = sc.property_id
join ea.department on m.department_id = department.id
left join ea.direction d on d.id = sc.direction_id
where m.grade >= 2016
and scheme.version_number <= latest_scheme.version_number
and (sc.revise_version is null or sc.revise_version > latest_scheme.version_number)
union all
select department.name as department,
    p.id as program_id,
    m.grade as grade,
    s.name as subject,
    d.name as direction,
    property.name as property,
    'T' || course.id :: text as course_id,
    course.name as course_name,
    course.credit,
    sc.practice_credit,
    suggested_term,
    sc.revise_version,
    sc.id as scheme_course_id,
    scheme.id as scheme_id
from scheme_temp_course sc
join temp_course course on sc.temp_course_id = course.id
join scheme on scheme.id = sc.scheme_id
join ea.program p on p.id = scheme.program_id
join ea.major m on m.id = p.major_id
join ea.subject s on s.id = m.subject_id
join latest_scheme on latest_scheme.program_id = scheme.program_id
join ea.property on property.id = sc.property_id
join ea.department on m.department_id = department.id
left join ea.direction d on d.id = sc.direction_id
where m.grade >=2016
and scheme.version_number <= latest_scheme.version_number
and (sc.revise_version is null or sc.revise_version > latest_scheme.version_number);

-- 辅助视图：最新培养方案学分统计
create or replace view av_latest_scheme_credit as
select program_id, subject, direction, property, sum(credit) as credit, sum(practice_credit) as practice_credit
from av_latest_scheme_course
group by program_id, subject, direction, property
order by 1, 2, 3, 4;

-- 检查视图：培养方案与执行计划学分比较
create or replace view tm.cv_scheme_program_credit as
with scheme_info as (
  select program_id, subject, property, direction, sum(credit) as credit
  from tm.av_latest_scheme_course
  group by program_id, subject, property, direction
), program_info as (
  select pc.program_id, p.name as property, d.name as direction, sum(credit) as credit
  from ea.program_course pc
  join ea.property p on pc.property_id = p.id
  join ea.course c on pc.course_id = c.id
  left join ea.direction d on pc.direction_id = d.id
  group by pc.program_id, p.name, d.name
), program_property as (
  select pp.program_id, p.name as property, pp.credit
  from ea.program_property pp
  join ea.property p on pp.property_id = p.id
)
select a.program_id, a.subject, a.property, a.direction,
  a.credit as scheme_course_total_credit,
  c.credit as program_property_credit,
  b.credit as program_course_total_credit
from scheme_info a
join program_property c on a.program_id = c.program_id and a.property = c.property
left join program_info b on a.program_id = b.program_id and a.property = b.property
  and a.direction is not distinct from b.direction
order by 1, 3;
