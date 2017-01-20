-- 菜单
create or replace view ea.dv_menu as
with recursive r as (
    select m.id, m.name, m.label_cn, m.label_en,
        m.id as root,
        1 as path_level,
        to_char(m.display_order, '09') as display_order
    from ea.menu m
    where array_length(regexp_split_to_array(m.id, E'\\.'), 1) = 1
    union all
    select m.id, m.name, m.label_cn, m.label_en,
        r.root as root,
        array_length(regexp_split_to_array(m.id, E'\\.'), 1),
        r.display_order || to_char(m.display_order, '09')
    from ea.menu m
    join r on strpos(m.id, r.id) = 1 and array_length(regexp_split_to_array(m.id, E'\\.'), 1) = r.path_level + 1
)
select id, name, label_cn, label_en, path_level -1 as menu_level, root from r
where path_level > 1
order by display_order;

-- Auxiliary View

-- 教学任务
create or replace view ea.av_task as
select task.id, cc.term_id, c.id as course_id, c.name as course_name,
    ci.name as course_item,
    array_agg(t.name) as teacher_name,
    count(t.id) as teacher_count,
    task.code
from task
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join task_teacher tt on tt.task_id = task.id
join teacher t on t.id = tt.teacher_id
left join course_item ci on task.course_item_id = ci.id
group by term_id, task.id, c.id, c.name, ci.name, task.code;

-- 教学安排
create or replace view ea.av_task_schedule as
select a.id, cc.term_id, c.id as course_id, c.name as course_name, ci.name as course_item,
    te.id as teacher_id, te.name as teacher_name, a.start_week, a.end_week,
    day_of_week, start_section, total_section, odd_even, place_id, task_id, task.code as task_code, course_class_id
from task_schedule a
join task on a.task_id = task.id
join course_class cc on cc.id = task.course_class_id
join course c on c.id = cc.course_id
join teacher te on te.id = a.teacher_id
left join course_item ci on ci.id = task.course_item_id;
