/**
 * 更新班主班
 */
create or replace function tm.sp_update_student_leave_approver()
returns trigger
as $$
declare
  p_term_start date;
  p_term_end date;
  p_count integer;
begin
  select start_date, start_date + max_week * interval  '1 week' - interval '1 day'
  into p_term_start, p_term_end
  from ea.term
  where active = true;

  update tm.workitem w set
  to_user = new.counsellor_id
  where to_user = old.counsellor_id
  and from_user in (
    select id from ea.student where admin_class_id = new.id
  )
  and activity = 'student.leave.approve'
  and date_processed is null
  and date_created between p_term_start and p_term_end;
  get diagnostics p_count = row_count;
  
  raise notice 'Update admin_class counsellor from % to new %, update % student leave approve workitems.',
    old.counsellor_id, new.counsellor_id, p_count;
  return new;
end;
$$ language plpgsql;

/**
 * 周次转整数
 */
create or replace function ea.fn_weeks_to_integer(
  start_week integer,
  end_week integer,
  odd_even integer
) returns integer immutable
returns null on null input as $$
declare
  result integer;
begin
  result = 2147483647 >> (30 - end_week + start_week) << (start_week - 1);
  if odd_even = 0 then
    return result;
  elseif odd_even = 1 then
    return result & 1431655765; -- x'55555555'
  elseif odd_even = 2 then
    return result & 715827882;  -- x'2AAAAAAA'
  else
    raise 'Error odd_even value';
  end if;
end;
$$ language plpgsql;

/**
 * 周次转整数(成员函数)
 */
create or replace function ea.mf_get_weeks(
  schedule ea.task_schedule
) returns integer immutable
returns null on null input as $$
begin
  return ea.fn_weeks_to_integer(schedule.start_week, schedule.end_week, schedule.odd_even);
end
$$ language plpgsql;

/**
 * 计算周数
 */
create function ea.fn_weeks_count(
  start_week integer,
  end_week integer,
  odd_even integer
) returns integer immutable
returns null on null input as $$
begin
  if odd_even = 0 then
    return end_week - start_week + 1;
  elseif odd_even = 1 then
    return (end_week - start_week + 1) / 2 + (end_week & 1) * (start_week & 1);
  elseif odd_even = 2 then
    return (end_week - start_week + 1) / 2 + ((end_week + 1) & 1) * ((start_week + 1) & 1);
  else
    raise 'Error odd_even value';
  end if;
end
$$ language plpgsql;

/**
 * 计算周数(成员函数)
 */
create function ea.mf_get_week_count(
  schedule ea.task_schedule
) returns integer immutable
returns null on null input as $$
begin
  return ea.fn_weeks_count(schedule.start_week, schedule.end_week, schedule.odd_even);
end
$$ language plpgsql;

/*
 * 节次转整数
 */
create or replace function ea.fn_sections_to_integer(
  start_section integer,
  total_section integer
) returns integer immutable
returns null on null input as $$
begin
  return 2147483647 >> (31 - total_section) << (start_section - 1);
end;
$$ language plpgsql;

/*
 * 节次转整数(成员函数)
 */
create function ea.mf_get_sections(
  schedule ea.task_schedule
) returns integer immutable
returns null on null input as $$
begin
  return ea.fn_sections_to_integer(schedule.start_section, schedule.total_section);
end
$$ language plpgsql;

/*
 * 星期几转字符串
 */
create or replace function ea.fn_day_of_week_to_string(
  day_of_week integer
) returns text immutable
returns null on null input as $$
begin
  return '星期' || substring('一二三四五六日', day_of_week, 1);
end;
$$ language plpgsql;

/*
 * 节次转字符串
 */
create or replace function ea.fn_sections_to_string(
  start_section integer,
  total_section integer
) returns text immutable
returns null on null input as $$
begin
  return start_section || '-' || start_section + total_section - 1 || '节';
end;
$$ language plpgsql;

/*
 * 上课时间
 */
create or replace function ea.fn_timetable_to_string(
  start_week integer,
  end_week integer,
  odd_even integer,
  day_of_week integer,
  start_section integer,
  total_section integer
) returns text immutable
returns null on null input as $$
begin
  return start_week || '-' || end_week || '周'
    || case odd_even when 1 then '(单)' when 2 then '(双)' else '' end
    || '星期' || substring('一二三四五六日', day_of_week, 1)
    || start_section || '-' || start_section + total_section - 1 || '节';
end;
$$ language plpgsql;

/*
 * 上课时间(成员函数)
 */
create function ea.mf_get_timetable_string(
  schedule ea.task_schedule
) returns text immutable
returns null on null input as $$
begin
  return ea.fn_timetable_to_string(
    schedule.start_week,
    schedule.end_week,
    schedule.odd_even,
    schedule.day_of_week,
    schedule.start_section,
    schedule.total_section
  );
end
$$ language plpgsql;

create or replace function ea.mf_get_timetable_ordinal(
  schedule ea.task_schedule
) returns integer immutable
returns null on null input as $$
begin
  return schedule.day_of_week * 100000 +
         schedule.start_section * 1000 +
         schedule.start_week * 10 +
         schedule.odd_even;
end;
$$ language plpgsql;

