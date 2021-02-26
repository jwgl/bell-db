create or replace function wf.fn_find_workflow_tasks(
  p_process_instance_id text
) returns jsonb
as $$
declare
  result jsonb;
begin
    select jsonb_agg(jsonb_build_object(
      'id', id,
      'name', name,
      'taskKey', task_key,
      'assigneeId', assignee_id,
      'assigneeName', assignee_name,
      'taskKey', task_key,
      'startTime', start_time,
      'endTime', end_time,
      'resultKey', result_key,
      'resultValue', result_value,
      'resultComment', result_comment
    ) order by start_time) into result
    from wf.dv_workflow_task
    where dv_workflow_task.process_instance_id = p_process_instance_id;

    return result;
end;
$$ language plpgsql;