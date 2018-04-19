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
select distinct course_class.teacher_id as user_id, case term.active
    when true then 'ROLE_COURSE_CLASS_TEACHER'
    else 'ROLE_ONCE_COURSE_CLASS_TEACHER'
  end as role_id
from ea.course_class
join ea.term on course_class.term_id = term.id
where term.id >= (select value::integer from system_config where key='rollcall.start_term')
union all
select distinct task_schedule.teacher_id as user_id, case term.active
    when true then 'ROLE_TASK_SCHEDULE_TEACHER'
    else 'ROLE_ONCE_TASK_SCHEDULE_TEACHER'
  end as role_id
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.task_schedule on task_schedule.task_id = task.id
join ea.term on course_class.term_id = term.id
where term.id >= (select value::integer from system_config where key='rollcall.start_term')
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
from tm_dual.mentor s;

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
select '' as userId, '' as role_id where 1 = 2;

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
with free_listen as (
  select item.id as item_id,
         form.id as form_id,
         course_class.term_id,
         form.student_id,
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
         course_class.term_id,
         form.student_id,
         task_schedule.id as task_schedule_id
  from tm.free_listen_form form
  join tm.free_listen_item item on item.form_id = form.id
  join ea.task_schedule on item.task_schedule_id = task_schedule.root_id
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
   and case task_schedule.odd_even
     when 0 then true
     when 1 then item.week % 2 = 1
     when 2 then item.week % 2 = 0
   end
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

-- 有效免听视图，用于函数统计
create or replace view tm.dva_valid_free_listen as
select item.id as item_id,
       form.id as form_id,
       course_class.term_id,
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
       course_class.term_id,
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
       course_class.id as course_class_id,
       task.id as task_id,
       task_schedule.id as task_schedule_id,
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
       course_class.id as course_class_id,
       task.id as task_id,
       rollcall.task_schedule_id,
       task_schedule.total_section,
       rollcall.type,
       rollcall.teacher_id
from tm.rollcall
join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
join ea.task_student on task.id = task_student.task_id and rollcall.student_id = task_student.student_id
join ea.course_class on task.course_class_id = course_class.id
where rollcall.type <> 6;

--引用时段表;
create or replace view tm.dv_course_section as
select *
from tm.booking_section
where booking_section.id <> 0 and booking_section.id <> '-5'::integer;

-- 统计老师被校督导听课次数（与课程无关）;
create or replace view tm.dv_observation_count as
select teacher.id as teacher_id,
       teacher.name as teacher_name,
       department.name as department_name,
       count(*) as supervise_count
from tm.observation_form form
join ea.teacher on form.teacher_id = teacher.id
join ea.term on form.term_id = term.id
join ea.department on teacher.department_id = department.id
where term.active is true and form.observer_type = 1
group by teacher.id, teacher.name, department.name
having count(*) > 1;

-- 历史遗留数据视图，避免修改;
create or replace view tm.dv_observation_legacy_form as
select *
from tm.observation_legacy_form form;

-- 优先听课名单视图:本学期有课，且查询的当周还有课，近4个学期未被听课，是否新老师;
create or replace view tm.dv_observation_priority as
with active_term as (
    select term.id
    from ea.term
    where term.active is true
), course_teacher as (
    select distinct courseclass.teacher_id, courseclass.term_id as termid
    from ea.task_schedule schedule
    join ea.task task on schedule.task_id = task.id
    join ea.course_class courseclass on task.course_class_id = courseclass.id
    join ea.course course_1 on courseclass.course_id = course_1.id
), active_teacher as (
    select distinct courseteacher.id as teacher_id,
          courseteacher.name as teacher_name,
          courseteacher.academic_title,
          department.name as department_name,
          courseclass.term_id as termid
    from ea.task_schedule schedule
    join ea.task task on schedule.task_id = task.id
    join ea.course_class courseclass on task.course_class_id = courseclass.id
    join ea.course course_1 on courseclass.course_id = course_1.id
    join ea.place place on schedule.place_id = place.id
    join ea.teacher courseteacher on courseclass.teacher_id = courseteacher.id
    join ea.department department on courseteacher.department_id = department.id
    where courseclass.term_id = ((select active_term.id from active_term)) and place.building <> '北理工'
    and schedule.end_week > (( select date_part('week', now()) - date_part('week', term.start_date) + 1 from ea.term where term.active is true))
), new_teacher as (
    select course_teacher.teacher_id
    from course_teacher
    group by course_teacher.teacher_id
    having min(course_teacher.termid) = (( select active_term.id from active_term))
), inspect4 as (
    select distinct inspector.teachercode as teacher_id
    from tm.observation_legacy_form inspector
    where inspector.teachercode is not null and inspector.observer_type = 1 and (inspector.term_id + 20) > (( select active_term.id from active_term))
    union
    select distinct form.teacher_id
    from tm.observation_form form
    where form.observer_type =1 and (form.term_id + 20) > (( select active_term.id from active_term))
)
select distinct active.teacher_id,
    active.teacher_name,
    active.department_name,
    active.academic_title,
    a.teacher_id as isnew,
    inspect4.teacher_id as has_supervisor
from active_teacher active
left join new_teacher a on active.teacher_id = a.teacher_id
left join inspect4 on active.teacher_id = inspect4.teacher_id;

-- JOIN课表，抽取最全常用字段
create or replace view tm.dv_observation_view as
select distinct form.id,
    form.attendant_stds,
    form.due_stds,
    form.earlier,
    form.evaluate_level,
    form.evaluation_text,
    form.late,
    form.late_stds,
    form.leave,
    form.leave_stds,
    form.lecture_week,
    form.status,
    form.suggest,
    supervisor.id as supervisor_id,
    form.supervisor_date,
    form.teaching_methods,
    form.total_section as form_total_section,
    form.record_date,
    form.reward_date,
    supervisor.name as supervisor_name,
    form.observer_type,
    courseteacher.id as teacher_id,
    courseteacher.academic_title,
    array_to_string(array_agg(distinct courseclass.name), ',', '*') as course_class_name,
    schedule.start_week,
    schedule.end_week,
    schedule.odd_even,
    schedule.day_of_week,
    schedule.start_section,
    schedule.total_section,
    course_1.name as course_name,
    place.name as place_name,
    courseteacher.name as teacher_name,
    department.name as department_name,
    cp.property_name as property,
    courseclass.term_id as term_id
   from tm.observation_form form
     join ea.teacher supervisor on form.observer_id = supervisor.id
     join ea.task_schedule schedule on (form.teacher_id = schedule.teacher_id
          and (form.lecture_week between schedule.start_week and schedule.end_week )
          and (schedule.odd_even = 0
               or schedule.odd_even = 1 and form.lecture_week % 2 =1
               or schedule.odd_even = 2 and form.lecture_week % 2 =0)
          and schedule.day_of_week = form.day_of_week
          and form.start_section = schedule.start_section)
     join ea.task task on schedule.task_id = task.id
     join ea.course_class courseclass on task.course_class_id = courseclass.id
     join ea.department department on courseclass.department_id = department.id
     join ea.course course_1 on courseclass.course_id = course_1.id
     join ea.teacher courseteacher on form.teacher_id = courseteacher.id
     left join ea.place on schedule.place_id = place.id
     join tm.dv_observation_course_property cp on courseclass.id = cp.id
  where form.term_id=courseclass.term_id and not form.is_schedule_temp is true
  group by form.id, form.attendant_stds, form.due_stds, form.earlier, form.evaluate_level,
  form.evaluation_text, form.late, form.late_stds, form.leave, form.leave_stds,
  form.lecture_week, form.status, form.suggest, supervisor.id, form.supervisor_date,
  form.teaching_methods, form.total_section, form.record_date, form.reward_date,
  supervisor.name, form.observer_type, courseteacher.id, courseteacher.academic_title,
  schedule.start_week, schedule.end_week, schedule.odd_even, schedule.day_of_week,
  schedule.start_section, schedule.total_section, course_1.name, place.name,
  courseteacher.name, department.name, cp.property_name, courseclass.term_id
  union all
  select distinct form.id,
    form.attendant_stds,
    form.due_stds,
    form.earlier,
    form.evaluate_level,
    form.evaluation_text,
    form.late,
    form.late_stds,
    form.leave,
    form.leave_stds,
    form.lecture_week,
    form.status,
    form.suggest,
    supervisor.id as supervisor_id,
    form.supervisor_date,
    form.teaching_methods,
    form.total_section as form_total_section,
    form.record_date,
    form.reward_date,
    supervisor.name as supervisor_name,
    form.observer_type,
    courseteacher.id as teacher_id,
    courseteacher.academic_title,
    array_to_string(array_agg(distinct courseclass.name), ',', '*') as course_class_name,
    schedule.start_week,
    schedule.end_week,
    schedule.odd_even,
    schedule.day_of_week,
    schedule.start_section,
    schedule.total_section,
    course_1.name as course_name,
    schedule.place as place_name,
    courseteacher.name as teacher_name,
    department.name as department_name,
    cp.property_name as property,
    courseclass.term_id as term_id
   from tm.observation_form form
     join ea.teacher supervisor on form.observer_id = supervisor.id
     join tm.task_schedule_temp schedule on (form.teacher_id = schedule.teacher_id
          and (form.lecture_week between schedule.start_week and schedule.end_week )
          and (schedule.odd_even = 0
               or schedule.odd_even = 1 and form.lecture_week % 2 =1
               or schedule.odd_even = 2 and form.lecture_week % 2 =0)
          and schedule.day_of_week = form.day_of_week
          and form.start_section = schedule.start_section)
     join ea.task task on schedule.task_id = task.id
     join ea.course_class courseclass on task.course_class_id = courseclass.id
     join ea.department department on courseclass.department_id = department.id
     join ea.course course_1 on courseclass.course_id = course_1.id
     join ea.teacher courseteacher on form.teacher_id = courseteacher.id
     join tm.dv_observation_course_property cp on courseclass.id = cp.id
  where form.term_id=courseclass.term_id and form.is_schedule_temp is true
  group by form.id, form.attendant_stds, form.due_stds, form.earlier, form.evaluate_level,
  form.evaluation_text, form.late, form.late_stds, form.leave, form.leave_stds,
  form.lecture_week, form.status, form.suggest, supervisor.id, form.supervisor_date,
  form.teaching_methods, form.total_section, form.record_date, form.reward_date,
  supervisor.name, form.observer_type, courseteacher.id, courseteacher.academic_title,
  schedule.start_week, schedule.end_week, schedule.odd_even, schedule.day_of_week,
  schedule.start_section, schedule.total_section, course_1.name, schedule.place,
  courseteacher.name, department.name, cp.property_name, courseclass.term_id;

-- 督导听课视图，合并了新旧数据，只抽取重要的字段信息;
create or replace view tm.dv_observation_public as
select view.id,
    false as is_legacy,
    view.supervisor_date,
    view.evaluate_level::text,
    view.observer_type,
    view.term_id as term_id,
    view.department_name,
    view.teacher_id,
    view.teacher_name,
    view.course_name,
    view.place_name,
    view.day_of_week,
    view.start_section,
    view.total_section
from tm.dv_observation_view view
where view.status = 2;

-- 课程性质视图
create or replace view tm.dv_observation_course_property as
select course_class.id, case
	when property.name is not null then property.name
	else (
		select array_to_string(array_agg(distinct pr.name), ',', '*')
		from ea.course_class cc
		join ea.course_class_program ccp on ccp.course_class_id = cc.id
		join ea.program p on p.id= ccp.program_id
		join ea.program_course pc on pc.program_id = p.id and pc.course_id = cc.course_id
		join ea.property pr on pr.id = pc.property_id
		where cc.id = course_class.id
	) end as property_name
from ea.course_class
left join ea.property on property.id = course_class.property_id;

-- 辅助视图：最新培养方案课程
create or replace view tm.av_latest_scheme_course as
with latest_scheme as (
  select program_id, max(version_number) as version_number
  from Scheme
  where status = 'APPROVED'
  group by program_id
)
select p.id as program_id,
    s.name as subject,
    d.name as direction,
    property.name as property,
    course.id::text as course_id,
    course.name as course_name,
    course.credit,
    sc.practice_credit,
    suggested_term,
    sc.revise_version
from scheme_course sc
join ea.course on sc.course_id = course.id
join scheme on scheme.id = sc.scheme_id
join ea.program p on p.id = scheme.program_id
join ea.major m on m.id = p.major_id
join ea.subject s on s.id = m.subject_id
join latest_scheme on latest_scheme.program_id = scheme.program_id
join ea.property on property.id = sc.property_id
left join ea.direction d on d.id = sc.direction_id
where m.grade in (2016, 2017)
and scheme.version_number <= latest_scheme.version_number
and (sc.revise_version is null or sc.revise_version > latest_scheme.version_number)
union all
select p.id as program_id,
    s.name as subject,
    d.name as direction,
    property.name as property,
    'T' || course.id :: text as course_id,
    course.name as course_name,
    course.credit,
    sc.practice_credit,
    suggested_term,
    sc.revise_version
from scheme_temp_course sc
join temp_course course on sc.temp_course_id = course.id
join scheme on scheme.id = sc.scheme_id
join ea.program p on p.id = scheme.program_id
join ea.major m on m.id = p.major_id
join ea.subject s on s.id = m.subject_id
join latest_scheme on latest_scheme.program_id = scheme.program_id
join ea.property on property.id = sc.property_id
left join ea.direction d on d.id = sc.direction_id
where m.grade in (2016, 2017)
and scheme.version_number <= latest_scheme.version_number
and (sc.revise_version is null or sc.revise_version > latest_scheme.version_number);

-- 辅助视图：最新培养方案
create or replace view av_latest_scheme as
select program_id, subject, direction, property, sum(credit) as credit, sum(practice_credit) as practice_credit
from av_latest_scheme_course
group by program_id, subject, direction, property
order by 1, 2, 3, 4;
