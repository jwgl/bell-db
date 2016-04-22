-- 教学任务
insert into ea.task(id, is_primary, start_week, end_week, course_item_id, course_class_id, original_id)
select id, is_primary, start_week, end_week, course_item_id, course_class_id, original_id from ea.sv_task
on conflict(id) do update set
is_primary      = EXCLUDED.is_primary,
start_week      = EXCLUDED.start_week,
end_week        = EXCLUDED.end_week,
course_item_id  = EXCLUDED.course_item_id,
course_class_id = EXCLUDED.course_class_id,
original_id     = EXCLUDED.original_id;
