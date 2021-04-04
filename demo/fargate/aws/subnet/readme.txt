# Check VPC ID
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=ECS tomcat - VPC" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

# Create Subnet(Primary)
aws ec2 create-subnet --vpc-id [VPC_ID] --cidr-block 10.0.0.0/24 --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=ECS tomcat - Primary Subnet"}]

