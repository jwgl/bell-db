create index rollcall_student_idx on rollcall(student_id);
create index rollcall_task_schedule_idx on rollcall(task_schedule_id);
create index student_leave_item_task_schedule_idx on student_leave_item(task_schedule_id);
create index student_leave_item_form_idx on student_leave_item(form_id);
create index free_listen_item_task_schedule_idx on free_listen_item(task_schedule_id);
create index free_listen_item_form_idx on free_listen_item(form_id);