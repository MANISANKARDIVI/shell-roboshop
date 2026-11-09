#!/usr/bin/env bash

set -euo pipefail

USER_ID=$(id -u)
DIR=$(pwd)


if [ "$USER_ID" -eq 0 ]
then
  echo "USER have Root Access"
else
  echo "USER Dont Root Access"
fi

VALIDATE() {
  if [ $1 -eq 0 ]
  then
    echo "$2 ... SUCCESS"
  else
    echo "$2 ... FAILED"
  fi
}


dnf module list
VALIDATE $? "listed node modules"

dnf module disable nodejs -y
VALIDATE $? "disabled nodejs module"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabled nodejs module"

dnf install nodejs -y
VALIDATE $? "Installed nodejs"

if id roboshop
then
    echo "System user roboshop already created ..."
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
fi

mkdir -p /app

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip
cd /app
unzip /tmp/user.zip
VALIDATE $? "Unzipped files"

npm install
VALIDATE $? "Node package install"


cp $DIR/user.service  /etc/systemd/system/user.service
VALIDATE $? "copied user.service file"


systemctl daemon-reload
VALIDATE $? "reload daemon"

systemctl enable user
VALIDATE $? "Enable user service"

systemctl start user
VALIDATE $? " Start user service"

