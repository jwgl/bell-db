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
