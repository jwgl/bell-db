-- 点名调整
with correct as (
  select rollcall.id
  from tm.rollcall join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
)
select distinct week, task_schedule.id as task_schedule_id, 
  upper(replace(task_schedule.id::text, '-', '')) as task_schedule,
  task_id,
  upper(replace(task_schedule.task_id::text, '-', '')) task, task.code
from tm.rollcall 
join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
where tm.rollcall.id not in (select id from correct)
order by task_id, task_schedule.id, week;

with correct as (
  select rollcall.id
  from tm.rollcall join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
)
select * from tm.rollcall 
where tm.rollcall.id not in (select id from correct);

-- 查找拆分后第3段进行修正
with correct as (
  select rollcall.id
  from tm.rollcall join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, rollcall.id, week,
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from tm.rollcall
    join ea.task_schedule t1 on rollcall.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where rollcall.id not in (select id from correct)
    and week between t2.start_week and t2.end_week
    and (case t2.odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
    and not int4range(t1.start_week, t1.end_week) && int4range(t2.start_week, t2.end_week)
    and t1.day_of_week = t2.day_of_week
    and t1.start_section = t2.start_section
)
update tm.rollcall
set task_schedule_id = related.id2
from related
where rollcall.id = related.id;

with correct as (
  select rollcall.id
  from rollcall join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, rollcall.id, week, t1.start_week,
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from rollcall
    join ea.task_schedule t1 on rollcall.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where rollcall.id not in (select id from correct) and task_schedule_id is not null
    and t1.id <> t2.id
    and t2.start_week = t2.end_week
    and t2.start_week <> week
    and (t1.day_of_week <> t2.day_of_week or t1.start_section <> t2.start_section)
    and t1.id = '42e43699-1a9a-4bee-e050-10ac88052dea'
)
 select * from related;


-- 查找拆分后的第2段进行修正
with correct as (
  select rollcall.id
  from rollcall join ea.task_schedule on rollcall.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, rollcall.id, week,
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from rollcall
    join ea.task_schedule t1 on rollcall.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where rollcall.id not in (select id from correct)
    and week between t2.start_week and t2.end_week
    and (case t2.odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
    and not int4range(t1.start_week, t1.end_week) && int4range(t2.start_week, t2.end_week)
)
update rollcall
set task_schedule_id = related.id2
from related
where rollcall.id = related.id;

-- 请假调整
with correct as (
  select student_leave_item.id
  from tm.student_leave_item join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
)
select distinct week, task_schedule.id as task_schedule_id, 
  upper(replace(task_schedule.id::text, '-', '')) as task_schedule,
  task_id,
  upper(replace(task_schedule.task_id::text, '-', '')) task, task.code
from tm.student_leave_item 
join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
where tm.student_leave_item.id not in (select id from correct)
order by task_id, task_schedule.id, week;

with correct as (
  select student_leave_item.id
  from tm.student_leave_item join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
)
select *
from tm.student_leave_item 
where tm.student_leave_item.id not in (select id from correct) and task_schedule_id is not null;

with correct as (
  select student_leave_item.id
  from student_leave_item join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, student_leave_item.id, week,
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from student_leave_item
    join ea.task_schedule t1 on student_leave_item.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where student_leave_item.id not in (select id from correct) and task_schedule_id is not null
    and week between t2.start_week and t2.end_week
    and (case t2.odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
    and not int4range(t1.start_week, t1.end_week) && int4range(t2.start_week, t2.end_week)
    and t1.day_of_week = t2.day_of_week
    and t1.start_section = t2.start_section
)
update student_leave_item
set task_schedule_id = related.id2
from related
where student_leave_item.id = related.id;

with correct as (
  select student_leave_item.id
  from student_leave_item join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, student_leave_item.id, week, t2.start_week
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from student_leave_item
    join ea.task_schedule t1 on student_leave_item.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where student_leave_item.id not in (select id from correct) and task_schedule_id is not null
    and week between t2.start_week and t2.end_week
    and (case t2.odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
    and not int4range(t1.start_week, t1.end_week) && int4range(t2.start_week, t2.end_week)
)
update student_leave_item
set task_schedule_id = related.id2, week = related.start_week
from related
where student_leave_item.id = related.id;

with correct as (
  select student_leave_item.id
  from student_leave_item join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, student_leave_item.id, week, t2.start_week,
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from student_leave_item
    join ea.task_schedule t1 on student_leave_item.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where student_leave_item.id not in (select id from correct) and task_schedule_id is not null
    and t1.id <> t2.id
    and t1.day_of_week <> t2.day_of_week
    and t1.start_section <> t2.start_section
)
update student_leave_item
set task_schedule_id = related.id2, week = related.start_week
from related
where student_leave_item.id = related.id;

with correct as (
  select student_leave_item.id
  from student_leave_item join ea.task_schedule on student_leave_item.task_schedule_id = task_schedule.id
  where week between start_week and end_week
  and (case odd_even when 0 then true when 1 then week % 2 = 1 when 2 then week % 2 = 0 end)
), related as (
    select t1.task_id, student_leave_item.id, week, t1.start_week,
      t1.id as id1, t1.start_week || '-' || t1.end_week || '-' || t1.odd_even, t1.day_of_week, t1.start_section, t1.total_section, t1.teacher_id, t1.place_id,
      t2.id as id2, t2.start_week || '-' || t2.end_week || '-' || t2.odd_even, t2.day_of_week, t2.start_section, t2.total_section, t2.teacher_id, t2.place_id
    from student_leave_item
    join ea.task_schedule t1 on student_leave_item.task_schedule_id = t1.id
    join ea.task_schedule t2 on t1.task_id = t2.task_id and coalesce(t1.root_id, t1.id) = t2.root_id
    where student_leave_item.id not in (select id from correct) and task_schedule_id is not null
    and t1.id <> t2.id
    and t2.start_week = t2.end_week
    and t2.start_week <> week
    and (t1.day_of_week <> t2.day_of_week or t1.start_section <> t2.start_section)
)
 select * from related;
--select id from related group by id having count(*) > 1;
update student_leave_item
set week = related.start_week
from related
where student_leave_item.id = related.id;

-- 点名调整
with correct as (
  select free_listen_item.id
  from tm.free_listen_item join ea.task_schedule on free_listen_item.task_schedule_id = task_schedule.id
)
select distinct task_schedule.id as task_schedule_id, 
  upper(replace(task_schedule.id::text, '-', '')) as task_schedule,
  task_id,
  upper(replace(task_schedule.task_id::text, '-', '')) task, task.code
from tm.free_listen_item 
join ea.task_schedule on free_listen_item.task_schedule_id = task_schedule.id
join ea.task on task_schedule.task_id = task.id
where tm.free_listen_item.id not in (select id from correct)
order by task_id, task_schedule.id;

with correct as (
  select free_listen_item.id
  from tm.free_listen_item join ea.task_schedule on free_listen_item.task_schedule_id = task_schedule.id
)
select * from tm.free_listen_item 
where tm.free_listen_item.id not in (select id from correct);

select *
from ea.task_schedule
where root_id in (
	select task_schedule_id from tm.free_listen_item
) or id in (
	select task_schedule_id from tm.free_listen_item
)
;

select *
from ea.task_schedule
where id in (
	select task_schedule_id from tm.free_listen_item
)
;

select *
from ea.task_schedule
where root_id in (
	select task_schedule_id from tm.free_listen_item
) and id in (
	select task_schedule_id from tm.free_listen_item
)
;