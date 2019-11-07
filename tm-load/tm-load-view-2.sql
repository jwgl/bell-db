/*
 * 辅助视图：教学安排
 */
create or replace view tm_load.dva_task_schedule_base as
select term_id, department_id, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id, workload_type, workload_mode,
  array_agg(distinct (course_id, course_name)::tm_load.t_text_pair order by (course_id, course_name)::tm_load.t_text_pair) as courses,
  max(course_credit) as course_credit,
  string_agg(distinct course_item_name, ',' order by course_item_name) as course_item,
  string_agg(task_code, ',' order by task_ordinal) as task_codes,
  min(task_ordinal) as task_ordinal,
  array_agg(task_id order by task_ordinal) as task_ids,
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
    coalesce(course_item_workload_settings.workload_type, course_workload_settings.workload_type, 2 /*正常*/) as workload_type,
    coalesce(course_item_workload_settings.workload_mode, course_workload_settings.workload_mode, 1 /*课时*/) as workload_mode
  from ea.task_schedule
  join ea.task on task.id = task_schedule.task_id
  join ea.course_class on course_class.id = task.course_class_id
  join ea.course on course.id = course_class.course_id
  left join ea.course_item on course_item.id = task.course_item_id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
  left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
  where term_id >= 20171
) x
group by term_id, department_id, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id, workload_type, workload_mode;

/*
 * 辅助视图：已排课教学任务
 */
create or replace view tm_load.dva_task_with_timetable as
select distinct term_id, department_id, task_codes as code, task_ids,
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
  coalesce(course_item_workload_settings.workload_type, course_workload_settings.workload_type, 2 /*正常*/) as workload_type,
  coalesce(course_item_workload_settings.workload_mode, course_workload_settings.workload_mode, 1 /*课时*/) as workload_mode
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
left join ea.course_item on task.course_item_id = course_item.id
left join ea.task_schedule on task_schedule.task_id = task.id
left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
left join tm_load.course_item_workload_settings on course_item_workload_settings.course_item_id = task.course_item_id and course_item_workload_settings.department_id = course_class.department_id
where term_id >= 20171
and task_schedule.id is null; -- 未排课

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
 * 更新视图：工作量教学任务-课程性质
 */
create or replace view tm_load.dvu_workload_task_course_property as
select workload_task.id as workload_task_id, string_agg(distinct coalesce(p1.name, p2.name), ',' order by coalesce(p1.name, p2.name)) as course_property
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
  class_size_ratio.ratio
from task
join tm_load.class_size_type on class_size_type.id = task.class_size_type_id
left join tm_load.class_size_ratio on class_size_ratio.type_id = task.class_size_type_id
  and task.student_count between class_size_ratio.lower_bound and class_size_ratio.upper_bound;

/*
 * 更新视图：工作量教学任务-教学形式
 */
create or replace view tm_load.dvu_workload_task_instructional_mode as
with task as (
  select workload_task.id as workload_task_id,
    coalesce(
      course_item_workload_settings.instructional_mode_id,
      course_workload_settings.instructional_mode_id,
      10 -- 理论课
    ) as instructional_mode_id,
    case
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
  where workload_task.instructional_mode_source is null or workload_task.instructional_mode_source <> 9
)
select distinct on (workload_task_id) workload_task_id,
  instructional_mode_source as source,
  instructional_mode.name as type,
  instructional_mode.ratio, instructional_mode.upper_bound
from task
join tm_load.instructional_mode on instructional_mode.id = task.instructional_mode_id;

/*
 * 合并视图：工作量教师表
 */
create or replace view tm_load.dvm_workload_task_teacher as
with task as ( -- 查询所有任务的主讲教师和平行班系数设置
  select workload_task.id, primary_teacher_id, course_workload_settings.parallel_ratio
  from tm_load.workload_task
  join ea.task on task.id = any(workload_task.task_ids)
  join ea.course_class on course_class.id = task.course_class_id
  left join tm_load.course_workload_settings on course_workload_settings.course_id = course_class.course_id and course_workload_settings.department_id = course_class.department_id
), task_settings as ( -- 合并主讲教师和平行班系数设置
  select distinct on (id) id, parallel_ratio, primary_teacher_id
  from task
  order by id, coalesce(parallel_ratio, 0.9) desc
), task_teacher_by_timetable_base as ( -- 计算任务教师排课工作量
  select workload_task.id, teacher_id, task_ids, sum(case workload_task.workload_type
      when 1 then 0
      when 2 then coalesce(ea.fn_weeks_count(start_week, end_week, odd_even) * total_section, 0)
    end) as workload, workload_task.workload_type
  from tm_load.workload_task
  left join tm_load.workload_task_schedule on workload_task_schedule.workload_task_id = workload_task.id
  where workload_task.workload_type <> 0 and workload_task.workload_mode = 1
  group by workload_task.id, teacher_id
), task_teacher_by_timetable as ( -- 查询所有任务相关教师情况，包括多教师
  select a.id, coalesce(a.teacher_id, c.primary_teacher_id) as teacher_id, workload, case a.workload_type
      when 1 then 0
      when 2 then coalesce(correction, 0)
    end as correction
  from task_teacher_by_timetable_base a
  left join tm_load.workload_task_teacher b on a.id = b.workload_task_id and a.teacher_id = b.teacher_id
  left join task_settings c on a.id = c.id
  union
  select a.id, task_teacher.teacher_id, coalesce(correction, 0) as workload, coalesce(correction, 0) correction
  from task_teacher_by_timetable_base a
  join ea.task on task.id = any(a.task_ids)
  join ea.task_teacher on task.id = task_teacher.task_id
  left join tm_load.workload_task_teacher on a.id = workload_task_teacher.workload_task_id and task_teacher.teacher_id = workload_task_teacher.teacher_id
  where (a.id, task_teacher.teacher_id) not in (
    select x.id, coalesce(x.teacher_id, y.primary_teacher_id)
    from task_teacher_by_timetable_base x
    join task_settings y on x.id = y.id
  )
), workload_by_timetable as ( -- 计算课时任务的平行班系数
  select a.id, coalesce(a.teacher_id, c.primary_teacher_id) as teacher_id, workload, correction, case
      when c.parallel_ratio is not null then c.parallel_ratio
      when rank() over(partition by term_id, teacher_id, course_name, course_credit, course_item order by (workload + correction) desc, code) = 1 then 1.0
      else 0.9
    end as parallel_ratio
  from task_teacher_by_timetable a
  join tm_load.workload_task b on a.id = b.id
  left join task_settings c on b.id = c.id
), task_teacher_by_student_base as ( -- 查询按学生计的任务和教师，包含多教师情况
  select id, teacher_id, bool_or(primary_teacher) as primary_teacher
  from (
    select workload_task.id, course_class.teacher_id, true as primary_teacher
    from tm_load.workload_task
    join ea.task on task.id = any(workload_task.task_ids)
    join ea.course_class on task.course_class_id = course_class.id
    where workload_mode = 2
    union
    select workload_task.id, task_teacher.teacher_id, false as primary_teacher
    from tm_load.workload_task
    join ea.task on task.id = any(workload_task.task_ids)
    join ea.task_teacher on task_teacher.task_id = task.id
    where workload_mode = 2
  ) workload_teacher_temp
  group by id, teacher_id
), task_teacher_by_student as ( -- 计算学生人数和修正值
  select a.id, b.teacher_id, a.workload_type, a.course_credit, case b.primary_teacher
      when true then student_count + coalesce(c.correction, 0)
      else coalesce(c.correction, 0)
    end as student_count,
    coalesce(c.correction, 0) as correction,
    instructional_mode_ratio
  from tm_load.workload_task a
  join task_teacher_by_student_base b on a.id = b.id
  left join tm_load.workload_task_teacher c on a.id = c.workload_task_id and b.teacher_id = c.teacher_id
  where a.workload_type <> 0
), workload_by_student as ( -- 计算按学生计的任务工作量
  select id, teacher_id,
    case workload_type
      when 1 then 0
      when 2 then course_credit * student_count * instructional_mode_ratio
    end as workload, correction, 1.0 as parallel_ratio
  from task_teacher_by_student
)
select id as workload_task_id, teacher_id, workload as original_workload, correction, parallel_ratio
from workload_by_timetable
union all
select id as workload_task_id, teacher_id, workload as original_workload, correction, parallel_ratio
from workload_by_student;

/*
 * 更新视图：工作量教学任务-标准工作量和任务顺序
 */
create or replace view tm_load.workload_task_teacher_standard_workload as
select workload_task.id as workload_task_id, workload_task_teacher.teacher_id, rank() over(
    partition by term_id, workload_task_teacher.teacher_id
    order by
      course_id,
      case when workload_task.primary_teacher_id = workload_task_teacher.teacher_id then 1 else 2 end,
      translate(substring(workload_task.code from '-(\d+[A-Z]?)$'), 'ABCDEFG', '1234567')::integer * case when workload_task.course_item = '理论' then 10 else 1 end
   ) as task_ordinal,
  case workload_type
    when 0 then 0 -- 排除
    when 1 then 0 -- 不计
    when 2 then case workload_mode -- 正常
      when 1 then original_workload * class_size_ratio * instructional_mode_ratio * parallel_ratio
      when 2 then original_workload
    end
  end as standard_workload
from tm_load.workload_task
join tm_load.workload_task_teacher on workload_task.id = workload_task_teacher.workload_task_id;

/**
 * 辅助视图：教师任务工作量
 */
create or replace view tm_load.av_teacher_workload_by_task as
select term_id, code, task_ordinal, primary_teacher_id,
  teacher_id, teacher.name as teacher_name, d1.name as teacher_department,
  course_id, course_name, course_item, course_property, d2.name as course_class_department,
  workload_mode, workload_type, student_count,
  class_size_ratio, instructional_mode_ratio, parallel_ratio,
  correction, original_workload, standard_workload
from tm_load.workload_task
join tm_load.workload_task_teacher on workload_task.id = workload_task_teacher.workload_task_id
join ea.teacher on workload_task_teacher.teacher_id = teacher.id
join ea.department d1 on d1.id = teacher.department_id
join ea.department d2 on d2.id = workload_task.department_id
order by term_id desc, task_ordinal;

/**
 * 合并视图：教师学期工作量
 */
create or replace view tm_load.dvm_workload as
with teacher_task_workload as (
  select workload_task.term_id, case coalesce(teacher_workload_settings.declaration_type, 2)
      when 1 then workload_task.department_id -- 按开课单位申报
      when 2 then teacher.department_id -- 按教师单位申报
    end as department_id, workload_task_teacher.teacher_id,
    workload_mode, standard_workload
  from tm_load.workload_task
  join tm_load.workload_task_teacher on workload_task_teacher.workload_task_id = workload_task.id
  join ea.teacher on workload_task_teacher.teacher_id = teacher.id
  join ea.term on workload_task.term_id = term.id
  left join tm_load.teacher_workload_settings on workload_task_teacher.teacher_id = teacher_workload_settings.teacher_id
  where (teacher_workload_settings.workload_type is null or teacher_workload_settings.workload_type <> 0)
), teacher_term_workload_base as (
  select term_id, department_id, teacher_id,
    sum(standard_workload) filter(where workload_mode = 1) as teaching_workload,
    sum(standard_workload) filter(where workload_mode = 2) as practice_workload
  from teacher_task_workload
  group by term_id, department_id, teacher_id
), teacher_term_workload as (
  select term_id, department_id, teacher_term_workload_base.teacher_id,
    coalesce(teaching_workload, 0.00) as teaching_workload,
    coalesce(practice_workload, 0.00) as practice_workload,
    coalesce(teacher_workload_settings.supplement, coalesce(teacher_workload_settings.employment_mode, '外聘') = '在编') as need_supplement,
    coalesce(executive_weekly_workload, 0.00) as executive_weekly_workload
  from teacher_term_workload_base
  left join tm_load.teacher_workload_settings on teacher_term_workload_base.teacher_id = teacher_workload_settings.teacher_id
)
select term_id, department_id, teacher_id, teaching_workload,
  case need_supplement when true then round(teaching_workload / 17.0, 2) else 0.00 end as adjustment_workload,
  case need_supplement when true then round(least(20.00, teaching_workload / 17.0 * 2), 2) else 0.00 end as supplement_workload,
  practice_workload,
  executive_weekly_workload * 20 as executive_workload
from teacher_term_workload
order by term_id, department_id, teacher_id;

create or replace view tm_load.av_teacher_workload_by_term as
select term_id, workload.department_id, department.name as department_name, 
  workload.teacher_id, teacher.name as teacher_name,
  teaching_workload, adjustment_workload, supplement_workload, practice_workload, executive_workload,
  correction, total_workload
from tm_load.workload
join ea.teacher on workload.teacher_id = teacher.id
join ea.department on workload.department_id = department.id;