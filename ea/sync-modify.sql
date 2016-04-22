/**
 * zfxfzb.tjkbapqkb
 */

-- 修改推荐课表安排表
alter table zfxfzb.tjkbapqkb modify kc varchar2(32);
update zfxfzb.tjkbapqkb set kc='';
delete from tjkbapqkb_guid;

select * from zfxfzb.tjkbapqkb
where (tjkbdm, xkkh, jszgh, xqj, sjdxh) in (
	select tjkbdm, xkkh, jszgh, xqj, sjdxh
	from zfxfzb.tjkbapqkb
	group by tjkbdm, xkkh, jszgh, xqj, sjdxh
	having count(*) > 2
) order by tjkbdm, xkkh, jszgh, sjdxh, qssj, dsz;

-- 创建临时表
create global temporary table tjkbapqkb_guid (
	xkkh	varchar2(31),
	jszgh	varchar2(5),
	jsbh	varchar2(6),
	qssj	number,
	jssj	number,
	xqj		number,
	qssjd	number,
	jssjd	number,
	guid	varchar2(32) default rawtohex(sys_guid())
);

-- 生成GUID
insert into tjkbapqkb_guid(xkkh, jszgh, jsbh, qssj, jssj, xqj, qssjd, jssjd)
with tjkbapqkb_fix as (
select xkkh, jszgh, xqj, dsz, qssj, jssj, sjdxh, qssjd, coalesce(jsbh, (
		select distinct jsbh from zfxfzb.tjkbapqkb
		where xkkh = a.xkkh and jszgh = a.jszgh and qssj = a.qssj and jssj = a.jssj and xqj = a.xqj and sjdxh = a.sjdxh 
		and jsbh is not null
	)) as jsbh
	from zfxfzb.tjkbapqkb a
)
select xkkh, jszgh, jsbh, qssj, jssj, xqj, min(sjdxh) as qssjd, max(sjdxh) as jssjd
from tjkbapqkb_fix
group by xkkh, jszgh, jsbh, qssj, jssj, xqj, qssjd;

-- 更新安排表
merge into zfxfzb.tjkbapqkb a
using tjkbapqkb_guid b 
on (a.xkkh = b.xkkh 
	and a.jszgh = b.jszgh
	and coalesce(a.jsbh, (
		select distinct jsbh from zfxfzb.tjkbapqkb
		where xkkh = a.xkkh and jszgh = a.jszgh and qssj = a.qssj and jssj = a.jssj and xqj = a.xqj and sjdxh = a.sjdxh 
		and jsbh is not null
	), '0') = nvl(b.jsbh, '0')
	and a.qssj = b.qssj
	and a.jssj = b.jssj
	and a.xqj = b.xqj
	and a.sjdxh between b.qssjd and b.jssjd
)
when matched then 
update set kc = guid
where kc is null;

-- 删除临时表
drop table tjkbapqkb_guid;

-- 触发器，安排表中插入或更新数据时新建GUID或查找已有的GUID
create or replace trigger zfxfzb.tjkbapqkb_insert
before insert on zfxfzb.tjkbapqkb
referencing new as new old as old
for each row
declare
	v_guid  varchar2(32);
	v_number number;
pragma autonomous_transaction;
begin
	select count(*) into v_number from tjkbapqkb 
	where xkkh = :new.xkkh 
	and jszgh = :new.jszgh 
	and jsbh = :new.jsbh 
	and xqj = :new.xqj 
	and qssjd = :new.qssjd 
	and qssj = :new.qssj 
	and jssj = :new.jssj;
	
	if v_number = 0 then
		v_guid := rawtohex(sys_guid());
	else
		select distinct kc into v_guid 
		from tjkbapqkb 
		where xkkh = :new.xkkh 
		and jszgh = :new.jszgh 
		and jsbh = :new.jsbh 
		and xqj = :new.xqj 
		and qssjd = :new.qssjd 
		and qssj = :new.qssj 
		and jssj = :new.jssj;
	end if;
	
	:new.kc := v_guid;
	
	commit;
end;


/**
 * zfxfzb.qtkapb
 */

-- 修改其它课表安排表
alter table zfxfzb.qtkapb modify bz varchar2(255 byte) default rawtohex(sys_guid());

update zfxfzb.qtkapb set bz = rawtohex(sys_guid());
