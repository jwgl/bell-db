create or replace view tm_dual.dv_agreement_carryout_view as
select distinct sj.id as subject_id,
    sj.name as subject_name,
    r.name as region_name,
    m.grade,
    etm.major_id
from tm_dual.agreement a
join tm_dual.cooperative_university u on a.university_id = u.id
join tm_dual.agreement_region r on u.region_id = r.id
join tm_dual.agreement_subject s on s.agreement_id = a.id
join ea.subject sj on sj.id = s.subject_id
join ea.major m on m.subject_id = sj.id and m.grade >= s.started_grade and m.grade <= s.ended_grade
left join tm.et_dualdegree_major_region etm on m.id::text = etm.major_id::text and r.name = etm.region;
