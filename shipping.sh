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
  echo "user already exists"
else
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
fi

mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
cd /app
unzip /tmp/shipping.zip

mvn clean package
mv target/shipping-1.0.jar shipping.jar


cp $DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload
systemctl enable shipping
systemctl start shipping

dnf install mysql -y

echo "Please enter root password to setup"
read -s password

if mysql -h mysql.manisankardivi.online -u root -p"$password" -e 'USE cities'
then
    echo "Data is already loaded into MySQL ... SKIPPING"
else
    mysql -h mysql.manisankardivi.online -u root -p"$password" < /app/db/schema.sql
    mysql -h mysql.manisankardivi.online -u root -p"$password" < /app/db/app-user.sql
    mysql -h mysql.manisankardivi.online -u root -p"$password" < /app/db/master-data.sql

    echo "Loading data into MySQL ... SUCCESS"
fi

systemctl restart shipping
