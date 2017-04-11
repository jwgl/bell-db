-- both bell/ea and bell/tm

create or replace view dv_sync_basic_table as
select table_schema || '.' || table_name as id
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema', 'sync')
and table_type = 'BASE TABLE';

create or replace view dv_sync_basic_column as
select t.table_schema || '.' || t.table_name as table_id,
       c.column_name as name,
       c.ordinal_position as ordinal,
       case when kcu.column_name is not null then true else false end as primary_key
from information_schema.tables t
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

create or replace view dv_sync_foreign_table as
select t.foreign_table_schema || '.' || t.foreign_table_name as id
from information_schema.foreign_tables t
where t.foreign_table_schema not in ('pg_catalog', 'information_schema', 'sync');

create or replace view dv_sync_foreign_column as
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

create or replace view dv_sync_dependency as
select ccu.table_schema || '.' || ccu.table_name as parent_id,
       tc.table_schema || '.' || tc.table_name as child_id
from information_schema.table_constraints as tc 
join information_schema.key_column_usage as kcu
  on tc.constraint_name = kcu.constraint_name
join information_schema.constraint_column_usage as ccu
  on ccu.constraint_name = tc.constraint_name
where constraint_type = 'FOREIGN KEY';