create or replace function tm_load.fn_build_workload_task_schedule_string(
  p_workload_task_id uuid,
  p_teacher_id text
) returns text stable as $$
declare
  result text;
begin
  with schedule_weeks as (
    select day_of_week, start_section, total_section, '第' || string_agg(
        case when start_week = end_week then start_week::text else start_week || '-' || end_week end ||
        case odd_even when 1 then '单' when 2 then '双' else '' end,
        ',' order by start_week) || '周' as weeks
    from tm_load.workload_task_schedule
    where workload_task_id = p_workload_task_id
    and teacher_id = p_teacher_id
    group by day_of_week, start_section, total_section
  ), schedule_weeks_sections as (
    select day_of_week, weeks || ea.fn_day_of_week_to_string(day_of_week) || string_agg(
        start_section || '-' || (start_section + total_section - 1),
        ',' order by start_section) || '节' as schedule
    from schedule_weeks
    group by weeks, day_of_week
  )
  select string_agg(schedule, ';' order by day_of_week) into result
  from schedule_weeks_sections;

  return result;
end;
$$ language plpgsql;
