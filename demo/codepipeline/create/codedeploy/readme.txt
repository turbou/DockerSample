# Create Application
aws deploy create-application --application-name PetClinic2 --compute-platform Server --region ap-northeast-1

# Create Deployment Group
aws deploy create-deployment-group \
  --application-name PetClinic2 \
  --region ap-northeast-1 \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --deployment-group-name PetClinicDeployGroup2 \
  --service-role-arn arn:aws:iam::310199975805:role/service-role/CodeDeployServiceRole-Demo \
  --ec2-tag-filters Key=Target,Value=PetClinic,Type=KEY_AND_VALUE

