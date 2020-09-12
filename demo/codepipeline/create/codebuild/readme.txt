# Create Skeleton
aws codebuild create-project --generate-cli-skeleton > skeleton.json

# Create CodeBuild Project(Build)
aws codebuild create-project --cli-input-json file://codebuild_build.json
# Create CodeBuild Project(Test)
aws codebuild create-project --cli-input-json file://codebuild_test.json
