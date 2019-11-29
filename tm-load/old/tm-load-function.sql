/**
 * 任务教学方式更新触发器函数
 */
create or replace function tm_load.fn_before_update_task_workload_config() returns trigger as $$
declare
  v_form_status tm.state;
  v_value_changed boolean;
	v_history jsonb;
  v_history_fields text[];
begin
  case TG_TABLE_NAME
    when 'task_instructional_mode' then
      v_history_fields = '{type, ratio}';
    when 'task_workload_settings' then
      v_history_fields = '{type, value, note}';
    when 'workload_correction' then
      v_history_fields = '{type, value, note}';
  end case;

  -- v_value_changed = old.a <> new.a or old.b <> new.b ...
  execute 'select ' || (
    select string_agg('$1.' || field || ' <> $2.' || field, ' or ') from unnest(v_history_fields) t(field)
  )
  into v_value_changed
  using old, new;

  -- 如果跟踪值没有修改，则继续
  if not v_value_changed then
    return new;
  end if;

  -- 如果当前为恢复操作，则继续
  if jsonb_array_length(old.histories) = jsonb_array_length(new.histories) + 1 then
    return new;
  end if;

  if old.form_id is not null then
    -- 获取表单状态
    select status into v_form_status
    from tm_load.workload_form
    where id = old.form_id;

    -- 如果正在审批过程中，则报错
    if v_form_status in ('SUBMITTED', 'CHECKED', 'APPROVED') then
      raise exception 'Should not update item task_id=% when it in workflow.', old.task_id;
    end if;

    -- 如果已提交，则保存历史
    -- v_history = jsonb_build_object('a', old.a, 'b', old.b, ..., 'effective_to', localtimestamp);
    v_history_fields = v_history_fields || '{flag, form_id, date_created, last_updated}';
    execute 'select jsonb_build_object(' || (
      select string_agg('''' || field || ''', $1.' || field, ', ') from unnest(v_history_fields) t(field)
    ) || ', ''effective_to'', localtimestamp)'
    into v_history
    using old;

    new.histories = jsonb_insert(old.histories, '{0}', v_history);
    new.flag = 'U';
    new.form_id = null;
  else
    -- 获取表单状态
    select status into v_form_status
    from tm_load.workload_form
    where (term_id, department_id) in (
      select term_id, department_id
      from ea.course_class
      join ea.task on course_class.id = task.course_class_id
      where task.id = (string_to_array(old.task_id, ','))[1]::uuid
    );

    -- 如果正在审批过程中，则报错
    if v_form_status in ('SUBMITTED', 'CHECKED', 'APPROVED') then
      raise exception 'Should not update this row when it in workflow.';
    end if;

    -- 如果未提交且为软删除，则报错
    if old.flag = 'D' then
      raise exception 'Can not update this row when it soft deleted.'
      using hint = 'Please delete to restore the item.';
    end if;
  end if;

  new.last_updated = localtimestamp;
  return new;
end;
$$ language plpgsql;

/**
 * 任务教学方式删除触发器函数
 */
create or replace function tm_load.fn_before_delete_task_workload_config()
returns trigger as $$
declare
  v_form_status tm.state;
  v_history jsonb;
  v_history_fields text[];
  v_history_values record;
  v_primary_fields text[];
  v_primary_values record;
begin
  -- 标记为X的，可强制删除
  if old.flag = 'X' then
    return old;
  end if;

  case TG_TABLE_NAME
    when 'task_instructional_mode' then
      v_history_fields = '{type, ratio}';
      v_primary_fields = '{task_id}';
    when 'task_workload_settings' then
      v_history_fields = '{type, value, note}';
      v_primary_fields = '{task_id}';
    when 'workload_correction' then
      v_history_fields = '{type, value, note}';
      v_primary_fields = '{task_id, teacher_id}';
  end case;
  v_history_fields = v_history_fields || '{flag, form_id, date_created, last_updated}';

  -- v_primary_values = (old.a, old.b, ...)
  execute 'select ' || (
    select string_agg('$1.' || field, ', ') from unnest(v_primary_fields) t(field)
  )
  into v_primary_values
  using old;

  if old.form_id is not null then
    -- 获取表单状态
    select status into v_form_status
    from tm_load.workload_form
    where id = old.form_id;

    -- 如果正在审批过程中，则报错
    if v_form_status in ('SUBMITTED', 'CHECKED', 'APPROVED') then
      raise exception 'Should not delete this row when it in workflow.';
    end if;

    -- 如果已提交，则保存历史
    -- v_history = jsonb_build_object('a', old.a, 'b', old.b, ..., 'effective_to', localtimestamp);
    execute 'select jsonb_build_object(' || (
      select string_agg('''' || field || ''', $1.' || field, ', ') from unnest(v_history_fields) t(field)
    ) || ', ''effective_to'', localtimestamp)'
    into v_history
    using old;

    execute format($exe$
      update tm_load.%I set
      histories = $1,
      flag = 'D',
      last_updated = localtimestamp,
      form_id = null
      where %s = $2
    $exe$, TG_TABLE_NAME, 'row(' || array_to_string(v_primary_fields, ',') || ')')
    using jsonb_insert(old.histories, '{0}', v_history), v_primary_values;
    return null;
  else -- 未提交
    -- 获取表单状态
    select status into v_form_status
    from tm_load.workload_form
    where (term_id, department_id) in (
      select term_id, department_id
      from ea.course_class
      join ea.task on course_class.id = task.course_class_id
      where task.id = (string_to_array(old.task_id, ','))[1]::uuid
    );

    -- 如果正在审批过程中，则报错
    if v_form_status in ('SUBMITTED', 'CHECKED', 'APPROVED') then
      raise exception 'Should not delete this row when it in workflow.';
    end if;

    -- 如果没有历史数据则直接删除
    if jsonb_array_length(old.histories) = 0 then
      return old;
    else
      -- 如果存在历史数据，则恢复
      v_history = old.histories->0;
      -- 重要，使v_history_values获取当前表的类型
      v_history_values = old;
      v_history_values = jsonb_populate_record(v_history_values, v_history);

      -- update table_name set
      -- (a,b,c) = (y.a,y.b,y.c)
      -- where row(x.m,x.n) = (m,n)
      execute format($exe$
        update tm_load.%I x set
        histories = x.histories - 0,
        (%s) = (%s)
        from (select $1.*) y
        where %s = $2
      $exe$, TG_TABLE_NAME, array_to_string(v_history_fields, ','), (
          select string_agg('y.' || t.field, ',') from unnest(v_history_fields) t(field)
        ), (
          select 'row(' || string_agg('x.' || t.field, ',') || ')' from unnest(v_primary_fields) t(field)
        )
      )
      using v_history_values, v_primary_values;
      return null;
    end if;
  end if;
end;
$$ language plpgsql;

/**
 * 任务教学方式更新触发器
 */
drop trigger if exists tr_before_update_task_instructional_mode
on tm_load.task_instructional_mode;
create trigger tr_before_update_task_instructional_mode
before update on tm_load.task_instructional_mode for each row
execute procedure tm_load.fn_before_update_task_workload_config();

/**
 * 任务教学方式删除触发器
 */
drop trigger if exists tr_before_delete_task_instructional_mode
on tm_load.task_instructional_mode;
create trigger tr_before_delete_task_instructional_mode
before delete on tm_load.task_instructional_mode for each row
execute procedure tm_load.fn_before_delete_task_workload_config();

/**
 * 任务工作量设置更新触发器
 */
drop trigger if exists tr_before_update_task_workload_settings
on tm_load.task_workload_settings;
create trigger tr_before_update_task_workload_settings
before update on tm_load.task_workload_settings for each row
execute procedure tm_load.fn_before_update_task_workload_config();

/**
 * 任务工作量设置删除触发器
 */
drop trigger if exists tr_before_delete_task_workload_settings
on tm_load.task_workload_settings;
create trigger tr_before_delete_task_workload_settings
before delete on tm_load.task_workload_settings for each row
execute procedure tm_load.fn_before_delete_task_workload_config();

/**
 * 任务工作量调整更新触发器
 */
drop trigger if exists tr_before_update_workload_correction
on tm_load.workload_correction;
create trigger tr_before_update_workload_correction
before update on tm_load.workload_correction for each row
execute procedure tm_load.fn_before_update_task_workload_config();

/**
 * 任务工作量调整置删除触发器
 */
drop trigger if exists tr_before_delete_workload_correction
on tm_load.workload_correction;
create trigger tr_before_delete_workload_correction
before delete on tm_load.workload_correction for each row
execute procedure tm_load.fn_before_delete_task_workload_config();
