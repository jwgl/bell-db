-- 创建用户
create user tm with password 'bell_tm_password';

-- 创建架构
create schema tm authorization tm;

INSERT INTO tm.role (id,name) VALUES ('ROLE_SYSTEM_ADMIN',               '系统管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DEPARTMENT_ADMIN',           '部门管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_USER',                       '用户');
INSERT INTO tm.role (id,name) VALUES ('ROLE_TEACHER',                    '教师');
INSERT INTO tm.role (id,name) VALUES ('ROLE_IN_SCHOOL_TEACHER',          '在校教师');
INSERT INTO tm.role (id,name) VALUES ('ROLE_COURSE_CLASS_TEACHER',       '主讲教师-当前学期');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ONCE_COURSE_CLASS_TEACHER',  '主讲教师-以往学期');
INSERT INTO tm.role (id,name) VALUES ('ROLE_TASK_SCHEDULE_TEACHER',      '任课教师-当前学期');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ONCE_TASK_SCHEDULE_TEACHER', '任课教师-以往学期');
INSERT INTO tm.role (id,name) VALUES ('ROLE_SUBJECT_DIRECTOR',           '专业负责人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DEAN_OF_TEACHING',           '教学院长');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ACADEMIC_SECRETARY',         '教务秘书');
INSERT INTO tm.role (id,name) VALUES ('ROLE_SUBJECT_SECRETARY',          '教务秘书-校内专业');
INSERT INTO tm.role (id,name) VALUES ('ROLE_CLASS_SUPERVISOR',           '班主任');
INSERT INTO tm.role (id,name) VALUES ('ROLE_STUDENT_COUNSELLOR',         '辅导员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PLACE_BOOKING_CHECKER',      '借教室审核人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PLACE_BOOKING_ADMIN',        '借教室管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_BOOKING_ADV_USER',           '借教室高级用户');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PROGRAM_ADMIN',              '计划管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_REGISTER_ADMIN',             '学籍管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_STUDENT',                    '学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_IN_SCHOOL_STUDENT',          '在校学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_POSTPONED_STUDENT',          '延期学习学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_COURSE_REGISTER_STUDENT',    '可选课学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_FREE_LISTEN_ADMIN',          '免听管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ROLLCALL_ADMIN',             '考勤管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ROLLCALL_DEPT_ADMIN',        '考勤管理员-学院');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PLACE_KEEPER',               '教室管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_BUILDING_KEEPER',            '教学楼管理员');

INSERT INTO tm.permission (id,name) VALUES ('PERM_WORK_ITEMS',                     '待办事项');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SYSTEM_SETUP',                   '系统设置');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PROFILE_SETUP',                  '个人设置');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_READ',                    '教学计划-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_WRITE',                   '教学计划-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_CHECK',                   '教学计划-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_APPROVE',                 '教学计划-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_ADMIN',                   '教学计划-管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_DEPT_ADMIN',              '教学计划-学院管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_READ',                    '培养方案-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_WRITE',                   '培养方案-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_CHECK',                   '培养方案-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_APPROVE',                 '培养方案-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_ADMIN',                   '培养方案-管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_DEPT_ADMIN',              '培养方案-学院管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SUBJECT_SETUP',                  '设置-校内专业');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PROGRAM_SETUP',                  '设置-教学计划');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ATTENDANCE_DEPT_ADMIN',          '考勤-学院统计列表');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ATTENDANCE_CLASS_ADMIN',         '考勤-班级统计列表');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ATTENDANCE_ITEM',                '考勤-统计个人');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ROLLCALL_WRITE',                 '考勤-点名');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEDULE_READ',                  '课表-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_COURSE_REGISTER',                '学生选课');
INSERT INTO tm.permission (id,name) VALUES ('PERM_COURSE_EVALUATE',                '学生评教');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_LEAVE_READ',             '学生请假-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_LEAVE_WRITE',            '学生请假-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_LEAVE_APPROVE',          '学生批假-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_READ',               '免听-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_WRITE',              '免听-申请');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_CHECK',              '免听-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_APPROVE',            '免听-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_BOOKING_WRITE',            '借教室-申请');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_BOOKING_CHECK',            '借教室-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_BOOKING_APPROVE',          '借教室-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_BOOKING_MISCONDUCT_WRITE',       '教室违规-记录');
INSERT INTO tm.permission (id,name) VALUES ('PERM_BOOKING_MISCONDUCT_CHECK',       '教室违规-核实');
INSERT INTO tm.permission (id,name) VALUES ('PERM_BOOKING_MISCONDUCT_APPROVE',     '教室违规-处理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_USAGE_READ',               '教室使用情况');
INSERT INTO tm.permission (id,name) VALUES ('PERM_CARD_REISSUE_WRITE',             '补办学生证-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_CARD_REISSUE_APPROVE',           '补办学生证-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_TASK_SCHEDULE_READ',             '排课-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_TASK_SCHEDULE_EXECUTE',          '排课-执行');
INSERT INTO tm.permission (id,name) VALUES ('PERM_COURSE_CLASS_READ',              '教学班-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_COURSE_CLASS_EXECUTE',           '教学班-执行');
INSERT INTO tm.permission (id,name) VALUES ('PERM_EXAM_DISQUAL_DEPT_ADMIN',        '取消考试资格-管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_EXAM_DISQUAL_WRITE',             '取消考试资格-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_SCHEDULES_READ',         '学生个人课表-查看');
      
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SYSTEM_ADMIN',               'PERM_SYSTEM_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_USER',                       'PERM_PROFILE_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT',                    'PERM_SCHEME_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TEACHER',                    'PERM_SCHEME_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_CLASS_TEACHER',       'PERM_COURSE_CLASS_EXECUTE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_CLASS_TEACHER',       'PERM_COURSE_CLASS_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ONCE_COURSE_CLASS_TEACHER',  'PERM_COURSE_CLASS_EXECUTE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ONCE_COURSE_CLASS_TEACHER',  'PERM_COURSE_CLASS_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TASK_SCHEDULE_TEACHER',      'PERM_TASK_SCHEDULE_EXECUTE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TASK_SCHEDULE_TEACHER',      'PERM_TASK_SCHEDULE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ONCE_TASK_SCHEDULE_TEACHER', 'PERM_TASK_SCHEDULE_EXECUTE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ONCE_TASK_SCHEDULE_TEACHER', 'PERM_TASK_SCHEDULE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_DIRECTOR',           'PERM_SCHEME_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DEAN_OF_TEACHING',           'PERM_SCHEME_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',              'PERM_SCHEME_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',              'PERM_SCHEME_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_SECRETARY',          'PERM_SCHEME_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT',                    'PERM_VISION_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TEACHER',                    'PERM_VISION_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_DIRECTOR',           'PERM_VISION_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DEAN_OF_TEACHING',           'PERM_VISION_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',              'PERM_VISION_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',              'PERM_VISION_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_SECRETARY',          'PERM_VISION_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',              'PERM_SUBJECT_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',              'PERM_PROGRAM_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ROLLCALL_DEPT_ADMIN',        'PERM_ATTENDANCE_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT_COUNSELLOR',         'PERM_ATTENDANCE_CLASS_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_CLASS_SUPERVISOR',           'PERM_ATTENDANCE_CLASS_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_ATTENDANCE_ITEM');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_POSTPONED_STUDENT',          'PERM_ATTENDANCE_ITEM');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TASK_SCHEDULE_TEACHER',      'PERM_ROLLCALL_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_SCHEDULE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_COURSE_EVALUATE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TASK_SCHEDULE_TEACHER',      'PERM_STUDENT_LEAVE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT_COUNSELLOR',         'PERM_STUDENT_LEAVE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_CLASS_SUPERVISOR',           'PERM_STUDENT_LEAVE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_STUDENT_LEAVE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_POSTPONED_STUDENT',          'PERM_STUDENT_LEAVE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT_COUNSELLOR',         'PERM_STUDENT_LEAVE_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TASK_SCHEDULE_TEACHER',      'PERM_FREE_LISTEN_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_FREE_LISTEN_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_POSTPONED_STUDENT',          'PERM_FREE_LISTEN_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_CLASS_TEACHER',       'PERM_FREE_LISTEN_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_FREE_LISTEN_ADMIN',          'PERM_FREE_LISTEN_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',          'PERM_PLACE_BOOKING_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_PLACE_BOOKING_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_BOOKING_ADV_USER',           'PERM_PLACE_BOOKING_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_CHECKER',      'PERM_PLACE_BOOKING_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_CHECKER',      'PERM_BOOKING_MISCONDUCT_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_ADMIN',        'PERM_PLACE_BOOKING_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_ADMIN',        'PERM_BOOKING_MISCONDUCT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_ADMIN',        'PERM_BOOKING_MISCONDUCT_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_KEEPER',               'PERM_BOOKING_MISCONDUCT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_BUILDING_KEEPER',            'PERM_BOOKING_MISCONDUCT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_USER',                       'PERM_PLACE_USAGE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_CARD_REISSUE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_REGISTER_ADMIN',             'PERM_CARD_REISSUE_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_USER',                       'PERM_WORK_ITEMS');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ACADEMIC_SECRETARY',         'PERM_COURSE_CLASS_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_ACADEMIC_SECRETARY',         'PERM_EXAM_DISQUAL_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_CLASS_TEACHER',       'PERM_EXAM_DISQUAL_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',          'PERM_STUDENT_SCHEDULES_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_POSTPONED_STUDENT',          'PERM_STUDENT_SCHEDULES_READ');

INSERT INTO tm.menu(id, label, display_order) VALUES ('main',               '主菜单',       01);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.program',       '教学计划',     10);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.process',       '教学过程',     20);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.steer',         '质量监控',     30);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.dual',          '联合培养',     40);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.dual.workflow', '审核流程',     41);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.affair',        '事务处理',     50);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.resource',      '资源管理',     55);
INSERT INTO tm.menu(id, label, display_order) VALUES ('main.settings',      '系统设置',     90);
INSERT INTO tm.menu(id, label, display_order) VALUES ('user',               '用户菜单',     02);
INSERT INTO tm.menu(id, label, display_order) VALUES ('user.profile',       '${userName}', 10);

INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.visionList', 'main.program', '培养方案目录', '/plan/visions', true, array['TM-PLAN-API'], 10, 'PERM_VISION_READ');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.visionDraft', 'main.program', '编辑培养方案', '/plan/users/${userId}/visions', true, array['TM-PLAN-API'], 11, 'PERM_VISION_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.visionCheck', 'main.program', '培养方案审核', '/plan/checkers/${userId}/visions', true, array['TM-PLAN-API'], 12, 'PERM_VISION_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.visionApproval', 'main.program', '培养方案审批', '/plan/approvers/${userId}/visions', true, array['TM-PLAN-API'], 13, 'PERM_VISION_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.schemeList', 'main.program', '教学计划目录', '/plan/schemes', true, array['TM-PLAN-API'], 20, 'PERM_SCHEME_READ');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.schemeDraft', 'main.program', '编辑教学计划', '/plan/users/${userId}/schemes', true, array['TM-PLAN-API'], 21, 'PERM_SCHEME_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.schemeCheck', 'main.program', '教学计划审核', '/plan/checkers/${userId}/schemes', true, array['TM-PLAN-API'], 22, 'PERM_SCHEME_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.schemeApproval', 'main.program', '教学计划审批', '/plan/approvers/${userId}/schemes', true, array['TM-PLAN-API'], 23, 'PERM_SCHEME_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.schemeAdmin', 'main.program', '教学计划管理', '/plan/admin/schemes', true, array['TM-PLAN-API'], 24, 'PERM_SCHEME_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.program.schemeDeptAdmin', 'main.program', '教学计划管理', '/plan/departments/${departmentId}/schemes', true, array['TM-PLAN-API'], 25, 'PERM_SCHEME_DEPT_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.studentTimetable', 'main.process', '我的课表', '/core/students/${userId}/schedules', true, array['TM-CORE-API'], 10, 'PERM_STUDENT_SCHEDULES_READ');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.rollcallForm', 'main.process', '点名', '/here/teachers/${userId}/rollcalls', true, array['TM-HERE-API'], 20, 'PERM_ROLLCALL_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.studentLeaveForm', 'main.process', '请假', '/here/students/${userId}/leaves', true, array['TM-HERE-API'], 30, 'PERM_STUDENT_LEAVE_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.studentLeaveApproval', 'main.process', '批假', '/here/approvers/${userId}/leaves', true, array['TM-HERE-API'], 31, 'PERM_STUDENT_LEAVE_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.freeListenForm', 'main.process', '免听申请', '/here/students/${userId}/freeListens', true, array['TM-HERE-API'], 40, 'PERM_FREE_LISTEN_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.freeListenCheck', 'main.process', '免听审核', '/here/teachers/${userId}/freeListens', true, array['TM-HERE-API'], 41, 'PERM_FREE_LISTEN_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.freeListenApproval', 'main.process', '免听审批', '/here/approvers/${userId}/freeListens', true, array['TM-HERE-API'], 42, 'PERM_FREE_LISTEN_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.courseClassAttendancesByTeacher', 'main.process', '教学班考勤','/here/teachers/${userId}/courseClasses', true, array['TM-HERE-API'], 50, 'PERM_COURSE_CLASS_EXECUTE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.courseClassAttendancesByDepartment', 'main.process', '开课单位考勤', '/here/departments/${departmentId}/courseClasses', true, array['TM-HERE-API'], 51, 'PERM_EXAM_DISQUAL_DEPT_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.adminClassAttendancesByTeacher', 'main.process', '行政班考勤', '/here/teachers/${userId}/adminClasses', true, array['TM-HERE-API'], 52, 'PERM_ATTENDANCE_CLASS_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.adminClassAttendancesByDepartment', 'main.process', '学生学院考勤', '/here/departments/${departmentId}/adminClasses', true, array['TM-HERE-API'], 53, 'PERM_ATTENDANCE_DEPT_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.process.studentAttendances', 'main.process', '我的考勤', '/here/students/${userId}/attendances', true, array['TM-HERE-API'], 54, 'PERM_ATTENDANCE_ITEM');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.workitems', 'main.affair', '待办事项', '/core/users/${userId}/works', true, array['TM-CORE-API'], 10, 'PERM_WORK_ITEMS');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.cardReissueForm', 'main.affair', '补办学生证申请', '/card/students/${userId}/reissues', true, array['TM-CARD-API'], 40, 'PERM_CARD_REISSUE_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.cardReissueApproval', 'main.affair', '补办学生证审批', '/card/approvers/${userId}/reissues', true, array['TM-CARD-API'], 41, 'PERM_CARD_REISSUE_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.cardReissueOrder', 'main.affair', '补办学生证订单', '/card/reissueOrders', true, array['TM-CARD-API'], 42, 'PERM_CARD_REISSUE_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.placeUsage', 'main.affair', '教室使用情况', '/place/usages', true, array['TM-PLACE-API'], 51, 'PERM_PLACE_USAGE_READ');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.placeBookingForm', 'main.affair', '借用教室申请', '/place/users/${userId}/bookings', true, array['TM-PLACE-API'], 52, 'PERM_PLACE_BOOKING_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.settings.subject', 'main.settings', '校内专业', '/plan/settings/subjects', true, array['TM-PLAN-API'], 10, 'PERM_SUBJECT_SETUP');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.settings.program', 'main.settings', '教学计划', '/plan/settings/programs', true, array['TM-PLAN-API'], 11, 'PERM_PROGRAM_SETUP');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.settings.placeBookingAuth', 'main.settings', '借用教室审核人', '/place/settings/bookingAuths', true, array['TM-PLACE-API'], 50, 'PERM_PLACE_BOOKING_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('user.profile.modify', 'user.profile', '修改个人信息', '/core/users/${userId}/profile', true, array['TM-CORE-API'], 10, 'PERM_PROFILE_SETUP');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('user.profile.password', 'user.profile', '修改密码', '/core/users/${userId}/password', true, array['TM-CORE-API'], 20, 'PERM_PROFILE_SETUP');

INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.placeBookingCheck', 'main.resource', '借用教室审核', '/place/checkers/${userId}/bookings', true, array['TM-PLACE-API'], 10, 'PERM_PLACE_BOOKING_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.placeBookingApproval', 'main.resource', '借用教室审批', '/place/approvers/${userId}/bookings', true, array['TM-PLACE-API'], 11, 'PERM_PLACE_BOOKING_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.placeBookingReport', 'main.resource', '借用教室报表', '/place/bookingReports', true, array['TM-PLACE-API'], 12, 'PERM_PLACE_BOOKING_APPROVE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.misconductRecord', 'main.resource', '教室违规记录', '/place/keepers/${userId}/bookings', true, array['TM-PLACE-API'], 13, 'PERM_BOOKING_MISCONDUCT_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.misconductCheck', 'main.resource', '教室违规核实', '/place/checkers/${userId}/misconducts', true, array['TM-PLACE-API'], 14, 'PERM_BOOKING_MISCONDUCT_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.misconductApprove', 'main.resource', '教室违规处理', '/place/approvers/${userId}/misconducts', true, array['TM-PLACE-API'], 15, 'PERM_BOOKING_MISCONDUCT_APPROVE');

INSERT INTO tm.workflow (id,name) VALUES ('scheme.create',  '教学计划编制');
INSERT INTO tm.workflow (id,name) VALUES ('scheme.revise',  '教学计划变更');
INSERT INTO tm.workflow (id,name) VALUES ('vision.create',  '培养方案编制');
INSERT INTO tm.workflow (id,name) VALUES ('vision.revise',  '培养方案变更');
INSERT INTO tm.workflow (id,name) VALUES ('card.reissue',   '补办学生证申请');
INSERT INTO tm.workflow (id,name) VALUES ('place.booking',  '借用教室申请');
INSERT INTO tm.workflow (id,name) VALUES ('student.leave',  '学生请假');
INSERT INTO tm.workflow (id,name) VALUES ('schedule.free',  '免听申请');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.approve','审批','/plan/approvers/${userId}/schemes/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.check',  '审核','/plan/checkers/${userId}/schemes/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.review', '加签','/plan/reviewers/${userId}/schemes/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.reject', '退回','/plan/users/${userId}/schemes/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.view',   '查看','/plan/users/${userId}/schemes/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.approve','审批','/plan/approvers/${userId}/schemes/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.check',  '审核','/plan/checkers/${userId}/schemes/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.review', '加签','/plan/reviewers/${userId}/schemes/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.reject', '退回','/plan/users/${userId}/schemes/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.view',   '查看','/plan/users/${userId}/schemes/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.approve','审批','/plan/approvers/${userId}/visions/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.check',  '审核','/plan/checkers/${userId}/visions/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.review', '加签','/plan/reviewers/${userId}/visions/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.reject', '退回','/plan/users/${userId}/visions/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.view',   '查看','/plan/users/${userId}/visions/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.approve','审批','/plan/approvers/${userId}/visions/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.check',  '审核','/plan/checkers/${userId}/visions/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.review', '加签','/plan/reviewers/${userId}/visions/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.reject', '退回','/plan/users/${userId}/visions/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.view',   '查看','/plan/users/${userId}/visions/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('card.reissue', 'card.reissue.approve', '审批','/card/approvers/${userId}/reissues/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('card.reissue', 'card.reissue.reject',  '退回','/card/students/${userId}/reissues/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('card.reissue', 'card.reissue.view',    '查看','/card/students/${userId}/reissues/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.approve','审批','/place/approvers/${userId}/bookings/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.check',  '审核','/place/checkers/${userId}/bookings/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.reject', '退回','/place/users/${userId}/bookings/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.view',   '查看','/place/users/${userId}/bookings/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.approve','审批','/here/approvers/${userId}/leaves/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.reject', '退回','/here/students/${userId}/leaves/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.finish', '销假','/here/students/${userId}/leaves/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.view',   '查看','/here/students/${userId}/leaves/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.approve','审批','/here/approvers/${userId}/freeListens/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.check',  '审核','/here/teachers/${userId}/freeListens/${todo}/${id};wi=${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.reject', '退回','/here/students/${userId}/freeListens/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.view',   '查看','/here/students/${userId}/freeListens/${id}');

INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (1,   1, '1-2节',           1,  2,  '{1}'::int[],                 b'0000000000000011'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (3,   2, '3-4节',           3,  2,  '{3}'::int[],                 b'0000000000001100'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (5,   3, '5-6节',           5,  2,  '{5}'::int[],                 b'0000000000110000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (7,   4, '7-8节',           7,  2,  '{7}'::int[],                 b'0000000011000000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (9,   5, '第9节',           9,  1,  '{9}'::int[],                 b'0000000100000000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10,  6, '10-11节',         10, 2,  '{10}'::int[],                b'0000011000000000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (12,  7, '12-13节',         12, 2,  '{12}'::int[],                b'0001100000000000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (-1,  8, '白天（1-9节）',    1,  9,  '{1,3,5,7,9}'::int[],         b'0000000111111111'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (-2,  9, '上午（1-4节）',    1,  4,  '{1,3}'::int[],               b'0000000000001111'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (0,  10, '中午',            0,  1,  '{0}'::int[],                 b'1000000000000000'::int, 0, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (-3, 11, '下午（5-9节）',    5,  5,  '{5,7,9}'::int[],             b'0000000111110000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (-4, 12, '晚上（10-13节）',  10, 4,  '{10,12}'::int[],             b'0001111000000000'::int, 0, 20202);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (-5, 13, '全天',            1,  13, '{0,1,3,5,7,9,10,12}'::int[], b'1001111111111111'::int, 0, 20202);

INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10102,   1, '1-2节',           1,  2,  '{10102}'::int[],                                 b'0000000000000011'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10302,   2, '3-4节',           3,  2,  '{10302}'::int[],                                 b'0000000000001100'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10502,   3, '5-6节',           5,  2,  '{10502}'::int[],                                 b'0000000000110000'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10702,   4, '7-8节',           7,  2,  '{10702}'::int[],                                 b'0000000011000000'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10902,   5, '9-10节',          9,  2,  '{10902}'::int[],                                 b'0000001100000000'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (11102,   6, '11-12节',        11,  2,  '{11102}'::int[],                                 b'0000110000000000'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10108,   8, '白天（1-8节）',    1,  8,  '{10102,10302,10502,10702}'::int[],              b'0000000011111111'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10104,   9, '上午（1-4节）',    1,  4,  '{10102,10302}'::int[],                          b'0000000000001111'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10504,  10, '下午（5-8节）',    5,  4,  '{10502,10702}'::int[],                          b'0000000011110000'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10904,  11, '晚上（9-12节）',   9,  4,  '{10902,11102}'::int[],                          b'0000111100000000'::int, 20211, 99999);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes, value, start_term, end_term) VALUES (10112,  12, '全天',            1,  12, '{0,10102,10302,10502,10702,10902,11102}'::int[], b'1000111111111111'::int, 20211, 99999);
