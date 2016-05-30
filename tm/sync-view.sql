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
            when yhm <> jsmm then 1
            else 0 -- 用户名密码相同则禁用
        end as enabled,
        1 as user_type,
        xydm as department_id
    from zfxfzb.yhb
    join zfxfzb.jsxxb on yhm = zgh -- 以职工号为用户名
    left join zfxfzb.xydmb on bm = xymc
    where (ty is null or ty = 'F') -- 停用
    and (sfzg is null or sfzg = '是') -- 是否在职
    and (yhm in (select yhm from zfxfzb.czrzb where czsj > '2012') -- 近两年登录过系统
      or yhm in (select jszgh from zfxfzb.jxrwbview where xn > '2012') -- 近两年有教学任务
    )
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
    and exists (select * from zfxfzb.cjb where cjb.xh = xsjbxxb.xh) -- 有成绩
    and dqszj > (select max(dqszj) - 8 from zfxfzb.xsjbxxb)
    order by xh
)
select * from teacher
union all
select * from student;

/**
 * 行政班管理员
 */
create or replace view tm.sv_admin_class_manager as
select nj || sszydm || substr(bjdm, -2, 2) as admin_class_id,
    bzrxm as teacher_id, 1 as type
from zfxfzb.bjdmb
where bzrxm is not null and bzrxm in (select zgh from zfxfzb.jsxxb)
union
select nj || sszydm || substr(bjdm, -2, 2) as admin_class_id,
    bzrxm2 as teacher_id, 2 as type
from zfxfzb.bjdmb
where bzrxm2 is not null and bzrxm2 in (select zgh from zfxfzb.jsxxb)
order by admin_class_id, type;
