/**
 * database zf/zfxfzb
 */

grant select on zfxfzb.zydmb                   to tm; -- 专业代码表
grant select on zfxfzb.yhb                     to tm; -- 用户表
grant select on zfxfzb.xydmb                   to tm; -- 学院
grant select on zfxfzb.jsxxb                   to tm; -- 教师
grant select on zfxfzb.xsjbxxb                 to tm; -- 学生
grant select on zfxfzb.bjdmb                   to tm; -- 班级
grant select on zfxfzb.jxrwbview               to tm; -- 任务视图
grant select on zfxfzb.cjb                     to tm; -- 成绩
grant select on zfxfzb.czrzb                   to tm; -- 日志
grant select on zfxfzb.ttksqb                  to tm; -- 调停课申请表
grant select on zfxfzb.jxcdxxb                 to tm; -- 教学场地信息表
grant select on zfxfzb.jxcdview_old_tms        to tm; -- 教学场地使用视图

grant insert on zfxfzb.jxjhkcxxb               to tm; -- 教学计划课程信息表
grant insert on zfxfzb.ttksqb                  to tm; -- 教学计划课程信息表
grant select, insert, delete on zfxfzb.jxcdyyb to tm; -- 教学场地预约表

grant select, 
      update(bz, bz_operator) on zfxfzb.xsxkb  to tm; -- 学生选课表
grant select, zfxfzb.cjb                       to tm; -- 成绩表

grant usage on schema tm to tm_dual;	

grant references on tm.workflow_instance    to tm_dual;	