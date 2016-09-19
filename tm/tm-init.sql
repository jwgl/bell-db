Insert into tm.ROLE (ID,NAME) values ('ROLE_SYSTEM_ADMIN','系统管理员');
Insert into tm.ROLE (ID,NAME) values ('ROLE_DEPARTMENT_ADMIN','部门管理员');
Insert into tm.ROLE (ID,NAME) values ('ROLE_USER','用户');
Insert into tm.ROLE (ID,NAME) values ('ROLE_TEACHER','教师');
Insert into tm.ROLE (ID,NAME) values ('ROLE_IN_SCHOOL_TEACHER','在校教师');
Insert into tm.ROLE (ID,NAME) values ('ROLE_COURSE_TEACHER','任课教师');
Insert into tm.ROLE (ID,NAME) values ('ROLE_SUBJECT_DIRECTOR','专业负责人');
Insert into tm.ROLE (ID,NAME) values ('ROLE_DEAN_OF_TEACHING','教学院长');
Insert into tm.ROLE (ID,NAME) values ('ROLE_TEACHING_SECRETARY','教务秘书');
Insert into tm.ROLE (ID,NAME) values ('ROLE_STUDENT_ABSENCE_CHECKER','学生批假人');
Insert into tm.ROLE (ID,NAME) values ('ROLE_BOOKING_CHECKER','借教室审核人');
Insert into tm.ROLE (ID,NAME) values ('ROLE_BOOKING_ADMIN','借教室管理员');
Insert into tm.ROLE (ID,NAME) values ('ROLE_PROGRAM_ADMIN','计划管理员');
Insert into tm.ROLE (ID,NAME) values ('ROLE_REGISTER_ADMIN','学籍管理员');
Insert into tm.ROLE (ID,NAME) values ('ROLE_STUDENT','学生');
Insert into tm.ROLE (ID,NAME) values ('ROLE_IN_SCHOOL_STUDENT','在校学生');
Insert into tm.ROLE (ID,NAME) values ('ROLE_COURSE_REGISTER_STUDENT','可选课学生');

Insert into tm.PERMISSION (ID,NAME) values ('PERM_WORK_ITEMS','待办事项');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SYSTEM_SETUP','系统设置');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_PROFILE_SETUP','个人设置');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SCHEME_READ','教学计划-查看');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SCHEME_WRITE','教学计划-编辑');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SCHEME_CHECK','教学计划-审核');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SCHEME_APPROVE','教学计划-审批');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_VISION_READ','培养方案-查看');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_VISION_WRITE','培养方案-编辑');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_VISION_CHECK','培养方案-审核');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_VISION_APPROVE','培养方案-审批');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SUBJECT_SETUP','设置-校内专业');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_PROGRAM_SETUP','设置-教学计划');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_ROLLCALL_WRITE','考勤-点名');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_ROLLCALL_QUERY','考勤-统计');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_SCHEDULE_READ','课表-查看');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_COURSE_REGISTER','学生选课');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_COURSE_EVALUATE','学生评教');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_STUDENT_ABSENCE_WRITE','学生请假');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_STUDENT_ABSENCE_CHECK','学生批假');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_BOOKING_WRITE','借教室-申请');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_BOOKING_CHECK','借教室-审核');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_BOOKING_APPROVE','借教室-审批');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_CARD_REISSUE_WRITE','补办学生证-编辑');
Insert into tm.PERMISSION (ID,NAME) values ('PERM_CARD_REISSUE_CHECK','补办学生证-审核');

Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_SYSTEM_ADMIN','PERM_SYSTEM_SETUP');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_USER','PERM_PROFILE_SETUP');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_STUDENT','PERM_SCHEME_READ');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_TEACHER','PERM_SCHEME_READ');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_SUBJECT_DIRECTOR','PERM_SCHEME_WRITE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_STUDENT','PERM_VISION_READ');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_TEACHER','PERM_VISION_READ');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_SUBJECT_DIRECTOR','PERM_VISION_WRITE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_DEAN_OF_TEACHING','PERM_SCHEME_CHECK');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_DEAN_OF_TEACHING','PERM_VISION_CHECK');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_VISION_APPROVE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_SCHEME_APPROVE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_SUBJECT_SETUP');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_PROGRAM_ADMIN','PERM_PROGRAM_SETUP');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_COURSE_TEACHER','PERM_ROLLCALL_WRITE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_TEACHER','PERM_ROLLCALL_QUERY');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_CARD_REISSUE_WRITE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_SCHEDULE_READ');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_COURSE_EVALUATE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_STUDENT_ABSENCE_WRITE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_ABSENCE_CHECKER','PERM_ABSENCE_CHECK');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_TEACHER','PERM_BOOKING_APPLY');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_IN_SCHOOL_STUDENT','PERM_BOOKING_APPLY');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_BOOKING_CHECKER','PERM_BOOKING_CHECK');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_BOOKING_ADMIN','PERM_BOOKING_APPROVE');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_REGISTER_ADMIN','PERM_CARD_REISSUE_CHECK');
Insert into tm.ROLE_PERMISSION (ROLE_ID,PERMISSION_ID) values ('ROLE_USER','PERM_WORK_ITEMS');

Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main',          1, '主菜单',   '主菜单',   'Main');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.program',  1, '培养方案', '培养方案', 'Scheme');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.program.settings',  100, '参数设置', '参数设置', 'Settings');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.teaching', 2, '教学过程', '教学过程', 'Process');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.affair',   3, '事务处理', '事务处理', 'Affair');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('main.system',   9, '系统设置', '系统设置', 'System');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('user',          2, '用户菜单', '用户菜单', 'User');
Insert into tm.MENU (ID,DISPLAY_ORDER,NAME,LABEL_CN,LABEL_EN) values ('user.profile',  1, '用户菜单', '用户菜单', 'Profile');

Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.program.visions',11,true,'main.program','培养方案-列表','PERM_VISION_READ','/visions','培养方案目录','Vision List');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.program.visions.edit',12,true,'main.program','培养方案-编辑','PERM_VISION_WRITE','/users/${userId}/visions','编辑培养方案','Edit Vision');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.program.schemes',21,true,'main.program','教学计划-列表','PERM_SCHEME_READ','/schemes','教学计划目录','Scheme List');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.program.schemes.edit',22,true,'main.program','教学计划-编辑','PERM_SCHEME_WRITE','/users/${userId}/schemes','编辑教学计划','Edit Scheme');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.program.settings.subject',1,true,'main.program.settings','设置-校内专业','PERM_SUBJECT_SETUP','/settings/subject','专业负责人','Settings - Subject');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.program.settings.program',2,true,'main.program.settings','设置-教学计划','PERM_PROGRAM_SETUP','/settings/program','教学计划','Settings - Program');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.teaching.schedule',1,true,'main.teaching','课表','PERM_SCHEDULE_READ','/schedule','课表','Schedule');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.teaching.rollcall',2,true,'main.teaching','点名','PERM_ROLLCALL_WRITE','/rollcall','点名','Rollcall');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.teaching.rollcallStatis',3,true,'main.teaching','考勤统计','PERM_ROLLCALL_QUERY','/rollcall-statis','考勤情况','Rollcall Statis');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.teaching.courseRegister',4,true,'main.teaching','学生选课','PERM_COURSE_REGISTER','/register','选课','Register Course');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.teaching.courseEvaluation',5,true,'main.teaching','学生评教','PERM_COURSE_EVALUATE','/evaluation','评教','Evaluate Course');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.system.user',1,true,'main.system','用户','PERM_SYSTEM_SETUP','/system/users','用户','Users');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.system.role',2,true,'main.system','角色','PERM_SYSTEM_SETUP','/system/roles','角色','Roles');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.system.perm',3,true,'main.system','权限','PERM_SYSTEM_SETUP','/system/permissions','权限','Permissions');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('user.profile.modify',1,true,'user.profile','修改个人信息','PERM_PROFILE_SETUP','/profile','修改个人信息','Modify Profile');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('user.profile.password',2,true,'user.profile','修改密码','PERM_PROFILE_SETUP','/password','修改密码','Modify Password');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.affair.workItems',1,true,'main.affair','待办事项','PERM_WORK_ITEMS','/users/${userId}/works','待办事项','Work Items');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.affair.absenceForm',2,true,'main.affair','请假','PERM_STUDENT_ABSENCE_WRITE','/users/${userId}/absences','请假','Request For Leave');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.affair.bookingForm',3,true,'main.affair','借用教室','PERM_BOOKING_WRITE','/users/${userId}/bookings','借教室','Classroom Booking');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.affair.cardReissueForm',40,true,'main.affair','补办学生证','PERM_CARD_REISSUE_WRITE','/users/${userId}/cardReissues','补办学生证','ID Card Reissue');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.affair.cardReissueAdmin',41,true,'main.affair','补办学生证申请','PERM_CARD_REISSUE_CHECK','/cardReissues','补办学生证申请','Card Reissue Forms');
Insert into tm.MENU_ITEM (ID,DISPLAY_ORDER,ENABLED,MENU_ID,NAME,PERMISSION_ID,URL,LABEL_CN,LABEL_EN) values
('main.affair.cardReissueOrder',42,true,'main.affair','补办学生证订单','PERM_CARD_REISSUE_CHECK','/cardReissueOrders','补办学生证订单','Card Reissue Orders');


Insert into tm.WORKFLOW (ID,NAME) values ('scheme.create','教学计划编制');
Insert into tm.WORKFLOW (ID,NAME) values ('scheme.revise','教学计划变更');
Insert into tm.WORKFLOW (ID,NAME) values ('vision.create','培养方案编制');
Insert into tm.WORKFLOW (ID,NAME) values ('vision.revise','培养方案变更');
Insert into tm.WORKFLOW (ID,NAME) values ('card.reissue', '补办学生证申请');

Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.approve','审批','/schemes/${id}/reviews/${workitem}','scheme.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.check',  '审核','/schemes/${id}/reviews/${workitem}','scheme.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.reject', '退回','/users/${userId}/schemes#/${id}',   'scheme.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.review', '加签','/schemes/${id}/reviews/${workitem}','scheme.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.create.view',   '查看','/users/${userId}/schemes#/${id}',   'scheme.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.approve','审批','/schemes/${id}/reviews/${workitem}','scheme.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.check',  '审核','/schemes/${id}/reviews/${workitem}','scheme.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.reject', '退回','/users/${userId}/schemes#/${id}',   'scheme.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.review', '加签','/schemes/${id}/reviews/${workitem}','scheme.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('scheme.revise.view',   '查看','/users/${userId}/schemes#/${id}',   'scheme.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.approve','审批','/visions/${id}/reviews/${workitem}','vision.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.check',  '审核','/visions/${id}/reviews/${workitem}','vision.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.reject', '退回','/users/${userId}/visions#/${id}',   'vision.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.review', '加签','/visions/${id}/reviews/${workitem}','vision.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.create.view',   '查看','/users/${userId}/visions#/${id}',   'vision.create');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.approve','审批','/visions/${id}/reviews/${workitem}','vision.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.check',  '审核','/visions/${id}/reviews/${workitem}','vision.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.reject', '退回','/users/${userId}/visions#/${id}',   'vision.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.review', '加签','/visions/${id}/reviews/${workitem}','vision.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('vision.revise.view',   '查看','/users/${userId}/visions#/${id}',   'vision.revise');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('card.reissue.check',   '审核','/cardReissues/${id}/reviews/${workitem}','card.reissue');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('card.reissue.reject',  '退回','/users/${userId}/cardReissues#/${id}',   'card.reissue');
Insert into tm.WORKFLOW_ACTIVITY (ID,NAME,URL,WORKFLOW_ID) values ('card.reissue.view',    '查看','/users/${userId}/cardReissues#/${id}',   'card.reissue');
