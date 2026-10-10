#!/usr/bin/env bash

# Create 11 instances of RoboShop application
# Rename them
# Update Route53 records
# If instance is frontend:
#     use public IP
# Else:
#     use private IP

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0e4707bf1d18b6898"
ZONE_ID="Z00088451NX8RO0IJKRPT"
DOMAIN_NAME="manisankardivi.online"

INSTANCES=("mongodb" "redis" "mysql" "frontend" "cart" "catalogue" "user" "shipping" "payment" "rabbitmq" "dispatch")


for instance in "${INSTANCES[@]}"
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t2.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ "$instance" != "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"

    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IPAddress: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'

done