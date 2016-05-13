CREATE OR REPLACE PROCEDURE IMP_COURSE_CLASS_ID AS 
BEGIN
  
INSERT INTO curr_course_class_id
WITH jxrw AS
  (SELECT DISTINCT xn,xq,kkxy,kcdm,kcmc,xkkh FROM sva_task_base a
  ) ,
  id_old AS
  (SELECT rank() over (partition BY xn,xq,kkxy order by kcdm) order_course,
    rank() over (partition BY xn,xq,kkxy,kcdm order by xkkh) order_class,
    a.*
  FROM jxrw a
  JOIN curr_course_class_id b
  ON a.xkkh=b.original_id
  ORDER BY xn,
    xq,
    kkxy,
    order_course,
    order_class
  ) ,
  id_old_course_max AS
  (SELECT xn,
    xq,
    kkxy,
    MAX(order_course) order_course
  FROM id_old
  GROUP BY xn,
    xq,
    kkxy
  ) ,
  id_old_class_max AS
  (SELECT xn,
    xq,
    kkxy,
    kcdm,
    MAX(order_class) order_class
  FROM id_old
  GROUP BY xn,
    xq,
    kkxy,
    kcdm
  ) ,
  id_new AS
  (SELECT rank() over (partition BY xn,xq,kkxy order by kcdm) order_course,
    rank() over (partition BY xn,xq,kkxy,kcdm order by xkkh) order_class,
    a.*,a1.id
  FROM jxrw a join sv_department a1 on a.kkxy=a1.name
  LEFT JOIN curr_course_class_id b
  ON a.xkkh            =b.original_id
  WHERE b.original_id IS NULL
  ) ,
  id_imp AS
  (SELECT a.xn,
    a.xq,
    a.kkxy,a.id,
    a.kcdm,
    a.kcmc,
    a.xkkh,
    a.order_course+NVL(b.order_course,0) order_course,
    a.order_class +NVL(c.order_class,0) order_class
  FROM id_new a
  LEFT JOIN id_old_course_max b
  ON a.xn   =b.xn
  AND a.xq  =b.xq
  AND a.kkxy=b.kkxy
  LEFT JOIN id_old_class_max c
  ON a.xn   =c.xn
  AND a.xq  =c.xq
  AND a.kkxy=c.kkxy
  AND a.kcdm=c.kcdm
  )
SELECT SUBSTR(xn,0,4)
  ||xq||id
  ||TO_CHAR(order_course,'fm000')
  ||TO_CHAR(order_class,'fm000'),
  xkkh
FROM id_imp ;
END IMP_COURSE_CLASS_ID;