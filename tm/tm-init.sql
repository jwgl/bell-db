Insert into ROLE (ID,NAME) values ('ROLE_SYSTEM_ADMIN','系统管理员');
Insert into ROLE (ID,NAME) values ('ROLE_DEPARTMENT_ADMIN','部门管理员');
Insert into ROLE (ID,NAME) values ('ROLE_USER','用户');
Insert into ROLE (ID,NAME) values ('ROLE_TEACHER','教师');
Insert into ROLE (ID,NAME) values ('ROLE_IN_SCHOOL_TEACHER','在校教师');
Insert into ROLE (ID,NAME) values ('ROLE_COURSE_TEACHER','任课教师');
Insert into ROLE (ID,NAME) values ('ROLE_SUBJECT_DIRECTOR','专业负责人');
Insert into ROLE (ID,NAME) values ('ROLE_DEAN_OF_TEACHING','教学院长');
Insert into ROLE (ID,NAME) values ('ROLE_TEACHING_SECRETARY','教务秘书');
Insert into ROLE (ID,NAME) values ('ROLE_LEAVE_APPROVER','批假人');
Insert into ROLE (ID,NAME) values ('ROLE_BOOKING_CHECKER','借教室审核人');
Insert into ROLE (ID,NAME) values ('ROLE_BOOKING_ADMIN','借教室管理员');
Insert into ROLE (ID,NAME) values ('ROLE_PROGRAM_ADMIN','计划管理员');
Insert into ROLE (ID,NAME) values ('ROLE_STUDENT','学生');
Insert into ROLE (ID,NAME) values ('ROLE_IN_SCHOOL_STUDENT','在校学生');
Insert into ROLE (ID,NAME) values ('ROLE_SELECT_COURSE_STUDENT','可选课学生');

Insert into PERMISSION (ID,NAME) values ('PERM_WORK_ITEMS','待办事项');
Insert into PERMISSION (ID,NAME) values ('PERM_SYSTEM_SETUP','系统设置');
Insert into PERMISSION (ID,NAME) values ('PERM_PROFILE_SETUP','个人设置');
Insert into PERMISSION (ID,NAME) values ('PERM_SCHEME_READ','教学计划-查看');
Insert into PERMISSION (ID,NAME) values ('PERM_SCHEME_WRITE','教学计划-编辑');
Insert into PERMISSION (ID,NAME) values ('PERM_SCHEME_CHECK','教学计划-审核');
Insert into PERMISSION (ID,NAME) values ('PERM_SCHEME_APPROVE','教学计划-审批');
Insert into PERMISSION (ID,NAME) values ('PERM_VISION_READ','培养方案-查看');
Insert into PERMISSION (ID,NAME) values ('PERM_VISION_WRITE','培养方案-编辑');
Insert into PERMISSION (ID,NAME) values ('PERM_VISION_CHECK','培养方案-审核');
Insert into PERMISSION (ID,NAME) values ('PERM_VISION_APPROVE','培养方案-审批');
Insert into PERMISSION (ID,NAME) values ('PERM_SUBJECT_SETUP','设置-专业');
Insert into PERMISSION (ID,NAME) values ('PERM_SCHEME_SETUP','设置-教学计划');
Insert into PERMISSION (ID,NAME) values ('PERM_VISION_SETUP','设置-培养方案');
Insert into PERMISSION (ID,NAME) values ('PERM_ROLLCALL_WRITE','考勤-点名');
Insert into PERMISSION (ID,NAME) values ('PERM_ROLLCALL_QUERY','考勤-统计');
Insert into PERMISSION (ID,NAME) values ('PERM_SCHEDULE_READ','课表-查看');
Insert into PERMISSION (ID,NAME) values ('PERM_COURSE_REGISTER','学生选课');
Insert into PERMISSION (ID,NAME) values ('PERM_COURSE_EVALUATE','学生评教');
Insert into PERMISSION (ID,NAME) values ('PERM_LEAVE_APPLY','请假');
Insert into PERMISSION (ID,NAME) values ('PERM_LEAVE_APPROVE','批假');
Insert into PERMISSION (ID,NAME) values ('PERM_BOOKING_APPLY','借教室-申请');
Insert into PERMISSION (ID,NAME) values ('PERM_BOOKING_CHECK','借教室-审核');
Insert into PERMISSION (ID,NAME) values ('PERM_BOOKING_APPROVE','借教室-审批');

Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_SYSTEM_ADMIN','PERM_SYSTEM_SETUP');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_USER','PERM_PROFILE_SETUP');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_STUDENT','PERM_SCHEME_READ');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_TEACHER','PERM_SCHEME_READ');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_SUBJECT_DIRECTOR','PERM_SCHEME_WRITE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_DEAN_OF_TEACHING','PERM_SCHEME_CHECK');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_SCHEME_APPROVE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_STUDENT','PERM_VISION_READ');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_TEACHER','PERM_VISION_READ');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_SUBJECT_DIRECTOR','PERM_VISION_WRITE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_DEAN_OF_TEACHING','PERM_VISION_CHECK');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_VISION_APPROVE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_SCHEME_SETUP');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_VISION_SETUP');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_SUBJECT_SETUP');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_COURSE_TEACHER','PERM_ROLLCALL_WRITE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_TEACHER','PERM_ROLLCALL_QUERY');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_SCHEDULE_READ');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_COURSE_EVALUATE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_LEAVE_APPLY');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_LEAVE_APPROVER','PERM_LEAVE_APPROVE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_TEACHER','PERM_BOOKING_APPLY');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_BOOKING_APPLY');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_BOOKING_CHECKER','PERM_BOOKING_CHECK');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_BOOKING_ADMIN','PERM_BOOKING_APPROVE');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_TEST','PERM_TEST_ACTION');
Insert into ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_USER','PERM_WORK_ITEMS');

Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main',          1, '主菜单',   '主菜单',   'Main');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.program',  1, '培养方案', '培养方案', 'Scheme');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.program.settings',  100, '参数设置', '参数设置', 'Settings');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.teaching', 2, '教学过程', '教学过程', 'Process');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.affair',   3, '事务处理', '事务处理', 'Affair');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.system',   9, '系统设置', '系统设置', 'System');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('user',          2, '用户菜单', '用户菜单', 'User');
Insert into MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('user.profile',  1, '用户菜单', '用户菜单', 'Profile');

Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.visions',11,true,'main.program','培养方案-列表','PERM_VISION_READ','/visions','培养方案目录','Vision List');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.visions.edit',12,true,'main.program','培养方案-编辑','PERM_VISION_WRITE','/users/${userId}/visions','编辑培养方案','Edit Vision');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.schemes',21,true,'main.program','教学计划-列表','PERM_SCHEME_READ','/schemes','教学计划目录','Scheme List');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.schemes.edit',22,true,'main.program','教学计划-编辑','PERM_SCHEME_WRITE','/users/${userId}/schemes','编辑教学计划','Edit Scheme');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.settings.subject',1,true,'main.program.settings','设置-专业','PERM_SUBJECT_SETUP','/settings/subject','专业负责人','Settings - Subject');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.settings.vision',2,true,'main.program.settings','设置-培养方案','PERM_VISION_SETUP','/settings/vision','培养方案','Settings - Vision');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.program.settings.scheme',3,true,'main.program.settings','设置-教学计划','PERM_SCHEME_SETUP','/settings/scheme','教学计划','Settings - Scheme');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.teaching.schedule',1,true,'main.teaching','课表','PERM_SCHEDULE_READ','/schedule','课表','Schedule');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.teaching.rollcall',2,true,'main.teaching','点名','PERM_ROLLCALL_WRITE','/rollcall','点名','Rollcall');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.teaching.rollcallStatis',3,true,'main.teaching','考勤统计','PERM_ROLLCALL_QUERY','/rollcall-statis','考勤情况','Rollcall Statis');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.teaching.courseRegister',4,true,'main.teaching','学生选课','PERM_COURSE_REGISTER','/register','选课','Register Course');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.teaching.courseEvaluation',5,true,'main.teaching','学生评教','PERM_COURSE_EVALUATE','/evaluation','评教','Evaluate Course');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.system.user',1,true,'main.system','用户','PERM_SYSTEM_SETUP','/system/users','用户','Users');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.system.role',2,true,'main.system','角色','PERM_SYSTEM_SETUP','/system/roles','角色','Roles');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.system.perm',3,true,'main.system','权限','PERM_SYSTEM_SETUP','/system/permissions','权限','Permissions');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('user.profile.modify',1,true,'user.profile','修改个人信息','PERM_PROFILE_SETUP','/profile','修改个人信息','Modify Profile');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('user.profile.password',2,true,'user.profile','修改密码','PERM_PROFILE_SETUP','/password','修改密码','Modify Password');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.affair.workItems',1,true,'main.affair','待办事项','PERM_WORK_ITEMS','/users/${userId}/works','待办事项','Work Items');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.affair.leaveRequest',2,true,'main.affair','请假','PERM_LEAVE_APPLY','/leave/request','请假','Apply Leave Request');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.affair.leaveApprove',3,true,'main.affair','批假','PERM_LEAVE_APPROVE','/leave/approve','批假','Approve Leave Request');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.affair.bookingApply',4,true,'main.affair','教室借用-申请','PERM_BOOKING_APPLY','/booking/apply','借教室','Booking');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.affair.bookingCheck',5,true,'main.affair','教室借用-审核','PERM_BOOKING_CHECK','/booking/check','借教室审核','Check Booking');
Insert into MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values 
('main.affair.bookingApprove',6,true,'main.affair','教室借用-审批','PERM_BOOKING_APPROVE','/booking/approve','借教室审批','Approve Booking');

Insert into WORKFLOW (ID,NAME) values ('scheme.create','教学计划编制');
Insert into WORKFLOW (ID,NAME) values ('scheme.revise','教学计划变更');
Insert into WORKFLOW (ID,NAME) values ('vision.create','培养方案编制');
Insert into WORKFLOW (ID,NAME) values ('vision.revise','培养方案变更');

Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.approve','审批','/schemes/${id}/reviews/${workitem}','scheme.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.check','审核','/schemes/${id}/reviews/${workitem}','scheme.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.reject','退回','/users/${userId}/schemes#/${id}','scheme.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.review','加签','/schemes/${id}/reviews/${workitem}','scheme.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.view','退回','/users/${userId}/schemes#/${id}','scheme.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.approve','审批','/schemes/${id}/reviews/${workitem}','scheme.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.check','审核','/schemes/${id}/reviews/${workitem}','scheme.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.reject','退回','/users/${userId}/schemes#/${id}','scheme.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.review','加签','/schemes/${id}/reviews/${workitem}','scheme.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.view','查看','/users/${userId}/schemes#/${id}','scheme.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.approve','审批','/visions/${id}/reviews/${workitem}','vision.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.check','审核','/visions/${id}/reviews/${workitem}','vision.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.reject','退回','/users/${userId}/visions#/${id}','vision.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.review','加签','/visions/${id}/reviews/${workitem}','vision.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.view','退回','/users/${userId}/visions#/${id}','vision.create');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.approve','审批','/visions/${id}/reviews/${workitem}','vision.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.check','审核','/visions/${id}/reviews/${workitem}','vision.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.reject','退回','/users/${userId}/visions#/${id}','vision.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.review','加签','/visions/${id}/reviews/${workitem}','vision.revise');
Insert into WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.view','查看','/users/${userId}/visions#/${id}','vision.revise');