-- tm@bnuz/tm
-- 人事数据
create table tm_load.human_resource_teacher (
  id text primary key,
  name text,
  department text,
  sex text,
  birthday date,
  age integer,
  country text,
  date_entrolled text,
  employment_mode text,
  employment_status text,
  academic_degree text,
  post_type text,
  technical_Post text,
  teacher_id text
);
comment on column tm_load.human_resource_teacher.id is '职工号';
comment on column tm_load.human_resource_teacher.name is '姓名';
comment on column tm_load.human_resource_teacher.department is '所在单位';
comment on column tm_load.human_resource_teacher.sex is '性别';
comment on column tm_load.human_resource_teacher.birthday is '出生日期';
comment on column tm_load.human_resource_teacher.age is '年龄';
comment on column tm_load.human_resource_teacher.country is '国家(地区)';
comment on column tm_load.human_resource_teacher.date_entrolled is '来校年月';
comment on column tm_load.human_resource_teacher.employment_mode is '用人形式';
comment on column tm_load.human_resource_teacher.employment_status is '当前状态';
comment on column tm_load.human_resource_teacher.academic_degree is '最高学位';
comment on column tm_load.human_resource_teacher.post_type is '岗位类别';
comment on column tm_load.human_resource_teacher.technical_Post is '专业技术职务';
comment on column tm_load.human_resource_teacher.teacher_id is '教务职工号';

\copy tm_load.human_resource_teacher(id, name, department, sex, birthday, age, country, date_entrolled, employment_mode, employment_status, academic_degree, post_type, technical_Post) from 'bnuz-formal-teacher.csv' with header csv;

-- 更新教师职工号
update tm_load.human_resource_teacher
set teacher_id = (select id from ea.teacher where human_resource_number = human_resource_teacher.id);

-- 人事数据
\copy tm_load.human_resource_teacher_import(id, name, department, sex, birthday, age, country, date_entrolled, employment_mode, employment_status, academic_degree, post_type, technical_post) from 'hr-info.csv' csv header;

insert into tm_load.human_resource_teacher(id, name, department, sex, birthday, age, country, date_entrolled,
  employment_mode, employment_status, academic_degree, post_type, technical_post)
select id, name, department, sex, birthday, age, country, date_entrolled,
  employment_mode, employment_status, academic_degree, post_type, technical_post
from tm_load.human_resource_teacher_import
on conflict(id) do update set
id = excluded.id,
name = excluded.name,
department = excluded.department,
sex = excluded.sex,
birthday = excluded.birthday,
age = excluded.age,
country = excluded.country,
date_entrolled = excluded.date_entrolled,
employment_mode = excluded.employment_mode,
employment_status = excluded.employment_status,
academic_degree = excluded.academic_degree,
post_type = excluded.post_type,
technical_post = excluded.technical_post;

with teacher_map as (
    select a.id tid, b.id hid from ea.teacher a join tm_load.human_resource_teacher b on a.human_resource_number=b.id
), duplicate_map as (
    select * from teacher_map where hid in (select hid from teacher_map group by hid having count(*) > 1) 
), duplicate_term as (
    select hid, tid, max(term_id) as max_term
    from ea.av_task_schedule a
    join duplicate_map b on a.teacher_id = b.tid
    group by hid, tid
), unique_teacher as (
    select distinct on(hid) hid, tid, max_term
    from duplicate_term
    order by hid, max_term desc
), unique_map as (
    select hid, tid from unique_teacher
    union
    select hid, tid from teacher_map where hid not in (select hid from unique_teacher)
)
update tm_load.human_resource_teacher a
set teacher_id = unique_map.tid
from unique_map
where unique_map.hid = a.id;

-- 双语课
create table tm_load.tmp_foreign_language_course_class(
    term_id integer,
    department text,
    teacher_name text,
    course_name text,
    type text,
    credit numeric(3,1),
    property text,
    task_code text
);

insert into tm_load.tmp_foreign_language_course_class
(term_id, department, teacher_name, course_name, credit, property, type, task_code) values
(20192,'设计学院','潘绍华','设计基础Ⅲ','3','专业核心课','双语教学','(2019-2020-2)-13114260-13185-1,(2019-2020-2)-13114260-13185-2'),
;

-- 检查选课课号
with normal as (
  select term_id, department, teacher_name, course_name, type, credit, property, unnest(regexp_split_to_array(task_code, ',')) as code
  from tmp_foreign_language_course_class
)
select * from normal where code not in (select code from ea.task);

-- 检查课程名称、学分
with normal as (
  select term_id, department, teacher_name, course_name, type, credit, property, unnest(regexp_split_to_array(task_code, ',')) as code
  from tmp_foreign_language_course_class
)
select a.*, (select course_name||'|'||credit from ea.av_course_class where code = a.code) as by_task,
  array((select course_name||'|'||credit from ea.av_course_class where term_id = 20192 and teacher_name = a.teacher_name)) as other_class
from normal a where (teacher_name, course_name, credit) not in (
    select teacher_name, course_name, credit from ea.av_course_class where term_id=20192
) and term_id=20192;

-- 插入任务工作量设置表
insert into tm_load.task_workload_settings(task_id, instructional_mode_id)
with normal as (
    select a.*, unnest(regexp_split_to_array(a.task_code, ',')) as code
    from tm_load.tmp_foreign_language_course_class a
)
select task.id, case normal.type
    when '双语教学' then 30
    when '外语教学' then 31
  end as instructional_mode_id
from normal
left join ea.task on task.code = normal.code
where term_id = 20192
on conflict (task_id) do update set
instructional_mode_id = excluded.instructional_mode_id;

create table tm_load.task_workload_settings(
    task_id uuid primary key references ea.task,
    instructional_mode_id integer references tm_load.instructional_mode
);

-- 工作量调整
with task_teacher_correction as (
    select teacher_id, t.id as workload_task_id, c.code, correction::numeric(6,2) as correction from (values
        ('04086','(2019-2020-1)-04112241-04086-1,(2019-2020-1)-04112241-04105-1','3.24'),
        ('04086','(2019-2020-1)-04112241-04105-1','-9.6'),
        ('04105','(2019-2020-1)-04112241-04086-1,(2019-2020-1)-04112241-04105-1','18')
    ) as c (teacher_id, code, correction)
    join tm_load.workload_task t on t.code = c.code
)
update tm_load.workload_task_teacher a
set correction = c.correction
from task_teacher_correction c
where a.workload_task_id = c.workload_task_id and a.teacher_id = c.teacher_id;

-- 法律诊所
update tm_load.workload_task_teacher a
set correction = 51
from tm_load.workload_task b
where b.course_name = '法律诊所' and a.workload_task_id = b.id and original_workload = 0;

-- 专业工作量设置（理工外语/文法经管艺体）
insert into tm_load.subject_workload_settings(subject_id, class_size_type_id)
select distinct subject.id, case
  when subject.id = '0504' then 7 -- 留学生
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

-- 课程工作量设置-公共课
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
select '93', id, '政治实践课', null, 2 /*正常*/, 3 /*学时*/, 5 /*政治课*/, 66 /*0.6*/
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
select '93', course.id, '政治理论课', null, 1 /*不计*/, 3 /*学时*/, 9 /*常量*/, 66 /*0.6*/
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
select '94', course.id, '军事教育', null, 0 /*排除*/, 1 /*排课*/, 9 /*常量*/, 10 /*理论课*/
from ea.course
where department_id = '94' and id like '9411%'
union all -- 排除-北理共享
select course_class.department_id, course.id, '北理共享', null, 0 /*排除*/, 1 /*排课*/, 9 /*常量*/, 99 /*其他*/
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.task on task.course_class_id = course_class.id
join ea.task_schedule on task_schedule.task_id = task.id
where course_class.term_id >= 20191
and task_schedule.place_id like 'B%'
union all -- 教授论坛
select course_class.department_id, course.id, '教授论坛', null, 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 99
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name like '%教授论坛'
union all -- 不计慈善
select distinct course_class.department_id, course.id, '慈善中心', null::numeric(3,2), 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 99 /*其他*/
from ea.course_class
join ea.course on course_class.course_id = course.id
join ea.course_class_program on course_class_program.course_class_id = course_class.id
join ea.program on course_class_program.program_id = program.id
join ea.major on program.major_id = major.id
where major.subject_id = '0706'
and course.id like '50%'
and course_class.term_id >= 20191
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
  or course.name like '毕业作品%'
)
union all -- 实习
select distinct course_class.department_id, course.id, '分散实习', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/,
  case course.name
    when '境外实习' then 44 /*暑期实习1.2*/
    when '金工实习' then 43 /*集中实习0.8*/
    else 40
  end
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and (course.name like '%实习%'
    and course.name not like '环境化学实习' -- 不动产(排课)
  or course.name like '%见习%'
)
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程工作量设置-实践课
insert into tm_load.course_workload_settings(department_id, course_id, category, parallel_ratio, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
select distinct course_class.department_id, course.id, '实践教学', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/, 62 /*0.2*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and (course.name like '%工作坊%'
    and course.name not like 'EAP工作坊%' -- 教育(排课)
    and course.name not like '读书研习工作坊%' -- 文学(排课)
  or course.name like '专业创新作品%'
  or course.name like '专业素质养成%'
  or course.name like '专业拓展%'
  or course.name like '专业综合实践' and course.id = '21111590' -- 运休
)
union all -- 文学
select distinct course_class.department_id, course.id, '社会调查', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/, 62 /*0.2*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name like '中国社会调查%'
union all -- 教育
select '07', id, '教育实践', null, 2 /*正常*/, 3 /*学时*/, 3 /*实验课*/, 68 /*0.8*/
from ea.course
where course.name = '表达性艺术治疗实践' and credit = 2
or course.name like '中小学教育实务%' and credit = 2
union all -- 教育
select '07', id, '教育实践', null, 2 /*正常*/, 3 /*学时*/, 1 /*文法经管*/, 70 /*1.0*/
from ea.course
where course.name like '幼儿园教育实务'
or course.name like '应用心理学专业专题研习%' and credit = 1
or course.name like '学前教育专业专题研习%' and credit = 1
or course.name like '教育专业专题研习%' and credit = 1
union all -- 法政
select distinct course_class.department_id, course.id, '学年论文', null::numeric(3,2), 2 /*正常*/, 2 /*学生*/, 9 /*常量*/, 62 /*0.2*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name in ('学年论文') and course_class.department_id = '10'
union all -- 法政
select distinct course_class.department_id, course.id, '法政实践', null::numeric(3,2), 2 /*正常*/, 3 /*学时*/, 9 /*常量*/, 66 /*0.6*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name in ('社会调研', '专业素质拓展', '志愿服务') and course_class.department_id = '10'
union all -- 不动产
select distinct course_class.department_id, course.id, '实践教学', null::numeric(3,2), 2 /*正常*/, 3 /*学时*/, 9 /*常量*/, 70 /*1.0*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name in ('国土整治实务') and course_class.department_id = '04'
union all -- 设计
select distinct course_class.department_id, course.id, '设计考察', null::numeric(3,2), 2 /*正常*/, 3 /*学时*/, 4 /*小班*/, 70 /*1.0*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name in ('设计考察与实践') and course_class.department_id = '13'
union all -- 国商
select distinct course_class.department_id, course.id, '沙盘模拟', null::numeric(3,2), 2 /*正常*/, 3 /*学时*/, 3 /*实验*/, 70 /*1.0*/
from ea.course_class
join ea.course on course_class.course_id = course.id
where course_class.term_id >= 20191
and course.name in ('ERP沙盘模拟') and course_class.department_id = '20'
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程工作量设置-运休小班
insert into tm_load.course_workload_settings(department_id, course_id, category, parallel_ratio, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
select '21', course.id, '运休小班', null::numeric(3,2), 2 /*正常*/, 1 /*排课*/, 4 /*小班*/, 10 /*理论课*/
from ea.course
where id in (
  '21110290', '21110390', '21110451', '21110461', '21110471', '21110480',
  '21110760', '21111280', '21111350', '21111430', '21111460', '21111490',
  '21111520', '21111540', '21190390', '21190450', '21190510', '21190520',
  '21190530', '21190550', '21190560', '21190570', '21190580', '21190620',
  '21190640'
)
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程工作量设置-艺传小班
insert into tm_load.course_workload_settings(department_id, course_id, category, parallel_ratio, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
select '08', course.id, '艺传小班', null::numeric(3,2), 2 /*正常*/, 1 /*排课*/, 4 /*小班*/, 10 /*理论课*/
from ea.course
where id in (
  '08110950', '08111571', '08112470', '08113370', '08113570', '08113580',
  '08113830', '08113840', '08113890', '08114180', '08114230', '08114530',
  '08114560', '08114680', '08114690', '08114700', '08114720', '08120021',
  '08120033', '08120701', '08121021', '08121081', '08121661', '08129330',
  '08129360', '08130165', '08130172', '08130181', '08130221', '08130230',
  '08130411', '08130712', '08130720', '08131010', '08131060', '08131182',
  '08131260', '08131270', '08131420', '08131430', '08191671', '08191712',
  '08192240', '08192290', '08192310', '08192380', '08192600', '08192660',
  '08192810'
)
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程工作量设置-不动产小班
insert into tm_load.course_workload_settings(department_id, course_id, category, parallel_ratio, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
select '04', course.id, '不动产小班', null::numeric(3,2), 2 /*正常*/, 1 /*排课*/, 4 /*小班*/, 10 /*理论课*/
from ea.course
where id in (
  '04112221', '04112531', '04112580', '04112820', '04112831', '04112870',
  '04112890', '04113491', '04113690', '04113691', '04113810', '04191531',
  '04191640', '04191650'
)
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程工作量设置-教育小班
insert into tm_load.course_workload_settings(department_id, course_id, category, parallel_ratio, workload_type, workload_mode, class_size_type_id, instructional_mode_id)
select '07', course.id, '教育小班', null::numeric(3,2), 2 /*正常*/, 1 /*排课*/, 4 /*小班*/, 10 /*理论课*/
from ea.course
where id in (
  '07193110'
);
order by 1, 2
on conflict(department_id, course_id) do update set
category = excluded.category,
parallel_ratio = excluded.parallel_ratio,
workload_mode = excluded.workload_mode,
workload_type = excluded.workload_type,
class_size_type_id = excluded.class_size_type_id,
instructional_mode_id = excluded.instructional_mode_id;

-- 课程工作量设置-设计小班
select '13', course.id, '设计小班', null::numeric(3,2), 2 /*正常*/, 1 /*排课*/, 4 /*小班*/, 10 /*理论课*/
from ea.course
where id in (
  '04112541', '08110351', '08110401', '08110420', '08110440', '08111310',
  '08111440', '08111530', '08111640', '08111650', '08111950', '08112410',
  '08112421', '08120072', '08121310', '08130850', '08191380', '08191410',
  '13110064', '13110073', '13110130', '13110150', '13110210', '13110260',
  '13110331', '13110363', '13110391', '13110460', '13110461', '13110470',
  '13110573', '13110600', '13110670', '13110671', '13110672', '13110711',
  '13110720', '13110800', '13110832', '13110850', '13110861', '13110862',
  '13110910', '13111010', '13111011', '13111110', '13111111', '13111113',
  '13111120', '13111121', '13111132', '13111211', '13111222', '13111250',
  '13111280', '13111290', '13111431', '13111480', '13111520', '13111521',
  '13111790', '13111851', '13111852', '13112060', '13112070', '13112080',
  '13112111', '13112120', '13112122', '13112160', '13112161', '13112162',
  '13112470', '13112480', '13112502', '13112511', '13112520', '13112530',
  '13112550', '13112580', '13112591', '13112611', '13112620', '13112640',
  '13112690', '13112691', '13112692', '13112700', '13112710', '13112711',
  '13112780', '13112790', '13112800', '13112810', '13112821', '13112980',
  '13113030', '13113100', '13113111', '13113120', '13113121',
  '13113130', '13113131', '13113140', '13113170', '13113171', '13113180',
  '13113270', '13113290', '13113370', '13113410', '13113461', '13113470',
  '13113502', '13113521', '13113630', '13113640', '13113650', '13113700',
  '13113710', '13113770', '13113780', '13113810', '13113840', '13113850',
  '13113851', '13113890', '13113901', '13113910', '13113951', '13113960',
  '13114000', '13114010', '13114030', '13114090', '13114100', '13114110',
  '13114120', '13114130', '13114140', '13114150', '13114160', '13114170',
  '13114180', '13114260', '13114290', '13114300', '13114380', '13114391',
  '13114410', '13114411', '13114440', '13114450', '13114470', '13114490',
  '13114520', '13114530', '13114550', '13114590', '13114600', '13114610',
  '13114611', '13114621', '13114650', '13114670', '13114680', '13114710',
  '13114720', '13114730', '13114740', '13114750', '13114760', '13114770',
  '13114780', '13114790', '13114800', '13114810', '13114820', '13114830',
  '13114840', '13114850', '13114880', '13114890', '13114900', '13114910',
  '13114920', '13114940', '13114950', '13114960', '13114970', '13114980',
  '13115020', '13115030', '13130101', '13130150', '13130170', '13130201',
  '13130280', '13130291', '13130292', '13130310', '13130330', '13130522',
  '13130530', '13130540', '13190050', '13190051', '13190220', '13190350',
  '13190640', '13190641', '13190701', '13190720', '13190780', '13190840',
  '13190860', '13190920', '13191000', '13191020', '13191070', '13191090',
  '13191130', '13191150', '13191160', '13191240', '13191300', '13191400',
  '13191470', '13191490', '13191510', '13191520', '13191551', '13191700',
  '13191720', '13191740', '13191770', '13191780', '13191790', '13191800',
  '13191810', '13191820', '13191850', '13191930', '13191960', '13191970',
  '13191980', '20110760', '61101440'
)
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
select distinct course_class.department_id, course_item.id, '体育俱乐部', 2 /*正常*/, 2 /*学生*/, 9 /*常量*/, 62 /*0.2*/
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20191
and department_id = '92' and course_item.name like '%俱乐部%'
union all
select distinct course_class.department_id, course_item.id, '校体育队', 2 /*正常*/, 2 /*学生*/, 9 /*常量*/, 62 /*0.2*/
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
union all
select distinct course_class.department_id, course_item.id, '弓道', 1 /*不计*/, 1 /*排课*/, 9 /*常量*/, 99 /*其他*/
from ea.course_class
join ea.task on task.course_class_id = course_class.id
join ea.course_item on task.course_item_id = course_item.id
where term_id >= 20191
and department_id = '92' and course_item.name like '弓道_'
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
