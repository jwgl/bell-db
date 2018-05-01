/**
 * 构建同步语句
 * @param i_table_id 基本表ID
 * @param i_term_id 学期ID
 * @param out o_upsert_sql Upsert语句
 * @param out o_delete_sql Delete语句
 */
create or replace function sync.fn_build_sync_sql(
  i_table_id text,
  i_term_id integer,
  out o_upsert_sql text,
  out o_delete_sql text
) as $$
declare
  v_config record;
  v_foreign_table text;
  v_column_names text; 
  v_key_names text;
  v_update_column_names text;
  v_update_condition text;
  v_upsert_condition text;
  v_delete_condition text;
  v_doing text;
  v_select_sql text;
begin
  select * into v_config from sync.sync_config where id = i_table_id;
  if not found then
    raise exception 'Sync table % does not exist.', i_table_id;
  end if;

  v_foreign_table := v_config.basic_schema || '.' || v_config.foreign_table;
  
  select string_agg(a.name, ', '),
    string_agg(case when a.primary_key then a.name else null end, ', '),
    string_agg(case when not a.primary_key then format('%1$s = EXCLUDED.%1$s', a.name) else null end, E',\n'),
    string_agg(case when not a.primary_key then format('%1$s.%2$s <> EXCLUDED.%2$s', v_config.basic_table, a.name) else null end, E' or\n')
  into v_column_names, v_key_names, v_update_column_names, v_update_condition
  from sync.dv_basic_table_column a
  join sync.dv_foreign_table_column b on a.name = b.name
  where a.table_id = i_table_id
  and b.table_id = v_foreign_table;
  
  if v_config.upsert_condition is not null then
    v_upsert_condition := 'where ' || replace(v_config.upsert_condition, '${term_id}', i_term_id::text);
  end if;
  
  -- select sql
  if v_config.select_sql is not null then
    v_select_sql := v_config.select_sql;
    if v_upsert_condition is not null then
      if strpos(v_select_sql, '${where}') > 0 then
        v_select_sql := replace(v_select_sql, '${where}', v_upsert_condition);
      else
        v_select_sql := v_select_sql || E'\n' || v_upsert_condition;
      end if;
    end if;
  else
    v_select_sql := format(E'select %s\nfrom %s', v_column_names, v_foreign_table);
    if v_upsert_condition is not null then
      v_select_sql := v_select_sql || E'\n' || v_upsert_condition;
    end if;
  end if;
  
  if v_config.unique_index is not null then
    v_key_names := v_config.unique_index;
  end if;
  
  if v_update_column_names is not null then
    v_doing := format(E'update set\n%s\nwhere %s', v_update_column_names, v_update_condition);
  else
    v_doing := 'nothing';
  end if;

  -- upsert sql
  o_upsert_sql = format($i$insert into %s(%s)
%s
on conflict(%s) do %s;$i$, v_config.id, v_column_names, v_select_sql,
            coalesce(v_config.unique_index, v_key_names), v_doing);
  
  if v_config.delete_condition is not null then
    v_delete_condition := ' and ' || replace(v_config.delete_condition, '${term_id}', i_term_id::text);
  end if;
  
  -- delete sql
  o_delete_sql = format($d$delete from %s
where (%s) not in (
  select %2$s
  from %s %s
) %s;$d$, v_config.id, v_key_names, v_foreign_table, v_upsert_condition, v_delete_condition);  
end;
$$ language plpgsql;

/**
 * 更新同步上下文
 * @param i_table_id 基本表ID，如果为空则全部更新
 * @param i_term_id 学期ID，如果为空则取当前学期
 */
create or replace function sync.fn_update_sync_context(
  i_table_id text,
  i_term_id integer
) returns void as $$
begin
  if i_term_id is null then
    select id into i_term_id from ea.term where active = true;
  end if;
  
  -- insert or update ordinal
  insert into sync.sync_context (id, ordinal, date_created)
  select id, ordinal, clock_timestamp()
  from sync.dv_basic_table
  where id like coalesce(i_table_id, '%')
  on conflict(id) do update set
  ordinal = excluded.ordinal,
  date_modified = clock_timestamp()
  where sync_context.ordinal <> EXCLUDED.ordinal;
  
  -- update schema_owner
  with owner_info as (
    select id, schema_owner
    from sync.sync_config a
    join information_schema.schemata b on a.basic_schema = b.schema_name
    where id like coalesce(i_table_id, '%')
  )
  update sync.sync_context set
  schema_owner = owner_info.schema_owner
  from owner_info
  where sync_context.id = owner_info.id
  and coalesce(sync_context.schema_owner, '') <> coalesce(owner_info.schema_owner, '');
  
  -- update upsert_sql and delete_sql
  with sync_sql as (
    select id, (sync.fn_build_sync_sql(id, i_term_id)).*,
      replace(before_sync, '${term_id}', i_term_id::text) as before_sync,
      replace(after_sync, '${term_id}', i_term_id::text) as after_sync
    from sync.sync_config
    where id like coalesce(i_table_id, '%')
  )
  update sync.sync_context set
  before_sync = sync_sql.before_sync,
  upsert_sql = sync_sql.o_upsert_sql,
  delete_sql = sync_sql.o_delete_sql,
  after_sync = sync_sql.after_sync,
  date_modified = clock_timestamp()
  from sync_sql
  where sync_context.id = sync_sql.id 
    and (coalesce(sync_context.before_sync, '') <> coalesce(sync_sql.before_sync, '')
     or coalesce(sync_context.upsert_sql, '') <> coalesce(sync_sql.o_upsert_sql, '')
     or coalesce(sync_context.delete_sql, '') <> coalesce(sync_sql.o_delete_sql, '')
     or coalesce(sync_context.after_sync, '') <> coalesce(sync_sql.after_sync, ''));
  
  -- update ancestors
  with depenency as (
    select a.descendant_id, array_agg(a.ancestor_id order by b.ordinal) as ancestors
    from sync.dv_transitive_dependency a
    join sync.sync_context b on a.ancestor_id = b.id
    where a.descendant_id like coalesce(i_table_id, '%')
    group by a.descendant_id
  )
  update sync.sync_context set
  ancestors = depenency.ancestors,
  date_modified = clock_timestamp()
  from depenency
  where sync_context.id = depenency.descendant_id 
    and coalesce(sync_context.ancestors, '{}'::text[]) <> coalesce(depenency.ancestors, '{}'::text[]);

  -- update descendants
  with depenency as (
    select a.ancestor_id, array_agg(a.descendant_id order by b.ordinal desc) as descendants
    from sync.dv_transitive_dependency a
    join sync.sync_context b on a.descendant_id = b.id
    where a.ancestor_id like coalesce(i_table_id, '%')
    group by a.ancestor_id
  )
  update sync.sync_context set
  descendants = depenency.descendants,
  date_modified = clock_timestamp()
  from depenency
  where sync_context.id = depenency.ancestor_id 
    and coalesce(sync_context.descendants, '{}'::text[]) <> coalesce(depenency.descendants, '{}'::text[]);
end;
$$ language plpgsql;

/**
 * 执行同步
 * @param i_table_id 基本表ID，如果为空则全部更新
 */
create or replace function sync.fn_execute_sync(i_table_id text)
returns void as $$
declare
  v_result text;
  v_row_count integer;
  v_log_id integer;
  v_execute_result text = 'ok';
  v_ancestors text[];
  v_descendants text[];
  v_sync_id text;
  v_context sync.sync_context%rowtype;
  v_message_text text;
  v_exception_detail text;
  v_loop_start timestamp;
  v_loop_time numeric;
begin
  insert into sync.sync_log(start_time) values(clock_timestamp())
  returning id into v_log_id;

  if i_table_id is null then
    select array_agg(a.id order by a.ordinal) into v_ancestors
    from sync.sync_context a;
    v_descendants = array(select v_ancestors[i] from generate_subscripts(v_ancestors, 1) as s(i) order by i desc);
  else
    select array_agg(a.id order by a.ordinal) into v_ancestors
    from sync.sync_context a
    join sync.sync_context b on a.id = any(b.ancestors)
    where b.id = i_table_id;
    v_ancestors = array_append(v_ancestors, i_table_id);
    v_descendants = array(select v_ancestors[i] from generate_subscripts(v_ancestors, 1) as s(i) order by i desc);
    -- v_descendants = array_cat((select descendants from sync.sync_context where id = i_table_id), v_descendants);
  end if;

  -- upsert
  foreach v_sync_id in array v_ancestors loop
    raise notice 'Upserting % ...', v_sync_id;
    begin
      v_loop_start = clock_timestamp();
      select * into v_context
      from sync.sync_context
      where id = v_sync_id;
      execute 'set local session authorization ' || v_context.schema_owner;
      if v_context.before_sync is not null then
        execute v_context.before_sync;
      end if;
      execute v_context.upsert_sql;
      get diagnostics v_row_count = row_count;
      v_loop_time = trunc(extract(epoch from clock_timestamp() - v_loop_start)::numeric, 3);
      raise notice 'Insert or update % row(s) in % seconds.', v_ROW_COUNT, v_loop_time;
      reset session authorization;
    exception
      when others then
        get stacked diagnostics v_message_text = message_text,
                                v_exception_detail = pg_exception_detail;
        v_execute_result = format(E'%s\n%s', v_message_text, v_exception_detail);
        raise notice '%', v_execute_result;
        reset session authorization;
        exit;
    end;
  end loop;
  
  -- delete
  foreach v_sync_id in array v_descendants loop
    raise notice 'Deleting % ...', v_sync_id;
    begin
      v_loop_start = clock_timestamp();
      select * into v_context
      from sync.sync_context
      where id = v_sync_id;
      execute 'set local session authorization ' || v_context.schema_owner;
      execute v_context.delete_sql;
      get diagnostics v_row_count = row_count;
      v_loop_time = trunc(extract(epoch from clock_timestamp() - v_loop_start)::numeric, 3);
      raise notice 'Delete % row(s) in % seconds.', v_ROW_COUNT, v_loop_time;
      if v_context.after_sync is not null then
        execute v_context.after_sync;
      end if;
      reset session authorization;
    exception
      when others then
        get stacked diagnostics v_message_text = message_text,
                                v_exception_detail = pg_exception_detail;
        v_execute_result = format(E'%s\n%s', v_message_text, v_exception_detail);
        raise notice '%', v_execute_result;
        reset session authorization;
        exit;
    end;
  end loop;
  
  update sync.sync_log set
  end_time = clock_timestamp(),
  execute_result = v_execute_result
  where id = v_log_id;
end;
$$ language plpgsql;
