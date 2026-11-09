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


dnf install maven -y

if id roboshop
then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
  echo "Already user exists"
fi

mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
cd /app
unzip /tmp/shipping.zip

mvn clean package
mv target/shipping-1.0.jar shipping.jar




systemctl daemon-reload
systemctl enable shipping
systemctl start shipping

dnf install mysql -y

echo "Please enter root password to setup"
read -s password

mysql -h mysql.manisankardivi.online -u root -p$password -e 'use cities'

if [ $? -ne 0 ]
then
    mysql -h mysql.manisankardivi.online -uroot -p$password < /app/db/schema.sql
    mysql -h mysql.manisankardivi.online -uroot -p$password < /app/db/app-user.sql
    mysql -h mysql.manisankardivi.online -uroot -p$password < /app/db/master-data.sql
    VALIDATE $? "Loading data into MySQL"
else
    echo "Data is already loaded into MySQL ...SKIPPING"
fi

systemctl restart shipping
