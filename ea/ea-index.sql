create unique index uk_program_course_direction on ea.program_course(program_id, coalesce(direction_id, 0), course_id);

create index task_course_class_idx on task(course_class_id);
create index task_schedule_task_idx on task_schedule(task_id);
create index task_schedule_teacher_idx on task_schedule(teacher_id);
create index task_schedule_odd_even_idx on task_schedule(odd_even);
create index task_student_task_idx on task_student(task_id);
create index task_student_student_idx on task_student(student_id);