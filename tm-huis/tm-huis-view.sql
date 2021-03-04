-- 数据辅助视图-教师角色
create or replace view tm_huis.dva_teacher_role as
select distinct user_id, booking_type.role_id
from tm_huis.booking_auth
join tm_huis.booking_type on booking_auth.booking_type_id = booking_type.id
join tm_huis.room on booking_auth.department_id = room.department_id
where booking_auth.enabled is true
and room.enabled is true
and booking_type.id = 101
union all
select distinct user_id, booking_type.role_id
from tm_huis.booking_auth
join tm_huis.booking_type on booking_auth.booking_type_id = booking_type.id
where booking_auth.enabled is true
and booking_type.id > 101
union all
select distinct operator_id, 'ROLE_HUIS_ROOM_OPERATOR' as role_id
from tm_huis.room_operator
join tm_huis.room on room_operator.room_id = room.id
where room.enabled is true;

-- 数据视图-会议室查看视图
create or replace view tm_huis.dv_booking_room as
select room.id,
  room.name,
  department.id as department_id,
  department.name as department_name,
  room.furniture,
  room.seat,
  room.max_seat,
  room.area,
  room.unit_price,
  room.time_unit,
  room.is_internal_free,
  room.is_public,
  (select jsonb_agg(jsonb_build_object(
        'id', facility.id,
        'name', facility.name,
        'unitPrice', facility.unit_price,
        'unitName', facility.unit_name,
        'timeUnit', facility.time_unit,
        'quantity', room_facility.quantity,
        'isBasic', room_facility.is_basic
      ) order by facility.id)
    from tm_huis.room_facility
    join tm_huis.facility on room_facility.facility_id = facility.id       
    where room_facility.room_id = room.id
  ) as facilities,
  (with booking as (
      select booking_item.id,
        booking_item.booking_time,
        booking_item.actual_time
      from tm_huis.booking_form
      join tm_huis.booking_item on booking_form.id = booking_item.form_id
      where booking_item.room_id = room.id
      and booking_form.status = 'ACTIVE'
      and booking_item.status = 'ACTIVE'
      and (booking_item.booking_time && tsrange(CURRENT_DATE, '9999-12-30'::date)
        or booking_item.actual_time && tsrange(CURRENT_DATE, '9999-12-30'::date)
      )
    ), booking_all as (
      select id, booking_time as occupied_time, false as is_actual
      from booking
      where actual_time is null
      union all
      select id, booking_time + actual_time, true
      from booking
      where booking_time && actual_time
      union all
      select id, actual_time, true
      from booking 
      where not booking_time && actual_time
      union all
        select x.id, reserved_time, false
        from (
          select room_reservation.id, tsrange(
            (reserved_date + room_reservation.lower_time)::timestamp,
            (reserved_date + room_reservation.upper_time)::timestamp,
            '[)'
          ) as reserved_time
          from tm_huis.room_reservation, generate_series(
            lower_date, upper_date, (date_interval || 'day')::interval
          ) t(reserved_date)
          where room_reservation.room_id = room.id
        ) x
        where reserved_time && tsrange(CURRENT_DATE, '9999-12-30'::date)
    )
    select jsonb_agg(jsonb_build_object(
        'id', booking_all.id,
        'lowerTime', lower(occupied_time),
        'upperTime', upper(occupied_time),
        'isActual', is_actual
      ) order by lower(occupied_time))
    from booking_all
  ) as booked_times
from tm_huis.room
join ea.department on room.department_id = department.id
order by room.name;

-- 数据视图-借用单列表视图
create or replace view tm_huis.dv_booking_list as
select booking_form.id,
  department.name as department,
  booking_type.name as type,
  booking_form.subject,
  booking_form.user_id,
  booking_form.date_updated,
  booking_form.workflow_state,
  (select act_ru_task.id_
    from wf.act_ru_task
    where booking_form.workflow_instance_id = act_ru_task.proc_inst_id_
    and booking_form.user_id = assignee_
    order by act_ru_task.create_time_
    limit 1
  ) as workflow_task_id
from tm_huis.booking_form
join ea.department on booking_form.department_id = department.id
join tm_huis.booking_type on booking_form.booking_type_id = booking_type.id
order by date_updated desc;

-- 数据视图-借用单查看视图
create or replace view tm_huis.dv_booking_form as
select booking_form.id,
  department.id as department_id,
  department.name as department_name,
  booking_type.id as booking_type_id,
  booking_type.name as booking_type_name,
  booking_form.is_internal,
  booking_form.subject,
  booking_form.description,
  booking_form.attendance,
  system_user.id as user_id,
  system_user.name as user_name,
  system_user.long_phone as user_phone_number,
  system_user.department_id as user_department_id,
  booking_form.contact,
  booking_form.contact_number,
  booking_form.workflow_state,
  booking_form.workflow_instance_id,
  booking_form.date_created,
  booking_form.date_updated,
  booking_form.status,
  (select jsonb_agg(jsonb_build_object(
      'id', booking_item.id,
      'roomId', room.id,
      'roomName', room.name,
      'bookingLowerTime', lower(booking_item.booking_time),
      'bookingUpperTime', upper(booking_item.booking_time),
      'actualLowerTime', lower(booking_item.actual_time),
      'actualUpperTime', upper(booking_item.actual_time),
      'timeUnit', booking_item.time_unit,
      'timeUnitQuantity', booking_item.time_unit_quantity,
      'overTimeQuantity', booking_item.over_time_quantity,
      'operatorId', system_user.id,
      'operatorName', system_user.name,
      'operatorNote', booking_item.operator_note,
      'workflowState', booking_item.workflow_state,
      'workflowInstanceId', booking_item.workflow_instance_id,
      'dateConfirm', booking_item.date_confirm,
      'dateCreated', booking_item.date_created,
      'dateUpdated', booking_item.date_updated,
      'status', booking_item.status,
      'note', booking_item.note,
      'isConflict', exists(
          select 1
          from tm_huis.booking_form bf
          join tm_huis.booking_item bi on bf.id = bi.form_id
          where bf.id <> booking_form.id
          and bi.room_id = booking_item.room_id
          and bi.booking_time && booking_item.booking_time
          and bf.status = 'ACTIVE'
          and bi.status = 'ACTIVE'
          and booking_form.status = 'INACTIVE'
          and booking_item.status = 'INACTIVE'
      ),
      'facilities', (select jsonb_agg(jsonb_build_object(
          'id', booking_facility.id,
          'facilityId', facility.id,
          'facilityName', facility.name,
          'unitPrice', booking_facility.unit_price,
          'unitName', booking_facility.unit_name,
          'timeUnit', booking_facility.time_unit,
          'quantity', booking_facility.quantity,
          'discount', booking_facility.discount,
          'subtotal', booking_facility.subtotal,
          'isAdditional', booking_facility.is_additional,
          'statementFormId', booking_facility.statement_form_id,
          'dateCreated', booking_facility.date_created,
          'dateUpdated', booking_facility.date_updated,
          'status', booking_facility.status,
          'note', booking_facility.note
        ) order by booking_facility.id)
        from tm_huis.booking_facility
        join tm_huis.facility on booking_facility.facility_id = facility.id       
        where booking_facility.item_id = booking_item.id
      )
    ) order by booking_item.id)
    from tm_huis.booking_item
    join tm_huis.room on booking_item.room_id = room.id
    left join tm.system_user on booking_item.operator_id = system_user.id
    where booking_item.form_id = booking_form.id
  ) as items,
  wf.fn_find_workflow_tasks(booking_form.workflow_instance_id) as workflow_tasks
from tm_huis.booking_form
join ea.department on booking_form.department_id = department.id
join tm_huis.booking_type on booking_form.booking_type_id = booking_type.id
join tm.system_user on booking_form.user_id = system_user.id;

-- 数据视图-借用项冲突
-- TODO: 优化只判断未来时间
create or replace view tm_huis.dv_booking_item_conflict as
select booking_item.id, booking_item.form_id, exists (
  select 1
  from tm_huis.booking_form bf
  join tm_huis.booking_item bi on bf.id = bi.form_id
  where bf.id <> booking_form.id
  and bi.room_id = booking_item.room_id  
  and bi.booking_time && booking_item.booking_time
  and bf.status = 'ACTIVE'
  and bi.status = 'ACTIVE'
  and booking_form.status = 'INACTIVE'
  and booking_item.status = 'INACTIVE'
) as is_conflict
from tm_huis.booking_form
join tm_huis.booking_item on booking_form.id = booking_item.form_id;

-- 数据视图-借用单冲突
-- TODO: 优化只判断未来时间
create or replace view tm_huis.dv_booking_form_conflict as
select bf1.id, exists (
  select 1
  from tm_huis.booking_item bi1,
       tm_huis.booking_form bf2
  join tm_huis.booking_item bi2 on bf2.id = bi2.form_id
  where bi1.form_id = bf1.id
  and bf1.id <> bf2.id
  and bi1.room_id = bi2.room_id
  and bi1.booking_time && bi2.booking_time
  and bf2.status = 'ACTIVE'
  and bi2.status = 'ACTIVE'
  and bf1.status = 'INACTIVE'
  and bf1.status = 'INACTIVE'
) as is_conflict
from tm_huis.booking_form bf1;

-- 数据视图-确认单列表视图
create or replace view tm_huis.dv_operation_list as
select booking_item.id as id,
  department.name as department,
  booking_type.name as type,
  booking_form.subject,
  room.name as room,
  lower(booking_item.booking_time) as booking_lower_time,
  upper(booking_item.booking_time) as booking_upper_time,
  lower(booking_item.actual_time) as actual_lower_time,
  upper(booking_item.actual_time) as actual_upper_time,
  room_operator.operator_id,
  booking_item.workflow_state,
  (select act_ru_task.id_
    from wf.act_ru_task
    where booking_item.workflow_instance_id = act_ru_task.proc_inst_id_
    and room_operator.operator_id = assignee_
    order by act_ru_task.create_time_
    limit 1
  ) as workflow_task_id,
  (select sum(booking_facility.subtotal)
    from tm_huis.booking_facility
    where booking_facility.item_id = booking_item.id
  ) as subtotal
from tm_huis.booking_form
join tm_huis.booking_item on booking_form.id = booking_item.form_id
join tm_huis.room on booking_item.room_id = room.id
join tm_huis.room_operator on room.id = room_operator.room_id
join ea.department on booking_form.department_id = department.id
join tm_huis.booking_type on booking_form.booking_type_id = booking_type.id
where booking_form.status = 'ACTIVE'
order by lower(booking_item.booking_time);

-- 数据视图-确认单查看视图
create or replace view tm_huis.dv_operation_form as
select booking_item.id as id,
  room.id as room_id,
  room.name as room_name,
  lower(booking_item.booking_time) as booking_lower_time,
  upper(booking_item.booking_time) as booking_upper_time,
  lower(booking_item.actual_time) as actual_lower_time,
  upper(booking_item.actual_time) as actual_upper_time,
  booking_item.time_unit,
  booking_item.time_unit_quantity,
  booking_item.over_time_quantity,
  system_user.id as operator_id,
  system_user.name as operator_name,
  booking_item.operator_note,
  booking_item.workflow_state as workflow_state,
  booking_item.workflow_instance_id as workflow_instance_id,
  booking_item.date_confirm,
  booking_item.date_created as date_created,
  booking_item.date_updated as date_updated,
  booking_item.status as status,
  booking_item.note,
  (select jsonb_build_object(
      'id', booking_form.id,
      'departmentName', department.name,
      'bookingTypeName', booking_type.name,
      'isInternal', booking_form.is_internal,
      'subject', booking_form.subject,
      'description', booking_form.description,
      'attendance', booking_form.attendance,
      'userName', form_user.name,
      'userPhoneNumber', form_user.long_phone,
      'contact', booking_form.contact,
      'contactNumber', booking_form.contact_number,
      'workflowState', booking_form.workflow_state,
      'workflowInstanceId', booking_form.workflow_instance_id,
      'status', booking_form.status,
      'dateCreated', booking_form.date_created,
      'dateUpdated', booking_form.date_updated
    )
    from tm_huis.booking_form
    join ea.department on booking_form.department_id = department.id
    join tm_huis.booking_type on booking_form.booking_type_id = booking_type.id
    join tm.system_user form_user on booking_form.user_id = form_user.id
    where booking_form.id = booking_item.form_id
  ) as form,  
  (select jsonb_agg(jsonb_build_object(
      'id', booking_facility.id,
      'facilityId', facility.id,
      'facilityName', facility.name,
      'unitPrice', booking_facility.unit_price,
      'unitName', booking_facility.unit_name,
      'timeUnit', booking_facility.time_unit,
      'quantity', booking_facility.quantity,
      'discount', booking_facility.discount,
      'subtotal', booking_facility.subtotal,
      'isAdditional', booking_facility.is_additional,
      'statementFormId', booking_facility.statement_form_id,
      'dateCreated', booking_facility.date_created,
      'dateUpdated', booking_facility.date_updated,
      'status', booking_facility.status,
      'note', booking_facility.note
    ) order by booking_facility.id)
    from tm_huis.booking_facility
    join tm_huis.facility on booking_facility.facility_id = facility.id
    where booking_facility.item_id = booking_item.id
  ) as facilities,
  wf.fn_find_workflow_tasks(booking_item.workflow_instance_id) as workflow_tasks
from tm_huis.booking_item
join tm_huis.booking_form on booking_item.form_id = booking_form.id
join tm_huis.room on booking_item.room_id = room.id
left join system_user on booking_item.operator_id = system_user.id;

-- 数据视图-超期结算视图
create or replace view tm_huis.dv_statement_delay as
with delay_config as (
  select (value || 'd') :: interval as value from tm.system_config where key ='huis.statement.delay'
)
select booking_facility.id as id,
  form_user.id as user_id,
  form_user.name as user_name,
  booking_form.id as booking_form_id,
  booking_item.id as booking_item_id,
  booking_form.subject as subject,
  room.name as room,
  lower(booking_item.booking_time) as booking_lower_time,
  upper(booking_item.booking_time) as booking_upper_time,
  facility.name as facility,
  booking_facility.subtotal as subtotal,
  booking_item.date_confirm,
  booking_item.workflow_instance_id as item_workflow_instance_id,
  booking_item.workflow_state as item_workflow_state,
  statement_form.id as statement_form_id,
  statement_form.workflow_instance_id as statement_workflow_instance_id,
  statement_form.workflow_state as statement_workflow_state,
  now() - booking_item.date_confirm - (select value from delay_config) as statement_delay
from tm_huis.booking_form
join tm_huis.booking_item on booking_item.form_id = booking_form.id
join tm_huis.booking_facility on booking_facility.item_id = booking_item.id
join tm_huis.room on booking_item.room_id = room.id
join tm_huis.facility on booking_facility.facility_id = facility.id
join tm.system_user form_user on booking_form.user_id = form_user.id
left join tm_huis.statement_form on booking_facility.statement_form_id = statement_form.id
where (statement_form.id is null or statement_form.status <> 'ACTIVE')
and now() - booking_item.date_confirm > (select value from delay_config)
and not( booking_form.is_internal and room.is_internal_free)
and booking_form.status = 'ACTIVE'
and booking_item.status = 'ACTIVE'
and booking_facility.status = 'ACTIVE';

-- 数据视图-结算单列表视图
create or replace view tm_huis.dv_statement_list as
select statement_form.id as id,
  department.name as department,
  statement_form.description,
  statement_form.user_id,
  statement_form.date_updated,
  statement_form.workflow_state,
  (select act_ru_task.id_
    from wf.act_ru_task
    where statement_form.workflow_instance_id = act_ru_task.proc_inst_id_
    and statement_form.user_id = assignee_
    order by act_ru_task.create_time_
    limit 1
  ) as workflow_task_id
from tm_huis.statement_form
join ea.department on statement_form.department_id = department.id
order by date_updated desc;

-- 数据视图-结算单视图
create or replace view tm_huis.dv_statement_form as
select statement_form.id,
  department.id as department_id,
  department.name as department_name,
  system_user.id as user_id,
  system_user.name as user_name,
  system_user.long_phone as user_phone_number,
  statement_form.total,
  statement_form.description,
  statement_form.workflow_state,
  statement_form.workflow_instance_id,
  statement_form.date_created,
  statement_form.date_updated,
  statement_form.status,
  (select jsonb_agg(jsonb_build_object(
      'id', booking_facility.id,
      'facilityId', facility.id,
      'facilityName', facility.name,
      'unitPrice', booking_facility.unit_price,
      'unitName', booking_facility.unit_name,
      'timeUnit', booking_facility.time_unit,
      'quantity', booking_facility.quantity,
      'discount', booking_facility.discount,
      'subtotal', booking_facility.subtotal,
      'isAdditional', booking_facility.is_additional,
      'dateCreated', booking_facility.date_created,
      'dateUpdated', booking_facility.date_updated,
      'status', booking_facility.status,
      'note', booking_facility.note,
      'statementFormId', booking_facility.statement_form_id,
      'item', (select jsonb_build_object(
          'id', booking_item.id,
          'roomId', room.id,
          'roomName', room.name,
          'bookingLowerTime', lower(booking_item.booking_time),
          'bookingUpperTime', upper(booking_item.booking_time),
          'actualLowerTime', lower(booking_item.actual_time),
          'actualUpperTime', upper(booking_item.actual_time),
          'timeUnit', booking_item.time_unit,
          'timeUnitQuantity', booking_item.time_unit_quantity,
          'overTimeQuantity', booking_item.over_time_quantity,
          'operatorId', system_user.id,
          'operatorName', system_user.name,
          'operatorNote', booking_item.operator_note,
          'workflowState', booking_item.workflow_state,
          'workflowInstanceId', booking_item.workflow_instance_id,
          'status', booking_item.status,
          'note', booking_item.note,
          'dateCreated', booking_item.date_created,
          'dateUpdated', booking_item.date_updated,
          'dateConfirm', booking_item.date_confirm,
          'form', (select jsonb_build_object(
              'id', booking_form.id,
              'departmentName', department.name,
              'bookingTypeName', booking_type.name,
              'isInternal', booking_form.is_internal,
              'subject', booking_form.subject,
              'description', booking_form.description,
              'attendance', booking_form.attendance,
              'userName', system_user.name,
              'userPhoneNumber', system_user.long_phone,
              'contact', booking_form.contact,
              'contactNumber', booking_form.contact_number,
              'workflowState', booking_form.workflow_state,
              'workflowInstanceId', booking_form.workflow_instance_id,
              'status', booking_form.status,
              'dateCreated', booking_form.date_created,
              'dateUpdated', booking_form.date_updated
            )
            from tm_huis.booking_form
            join ea.department on booking_form.department_id = department.id
            join tm_huis.booking_type on booking_form.booking_type_id = booking_type.id
            join tm.system_user on booking_form.user_id = system_user.id
            where booking_form.id = booking_item.form_id
          )
        )
        from tm_huis.booking_item
        join tm_huis.room on booking_item.room_id = room.id
        left join tm.system_user on booking_item.operator_id = system_user.id
        where booking_item.id = booking_facility.item_id)
      )
    )
    from tm_huis.booking_facility
    join tm_huis.facility on booking_facility.facility_id = facility.id
    where booking_facility.statement_form_id = statement_form.id
  ) as items,
  wf.fn_find_workflow_tasks(statement_form.workflow_instance_id) as workflow_tasks
from tm_huis.statement_form
join ea.department on statement_form.department_id = department.id
join tm.system_user on statement_form.user_id = system_user.id;

-- 数据视图-结算项目视图
create or replace view tm_huis.dv_statement_item as
select booking_item.id,
  room.id as room_id,
  room.name as room_name,
  lower(booking_item.booking_time) as booking_lower_time,
  upper(booking_item.booking_time) as booking_upper_time,
  lower(booking_item.actual_time) as actual_lower_time,
  upper(booking_item.actual_time) as actual_upper_time,
  booking_item.time_unit,
  booking_item.time_unit_quantity,
  booking_item.over_time_quantity,
  system_user.id as operator_id,
  system_user.name as operator_name,
  booking_item.operator_note,
  booking_item.workflow_state,
  booking_item.workflow_instance_id,
  booking_item.status,
  booking_item.date_created,
  booking_item.date_updated,
  booking_item.date_confirm,
  booking_item.note,
  booking_auth.user_id,
  (select jsonb_build_object(
      'id',  booking_form.id,
      'departmentName', department.name,
      'bookingTypeName', booking_type.name,
      'isInternal', booking_form.is_internal,
      'subject', booking_form.subject,
      'description', booking_form.description,
      'attendance', booking_form.attendance,
      'userName', form_user.name,
      'userPhoneNumber', form_user.long_phone,
      'contact', booking_form.contact,
      'contactNumber', booking_form.contact_number,
      'workflowState', booking_form.workflow_state,
      'workflowInstanceId', booking_form.workflow_instance_id,
      'status', booking_form.status,
      'dateCreated', booking_form.date_created,
      'dateUpdated', booking_form.date_updated
    )
    from tm_huis.booking_form
    join ea.department on booking_form.department_id = department.id
    join tm_huis.booking_type on booking_form.booking_type_id = booking_type.id
    join tm.system_user form_user on booking_form.user_id = form_user.id
    where booking_item.form_id = booking_form.id
  ) as form,
  (select jsonb_agg(jsonb_build_object(
      'id', booking_facility.id,
      'facilityId', facility.id,
      'facilityName', facility.name,
      'unitPrice', booking_facility.unit_price,
      'unitName', booking_facility.unit_name,
      'timeUnit', booking_facility.time_unit,
      'quantity', booking_facility.quantity,
      'discount', booking_facility.discount,
      'subtotal', booking_facility.subtotal,
      'isAdditional', booking_facility.is_additional,
      'dateCreated', booking_facility.date_created,
      'dateUpdated', booking_facility.date_updated,
      'status', booking_facility.status,
      'note', booking_facility.note
    ) order by booking_facility.id)
    from tm_huis.booking_facility
    join tm_huis.facility on booking_facility.facility_id = facility.id
    where booking_facility.item_id = booking_item.id
    and booking_facility.statement_form_id is null
    and booking_facility.status = 'ACTIVE'
    and booking_facility.subtotal > 0
  ) as facilities
from tm_huis.booking_item
join tm_huis.booking_form on booking_form.id = booking_item.form_id
join tm_huis.room on booking_item.room_id = room.id
join tm.system_user on booking_item.operator_id = system_user.id
join tm_huis.booking_auth on booking_auth.department_id = booking_form.department_id
where booking_item.status = 'ACTIVE'
and booking_auth.booking_type_id = 104
and booking_item.workflow_state = 'CONFIRMED'
and exists (
  select 1
  from tm_huis.booking_facility
  where booking_facility.item_id = booking_item.id
  and booking_facility.statement_form_id is null
  and booking_facility.status = 'ACTIVE'
  and booking_facility.subtotal > 0
) order by date_confirm;

-- 数据视图-会议室借用工作流任务
create or replace view tm_huis.dv_booking_task as
select task.id_ as id, task.name_ as name,
  form.id as form_id,
  form.subject,
  task.task_def_key_ as task_key,
  task.form_key_ as form_key,
  task.assignee_ as assignee,
  task.create_time_ as create_time
from tm_huis.booking_form form
join wf.act_ru_task task on form.workflow_instance_id = task.proc_inst_id_
order by task.create_time_;

-- 数据视图-会议室借用工作流历史
create or replace view tm_huis.dv_booking_step as
with step as (
  select distinct on (task.assignee_, form.id) task.id_ as id, task.name_ as name,
    form.id as form_id,
    form.subject,
    task.task_def_key_ as task_key,
    task.form_key_ as form_key,
    task.assignee_ as assignee,
    task.start_time_ as start_time,
    task.end_time_ as end_time
  from tm_huis.booking_form form
  join wf.act_hi_taskinst task on form.workflow_instance_id = task.proc_inst_id_
  where task.end_time_ is not null
  order by task.assignee_, form.id, task.end_time_ desc
)
select id, name, form_id, subject, task_key, form_key, assignee, start_time, end_time
from step
order by end_time desc;

-- 数据视图-使用确认工作流任务
create or replace view tm_huis.dv_operation_task as
select task.id_ as id, task.name_ as name,
  item.id as form_id,
  form.subject || '[' || room.name || '/' || substr(lower(item.booking_time)::text, 6, 11) || ']' as subject,
  task.task_def_key_ as task_key,
  task.form_key_ as form_key,
  task.assignee_ as assignee,
  task.create_time_ as create_time
from tm_huis.booking_form form
join tm_huis.booking_item item on form.id = item.form_id
join tm_huis.room on item.room_id = room.id
join wf.act_ru_task task on item.workflow_instance_id = task.proc_inst_id_
order by task.create_time_;

-- 数据视图-使用确认工作流历史
create or replace view tm_huis.dv_operation_step as
with step as (
  select distinct on (task.assignee_, item.id) task.id_ as id, task.name_ as name,
    item.id as form_id,
    form.subject || '[' || room.name || '/' || substr(lower(item.booking_time)::text, 6, 11) || ']' as subject,
    task.task_def_key_ as task_key,
    task.form_key_ as form_key,
    task.assignee_ as assignee,
    task.start_time_ as start_time,
    task.end_time_ as end_time
  from tm_huis.booking_form form
  join tm_huis.booking_item item on form.id = item.form_id
  join tm_huis.room on item.room_id = room.id
  join wf.act_hi_taskinst task on item.workflow_instance_id = task.proc_inst_id_
  where task.end_time_ is not null
  order by task.assignee_, item.id, task.end_time_ desc
)
select id, name, form_id, subject, task_key, form_key, assignee, start_time, end_time
from step
order by end_time desc;

-- 数据视图-借用结算工作流任务
create or replace view tm_huis.dv_statement_task as
select task.id_ as id, task.name_ as name,
  case when length(form.description) > 32 then left(form.description, 31) || '…' else form.description end as subject,
  form.id as form_id,
  task.task_def_key_ as task_key,
  task.form_key_ as form_key,
  task.assignee_ as assignee,
  task.create_time_ as create_time
from tm_huis.statement_form form
join wf.act_ru_task task on form.workflow_instance_id = task.proc_inst_id_;

-- 数据视图-借用结算工作流历史
create or replace view tm_huis.dv_statement_step as
with step as (
  select distinct on (task.assignee_, form.id) task.id_ as id, task.name_ as name,
    form.id as form_id,
    case when length(form.description) > 32 then left(form.description, 31) || '…' else form.description end as subject,
    task.task_def_key_ as task_key,
    task.form_key_ as form_key,
    task.assignee_ as assignee,
    task.start_time_ as start_time,
    task.end_time_ as end_time
  from tm_huis.statement_form form
  join ea.department on form.department_id = department.id
  join wf.act_hi_taskinst task on form.workflow_instance_id = task.proc_inst_id_
  where task.end_time_ is not null
  order by task.assignee_, form.id, task.end_time_ desc
)
select id, name, form_id, subject, task_key, form_key, assignee, start_time, end_time
from step
order by end_time desc;

-- 数据视图-会议室设置视图
create or replace view tm_huis.dv_room_setting as
select room.id,
  room.name,
  department.id as department_id,
  department.name as department_name,
  room.furniture,
  room.seat,
  room.max_seat,
  room.area,
  room.unit_price,
  room.time_unit,
  room.is_internal_free,
  room.is_public,
  (select jsonb_agg(jsonb_build_object(
        'id', facility.id,
        'name', facility.name,
        'unitPrice', facility.unit_price,
        'unitName', facility.unit_name,
        'timeUnit', facility.time_unit,
        'quantity', room_facility.quantity,
        'isBasic', room_facility.is_basic
      ) order by facility.id)
    from tm_huis.room_facility
    join tm_huis.facility on room_facility.facility_id = facility.id
    where room_facility.room_id = room.id
  ) as facilities,
  (select jsonb_agg(jsonb_build_object(
        'id', room_reservation.id,
        'lowerDate', lower_date,
        'upperDate', upper_date,
        'dateInterval', date_interval,
        'lowerTime', lower_time,
        'upperTime', upper_time,
        'note', note
      ) order by room_reservation.id)
    from tm_huis.room_reservation
    where room_reservation.room_id = room.id
  ) as reservations
from tm_huis.room
join ea.department on room.department_id = department.id
order by room.name;
