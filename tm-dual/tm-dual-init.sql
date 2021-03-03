-- 创建架构
create schema tm_dual authorization tm;

INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_AGREEMENT_ADMIN', '2+2合作协议管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_ADMIN',           '2+2管理员-教务处');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_ADMIN_DEPT',      '2+2管理员-学院');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_STUDENT',         '2+2学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_MENTOR',          '2+2论文导师');

INSERT INTO tm.permission (id,name) VALUES ('PERM_DUALDEGREE_AGREEMENT_WRITE',     '2+2合作协议-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_DUALDEGREE_AGREEMENT_READ',      '2+2合作协议-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_DUALDEGREE_ADMIN',               '2+2权限设置');
INSERT INTO tm.permission (id,name) VALUES ('PERM_DUALDEGREE_WRITE',               '2+2学位-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_DUALDEGREE_PAPER_APPROVE',       '2+2学位-论文审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_DUALDEGREE_DEPT_ADMIN',          '2+2学院权限-管理');
       
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_AGREEMENT_ADMIN', 'PERM_DUALDEGREE_AGREEMENT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_ADMIN',           'PERM_DUALDEGREE_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_ADMIN_DEPT',      'PERM_DUALDEGREE_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_ADMIN',      	  'PERM_DUALDEGREE_AGREEMENT_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_STUDENT',         'PERM_DUALDEGREE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_MENTOR',      	  'PERM_DUALDEGREE_PAPER_APPROVE');

INSERT INTO tm.workflow (id,name) VALUES ('dualdegree.application', '国内学位申请');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dual.application.check',       '初审',     '/dualdegree/checkers/${userId}/applications/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dual.application.reject',      '退回',     '/dualdegree/students/${userId}/applications#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dual.application.submitPaper', '提交论文', '/dualdegree/students/${userId}/applications#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dual.application.checkPaper',  '预审论文', '/dualdegree/checkers/${userId}/papers/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dual.application.approvePaper','审批论文', '/dualdegree/mentors/${userId}/papers/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dual.application.view',        '查看',     '/dualdegree/students/${userId}/applications#/${id}');

--菜单项
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.universityAdmin', 'main.dual', '合作大学管理', '/dual/users/${userId}/universities', true, array['TM-DUAL-API'], 10, 'PERM_DUALDEGREE_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.agreementAdmin', 'main.dual', '协议管理', '/dual/users/${userId}/agreements', true, array['TM-DUAL-API'], 11, 'PERM_DUALDEGREE_AGREEMENT_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.agreements', 'main.dual', '协议列表', '/dual/agreements', true, array['TM-DUAL-API'], 12, 'PERM_DUALDEGREE_AGREEMENT_READ');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.agreementsDept', 'main.dual', '协议列表', '/dual/departments/${departmentId}/agreements', true, array['TM-DUAL-API'], 12, 'PERM_DUALDEGREE_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.award', 'main.dual', '学位申请管理', '/dual/departments/${departmentId}/awards', true, array['TM-DUAL-API'], 13, 'PERM_DUALDEGREE_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.apply', 'main.dual', '在线申请', '/dual/students/${userId}/applications', true, array['TM-DUAL-API'], 14, 'PERM_DUALDEGREE_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.applicationCheck', 'main.dual.workflow', '材料审核', '/dual/checkers/${userId}/applications', true, array['TM-DUAL-API'], 15, 'PERM_DUALDEGREE_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.paperMentor', 'main.dual.workflow', '论文导师设置', '/dual/checkers/${userId}/papers', true, array['TM-DUAL-API'], 16, 'PERM_DUALDEGREE_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.paperApproval', 'main.dual.workflow', '论文审核', '/dual/mentors/${userId}/papers', true, array['TM-DUAL-API'], 17, 'PERM_DUALDEGREE_PAPER_APPROVE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.studentAbroad', 'main.dual', '学生管理', '/dual/departments/${departmentId}/students', true, array['TM-DUAL-API'], 11, 'PERM_DUALDEGREE_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.mentor', 'main.dual', '导师管理', '/dual/departments/${departmentId}/mentors', true, array['TM-DUAL-API'], 14, 'PERM_DUALDEGREE_DEPT_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.dual.applicationAdmin', 'main.dual', '申请单管理', '/dual/admin/applications', true, array['TM-DUAL-API'], 14, 'PERM_DUALDEGREE_ADMIN');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.settings.dualDegreeUser', 'main.settings', '联合培养用户', '/dual/settings/users', true, array['TM-DUAL-API'], 20, 'PERM_DUALDEGREE_ADMIN');
