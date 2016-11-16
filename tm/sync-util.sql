/**
 * database zf/tm
 */

CREATE OR REPLACE PACKAGE "TM"."UTIL" AS 
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
   * 逗句分隔字符串转换为整数
   * number_to_csv_bit(7, 1) => '2,3'
   */
  function number_to_csv_bit(value number, init number) return varchar2;
  
  /**
   * 获取星期几
   */
  function day_of_week(x in date) return number;
END UTIL;

/

CREATE OR REPLACE PACKAGE BODY "TM"."UTIL" as
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
   * 整数转换为逗句分隔字符串，不包含init所在位
   * value - 按位标记的整数
   * init - 取消设置位
   */
  function number_to_csv_bit(value number, init number) return varchar2 as
    result varchar2(100);
    initFlag number;
    flag number;
    newInit number;
    newValue number;
  begin
    -- 小学期折回正常学期
    if init > 16 then
      newInit := init - 16;
    else
      newInit := init;
    end if;

    newValue := bitor(floor(value / power(2, 16)), bitand(value, power(2, 16) - 1));    

    initFlag := power(2, newInit - 1);

    if newValue = initFlag then
      return null;
    end if;

    for i in 1..16 loop
      flag := power(2, i - 1);
      if initFlag <> flag and bitand(newValue, flag) <> 0 then
        if result is null then
          result := to_char(i);
        else
          result := result || ',' || i;
        end if;
      end if;
    end loop;
    return result;
  end number_to_csv_bit;

  /**
   * 获取星期几
   */
  function day_of_week(x in date) return number is
  begin
    return 1 + trunc(x) - trunc(x, 'IW');
  end;
end util;

/
