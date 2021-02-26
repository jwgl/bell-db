-- 数据视图-工作流流程
create or replace view wf.dv_workflow_task as
select task.id_ as id, task.name_ as name,
  task.proc_inst_id_ as process_instance_id,
  task.task_def_key_ as task_key,
  system_user.id as assignee_id,
  system_user.name as assignee_name,
  task.start_time_ as start_time,
  task.end_time_ as end_time,
  detail.name_ as result_key,
  detail.text_ as result_value,
  comment.message_ as result_comment
from wf.act_hi_taskinst task
join tm.system_user on task.assignee_ = system_user.id
left join wf.act_hi_actinst action on task.id_ = action.task_id_
left join wf.act_hi_detail detail on action.id_ = detail.act_inst_id_ and detail.type_ = 'VariableUpdate' and detail.name_ like '%Result'
left join wf.act_hi_comment comment on task.id_ = comment.task_id_ and comment.type_ = 'comment'
union all
select proc.id_ as id, '发起' as name,
  proc.id_ as process_instance_id,
  proc.start_act_id_ as task_key,
  system_user.id as assignee_id,
  system_user.name as assignee_name,
  proc.start_time_ as start_time,
  proc.start_time_ as end_time,
  'startProcess' as result_key,
  'START_UP' as result_value,
  null as result_comment
from wf.act_hi_procinst proc
join tm.system_user on proc.start_user_id_ = system_user.id
order by process_instance_id, start_time;
