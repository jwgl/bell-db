-- 学生用户视图
create or replace view tm_wx.dv_user as 
select id, password
from tm.system_user
where user_type = 2 and enabled;

