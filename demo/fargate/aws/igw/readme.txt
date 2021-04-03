# Create IGW
aws ec2 create-internet-gateway --tag-specifications ResourceType=internet-gateway,Tags=[{"Key=Name,Value=ECS tomcat - IGW"}]

# Check VPC ID
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=ECS tomcat - VPC" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

# Attach IGW to VPC
aws ec2 attach-internet-gateway --vpc-id [VPC_ID] --internet-gateway-id [IGW_ID]

# Create Custom RootTable
aws ec2 create-route-table --vpc-id [VPC_ID]

aws ec2 create-route --route-table-id [RTB_ID] --destination-cidr-block 0.0.0.0/0 --gateway-id [IGW_ID]

# Check Subnet ID
aws ec2 describe-subnets --filters "Name=tag:Name,Values=ECS tomcat - Primary Subnet" --query 'Subnets[*].[VpcId,SubnetId]' --output table

# Associate RootTable
aws ec2 associate-route-table  --subnet-id [SUBNET_ID] --route-table-id [RTB_ID]

