# Create Application
aws deploy create-application --application-name PetClinic --compute-platform Server --region ap-northeast-1

# Create Deployment Group
aws deploy create-deployment-group \
  --application-name PetClinic \
  --region ap-northeast-1 \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --deployment-group-name PetClinicDeployGroup \
  --service-role-arn arn:aws:iam::[ACCOUNT_ID]:role/service-role/CodeDeployServiceRole-Demo \
  --ec2-tag-filters Key=Target,Value=PetClinic,Type=KEY_AND_VALUE

