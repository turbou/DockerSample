# CreateRole(Pipeline)
aws iam create-role --path "/service-role/" --role-name CodePipelineServiceRole-Demo --assume-role-policy-document file://./role_codepipeline.json
# CreateRole(CodeBuild)
aws iam create-role --path "/service-role/" --role-name CodeBuildServiceRole-Demo --assume-role-policy-document file://./role_codebuild.json
# CreateRole(CodeDeploy)
aws iam create-role --path "/service-role/" --role-name CodeDeployServiceRole-Demo --assume-role-policy-document file://./role_codedeploy.json

