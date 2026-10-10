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

dnf module disable redis -y &>>$LOG_NAME
VALIDATE $? "Disabling Redis module"

dnf module enable redis:7 -y &>>$LOG_NAME
VALIDATE $? "Enabling Redis module 7"

# installing redis
dnf install redis -y &>>$LOG_NAME
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis&>>$LOG_NAME
VALIDATE $? "Enabling Redis service"

systemctl start redis &>>$LOG_NAME
VALIDATE $? "Starting Redis service"

END_TIME=$(date +%s)
echo "Script execution time: $(($END_TIME - $START_TIME)) seconds" | tee -a $LOG_NAME