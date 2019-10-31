-- 合并workload_task
insert into tm_load.workload_task(term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type, workload_mode, campus)
select term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type, workload_mode, 1
from tm_load.dvm_workload_task
on conflict(task_ids) do update set
term_id = excluded.term_id,
code = excluded.code,
course_id = excluded.course_id,
course_name = excluded.course_name,
course_credit = excluded.course_credit,
course_item = excluded.course_item,
workload_type = excluded.workload_type,
workload_mode = excluded.workload_mode;

-- 删除workload_task
delete from tm_load.workload_task
where task_ids not in (
  select task_ids from tm_load.dva_workload_task
);

-- 更新workload_task的选课人数
update tm_load.workload_task wt set
student_count = (
  select count(distinct student_id)
  from ea.task_student
  where task_student.task_id = any(wt.task_ids)
);

-- 更新workload_task的课程性质
update tm_load.workload_task workload_task set
course_property = dvu.course_property
from tm_load.dvu_workload_task_course_property dvu
where dvu.workload_task_id = workload_task.id;

-- 更新workload_task的班级规模
update tm_load.workload_task workload_task set
class_size_source = dvu.source,
class_size_type = dvu.type,
class_size_ratio = coalesce(dvu.ratio, 0)
from tm_load.dvu_workload_task_class_size dvu
where dvu.workload_task_id = workload_task.id;

-- 更新workload_task的教学形式
update tm_load.workload_task workload_task set
instructional_mode_source = dvu.source,
instructional_mode_type = dvu.type,
instructional_mode_ratio = dvu.ratio,
student_count_upper_bound = dvu.upper_bound
from tm_load.dvu_workload_task_instructional_mode dvu
where dvu.workload_task_id = workload_task.id;

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

-- 合并workload_task_teacher
insert into tm_load.workload_task_teacher(workload_task_id, teacher_id, original_workload, correction, parallel_ratio)
select workload_task_id, teacher_id, original_workload, correction, parallel_ratio
from tm_load.dvm_workload_task_teacher
on conflict(workload_task_id, teacher_id) do update set
original_workload = excluded.original_workload,
parallel_ratio = excluded.parallel_ratio
where workload_task_teacher.original_workload <> excluded.original_workload
   or workload_task_teacher.parallel_ratio <> excluded.parallel_ratio;

