Hibernate: create table ea.term_swap_date (id int8 not null, from_date date not null, term_id int4 not null, to_date date not null, primary key (id))
Hibernate: comment on table ea.term_swap_date is 'У����������'
Hibernate: comment on column ea.term_swap_date.from_date is 'Դ����'
Hibernate: comment on column ea.term_swap_date.to_date is 'Ŀ������'
Hibernate: alter table ea.term_swap_date add constraint FKiiylyhqj638sl3b4bthdly2dk foreign key (term_id) references ea.term