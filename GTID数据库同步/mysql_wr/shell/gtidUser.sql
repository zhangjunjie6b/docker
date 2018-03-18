use mysql;
CREATE USER 'docker'@'%' IDENTIFIED BY 'docker';
GRANT REPLICATION SLAVE ON *.* TO 'docker'@'%';