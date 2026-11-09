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
dnf module list nodejs &>/dev/null
VALIDATE $? "Listing the node modules"

# Disable current module
dnf module disable nodejs -y &>/dev/null
VALIDATE $? "Disabled existing node version"

# Enable required node version
dnf module enable nodejs:20 -y &>/dev/null
VALIDATE $? "Enabling node version"

# Install Nodejs package
dnf install nodejs -y &>/dev/null
VALIDATE $? "Installed Nodejs"


if id roboshop
then
    echo "System user roboshop already created ..."
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
fi


# create Directory
mkdir -p /app &>/dev/null
VALIDATE $? "Created directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>/dev/null
VALIDATE $? "Downloading catalogue packages"

rm -rf /app/* &>/dev/null
cd /app
unzip /tmp/catalogue.zip &>/dev/null
VALIDATE $? "Unzip files"

# install packages
npm install &>/dev/null
VALIDATE $? "Installed node packages"

# copying catalogue service file
cp ./catalogue.service /etc/systemd/system/catalogue.service &>/dev/null
VALIDATE $? "copying catalogue.service file"

# restart the service
systemctl daemon-reload &>/dev/null
VALIDATE $? "Reload the daemon"

# Enable the service
systemctl enable catalogue &>/dev/null
VALIDATE $? "Enable the catalogue"

# Start the service
systemctl start catalogue &>/dev/null
VALIDATE $? "Start catalogue"


# Install mongo client
cp mongo.repo /etc/yum.repos.d/mongo.repo &>/dev/null
VALIDATE $? "Copied mongo.repo file"

# Install mongosh
dnf install mongodb-mongosh -y &>/dev/null
VALIDATE $? "Installed mongosh"

# Load master data
STATUS=$(mongosh --host mongodb.manisankardivi.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")') &>/dev/null
if [ "$STATUS" -lt 0 ]
then
  mongosh --host mongodb.manisankardivi.online </app/db/master-data.js
  VALIDATE $? "Loading data into MongoDB"
else
   echo "Data is already loaded ..."
fi




