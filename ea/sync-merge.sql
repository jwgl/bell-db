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
insert into ea.department(id, name, english_name, short_name, is_teaching, has_students)
select id, name, english_name, short_name, is_teaching, has_students from ea.sv_department
on conflict(id) do update set
name         = EXCLUDED.name, 
english_name = EXCLUDED.english_name,
short_name   = EXCLUDED.short_name, 
is_teaching  = EXCLUDED.is_teaching, 
has_students = EXCLUDED.has_students;

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

 -- 教学场地-允许借用用户类型
insert into ea.place_booking_user_type(place_id, user_type)
select place_id, user_type from ea.sv_place_booking_user_type
on conflict(place_id, user_type) do nothing;

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

update ea.course set period_theory = 0, period_experiment = 2 where id = '11190431';
update ea.course set period_theory = 0, period_experiment = 2 where id = '17110890';
update ea.course set period_theory = 1 where id = '17110900';
update ea.course set period_theory = 1 where id = '20190530';
update ea.course set period_weeks = 6 where id = '06110700';
update ea.course set period_experiment = 1 where id = '01190061';
update ea.course set period_experiment = 1 where id = '01190350';
update ea.course set period_experiment = 1 where id = '01190380';
update ea.course set period_theory = 2, period_experiment = 2 where id = '01110261';
update ea.course set period_theory = 0, period_experiment = 2 where id = '12190550';
update ea.course set period_theory = 0, period_experiment = 2 where id = '01111220';
update ea.course set period_theory = 0, period_experiment = 4 where id = '01111230';

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
on conflict(program_id, course_id, direction_id) do update set
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
insert into ea.admin_class(id, name, major_id, department_id)
select id, name, major_id, department_id from ea.sv_admin_class
on conflict(id) do update set
name          = EXCLUDED.name,
major_id      = EXCLUDED.major_id,
department_id = EXCLUDED.department_id;

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

-- postgres=# set client_encoding to 'utf8';
-- update admission set used_name = '李' where student_id = '0416020026';
update admission set used_name = '刘龑' where student_id = '1017010074';

-- 学生
insert into ea.student(id, name, pinyin_name, sex, birthday, political_status, nationality, date_enrolled, 
	date_graduated, is_enrolled, at_school, is_registed, train_range, 
	category, forign_language, forign_language_level, change_type, department_id,
	admin_class_id, major_id, direction_id, admission_id)
select id, name, pinyin_name, sex, birthday, political_status, nationality, date_enrolled, 
	date_graduated, is_enrolled, at_school, is_registed, train_range, 
	category, forign_language, forign_language_level, change_type, department_id,
	admin_class_id, major_id, direction_id, admission_id
from ea.sv_student
on conflict(id) do update set
name                  = EXCLUDED.name,
pinyin_name           = EXCLUDED.pinyin_name,
sex                   = EXCLUDED.sex,
birthday              = EXCLUDED.birthday,
political_status      = EXCLUDED.political_status,
nationality           = EXCLUDED.nationality,
date_enrolled         = EXCLUDED.date_enrolled,
date_graduated        = EXCLUDED.date_graduated,
is_enrolled           = EXCLUDED.is_enrolled,
at_school             = EXCLUDED.at_school,
is_registed           = EXCLUDED.is_registed,
train_range           = EXCLUDED.train_range,
category              = EXCLUDED.category,
forign_language       = EXCLUDED.forign_language,
forign_language_level = EXCLUDED.forign_language_level,
change_type           = EXCLUDED.change_type,
department_id         = EXCLUDED.department_id,
admin_class_id        = EXCLUDED.admin_class_id,
major_id              = EXCLUDED.major_id,
direction_id          = EXCLUDED.direction_id,
admission_id          = EXCLUDED.admission_id;

-- postgres=# set client_encoding to 'utf8';
update student set name = '谭龑焘' where id = '0818010172';

-- 教学班
insert into ea.course_class(id, period_theory, period_experiment, period_weeks, property_id, assess_type, test_type, start_week, end_week, 
	term_id, course_id, department_id, teacher_id, original_id)
select id, period_theory, period_experiment, period_weeks, property_id, assess_type, test_type, start_week, end_week, 
	term_id, course_id, department_id, teacher_id, original_id
from ea.sv_course_class
on conflict(id) do update set
period_theory     = EXCLUDED.period_theory,
period_experiment = EXCLUDED.period_experiment,
period_weeks      = EXCLUDED.period_weeks,
property_id       = EXCLUDED.property_id,
assess_type       = EXCLUDED.assess_type,
test_type         = EXCLUDED.test_type,
start_week        = EXCLUDED.start_week,
end_week          = EXCLUDED.end_week,
term_id           = EXCLUDED.term_id,
course_id         = EXCLUDED.course_id,
department_id     = EXCLUDED.department_id,
teacher_id        = EXCLUDED.teacher_id,
original_id       = EXCLUDED.original_id;

-- 教学班-计划
insert into ea.course_class_program(course_class_id, program_id)
select course_class_id, program_id from ea.sv_course_class_program
on conflict(course_class_id, program_id) do nothing;

-- 教学任务
insert into ea.task(id, is_primary, start_week, end_week, course_item_id, course_class_id, original_id)
select id, is_primary, start_week, end_week, course_item_id, course_class_id, original_id from ea.sv_task
on conflict(id) do update set
is_primary      = EXCLUDED.is_primary,
start_week      = EXCLUDED.start_week,
end_week        = EXCLUDED.end_week,
course_item_id  = EXCLUDED.course_item_id,
course_class_id = EXCLUDED.course_class_id,
original_id     = EXCLUDED.original_id;

-- 教学安排
insert into ea.arrangement(id, task_id, teacher_id, place_id, start_week, end_week,
	odd_even, day_of_week, start_section, total_section)
select id::uuid, task_id, teacher_id, place_id, start_week, end_week,
	odd_even, day_of_week, start_section, total_section
from ea.sv_arrangement
where id is not null
on conflict(id) do update set 
teacher_id     = EXCLUDED.teacher_id, 
place_id       = EXCLUDED.place_id,
start_week     = EXCLUDED.start_week, 
end_week       = EXCLUDED.end_week, 
odd_even       = EXCLUDED.odd_even,
day_of_week    = EXCLUDED.day_of_week,
start_section  = EXCLUDED.start_section,
total_section  = EXCLUDED.total_section;

insert into ea.arrangement(id, task_id, teacher_id, place_id, start_week, end_week,
	odd_even, day_of_week, start_section, total_section)
select uuid_generate_v4(), task_id, teacher_id, place_id, start_week, end_week,
	odd_even, day_of_week, start_section, total_section
from ea.sv_arrangement
where id is null
and task_id not in (select task_id from ea.arrangement);

update ea.arrangement t set
teacher_id     = sv.teacher_id, 
place_id       = sv.place_id,
start_week     = sv.start_week, 
end_week       = sv.end_week, 
odd_even       = sv.odd_even,
day_of_week    = sv.day_of_week,
start_section  = sv.start_section,
total_section  = sv.total_section
from ea.sv_arrangement sv
where sv.id is null and t.task_id = sv.task_id;
