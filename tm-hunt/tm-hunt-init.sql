INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_ADMIN',           '质量工程管理员-教务处');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_CHECKER',         '质量工程审核员-学院');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_EXPERT',          '质量工程评审专家');

INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_CHECK',     '质量工程-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_ADMIN',     '质量工程-管理、审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_WRITE',     '质量工程-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_REVIEW',    '质量工程-评审');
       
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_ADMIN', 			'PERM_HUNT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_CHECKER',			'PERM_HUNT_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',    'PERM_HUNT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_EXPERT',         	'PERM_HUNT_REVIEW');

insert into tm.menu(id, label, display_order) values ('main.hunt',        '质量工程',     60);

insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.huntType', 'main.settings', '项目类型', '/hunt/settings/types', true, array['TM-HUNT-API'], 30, 'PERM_HUNT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.huntTask', 'main.settings', '任务管理', '/hunt/settings/tasks', true, array['TM-HUNT-API'], 31, 'PERM_HUNT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.huntExpert', 'main.settings', '专家库', '/hunt/settings/experts', true, array['TM-HUNT-API'], 32, 'PERM_HUNT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.huntChecker', 'main.settings', '学院审核员', '/hunt/settings/checkers', true, array['TM-HUNT-API'], 33, 'PERM_HUNT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.application', 'main.hunt', '项目填报', '/hunt/teachers/${userId}/applications', true, array['TM-HUNT-API'], 10, 'PERM_HUNT_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.check', 'main.hunt', '项目审核', '/hunt/checkers/${userId}/tasks', true, array['TM-HUNT-API'], 20, 'PERM_HUNT_CHECK');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.approval', 'main.hunt', '项目审批', '/hunt/approvers/${userId}/tasks', true, array['TM-HUNT-API'], 30, 'PERM_HUNT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.expertReview', 'main.hunt', '项目评审', '/hunt/experts/${userId}/reviews', true, array['TM-HUNT-API'], 40, 'PERM_HUNT_REVIEW');

INSERT INTO tm.workflow (id,name) VALUES ('hunt.review', 		'质量工程项目审核');
