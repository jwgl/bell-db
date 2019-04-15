/**
 * database bell/ea
 */
grant usage on schema ea                   to tm;

grant references on ea.admin_class         to tm;
grant references on ea.teacher             to tm;
grant references on ea.student             to tm;
grant references on ea.program             to tm;
grant references on ea.department          to tm;
grant references on ea.property            to tm;
grant references on ea.course              to tm;
grant references on ea.course_Item         to tm;
grant references on ea.direction           to tm;
grant references on ea.subject             to tm;
grant references on ea.major               to tm;
grant references on ea.field               to tm;
grant references on ea.place               to tm;
grant references on ea.term                to tm;
grant references on ea.task                to tm;
grant references on ea.task_schedule       to tm;
grant references on ea.course_class        to tm;

grant select on ea.term                    to tm;
grant select on ea.admin_class             to tm;
grant select on ea.teacher                 to tm;
grant select on ea.student                 to tm;
grant select on ea.admission               to tm;
grant select on ea.program                 to tm;
grant select on ea.program_course          to tm;
grant select on ea.department              to tm;
grant select on ea.property                to tm;
grant select on ea.program_property        to tm;
grant select on ea.course                  to tm;
grant select on ea.course_item             to tm;
grant select on ea.direction               to tm;
grant select on ea.subject                 to tm;
grant select on ea.major                   to tm;
grant select on ea.field                   to tm;
grant select on ea.field_class             to tm;
grant select on ea.discipline              to tm;
grant select on ea.course_class            to tm;
grant select on ea.task                    to tm;
grant select on ea.task_schedule           to tm;
grant select on ea.task_teacher            to tm;
grant select on ea.task_student            to tm;
grant select on ea.place                   to tm;
grant select on ea.place_booking_term      to tm;
grant select on ea.place_department        to tm;
grant select on ea.term_swap_date          to tm;
grant select on ea.course_class_program    to tm;
grant select on ea.sv_program_course       to tm;
grant select on ea.external_staff          to tm;

grant update(exam_flag) on ea.task_student to tm;


