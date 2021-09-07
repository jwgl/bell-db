drop foreign table if exists ea.et_bnuc_task_schedule;
create foreign table ea.et_bnuc_task_schedule (
  term_id       integer,
  id            uuid,
  task_id       uuid,
  teacher_id    text,
  start_week    integer,
  end_week      integer,
  odd_even      integer,
  day_of_week   integer,
  start_section integer,
  total_section integer,
  place_id      text,
  root_id       uuid,
  week_bits     integer,
  section_bits  integer
) server bnuc options (schema_name 'ea', table_name 'ev_bnuc_task_schedule', updatable 'false');


drop foreign table if exists ea.et_online_place_schedule_remote;
create foreign table ea.et_online_place_schedule_remote (
  task_id       uuid,
  place_id      character varying(6),
  day_of_week   integer,
  week_bits     integer,
  section_bits  integer,
  start_section integer,
  total_section integer,
  start_date    date,
  end_date      date
) server bnuc options (schema_name 'ea', table_name 'tv_online_place_schedule_local', updatable 'false');


drop foreign table if exists ea.et_place_live_student;
create foreign table ea.et_place_live_student (
  place_id      text,
  student_id    text,
  password      text,
  create_time   timestamp without time zone
) server bnuc options (schema_name 'ea', table_name 'place_live_student', updatable 'false');
