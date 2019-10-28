/**
 * 辅助视图-排课基础表
 * 1. 对未排课教学任务，取教学班的主讲教师，否则，取排课教师；
 * 2. 计算排课时间的hash值，用于后面合并；
 * 3. 提前计算选课学生数，用于后面消除错误数据。
 */
create or replace view tm_load.dva_task_schedule_base as
select course_class.term_id,
  course_class.department_id,
  task_schedule.teacher_id,
  course.id as course_id,
  course.name as course_name,
  course.credit as course_credit,
  course_item.id as course_item_id,
  course_item.name as course_item_name,
  course_class.property_id,
  task.id as task_id,
  task.code as task_code,
  case
    when substring(task.code, 24, 5) = task_schedule.teacher_id then 1000
    else 2000
  end + translate(substring(task.code from '-(\d+[A-Z]?)$'), 'ABCDEFG', '1234567')::integer * case
    when course_item.name = '理论' then 10
    else 1
  end as task_ordinal,
  course_class.id course_class_id,
  task_schedule.start_week, task_schedule.end_week, odd_even, day_of_week, start_section, total_section,
  coalesce((
    select count(student_id)
    from ea.task_student
    where task_id = task.id
  ), 0) as student_count,
  coalesce(course_item_workload_settings.workload_type, course_workload_settings.workload_type, 2) as workload_type
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
join ea.task_schedule on task_schedule.task_id = task.id
left join ea.course_item on task.course_item_id = course_item.id
left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
where term_id >= 20161
and (course_workload_settings.course_id is null or course_workload_settings.workload_type in (1, 2))
and (course_item_workload_settings.course_item_id is null or course_item_workload_settings.workload_type in (1, 2));

/**
 * 辅助视图-按上课时间合并教学任务
 * 1. 注意处理错误数据：存在同一时间不同开课单位的开课,
 *    也存在同一时间同一开课单位不同课程的情况，后面处理时，需要取最终工作量的最大值。
 * 2. 存在多计划合班情况，计算课程性质；
 * 3. 提前处理专业班型规模类型。
 */
create or replace view tm_load.dva_task_schedule as
select term_id, department_id, teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  c.task_id, course_tasks, course_class_ordinal, student_count,
  task_instructional_mode.type as instructional_mode_type,
  coalesce(task_instructional_mode.ratio, 1.0) as instructional_mode_ratio,
  class_size_type,
  start_week, end_week, odd_even, day_of_week, start_section, total_section,
  course_workload_type,
  task_workload_settings.type as task_workload_type,
  case
    when task_workload_settings.note is not null then
      jsonb_build_object('taskWorkloadSettings', task_workload_settings.note)
    else
      '{}'::jsonb
  end as note
from ( /*合并同一时间上课的教学任务*/
  select term_id, department_id, teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
    array_to_string(array_agg(task_id order by task_ordinal), ',') as task_id,
    jsonb_agg(jsonb_build_object(
      'id', task_id,
      'code', task_code,
      'ordinal', task_ordinal
    ) order by task_ordinal) as course_tasks,
    min(task_ordinal) as course_class_ordinal,
    sum(student_count) as student_count,
    course_workload_type,
    max(class_size_type) as class_size_type, /*5,6同时存在时，取6*/
    start_week, end_week, odd_even, day_of_week, start_section, total_section
  from ( /*合并课程性质和班级规模类型*/
    select term_id, b.department_id, teacher_id, b.course_id, course_name, course_item_id, course_item_name, course_credit,
      string_agg(distinct coalesce(p1.name, p2.name), ', ') as course_properties,
      task_id, task_code, task_ordinal, student_count,
      course_workload_type,
      max(scst.type_id) as class_size_type, /*5,6同时存在时，取6*/
      b.start_week, b.end_week, odd_even, day_of_week, start_section, total_section
    from tm_load.dva_task_schedule_base b
    left join ea.property p1 on b.property_id = p1.id
    left join ea.course_class_program ccp on b.course_class_id = ccp.course_class_id
    left join ea.program_course pc on pc.program_id = ccp.program_id and pc.course_id = b.course_id
    left join ea.property p2 on pc.property_id = p2.id
    left join ea.program p on pc.program_id = p.id
    left join ea.major m on p.major_id = m.id
    left join ea.subject s on m.subject_id = s.id
    left join tm_load.subject_class_size_type scst on scst.subject_id = s.id
    group by term_id, b.department_id, teacher_id, b.course_id, course_name, course_item_id, course_item_name, course_credit,
      task_id, task_code, task_ordinal, student_count, course_workload_type,
      b.start_week, b.end_week, odd_even, day_of_week, start_section, total_section
  ) b
  group by term_id, department_id, teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit,
    course_properties, course_workload_type, start_week, end_week, odd_even, day_of_week, start_section, total_section
) c
left join tm_load.task_instructional_mode on task_instructional_mode.task_id = c.task_id and task_instructional_mode.flag <> 'D'
left join tm_load.task_workload_settings on task_workload_settings.task_id = c.task_id and task_workload_settings.flag <> 'D'
where (task_workload_settings.task_id is null or task_workload_settings.type in (1, 2));

/**
 * 辅助视图-未排课任务基础表（不包括按学生计的任务）
 */
create or replace view tm_load.dva_task_without_timetable_base as
select course_class.term_id,
  course_class.department_id,
  course_class.teacher_id,
  course.id as course_id,
  course.name as course_name,
  course_item.id as course_item_id,
  course_item.name as course_item_name,
  course.credit as course_credit,
  course_class.property_id,
  task.id::text as task_id,
  task.code as task_code,
  substring(task.code from '-(\d+)[A-Z]?$')::integer as task_ordinal,
  course_class.id course_class_id,
  coalesce((select count(student_id) as student_count
    from ea.task_student
    where task_id = task.id
  ), 0) as student_count,
  task_instructional_mode.type as instructional_mode_type,
  coalesce(task_instructional_mode.ratio, 1.0)::numeric(2, 1) as instructional_mode_ratio,
  case task_workload_settings.type
    when 2 then task_workload_settings.value /*未排课任务调整课时*/
    else 0
  end as workload_correction,
  coalesce(course_item_workload_settings.type, course_workload_settings.type, 2) as course_workload_type,
  task_workload_settings.type as task_workload_type,
  case when task_workload_settings.note is not null then jsonb_build_object('taskWorkloadSettings', task_workload_settings.note) else '{}'::jsonb end as note
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
left join ea.course_item on task.course_item_id = course_item.id
left join tm_load.task_instructional_mode on task_instructional_mode.task_id = task.id::text and task_instructional_mode.flag <> 'D'
left join tm_load.task_workload_settings on task_workload_settings.task_id = task.id::text and task_workload_settings.flag <> 'D'
left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
left join ea.property on course_class.property_id = property.id
where term_id >= 20161
and not exists(select 1 from ea.task_schedule where task_schedule.task_id = task.id) /*未排课*/
and (task_workload_settings.task_id is null or task_workload_settings.type in (1, 2)) /*不计或调整课时*/
and (course_workload_settings.course_id is null or course_workload_settings.type = 1) /*按课程或不计*/
and (course_item_workload_settings.course_item_id is null or course_item_workload_settings.type = 1) /*按课程项或不计*/;

/**
 * 辅助视图-未排课任务，合并课程性质和班级规模类型
 */
create or replace view tm_load.dva_task_without_timetable as
select term_id, b.department_id, teacher_id, b.course_id, course_name, course_item_id, course_item_name, course_credit,
  string_agg(distinct coalesce(p1.name, p2.name), ', ') as course_properties,
  task_id, task_code, task_ordinal, student_count, workload_correction,
  course_workload_type, task_workload_type, instructional_mode_type, instructional_mode_ratio,
  max(scst.type_id) as class_size_type, /*5,6同时存在时，取6*/
  note
from tm_load.dva_task_without_timetable_base b
left join ea.property p1 on b.property_id = p1.id
left join ea.course_class_program ccp on b.course_class_id = ccp.course_class_id
left join ea.program_course pc on pc.program_id = ccp.program_id and pc.course_id = b.course_id
left join ea.property p2 on pc.property_id = p2.id
left join ea.program p on pc.program_id = p.id
left join ea.major m on p.major_id = m.id
left join ea.subject s on m.subject_id = s.id
left join tm_load.subject_class_size_type scst on scst.subject_id = s.id
group by term_id, b.department_id, teacher_id, b.course_id, course_name, course_item_id, course_item_name, task_id, task_code, task_ordinal, course_credit,
  student_count, workload_correction, course_workload_type, task_workload_type, instructional_mode_type, instructional_mode_ratio, note;

/**
 * 辅助视图-按排课计工作量的任务
 */
create or replace view tm_load.dva_task_by_classhour as
select term_id, department_id, teacher_id, ts.course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  task_id, course_tasks, course_class_ordinal, student_count, schedule_workload, workload_correction,
  instructional_mode_type, instructional_mode_ratio,
  case -- 计算班级规模类型
    when course_item_name = '实验' then 4 -- 实验课
    when course_properties in ('公共选修课', '公共必修课') then 1 -- 公共课
    when ccst.type_id is not null then ccst.type_id -- 按课程（政治/艺术小班）
    when class_size_type is null and department_id = '50' then 5 -- 慈善特殊课
    else class_size_type -- 按专业
 end as class_size_type,
 course_workload_type, task_workload_type,
 workload_source, note
from (
  -- 排课任务按任务合并教学安排
  select term_id, department_id, x.teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
    x.task_id, course_tasks, course_class_ordinal, student_count,
    coalesce(sum(ea.fn_weeks_count(start_week, end_week, odd_even) * total_section), 0) as schedule_workload,
    coalesce(y.value, 0) as workload_correction,
    instructional_mode_type, instructional_mode_ratio, class_size_type,
    course_workload_type, task_workload_type,
    jsonb_build_object(
      'type', 'H',
      'assigned', false,
      'timetable', jsonb_agg(jsonb_build_object(
        'startWeek', start_week,
        'endWeek', end_week,
        'oddEven', odd_even,
        'dayOfWeek', day_of_week,
        'startSection', start_section,
        'totalSection', total_section
      ))
    ) as workload_source,
    case when y.note is not null then x.note || jsonb_build_object('workloadCorrection', y.note) else x.note end as note
  from tm_load.dva_task_schedule x
  left join tm_load.workload_correction y on y.task_id = x.task_id and y.teacher_id = x.teacher_id and y.type = 2 and y.flag <> 'D'
  group by term_id, department_id, x.teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
    x.task_id, course_tasks, course_class_ordinal, student_count, y.value,
    instructional_mode_type, instructional_mode_ratio, course_workload_type, task_workload_type, class_size_type, x.note, y.note
  union all
  -- 分配课时
  select distinct term_id, department_id, y.teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
    x.task_id, course_tasks, course_class_ordinal, student_count,
    0 as schedule_workload,
    y.value as workload_correction,
    instructional_mode_type, instructional_mode_ratio, class_size_type,
    course_workload_type, y.type as task_workload_type,
    jsonb_build_object('type', 'H', 'assigned', true) as workload_source,
    x.note || jsonb_build_object('workloadCorrection', y.note) as note
  from tm_load.dva_task_schedule x
  join tm_load.workload_correction y on y.task_id = x.task_id and y.type = 3 and y.flag <> 'D'
  union all
  -- 未排课的任务
  select term_id, department_id, teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
    x.task_id, jsonb_build_array(jsonb_build_object(
      'id', task_id,
      'code', task_code,
      'ordinal', task_ordinal
    )) as course_tasks, task_ordinal as course_class_ordinal, student_count, 0 as schedule_workload, workload_correction,
    instructional_mode_type, instructional_mode_ratio, class_size_type,
    course_workload_type, task_workload_type,
    jsonb_build_object('type', 'H', 'assigned', false) as workload_source,
    note
  from tm_load.dva_task_without_timetable x
  union all
  -- 未排课的任务分配课时
  select distinct term_id, department_id, y.teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
    x.task_id, jsonb_build_array(jsonb_build_object(
      'id', x.task_id,
      'code', task_code,
      'ordinal', task_ordinal
    )) as course_tasks, task_ordinal as course_class_ordinal, student_count, 0 as schedule_workload, y.value as workload_correction,
    instructional_mode_type, instructional_mode_ratio, class_size_type,
    course_workload_type, y.type as task_workload_type,
    jsonb_build_object('type', 'H', 'assigned', true) as workload_source,
    x.note || jsonb_build_object('workloadCorrection', y.note) as note
  from tm_load.dva_task_without_timetable x
  join tm_load.workload_correction y on y.task_id = x.task_id::text and y.type = 3 and y.flag <> 'D'
) ts
left join tm_load.course_class_size_type ccst on ccst.course_id = ts.course_id;

/**
 * 辅助视图-按课时计的工作量
 */
create or replace view tm_load.dva_workload_by_classhour as
select term_id, department_id, teacher_id, a.course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  task_id, course_tasks, student_count,
  case
    when course_workload_type = 1 or task_workload_type = 1 then 0
    else schedule_workload
  end as original_workload,
  workload_correction,
  instructional_mode_type, instructional_mode_ratio,
  coalesce(b.ratio, 1.0)::numeric(2,1) as class_size_ratio,
  case
    when c.ratio is not null then c.ratio
    when rank() over(partition by term_id, department_id, teacher_id, a.course_id, course_item_id
      order by (schedule_workload + workload_correction) * instructional_mode_ratio * b.ratio desc, course_class_ordinal) = 1 then 1.0
    else 0.9
  end as class_parallel_ratio,
  course_workload_type, task_workload_type,
  workload_source,
  case
    when task_workload_type = 1 then
      a.note || jsonb_build_object('taskWorkloadType', '该任务不计工作量')
    when course_workload_type = 1 then
      a.note || jsonb_build_object('courseWorkloadType', '该课程不计工作量')
    else
      a.note
  end as note
from tm_load.dva_task_by_classhour a
left join tm_load.class_size_ratio b on a.class_size_type = b.type_id and student_count between b.lower_bound and b.upper_bound
left join tm_load.course_parallel_ratio c on a.course_id = c.course_id;

/**
 * 辅助视图-按学生数计工作量的任务
 */
create or replace view tm_load.dva_task_by_student as
select course_class.term_id,
  course_class.department_id,
  course_class.teacher_id,
  course.id as course_id,
  course.name as course_name,
  course_item.id as course_item_id,
  course_item.name as course_item_name,
  course.credit as course_credit,
  coalesce(property.name, array_to_string(
    array(select distinct p.name
        from ea.program_course pc
        join ea.course_class_program ccp on pc.program_id = ccp.program_id
        join ea.property p on pc.property_id = p.id
        where pc.course_id = course_class.course_id
        and ccp.course_class_id = course_class.id
    ), ', ')) as course_properties,
  task.id::text as task_id,
  task.code as task_code,
  substring(task.code from '-(\d+)[A-Z]?$')::integer as task_ordinal,
  course_class.id course_class_id,
  coalesce((select count(student_id) as student_count
    from ea.task_student
    where task_id = task.id
  ), 0) + coalesce(task_workload_settings.value, 0) as student_count,
  null as instructional_mode_type,
  course_workload_settings.ratio as instructional_mode_ratio,
  course_workload_settings.type as course_workload_type,
  task_workload_settings.type as task_workload_type,
  course_workload_settings.upper_bound as student_upper_bound,
  case when task_workload_settings.note is not null then jsonb_build_object('taskWorkloadSettings', task_workload_settings.note) else '{}'::jsonb end as note
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
left join ea.course_item on task.course_item_id = course_item.id
left join tm_load.task_instructional_mode on task_instructional_mode.task_id = task.id::text and task_instructional_mode.flag <> 'D'
left join tm_load.task_workload_settings on task_workload_settings.task_id = task.id::text and task_workload_settings.flag <> 'D' and task_workload_settings.type = 4 -- 修正学生数
left join ea.property on course_class.property_id = property.id
where term_id >= 20161
and course_workload_settings.type = 4 /*按学生计*/;

/**
 * 辅助视图-按学生数计的工作量
 */
create or replace view tm_load.dva_workload_by_student as
select term_id, department_id, x.teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  x.task_id as task_id,
  jsonb_build_array(jsonb_build_object(
    'id', x.task_id,
    'code', task_code,
    'ordinal', task_ordinal
  )) as course_tasks,
  x.student_count - coalesce(y.student_count, 0) as student_count,
  least(x.student_count - coalesce(y.student_count, 0), student_upper_bound) * course_credit::integer as original_workload,
  0 as workload_correction,
  instructional_mode_type, instructional_mode_ratio,
  1.0 as class_size_ratio, 1.0 as class_parallel_ratio,
  course_workload_type, task_workload_type,
  jsonb_build_object('type', 'S', 'assigned', false) as workload_source,
  note
from tm_load.dva_task_by_student x
left join (
  select task_id, sum(value) as student_count
  from tm_load.workload_correction
  where type = 4 and flag <> 'D'
  group by task_id
) y on y.task_id = x.task_id::text
union all
select term_id, department_id, y.teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  x.task_id as task_id,
  jsonb_build_array(jsonb_build_object(
    'id', x.task_id,
    'code', task_code,
    'ordinal', task_ordinal
  )) as course_tasks,
  y.value as student_count, 0 as original_workload,
  least(y.value, x.student_upper_bound) * course_credit::integer as workload_correction,
  instructional_mode_type, instructional_mode_ratio,
  1.0 as class_size_ratio, 1.0 as class_parallel_ratio,
  course_workload_type, y.type as task_workload_type,
  jsonb_build_object('type', 'S', 'assigned', true)as workload_source,
  x.note || jsonb_build_object('workloadCorrection', y.note) as note
from tm_load.dva_task_by_student x
join tm_load.workload_correction y on y.task_id = x.task_id::text
where y.type = 4 and flag <> 'D';

/**
 * 辅助视图-教学工作量及系数
 */
create or replace view tm_load.dva_workload_item as
select term_id, department_id, teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  task_id, course_tasks, student_count, original_workload, workload_correction,
  instructional_mode_type, instructional_mode_ratio, class_size_ratio, class_parallel_ratio,
  ((original_workload + workload_correction) * instructional_mode_ratio * class_size_ratio * class_parallel_ratio / (term.end_week - term.start_week - 1) * 18) ::numeric(6, 2) as normalized_workload,
  workload_source, course_workload_type, task_workload_type, note
from tm_load.dva_workload_by_classhour
join ea.term on dva_workload_by_classhour.term_id = term.id
union all
select term_id, department_id, teacher_id, course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  task_id, course_tasks, student_count, original_workload, workload_correction,
  instructional_mode_type, instructional_mode_ratio, class_size_ratio, class_parallel_ratio,
  ((original_workload + workload_correction) * instructional_mode_ratio * class_size_ratio * class_parallel_ratio)::numeric(6, 2) as normalized_workload,
  workload_source, course_workload_type, task_workload_type, note
from tm_load.dva_workload_by_student;

/**
 * 数据视图-教学工作量及系数
 */
create or replace view tm_load.dv_workload_item as
select dva_workload_item.term_id, dva_workload_item.department_id, teacher.id as teacher_id, teacher.name as teacher_name,
  department.name as teacher_department, teacher.is_external as is_external_teacher, case teacher.is_external
    when true then
      coalesce(teacher_workload_type.type, 3) -- 外聘教师默认按原始工作量
    else
      coalesce(teacher_workload_type.type, 2) -- 专职教师默认按标准工作量
  end as teacher_workload_type,
  coalesce(teacher_admin_workload.value, 0) as teacher_admin_workload,
  course_id, course_name, course_item_id, course_item_name, course_credit, course_properties,
  task_id, course_tasks, student_count, original_workload, workload_correction,
  instructional_mode_type, instructional_mode_ratio, class_size_ratio, class_parallel_ratio,
  normalized_workload, workload_source, course_workload_type, task_workload_type,
  note
from tm_load.dva_workload_item
join ea.teacher on dva_workload_item.teacher_id = teacher.id
join ea.department on teacher.department_id = department.id
left join tm_load.teacher_workload_type on dva_workload_item.department_id = teacher_workload_type.department_id
  and dva_workload_item.teacher_id = teacher_workload_type.teacher_id
  and dva_workload_item.term_id = teacher_workload_type.term_id
left join tm_load.teacher_admin_workload on dva_workload_item.teacher_id = teacher_admin_workload.teacher_id
  and dva_workload_item.term_id = teacher_admin_workload.term_id
where teacher_workload_type.type is null or teacher_workload_type.type > 0;

/**
 * 辅助视图-输出
 */
create or replace view tm_load.av_workload_item as
select a.term_id as 学期, b.name as 开课单位, teacher_id as 教师编号, teacher_name as 教师姓名, teacher_department as 教师单位, 
    case when is_external_teacher then '是' else '否' end as 是否外聘,
    course_id as 课程编号, course_name || coalesce('(' || course_item_name || ')', '') as 课程名称, course_credit as 学分,
    course_properties as 课程性质, student_count as 选课人数, 
    original_workload as 原始工作量, workload_correction 工作量调整,
    instructional_mode_ratio as 教学形式系统, class_size_ratio as 班级规模系统, class_parallel_ratio as 平行班系统,
    normalized_workload as 标准工作量,
    array_to_string(array((
        select obj.val->>'code'
        from jsonb_array_elements(course_tasks) obj(val)
    )), ',') as 选课课号, array_to_string(array((
        select ea.fn_timetable_to_string(
            (obj.val->>'startWeek')::integer,
            (obj.val->>'endWeek')::integer,
            (obj.val->>'oddEven')::integer,
            (obj.val->>'dayOfWeek')::integer,
            (obj.val->>'startSection')::integer,
            (obj.val->>'totalSection')::integer
        )
        from jsonb_array_elements(workload_source->'timetable') obj(val)
    )), ',') as 教学安排
from tm_load.dv_workload_item a
join ea.department b on a.department_id = b.id;