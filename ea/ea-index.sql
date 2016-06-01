create unique index uk_program_course_direction on ea.program_course(program_id, coalesce(direction_id, 0), course_id);
