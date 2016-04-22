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