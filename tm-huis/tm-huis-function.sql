create or replace function tm_huis.fn_find_public_rooms(
  p_user_id text,
  p_start_date date,
  p_end_date date
) returns table (
  id int,
  name text,
  department_id text,
  department_name text,
  furniture text,
  seat int,
  max_seat int,
  area int,
  unit_price numeric(6,2),
  time_unit int,
  is_internal_free boolean,
  is_public boolean,
  facilities jsonb,
  booked_times jsonb
) as $$
declare
  v_range tsrange;
begin
  v_range := tsrange(p_start_date, p_end_date + 1, '[)');

  return query
  select room.id,
    room.name,
    department.id::text as department_id,
    department.name::text as department_name,
    room.furniture,
    room.seat,
    room.max_seat,
    room.area,
    room.unit_price,
    room.time_unit,
    room.is_internal_free,
    room.is_public,
    (select jsonb_agg(jsonb_build_object(
          'id', facility.id,
          'name', facility.name,
          'unitPrice', facility.unit_price,
          'unitName', facility.unit_name,
          'timeUnit', facility.time_unit,
          'quantity', room_facility.quantity,
          'isBasic', room_facility.is_basic
        ) order by facility.id)
      from tm_huis.room_facility
      join tm_huis.facility on room_facility.facility_id = facility.id       
      where room_facility.room_id = room.id
    ) as facilities,
    (with booking as (
        select booking_item.id,
          booking_item.booking_time,
          booking_item.actual_time
        from tm_huis.booking_form
        join tm_huis.booking_item on booking_form.id = booking_item.form_id
        where booking_item.room_id = room.id
        and booking_form.status = 'ACTIVE'
        and booking_item.status = 'ACTIVE'
        and (booking_item.booking_time && v_range or booking_item.actual_time && v_range)
      ), booking_all as (
        select booking.id, booking_time as occupied_time, false as is_actual
        from booking
        where actual_time is null
        union all
        select booking.id, booking_time + actual_time, true
        from booking
        where booking_time && actual_time
        union all
        select booking.id, actual_time, true
        from booking
        where not booking_time && actual_time
        union all
        select x.id, reserved_time, false
        from (
          select room_reservation.id, tsrange(
            (reserved_date + room_reservation.lower_time)::timestamp,
            (reserved_date + room_reservation.upper_time)::timestamp,
            '[)'
          ) as reserved_time
          from tm_huis.room_reservation, generate_series(
            lower_date, upper_date, (date_interval || 'day')::interval
          ) t(reserved_date)
          where room_reservation.room_id = room.id
        ) x
        where reserved_time && v_range
      )
      select jsonb_agg(jsonb_build_object(
          'id', booking_all.id,
          'lowerTime', lower(occupied_time),
          'upperTime', upper(occupied_time),
          'isActual', is_actual
        ) order by lower(occupied_time))
      from booking_all
    ) as booked_times
  from tm_huis.room
  join ea.department on room.department_id = department.id
  order by room.name;
end;
$$ language plpgsql;

create or replace function tm_huis.fn_find_schedules_by_user(
  p_user_id text,
  p_start_date date,
  p_end_date date
) returns table (
  booked_date date,
  booked_times jsonb
) as $$
declare
  v_range tsrange;
begin
  v_range := tsrange(p_start_date, p_end_date + 1, '[)');
  return query
  with booking as (
    select booking_item.id,
      booking_item.room_id,
      booking_form.subject,
      booking_item.booking_time,
      booking_item.actual_time
    from tm_huis.booking_form
    join tm_huis.booking_item on booking_form.id = booking_item.form_id
    join tm_huis.room on booking_item.room_id = room.id
    and booking_form.status = 'ACTIVE'
    and booking_item.status = 'ACTIVE'
    where (booking_item.booking_time && v_range or booking_item.actual_time && v_range)
  ), booking_all as (
    select booking.id, room_id, subject,
      lower(booking_time) as lower_time,
      upper(booking_time) as upper_time,
      false as is_actual
    from booking
    where actual_time is null
    union all
    select booking.id, room_id, subject,
      lower(booking_time + actual_time),
      upper(booking_time + actual_time),
      true
    from booking
    where booking_time && actual_time
    union all
    select booking.id, room_id, subject,
      lower(actual_time),
      upper(actual_time),
      true
    from booking
    where not booking_time && actual_time
  )
  select lower_time::date as occupied_date,
    jsonb_agg(jsonb_build_object(
      'id', booking_all.id,
      'building', room.building,
      'room', room.name,
      'subject', booking_all.subject,
      'lowerTime', substr(lower_time::text, 12, 5),
      'upperTime', substr(upper_time::text, 12, 5),
      'isActual', is_actual
    ) order by lower_time) as booked_times
  from booking_all
  join tm_huis.room on booking_all.room_id = room.id
  group by lower_time::date;
end;
$$ language plpgsql;

create or replace function tm_huis.fn_find_schedules_by_room(
  p_room_id int,
  p_start_date date,
  p_end_date date
) returns table (
  booked_date date,
  booked_times jsonb
) as $$
declare
  v_range tsrange;
begin
  v_range := tsrange(p_start_date, p_end_date + 1, '[)');
  return query
  with booking as (
    select booking_item.id,
      booking_item.room_id,
      booking_form.subject,
      booking_item.booking_time,
      booking_item.actual_time
    from tm_huis.booking_form
    join tm_huis.booking_item on booking_form.id = booking_item.form_id
    join tm_huis.room on booking_item.room_id = room.id
    and booking_form.status = 'ACTIVE'
    and booking_item.status = 'ACTIVE'
    where (booking_item.booking_time && v_range or booking_item.actual_time && v_range)
    and room.id = p_room_id
  ), booking_all as (
    select booking.id, room_id, subject,
      lower(booking_time) as lower_time,
      upper(booking_time) as upper_time,
      false as is_actual
    from booking
    where actual_time is null
    union all
    select booking.id, room_id, subject,
      lower(booking_time + actual_time),
      upper(booking_time + actual_time),
      true
    from booking
    where booking_time && actual_time
    union all
    select booking.id, room_id, subject,
      lower(actual_time),
      upper(actual_time),
      true
    from booking
    where not booking_time && actual_time
  )
  select lower_time::date as occupied_date,
    jsonb_agg(jsonb_build_object(
      'id', booking_all.id,
      'building', room.building,
      'room', room.name,
      'subject', booking_all.subject,
      'lowerTime', substr(lower_time::text, 12, 5),
      'upperTime', substr(upper_time::text, 12, 5),
      'isActual', is_actual
    ) order by lower_time) as booked_times
  from booking_all
  join tm_huis.room on booking_all.room_id = room.id
  group by lower_time::date;
end;
$$ language plpgsql;
