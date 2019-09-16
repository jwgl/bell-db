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
          courseteacher.is_external as is_external,
          department.name as department_name,
          array_to_string(array_agg(distinct course_1.name), ',', '*') as course_name,
          course_dept.name as course_dept_name,
          courseclass.term_id as termid
    from ea.task_schedule schedule
    join ea.task task on schedule.task_id = task.id
    join ea.course_class courseclass on task.course_class_id = courseclass.id
    join ea.course course_1 on courseclass.course_id = course_1.id
    join ea.place place on schedule.place_id = place.id
    join ea.teacher courseteacher on courseclass.teacher_id = courseteacher.id
    join ea.department course_dept on courseclass.department_id = course_dept.id
    join ea.department department on courseteacher.department_id = department.id
    where courseclass.term_id = ((select active_term.id from active_term)) and place.building <> '北理工'
    and schedule.end_week > (( select date_part('week', now()) - date_part('week', term.start_date) + 1 from ea.term where term.active is true))
    group by courseteacher.id,courseteacher.name,courseteacher.academic_title,department.name,course_dept.name,courseclass.term_id
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
select active.teacher_id,
    active.teacher_name,
    active.department_name,
    active.academic_title,    
    a.teacher_id as isnew,
    inspect4.teacher_id as has_supervisor,
    array_to_string(array_agg(distinct concat(active.course_dept_name,': ',active.course_name)), ';') as course_name,
    active.is_external
from active_teacher active
left join new_teacher a on active.teacher_id = a.teacher_id
left join inspect4 on active.teacher_id = inspect4.teacher_id
group by active.teacher_id,active.teacher_name,active.department_name,active.academic_title,active.is_external,a.teacher_id,inspect4.teacher_id;

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
    schedule.teacher_id,
    schedule.academic_title,
    schedule.course_class_name as course_class_name,
    schedule.start_week,
    schedule.end_week,
    schedule.odd_even,
    schedule.day_of_week,
    schedule.start_section,
    schedule.total_section,
    schedule.course_name,
    schedule.place_name,
    schedule.teacher_name,
    schedule.department_name,
    schedule.property as property,
    schedule.term_id as term_id,
    form.recommend as recommend
   from tm.observation_form form
   join ea.teacher supervisor on form.observer_id = supervisor.id
   join tm.dv_observation_task schedule on (schedule.day_of_week = form.day_of_week
          and form.start_section = schedule.start_section
          and form.teacher_id = schedule.teacher_id
          and schedule.week_bits & (1 << form.lecture_week - 1) <> 0)
        and form.term_id = schedule.term_id
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

--当前学期领导
create or replace view tm.dv_leaders as
select o.teacher_id
from tm.observer o join ea.term on o.term_id = term.id
where o.observer_type = 3 and term.active;

--督导听课用课表视图
create or replace view tm.dv_observation_task as
select courseteacher.id as teacher_id,
  array_to_string(array_agg(distinct courseclass.name), ',', '*') as course_class_name,
  schedule.start_week,
  schedule.end_week,
  schedule.odd_even,
  schedule.day_of_week,
  schedule.start_section,
  schedule.total_section,
  schedule.week_bits,
  course_1.name as course_name,
  place.name as place_name,
  courseteacher.name as teacher_name,
  courseteacher.academic_title,
  department.name as department_name,
  cp.property_name as property,
  courseclass.term_id as term_id
from ea.task_schedule schedule 
     join ea.task task on schedule.task_id = task.id
     join ea.course_class courseclass on task.course_class_id = courseclass.id
     join ea.department department on courseclass.department_id = department.id
     join ea.course course_1 on courseclass.course_id = course_1.id
     join ea.teacher courseteacher on schedule.teacher_id = courseteacher.id
     join tm.dv_observation_course_property cp on courseclass.id = cp.id
     left join ea.place on schedule.place_id = place.id
group by courseteacher.id, courseteacher.academic_title,
  schedule.start_week, schedule.end_week, schedule.odd_even, schedule.day_of_week,
  schedule.start_section, schedule.week_bits, schedule.total_section, course_1.name, place.name,
  courseteacher.name, department.name, cp.property_name, courseclass.term_id;