/**
 * database zf/zfxfzb
 */
grant select on zfxfzb.xydmb         to ea with grant option; -- 学院
grant select on zfxfzb.bjdmb         to ea; -- 班级
grant select on zfxfzb.yhb           to ea; -- 用户表
grant select on zfxfzb.jsxxb         to ea; -- 教师
grant select on zfxfzb.xsjbxxb       to ea with grant option; -- 学生
grant select on zfxfzb.mzdmb         to ea; -- 民族代码
grant select on zfxfzb.zzmmdmb       to ea; -- 政治面貌代码
grant select on zfxfzb.xjyddmb       to ea; -- 学籍异动代码
grant select on zfxfzb.xslbdmb       to ea; -- 学生类别代码
grant select on zfxfzb.zydmb         to ea with grant option; -- 专业
grant select on zfxfzb.jxjhzyxxb     to ea with grant option; -- 计划-专业
grant select on zfxfzb.jxjhkcxxb     to ea with grant option; -- 计划-课程
grant select on zfxfzb.zyfxb         to ea with grant option; -- 辅修
grant select on zfxfzb.fxjxjhkcxxb   to ea with grant option; -- 辅修-课程
grant select on zfxfzb.fxmkb         to ea with grant option; -- 辅修-模块
grant select on zfxfzb.kcdmb         to ea with grant option; -- 课程
grant select on zfxfzb.tykcdmb       to ea; -- 体育课
grant select on zfxfzb.tykkcdmb      to ea with grant option; -- 体育课项目
grant select on zfxfzb.bkkcfldmb     to ea; -- 外语课项目
grant select on zfxfzb.kcxzdmb       to ea with grant option; -- 课程性质
grant select on zfxfzb.xxmc          to ea; -- 参数
grant select on zfxfzb.rqkszb        to ea; -- 日期
grant select on zfxfzb.jxrwbview     to ea; -- 任务视图
grant select on zfxfzb.jxrwb         to ea with grant option; -- 任务
grant select on zfxfzb.xxkjxrwb      to ea with grant option; -- 公选课任务
grant select on zfxfzb.fxkjxrwb      to ea with grant option; -- 辅修课任务
grant select on zfxfzb.cfbjxrwb      to ea with grant option; -- 特殊课任务
grant select on zfxfzb.tykjxrwb      to ea with grant option; -- 体育课任务
grant select on zfxfzb.dgjsskxxb     to ea; -- 多教师任务
grant select on zfxfzb.tjkbapqkb     to ea; -- 推荐课表安排表
grant select on zfxfzb.bksjapb       to ea; -- 板块时间安排表
grant select on zfxfzb.bkdjjsfpb     to ea; -- 板块等级教师分配
grant select on zfxfzb.bkzyfpb       to ea; -- 板块专业分配表
grant select on zfxfzb.qtkapb        to ea; -- 其它课安排表
grant select on zfxfzb.cxbskb        to ea; -- 特殊课安排表
grant select on zfxfzb.jxcdxxb       to ea; -- 教学场地表
grant select on zfxfzb.xsxkb         to ea; -- 学生选课表
grant select on zfxfzb.cjb           to ea with grant option; -- 成绩
grant select on zfxfzb.czrzb         to ea; -- 日志
grant select on zfxfzb.ttkjlb        to ea with grant option; -- 调停课记录

/**
 * database zf/ea
 */
grant select on ea.discipline        to tm;
grant select on ea.field             to tm;
grant select on ea.sv_department     to tm;
grant select on ea.sv_property       to tm;
grant select on ea.sv_subject        to tm;
grant select on ea.sv_major          to tm;
grant select on ea.sv_program        to tm;
grant select on ea.sv_direction      to tm;
grant select on ea.sv_course         to tm;
grant select on ea.sv_program_course to tm;
