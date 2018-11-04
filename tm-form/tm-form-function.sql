/**
 * 按学生查找可用调查问卷
 */
create or replace function tm_form.sp_find_available_questionnaire_by_student(
  p_student_id text         -- 学生ID
) returns table (
  hash_id text,             -- Hash ID
  pollster text,            -- 调查人
  department text,          -- 所在单位
  title text,               -- 标题
  prologue text,            -- 欢迎词
  survey_type int4,         -- 调查类型
  anonymous boolean,        -- 是否匿名
  date_published timestamp, -- 发布时间
  date_expired timestamp,   -- 截止时间
  form_id bigint            -- 创建但未提交的响应表单ID
)
as $$
declare
  v_student_properties jsonb;
  v_student_department_id ea.department.id%TYPE;
  v_student_admin_class_id ea.admin_class.id%TYPE;
begin
  select jsonb_build_object(
      '学院', department.name,
      '性别', sex,
      '年级', grade,
      '专业', subject.name,
      '班级', admin_class.name
    ), department.id, admin_class.id
  into v_student_properties, v_student_department_id, v_student_admin_class_id
  from ea.student
  join ea.department on student.department_id = department.id
  join ea.major on student.major_id = major.id
  join ea.subject on major.subject_id = subject.id
  join ea.admin_class on student.admin_class_id = admin_class.id
  where student.id = p_student_id;

  return query 
  select q.hash_id, u.name::text as pollster, 
    d.name::text as department,
    q.title, case
      when length(q.prologue) > 97 then substring(q.prologue, 1, 97) || '...'
      else q.prologue
    end as prologue,
    q.survey_type, q.anonymous, q.date_published, q.date_expired,
    f.id as form_id
  from tm_form.questionnaire q
  join tm.system_user u on q.pollster_id = u.id
  join ea.department d on q.department_id = d.id
  join ea.admin_class ac on q.admin_class_id = ac.id
  left join tm_form.response_form f on f.questionnaire_id = q.id and f.respondent_id = p_student_id -- 已创建
  where q.respondent_type = 2 -- 面向学生 
  and q.status = 'APPROVED' -- 已批准
  and q.published = true -- 已发布
  and q.date_expired > current_timestamp -- 未过期
  and (q.survey_scope = 0 -- 校级
    or q.survey_scope = 1 and q.department_id = v_student_department_id -- 院级
    or q.survey_scope = 2 and q.admin_class_id = v_student_admin_class_id -- 班级
  )
  and (jsonb_array_length(oriented) = 0 or v_student_properties @> any(select jsonb_array_elements(q.oriented))) -- 面向对象
  and not v_student_properties @> any(select jsonb_array_elements(q.restricted)) -- 限制对象
  and f.date_submitted is null -- 未响应的问卷
  order by date_published desc;
end;
$$ language plpgsql;

/**
 * 按教师查找可用调查问卷
 */
create or replace function tm_form.sp_find_available_questionnaire_by_teacher(
  p_teacher_id text         -- 教师ID
) returns table (
  hash_id text,             -- Hash ID
  pollster text,            -- 调查人
  department text,          -- 所在单位
  title text,               -- 标题
  survey_scope int4,        -- 调查范围
  anonymous boolean,        -- 是否匿名
  date_published timestamp, -- 发布时间
  date_expired timestamp,   -- 截止时间
  form_id bigint            -- 创建但未提交的响应表单ID
)
as $$
declare
  v_teacher_properties jsonb;
  v_teacher_department_id ea.department.id%TYPE;
begin
  select jsonb_build_object(
      '学院', department.name,
      '性别', sex
  ), department.id
  into v_teacher_properties, v_teacher_department_id
  from ea.teacher
  join ea.department on teacher.department_id = department.id
  where teacher.id = p_teacher_id;

  return query 
  select q.hash_id, u.name::text as pollster, 
    d.name::text as department,
    q.title, q.survey_scope, q.anonymous, q.date_published, q.date_expired,
    f.id as form_id
  from tm_form.questionnaire q
  join tm.system_user u on q.pollster_id = u.id
  join ea.department d on q.department_id = d.id
  left join tm_form.response_form f on f.questionnaire_id = q.id and f.respondent_id = p_teacher_id -- 已创建
  where q.respondent_type = 1 -- 面向教师 
  and q.status = 'APPROVED' -- 已批准
  and q.published = true -- 已发布
  and q.date_expired > current_timestamp -- 未过期
  and (q.survey_scope = 0 -- 校级
    or q.survey_scope = 1 and q.department_id = v_teacher_department_id -- 院级
  )
  and (jsonb_array_length(oriented) = 0 or v_teacher_properties @> any(select jsonb_array_elements(q.oriented))) -- 面向对象
  and not v_teacher_properties @> any(select jsonb_array_elements(q.restricted)) -- 限制对象
  and f.date_submitted is null -- 未响应的问卷
  order by date_published desc;
end;
$$ language plpgsql;