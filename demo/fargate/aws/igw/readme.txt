aws ec2 create-internet-gateway

aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
aws ec2 attach-internet-gateway --vpc-id [VPC_ID] --internet-gateway-id [IGW_ID]

