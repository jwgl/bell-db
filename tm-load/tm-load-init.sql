-- 创建架构
create schema tm_load authorization tm;

insert into tm_load.department_settings(department_id, creator_id, checker_id) values ('01', '01035', '01039');

-- 教学形式类别
insert into tm_load.task_instructional_type(name, ratio, editable) values('全外语课', 1.5, false);
insert into tm_load.task_instructional_type(name, ratio, editable) values('双语课', 1.2, false);
insert into tm_load.task_instructional_type(name, ratio, editable) values('普通实验', 0.8, true);
insert into tm_load.task_instructional_type(name, ratio, editable) values('验证性实验', 1.0, true);
insert into tm_load.task_instructional_type(name, ratio, editable) values('综合性实验', 1.2, true);

-- 班级规模类别
insert into tm_load.class_size_type(id, name, category) values (1, '通识选修课', 'property');
insert into tm_load.class_size_type(id, name, category) values (2, '政治理论课', 'course');
insert into tm_load.class_size_type(id, name, category) values (3, '艺术小班课', 'course');
insert into tm_load.class_size_type(id, name, category) values (4, '实验课', 'course item');
insert into tm_load.class_size_type(id, name, category) values (5, '文法经管艺体', 'subject');
insert into tm_load.class_size_type(id, name, category) values (6, '理工外语', 'subject');
insert into tm_load.class_size_type(id, name, category) values (9, '常量班型', 'constant');

-- 通识选修课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(11, 1, 0,   100,  1.0),
(12, 1, 101, 125,  1.1),
(13, 1, 126, 150,  1.2),
(14, 1, 151, 175,  1.3),
(15, 1, 176, 200,  1.4),
(16, 1, 201, 9999, 1.5);

-- 政治理论课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(21, 2, 0,   120,  1.0),
(22, 2, 121, 125,  1.1),
(23, 2, 126, 150,  1.2),
(24, 2, 151, 180,  1.3),
(25, 2, 181, 210,  1.4),
(26, 2, 211, 9999, 1.5);

-- 艺术小班课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(31, 3, 0,   15,   0.6),
(32, 3, 16,  24,   0.8),
(33, 3, 25,  30,   1.0),
(34, 3, 31,  40,   1.1),
(35, 3, 41,  9999, 1.2);

-- 实验课
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(41, 4, 0,   50,   1.0),
(42, 4, 51,  65,   1.1),
(43, 4, 66,  80,   1.2),
(44, 4, 81,  95,   1.3),
(45, 4, 96,  9999, 1.4);

-- 文法经管艺体
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(51, 5, 0,   60,   1.0),
(52, 5, 61,  80,   1.1),
(53, 5, 81,  9999, 1.2);

-- 理工外语
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(61, 6, 0,   50,   1.0),
(62, 6, 51,  65,   1.1),
(63, 6, 66,  9999, 1.2);

-- 常量班型
insert into tm_load.class_size_ratio(id, type_id, lower_bound, upper_bound, ratio) values
(91, 9, 0,   9999, 1.0);

-- 政治理论课
insert into tm_load.course_class_size_type(course_id, type_id)
select id, 2
from ea.course
where id like '93%'
and id in (
	select course_id
	from ea.course_class
  where term_id between 20161 and 20192
) order by 1;

-- 理工外语/文法经管艺体
insert into tm_load.subject_class_size_type(subject_id, type_id)
select distinct subject.id, case
  when subject.id like '15%' or discipline.name in ('理学', '工学') then 6
  else 5 end as class_size_type
from ea.discipline
join ea.subject on subject.degree_id = discipline.id
left join ea.major on major.subject_id = subject.id
where major.id is not null
and major.grade between 2012 and 2018
order by 1;

-- 艺术小班课
select dept.name, s.name, c.id, c.name, c.credit,
  array_agg(distinct property.name),
  array_agg(distinct m.grade order by m.grade)
from ea.course c
join ea.program_course pc on c.id = pc.course_id
join ea.program p on p.id = pc.program_id
join ea.major m on m.id = p.major_id
join ea.subject s on s.id = m.subject_id
join ea.discipline d on s.degree_id = d.id
join ea.department dept on dept.id = m.department_id
join ea.property on pc.property_id = property.id
where d.name = '艺术学'
and m.grade between 2015 and 2018
and pc.property_id not in (1, 2)
and c.name not like '%英语%'
group by dept.name, s.name, c.id, c.name, c.credit
order by 1, 2, 3;

-- 英语/体育平行班系数
insert into tm_load.course_parallel_ratio(course_id, ratio)
select distinct c.id, 0.72
from ea.course_class cc
join ea.course c on c.id = cc.course_id
where cc.property_id = 1
and substring(course_id, 1, 4) in ('1511', '9211')
and term_id >= 20161
union all
select id, 0.72 -- 商学部大学外语
from ea.course where id like '031100_1'
order by 1;

-- 教学任务工作量修正
insert into tm_load.task_workload_settings(task_id, type, value, note)
select id, 0 as type, 0 as value, '错误任务' as note
from ea.task
where code in (
  '(2016-2017-1)-15110012-15065-2',
  '(2016-2017-1)-15110012-15065-3',
  '(2016-2017-2)-15112220-15004-2',
  '(2017-2018-2)-93110091-93067-1'
)
on conflict(task_id) do update set
type = excluded.type,
value = excluded.value;

insert into tm_load.task_workload_correction(task_id, teacher_id, type, value, note)
select id, teacher_id, 4 as type, student_count as value, '测试学生分配' || teacher_id as note
from ea.task
cross join (values
  ('18001', 10),
  ('18002', 20),
  ('18003', 30),
  ('18004', 40)
) as teacher_student_count (teacher_id, student_count)
where task.code = '(2018-2019-1)-61110295-18030-1'
union all
select id, teacher_id, 3 as type, student_count as value, '测试课时分配' || teacher_id as note
from ea.task
cross join (values
  ('20013', 10),
  ('20014', 20)
) as teacher_student_count (teacher_id, student_count)
where task.code in ('(2018-2019-1)-06111180-06028-3', '(2018-2019-1)-06111180-06028-4')
on conflict(task_id, teacher_id) do update set
type = excluded.type,
value = excluded.value,
note = excluded.note;

-- 课程工作量设置
insert into tm_load.course_workload_settings(department_id, course_id, type, category, upper_bound, ratio)
select '77', '77100000', 0, '研究生', 0, 0
union all
select '94', course.id, 0, '军事教育', 0, 0
from ea.course
where name in ('军事教育')
union all
select '93', course.id, 1, '政治课', 0, 0
from ea.course
where name in ('思想道德修养与法律基础（实践）', '形势与政策')
union all
select distinct course_class.department_id, course.id, 4, '毕业论文或设计', 9999,
  case course_class.department_id
    when '13' then 0.7 -- 设计学院
    else 0.5
  end as ratio
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20161
and (course.name like '毕业论文%' or course.name like '毕业设计%' or course.name like '辅修毕业论文%' or
  course.name like '毕业创作' or course.name like '毕业作品%')
union all
select distinct course_class.department_id, course.id, 4, '分散实习', 30, 0.2
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20161
and (course.name = '毕业实习' or course.name='专业实习' or course.name like '专业创新作品%' or course.name like '专业素质养成%'
  or course.name like '导师工作坊')
on conflict(department_id, course_id) do update set
type = excluded.type,
category = excluded.category,
upper_bound = excluded.upper_bound,
ratio = excluded.ratio;

-- 课程项目设定
select course_class.department_id, course.id as course_id, course.name as course_name,
  course_item.id as course_item_id, course_item.name as course_item_name,
  array_to_string(array_agg(distinct task.code order by task.code desc), ',') as task_codes
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
join ea.course on course_item.course_id = course.id
where term_id >= 20161
and course_class.department_id not in ('15')
and (course_class.department_id, course_item.id) not in (
  select department_id, course_item_id
  from course_item_workload_settings
)
and course.name <> course_item.name
group by course_class.department_id, course.id, course.name, course_item.id, course_item.name;

insert into course_item_workload_settings(department_id, course_item_id, type, category, upper_bound, ratio)
select distinct course_class.department_id, course_item.id as course_item_id, 1 as type, '体育俱乐部' as category, 0 as upper_bound, 1.0 as ratio
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20161
and department_id = '92' and course_item.name like '%俱乐部%'
union all
select distinct course_class.department_id, course_item.id as course_item_id, 1 as type, '校体育队' as category, 0 as upper_bound, 1.0 as ratio
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20161
and department_id = '92' and course_item.name like '%队%'
union all
select distinct course_class.department_id, course_item.id as course_item_id, 1 as type, '阳光长跑' as category, 0 as upper_bound, 1.0 as ratio
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20161
and department_id = '92' and course_item.name like '阳光长跑%'
order by 1, 2
on conflict(department_id, course_item_id) do update set
type = excluded.type,
category = excluded.category,
upper_bound = excluded.upper_bound,
ratio = excluded.ratio;
