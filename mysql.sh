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


dnf install mysql-server -y

systemctl enable mysqld
systemctl start mysqld

mysql_secure_installation --set-root-pass RoboShop@1