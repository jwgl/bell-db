CREATE TABLE TM.PROGRAM_COURSE (
    PROGRAM_ID NUMBER,
    COURSE_ID VARCHAR2(8),
    PERIOD_THEORY NUMBER,
    PERIOD_EXPERIMENT NUMBER,
    PERIOD_WEEKS NUMBER,
    IS_COMPULSORY NUMBER,
    IS_PRACTICAL NUMBER,
    PROPERTY_ID NUMBER,
    ASSESS_TYPE NUMBER,
    TEST_TYPE NUMBER,
    START_WEEK NUMBER,
    END_WEEK NUMBER,
    SUGGESTED_TERM NUMBER,
    ALLOWED_TERM NUMBER,
    SCHEDULE_TYPE NUMBER,
    DEPARTMENT_ID VARCHAR2(2),
    DIRECTION_ID NUMBER
);

INSERT INTO tm.role (id,name) VALUES ('ROLE_SYSTEM_ADMIN',           '系统管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DEPARTMENT_ADMIN',       '部门管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_USER',                   '用户');
INSERT INTO tm.role (id,name) VALUES ('ROLE_TEACHER',                '教师');
INSERT INTO tm.role (id,name) VALUES ('ROLE_IN_SCHOOL_TEACHER',      '在校教师');
INSERT INTO tm.role (id,name) VALUES ('ROLE_COURSE_TEACHER',         '任课教师');
INSERT INTO tm.role (id,name) VALUES ('ROLE_SUBJECT_DIRECTOR',       '专业负责人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_DEAN_OF_TEACHING',       '教学院长');
INSERT INTO tm.role (id,name) VALUES ('ROLE_ACADEMIC_SECRETARY',     '教务秘书');
INSERT INTO tm.role (id,name) VALUES ('ROLE_SUBJECT_SECRETARY',      '教务秘书-校内专业');
INSERT INTO tm.role (id,name) VALUES ('ROLE_CLASS_SUPERVISOR',       '班主任');
INSERT INTO tm.role (id,name) VALUES ('ROLE_STUDENT_COUNSELLOR',     '辅导员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PLACE_BOOKING_CHECKER',  '借教室审核人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PLACE_BOOKING_ADMIN',    '借教室管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_PROGRAM_ADMIN',          '计划管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_REGISTER_ADMIN',         '学籍管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_STUDENT',                '学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_IN_SCHOOL_STUDENT',      '在校学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_POSTPONED_STUDENT',      '延期学习学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_COURSE_REGISTER_STUDENT','可选课学生');
INSERT INTO tm.role (id,name) VALUES ('ROLE_FREE_LISTEN_ADMIN',      '免听管理员');


INSERT INTO tm.permission (id,name) VALUES ('PERM_WORK_ITEMS',           '待办事项');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SYSTEM_SETUP',         '系统设置');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PROFILE_SETUP',        '个人设置');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_READ',          '教学计划-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_WRITE',         '教学计划-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_CHECK',         '教学计划-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_APPROVE',       '教学计划-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_ADMIN',         '教学计划-管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEME_DEPT_ADMIN',    '教学计划-学院管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_READ',          '培养方案-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_WRITE',         '培养方案-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_CHECK',         '培养方案-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_APPROVE',       '培养方案-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_ADMIN',         '培养方案-管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_VISION_DEPT_ADMIN',    '培养方案-学院管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SUBJECT_SETUP',        '设置-校内专业');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PROGRAM_SETUP',        '设置-教学计划');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ROLLCALL_WRITE',       '考勤-点名');
INSERT INTO tm.permission (id,name) VALUES ('PERM_ROLLCALL_QUERY',       '考勤-统计');
INSERT INTO tm.permission (id,name) VALUES ('PERM_SCHEDULE_READ',        '课表-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_COURSE_REGISTER',      '学生选课');
INSERT INTO tm.permission (id,name) VALUES ('PERM_COURSE_EVALUATE',      '学生评教');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_LEAVE_READ',   '学生请假-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_LEAVE_WRITE',  '学生请假-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_STUDENT_LEAVE_APPROVE','学生批假-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_READ',     '免听-查看');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_WRITE',    '免听-申请');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_CHECK',    '免听-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_FREE_LISTEN_APPROVE',  '免听-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_BOOKING_WRITE',  '借教室-申请');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_BOOKING_CHECK',  '借教室-审核');
INSERT INTO tm.permission (id,name) VALUES ('PERM_PLACE_BOOKING_APPROVE','借教室-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_CARD_REISSUE_WRITE',   '补办学生证-编辑');
INSERT INTO tm.permission (id,name) VALUES ('PERM_CARD_REISSUE_CHECK',   '补办学生证-审核');


INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SYSTEM_ADMIN',            'PERM_SYSTEM_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_USER',                    'PERM_PROFILE_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT',                 'PERM_SCHEME_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TEACHER',                 'PERM_SCHEME_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_DIRECTOR',        'PERM_SCHEME_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DEAN_OF_TEACHING',        'PERM_SCHEME_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',           'PERM_SCHEME_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',           'PERM_SCHEME_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_SECRETARY',       'PERM_SCHEME_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT',                 'PERM_VISION_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_TEACHER',                 'PERM_VISION_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_DIRECTOR',        'PERM_VISION_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_DEAN_OF_TEACHING',        'PERM_VISION_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',           'PERM_VISION_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',           'PERM_VISION_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_SUBJECT_SECRETARY',       'PERM_VISION_DEPT_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',           'PERM_SUBJECT_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PROGRAM_ADMIN',           'PERM_PROGRAM_SETUP');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_TEACHER',          'PERM_ROLLCALL_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',       'PERM_ROLLCALL_QUERY');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',       'PERM_SCHEDULE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',       'PERM_COURSE_EVALUATE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_TEACHER',          'PERM_STUDENT_LEAVE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',       'PERM_STUDENT_LEAVE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_STUDENT_COUNSELLOR',      'PERM_STUDENT_LEAVE_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_TEACHER',          'PERM_FREE_LISTEN_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',       'PERM_FREE_LISTEN_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_POSTPONED_STUDENT',       'PERM_FREE_LISTEN_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_COURSE_TEACHER',          'PERM_FREE_LISTEN_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_FREE_LISTEN_ADMIN',       'PERM_FREE_LISTEN_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',       'PERM_PLACE_BOOKING_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',       'PERM_PLACE_BOOKING_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_CHECKER',   'PERM_PLACE_BOOKING_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_PLACE_BOOKING_ADMIN',     'PERM_PLACE_BOOKING_APPROVE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_STUDENT',       'PERM_CARD_REISSUE_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_REGISTER_ADMIN',          'PERM_CARD_REISSUE_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_USER',                    'PERM_WORK_ITEMS');

INSERT INTO tm.workflow (id,name) VALUES ('scheme.create',  '教学计划编制');
INSERT INTO tm.workflow (id,name) VALUES ('scheme.revise',  '教学计划变更');
INSERT INTO tm.workflow (id,name) VALUES ('vision.create',  '培养方案编制');
INSERT INTO tm.workflow (id,name) VALUES ('vision.revise',  '培养方案变更');
INSERT INTO tm.workflow (id,name) VALUES ('card.reissue',   '补办学生证申请');
INSERT INTO tm.workflow (id,name) VALUES ('place.booking',  '借用教室申请');
INSERT INTO tm.workflow (id,name) VALUES ('student.leave',  '学生请假');
INSERT INTO tm.workflow (id,name) VALUES ('schedule.free',  '免听申请');

INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.approve','审批','/web/plan/reviewers/${userId}/schemes/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.check',  '审核','/web/plan/reviewers/${userId}/schemes/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.review', '加签','/web/plan/reviewers/${userId}/schemes/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.reject', '退回','/web/plan/users/${userId}/schemes#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.create','scheme.create.view',   '查看','/web/plan/users/${userId}/schemes#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.approve','审批','/web/plan/reviewers/${userId}/schemes/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.check',  '审核','/web/plan/reviewers/${userId}/schemes/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.review', '加签','/web/plan/reviewers/${userId}/schemes/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.reject', '退回','/web/plan/users/${userId}/schemes#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('scheme.revise','scheme.revise.view',   '查看','/web/plan/users/${userId}/schemes#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.approve','审批','/web/plan/reviewers/${userId}/visions/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.check',  '审核','/web/plan/reviewers/${userId}/visions/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.review', '加签','/web/plan/reviewers/${userId}/visions/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.reject', '退回','/web/plan/users/${userId}/visions#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.create','vision.create.view',   '查看','/web/plan/users/${userId}/visions#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.approve','审批','/web/plan/reviewers/${userId}/visions/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.check',  '审核','/web/plan/reviewers/${userId}/visions/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.review', '加签','/web/plan/reviewers/${userId}/visions/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.reject', '退回','/web/plan/users/${userId}/visions#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('vision.revise','vision.revise.view',   '查看','/web/plan/users/${userId}/visions#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('card.reissue', 'card.reissue.check',   '审核','/web/card/reviewers/${userId}/reissues#/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('card.reissue', 'card.reissue.reject',  '退回','/web/card/users/${userId}/reissues#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('card.reissue', 'card.reissue.view',    '查看','/web/card/users/${userId}/reissues#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.approve','审批','/web/place/approvers/${userId}/bookings#/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.check',  '审核','/web/place/checkers/${userId}/bookings#/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.reject', '退回','/web/place/users/${userId}/bookings#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('place.booking','place.booking.view',   '查看','/web/place/users/${userId}/bookings#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.approve','审批','/web/here/approvers/${userId}/leaves#/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.reject', '退回','/web/here/students/${userId}/leaves#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.finish', '销假','/web/here/students/${userId}/leaves#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('student.leave','student.leave.view',   '查看','/web/here/students/${userId}/leaves#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.approve','审批','/web/here/approvers/${userId}/freeListens#/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.check',  '审核','/web/here/teachers/${userId}/freeListens#/${id}/workitems/${workitem}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.reject', '退回','/web/here/students/${userId}/freeListens#/${id}');
INSERT INTO tm.workflow_activity (workflow_id,id,name,url) VALUES ('schedule.free','schedule.free.view',   '查看','/web/here/students/${userId}/freeListens#/${id}');

INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (1,   1, '1-2节',           1,  2,  '{1}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (3,   2, '3-4节',           3,  2,  '{3}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (5,   3, '5-6节',           5,  2,  '{5}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (7,   4, '7-8节',           7,  2,  '{7}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (9,   5, '第9节',           9,  1,  '{9}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (10,  6, '10-11节',         10, 2,  '{10}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (12,  7, '12-13节',         12, 2,  '{12}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (-1,  8, '白天（1-9节）',   1,  9,  '{1,3,5,7,9}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (-2,  9, '上午（1-4节）',   1,  4,  '{1,3}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (0,  10, '中午',            0,  1,  '{0}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (-3, 11, '下午（5-9节）',   5,  5,  '{5,7,9}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (-4, 12, '晚上（10-13节）', 10, 4,  '{10,12}'::int[]);
INSERT INTO tm.booking_section(id, display_order, name, start, total, includes) VALUES (-5, 13, '全天',            1,  13, '{0,1,3,5,7,9,10,12}'::int[]);
