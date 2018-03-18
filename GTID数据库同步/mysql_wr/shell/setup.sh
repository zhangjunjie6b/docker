#!/bin/bash
set -e #报错就弹出

echo '1.启动mysql...'
service mysql start

sleep 3
echo `service mysql status`
sleep 3

echo '2.导入GTID同步账号'
#导入数据
mysql < /tmp/gtidUser.sql
echo '3.导入完毕'

sleep 3
echo `service mysql reload`

echo `mysql容器启动完毕,且数据导入成功`


tail -f /dev/null #保持docker在执行完shell后运行
