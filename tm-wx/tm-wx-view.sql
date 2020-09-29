-- 学生、老师用户视图
create or replace view tm_wx.dv_user as 
select id, password, user_type, name
from tm.system_user
where (user_type = 2 or user_type = 1) and enabled;

--近一周申请的学生学号及初始密码
create or replace view tm_wx.dv_report_student_last_week as
select distinct user_id, (extract(doy from now()) * 1917)::integer as password
from tm_wx.report 
where extract(DOW FROM now()) = 6
and date_created  between current_date - interval '7 days' and current_date - interval '0 days';

