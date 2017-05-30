/**
 * database zf/tm
 */

/**
 * 用户表
 */
create or replace view tm.sv_system_user as
with teacher as (
    select
        yhm as id,
        jsxxb.xm as name,
        case when dlm = yhm then null else dlm end as login_name,
        nvl(jsmm, yhm) as password,
        case
            when yhb.emldz is not null then yhb.emldz
            when jsxxb.emldz is not null then jsxxb.emldz
        end as email,
        case
            when regexp_like(telnumber, '1\d{10}') then regexp_substr(telnumber, '1\d{10}', 1, 1)
            when regexp_like(lxdh, '1\d{10}') then regexp_substr(lxdh, '1\d{10}', 1, 1)
        end as long_phone,
        case
            when yhm <> jsmm and not regexp_like(jsmm, 'a[b-d]{3}[0-9]{4}') then 1
            else 0 -- 用户名密码相同则禁用
        end as enabled,
        1 as user_type,
        xydm as department_id
    from zfxfzb.yhb
    join zfxfzb.jsxxb on yhm = zgh -- 以职工号为用户名
    left join zfxfzb.xydmb on bm = xymc
    where (ty is null or ty = 'F') -- 停用
    and (sfzg is null or sfzg = '是') -- 是否在职
    order by id
), student as (
    select
        xh as id,
        xm as name,
        null as login_name,
        nvl(xsmm, DBMS_RANDOM.STRING('A', 10)) as password,
        dzyxdz as email,
        case
            when regexp_like(telnumber, '1\d{10}') then regexp_substr(telnumber, '1\d{10}', 1, 1)
        end as long_phone,
        1 as enabled,
        2 as user_type,
        xydm as department_id
    from zfxfzb.xsjbxxb
    left join zfxfzb.xydmb on xy_xsxy = xymc
    where xjzt =  '有' -- 有学籍
    and dqszj > (select max(dqszj) - 8 from zfxfzb.xsjbxxb)
    order by xh
)
select * from teacher
union all
select * from student;

/**
 * 教学场地-允许借用用户类型
 */
create or replace view tm.sv_place_user_type as
select jsbh as place_id, 1 as user_type from zfxfzb.jxcdxxb
where substr(jyjsdx, 2, 1) = '1' -- 教师
union all
select jsbh as place_id, 2 as user_type from zfxfzb.jxcdxxb
where substr(jyjsdx, 1, 1) = '1' -- 学生
order by place_id, user_type;

/**
 * 教学场地使用视图
 */
create or replace view tm.dv_place_usage as
select distinct to_number(substr(xn, 1, 4) || xq) as term_id,
    jsbh as place_id,
    nvl(qsz, 1) as start_week,
    case when k.xkkh is not null then (nvl(jsz, 30)-1) else nvl(jsz, 30) end as end_week,
    case dsz when '单' then 1 when '双' then 2 else 0 end as odd_even,
    to_number(xqj) as day_of_week,
    sjd as start_section,
    skcd as total_section,
    lb as type,
    sydw as department,
    bz as description
from zfxfzb.jxcdview_old_tms t
left join (select * from zfxfzb.ttksqb
    where bdlb='考试' and shbj='1') k on t.xkkh=k.xkkh
    and t.xqj=k.yxqj and to_char(t.sjd)=k.ysjd and to_char(t.jsz)=k.yjsz
where jsbh is not null;

/**
 * 教学场地借用视图，用于插入数据
 */
create or replace view tm.iv_booking_form as
select
  jyjtsj as id,
  xuh as form_id,
  xn as school_year,
  xq as term,
  jsbh as place_id,
  jsmc as place_name,
  ksz as start_week,
  jsz as end_week,
  dsz as odd_even,
  xqj as day_of_week,
  sjd as start_section,
  skcd as total_section,
  zwsjd as section_name,
  jydw as department_name,
  jyjs as user_id,
  sjgr as user_name,
  grdh as user_phone,
  jyly as reason,
  jysj as booking_date,
  dh as checker_phone,
  shr as approver_id,
  ly as source,
  bz as status
from zfxfzb.jxcdyyb
where ly='Tm' and jyjtsj is not null
with check option;

/*
 * 教学计划-课程视图，用于插入数据
 */
drop table tm.program_course;
create table tm.program_course (
    program_id number,
    course_id varchar2(8),
    period_theory number,
    period_experiment number,
    period_weeks number,
    is_compulsory number,
    is_practical number,
    property_id number,
    assess_type number,
    test_type number,
    start_week number,
    end_week number,
    suggested_term number,
    allowed_term number,
    schedule_type number,
    department_id varchar2(2),
    direction_id number
);

create or replace view tm.iv_program_course as
select
    program_id,
    course_id,
    period_theory,
    period_experiment,
    period_weeks,
    is_compulsory,
    is_practical,
    property_id,
    assess_type,
    test_type,
    start_week,
    end_week,
    suggested_term,
    allowed_term,
    schedule_type,
    department_id,
    direction_id
from tm.program_course;

/**
 * 教学计划-课程触发器，插入数据
 * TODO：处理辅修教学计划
 */
create or replace trigger tm.iv_program_course_trigger
  instead of insert
  on tm.iv_program_course
declare
  zydm varchar2(4);
  zymc varchar2(40);
  nj number(4, 0);
  kcmc varchar2(100);
  xf varchar2(5);
  zxs varchar2(9);
  kcxz varchar2(20);
  kclb varchar2(20);
  kkxy varchar2(30);
  zyfx varchar2(100);
  zhxs varchar2(9);
  jkxs varchar2(9);
  syxs varchar2(9);
begin
  select s.zydm, s.zymc, m.grade
  into zydm, zymc, nj
  from ea.sv_program p
  join ea.sv_major m on p.major_id = m.id
  join zfxfzb.zydmb s on m.subject_id = s.zydm
  where p.id = :new.program_id;

  select c.name, to_char(c.credit, 'fm90.0')
  into kcmc, xf
  from ea.sv_course c
  where c.id = :new.course_id;

  if :new.period_theory = 0 and :new.period_experiment = 0 then
    zxs := '+' || :new.period_weeks;
    zhxs := '0';
    jkxs := '0';
    syxs := '0';
  else
    zxs := to_char(:new.period_theory, 'fm90.0') || '-' || to_char(:new.period_experiment, 'fm90.0');
    zhxs := to_char((:new.end_week - :new.start_week + 1) * (:new.period_theory + :new.period_experiment));
    jkxs := to_char((:new.end_week - :new.start_week + 1) * (:new.period_theory));
    syxs := to_char((:new.end_week - :new.start_week + 1) * (:new.period_experiment));
  end if;

  select name, case name
    when '实践教学' then '实践环节'
    else case IS_COMPULSORY
      when 1 then '必修课'
      else '选修课'
      end
    end
  into kcxz, kclb
  from ea.sv_property
  where id = :new.property_id;

  select name
  into kkxy
  from ea.sv_department
  where id = :new.department_id;

  if :new.direction_id is null then
    zyfx := '无方向';
  else
    select name
    into zyfx
    from ea.sv_direction
    where id = :new.direction_id;
  end if;

  if mod(:new.program_id, 10) = 0 then
    insert into zfxfzb.jxjhkcxxb(jxjhh,
        zydm, zymc, nj, kcdm, kcmc, xf, zxs, kcxz, kclb,
        khfs, ksfs,
        qsz, jsz, qsjsz,
        kkxy, zyfx,
        jyxdxq, kkkxq,
        zhxs, jkxs, syxs, sjxs,
        qzxs,
        bz
    )
    values(to_char(floor(:new.program_id / 10)),
        zydm, zymc, nj, :new.course_id, kcmc, xf, zxs, kcxz, kclb,
        decode(:new.assess_type, 1, '考试', 2, '考查', 3, '论文', 9, null),
        decode(:new.test_type, 1, '集中', 2, '分散', null) ,
        :new.start_week, :new.end_week, to_char(:new.start_week, 'fm09') || '-' || to_char(:new.end_week, 'fm09'),
        kkxy, zyfx,
        :new.suggested_term, tm.util.number_to_csv_bit(:new.allowed_term, :new.suggested_term),
        zhxs, jkxs, syxs, '0',
        '1.0',
        'TM'
    );
  end if;
end;

/**
 * 学生选课视图，用于取消考试资格
 */
create or replace view tm.iv_task_student as
select
  xkkh as task_code,
  xh as student_id,
  bz as exam_flag
from zfxfzb.xsxkb;
