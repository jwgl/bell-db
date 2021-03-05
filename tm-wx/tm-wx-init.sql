-- 创建架构
create schema tm_wx authorization tm;

--资产状态对照表
create table tm_wx.asset_state(id text, name text);
insert into tm_wx.asset_state(id,name)values
('USING','在用'),
('STANDBY','备用'),
('REPAIRING','维修'),
('OFF','报废'),
('CLEARANCE','核销'),
('LOST','丢失');

