# Create IGW
aws ec2 create-internet-gateway --tag-specifications ResourceType=internet-gateway,Tags=[{"Key=Name,Value=ECS tomcat - IGW"}]

# Check VPC ID
aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

# Attach IGW to VPC
aws ec2 attach-internet-gateway --vpc-id [VPC_ID] --internet-gateway-id [IGW_ID]

