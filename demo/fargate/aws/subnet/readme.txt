aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
aws ec2 create-subnet --vpc-id [VPC_ID] --cidr-block 10.0.0.0/24
aws ec2 create-subnet --vpc-id [VPC_ID] --cidr-block 10.0.1.0/24

