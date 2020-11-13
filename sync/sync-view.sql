-- bell/sync
/**
 * 基本表直接依赖
 */
create or replace view sync.dv_direct_dependency as
with foreign_constraints as (
  select c.conname as constraint_name,
    nr.nspname as table_schema,
    r.relname as table_name,
    c.contype as constraint_type
  from pg_namespace nr
  join pg_class r on nr.oid = r.relnamespace
  join pg_constraint c on c.conrelid = r.oid
  where c.contype = 'f'
), constraint_column_usage as (
  SELECT nr.nspname AS table_schema,
    r.relname AS table_name,
    c.conname AS constraint_name
  FROM pg_namespace nr
  join pg_class r on nr.oid = r.relnamespace
  join pg_attribute a on r.oid = a.attrelid
  join pg_constraint c on r.oid = c.confrelid and a.attnum = ANY (c.confkey)
  where c.contype = 'f'
)
select c1.id as parent_id, c2.id as child_id
from foreign_constraints as tc
join constraint_column_usage as ccu on ccu.constraint_name = tc.constraint_name
join sync.sync_config c1 on ccu.table_schema = c1.basic_schema and ccu.table_name = c1.basic_table
left join sync.sync_config c2 on tc.table_schema = c2.basic_schema and tc.table_name = c2.basic_table
where c1.id <> c2.id;

/**
 * 基本表间接依赖
 */
create or replace view sync.dv_transitive_dependency as
with recursive traverse(id, dependencies) as (
  select distinct a.parent_id, '{}'::text[] as dependencies
  from sync.dv_direct_dependency a
  left join sync.dv_direct_dependency b on a.parent_id = b.child_id
  where b.child_id is null
  union all
  select distinct b.child_id, a.dependencies || b.parent_id
  from traverse a
  join sync.dv_direct_dependency b on a.id = b.parent_id
)
select distinct id as descendant_id, unnest(dependencies) as ancestor_id
from traverse
order by id;

/**
 * 基本表
 */
create or replace view sync.dv_basic_table as
with recursive traverse(id, path, cycle) as (
  select distinct a.child_id, array[a.child_id], false
  from sync.dv_direct_dependency a
  left join sync.dv_direct_dependency b on a.child_id = b.parent_id
  where b.parent_id is null
  union all
  select distinct b.parent_id, a.path || b.parent_id, b.parent_id = any(a.path)
  from traverse a
  join sync.dv_direct_dependency b on a.id = b.child_id
  where not cycle
)
select a.id, row_number() over(order by max(array_length(a.path, 1)) desc) ordinal
from traverse a
left join traverse b on b.cycle = true
where b.cycle is null
group by a.id
union all
select id, 0
from sync.sync_config
where id not in (select id from traverse)
and (basic_table, basic_table) in (
  select table_schema, table_name from information_schema.tables
)
order by 2;

/**
 * 基本表列属性
 */
create or replace view sync.dv_basic_table_column as
select t.table_schema || '.' || t.table_name as table_id,
       c.column_name as name,
       c.ordinal_position as ordinal,
       case when kcu.column_name is not null then true else false end as primary_key
from information_schema.tables t
join sync.sync_config on t.table_schema || '.' || t.table_name = sync_config.id
join information_schema.columns c
     on c.table_catalog = t.table_catalog
     and c.table_schema = t.table_schema
     and c.table_name = t.table_name
left join information_schema.table_constraints tc
     on tc.table_catalog = t.table_catalog
     and tc.table_schema = t.table_schema
     and tc.table_name = t.table_name
     and tc.constraint_type = 'PRIMARY KEY'
left join information_schema.key_column_usage kcu
     on kcu.table_catalog = tc.table_catalog
     and kcu.table_schema = tc.table_schema
     and kcu.table_name = tc.table_name
     and kcu.constraint_name = tc.constraint_name
     and kcu.column_name = c.column_name
where t.table_schema not in ('pg_catalog', 'information_schema', 'sync')
and t.table_type = 'BASE TABLE'
order by c.ordinal_position;

/**
 * 外部表列属性
 */
create or replace view sync.dv_foreign_table_column as
select t.foreign_table_schema || '.' || t.foreign_table_name as table_id,
       c.column_name as name,
       c.ordinal_position as ordinal,
       case when kcu.column_name is not null then true else false end as primary_key
from information_schema.foreign_tables t
join information_schema.columns c
     on c.table_catalog = t.foreign_table_catalog
     and c.table_schema = t.foreign_table_schema
     and c.table_name = t.foreign_table_name
left join information_schema.table_constraints tc
     on tc.table_catalog = t.foreign_table_catalog
     and tc.table_schema = t.foreign_table_schema
     and tc.table_name = t.foreign_table_name
     and tc.constraint_type = 'PRIMARY KEY'
left join information_schema.key_column_usage kcu
     on kcu.table_catalog = tc.table_catalog
     and kcu.table_schema = tc.table_schema
     and kcu.table_name = tc.table_name
     and kcu.constraint_name = tc.constraint_name
     and kcu.column_name = c.column_name
where t.foreign_table_schema not in ('pg_catalog', 'information_schema', 'sync')
order by c.ordinal_position;