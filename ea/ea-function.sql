create or replace function tm.update_student_leave_approver()
returns trigger
as $$
declare
  p_term_start date;
  p_term_end date;
  p_count integer;
begin
  select start_date, start_date + max_week * interval  '1 week' - interval '1 day'
  into p_term_start, p_term_end
  from ea.term
  where active = true;

  update tm.workitem w set
  to_user = new.counsellor_id
  where to_user = old.counsellor_id
  and from_user in (
    select id from ea.student where admin_class_id = new.id
  )
  and activity = 'student.leave.approve'
  and date_processed is null
  and date_created between p_term_start and p_term_end;
  get diagnostics p_count = row_count;
  
  raise notice 'Update admin_class counsellor from % to new %, update % student leave approve workitems.',
    old.counsellor_id, new.counsellor_id, p_count;
  return new;
end;
$$ language plpgsql;
