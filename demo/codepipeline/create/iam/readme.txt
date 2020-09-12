# CreateRole(Pipeline)
aws iam create-role --path "/service-role/" --role-name CodePipelineServiceRole-Demo --assume-role-policy-document file://role_codepipeline.json
aws iam put-role-policy --role-name CodePipelineServiceRole-Demo --policy-name CodePipelineBasePolicy-PetClinic --policy-document file://policy_codepipeline.json

# CreateRole(CodeBuild)
aws iam create-role --path "/service-role/" --role-name CodeBuildServiceRole-Demo --assume-role-policy-document file://role_codebuild.json
aws iam put-role-policy --role-name CodeBuildServiceRole-Demo --policy-name CodeBuildBasePolicy-PetClinic --policy-document file://policy_codebuild.json

# CreateRole(CodeDeploy)
aws iam create-role --path "/service-role/" --role-name CodeDeployServiceRole-Demo --assume-role-policy-document file://role_codedeploy.json
# Attach Policy
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole --role-name CodeDeployServiceRole-Demo

