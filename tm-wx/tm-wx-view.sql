-- 学生、老师用户视图
create or replace view tm_wx.dv_user as 
select id, password, user_type, name
from tm.system_user
where (user_type = 2 or user_type = 1) and enabled;

--近一周申请的学生学号及初始密码
create or replace view tm_wx.dv_report_student_last_week as
select distinct user_id, (extract(doy from now()) * 1917)::integer as password
from tm_wx.report 
where extract(DOW FROM now()) = 6
and date_created  between current_date - interval '7 days' and current_date - interval '0 days';

--资产视图
create or replace view tm_wx.dv_asset as
select
a.id,
a.code,
a.sn,
a.name,
a.asset_type,
a.price,
a.state,
a.date_bought,
a.date_forbid,
a.pcs,
a.qualify_month,
a.unit,
a.date_close,
a.note,
r.name as place,
r.building as building,
am.brand,
am.specs,
am.parameter,
p.name as supplier
from tm_asset.asset a
left join tm_asset.supplier p on a.supplier_id=p.id
left join tm_asset.asset_model am on a.asset_model_id=am.id
left join tm_asset.room r on a.room_id=r.id;

ALTER TABLE tm_wx.dv_asset OWNER TO tm;

--AssetUser视图
create or replace view tm_wx.dv_asset_user as
select user_id,role_id from tm.dv_teacher_role where role_id like 'ROLE_ASSET%'
union all
select user_id,role_id from tm.user_role where role_id like 'ROLE_ASSET%';	

ALTER TABLE tm_wx.dv_asset_user OWNER TO tm;

--设备流转足迹视图
create or replace view tm_wx.dv_asset_track as
select 
i.asset_id as id,
t.name as type,
tc.name as operator,
s.name as state,
f.date_approved,
concat(r.building,' ',r.name) as source,
i.note
from tm_asset.transfer_form f join tm_asset.transfer_item i on f.id=i.transfer_form_id
join tm_asset.transfer_type t on f.transfer_type_id=t.id
left join ea.teacher tc on f.operator_id=tc.id
left join tm_wx.asset_state s on s.id=i.state::text
left join tm_asset.room r on r.id=i.source_id;

ALTER TABLE tm_wx.dv_asset_track OWNER TO tm;

--设备变更日志
create or replace view tm_wx.dv_asset_change_log as
select m.*, l.date_created,l.sake,l.asset_id,s.name as supplier
from tm_asset.asset_change_log l left join tm_asset.asset_model m on (l.from_value::json->'assetModelId')::text=m.id::text
left join tm_asset.supplier s on (l.from_value::json->'supplierId')::text=s.id::text;

ALTER TABLE tm_wx.dv_asset_change_log OWNER TO tm;
