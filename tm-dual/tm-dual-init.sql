INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_AGREEMENT_ADMIN', '2+2合作协议管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_ADMIN',           '2+2管理员-教务处');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_ADMIN_DEPT',      '2+2管理员-学院');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_STUDENT',         '2+2学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DUALDEGREE_MENTOR',         '2+2论文导师');

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
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DUALDEGREE_ADMIN_DEPT',      'PERM_DUALDEGREE_PAPER_APPROVE');

INSERT INTO tm.workflow (id,name) VALUES ('scheme.create',  		'教学计划编制');
INSERT INTO tm.workflow (id,name) VALUES ('scheme.revise',  		'教学计划变更');
INSERT INTO tm.workflow (id,name) VALUES ('vision.create',  		'培养方案编制');
INSERT INTO tm.workflow (id,name) VALUES ('vision.revise',  		'培养方案变更');
INSERT INTO tm.workflow (id,name) VALUES ('card.reissue',   		'补办学生证申请');
INSERT INTO tm.workflow (id,name) VALUES ('place.booking',  		'借用教室申请');
INSERT INTO tm.workflow (id,name) VALUES ('student.leave',  		'学生请假');
INSERT INTO tm.workflow (id,name) VALUES ('schedule.free',  		'免听申请');
INSERT INTO tm.workflow (id,name) VALUES ('dualdegree.application', '国内学位申请');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dualdegree.application.approve', '初审','/web/dualdegree/approvers/${userId}/applications#/${todo}/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dualdegree.application.reject', '退回','/web/dualdegree/students/${userId}/applications#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dualdegree.application.view', '查看','/web/dualdegree/students/${userId}/applications#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dualdegree.application.process', '提交论文','/web/dualdegree/students/${userId}/applications#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dualdegree.application.finish', '审批论文','/web/dualdegree/approvers/${userId}/papers#/${todo}/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('dualdegree.application','dualdegree.application.review', '预审论文','/web/dualdegree/approvers/${userId}/papermentors#/${todo}/${id}/workitems/${workitem}');
