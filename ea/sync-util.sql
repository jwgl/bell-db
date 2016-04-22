/**
 * database zf/ea
 */

CREATE OR REPLACE PACKAGE "EA"."UTIL" AS 
  /**
   * 按位或
   * bitor(1, 2) => 3
   */
  function bitor(x in number, y in number) return number;
  
  /**
   * 按位异或
   */
  function bitxor(x in number, y in number) return number;
  
  /**
   * 按位取反
   */
  function bitnot(x in number) return number;
  
  /** 
   * 逗句分隔字符串转换为整数
   * csv_bit_to_number('1,2,3')    => 7(0111)
   * csv_bit_to_number('1,3', 2)   => 7(0111)
   * csv_bit_to_number('1,2,3', 2) => 7(0111)
   */
  function csv_bit_to_number(csv in varchar2, init in number) return number;
  
  /**
   * 获取星期几
   */
  function day_of_week(x in date) return number;
END UTIL;

/

CREATE OR REPLACE PACKAGE BODY "EA"."UTIL" as
  /**
   * 按位或
   */
  function bitor(x number, y number) return number as
  begin
    return (x+y)-bitand(x,y);
  end bitor;

  /**
   * 按位异或
   */
  function bitxor(x in number, y in number) return number as
  begin
      return bitor(x,y) - bitand(x,y);
  end;

  /**
   * 按位取反
   */
  function bitnot(x in number) return number as 
  begin
      return (0 - x) - 1;
  end;

  /** 
   * 逗句分隔字符串转换为整数
   * csv - 逗句分隔字符器
   * init - 必设位
   */
  function csv_bit_to_number(csv in varchar2, init number) return number as
    cursor v_itemCursor(items varchar2) is
      select regexp_substr(items, '\d+', 1, level) as value
      from dual
      connect by level <= regexp_count(items, '\d+');
    result number;
    flag number;
  begin 
    if init is null or init <= 0 then
      result := 0;
    else
      result := power(2, init - 1);
    end if;
    
    if csv is null then 
       return result;
    end if;
    
    for item in v_itemCursor(csv) loop
      flag := power(2, item.value - 1);
      result := bitor(result, flag);
    end loop;
    
    -- if 0 then null
    if result = 0 then
      return null;
    else
      return result;
    end if;
  end csv_bit_to_number;
  
  /**
   * 获取星期几
   */
  function day_of_week(x in date) return number is
  begin
    return 1 + trunc(x) - trunc(x, 'IW');
  end;
end util;

/

/**
 * 保存当前学期已同步的教学班数据。
 * 由于当前学期的教学任务可能变化，如临时新增任务，导致按顺序生成ID的方法失效。
 * 在每次同步前，需要将EA中当前学期的教学班ID和选课课号的映射关系写回ZF数据库EA用户
 * 的curr_course_class_id表中，写回前必须清空表中已有数据。
 * 同步过程中，需要查找不在curr_course_class_id表中数据，rank后，加上已有数据的最
 * 大值，从而产生新的对应关系。
 */
create table ea.curr_course_class_id (
	course_class_id number(13),
	original_id varchar2(31),
	primary key(course_class_id, original_id)
);