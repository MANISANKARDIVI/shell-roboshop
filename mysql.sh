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

dnf install mysql-server -y &>>"$LOG_NAME"
VALIDATE $? "MySQL Server Installation"

systemctl enable mysqld &>>"$LOG_NAME"
VALIDATE $? "Enabling MySQL Service"

systemctl start mysqld &>>"$LOG_NAME"
VALIDATE $? "Starting MySQL Service"

echo "enter your mysql root password:"
read -s password

mysql_secure_installation --set-root-pass "$password" &>>"$LOG_NAME"
VALIDATE $? "Securing MySQL password"


END_TIME=$(date +%s)
echo "$Y Script execution time: $(($END_TIME - $START_TIME)) seconds $N" | tee -a "$LOG_NAME"
