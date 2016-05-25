-- 菜单
create or replace view tm.v_menu as
with recursive r as (
    select m.id, m.name, m.label_cn, m.label_en,
        m.id as root,
        1 as path_level,
        to_char(m.display_order, '09') as display_order
    from tm.menu m
    where array_length(regexp_split_to_array(m.id, E'\\.'), 1) = 1
    union all
    select m.id, m.name, m.label_cn, m.label_en,
        r.root as root,
        array_length(regexp_split_to_array(m.id, E'\\.'), 1),
        r.display_order || to_char(m.display_order, '09')
    from tm.menu m
    join r on strpos(m.id, r.id) = 1 and array_length(regexp_split_to_array(m.id, E'\\.'), 1) = r.path_level + 1
)
select id, name, label_cn, label_en, path_level -1 as menu_level, root from r
where path_level > 1
order by display_order;

-- Helper View
-- 教学任务
create or replace view v_task as
select task.id, cc.term_id, c.id as course_id, c.name as course_name,
    array_agg(t.name) as teacher_name,
    count(t.id) as teacher_count,
    task.original_id
from task
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join task_teacher tt on tt.task_id = task.id
join teacher t on t.id = tt.teacher_id
group by term_id, task.id, c.id, c.name, task.original_id;

-- 教学安排
create or replace view v_task_schedule as
select a.id, cc.term_id, c.id as course_id, c.name as course_name,
    te.id as teacher_id, te.name as teacher_name, a.start_week, a.end_week,
    day_of_week, start_section, total_section, odd_even, place_id, task_id, course_class_id
from task_schedule a
join task on a.task_id = task.id
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join teacher te on te.id = a.teacher_id;
