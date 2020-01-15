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
before_sync = $$insert into ea.sv_course_class_map values(null);$$,
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
before_sync = $$insert into ea.sv_task_map values(null);$$,
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
), formal as (
    select case when b.total_section is null then a.id else b.id end as id, -- 统一ID为长度不等于1的安排
	    case when b.id is null then a.root_id else b.root_id end as root_id, -- 统一ROOT_ID为长度不等于1的安排
        a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
        a.odd_even, a.day_of_week, a.start_section, a.total_section
    from task_schedule a
    left join task_schedule b on a.task_id = b.task_id
    and a.teacher_id = b.teacher_id
    and (a.place_id = b.place_id or a.place_id is null and b.place_id is null)
    and a.start_week = b.start_week
    and a.end_week = b.end_week
    and a.odd_even = b.odd_even
    and a.day_of_week = b.day_of_week
    and a.total_section = 1
    and (a.start_section + a.total_section = b.start_section and b.start_section not in (5, 10)
      or b.start_section + b.total_section = a.start_section and a.start_section not in (5, 10))
), schedule as (
  select id, day_of_week, end_week, odd_even, place_id, min(start_section) as start_section,
     start_week, task_id, teacher_id, sum(total_section) as total_section, root_id
  from formal
  group by id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, root_id
), fix_root as (
  select id, day_of_week, end_week, odd_even, place_id, start_section, start_week, task_id, teacher_id, total_section, 
    case
      when root_id is null then null
      when exists (select id from schedule x where x.id = y.root_id) then root_id
      else null
    end as root_id
  from schedule y
)
select ${column_names} from fix_root$$,
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
  ), formal as (
      select case when b.total_section is null then a.id else b.id end as id, -- 统一ID为长度不等于1的安排
        case when b.id is null then a.root_id else b.root_id end as root_id, -- 统一ROOT_ID为长度不等于1的安排
          a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
          a.odd_even, a.day_of_week, a.start_section, a.total_section
      from task_schedule a
      left join task_schedule b on a.task_id = b.task_id
      and a.teacher_id = b.teacher_id
      and (a.place_id = b.place_id or a.place_id is null and b.place_id is null)
      and a.start_week = b.start_week
      and a.end_week = b.end_week
      and a.odd_even = b.odd_even
      and a.day_of_week = b.day_of_week
      and a.total_section = 1
      and (a.start_section + a.total_section = b.start_section and b.start_section not in (5, 10)
        or b.start_section + b.total_section = a.start_section and a.start_section not in (5, 10))
  ), schedule as (
    select id, day_of_week, end_week, odd_even, place_id, min(start_section) as start_section,
      start_week, task_id, teacher_id, sum(total_section) as total_section, root_id
    from formal
    group by id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, root_id
  )
  select id
  from schedule
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
