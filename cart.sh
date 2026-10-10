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
SCRIPT_NAME=$( echo $0 | cut -d "." -f 1)
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
VALIDATE $? "Checking NodeJS module list"

dnf module disable nodejs -y &>>$LOG_NAME
VALIDATE $? "Disabling NodeJS module"

dnf module enable nodejs:20 -y &>>$LOG_NAME
VALIDATE $? "Enabling NodeJS module 20"

dnf install nodejs -y &>>$LOG_NAME
VALIDATE $? "Installing NodeJS"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_NAME
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_NAME
VALIDATE $? "Creating /app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_NAME
VALIDATE $? "Downloading user service zip file"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>>$LOG_NAME
VALIDATE $? "unzipping cart"

npm install &>>$LOG_NAME
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart service"

systemctl daemon-reload &>>$LOG_NAME
systemctl enable cart  &>>$LOG_NAME
systemctl start cart &>>$LOG_NAME
VALIDATE $? "Starting cart"


END_TIME=$(date +%s)
echo "Script execution time: $(($END_TIME - $START_TIME)) seconds" | tee -a $LOG_NAME