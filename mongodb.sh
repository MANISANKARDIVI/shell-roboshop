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
SCRIPT_NAME=$( echo $0 | cut -d "." -f 1)
LOG_NAME="$LOG_FOLDER/$SCRIPT_NAME.log"

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


cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_NAME
VALIDATE $? "Copying the mongodb repo file"

dnf install mongodb-org -y &>>$LOG_NAME
VALIDATE $? "Installing mongodb-org"

systemctl enable mongod &>>$LOG_NAME
VALIDATE $? "Enabling mongodb service"

systemctl start mongod &>>$LOG_NAME
VALIDATE $? "Starting mongodb service"

sed -i -e "s/127.0.0.1/0.0.0.0/" /etc/mongod.conf &>>$LOG_NAME
VALIDATE $? "Updating mongodb bind address"

systemctl restart mongod &>>$LOG_NAME
VALIDATE $? "Restarting mongodb service"

echo "Script finished executing at: $(date)" | tee -a $LOG_NAME








