#!/usr/bin/env bash

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

mkdir -p $LOG_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_NAME

# check the user has root privileges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_NAME
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_NAME
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_NAME
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_NAME
        exit 1
    fi
}



dnf module list nodejs &>>$LOG_NAME
VALIDATE $? "Listing nodejs module"

dnf module disable nodejs -y &>>$LOG_NAME
VALIDATE $? "Disabling nodejs module"

dnf module enable nodejs:20 -y &>>$LOG_NAME
VALIDATE $? "Enabling nodejs module"

dnf install nodejs -y &>>$LOG_NAME
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_NAME
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N" | tee -a $LOG_NAME
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_NAME
VALIDATE $? "Downloading catalogue zip file"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_NAME
VALIDATE $? "Extracting catalogue zip file"

npm install &>>$LOG_NAME
VALIDATE $? "Installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_NAME
VALIDATE $? "Copying catalogue systemd service file"

systemctl daemon-reload &>>$LOG_NAME
systemctl enable catalogue &>>$LOG_NAME
systemctl start catalogue &>>$LOG_NAME
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_NAME
VALIDATE $? "Copying mongodb repo file"

dnf install mongodb-mongosh -y &>>$LOG_NAME
VALIDATE $? "Installing mongodb-mongosh"

mongosh --host mongodb.manisankardivi.online </app/db/master-data.js &>>$LOG_NAME
VALIDATE $? "Loading catalogue schema"

STATUS=$(mongosh --host mongodb.manisankardivi.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.manisankardivi.online </app/db/master-data.js &>>$LOG_NAME
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N" | tee -a $LOG_NAME
fi

echo "Script finished executing at: $(date)" | tee -a $LOG_NAME