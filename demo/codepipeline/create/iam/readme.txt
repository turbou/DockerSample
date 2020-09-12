# CreateRole(Pipeline)
aws iam create-role --path "/service-role/" --role-name CodePipelineServiceRole-Demo --assume-role-policy-document file://./policy_codepipeline.json
# CreateRole(CodeBuild)
aws iam create-role --path "/service-role/" --role-name CodeBuildServiceRole-Demo --assume-role-policy-document file://./policy_codebuild.json

