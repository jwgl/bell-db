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
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(25, '政治课实践', 0.6, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(30, '双语课', 1.2, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(31, '全外语课', 1.5, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(40, '分散实习', 0.2, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(41, '集中实习1', 0.2, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(42, '集中实习2', 0.4, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(43, '集中实习3', 0.8, 20);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(44, '暑期实习', 1.2, 20);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(45, '教育实习', 0.2, 30);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(46, '野外实习', 1.2, 20);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(50, '毕业论文（设计）', 0.5, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(51, '毕业论文（设计）', 0.7, null);
insert into tm_load.instructional_mode(id, name, ratio, upper_bound) values(99, '其他', 1.0, null);

-- 班级规模类别
insert into tm_load.class_size_type(id, name, category) values (1, '文法经管艺体', '专业');
insert into tm_load.class_size_type(id, name, category) values (2, '理工外语', '专业');
insert into tm_load.class_size_type(id, name, category) values (3, '实验课', '教学形式');
insert into tm_load.class_size_type(id, name, category) values (4, '艺体实操课', '课程');
insert into tm_load.class_size_type(id, name, category) values (5, '通识课', '课程性质');
insert into tm_load.class_size_type(id, name, category) values (6, '政治理论课', '课程');
insert into tm_load.class_size_type(id, name, category) values (7, '研究生课程', '学生层次');
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

-- 研究生课程
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

-- 专业工作量设置（理工外语/文法经管艺体）
insert into tm_load.subject_workload_settings(subject_id, class_size_type_id)
select distinct subject.id, case
  when subject.id like '15%' or discipline.name in ('理学', '工学') then 2
  else 1 end as class_size_type_id
from ea.discipline
join ea.subject on subject.degree_id = discipline.id
left join ea.major on major.subject_id = subject.id
where major.id is not null
and major.grade >= 2012
order by 1
on conflict(subject_id) do update set
class_size_type_id = excluded.class_size_type_id;

-- 课程工作量设置
insert into tm_load.course_workload_settings(department_id, course_id, category, parallel_ratio, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
-- 外国语大学外语
select distinct '15', c.id, '大学外语', 0.72, 2 /*正常*/, 1 /*排课*/, 5 /*通识课*/, 10 /*理论课*/
from ea.course_class cc
join ea.course c on c.id = cc.course_id
where cc.property_id = 1
and substring(course_id, 1, 4) = '1511'
and term_id >= 20191
union all -- 商学部大学外语
select '20', id, '大学外语', 0.72, 2 /*正常*/, 1 /*排课*/, 5 /*通识课*/, 10 /*理论课*/
from ea.course where id like '031100_1'
union all -- 大学体育
select distinct '92', c.id, '大学体育', 0.72, 2 /*正常*/, 1 /*排课*/, 5 /*通识课*/, 10 /*理论课*/
from ea.course_class cc
join ea.course c on c.id = cc.course_id
where cc.property_id = 1
and substring(course_id, 1, 4) = '9211'
and term_id >= 20191
union all -- 政治理论课
select '93', id, '政治理论课', null, 2 /*正常*/, 1 /*排课*/, 5 /*政治课*/, 10 /*理论课*/
from ea.course
where id like '93%'
and id in (
	select course_id
	from ea.course_class
  where term_id >= 20191
)
and name not like '%实践%'
and name not in ('思想道德修养与法律基础（实践）', '形势与政策')
union all -- 政治实践课
select '93', id, '政治实践课', null, 2 /*正常*/, 3 /*学时*/, 5 /*政治课*/, 25 /*政治实践课*/
from ea.course
where id like '93%'
and id in (
	select course_id
	from ea.course_class
  where term_id >= 20191
)
and name like '%实践%'
and name not in ('思想道德修养与法律基础（实践）', '形势与政策')
union all -- 不计-政治理论课
select '93', course.id, '政治理论课', null, 1 /*不计*/, 3 /*学时*/, 9 /*常量*/, 25 /*政治实践课*/
from ea.course
where name = '思想道德修养与法律基础（实践）'
union all -- 不计-政治理论课
select '93', course.id, '政治理论课', null, 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 10 /*理论课*/
from ea.course
where name = '形势与政策'
union all -- 排除-研究生选定课程
select '77', '77100000', '研究生排除', null, 0 /*排除*/, 1 /*排课*/, 9 /*常量*/, 10 /*理论课*/
union all -- 排除-研究生选定课程
select '15', '77100000', '研究生排除', null, 0 /*排除*/, 1 /*排课*/, 9 /*常量*/, 10 /*理论课*/
union all -- 排除-军事教育
select '94', course.id, '军事教育', null, 0 /*排除*/, 1 /*排课*/, 9, 10
from ea.course
where department_id = '94' and id like '9411%'
union all -- 毕业论文（设计）
select distinct course_class.department_id, course.id, '毕业论文（设计）', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/,
  case course_class.department_id
    when '13' then 51 -- 设计学院
    else 50
  end
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and (course.name like '毕业论文%'
  or course.name like '毕业设计%'
  or course.name like '辅修毕业论文%'
  or course.name like '毕业创作'
  or course.name like '毕业作品%')
union all -- 其他论文
select distinct course_class.department_id, course.id, '其他论文', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/, 50
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name in ('学年论文')
union all -- 实习
select distinct course_class.department_id, course.id, '分散实习', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/,
  case course.name
    when '境外实习' then 44 /*分散实习*/
    else 40
  end
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and (course.name like '%实习%'
  or course.name like '%见习%'
  or course.name like '%工作坊%'
  or course.name like '专业创新作品%'
  or course.name like '专业素质养成%'
  or course.name like '专业素质拓展%'
  or course.name like '专业拓展%'
  or course.name like '%专业专题研习%')
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程项目工作量设置
insert into tm_load.course_item_workload_settings(department_id, course_item_id, category, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
select distinct course_class.department_id, course_item.id, '实验', 2 /*正常*/, 1 /*排课*/ , 3 /*实验课*/, 22 /*综合性实验*/
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20191
and course_item.name like '实验'
union all
select distinct course_class.department_id, course_item.id, '体育俱乐部', 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 99 /*其他*/
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20191
and department_id = '92' and course_item.name like '%俱乐部%'
union all
select distinct course_class.department_id, course_item.id, '校体育队', 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 99 /*其他*/
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20191
and department_id = '92' and course_item.name like '%队%'
union all
select distinct course_class.department_id, course_item.id, '阳光长跑', 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 99 /*其他*/
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20191
and department_id = '92' and course_item.name like '阳光长跑%'
order by 1, 2
on conflict(department_id, course_item_id) do update set
category = excluded.category,
workload_type = excluded.workload_type,
workload_mode = excluded.workload_mode,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程项目查询
select course_class.department_id, course.id as course_id, course.name as course_name,
  course_item.id as course_item_id, course_item.name as course_item_name,
  array_to_string(array_agg(distinct task.code order by task.code desc), ',') as task_codes
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
join ea.course on course_item.course_id = course.id
where term_id >= 20191
and course_class.department_id not in ('15')
and (course_class.department_id, course_item.id) not in (
  select department_id, course_item_id
  from tm_load.course_item_workload_settings
)
-- and (course_class.department_id, course.id) not in (
--     select department_id, course_id
--     from tm_load.course_workload_settings
-- )
and course.name <> course_item.name
and course_item.name <> '理论'
group by course_class.department_id, course.id, course.name, course_item.id, course_item.name;

-- 级联删除
alter table tm_load."workload_task_teacher"
drop constraint "fkibohyn6osen4jndq0x2j0kkv9",
add constraint "fkibohyn6osen4jndq0x2j0kkv9"
  foreign key ("workload_task_id")
  references "workload_task"(id)
  on delete cascade;

alter table tm_load."workload_task_schedule"
drop constraint "fk4n6qejf7v6qbkafxbcoj7i52y",
add constraint "fk4n6qejf7v6qbkafxbcoj7i52y"
  foreign key ("workload_task_id")
  references "workload_task"(id)
  on delete cascade;