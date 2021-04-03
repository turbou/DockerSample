# Create Cluster
aws ecs create-cluster --cluster-name tomcat_sample

# Create Task Definition
# ===================================================================================== #
# !! task_definition.jsonの中の[ACCOUNT_ID]をご自身のAWSアカウントIDに変更してください。
# ===================================================================================== #
aws ecs register-task-definition --cli-input-json file://task_definition.json

# List Task Definition
aws ecs list-task-definitions

