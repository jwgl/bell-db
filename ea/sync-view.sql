/**
 * database zf/ea
 */

/**
 * 学期（取消，使用ea.term）
 */
create or replace view ea.sva_term as
with w as ( -- 教学任务中的起始结束周
    select xn, xq,
    to_number(regexp_substr(qsjsz, '^\d+')) qsz,
    to_number(regexp_substr(qsjsz, '\d+$')) jsz
    from zfxfzb.jxrwb
), a as ( -- 日期表中数据
    select xn, xq,
        to_date(min(nyr), 'YYYY-MM-DD') start_date,
        case when xn || xq = (select max(xn || xq) from zfxfzb.rqkszb) then -- 表中最后的学期
            to_date(max(nyr), 'YYYY-MM-DD')
        when xq = '2' then -- 如果为第2学期，则取下一学年第1学期
            (select to_date(min(nyr), 'YYYY-MM-DD') - 1 from zfxfzb.rqkszb where xn = (to_number(substr(x.xn,1,4)) + 1) || '-' || (to_number(substr(x.xn,6,4)) + 1) and xq = 1)
        else -- 如果为第1学期，则取同学年第2学期
            (select to_date(min(nyr), 'YYYY-MM-DD') - 1 from zfxfzb.rqkszb where xn = x.xn and xq = 2)
        end as max_date
    from zfxfzb.rqkszb x
    where djz >= 1
    group by xn, xq
), b as ( -- 查找最常用结束周
    select * from (
        select xn, xq, jsz, rank() over (PARTITION BY xn, xq order by count(*) desc) r from w group by xn, xq, jsz
    ) where r = 1
), c as (
    select * from ( -- 小学期
        select xn, xq, qsz, jsz, rank() over (PARTITION BY xn, xq order by count(*) desc) r from w where qsz > '18' group by xn, xq, qsz, jsz
    ) where r = 1
)
-- 日期表中数据
select to_number(substr(a.xn, 1, 4) || a.xq) id,
    start_date,
    1 as start_week,
    c.qsz as mid_week,
    case
        when a.xq = 1 and (select max(qsz) from c where xn = a.xn and xq = 2) is not null then -- 有小学期的前一学期
            b.jsz
        when c.qsz is not null then -- 有小学期
            c.jsz
        else -- 无小学期
            b.jsz + 2
    end as end_week,
    ((max_date - start_date) + 1) / 7 as max_week
from a join b on a.xn = b.xn and a.xq = b.xq
left join c on a.xn = c.xn and a.xq = c.xq
union
-- 手工生成数据
select id, to_date(start_date, 'YYYY-MM-DD'), 1 start_week, null mid_week,
    (to_date(end_date, 'YYYY-MM-DD') - to_date(start_date, 'YYYY-MM-DD') + 1) / 7 end_week,
    (to_date(max_date, 'YYYY-MM-DD') - to_date(start_date, 'YYYY-MM-DD') + 1) / 7 max_week
from (
    select 20021 id, '2002-10-7' start_date, '2003-1-26' end_date, '2003-2-16' max_date from dual
    union all
    select 20022, '2003-02-17', '2003-07-06', '2003-08-31' from dual
    union all
    select 20031, '2003-09-01', '2004-01-18', '2004-02-15' from dual
    union all
    select 20032, '2004-02-16', '2004-07-11', '2004-09-05' from dual
    union all
    select 20041, '2004-09-06', '2005-01-23', '2005-02-27' from dual
    union all
    select 20042, '2005-02-28', '2005-07-17', '2005-09-04' from dual
)
order by id;

/**
 * 学院
 */
create or replace view ea.sv_department as
select xydm as id,
    xymc as name,
    xyywmc as english_name,
    xyjc as short_name,
    decode(xylx, '教学单位', 1, 0) is_teaching,
    case
        when exists (select 1 from zfxfzb.xsjbxxb xs where xs.xy = xymc) then 1
            else 0
    end as has_students, -- 是否有学生
    case
        when xylx is null
            or not exists (select 1 from zfxfzb.xsjbxxb xs where xs.xy = xymc)
            or xylx = '教学单位'
            and exists (select 1 from zfxfzb.xsjbxxb xs where xs.dqszj >= 2010 and xs.xy = xymc)
            then 1
        else 0
    end as enabled -- 近四年没有学生则禁用
from zfxfzb.xydmb
order by id;

/**
 * 教学场地
 */
create or replace view ea.sv_place as
select jsbh as id,
    jsmc as name,
    jsjc as english_name,
    jslb as type,
    nvl(zws, 0) as seat,
    nvl(kszws, 0) as test_seat,
    lh as building,
    decode(kyf, 'T', 1, 0) as enabled,
    decode(kskyf, 'T', 1, 0) as can_test,
    to_number(substr(jykyxq, 1, 4) || substr(jykyxq, 11, 1)) as booking_term,
    decode(jyjsdx, '01', 1, '10', 2, '11', 3, 0) as booking_user,
    decode(xqdm, 0, 1, 1, 0) as is_external,
    regexp_replace(translate(bz, chr(10)||chr(11)||chr(13), '   '), '\s+', ' ') as note
from zfxfzb.jxcdxxb
order by id;

/**
 * 教学场地-允许使用单位
 */
create or replace view ea.sv_place_department as
select jsbh as place_id, xydm as department_id
from (
    select jsbh, regexp_substr(sybm, '[^,]+', 1, level) as sybm
    from zfxfzb.jxcdxxb
    where sybm is not null
    connect by level <= regexp_count(sybm, '[^,]+')
        and prior jsbh = jsbh
        and prior dbms_random.value is not null
) a join zfxfzb.xydmb b on b.xymc = sybm;

/**
 * 教学场地-允许借用学期
 */
create or replace view ea.sv_place_booking_term as
select jsbh as place_id,
    to_number(substr(jykyxq, 1, 4) || substr(jykyxq, -1, 1)) as term_id
from zfxfzb.jxcdxxb
where jykyxq is not null;

/**
 * 教学场地-允许借用用户类型
 */
create or replace view ea.sv_place_booking_user_type as
select jsbh as place_id, 1 as user_type from zfxfzb.jxcdxxb
where substr(jyjsdx, 2, 1) = '1' -- 教师
union all
select jsbh as place_id, 2 as user_type from zfxfzb.jxcdxxb
where substr(jyjsdx, 1, 1) = '1' -- 学生
order by place_id, user_type;

/**
 * 校内专业
 */
create or replace view ea.sv_subject as
select zydm as id,
    regexp_replace(replace(replace(zymc,'(', '（'), ')', '）'), '[（]插班(生)?[）]', '') as name,
    zyywmc as english_name,
    regexp_replace(replace(replace(nvl(zyjc, zymc),'(', '（'), ')', '）'), '[（]插班(生)?[）]', '') as short_name,
    decode(cc,
        '本科',       1,
        '硕士',       2,
        '外校研究生', 2,
        /*其它*/      9) as education_level,
    xz as length_of_schooling,
    case
        when (select enabled from ea.sv_department where id = ssxydm) = 0 then 1 -- 学院停用
        when not exists(select 1 from zfxfzb.jxjhzyxxb where nj > 2012 and a.zydm = zydm) then 1 -- 2012级之后没有计划
        when tjzymc is not null and b.id is null then 1 -- 新版招生目录中没有
        else 0
    end as stop_enroll,
    case zydm
        when '2201' then 1 -- 中加
        when '1317' then 1 -- 中德
        else 0
    end as is_joint_program,
    case
        when zyjc like '%2+2%' then 1
        else 0
    end as is_dual_degree,
    case
        when zymc like '%插班%' then 1
        else 0
    end as is_top_up,
    case
        when b.id is not null then b.id
        when c.id is not null then c.id
    end as field_id,
    case
        when b.id is not null then (select id from ea.discipline x where x.id like '2012%' and x.name = replace(xw, '学士', ''))
        when c.id is not null then (select id from ea.discipline x where x.id like '1998%' and x.name = replace(xw, '学士', ''))
    end as degree_id,
    ssxydm as department_id
from zfxfzb.zydmb a
left join ea.field b on a.tjzymc = b.name and b.id like '2012%'
left join ea.field c on a.tjzymc = c.name and c.id like '1998%'
where zymc not like '%（研）'
order by id;

/**
 * 年级专业
 */
create or replace view ea.sv_major as
select to_number(a.jxjhh) as id,
    a.zydm as subject_id,
    a.nj as grade,
    decode(a.zylb,
        '普通类',   0,
        '文科',     1,
        '理科',     2,
        '文科理科', 3,
        '艺术',     4,
        '体育',     8,
        '外语类',   16,
        '插班',     32,
        '计划外',   64,
        /*其它*/    0) as candidate_type,
    case
        when b.tjzymc is not null then
            case
                when nj > 2012 then
                    (select id from ea.field where id like '2012%' and name = tjzymc)
                else
                    (select id from ea.field where id like '1998%' and name = tjzymc)
            end
    end as field_id,
    case
        when a.nj > 2012 then
            (select id from ea.discipline x where x.id like '2012%' and x.name = replace(a.xw, '学士', ''))
        else
            (select id from ea.discipline x where x.id like '1998%' and x.name = replace(a.xw, '学士', ''))
    end as degree_id,
    a.xydm as department_id
from zfxfzb.jxjhzyxxb a join zfxfzb.zydmb b on a.zydm = b.zydm
where a.xydm is not null
order by id;

/**
 * 专业方向
 */
create or replace view ea.sv_direction as
select to_number(substr(zyfxdm, 1, 8) || '0' || substr(zyfxdm, 9, 1)) as id,
    to_number(substr(zyfxdm, 1, 8) || '0') as program_id, zyfxmc as name
from zfxfzb.zyfxb
order by id;

/**
 * 教学计划
 */
create or replace view ea.sv_program as
select to_number(jxjhh || '0') as id, -- 主修计划
    case when zymc like '%插班%' then 3 else 0 end as type,
    to_number(jxjhh) as major_id,
    nvl(zdbyxf, 0) as credit
from zfxfzb.jxjhzyxxb
where jxjhh in (select id from ea.sv_major)
union all
select distinct to_number(jxjhh || case -- 辅修计划
        -- 12级有重叠，12级以前的计划以9结尾，12级以后的计划以1结尾
        when substr(jxjhh, 1, 4) < 2012 then '9'
        when substr(jxjhh, 1, 4) = 2012 then decode(fxbs, 1, '9', '1')
        -- 15级之后有定向辅修以2结尾，非定向普通辅修以1结尾
        when substr(jxjhh, 1, 4) > 2012 then decode(fxbs, 1, '2', '1')
    end) as id,
    case when substr(jxjhh, 1, 4) > 2012 and fxbs = 1 then 2 else 1 end as type,
    to_number(jxjhh) as major_id,
    55
from zfxfzb.fxjxjhkcxxb x
where jxjhh in (select id from ea.sv_major)
order by id;

/**
 * 课程性质
 */
create or replace view ea.sv_property as
select to_number(kcxzdm) as id,
    kcxzmc as name,
    kcxzjc as short_name,
    decode(xbx, '选', 0, '必', 1, 1) as is_compulsory,
    decode(kcxzmc, '学科基础课', 1, '专业主干课', 1, 0) as is_primary
from zfxfzb.kcxzdmb
order by id;

/**
 * 教学计划-课程性质
 */
create or replace view ea.sv_program_property as
select to_number(program_id) as program_id, property_id, credit, is_weighted from (
    select jxjhh || '0' as program_id, -- 主修计划
        property_id,
        credit,
        1 as is_weighted
    from zfxfzb.jxjhzyxxb
    unpivot (
        credit for property_id in (
        "XFYQ1" as 1,
        "XFYQ2" as 2,
        "XFYQ3" as 3,
        "XFYQ4" as 4,
        "XFYQ5" as 5,
        "XFYQ6" as 6,
        "XFYQ7" as 7,
        "XFYQ8" as 8,
        "XFYQ9" as 9,
        "XFYQ10" as 10,
        "XFYQ11" as 11,
        "XFYQ12" as 12,
        "XFYQ13" as 13
        )
    )
)
where credit <> 0 -- 去除学分为0的项
and program_id in (select id from ea.sv_program)
union
select id as program_id, -- 辅修计划
    to_number(kcxzdm) as property_id,
    decode(kcxzmc, '辅修课', 30, '双学位课', 25) as credit,
    1 as is_weighted
from (
    select id from ea.sv_program where type = 1
) a cross join (
    select kcxzdm, kcxzmc from zfxfzb.kcxzdmb where kcxzmc in('双学位课', '辅修课')
) b
order by program_id, property_id;

/**
 * 课程
 */
create or replace view ea.sv_course as
select kcdm as id,
    kczwmc as name,
    kcywmc as english_name,
    to_number(xf) as credit,
    case when regexp_like(zxs, '^\d+\.\d?')  then to_number(regexp_substr(zxs, '^\d+\.\d?')) else 0 end as period_theory,
    case when regexp_like(zxs, '-\d+\.\d?$') then to_number(regexp_substr(zxs, '\d+\.\d?$')) else 0 end as period_experiment,
    case when regexp_like(zxs, '^\+\d+$')    then to_number(regexp_substr(zxs, '\d+'))       else 0 end as period_weeks,
    to_number(kcxzdm) as property_id,
    decode(kclb, '必修课', 1, '选修课', 0, '实践环节', 1, 1) as is_compulsory,
    case when regexp_like(zxs, '^\+\d+$') then 1 else 0 end as is_practical,
    decode(xlcc,'本科', 1, '本科毕业生', 1, '硕士研究生', 2, /*其它或空*/ 9) as education_level,
    decode(khfs, '考试', 1, '考查', 2, '论文', 3, /*空*/ 9) as assess_type,
    nvl(sfpk, 1) as schedule_type,
    kcjj as introduction,
    decode(tkbj, '1', 0, 1) enabled,
    case when kkbmdm is null then substr(kcdm, 1, 2) else kkbmdm end as department_id
from zfxfzb.kcdmb a
left join zfxfzb.kcxzdmb b on kcxzmc = kcxz
left join ( -- 是否排课
    select kcdm as pk_kcdm, decode(sfpk, 0, 0, 1) as sfpk  from(
        select kcdm, sum (case when skdd is null and sksj is null then 0 else 1 end) as sfpk
        from zfxfzb.jxrwbview a
        where xkzt <> 4
        group by kcdm
    )
) on kcdm = pk_kcdm
where kcxz is not null
order by id;

/**
 * 课程项
 */
create or replace view ea.sv_course_item as
with sykc as ( -- 实验课
    select distinct substr(xkkh, 15, 8) as kcdm
    from zfxfzb.dgjsskxxb
    where substr(xkkh, -1, 1) between 'A' and 'Z'
), tykc as ( -- 体育课
    select kcdm, rank() over (partition by sskcdm order by kcdm) r
    from zfxfzb.tykkcdmb
)
-- 理论
select kcdm || '01' as id,
    '理论' as name,
    1 as ordinal,
    1 as is_primary,
    kcdm as course_id,
    kcdm as task_course_id -- 与任务连接用的课号
from sykc
union all
-- 实验
select kcdm || '02' as id,
    '实验' as name,
    2 as ordinal,
    0 as is_primary,
    kcdm as course_id,
    kcdm as task_course_id
from sykc
union all
-- 外语
select bkkcdm || to_char(xh, 'fm09') as id,
    bz as name,
    xh as ordinal,
    decode(xh, 1, 1, 0) as is_primary,
    bkkcdm as course_id,
    bkkcdm as task_course_id
from zfxfzb.bkkcfldmb
union all
-- 体育
select sskcdm || to_char(r, 'fm09') as id,
    kczwmc as name,
    r as ordinal,
    0 as is_primary,
    sskcdm as course_id,
    a.kcdm as task_course_id
from zfxfzb.tykkcdmb a join tykc b on a.kcdm = b.kcdm
order by id;

/**
 * 教学计划-课程
 */
create or replace view ea.sv_program_course as
with x as (
    select
        jxjhh || '0' as program_id,
        kcdm as course_id,
        case when regexp_like(zxs, '^\d+\.\d?')  then to_number(regexp_substr(zxs, '^\d+\.\d?')) else 0 end as period_theory,
        case when regexp_like(zxs, '-\d+\.\d?$') then to_number(regexp_substr(zxs, '\d+\.\d?$')) else 0 end as period_experiment,
        case when regexp_like(zxs, '^\+\d+$')    then to_number(regexp_substr(zxs, '\d+'))       else 0 end as period_weeks,
        decode(kclb, '必修课', 1, '选修课', 0, '实践环节', 1, 1) as is_compulsory,
        case when regexp_like(zxs, '^\+\d+$') then 1 else 0 end as is_practical,
        to_number(kcxzdm) as property_id,
        decode(khfs, '考试', 1, '考查', 2, '论文', 3, /*空*/ 9) as assess_type,
        decode(ksfs, '集中', 1, '分散', 2, /*缺省集中*/ 1) as test_type,
        to_number(regexp_substr(qsjsz, '^\d+')) as start_week,
        to_number(regexp_substr(qsjsz, '\d+$')) as end_week,
        case when jyxdxq > 8 then 7 else jyxdxq end as suggested_term, -- error > 8
        ea.util.csv_bit_to_number(kkkxq, jyxdxq) as allowed_term,
        nvl(sfpk, sv_course.schedule_type) as schedule_type,
        xydm as department_id,
        sv_direction.id as direction_id
    from zfxfzb.jxjhkcxxb
    join zfxfzb.kcxzdmb on kcxz = kcxzmc
    join zfxfzb.xydmb on kkxy = xymc
    join ea.sv_course on kcdm = sv_course.id
    left join sv_direction on sv_direction.name = zyfx and sv_direction.program_id = jxjhh || 0
    left join ( -- 是否排课
        select jxjhh as pk_jxjhh, kcdm as pk_kcdm, zyfx as pk_zyfx, decode(sfpk, 0, 0, 1) as sfpk  from(
            select jxjhh, kcdm, zyfx, sum (case when skdd is null and sksj is null then 0 else 1 end) as sfpk
            from zfxfzb.jxrwbview a
            where xkzt <> 4
            group by jxjhh, kcdm, zyfx
        )
    ) on jxjhh = pk_jxjhh and kcdm = pk_kcdm and zyfx = pk_zyfx
    union all
    select
        jxjhh || case
            when substr(jxjhh, 1, 4) < 2012 then '9'
            when substr(jxjhh, 1, 4) = 2012 then decode(fxbs, 1, '9', '1')
            when substr(jxjhh, 1, 4) > 2012 then decode(fxbs, 1, '2', '1')
        end as program_id,
        kcdm as course_id,
        case when regexp_like(zxs, '^\d+\.\d?')  then to_number(regexp_substr(zxs, '^\d+\.\d?')) else 0 end as period_theory,
        case when regexp_like(zxs, '-\d+\.\d?$') then to_number(regexp_substr(zxs, '\d+\.\d?$')) else 0 end as period_experiment,
        case when regexp_like(zxs, '^\+\d+$')    then to_number(regexp_substr(zxs, '\d+'))       else 0 end as period_weeks,
        decode(kclb, '必修课', 1, '选修课', 0, '实践环节', 1, 1) as is_compulsory,
        case when regexp_like(zxs, '^\+\d+$') then 1 else 0 end as is_practical,
        to_number(kcxzdm) as property_id,
        decode(khfs, '考试', 1, '考查', 2, '论文', 3, /*空*/ 9) as assess_type,
        decode(ksfs, '集中', 1, '分散', 2, /*缺省集中*/ 1) as test_type,
        to_number(regexp_substr(qsjsz, '^\d+')) as start_week,
        to_number(regexp_substr(qsjsz, '\d+$')) as end_week,
        jyxdxq as suggested_term,
        ea.util.csv_bit_to_number(kkkxq, jyxdxq) as allowed_term,
        nvl(sfpk, sv_course.schedule_type) as schedule_type,
        xydm as department_id,
        /*zyfxdm*/ null as direction_id
    from zfxfzb.fxjxjhkcxxb
    join zfxfzb.kcxzdmb on kcxz = kcxzmc
    join zfxfzb.xydmb on kkxy = xymc
    join ea.sv_course on kcdm = sv_course.id
    /* left join zfxfzb.zyfxb on zyfxmc = zyfx and jxjhh = substr(zyfxdm, 1, 8) */ -- 辅修课不处理专业方向
    left join ( -- 是否排课
        select jxjhh as pk_jxjhh, kcdm as pk_kcdm, zyfx as pk_zyfx, decode(sfpk, 0, 0, 1) as sfpk  from(
            select jxjhh, kcdm, zyfx, sum (case when skdd is null and sksj is null then 0 else 1 end) as sfpk
            from zfxfzb.jxrwbview a
            where xkzt <> 4
            group by jxjhh, kcdm, zyfx
        )
    ) on jxjhh = pk_jxjhh and kcdm = pk_kcdm and zyfx = pk_zyfx
)
select to_number(program_id) as program_id, course_id, period_theory, period_experiment,
    case
        when period_weeks <> 0 then period_weeks
        when (end_week - start_week + 1) >= 16 then 18
        else (end_week - start_week + 1)
    end as period_weeks, is_compulsory, is_practical,
    property_id, assess_type, test_type, start_week, end_week,
    suggested_term, allowed_term, schedule_type, department_id, direction_id
from x
where program_id in (select id from ea.sv_program)
order by program_id, suggested_term, course_id;

/**
 * 教师
 */
create or replace view ea.sv_teacher as
select
    zgh as id,
    xm as name,
    xb as sex,
    case
        when regexp_like(csrq, '\d{8}') then
            to_date(csrq, 'yyyymmdd')
        when regexp_like(csrq, '\d+') then
            to_date(regexp_substr(csrq, '\d+', 1, 1) || '-' ||
            coalesce(regexp_substr(csrq, '\d+', 1, 2), '1') || '-' ||
            coalesce(regexp_substr(csrq, '\d+', 1, 3), '1'), 'yyyy-mm-dd')
    end as birthday,
    decode(zzmm, '---请选择政治面貌---', null, zzmm) as political_status,
    decode(mz, '---请选择民族---', null, mz) as nationality,
    zc as academic_title,
    decode(jsjb, '无', null, jsjb) as academic_level,
    case
        when xw like '%博士%' then '博士'
        when xw like '%硕士%' then '硕士'
        when xw like '%学士%' then '学士'
    end as academic_degree,
    xl as educational_background,
    byyx as graduate_school,
    zymc graduate_major,
    case when regexp_like(bysj, '\d+') then
        to_date(regexp_substr(bysj, '\d+', 1, 1) || '-' ||
        coalesce(regexp_substr(bysj, '\d+', 1, 2), '1') || '-' ||
        coalesce(regexp_substr(bysj, '\d+', 1, 3), '1'), 'yyyy-mm-dd')
    end as date_graduated,
    lbmc as post_type,
    case ywjszg when '有' then 1 else 0 end as has_qualification,
    case sfsysry when '是' then 1 else 0 end as is_lab_technician,
    case sfwp when '是' then 1 else 0 end as is_external,
    case sfzg when '否' then 0 else 1 end as at_school,
    case zdbyzg when '否' then 0 else 1 end as can_guidance_graduate,
    case
        when bm is null then
            case
                when not regexp_like(zgh, '^\d{2}') then
                    (select xydm from zfxfzb.xydmb where xymc = '教务处')
                else
                    substr(zgh, 1, 2)
            end
        else
            case
                when exists (select 1 from zfxfzb.xydmb where xymc = bm) then
                    (select xydm from zfxfzb.xydmb where xymc = bm)
                else
                    substr(zgh, 1, 2)
            end
    end as department_id,
    jsjj as resume
from zfxfzb.jsxxb
order by id;

/**
 * 班级
 */
create or replace view ea.sv_admin_class as
select
    to_number(nj || sszydm || substr(bjdm, -2, 2)) id,
    bjmc as name,
    to_number(nj || sszydm) as major_id,
    ssxydm as department_id
from zfxfzb.bjdmb
order by id;

/**
 * 录取信息
 */
create or replace view ea.sv_admission as
select
    to_number('20' || xh) as id,
    xh as student_id,
    nvl(b.zydm, a.zydm) as subject_id, -- 还原入学专业
    to_number('20' || substr(xh, 1, 2)) as grade, -- 还原入学年级
    case xh when '0818010172' then '待修复' else xm end as name,
    case when xh in('0416020026', '1017010074') then NULL else zym end as used_name,
    xb as sex,
    case
        when regexp_like(csrq, '\d{8}') then to_date(csrq, 'yyyymmdd') -- 19810101
        when regexp_like(csrq, '\d{4}-\d{2}-\d{2}') then to_date(csrq, 'yyyy-mm-dd') -- 1981-01-01
    end as birthday,
    zzmm as political_status,
    mz as nationality,
    lxdh as phone_number,
    lys as from_province,
    lydq as from_city,
    jtszd as home_address,
    hkszd as household_address,
    yzbm as postal_code,
    case when regexp_like(byzx, '\d') and not regexp_like(byzx, '中') then null else byzx end as middle_school,
    ksh as candidate_number,
    zkzh as examination_number,
    round(to_number(regexp_substr(rxzf, '\d+(\.\d+)?', 1, 1))) as total_score,
    round(to_number(yycj)) as english_score,
    sfzh as id_number,
    yhzh as bank_number
from zfxfzb.xsjbxxb a
left join zfxfzb.zydmb b on substr(xh, 3, 4) = b.zydm
order by id;

/**
 * 学生
 */
create or replace view ea.sv_student as
select xh as id,
    xsmm as password,
    case xh when '0818010172' then '待修复' else xm end as name,
    xmpy as pinyin_name,
    xb as sex,
    case
        when regexp_like(csrq, '\d{8}') then to_date(csrq, 'YYYYMMDD') -- 19810101
        when regexp_like(csrq, '\d{4}-\d{2}-\d{2}') then to_date(csrq, 'YYYY-MM-DD') -- 1981-01-01
    end as birthday,
    to_number(mzdm) as nationality,
    to_number(zzmmdm) as political_status,
    decode(dqszj, null, to_number('20' || substr(xh, 1, 2)), dqszj) as grade,
    case
        when rxrq is null then to_date('20' || substr(xh, 1, 2) || '0901', 'YYYYMMDD') -- 为空
        when regexp_like(rxrq, '\d{8}') then to_date(rxrq, 'YYYYMMDD')
        when regexp_like(rxrq, '\d{4}-\d{2}-\d{2}') then to_date(rxrq, 'YYYY-MM-DD')
    end as date_enrolled,
    case
        when regexp_like(byrq, '\d{8}') then to_date(byrq, 'YYYYMMDD')
        when regexp_like(byrq, '\d{6}') then to_date(regexp_substr(byrq, '\d{6}', 1, 1) || '01', 'YYYYMMDD')
        when regexp_like(byrq, '\d{4}-\d{2}') then to_date(byrq || '-01', 'YYYY-MM-DD')
    end as date_graduated,
    decode(xjzt, '有', 1, 0) as is_enrolled,
    decode(sfzx, '是', 1, 0) as at_school,
    decode(sfzc, '是', 1, 0) as is_registed,
    ccqj as train_range,
    to_number(xslbdm) as category,
    decode(zxwyyz,
        '英语(EN)', 'en',
        '英语1',    'en',
        '日语',     'ja',
        '俄语',     'ru',
        '德语',     'de',
        '法语',     'fr',
        /*缺省*/    'en'
    ) as forign_language,
    case
        when dqszj < 2013 then 0
        when dqszj is not null then
            to_number(substr(dj, ( -- 取选课学期
                (select max(substr(xn, 1, 4)) from zfxfzb.xxmc) - dqszj) * 2 +
                (select max(xq) from zfxfzb.xxmc), 1))
        else 0
    end as forign_language_level,
    to_number(xjyddm) as change_type,
    xydm as department_id,
    sv_admin_class.id as admin_class_id,
    sv_major.id as major_id,
    sv_direction.id as direction_id,
    to_number('20' || xh) as admission_id
from zfxfzb.xsjbxxb
left join zfxfzb.xydmb on xy = xymc
left join zfxfzb.xjyddmb on ydlb = xjydmc
left join zfxfzb.xslbdmb on xslb = xslbmc
left join zfxfzb.mzdmb on mz = mzmc
left join zfxfzb.zzmmdmb on zzmm = zzmmmc
left join ea.sv_admin_class on xzb = name
left join ea.sv_major on dqszj || zydm = sv_major.id
left join ea.sv_direction on zyfx = sv_direction.name and (dqszj || zydm || '0') = sv_direction.program_id
order by id;

/*
 * 辅助视图 - 主教学任务（jxrwbview简化版）
 */
create or replace view ea.sva_task_base as
with task as (
    select -- 按专业培养方案产生的教学计划（主修）
        jxjhh, zydm, zymc, zyfx,
        xn, xq, kcdm, kcmc, xf, kcxz, kclb, kkxy, kkx,
        jszgh, jsxm, xkkh, skdd, sksj, rs, qsjsz,
        bjmc, jxbmc, zxs, xkzt, mxdx, xzdx, ksfs, khfs,
        jxjhh || '0' as program_id,
        'jxrwb-1' tab
    from zfxfzb.jxrwb
    where jxjhh in (select jxjhh from zfxfzb.jxjhkcxxb)
    union all
    select -- 按实际执行产生的教学计划（外语）
        jxjhh, zydm, zymc, zyfx,
        xn, xq, kcdm, kcmc, xf, kcxz, kclb, kkxy, kkx,
        jszgh, jsxm, xkkh, skdd, sksj, rs, qsjsz,
        bjmc, jxbmc, zxs, xkzt, mxdx, xzdx, ksfs, khfs,
        null as program_id,
        'jxrwb-2' tab
    from zfxfzb.jxrwb
    where jxjhh not in (select jxjhh from zfxfzb.jxjhkcxxb)
    union all
    select -- 按实际执行产生的教学计划（公选，政治）
        substr(xn, 1, 4) || xq jxjhh, null zydm, null zymc, null zyfx,
        xn, xq, kcdm, kcmc, xf, kcxz, kclb, kkxy, kkx,
        jszgh, jsxm, xkkh, skdd, sksj, rs, qsjsz,
        null bjmc, null jxbmc, zxs, xkzt, mxdx, xzdx, ksfs, khfs,
        null as program_id,
        'xxkjxrwb' tab
    from zfxfzb.xxkjxrwb
    union all
    select -- 按专业培养方案产生的教学计划（辅修）
        jxjhh, zydm, zymc, null zyfx,
        xn, xq, kcdm, kcmc, xf, kcxz, kclb, kkxy, kkx,
        jszgh, jsxm, xkkh, skdd, sksj, rs, qsjsz,
        null bjmc, null jxbmc, zxs, xkzt, mxdx, xzdx, ksfs, khfs,
        jxjhh || case
            when substr(jxjhh, 1, 4) < 2012 then '9'
            when substr(jxjhh, 1, 4) = 2012 then decode(fxbs, 1, '9', '1')
            when substr(jxjhh, 1, 4) > 2012 then decode(fxbs, 1, '2', '1')
        end as program_id,
        'fxkjxrwb' tab
    from zfxfzb.fxkjxrwb
    where jxjhh in (select jxjhh from zfxfzb.fxjxjhkcxxb) -- 存在错误数据（教学任务问题37）
    union all
    select -- 按实际执行产生的教学计划（特殊课）
        case when mxnj is null then substr(xn, 1, 4) else mxnj end || xq jxjhh, null zydm, null zymc, null zyfx,
        xn, xq, kcdm, kcmc, xf, kcxz, kclb, kkxy, kkx,
        jszgh, jsxm, xkkh, skdd, sksj, rs, qsjsz,
        null bjmc, null jxbmc, zxs, xkzt, mxdx, xzdx, ksfs, khfs,
        null as program_id,
        'cfbjxrwb' tab
    from zfxfzb.cfbjxrwb
    where kcdm <> '74000000'
    union all
    select -- 按实际执行产生的教学计划（体育课）
        substr(xn, 1, 4) || xq jxjhh, null zydm, null zymc, null zyfx,
        xn, xq, c.kcdm, c.kczwmc, a.xf, a.kcxz, a.kclb, a.kkxy, a.kkx,
        jszgh, a.jsxm, a.xkkh, a.skdd, a.sksj, a.rs, a.qsjsz,
        null bjmc, null jxbmc, a.zxs, xkzt, mxdx, xzdx, a.ksfs, a.khfs,
        null program_id,
        'tykjxrwb' tab
    from zfxfzb.tykjxrwb a
    join zfxfzb.tykkcdmb b on a.kcdm = b.kcdm
    join zfxfzb.kcdmb c on c.kcdm = b.sskcdm -- 还原体育1、体育2
)
select jxjhh, zydm, zymc, zyfx,
        xn, xq, kcdm, kcmc, xf, kcxz, kclb, kkxy, kkx,
        jszgh, jsxm, xkkh, skdd, sksj, rs,
        nvl(to_number(regexp_substr(qsjsz, '^\d+')), term.start_week) as qsz,
        nvl(to_number(regexp_substr(qsjsz, '\d+$')), term.end_week) as jsz,
        bjmc, jxbmc, zxs, xkzt, mxdx, xzdx, ksfs, khfs,
        program_id, tab
from task
join term on term.id = substr(xn, 1, 4) || xq
where nvl(xkzt, 0) <> 4;

/**
 * 教学班ID映射（未同步）
 * 建立新教学班编号与原教学任务号之间的关系。
 * 本视图只查询出ea.course_class_map中未编号的教学班，在数据库同步时，
 * 插入到ea.course_class_map表中。
 */
create or replace view ea.sv_course_class_map_unsync as
with unsynced as (
    select distinct xkkh, case
        when xkkh like '%zk000%' then
            xkkh
        else
            substr(xkkh, 1, 29) ||
            to_char(to_number(regexp_substr(xkkh, '\d+', 30)), 'fm09') ||
            regexp_substr(xkkh, '[^0-9]$', 30) -- 把最后的数字变成01，便于排序
        end as xkkh_normal
    from ea.sva_task_base a
    where xkkh not in (select course_class_code from ea.course_class_map) -- 未同步过的选课课号
)
select xkkh as course_class_code
from unsynced
order by course_class_code;

/**
 * 教学班ID映射（已同步）
 */
create or replace view ea.sv_course_class_map_synced as
select course_class_id, course_class_code, date_created
from ea.course_class_map;

/**
 * 教学班（注意：先创建ea.term，更新学期数据至最新）
 */
create or replace view ea.sv_course_class as
select distinct
    d.course_class_id as id,
    d.course_class_code as code,
    nvl(case when regexp_like(zxs, '^\d+\.\d?')  then to_number(regexp_substr(zxs, '^\d+\.\d?')) else 0 end, b.period_theory) as period_theory,
    nvl(case when regexp_like(zxs, '-\d+\.\d?$') then to_number(regexp_substr(zxs, '\d+\.\d?$')) else 0 end, b.period_experiment) as period_experiment,
    nvl(case when regexp_like(zxs, '^\+\d+$')    then to_number(regexp_substr(zxs, '\d+'))       else 0 end, b.period_weeks) as period_weeks,
    decode(program_id, null, g.id, null) as property_id, -- 对于没有计划的任务记录课程性质
    decode(khfs, '考试', 1, '考查', 2, '论文', 3, /*空*/ 9) as assess_type,
    decode(ksfs, '集中', 1, '分散', 2, /*缺省集中*/ 1) as test_type,
    qsz as start_week,
    jsz as end_week,
    to_number(substr(xn, 1, 4) || xq) as term_id,
    b.id as course_id,
    e.id as department_id,
    a.jszgh as teacher_id
from ea.sva_task_base a
join ea.sv_course b on a.kcdm = b.id
join ea.course_class_map d on a.xkkh = d.course_class_code
join ea.sv_department e on a.kkxy = e.name
left join ea.sv_property g on a.kcxz = g.name
order by code;

/**
 * 教学班-计划
 */
create or replace view ea.sv_course_class_program as
select distinct b.course_class_id, to_number(a.program_id) as program_id
from ea.sva_task_base a
join ea.course_class_map b on b.course_class_code = a.xkkh
where program_id is not null
order by course_class_id, program_id;

/**
 * 辅助视图 - 所有教学任务
 */
create or replace view ea.sva_task as
with task_with_lab as ( -- 带实验课任务
    select distinct a.xkkh
    from zfxfzb.jxrwb a
    join zfxfzb.dgjsskxxb b on a.xkkh = substr(b.xkkh, 1, length(b.xkkh) - 1)
        and a.jxjhh || a.bjmc = b.bjmc
        and a.zyfx = b.zyfx
        and substr(b.xkkh, -1, 1) >= 'A'
    where jxjhh in (select jxjhh from zfxfzb.jxjhkcxxb)
    and nvl(xkzt, 0) <> 4
), task_en as ( -- 外语
    select distinct xkkh
    from zfxfzb.jxrwb
    where jxjhh not in (select jxjhh from zfxfzb.jxjhkcxxb)
    and nvl(xkzt, 0) <> 4
), task_pe as ( -- 体育
    select distinct xkkh
    from zfxfzb.tykjxrwb
    where nvl(xkzt, 0) <> 4
), task_normal as ( -- 其它
    select distinct xkkh from ea.sva_task_base
    minus
    select xkkh from task_with_lab
    minus
    select xkkh from task_en
    minus
    select xkkh from task_pe
)
select distinct -- 正常教学任务
    a.xkkh, -- 选课课号
    a.xkkh as zkh, -- 主任务课号
    a.qsz, a.jsz, -- 起始结束周
    1 as is_primary, -- 是否主任务
    null as course_item_id, -- 课程项目ID
    'norm' as tab
from ea.sva_task_base a
join task_normal b on a.xkkh = b.xkkh
union all
select distinct -- 带实验课程的主任务
    a.xkkh, a.xkkh as zkh, a.qsz, a.jsz, c.is_primary, c.id, 'wl_t' as tab
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join ea.sv_course_item c on a.kcdm = c.course_id and ordinal = 1
union all
select distinct -- 带实验课程的实验任务
    d.xkkh, a.xkkh as zkh, a.qsz, a.jsz, c.is_primary, c.id, 'wl_e' as tab
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join ea.sv_course_item c on c.course_id = a.kcdm and ordinal = 2
join zfxfzb.dgjsskxxb d on a.xkkh = substr(d.xkkh, 1, length(d.xkkh) - 1)
union all
select distinct -- 外语
    a.xkkh, a.xkkh as zkh, a.qsz, a.jsz, c.is_primary, c.id, 'en' as tab
from ea.sva_task_base a
join task_en b on a.xkkh = b.xkkh
join ea.sv_course_item c on a.kcdm = c.course_id
join zfxfzb.bkdjjsfpb d on a.xkkh = d.xkkh and d.bz = c.name
union all
select distinct -- 体育
    a.xkkh, a.xkkh as zkh, a.qsz, a.jsz, 1, d.id, 'pe' as tab
from zfxfzb.tykjxrwb a
join task_pe b on b.xkkh = a.xkkh
join ea.sv_course_item d on a.kcdm = d.task_course_id;

/**
 * 任务ID映射（未同步）
 */
create or replace view ea.sv_task_map_unsync as
with normal as (
    select xkkh, nvl(course_item_id, '0000000000') as course_item_id -- 注意反向操作
    from ea.sva_task
), unsynced as (
    select distinct xkkh, course_item_id, case
        when xkkh like '%zk000%' then
            xkkh
        else
            substr(xkkh, 1, 29) ||
            to_char(to_number(regexp_substr(xkkh, '\d+', 30)), 'fm09') ||
            regexp_substr(xkkh, '[^0-9]$', 30) -- 把最后的数字变成01，便于排序
        end as xkkh_normal
    from normal
    where (xkkh, course_item_id) not in (
        select task_code, course_item_id from ea.task_map
    ) -- 未同步过的选课课号
)
select xkkh as task_code, course_item_id as course_item_id
from unsynced
order by task_code, course_item_id;

/**
 * 任务ID映射（已同步）
 */
create or replace view ea.sv_task_map_synced as
select task_id, task_code, course_item_id, date_created
from ea.task_map;

/**
 * 教学任务
 */
create or replace view ea.sv_task as
select distinct
    c.task_id as id,
    c.task_code as code,
    a.is_primary,
    a.qsz as start_week,
    a.jsz as end_week,
    a.course_item_id,
    b.course_class_id
from ea.sva_task a
join ea.course_class_map b on b.course_class_code = a.zkh
join ea.task_map c on c.task_code = a.xkkh and nvl(a.course_item_id, '0000000000') = c.course_item_id;

/**
 * 辅助视图 - 教学任务-教师
 */
create or replace view ea.sva_task_teacher as
with task_with_lab as ( -- 带实验课任务
    select distinct a.xkkh
    from zfxfzb.jxrwb a
    join zfxfzb.dgjsskxxb b on a.xkkh = substr(b.xkkh, 1, length(b.xkkh) - 1)
        and a.jxjhh || a.bjmc = b.bjmc
        and a.zyfx = b.zyfx
        and substr(b.xkkh, -1, 1) >= 'A'
    where jxjhh in (select jxjhh from zfxfzb.jxjhkcxxb)
    and nvl(xkzt, 0) <> 4
), task_en as ( -- 外语
    select distinct xkkh
    from zfxfzb.jxrwb
    where jxjhh not in (select jxjhh from zfxfzb.jxjhkcxxb)
    and jsxm like ('%/%') -- 多教师
    and nvl(xkzt, 0) <> 4
), task_pe as ( -- 体育
    select distinct xkkh
    from zfxfzb.tykjxrwb
    where nvl(xkzt, 0) <> 4
), task_normal as ( -- 其它
    select distinct xkkh from ea.sva_task_base
    minus
    select xkkh from task_with_lab
    minus
    select xkkh from task_en
    minus
    select xkkh from task_pe
)
(select distinct -- 正常教学任务
    a.xkkh, a.jszgh, null as course_item_id, 'norm1' as tab
from ea.sva_task_base a
join task_normal b on b.xkkh = a.xkkh
union
select distinct -- 正常教学任务（多教师）
    a.xkkh, c.jszgh, null, 'norm2'
from ea.sva_task_base a
join task_normal b on b.xkkh = a.xkkh
join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh)
union all
(select distinct -- 带实验课程的主任务
    a.xkkh, a.jszgh, c.id, 'wl_t1'
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join ea.sv_course_item c on c.course_id = a.kcdm and ordinal = 1
union
select distinct -- 带实验课程的主任务（多教师）
    a.xkkh, c.jszgh, d.id, 'wl_t2'
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
join ea.sv_course_item d on d.course_id = a.kcdm and ordinal = 1)
union all
select distinct -- 带实验课程的实验任务
    c.xkkh, c.jszgh, d.id, 'wl_e'
from ea.sva_task_base a
join task_with_lab b on b.xkkh = a.xkkh
join zfxfzb.dgjsskxxb c on substr(c.xkkh, 1, length(c.xkkh) - 1) = a.xkkh
join ea.sv_course_item d on d.course_id = a.kcdm and ordinal = 2
union all
select distinct -- 外语
    a.xkkh, d.jszgh, c.id, 'en'
from ea.sva_task_base a
join task_en b on a.xkkh = b.xkkh
join ea.sv_course_item c on c.course_id = a.kcdm
join zfxfzb.dgjsskxxb d on d.xkkh = a.xkkh and nvl(d.xh_bksj, xh) = c.ordinal
union all
select distinct -- 体育
    a.xkkh, a.jszgh, c.id, 'pe'
from zfxfzb.tykjxrwb a
join task_pe b on b.xkkh = a.xkkh
join ea.sv_course_item c on c.task_course_id = a.kcdm;

/**
 * 教学任务-教师
 */
create or replace view ea.sv_task_teacher as
select distinct b.task_id, b.task_code, jszgh as teacher_id
from ea.sva_task_teacher a
join ea.task_map b on b.task_code = a.xkkh and b.course_item_id = nvl(a.course_item_id, '0000000000')
join zfxfzb.jsxxb c on c.zgh = a.jszgh;

/**
 * 辅助视图 - 教学安排
 */
create or replace view ea.sva_task_schedule as
with task_normal_all as (
    select distinct jxjhh, xkkh, bjmc, zyfx, jszgh
    from zfxfzb.jxrwb
    where nvl(xkzt, 0) <> 4
), task_with_lab as ( -- 带实验课任务
    select distinct a.xkkh
    from task_normal_all a
    join zfxfzb.dgjsskxxb b on a.xkkh = substr(b.xkkh, 1, length(b.xkkh) - 1)
        and a.jxjhh || a.bjmc = b.bjmc
        and a.zyfx = b.zyfx
        and substr(b.xkkh, -1, 1) >= 'A'
    where a.jxjhh in (select jxjhh from zfxfzb.jxjhkcxxb)
), task_en as ( -- 外语
    select distinct xkkh
    from zfxfzb.jxrwb
    where jxjhh not in (select jxjhh from zfxfzb.jxjhkcxxb)
), task_normal as ( -- 正常任务
    select distinct xkkh from task_normal_all
    minus
    select xkkh from task_with_lab
    minus
    select xkkh from task_en
), task_other as ( -- 其它课（公选、辅修、特殊）
    select xkkh from zfxfzb.xxkjxrwb
    where nvl(xkzt, 0) <> 4
    union
    select distinct xkkh
    from zfxfzb.fxkjxrwb
    where nvl(xkzt, 0) <> 4
    union
    select distinct xkkh
    from zfxfzb.cfbjxrwb
    where nvl(xkzt, 0) <> 4
    and kcdm <> '74000000'
), tjkbapqkb_fix as (
    select xkkh, jszgh, xqj, dsz, qssj, jssj, sjdxh, qssjd, coalesce(jsbh, (
        select distinct jsbh from zfxfzb.tjkbapqkb
        where xkkh = a.xkkh and jszgh = a.jszgh and qssj = a.qssj and jssj = a.jssj and xqj = a.xqj and sjdxh = a.sjdxh
        and jsbh is not null
    )) as jsbh, kc as guid
    from zfxfzb.tjkbapqkb a
), arr_normal as (
    select xkkh, jszgh, jsbh, xqj,
        min(sjdxh) as qssjd,
        case
            when count(case when dsz='单' then dsz end)<>0 and count(case when dsz='双' then dsz end)=0  then 1
            when count(case when dsz='单' then dsz end)=0  and count(case when dsz='双' then dsz end)<>0 then 2
            else 0
        end as dsz,
        qssj as qsz,
        jssj as jsz,
        max(sjdxh) - min(sjdxh) + 1 as skcd,
        guid
    from tjkbapqkb_fix
    group by xkkh, jszgh, jsbh, xqj, qssjd, qssj, jssj, guid
)
(select distinct -- 正常教学任务
    a.xkkh, a.jszgh, c.jsbh, c.qsz, c.jsz, c.dsz, c.xqj, c.qssjd, c.skcd, c.guid,
    null as course_item_id, -- 课程项目ID
    'norm' as tab
from zfxfzb.jxrwb a
join task_normal b on b.xkkh = a.xkkh
join arr_normal c on c.xkkh = a.xkkh and c.jszgh = a.jszgh
union
select distinct -- 正常教学任务（多教师）
    a.xkkh, c.jszgh, d.jsbh, d.qsz, d.jsz, d.dsz, d.xqj, d.qssjd, d.skcd, d.guid,
    null as course_item_id,
    'norm' as tab
from zfxfzb.jxrwb a
join task_normal b on b.xkkh = a.xkkh
join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
join arr_normal d on d.xkkh = a.xkkh and d.jszgh = c.jszgh)
union all
(select distinct -- 带实验课程的主任务
    a.xkkh, a.jszgh, c.jsbh, c.qsz, c.jsz, c.dsz, c.xqj, c.qssjd, c.skcd, c.guid,
    d.id as course_item_id,
    'wl_t' as tabset
from zfxfzb.jxrwb a
join task_with_lab b on a.xkkh = b.xkkh
join arr_normal c on c.xkkh = a.xkkh and c.jszgh = a.jszgh
join ea.sv_course_item d on d.course_id = a.kcdm and ordinal = 1
union
select distinct -- 带实验课程的主任务（多教师）
    a.xkkh, c.jszgh, d.jsbh, d.qsz, d.jsz, d.dsz, d.xqj, d.qssjd, d.skcd, d.guid,
    e.id as course_item_id,
    'wl_t' as tab
from zfxfzb.jxrwb a
join task_with_lab b on a.xkkh = b.xkkh
join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
join arr_normal d on d.xkkh = a.xkkh and d.jszgh = c.jszgh
join ea.sv_course_item e on e.course_id = a.kcdm and ordinal = 1)
union all
select distinct -- 带实验课程的实验任务
    c.xkkh, c.jszgh, d.jsbh, d.qsz, d.jsz, d.dsz, d.xqj, d.qssjd, d.skcd, d.guid,
    e.id as course_item_id,
    'wl_e' as tab
from zfxfzb.jxrwb a
join task_with_lab b on b.xkkh = a.xkkh
join zfxfzb.dgjsskxxb c on substr(c.xkkh, 1, length(c.xkkh) - 1) = a.xkkh
join arr_normal d on d.xkkh = c.xkkh and d.jszgh = c.jszgh
join ea.sv_course_item e on e.course_id = a.kcdm and ordinal = 2
union all
select distinct -- 外语
    b.xkkh, b.jszgh, f.jsbh/*b.jsbh*/, b.qsz, b.jsz, decode(a.dsz, '单', 1, '双', 2, 0) as dsz, a.xqj, a.qssjd, a.skcd, b.guid,
    d.id as course_item_id,
    'en' as tab
from zfxfzb.bksjapb a
join zfxfzb.bkdjjsfpb b on b.bkdm = a.bkdm and b.bkkcmc = a.bkkcmc and
    b.nj = a.nj and b.xn = a.xn and b.xq = a.xq
    and b.xqj = a.xqj and b.qssjd = a.qssjd
    and (b.dsz = a.dsz or (b.dsz is null and a.dsz is null))
join ea.sv_course_item d on d.course_id = substr(b.xkkh, 15, 8) and d.name = b.bz
join task_en e on e.xkkh = b.xkkh
join zfxfzb.jsxxb g on g.zgh = b.jszgh -- 有不存在的教师
left join zfxfzb.jxcdxxb f on b.jsbh = f.jsbh -- 有不存在的场地
union all
select distinct -- 其它课
    a.xkkh, nvl(c.jszgh, a.jszgh) as jszgh,
    d.jsbh/*a.jsbh*/, a.qsz, a.jsz, decode(a.dsz, '单', 1, '双', 2, 0) dsz, a.xqj, a.qssjd, a.skcd,
    case
        when c.xkkh is not null then -- 多教师情况，用序号替换GUID后两位
            substr(a.bz, 1, 30) || to_char(c.xh, 'fm0X')
        else
            a.bz
    end as guid,
    null as course_item_id, -- todo: verify
    'qt' tab
from zfxfzb.qtkapb a
join task_other b on a.xkkh = b.xkkh
left join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
left join zfxfzb.jxcdxxb d on a.jsbh = d.jsbh -- 有不存在的场地
where xqj is not null
union all
select distinct  -- 体育
    xkkh, jszgh,
    b.jsbh,
    to_number(regexp_substr(sksj, '第(\d+)-(\d+)周', 1, 1, null, 1)) qsz,
    to_number(regexp_substr(sksj, '第(\d+)-(\d+)周', 1, 1, null, 2)) jsz,
    0 as dsz,
    decode(regexp_substr(sksj, '^周(.)', 1, 1, null, 1), '一', 1, '二', 2, '三', 3, '四', 4, '五', 5, '六', 6, '日', 7, '天', 7) xqj,
    to_number(regexp_substr(sksj, '第(\d+)(,\d+)*节', 1, 1, null, 1)) qssjd,
    case
        when regexp_like(sksj, '第\d+,\d+节') then 2
        when regexp_like(sksj, '第\d+,\d+,\d+,\d+节') then 4
        when regexp_like(sksj, '第\d+节') then 1
        when regexp_like(sksj, '第\d+,\d+,\d+节') then 3
    end as skcd,
    a.guid,
    c.id as course_item_id,
    'pe' tab
from zfxfzb.tykjxrwb a
join zfxfzb.jxcdxxb b on b.jsmc = a.skdd
join ea.sv_course_item c on c.task_course_id = a.kcdm
where nvl(a.xkzt, 0) <> 4;

/**
 * 教学安排（未合并）
 */
create or replace view ea.sv_task_schedule as
select distinct
    HEXTORAW(guid) as id,
    b.task_id,
    b.task_code,
    jszgh as teacher_id,
    jsbh as place_id,
    qsz as start_week,
    jsz as end_week,
    dsz as odd_even,
    xqj as day_of_week,
    qssjd as start_section,
    skcd as total_section
from ea.sva_task_schedule a
join ea.task_map b on b.task_code = a.xkkh and b.course_item_id = nvl(a.course_item_id, '0000000000');

/**
 * 学生选课
 */
create or replace view ea.sv_task_student as
select
    t.task_id,
    t.task_code,
    xh as student_id,
    to_date(xksj, 'yyyy-mm-dd HH24:MI:SS') as date_created,
    0 as register_type
from zfxfzb.xsxkb x
join ea.task_map t on t.task_code = x.xkkh;
