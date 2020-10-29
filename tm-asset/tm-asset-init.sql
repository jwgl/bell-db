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
('main.asset.place', 'main.asset', '场地查询', '/asset/users/${userId}/places', true, array['TM-ASSET-API'], 30, 'PERM_ASSET_VIEW');
