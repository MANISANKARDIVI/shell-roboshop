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

dnf module list nginx &>>$LOG_NAME
VALIDATE $? "Checking Nginx module list"

dnf module disable nginx -y &>>$LOG_NAME
VALIDATE $? "Disabling Nginx module"

dnf module enable nginx:1.24 -y &>>$LOG_NAME
VALIDATE $? "Enabling Nginx module 1.24"

dnf install nginx -y &>>$LOG_NAME
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_NAME
VALIDATE $? "Enabling Nginx service"

systemctl start nginx &>>$LOG_NAME
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOG_NAME
VALIDATE $? "Cleaning Nginx html directory"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_NAME
VALIDATE $? "Downloading frontend zip file"

cd /usr/share/nginx/html &>>$LOG_NAME
VALIDATE $? "Changing directory to Nginx html directory"

unzip /tmp/frontend.zip &>>$LOG_NAME
VALIDATE $? "Unzipping frontend zip file"

rm -rf /etc/nginx/nginx.conf &>>$LOG_NAME
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_NAME
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx &>>$LOG_NAME
VALIDATE $? "Restarting Nginx service"

echo "Frontend setup completed successfully: $(date)" | tee -a $LOG_NAME
