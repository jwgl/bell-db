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
insert into tm_load.teacher_workload_settings(teacher_id, post_type, employment_mode, employment_status, supplement)
select teacher_id, post_type, employment_mode, employment_status, supplement
from tm_load.dvm_teacher_workload_settings
on conflict(teacher_id) do update set
post_type = excluded.post_type,
employment_mode = excluded.employment_mode,
employment_status = excluded.employment_status,
supplement = excluded.supplement;

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

-- 合并workload
insert into tm_load.workload(term_id, department_id, teacher_id,
  teaching_workload, practice_workload, executive_workload)
select term_id, department_id, teacher_id,
  teaching_workload, practice_workload, executive_workload
from tm_load.dvm_workload
on conflict(term_id, department_id, teacher_id) do update set
teaching_workload = excluded.teaching_workload,
practice_workload = excluded.practice_workload,
executive_workload = excluded.executive_workload;

-- 合并external_workload
insert into tm_load.workload(term_id, department_id, teacher_id,
  teaching_workload, practice_workload, executive_workload,
  external_teaching_workload, external_practice_workload,
  external_executive_workload, external_correction)
select term_id, department_id, teacher_id,
  teaching_workload, practice_workload, executive_workload,
  external_teaching_workload, external_practice_workload,
  external_executive_workload, external_correction
from tm_load.dvm_external_workload
on conflict(term_id, department_id, teacher_id) do update set
external_teaching_workload = excluded.external_teaching_workload,
external_practice_workload = excluded.external_practice_workload,
external_executive_workload = excluded.external_executive_workload,
external_correction = excluded.external_correction;

-- 校区教辅工作量
with teacher_with_name as (
    select * from (values
        (20191,'谭洋',24),
        (20191,'丁琦',24),
        (20191,'周庆华',4),
        (20191,'黄喻培',19),
        (20191,'周海婴',19),
        (20191,'刘炜',16),
        (20191,'燕飞',16),
        (20191,'霍录景',23),
        (20191,'李玉玲',23),
        (20191,'张金花',23),
        (20191,'刘思圆',28),
        (20191,'马迎秋',16)
    ) as t(term_id, teacher_name, correction)
), teacher_correction as (
    select x.*, (select id from ea.teacher where teacher.name = x.teacher_name and teacher.department_id = (
      select id from ea.department where name ='应用数学学院')
    ) as teacher_id
    from teacher_with_name x
)
update tm_load.workload w
set external_correction = external_correction + c.correction
from teacher_correction c
where w.term_id = c.term_id and w.teacher_id = c.teacher_id;

-- 更新workload的总工作量
update tm_load.workload workload set
adjustment_workload = dvu.adjustment_workload,
supplement_workload = dvu.supplement_workload,
total_workload = dvu.total_workload
from tm_load.dvu_workload dvu
where dvu.term_id = workload.term_id
and dvu.department_id = workload.department_id
and dvu.teacher_id = workload.teacher_id;

-- 删除workload
delete from tm_load.workload
where (term_id, department_id, teacher_id) not in (
  select term_id, department_id, teacher_id
  from tm_load.dvm_workload
  union all
  select term_id, department_id, teacher_id
  from tm_load.dvm_external_workload
);


-- 合并workload_report_detail：插入新数据
insert into tm_load.workload_report_detail(term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  workload_task_id, workload_task_code, task_ordinal,
  course_id, course_name, course_item, course_credit, course_property, course_class_department,
  workload_mode, workload_type, student_count_upper_bound, student_count,
  class_size_source, class_size_type, class_size_ratio,
  instructional_mode_source, instructional_mode_type, instructional_mode_ratio,
  parallel_ratio, correction, original_workload, standard_workload,
  workload_source, note, hash_value
)
select term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  workload_task_id, workload_task_code, task_ordinal,
  course_id, course_name, course_item, course_credit, course_property, course_class_department,
  workload_mode, workload_type, student_count_upper_bound, student_count,
  class_size_source, class_size_type, class_size_ratio,
  instructional_mode_source, instructional_mode_type, instructional_mode_ratio,
  parallel_ratio, correction, original_workload, standard_workload,
  workload_source, note, hash_value
from tm_load.dvm_workload_report_detail
where (term_id, teacher_id, workload_task_id) not in (
  select term_id, teacher_id, workload_task_id from tm_load.workload_report
);

-- 合并workload_report_detail：更新旧数据
with inserted as (
  insert into tm_load.workload_report_detail(term_id,
    human_resource_id, human_resource_name, human_resource_department,
    employment_mode, post_type,
    teacher_id, teacher_name, teacher_department,
    workload_task_id, workload_task_code, task_ordinal,
    course_id, course_name, course_item, course_credit, course_property, course_class_department,
    workload_mode, workload_type, student_count_upper_bound, student_count,
    class_size_source, class_size_type, class_size_ratio,
    instructional_mode_source, instructional_mode_type, instructional_mode_ratio,
    parallel_ratio, correction, original_workload, standard_workload,
    workload_source, note, hash_value
  )
  select a.term_id,
    a.human_resource_id, a.human_resource_name, a.human_resource_department,
    a.employment_mode, a.post_type,
    a.teacher_id, a.teacher_name, a.teacher_department,
    a.workload_task_id, a.workload_task_code, a.task_ordinal,
    a.course_id, a.course_name, a.course_item, a.course_credit, a.course_property, a.course_class_department,
    a.workload_mode, a.workload_type, a.student_count_upper_bound, a.student_count,
    a.class_size_source, a.class_size_type, a.class_size_ratio,
    a.instructional_mode_source, a.instructional_mode_type, a.instructional_mode_ratio,
    a.parallel_ratio, a.correction, a.original_workload, a.standard_workload,
    a.workload_source, a.note, a.hash_value
  from tm_load.dvm_workload_report_detail a
  join tm_load.workload_report_detail b on a.term_id = b.term_id
   and a.teacher_id = b.teacher_id
   and a.workload_task_id = b.workload_task_id
  where a.hash_value <> b.hash_value
  returning term_id, teacher_id, workload_task_id
)
update tm_load.workload_report_detail r
set date_invalid = localtimestamp
from inserted
where r.term_id = inserted.term_id
  and r.teacher_id = inserted.teacher_id
  and r.workload_task_id = inserted.workload_task_id
  and r.date_invalid is null;

-- 合并workload_report：删除旧数据
update tm_load.workload_report_detail
set date_invalid = localtimestamp
where (term_id, teacher_id, workload_task_id) not in (
  select term_id, teacher_id, workload_task_id from tm_load.dvm_workload_report_detail
);

-- 合并workload_report：插入新数据
insert into tm_load.workload_report(term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  teaching_workload, external_teaching_workload,
  adjustment_workload, supplement_workload,
  practice_workload, external_practice_workload,
  executive_workload, external_executive_workload,
  correction, external_correction, total_workload,
  hash_value
)
select term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  teaching_workload, external_teaching_workload,
  adjustment_workload, supplement_workload,
  practice_workload, external_practice_workload,
  executive_workload, external_executive_workload,
  correction, external_correction,
  total_workload, hash_value
from tm_load.dvm_workload_report
where (term_id, teacher_id, teacher_name, teacher_department) not in (
  select term_id, teacher_id, teacher_name, teacher_department from tm_load.workload_report
);

-- 合并workload_report：更新旧数据
with inserted as (
  insert into tm_load.workload_report(term_id,
    human_resource_id, human_resource_name, human_resource_department,
    employment_mode, post_type,
    teacher_id, teacher_name, teacher_department,
    teaching_workload, external_teaching_workload,
    adjustment_workload, supplement_workload,
    practice_workload, external_practice_workload,
    executive_workload, external_executive_workload,
    correction, external_correction,
    total_workload, hash_value
  )
  select a.term_id,
    a.human_resource_id, a.human_resource_name, a.human_resource_department,
    a.employment_mode, a.post_type,
    a.teacher_id, a.teacher_name, a.teacher_department,
    a.teaching_workload, a.external_teaching_workload,
    adjustment_workload, supplement_workload,
    a.practice_workload, a.external_practice_workload,
    a.executive_workload, a.external_executive_workload,
    a.correction, a.external_correction,
    a.total_workload, a.hash_value
  from tm_load.dvm_workload_report a
  join tm_load.workload_report b on a.term_id = b.term_id
   and a.teacher_id = b.teacher_id
   and a.teacher_name = b.teacher_name
   and a.teacher_department = b.teacher_department
  where a.hash_value <> b.hash_value
  returning term_id, teacher_id, teacher_name, teacher_department
)
update tm_load.workload_report r
set date_invalid = localtimestamp
from inserted
where r.term_id = inserted.term_id
  and r.teacher_id = inserted.teacher_id
  and r.teacher_name = inserted.teacher_name
  and r.teacher_department = inserted.teacher_department
  and r.date_invalid is null;

-- 合并workload_report：删除旧数据
update tm_load.workload_report
set date_invalid = localtimestamp
where (term_id, teacher_id, teacher_department) not in (
  select term_id, teacher_id, teacher_department from tm_load.dvm_workload_report
);
