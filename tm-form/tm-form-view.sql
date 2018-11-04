/**
 * 数据辅助视图-问题选项响应统计
 */
create or replace view tm_form.dva_question_option_response_stats(
  questionnaire_id,
  question_id,
  question_option_id,
  response_count
) as
select qf.id, q.id, 0, count(ri.text_value)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 0
group by qf.id, q.id
union all
select qf.id, q.id, qo.id, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question_option qo on ri.choice_id = qo.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 1
group by qf.id, q.id, qo.id
union all
select qf.id, q.id, 0, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 1
and q.open_ended = true
and ri.text_value is not null
group by qf.id, q.id
union all
select qf.id, q.id, qo.id, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.response_pick rp on rp.item_id = ri.id
join tm_form.question_option qo on rp.option_id = qo.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 2
group by qf.id, q.id, qo.id
union all
select qf.id, q.id, 0, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 2
and q.open_ended = true
and ri.text_value is not null
group by qf.id, q.id
union all
select qf.id, q.id, ri.int_value, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 3
group by qf.id, q.id, ri.int_value;

/**
 * 数据辅助视图-问题响应统计
 */
create or replace view tm_form.dva_question_response_stats(
  questionnaire_id,
  question_id,
  response_count,
  question_option_stats
) as
select questionnaire_id, question_id, response_count, question_option_stats
from (
  select questionnaire_id, question_id, jsonb_object_agg(question_option_id, response_count) as question_option_stats
  from tm_form.dva_question_option_response_stats
  group by questionnaire_id, question_id
) a join (
  select rf.questionnaire_id, ri.question_id, count(*) as response_count
  from tm_form.response_form rf
  join tm_form.response_item ri on ri.form_id = rf.id
  where rf.date_submitted is not null
  group by rf.questionnaire_id, ri.question_id
) b using(questionnaire_id, question_id);

/**
 * 数据视图-问卷响应统计
 */
create or replace view tm_form.dv_questionnaire_response_stats(
  id,
  response_count,
  question_stats
) as
select questionnaire_id as id, response_count, question_stats
from (
  select questionnaire_id, jsonb_object_agg(question_id, jsonb_build_object(
      'response_count', response_count,
      'question_option_stats', question_option_stats)) as question_stats
  from tm_form.dva_question_response_stats 
  group by questionnaire_id
) a join (
  select rf.questionnaire_id, count(*) as response_count
  from tm_form.response_form rf
  where rf.date_submitted is not null
  group by rf.questionnaire_id
) b using(questionnaire_id);

/**
 * 数据视图-问题开放响应统计
 */
create or replace view tm_form.dv_question_open_response_stats(
  questionnaire_id,
  question_id,
  text_value,
  response_count
) as
select qf.id, q.id, ri.text_value, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 0
group by qf.id, q.id, ri.text_value
union all
select qf.id, q.id, ri.text_value, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id
where rf.date_submitted is not null and q.type = 1
and q.open_ended = true
and ri.text_value is not null
group by qf.id, q.id, ri.text_value
union all
select qf.id, q.id, s.value, count(*)
from tm_form.questionnaire qf
join tm_form.response_form rf on rf.questionnaire_id = qf.id
join tm_form.response_item ri on ri.form_id = rf.id
join tm_form.question q on ri.question_id = q.id,
unnest(regexp_split_to_array(ri.text_value, '；')) s(value)
where rf.date_submitted is not null and q.type = 2
and q.open_ended = true
and ri.text_value is not null
group by qf.id, q.id, s.value;
