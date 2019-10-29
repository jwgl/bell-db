create or replace view tm_load.dva_task_schedule_base as
select term_id, department_id, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id, workload_type,
  array_agg(distinct (course_id, course_name)::tm_load.t_text_pair order by (course_id, course_name)::tm_load.t_text_pair) as courses,
  max(course_credit) as course_credit,
  string_agg(distinct course_item_name, ',' order by course_item_name) as course_item,
  array_agg(task_id order by task_ordinal) as task_ids,
  string_agg(task_code, ',' order by task_ordinal) as task_codes,
  array_agg(task_schedule_id order by task_schedule_id) as task_schedule_ids
from (
  select term_id, course_class.department_id, course_class.course_id, task.id as task_id, task.code as task_code,
    task_schedule.id as task_schedule_id, course.name as course_name, course.credit as course_credit, course_item.name as course_item_name,
    task_schedule.start_week, task_schedule.end_week, odd_even, day_of_week, start_section, total_section, task_schedule.teacher_id,
    case
      when substring(task.code, 24, 5) = task_schedule.teacher_id then 1000
      else 2000
    end + translate(substring(task.code from '-(\d+[A-Z]?)$'), 'ABCDEFG', '1234567')::integer * case
      when course_item.name = '理论' then 10
      else 1
    end as task_ordinal,
    coalesce(course_item_workload_settings.workload_type, course_workload_settings.workload_type, 2) as workload_type
  from ea.task_schedule
  join ea.task on task.id = task_schedule.task_id
  join ea.course_class on course_class.id = task.course_class_id
  join ea.course on course.id = course_class.course_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
  left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
  where term_id >= 20161
) x
group by term_id, department_id, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id, workload_type;

create or replace view tm_load.dva_task_with_timetable as
select distinct term_id, department_id, task_codes as code, task_ids,
  array_to_string(array(select p1 from unnest(courses) group by p1 order by p1), ',') course_id,
  array_to_string(array(select p2 from unnest(courses) group by p2 order by min(p1)), ',') course_name,
  course_credit, course_item, workload_type
from tm_load.dva_task_schedule_base;

create or replace view tm_load.dva_task_without_timetable as
select course_class.term_id,
  course_class.department_id,
  task.code,
  array[task.id] as task_ids,
  course.id as course_id,
  course.name as course_name,
  course.credit as course_credit,
  course_item.name as course_item,
  coalesce(course_item_workload_settings.workload_type, course_workload_settings.workload_type, 3) as workload_type
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
left join ea.course_item on task.course_item_id = course_item.id
left join ea.task_schedule on task_schedule.task_id = task.id
left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
where term_id >= 20161
and task_schedule.id is null; /*未排课*/

create or replace view tm_load.dva_workload_task as
select term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type
from tm_load.dva_task_with_timetable
union all
select term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type
from tm_load.dva_task_without_timetable
order by term_id, department_id, code, course_item;

insert into tm_load.workload_task(term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type, campus)
select term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type, 1
from tm_load.dva_workload_task
on conflict(task_ids) do update set
term_id = excluded.term_id,
code = excluded.code,
course_id = excluded.course_id,
course_name = excluded.course_name,
course_credit = excluded.course_credit,
course_item = excluded.course_item,
workload_type = excluded.workload_type;

delete from tm_load.workload_task
where task_ids not in (
  select task_ids from tm_load.dva_workload_task
);

-- 合并workload_task_schedule
insert into tm_load.workload_task_schedule(workload_task_id, task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id)
select b.id as workload_task_id, task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id
from tm_load.dva_task_schedule_base a
join tm_load.workload_task b on a.task_ids = b.task_ids
on conflict(task_schedule_ids) do update set
start_week = excluded.start_week,
end_week = excluded.end_week,
odd_even = excluded.odd_even,
day_of_week = excluded.day_of_week,
start_section = excluded.start_section,
total_section = excluded.total_section,
teacher_id = excluded.teacher_id;

-- 删除workload_task_schedule
delete from tm_load.workload_task_schedule
where (task_schedule_ids) not in (
  select task_schedule_ids
  from tm_load.dva_task_schedule_base a
  join tm_load.workload_task b on a.task_ids = b.task_ids
);

-- 更新workload_task的选课人数
update tm_load.workload_task wt set
student_count = (
  select count(distinct student_id)
  from ea.task_student
  where task_student.task_id = any(wt.task_ids)
);

-- 更新workload_task的课程性质
with task as (
  select workload_task.id as workload_task_id, string_agg(distinct coalesce(p1.name, p2.name), ',' order by coalesce(p1.name, p2.name)) as course_property
  from tm_load.workload_task
  join ea.task on task.id = any(workload_task.task_ids)
  join ea.course_class on course_class.id = task.course_class_id
  join ea.course on course.id = course_class.course_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join ea.property p1 on course_class.property_id = p1.id
  left join ea.course_class_program on course_class.id = course_class_program.course_class_id
  left join ea.program_course on program_course.program_id = course_class_program.program_id and program_course.course_id = course.id
  left join ea.property p2 on program_course.property_id = p2.id
  left join ea.program on program_course.program_id = program.id
  left join ea.major on program.major_id = major.id
  left join ea.subject on major.subject_id = subject.id
  group by workload_task.id
)
update tm_load.workload_task workload_task set
course_property = task.course_property
from task
where task.workload_task_id = workload_task.id;

-- 更新workload_task的班级规模
with task as (
  select workload_task.id as workload_task_id, workload_task.student_count,
    case
      when coalesce(p1.id, p2.id) in (1, 2)
        then 5 -- /*通识课*/
      else
        coalesce(
          course_item_workload_settings.class_size_type_id,
          course_workload_settings.class_size_type_id,
          subject_workload_settings.class_size_type_id,
          9 /*常量班型*/
        )
    end as class_size_type_id,
    case
      when coalesce(p1.id, p2.id) in (1, 2) then 4
      when course_item_workload_settings.class_size_type_id is not null then 3
      when course_workload_settings.class_size_type_id is not null then 2
      when subject_workload_settings.class_size_type_id is not null then 1
      else 0
    end as class_size_source
  from tm_load.workload_task
  join ea.task on task.id = any(workload_task.task_ids)
  join ea.course_class on course_class.id = task.course_class_id
  join ea.course on course.id = course_class.course_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join ea.property p1 on course_class.property_id = p1.id
  left join ea.course_class_program on course_class.id = course_class_program.course_class_id
  left join ea.program_course on program_course.program_id = course_class_program.program_id and program_course.course_id = course.id
  left join ea.property p2 on program_course.property_id = p2.id
  left join ea.program on program_course.program_id = program.id
  left join ea.major on program.major_id = major.id
  left join ea.subject on major.subject_id = subject.id
  left join tm_load.subject_workload_settings on subject_workload_settings.subject_id = subject.id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
  left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
  where workload_task.class_size_source is null or workload_task.class_size_source <> 9
), task_class_size as (
  select distinct on (workload_task_id) workload_task_id, class_size_source as source, class_size_type.name as type, class_size_ratio.ratio
  from task
  join tm_load.class_size_type on class_size_type.id = task.class_size_type_id
  left join tm_load.class_size_ratio on class_size_ratio.type_id = task.class_size_type_id
    and task.student_count between class_size_ratio.lower_bound and class_size_ratio.upper_bound
  order by workload_task_id, class_size_ratio.ratio desc
)
update tm_load.workload_task workload_task set
class_size_source = task_class_size.source,
class_size_type = task_class_size.type,
class_size_ratio = coalesce(task_class_size.ratio, 0)
from task_class_size
where task_class_size.workload_task_id = workload_task.id;