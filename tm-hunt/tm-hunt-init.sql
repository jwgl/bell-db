-- 创建架构
create schema tm_hunt authorization tm;

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
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_ADMIN',      	  	'PERM_HUNT_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUNT_EXPERT',         	'PERM_HUNT_REVIEW');

INSERT INTO tm.workflow (id,name) VALUES ('hunt.review', 		'质量工程项目审核');
