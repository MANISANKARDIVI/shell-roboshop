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


dnf install python3 gcc python3-devel -y &>>"$LOG_NAME"
VALIDATE $? "Installing Python3, GCC, and Python3-devel"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_LOG_NAME
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N" &>>$LOG_LOG_NAME
fi


mkdir -p /app &>>"$LOG_NAME"
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>"$LOG_NAME"
VALIDATE $? "Downloading payment service code"

rm -rf /app/*
cd /app
unzip /tmp/payment.zip &>>"$LOG_NAME"
VALIDATE $? "Extracting payment service code"


pip3 install -r requirements.txt &>>"$LOG_NAME"
VALIDATE $? "Installing Python dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>"$LOG_NAME"
VALIDATE $? "Copying payment.service to systemd directory"

systemctl daemon-reload &>>"$LOG_NAME"
VALIDATE $? "Reloading systemd daemon"

systemctl enable payment &>>$LOG_NAME
VALIDATE $? "Enabled payment service"

systemctl start payment &>>"$LOG_NAME"
VALIDATE $? "started payment service"

END_TIME=$(date +%s)
echo -e "$Y Script execution time: $(($END_TIME - $START_TIME)) seconds $N" | tee -a "$LOG_NAME"
