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


dnf install python3 gcc python3-devel -y

if id roboshop
then
  echo "user already exists"
else
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
fi

mkdir -p /app

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
cd /app
unzip /tmp/payment.zip
pip3 install -r requirements.txt

cp $DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload

systemctl enable payment

systemctl start payment



