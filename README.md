# Bell教务管理系统数据库脚本

## 文件命名规范
- **ea**_file_name.sql 用于Bell数据库EA架构
- **tm**_file_name.sql 用于Bell数据库TM架构
- **sync**_file_name.sql 用于数据同步

## 视图命名规范
- **dv**_domain_name 映射domain类的视图
- **sv**_sync_view 同步视图，在ZF数据库中定义为同步视图，在Bell数据库中定义为只读FDW外部表
- **sva**_sync_auxiliary_view 同步辅助视图，在ZF数据库中定义，不用于外部访问
- **av**_auxiliary_view 辅助视图，多表连接查询，提供完整信息
- **mv**_management_view 用于日常管理的视图

## 表命名规范
- **et**_external_table 可写的FDW外部表
- domain_name 映射domain类的表

## 数据同步
1. 在ZF数据库中创建EA和TM用户（sync-user.sql)
2. 对EA和TM用户进行授权，可访问ZF主数据库（sync-grant.sql）
3. 在ZF中创建初始数据（sync-init.sql）
4. 在ZF中创建同步视图（sync-view.sql）
5. 在Bell中创建FDW（sync-fdw.sql）
6. 数据同步（sync-merge.sql）

## 版权
本项目为开源软件，按照[Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0.html)发布。