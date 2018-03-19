use mysql;
CREATE USER 'docker'@'%' IDENTIFIED BY 'docker';
GRANT REPLICATION SLAVE ON *.* TO 'docker'@'%';
update user set host='%' where user='root' and host='localhost';