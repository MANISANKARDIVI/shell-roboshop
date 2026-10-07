#!/usr/bin/env bash

# create 11 instances of roboshop application
# rename them
# update route53 records
#   if (insstance  is frontend)
#   then
#     update public IP
#   else
#     update private IP

# we need instance id, ami id, security group, subnet id, key name, instance type, region, route53 hosted zone id

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0e4707bf1d18b6898"
INSTANCES=("mongodb" "redis" "mysql" "frontend" "cart" "catalogue" "user" "shipping" "payment" "rabbitmq" "dispatch")
ZONE_ID="Z00088451NX8RO0IJKRPT"
DOMAIN_NAME="manisankardivi.online"


for instance in ${INSTANCES[@]}
do
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  if [ $instance != "frontend" ]
  then
    IP=$(aws ec2 describe-instances \
          --instance-ids $INSTANCE_ID \
          --query "Reservations[0].Instances[0].PrivateIpAddress" \
          --output text)
  else
    IP=$(aws ec2 describe-instances \
          --instance-ids $INSTANCE_ID \
          --query "Reservations[0].Instances[0].PublicIpAddress" \
          --output text)
  fi
  echo "$instance IP Address: $IP"
done
