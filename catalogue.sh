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
dnf module list nodejs
VALIDATE $? "Listing the node modules"

# Disable current module
dnf module disable nodejs -y
VALIDATE $? "Disabled existing node version"

# Enable required node version
dnf module enable nodejs:20 -y
VALIDATE $? "Enabling node version"

# Install Nodejs package
dnf install nodejs -y
VALIDATE $? "Installed Nodejs"

id roboshop
if [ $? -ne 0 ]
then
  echo "useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop"
   VALIDATE $? "Creating roboshop system user"
else
  echo "Already roboshop user exist"
fi


# create Directory
mkdir -p /app
VALIDATE $? "Created directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Downloading catalogue packages"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip
VALIDATE $? "Unzip files"

# install packages
npm install
VALIDATE $? "Installed node packages"

# copying catalogue service file
cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue.service file"

# restart the service
systemctl daemon-reload
VALIDATE $? "Reload the daemon"

# Enable the service
systemctl enable catalogue
VALIDATE $? "Enable the catalogue"

# Start the service
systemctl start catalogue
VALIDATE $? "Start catalogue"


# Install mongo client
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copied mongo.repo file"

# Install mongosh
dnf install mongodb-mongosh -y
VALIDATE $? "Installed mongosh"

# Load master data
STATUS=$(mongosh --host mongodb.manisankardivi.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ "$STATUS" -lt 0 ]
then
  mongosh --host mongodb.manisankardivi.online </app/db/master-data.js
  VALIDATE $? "Loading data into MongoDB"
else
   echo "Data is already loaded ..."
fi




