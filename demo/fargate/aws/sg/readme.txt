# Check VPC ID
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=ECS tomcat - VPC" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

# Create SecurityGroup
aws ec2 create-security-group --group-name ECS-tomcat-sample --description "Tomcat 8080" --vpc-id [VPC_ID] --tag-specifications ResourceType=security-group,Tags=[{"Key=Name,Value=ECS tomcat - SecurityGroup"}] 

# Add Inbound Rule
aws ec2 authorize-security-group-ingress --group-id [SG_ID] --protocol tcp --port 8080 --cidr 0.0.0.0/0

