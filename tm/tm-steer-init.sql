--创建角色
INSERT INTO tm.role (id,name) VALUES ('ROLE_OBSERVER',                   '现任督导员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_OBSERVATION_ADMIN',          '督导管理员');

--创建权限
INSERT INTO tm.permission (id,name) VALUES ('PERM_OBSERVATION_WRITE',              '督导听课-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_OBSERVATION_READ',               '督导听课-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_OBSERVATION_DEPT_APPROVE',       '督导听课-院督导听课发布');
INSERT INTO tm.permission (id,name) VALUES ('PERM_OBSERVER_ADMIN',                 '督导管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_OBSERVER_DEPT_ADMIN',            '督导管理-院督导员管理');

--授权
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_OBSERVER',                   'PERM_OBSERVATION_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_OBSERVATION_ADMIN',          'PERM_OBSERVATION_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_OBSERVATION_ADMIN',          'PERM_OBSERVER_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_OBSERVATION_ADMIN',          'PERM_OBSERVATION_DEPT_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DEAN_OF_TEACHING',           'PERM_OBSERVATION_DEPT_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ACADEMIC_SECRETARY',         'PERM_OBSERVER_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_CLASS_TEACHER',       'PERM_OBSERVATION_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ONCE_COURSE_CLASS_TEACHER',  'PERM_OBSERVATION_READ');

--菜单项
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.process.observationView', 'main.process', '督导听课反馈', '/steer/teachers/${userId}/observations', true, array['TM-STEER-API'], 60, 'PERM_TASK_SCHEDULE_EXECUTE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.steer.observationForm', 'main.steer', '督导听课记录', '/steer/obervers/${userId}/observations', true, array['TM-STEER-API'], 10, 'PERM_OBSERVATION_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.steer.observationApproval', 'main.steer', '听课记录发布', '/steer/approvers/${userId}/observations', true, array['TM-STEER-API'], 11, 'PERM_OBSERVATION_APPROVE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.steer.observationReport', 'main.steer', '督导听课统计', '/steer/reports', true, array['TM-STEER-API'], 12, 'PERM_OBSERVATION_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.steer.observationLegacy', 'main.steer', '督导听课历史数据', '/steer/legacies', true, array['TM-STEER-API'], 13, 'PERM_OBSERVER_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.observer', 'main.settings', '校级督导', '/steer/settings/observers', true, array['TM-STEER-API'], 40, 'PERM_OBSERVER_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.deptObserver', 'main.settings', '院级督导', '/steer/departments/${departmentId}/observers', true, array['TM-STEER-API'], 41, 'PERM_OBSERVER_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.steer.dean', 'main.steer', '本学院被听课', '/steer/obervers/${userId}/deans', true, array['TM-STEER-API'], 14, 'PERM_OBSERVATION_DEPT_APPROVE');
