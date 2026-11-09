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


dnf module disable redis -y
VALIDATE $? " disabled redis module"

dnf module enable redis:7 -y
VALIDATE $? "enabled redis module"

dnf install redis -y
VALIDATE $? "installed redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "updated port number"

systemctl enable redis
VALIDATE $? "enabled redis service"

systemctl start redis
VALIDATE $? "started redis service"