-- 创建架构
create schema tm_asset authorization tm;

INSERT INTO tm.role (id,name) VALUES ('ROLE_ASSET_BUILDING_ADMIN',           '楼区管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ASSET_CENTER_ADMIN',             '中心库房管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ASSET_DIRECTOR',                 '教室管理中心负责人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ASSET_SYS',                 	 '系统管理员');

INSERT INTO tm.permission (id,name) VALUES ('PERM_ASSET_PLACE_EDIT',      '场地编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ASSET_PLACE_WRITE',     '场地创建');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ASSET_ADVICE_WRITE',    '设备创建');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ASSET_ADVICE_TRANSFER', '设备流转');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ASSET_APPROVAL',        '审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ASSET_VIEW',			  '信息浏览');

INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_BUILDING_ADMIN', 'PERM_ASSET_PLACE_EDIT');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_BUILDING_ADMIN', 'PERM_ASSET_ADVICE_TRANSFER');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_CENTER_ADMIN',   'PERM_ASSET_PLACE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_CENTER_ADMIN',   'PERM_ASSET_ADVICE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_DIRECTOR',   	'PERM_ASSET_APPROVAL');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_DIRECTOR',   	'PERM_ASSET_VIEW');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_CENTER_ADMIN',   'PERM_ASSET_VIEW');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_BUILDING_ADMIN', 'PERM_ASSET_VIEW');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_SYS', 'PERM_ASSET_VIEW');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_SYS', 'PERM_ASSET_PLACE_EDIT');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_SYS', 'PERM_ASSET_PLACE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_SYS', 'PERM_ASSET_ADVICE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ASSET_SYS', 'PERM_ASSET_ADVICE_TRANSFER');

insert into tm.menu(id, label, display_order) values ('main.asset',        '教室资产',     70);

insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.place', 'main.asset', '场地查询', '/asset/users/${userId}/places', true, array['TM-ASSET-API'], 10, 'PERM_ASSET_VIEW');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.receipt', 'main.asset', '入库单', '/asset/users/${userId}/receiptForms', true, array['TM-ASSET-API'], 20, 'PERM_ASSET_ADVICE_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.center', 'main.asset', '中心设备管理', '/asset/users/${userId}/centers', true, array['TM-ASSET-API'], 22, 'PERM_ASSET_ADVICE_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.area', 'main.asset', '楼区设备管理', '/asset/users/${userId}/areas', true, array['TM-ASSET-API'], 22, 'PERM_ASSET_ADVICE_TRANSFER');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.receiptApproval', 'main.asset', '入库单审批', '/asset/approvers/${userId}/receiptForms', true, array['TM-ASSET-API'], 21, 'PERM_ASSET_APPROVAL');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.transferApproval', 'main.asset', '进出库单审批', '/asset/approvers/${userId}/transferApproval', true, array['TM-ASSET-API'], 23, 'PERM_ASSET_ADVICE_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.setting', 'main.asset', '设置', '/asset/models', true, array['TM-ASSET-API'], 24, 'PERM_ASSET_ADVICE_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.asset.grant', 'main.asset', '楼区用户授权', '/asset/approvers/${userId}/grants', true, array['TM-ASSET-API'], 24, 'PERM_ASSET_APPROVAL');

INSERT INTO tm.workflow (id,name) VALUES ('asset.checkin', 		'入库单审核');
INSERT INTO tm.workflow (id,name) VALUES ('asset.transfer', 	'设备流转');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('asset.checkin', 'asset.checkin.approve',   '审核',     '/asset/approvers/${userId}/receiptForms/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('asset.checkin', 'asset.checkin.view', 	 '查看',     '/asset/approvers/${userId}/receiptForms/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('asset.transfer', 'asset.transfer.approve',   '审核',     '/asset/approvers/${userId}/transferForms/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('asset.transfer', 'asset.transfer.view', 	 '查看',     '/asset/approvers/${userId}/transferForms/${id}');

--设备状态
CREATE TYPE tm_asset.state AS ENUM ('USING', 'STANDBY', 'REPAIRING', 'OFF', 'CLEARANCE', 'LOST');
