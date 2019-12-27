\copy tm_load.human_resource_teacher_import(id, name, department, sex, birthday, age, country, date_entrolled, employment_mode, employment_status, academic_degree, post_type, technical_post) from 'hr-info.csv' csv header;

insert into tm_load.human_resource_teacher(id, name, department, sex, birthday, age, country, date_entrolled,
  employment_mode, employment_status, academic_degree, post_type, technical_post)
select id, name, department, sex, birthday, age, country, date_entrolled,
  employment_mode, employment_status, academic_degree, post_type, technical_post
from tm_load.human_resource_teacher_import
on conflict(id) do update set
id = excluded.id,
name = excluded.name,
department = excluded.department,
sex = excluded.sex,
birthday = excluded.birthday,
age = excluded.age,
country = excluded.country,
date_entrolled = excluded.date_entrolled,
employment_mode = excluded.employment_mode,
employment_status = excluded.employment_status,
academic_degree = excluded.academic_degree,
post_type = excluded.post_type,
technical_post = excluded.technical_post;


with teacher_map as (
    select a.id tid, b.id hid from ea.teacher a join tm_load.human_resource_teacher b on a.human_resource_number=b.id
), duplicate_map as (
    select * from teacher_map where hid in (select hid from teacher_map group by hid having count(*) > 1) 
), duplicate_term as (
    select hid, tid, max(term_id) as max_term
    from ea.av_task_schedule a
    join duplicate_map b on a.teacher_id = b.tid
    group by hid, tid
), unique_teacher as (
    select distinct on(hid) hid, tid, max_term
    from duplicate_term
    order by hid, max_term desc
), unique_map as (
    select hid, tid from unique_teacher
    union
    select hid, tid from teacher_map where hid not in (select hid from unique_teacher)
)
update tm_load.human_resource_teacher a
set teacher_id = unique_map.tid
from unique_map
where unique_map.hid = a.id;
