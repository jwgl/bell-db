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

# Passwordless SSH

## Generate key
user@test241:~$ sudo -i -u postgres
postgres@test241:~$ ssh-keygen
postgres@test241:~$ cd .ssh
postgres@test241:~/.ssh$ touch config
postgres@test241:~/.ssh$ vi config
  >> Host *
  >>     StrictHostKeyChecking no
postgres@test241:~/.ssh$ cat id_rsa.pub >> authorized_keys
postgres@test241:exit

创建临时目录
user@test242:~$ mkdir ssh
user@test243:~$ mkdir ssh

复制到242和243的临时目录
postgres@test241:~$ scp .ssh/config user@172.20.32.242:~/ssh
postgres@test241:~$ scp .ssh/id_rsa user@172.20.32.242:~/ssh
postgres@test241:~$ scp .ssh/id_rsa.pub user@172.20.32.242:~/ssh
postgres@test241:~$ scp .ssh/authorized_keys user@172.20.32.242:~/ssh

postgres@test241:~$ scp .ssh/config user@172.20.32.243:~/ssh
postgres@test241:~$ scp .ssh/id_rsa user@172.20.32.243:~/ssh
postgres@test241:~$ scp .ssh/id_rsa.pub user@172.20.32.243:~/ssh
postgres@test241:~$ scp .ssh/authorized_keys user@172.20.32.243:~/ssh

复制到postgres用户目录
user@test242:~$ chmod 644 ssh/id_rsa
user@test242:~$ sudo -i -u postgres
postgres@test242:~$ mkdir .ssh
postgres@test242:~$ cp /home/jwcuser/ssh/* ~/.ssh/
postgres@test242:~$ chmod 0700 ~/.ssh
postgres@test242:~$ chmod 0644 ~/.ssh/id_rsa.pub
postgres@test242:~$ chmod 0644 ~/.ssh/authorized_keys
postgres@test242:~$ chmod 0600 ~/.ssh/id_rsa
postgres@test242:~$ chmod 0600 ~/.ssh/config

user@test243:~$ chmod 644 ssh/id_rsa
user@test243:~$ sudo -i -u postgres
postgres@test243:~$ mkdir .ssh
postgres@test243:~$ cp /home/jwcuser/ssh/* ~/.ssh/
postgres@test243:~$ chmod 0700 ~/.ssh
postgres@test243:~$ chmod 0644 ~/.ssh/id_rsa.pub
postgres@test243:~$ chmod 0644 ~/.ssh/authorized_keys
postgres@test243:~$ chmod 0600 ~/.ssh/id_rsa
postgres@test243:~$ chmod 0600 ~/.ssh/config

删除临时目录
user@test242:~$ rm -rf ssh
user@test243:~$ rm -rf ssh

测试
postgres@test241:~$ ssh -T postgres@172.20.32.242 ls
postgres@test241:~$ ssh -T postgres@172.20.32.243 ls

## 模板文件
postgres@test241:~$ mkdir /etc/postgresql/9.6/main/repltemplates
postgres@test241:~$ cp /etc/postgresql/9.6/main/postgresql.conf /etc/postgresql/9.6/main/repltemplates/postgresql.conf.primary
postgres@test241:~$ scp postgres@172.20.32.242:/etc/postgresql/9.6/main/postgresql.conf /etc/postgresql/9.6/main/repltemplates/postgresql.conf.standby

postgres@test241:~$ scp -r /etc/postgresql/9.6/main/repltemplates postgres@172.20.32.242:/etc/postgresql/9.6/main
postgres@test241:~$ scp -r /etc/postgresql/9.6/main/repltemplates postgres@172.20.32.243:/etc/postgresql/9.6/main
postgres@test241:~$ ssh -T postgres@172.20.32.242 ls /etc/postgresql/9.6/main/repltemplates/
postgres@test241:~$ ssh -T postgres@172.20.32.243 ls /etc/postgresql/9.6/main/repltemplates/

https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+4

安装pgpool2
https://www.ubuntuupdates.org/package/postgresql/xenial-pgdg/main/base/pgpool2
wget http://apt.postgresql.org/pub/repos/apt/pool/main/p/pgpool2/pgpool2_3.6.2-1.pgdg16.04+1_amd64.deb
sudo apt install libmemcached11
sudo dpkg -i pgpool2_3.6.2-1.pgdg16.04+1_amd64.deb

https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+5
https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+6



