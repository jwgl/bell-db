/**
 * 生成教学安排
 */
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

/**
 * 设置工作量修正
 */
create or replace function tm_load.fn_set_workload_correction(
  p_term_id integer,
  p_department_id text,
  p_teacher_id text,
  p_correction numeric(6,2),
  p_note text
) returns void as $$
begin
  -- Upsert工作量修正
  insert into tm_load.workload(term_id, department_id, teacher_id, correction, note, workload_source_type, date_modified)
  select p_term_id, p_department_id, p_teacher_id, p_correction, p_note, 2 /*手工*/, LOCALTIMESTAMP
  on conflict(term_id, department_id, teacher_id) do update set
  correction = excluded.correction,
  note = excluded.note,
  date_modified = LOCALTIMESTAMP;

  -- 更新workload的总工作量
  update tm_load.workload workload set
  adjustment_workload = dvu.adjustment_workload,
  supplement_workload = dvu.supplement_workload,
  total_workload = dvu.total_workload
  from tm_load.dvu_workload dvu
  where dvu.term_id = workload.term_id
  and dvu.department_id = workload.department_id
  and dvu.teacher_id = workload.teacher_id
  and workload.term_id = p_term_id
  and workload.department_id = p_department_id
  and workload.teacher_id = p_teacher_id;

  -- 更新报表
  perform tm_load.fn_update_workload_report(p_term_id, p_teacher_id);
end;
$$ language plpgsql;

/**
 * 设置任务教师工作量修正
 */
create or replace function tm_load.fn_set_workload_task_teacher_correction(
  p_workload_task_id uuid,
  p_teacher_id text,
  p_correction numeric(6,2),
  p_note text
) returns void as $$
declare
  v_term_id integer;
  v_department_id text;
begin
  -- 更新工作量修正
  update tm_load.workload_task_teacher set
  correction = p_correction,
  note = p_note
  where workload_task_id = p_workload_task_id
  and teacher_id = p_teacher_id;

  select term_id, department_id into v_term_id, v_department_id
  from tm_load.workload_task
  where id = p_workload_task_id;

  -- 更新workload_task_teacher的标准工作量和任务顺序
  update tm_load.workload_task_teacher workload_task_teacher set
  standard_workload = dvu.standard_workload,
  task_ordinal = dvu.task_ordinal
  from tm_load.dvu_workload_task_teacher_standard_workload dvu
  where dvu.workload_task_id = workload_task_teacher.workload_task_id
  and dvu.teacher_id = p_teacher_id
  and workload_task_teacher.workload_task_id = p_workload_task_id;

  -- 更新workload的总工作量
  update tm_load.workload workload set
  adjustment_workload = dvu.adjustment_workload,
  supplement_workload = dvu.supplement_workload,
  total_workload = dvu.total_workload
  from tm_load.dvu_workload dvu
  where dvu.term_id = workload.term_id
  and dvu.department_id = workload.department_id
  and dvu.teacher_id = workload.teacher_id
  and workload.term_id = v_term_id
  and workload.department_id = v_department_id
  and workload.teacher_id = p_teacher_id;

  -- 更新报表
  perform tm_load.fn_update_workload_report(v_term_id, p_teacher_id);
end;
$$ language plpgsql;

/**
 * 更新教学工作量
 */
create or replace function tm_load.fn_update_workload(
  p_term_id integer
) returns void as $$
begin
  -- 合并workload_task
  raise notice 'Insert workload_task ...';
  insert into tm_load.workload_task(term_id, department_id, code, task_ids, course_id, course_name,
    course_credit, course_item, workload_type, workload_mode, campus)
  select term_id, department_id, code, task_ids, course_id, course_name,
    course_credit, course_item, workload_type, workload_mode, 1
  from tm_load.dvm_workload_task
  where term_id = p_term_id
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
  raise notice 'Update workload_task primary_teacher ...';
  update tm_load.workload_task workload_task set
  primary_teacher_id = dvu.primary_teacher_id
  from tm_load.dvu_task_primary_teacher dvu
  where dvu.id = workload_task.id
  and workload_task.term_id = p_term_id;

  -- 更新workload_task的选课人数
  raise notice 'Update workload_task student_count ...';
  update tm_load.workload_task workload_task set
  student_count = (
    select count(distinct student_id)
    from ea.task_student
    where task_student.task_id = any(workload_task.task_ids)
  )
  where workload_task.term_id = p_term_id;

  -- 更新workload_task的教学班信息
  raise notice 'Update workload_task course_class ...';
  update tm_load.workload_task workload_task set
  course_property = dvu.course_property,
  course_class_name = dvu.course_class_name,
  course_class_major = dvu.course_class_major
  from tm_load.dvu_workload_task_course_class dvu
  where dvu.workload_task_id = workload_task.id
  and workload_task.term_id = p_term_id;

  -- 更新workload_task的班级规模
  raise notice 'Update workload_task class_size ...';
  update tm_load.workload_task workload_task set
  class_size_source = dvu.source,
  class_size_type = dvu.type,
  class_size_ratio = dvu.ratio
  from tm_load.dvu_workload_task_class_size dvu
  where dvu.workload_task_id = workload_task.id
  and workload_task.term_id = p_term_id;

  -- 更新workload_task的教学形式
  raise notice 'Update workload_task instructional_mode ...';
  update tm_load.workload_task workload_task set
  instructional_mode_source = dvu.source,
  instructional_mode_type = dvu.type,
  instructional_mode_ratio = dvu.ratio,
  student_count_upper_bound = dvu.upper_bound
  from tm_load.dvu_workload_task_instructional_mode dvu
  where dvu.workload_task_id = workload_task.id
  and workload_task.term_id = p_term_id;

  -- 合并workload_task_schedule
  raise notice 'Merge workload_task_schedule ...';
  insert into tm_load.workload_task_schedule(workload_task_id, task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id)
  select workload_task_id, task_schedule_ids, start_week, end_week, odd_even, day_of_week, start_section, total_section, teacher_id
  from tm_load.dvm_task_schedule
  where workload_task_id in (
    select id from tm_load.workload_task where term_id = p_term_id
  )
  on conflict(task_schedule_ids) do update set
  start_week = excluded.start_week,
  end_week = excluded.end_week,
  odd_even = excluded.odd_even,
  day_of_week = excluded.day_of_week,
  start_section = excluded.start_section,
  total_section = excluded.total_section,
  teacher_id = excluded.teacher_id;

  -- 合并workload_task_teacher
  raise notice 'Merge workload_task_teacher ...';
  insert into tm_load.workload_task_teacher(workload_task_id, teacher_id, original_workload, correction, parallel_ratio)
  select workload_task_id, teacher_id, original_workload, correction, parallel_ratio
  from tm_load.dvm_workload_task_teacher
  where workload_task_id in (
    select id from tm_load.workload_task where term_id = p_term_id
  )
  on conflict(workload_task_id, teacher_id) do update set
  original_workload = excluded.original_workload,
  parallel_ratio = excluded.parallel_ratio
  where workload_task_teacher.original_workload <> excluded.original_workload
    or workload_task_teacher.parallel_ratio <> excluded.parallel_ratio;

  -- 更新workload_task_teacher的标准工作量和任务顺序
  raise notice 'Update workload_task_teacher standard_workload ...';
  update tm_load.workload_task_teacher workload_task_teacher set
  standard_workload = dvu.standard_workload,
  task_ordinal = dvu.task_ordinal
  from tm_load.dvu_workload_task_teacher_standard_workload dvu
  where dvu.workload_task_id = workload_task_teacher.workload_task_id
  and dvu.teacher_id = workload_task_teacher.teacher_id
  and workload_task_teacher.workload_task_id in (
    select id from tm_load.workload_task where term_id = p_term_id
  );

  -- 合并teacher_workload_settings
  raise notice 'Merge teacher_workload_settings ...';
  insert into tm_load.teacher_workload_settings(teacher_id, post_type, employment_mode, employment_status, supplement)
  select teacher_id, post_type, employment_mode, employment_status, supplement
  from tm_load.dvm_teacher_workload_settings
  on conflict(teacher_id) do update set
  post_type = excluded.post_type,
  employment_mode = excluded.employment_mode,
  employment_status = excluded.employment_status,
  supplement = excluded.supplement;

  -- 删除workload_task_teacher
  raise notice 'Delete teacher_workload_settings ...';
  delete from tm_load.teacher_workload_settings
  where teacher_id not in (
    select teacher_id
    from tm_load.dvm_teacher_workload_settings
  );

  -- 删除workload_task_schedule
  raise notice 'Delete workload_task_schedule ...';
  delete from tm_load.workload_task_schedule
  where task_schedule_ids not in (
    select task_schedule_ids
    from tm_load.dvm_task_schedule
  ) and workload_task_id in (
    select id from tm_load.workload_task where term_id = p_term_id
  );

  -- 删除workload_task_teacher
  raise notice 'Delete workload_task_teacher ...';
  delete from tm_load.workload_task_teacher
  where (workload_task_id, teacher_id) not in (
    select workload_task_id, teacher_id
    from tm_load.dvm_workload_task_teacher
  ) and workload_task_id in (
    select id from tm_load.workload_task where term_id = p_term_id
  );

  -- 删除workload_task
  raise notice 'Delete workload_task ...';
  delete from tm_load.workload_task
  where task_ids not in (
    select task_ids
    from tm_load.dvm_workload_task
    where term_id = p_term_id
  ) and term_id = p_term_id;

  -- 合并workload
  raise notice 'Merge workload ...';
  insert into tm_load.workload(term_id, department_id, teacher_id,
    teaching_workload, practice_workload, executive_workload)
  select term_id, department_id, teacher_id,
    teaching_workload, practice_workload, executive_workload
  from tm_load.dvm_workload
  where term_id = p_term_id
  on conflict(term_id, department_id, teacher_id) do update set
  teaching_workload = excluded.teaching_workload,
  practice_workload = excluded.practice_workload,
  executive_workload = excluded.executive_workload;

  -- 更新不存在的教师的工作量为0
  raise notice 'Update workload not exists ...';
  update tm_load.workload set
  teaching_workload = 0,
  practice_workload = 0,
  executive_workload = 0
  where term_id = p_term_id
  and teacher_id not in (
    select teacher_id from tm_load.dvm_workload where term_id = p_term_id
  );

  -- 合并external_workload
  raise notice 'Merge external_workload ...';
  insert into tm_load.workload(term_id, department_id, teacher_id,
    teaching_workload, practice_workload, executive_workload,
    external_teaching_workload, external_practice_workload,
    external_executive_workload, external_correction)
  select term_id, department_id, teacher_id,
    0.00, 0.00, 0.00,
    external_teaching_workload, external_practice_workload,
    external_executive_workload, external_correction
  from tm_load.dvm_external_workload
  where term_id = p_term_id
  on conflict(term_id, department_id, teacher_id) do update set
  external_teaching_workload = excluded.external_teaching_workload,
  external_practice_workload = excluded.external_practice_workload,
  external_executive_workload = excluded.external_executive_workload,
  external_correction = excluded.external_correction;

  -- 更新不存在的教师的外部工作量为0
  raise notice 'Update external workload not exists ...';
  update tm_load.workload set
  external_teaching_workload = 0,
  external_practice_workload = 0,
  external_executive_workload = 0,
  external_correction = 0
  where term_id = p_term_id
  and teacher_id not in (
    select teacher_id from tm_load.dvm_external_workload where term_id = p_term_id
  );

  -- 更新workload的总工作量
  raise notice 'Update total workload ...';
  update tm_load.workload workload set
  adjustment_workload = dvu.adjustment_workload,
  supplement_workload = dvu.supplement_workload,
  total_workload = dvu.total_workload
  from tm_load.dvu_workload dvu
  where dvu.term_id = workload.term_id
  and dvu.department_id = workload.department_id
  and dvu.teacher_id = workload.teacher_id
  and workload.term_id = p_term_id;

  -- 删除workload
  raise notice 'Delete workload ...';
  delete from tm_load.workload
  where (term_id, department_id, teacher_id) not in (
    select term_id, department_id, teacher_id
    from tm_load.dvm_workload
    union all
    select term_id, department_id, teacher_id
    from tm_load.dvm_external_workload
  ) and term_id = p_term_id
  and correction = 0.00; -- 且教师无修正，如有修正，则不删除。

  -- 更新报表
  raise notice 'Update report ...';
  perform tm_load.fn_update_workload_report(p_term_id);
end;
$$ language plpgsql;

/**
 * 按学期更新教学工作量报告
 */
create or replace function tm_load.fn_update_workload_report(
  p_term_id integer,
  p_teacher_id text default '%'
) returns void as $$
begin
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
    workload_source, course_class_name, course_class_major, note, hash_value
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
    workload_source, course_class_name, course_class_major, note, hash_value
  from tm_load.dvm_workload_report_detail
  where (term_id, teacher_id, workload_task_id) not in (
      select term_id, teacher_id, workload_task_id
      from tm_load.workload_report_detail
      where date_invalid is null
    )
    and term_id = p_term_id
    and teacher_id like p_teacher_id;

  -- 合并workload_report_detail：更新旧数据
  if exists(select 1 from tm_load.dvm_workload_report_detail
    where term_id = p_term_id
    and teacher_id like p_teacher_id
    and hash_value is null) then
    raise exception using hint = "Exists null hash_value in tm_load.dvm_workload_report_detail.";
  end if;

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
      workload_source, course_class_name, course_class_major, note, hash_value
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
      a.workload_source, a.course_class_name, a.course_class_major, a.note, a.hash_value
    from tm_load.dvm_workload_report_detail a
    join tm_load.workload_report_detail b on a.term_id = b.term_id
    and a.teacher_id = b.teacher_id
    and a.workload_task_id = b.workload_task_id
    where a.hash_value is distinct from b.hash_value
    and b.date_invalid is null
    and a.term_id = p_term_id
    and a.teacher_id like p_teacher_id
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
      select term_id, teacher_id, workload_task_id
      from tm_load.dvm_workload_report_detail
    )
    and date_invalid is null
    and term_id = p_term_id
    and teacher_id like p_teacher_id;

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
    note, hash_value
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
    note, hash_value
  from tm_load.dvm_workload_report
  where (term_id, teacher_id, teacher_name, teacher_department) not in (
      select term_id, teacher_id, teacher_name, teacher_department
      from tm_load.workload_report
      where date_invalid is null
    )
    and term_id = p_term_id
    and teacher_id like p_teacher_id;

  -- 合并workload_report：更新旧数据
  if exists(select 1 from tm_load.dvm_workload_report
    where term_id = p_term_id
    and teacher_id like p_teacher_id
    and hash_value is null) then
    raise exception using hint = "Exists null hash_value in tm_load.dvm_workload_report.";
  end if;

  with inserted as (
    insert into tm_load.workload_report(term_id,
      human_resource_id, human_resource_name, human_resource_department,
      employment_mode, post_type,
      teacher_id, teacher_name, teacher_department,
      teaching_workload, external_teaching_workload,
      adjustment_workload, supplement_workload,
      practice_workload, external_practice_workload,
      executive_workload, external_executive_workload,
      correction, external_correction, total_workload,
      note, hash_value
    )
    select a.term_id,
      a.human_resource_id, a.human_resource_name, a.human_resource_department,
      a.employment_mode, a.post_type,
      a.teacher_id, a.teacher_name, a.teacher_department,
      a.teaching_workload, a.external_teaching_workload,
      a.adjustment_workload, a.supplement_workload,
      a.practice_workload, a.external_practice_workload,
      a.executive_workload, a.external_executive_workload,
      a.correction, a.external_correction, a.total_workload,
      a.note, a.hash_value
    from tm_load.dvm_workload_report a
    join tm_load.workload_report b on a.term_id = b.term_id
    and a.teacher_id = b.teacher_id
    and a.teacher_name = b.teacher_name
    and a.teacher_department = b.teacher_department
    where a.hash_value is distinct from b.hash_value
      and b.date_invalid is null
      and a.term_id = p_term_id
      and a.teacher_id like p_teacher_id
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
      select term_id, teacher_id, teacher_department
      from tm_load.dvm_workload_report
    )
    and date_invalid is null
    and term_id = p_term_id
    and teacher_id like p_teacher_id;
end;
$$ language plpgsql;
