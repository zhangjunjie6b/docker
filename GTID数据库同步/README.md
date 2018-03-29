基于GTID主从数据库同步的docker环境
------------
[TOC]

## GTID概述
> 1、全局事物标识：global transaction identifieds。

> 2、GTID事物是全局唯一性的，且一个事务对应一个GTID。

> 3、一个GTID在一个服务器上只执行一次，避免重复执行导致数据混乱或者主从不一致。

> 4、GTID用来代替classic的复制方法，不在使用binlog+pos开启复制。而是使用master_auto_postion=1的方式自动匹配GTID断点进行复制。

> 5、MySQL-5.6.5开始支持的，MySQL-5.6.10后开始完善。

> 6、在传统的slave端，binlog是不用开启的，但是在GTID中，slave端的binlog是必须开启的，目的是记录执行过的GTID（强制）。

## GTID 优势
> 1、更简单的实现failover，不用以前那样在需要找log_file和log_Pos。

> 2、更简单的搭建主从复制。

> 3、比传统复制更加安全。

> 4、GTID是连续没有空洞的，因此主从库出现数据冲突时，可以用添加空事物的方式进行跳过。

##日志点配置
Master my.cnf配置片段

    [mysqld]
    server-id = 1                                 #服务器id
    gtid_mode = on                                #开启gtid模式
    log-bin = /data/mysql/binlog/master-binlog    #开启binlog
    enforce_gtid_consistency = 1                  #强制gtid一致性，开启后对于特定create table不被支持
    log_slave_update = 1                          #开启从库写入binlog
    binlog_format = row                           #binlog开启row模式
    relay_log_recovery = 1                        #开启中继日志完整性（当slave从库宕机后，假如relay-log损坏了，导致一部分中继日志没有处理，则自动放弃所有未执行的relay-log，并且重新从master上获取日志，这样就保证了relay-log的完整性。）
    sync-binlog = 1                               #强制将binlog_cache写入磁盘，一致性要求不高的场景下设置为0可关闭，性能会大幅提速数倍
    skip_slave_start = 1                          #使slave在mysql启动时不启动复制进程，使用 start slave启动 `

Slave my.cnf配置片段

    [mysqld]
    server-id = 5                                 #服务器id
    gtid_mode = on                                #开启gtid模式
    log-bin = /data/mysql/binlog/slave-binlog     #开启binlog
    enforce_gtid_consistency = 1                  #强制gtid一致性，开启后对于特定create table不被支持
    log_slave_update = 1                          #开启从库写入binlog
    binlog_format = row                           #binlog开启row模式
    relay_log_recovery = 1                        #开启中继日志完整性（当slave从库宕机后，假如relay-log损坏了，导致一部分中继日志没有处理，则自动放弃所有未执行的relay-log，并且重新从master上获取日志，这样就保证了relay-log的完整性。）
    sync-binlog = 1                               #强制将binlog_cache写入磁盘，一致性要求不高的场景下设置为0可关闭，性能会大幅提速数倍
    skip_slave_start = 1                          #使slave在mysql启动时不启动复制进程，使用 start slave启动 

在Master上创建主从复制账号

    CREATE USER 'docker'@'%' IDENTIFIED BY 'docker';
    GRANT REPLICATION SLAVE ON *.* TO 'docker'@'%';
    flush privileges;(shell已创建)

在Slave上执行
 
    CHANGE MASTER TO MASTER_HOST=mysql-m,MASTER_PORT=3306,MASTER_USER='docker',MASTER_PASSWORD='docker',master_log_file='slave-binlog.000005',master_log_pos=191;
    START SLAVE;
    SHOW SLAVE STATUS\G;

##部署说明
1.获取 

    git clone git@github.com:526353781/docker.git

2.进入 GTID 目录 构建服务

    docker-compose up 

3.部署成功后会看见以下2个容器
![容器启动][1]
  gtid_mysql-m 主库 3308端口
  gtid_mysql-c 从库 3307端口
  
4.查看主库 ID 并获取binlog信息

    远程连接主库执行 show master status;

获取文件名和偏移量
![binlog][2]

5.连接从库执行（注：master_log_file，master_log_pos需替换为上一步获取到的信息）
   
    change master to master_host='mysql-m',master_user='docker',master_password='docker',master_log_file='slave-binlog.000004',master_log_pos=191;

    启动同步 start slave;

## 更新历史

### 2018年03月21日23:33:54
- [x] README 编写GTID 和 dome 中的相关文档
- [ ] 尝试shell 获取主库 binlog 名称和偏移量
- [ ] 罗列数据库参数配置信息 
### 2018年03月19日23:42:31
- [x] 编写 docker-compose
- [x] 修复 dockerfile build 镜像root账号对外无法连接
- [ ] README 编写GTID 和 dome 中的相关文档
- [ ] 尝试shell 获取主库 binlog 名称和偏移量

### 2018年03月18日23:38:50
- [x] 构建GTID 主从数据库 dockerfile 
- [x] shell 创建 repl 同步账号
- [ ] 编写 docker-compose
 



  [1]: http://pic.geekstool.com/markdown/WX20180321-213059@2x.png
  [2]: http://pic.geekstool.com/markdown/WX20180321-231526@2x.png