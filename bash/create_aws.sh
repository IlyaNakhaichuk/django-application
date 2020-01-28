#!/bin/bash

ACCESS_KEY=test
KEY_PAIR_EC2=secret_key

value_vpc_id=$(aws ec2 describe-vpcs --query 'Vpcs[*].{VpcId:VpcId}' --output text --profile $ACCESS_KEY)
aws ssm put-parameter --name "vpc_id_parameter" --type "String" --description "Vpc_id Oregon parameter for using EC2" --value $value_vpc_id --no-overwrite --tags Key=Name,Value=VPC --profile $ACCESS_KEY
if [ ! -f "./ansible/ssh-private-key/$KEY_PAIR_EC2.pem" ]; then
    aws ec2 create-key-pair --key-name $KEY_PAIR_EC2 --query '{KeyMaterial:KeyMaterial}' --output text --profile $ACCESS_KEY >> ./ansible/ssh-private-key/$KEY_PAIR_EC2.pem
    aws ssm put-parameter --name "key_pair" --type "String" --description "Key pair Oregon parameter for using EC2" --value $KEY_PAIR_EC2 --no-overwrite --tags Key=Name,Value=Keypair --profile $ACCESS_KEY
    chmod 400 ansible/ssh-private-key/$KEY_PAIR_EC2.pem
fi

cd aws-cdk-project/
cdk deploy Stack-A-SG --require-approval=never --profile $ACCESS_KEY
cdk deploy Stack-B-EC2 --require-approval=never --profile $ACCESS_KEY

cd ../ansible/
my_ip_instance=$(aws ec2 describe-addresses --filters "Name=tag-value, Values=Stack-B-EC2" --query 'Addresses[*].{PublicIp:PublicIp}' --output text --profile $ACCESS_KEY)
until [ "$(ansible all -m ping --extra-vars "hostrouter=$my_ip_instance key_pair=$KEY_PAIR_EC2.pem" | grep SUCCESS | cut -d ' ' -f 3)" == "SUCCESS" ]; do
    sleep 2
    echo "Wait please"
done
ansible all -m ping --extra-vars "hostrouter=$my_ip_instance key_pair=$KEY_PAIR_EC2.pem"
ansible-playbook playbooks/main.yml --extra-vars "hostrouter=$my_ip_instance key_pair=$KEY_PAIR_EC2.pem"