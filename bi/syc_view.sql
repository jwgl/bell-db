-- 考试试卷编号表
create or replace view exam as
select
xkkh as course_class_id,
sjbh as id,
fltj as id_rule,
ksxn as xn,
ksxq as xq
from zfxfzb.ks_sjbhb;
comment on column exam.id is '试卷编号';
comment on column exam.course_class_id is '教学班id';
comment on column exam.xn is '学年';
comment on column exam.xq is '学期';
comment on column exam.id_rule is '试卷编号规则';
-- 考试时间表
create or replace view exam_schedule as
select 
kssj as id,
kcmc as course_name,
xn,
xq,
nj as type,
sjbh as exam_id,
kcdm as course_id
from zfxfzb.kssjjsb;
comment on column exam_schedule.id is '时间表id';
comment on column exam_schedule.course_name is '课程名称';
comment on column exam_schedule.xn is '学年';
comment on column exam_schedule.xq is '学期';
comment on column exam_schedule.course_id is '课程编号';
comment on column exam_schedule.type is '补考/统一';
comment on column exam_schedule.exam_id is '试卷编号';

-- 考试时间段设定表
create or replace view exam_time_schedule as
select 
xn,
xq,
nj as type,
kssj as id,
ksjtsj as detail,
xh as idx
from zfxfzb.kssjsdb;
comment on column exam_time_schedule.id is '时间表id';
comment on column exam_time_schedule.detail is '具体时间';
comment on column exam_time_schedule.xn is '学年';
comment on column exam_time_schedule.xq is '学期';
comment on column exam_time_schedule.type is '补考/统一';
comment on column exam_time_schedule.idx is '序号';

-- 考试时间地点安排表
create or replace view exam_timeslot_schedule as
select
xn,
xq,
nj as type,
kssj as id,
ksjtsj as detail,
kcmc as course_name,
xkkh as course_class_id,
sjbh as exam_id,
jsmc as place,
skjsxm as teacher_name,
skjszgh as teacher_id,
jsbh as place_id,
kcrs as course_student_count,
zkcrs as course_student_total,
sjrs as real_student_count,
jkjszgh as observer_id,
jkjsxm	as observer_name,
kkxy as course_department_name,
jkjs1 as obser_time1,
jkjs2 as obser_time2,
jkjs3 as obser_time3,
jkjs4 as obser_time4,
jk as observer_name_and_id
from zfxfzb.kssjddapb;
comment on column exam_timeslot_schedule.id is '时间表id';
comment on column exam_timeslot_schedule.xn is '学年';
comment on column exam_timeslot_schedule.xq is '学期';
comment on column exam_timeslot_schedule.type is '补考/统一';
comment on column exam_timeslot_schedule.detail is '具体时间';
comment on column exam_timeslot_schedule.course_name is '课程名称';
comment on column exam_timeslot_schedule.course_class_id is '教学班id';
comment on column exam_timeslot_schedule.exam_id is '试卷编号';
comment on column exam_timeslot_schedule.place is '考试地点';
comment on column exam_timeslot_schedule.place_id is '考试地点id';
comment on column exam_timeslot_schedule.teacher_name is '主考老师';
comment on column exam_timeslot_schedule.teacher_id is '主考老师id';
comment on column exam_timeslot_schedule.course_student_count is '课程人数';
comment on column exam_timeslot_schedule.course_student_total is '课程总人数';
comment on column exam_timeslot_schedule.real_student_count is '实际人数';
comment on column exam_timeslot_schedule.observer_id is '监考老师id';
comment on column exam_timeslot_schedule.observer_name is '监考老师';
comment on column exam_timeslot_schedule.course_department_name is '开课单位';
comment on column exam_timeslot_schedule.obser_time1 is '监考时间1';
comment on column exam_timeslot_schedule.jk is '监考老师姓名及id';

-- 教学任务表
create or replace view task as 
select
xn,
xq,
kcdm as course_id,
kcmc as course_name,
xf as credit,
zxs as section_of_week,
khfs as test_type,
ksfs as exam_type,
kssjd as exam_section,
kcxz as course_property,
kclb as course_type,
kkxy as course_department_name,
jszgh as teacher_id,
jsxm as teacher_name,
xkkh as course_class_id,
skdd as place,
sksj as timeslot,
yxrs as class_student_count,
jxjhh as scheme_id,
jsz as end_week,
bjmc as course_class_name,
qsjsz as week_section,
zymc as subject_name,
zyfx as subject_direction,
cdbs as place_type,
lrsz as score_status,
tjqr as score_checked
from zfxfzb.jxrwbview;
comment on column task.xn is '学年';
comment on column task.xq is '学期';
comment on column task.course_id is '课程编号';
comment on column task.course_name is '课程名称';
comment on column task.credit is '学分';
comment on column task.section_of_week is '每周学时';
comment on column task.test_type is '考核方式';
comment on column task.exam_type is '考试方式';
comment on column task.exam_section is '考试学段';
comment on column task.course_property is '课程性质';
comment on column task.course_type is '课程分类：实践环节，必修课，选修课';
comment on column task.course_department_name is '开课单位';
comment on column task.teacher_id is '教师工号';
comment on column task.teacher_name is '教师姓名';
comment on column task.course_class_id is '教学班id';
comment on column task.place is '上课地点';
comment on column task.timeslot is '上课时间';
comment on column task.class_student_count is '学生人数';
comment on column task.scheme_id is '教学计划号';
comment on column task.course_class_name is '班级名称';
comment on column task.week_section is '起始结束周';
comment on column task.subject_name is '专业名称';
comment on column task.subject_direction is '专业方向';
comment on column task.place_type is '场地标识';
comment on column task.score_status is '成绩录入状态';
comment on column task.score_checked is '成绩审核状态';

-- 成绩
create or replace view score as 
select distinct
c.course_id,
c.course_name,
c.course_class_id,
c.teacher_id,
c.teacher_name,
c.course_student_count,
c.course_department_name,
c.course_property,
c.score_checked,
a.xn,
a.xq,
a.xh as student_id,
a.zscj as score_number,
to_number(nvl(to_char(b1.dycj), a.pscj)) as score_usual,
to_number(nvl(to_char(b2.dycj), a.qzcj)) as score_mid,
to_number(nvl(to_char(b3.dycj), a.qmcj)) as score_last
from zfxfzb.cjb a
join task c on a.xkkh   = c.course_class_id
left join zfxfzb.cjdzb b1 on a.pscj    = b1.cj
left join zfxfzb.cjdzb b2 on a.qzcj   = b2.cj
left join zfxfzb.cjdzb b3 on a.qmcj   = b3.cj;
comment on column score.xn is '学年';
comment on column score.xq is '学期';
comment on column score.student_id is '学号';
comment on column score.course_class_id is '教学班id';
comment on column score.score_number is '折算成绩';
comment on column score.score_usual is '平时成绩';
comment on column score.score_mid is '期中成绩';
comment on column score.score_last is '期末成绩';

select distinct t.xn, t.xq, t.JSXM, t.JSZGH, s.KCMC, t.KKXY, t.YXRS, t.xkkh, t.kcdm, t.kcxz,
s.ZSCJ,s.xm,s.xh, to_number(nvl(TO_CHAR(b1.dycj), s.pscj))pscj, to_number
  (nvl(TO_CHAR(b2.dycj), s.qzcj))qzcj, to_number(nvl(TO_CHAR(b3.dycj), s.qmcj))qmcj
from zfxfzb.cjb s left join zfxfzb.jxrwbview t on s.xkkh=t.xkkh and s.xn=t.xn and s.xq=t.xq
  LEFT JOIN zfxfzb.cjdzb b1 ON s.pscj   = b1.cj
  LEFT JOIN zfxfzb.cjdzb b2 ON s.qzcj   = b2.cj
  LEFT JOIN zfxfzb.cjdzb b3 ON s.qmcj   = b3.cj
where t.xn='2018-2019' and t.xq=1;

-- 本科生学籍信息视图
create or replace view student_info as
select a.xh as student_id,
a.xm as student_name,
a.xb as sex,
a.xy as department_name,
b.tjzydm as subject_id_of_nation,
a.sfzx as at_school,
b.tjzymc as subject_name_of_nation,
a.zydm as subject_id,
a.zymc as subject_name,
a.dqszj as grade,
a.csrq as birthday,
a.zzmm as political_status,
a.mz as nationality,
a.lys as from_province,
a.hkszd as household_address,
a.lydq as from_city,
a.xslb as student_type,
a.xz as length_of_school,
to_date(a.rxrq, 'yyyymmdd') as date_enrolled,
a.cc as academic_level,
a.kslb as candidate_type,
a.ydlb as change_type,
c.xw as academic_degree,
a.sfzh as id_number,
a.ksh as candidate_number,
b1.zylbmc as major_type_2,
b2.xklb as major_type_1,
b2.xkdl as major_type_0,
e.byjr as status_graduated,
to_date(e.byrq, 'yyyymmdd') as date_graduated,
e.ywxw as got_degree,
a.xjzt as enrolled,
b.zylb as major_type_id,
to_date(e.jyrq, 'yyyymmdd') as date_completed
from zfxfzb.xsjbxxb a 
join zfxfzb.zydmb b on a.zydm=b.zydm 
join zfxfzb.zylbdmb b1 on b.zylb=b1.zylbdm
join zfxfzb.xkflb b2 on b.xklb=b2.bh
join zfxfzb.jxjhzyxxb c on a.dqszj||a.zydm=c.jxjhh 
left join zfxfzb.xsjtb d on a.xh=d.xh
left join zfxfzb.bysfzxxb e on a.xh=e.xh
where a.cc='本科' 
--双专业的情况
union all
select 
a.xh,
a.xm,
a.xb,
a.xy,
b.tjzydm,
a.sfzx,
b.tjzymc,
b0.major1,
b.zymc,
a.dqszj,
a.csrq,
a.zzmm,
a.mz,
a.lys,
a.hkszd,
a.lydq,
a.xslb,
a.xz,
a.rxrq,
a.cc,
a.kslb,
a.ydlb,
c.xw,
a.sfzh,
a.ksh,
b1.zylbmc,
b2.xklb,
b2.xkdl,
e.byjr,
to_date(e.byrq, 'yyyymmdd'),
e.ywxw,
a.xjzt,
b.zylb,
to_date(e.jyrq, 'yyyymmdd')
from zfxfzb.xsjbxxb a 
join zfxfzb.zydmb_major2 b0 on a.zydm = b0.zydm
join zfxfzb.zydmb b on b0.major1=b.zydm 
join zfxfzb.zylbdmb b1 on b.zylb=b1.zylbdm
join zfxfzb.xkflb b2 on b.xklb=b2.bh
join zfxfzb.jxjhzyxxb c on a.dqszj||a.zydm=c.jxjhh 
left join zfxfzb.xsjtb d on a.xh=d.xh
left join zfxfzb.bysfzxxb e on a.xh=e.xh
where a.cc='本科' ;
comment on column student_last_5_grade.subject_id_of_nation is '招生专业代码';
comment on column student_last_5_grade.subject_name_of_nation is '招生专业名称';
comment on column student_last_5_grade.student_type is '学生类别：计划内、计划外、港澳台等';
comment on column student_last_5_grade.length_of_school is '学制';
comment on column student_last_5_grade.academic_level is '层次：本科等';
comment on column student_last_5_grade.candidate_type is '考生类别';
comment on column student_last_5_grade.change_type is '学籍异动类别';
comment on column student_last_5_grade.major_type_2 is '专业名称：二级分类';
comment on column student_last_5_grade.major_type_1 is '专业分类：一级分类';
comment on column student_last_5_grade.major_type_0 is '学科分类';
comment on column student_last_5_grade.date_graduated is '毕业结论';
comment on column student_last_5_grade.enrolled is '学籍状态';
comment on column student_last_5_grade.major_type_id is '专业代码';
comment on column student_last_5_grade.got_degree is '有无学位';

-- 近5年学籍信息数据集
with a as (
select xh, xm, ydsj, ydlb, ydjg, ydqcc, ydqsfzx, ydqsznj, ydqxjzt, ydqxz, ydqzxzk, ydqxy, ydqzy, ydqzydm, ydqzyfx, ydqzylb,
z.tjzydm, z.tjzymc, b1.zylbmc, b2.xklb, b2.xkdl, z.zylb as zylb1,
rank()over(PARTITION by xh order by ydsj, czrq) as index1
from zfxfzb.xjydb x join zfxfzb.zydmb z on x.ydqzydm = z.zydm
join zfxfzb.zylbdmb b1 on z.zylb=b1.zylbdm
join zfxfzb.xkflb b2 on z.xklb=b2.bh
where ydsj > '2018-09-25'
),b as (
select 
student_id,
student_name,
sex,
department_name,
subject_id_of_nation,
at_school,
subject_name_of_nation,
subject_id,
subject_name,
grade,
birthday,
political_status,
nationality,
from_province,
household_address,
from_city,
student_type,
length_of_school,
date_enrolled,
academic_level,
candidate_type,
change_type,
academic_degree,
id_number,
candidate_number,
major_type_2,
major_type_1,
major_type_0,
status_graduated,
date_graduated,
enrolled,
major_type_id,
date_completed
from student_info s left join a on s.student_id=a.xh and a.index1=1
where a.xh is null

union all
select
student_id,
student_name,
sex,
a.ydqxy,
a.tjzydm,
a.ydqsfzx,
a.tjzymc,
a.ydqzydm,
a.ydqzy,
a.ydqsznj,
birthday,
political_status,
nationality,
from_province,
household_address,
from_city,
student_type,
a.ydqxz,
date_enrolled,
academic_level,
candidate_type,
change_type,
academic_degree,
id_number,
candidate_number,
a.zylbmc,
a.xklb,
a.xkdl,
status_graduated,
date_graduated,
a.ydqxjzt,
a.zylb1,
date_completed
from student_info s left join a on s.student_id=a.xh and a.index1=1
where a.xh is not null)

-- 某个时点以后学籍异动前的状态
create or replace view student_info_change_before as
select xh, xm, ydsj, ydlb, ydjg, ydqcc, ydqsfzx, ydqsznj, ydqxjzt, ydqxz, ydqzxzk, ydqxy, ydqzy, ydqzydm, ydqzyfx, ydqzylb,
z.tjzydm, z.tjzymc, b1.zylbmc, b2.xklb as major_type_1, b2.xkdl as major_type_0, z.zylb as major_type_id,
rank()over(PARTITION by xh order by ydsj, czrq) as index1
from zfxfzb.xjydb x join zfxfzb.zydmb z on x.ydqzydm = z.zydm
join zfxfzb.zylbdmb b1 on z.zylb=b1.zylbdm
join zfxfzb.xkflb b2 on z.xklb=b2.bh

--原数据集4-12
with a as (
select distinct xh, xm, ydsj, ydlb, ydjg, ydqcc, ydqsfzx, ydqsznj, ydqxjzt, ydqxz, ydqzxzk, ydqxy, ydqzy, ydqzydm, ydqzyfx, ydqzylb,
z.tjzydm, z.tjzymc, b1.zylbmc, b2.xklb, b2.xkdl, z.zylb as zylb1,
rank()over(PARTITION by xh order by ydsj, czrq) as index1
from zfxfzb.xjydb x join zfxfzb.zydmb z on x.ydqzydm = z.zydm
join zfxfzb.zylbdmb b1 on z.zylb=b1.zylbdm
join zfxfzb.xkflb b2 on z.xklb=b2.bh
where ydsj > '2018-09-25'
),b as (select s.*, a.* from STUDENT_LAST_5_GRADE s left join a on s.student_id=a.xh and a.index1=1)
select distinct student_id, student_name, sex, birthday, political_status, nationality, from_province, household_address, from_city, student_type, academic_level,
candidate_type, change_type, academic_degree, id_number, candidate_number, trim(status_graduated) as status_graduated, date_graduated,
case when xh is not null then ydqxy else department_name end as department_name,
case when xh is not null then tjzydm else subject_id_of_nation end as subject_id_of_nation,
case when xh is not null then tjzymc else subject_name_of_nation end as subject_name_of_nation,
case when xh is not null then ydqsfzx else at_school end as at_school,
case when xh is not null then ydqzydm else subject_id end as subject_id,
case when xh is not null then ydqzy else subject_name end as subject_name,
case when xh is not null then ydqsznj else grade end as grade,
case when xh is not null then zylbmc else major_type_2 end as major_type_2,
case when xh is not null then xklb else major_type_1 end as major_type_1,
case when xh is not null then xkdl else major_type_0 end as major_type_0,
case when xh is not null then zylb1 else major_type_id end as major_type_id,
case when xh is not null then ydqxz else length_of_school end as length_of_school,
case when xh is not null then ydqxjzt else enrolled end as enrolled,
(select max(grade) from STUDENT_LAST_5_GRADE) as max_grade
from b

--新数据集
--join毕业生辅助信息表，获取毕业信息
with step1 as (
select a.xh as student_id,
a.xm as student_name,
a.xb as sex,
a.xy as department_name,
a.sfzx as at_school,
a.zydm as subject_id,
a.dqszj as grade,
a.csrq as birthday,
a.zzmm as political_status,
a.mz as nationality,
a.lys as from_province,
a.hkszd as household_address,
a.lydq as from_city,
a.xslb as student_type,
a.xz as length_of_school,
a.rxrq as date_enrolled,
a.cc as academic_level,
a.kslb as candidate_type,
a.ydlb as change_type,
c.xw as academic_degree,
a.sfzh as id_number,
a.ksh as candidate_number,
e.byjr as status_graduated,
e.byrq as date_graduated,
e.ywxw as got_degree,
a.xjzt as enrolled,
e.jyrq as date_completed
from zfxfzb.xsjbxxb a 
join zfxfzb.jxjhzyxxb c on a.dqszj||a.zydm=c.jxjhh 
left join zfxfzb.bysfzxxb e on a.xh=e.xh
),
-- 第二步还原时点的学籍异动前状态
b as (
select distinct xh, xm, ydsj, ydlb, ydjg, ydqcc, ydqsfzx, ydqsznj, ydqxjzt, ydqxz, ydqxy, ydqzy, ydqzydm, ydqzyfx, ydqzylb,
rank()over(PARTITION by xh order by ydsj, czrq) as index1
from zfxfzb.xjydb
where ydsj > '2018-09-25'
), step2 as (
select
student_id,
student_name,
sex,
nvl(b.ydqxy, department_name) as department_name,
nvl(b.ydqsfzx, at_school) as at_school,
nvl(b.ydqzydm, subject_id) as subject_id,
nvl(b.ydqsznj, grade) as grade,
birthday,
political_status,
nationality,
from_province,
household_address,
from_city,
student_type,
nvl(b.ydqxz, length_of_school) as length_of_school,
date_enrolled,
academic_level,
candidate_type,
change_type,
academic_degree,
id_number,
candidate_number,
status_graduated,
date_graduated,
got_degree,
nvl(b.ydqxjzt, enrolled) as enrolled,
date_completed
from step1 left join b on student_id=b.xh and b.index1=1
),

-- 第三步join双专业表获得主专业
step3 as (
select 
student_id,
student_name,
sex,
department_name,
at_school,
nvl(m.major1, subject_id) as subject_id,
grade,
birthday,
political_status,
nationality,
from_province,
household_address,
from_city,
student_type,
length_of_school,
date_enrolled,
academic_level,
candidate_type,
change_type,
academic_degree,
id_number,
candidate_number,
status_graduated,
date_graduated,
got_degree,
enrolled,
date_completed
from step2 left join zfxfzb.zydmb_major2 m on step2.subject_id = m.zydm
)
--第四步join zydmb、zylbdmb、xkflb，获取专业名称、专业类别等
select 
student_id,
student_name,
sex,
department_name,
at_school,
subject_id,
b.zymc as subject_name,
grade,
birthday,
political_status,
nationality,
from_province,
household_address,
from_city,
student_type,
length_of_school,
date_enrolled,
academic_level,
candidate_type,
change_type,
academic_degree,
id_number,
candidate_number,
status_graduated,
to_date(date_graduated, 'yyyymmdd') as date_graduated,
got_degree,
enrolled,
to_date(date_completed, 'yyyymmdd') as date_completed,
b1.zylbmc as major_type_2,
b2.xklb as major_type_1,
b2.xkdl as major_type_0,
b.zylb as major_type_id
from step3 join zfxfzb.zydmb b on subject_id = b.zydm
join zfxfzb.zylbdmb b1 on b.zylb=b1.zylbdm
join zfxfzb.xkflb b2 on b.xklb=b2.bh
--刨去距离入学时间超过8年的学生
where date_enrolled is not null
and to_date(to_char(to_number(replace(date_enrolled, '-', '')) + 80000, '00000000'), 'yyyymmdd') > current_date
and enrolled = '有'
--刨去非本科生
and academic_level='本科'