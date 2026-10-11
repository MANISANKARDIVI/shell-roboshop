#!/usr/bin/env bash


# Start time
START_TIME=$(date +%s)

# Get user ID
USERID=$(id -u)

# Colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Log folder and file
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_NAME="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)

mkdir -p "$LOG_FOLDER"
echo "Script started executing at: $(date)" | tee -a "$LOG_NAME"

# check the user has root privileges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a "$LOG_NAME"
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a "$LOG_NAME"
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a "$LOG_NAME"
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a "$LOG_NAME"
        exit 1
    fi
}

dnf install maven -y &>>"$LOG_NAME"
VALIDATE $? "Maven Installation"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app &>>"$LOG_NAME"
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>"$LOG_NAME"
VALIDATE $? "Downloading Shipping Service Artifact"


rm -rf /app/*
cd /app
unzip /tmp/shipping.zip &>>"$LOG_NAME"
VALIDATE $? "Extracting Shipping Service Artifact"

mvn clean package  &>>$LOG_FILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE
VALIDATE $? "Moving and renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon Realod"

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Install MySQL"

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

mysql -h mysql.manisankardivi.online -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.manisankardivi.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.manisankardivi.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.manisankardivi.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"


END_TIME=$(date +%s)
echo -e "$Y Script execution time: $(($END_TIME - $START_TIME)) seconds $N" | tee -a "$LOG_NAME"
