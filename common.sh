#!/bin/bash

# call by sh <script-name>
# call by source <script-name>

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop-common"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-scripting/17-loops.sh
START_TIME=$(date +%s)

MONGODB_HOST=mongodb.devopslearn.sh
MYSQL_HOST=mysql.devopslearn.sh

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

check_root(){
    if [ $USERID -ne 0 ]; then
        echo "ERROR:: Please run this script with root privilage"
        exit 1 #failure is other than 0
    fi 
}

VALIDATE(){ #functions receive the i/p's through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "Installing $2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "Installing $2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling NodeJS"
    dnf module enable nodejs:20 -y  &>>$LOG_FILE
    VALIDATE $? "Enabling NodeJS 20"
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing NodeJS" 

    npm install &>>$LOG_FILE
    VALIDATE $? "Install dependencies"
}

java_setup(){
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "Installing Maven"
    mvn clean package &>>$LOG_FILE
    VALIDATE $? "Clean the package"
    mv target/shipping-1.0.jar shipping.jar
    VALIDATE $? "Move the file"   
}

rabbitmq_setup(){
    cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
    VALIDATE $? "Adding RabbitMQ repo"
    dnf install rabbitmq-server -y &>>$LOG_FILE
    VALIDATE $? "Installing RabbitMQ Server"
    systemctl enable rabbitmq-server &>>$LOG_FILE
    VALIDATE $? "Enabling RabbitMQ Server"
    systemctl start rabbitmq-server &>>$LOG_FILE
    VALIDATE $? "Starting RabbitMQ"
    rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
    VALIDATE $? "Setting up permissions"
}

python_setup(){
    dnf install python3 gcc python3-devel -y &>>$LOG_FILE
    VALIDATE $? "Installing the Python3"
    pip3 install -r requirements.txt &>>$LOG_FILE
    VALIDATE $? "Install the requirements"
}

app_setup(){
    mkdir -p /app
    VALIDATE $? "Creating app directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    VALIDATE $? "Downloading $app_name application"

    cd /app 
    VALIDATE $? "Changing to app directory"

    rm -rf /app/*
    VALIDATE $? "Removing existing code"

    unzip /tmp/$app_name.zip &>>$LOG_FILE
    VALIDATE $? "unzip $app_name"
}

systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Copy systemctl service"

    systemctl daemon-reload
    systemctl enable $app_name &>>$LOG_FILE
    VALIDATE $? "Enable $app_name"
}

app_restart(){
        systemctl restart $app_name
    VALIDATE $? "Restart the $app_name"
}
print_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
}
