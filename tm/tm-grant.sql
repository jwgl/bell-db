/**
 * database bell/tm
 */
grant usage on schema tm to ea;

grant select, delete on student_leave_item to ea;
grant select, delete on free_listen_item   to ea;
grant select, delete on rollcall           to ea;
grant select, update on workitem           to ea;