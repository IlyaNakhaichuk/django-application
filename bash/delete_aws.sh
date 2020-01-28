#!/bin/bash

ACCESS_KEY=test
KEY_PAIR_EC2=secret_key

cd aws-cdk-project/
cdk destroy Stack-B-EC2 --force --profile $ACCESS_KEY
cdk destroy Stack-A-SG --force --profile $ACCESS_KEY
cd ../
aws ssm delete-parameter --name "vpc_id_parameter" --profile $ACCESS_KEY
aws ssm delete-parameter --name "key_pair" --profile $ACCESS_KEY
aws ec2 delete-key-pair --key-name $KEY_PAIR_EC2 --profile $ACCESS_KEY
rm -f ansible/ssh-private-key/$KEY_PAIR_EC2.pem



