/**
 * database bell/ea
 */

-- 学期
insert into ea.term (id, start_date, start_week, mid_left, mid_right,end_week, max_week)
select id, start_date, start_week, mid_left, mid_right, end_week, max_week from ea.sv_term
on conflict(id) do update set
start_date = EXCLUDED.start_date,
start_week = EXCLUDED.start_week,
mid_left   = EXCLUDED.mid_left,
mid_right  = EXCLUDED.mid_right,
end_week   = EXCLUDED.end_week,
max_week   = EXCLUDED.max_week;

-- 学院
insert into ea.department(id, name, english_name, short_name, is_teaching, has_students, enabled)
select id, name, english_name, short_name, is_teaching, has_students, enabled from ea.sv_department
on conflict(id) do update set
name         = EXCLUDED.name,
english_name = EXCLUDED.english_name,
short_name   = EXCLUDED.short_name,
is_teaching  = EXCLUDED.is_teaching,
has_students = EXCLUDED.has_students,
enabled      = EXCLUDED.enabled;

-- 教学场地
insert into ea.place(id, name, english_name, building, type, seat, test_seat, enabled, can_test, is_external, note)
select id, name, english_name, building, type, seat, test_seat, enabled, can_test, is_external, note from ea.sv_place
on conflict(id) do update set
name         = EXCLUDED.name,
english_name = EXCLUDED.english_name,
building     = EXCLUDED.building,
type         = EXCLUDED.type,
seat         = EXCLUDED.seat,
test_seat    = EXCLUDED.test_seat,
enabled      = EXCLUDED.enabled,
can_test     = EXCLUDED.can_test,
is_external  = EXCLUDED.is_external,
note         = EXCLUDED.note;

-- 教学场地-允许使用单位
insert into ea.place_department(place_id, department_id)
select place_id, department_id from ea.sv_place_department
on conflict (place_id, department_id) do nothing;

-- 教学场地-允许借用学期
insert into ea.place_booking_term(place_id, term_id)
select place_id, term_id from  ea.sv_place_booking_term
on conflict(place_id, term_id) do nothing;

-- 学科门类
insert into ea.discipline(id, name, code)
select id, name, code from ea.sv_discipline
on conflict(id) do update set
name = EXCLUDED.name,
code = EXCLUDED.code;

-- 专业类
insert into ea.field_class(id, name, code, discipline_id)
select id, name, code, discipline_id from ea.sv_field_class
on conflict(id) do update set
name          = EXCLUDED.name,
code          = EXCLUDED.code,
discipline_id = EXCLUDED.discipline_id;

-- 专业目录
insert into ea.field(id, name, code, flag, field_class_id)
select id, name, code, flag, field_class_id from ea.sv_field
on conflict(id) do update set
name           = EXCLUDED.name,
code           = EXCLUDED.code,
flag           = EXCLUDED.flag,
field_class_id = EXCLUDED.field_class_id;

-- 专业目录允许授予学位
insert into ea.field_allow_degree(field_id, discipline_id)
select field_id, discipline_id from ea.sv_field_allow_degree
on conflict(field_id, discipline_id) do nothing;

-- 校内专业
insert into ea.subject(id, name, english_name, short_name, education_level, length_of_schooling,
    stop_enroll, is_joint_program, is_dual_degree, is_top_up, field_id, degree_id, department_id)
select id, name, english_name, short_name, education_level, length_of_schooling,
    stop_enroll, is_joint_program, is_dual_degree, is_top_up, field_id, degree_id, department_id
from ea.sv_subject
on conflict(id) do update set
name                = EXCLUDED.name,
english_name        = EXCLUDED.english_name,
short_name          = EXCLUDED.short_name,
education_level     = EXCLUDED.education_level,
length_of_schooling = EXCLUDED.length_of_schooling,
stop_enroll         = EXCLUDED.stop_enroll,
is_joint_program    = EXCLUDED.is_joint_program,
is_dual_degree      = EXCLUDED.is_dual_degree,
is_top_up           = EXCLUDED.is_top_up,
field_id            = EXCLUDED.field_id,
degree_id           = EXCLUDED.degree_id,
department_id       = EXCLUDED.department_id;

-- 年级专业
insert into ea.major(id, subject_id, grade, candidate_type, field_id, degree_id, department_id)
select id, subject_id, grade, candidate_type, field_id, degree_id, department_id from ea.sv_major
on conflict(id) do update set
subject_id     = EXCLUDED.subject_id,
grade          = EXCLUDED.grade,
candidate_type = EXCLUDED.candidate_type,
field_id       = EXCLUDED.field_id,
degree_id      = EXCLUDED.degree_id,
department_id  = EXCLUDED.department_id;

-- 教学计划
insert into ea.program(id, type, major_id, credit)
select id, type, major_id, credit from ea.sv_program
on conflict(id) do update set
type     = EXCLUDED.type,
major_id = EXCLUDED.major_id,
credit   = EXCLUDED.credit;

-- 专业方向
insert into ea.direction(id, program_id, name)
select id, program_id, name from ea.sv_direction
on conflict(id) do update set
program_id = EXCLUDED.program_id,
name       = EXCLUDED.name;

INSERT INTO ea.direction (id, program_id, name) VALUES (2014020401, 201402040, '社会保障方向');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014020402, 201402040, '劳动关系方向');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014050701, 201405070, '对外汉语教学');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014050702, 201405070, '英语语言文学');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014050703, 201405070, '英语教育');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014050801, 201405080, '汉语言文学');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014050802, 201405080, '商务日语');
INSERT INTO ea.direction (id, program_id, name) VALUES (2014050803, 201405080, '汉语言');

-- 课程性质
insert into ea.property(id, name, short_name, is_compulsory, is_primary)
select id, name, short_name, is_compulsory, is_primary from ea.sv_property
on conflict(id) do update set
name          = EXCLUDED.name,
short_name    = EXCLUDED.short_name,
is_compulsory = EXCLUDED.is_compulsory,
is_primary    = EXCLUDED.is_primary;

-- 教学计划-课程性质
insert into ea.program_property(program_id, property_id, credit, is_weighted)
select program_id, property_id, credit, is_weighted from ea.sv_program_property
on conflict(program_id, property_id) do update set
credit      = EXCLUDED.credit,
is_weighted = EXCLUDED.is_weighted;

-- 课程
insert into ea.course(id, name, english_name, credit, period_theory, period_experiment, period_weeks,
    is_compulsory, is_practical, property_id, education_level, assess_type,
    schedule_type, introduction, enabled, department_id)
select id, name, english_name, credit, period_theory, period_experiment, period_weeks,
    is_compulsory, is_practical, property_id, education_level, assess_type,
    schedule_type, introduction, enabled, department_id
from ea.sv_course
on conflict(id) do update set
name              = EXCLUDED.name,
english_name      = EXCLUDED.english_name,
period_theory     = EXCLUDED.period_theory,
period_experiment = EXCLUDED.period_experiment,
period_weeks      = EXCLUDED.period_weeks,
is_compulsory     = EXCLUDED.is_compulsory,
is_practical      = EXCLUDED.is_practical,
property_id       = EXCLUDED.property_id,
education_level   = EXCLUDED.education_level,
assess_type       = EXCLUDED.assess_type,
schedule_type     = EXCLUDED.schedule_type,
introduction      = EXCLUDED.introduction,
enabled           = EXCLUDED.enabled,
department_id     = EXCLUDED.department_id;

--课程项目
insert into ea.course_item(id, name, ordinal, is_primary, course_id)
select id, name, ordinal, is_primary, course_id from ea.sv_course_item
on conflict(id) do update set
name       = EXCLUDED.name,
ordinal    = EXCLUDED.ordinal,
is_primary = EXCLUDED.is_primary,
course_id  = EXCLUDED.course_id;

-- 教学计划-课程
insert into ea.program_course(program_id, course_id, direction_id, period_theory, period_experiment, period_weeks,
    is_compulsory, is_practical, property_id, assess_type, test_type,
    start_week, end_week, suggested_term, allowed_term, schedule_type,
    department_id)
select program_id, course_id, direction_id, period_theory, period_experiment, period_weeks,
    is_compulsory, is_practical, property_id, assess_type, test_type,
    start_week, end_week, suggested_term, allowed_term, schedule_type,
    department_id
from ea.sv_program_course
on conflict(program_id, coalesce(direction_id, 0), course_id) do update set
period_theory     = EXCLUDED.period_theory,
period_experiment = EXCLUDED.period_experiment,
period_weeks      = EXCLUDED.period_weeks,
is_compulsory     = EXCLUDED.is_compulsory,
is_practical      = EXCLUDED.is_practical,
property_id       = EXCLUDED.property_id,
assess_type       = EXCLUDED.assess_type,
test_type         = EXCLUDED.test_type,
start_week        = EXCLUDED.start_week,
end_week          = EXCLUDED.end_week,
suggested_term    = EXCLUDED.suggested_term,
allowed_term      = EXCLUDED.allowed_term,
schedule_type     = EXCLUDED.schedule_type,
department_id     = EXCLUDED.department_id;

-- 教师
insert into ea.teacher(id, name, sex, birthday, political_status, nationality, academic_title,
    academic_level, academic_degree, educational_background, graduate_school, graduate_major,
    date_graduated, post_type, has_qualification, is_lab_technician, is_external,
    at_school, can_guidance_graduate, department_id, resume)
select id, name, sex, birthday, political_status, nationality, academic_title,
    academic_level, academic_degree, educational_background, graduate_school, graduate_major,
    date_graduated, post_type, has_qualification, is_lab_technician, is_external,
    at_school, can_guidance_graduate, department_id, resume
from ea.sv_teacher
on conflict(id) do update set
name                   = EXCLUDED.name,
sex                    = EXCLUDED.sex,
birthday               = EXCLUDED.birthday,
political_status       = EXCLUDED.political_status,
nationality            = EXCLUDED.nationality,
academic_title         = EXCLUDED.academic_title,
academic_level         = EXCLUDED.academic_level,
academic_degree        = EXCLUDED.academic_degree,
educational_background = EXCLUDED.educational_background,
graduate_school        = EXCLUDED.graduate_school,
graduate_major         = EXCLUDED.graduate_major,
date_graduated         = EXCLUDED.date_graduated,
post_type              = EXCLUDED.post_type,
has_qualification      = EXCLUDED.has_qualification,
is_lab_technician      = EXCLUDED.is_lab_technician,
is_external            = EXCLUDED.is_external,
at_school              = EXCLUDED.at_school,
can_guidance_graduate  = EXCLUDED.can_guidance_graduate,
department_id          = EXCLUDED.department_id,
resume                 = EXCLUDED.resume;

-- 行政班
insert into ea.admin_class(id, name, major_id, department_id, supervisor_id, counsellor_id)
select id, name, major_id, department_id, supervisor_id, counsellor_id from ea.sv_admin_class
on conflict(id) do update set
name          = EXCLUDED.name,
major_id      = EXCLUDED.major_id,
department_id = EXCLUDED.department_id,
supervisor_id = EXCLUDED.supervisor_id,
counsellor_id = EXCLUDED.counsellor_id;

-- 录取信息
insert into ea.admission(id, student_id, subject_id, grade, name, used_name, sex, birthday, political_status,
    nationality, phone_number, from_province, from_city, home_address, household_address,
    postal_code, middle_school, candidate_number, examination_number, total_score,
    english_score, id_number, bank_number)
select id, student_id, subject_id, grade, name, used_name, sex, birthday, political_status,
    nationality, phone_number, from_province, from_city, home_address, household_address,
    postal_code, middle_school, candidate_number, examination_number, total_score,
    english_score, id_number, bank_number
from ea.sv_admission
on conflict(id) do update set
student_id         = EXCLUDED.student_id,
subject_id         = EXCLUDED.subject_id,
grade              = EXCLUDED.grade,
name               = EXCLUDED.name,
used_name          = EXCLUDED.used_name,
sex                = EXCLUDED.sex,
birthday           = EXCLUDED.birthday,
political_status   = EXCLUDED.political_status,
nationality        = EXCLUDED.nationality,
phone_number       = EXCLUDED.phone_number,
from_province      = EXCLUDED.from_province,
from_city          = EXCLUDED.from_city,
home_address       = EXCLUDED.home_address,
household_address  = EXCLUDED.household_address,
postal_code        = EXCLUDED.postal_code,
middle_school      = EXCLUDED.middle_school,
candidate_number   = EXCLUDED.candidate_number,
examination_number = EXCLUDED.examination_number,
total_score        = EXCLUDED.total_score,
english_score      = EXCLUDED.english_score,
id_number          = EXCLUDED.id_number,
bank_number        = EXCLUDED.bank_number;

-- 学生
insert into ea.student(id, name, pinyin_name, sex, birthday, political_status, nationality, date_enrolled,
    date_graduated, is_enrolled, at_school, is_registered, train_range,
    category, foreign_language, foreign_language_level, change_type, department_id,
    admin_class_id, major_id, direction_id, admission_id)
select id, name, pinyin_name, sex, birthday, political_status, nationality, date_enrolled,
    date_graduated, is_enrolled, at_school, is_registered, train_range,
    category, foreign_language, foreign_language_level, change_type, department_id,
    admin_class_id, major_id, direction_id, admission_id
from ea.sv_student
on conflict(id) do update set
name                   = EXCLUDED.name,
pinyin_name            = EXCLUDED.pinyin_name,
sex                    = EXCLUDED.sex,
birthday               = EXCLUDED.birthday,
political_status       = EXCLUDED.political_status,
nationality            = EXCLUDED.nationality,
date_enrolled          = EXCLUDED.date_enrolled,
date_graduated         = EXCLUDED.date_graduated,
is_enrolled            = EXCLUDED.is_enrolled,
at_school              = EXCLUDED.at_school,
is_registered          = EXCLUDED.is_registered,
train_range            = EXCLUDED.train_range,
category               = EXCLUDED.category,
foreign_language       = EXCLUDED.foreign_language,
foreign_language_level = EXCLUDED.foreign_language_level,
change_type            = EXCLUDED.change_type,
department_id          = EXCLUDED.department_id,
admin_class_id         = EXCLUDED.admin_class_id,
major_id               = EXCLUDED.major_id,
direction_id           = EXCLUDED.direction_id,
admission_id           = EXCLUDED.admission_id;

-- 生成course_class_id与course_class_code对应关系，通过视图触发器实现
insert into ea.sv_course_class_map values(null, null, null);

-- 教学班
insert into ea.course_class(term_id, id, code, name, period_theory, period_experiment, period_weeks,
    property_id, assess_type, test_type, start_week, end_week,
    course_id, department_id, teacher_id)
select term_id, id, code, name, period_theory, period_experiment, period_weeks,
    property_id, assess_type, test_type, start_week, end_week,
    course_id, department_id, teacher_id
from ea.sv_course_class
on conflict(id) do update set
term_id           = EXCLUDED.term_id,
code              = EXCLUDED.code,
name              = EXCLUDED.name,
period_theory     = EXCLUDED.period_theory,
period_experiment = EXCLUDED.period_experiment,
period_weeks      = EXCLUDED.period_weeks,
property_id       = EXCLUDED.property_id,
assess_type       = EXCLUDED.assess_type,
test_type         = EXCLUDED.test_type,
start_week        = EXCLUDED.start_week,
end_week          = EXCLUDED.end_week,
course_id         = EXCLUDED.course_id,
department_id     = EXCLUDED.department_id,
teacher_id        = EXCLUDED.teacher_id;

-- 教学班-计划
insert into ea.course_class_program(course_class_id, program_id)
select course_class_id, program_id from ea.sv_course_class_program
on conflict(course_class_id, program_id) do nothing;

-- 生成task_id与task_code对应关系，通过视图触发器实现
insert into ea.sv_task_map values(null);

-- 教学任务
insert into ea.task(id, code, is_primary, start_week, end_week, course_item_id, course_class_id)
select id, code, is_primary, start_week, end_week, course_item_id, course_class_id from ea.sv_task
on conflict(id) do update set
code            = EXCLUDED.code,
is_primary      = EXCLUDED.is_primary,
start_week      = EXCLUDED.start_week,
end_week        = EXCLUDED.end_week,
course_item_id  = EXCLUDED.course_item_id,
course_class_id = EXCLUDED.course_class_id;

-- 教学任务-教师
insert into ea.task_teacher(task_id, teacher_id)
select task_id, teacher_id from ea.sv_task_teacher
on conflict(task_id, teacher_id) do nothing;

-- 教学安排
-- Oracle 11g端合并性能低，合并逻辑移到PostgreSQL端
insert into ea.task_schedule(id, task_id, teacher_id, place_id, start_week, end_week,
    odd_even, day_of_week, start_section, total_section, root_id)
with formal as (
    select case when b.id is null then a.id else b.id end as id, -- 统一ID为长度不等于1的安排
        case when b.id is null then a.root_id else b.root_id end as root_id, -- 统一ROOT_ID为长度不等于1的安排
        a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
        a.odd_even, a.day_of_week, a.start_section, a.total_section
    from sv_task_schedule a
    left join sv_task_schedule b on a.task_id = b.task_id
    and a.teacher_id = b.teacher_id
    and (a.place_id = b.place_id or a.place_id is null and b.place_id is null)
    and a.start_week = b.start_week
    and a.end_week = b.end_week
    and a.odd_even = b.odd_even
    and a.day_of_week = b.day_of_week
    and a.total_section = 1
    and (a.start_section + a.total_section = b.start_section and b.start_section not in (5, 10)
      or b.start_section + b.total_section = a.start_section and a.start_section not in (5, 10))
)
select id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week,
    min(start_section), sum(total_section) as total_section, root_id
from formal
group by id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, root_id
on conflict(id) do update set
task_id        = EXCLUDED.task_id,
teacher_id     = EXCLUDED.teacher_id,
place_id       = EXCLUDED.place_id,
start_week     = EXCLUDED.start_week,
end_week       = EXCLUDED.end_week,
odd_even       = EXCLUDED.odd_even,
day_of_week    = EXCLUDED.day_of_week,
start_section  = EXCLUDED.start_section,
total_section  = EXCLUDED.total_section,
root_id        = EXCLUDED.root_id;

-- 学生选课
insert into ea.task_student(task_id, student_id, date_created, register_type, repeat_type, exam_flag)
select task_id, student_id, date_created, register_type, repeat_type, exam_flag
from ea.sv_task_student
where term_id = 20162
on conflict(task_id, student_id) do update set
date_created     = EXCLUDED.date_created,
register_type    = EXCLUDED.register_type,
repeat_type      = EXCLUDED.repeat_type,
exam_flag        = EXCLUDED.exam_flag;

-- 删除数据
delete from ea.task_student
where (task_id, student_id) not in (
    select task_id, student_id
    from ea.sv_task_student
    where term_id = 20162
) and task_id in (
    select task.id
    from ea.task
    join ea.course_class on course_class.id = task.course_class_id
    where course_class.term_id = 20162
);

delete from ea.task_teacher
where (task_id, teacher_id) not in (
    select task_id, teacher_id
    from ea.sv_task_teacher
);

delete from tm.student_leave_item
where task_schedule_id not in (
    select id
    from ea.sv_task_schedule
);

delete from tm.free_listen_item
where task_schedule_id not in (
    select id
    from ea.sv_task_schedule
);

delete from tm.rollcall
where task_schedule_id not in (
    select id
    from ea.sv_task_schedule
);

delete from ea.task_schedule
where id not in (
    with formal as (
        select case when b.id is null then a.id else b.id end as id, -- 统一ID为长度不等于1的安排
            case when b.id is null then a.root_id else b.root_id end as root_id, -- 统一ROOT_ID为长度不等于1的安排
            a.task_id, a.teacher_id, a.place_id, a.start_week, a.end_week,
            a.odd_even, a.day_of_week, a.start_section, a.total_section
        from sv_task_schedule a
        left join sv_task_schedule b on a.task_id = b.task_id
        and a.teacher_id = b.teacher_id
        and (a.place_id = b.place_id or a.place_id is null and b.place_id is null)
        and a.start_week = b.start_week
        and a.end_week = b.end_week
        and a.odd_even = b.odd_even
        and a.day_of_week = b.day_of_week
        and a.total_section = 1
        and (a.start_section + a.total_section = b.start_section and b.start_section not in (5, 10)
          or b.start_section + b.total_section = a.start_section and a.start_section not in (5, 10))
    )
    select id
    from formal
    group by id, task_id, teacher_id, place_id, start_week, end_week, odd_even, day_of_week, root_id
);

delete from ea.task
where id not in (
    select id from ea.sv_task
);

delete from ea.course_class_program
where (course_class_id, program_id) not in (
    select course_class_id, program_id
    from ea.sv_course_class_program
);

delete from ea.course_class
where id not in (
    select id from ea.sv_course_class
);

delete from ea.program_course
where (program_id, coalesce(direction_id, 0), course_id) not in (
    select program_id, coalesce(direction_id, 0), course_id
    from ea.sv_program_course
);

delete from ea.program_property
where (program_id, property_id) not in (
    select program_id, property_id
    from ea.sv_program_property
);

delete from ea.direction
where id not in (
    select id from ea.sv_direction
) and id > 2016000000;

delete from program where id not in (select id from sv_program);

delete from major where id not in (select id from sv_major);
