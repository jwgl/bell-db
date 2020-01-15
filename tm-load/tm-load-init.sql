-- 创建架构
create schema tm_load authorization tm;

create type tm_load.t_tuple_2 as (p1 text, p2 text);
create type tm_load.t_tuple_3 as (p1 text, p2 text, p3 text);

insert into tm_load.department_settings(department_id, creator_id, checker_id) values ('01', '01035', '01039');
insert into tm_load.department_settings(department_id, creator_id, checker_id) values ('11', '11103', '11103');

-- 教学形式类别
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(10, '理论课', 1.0, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(20, '通识课实验', 0.6, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(21, '专业课实验', 0.8, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(22, '综合性实验', 1.0, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(30, '双语课', 1.2, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(31, '外语课', 1.5, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(40, '分散实习', 0.2, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(41, '集中实习1', 0.2, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(42, '集中实习2', 0.4, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(43, '集中实习3', 0.8, 20);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(44, '暑期实习', 1.2, 20);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(45, '教育实习', 0.2, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(46, '野外实习', 1.2, 20);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(50, '毕业论文（设计）', 0.5, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(51, '毕业论文（设计）', 0.7, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(61, '实践课01', 0.1, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(62, '实践课02', 0.2, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(63, '实践课03', 0.3, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(64, '实践课04', 0.4, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(65, '实践课05', 0.5, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(66, '实践课06', 0.6, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(67, '实践课07', 0.7, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(68, '实践课08', 0.8, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(69, '实践课09', 0.9, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(70, '实践课10', 1.0, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(71, '实践课11', 1.1, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(72, '实践课12', 1.2, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(99, '其他', 1.0, null);

-- 班级规模类别
insert into tm_load.class_size_type(id, name, category) values (1, '文法经管艺体', '专业');
insert into tm_load.class_size_type(id, name, category) values (2, '理工外语', '专业');
insert into tm_load.class_size_type(id, name, category) values (3, '实验课', '教学形式');
insert into tm_load.class_size_type(id, name, category) values (4, '艺体实操课', '课程');
insert into tm_load.class_size_type(id, name, category) values (5, '通识课', '课程性质');
insert into tm_load.class_size_type(id, name, category) values (6, '政治理论课', '课程');
insert into tm_load.class_size_type(id, name, category) values (7, '研究生留学生课程', '学生层次');
insert into tm_load.class_size_type(id, name, category) values (9, '常量班型', '常量');

-- 文法经管艺体
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(10, 1, 1,   5,    0.5),
(11, 1, 6,   10,   0.75),
(12, 1, 11,  60,   1.0),
(13, 1, 61,  80,   1.1),
(14, 1, 81,  9999, 1.2);

-- 理工外语
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(20, 2, 1,   5,    0.5),
(21, 2, 6,   10,   0.75),
(22, 2, 11,  50,   1.0),
(23, 2, 51,  65,   1.1),
(24, 2, 66,  9999, 1.2);

-- 实验课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(30, 3, 1,   5,    0.5),
(31, 3, 6,   10,   0.75),
(32, 3, 11,  50,   1.0),
(33, 3, 51,  65,   1.1),
(34, 3, 66,  80,   1.2),
(35, 3, 81,  95,   1.3),
(36, 3, 96,  9999, 1.4);

-- 艺体小班课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(40, 4, 1,   5,    0.5),
(41, 4, 6,   15,   0.8),
(42, 4, 16,  30,   1.0),
(44, 4, 31,  40,   1.1),
(45, 4, 41,  9999, 1.2);

-- 政治理论课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(50, 5, 1,   100,  1.0),
(51, 5, 101, 125,  1.1),
(52, 5, 126, 150,  1.2),
(53, 5, 151, 175,  1.3),
(54, 5, 176, 200,  1.4),
(55, 5, 201, 9999, 1.5);

-- 通识选修课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(60, 6, 1,   100,  1.0),
(61, 6, 101, 125,  1.1),
(62, 6, 126, 150,  1.2),
(63, 6, 151, 175,  1.3),
(64, 6, 176, 200,  1.4),
(65, 6, 201, 9999, 1.5);

-- 研究生留学生课程
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(70, 7, 1,   5,    0.5),
(71, 7, 6,   10,   0.9),
(72, 7, 11,  20,   1.0),
(73, 7, 21,  50,   1.2),
(74, 7, 51,  100,  1.3),
(75, 7, 101, 9999, 1.4);

-- 常量班型
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(90, 9, 0,   9999, 1.0);

-- 级联删除
alter table tm_load.workload_task_teacher
drop constraint fkibohyn6osen4jndq0x2j0kkv9,
add constraint fkibohyn6osen4jndq0x2j0kkv9
  foreign key (workload_task_id)
  references tm_load.workload_task(id)
  on delete cascade;

alter table tm_load.workload_task_schedule
drop constraint fk4n6qejf7v6qbkafxbcoj7i52y,
add constraint fk4n6qejf7v6qbkafxbcoj7i52y
  foreign key (workload_task_id)
  references tm_load.workload_task(id)
  on delete cascade;