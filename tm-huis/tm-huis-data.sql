insert into tm.system_config(key, type, value, description) values
('huis.statement.delay', 'I', 14, '结算延期天数');

insert into tm_huis.booking_type(id, name, role_id) values
(101, '借用管理员', 'ROLE_HUIS_BOOKING_ADMIN'),
(102, '缺省部门借用审核人', 'ROLE_HUIS_BOOKING_CHECKER'),
(103, '部门结算审核人', 'ROLE_HUIS_STATEMENT_CHECKER'),
(104, '部门结算经办人', 'ROLE_HUIS_STATEMENT_MANAGER'),
(201, '会议', 'ROLE_HUIS_BOOKING_CHECKER'),
(202, '讲座', 'ROLE_HUIS_BOOKING_CHECKER'),
(203, '论坛', 'ROLE_HUIS_BOOKING_CHECKER'),
(204, '培训', 'ROLE_HUIS_BOOKING_CHECKER'),
(205, '典礼', 'ROLE_HUIS_BOOKING_CHECKER'),
(206, '演出', 'ROLE_HUIS_BOOKING_CHECKER'),
(207, '比赛', 'ROLE_HUIS_BOOKING_CHECKER'),
(301, '教学活动', 'ROLE_HUIS_BOOKING_CHECKER'),
(302, '教师活动', 'ROLE_HUIS_BOOKING_CHECKER'),
(303, '学生活动', 'ROLE_HUIS_BOOKING_CHECKER'),
(304, '就业活动', 'ROLE_HUIS_BOOKING_CHECKER');