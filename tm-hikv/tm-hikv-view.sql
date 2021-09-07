create or replace view tm_hikv.dv_place_schedule as
select id, place_id, place_name, start_date, end_date, date_interval, start_time, end_time, note
from ea.av_place_schedule_local;
