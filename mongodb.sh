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

# copy mongo configuration file
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copied configuration file"

# Install Mongodb
dnf install mongodb-org -y
VALIDATE $? "Installed mongodb"

# Start & Enable the server
systemctl enable mongod
VALIDATE $? "Mongo server enabled"

systemctl start mongod
VALIDATE $? "Mongo server started"

# update the port number 127.0.0.1 to 0.0.0.0
sed -i -e "s/127.0.0.1/0.0.0.0/" /etc/mongod.conf
VALIDATE $? "Updated port number"

# Restart the mongo server
systemctl restart mongod
VALIDATE $? "Restarted mongodb server"
