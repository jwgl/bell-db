-- 菜单
create or replace view ea.dv_menu as
with recursive r as (
    select m.id, m.name, m.label_cn, m.label_en,
        m.id as root,
        1 as path_level,
        to_char(m.display_order, '09') as display_order
    from ea.menu m
    where array_length(regexp_split_to_array(m.id, E'\\.'), 1) = 1
    union all
    select m.id, m.name, m.label_cn, m.label_en,
        r.root as root,
        array_length(regexp_split_to_array(m.id, E'\\.'), 1),
        r.display_order || to_char(m.display_order, '09')
    from ea.menu m
    join r on strpos(m.id, r.id) = 1 and array_length(regexp_split_to_array(m.id, E'\\.'), 1) = r.path_level + 1
)
select id, name, label_cn, label_en, path_level -1 as menu_level, root from r
where path_level > 1
order by display_order;

-- 辅助视图
-- 教学班
create or replace view ea.av_course_class as
select cc.term_id, cc.id, cc.code, c.name as course,
  c.credit, d.name as department,
  coalesce(p.name, array_to_string(array(
    select distinct property.name
    from ea.course_class_program ccp
    join ea.program_course pc on pc.program_id = ccp.program_id
    join ea.property on pc.property_id = property.id
    where pc.course_id = c.id
    and ccp.course_class_id = cc.id
    ), ',')) as property,
  t.name as teacher,
  cc.start_week, cc.end_week,
  case cc.assess_type
    when 1 then '考试'
    when 2 then '考查'
    when 3 then '毕业论文'
    else '其它'
  end as assess_type,
  case cc.test_type
    when 1 then '集中'
    when 2 then '分散'
    else '其它'
  end as test_type,
  (
    select count(distinct student_id)
    from task_student
    join task on task_student.task_id = task.id
    where task.course_class_id = cc.id
  ) as student_count
from course_class cc
join course c on c.id = cc.course_id
join teacher t on t.id = cc.teacher_id
join department d on d.id = cc.department_id
left join property p on p.id = cc.property_id;

-- 教学任务
create or replace view ea.av_task as
select task.id, cc.term_id, c.id as course_id, c.name as course_name,
    ci.name as course_item,
    array_agg(t.name) as teacher_name,
    count(t.id) as teacher_count,
    task.code
from task
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join task_teacher tt on tt.task_id = task.id
join teacher t on t.id = tt.teacher_id
left join course_item ci on task.course_item_id = ci.id
group by term_id, task.id, c.id, c.name, ci.name, task.code;

-- 教学安排
create or replace view ea.av_task_schedule as
select a.id, cc.term_id, c.id as course_id, c.name as course_name, ci.name as course_item,
    te.id as teacher_id, te.name as teacher_name, a.start_week, a.end_week,
    day_of_week, start_section, total_section, odd_even, place_id, task_id, task.code as task_code, course_class_id, d.name as department
from task_schedule a
join task on a.task_id = task.id
join course_class cc on cc.id = task.course_class_id
join department d on d.id = cc.department_id
join course c on c.id = cc.course_id
join teacher te on te.id = a.teacher_id
left join course_item ci on ci.id = task.course_item_id;

-- 学生课表
create or replace view ea.av_student_schedule as
select student.id as student_id, student.name as student_name, a.id as task_schedule_id, cc.term_id, c.id as course_id, c.name as course_name, ci.name as course_item,
    te.id as teacher_id, te.name as teacher_name, a.start_week, a.end_week,
    day_of_week, start_section, total_section, odd_even, place_id, task.id as task_id, task.code as task_code, course_class_id,
    ts.repeat_type
from task
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join task_schedule a on a.task_id = task.id
join task_student ts on ts.task_id = task.id
join student on student.id = ts.student_id
join teacher te on te.id = a.teacher_id
left join course_item ci on ci.id = task.course_item_id;

-- 学生信息
create or replace view ea.av_student as
select student.id, student.name, d.id || '-' || d.name as department, m.grade || '-' || s.name as subject, ac.name as adimin_class,
       t1.id || '-' || t1.name as counsellor, t1.id || '-' || t2.name supervisor
from student
join admin_class ac on ac.id = student.admin_class_id
join department d on d.id = student.department_id
join major m on m.id = student.major_id
join subject s on s.id = m.subject_id
left join teacher t1 on t1.id = ac.counsellor_id
left join teacher t2 on t2.id = ac.supervisor_id;

-- 教学工作量
create or replace view ea.av_teacher_workload as
with teacher_schedule as (
  select term_id,
    course_class.department_id as course_class_department_id,
    teacher.id as teacher_id,
    teacher.name as teacher_name,
    teacher.department_id as teacher_department_id,
    task.code || '|' || ea.fn_timetable_to_string(task_schedule.start_week, task_schedule.end_week, task_schedule.odd_even,
      task_schedule.day_of_week, task_schedule.start_section, task_schedule.total_section) as task_code,
    course_class.property_id,
    ea.fn_weeks_to_integer(task_schedule.start_week, task_schedule.end_week, task_schedule.odd_even)::bit(32) weeks,
    task_schedule.day_of_week,
    ea.fn_sections_to_integer(task_schedule.start_section, task_schedule.total_section)::bit(16) sections,
    case
      when course_class.property_id is not null
        then array[course_class.property_id]
      else array(select distinct property_id
        from ea.program_course pc
        join ea.course_class_program ccp on pc.program_id = ccp.program_id
        where pc.course_id = course_class.course_id
        and ccp.course_class_id = course_class.id)
    end as course_class_properties
  from ea.course_class
  join ea.task on task.course_class_id = course_class.id
  join ea.task_schedule on task_schedule.task_id = task.id
  join ea.teacher on task_schedule.teacher_id = teacher.id
  join ea.department course_class_department on course_class_department.id = course_class.department_id
  join ea.department teacher_department on teacher_department.id = teacher.department_id
  where task_schedule.place_id not like 'B%'
  and term_id >= (select id - 20 from ea.term where active = true)
  and exists(select * from ea.task_student where task_student.task_id = task.id)
), schedule_normal as (
  select term_id, course_class_department_id, teacher_id, teacher_name, teacher_department_id, property_id, weeks, day_of_week, sections, course_class_properties,
    array_agg(task_code order by task_code) as task_codes
  from teacher_schedule
  group by term_id, course_class_department_id, teacher_id, teacher_name, teacher_department_id, property_id, weeks, day_of_week, sections, course_class_properties
)
select term_id, course_class_department_id, teacher_id, teacher_name, teacher_department_id, course_class_properties,
  length(replace(weeks::text, '0', '')) * length(replace(sections::text, '0', '')) as workload, task_codes
from schedule_normal;

-- 按开课单位查询教师工作量
create or replace view ea.av_teacher_workload_by_course_class_department as
select term_id, course_class_department.name as course_class_department,
  t.id as teacher_id, t.name as teacher_name, teacher_department.name as teacher_department,
  t.is_external or (course_class_department.name <> teacher_department.name) as is_external,
  sum(workload) as workload,
  sum(workload) filter (where tw.course_class_properties && array[1]) as public_compulsory_workload,
  sum(workload) filter (where tw.course_class_properties && array[2,3]) as public_elective_workload
from av_teacher_workload tw
join teacher t on tw.teacher_id = t.id
join department course_class_department on tw.course_class_department_id = course_class_department.id
join department teacher_department on tw.teacher_department_id = teacher_department.id
group by term_id, course_class_department.name, t.id, t.name, teacher_department.name;

-- 按教师所在单位查询教师工作量
create or replace view ea.av_teacher_workload_by_teacher_department as
select term_id, d.id as department_id, d.name as department, t.id as teacher_id, t.name as teacher_name, t.is_external,
  count(*) as workload,
  count(*) filter (where tw.properties && array[1]) as public_compulsory_workload,
  count(*) filter (where tw.properties && array[2,3]) as public_elective_workload
from av_teacher_workload tw
join teacher t on tw.teacher_id = t.id
join department d on tw.teacher_department_id = d.id
group by term_id, d.id, d.name, t.id, t.name;
