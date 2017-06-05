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
UNION ALL
SELECT DISTINCT s.teacher_id AS user_id,
'ROLE_OBSERVER' AS role_id
FROM tm.observer s
JOIN tm.observer_type r ON s.observer_type_id = r.id
JOIN ea.term t ON s.term_id = t.id
WHERE (r.name = '校督导' OR r.name = '院督导') AND t.active IS TRUE;
;

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
    select *
    from ea.course_class
    join ea.task on task.course_class_id = course_class.id
    join ea.task_student on task_student.task_id = task.id
    join ea.term on term.id = course_class.term_id
    where task_student.student_id = s.id
    and ea.course_class.term_id =  (select id from ea.term where active = true)
)
;

-- 外部用户角色
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
where form.status = 'APPROVED';

-- 有效请假视图，用于函数统计
create or replace view tm.dva_valid_student_leave as
select item.id as item_id,
       form.id as form_id,
       form.term_id,
       form.student_id,
       item.week,
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
CREATE OR REPLACE VIEW tm.dv_course_section AS
SELECT *
FROM tm.booking_section
WHERE booking_section.id <> 0 AND booking_section.id <> '-5'::integer;

-- 统计老师被校督导听课次数（与课程无关）;
CREATE OR REPLACE VIEW tm.dv_observation_count AS
SELECT teacher.id AS teacher_id,
       teacher.name AS teacher_name,
       department.name AS department_name,
       count(*) AS supervise_count
FROM tm.observation_form form
JOIN ea.teacher ON form.teacher_id = teacher.id
JOIN ea.term ON form.term_id = term.id
JOIN ea.department ON teacher.department_id = department.id
WHERE term.active IS TRUE AND form.observer_type = 1
GROUP BY teacher.id, teacher.name, department.name
HAVING count(*) > 1;

-- 历史遗留数据视图，避免修改;
CREATE OR REPLACE VIEW tm.dv_observation_legacy_form AS
SELECT *
FROM tm.observation_legacy_form form;

-- 优先听课名单视图:本学期有课，且查询的当周还有课，近4个学期未被听课，是否新老师;
CREATE OR REPLACE VIEW tm.dv_observation_priority AS
WITH active_term AS (
    SELECT term.id
    FROM ea.term
    WHERE term.active IS TRUE
), course_teacher AS (
    SELECT DISTINCT courseclass.teacher_id, courseclass.term_id AS termid
    FROM ea.task_schedule schedule
    JOIN ea.task task ON schedule.task_id = task.id
    JOIN ea.course_class courseclass ON task.course_class_id = courseclass.id
    JOIN ea.course course_1 ON courseclass.course_id = course_1.id
), active_teacher AS (
    SELECT DISTINCT courseteacher.id AS teacher_id,
          courseteacher.name AS teacher_name,
          courseteacher.academic_title,
          department.name AS department_name,
          courseclass.term_id AS termid
    FROM ea.task_schedule schedule
    JOIN ea.task task ON schedule.task_id = task.id
    JOIN ea.course_class courseclass ON task.course_class_id = courseclass.id
    JOIN ea.course course_1 ON courseclass.course_id = course_1.id
    JOIN ea.teacher courseteacher ON courseclass.teacher_id = courseteacher.id
    JOIN ea.department department ON courseteacher.department_id = department.id
    WHERE courseclass.term_id = ((SELECT active_term.id FROM active_term))
    AND schedule.end_week > (( SELECT date_part('week', now()) - date_part('week', term.start_date) + 1 FROM ea.term WHERE term.active IS TRUE))
), new_teacher AS (
    SELECT course_teacher.teacher_id
    FROM course_teacher
    GROUP BY course_teacher.teacher_id
    HAVING min(course_teacher.termid) = (( SELECT active_term.id FROM active_term))
), inspect4 AS (
    SELECT DISTINCT inspector.teachercode AS teacher_id
    FROM tm.observation_legacy_form inspector
    WHERE inspector.teachercode IS NOT NULL AND inspector.type = '督导' AND (inspector.term_id + 20) > (( SELECT active_term.id FROM active_term))
    UNION
    SELECT DISTINCT form.teacher_id
    FROM tm.observation_form form
    JOIN ea.task_schedule schedule ON form.task_schedule_id = schedule.id
    JOIN ea.task ON schedule.task_id = task.id
    JOIN ea.course_class courseclass ON task.course_class_id = courseclass.id
    WHERE form.observer_type =1 AND (courseclass.term_id + 20) > (( SELECT active_term.id FROM active_term))
)
SELECT DISTINCT active.teacher_id,
    active.teacher_name,
    active.department_name,
    active.academic_title,
    a.teacher_id AS isnew,
    inspect4.teacher_id AS has_supervisor
FROM active_teacher active
LEFT JOIN new_teacher a ON active.teacher_id = a.teacher_id
LEFT JOIN inspect4 ON active.teacher_id = inspect4.teacher_id;

 -- JOIN课表，抽取最全常用字段;
CREATE OR REPLACE VIEW tm.dv_observation_view AS
SELECT form.id,
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
    supervisor.id AS supervisor_id,
    form.supervisor_date,
    form.teaching_methods,
    form.total_section AS form_total_section,
    form.record_date,
    form.reward_date,
    supervisor.name AS supervisor_name,
    form.observer_type,
    courseteacher.id AS teacher_id,
    courseteacher.academic_title,
    courseclass.name AS course_class_name,
    schedule.start_week,
    schedule.end_week,
    schedule.odd_even,
    schedule.day_of_week,
    schedule.start_section,
    schedule.total_section,
    course_1.name AS course_name,
    place.name AS place_name,
    courseteacher.name AS teacher_name,
    department.name AS department_name,
    courseclass.term_id AS termid
FROM tm.observation_form form
JOIN ea.teacher supervisor ON form.observer_id = supervisor.id
JOIN ea.task_schedule schedule ON form.task_schedule_id = schedule.id
JOIN ea.task task ON schedule.task_id = task.id
JOIN ea.course_class courseclass ON task.course_class_id = courseclass.id
JOIN ea.department department ON courseclass.department_id = department.id
JOIN ea.course course_1 ON courseclass.course_id = course_1.id
JOIN ea.teacher courseteacher ON courseclass.teacher_id = courseteacher.id
LEFT JOIN ea.place ON schedule.place_id = place.id
ORDER BY id;

-- 督导听课视图，合并了新旧数据，只抽取重要的字段信息;
CREATE OR REPLACE VIEW tm.dv_observation_public AS
SELECT view.id,
    false AS is_legacy,
    view.supervisor_date,
    view.evaluate_level,
    concat(substring('校院',view.observer_type,1),'督导'),
    view.termid AS term_id,
    view.department_name,
    view.teacher_id,
    view.teacher_name,
    view.course_name,
    concat('星期', substring('一二三四五六日', view.day_of_week, 1), ' ', view.start_section, '-', (view.start_section + view.total_section - 1), '节 ', view.place_name) AS course_other_info
FROM tm.dv_observation_view view
WHERE view.status = 2
UNION ALL
SELECT legacy_form.id,
    true AS is_legacy,
    legacy_form.listentime AS supervisor_date,
    legacy_form.evaluategrade AS evaluate_level,
    legacy_form.type AS type_name,
    legacy_form.term_id,
    legacy_form.collegename AS department_name,
    legacy_form.teachercode AS teacher_id,
    legacy_form.teachername AS teacher_name,
    legacy_form.coursename AS course_name,
    legacy_form.classpostion AS course_other_info
FROM tm.dv_observation_legacy_form legacy_form
WHERE legacy_form.state = 'yes';

