#!/bin/bash

source ./common.sh

check_root

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MYSQL"
systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling the MYSQL"
systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Start the MYSQL"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting up Root Passwprd"

print_time