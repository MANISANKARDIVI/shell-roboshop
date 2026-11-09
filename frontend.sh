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

dnf module list nginx
VALIDATE $? "Listed nginx modules"

dnf module disable nginx -y
VALIDATE $? "disabled nginx module"

dnf module enable nginx:1.24 -y
VALIDATE $? "Enable module nignx"

dnf install nginx -y
VALIDATE $? "Installed nginx"

systemctl enable nginx
VALIDATE $? "Enable nginx service"

systemctl start nginx
VALIDATE $? "Start nginx service"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "remove existing nginx default files"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Download nginx files"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip
VALIDATE $? " unzipped files"

cp $DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copied configuration"

systemctl restart nginx
VALIDATE $? "restart nginx service"












