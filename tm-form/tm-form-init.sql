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

Hibernate: create table tm_form.question (id  bigserial not null, questionnaire_id int8 not null, open_ended boolean not null, step_value int4 not null, content text not null, open_label text, title text not null, ordinal int4 not null, mandatory boolean not null, max_value int4, type int4 not null, min_value int4, primary key (id))
Hibernate: comment on table tm_form.question is '问题'
Hibernate: comment on column tm_form.question.id is 'ID'
Hibernate: comment on column tm_form.question.questionnaire_id is '所属问卷'
Hibernate: comment on column tm_form.question.open_ended is '是否为开放问题'
Hibernate: comment on column tm_form.question.step_value is '量表间隔'
Hibernate: comment on column tm_form.question.content is '问题内容'
Hibernate: comment on column tm_form.question.open_label is '开放问题提示'
Hibernate: comment on column tm_form.question.title is '问题标题'
Hibernate: comment on column tm_form.question.ordinal is '问题序号'
Hibernate: comment on column tm_form.question.mandatory is '是否为必选问题'
Hibernate: comment on column tm_form.question.max_value is '最大值'
Hibernate: comment on column tm_form.question.type is '问题类型-0:开放;1:单选;2:多选;3:量表'
Hibernate: comment on column tm_form.question.min_value is '最小值'
Hibernate: create table tm_form.question_option (id  bigserial not null, ordinal int4 not null, value int4, content text not null, label text, question_id int8 not null, primary key (id))
Hibernate: comment on table tm_form.question_option is '问题选项'
Hibernate: comment on column tm_form.question_option.id is 'ID'
Hibernate: comment on column tm_form.question_option.ordinal is '选项序号'
Hibernate: comment on column tm_form.question_option.value is '选项数值'
Hibernate: comment on column tm_form.question_option.content is '选项内容'
Hibernate: comment on column tm_form.question_option.label is '选项标签'
Hibernate: comment on column tm_form.question_option.question_id is '所属问题'
Hibernate: create table tm_form.questionnaire (id  bigserial not null, workflow_instance_id uuid, date_approved timestamp, survey_scope int4 not null, date_created timestamp not null, pollster_id varchar(10) not null, anonymous boolean default true not null, prologue text, date_checked timestamp, epilogue text, restricted jsonb, date_expired timestamp not null, date_submitted timestamp, oriented jsonb, hash_id text, response_visibility int4 not null, title text not null, department_id varchar(2) not null, survey_type int4 not null, checker_id varchar(5), date_published timestamp, respondent_type int4 not null, status state not null, approver_id varchar(5), date_modified timestamp not null, primary key (id))
Hibernate: comment on table tm_form.questionnaire is '调查问卷'
Hibernate: comment on column tm_form.questionnaire.id is 'ID'
Hibernate: comment on column tm_form.questionnaire.workflow_instance_id is '工作流实例'
Hibernate: comment on column tm_form.questionnaire.date_approved is '审批时间'
Hibernate: comment on column tm_form.questionnaire.date_created is '创建日期'
Hibernate: comment on column tm_form.questionnaire.pollster_id is '发起人'
Hibernate: comment on column tm_form.questionnaire.anonymous is '是否匿名'
Hibernate: comment on column tm_form.questionnaire.prologue is '欢迎词'
Hibernate: comment on column tm_form.questionnaire.date_checked is '审核时间'
Hibernate: comment on column tm_form.questionnaire.epilogue is '结束语'
Hibernate: comment on column tm_form.questionnaire.restricted is '限制对象'
Hibernate: comment on column tm_form.questionnaire.date_expired is '截止日期'
Hibernate: comment on column tm_form.questionnaire.date_submitted is '提交时间'
Hibernate: comment on column tm_form.questionnaire.oriented is '面向对象'
Hibernate: comment on column tm_form.questionnaire.hash_id is 'Hash ID'
Hibernate: comment on column tm_form.questionnaire.title is '问卷题目'
Hibernate: comment on column tm_form.questionnaire.department_id is '所在单位'
Hibernate: comment on column tm_form.questionnaire.checker_id is '审核人'
Hibernate: comment on column tm_form.questionnaire.date_published is '发布日期'
Hibernate: comment on column tm_form.questionnaire.status is '状态'
Hibernate: comment on column tm_form.questionnaire.approver_id is '审批人'
Hibernate: comment on column tm_form.questionnaire.date_modified is '修改日期'
Hibernate: create table tm_form.response_form (id  bigserial not null, questionnaire_id int8 not null, date_created timestamp not null, date_submitted timestamp, respondent_id varchar(10) not null, date_modified timestamp not null, primary key (id))
Hibernate: comment on table tm_form.response_form is '问卷响应表单'
Hibernate: comment on column tm_form.response_form.id is 'ID'
Hibernate: comment on column tm_form.response_form.questionnaire_id is '所属问卷'
Hibernate: comment on column tm_form.response_form.date_created is '创建日期'
Hibernate: comment on column tm_form.response_form.date_submitted is '提交时间'
Hibernate: comment on column tm_form.response_form.respondent_id is '调查对象'
Hibernate: comment on column tm_form.response_form.date_modified is '修改日期'
Hibernate: create table tm_form.response_item (id  bigserial not null, form_id int8 not null, int_value int4, choice_id int8, text_value text, question_id int8 not null, primary key (id))
Hibernate: comment on table tm_form.response_item is '问卷响应项目'
Hibernate: comment on column tm_form.response_item.id is 'ID'
Hibernate: comment on column tm_form.response_item.form_id is '所属表单'
Hibernate: comment on column tm_form.response_item.int_value is '数值响应'
Hibernate: comment on column tm_form.response_item.choice_id is '单选响应'
Hibernate: comment on column tm_form.response_item.text_value is '文本响应'
Hibernate: comment on column tm_form.response_item.question_id is '调查问题'
Hibernate: create table tm_form.response_pick (item_id int8 not null, option_id int8 not null, primary key (item_id, option_id))
Hibernate: comment on table tm_form.response_pick is '问卷响应选择'
Hibernate: comment on column tm_form.response_pick.item_id is '响应项目'
Hibernate: comment on column tm_form.response_pick.option_id is '问题选项'
Hibernate: alter table if exists tm_form.questionnaire drop constraint if exists UK_kvmv7x4t6eliayvfclos5925j
Hibernate: alter table if exists tm_form.questionnaire add constraint UK_kvmv7x4t6eliayvfclos5925j unique (hash_id)
Hibernate: alter table if exists tm_form.question add constraint FK5a4p6bl440c9amsq08rs546wu foreign key (questionnaire_id) references tm_form.questionnaire
Hibernate: alter table if exists tm_form.question_option add constraint FKmmdv54rmm5hkgxbn1008ix87n foreign key (question_id) references tm_form.question
Hibernate: alter table if exists tm_form.questionnaire add constraint FKjct4r9wqjpbn4u72gsb4k9srf foreign key (workflow_instance_id) references tm.workflow_instance
Hibernate: alter table if exists tm_form.questionnaire add constraint FK881mrscwwf6iyuhwjamxj1k7n foreign key (pollster_id) references tm.system_user
Hibernate: alter table if exists tm_form.questionnaire add constraint FKpkd40iatptjnu2a19l01r2pta foreign key (department_id) references ea.department
Hibernate: alter table if exists tm_form.questionnaire add constraint FKg7fsstqnrn5va889ias8lr435 foreign key (checker_id) references ea.teacher
Hibernate: alter table if exists tm_form.questionnaire add constraint FK5vfle7ucu779ei6gkjjsd8i4i foreign key (approver_id) references ea.teacher
Hibernate: alter table if exists tm_form.response_form add constraint FKe30bhhia8hnx8cwti0l8tkngw foreign key (questionnaire_id) references tm_form.questionnaire
Hibernate: alter table if exists tm_form.response_form add constraint FKk4kktl005h1hrfcgpdjb56s9e foreign key (respondent_id) references tm.system_user
Hibernate: alter table if exists tm_form.response_item add constraint FK9071pv8jk21xenqkqhdtldiba foreign key (form_id) references tm_form.response_form
Hibernate: alter table if exists tm_form.response_item add constraint FK459inki8y9c5odwnjxyv26d7s foreign key (choice_id) references tm_form.question_option
Hibernate: alter table if exists tm_form.response_item add constraint FKxgsdau7wlap4svooihcf4n3i foreign key (question_id) references tm_form.question
Hibernate: alter table if exists tm_form.response_pick add constraint FKpthac61ojtt3vfq00u793tpba foreign key (item_id) references tm_form.response_item
Hibernate: alter table if exists tm_form.response_pick add constraint FK37fb47wqtvl4en3jngxp7xh78 foreign key (option_id) references tm_form.question_option

drop table tm_form.response_pick;
drop table tm_form.response_item;
drop table tm_form.response_form;
drop table tm_form.question_option;
drop table tm_form.question;
drop table tm_form.questionnaire;