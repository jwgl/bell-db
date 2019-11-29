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

-- 更新workload_task的主讲教师
update tm_load.workload_task workload_task set
primary_teacher_id = dvu.primary_teacher_id
from tm_load.dvu_task_primary_teacher dvu
where dvu.id = workload_task.id;

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
select workload_task_id, task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id
from tm_load.dvm_task_schedule
on conflict(task_schedule_ids) do update set
start_week = excluded.start_week,
end_week = excluded.end_week,
odd_even = excluded.odd_even,
day_of_week = excluded.day_of_week,
start_section = excluded.start_section,
total_section = excluded.total_section,
teacher_id = excluded.teacher_id;

-- 合并workload_task_teacher
insert into tm_load.workload_task_teacher(workload_task_id, teacher_id, original_workload, correction, parallel_ratio)
select workload_task_id, teacher_id, original_workload, correction, parallel_ratio
from tm_load.dvm_workload_task_teacher
on conflict(workload_task_id, teacher_id) do update set
original_workload = excluded.original_workload,
parallel_ratio = excluded.parallel_ratio
where workload_task_teacher.original_workload <> excluded.original_workload
   or workload_task_teacher.parallel_ratio <> excluded.parallel_ratio;

-- 更新workload_task_teacher的标准工作量和任务顺序
update tm_load.workload_task_teacher workload_task_teacher set
standard_workload = dvu.standard_workload,
task_ordinal = dvu.task_ordinal
from tm_load.dvu_workload_task_teacher_standard_workload dvu
where dvu.workload_task_id = workload_task_teacher.workload_task_id
and dvu.teacher_id = workload_task_teacher.teacher_id;

-- 合并teacher_workload_settings
insert into tm_load.teacher_workload_settings(teacher_id, post_type, employment_mode, employment_status)
select teacher_id, post_type, employment_mode, employment_status
from tm_load.dvm_teacher_workload_settings
on conflict(teacher_id) do update set
post_type = excluded.post_type,
employment_mode = excluded.employment_mode,
employment_status = excluded.employment_status;

-- 合并workload
insert into tm_load.workload(term_id, department_id, teacher_id,
  teaching_workload, adjustment_workload, supplement_workload, practice_workload, executive_workload)
select term_id, department_id, teacher_id,
  teaching_workload, adjustment_workload, supplement_workload, practice_workload, executive_workload
from tm_load.dvm_workload
on conflict(term_id, department_id, teacher_id) do update set
teaching_workload = excluded.teaching_workload,
adjustment_workload = excluded.adjustment_workload,
supplement_workload = excluded.supplement_workload,
practice_workload = excluded.practice_workload,
executive_workload = excluded.executive_workload;

update tm_load.workload set
total_workload = teaching_workload + adjustment_workload + supplement_workload
               + practice_workload + executive_workload + correction;

-- 删除workload
delete from tm_load.workload
where (term_id, department_id, teacher_id) not in (
  select term_id, department_id, teacher_id
  from tm_load.dvm_workload
);

-- 删除workload_task_teacher
delete from tm_load.teacher_workload_settings
where teacher_id not in (
  select teacher_id
  from tm_load.dvm_teacher_workload_settings
);

-- 删除workload_task_schedule
delete from tm_load.workload_task_schedule
where task_schedule_ids not in (
  select task_schedule_ids
  from tm_load.dvm_task_schedule
);

-- 删除workload_task_teacher
delete from tm_load.workload_task_teacher
where (workload_task_id, teacher_id) not in (
  select workload_task_id, teacher_id
  from tm_load.dvm_workload_task_teacher
);

-- 删除workload_task
delete from tm_load.workload_task
where task_ids not in (
  select task_ids from tm_load.dvm_workload_task
);

