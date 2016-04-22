/**
 * database zf/ea
 */

drop table ea.term;

create table ea.term(
	id number(5,0) primary key,
	start_date date,
	start_week number(2,0),
	mid_left number(2,0),
	mid_right number(2,0),
	end_week number(2,0),
	max_week number(2,0)
);

Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20021,to_date('2002-10-07','yyyy-mm-dd'),1,null,null,16,19);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20022,to_date('2003-02-17','yyyy-mm-dd'),1,null,null,20,28);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20031,to_date('2003-09-01','yyyy-mm-dd'),1,null,null,20,24);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20032,to_date('2004-02-16','yyyy-mm-dd'),1,null,null,21,29);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20041,to_date('2004-09-06','yyyy-mm-dd'),1,null,null,20,25);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20042,to_date('2005-02-28','yyyy-mm-dd'),1,null,null,20,27);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20051,to_date('2005-09-05','yyyy-mm-dd'),1,null,null,20,24);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20052,to_date('2006-02-20','yyyy-mm-dd'),1,null,null,20,28);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20061,to_date('2006-09-04','yyyy-mm-dd'),1,null,null,20,26);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20062,to_date('2007-03-05','yyyy-mm-dd'),1,null,null,19,26);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20071,to_date('2007-09-03','yyyy-mm-dd'),1,null,null,20,24);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20072,to_date('2008-02-18','yyyy-mm-dd'),1,null,null,20,28);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20081,to_date('2008-09-01','yyyy-mm-dd'),1,null,null,20,24);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20082,to_date('2009-02-16','yyyy-mm-dd'),1,null,null,20,29);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20091,to_date('2009-09-07','yyyy-mm-dd'),1,null,null,20,25);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20092,to_date('2010-03-01','yyyy-mm-dd'),1,null,null,20,28);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20101,to_date('2010-09-13','yyyy-mm-dd'),1,null,null,18,22);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20102,to_date('2011-02-14','yyyy-mm-dd'),1,18,20,23,30);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20111,to_date('2011-09-12','yyyy-mm-dd'),1,null,null,18,22);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20112,to_date('2012-02-13','yyyy-mm-dd'),1,18,20,23,31);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20121,to_date('2012-09-17','yyyy-mm-dd'),1,null,null,18,23);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20122,to_date('2013-02-25','yyyy-mm-dd'),1,18,19,22,29);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20131,to_date('2013-09-16','yyyy-mm-dd'),1,null,null,18,22);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20132,to_date('2014-02-17','yyyy-mm-dd'),1,18,19,22,30);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20141,to_date('2014-09-15','yyyy-mm-dd'),1,null,null,19,24);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20142,to_date('2015-03-02','yyyy-mm-dd'),1,19,20,21,27);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20151,to_date('2015-09-07','yyyy-mm-dd'),1,null,null,19,24);
Insert into TERM (ID,START_DATE,START_WEEK,MID_LEFT,MID_RIGHT,END_WEEK,MAX_WEEK) values (20152,to_date('2016-02-29','yyyy-mm-dd'),1,19,20,21,27);
