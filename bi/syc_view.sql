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
