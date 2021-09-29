-- 创建架构
create schema tm_huis authorization tm;

-- 工作流状态
create type tm_huis.workflow_state as enum (
    'CREATED',
    'SUBMITTED',
    'CHECKED',
    'APPROVED',
    'REJECTED',
    'SENT_BACK',
    'TERMINATED',
    'REQUESTED',
    'CONFIRMED'
);

-- 借用单状态
create type tm_huis.booking_form_status as enum (
    'INACTIVE',
    'ACTIVE',
    'REVOKED',
    'CLOSED'
);

-- 借用项状态
create type tm_huis.booking_item_status as enum (
    'INACTIVE',
    'ACTIVE',
    'UNUSED',
    'CANCELED',
    'REVOKED',
    'CLOSED'
);

-- 借用设施状态
create type tm_huis.booking_facility_status as enum (
    'INACTIVE',
    'ACTIVE',
    'UNUSED',
    'CANCELED',
    'REVOKED',
    'CLOSED'
);

-- 结算单状态
create type tm_huis.statement_form_status as enum (
    'INACTIVE',
    'ACTIVE',
    'REVOKED',
    'CLOSED'
);

-- 会议设施类别
create type tm_huis.facility_type as enum (
    'BASIC_SERVICE',
    'BASIC_DETAIL',
    'EXTRA_SERVICE',
    'REQUIRED_SERVICE'
);

INSERT INTO tm.role (id,name) VALUES ('ROLE_HUIS_BOOKING_CHECKER',     '会议室借用审核人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUIS_BOOKING_ADMIN',       '会议室借用审批人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUIS_ROOM_OPERATOR',       '会议室管理员');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUIS_STATEMENT_MANAGER',   '会议室结算经办人');
INSERT INTO tm.role (id,name) VALUES ('ROLE_HUIS_STATEMENT_CHECKER',   '会议室结算审核人');

INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_PUBLIC_ROOM_READ',  '公共会议室-查询');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_SCHEDULE_READ',     '会议室安排-查询');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_BOOKING_WRITE',     '会议室借用-申请');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_BOOKING_CHECK',     '会议室借用-审批');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_BOOKING_ADMIN',     '会议室借用-管理');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_OPERATION_WRITE',   '会议室使用-确认');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_OPERATION_CHECK',   '会议室借用-确认');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_STATEMENT_WRITE',   '会议室结算-申请');
INSERT INTO tm.permission (id,name) VALUES ('PERM_HUIS_STATEMENT_CHECK',   '会议室结算-审批');

INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',      'PERM_HUIS_PUBLIC_ROOM_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',      'PERM_HUIS_BOOKING_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_IN_SCHOOL_TEACHER',      'PERM_HUIS_OPERATION_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_BOOKING_CHECKER',   'PERM_HUIS_BOOKING_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_BOOKING_ADMIN',     'PERM_HUIS_BOOKING_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_BOOKING_ADMIN',     'PERM_HUIS_STATEMENT_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_BOOKING_ADMIN',     'PERM_HUIS_SCHEDULE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_BOOKING_ADMIN',     'PERM_HUIS_BOOKING_ADMIN');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_ROOM_OPERATOR',     'PERM_HUIS_OPERATION_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_ROOM_OPERATOR',     'PERM_HUIS_SCHEDULE_READ');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_STATEMENT_MANAGER', 'PERM_HUIS_STATEMENT_WRITE');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_HUIS_STATEMENT_CHECKER', 'PERM_HUIS_STATEMENT_CHECK');
INSERT INTO tm.role_permission (role_id,permission_id) VALUES ('ROLE_BUILDING_KEEPER',        'PERM_HUIS_SCHEDULE_READ');

INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.huisPublicRoom', 'main.affair', '会议室列表', '/huis/users/${userId}/publicRooms', true, array['TM-HUIS-API'], 60, 'PERM_HUIS_PUBLIC_ROOM_READ');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.huisBookingForm', 'main.affair', '会议室借用申请', '/huis/users/${userId}/bookingForms', true, array['TM-HUIS-API'], 61, 'PERM_HUIS_BOOKING_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.affair.huisOperationTask', 'main.affair', '会议室借用确认', '/huis/users/${userId}/operationTasks', true, array['TM-HUIS-API'], 62, 'PERM_HUIS_OPERATION_CHECK');

INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisBookingTask', 'main.resource', '会议室借用审批', '/huis/users/${userId}/bookingTasks', true, array['TM-HUIS-API'], 20, 'PERM_HUIS_BOOKING_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisOperationForm', 'main.resource', '会议室使用确认', '/huis/users/${userId}/operationForms', true, array['TM-HUIS-API'], 21, 'PERM_HUIS_OPERATION_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisStatementForm', 'main.resource', '会议室借用结算', '/huis/users/${userId}/statementForms', true, array['TM-HUIS-API'], 22, 'PERM_HUIS_STATEMENT_WRITE');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisStatementTask', 'main.resource', '会议室结算审批', '/huis/users/${userId}/statementTasks', true, array['TM-HUIS-API'], 23, 'PERM_HUIS_STATEMENT_CHECK');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisRoomSchedule', 'main.resource', '会议室使用安排', '/huis/users/${userId}/roomSchedules', true, array['TM-HUIS-API'], 24, 'PERM_HUIS_SCHEDULE_READ');

INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.settings.huisBookingAuth', 'main.settings', '会议室借用审核人', '/huis/settings/bookingAuths', true, array['TM-HUIS-API'], 51, 'PERM_HUIS_BOOKING_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.settings.huisRoomSetting', 'main.settings', '会议室设置', '/huis/departments/${departmentId}/rooms', true, array['TM-HUIS-API'], 52, 'PERM_HUIS_BOOKING_ADMIN');

INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisBookingAdmin', 'main.resource', '会议室借用管理', '/huis/departments/${departmentId}/bookingForms', true, array['TM-HUIS-API'], 25, 'PERM_HUIS_BOOKING_ADMIN');
INSERT INTO tm.menu_item(id, menu_id, label, url, enabled, depends_on, display_order, permission_id) VALUES
('main.resource.huisStatementAdmin', 'main.resource', '会议室结算管理', '/huis/statementForms', true, array['TM-HUIS-API'], 26, 'PERM_HUIS_BOOKING_ADMIN');
