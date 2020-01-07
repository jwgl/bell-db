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
select cc.term_id, cc.id, cc.code, c.id as course_id, c.name as course_name,
  c.credit, d.name as department,
  coalesce(p.name, array_to_string(array(
    select distinct property.name
    from ea.course_class_program ccp
    join ea.program_course pc on pc.program_id = ccp.program_id
    join ea.property on pc.property_id = property.id
    where pc.course_id = c.id
    and ccp.course_class_id = cc.id
    ), ',')) as property,
  array_to_string(array(
    select distinct major.grade || '级' || subject.short_name
    from ea.course_class_program ccp
    join ea.program_course pc on pc.program_id = ccp.program_id
    join ea.property on pc.property_id = property.id
    join ea.program on pc.program_id = program.id
    join ea.major on program.major_id = major.id
    join ea.subject on major.subject_id = subject.id
    where pc.course_id = c.id
    and ccp.course_class_id = cc.id
  ), ',') as major,
  t.id as teacher_id,
  t.name as teacher_name,
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
    day_of_week, start_section, total_section, odd_even, place_id, place.name as place,
    task_id, task.code as task_code, course_class_id, d.name as department, week_bits, section_bits
from task_schedule a
join task on a.task_id = task.id
join course_class cc on cc.id = task.course_class_id
join department d on d.id = cc.department_id
join course c on c.id = cc.course_id
join teacher te on te.id = a.teacher_id
left join course_item ci on ci.id = task.course_item_id
left join place on place.id = a.place_id;

-- 学生课表
create or replace view ea.av_student_schedule as
select student.id as student_id, student.name as student_name, a.id as task_schedule_id, cc.term_id, c.id as course_id, c.name as course_name, ci.name as course_item,
    te.id as teacher_id, te.name as teacher_name, a.start_week, a.end_week,
    day_of_week, start_section, total_section, odd_even, week_bits, section_bits,
    place.id as place_id, place.name as place_name,
    task.id as task_id, task.code as task_code, course_class_id,
    ts.repeat_type
from task
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join task_schedule a on a.task_id = task.id
join task_student ts on ts.task_id = task.id
join student on student.id = ts.student_id
join teacher te on te.id = a.teacher_id
left join course_item ci on ci.id = task.course_item_id
left join place on place.id = a.place_id;

-- 学生信息
create or replace view ea.av_student as
select student.id, student.name, d.id as department_id, d.name as department_name, m.grade,
  s.name as subject, ac.name as adimin_class,
  t1.id || '-' || t1.name as counsellor, t1.id || '-' || t2.name supervisor, student.at_school
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
    course.name as course_name,
    course_item.name as course_item,
    task.code as task_code,
    ea.fn_timetable_to_string(task_schedule.start_week, task_schedule.end_week, task_schedule.odd_even,
      task_schedule.day_of_week, task_schedule.start_section, task_schedule.total_section) as timetable,
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
    end as course_class_properties,
    array (
      select grade || s.short_name
      from ea.program_course pc
        join ea.course_class_program ccp on pc.program_id = ccp.program_id
        join ea.program on program.id = pc.program_id
        join ea.major m on program.major_id = m.id
        join ea.subject s on m.subject_id = s.id
        where pc.course_id = course_class.course_id
        and ccp.course_class_id = course_class.id
    ) as majors,
    (select max(grade + (select max(grade) from ea.major) - (select max(grade) from ea.major where subject_id = m.subject_id))
        from ea.program_course pc
        join ea.course_class_program ccp on pc.program_id = ccp.program_id
        join ea.program on program.id = pc.program_id
        join ea.major m on program.major_id = m.id
        where pc.course_id = course_class.course_id
        and ccp.course_class_id = course_class.id) as max_grade
  from ea.course_class
  join ea.task on task.course_class_id = course_class.id
  join ea.task_schedule on task_schedule.task_id = task.id
  join ea.teacher on task_schedule.teacher_id = teacher.id
  join ea.department course_class_department on course_class_department.id = course_class.department_id
  join ea.department teacher_department on teacher_department.id = teacher.department_id
  join ea.course on course_class.course_id = course.id
  left join ea.course_item on task.course_item_id = course_item.id
  where task_schedule.place_id not like 'B%'
  and term_id >= (select id - 30 from ea.term where active = true)
  and (
    (select id from ea.term where schedule = true) <> (select id from ea.term where active = true) and exists(select * from ea.task_student where task_student.task_id = task.id)
    or term_id = (select id from ea.term where schedule = true)
  )
), schedule_normal as (
  select term_id, course_class_department_id, course_name, course_item, teacher_id, teacher_name, teacher_department_id, property_id, weeks, day_of_week, sections, course_class_properties,
    array_agg(task_code order by task_code) as task_codes, max(max_grade) as max_grade
  from teacher_schedule
  group by term_id, course_class_department_id, course_name, course_item, teacher_id, teacher_name, teacher_department_id, property_id, weeks, day_of_week, sections, course_class_properties
)
select term_id, course_class_department_id, course_name, course_item, teacher_id, teacher_name, teacher_department_id, course_class_properties,
  length(replace(weeks::text, '0', '')) * length(replace(sections::text, '0', '')) as workload, task_codes, max_grade
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
  count(*) filter (where tw.course_class_properties && array[1]) as public_compulsory_workload,
  count(*) filter (where tw.course_class_properties && array[2,3]) as public_elective_workload
from av_teacher_workload tw
join teacher t on tw.teacher_id = t.id
join department d on tw.teacher_department_id = d.id
group by term_id, d.id, d.name, t.id, t.name;

-- 教学计划执行情况
create or replace view ea.av_program_execution as
with active_program as (
  select p.id, (select (id / 10 - m.grade) * 2 + id % 10 from term where schedule = true) as current_term
  from program p
  join major m on m.id = p.major_id
  join subject s on s.id = m.subject_id
  where m.grade + s.length_of_schooling > (select id / 10 from term where schedule = true)
  and p.type = 0
), program_course as (
  select d.name as department, p.id as program_id, grade, s.name as subject,
    c.id as course_id, c.name as course_name,
    property.name as property, coalesce(pc.direction_id, 0) as direction_id, c.credit,
    ap.current_term, pc.suggested_term, pc.allowed_term::bit(16) as allowed_term
  from active_program ap
  join program p on p.id = ap.id
  join program_course pc on p.id = pc.program_id
  join course c on c.id = pc.course_id
  join major m on m.id = p.major_id
  join subject s on s.id = m.subject_id
  join property on property.id = pc.property_id
  join department d on d.id = m.department_id
  where property.is_compulsory = true and property.name not in ('公共必修课')
), program_student as (
  select p.id as program_id, 0 as direction_id, count(s.id) as student_count
  from active_program ap
  join program p on p.id = ap.id
  join major m on m.id = p.major_id
  join student s on s.major_id = m.id
  where s.at_school is true
  group by p.id
  union all
  select p.id as program_id, d.id as direction_id, count(s.id) as student_count
  from active_program ap
  join program p on p.id = ap.id
  join direction d on d.program_id = p.id
  join major m on m.id = p.major_id
  join student s on s.major_id = m.id and s.direction_id = d.id
  where s.at_school is true
  group by p.id, d.id
), program_course_class as (
  select cc.code, p.id as program_id, cc.course_id, cc.term_id,
    count(distinct s.id) as course_student_count,
    count(distinct s.id ) filter (where s.major_id = m.id) as major_course_student_count
  from course_class cc
  join course_class_program ccp on ccp.course_class_id = cc.id
  join program p on p.id = ccp.program_id
  join active_program ap on p.id = ap.id
  join program_course pc on pc.program_id = p.id and cc.course_id = pc.course_id
  join major m on m.id = p.major_id
  join task t on t.course_class_id = cc.id
  left join task_student ts on ts.task_id = t.id
  left join student s on s.id = ts.student_id
  group by cc.code, p.id, cc.course_id, cc.term_id
)
select pc.department, pc.program_id, grade, subject, ps.student_count as major_student_count,
  pc.course_id, pc.course_name, pc.credit, pc.property, current_term, suggested_term, allowed_term,
  pcc.term_id, pcc.code as course_class_code, course_student_count, major_course_student_count
from program_course pc
join program_student ps on pc.program_id = ps.program_id and pc.direction_id = ps.direction_id
left join program_course_class pcc on pc.program_id = pcc.program_id and pcc.course_id = pc.course_id;

-- 未落实的教学计划
create or replace view ea.cv_unexecuted_program_course as
select department, program_id, grade, subject,
  course_id, course_name, credit, property, current_term, suggested_term,
  major_student_count, (select count(distinct student.id) 
  from ea.task_student
  join ea.task on task_student.task_id = task.id
  join ea.course_class on task.course_class_id = course_class.id
  join ea.student on task_student.student_id = student.id
  where student.major_id * 10 = a.program_id
  and student.at_school = true
  and course_class.course_id = a.course_id ) as excuted_student_count
from ea.av_program_execution a
where course_class_code is null
and suggested_term <= current_term
and course_name not like '毕业%'
and course_name <> '专业实习'
order by 1, 2;

-- 教室使用情况-按天和节统计周数
create or replace view ea.av_place_usage_by_day_and_section as
with all_schedule as (
  select place_id, a.start_week, a.end_week, odd_even, day_of_week, section_bits
  from ea.task_schedule a
  join ea.task b on a.task_id = b.id
  join ea.course_class c on b.course_class_id = c.id
  where term_id = (select id from ea.term where schedule = true)
  union all
  select place_id, start_week, end_week, odd_even, day_of_week, section_bits
  from ea.et_bnuc_task_schedule
  where term_id = (select id from ea.term where schedule = true)
), schedule as (
  select distinct place_id, start_week, end_week, end_week, day_of_week,
    ea.fn_weeks_count(start_week, end_week, odd_even) as weeks_count, section_bits
  from all_schedule
), place_section as (
  select place_id, day_of_week,
    sum(weeks_count) filter( where (1 << 0) & section_bits <> 0) as s1,
    sum(weeks_count) filter( where (1 << 1) & section_bits <> 0) as s2,
    sum(weeks_count) filter( where (1 << 2) & section_bits <> 0) as s3,
    sum(weeks_count) filter( where (1 << 3) & section_bits <> 0) as s4,
    sum(weeks_count) filter( where (1 << 4) & section_bits <> 0) as s5,
    sum(weeks_count) filter( where (1 << 5) & section_bits <> 0) as s6,
    sum(weeks_count) filter( where (1 << 6) & section_bits <> 0) as s7,
    sum(weeks_count) filter( where (1 << 7) & section_bits <> 0) as s8,
    sum(weeks_count) filter( where (1 << 8) & section_bits <> 0) as s9,
    sum(weeks_count) filter( where (1 << 9) & section_bits <> 0) as s10,
    sum(weeks_count) filter( where (1 << 10) & section_bits <> 0) as s11,
    sum(weeks_count) filter( where (1 << 11) & section_bits <> 0) as s12,
    sum(weeks_count) filter( where (1 << 12) & section_bits <> 0) as s13
  from schedule
  group by place_id, day_of_week
), place_day as (
    select id, name, seat, type, day
    from ea.place, generate_series(1, 7) as gs(day)
    where id not in ('000000', '000001', '000002')
    and building not in ('北理工', '元白楼', '南曦园')
    and seat > 0
)
select b.id, b.name, b.seat, b.type, b.day, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13
from place_section a
right join place_day b on a.place_id = b.id and a.day_of_week = b.day
order by b.id, b.day;

-- 检查root_id不存在的排课
create or replace view ea.cv_root_id_not_exists as
with formal as (
    select case when b.id is null then a.id else b.id end as id, -- 统一ID为长度不等于1的安排
        case when b.id is null then a.root_id else b.root_id end as root_id, -- 统一ROOT_ID为长度不等于1的安排
        a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
        a.odd_even, a.day_of_week, a.start_section, a.total_section
    from ea.sv_task_schedule a
    left join ea.sv_task_schedule b on a.task_id = b.task_id
    and a.teacher_id = b.teacher_id
    and (a.place_id = b.place_id or a.place_id is null and b.place_id is null)
    and a.start_week = b.start_week
    and a.end_week = b.end_week
    and a.odd_even = b.odd_even
    and a.day_of_week = b.day_of_week
    and a.total_section = 1
    and (a.start_section + a.total_section = b.start_section and b.start_section not in (5, 10)
      or b.start_section + b.total_section = a.start_section and a.start_section not in (5, 10))
), schedule as (
    select id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week,
        min(start_section) as start_section, sum(total_section) as total_section, root_id
    from formal
    group by id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, root_id
)
select task.code, schedule.id, root_id, schedule.start_week, schedule.end_week, odd_even,
  day_of_week, start_section, total_section
from schedule
join ea.task on schedule.task_id = task.id where root_id not in (select id from schedule)
order by task.code, schedule.start_week, day_of_week, start_section;
