create user sync with password 'bell_sync_password';

create schema sync authorization sync;

create table sync.sync_config (
  id text primary key,
  basic_schema text,
  basic_table text,
  foreign_table text,
  unique_index text,
  select_sql text,
  before_sync text,
  upsert_condition text,
  delete_condition text,
  after_sync text
);

create table sync.sync_context (
  id text primary key,
  schema_owner text,
  before_sync text,
  upsert_sql text,
  delete_sql text,
  after_sync text,
  ancestors text[],
  descendants text[],
  ordinal integer,
  date_created timestamp,
  date_modified timestamp
);

create table sync.sync_log(
  id serial primary key,
  start_time timestamp,
  end_time timestamp,
  execute_result text
);

insert into sync.sync_config(id, basic_schema, basic_table, foreign_table) values
('ea.discipline',            'ea', 'discipline',            'sv_discipline'),
('ea.field_class',           'ea', 'field_class',           'sv_field_class'),
('ea.field',                 'ea', 'field',                 'sv_field'),
('ea.department',            'ea', 'department',            'sv_department'),
('ea.place',                 'ea', 'place',                 'sv_place'),
('ea.place_department',      'ea', 'place_department',      'sv_place_department'),
('ea.place_booking_term',    'ea', 'place_booking_term',    'sv_place_booking_term'),
('ea.field_allow_degree',    'ea', 'field_allow_degree',    'sv_field_allow_degree'),
('ea.subject',               'ea', 'subject',               'sv_subject'),
('ea.major',                 'ea', 'major',                 'sv_major'),
('ea.program',               'ea', 'program',               'sv_program'),
('ea.direction',             'ea', 'direction',             'sv_direction'),
('ea.property',              'ea', 'property',              'sv_property'),
('ea.program_property',      'ea', 'program_property',      'sv_program_property'),
('ea.course',                'ea', 'course',                'sv_course'),
('ea.course_item',           'ea', 'course_item',           'sv_course_item'),
('ea.program_course',        'ea', 'program_course',        'sv_program_course'),
('ea.teacher',               'ea', 'teacher',               'sv_teacher'),
('ea.admin_class',           'ea', 'admin_class',           'sv_admin_class'),
('ea.admission',             'ea', 'admission',             'sv_admission'),
('ea.student',               'ea', 'student',               'sv_student'),
('ea.student_level',         'ea', 'student_level',         'sv_student_level'),
('ea.admin_class_cadre',     'ea', 'admin_class_cadre',     'sv_admin_class_cadre'),
('ea.timeplate_course',      'ea', 'timeplate_course',      'sv_timeplate_course'),
('ea.timeplate',             'ea', 'timeplate',             'sv_timeplate'),
('ea.timeplate_slot',        'ea', 'timeplate_slot',        'sv_timeplate_slot'),
('ea.timeplate_admin_class', 'ea', 'timeplate_admin_class', 'sv_timeplate_admin_class'),
('ea.timeplate_task',        'ea', 'timeplate_task',        'sv_timeplate_task'),
('ea.course_class',          'ea', 'course_class',          'sv_course_class'),
('ea.course_class_condition','ea', 'course_class_condition','sv_course_class_condition'),
('ea.course_class_program',  'ea', 'course_class_program',  'sv_course_class_program'),
('ea.task',                  'ea', 'task',                  'sv_task'),
('ea.task_teacher',          'ea', 'task_teacher',          'sv_task_teacher'),
('ea.task_schedule',         'ea', 'task_schedule',         'sv_task_schedule'),
('ea.task_student',          'ea', 'task_student',          'sv_task_student'),
('tm.system_user',           'tm', 'system_user',           'sv_system_user'),
('tm.place_user_type',       'tm', 'place_user_type',       'sv_place_user_type')
on conflict(id) do update set
basic_schema  = excluded.basic_schema,
basic_table   = excluded.basic_table,
foreign_table = excluded.foreign_table;

update sync.sync_config
set delete_condition = $$id > 2015000000$$
where id = 'ea.direction';

update sync.sync_config
set unique_index = 'program_id, coalesce(direction_id, 0), course_id'
where id = 'ea.program_course';

update sync.sync_config
set unique_index = 'timeplate_id, odd_even, day_of_week, start_section'
where id = 'ea.timeplate_slot';

update sync.sync_config set
delete_condition = $$id not in ('00000')$$
where id = 'ea.teacher';

update sync.sync_config set
before_sync = $$insert into ea.sv_course_class_map values(null, null, null, null);$$,
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$term_id = ${term_id}$$
where id = 'ea.course_class';

update sync.sync_config set
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$course_class_id in (
    select id
    from ea.course_class
    where term_id = ${term_id}
)$$
where id = 'ea.course_class_condition';

update sync.sync_config set
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$course_class_id in (
    select id
    from ea.course_class
    where term_id = ${term_id}
)$$
where id = 'ea.course_class_program';

update sync.sync_config set
before_sync = $$insert into ea.sv_task_map values(null, null, null, null, null);$$,
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$course_class_id in (
    select id
    from ea.course_class
    where term_id = ${term_id}
)$$
where id = 'ea.task';

update sync.sync_config set
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$task_id in (
    select task.id
    from ea.task
    join ea.course_class on course_class.id = task.course_class_id
    where course_class.term_id = ${term_id}
)$$
where id = 'ea.task_teacher';

update sync.sync_config set
select_sql = $$with task_schedule as (
    select * from sv_task_schedule ${where}
), schedule_segment as (
  select a.id, a.root_id, a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
      a.odd_even, a.day_of_week, a.start_section, a.total_section, b.segment
  from task_schedule a
  join ea.period b on a.term_id between b.start_term and b.end_term and a.start_section = b.code
), schedule_start as (
  select schedule_segment.*, case
    when lag(start_section) over w1 + lag(total_section) over w1 = start_section -- 相连
      and (sum(total_section) over w2 % 2 = 1 -- 之前节数合计为奇数
        or total_section = 1 and coalesce(lead(total_section) over w1, 0) % 2 = 0 -- 或之前节数为偶数，当前节数为单节且后续节不为奇数
      )
    then 0 else 1 end as start_flag
  from schedule_segment
  window w1 as (partition by task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, segment
                order by start_section),
         w2 as (partition by task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, segment
                order by start_section
                range unbounded preceding exclude current row)
), schedule_group as (
  select schedule_start.*, sum(start_flag) over w as group_number
  from schedule_start
  window w as (partition by task_id, teacher_id, start_week, end_week, odd_even, day_of_week, segment
               order by start_section)
), schedule_merge as (
  select first_value(id) over w as id,
    first_value(root_id) over w as root_id,
    task_id, teacher_id, place_id,
    start_week, end_week, odd_even, day_of_week,
    start_section, total_section, start_flag, group_number,
    min(start_section) over w as start_section_new,
    sum(total_section) over w as total_section_new
  from schedule_group
  window w as (partition by task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, segment, group_number
               order by total_section desc, start_section -- 取节数最长的id和root_id，相同节数取节次最小值
               range between unbounded preceding and unbounded following)
), schedule_normal as (
  select id, root_id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week,
    start_section_new as start_section, total_section_new as total_section
  from schedule_merge
  where start_flag = 1
)
select ${column_names} from schedule_normal$$,
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$task_id in (
    select task.id
    from ea.task
    join ea.course_class on course_class.id = task.course_class_id
    where course_class.term_id = ${term_id}
) or
task_id in (
    select task.id
    from ea.task
    join ea.course_class on course_class.id = task.course_class_id
    where course_class.term_id = ${term_id}
)
and id not in (
  with task_schedule as (
      select * from sv_task_schedule where term_id = ${term_id}
  ), schedule_segment as (
    select a.id, a.root_id, a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
        a.odd_even, a.day_of_week, a.start_section, a.total_section, b.segment
    from task_schedule a
    join ea.period b on a.term_id between b.start_term and b.end_term and a.start_section = b.code
  ), schedule_start as (
    select schedule_segment.*, case
      when lag(start_section) over w1 + lag(total_section) over w1 = start_section -- 相连
        and (sum(total_section) over w2 % 2 = 1 -- 之前节数合计为奇数
          or total_section = 1 and coalesce(lead(total_section) over w1, 0) % 2 = 0 -- 或之前节数为偶数，当前节数为单节且后续节不为奇数
        )
      then 0 else 1 end as start_flag
    from schedule_segment
    window w1 as (partition by task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, segment
                  order by start_section),
           w2 as (partition by task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, segment
                  order by start_section
                  range unbounded preceding exclude current row)
  ), schedule_group as (
    select schedule_start.*, sum(start_flag) over w as group_number
    from schedule_start
    window w as (partition by task_id, teacher_id, start_week, end_week, odd_even, day_of_week, segment
                 order by start_section)
  ), schedule_merge as (
    select first_value(id) over w as id,
      first_value(root_id) over w as root_id,
      task_id, teacher_id, place_id,
      start_week, end_week, odd_even, day_of_week,
      start_section, total_section, start_flag, group_number,
      min(start_section) over w as start_section_new,
      sum(total_section) over w as total_section_new
    from schedule_group
    window w as (partition by task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, segment, group_number
                 order by total_section desc, start_section -- 取节数最长的id和root_id，相同节数取节次最小值
                 range between unbounded preceding and unbounded following)
  ), schedule_normal as (
    select id, root_id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week,
      start_section_new as start_section, total_section_new as total_section
    from schedule_merge
    where start_flag = 1
  )
  select id from schedule_normal
)$$,
after_sync = $$update task_schedule ts set
week_bits = ea.fn_weeks_to_integer(ts.start_week, ts.end_week, ts.odd_even),
section_bits = ea.fn_sections_to_integer(ts.start_section, ts.total_section)
from task t
join course_class cc on cc.id = t.course_class_id
where ts.task_id = t.id
and cc.term_id = ${term_id}$$
where id = 'ea.task_schedule';

update sync.sync_config set
upsert_condition = $$term_id = ${term_id}$$,
delete_condition = $$task_id in (
    select task.id
    from ea.task
    join ea.course_class on course_class.id = task.course_class_id
    where course_class.term_id = ${term_id}
)$$
where id = 'ea.task_student';

update sync.sync_config set
select_sql = $$select u1.id, u1.department_id, coalesce(u2.email, u1.email) as email,
   u1.enabled, u1.login_name, coalesce(u2.long_phone, u1.long_phone) as long_phone,
   u1.name, u1.password, u1.user_type
from tm.sv_system_user u1
left join tm.system_user u2 on u1.id = u2.id$$,
delete_condition = $$1 = 2$$,
after_sync = $$update tm.system_user
set enabled = false
where id not in (
	select id from tm.sv_system_user
) and user_type in (1, 2)$$
where id = 'tm.system_user';
