-- 创建架构
create schema tm_form authorization tm;

INSERT INTO tm.role (id,name) VALUES ('ROLE_QUESTIONNAIRE_ADMIN',      '调查问卷管理员-校级');
INSERT INTO tm.role (id,name) VALUES ('ROLE_QUESTIONNAIRE_DEPT_ADMIN', '调查问卷管理员-院级');

INSERT INTO tm.permission (id,name) VALUES ('PERM_QUESTIONNAIRE_WRITE',             '调查问卷-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_QUESTIONNAIRE_RESPONSE',          '调查问卷-响应');
INSERT INTO tm.permission (id,name) VALUES ('PERM_QUESTIONNAIRE_ADMIN_CLASS_CHECK', '调查问卷-班级审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_QUESTIONNAIRE_CHECK',             '调查问卷-院级审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_QUESTIONNAIRE_APPROVE',           '调查问卷-校级审批');

INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',        'PERM_QUESTIONNAIRE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',        'PERM_QUESTIONNAIRE_RESPONSE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',        'PERM_QUESTIONNAIRE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',        'PERM_QUESTIONNAIRE_RESPONSE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_CLASS_SUPERVISOR',         'PERM_QUESTIONNAIRE_ADMIN_CLASS_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_QUESTIONNAIRE_DEPT_ADMIN', 'PERM_QUESTIONNAIRE_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_QUESTIONNAIRE_ADMIN',      'PERM_QUESTIONNAIRE_APPROVE');

INSERT INTO tm.workflow (id,name) VALUES ('form.questionnaire', '调查问卷');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('form.questionnaire', 'form.questionnaire.adminClassCheck', '班级审核', '/form/supervisors/${userId}/questionnaires/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('form.questionnaire', 'form.questionnaire.check',           '院级审核', '/form/checkers/${userId}/questionnaires/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('form.questionnaire', 'form.questionnaire.approve',         '审批',     '/form/approvers/${userId}/questionnaires/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('form.questionnaire', 'form.questionnaire.reject',          '退回',     '/form/pollsters/${userId}/questionnaires/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('form.questionnaire', 'form.questionnaire.view',            '查看',     '/form/pollsters/${userId}/questionnaires/${id}');

insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.affair.questionnaire', 'main.affair', '调查问卷申请', '/form/pollsters/${userId}/questionnaires', true, array['TM-FORM-API'], 60, 'PERM_QUESTIONNAIRE_WRITE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.affair.questionnaireAdminClassCheck', 'main.affair', '调查问卷审核（班级）', '/form/supervisors/${userId}/questionnaires', true, array['TM-FORM-API'], 61, 'PERM_QUESTIONNAIRE_ADMIN_CLASS_CHECK');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.affair.questionnaireCheck', 'main.affair', '调查问卷审核（院级）', '/form/checkers/${userId}/questionnaires', true, array['TM-FORM-API'], 62, 'PERM_QUESTIONNAIRE_CHECK');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.affair.questionnaireApproval', 'main.affair', '调查问卷审批', '/form/approvers/${userId}/questionnaires', true, array['TM-FORM-API'], 63, 'PERM_QUESTIONNAIRE_APPROVE');
insert into tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) values
('main.affair.questionnaireResponse', 'main.affair', '参与调查问卷', '/form/respondents/${userId}/questionnaires', true, array['TM-FORM-API'], 64, 'PERM_QUESTIONNAIRE_RESPONSE');
