/**
 * 查找场地
 *
 * @param p_term_id 学期
 * @param p_start_week 开始周
 * @param p_end_week 结束周
 * @param p_odd_even 单双周
 * @param p_day_of_week 星期几
 * @param p_start_section 开始节
 * @param p_end_section 结束节
 * @param p_user_type 用户类型
 * @param p_adv_user 是否高级用户
 *
 * @returns 返回满足条件的教学场地
 */
CREATE OR REPLACE FUNCTION tm.sp_find_available_place (
  p_term_id integer,
  p_start_week integer,
  p_end_week integer,
  p_odd_even integer,
  p_day_of_week integer,
  p_section_id integer,
  p_place_type varchar(20),
  p_user_type integer,
  p_adv_user boolean
) RETURNS TABLE(
   id varchar(6),
   name varchar(50),
   seat integer,
   count bigint
) AS $$
declare
  p_start_section integer;
  p_total_section integer;
  p_includes integer[];
  p_term_start_week integer;
  p_term_max_week integer;
begin
  select start, total, includes
  into p_start_section, p_total_section, p_includes
  from tm.booking_section bs
  where bs.id = p_section_id;

  select start_week, max_week
  into p_term_start_week, p_term_max_week
  from ea.term
  where term.id = p_term_id;

  return query
  with series as ( -- 生成序列，用于判断周次是否相交
    select i from generate_series(p_term_start_week, p_term_max_week) as s(i)
  ), booking_weeks as (
    select i from series
    where i between p_start_week and p_end_week
      and (p_odd_even = 0 or p_odd_even = 1 and i % 2 = 1 or p_odd_even = 2 and i % 2 = 0)
  )
  select p1.id, p1.name, p1.seat, (
    select count(*)
    from booking_form bf
    join booking_item bi on bf.id = bi.form_id
    join booking_section bs on bs.id = bi.section_id
    where bf.term_id = p_term_id
    and bf.status in ('SUBMITTED', 'CHECKED')
    and bi.day_of_week = p_day_of_week
    and bs.includes && p_includes
    and exists (
          select i from booking_weeks
          intersect
          select i from series
          where i between start_week and end_week
            and (odd_even = 0 or odd_even = 1 and i % 2 = 1 or odd_even = 2 and i % 2 = 0)
    )
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
    where term_id = p_term_id
      and day_of_week = p_day_of_week
      and int4range(p_start_section, p_start_section + p_total_section)
       && int4range(start_section, start_section + total_section)
      and exists (
            select * from booking_weeks
            intersect
            select * from series
            where i between start_week and end_week
              and (odd_even = 0 or odd_even = 1 and i % 2 = 1 or odd_even = 2 and i % 2 = 0)
      )
  );
end;
$$ LANGUAGE plpgsql;

/**
 * 查询冲突的教室借用项
 *
 * @param p_form_id 借用表单ID
 *
 * @returns 冲突的教室借用项ID
 */
CREATE OR REPLACE FUNCTION tm.sp_find_booking_conflict(
  p_form_id bigint
) RETURNS TABLE (
  item_id bigint
) AS $$
begin
  return query
  with series as ( -- 生成序列，用于判断周次是否相交
    select i from generate_series(1, 30) as s(i)
  ), form_item as ( -- 备选教室借用项
    select form.term_id, item.id item_id, item.place_id,
           item.start_week, item.end_week, item.odd_even, item.day_of_week,
           bs.start as start_section, bs.total as total_section
    from booking_form form
    join booking_item item on form.id = item.form_id
    join booking_section bs on item.section_id = bs.id
    where form.id = p_form_id
  )
  select fi.item_id
  from form_item fi
  where exists (
    select place_id
    from tm.ev_place_usage pu
    where pu.term_id = fi.term_id
      and pu.place_id = fi.place_id
      and pu.day_of_week = fi.day_of_week
      and int4range(pu.start_section, pu.start_section + pu.total_section)
       && int4range(fi.start_section, fi.start_section + fi.total_section)
      and exists (
        select * from series where i between pu.start_week and pu.end_week
        and (pu.odd_even = 0 or pu.odd_even = 1 and i % 2 = 1 or pu.odd_even = 2 and i % 2 = 0)
        intersect
        select * from series where i between fi.start_week and fi.end_week
        and (fi.odd_even = 0 or fi.odd_even = 1 and i % 2 = 1 or fi.odd_even = 2 and i % 2 = 0)
      )
  );
end;
$$ LANGUAGE plpgsql;

/**
 * 查询指定行政班的学生考勤统计
 *
 * @p_term_id 学期
 * @p_admin_class_id 行政班ID
 */
create or replace function tm.sp_get_student_attendance_stats_by_admin_class (
  p_term_id integer,
  p_admin_class_id bigint
) returns table (
  id text,
  name text,
  admin_class text,
  absent bigint,
  late numeric(8,1),
  early bigint,
  total numeric(8,1),
  leave bigint
) as $$
begin
  return query
  with free_listen as (
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
      sum(case when type = 1 then total_section else 0 end) as absent,
      sum(case when type = 2 then 0.5 else 0.0 end)         as late,
      sum(case when type = 3 then total_section else 0 end) as early,
      sum(case when type = 4 then total_section else 0 end) as leave,
      sum(case when type = 5 then total_section else 0 end) as late_early
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    group by student_id
  )
  select student.id::text, student.name::text, admin_class.name::text,
         attendance.absent,
         attendance.late,
         attendance.early +
         attendance.late_early as early,
         attendance.absent +
         attendance.late +
         attendance.early +
         attendance.late_early as total,
         attendance.leave
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by total desc, leave desc;
end;
$$ LANGUAGE plpgsql;

/**
 * 查询指定管理员（班主任/辅导员）的学生考勤统计
 *
 * @p_term_id 学期
 * @p_user_id 用户ID
 */
create or replace function tm.sp_get_student_attendance_stats_by_administrator (
  p_term_id integer,
  p_user_id text
) returns table (
  id text,
  name text,
  admin_class text,
  absent bigint,
  late numeric(8,1),
  early bigint,
  total numeric(8,1),
  leave bigint
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
      sum(case when type = 1 then total_section else 0 end) as absent,
      sum(case when type = 2 then 0.5 else 0.0 end)         as late,
      sum(case when type = 3 then total_section else 0 end) as early,
      sum(case when type = 4 then total_section else 0 end) as leave,
      sum(case when type = 5 then total_section else 0 end) as late_early
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    group by student_id
  )
  select student.id::text, student.name::text, admin_class.name::text,
         attendance.absent,
         attendance.late,
         attendance.early +
         attendance.late_early as early,
         attendance.absent +
         attendance.late +
         attendance.early +
         attendance.late_early as total,
         attendance.leave
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by total desc, leave desc
  limit 100;
end;
$$ LANGUAGE plpgsql;

/**
 * 查询指定管理员（班主任/辅导员）按行政班统计存在考勤数据的学生数
 *
 * @p_term_id 学期
 * @p_user_id 用户ID
 */
create or replace function tm.sp_get_admin_class_attendance_stats_by_administrator (
  p_term_id integer,
  p_user_id text
) returns table (
  id bigint,
  name text,
  count bigint
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
$$ LANGUAGE plpgsql;

/**
 * 查询指定学院的学生考勤统计
 *
 * @p_term_id 学期
 * @p_department_id 学院ID
 */
create or replace function tm.sp_get_student_attendance_stats_by_department (
  p_term_id integer,
  p_department_id text
) returns table (
  id text,
  name text,
  admin_class text,
  absent bigint,
  late numeric(8,1),
  early bigint,
  total numeric(8,1),
  leave bigint
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
      sum(case when type = 1 then total_section else 0 end) as absent,
      sum(case when type = 2 then 0.5 else 0.0 end)         as late,
      sum(case when type = 3 then total_section else 0 end) as early,
      sum(case when type = 4 then total_section else 0 end) as leave,
      sum(case when type = 5 then total_section else 0 end) as late_early
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    group by student_id
  )
  select student.id::text, student.name::text, admin_class.name::text,
         attendance.absent,
         attendance.late,
         attendance.early +
         attendance.late_early as early,
         attendance.absent +
         attendance.late +
         attendance.early +
         attendance.late_early as total,
         attendance.leave
  from attendance
  join ea.student on attendance.student_id = student.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  order by total desc, leave desc
  limit 100;
end;
$$ LANGUAGE plpgsql;

/**
 * 查询指定学院按行政班统计存在考勤数据的学生数
 *
 * @p_term_id 学期
 * @p_department_id 学院ID
 */
create or replace function tm.sp_get_admin_class_attendance_stats_by_department (
  p_term_id integer,
  p_department_id text
) returns table (
  id bigint,
  name text,
  count bigint
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
$$ LANGUAGE plpgsql;

/**
 * 按时间段查询学生考勤统计，用于点名显示
 *
 * @p_term_id 学期
 * @p_teacher_id 教师ID
 * @p_week 周次
 * @p_day_of_week 星期几
 * @p_start_section 开始节
 */
create or replace function tm.sp_get_student_attendance_stats_by_timeslot (
  p_term_id integer,
  p_teacher_id text,
  p_week integer,
  p_day_of_week integer,
  p_start_section integer
) returns table (
  id text,
  absent bigint,
  late bigint,
  early bigint,
  leave bigint
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
$$ LANGUAGE plpgsql;

/**
 * 按安排和学生查询学生考勤统计，用于点名时实时更新
 *
 * @p_task_schedule_id 安排
 * @p_student_id 学号
 */
create or replace function tm.sp_get_student_attendance_stats_by_task_schedule_student (
  p_task_schedule_id uuid,
  p_student_id text
) returns table (
  id text,
  absent bigint,
  late bigint,
  early bigint,
  leave bigint
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
$$ LANGUAGE plpgsql;

/**
 * 按教学班查询学生考勤统计
 *
 * @p_course_class_id 教学班ID
 */
create or replace function tm.sp_get_student_attendance_stats_by_course_class (
  p_course_class_id uuid
) returns table (
  id text,
  absent bigint,
  late numeric(8,1),
  early bigint,
  total numeric(8,1),
  leave bigint
) as $$
begin
  return query
  with attendance_student as ( -- 教学班覆盖的学生
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
      sum(case when type = 1 then total_section else 0 end) as absent,
      sum(case when type = 2 then 0.5 else 0.0 end)         as late,
      sum(case when type = 3 then total_section else 0 end) as early,
      sum(case when type = 4 then total_section else 0 end) as leave,
      sum(case when type = 5 then total_section else 0 end) as late_early
    from (
      select student_id, total_section, type from rollcall
      union all
      select student_id, total_section, type from student_leave
    ) as x
    group by student_id
  )
  select student_id::text,
         attendance.absent,
         attendance.late,
         attendance.early +
         attendance.late_early as early,
         attendance.absent +
         attendance.late +
         attendance.early +
         attendance.late_early as total,
         attendance.leave
  from attendance
  order by 1;
end;
$$ LANGUAGE plpgsql;

/**
 * 按教学班和学号查询学生点名详情
 *
 * @p_course_class_id 教学班ID
 * @p_student_id 学号
 */
create or replace function tm.sp_get_rollcall_details_by_course_class_student (
  p_course_class_id uuid,
  p_student_id text
) returns table (
  id bigint,
  week integer,
  day_of_week integer,
  start_section integer,
  total_section integer,
  type integer,
  course text,
  course_item text,
  teacher text,
  student_leave_form_id bigint,
  free_listen_form_id bigint
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
$$ LANGUAGE plpgsql;

/**
 * 按教学班和学号查询学生请假详情
 *
 * @p_course_class_id 教学班ID
 * @p_student_id 学号
 */
create or replace function tm.sp_get_student_leave_details_by_course_class_student (
  p_course_class_id uuid,
  p_student_id text
) returns table (
  id bigint,
  week integer,
  day_of_week integer,
  start_section integer,
  total_section integer,
  type integer,
  course text,
  course_item text,
  teacher text,
  student_leave_form_id bigint,
  free_listen_form_id bigint
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
$$ LANGUAGE plpgsql;

/**
 * 按学期和学号查询学生点名详情
 *
 * @p_term_id 学期
 * @p_student_id 学号
 */
create or replace function tm.sp_get_rollcall_details_by_student (
  p_term_id integer,
  p_student_id text
) returns table (
  id bigint,
  week integer,
  day_of_week integer,
  start_section integer,
  total_section integer,
  type integer,
  course text,
  course_item text,
  teacher text,
  student_leave_form_id bigint,
  free_listen_form_id bigint
) as $$
#variable_conflict use_column
begin
  return query
  with attendance_schedule as ( -- 教学班覆盖的安排
    select task_schedule.id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.term_id = p_term_id
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
$$ LANGUAGE plpgsql;

/**
 * 按学期和学号查询学生请假详情
 *
 * @p_term_id 学期
 * @p_student_id 学号
 */
create or replace function tm.sp_get_student_leave_details_by_student (
  p_term_id integer,
  p_student_id text
) returns table (
  id bigint,
  week integer,
  day_of_week integer,
  start_section integer,
  total_section integer,
  type integer,
  course text,
  course_item text,
  teacher text,
  student_leave_form_id bigint,
  free_listen_form_id bigint
) as $$
#variable_conflict use_column
begin
  return query
  with attendance_schedule as ( -- 教学班覆盖的安排
    select task_schedule.id
    from ea.course_class
    join ea.task on course_class.id = task.course_class_id
    join ea.task_schedule on task.id = task_schedule.task_id
    where course_class.term_id = p_term_id
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
$$ LANGUAGE plpgsql;