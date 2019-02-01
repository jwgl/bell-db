-- 创建架构
create schema tm_hunt authorization tm;

INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_ADMIN',           '教学项目管理员-教务处');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_CHECKER',         '教学项目审核员-学院');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_EXPERT',          '教学项目评审专家');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUNT_DIRECTOR',        '教学项目领导-处长');

INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_CHECK',     '教学项目-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_ADMIN',     '教学项目-管理、审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_WRITE',     '教学项目-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_REVIEW',    '教学项目-评审');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_DIRECT',    '教学项目-处长');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUNT_OVERVIEW',  '教学项目-项目总览');
       
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_ADMIN', 			'PERM_HUNT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_CHECKER',			'PERM_HUNT_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',    'PERM_HUNT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_EXPERT',         	'PERM_HUNT_REVIEW');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_DIRECTOR',        'PERM_HUNT_DIRECT');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_DIRECTOR',        'PERM_HUNT_OVERVIEW');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_ADMIN',        	'PERM_HUNT_OVERVIEW');

insert into tm.menu(id, label, display_order) values ('main.hunt',        '教学项目',     60);

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
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.projectChange', 'main.hunt', '项目变更', '/hunt/teachers/${userId}/info-changes', true, array['TM-HUNT-API'], 21, 'PERM_HUNT_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.changeCheck', 'main.hunt', '项目变更审核', '/hunt/checkers/${userId}/info-changes', true, array['TM-HUNT-API'], 30, 'PERM_HUNT_CHECK');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.changeApproval', 'main.hunt', '项目变更审批', '/hunt/approvers/${userId}/info-changes', true, array['TM-HUNT-API'], 40, 'PERM_HUNT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.projectDepartment', 'main.hunt', '本单位项目', '/hunt/checkers/${userId}/projects', true, array['TM-HUNT-API'], 50, 'PERM_HUNT_CHECK');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.changeReview', 'main.hunt', '处长加签', '/hunt/directors/${userId}/info-changes', true, array['TM-HUNT-API'], 20, 'PERM_HUNT_DIRECT');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.hunt.projects', 'main.hunt', '项目汇总', '/hunt/users/${userId}/projects', true, array['TM-HUNT-API'], 70, 'PERM_HUNT_OVERVIEW');

INSERT INTO tm.workflow (id,name) VALUES ('hunt.review', 		'教学项目项目审核');
INSERT INTO tm.workflow (id,name) VALUES ('hunt.info-change', 		'教学项目项目变更审核');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.review', 'hunt.review.check',       '审核',     '/hunt/checkers/${userId}/projects/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.review', 'hunt.review.reject',      '退回',     '/hunt/teachers/${userId}/projects/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.review', 'hunt.review.view', 		 '查看',     '/hunt/teachers/${userId}/projects/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.review', 'hunt.review.approve',	 '审批',     '/hunt/approvers/${userId}/projects/${todo}/${id};wi=${workitem}');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.info-change', 'hunt.info-change.check',       '审核',     '/hunt/checkers/${userId}/infoChanges/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.info-change', 'hunt.info-change.reject',      '退回',     '/hunt/teachers/${userId}/infoChanges/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.info-change', 'hunt.info-change.view',        '查看',     '/hunt/teachers/${userId}/infoChanges/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.info-change', 'hunt.info-change.approve',     '审批',     '/hunt/approvers/${userId}/infoChanges/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('hunt.info-change', 'hunt.info-change.review',      '加签',     '/hunt/directors/${userId}/infoChanges/${todo}/${id};wi=${workitem}');
