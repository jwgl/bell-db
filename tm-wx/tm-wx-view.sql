-- 学生、老师用户视图
create or replace view tm_wx.dv_user as 
select id, password, user_type, name
from tm.system_user
where (user_type = 2 or user_type = 1) and enabled;

