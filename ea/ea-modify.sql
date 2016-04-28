create unique index uk_program_course_direction_not_null on ea.program_course(program_id, direction_id, course_id)
where direction_id is not null;

create unique index uk_program_course_direction_is_null on ea.program_course(program_id, course_id)
where direction_id is null;