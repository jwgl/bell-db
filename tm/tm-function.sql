/**
 * 查找场地
 */
create or replace function tm.sp_find_available_place (
  p_term_id integer,       -- 学期
  p_start_week integer,    -- 开始周
  p_end_week integer,      -- 结束周
  p_odd_even integer,      -- 单双周
  p_day_of_week integer,   -- 星期几
  p_section_id integer,    -- 开始节
  p_place_type varchar(20),-- 结束节
  p_user_type integer,     -- 用户类型
  p_adv_user boolean       -- 是否高级用户
) returns table (
   id varchar(6),          -- 场地ID
   name varchar(50),       -- 场地名称
   seat integer,           -- 座位数
   count bigint            -- 预约次数
) as $$
declare
  p_includes integer[];
  p_weeks_integer integer;
  p_section_integer integer;
begin
  select ea.fn_sections_to_integer(start, total), includes
  into p_section_integer, p_includes
  from tm.booking_section bs
  where bs.id = p_section_id;

  select ea.fn_weeks_to_integer(p_start_week, p_end_week, p_odd_even)
  into p_weeks_integer;

  return query select p1.id, p1.name, p1.seat, (
    select count(*)
    from booking_form bf
    join booking_item bi on bf.id = bi.form_id
    join booking_section bs on bs.id = bi.section_id
    where bf.term_id = p_term_id
    and bf.status in ('SUBMITTED', 'CHECKED')
    and bi.day_of_week = p_day_of_week
    and bs.includes && p_includes
    and (ea.fn_weeks_to_integer(start_week, end_week, odd_even) & p_weeks_integer) <> 0
    and bi.place_id = p1.id
  ) as count
  from ea.place p1
  where p1.id in (
    select p2.id
    from ea.place p2
    join tm.place_user_type t on p2.id = t.place_id
    where (t.user_type = p_user_type or p_adv_user = true)
    and p2.type = p_place_type
    and (enabled = true or enabled = false and exists (
      select * from ea.place_booking_term where place_id = p2.id
    ))
    except
    select place_id
    from tm.ev_place_usage pu
    where pu.term_id = p_term_id
      and pu.day_of_week = p_day_of_week
      and (ea.fn_sections_to_integer(start_section, total_section) & p_section_integer) <> 0
      and (ea.fn_weeks_to_integer(start_week, end_week, odd_even) & p_weeks_integer) <> 0
  )
  order by p1.id;
end;
$$ language plpgsql;

/**
 * 查询冲突的教室借用项
 */
create or replace function tm.sp_find_booking_conflict (
  p_form_id bigint -- 借用表单ID
) returns table (
  item_id bigint   -- 冲突的教室借用项ID
) as $$
declare
  p_term_id integer;
begin
  select term_id into p_term_id from booking_form where id = p_form_id;

  return query
  with form_item as ( -- 备选教室借用项
    select item.id item_id, item.place_id,
           ea.fn_weeks_to_integer(item.start_week, item.end_week, item.odd_even) as weeks,
           item.day_of_week,
           ea.fn_sections_to_integer(bs.start, bs.total) as sections
    from booking_form form
    join booking_item item on form.id = item.form_id
    join booking_section bs on item.section_id = bs.id
    where form.id = p_form_id
  ), place_usage as (
    select place_id, start_week, end_week, odd_even, day_of_week, start_section, total_section
    from tm.ev_place_usage
    where term_id = p_term_id
  )
  select distinct fi.item_id
  from form_item fi
  join place_usage pu on pu.place_id = fi.place_id
   and pu.day_of_week = fi.day_of_week
   and (ea.fn_sections_to_integer(pu.start_section, pu.total_section) & fi.sections) <> 0
   and (ea.fn_weeks_to_integer(pu.start_week, pu.end_week, pu.odd_even) & fi.weeks) <> 0;
end;
$$ language plpgsql;

create or replace function tm.timeslot_intersect (
  p_start_week_1 integer,
  p_end_week_1 integer,
  p_odd_even_1 integer,
  p_day_of_week_1 integer,
  p_start_section_1 integer,
  p_total_section_1 integer,
  p_start_week_2 integer,
  p_end_week_2 integer,
  p_odd_even_2 integer,
  p_day_of_week_2 integer,
  p_start_section_2 integer,
  p_total_section_2 integer
) returns boolean as $$
begin
  return p_day_of_week_1 = p_day_of_week_2
     and int4range(p_start_section_1, p_start_section_1 + p_total_section_1)
      && int4range(p_start_section_2, p_start_section_2 + p_total_section_2)
     and exists (
       with series as ( -- 生成序列，用于判断周次是否相交
         select i from generate_series(1, 30) as s(i)
       )
       select * from series where i between p_start_week_1 and p_end_week_1
       and (p_odd_even_1 = 0 or p_odd_even_1 = 1 and i % 2 = 1 or p_odd_even_1 = 2 and i % 2 = 0)
       intersect
       select * from series where i between p_start_week_2 and p_end_week_2
       and (p_odd_even_2 = 0 or p_odd_even_2 = 1 and i % 2 = 1 or p_odd_even_2 = 2 and i % 2 = 0)
     );
end;
$$ language plpgsql;

/**
 * 查询指定行政班的学生考勤统计
 */
create or replace function tm.sp_get_student_attendance_stats_by_admin_class (
  p_term_id integer,      -- 学期
  p_admin_class_id bigint -- 行政班ID
) returns table (
  id text,                -- 学号
  name text,              -- 姓名
  admin_class text,       -- 行政班
  absent numeric(8,1),    -- 旷课节数
  late numeric(8,1),      -- 迟到节数
  early numeric(8,1),     -- 早退节数
  total numeric(8,1),     -- 折合节数
  leave numeric(8,1)      -- 请假节数
) as $$
begin
  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_settings
    join attendance_type_ratio on attendance_settings.id = attendance_type_ratio.attendance_settings_id
    where p_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999)
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join ea.student on student_id = student.id and student.admin_class_id = p_admin_class_id
    where term_id = p_term_id
  ), student_leave as (
    select student_id, week, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    join ea.student on student_id = student.id and student.admin_class_id = p_admin_class_id
    where term_id = p_term_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    join ea.student on student_id = student.id and student.admin_class_id = p_admin_class_id
    where term_id = p_term_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
    select student_id,
      sum(case when as_type = 1 then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type = 2 then instance_ratio + total_section * sections_ratio else 0.0 end) as late,
      sum(case when as_type = 3 then instance_ratio + total_section * sections_ratio else 0.0 end) as early,
      sum(case when as_type = 4 then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id
  )
  select student.id::text, student.name::text, admin_class.name::text,
         attendance.absent,
         attendance.late,
         attendance.early,
         attendance.absent + attendance.late + attendance.early as total,
         attendance.leave
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by total desc, leave desc;
end;
$$ language plpgsql;

/**
 * 查询指定管理员（班主任/辅导员）的学生考勤统计
 */
create or replace function tm.sp_get_student_attendance_stats_by_administrator (
  p_term_id integer,    -- 学期
  p_user_id text,       -- 用户ID
  p_limit integer = 100 -- 查询数量
) returns table (
  id text,              -- 学号
  name text,            -- 姓名
  admin_class text,     -- 行政班
  absent numeric(8,1),  -- 旷课节数
  late numeric(8,1),    -- 迟到节数
  early numeric(8,1),   -- 早退节数
  total numeric(8,1),   -- 折合节数
  leave numeric(8,1)    -- 请假节数
) as $$
begin
  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_settings
    join attendance_type_ratio on attendance_settings.id = attendance_type_ratio.attendance_settings_id
    where p_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999)
  ), admin_class as (
    select admin_class.id
    from ea.admin_class
    where admin_class.counsellor_id = p_user_id or admin_class.supervisor_id = p_user_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
  ), student_leave as (
    select student_id, week, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
    select student_id,
      sum(case when as_type = 1 then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type = 2 then instance_ratio + total_section * sections_ratio else 0.0 end) as late,
      sum(case when as_type = 3 then instance_ratio + total_section * sections_ratio else 0.0 end) as early,
      sum(case when as_type = 4 then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id
  )
  select student.id::text,
         student.name::text,
         admin_class.name::text,
         attendance.absent,
         attendance.late,
         attendance.early,
         attendance.absent + attendance.late + attendance.early as total,
         attendance.leave
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by total desc, leave desc
  limit p_limit;
end;
$$ language plpgsql;

/**
 * 查询指定管理员（班主任/辅导员）按行政班统计存在考勤数据的学生数
 */
create or replace function tm.sp_get_admin_class_attendance_stats_by_administrator (
  p_term_id integer, -- 学期
  p_user_id text     -- 用户ID
) returns table (
  id bigint,         -- 行政班ID
  name text,         -- 行政班名称
  count bigint       -- 存在考勤数据的学生数
) as $$
begin
  return query
  with admin_class as (
    select admin_class.id
    from ea.admin_class
    where admin_class.counsellor_id = p_user_id or admin_class.supervisor_id = p_user_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
  ), student_leave as (
    select student_id, week, task_schedule_id
    from tm.dva_valid_student_leave
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id
    from ea.student
    join admin_class on student.admin_class_id = admin_class.id
    join tm.dva_valid_rollcall on student.id = student_id
    where term_id = p_term_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
      select student_id from rollcall
      union
      select student_id from student_leave
  )
  select admin_class.id, admin_class.name::text, count(student_id)
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  group by 1, 2
  order by 3 desc;
end;
$$ language plpgsql;

/**
 * 查询指定学院的学生考勤统计
 */
create or replace function tm.sp_get_student_attendance_stats_by_department (
  p_term_id integer,    -- 学期
  p_department_id text, -- 学院ID
  p_limit integer = 100 -- 查询数量
) returns table (
  id text,              -- 学号
  name text,            -- 姓名
  admin_class text,     -- 行政班
  absent numeric(8,1),  -- 旷课节数
  late numeric(8,1),    -- 迟到节数
  early numeric(8,1),   -- 早退节数
  total numeric(8,1),   -- 折合节数
  leave numeric(8,1)    -- 请假节数
) as $$
begin
  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_settings
    join attendance_type_ratio on attendance_settings.id = attendance_type_ratio.attendance_settings_id
    where p_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999)
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join ea.student on student.id = student_id
    where term_id = p_term_id
    and student.department_id = p_department_id
  ), student_leave as (
    select student_id, week, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    join ea.student on student.id = student_id
    where term_id = p_term_id
      and student.department_id = p_department_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    join ea.student on student.id = student_id
    where term_id = p_term_id
      and student.department_id = p_department_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
    select student_id,
      sum(case when as_type = 1 then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type = 2 then instance_ratio + total_section * sections_ratio else 0.0 end) as late,
      sum(case when as_type = 3 then instance_ratio + total_section * sections_ratio else 0.0 end) as early,
      sum(case when as_type = 4 then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id
  )
  select student.id::text, student.name::text, admin_class.name::text,
         attendance.absent,
         attendance.late,
         attendance.early,
         attendance.absent + attendance.late + attendance.early as total,
         attendance.leave
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by total desc, leave desc, absent desc, late desc, early desc
  limit p_limit;
end;
$$ language plpgsql;

/**
 * 查询指定学院按行政班统计存在考勤数据的学生数
 */
create or replace function tm.sp_get_admin_class_attendance_stats_by_department (
  p_term_id integer,   -- 学期
  p_department_id text -- 学院ID
) returns table (
  id bigint,           -- 行政班ID
  name text,           -- 行政班名称
  count bigint         -- 存在考勤数据的学生数
) as $$
begin
  return query
  with admin_class as (
    select admin_class.id
    from ea.admin_class
    where admin_class.department_id = p_department_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
  ), student_leave as (
    select student_id, week, task_schedule_id
    from tm.dva_valid_student_leave
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id
    from tm.dva_valid_rollcall
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
    select student_id from rollcall
    union
    select student_id from student_leave
  )
  select admin_class.id, admin_class.name::text, count(student_id) as count
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  group by 1, 2
  order by 3 desc;
end;
$$ language plpgsql;

/**
 * 按时间段查询学生考勤统计，用于点名显示
 */
create or replace function tm.sp_get_student_attendance_stats_by_timeslot (
  p_term_id integer,       -- 学期
  p_teacher_id text,       -- 教师ID
  p_week integer,          -- 周次
  p_day_of_week integer,   -- 星期几
  p_start_section integer, -- 开始节
  p_total_section integer  -- 上课长度
) returns table (
  id text,                 -- 学号
  absent bigint,           -- 旷课次数
  late bigint,             -- 迟到次数
  early bigint,            -- 早退次数
  leave bigint             -- 请假次数
) as $$
begin
  return query
  with timeslot_schedule as ( -- 时间段覆盖的课程、任务和安排
    select task_schedule.id, task.id as task_id, course_class.id as course_class_id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.term_id = p_term_id
      and task_schedule.teacher_id = p_teacher_id
      and p_week between task_schedule.start_week and task_schedule.end_week
      and case task_schedule.odd_even
          when 0 then true
          when 1 then p_week % 2 = 1
          when 2 then p_week % 2 = 0 end
      and task_schedule.day_of_week = p_day_of_week
      and task_schedule.start_section = p_start_section
      and task_schedule.total_section = p_total_section
  ), attendance_student as ( -- 时间段覆盖的学生
    select distinct task_student.student_id as id
    from timeslot_schedule
    join ea.task on timeslot_schedule.task_id = task.id
    join ea.task_student on task.id = task_student.task_id
  ), attendance_schedule as ( -- 统计覆盖的安排
    select task_schedule.id, task.id as task_id, course_class.id as course_class_id
    from timeslot_schedule
    join ea.course_class on timeslot_schedule.course_class_id = course_class.id
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join attendance_student on student_id = attendance_student.id
    join attendance_schedule on task_schedule_id = attendance_schedule.id
  ), student_leave as (
    select student_id, week, task_schedule_id, 4 as type
    from tm.dva_valid_student_leave
    join attendance_student on student_id = attendance_student.id
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id, type
    from tm.dva_valid_rollcall
    join attendance_student on student_id = attendance_student.id
    join attendance_schedule on attendance_schedule.id = task_schedule_id
    where (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
    select student_id,
      count(case when type = 1 then 1 end) as absent,
      count(case when type = 2 then 1 end) as late,
      count(case when type = 3 then 1 end) as early,
      count(case when type = 4 then 1 end) as leave,
      count(case when type = 5 then 1 end) as late_early
    from (
      select student_id, task_schedule_id, type from rollcall
      union all
      select student_id, task_schedule_id, type from student_leave
    ) as x
    group by student_id
  )
  select attendance.student_id::text,
         attendance.absent,
         attendance.late +
         attendance.late_early as late,
         attendance.early +
         attendance.late_early as early,
         attendance.leave
  from attendance
  order by 1;
end;
$$ language plpgsql;

/**
 * 按安排和学生查询学生考勤统计，用于点名时实时更新
 */
create or replace function tm.sp_get_student_attendance_stats_by_task_schedule_student (
  p_task_schedule_id uuid, -- 排课ID
  p_student_id text        -- 学号
) returns table (
  id text,                 -- 学号
  absent bigint,           -- 旷课次数
  late bigint,             -- 迟到次数
  early bigint,            -- 早退次数
  leave bigint             -- 请假次数
) as $$
begin
  return query
  with attendance_schedule as ( -- 统计覆盖的安排
    select task_schedule.id, task.id as task_id, course_class.id as course_class_id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class_id = (
      select course_class.id
      from ea.course_class
      join ea.task on course_class.id = task.course_class_id
      join ea.task_schedule on task.id = task_schedule.task_id
      where task_schedule.id = p_task_schedule_id
    )
  ), free_listen as (
    select task_schedule_id
    from tm.dva_valid_free_listen
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where student_id = p_student_id
  ), student_leave as (
    select student_id, week, task_schedule_id, 4 as type
    from tm.dva_valid_student_leave
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where student_id = p_student_id
      and task_schedule_id not in (
        select task_schedule_id from free_listen
      )
  ), rollcall as (
    select week, task_schedule_id, type
    from tm.dva_valid_rollcall
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where student_id = p_student_id
      and (week, task_schedule_id) not in (
        select week, task_schedule_id from student_leave
      )
      and task_schedule_id not in (
        select task_schedule_id from free_listen
      )
  ), attendance as (
    select count(case when type = 1 then 1 end) as absent,
           count(case when type = 2 then 1 end) as late,
           count(case when type = 3 then 1 end) as early,
           count(case when type = 4 then 1 end) as leave,
           count(case when type = 5 then 1 end) as late_early
    from (
      select task_schedule_id, type from rollcall
      union all
      select task_schedule_id, type from student_leave
    ) as x
  )
  select p_student_id,
         attendance.absent,
         attendance.late +
         attendance.late_early as late,
         attendance.early +
         attendance.late_early as early,
         attendance.leave
  from attendance
  order by 1;
end;
$$ language plpgsql;

/**
 * 按教学班查询学生考勤统计
 */
create or replace function tm.sp_get_student_attendance_stats_by_course_class (
  p_course_class_id uuid -- 教学班ID
) returns table (
  id text,               -- 学号
  absent numeric(8,1),   -- 旷课节数
  late numeric(8,1),     -- 迟到节数
  early numeric(8,1),    -- 早退节数
  total numeric(8,1),    -- 折合节数
  leave numeric(8,1)     -- 请假节数
) as $$
declare
  v_term_id integer;
begin
  select term_id
    into v_term_id
  from ea.course_class
  where course_class.id = p_course_class_id;

  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_settings
    join attendance_type_ratio on attendance_settings.id = attendance_type_ratio.attendance_settings_id
    where v_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999)
  ), attendance_student as ( -- 教学班覆盖的学生
    select distinct task_student.student_id as id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_student on task.id = task_student.task_id
    where course_class.id = p_course_class_id
  ), attendance_schedule as ( -- 教学班覆盖的安排
    select task_schedule.id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.id = p_course_class_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join attendance_student on student_id = attendance_student.id
    join attendance_schedule on task_schedule_id = attendance_schedule.id
  ), student_leave as (
    select student_id, week, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    join attendance_student on student_id = attendance_student.id
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    join attendance_student on student_id = attendance_student.id
    join attendance_schedule on attendance_schedule.id = task_schedule_id
    where (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), attendance as (
    select student_id,
      sum(case when as_type = 1 then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type = 2 then instance_ratio + total_section * sections_ratio else 0.0 end) as late,
      sum(case when as_type = 3 then instance_ratio + total_section * sections_ratio else 0.0 end) as early,
      sum(case when as_type = 4 then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id
  )
  select student_id::text,
         attendance.absent,
         attendance.late,
         attendance.early,
         attendance.absent + attendance.late + attendance.early as total,
         attendance.leave
  from attendance
  order by 1;
end;
$$ language plpgsql;

/**
 * 按教学班和学号查询学生点名详情
 */
create or replace function tm.sp_get_rollcall_details_by_course_class_student (
  p_course_class_id uuid,       -- 教学班ID
  p_student_id text             -- 学号
) returns table (
  id bigint,                    -- 学号
  week integer,                 -- 周次
  day_of_week integer,          -- 星期几
  start_section integer,        -- 起始节
  total_section integer,        -- 共几节
  type integer,                 -- 考勤类型
  course text,                  -- 课程
  course_item text,             -- 课程项
  teacher text,                 -- 教师
  student_leave_form_id bigint, -- 请假ID
  free_listen_form_id bigint    -- 免听ID
) as $$
#variable_conflict use_column
begin
  return query
  with attendance_schedule as ( -- 教学班覆盖的安排
    select task_schedule.id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.id = p_course_class_id
  ), free_listen as (
    select form_id, task_schedule_id
    from tm.dva_valid_free_listen
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where student_id = p_student_id
  ), student_leave as (
    select form_id, week, task_schedule_id
    from tm.dva_valid_student_leave
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where student_id = p_student_id
  ), rollcall as (
    select dva_valid_rollcall.rollcall_id,
           dva_valid_rollcall.week,
           dva_valid_rollcall.task_schedule_id,
           dva_valid_rollcall.type,
           dva_valid_rollcall.teacher_id,
           student_leave.form_id as student_leave_form_id,
           free_listen.form_id as free_listen_form_id
    from tm.dva_valid_rollcall
    join attendance_schedule on attendance_schedule.id = task_schedule_id
    left join student_leave on dva_valid_rollcall.week = student_leave.week
          and dva_valid_rollcall.task_schedule_id = student_leave.task_schedule_id
    left join free_listen on dva_valid_rollcall.task_schedule_id = free_listen.task_schedule_id
    where student_id = p_student_id
  )
  select rollcall.rollcall_id,
         rollcall.week,
         task_schedule.day_of_week,
         task_schedule.start_section,
         task_schedule.total_section,
         rollcall.type,
         course.name::text as course,
         course_item.name::text as course_item,
         teacher.name::text as teacher,
         rollcall.student_leave_form_id,
         rollcall.free_listen_form_id
  from rollcall
  join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
  join ea.task on task_schedule.task_id = task.id
  join ea.course_class on task.course_class_id = course_class.id
  join ea.course on course_class.course_id = course.id
  join ea.teacher on rollcall.teacher_id = teacher.id
  left join ea.course_item on task.course_item_id = course_item.id
  order by week, day_of_week, start_section;
end;
$$ language plpgsql;

/**
 * 按教学班和学号查询学生请假详情
 */
create or replace function tm.sp_get_student_leave_details_by_course_class_student (
  p_course_class_id uuid,       -- 教学班ID
  p_student_id text             -- 学号
) returns table (
  id bigint,                    -- 学号
  week integer,                 -- 周次
  day_of_week integer,          -- 星期几
  start_section integer,        -- 起始节
  total_section integer,        -- 共几节
  type integer,                 -- 请假类型
  course text,                  -- 课程
  course_item text,             -- 课程项
  teacher text,                 -- 教师
  student_leave_form_id bigint, -- 请假ID
  free_listen_form_id bigint    -- 免听ID
) as $$
#variable_conflict use_column
begin
  return query
  with attendance_schedule as ( -- 教学班覆盖的安排
    select task_schedule.id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.id = p_course_class_id
  ), free_listen as (
    select form_id, task_schedule_id
    from tm.dva_valid_free_listen
    join attendance_schedule on task_schedule_id = attendance_schedule.id
    where student_id = p_student_id
  ), student_leave as (
    select dva_valid_student_leave.item_id,
           dva_valid_student_leave.week,
           dva_valid_student_leave.task_schedule_id,
           dva_valid_student_leave.teacher_id,
           dva_valid_student_leave.type,
           dva_valid_student_leave.form_id as student_leave_form_id,
           free_listen.form_id as free_listen_form_id
    from tm.dva_valid_student_leave
    join attendance_schedule on dva_valid_student_leave.task_schedule_id = attendance_schedule.id
    left join free_listen on dva_valid_student_leave.task_schedule_id = free_listen.task_schedule_id
    where student_id = p_student_id
  )
  select student_leave.item_id,
         student_leave.week,
         task_schedule.day_of_week,
         task_schedule.start_section,
         task_schedule.total_section,
         student_leave.type,
         course.name::text as course,
         course_item.name::text as course_item,
         teacher.name::text as teacher,
         student_leave.student_leave_form_id,
         student_leave.free_listen_form_id
  from student_leave
  join ea.task_schedule on student_leave.task_schedule_id = task_schedule.id
  join ea.task on task_schedule.task_id = task.id
  join ea.course_class on task.course_class_id = course_class.id
  join ea.course on course_class.course_id = course.id
  join ea.teacher on student_leave.teacher_id = teacher.id
  left join ea.course_item on task.course_item_id = course_item.id
  order by week, day_of_week, start_section;
end;
$$ language plpgsql;

/**
 * 按学期和学号查询学生点名详情
 */
create or replace function tm.sp_get_rollcall_details_by_student (
  p_term_id integer,            -- 学期
  p_student_id text             -- 学号
) returns table (
  id bigint,                    -- 学号
  week integer,                 -- 周次
  day_of_week integer,          -- 星期几
  start_section integer,        -- 起始节
  total_section integer,        -- 共几节
  type integer,                 -- 考勤类型
  course text,                  -- 课程
  course_item text,             -- 课程项
  teacher text,                 -- 教师
  student_leave_form_id bigint, -- 请假ID
  free_listen_form_id bigint    -- 免听ID
) as $$
#variable_conflict use_column
begin
  return query
  with free_listen as (
    select form_id, task_schedule_id
    from tm.dva_valid_free_listen
    where term_id = p_term_id
    and student_id = p_student_id
  ), student_leave as (
    select form_id, week, task_schedule_id
    from tm.dva_valid_student_leave
    where term_id = p_term_id
    and student_id = p_student_id
  )
  select vr.rollcall_id,
         vr.week,
         vr.day_of_week,
         vr.start_section,
         vr.total_section,
         vr.type,
         course.name::text as course,
         course_item.name::text as course_item,
         teacher.name::text as teacher,
         student_leave.form_id as student_leave_form_id,
         free_listen.form_id as free_listen_form_id
  from tm.dva_valid_rollcall vr
  join ea.course on vr.course_id = course.id
  join ea.teacher on vr.teacher_id = teacher.id
  left join ea.course_item on vr.course_item_id = course_item.id
  left join student_leave on vr.week = student_leave.week
        and vr.task_schedule_id = student_leave.task_schedule_id
  left join free_listen on vr.task_schedule_id = free_listen.task_schedule_id
  where term_id = p_term_id
  and student_id = p_student_id
  order by week, day_of_week, start_section;
end;
$$ language plpgsql;

/**
 * 按学期和学号查询学生请假详情
 */
create or replace function tm.sp_get_student_leave_details_by_student (
  p_term_id integer,            -- 学期
  p_student_id text             -- 学号
) returns table (
  id bigint,                    -- 学号
  week integer,                 -- 周次
  day_of_week integer,          -- 星期几
  start_section integer,        -- 起始节
  total_section integer,        -- 共几节
  type integer,                 -- 请假类型
  course text,                  -- 课程
  course_item text,             -- 课程项
  teacher text,                 -- 教师
  student_leave_form_id bigint, -- 请假ID
  free_listen_form_id bigint    -- 免听ID
) as $$
#variable_conflict use_column
begin
  return query
  with free_listen as (
    select form_id, task_schedule_id
    from tm.dva_valid_free_listen
    where term_id = p_term_id
    and student_id = p_student_id
  )
  select vsl.item_id * 100 + rank() over (partition by item_id order by vsl.task_schedule_id),
         vsl.week,
         vsl.day_of_week,
         vsl.start_section,
         vsl.total_section,
         vsl.type,
         course.name::text as course,
         course_item.name::text as course_item,
         teacher.name::text as teacher,
         vsl.form_id as student_leave_form_id,
         free_listen.form_id as free_listen_form_id
  from tm.dva_valid_student_leave vsl
  join ea.course on vsl.course_id = course.id
  join ea.teacher on vsl.teacher_id = teacher.id
  left join ea.course_item on vsl.course_item_id = course_item.id
  left join free_listen on vsl.task_schedule_id = free_listen.task_schedule_id
  where term_id = p_term_id
  and student_id = p_student_id
  order by week, day_of_week, start_section;
end;
$$ language plpgsql;

/**
 * 按学生所在学院查询取消考试资格统计
 */
create or replace function tm.sp_get_exam_disqual_by_student_department (
  p_term_id integer,             -- 学期
  p_department_id text           -- 学生所在学院ID
) returns table (
  id text,                       -- 学号
  name text,                     -- 学生姓名
  admin_class text,              -- 行政班
  course_class_code text,        -- 选课课号
  course text,                   -- 课程名称
  teacher text,                  -- 主讲教师
  department text,               -- 开课单位
  course_class_section bigint,   -- 课程总节数
  absent_section numeric(8, 1),  -- 旷课节数
  absent_exceeded boolean,       -- 旷课超限
  leave_section numeric(8, 1),   -- 请假节数
  attend_exceeded boolean,       -- 缺勤超限
  disqualified boolean           -- 是否已取消
) as $$
declare
  v_attendance_settings_id integer;
  v_absent_disqual_ratio numeric(6, 6);
  v_attend_disqual_ratio numeric(6, 6);
begin
  select attendance_settings.id, absent_disqual_ratio, attend_disqual_ratio
    into v_attendance_settings_id, v_absent_disqual_ratio, v_attend_disqual_ratio
  from attendance_settings
  where p_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999);

  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_type_ratio
    where attendance_settings_id = v_attendance_settings_id
  ), admin_class as (
    select admin_class.id
    from ea.admin_class
    where admin_class.department_id = p_department_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
  ), student_leave as (
    select student_id, week, course_class_id, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, course_class_id, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    join ea.student on student.id = student_id
    join admin_class on student.admin_class_id = admin_class.id
    where term_id = p_term_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), course_class_student_stats as ( -- 按学生和教学班统计旷课和迟到
    select student_id, course_class_id,
      sum(case when as_type in (1, 2, 3) then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type in (4)       then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, course_class_id, total_section, type from rollcall
      union all
      select student_id, course_class_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id, course_class_id
  ), course_class_section_stats as ( -- 按教学班统计总节数
    select course_class.id as course_class_id,
      sum(total_section * floor((task_schedule.end_week - task_schedule.start_week + 1) /
          (case task_schedule.odd_even when 0 then 1 else 2 end))::integer) as total
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.id in (
      select course_class_id from course_class_student_stats
    )
    group by course_class.id
  )
  select student.id::text,
         student.name::text,
         admin_class.name::text as admin_class,
         course_class.code::text as course_class_code,
         course.name::text as course,
         teacher.name::text as teacher,
         department.name::text as department,
         course_class_section_stats.total as course_class_section,
         course_class_student_stats.absent as absent_section,
         course_class_student_stats.absent >= course_class_section_stats.total * v_absent_disqual_ratio as absent_exceeded,
         course_class_student_stats.leave as leave_section,
         (course_class_student_stats.absent + course_class_student_stats.leave) >= course_class_section_stats.total * v_attend_disqual_ratio as attend_exceeded,
         exists (
           select *
           from ea.task
           join ea.task_student on task.id = task_student.task_id and student.id = task_student.student_id
           where task.course_class_id = course_class.id
             and task_student.exam_flag = 1
         ) as disqualified
  from course_class_student_stats
  join course_class_section_stats on course_class_student_stats.course_class_id = course_class_section_stats.course_class_id
  join ea.course_class on course_class_student_stats.course_class_id = course_class.id
  join ea.course on course_class.course_id = course.id
  join ea.department on course_class.department_id = department.id
  join ea.teacher on course_class.teacher_id = teacher.id
  join ea.student on course_class_student_stats.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by id, course_class_code;
end;
$$ language plpgsql;

/**
 * 按开课学院统计教学班取消考试资格学生数
 * 教务秘书处理入口
 */
create or replace function tm.sp_get_exam_disqual_stats_by_course_class_department (
  p_term_id integer,        -- 学期
  p_department_id text      -- 开课学院ID
) returns table (
  id uuid,                  -- 教学班ID
  code text,                -- 选课课号
  name text,                -- 教学班名称
  course text,              -- 课程名称
  teacher text,             -- 主讲教师
  section bigint,           -- 课程总节数
  processed bigint,         -- 已处理数量
  unprocessed bigint        -- 未处理数量
) as $$
declare
  v_attendance_settings_id integer;
  v_absent_disqual_ratio numeric(6, 6);
  v_attend_disqual_ratio numeric(6, 6);
begin
  select attendance_settings.id, absent_disqual_ratio, attend_disqual_ratio
    into v_attendance_settings_id, v_absent_disqual_ratio, v_attend_disqual_ratio
  from attendance_settings
  where p_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999);

  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_type_ratio
    where attendance_settings_id = v_attendance_settings_id
  ), course_class as (
    select course_class.id
    from ea.course_class
    where course_class.department_id = p_department_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    join course_class on course_class_id = course_class.id
    where term_id = p_term_id
  ), student_leave as (
    select student_id, week, course_class_id, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    join course_class on course_class_id = course_class.id
    where term_id = p_term_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, course_class_id, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    join course_class on course_class_id = course_class.id
    where term_id = p_term_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), course_class_student_stats as ( -- 按学生和教学班统计旷课和迟到节数
    select student_id, course_class_id,
      sum(case when as_type in (1, 2, 3) then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type in (4)       then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, course_class_id, total_section, type from rollcall
      union all
      select student_id, course_class_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id, course_class_id
  ), course_class_section_stats as ( -- 按教学班统计总节数
    select course_class.id as course_class_id,
           sum(total_section * floor((task_schedule.end_week - task_schedule.start_week + 1) /
           (case task_schedule.odd_even when 0 then 1 else 2 end))::integer) as total_section
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.id in (
      select course_class_id from course_class_student_stats
    )
    group by course_class.id
  ), course_class_student_disqual as ( -- 计算达到取消资格标准的学生
    select course_class_student_stats.student_id,
           course_class_student_stats.course_class_id,
           course_class_section_stats.total_section,
           exists (
             select *
             from ea.task
             join ea.task_student on task.id = task_student.task_id
              and course_class_student_stats.student_id = task_student.student_id
             where task.course_class_id = course_class_student_stats.course_class_id
               and task_student.exam_flag = 1
           ) as disqualified
    from course_class_student_stats
    join course_class_section_stats on course_class_student_stats.course_class_id = course_class_section_stats.course_class_id
    where course_class_student_stats.absent >= course_class_section_stats.total_section * v_absent_disqual_ratio
       or (course_class_student_stats.absent + course_class_student_stats.leave) >= course_class_section_stats.total_section * v_attend_disqual_ratio
       or exists (
            select *
            from ea.task
            join ea.task_student on task.id = task_student.task_id
             and course_class_student_stats.student_id = task_student.student_id
            where task.course_class_id = course_class_student_stats.course_class_id
              and task_student.exam_flag = 1
          )
  )
  select course_class.id,
         course_class.code::text,
         course_class.name::text,
         course.name::text as course,
         teacher.name::text as teacher,
         course_class_student_disqual.total_section,
         count(case when disqualified = true then 1 end) as processed_count,
         count(case when disqualified = false then 1 end) as unprocessed_count
  from course_class_student_disqual
  join ea.course_class on course_class_student_disqual.course_class_id = course_class.id
  join ea.course on course_class.course_id = course.id
  join ea.teacher on course_class.teacher_id = teacher.id
  group by 1, 2, 3, 4, 5, 6
  order by 2;
end;
$$ language plpgsql;

/**
 * 按教学班查询取消考试资格记录
 */
create or replace function tm.sp_get_exam_disqual_by_course_class (
  p_course_class_id uuid          -- 教学班ID
) returns table (
  id text,                        -- 学号
  name text,                      -- 学生姓名
  admin_class text,               -- 行政班
  department text,                -- 学生所在学院
  absent_section numeric(8, 1),   -- 旷课节数
  absent_exceeded boolean,        -- 旷课超限
  leave_section numeric(8, 1),    -- 请假节数
  attend_exceeded boolean,        -- 缺勤超限
  disqualified boolean            -- 是否已取消
) as $$
declare
  v_term_id integer;
  v_course_class_section bigint;
  v_attendance_settings_id integer;
  v_absent_disqual_ratio numeric(6, 6);
  v_attend_disqual_ratio numeric(6, 6);
begin
  select term_id
    into v_term_id
  from ea.course_class
  where course_class.id = p_course_class_id;

  -- 计算教学班总学时
  select sum(total_section * floor((task_schedule.end_week - task_schedule.start_week + 1) /
         (case task_schedule.odd_even when 0 then 1 else 2 end))::integer)
    into v_course_class_section
  from ea.course_class
  join ea.task on course_class.id = task.course_class_id
  join ea.task_schedule on task.id = task_schedule.task_id
  where course_class.id = p_course_class_id;

  select attendance_settings.id, absent_disqual_ratio, attend_disqual_ratio
    into v_attendance_settings_id, v_absent_disqual_ratio, v_attend_disqual_ratio
  from attendance_settings
  where v_term_id between coalesce(start_term_id, 00000) and coalesce(end_term_id, 99999);

  return query
  with type_ratio as (
    select type, as_type, instance_ratio, sections_ratio
    from attendance_type_ratio
    where attendance_settings_id = v_attendance_settings_id
  ), free_listen as (
    select student_id, task_schedule_id
    from tm.dva_valid_free_listen
    where course_class_id = p_course_class_id
  ), student_leave as (
    select student_id, week, task_schedule_id, total_section, 4 as type
    from tm.dva_valid_student_leave
    where course_class_id = p_course_class_id
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), rollcall as (
    select student_id, week, task_schedule_id, total_section, type
    from tm.dva_valid_rollcall
    where course_class_id = p_course_class_id
      and (student_id, week, task_schedule_id) not in (
        select student_id, week, task_schedule_id from student_leave
      )
      and (student_id, task_schedule_id) not in (
        select student_id, task_schedule_id from free_listen
      )
  ), course_class_student_stats as ( -- 按学生和教学班统计旷课和迟到节数
    select student_id,
      sum(case when as_type in (1, 2, 3) then instance_ratio + total_section * sections_ratio else 0.0 end) as absent,
      sum(case when as_type in (4)       then instance_ratio + total_section * sections_ratio else 0.0 end) as leave
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    join type_ratio on type_ratio.type = x.type
    group by student_id
  ), course_class_student_disqual as (
    select course_class_student_stats.student_id,
           course_class_student_stats.absent as absent_section,
           course_class_student_stats.absent >= v_course_class_section * v_absent_disqual_ratio as absent_exceeded,
           course_class_student_stats.leave as leave_section,
           (course_class_student_stats.absent + course_class_student_stats.leave) >= v_course_class_section * v_attend_disqual_ratio as attend_exceeded,
           exists (
             select *
             from ea.task
             join ea.task_student on task.id = task_student.task_id
              and course_class_student_stats.student_id = task_student.student_id
             where task.course_class_id = p_course_class_id
               and task_student.exam_flag = 1
           ) as disqualified
    from course_class_student_stats
  )
  select student.id::text,
         student.name::text,
         admin_class.name::text as admin_class,
         department.name::text as department,
         ccd.absent_section,
         ccd.absent_exceeded,
         ccd.leave_section,
         ccd.attend_exceeded,
         ccd.disqualified
  from course_class_student_disqual ccd
  join ea.student on ccd.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  join ea.department on student.department_id = department.id
  where ccd.absent_exceeded
     or ccd.attend_exceeded
     or ccd.disqualified
  order by id;
end;
$$ language plpgsql;

/**
 * 获取用户菜单
 */
create or replace function tm.sp_get_user_menu (
  p_roles text[] -- 角色数组
) returns text   -- 菜单
as $$
declare
  v_result text;
begin
  with recursive menu_tree as ( -- 从根开始生成菜单树
    select jb
    from menu_with_count
    where submenu_count = 0
    union all
    select jsonb_set((p).jb, '{children}', (
        select jsonb_agg(value order by value->'display_order')
        from jsonb_array_elements((p).jb->'children' || jsonb_agg((c).jb - 'parent_id' - 'path_level'))
      ))
    from (
      select p, c
      from menu_with_count p
      join menu_tree c ON c.jb->'parent_id' = p.jb->'id'
    ) t
    group by p
    having count(c) = (p).submenu_count -- 只有所有子节点聚齐时，才将子节点加入父节点
  ), menu_with_level as ( -- 菜单等级和父ID
    select id, label, display_order,
      length(id) - length(replace(id, '.', '')) as path_level,
      substring(id, 1, length(id) - nullif(position('.' in reverse(id)), 0)) as parent_id
    from tm.menu
  ), menu_item as ( -- 菜单项
    select distinct a.*
    from tm.menu_item a
    join tm.permission b on a.permission_id = b.id
    join tm.role_permission c on c.permission_id = b.id
    where c.role_id = any(p_roles)
    and a.enabled = true
  ), menu_with_items as ( -- 包含菜单项的菜单
    select menu.id, jsonb_agg(json_build_object(
        'id', menu_item.id,
        'label', menu_item.label,
        'url', menu_item.url,
        'display_order', menu_item.display_order
      ) order by menu_item.display_order) as children
    from tm.menu as menu
    join menu_item on menu_item.menu_id = menu.id
    group by menu.id
  ), menu_with_parent as ( -- 递归查询“包含菜单项的菜单”的父菜单
    select a.*, b.children
    from menu_with_level a
    join menu_with_items b on a.id = b.id
    union
    select b.*, coalesce(c.children, jsonb '[]') as children
    from menu_with_parent a
    join menu_with_level b on a.parent_id = b.id
    left join menu_with_items c on b.id = c.id
  ), menu_with_count as (
    select to_jsonb(p) as jb, count(c) as submenu_count
    from (
      select p, c
      from menu_with_parent p
      left join menu_with_parent c on c.parent_id = p.id
    ) t
    group by p
  )
  select jsonb_pretty(jsonb_object_agg(jb->>'id', jb->'children')) into v_result from menu_tree
  where jb @> '{"path_level": 0}';
  return v_result;
end;
$$ language plpgsql;

/**
 * 更新菜单项状态
 */
create or replace function tm.sp_update_menu_status (
  applications text[] -- 依赖的应用
) returns integer as $$
begin
  update tm.menu_item
  set enabled = applications @> depends_on;
  return 1;
end;
$$ language plpgsql;

/**
 * 同步用户密码
 */
create or replace function tm.sp_sync_user_password (
  p_user_id text
) returns integer as $$
begin
  update tm.system_user a
  set password = b.password
  from tm.sv_system_user b
  where a.id = b.id
  and a.id = p_user_id;
  return 1;
end;
$$ language plpgsql;
