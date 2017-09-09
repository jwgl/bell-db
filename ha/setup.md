## 参考
* [https://wiki.postgresql.org/wiki/Apt](https://wiki.postgresql.org/wiki/Apt)
* [PostgreSQL HA with pgpool-II - Part 1](https://www.itenlight.com/blog/2016/05/18/PostgreSQL+HA+with+pgpool-II+-+Part+1)
* [PostgreSQL HA with pgpool-II - Part 2](https://www.itenlight.com/blog/2016/05/19/PostgreSQL+HA+with+pgpool-II+-+Part+2)

## 关闭IPV6
```bash
lxc network set lxdbr0 ipv6.address none
```

## 安装PostgreSQL和pgpool2
```bash
$ sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ zesty-pgdg main"
$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
$ sudo apt update
$ sudo apt install postgresql-9.6
$ sudo apt install postgresql-9.6-pgpool2
```

## 修改数据库用户postgres的密码和认证方法
设置postgre数据库用户密码
```bash
$ sudo -i -u postgres
$ psql
```

执行SQL:
```sql
alter user postgres with password 'postgres_password';
```

编辑pg_hba.conf
```bash
$ vi /etc/postgresql/9.6/main/pg_hba.conf
```

修改postgres的认证方式为`md5`
```
local   all             postgres                                md5
```

重启数据库
```bash
$ sudo service postgresql restart
```

## 配置复制(replication)

### 创建replication用户
```bash
$ sudo -u postgres psql
```

执行SQL
```sql
postgres=# create role replication with replication password 'replication-password' login;
```
### 可无密码执行pg_basebackup
在用户home目录创建[.pgpass](https://www.postgresql.org/docs/current/static/libpq-pgpass.html)文件，允许操作系统用户postgres以数据库用户replication户执行命令时不必输入密码。
```bash
$ sudo -i -u postgres
$ vi .pgpass
```

输入：
```
*:*:*:replication:replication-password
```
前三个*表示“任意主机”、“任意端口”、“任意数据库”，后两项表示用户名和密码。

```bash
$ chmod 0600 .pgpass
```

### 配置postgres
```bash
$ sudo -i -u postgres
$ vi /etc/postgresql/9.6/main/postgresql.conf
```

输入：
```
listen_addresses = '*'
port = 5433
```

```bash
$ vi /etc/postgresql/9.6/main/pg_hba.conf
```

输入：
```
host    replication     replication     db-server-1             md5
host    replication     replication     db-server-2             md5
host    replication     replication     db-server-3             md5
```

### 配置primary服务器
```bash
$ sudo -i -u postgres
$ vi /etc/postgresql/9.6/main/postgresql.conf
```

输入：
```
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
```
$ sudo service postgresql restart

```sql
SELECT * FROM pg_create_physical_replication_slot('rep_slot_1');
SELECT * FROM pg_create_physical_replication_slot('rep_slot_2');
SELECT * FROM pg_create_physical_replication_slot('rep_slot_3');
```
创建对应stant by的replication slot。

### 配置standby服务器
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

## 跨节点的受信postgres用户
参考:
* [Set up trusted copy between postgres accounts](https://github.com/2ndQuadrant/repmgr/blob/master/SSH-RSYNC.md)
```bash
root@db-server-base:~# sudo -i -u postgres
postgres@db-server-base:~$ ssh-keygen -t rsa
```
```
ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/var/lib/postgresql/.ssh/id_rsa):
Created directory '/var/lib/postgresql/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /var/lib/postgresql/.ssh/id_rsa.
Your public key has been saved in /var/lib/postgresql/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:CxThnyaFBqRjZlvN1gNZHK7ki7nAk5tLsCLgBo0bEic postgres@db-server-base
```
```bash
postgres@db-server-base:~$ cd .ssh
postgres@db-server-base:~/.ssh$ cat id_rsa.pub >> authorized_keys
postgres@db-server-base:~/.ssh$ chmod go-rwx ./*
postgres@db-server-base:~/.ssh$ exit
root@db-server-base:~# exit
```
创建快照：
```bash
$ lxc snapshot db-server-base passwordless-postgres
```

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



## 配置pgpool2
参考：
* [enable md5 authentication](http://www.pgpool.net/mediawiki/index.php/FAQ#I_created_pool_hba.conf_and_pool_passwd_to_enable_md5_authentication_through_pgpool-II_but_it_does_not_work._Why.3F)

### 修改pgpool.conf
```bash
$ sudo vi /etc/pgpool2/pgpool.conf
```
进行如下配置：
```
listen_addresses = '*'
backend_hostname0 = 'localhost'
backend_data_directory0 = '/var/lib/postgresql/9.6/main'
```

### 修改pgpool认证方法
```bash
$ sudo vi /etc/pgpool2/pool_hba.conf
```
修改认证方法为`md5`。

### 生成pool_passwd
```bash
$ pg_md5 --md5auth --username=postgres postgres_password
```
重启pgpool2服务。

### 测试连接pgpool2
```bash
$ psql -p 5433 -Upostgres
```