/**
 * 查找场地
 *
 * @param p_term_id 学期
 * @param p_start_week 开始周
 * @param p_end_week 结束周
 * @param p_odd_even 单双周
 * @param p_day_of_week 星期几
 * @param p_start_section 开始节
 * @param p_end_section 结束节
 * @param p_user_type 用户类型
 * 
 * @returns 返回满足条件的教学场地
 */
CREATE OR REPLACE FUNCTION tm.sp_find_available_place (
  p_term_id integer,
  p_start_week integer,
  p_end_week integer,
  p_odd_even integer,
  p_day_of_week integer,
  p_section_id integer,
  p_place_type varchar(20),
  p_user_type integer
) RETURNS TABLE(
   id varchar(6),
   name varchar(50),
   seat integer,
   count bigint
) AS $$
declare
  p_start_section integer;
  p_total_section integer;
  p_includes integer[];
begin
  select start, total, includes
  into p_start_section, p_total_section, p_includes
  from tm.booking_section bs
  where bs.id = p_section_id;

  return query
  select p1.id, p1.name, p1.seat, (
    select count(*)
    from booking_form bf
    join booking_item bi on bf.id = bi.form_id
    join booking_section bs on bs.id = bi.section_id
    where bf.term_id = p_term_id
    and bf.status in ('SUBMITTED', 'CHECKED')
    and bi.day_of_week = p_day_of_week
    and bs.includes && p_includes
    and exists (
        select * from generate_series(
          case odd_even
            when 0 then p_start_week
            when 1 then p_start_week / 2 * 2 + 1
            when 2 then (p_start_week - 1) / 2 * 2 + 2
          end,
          p_end_week,
          case p_odd_even when 0 then 1 else 2 end
        )
        intersect
        select * from generate_series(
          case odd_even
            when 0 then start_week
            when 1 then start_week / 2 * 2 + 1
            when 2 then (start_week - 1) / 2 * 2 + 2
          end,
          end_week,
          case odd_even when 0 then 1 else 2 end
        )
      )
  ) as count
  from ea.place p1
  where p1.id in (
    select p2.id
    from ea.place p2
    join tm.place_user_type t on p2.id = t.place_id
    where t.user_type = p_user_type
    and p2.type = p_place_type
    and (enabled = true or enabled = false and exists (
      select * from ea.place_booking_term where place_id = p2.id
    ))
    except
    select place_id
    from tm.ev_place_usage pu
    where term_id = p_term_id
      and day_of_week = p_day_of_week
      and int4range(p_start_section, p_start_section + p_total_section)
       && int4range(start_section, start_section + total_section)
      and exists (
        select * from generate_series(
          case odd_even
            when 0 then p_start_week
            when 1 then p_start_week / 2 * 2 + 1
            when 2 then (p_start_week - 1) / 2 * 2 + 2
          end,
          p_end_week,
          case p_odd_even when 0 then 1 else 2 end
        )
        intersect
        select * from generate_series(
          case odd_even
            when 0 then start_week
            when 1 then start_week / 2 * 2 + 1
            when 2 then (start_week - 1) / 2 * 2 + 2
          end,
          end_week,
          case odd_even when 0 then 1 else 2 end
        )
      )
  );
end;
$$ LANGUAGE plpgsql;

/**
 * 查询冲突的教室借用项
 *
 * @param p_form_id 借用表单ID
 *
 * @returns 冲突的教室借用项ID
 */
CREATE OR REPLACE FUNCTION tm.sp_find_booking_conflict(
  p_form_id bigint
) RETURNS TABLE (
  item_id bigint
) AS $$
begin
  return query
  with series as ( -- 生成序列，用于判断周次是否相交
    select i from generate_series(1, 30) as s(i)
  ), form_item as ( -- 备选教室借用项
    select form.term_id, item.id item_id, item.place_id,
           item.start_week, item.end_week, item.odd_even, item.day_of_week,
           bs.start as start_section, bs.total as total_section
    from booking_form form
    join booking_item item on form.id = item.form_id
    join booking_section bs on item.section_id = bs.id
    where form.id = p_form_id
  )
  select fi.item_id
  from form_item fi
  where exists (
    select place_id
    from tm.ev_place_usage pu
    where pu.term_id = fi.term_id
      and pu.place_id = fi.place_id
      and pu.day_of_week = fi.day_of_week
      and int4range(pu.start_section, pu.start_section + pu.total_section)
       && int4range(fi.start_section, fi.start_section + fi.total_section)
      and exists (
        select * from series where i between pu.start_week and pu.end_week and (pu.odd_even = 0 or pu.odd_even = 1 and i % 2 = 1 or pu.odd_even = 2 and i % 2 = 0)
        intersect
        select * from series where i between fi.start_week and fi.end_week and (fi.odd_even = 0 or fi.odd_even = 1 and i % 2 = 1 or fi.odd_even = 2 and i % 2 = 0)
      )
  );
end;
$$ LANGUAGE plpgsql;