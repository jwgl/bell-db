-- postgres@bnuz/tm
create extension postgres_fdw;
create server bnuc foreign data wrapper postgres_fdw options (host 'host-name', dbname 'bell');
grant usage on foreign server bnuc to ea;
grant usage on foreign server bnuc to tm;
create user mapping for ea server bnuc options (user 'ea', password 'ea-password');
create user mapping for tm server bnuc options (user 'tm', password 'tm-password');

drop foreign table if exists tm_load.et_external_workload;
create foreign table tm_load.et_external_workload (
  term_id integer,
  teacher_id text,
  teacher_name text,
  teaching_workload numeric(6,2),
  practice_workload numeric(6,2),
  executive_workload numeric(6,2),
  correction numeric(6,2),
  opposite_number text
) server bnuc options (schema_name 'tm_load', table_name 'ev_workload', updatable 'false');

drop foreign table if exists tm_load.et_teacher_workload_by_task;
create foreign table tm_load.et_teacher_workload_by_task (
  term_id integer,
  id uuid,
  code text,
  task_ordinal integer,
  primary_teacher_id text,
  teacher_id text,
  teacher_name text,
  teacher_department text,
  course_id text,
  course_name text,
  course_item text,
  course_credit numeric(3,1),
  course_property text,
  course_class_department text,
  workload_mode text,
  workload_type text,
  student_count integer,
  class_size_ratio numeric(3,2),
  instructional_mode_ratio numeric(3,2),
  parallel_ratio numeric(3,2),
  correction integer,
  original_workload integer,
  standard_workload numeric(6,2),
  task_schedules text[]
) server bnuc options (schema_name 'tm_load', table_name 'ev_teacher_workload_by_task', updatable 'false');
