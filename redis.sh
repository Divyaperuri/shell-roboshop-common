#!/bin/bash

source ./common.sh

check_root

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling the Redis"
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling the Redis 7"
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing the redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote Connections to Redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling the Redis"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "Start the Redis"

print_time