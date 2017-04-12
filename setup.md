http://askubuntu.com/questions/831292/how-to-install-postgresql-9-6-on-any-ubuntu-version

sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install postgresql-9.6
sudo apt install postgresql-9.6-pgpool2

https://www.itenlight.com/blog/2016/05/18/PostgreSQL+HA+with+pgpool-II+-+Part+1
https://www.itenlight.com/blog/2016/05/19/PostgreSQL+HA+with+pgpool-II+-+Part+2

sudo -u postgres psql
alter user postgres with password 'postgres-password';
create role replication with replication password 'replication-password' login;

## pb_basebackup without password
$ sudo -i -u postgres
$ vi .pgpass
  >> *:*:*:replication:replication-password
$ chmod 0600 .pgpass

## config postgres
$ sudo -i -u postgres
$ cd /etc/postgresql/9.6/main
$ vi postgresql.conf
  >> listen_addresses = '*'
  >> port = 5433

$ vi pg_hba.conf
  >> host    replication     replication     172.20.32.241/32        md5
  >> host    replication     replication     172.20.32.242/32        md5
  >> host    replication     replication     172.20.32.243/32        md5

## replication slot
### On 241(master)
$ vi postgresql.conf
  >> wal_level = replica
  >> max_wal_senders = 5
  >> max_replication_slots = 5
$ sudo service postgresql restart

SELECT * FROM pg_create_physical_replication_slot('rep_slot1');

### on 242/243(standby)
Base backup
$ sudo -i -u postgres
$ cd 9.6
$ rm -rf main
$ pg_basebackup -v -D main -R -P -X stream -h 172.20.32.241 -p 5433 -U replication

Config
$ vi postgresql.conf
  >> hot_standby = on
  >> hot_standby_feedback = on

$ vi recovery.conf
  >> primary_slot_name = 'rep_slot1'
  >> trigger_file = '/etc/postgresql/9.6/main/im_the_master'

$ sudo service postgresql restart

https://www.itenlight.com/blog/2016/05/23/PostgreSQL+HA+with+pgpool-II+-+Part+3
https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+4
https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+5
https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+6


安装pgpool2
https://www.ubuntuupdates.org/package/postgresql/xenial-pgdg/main/base/pgpool2

wget http://apt.postgresql.org/pub/repos/apt/pool/main/p/pgpool2/pgpool2_3.6.2-1.pgdg16.04+1_amd64.deb
dpkg -i pgpool2_3.6.2-1.pgdg16.04+1_amd64.deb