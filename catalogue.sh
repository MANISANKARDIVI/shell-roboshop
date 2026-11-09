#!/usr/bin/env bash

set -euo pipefail

USER_ID=$(id -u)

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

# List nodejs modules
dnf module list nodejs 2>&1
VALIDATE $? "Listing the node modules"

# Disable current module
dnf module disable nodejs -y 2>&1
VALIDATE $? "Disabled existing node version"

# Enable required node version
dnf module enable nodejs:20 -y 2>&1
VALIDATE $? "Enabling node version"

# Install Nodejs package
dnf install nodejs -y 2>&1
VALIDATE $? "Installed Nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
else
    echo "System user roboshop already created ..."
fi


# create Directory
mkdir -p /app 2>&1
VALIDATE $? "Created directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 2>&1
VALIDATE $? "Downloading catalogue packages"

rm -rf /app/* 2>&1
cd /app
unzip /tmp/catalogue.zip 2>&1
VALIDATE $? "Unzip files"

# install packages
npm install 2>&1
VALIDATE $? "Installed node packages"

# copying catalogue service file
cp catalogue.service /etc/systemd/system/catalogue.service 2>&1
VALIDATE $? "copying catalogue.service file"

# restart the service
systemctl daemon-reload 2>&1
VALIDATE $? "Reload the daemon"

# Enable the service
systemctl enable catalogue 2>&1
VALIDATE $? "Enable the catalogue"

# Start the service
systemctl start catalogue 2>&1
VALIDATE $? "Start catalogue"


# Install mongo client
cp mongo.repo /etc/yum.repos.d/mongo.repo 2>&1
VALIDATE $? "Copied mongo.repo file"

# Install mongosh
dnf install mongodb-mongosh -y 2>&1
VALIDATE $? "Installed mongosh"

# Load master data
STATUS=$(mongosh --host mongodb.manisankardivi.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")') 2>&1
if [ "$STATUS" -lt 0 ]
then
  mongosh --host mongodb.manisankardivi.online </app/db/master-data.js
  VALIDATE $? "Loading data into MongoDB"
else
   echo "Data is already loaded ..."
fi




