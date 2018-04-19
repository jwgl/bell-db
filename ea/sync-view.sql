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
        when zymc like '%国际课程班' then 1 -- 停办
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
        when zymc = '视觉传达设计（中德联合培养）' then 1
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
union
select to_number(substr(fxmkdm, 1, 8) || '2' || substr(fxmkdm, 10, 1)) as id,
    to_number(substr(fxmkdm, 1, 8) || '2') as program_id, fxmkmc as name
from zfxfzb.fxmkb
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
 * 课程
 */
create or replace view ea.sv_course as
with scheduled as ( -- 已排课的代码
    select distinct kcdm as pk_kcdm
    from ea.sva_task_base
    where (skdd is not null or sksj is not null) and xkzt <> 4
    union
    select distinct kcdm as pk_kcdm
    from zfxfzb.kcdmb
    where kcdm not in (select kcdm from zfxfzb.cjb)
)
select kcdm as id,
    kczwmc as name,
    kcywmc as english_name,
    to_number(a.xf) as credit,
    case when regexp_like(a.zxs, '^\d+\.\d?')  then to_number(regexp_substr(a.zxs, '^\d+\.\d?')) else 0 end as period_theory,
    case when regexp_like(a.zxs, '-\d+\.\d?$') then to_number(regexp_substr(a.zxs, '\d+\.\d?$')) else 0 end as period_experiment,
    case when regexp_like(a.zxs, '^\+\d+$')    then to_number(regexp_substr(a.zxs, '\d+'))       else 0 end as period_weeks,
    to_number(kcxzdm) as property_id,
    decode(kclb, '必修课', 1, '选修课', 0, '实践环节', 1, 1) as is_compulsory,
    case when regexp_like(a.zxs, '^\+\d+$') then 1 else 0 end as is_practical,
    decode(xlcc,'本科', 1, '本科毕业生', 1, '硕士研究生', 2, /*其它或空*/ 9) as education_level,
    decode(khfs, '考试', 1, '考查', 2, '毕业论文', 3, /*空*/ 9) as assess_type,
    nvl2(pk_kcdm, 1, 0) as schedule_type,
    kcjj as introduction,
    decode(tkbj, '1', 0, 1) enabled,
    case when kkbmdm is null then substr(kcdm, 1, 2) else kkbmdm end as department_id
from zfxfzb.kcdmb a
left join zfxfzb.kcxzdmb b on b.kcxzmc = a.kcxz
left join scheduled c on c.pk_kcdm = a.kcdm
where a.kcxz is not null
order by id;

/**
 * 课程项
 */
create or replace view ea.sv_course_item as
with sykc as ( -- 实验课
    select distinct substr(xkkh, 15, 8) as kcdm
    from zfxfzb.dgjsskxxb
    where substr(xkkh, -1, 1) between 'A' and 'Z'
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
-- 体育（体育课有效位+项目后4位）
select substr(sskcdm, 0, 4) || substr(sskcdm, 7, 2) || substr(kcdm, 5, 4)  as id,
    kczwmc as name,
    to_number(substr(kcdm, 5, 4)) as ordinal,
    0 as is_primary,
    sskcdm as course_id,
    kcdm as task_course_id
from zfxfzb.tykkcdmb
order by id;

/**
 * 教学计划-课程
 */
create or replace view ea.sv_program_course as
with all_program as (
    select
        jxjhh || '0' as program_id,
        kcdm as course_id,
        case when regexp_like(zxs, '^\d+\.\d?')  then to_number(regexp_substr(zxs, '^\d+\.\d?')) else 0 end as period_theory,
        case when regexp_like(zxs, '-\d+\.\d?$') then to_number(regexp_substr(zxs, '\d+\.\d?$')) else 0 end as period_experiment,
        case when regexp_like(zxs, '^\+\d+$')    then to_number(regexp_substr(zxs, '\d+'))       else 0 end as period_weeks,
        decode(kclb, '必修课', 1, '选修课', 0, '实践环节', 1, 1) as is_compulsory,
        case when regexp_like(zxs, '^\+\d+$') then 1 else 0 end as is_practical,
        to_number(kcxzdm) as property_id,
        decode(khfs, '考试', 1, '考查', 2, '毕业论文', 3, /*空*/ 9) as assess_type,
        decode(ksfs, '集中', 1, '分散', 2, /*缺省集中*/ 1) as test_type,
        to_number(regexp_substr(qsjsz, '^\d+')) as start_week,
        to_number(regexp_substr(qsjsz, '\d+$')) as end_week,
        jyxdxq as suggested_term, -- error > 8
        ea.util.csv_bit_to_number(kkkxq, jyxdxq) as allowed_term,
        1 as schedule_type,
        xydm as department_id,
        sv_direction.id as direction_id
    from zfxfzb.jxjhkcxxb
    join zfxfzb.kcxzdmb on kcxz = kcxzmc
    join zfxfzb.xydmb on kkxy = xymc
    join ea.sv_course on kcdm = sv_course.id
    left join ea.sv_direction on sv_direction.name = zyfx and sv_direction.program_id = jxjhh || 0
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
        decode(khfs, '考试', 1, '考查', 2, '毕业论文', 3, /*空*/ 9) as assess_type,
        decode(ksfs, '集中', 1, '分散', 2, /*缺省集中*/ 1) as test_type,
        to_number(regexp_substr(qsjsz, '^\d+')) as start_week,
        to_number(regexp_substr(qsjsz, '\d+$')) as end_week,
        jyxdxq as suggested_term,
        ea.util.csv_bit_to_number(kkkxq, jyxdxq) as allowed_term,
        1 as schedule_type,
        xydm as department_id,
        sv_direction.id as direction_id
    from zfxfzb.fxjxjhkcxxb
    join zfxfzb.kcxzdmb on kcxz = kcxzmc
    join zfxfzb.xydmb on kkxy = xymc
    join ea.sv_course on kcdm = sv_course.id
    left join ea.sv_direction on sv_direction.name = fxmkmc and sv_direction.program_id = jxjhh || 2 -- 辅修课从模块取专业方向
)
select to_number(program_id) as program_id, course_id, period_theory, period_experiment,
    case
        when period_weeks <> 0 then period_weeks
        else (end_week - start_week + 1)
    end as period_weeks, is_compulsory, is_practical,
    property_id, assess_type, test_type, start_week, end_week,
    suggested_term, allowed_term, schedule_type, department_id, direction_id
from all_program
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
with normal as (
    select nj, bjdm, bjmc, sszydm, ssxydm,
           decode(bzrxm, '%%', null, bzrxm) as bzrxm,
           decode(bzrxm2, '%%', null, bzrxm2) as bzrxm2
    from zfxfzb.bjdmb
)
select
    to_number(nj || sszydm || substr(bjdm, -2, 2)) id,
    bjmc as name,
    to_number(nj || sszydm) as major_id,
    ssxydm as department_id,
    bzrxm as supervisor_id,
    nvl(bzrxm2, bzrxm) as counsellor_id -- 未设置辅导员，以班主任为辅导员
from normal
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
    xm as name,
    zym as used_name,
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
    xm as name,
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
    decode(sfzc, '是', 1, 0) as is_registered,
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
    ) as foreign_language,
    0 as foreign_language_level, -- TODO: remove
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

/**
 * 学生-等级
 */
create or replace view ea.sv_student_level as
with student_level as (
  select xh, case
    when instr(substr(dj, 1, 4), '2') <> 0 then 2
    when instr(substr(dj, 1, 4), '1') <> 0 then 1
    when instr(substr(dj, 11, 14), '2') <> 0 then 2
    when instr(substr(dj, 11, 44), '1') <> 0 then 1
    end as dj
  from zfxfzb.xsjbxxb
)
select xh as student_id, '英语' as type, dj as "level"
from student_level
where dj is not null
order by xh;

/**
 * 排课板块（辅助视图）
 */
create or replace view ea.sva_timeplate_base as
select to_number(substr(a.xn, 1, 4) || a.xq || b.dm || substr(to_char(a.nj), 3, 2) ||
       case when length(a.bkdm) = 1 then '0' else '' end || a.bkdm) as bkbh,
       a.xn, a.xq, b.bkkcdm, a.bkkcmc, a.nj, a.bkdm, a.bkmc
from zfxfzb.bkdmb a
join zfxfzb.bkkcdmb b on a.bkkcmc = b.bkkcmc;

/**
 * 板块课程
 */
create or replace view ea.sv_timeplate_course as
select dm as id, bkkcdm as course_id
from zfxfzb.bkkcdmb
order by id;

/**
 * 排课板块
 */
create or replace view ea.sv_timeplate as
select bkbh as id, to_number(substr(xn, 1, 4) || xq) as term_id,
       bkkcdm as course_id, nj as grade, to_number(bkdm) as ordinal, bkmc as name
from ea.sva_timeplate_base
order by id;

/**
 * 排课板块-时段
 */
create or replace view ea.sv_timeplate_slot as
with normal as (
    select xn, xq, nj, bkkcmc, bkdm, xqj,
        case
            when count(case when dsz='单' then dsz end)<>0 and count(case when dsz='双' then dsz end)=0  then 1
            when count(case when dsz='单' then dsz end)=0  and count(case when dsz='双' then dsz end)<>0 then 2
            else 0
        end as dsz,
        min(sjdxh) as qssjd,
        max(sjdxh) - min(sjdxh) + 1 as skcd
    from zfxfzb.bkjtsjapb
    group by xn, xq, nj, bkkcmc, bkdm, xqj, qssjd
)
select b.bkbh as timeplate_id,
    a.dsz as odd_even,
    a.xqj as day_of_week,
    a.qssjd as start_section,
    a.skcd as total_section
from normal a
join ea.sva_timeplate_base b on a.xn = b.xn and a.xq = b.xq and a.bkkcmc = b.bkkcmc and a.nj = b.nj and a.bkdm = b.bkdm
order by timeplate_id, odd_even, day_of_week, start_section, total_section;

/**
 * 排课板块-行政班
 */
create or replace view ea.sv_timeplate_admin_class as
select b.bkbh as timeplate_id,
    to_number(c.nj || c.sszydm || substr(c.bjdm, -2, 2)) as admin_class_id
from zfxfzb.bkzyfpb a
join ea.sva_timeplate_base b on a.xn = b.xn and a.xq = b.xq and a.bkkcmc = b.bkkcmc and a.nj = b.nj and a.bkdm = b.bkdm
join zfxfzb.bjdmb c on (a.bjdm = c.bjdm or a.bjdm = '无' and c.sszydm = a.zydm and c.nj = a.nj)
order by timeplate_id, admin_class_id;

/**
 * 排课板块-任务
 */
create or replace view ea.sv_timeplate_task as
select -- 外语
    to_number(b.bkbh || case when c.ordinal < 10 then '0' else '' end || c.ordinal) as id,
    b.bkbh as timeplate_id,
    min(qsz) as start_week,
    max(jsz) as end_week,
    decode(dsz, null, 2, 1) as period,
    c.id as course_item_id
from zfxfzb.bkdjjsfpb a
join ea.sva_timeplate_base b on a.xn = b.xn and a.xq = b.xq and a.bkkcmc = b.bkkcmc and a.nj = b.nj and a.bkdm = b.bkdm
join ea.sv_course_item c on b.bkkcdm = c.course_id and a.bz = c.name
group by b.bkbh, c.id, c.ordinal, decode(dsz, null, 2, 1)
union all
select -- 体育
    to_number(b.bkbh || '01') as id,
    b.bkbh as timeplate_id,
    qsz as start_week,
    jsz as end_week,
    decode(dsz, null, 2, 1) as period,
    null as course_item_id
from zfxfzb.bksjapb a
join ea.sva_timeplate_base b on a.xn = b.xn and a.xq = b.xq and a.bkkcmc = b.bkkcmc and a.nj = b.nj and a.bkdm = b.bkdm
left join ea.sv_course_item c on b.bkkcdm = c.course_id and a.bz = c.name
where a.bz = '无' and qsz is not null
order by id;

/**
 * 教学班ID映射
 */
create or replace view ea.sv_course_class_map as
select term_id, course_class_id, course_class_code, date_created
from ea.course_class_map;

/**
 * 用于同步时触发生成course_class_map数据，使用insert语句触发
 */
create or replace trigger ea.sv_course_class_map_trigger
  instead of insert
  on ea.sv_course_class_map
begin
  insert into ea.course_class_map(term_id, course_class_code)
  with unsynced as (
    select distinct xn, xq, xkkh, case
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
  select to_number(substr(xn, 1, 4) || xq) as term_id, xkkh as course_class_code
  from unsynced
  order by xkkh_normal;

  delete from ea.course_class_map
  where course_class_code not in (
    select xkkh
    from ea.sva_task_base
  );
end;
/

/**
 * 教学班（注意：先创建ea.term，更新学期数据至最新）
 */
create or replace view ea.sv_course_class as
with normal as (
  select distinct d.term_id,
      d.course_class_id as id,
      d.course_class_code as code,
      a.jxbmc as name, -- 有不同的名称
      nvl(case when regexp_like(zxs, '^\d+\.\d?')  then to_number(regexp_substr(zxs, '^\d+\.\d?')) else 0 end, b.period_theory) as period_theory,
      nvl(case when regexp_like(zxs, '-\d+\.\d?$') then to_number(regexp_substr(zxs, '\d+\.\d?$')) else 0 end, b.period_experiment) as period_experiment,
      nvl(case when regexp_like(zxs, '^\+\d+$')    then to_number(regexp_substr(zxs, '\d+'))       else 0 end, b.period_weeks) as period_weeks,
      decode(program_id, null, g.id, null) as property_id, -- 对于没有计划的任务记录课程性质
      decode(khfs, '考试', 1, '考查', 2, '毕业论文', 3, /*空*/ 9) as assess_type,
      decode(ksfs, '集中', 1, '分散', 2, /*缺省集中*/ 1) as test_type,
      qsz as start_week,
      jsz as end_week,
      b.id as course_id,
      e.id as department_id,
      a.jszgh as teacher_id
  from ea.sva_task_base a
  join ea.sv_course b on a.kcdm = b.id
  join ea.course_class_map d on a.xkkh = d.course_class_code
  join ea.sv_department e on a.kkxy = e.name
  left join ea.sv_property g on a.kcxz = g.name
), timeplate_course_class as (
  select distinct a.bkbh as timeplate_id, b.xkkh as code
  from ea.sva_timeplate_base a
  join zfxfzb.bkdjjsfpb b on a.xn = b.xn and a.xq = b.xq and a.nj = b.nj and a.bkkcmc = b.bkkcmc and a.bkdm = b.bkdm
  where b.xkkh is not null
)
select term_id, id, normal.code, listagg(name, ';') within group(order by name) as name,
  period_theory, period_experiment, period_weeks,
  property_id, assess_type, test_type, start_week, end_week, course_id,
  department_id, teacher_id, timeplate_id
from normal
left join timeplate_course_class on normal.code = timeplate_course_class.code
group by term_id, id, normal.code, period_theory, period_experiment, period_weeks,
  property_id, assess_type, test_type, start_week, end_week, course_id,
  department_id, teacher_id, timeplate_id
order by code;

/**
 * 选课条件
 */
create or replace view sv_course_class_condition as
with task_base as ( -- 所有任务
  select distinct xkkh as code, 1 as include, regexp_replace(mxdx, '^,(.*),$', '\1', 1, 1, 'm') as conditions
  from zfxfzb.jxrwbview
  where mxdx is not null
  union
  select distinct xkkh as code, 0 as include, regexp_replace(xzdx, '^,(.*),$', '\1', 1, 1, 'm') as conditions
  from zfxfzb.jxrwbview
  where xzdx is not null
  union
  select xkkh as code, 1 as include, '计划内提高班' as conditions -- 使用“计划内提高班”标记英语等级2
  from zfxfzb.xxkjxrwb
  where kcxz='公共必修课'
    and kkxy ='外国语学院'
    and (mxdx is null or mxdx not like '%计划内提高班%')
    and (xzdx is null or xzdx not like '%计划内%')
), task as ( -- 任务去重
  select code, include, listagg(conditions, ',') within group (order by conditions) as conditions
  from task_base
  group by code, include
), direction as ( -- 专业方向
  select substr(zyfxdm, 1, 8) || '0' || substr(zyfxdm, 9, 1) direction_id,
    nj, zydmb.zydm, zydmb.zymc, zyfxdm, zyfxmc, xz
  from zfxfzb.zyfxb
  join zfxfzb.jxjhzyxxb on substr(zyfxdm, 1, 8) = nj || jxjhzyxxb.zydm
  join zfxfzb.zydmb on zydmb.zydm = jxjhzyxxb.zydm
), condition_base as ( -- 递归分割字符串
  select distinct code, include, level as condition_group,
    regexp_substr(conditions, '[^,]+', 1, level) as condition
  from task
  where conditions is not null
  connect by level <= regexp_count(conditions, '[^,]+')
      and prior code = code
      and prior include = include
      and prior dbms_random.value is not null
), condition_all as ( -- 去重
  select distinct code, include, min(condition_group) as condition_group, condition
  from condition_base
  group by code, include, condition
), with_sex as ( -- 包含性别
  select code, include, condition_group,
    '性别'  as condition_name, substr(condition, -2, 1) as condition_value
  from condition_all
  where condition like '%男生' or condition like '%女生'
), without_sex as ( -- 排除性别
  select code, include, condition_group, condition,
    regexp_replace(condition, '(.*)[男女]生$', '\1') as replaced
  from condition_all
  where condition not in ('男生', '女生')
), with_major as ( -- 包含年级专业
  select code, include, condition_group,
    '年级专业'  as condition_name, nj || zydm  as condition_value
  from without_sex
  join zfxfzb.jxjhzyxxb on replaced = nj || '级' || zymc
), without_major as ( -- 排除年级专业
  select code, include, condition_group, condition, replaced
  from without_sex
  where replaced not in (select nj || '级' || zymc from zfxfzb.jxjhzyxxb)
), with_direction as ( -- 包含专业方向
  select code, include, condition_group,
    '专业方向'  as condition_name, direction_id as condition_value
  from without_major
  join direction on replaced = nj || '级' || zymc || zyfxmc
), without_direction as ( -- 排除专业方向
  select code, include, condition_group, condition, replaced
  from without_major a
  where replaced not in (select nj || '级' || zymc || zyfxmc from direction)
), with_grade as ( -- 包含年级
  select distinct code, include, condition_group,
    '年级'  as condition_name, substr(replaced, 1, 4) as condition_value
  from without_direction
  where replaced like'____级%'
), without_grade as ( -- 排除年级
  select code, include, condition_group, condition,
    regexp_replace(replaced, '^\d{4}级(.*)', '\1') as replaced
  from without_direction
  where replaced not like '____级'
), with_department as ( -- 包含学院
  select distinct code, include, condition_group,
    '学院'  as condition_name, xydm as condition_value
  from without_grade
  join zfxfzb.xydmb on instr(replaced, xymc) = 1
), without_department as (  -- 排除学院
  select code, include, condition_group, condition,
    replace(replaced, xymc) as replaced
  from without_grade
  left join zfxfzb.xydmb on replaced like xymc || '%'
  where replaced not in (select xymc from zfxfzb.xydmb)
), with_admin_class as ( -- 包含班级
  select code, include, condition_group,
    '班级'  as condition_name, nj || sszydm || substr(bjdm, -2, 2) as condition_value
  from without_department
  join zfxfzb.bjdmb on replaced = bjmc
), without_admin_class as ( -- 排除班级
  select code, include, condition_group, condition, replaced
  from without_department
  where replaced not in (select bjmc from zfxfzb.bjdmb)
), with_english_level as ( -- 包含英语等级
  select code, include, condition_group,
    '英语等级'  as condition_name, '2' as condition_value
  from without_admin_class
  where replaced = '计划内提高班' and include = 1 or replaced = '计划内' and include = 0
), without_student_level as (  -- 排除英语等级
  select code, include, condition_group, condition, replaced
  from without_admin_class
  where not (replaced = '计划内提高班' and include = 1 or replaced = '计划内' and include = 0)
), subject_name_1 as ( -- 唯一专业
  select zymc from zfxfzb.zydmb group by zymc having count(*) = 1
), subject_name_n as ( -- 重名专业
  select zymc from zfxfzb.zydmb group by zymc having count(*) > 1
), with_subject as ( -- 包含专业
  -- 唯一专业名称
  select code, include, condition_group,
    '专业'  as condition_name, zydm as condition_value
  from without_student_level
  join zfxfzb.zydmb on replaced = zymc
  join subject_name_1 on replaced = subject_name_1.zymc
  union
  -- 重复专业，存在教学计划
  select distinct code, include, condition_group,
    '专业'  as condition_name, jxjhzyxxb.zydm as condition_value
  from without_student_level
  join zfxfzb.jxrwbview on code = jxrwbview.xkkh
  join zfxfzb.jxjhzyxxb on jxrwbview.jxjhh = jxjhzyxxb.jxjhh and replaced = jxjhzyxxb.zymc
  join subject_name_n on replaced = subject_name_n.zymc
  union
  -- 重复专业，公选课中开课单位关联专业
  select code, include, condition_group,
    '专业'  as condition_name, zydmb.zydm as condition_value
  from without_student_level
  join zfxfzb.jxrwbview on code = jxrwbview.xkkh and jxrwbview.tab = 'xxkjxrwb'
  join zfxfzb.xydmb on jxrwbview.kkxy = xymc
  join zfxfzb.zydmb on replaced = zydmb.zymc and substr(zydmb.zydm, 1, 2) = xydmb.xydm
  join subject_name_n on replaced = subject_name_n.zymc
), with_cross_subject as ( -- 包含专业（根据年级/学制，存在交叉）
  -- 重复专业，根据专业年级区间
  select code, include, zydm * 100 + condition_group as condition_group,
    '专业'  as condition_name, zydm as condition_value
  from (
    select code, include, condition_group, condition, replaced
    from without_student_level
    where (code, include, condition_group, condition) not in (
      select code, include, condition_group, condition from with_subject
    )
  ) a join (
    select zydmb.zydm, zydmb.zymc, min(nj) as min_nj, max(nj + xz) as max_nj
    from zfxfzb.zydmb
    join zfxfzb.jxjhzyxxb on zydmb.zydm = jxjhzyxxb.zydm
    group by zydmb.zydm, zydmb.zymc
  ) b on a.replaced = b.zymc and substr(code, 2, 4) between min_nj and max_nj
), without_subject as ( -- 排除专业
  select code, include, condition_group, condition, replaced
  from without_student_level
  where replaced not in (
    select zymc from zfxfzb.zydmb
  )
), with_cross_direction as ( -- 包含专业方向（交叉）
  select code, include, substr(direction_id, 2) * 100 + condition_group as condition_group,
    '专业方向'  as condition_name, direction_id as condition_value
  from without_subject
  join direction on (replaced = zyfxmc or replaced = zymc || zyfxmc) and substr(code, 2, 4) between nj and nj + xz - 1
), without_cross_direction as ( -- 排除专业方向（交叉）
  select code, include, condition_group, condition, replaced
  from without_subject
  where replaced not in (
    select zyfxmc from direction
    union
    select zymc || zyfxmc from direction
  )
), condition_normal as (
  select * from with_sex
  union
  select * from with_major
  union
  select * from with_direction
  union
  select * from with_grade
  union
  select * from with_department
  union
  select * from with_admin_class
  union
  select * from with_english_level
  union
  select * from with_subject
  union
  select * from with_cross_subject
  union
  select * from with_cross_direction
)
select course_class_id, include, condition_group, condition_name, condition_value
from condition_normal
join ea.course_class_map on course_class_code = code
order by 1, 2 desc, 3, 5;

/**
 * 教学班-计划
 */
create or replace view ea.sv_course_class_program as
select distinct b.term_id, b.course_class_id, to_number(a.program_id) as program_id
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
    a.xn, a.xq, -- 学年学期
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
    a.xn, a.xq, a.xkkh, a.xkkh as zkh, a.qsz, a.jsz, c.is_primary, c.id, 'wl_t' as tab
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join ea.sv_course_item c on a.kcdm = c.task_course_id and ordinal = 1
union all
select distinct -- 带实验课程的实验任务
    a.xn, a.xq, d.xkkh, a.xkkh as zkh, a.qsz, a.jsz, c.is_primary, c.id, 'wl_e' as tab
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join ea.sv_course_item c on a.kcdm = c.task_course_id and ordinal = 2
join zfxfzb.dgjsskxxb d on a.xkkh = substr(d.xkkh, 1, length(d.xkkh) - 1)
union all
select distinct -- 外语
    a.xn, a.xq, a.xkkh, a.xkkh as zkh, a.qsz, a.jsz, c.is_primary, c.id, 'en' as tab
from ea.sva_task_base a
join task_en b on a.xkkh = b.xkkh
join ea.sv_course_item c on a.kcdm = c.task_course_id
join zfxfzb.bkdjjsfpb d on a.xkkh = d.xkkh and d.bz = c.name
union all
select distinct -- 体育
    a.xn, a.xq, a.xkkh, a.xkkh as zkh, a.qsz, a.jsz, 1, c.id, 'pe' as tab
from zfxfzb.tykjxrwb a
join task_pe b on b.xkkh = a.xkkh
join ea.sv_course_item c on a.kcdm = c.task_course_id;

/**
 * 教学任务ID映射
 */
create or replace view ea.sv_task_map as
select term_id, task_id, task_code, course_item_id, date_created
from ea.task_map;

/**
 * 用于同步时触发生成task_map数据，使用insert语句触发
 */
create or replace trigger ea.sv_task_map_trigger
  instead of insert
  on ea.sv_task_map
begin
  insert into ea.task_map(term_id, task_code, course_item_id)
  with normal as (
    select xn, xq, xkkh, nvl(course_item_id, '0000000000') as course_item_id -- 注意反向操作
    from ea.sva_task
  ), unsynced as (
      select distinct xn, xq, xkkh, course_item_id, case
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
  select to_number(substr(xn, 1, 4) || xq) as term_id, xkkh as task_code, course_item_id
  from unsynced
  order by xkkh_normal, course_item_id;

  delete from ea.task_map
  where (task_code, course_item_id) not in (
    select xkkh, nvl(course_item_id, '0000000000')
    from ea.sva_task
  );
end;
/

/**
 * 教学任务
 */
create or replace view ea.sv_task as
select distinct
    b.term_id,
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
    join zfxfzb.dgjsskxxb b on a.xkkh = substr(b.xkkh, 1, length(b.xkkh) - 1) and substr(b.xkkh, -1, 1) >= 'A'
    and nvl(xkzt, 0) <> 4
), task_en as ( -- 外语
    select distinct xkkh
    from zfxfzb.jxrwb
    where substr(jxjhh, 5, 1) = 'a'
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
select distinct -- 正常教学任务（多教师）
    a.xkkh, coalesce(c.jszgh, a.jszgh) as jszgh, null as course_item_id, 'norm1' as tab
from ea.sva_task_base a
join task_normal b on b.xkkh = a.xkkh
left join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
union all
select distinct -- 带实验课程的主任务（多教师）
    a.xkkh, coalesce(d.jszgh, a.jszgh) as jszgh, c.id, 'wl_t'
from ea.sva_task_base a
join task_with_lab b on a.xkkh = b.xkkh
join ea.sv_course_item c on c.course_id = a.kcdm and ordinal = 1
left join zfxfzb.dgjsskxxb d on d.xkkh = a.xkkh
union all
select distinct -- 带实验课程的实验任务
    d.xkkh, d.jszgh, c.id, 'wl_e'
from ea.sva_task_base a
join task_with_lab b on b.xkkh = a.xkkh
join ea.sv_course_item c on c.course_id = a.kcdm and ordinal = 2
join zfxfzb.dgjsskxxb d on substr(d.xkkh, 1, length(d.xkkh) - 1) = a.xkkh
union all
select distinct -- 外语
    a.xkkh, d.jszgh, c.id, 'en'
from ea.sva_task_base a
join task_en b on a.xkkh = b.xkkh
join ea.sv_course_item c on c.course_id = a.kcdm
join zfxfzb.dgjsskxxb d on d.xkkh = a.xkkh and nvl(d.xh, xh) = c.ordinal
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
select distinct b.term_id, b.task_id, jszgh as teacher_id
from ea.sva_task_teacher a
join ea.task_map b on b.task_code = a.xkkh and b.course_item_id = nvl(a.course_item_id, '0000000000')
join zfxfzb.jsxxb c on c.zgh = a.jszgh;

/**
 * 辅助视图 - 教学安排(不含调课)
 */
create or replace view ea.sva_task_schedule as
with task_normal_all as (
    select distinct jxjhh, xkkh, bjmc, zyfx, jszgh
    from zfxfzb.jxrwb
    where nvl(xkzt, 0) <> 4
), task_with_lab as ( -- 带实验课任务
    select distinct a.xkkh
    from task_normal_all a
    join zfxfzb.dgjsskxxb b on a.xkkh = substr(b.xkkh, 1, length(b.xkkh) - 1) and substr(b.xkkh, -1, 1) >= 'A'
), task_en as ( -- 外语
    select distinct xkkh
    from task_normal_all
    where substr(jxjhh, 5, 1) = 'a'
), task_normal as ( -- 正常任务
    select xkkh from task_normal_all
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
), arr_normal as (
    select xkkh, jszgh, jsbh, xqj,
        min(sjdxh) as qssjd,
        decode(sign(sum(decode(dsz, '单', -1, '双', 1))), -1, 1, 1, 2, 0) as dsz,
        qssj as qsz,
        jssj as jsz,
        max(sjdxh) - min(sjdxh) + 1 as skcd,
        kc as guid,sknr
    from zfxfzb.tjkbapqkb
    group by xkkh, jszgh, jsbh, xqj, qssjd, qssj, jssj, kc, sknr
), task_normal_info as (
    select distinct -- 正常教学任务（多教师）
        a.xn, a.xq, a.kcdm, a.xkkh, coalesce(c.jszgh, a.jszgh) as jszgh,
        null as course_item_id, -- 课程项目ID
        'norm' as tab
    from zfxfzb.jxrwb a
    join task_normal b on b.xkkh = a.xkkh
    left join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
    union all
    select distinct -- 带实验课程的主任务（多教师）
        a.xn, a.xq, a.kcdm, a.xkkh, coalesce(c.jszgh, a.jszgh) as jszgh,
        a.kcdm || '01' as course_item_id,
        'wl_t' as tabset
    from zfxfzb.jxrwb a
    join task_with_lab b on a.xkkh = b.xkkh
    left join zfxfzb.dgjsskxxb c on c.xkkh = a.xkkh
    union all
    select distinct -- 带实验课程的实验任务
        a.xn, a.xq, a.kcdm, c.xkkh, c.jszgh,
        a.kcdm || '02' as course_item_id,
        'wl_e' as tab
    from zfxfzb.jxrwb a
    join task_with_lab b on a.xkkh = b.xkkh
    join zfxfzb.dgjsskxxb c on substr(c.xkkh, 1, length(c.xkkh) - 1) = a.xkkh
)
select a.xn, a.xq, a.kcdm, a.xkkh, c.jszgh, c.jsbh, c.qsz, c.jsz, c.dsz,
    c.xqj, c.qssjd, c.skcd, c.guid, course_item_id, tab, c.sknr
from task_normal_info a
join arr_normal c on a.xkkh=c.xkkh and a.jszgh=c.jszgh
union all
select distinct -- 外语
    a.xn,a.xq,d.course_id,b.xkkh, b.jszgh, b.jsbh, b.qsz, b.jsz, decode(a.dsz, '单', 1, '双', 2, 0) as dsz,
    a.xqj, a.qssjd, a.skcd, b.guid, d.id as course_item_id, 'en' as tab,'5' sknr
from zfxfzb.bksjapb a
join zfxfzb.bkdjjsfpb b on b.bkdm = a.bkdm and b.bkkcmc = a.bkkcmc and
    b.nj = a.nj and b.xn = a.xn and b.xq = a.xq
    and b.xqj = a.xqj and b.qssjd = a.qssjd
    and (b.dsz = a.dsz or (b.dsz is null and a.dsz is null))
join ea.sv_course_item d on d.course_id = substr(b.xkkh, 15, 8) and d.name = b.bz
join task_en e on e.xkkh = b.xkkh
join zfxfzb.jsxxb g on g.zgh = b.jszgh -- 有不存在的教师
union all
select distinct -- 其它课
    a.xn, to_number(a.xq), a.kcdm ,a.xkkh, a.jszgh,
    a.jsbh, a.qsz, a.jsz, decode(a.dsz, '单', 1, '双', 2, 0) dsz, a.xqj, a.qssjd, a.skcd,
    a.bz,
    null as course_item_id, -- todo: verify
    'qt' tab,'5' sknr
from zfxfzb.qtkapb a
join task_other b on a.xkkh = b.xkkh
where xqj is not null
union all
select distinct  -- 体育
    a.xn, a.xq, a.kcdm,  xkkh, jszgh,
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
    'pe' tab, '5' sknr
from zfxfzb.tykjxrwb a
join zfxfzb.jxcdxxb b on b.jsmc = a.skdd
join ea.sv_course_item c on c.task_course_id = a.kcdm
where nvl(a.xkzt, 0) <> 4;

/**
 * 教学安排（未合并）
 */
create or replace view ea.sv_task_schedule as
with task_schedule as (
    select a.guid, a.xkkh, a.course_item_id,
           a.qsz, a.jsz, a.xqj, a.qssjd, a.jsbh, a.jszgh, a.dsz, a.skcd,
           null as root_guid
    from ea.sva_task_schedule a
    left join zfxfzb.ttkjlb b on a.xkkh = b.xkkh and a.guid = b.guid and b.flag >= 1
    where b.guid is null
    union all
    select guid, xkkh, course_item_id,
           qsz, jsz, xqj, qssjd, jsbh, jszgh, dsz, skcd,
           root_guid
    from zfxfzb.ttkjlb
    where flag = 1
)
select b.term_id,
    HEXTORAW(guid) as id,
    b.task_id,
    jszgh as teacher_id,
    jsbh as place_id,
    qsz as start_week,
    jsz as end_week,
    dsz as odd_even,
    xqj as day_of_week,
    qssjd as start_section,
    skcd as total_section,
    HEXTORAW(root_guid) as root_id
from task_schedule a
join ea.task_map b on b.task_code = a.xkkh and b.course_item_id = nvl(a.course_item_id, '0000000000');

/**
 * 学生选课
 */
create or replace view ea.sv_task_student as
select term_id,
    task_id,
    xh as student_id,
    to_date(xksj, 'yyyy-mm-dd HH24:MI:SS') as date_created,
    decode(xsf,
        '6', 0, -- 排课
        '1', 1, -- 选课
        '2', 2  -- 跨专业选课
    ) as register_type,
    nvl(cxbj, 0) as repeat_type,
    decode(bz,
        null,       0,
        '取消资格', 1,
        '缓考',     2
    ) as exam_flag
from zfxfzb.xsxkb
join ea.task_map on task_code = xkkh;

/**
 * 教学班考核方案
 */
create or replace view ea.sv_course_class_assessment as
with assess_normal as (
  select distinct xkkh,
    round(to_number(nvl(pscj,0)) / 100.0, 2) as pscj, '考查' as psfs,
    round(to_number(nvl(sycj,0)) / 100.0, 2) as sycj, '考查' as syfs,
    round(to_number(nvl(qzcj,0)) / 100.0, 2) as qzcj, khfs as qzfs,
    round(to_number(nvl(qmcj,0)) / 100.0, 2) as qmcj, khfs as qmfs,
    khfs as bkfs
  from zfxfzb.jxrwbview
), assess_ratio as (
  select *
  from assess_normal
  unpivot(
    (assess_type, assess_ratio) for assess_stage in (
      (psfs, pscj) as '平时',
      (syfs, sycj) as '实验',
      (qzfs, qzcj) as '期中',
      (qmfs, qmcj) as '期末'
    )
  )
  where assess_ratio > 0
)
select
  b.course_class_id,
  b.course_class_code,
  a.assess_stage,
  a.assess_type,
  a.assess_ratio
from assess_ratio a
join course_class_map b on a.xkkh = b.course_class_code;

/**
 * 选课课号与成绩来源映射
 */
create or replace view ea.sv_course_class_suffix_map as
select course_class_code, course_grade_source_code, submit_type, suffix
from ea.course_class_suffix_map;

/**
 * 用于同步时触发生成course_class_suffix_map数据，使用insert语句触发
 */
create or replace trigger ea.sv_course_class_suffix_map_trigger
  instead of insert
  on ea.sv_course_class_suffix_map
begin
  merge into ea.course_class_suffix_map a
  using (
    select x.xkkh as course_class_code, case y.trim_flag
      when 2 then substr(x.xkkh, 1, length(x.xkkh) - length(y.suffix) + 1)
      when 1 then substr(x.xkkh, 1, length(x.xkkh) - length(y.suffix))
      else x.xkkh
    end as course_grade_source_code,
    y.submit_type,
    substr(y.suffix, y.trim_flag) as suffix
    from (select distinct coalesce(xmdm, xkkh) as xkkh from zfxfzb.cjb) x
    join ea.course_class_suffix y on reverse(x.xkkh) like reverse('%' || y.suffix)
  ) b on (a.course_class_code = b.course_class_code)
  when not matched then insert (course_class_code, course_grade_source_code, submit_type, suffix)
    values(b.course_class_code, b.course_grade_source_code, b.submit_type, b.suffix)
  when matched then update set
    course_grade_source_code = b.course_grade_source_code,
    submit_type = b.submit_type,
    suffix = b.suffix;

  delete from ea.course_class_suffix_map
  where (course_class_code) not in (
    select coalesce(xmdm, xkkh) as xkkh from zfxfzb.cjb
  );
end;
/

/**
 * 辅助视图-课程考核阶段
 */
create or replace view ea.sva_course_assessment_stage as
with grade_normal_count_base as ( -- 正考及其它成绩
  select coalesce(xmdm, xkkh) as xkkh,
    count(zscj) as zpcj_count,
    count(pscj) as pscj_count,
    count(sycj) as sycj_count,
    count(qzcj) as qzcj_count,
    count(qmcj) as qmcj_count
  from zfxfzb.cjb
  group by coalesce(xmdm, xkkh)
), grade_normal_count as (
  select coalesce(course_grade_source_code, xkkh) as xkkh,
    zpcj_count, pscj_count, sycj_count, qzcj_count, qmcj_count,
    nvl(submit_type, '正考') as submit_type, suffix
  from grade_normal_count_base a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), grade_makeup_count_base as ( -- 补考成绩
  select coalesce(xmdm, xkkh) as xkkh,
    count(bkcj) as zpcj_count,
    count(bkcj) as bkcj_count
  from zfxfzb.cjb
  where bkcj is not null
  group by coalesce(xmdm, xkkh)
), grade_makeup_count as (
  select coalesce(course_grade_source_code, xkkh) as xkkh,
    zpcj_count, bkcj_count,
    '补考' as submit_type, suffix
  from grade_makeup_count_base a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), grade_deferred_count_base as ( -- 缓考成绩
  select coalesce(xmdm, xkkh) as xkkh,
    count(zscj) as zpcj_count,
    count(zscj) as hkcj_count
  from zfxfzb.cjb
  where bz = '缓考'
  group by coalesce(xmdm, xkkh)
), grade_deferred_count as (
  select coalesce(course_grade_source_code, xkkh) as xkkh,
    zpcj_count, hkcj_count,
    '补考' as submit_type, suffix
  from grade_deferred_count_base a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), grade_count_unpivot as (
  select xkkh, submit_type, assess_stage, grade_count, suffix
  from grade_normal_count
  unpivot(
    (grade_count) for assess_stage in (
      zpcj_count as '总评',
      pscj_count as '平时',
      sycj_count as '实验',
      qzcj_count as '期中',
      qmcj_count as '期末'
    )
  )
  where grade_count > 0
  union all
  select xkkh, submit_type, assess_stage, grade_count, suffix
  from grade_makeup_count
  unpivot(
    (grade_count) for assess_stage in (
      zpcj_count as '总评',
      bkcj_count as '补考'
    )
  )
  where grade_count > 0
  union all
  select xkkh, submit_type, assess_stage, grade_count, suffix
  from grade_deferred_count
  unpivot(
    (grade_count) for assess_stage in (
      zpcj_count as '总评',
      hkcj_count as '缓考'
    )
  )
  where grade_count > 0
)
select xkkh, submit_type, assess_stage,
  sum(grade_count) grade_count,
  listagg(suffix, ',') within group(order by suffix) as suffixes
from grade_count_unpivot
group by xkkh, submit_type, assess_stage;

/**
 * 课程成绩提交ID映射
 */
create or replace view ea.sv_course_grade_submit_map as
select term_id, course_grade_submit_id, course_class_code, submit_type, date_submitted，date_created
from ea.course_grade_submit_map;

/**
 * 用于同步时触发生成course_assessment_map和course_grade_submit_map数据，使用insert语句触发
 */
create or replace trigger ea.sv_course_grade_submit_map_trigger
  instead of insert
  on ea.sv_course_grade_submit_map
begin
  -- 合并course_assessment_map
  merge into ea.course_assessment_map a
  using (
    select to_number(substr(xkkh, 2, 4) || substr(xkkh, 12, 1)) as term_id,
      xkkh as course_class_code, submit_type, assess_stage
    from ea.sva_course_assessment_stage
  ) b on (a.course_class_code = b.course_class_code and a.assess_stage = b.assess_stage)
  when not matched then insert (term_id, course_class_code, submit_type, assess_stage)
  values(b.term_id, b.course_class_code, b.submit_type, b.assess_stage);

  delete from ea.course_assessment_map
  where (course_class_code, assess_stage) not in (
    select xkkh, assess_stage
    from ea.sva_course_assessment_stage
  );

  -- 合并course_grade_submit_map
  merge into ea.course_grade_submit_map a
  using (
    select distinct term_id, course_class_code, submit_type
    from ea.course_assessment_map
    order by course_class_code, submit_type
  ) b on (a.course_class_code = b.course_class_code and a.submit_type = b.submit_type)
  when not matched then insert (term_id, course_class_code, submit_type)
  values(b.term_id, b.course_class_code, b.submit_type);

  delete from ea.course_grade_submit_map
  where (course_class_code, submit_type) not in (
    select distinct course_class_code, submit_type
    from ea.course_assessment_map
  );

  -- 计算初次提交时间，修改任务表后可直接获取
  merge into ea.course_grade_submit_map a
  using (
    select xkkh as course_class_code, to_timestamp(min(cjdate), 'YYYY-MM-DD HH24:MI:SS') as date_submitted
    from zfxfzb.cjb
    where xn || '-' || xq >= '2013-2014-2'
    group by xkkh
  ) b on (a.course_class_code = b.course_class_code and a.submit_type='正考')
  when matched then update set date_submitted = b.date_submitted;
end;
/

/**
 * 课程成绩来源ID映射
 */
create or replace view ea.sv_course_grade_source_map as
select term_id, course_grade_source_id, course_grade_source_code, date_created
from ea.course_grade_source_map;

/**
 * 用于同步时触发生成sv_course_grade_source_map数据，使用insert语句触发
 */
create or replace trigger ea.sv_course_grade_source_map_trigger
  instead of insert
  on ea.sv_course_grade_source_map
begin
  merge into ea.course_grade_source_map a
  using (
    select distinct x.term_id, x.course_class_code
    from course_grade_submit_map x
    left join ea.course_class_map y on x.course_class_code = y.course_class_code
    where y.course_class_id is null
  ) b on (a.course_grade_source_code = b.course_class_code)
  when not matched then insert (term_id, course_grade_source_code)
  values(b.term_id, b.course_class_code);

  delete from ea.course_grade_source_map
  where (course_grade_source_code) not in (
    select x.course_class_code
    from course_grade_submit_map x
    left join ea.course_class_map y on x.course_class_code = y.course_class_code
    where y.course_class_id is null
  );
end;
/

/**
 * 课程成绩提交
 */
create or replace view ea.sv_course_grade_submit as
select a.course_grade_submit_id as id,
  b.course_class_id as course_grade_source_id,
  1 as course_grade_source_type, -- 来自教学班
  submit_type, c.teacher_id, a.date_submitted, a.term_id
from ea.course_grade_submit_map a
join ea.course_class_map b on a.course_class_code = b.course_class_code
left join ea.sv_course_class c on a.course_class_code = c.code
union all
select a.course_grade_submit_id as id,
  b.course_grade_source_id,
  2 as course_grade_source_type, -- 来自其它
  submit_type, null as teacher_id, a.date_submitted, a.term_id
from ea.course_grade_submit_map a
join ea.course_grade_source_map b on a.course_class_code = b.course_grade_source_code;

/**
 * 课程考核
 */
create or replace view ea.sv_course_assessment as
select a.course_assessment_id as id,
  b.course_grade_submit_id,
  assess_stage
from ea.course_assessment_map a
join ea.course_grade_submit_map b on a.course_class_code = b.course_class_code and a.submit_type = b.submit_type

/**
 * 课程考核成绩
 */
create or replace view ea.sv_course_assessment_grade as
with assess_normal_grade_base as ( -- 正考及其它成绩
  select coalesce(xmdm, xkkh) as xkkh, xh,
    case bz when '缓考' then '0' else cj end as zpcj,
    b.value as zpcj_flag,
    nvl2(b.value, bzxx, case
      when bz is not null and bzxx is not null then bz || '|' || bzxx
      when bz is null then bzxx
      when bzxx is null then bz
    end) as zpcj_note,
    pscj, null as pscj_flag, null as pscj_note,
    sycj, null as sycj_flag, null as sycj_note,
    qzcj, null as qzcj_flag, null as qzcj_note,
    case bz when '缓考' then '0' else qmcj end as qmcj,
    b.value as qmcj_flag,
    nvl2(b.value, null, bz) as qmcj_note
  from zfxfzb.cjb a
  left join ea.assess_flag b on a.bz = b.id
), assess_normal_grade as (
  select coalesce(course_grade_source_code, xkkh) as xkkh, xh,
    zpcj, zpcj_flag, zpcj_note,
    pscj, pscj_flag, pscj_note,
    sycj, sycj_flag, sycj_note,
    qzcj, qzcj_flag, qzcj_note,
    qmcj, qmcj_flag, qmcj_note,
    nvl(submit_type, '正考') as submit_type,
    suffix
  from assess_normal_grade_base a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), assess_makeup_grade_base as ( -- 补考成绩
  select coalesce(xmdm, xkkh) as xkkh, xh,
    bkcj as zpcj, null as zpcj_flag, null as zpcj_note,
    bkcj, b.value as bkcj_flag, nvl2(b.value, null, bkcj_bz) as bkcj_note
  from zfxfzb.cjb a
  left join ea.assess_flag b on a.bkcj_bz = b.id
  where bkcj is not null
), assess_makeup_grade as (
  select coalesce(course_grade_source_code, xkkh) as xkkh, xh,
    zpcj, zpcj_flag, zpcj_note,
    bkcj, bkcj_flag, bkcj_note,
    '补考' as submit_type,
    suffix
  from assess_makeup_grade_base a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), assess_defered_grade_base as ( -- 缓考成绩
  select coalesce(xmdm, xkkh) as xkkh, xh,
    cj as zpcj, null as zpcj_flag, null as zpcj_note,
    qmcj as hkcj, b.value as hkcj_flag, nvl2(b.value, null, bkcj_bz) as hkcj_note
  from zfxfzb.cjb a
  left join ea.assess_flag b on a.bkcj_bz = b.id
  where bz = '缓考'
), assess_defered_grade as (
  select coalesce(course_grade_source_code, xkkh) as xkkh, xh,
    zpcj, zpcj_flag, zpcj_note,
    hkcj, hkcj_flag, hkcj_note,
    '补考' as submit_type,
    suffix
  from assess_defered_grade_base a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), assess_stage_grade as (
  select xkkh, xh, submit_type, assess_stage, grade, assess_flag, note
  from assess_normal_grade
  unpivot(
    (grade, assess_flag, note) for assess_stage in (
      (zpcj, zpcj_flag, zpcj_note) as '总评',
      (pscj, pscj_flag, pscj_note) as '平时',
      (sycj, sycj_flag, sycj_note) as '实验',
      (qzcj, qzcj_flag, qzcj_note) as '期中',
      (qmcj, qmcj_flag, qmcj_note) as '期末'
    )
  )
  union all
  select xkkh, xh, submit_type, assess_stage, grade, assess_flag, note
  from assess_makeup_grade
  unpivot(
    (grade, assess_flag, note) for assess_stage in (
      (zpcj, zpcj_flag, zpcj_note) as '总评',
      (bkcj, bkcj_flag, bkcj_note) as '补考'
    )
  )
  union all
  select xkkh, xh, submit_type, assess_stage, grade, assess_flag, note
  from assess_defered_grade
  unpivot(
    (grade, assess_flag, note) for assess_stage in (
      (zpcj, zpcj_flag, zpcj_note) as '总评',
      (hkcj, hkcj_flag, hkcj_note) as '缓考'
    )
  )
), assess_stage_grade_normal as (
  select xkkh as course_class_code,
    submit_type,
    assess_stage,
    xh as student_id,
    cjdzb.cj as letter_grade,
    coalesce(cjdzb.dycj, round(to_number(grade), 1)) as percentage_grade,
    assess_flag, note
  from assess_stage_grade
  left join zfxfzb.cjdzb on cjdzb.cj = grade
)
select term_id, b.course_assessment_id, student_id,
  letter_grade, percentage_grade, assess_flag, note
from assess_stage_grade_normal a
join ea.course_assessment_map b on a.course_class_code = b.course_class_code
 and a.submit_type = b.submit_type
 and a.assess_stage = b.assess_stage;

/**
 * 学生成绩
 */
create or replace view ea.sv_student_grade as
with assess_normal_grade as ( -- 正考及其它成绩
  select coalesce(xmdm, xkkh) as xkkh, xh,
    decode(bz, '缓考', '0', cj) as grade, b.value as flag, cjdate, xgsj,
    nvl2(b.value,
      case when bz = '缓考' and bzxx = '学院申请' then null else bzxx end,
      case when bz is not null and bzxx is not null then bz || '|' || bzxx else coalesce(bz, bzxx) end
    ) as note
  from zfxfzb.cjb a
  left join ea.assess_flag b on a.bz = b.id
), assess_makeup_grade as ( -- 补考成绩
  select coalesce(xmdm, xkkh) as xkkh, xh,
    bkcj as grade, b.value as flag, cjdate, xgsj,
    bzxx as note
  from zfxfzb.cjb a
  left join ea.assess_flag b on a.bkcj_bz = b.id
  where bkcj is not null
), assess_defered_grade as ( -- 缓考成绩
  select coalesce(xmdm, xkkh) as xkkh, xh,
    cj as grade, b.value as flag, cjdate, xgsj,
    nvl2(b.value,
      bzxx,
      case when bz is not null and bzxx is not null then bz || '|' || bzxx else coalesce(bz, bzxx) end
    ) as note
  from zfxfzb.cjb a
  left join ea.assess_flag b on a.bkcj_bz = b.id
  where bz = '缓考'
), assess_stage_grade as (
  select coalesce(course_grade_source_code, xkkh) as xkkh, xh,
    grade, flag, cjdate, xgsj, note,
    nvl(submit_type, '正考') as submit_type, suffix
  from assess_normal_grade a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
  union all
  select coalesce(course_grade_source_code, xkkh) as xkkh, xh,
    grade, flag, cjdate, xgsj, note,
    '补考' as submit_type, suffix
  from assess_makeup_grade a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
  union all
  select coalesce(course_grade_source_code, xkkh) as xkkh, xh,
    grade, flag, cjdate, xgsj, note,
    '补考' as submit_type, suffix
  from assess_defered_grade a
  left join ea.sv_course_class_suffix_map b on a.xkkh = b.course_class_code
), assess_stage_grade_normal as (
  select xkkh as course_class_code,
    submit_type,
    xh as student_id,
    cjdzb.cj as letter_grade,
    coalesce(cjdzb.dycj, round(to_number(grade),1), 0) as percentage_grade,
    flag as assess_flag,
    to_timestamp(cjdate, 'YYYY-MM-DD HH24:MI:SS') as date_created,
    to_timestamp(xgsj, case
      when xgsj like '%,%'
      then 'YYYY MM"月"  DD,HH24:MI:SS'
      else 'YYYY-MM-DD HH24:MI:SS'
    end) as date_modified,
    note
  from assess_stage_grade
  left join zfxfzb.cjdzb on cjdzb.cj = grade
)
select term_id, b.course_grade_submit_id, substr(a.course_class_code, 15, 8) as course_id, student_id,
  letter_grade, percentage_grade, assess_flag, a.date_created,
    case
      when a.date_created = date_modified then null
      else date_modified
    end as date_modified, note
from assess_stage_grade_normal a
join ea.course_grade_submit_map b on a.course_class_code = b.course_class_code
 and a.submit_type = b.submit_type;