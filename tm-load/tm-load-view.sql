/*
 * 辅助视图：教学安排
 */
create or replace view tm_load.dva_task_schedule_base as
select term_id, department_id, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id, workload_type, workload_mode,
  array_agg(distinct (task_ordinal, task_id, task_code)::tm_load.t_tuple_3 order by (task_ordinal, task_id, task_code)::tm_load.t_tuple_3) as tasks,
  array_agg(distinct (course_id, course_name)::tm_load.t_tuple_2 order by (course_id, course_name)::tm_load.t_tuple_2) as courses,
  max(course_credit) as course_credit,
  max(education_level) as education_level,
  string_agg(distinct course_item_name, ',' order by course_item_name) as course_item,
  min(task_ordinal) as task_ordinal,
  array_agg(distinct task_schedule_id order by task_schedule_id) as task_schedule_ids
from (
    select term_id, course_class.department_id, course_class.course_id, task.id as task_id, task.code as task_code,
    task_schedule.id as task_schedule_id, course.name as course_name, course.credit as course_credit, course.education_level, course_item.name as course_item_name,
    task_schedule.start_week, task_schedule.end_week, odd_even, day_of_week, start_section, total_section, task_schedule.teacher_id,
    case
      when substring(task.code, 24, 5) = task_schedule.teacher_id then 1000
      else 2000
    end + translate(substring(task.code from '-(\d+[A-Z]?)$'), 'ABCDEFG', '1234567')::integer * case
      when course_item.name = '理论' then 10
      else 1
    end as task_ordinal,
    coalesce(
      task_workload_settings.workload_type,
      course_item_workload_settings.workload_type,
      course_workload_settings.workload_type,
      2 /*正常*/
    ) as workload_type,
    coalesce(
      task_workload_settings.workload_mode,
      course_item_workload_settings.workload_mode,
      course_workload_settings.workload_mode,
      1 /*课时*/
    ) as workload_mode
  from ea.task_schedule
  join ea.task on task.id = task_schedule.task_id
  join ea.course_class on course_class.id = task.course_class_id
  join ea.course on course.id = course_class.course_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
  left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
  left join tm_load.task_workload_settings on task_workload_settings.task_id = task.id
  where term_id >= 20191
) x
group by term_id, department_id, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id, workload_type, workload_mode;

/*
 * 辅助视图：已排课教学任务
 */
create or replace view tm_load.dva_task_with_timetable as
select distinct term_id, department_id,
  array_to_string(array(select p3 from unnest(tasks) group by p3 order by min(p1)), ',') code,
  array(select p2::uuid from unnest(tasks) group by p2 order by min(p1)) task_ids,
  array_to_string(array(select p1 from unnest(courses) group by p1 order by p1), ',') course_id,
  array_to_string(array(select p2 from unnest(courses) group by p2 order by min(p1)), ',') course_name,
  course_credit, course_item, workload_type, workload_mode
from tm_load.dva_task_schedule_base;

/*
 * 辅助视图：未排课教学任务
 */
create or replace view tm_load.dva_task_without_timetable as
select course_class.term_id,
  course_class.department_id,
  task.code,
  array[task.id] as task_ids,
  course.id as course_id,
  course.name as course_name,
  course.credit as course_credit,
  course_item.name as course_item,
  coalesce(
    task_workload_settings.workload_type,
    course_item_workload_settings.workload_type,
    course_workload_settings.workload_type,
    2 /*正常*/
  ) as workload_type,
  coalesce(
    task_workload_settings.workload_mode,
    course_item_workload_settings.workload_mode,
    course_workload_settings.workload_mode,
    1 /*课时*/
  ) as workload_mode
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
left join ea.course_item on task.course_item_id = course_item.id
left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
left join tm_load.task_workload_settings on task_workload_settings.task_id = task.id
where not exists (
  select 1 from ea.task_schedule
  where task_id = task.id
)
and course_class.term_id >= 20191;

/*
 * 合并视图：工作量教学任务
 */
create or replace view tm_load.dvm_workload_task as
select term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type, workload_mode
from tm_load.dva_task_with_timetable
union all
select term_id, department_id, code, task_ids, course_id, course_name, course_credit, course_item, workload_type, workload_mode
from tm_load.dva_task_without_timetable
order by term_id, department_id, code, course_item;

/*
 * 更新视图：工作量教学任务-主讲教师
 */
create or replace view tm_load.dvu_task_primary_teacher as
select distinct on (workload_task.id) workload_task.id, course_class.teacher_id as primary_teacher_id
from tm_load.workload_task
join ea.task on task.id = any(workload_task.task_ids)
join ea.course_class on course_class.id = task.course_class_id
order by workload_task.id, case
    when exists (
      select 1 from tm_load.workload_task_schedule
      where workload_task_id = workload_task.id
      and teacher_id = course_class.teacher_id
    ) then 1
    else 0 end desc;

/*
 * 更新视图：工作量教学任务-教学班信息
 */
create or replace view tm_load.dvu_workload_task_course_class as
select workload_task.id as workload_task_id,
  string_agg(distinct coalesce(p1.name, p2.name), ',' order by coalesce(p1.name, p2.name)) as course_property,
  string_agg(distinct course_class.name, ',' order by course_class.name) as course_class_name,
  string_agg(distinct major.grade || '级' || subject.short_name, ',' order by major.grade || '级' || subject.short_name) as course_class_major
from tm_load.workload_task
join ea.task on task.id = any(workload_task.task_ids)
join ea.course_class on course_class.id = task.course_class_id
left join ea.course_item on course_item.id = task.course_item_id
left join ea.property p1 on course_class.property_id = p1.id
left join ea.course_class_program on course_class.id = course_class_program.course_class_id
left join ea.program_course on program_course.program_id = course_class_program.program_id and program_course.course_id = course_class.course_id
left join ea.property p2 on program_course.property_id = p2.id
left join ea.program on program_course.program_id = program.id
left join ea.major on program.major_id = major.id
left join ea.subject on major.subject_id = subject.id
group by workload_task.id;

/*
 * 更新视图：工作量教学任务-班级规模
 */
create or replace view tm_load.dvu_workload_task_class_size as
with task as (
  select workload_task.id as workload_task_id, workload_task.student_count,
    case
      when coalesce(p1.id, p2.id) in (1, 2)
        then 5 -- 通识课
      else
        coalesce(
          course_item_workload_settings.class_size_type_id,
          course_workload_settings.class_size_type_id,
          subject_workload_settings.class_size_type_id,
          9 -- 常量班型
        )
    end as class_size_type_id,
    case
      when coalesce(p1.id, p2.id) in (1, 2) then 4 -- 按课程性质
      when course_item_workload_settings.class_size_type_id is not null then 3 -- 按课程项
      when course_workload_settings.class_size_type_id is not null then 2 -- 按课程
      when subject_workload_settings.class_size_type_id is not null then 1 -- 按专业
      else 0  -- 缺省
    end as class_size_source
  from tm_load.workload_task
  join ea.task on task.id = any(workload_task.task_ids)
  join ea.course_class on course_class.id = task.course_class_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join ea.property p1 on course_class.property_id = p1.id
  left join ea.course_class_program on course_class.id = course_class_program.course_class_id
  left join ea.program_course on program_course.program_id = course_class_program.program_id and program_course.course_id = course_class.course_id
  left join ea.property p2 on program_course.property_id = p2.id
  left join ea.program on program_course.program_id = program.id
  left join ea.major on program.major_id = major.id
  left join ea.subject on major.subject_id = subject.id
  left join tm_load.subject_workload_settings on subject_workload_settings.subject_id = subject.id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
  left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
  where workload_task.class_size_source is null or workload_task.class_size_source <> 9
)
select distinct on (workload_task_id) workload_task_id,
  class_size_source as source,
  class_size_type.name as type,
  coalesce(class_size_ratio.ratio, 0.00)::numeric(3,2) as ratio
from task
join tm_load.class_size_type on class_size_type.id = task.class_size_type_id
left join tm_load.class_size_ratio on class_size_ratio.type_id = task.class_size_type_id
  and task.student_count between class_size_ratio.lower_bound and class_size_ratio.upper_bound
order by workload_task_id, ratio desc, class_size_type.id desc;

/*
 * 更新视图：工作量教学任务-教学形式
 */
create or replace view tm_load.dvu_workload_task_instructional_mode as
with task as (
  select workload_task.id as workload_task_id,
    case
      when workload_task.course_id = '01100060' and workload_task.code not like '%,%' then 20 -- 通识课实验
      else coalesce(
        task_workload_settings.instructional_mode_id,
        course_item_workload_settings.instructional_mode_id,
        course_workload_settings.instructional_mode_id,
        10 -- 理论课
      )
    end as instructional_mode_id,
    case
      when workload_task.course_id = '01100060' and workload_task.code not like '%,%' then 4
      when task_workload_settings.instructional_mode_id is not null then 3
      when course_item_workload_settings.instructional_mode_id is not null then 2
      when course_workload_settings.instructional_mode_id is not null then 1
      else 0
    end as instructional_mode_source
  from tm_load.workload_task
  join ea.task on task.id = any(workload_task.task_ids)
  join ea.course_class on course_class.id = task.course_class_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
  left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
  left join tm_load.task_workload_settings on task_workload_settings.task_id = any(tm_load.workload_task.task_ids)
  where workload_task.instructional_mode_source is null or workload_task.instructional_mode_source <> 9
)
select distinct on (workload_task_id) workload_task_id,
  instructional_mode_source as source,
  instructional_mode.name as type,
  instructional_mode.ratio, instructional_mode.upper_bound
from task
join tm_load.instructional_mode on instructional_mode.id = task.instructional_mode_id;

/**
 * 合并视图：教学安排
 */
create or replace view tm_load.dvm_task_schedule as
select b.id as workload_task_id, task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id
from (
  select array(select p2::uuid from unnest(tasks) group by p2 order by min(p1)) as task_ids,
    task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id
  from tm_load.dva_task_schedule_base
) a
join tm_load.workload_task b on a.task_ids = b.task_ids;

/*
 * 合并视图：工作量教师表
 */
create or replace view tm_load.dvm_workload_task_teacher as
with task as ( -- 查询所有任务的主讲教师和平行班系数设置
  select a.id, primary_teacher_id, d.parallel_ratio
  from tm_load.workload_task a
  left join ea.task b on b.id = any(a.task_ids)
  left join ea.course_class c on c.id = b.course_class_id
  left join tm_load.course_workload_settings d on d.course_id = c.course_id and d.department_id = c.department_id
), task_settings as ( -- 合并主讲教师和平行班系数设置
  select distinct on (id) id, parallel_ratio, primary_teacher_id
  from task
  order by id, coalesce(parallel_ratio, 0.9) desc
), task_teacher_by_timetable_base as ( -- 计算任务教师排课工作量
  select id, teacher_id, task_ids, sum(workload) as workload, workload_type
  from (
    select a.id, b.teacher_id, task_ids, case coalesce(c.workload_type, a.workload_type)
        when 1 then 0
        when 2 then coalesce(ea.fn_weeks_count(start_week, end_week, odd_even) * total_section, 0)
      end as workload,
      coalesce(c.workload_type, a.workload_type) as workload_type
    from tm_load.workload_task a
    left join tm_load.workload_task_schedule b on b.workload_task_id = a.id
    left join tm_load.workload_task_teacher_settings c on a.id = c.workload_task_id and b.teacher_id = c.teacher_id
    where coalesce(c.workload_type, a.workload_type) <> 0 and a.workload_mode = 1
  ) as t
  group by id, teacher_id, task_ids, workload_type
), task_teacher_by_timetable as ( -- 查询所有任务相关教师情况，包括多教师
  select a.id, coalesce(a.teacher_id, c.primary_teacher_id) as teacher_id, workload, case a.workload_type
      when 1 then 0
      when 2 then coalesce(b.correction, 0)
    end as correction
  from task_teacher_by_timetable_base a
  left join tm_load.workload_task_teacher_settings b on a.id = b.workload_task_id and a.teacher_id = b.teacher_id
  left join task_settings c on a.id = c.id
  union all
  select distinct a.id, c.teacher_id, 0 as workload, case a.workload_type
      when 1 then 0
      when 2 then coalesce(d.correction, 0)
    end as correction
  from tm_load.workload_task a
  join ea.task b on b.id = any(a.task_ids)
  join ea.task_teacher c on b.id = c.task_id
  left join tm_load.workload_task_teacher_settings d on a.id = d.workload_task_id and c.teacher_id = d.teacher_id
  where not exists (
    select 1
    from task_teacher_by_timetable_base x
    left join task_settings y on x.id = y.id
    where x.id = a.id and coalesce(x.teacher_id, y.primary_teacher_id) = c.teacher_id
  )
  and a.workload_type <> 0 and a.workload_mode = 1
), workload_by_timetable as ( -- 计算按排课计的任务的平行班系数
  select a.id, a.teacher_id, workload, coalesce(d.correction, 0) as correction, case
      when d.parallel_ratio is not null then d.parallel_ratio
      when c.parallel_ratio is not null then c.parallel_ratio
      when rank() over(partition by term_id, a.teacher_id, course_id, course_item order by (workload * class_size_ratio + coalesce(d.correction, 0)) desc, code) = 1 then 1.0
      else 0.9
    end as parallel_ratio
  from task_teacher_by_timetable a
  join tm_load.workload_task b on a.id = b.id
  left join task_settings c on b.id = c.id
  left join tm_load.workload_task_teacher_settings d on a.id = d.workload_task_id and a.teacher_id = d.teacher_id
), task_teacher_by_student_base as ( -- 查询按学生计的任务和教师，包含多教师情况
  select id, teacher_id, bool_or(primary_teacher) as primary_teacher, parallel_ratio
  from (
    select a.id, c.teacher_id, true as primary_teacher, coalesce(e.parallel_ratio, d.parallel_ratio, 1.0) as parallel_ratio
    from tm_load.workload_task a
    join ea.task b on b.id = any(a.task_ids)
    join ea.course_class c on b.course_class_id = c.id
    left join tm_load.course_workload_settings d on d.course_id = a.course_id and d.department_id = a.department_id
    left join tm_load.workload_task_teacher_settings e on a.id = e.workload_task_id and c.teacher_id = e.teacher_id
    where coalesce(e.workload_type, a.workload_type) <> 0 and a.workload_mode = 2
    union
    select a.id, c.teacher_id, false as primary_teacher, coalesce(e.parallel_ratio, d.parallel_ratio, 1.0) as parallel_ratio
    from tm_load.workload_task a
    join ea.task b on b.id = any(a.task_ids)
    join ea.task_teacher c on c.task_id = b.id
    left join tm_load.course_workload_settings d on d.course_id = a.course_id and d.department_id = a.department_id
    left join tm_load.workload_task_teacher_settings e on a.id = e.workload_task_id and c.teacher_id = e.teacher_id
    where coalesce(e.workload_type, a.workload_type) <> 0 and a.workload_mode = 2
  ) workload_teacher_temp
  group by id, teacher_id, parallel_ratio
), task_teacher_by_student as ( -- 计算学生人数和修正值
  select a.id, b.teacher_id, coalesce(c.workload_type, a.workload_type) as workload_type,
    a.course_credit, case b.primary_teacher
      when true then student_count + coalesce(c.correction, 0)
      else coalesce(c.correction, 0)
    end as student_count,
    coalesce(c.correction, 0) as correction,
    b.parallel_ratio,
    instructional_mode_ratio,
    student_count_upper_bound
  from tm_load.workload_task a
  join task_teacher_by_student_base b on a.id = b.id
  left join tm_load.workload_task_teacher_settings c on a.id = c.workload_task_id and b.teacher_id = c.teacher_id
), workload_by_student as ( -- 计算按学生计的任务工作量
  select id, teacher_id,
    case workload_type
      when 1 then 0
      when 2 then round(course_credit * least(student_count, coalesce(student_count_upper_bound, 1e10)), 0)
    end as workload, correction, parallel_ratio
  from task_teacher_by_student
), task_teacher_by_coursehour_base as ( -- 查询按学时计的任务工作量
  select a.id, b.primary_teacher_id as teacher_id, task_ids, a.course_credit * 17 as workload, a.workload_type
  from tm_load.workload_task a
  join task_settings b on a.id = b.id
  where a.workload_type <> 0 and a.workload_mode = 3
), task_teacher_by_coursehour as ( -- 查询所有任务相关教师情况，包括多教师
  select a.id, a.teacher_id, workload, case coalesce(b.workload_type, a.workload_type)
      when 1 then 0
      when 2 then coalesce(b.correction, 0)
    end as correction
  from task_teacher_by_coursehour_base a
  left join tm_load.workload_task_teacher_settings b on a.id = b.workload_task_id and a.teacher_id = b.teacher_id
  union all
  select a.id, c.teacher_id, workload, case coalesce(d.workload_type, a.workload_type)
      when 1 then 0
      when 2 then coalesce(d.correction, 0)
    end as correction
  from task_teacher_by_coursehour_base a
  join ea.task b on b.id = any(a.task_ids)
  join ea.task_teacher c on b.id = c.task_id
  left join tm_load.workload_task_teacher_settings d on a.id = d.workload_task_id and c.teacher_id = d.teacher_id
  where not exists (
    select 1
    from task_teacher_by_coursehour_base x
    join task_settings y on x.id = y.id
    where x.id = a.id and coalesce(x.teacher_id, y.primary_teacher_id) = c.teacher_id
  )
), task_teacher_by_coursehour_count as (
  select id, count(*) as teacher_count from task_teacher_by_coursehour group by id
), workload_by_coursehour as ( -- 计算按学时计任务的平行班系数
  select a.id, a.teacher_id, workload / teacher_count as workload, a.correction, case
      when e.parallel_ratio is not null then e.parallel_ratio
      when d.parallel_ratio is not null then d.parallel_ratio
      when rank() over(partition by term_id, a.teacher_id, course_id, course_item order by (workload * class_size_ratio / teacher_count + a.correction) desc, code) = 1 then 1.0
      else 0.9
    end as parallel_ratio
  from task_teacher_by_coursehour a
  join tm_load.workload_task b on a.id = b.id
  join task_teacher_by_coursehour_count c on a.id = c.id
  left join task_settings d on a.id = d.id
  left join tm_load.workload_task_teacher_settings e on a.id = e.workload_task_id and a.teacher_id = e.teacher_id
), workload_all as (
  select id as workload_task_id, teacher_id, workload as original_workload, correction, parallel_ratio
  from workload_by_timetable
  union all
  select id as workload_task_id, teacher_id, workload as original_workload, correction, parallel_ratio
  from workload_by_student
  union all
  select id as workload_task_id, teacher_id, workload as original_workload, correction, parallel_ratio
  from workload_by_coursehour
)
select * from workload_all where teacher_id is not null;

/*
 * 更新视图：工作量教学任务-标准工作量和任务顺序
 */
create or replace view tm_load.dvu_workload_task_teacher_standard_workload as
select a.id as workload_task_id, b.teacher_id, rank() over(
    partition by term_id, b.teacher_id
    order by
      course_id,
      case
        when a.primary_teacher_id = b.teacher_id then 1
        else 2
      end,
      translate(substring(a.code from '-(\d+[A-Z]?)(,|$)'), 'ABCDEFG', '1234567')::integer * case
        when a.course_item = '理论' then 10
        else 1
      end,
      a.code,
      course_item
   ) as task_ordinal,
  case coalesce(c.workload_type, a.workload_type)
    when 0 then 0 -- 排除
    when 1 then 0 -- 不计
    when 2 then case workload_mode -- 正常
      when 1 then (original_workload + b.correction) * coalesce(d.ratio, instructional_mode_ratio) * class_size_ratio * b.parallel_ratio -- 按排课
      when 2 then original_workload * coalesce(d.ratio, instructional_mode_ratio) * b.parallel_ratio -- 按学生
      when 3 then (original_workload + b.correction) * coalesce(d.ratio, instructional_mode_ratio) * class_size_ratio * b.parallel_ratio -- 按学时
    end
  end as standard_workload
from tm_load.workload_task a
join tm_load.workload_task_teacher b on a.id = b.workload_task_id
left join tm_load.workload_task_teacher_settings c on a.id = c.workload_task_id and b.teacher_id = c.teacher_id
left join tm_load.instructional_mode d on c.instructional_mode_id = d.id;

/**
 * 辅助视图：教师任务工作量
 */
create or replace view tm_load.av_teacher_workload_by_task as
select term_id, workload_task.id, code, task_ordinal, primary_teacher_id,
  teacher_id, teacher.name as teacher_name, d1.name as teacher_department,
  course_id, course_name, course_item, course_credit, course_property, d2.name as course_class_department,
  case workload_mode
    when 1 then '排课'
    when 2 then '学生'
    when 3 then '学时'
  end as workload_mode,
  case workload_type
    when 0 then '排除'
    when 1 then '不计'
    when 2 then '正常'
  end as workload_type,
  student_count, class_size_ratio, instructional_mode_ratio, parallel_ratio,
  correction, original_workload, standard_workload,
  tm_load.fn_build_workload_task_schedule_string(workload_task.id, workload_task_teacher.teacher_id) as workload_source
from tm_load.workload_task
join tm_load.workload_task_teacher on workload_task.id = workload_task_teacher.workload_task_id
join ea.teacher on workload_task_teacher.teacher_id = teacher.id
join ea.department d1 on d1.id = teacher.department_id
join ea.department d2 on d2.id = workload_task.department_id
order by term_id desc, task_ordinal;

/**
 * 合并视图：教师工作量设置
 */
create or replace view tm_load.dvm_teacher_workload_settings as
select a.id as teacher_id,
  coalesce(b.post_type, '教师岗') as post_type,
  case
    when b.employment_mode = '在编人员' and employment_status in ('在岗', '离岗') then '在编'
    when b.employment_mode = '外籍教师人员' then '外籍'
    else '外聘'
  end as employment_mode,
  coalesce(b.employment_status, '在岗') as employment_status,
  coalesce(b.supplement, false) as supplement
from ea.teacher a
left join tm_load.human_resource_teacher b on a.human_resource_number = b.id
where a.id in (
  select teacher_id from tm_load.workload_task_teacher
  union
  select teacher_id from tm_load.et_external_workload
);

/**
 * 合并视图：教师学期工作量
 */
create or replace view tm_load.dvm_workload as
with teacher_task_workload as (
  select workload_task.term_id, case coalesce(teacher_workload_settings.declaration_type, 2)
      when 1 then workload_task.department_id -- 按开课单位申报
      when 2 then teacher.department_id -- 按教师单位申报
    end as department_id, workload_task_teacher.teacher_id,
    workload_mode, standard_workload, executive_weekly_workload
  from tm_load.workload_task
  join tm_load.workload_task_teacher on workload_task_teacher.workload_task_id = workload_task.id
  join ea.teacher on workload_task_teacher.teacher_id = teacher.id
  join ea.term on workload_task.term_id = term.id
  left join tm_load.teacher_workload_settings on workload_task_teacher.teacher_id = teacher_workload_settings.teacher_id
  where (teacher_workload_settings.workload_type is null or teacher_workload_settings.workload_type <> 0)
)
select term_id, department_id, teacher_id,
  coalesce(sum(standard_workload) filter(where workload_mode = 1), 0.00) as teaching_workload,
  coalesce(sum(standard_workload) filter(where workload_mode in (2, 3)), 0.00) as practice_workload,
  coalesce(executive_weekly_workload, 0.00) * 20 as executive_workload
from teacher_task_workload
group by term_id, department_id, teacher_id, executive_weekly_workload;

/**
 * 合并视图：外部教学学期工作量
 */
create or replace view tm_load.dvm_external_workload as
select a.term_id, b.department_id, a.teacher_id,
  coalesce(a.teaching_workload, 0.00) as external_teaching_workload,
  coalesce(a.practice_workload, 0.00) as external_practice_workload,
  coalesce(a.executive_workload, 0.00) as external_executive_workload,
  coalesce(a.correction, 0.00) as external_correction
from tm_load.et_external_workload a
join ea.teacher b on a.teacher_id = b.id;

/**
 * 更新视图：教师学期工作量-调整与合计
 */
create or replace view tm_load.dvu_workload as
with teacher_term_workload_supplyment as (
  select term_id, department_id, a.teacher_id,
    teaching_workload, practice_workload, executive_workload,
    external_teaching_workload, external_practice_workload,
    external_executive_workload, external_correction, correction,
    case coalesce(b.supplement, b.employment_mode = '在编' and b.employment_status = '在岗')
      when true then round((teaching_workload + external_teaching_workload) / 17.0, 2)
      else 0.00
    end as adjustment_workload,
    case coalesce(b.supplement, b.employment_mode = '在编' and b.employment_status = '在岗')
      when true then round(least(20.00, (teaching_workload + external_teaching_workload) / 17.0 * 2), 2)
      else 0.00 end
    as supplement_workload
  from tm_load.workload a
  left join tm_load.teacher_workload_settings b on a.teacher_id = b.teacher_id
)
select term_id, department_id, teacher_id,
    adjustment_workload, supplement_workload,
    teaching_workload + external_teaching_workload +
    adjustment_workload + supplement_workload +
    practice_workload + external_practice_workload +
    --executive_workload + external_executive_workload +
    correction + external_correction as total_workload
from teacher_term_workload_supplyment;

/**
 * 辅助视图：教师学期工作量
 */
create or replace view tm_load.av_teacher_workload_by_term as
select term_id, workload.department_id, department.name as department_name,
  workload.teacher_id, teacher.name as teacher_name,
  teaching_workload, adjustment_workload, supplement_workload, practice_workload, executive_workload, correction,
  external_teaching_workload, external_practice_workload, external_executive_workload, external_correction,
  total_workload
from tm_load.workload
join ea.teacher on workload.teacher_id = teacher.id
join ea.department on workload.department_id = department.id;

/**
 * 外部视图：为bnuc提供教师学期工作量
 */
create or replace view tm_load.ev_workload as
select term_id, opposite_number as teacher_id, teacher.name as teacher_name,
  teaching_workload, practice_workload, executive_workload, correction, teacher.id as opposite_number
from tm_load.workload
join ea.teacher on workload.teacher_id = teacher.id
where teacher.department_id = '91'
and opposite_number is not null;

/**
 * 合并视图：工作量报表明细
 */
create or replace view tm_load.dvm_workload_report_detail as
with task as (
  select term_id, a.id, code, task_ordinal,
    c.id as teacher_id, c.name as teacher_name, d.name as teacher_department, human_resource_number,
    course_id, course_name, course_item, course_credit, course_property, e.name as course_class_department,
    case workload_mode
      when 1 then '排课'
      when 2 then '学生'
      when 3 then '学时'
    end as workload_mode,
    case coalesce(f.workload_type, a.workload_type)
      when 0 then '排除'
      when 1 then '不计'
      when 2 then '正常'
    end as workload_type,
    student_count_upper_bound, student_count,
    case class_size_source
      when 0 then '缺省'
      when 1 then '专业'
      when 2 then '课程'
      when 3 then '课程项'
      when 4 then '课程性质'
      when 9 then '自定义'
    end as class_size_source,
    class_size_type,
    class_size_ratio,
    case 
      when f.instructional_mode_id is not null then '个人'
      else case instructional_mode_source
        when 0 then '缺省'
        when 1 then '专业'
        when 2 then '课程'
        when 3 then '课程项'
        when 4 then '课程性质'
        when 9 then '自定义'
      end
    end as instructional_mode_source,
    coalesce(g.name, instructional_mode_type) as instructional_mode_type,
    coalesce(g.ratio, instructional_mode_ratio)::numeric(3, 2) as instructional_mode_ratio,
    b.parallel_ratio, b.correction, b.original_workload, b.standard_workload,
    tm_load.fn_build_workload_task_schedule_string(a.id, b.teacher_id) as workload_source,
    course_class_name, course_class_major, f.note
  from tm_load.workload_task a
  join tm_load.workload_task_teacher b on b.workload_task_id = a.id
  join ea.teacher c on b.teacher_id = c.id
  join ea.department d on c.department_id = d.id
  join ea.department e on a.department_id = e.id
  left join tm_load.workload_task_teacher_settings f on a.id = f.workload_task_id and b.teacher_id = f.teacher_id
  left join tm_load.instructional_mode g on f.instructional_mode_id = g.id
  union all
  select term_id, a.id, code, task_ordinal,
    b.id as teacher_id, b.name as teacher_name, c.name as teacher_department, human_resource_number,
    course_id, course_name, course_item, course_credit, course_property, course_class_department,
    workload_mode, workload_type, student_count_upper_bound, student_count,
    class_size_source, class_size_type, class_size_ratio,
    instructional_mode_source, instructional_mode_type, instructional_mode_ratio,
    parallel_ratio, correction, original_workload, standard_workload, workload_source,
    course_class_name, course_class_major, note
  from tm_load.et_teacher_workload_by_task a
  join ea.teacher b on a.teacher_id = b.opposite_number
  join ea.department c on b.department_id = c.id
)
select term_id,
  human_resource_teacher.id as human_resource_id,
  human_resource_teacher.name as human_resource_name,
  human_resource_teacher.department as human_resource_department,
  teacher_workload_settings.employment_mode,
  teacher_workload_settings.post_type,
  task.teacher_id,
  task.teacher_name,
  task.teacher_department,
  task.id as workload_task_id,
  task.code as workload_task_code,
  task.task_ordinal,
  course_id,
  course_name,
  course_item,
  course_credit,
  course_property,
  course_class_department,
  task.workload_mode,
  task.workload_type,
  student_count_upper_bound,
  student_count,
  class_size_source,
  class_size_type,
  class_size_ratio,
  instructional_mode_source,
  instructional_mode_type,
  instructional_mode_ratio,
  parallel_ratio,
  correction,
  original_workload,
  standard_workload,
  workload_source,
  course_class_name,
  course_class_major,
  note,
  encode(digest(term_id
    || coalesce(human_resource_teacher.id, '') || coalesce(human_resource_teacher.name, '') ||  coalesce(human_resource_teacher.department, '')
    || coalesce(teacher_workload_settings.employment_mode, '') || coalesce(teacher_workload_settings.post_type, '')
    || task.teacher_name || task.teacher_department || task.code || task.task_ordinal
    || course_id || course_name || coalesce(course_item, '') || course_credit || course_property || course_class_department
    || task.workload_mode || task.workload_type || coalesce(student_count_upper_bound, 1e10) || student_count
    || class_size_source|| class_size_type || class_size_ratio
    || instructional_mode_source|| instructional_mode_type || instructional_mode_ratio
    || parallel_ratio || correction || original_workload || standard_workload
    || coalesce(workload_source, '') || coalesce(course_class_name, '') || coalesce(course_class_major, '') || coalesce(note, ''),
  'md5'), 'hex') as hash_value
from task
join tm_load.teacher_workload_settings on teacher_workload_settings.teacher_id= task.teacher_id
left join tm_load.human_resource_teacher on human_resource_teacher.id = task.human_resource_number
order by term_id, task.teacher_department, task.teacher_id, task.task_ordinal;

/**
 * 合并视图：教师学期工作量
 */
create or replace view tm_load.dvm_workload_report as
select term_id,
  human_resource_teacher.id as human_resource_id,
  human_resource_teacher.name as human_resource_name,
  human_resource_teacher.department as human_resource_department,
  teacher_workload_settings.employment_mode,
  teacher_workload_settings.post_type,
  teacher.id as teacher_id,
  teacher.name as teacher_name,
  department.name as teacher_department,
  teaching_workload,
  external_teaching_workload,
  adjustment_workload,
  supplement_workload,
  practice_workload,
  external_practice_workload,
  executive_workload,
  external_executive_workload,
  correction,
  external_correction,
  total_workload,
  note,
  encode(digest(term_id
    || coalesce(human_resource_teacher.id, '') || coalesce(human_resource_teacher.name, '') ||  coalesce(human_resource_teacher.department, '')
    || coalesce(teacher_workload_settings.employment_mode, '') || coalesce(teacher_workload_settings.post_type, '')
    || teaching_workload || external_teaching_workload || adjustment_workload || supplement_workload
    || practice_workload || external_practice_workload
    || executive_workload || external_executive_workload
    || correction || external_correction || total_workload || coalesce(note, ''),
  'md5'), 'hex') as hash_value
from tm_load.workload
join ea.teacher on workload.teacher_id = teacher.id
join ea.department on workload.department_id = department.id
join tm_load.teacher_workload_settings on teacher_workload_settings.teacher_id= workload.teacher_id
left join tm_load.human_resource_teacher on human_resource_teacher.id = teacher.human_resource_number
order by term_id, department.name, workload.teacher_id;

/**
 * 报表视图：工作量报表明细
 */
create or replace view tm_load.rv_workload_report_detail as
select term_id, human_resource_id, human_resource_name, human_resource_department, employment_mode, post_type,
  teacher_id, teacher_name, teacher_department, workload_task_code,
  course_id, course_name, course_item, course_credit, course_property, course_class_department, workload_mode,
  workload_type, student_count, class_size_ratio, instructional_mode_ratio, parallel_ratio, correction,
  original_workload, standard_workload, workload_source, course_class_name, course_class_major, note
from tm_load.workload_report_detail
where date_invalid is null
order by term_id, teacher_department, teacher_id, task_ordinal;

/**
 * 报表视图：工作量报表
 */
create or replace view tm_load.rv_workload_report as
select term_id, human_resource_id, human_resource_name, human_resource_department, employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  teaching_workload, external_teaching_workload,
  adjustment_workload, supplement_workload,
  practice_workload, external_practice_workload,
  -- executive_workload, external_executive_workload,
  correction, external_correction,
  total_workload, note
from tm_load.workload_report
where date_invalid is null
order by term_id, teacher_department, teacher_id;


/**
 * 辅助视图：工作量报表明细差异
 */
create or replace view tm_load.av_workload_report_detail_diff as
with invalid_item as (
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
  workload_source, course_class_name, course_class_major, note, hash_value, date_created, date_invalid
  from tm_load.workload_report_detail
  where date_invalid is not null
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
  workload_source, course_class_name, course_class_major, note, hash_value, date_created, date_invalid
from invalid_item
union
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
  workload_source, course_class_name, course_class_major, note, hash_value, date_created, date_invalid
from tm_load.workload_report_detail
where date_invalid is null
and (term_id, teacher_id, workload_task_code) in (
  select term_id, teacher_id, workload_task_code
  from invalid_item
)
order by term_id, teacher_department, teacher_id, workload_task_code, date_created;

/**
 * 辅助视图：最新工作量报表明细差异
 */
create or replace view tm_load.av_workload_report_latest_detail_diff as
with term_last_update as (
  select term_id, max(date_created) as last_update
  from tm_load.av_workload_report_detail_diff
  group by term_id
)
select * from tm_load.av_workload_report_detail_diff
where (term_id, date_created) in (
  select term_id, last_update from term_last_update
) or (term_id, date_invalid) in (
  select term_id, last_update from term_last_update
);


/**
 * 辅助视图：工作量报表差异
 */
create or replace view tm_load.av_workload_report_diff as
with invalid_item as (
  select term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  teaching_workload, external_teaching_workload,
  adjustment_workload, supplement_workload,
  practice_workload, external_practice_workload,
  executive_workload, external_executive_workload,
  correction, external_correction, total_workload,
  note, hash_value, date_created, date_invalid
  from tm_load.workload_report
  where date_invalid is not null
)
select term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  teaching_workload, external_teaching_workload,
  adjustment_workload, supplement_workload,
  practice_workload, external_practice_workload,
  executive_workload, external_executive_workload,
  correction, external_correction, total_workload,
  note, hash_value, date_created, date_invalid
  from invalid_item
union
select term_id,
  human_resource_id, human_resource_name, human_resource_department,
  employment_mode, post_type,
  teacher_id, teacher_name, teacher_department,
  teaching_workload, external_teaching_workload,
  adjustment_workload, supplement_workload,
  practice_workload, external_practice_workload,
  executive_workload, external_executive_workload,
  correction, external_correction, total_workload,
  note, hash_value, date_created, date_invalid
  from tm_load.workload_report
where date_invalid is null
and (term_id, teacher_id, teacher_department) in (
  select term_id, teacher_id, teacher_department
  from invalid_item
)
order by term_id, teacher_department, teacher_id, date_created;

/**
 * 辅助视图：最新工作量报表差异
 */
create or replace view tm_load.av_workload_report_latest_diff as
with term_last_update as (
  select term_id, max(date_created) as last_update
  from tm_load.av_workload_report_diff
  group by term_id
)
select * from tm_load.av_workload_report_diff
where (term_id, date_created) in (
  select term_id, last_update from term_last_update
) or (term_id, date_invalid) in (
  select term_id, last_update from term_last_update
);

/**
 * 辅助视图：工作量任务
 */
create or replace view tm_load.av_workload_task as
select workload_task.id, term_id, department.name as course_class_department, code,
  course_id, course_name, course_item, course_credit, course_property,
  array_to_string(array(
    select e.grade || '级' || f.short_name
    from ea.course_class_program a
    join ea.course_class b on a.course_class_id = b.id
    join ea.task c on c.course_class_id = b.id
    join ea.program d on a.program_id = d.id
    join ea.major e on d.major_id = e.id
    join ea.subject f on e.subject_id = f.id
    where c.id = any(workload_task.task_ids)
    order by e.grade, f.short_name
  ), ',') as majors,
  array_to_string(array_agg(teacher.name order by case
    when primary_teacher_id = teacher_id then 1
    else 2
  end), '/') as teachers,
  student_count, string_agg(
    teacher.name || ':' || tm_load.fn_build_workload_task_schedule_string(workload_task.id, workload_task_teacher.teacher_id)
  , '/') as schedules
from tm_load.workload_task
join tm_load.workload_task_teacher on workload_task.id = workload_task_teacher.workload_task_id
join ea.teacher on workload_task_teacher.teacher_id = teacher.id
join ea.department on department.id = workload_task.department_id
group by term_id, department.name, code, workload_task.id, task_ids, course_id, course_name, course_item, course_credit, course_property, student_count
order by term_id, department.name, code;

/**
 * 辅助视图：教师工作量设置
 */
create or replace view tm_load.av_teacher_workload_settings as
select c.name as department, teacher_id, b.name as teacher_name, supplement,
  employment_mode, employment_status, workload_type, declaration_type, executive_weekly_workload
from tm_load.teacher_workload_settings a
join ea.teacher b on a.teacher_id = b.id
join ea.department c on b.department_id = c.id;

/**
 * 辅助视图：最新工作量报表差异JSON
 */
create or replace view tm_load.av_workload_report_latest_detail_diff_json as
with latest as (
  select max(date_created) - interval '1hour' as lastest_date from tm_load.workload_report_detail
), diff as (
  select a as x, lag(a) over(partition by a.workload_task_id, a.teacher_id order by date_created) as y,
    count(*) over(partition by a.workload_task_id, a.teacher_id) as row_count
  from tm_load.workload_report_detail a
  where date_invalid >= (select lastest_date from latest)
     or date_created >= (select lastest_date from latest)
)
select jsonb_pretty(jsonb_build_object(
  'term_id', (x).term_id,
  'teacher_id', (x).teacher_id,
  'teacher_name', (x).teacher_name,
  'teacher_department', (x).teacher_department,
  'workload_task_id', (x).workload_task_id,
  'workload_task_code', (x).workload_task_code,
  'course_id', (x).course_id,
  'course_name', (x).course_name,
  'course_item', (x).course_item,
  'course_credit', (x).course_credit,
  'course_property', (x).course_property,
  'course_class_department', (x).course_class_department
)) as base_info,
jsonb_pretty(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
  'date_created', json_build_object(
    'old', (y).date_created, 'new', (x).date_created
  ),
  'date_invalid', json_build_object(
    'old', (y).date_invalid, 'new', (x).date_invalid
  ),
  'workload_mode', case
    when (x).workload_mode is distinct from (y).workload_mode
    then jsonb_build_object('old', (y).workload_mode, 'new', (x).workload_mode)
  end,
  'workload_type', case
    when (x).workload_type is distinct from (y).workload_type
    then jsonb_build_object('old', (y).workload_type, 'new', (x).workload_type)
  end,
  'student_count', case
    when (x).student_count is distinct from (y).student_count
    then jsonb_build_object('old', (y).student_count, 'new', (x).student_count)
  end,
  'class_size_ratio', case
    when (x).class_size_ratio is distinct from (y).class_size_ratio
    then jsonb_build_object('old', (y).class_size_ratio, 'new', (x).class_size_ratio)
  end,
  'instructional_mode_ratio', case
    when (x).instructional_mode_ratio is distinct from (y).instructional_mode_ratio
    then jsonb_build_object('old', (y).instructional_mode_ratio, 'new', (x).instructional_mode_ratio)
  end,
  'parallel_ratio', case
    when (x).parallel_ratio is distinct from (y).parallel_ratio
    then jsonb_build_object('old', (y).parallel_ratio, 'new', (x).parallel_ratio)
  end,
  'correction', case
    when (x).correction is distinct from (y).correction
    then jsonb_build_object('old', (y).correction, 'new', (x).correction)
  end,
  'original_workload', case
    when (x).original_workload is distinct from (y).original_workload
    then jsonb_build_object('old', (y).original_workload, 'new', (x).original_workload)
  end,
  'standard_workload', case
    when (x).standard_workload is distinct from (y).standard_workload
    then jsonb_build_object('old', (y).standard_workload, 'new', (x).standard_workload)
  end,
  'workload_source', case
    when (x).workload_source is distinct from (y).workload_source
    then jsonb_build_object('old', (y).workload_source, 'new', (x).workload_source)
  end
)) order by (x).date_created desc)) as diff_info
from diff
where row_count = 1 or row_count > 1 and (y).workload_task_id is not null
group by (x).term_id, (x).teacher_department, (x).teacher_id, (x).teacher_name,
  (x).workload_task_id, (x).workload_task_code,
  (x).course_id, (x).course_name, (x).course_item, (x).course_credit, (x).course_property, (x).course_class_department
order by (x).term_id, (x).teacher_department, (x).teacher_id, (x).workload_task_code;

-- 无工作量的教师
create or replace view tm_load.av_teacher_without_workload as
with teacher as (
    select b.id as human_resouce_id, b.name as human_resouce_name, b.department as human_resouce_department,
        a.employment_mode, a.post_type,
        b.teacher_id, c.name as teacher_name, d.name as teacher_department
    from tm_load.teacher_workload_settings a
    join tm_load.human_resource_teacher b on a.teacher_id = b.teacher_id
    join ea.teacher c on a.teacher_id = c.id
    join ea.department d on c.department_id = d.id
    where a.employment_mode = '在编' and a.employment_status = '在岗'
), term as (
    select distinct term_id
    from tm_load.rv_workload_report
)
select y.term_id, x.*, 0 as workload
from teacher x, term y
where not exists (
    select * from
    tm_load.rv_workload_report
    where teacher_id = x.teacher_id
    and term_id = y.term_id
);