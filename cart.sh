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
VALIDATE $? "listed module"

dnf module disable nodejs -y
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enable nodejs"


if id roboshop
then
  echo "User already exists"
else
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
fi

mkdir -p /app

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip

cd /app

unzip /tmp/cart.zip

npm install

cp $DIR/cart.service /etc/systemd/system/cart.service

systemctl daemon-reload

systemctl enable cart

systemctl start cart











