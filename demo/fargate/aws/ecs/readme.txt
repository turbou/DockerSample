# Create Cluster
aws ecs create-cluster --cluster-name tomcat_sample

# Create Task Definition
# ===================================================================================== #
# !! task_definition.jsonの中の[ACCOUNT_ID]をご自身のAWSアカウントIDに変更してください。
# ===================================================================================== #
aws ecs register-task-definition --cli-input-json file://task_definition.json

# List Task Definition
aws ecs list-task-definitions

# Check Subnet ID
aws ec2 describe-subnets --filters "Name=tag:Name,Values=ECS tomcat - Primary Subnet" --query 'Subnets[*].[VpcId,SubnetId]' --output table
# Check SecurityGroup ID
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=ECS tomcat - SecurityGroup" --query 'SecurityGroups[*].[GroupId,Description]' --output table

# Create Service
aws ecs create-service --cluster tomcat_sample --service-name tomcat_sample-service --task-definition tomcat-task-definition:2 --desired-count 1 --launch-type "FARGATE" --network-configuration "awsvpcConfiguration={subnets=[subnet-abcd1234],securityGroups=[sg-abcd1234],assignPublicIp=ENABLED}"

